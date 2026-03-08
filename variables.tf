variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string

  validation {
    condition     = contains(["eastus2", "westus2"], var.location)
    error_message = "Only eastus2 and westus2 are allowed regions."
  }
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "lz"
}

variable "owner" {
  description = "Team or individual responsible for the resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center code for billing attribution"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_configs" {
  description = "Configuration for spoke virtual networks"
  type = map(object({
    address_space   = list(string)
    subnet_prefixes = map(string)
    subnet_purposes = map(string)
  }))
  default = {
    workload-1 = {
      address_space = ["10.1.0.0/16"]
      subnet_prefixes = {
        default = "10.1.0.0/24"
        aks     = "10.1.1.0/22"
      }
      subnet_purposes = {
        default = "general"
        aks     = "aks-nodes"
      }
    }
    workload-2 = {
      address_space = ["10.2.0.0/16"]
      subnet_prefixes = {
        default   = "10.2.0.0/24"
        endpoints = "10.2.1.0/24"
      }
      subnet_purposes = {
        default   = "general"
        endpoints = "private-endpoints"
      }
    }
  }
}

variable "aks_config" {
  description = "AKS cluster configuration"
  type = object({
    kubernetes_version = string
    system_node_count  = number
    system_vm_size     = string
    user_node_count    = number
    user_vm_size       = string
    max_node_count     = number
    network_plugin     = string
    network_policy     = string
  })
  default = {
    kubernetes_version = "1.29"
    system_node_count  = 3
    system_vm_size     = "Standard_D4s_v5"
    user_node_count    = 3
    user_vm_size       = "Standard_D8s_v5"
    max_node_count     = 10
    network_plugin     = "azure"
    network_policy     = "azure"
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
