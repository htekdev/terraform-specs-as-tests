variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  validation {
    condition     = contains(["eastus2", "westus2"], var.location)
    error_message = "Only eastus2 and westus2 are allowed."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for AKS node pool"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for OMS agent monitoring"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry ID for ACR integration"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.29"
}

variable "system_node_count" {
  description = "Number of nodes in the default system node pool"
  type        = number
  default     = 3
}

variable "system_vm_size" {
  description = "VM size for the default system node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
