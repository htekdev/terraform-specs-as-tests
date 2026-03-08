# Integration test: DNS module (real Azure deployment)
# Deploys private DNS zones with VNet links, validates all zones exist, auto-destroys.

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variables {
  test_id = "intdns"
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

run "deploy_dns" {
  command = apply

  module {
    source = "../../modules/dns"
  }

  variables {
    resource_group_name = run.setup.resource_group_name
    location            = run.setup.location
    hub_vnet_id         = run.setup.vnet_id
    tags = {
      Environment = "dev"
      Owner       = "integration-tests"
      CostCenter  = "CC-TEST-001"
      ManagedBy   = "terraform"
      Project     = "lz"
    }
  }

  # All 5 DNS zones created — zone_ids map has correct keys
  assert {
    condition     = contains(keys(output.zone_ids), "kv")
    error_message = "DNS zone_ids should contain 'kv' key for Key Vault"
  }

  assert {
    condition     = contains(keys(output.zone_ids), "st")
    error_message = "DNS zone_ids should contain 'st' key for Storage"
  }

  assert {
    condition     = contains(keys(output.zone_ids), "acr")
    error_message = "DNS zone_ids should contain 'acr' key for Container Registry"
  }

  assert {
    condition     = contains(keys(output.zone_ids), "aks")
    error_message = "DNS zone_ids should contain 'aks' key for AKS"
  }

  assert {
    condition     = contains(keys(output.zone_ids), "evhns")
    error_message = "DNS zone_ids should contain 'evhns' key for Event Hub"
  }

  # Exactly 5 zones
  assert {
    condition     = length(output.zone_ids) == 5
    error_message = "Expected 5 DNS zones, got ${length(output.zone_ids)}"
  }

  # Zone IDs are valid Azure resource IDs
  assert {
    condition     = can(regex("Microsoft.Network/privateDnsZones", output.zone_ids["kv"]))
    error_message = "Key Vault DNS zone ID should be a valid Azure resource ID"
  }
}
