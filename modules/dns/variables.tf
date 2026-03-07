variable "resource_group_name" {
  description = "Name of the resource group where DNS zones will be created"
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub virtual network to link DNS zones to"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all DNS resources"
  type        = map(string)
}
