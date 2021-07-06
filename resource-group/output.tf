output "control_rg_name" {
  value = azurerm_resource_group.control_rg.name
}

output "control_rg_location" {
  value = azurerm_resource_group.control_rg.location
  sensitive = true
}