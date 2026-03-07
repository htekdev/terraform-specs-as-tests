# Container Registry Module — Unit Tests
# Validates the container-registry module uses Premium SKU,
# disables admin access, denies public access, and creates a private endpoint.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-lz-dev-eastus2"
  location            = "eastus2"
  environment         = "dev"
  project             = "lz"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-services"
  private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "acr_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_container_registry.acr.name != ""
    error_message = "Container Registry name must not be empty"
  }

  assert {
    condition     = azurerm_container_registry.acr.sku == "Premium"
    error_message = "Container Registry must use Premium SKU (checked at output validation)"
  }
}

run "acr_uses_premium_sku" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_container_registry.acr.sku == "Premium"
    error_message = "Container Registry must use Premium SKU (required for private endpoints, CKV_LZ_004)"
  }
}

run "acr_has_admin_disabled" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_container_registry.acr.admin_enabled == false
    error_message = "Container Registry admin access must be disabled (CKV_LZ_004)"
  }
}

run "acr_denies_public_access" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_container_registry.acr.public_network_access_enabled == false
    error_message = "Container Registry must deny public network access"
  }
}

run "acr_has_private_endpoint" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_private_endpoint.acr.subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-services"
    error_message = "Container Registry private endpoint must be in the provided subnet"
  }
}

run "acr_tags_are_applied" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_container_registry.acr.tags["Environment"] == "dev"
    error_message = "Container Registry must carry the Environment tag"
  }

  assert {
    condition     = azurerm_container_registry.acr.tags["ManagedBy"] == "terraform"
    error_message = "Container Registry must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_container_registry.acr.tags["Project"] == "lz"
    error_message = "Container Registry must carry the Project tag"
  }
}

run "acr_uses_correct_location" {
  command = plan

  module {
    source = "./modules/container-registry"
  }

  assert {
    condition     = azurerm_container_registry.acr.location == "eastus2"
    error_message = "Container Registry must be deployed to eastus2"
  }
}
