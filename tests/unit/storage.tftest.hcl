# Storage Module — Unit Tests
# Validates the storage module enforces TLS 1.2, denies public access,
# enables blob versioning, and creates a private endpoint.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-lz-dev-eastus2"
  location            = "eastus2"
  environment         = "dev"
  project             = "lz"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-services"
  private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "storage_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.name != ""
    error_message = "Storage account name must not be empty"
  }

  assert {
    condition     = azurerm_storage_account.storage.account_tier == "Standard"
    error_message = "Storage account must use Standard tier (checked at output validation)"
  }
}

run "storage_enforces_tls_1_2" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.min_tls_version == "TLS1_2"
    error_message = "Storage account must enforce minimum TLS version 1.2"
  }
}

run "storage_denies_public_access" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.public_network_access_enabled == false
    error_message = "Storage account must deny public network access"
  }
}

run "storage_has_blob_versioning_enabled" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.blob_properties[0].versioning_enabled == true
    error_message = "Storage account must have blob versioning enabled"
  }
}

run "storage_requires_https" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.https_traffic_only_enabled == true
    error_message = "Storage account must require HTTPS traffic only"
  }
}

run "storage_uses_standard_tier" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.account_tier == "Standard"
    error_message = "Storage account must use Standard tier"
  }
}

run "storage_has_private_endpoint" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_private_endpoint.storage.subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-services"
    error_message = "Storage private endpoint must be in the provided subnet"
  }
}

run "storage_has_blob_soft_delete" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.blob_properties[0].delete_retention_policy[0].days >= 7
    error_message = "Storage blob soft delete retention must be at least 7 days"
  }
}

run "storage_tags_are_applied" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.tags["Environment"] == "dev"
    error_message = "Storage account must carry the Environment tag"
  }

  assert {
    condition     = azurerm_storage_account.storage.tags["ManagedBy"] == "terraform"
    error_message = "Storage account must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_storage_account.storage.tags["Project"] == "lz"
    error_message = "Storage account must carry the Project tag"
  }
}

run "storage_uses_correct_location" {
  command = plan

  module {
    source = "./modules/storage"
  }

  assert {
    condition     = azurerm_storage_account.storage.location == "eastus2"
    error_message = "Storage account must be deployed to eastus2"
  }
}
