# Hub Network Module — Unit Tests
# Validates the hub-network module produces the correct hub VNet topology
# with AzureFirewallSubnet, GatewaySubnet, and management subnet.

mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
      guid = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }
  mock_resource "azurerm_subnet_network_security_group_association" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }
}

variables {
  resource_group_name = "rg-lz-dev-eastus2"
  location            = "eastus2"
  environment         = "dev"
  project             = "lz"
  address_space       = ["10.0.0.0/16"]
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "hub_vnet_outputs_are_populated" {
  command = apply

  module {
    source = "./modules/hub-network"
  }

  assert {
    condition     = output.vnet_id != ""
    error_message = "Hub VNet ID output must not be empty"
  }

  assert {
    condition     = output.vnet_name != ""
    error_message = "Hub VNet name output must not be empty"
  }

  assert {
    condition     = output.firewall_subnet_id != ""
    error_message = "Firewall subnet ID output must not be empty"
  }

  assert {
    condition     = output.gateway_subnet_id != ""
    error_message = "Gateway subnet ID output must not be empty"
  }

  assert {
    condition     = output.management_subnet_id != ""
    error_message = "Management subnet ID output must not be empty"
  }
}

run "hub_vnet_uses_provided_address_space" {
  command = plan

  module {
    source = "./modules/hub-network"
  }

  assert {
    condition     = contains(azurerm_virtual_network.hub.address_space, "10.0.0.0/16")
    error_message = "Hub VNet must use the provided address space 10.0.0.0/16"
  }
}

run "hub_vnet_creates_required_subnets" {
  command = plan

  module {
    source = "./modules/hub-network"
  }

  assert {
    condition     = azurerm_subnet.firewall.name == "AzureFirewallSubnet"
    error_message = "Hub VNet must contain a subnet named AzureFirewallSubnet"
  }

  assert {
    condition     = azurerm_subnet.gateway.name == "GatewaySubnet"
    error_message = "Hub VNet must contain a subnet named GatewaySubnet"
  }

  assert {
    condition     = azurerm_subnet.management.name == "management"
    error_message = "Hub VNet must contain a subnet named management"
  }
}

run "hub_vnet_tags_are_applied" {
  command = plan

  module {
    source = "./modules/hub-network"
  }

  assert {
    condition     = azurerm_virtual_network.hub.tags["Environment"] == "dev"
    error_message = "Hub VNet must carry the Environment tag"
  }

  assert {
    condition     = azurerm_virtual_network.hub.tags["ManagedBy"] == "terraform"
    error_message = "Hub VNet must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_virtual_network.hub.tags["Project"] == "lz"
    error_message = "Hub VNet must carry the Project tag"
  }
}

run "hub_vnet_uses_correct_location" {
  command = plan

  module {
    source = "./modules/hub-network"
  }

  assert {
    condition     = azurerm_virtual_network.hub.location == "eastus2"
    error_message = "Hub VNet must be deployed to eastus2"
  }
}

run "hub_vnet_custom_address_space" {
  command = plan

  module {
    source = "./modules/hub-network"
  }

  variables {
    address_space = ["10.100.0.0/16"]
  }

  assert {
    condition     = contains(azurerm_virtual_network.hub.address_space, "10.100.0.0/16")
    error_message = "Hub VNet must respect overridden address space"
  }
}
