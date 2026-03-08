# Integration test: Monitoring module (real Azure deployment)
# Deploys Log Analytics workspace, validates configuration, auto-destroys.

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variables {
  test_id = "intmon"
}

run "setup_rg" {
  command = apply

  module {
    source = "./tests/integration/setup"
  }

  variables {
    test_id = var.test_id
  }
}

run "deploy_monitoring" {
  command = apply

  module {
    source = "./modules/monitoring"
  }

  variables {
    resource_group_name = run.setup_rg.resource_group_name
    location            = run.setup_rg.location
    environment         = "dev"
    project             = "lz"
    retention_in_days   = 30
    tags = {
      Environment = "dev"
      Owner       = "integration-tests"
      CostCenter  = "CC-TEST-001"
      ManagedBy   = "terraform"
      Project     = "lz"
    }
  }

  # Workspace deployed with correct name
  assert {
    condition     = output.workspace_name == "log-lz-dev-eastus2-001"
    error_message = "Expected workspace name 'log-lz-dev-eastus2-001', got '${output.workspace_name}'"
  }

  # Workspace ID is a valid Azure resource ID
  assert {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.OperationalInsights/workspaces/.+$", output.workspace_id))
    error_message = "Workspace ID is not a valid Azure resource ID"
  }
}
