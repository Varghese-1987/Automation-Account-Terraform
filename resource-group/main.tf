resource "azurerm_resource_group" "control_rg" {
  name     = var.control_rg_name
  location = var.control_rg_location
}