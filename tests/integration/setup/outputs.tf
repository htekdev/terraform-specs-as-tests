output "resource_group_name" {
  description = "Name of the test resource group"
  value       = azurerm_resource_group.test.name
}

output "location" {
  description = "Azure region of test resources"
  value       = azurerm_resource_group.test.location
}

output "vnet_id" {
  description = "ID of the test VNet"
  value       = azurerm_virtual_network.test.id
}

output "subnet_id" {
  description = "ID of the endpoints subnet"
  value       = azurerm_subnet.endpoints.id
}

output "workspace_id" {
  description = "ID of the test Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.test.id
}

output "eventhub_dns_zone_id" {
  description = "ID of the Event Hub private DNS zone"
  value       = azurerm_private_dns_zone.eventhub.id
}

output "keyvault_dns_zone_id" {
  description = "ID of the Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.keyvault.id
}
