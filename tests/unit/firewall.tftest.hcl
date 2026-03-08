# Firewall Module — Unit Tests
# Validates the firewall module produces an Azure Firewall with Standard tier,
# a public IP, a firewall policy, and diagnostic settings.

mock_provider "azurerm" {}

variables {
  resource_group_name        = "rg-lz-dev-eastus2"
  location                   = "eastus2"
  environment                = "dev"
  project                    = "lz"
  subnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/AzureFirewallSubnet"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "firewall_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall.fw.name != ""
    error_message = "Firewall name must not be empty"
  }

  assert {
    condition     = azurerm_firewall.fw.sku_tier == "Standard"
    error_message = "Firewall must use Standard tier (checked at output validation)"
  }
}

run "firewall_uses_standard_tier" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall.fw.sku_tier == "Standard"
    error_message = "Firewall must use Standard SKU tier"
  }

  assert {
    condition     = azurerm_firewall.fw.sku_name == "AZFW_VNet"
    error_message = "Firewall must use AZFW_VNet SKU name for VNet-based deployment"
  }

  assert {
    condition     = azurerm_firewall.fw.threat_intel_mode == "Deny"
    error_message = "Firewall must use Deny threat intelligence mode (CKV_AZURE_216)"
  }
}

run "firewall_creates_public_ip" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_public_ip.fw.allocation_method == "Static"
    error_message = "Firewall public IP must use Static allocation"
  }

  assert {
    condition     = azurerm_public_ip.fw.sku == "Standard"
    error_message = "Firewall public IP must use Standard SKU"
  }
}

run "firewall_creates_policy" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall_policy.policy.sku == "Standard"
    error_message = "Firewall policy must use Standard SKU to match firewall tier"
  }
}

run "firewall_has_diagnostic_settings" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.fw.name != ""
    error_message = "Diagnostic setting must have a name"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.fw.log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
    error_message = "Diagnostic setting must log to the provided Log Analytics workspace"
  }
}

run "firewall_tags_are_applied" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall.fw.tags["Environment"] == "dev"
    error_message = "Firewall must carry the Environment tag"
  }

  assert {
    condition     = azurerm_firewall.fw.tags["ManagedBy"] == "terraform"
    error_message = "Firewall must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_firewall.fw.tags["Project"] == "lz"
    error_message = "Firewall must carry the Project tag"
  }
}

run "firewall_uses_correct_location" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall.fw.location == "eastus2"
    error_message = "Firewall must be deployed to eastus2"
  }
}

run "firewall_is_associated_with_subnet" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall.fw.ip_configuration[0].subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/AzureFirewallSubnet"
    error_message = "Firewall must be associated with the AzureFirewallSubnet"
  }
}

run "firewall_has_rule_collection_group" {
  command = plan

  module {
    source = "./modules/firewall"
  }

  assert {
    condition     = azurerm_firewall_policy_rule_collection_group.default.priority == 1000
    error_message = "Firewall must have a default rule collection group with priority 1000"
  }

  assert {
    condition     = azurerm_firewall_policy_rule_collection_group.default.name != ""
    error_message = "Firewall rule collection group must have a name"
  }
}
