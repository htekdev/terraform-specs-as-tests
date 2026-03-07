locals {
  dns_zones = {
    kv  = "privatelink.vaultcore.azure.net"
    st  = "privatelink.blob.core.windows.net"
    acr = "privatelink.azurecr.io"
    aks = "privatelink.eastus2.azmk8s.io"
  }
  tags = merge(var.tags, { Module = "dns" })
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = local.dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each              = local.dns_zones
  name                  = "link-hub-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = local.tags
}
