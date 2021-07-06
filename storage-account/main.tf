locals {
  hadr_modules = jsondecode(file("${path.module}/hadr-modules.json"))
}

resource "azurerm_storage_account" "control_rg_blob" {
  name                      = var.storage_account_name
  resource_group_name       = var.control_rg_name
  location                  = var.control_rg_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = "true"
  account_kind              = "BlobStorage"
}

resource "azurerm_storage_container" "control_rg_container" {
  name                  = var.storage_container
  storage_account_name  = azurerm_storage_account.control_rg_blob.name
  container_access_type = "private"
}


data "archive_file" "source" {
  for_each    = { for hm in local.hadr_modules : hm.name => hm }
  type        = "zip"
  source_file = "${path.cwd}/modules/${each.value.name}"
  output_path = "${path.module}/${each.value.name}.zip"
}

resource "azurerm_storage_blob" "example" {
  for_each               = { for hm in local.hadr_modules : hm.name => hm }
  name                   = "${each.value.name}.zip"
  storage_account_name   = azurerm_storage_account.control_rg_blob.name
  storage_container_name = azurerm_storage_container.control_rg_container.name
  type                   = "Block"
  source                 = "${path.module}/${each.value.name}.zip"
}

resource "null_resource" "clean_up_module_zip_files" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command     = "${path.module}/clean-up-zip-files.sh"
    interpreter = ["/bin/bash"]
  }
  depends_on = [
    azurerm_storage_blob.example
  ]
}


