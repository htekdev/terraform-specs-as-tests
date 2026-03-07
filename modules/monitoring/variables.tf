variable "resource_group_name" {
  description = "Name of the resource group where the Log Analytics workspace will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the Log Analytics workspace"
  type        = string

  validation {
    condition     = contains(["eastus2", "westus2"], var.location)
    error_message = "Location must be eastus2 or westus2."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain log data in the workspace"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all monitoring resources"
  type        = map(string)
}
