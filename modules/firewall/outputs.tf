output "firewall_id" {
  description = "The resource ID of the Azure Firewall"
  value       = azurerm_firewall.fw.id
}

output "private_ip_address" {
  description = "The private IP address of the Azure Firewall"
  value       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "The public IP address assigned to the Azure Firewall"
  value       = azurerm_public_ip.fw.ip_address
}
