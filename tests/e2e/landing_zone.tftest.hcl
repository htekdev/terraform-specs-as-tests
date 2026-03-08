# E2E test: Full Landing Zone deployment
# Deploys the entire root module (all 11 modules) and validates cross-module integration.
# WARNING: This test creates significant Azure resources and may take 20+ minutes.
# Auto-destroys all resources on completion.

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
  environment = "dev"
  location    = "eastus2"
  project     = "lz"
  owner       = "e2e-test"
  cost_center = "CC-TEST-001"
}

run "deploy_full_landing_zone" {
  command = apply

  variables {
    environment = var.environment
    location    = var.location
    project     = var.project
    owner       = var.owner
    cost_center = var.cost_center

    hub_vnet_address_space = ["10.0.0.0/16"]

    spoke_configs = {
      "workload-1" = {
        address_space = ["10.1.0.0/16"]
        subnets = {
          "default" = {
            address_prefix = "10.1.0.0/24"
          }
          "aks" = {
            address_prefix = "10.1.1.0/22"
          }
        }
      }
      "workload-2" = {
        address_space = ["10.2.0.0/16"]
        subnets = {
          "default" = {
            address_prefix = "10.2.0.0/24"
          }
          "endpoints" = {
            address_prefix = "10.2.1.0/24"
          }
        }
      }
    }

    aks_config = {
      kubernetes_version = "1.29"
      node_count         = 1
      min_count          = 1
      max_count          = 2
      vm_size            = "Standard_D2ds_v5"
      os_disk_size_gb    = 30
      max_pods           = 30
      network_plugin     = "azure"
      network_policy     = "calico"
      service_cidr       = "172.16.0.0/16"
      dns_service_ip     = "172.16.0.10"
    }
  }

  # Resource group created
  assert {
    condition     = output.resource_group_name == "rg-lz-dev-eastus2"
    error_message = "Resource group naming convention violated"
  }

  # Hub VNet created
  assert {
    condition     = can(regex("Microsoft.Network/virtualNetworks", output.hub_vnet_id))
    error_message = "Hub VNet should be a valid Azure resource"
  }

  # Monitoring workspace created
  assert {
    condition     = can(regex("Microsoft.OperationalInsights/workspaces", output.monitoring_workspace_id))
    error_message = "Monitoring workspace should be a valid Azure resource"
  }

  # Event Hub namespace created
  assert {
    condition     = output.eventhub_namespace_name == "evhns-lz-dev-eastus2-001"
    error_message = "Event Hub namespace naming convention violated"
  }

  # All DNS zones created (5 expected)
  assert {
    condition     = length(output.dns_zone_ids) == 5
    error_message = "Expected 5 private DNS zones"
  }
}
