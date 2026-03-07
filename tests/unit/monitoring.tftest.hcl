# Monitoring Module — Unit Tests
# Validates the monitoring module creates a Log Analytics workspace
# with PerGB2018 SKU and adequate retention.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-lz-dev-eastus2"
  location            = "eastus2"
  environment         = "dev"
  project             = "lz"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "monitoring_outputs_are_populated" {
  command = apply

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = output.workspace_id != ""
    error_message = "Log Analytics workspace ID output must not be empty"
  }

  assert {
    condition     = output.workspace_name != ""
    error_message = "Log Analytics workspace name output must not be empty"
  }
}

run "monitoring_uses_pergb2018_sku" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.sku == "PerGB2018"
    error_message = "Log Analytics workspace must use PerGB2018 SKU"
  }
}

run "monitoring_has_adequate_retention" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.retention_in_days >= 30
    error_message = "Log Analytics workspace retention must be at least 30 days"
  }
}

run "monitoring_tags_are_applied" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.tags["Environment"] == "dev"
    error_message = "Log Analytics workspace must carry the Environment tag"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.tags["ManagedBy"] == "terraform"
    error_message = "Log Analytics workspace must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.tags["Project"] == "lz"
    error_message = "Log Analytics workspace must carry the Project tag"
  }
}

run "monitoring_uses_correct_location" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.location == "eastus2"
    error_message = "Log Analytics workspace must be deployed to eastus2"
  }
}

run "monitoring_default_retention_is_30_days" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.law.retention_in_days == 30
    error_message = "Log Analytics workspace retention must default to 30 days"
  }
}
