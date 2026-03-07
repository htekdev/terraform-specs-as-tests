output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  value       = module.hub_network.vnet_id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = module.hub_network.vnet_name
}

output "spoke_vnet_ids" {
  description = "Map of spoke name to VNet resource ID"
  value       = { for k, v in module.spoke_network : k => v.vnet_id }
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = module.firewall.private_ip_address
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = module.aks_cluster.cluster_id
}

output "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = module.container_registry.login_server
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  value       = module.monitoring.workspace_id
}

output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = module.storage.account_id
}

output "dns_zone_ids" {
  description = "Map of service key to private DNS zone ID"
  value       = module.dns.zone_ids
}

output "rbac_role_assignment_ids" {
  description = "Map of role assignment names to their IDs"
  value       = module.rbac.role_assignment_ids
}
