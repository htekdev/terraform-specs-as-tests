output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.cluster.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.cluster.name
}

output "private_fqdn" {
  description = "The private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.cluster.private_fqdn
}

output "node_resource_group" {
  description = "The auto-generated resource group for AKS node resources"
  value       = azurerm_kubernetes_cluster.cluster.node_resource_group
}

output "kubelet_identity" {
  description = "The kubelet managed identity assigned to the AKS cluster"
  value       = azurerm_kubernetes_cluster.cluster.kubelet_identity
}
