# DNS Module — Unit Tests
# Validates the dns module creates private DNS zones for key Azure services
# and links them to the hub VNet.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-lz-dev-eastus2"
  location            = "eastus2"
  hub_vnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "dns_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = length(output.zone_ids) > 0
    error_message = "DNS zone_ids map output must contain at least one entry"
  }
}

run "dns_creates_key_vault_zone" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone.zones["kv"].name == "privatelink.vaultcore.azure.net"
    error_message = "DNS module must create a private DNS zone for Key Vault (privatelink.vaultcore.azure.net)"
  }
}

run "dns_creates_blob_storage_zone" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone.zones["st"].name == "privatelink.blob.core.windows.net"
    error_message = "DNS module must create a private DNS zone for Blob Storage (privatelink.blob.core.windows.net)"
  }
}

run "dns_creates_acr_zone" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone.zones["acr"].name == "privatelink.azurecr.io"
    error_message = "DNS module must create a private DNS zone for Container Registry (privatelink.azurecr.io)"
  }
}

run "dns_creates_aks_zone" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone.zones["aks"].name == "privatelink.eastus2.azmk8s.io"
    error_message = "DNS module must create a private DNS zone for AKS (privatelink.eastus2.azmk8s.io)"
  }
}

run "dns_links_zones_to_hub_vnet" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.hub["kv"].virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    error_message = "Key Vault DNS zone must be linked to the hub VNet"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.hub["st"].virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    error_message = "Storage DNS zone must be linked to the hub VNet"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.hub["acr"].virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    error_message = "ACR DNS zone must be linked to the hub VNet"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.hub["aks"].virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    error_message = "AKS DNS zone must be linked to the hub VNet"
  }
}

run "dns_zone_links_have_registration_disabled" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.hub["kv"].registration_enabled == false
    error_message = "Private DNS zone VNet links must have auto-registration disabled (private endpoints use explicit records)"
  }
}

run "dns_tags_are_applied" {
  command = plan

  module {
    source = "./modules/dns"
  }

  assert {
    condition     = azurerm_private_dns_zone.zones["kv"].tags["Environment"] == "dev"
    error_message = "DNS zones must carry the Environment tag"
  }

  assert {
    condition     = azurerm_private_dns_zone.zones["kv"].tags["ManagedBy"] == "terraform"
    error_message = "DNS zones must carry the ManagedBy tag"
  }
}
