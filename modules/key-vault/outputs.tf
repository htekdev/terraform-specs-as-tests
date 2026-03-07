output "vault_id" {
  description = "The resource ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}
