locals {
  test_tags = merge(var.tags, {
    Environment = "test"
    Owner       = "integration-tests"
    CostCenter  = "CC-TEST-001"
    ManagedBy   = "terraform-test"
    Project     = "lz"
    Purpose     = "integration-test"
    DeleteAfter = timeadd(timestamp(), "4h")
  })
}

resource "azurerm_resource_group" "test" {
  name     = "rg-lz-test-${var.test_id}-${var.location}"
  location = var.location
  tags     = local.test_tags
}

resource "azurerm_virtual_network" "test" {
  name                = "vnet-lz-test-${var.test_id}-${var.location}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["10.200.0.0/16"]
  tags                = local.test_tags
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.200.1.0/24"]
}

resource "azurerm_log_analytics_workspace" "test" {
  name                = "log-lz-test-${var.test_id}-001"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.test_tags
}

resource "azurerm_private_dns_zone" "eventhub" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.test.name
  tags                = local.test_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "eventhub" {
  name                  = "link-test-evhns"
  resource_group_name   = azurerm_resource_group.test.name
  private_dns_zone_name = azurerm_private_dns_zone.eventhub.name
  virtual_network_id    = azurerm_virtual_network.test.id
  registration_enabled  = false
  tags                  = local.test_tags
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.test.name
  tags                = local.test_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-test-kv"
  resource_group_name   = azurerm_resource_group.test.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.test.id
  registration_enabled  = false
  tags                  = local.test_tags
}
