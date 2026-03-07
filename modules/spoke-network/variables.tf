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

variable "name" {
  description = "Spoke name identifier (e.g. workload-1)"
  type        = string
}

variable "address_space" {
  description = "Address space for the spoke VNet"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create in the spoke VNet"
  type = map(object({
    address_prefix = string
  }))
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP address of the hub Azure Firewall for forced tunneling"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
