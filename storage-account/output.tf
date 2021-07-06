output "storage_account_name" {
  value = azurerm_storage_account.control_rg_blob.name
}

output "storage_account_access_key" {
  value     = azurerm_storage_account.control_rg_blob.primary_access_key
  sensitive = true
}

output "storage_connection_string" {
  value     = azurerm_storage_account.control_rg_blob.primary_blob_connection_string
  sensitive = true
}
