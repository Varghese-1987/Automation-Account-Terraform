provider "azurerm" {
  features {}
}

locals {
  control_rg_name      = var.control_rg_name
  storage_account_name = "${var.control_rg_name}sta"
  storage_container    = "${var.control_rg_name}stacontainer"
  automation_account   = "${var.control_rg_name}aa"
}


data "azurerm_client_config" "current" {}


module "dr-control-resourcegroup" {
  source              = "./resource-group"
  control_rg_name     = local.control_rg_name
  control_rg_location = var.control_rg_location
}

module "dr-storage-account" {
  source               = "./storage-account"
  storage_account_name = local.storage_account_name
  storage_container    = local.storage_container
  control_rg_name      = local.control_rg_name
  control_rg_location  = var.control_rg_location
  depends_on           = [module.dr-control-resourcegroup]
}

module "dr-control-automationaccount" {
  source                    = "./automation-account"
  automation_account_name   = local.automation_account
  control_rg_name           = local.control_rg_name
  control_rg_location       = var.control_rg_location
  primary_infrastructure_id = var.primary_infrastructure_id

  storage_account_name     = local.storage_account_name
  storage_container        = local.storage_container
  storage_connectionstring = module.dr-storage-account.storage_connection_string

  depends_on = [
    module.dr-control-resourcegroup,
  module.dr-storage-account]
}

output "demos" {
  value = module.dr-control-automationaccount.testing
}

