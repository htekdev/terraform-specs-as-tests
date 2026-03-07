variable "resource_group_name" {
  description = "Name of the resource group where firewall resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the firewall deployment"
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
  description = "Resource ID of the AzureFirewallSubnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for diagnostic logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all firewall resources"
  type        = map(string)
  default     = {}
}
