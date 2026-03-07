output "vnet_id" {
  description = "The ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "The name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "The ID of the AzureFirewallSubnet"
  value       = azurerm_subnet.firewall.id
}

output "gateway_subnet_id" {
  description = "The ID of the GatewaySubnet"
  value       = azurerm_subnet.gateway.id
}

output "management_subnet_id" {
  description = "The ID of the management subnet"
  value       = azurerm_subnet.management.id
}
