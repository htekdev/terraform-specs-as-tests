# Key Vault Module — Unit Tests
# Validates the key-vault module enforces enterprise security requirements:
# purge protection, soft delete, no public access, and private endpoints.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-lz-dev-eastus2"
  location            = "eastus2"
  environment         = "dev"
  project             = "lz"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-services"
  private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "key_vault_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = output.vault_name != ""
    error_message = "Key Vault name output must not be empty"
  }

  assert {
    condition     = azurerm_key_vault.kv.purge_protection_enabled == true
    error_message = "Key Vault must have purge protection (checked at output validation)"
  }
}

run "key_vault_has_purge_protection_enabled" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.kv.purge_protection_enabled == true
    error_message = "Key Vault must have purge protection enabled (CKV_LZ_003)"
  }
}

run "key_vault_has_adequate_soft_delete_retention" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.kv.soft_delete_retention_days >= 7
    error_message = "Key Vault soft delete retention must be at least 7 days"
  }
}

run "key_vault_denies_public_access" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.kv.public_network_access_enabled == false
    error_message = "Key Vault must deny public network access"
  }
}

run "key_vault_has_private_endpoint" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_private_endpoint.kv.subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-services"
    error_message = "Key Vault private endpoint must be in the provided subnet"
  }
}

run "key_vault_tags_are_applied" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.kv.tags["Environment"] == "dev"
    error_message = "Key Vault must carry the Environment tag"
  }

  assert {
    condition     = azurerm_key_vault.kv.tags["ManagedBy"] == "terraform"
    error_message = "Key Vault must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_key_vault.kv.tags["Project"] == "lz"
    error_message = "Key Vault must carry the Project tag"
  }
}

run "key_vault_uses_correct_location" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.kv.location == "eastus2"
    error_message = "Key Vault must be deployed to eastus2"
  }
}

run "key_vault_default_retention_is_90_days" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.kv.soft_delete_retention_days == 90
    error_message = "Key Vault soft delete retention must default to 90 days"
  }
}
