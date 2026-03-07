locals {
  workspace_name = "log-${var.project}-${var.environment}-${var.location}-001"
  tags           = merge(var.tags, { Module = "monitoring" })
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = local.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = local.tags
}
