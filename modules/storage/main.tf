locals {
  # Storage account names: lowercase alphanumeric only, 3-24 chars
  storage_account_name = substr("st${var.project}${var.environment}${replace(var.location, "-", "")}001", 0, 24)

  tags = merge(var.tags, {
    Module = "storage"
  })
}

resource "azurerm_storage_account" "storage" {
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.account_replication_type
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
  }
}

resource "azurerm_private_endpoint" "storage" {
  name                = "pe-st-${var.project}-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-st-${var.project}-${var.environment}-${var.location}-001"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
