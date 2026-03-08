locals {
  tags = merge(var.tags, { Module = "firewall" })
}

resource "azurerm_public_ip" "fw" {
  name                = "pip-fw-${var.project}-${var.environment}-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall_policy" "policy" {
  name                = "fwp-${var.project}-${var.environment}-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall" "fw" {
  name                = "fw-${var.project}-${var.environment}-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  threat_intel_mode   = "Deny"
  firewall_policy_id  = azurerm_firewall_policy.policy.id
  tags                = local.tags

  ip_configuration {
    name                 = "ipconfig-fw"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "default" {
  name               = "rcg-default-${var.project}-${var.environment}"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 1000

  network_rule_collection {
    name     = "allow-dns"
    priority = 1000
    action   = "Allow"

    rule {
      name                  = "allow-dns-outbound"
      protocols             = ["UDP", "TCP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                       = "diag-fw-${var.project}-${var.environment}"
  target_resource_id         = azurerm_firewall.fw.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AZFWApplicationRule"
  }

  enabled_log {
    category = "AZFWNetworkRule"
  }

  enabled_log {
    category = "AZFWThreatIntel"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
