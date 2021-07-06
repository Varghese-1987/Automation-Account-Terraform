resource "azurerm_automation_account" "automation_account" {
  name                = var.automation_account_name
  location            = var.control_rg_location
  resource_group_name = var.control_rg_name

  sku_name = "Basic"
}

locals {
  automation_modules = jsondecode(file("${path.module}/automation-modules.json"))
  hadr_modules       = jsondecode(file("${path.cwd}/storage-account/hadr-modules.json"))
}

resource "azurerm_automation_module" "automation_modules" {

  for_each = { for am in local.automation_modules : am.name => am }

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name

  module_link {
    uri = each.value.uri
  }
  depends_on = [
    azurerm_automation_module.automation_modules["Az.Accounts"]
  ]
}

data "local_file" "dr_synchronize_script" {
  filename = "${path.module}/runbooks/dr-synchronize.ps1"
}

resource "azurerm_automation_runbook" "synchronize_automation_runbook" {
  name                    = "dr-synchronize"
  location                = var.control_rg_location
  resource_group_name     = var.control_rg_name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  content                 = data.local_file.dr_synchronize_script.content
}

resource "azurerm_automation_schedule" "synchronize_automation_schedule" {
  name                    = "dr-synchronize-schedule"
  resource_group_name     = var.control_rg_name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Hour"
  interval                = 3
}

resource "azurerm_automation_job_schedule" "synchronize_runbook_job_schedule" {
  resource_group_name     = var.control_rg_name
  automation_account_name = azurerm_automation_account.automation_account.name
  runbook_name            = azurerm_automation_runbook.synchronize_automation_runbook.name
  schedule_name           = azurerm_automation_schedule.synchronize_automation_schedule.name

  parameters = {
    primaryresourcegroupname = var.primary_infrastructure_id
  }

  depends_on = [
    azurerm_automation_runbook.synchronize_automation_runbook,
    azurerm_automation_schedule.synchronize_automation_schedule
  ]
}

data "local_file" "dr_update_automation_account_script" {
  filename = "${path.module}/runbooks/Update-AutomationAccountModule.ps1"
}

resource "azurerm_automation_runbook" "update_automation_account_automation_runbook" {
  name                    = "Update-AutomationAccountModule"
  location                = var.control_rg_location
  resource_group_name     = var.control_rg_name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  content                 = data.local_file.dr_update_automation_account_script.content
}



data "azurerm_storage_account_sas" "example" {
  connection_string = var.storage_connectionstring
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start = timestamp()
  # Increment by '1'
  expiry = timeadd(timestamp(), "300s")

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

data "azurerm_storage_blob" "demo" {

  for_each               = { for hm in local.hadr_modules : hm.name => hm }
  name                   = "${each.value.name}.zip"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_container
}

resource "azurerm_automation_module" "hadr_modules" {
  for_each                = { for hm in local.hadr_modules : hm.name => hm }
  name                    = trimsuffix(each.value.name, ".psm1")
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name

  module_link {
    uri = format("%s%s", data.azurerm_storage_blob.demo["${each.value.name}"].id, data.azurerm_storage_account_sas.example.sas)
  }

  depends_on = [
    data.azurerm_storage_account_sas.example,
    data.azurerm_storage_blob.demo
  ]
}

