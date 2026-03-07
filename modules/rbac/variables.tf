variable "aks_kubelet_identity_id" {
  description = "Principal ID of the AKS kubelet managed identity"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.aks_kubelet_identity_id))
    error_message = "aks_kubelet_identity_id must be a valid UUID"
  }
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ContainerRegistry/registries/[^/]+$", var.acr_id))
    error_message = "acr_id must be a valid Azure Container Registry resource ID"
  }
}

variable "key_vault_id" {
  description = "Resource ID of the Azure Key Vault"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.KeyVault/vaults/[^/]+$", var.key_vault_id))
    error_message = "key_vault_id must be a valid Azure Key Vault resource ID"
  }
}
