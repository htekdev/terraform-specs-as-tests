variable "resource_group_name" {
  description = "Name of the resource group where DNS zones will be created"
  type        = string
}

variable "location" {
  description = "Azure region (used for region-specific DNS zones like AKS)"
  type        = string

  validation {
    condition     = contains(["eastus2", "westus2"], var.location)
    error_message = "Location must be eastus2 or westus2."
  }
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub virtual network to link DNS zones to"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all DNS resources"
  type        = map(string)
}
