data "azurerm_client_config" "current" {}

locals {
  tenant_id = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  tags      = merge(var.tags, { Module = "key-vault" })
}

resource "azurerm_key_vault" "kv" {
  name                          = "kv-${var.project}-${var.environment}-${var.location}-001"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = local.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = false
  rbac_authorization_enabled    = true
  tags                          = local.tags
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-${var.project}-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-kv-${var.project}-${var.environment}-${var.location}-001"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
