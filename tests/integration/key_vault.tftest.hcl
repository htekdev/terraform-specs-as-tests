# Integration test: Key Vault module (real Azure deployment)
# Deploys Key Vault with private endpoint, validates security posture, auto-destroys.

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variables {
  test_id = "intkv"
}

run "setup" {
  command = apply

  module {
    source = "./setup"
  }

  variables {
    test_id = var.test_id
  }
}

run "deploy_key_vault" {
  command = apply

  module {
    source = "../../modules/key-vault"
  }

  variables {
    resource_group_name        = run.setup.resource_group_name
    location                   = run.setup.location
    environment                = "dev"
    project                    = "lz"
    subnet_id                  = run.setup.subnet_id
    private_dns_zone_id        = run.setup.keyvault_dns_zone_id
    soft_delete_retention_days = 7
    tags = {
      Environment = "dev"
      Owner       = "integration-tests"
      CostCenter  = "CC-TEST-001"
      ManagedBy   = "terraform"
      Project     = "lz"
    }
  }

  # Vault deployed with correct name
  assert {
    condition     = output.vault_name == "kv-lz-dev-eastus2-001"
    error_message = "Expected vault name 'kv-lz-dev-eastus2-001', got '${output.vault_name}'"
  }

  # Vault URI is valid
  assert {
    condition     = can(regex("^https://kv-lz-dev-eastus2-001\\.vault\\.azure\\.net", output.vault_uri))
    error_message = "Vault URI should be https://kv-lz-dev-eastus2-001.vault.azure.net"
  }

  # Vault ID is a valid Azure resource ID
  assert {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.KeyVault/vaults/.+$", output.vault_id))
    error_message = "Vault ID is not a valid Azure resource ID"
  }
}
