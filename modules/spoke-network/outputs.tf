output "vnet_id" {
  description = "The ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "The name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = { for key, subnet in azurerm_subnet.subnets : key => subnet.id }
}
