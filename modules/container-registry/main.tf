locals {
  # ACR names must be alphanumeric only (no hyphens)
  acr_name = "acr${var.project}${var.environment}${var.location}001"
  tags = merge(var.tags, {
    Module = "container-registry"
  })
}

resource "azurerm_container_registry" "acr" {
  name                          = local.acr_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = local.tags

  retention_policy_in_days = 7
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.project}-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-acr-${var.project}-${var.environment}-${var.location}-001"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
