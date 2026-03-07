output "account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.storage.id
}

output "primary_blob_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}
