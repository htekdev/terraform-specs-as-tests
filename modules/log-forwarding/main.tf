locals {
  namespace_name = "evhns-${var.project}-${var.environment}-${var.location}-001"
  hub_name       = "evh-${var.project}-${var.environment}-${var.location}-logs"
  tags           = merge(var.tags, { Module = "log-forwarding" })
}

resource "azurerm_eventhub_namespace" "main" {
  name                          = local.namespace_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Standard"
  capacity                      = var.capacity
  auto_inflate_enabled          = var.auto_inflate_enabled
  maximum_throughput_units      = var.auto_inflate_enabled ? var.maximum_throughput_units : null
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  local_authentication_enabled  = var.local_authentication_enabled
  tags                          = local.tags

  lifecycle {
    precondition {
      condition     = !var.auto_inflate_enabled || var.maximum_throughput_units >= var.capacity
      error_message = "maximum_throughput_units must be >= capacity when auto_inflate_enabled is true."
    }
  }
}

resource "azurerm_eventhub" "logs" {
  name              = local.hub_name
  namespace_id      = azurerm_eventhub_namespace.main.id
  partition_count   = var.partition_count
  message_retention = var.message_retention
}

resource "azurerm_eventhub_authorization_rule" "send" {
  name                = "diag-send"
  eventhub_name       = azurerm_eventhub.logs.name
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_eventhub_authorization_rule" "listen" {
  name                = "siem-listen"
  eventhub_name       = azurerm_eventhub.logs.name
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_private_endpoint" "evhns" {
  name                = "pe-evhns-${var.project}-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-evhns-${var.project}-${var.environment}-${var.location}-001"
    private_connection_resource_id = azurerm_eventhub_namespace.main.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "evhns" {
  name                       = "diag-evhns-${var.project}-${var.environment}"
  target_resource_id         = azurerm_eventhub_namespace.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ArchiveLogs"
  }

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "AutoScaleLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
