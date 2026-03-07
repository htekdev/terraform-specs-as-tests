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
  description = "Resource ID of the subnet for the private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Resource ID of the privatelink.vaultcore.azure.net DNS zone"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID. Defaults to the current client tenant."
  type        = string
  default     = ""
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted vaults (7–90)"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
