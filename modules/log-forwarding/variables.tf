variable "resource_group_name" {
  description = "Name of the resource group where Event Hub resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for Event Hub deployment"
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

variable "capacity" {
  description = "Throughput units for the Event Hub namespace (1-40 for Standard SKU)"
  type        = number
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 40
    error_message = "Capacity must be between 1 and 40 throughput units."
  }
}

variable "auto_inflate_enabled" {
  description = "Enable auto-inflate to automatically scale throughput units"
  type        = bool
  default     = true
}

variable "maximum_throughput_units" {
  description = "Maximum throughput units when auto-inflate is enabled (1-40)"
  type        = number
  default     = 10

  validation {
    condition     = var.maximum_throughput_units >= 1 && var.maximum_throughput_units <= 40
    error_message = "Maximum throughput units must be between 1 and 40."
  }
}

variable "local_authentication_enabled" {
  description = "Whether SAS-based local authentication is enabled (disable for AAD-only auth)"
  type        = bool
  default     = true
}

variable "partition_count" {
  description = "Number of partitions for the diagnostic logs event hub"
  type        = number
  default     = 4

  validation {
    condition     = var.partition_count >= 2 && var.partition_count <= 32
    error_message = "Partition count must be between 2 and 32."
  }
}

variable "message_retention" {
  description = "Number of days to retain messages in the event hub (1-7 for Standard)"
  type        = number
  default     = 7

  validation {
    condition     = var.message_retention >= 1 && var.message_retention <= 7
    error_message = "Message retention must be between 1 and 7 days for Standard SKU."
  }
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Resource ID of the privatelink.servicebus.windows.net DNS zone"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all log-forwarding resources"
  type        = map(string)
}
