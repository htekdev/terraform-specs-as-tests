# Spoke Network Module — Unit Tests
# Validates the spoke-network module produces VNets peered to hub
# with route tables forcing traffic through the firewall.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-spoke-dev-eastus2"
  location            = "eastus2"
  environment         = "dev"
  project             = "lz"
  name                = "workload-1"
  address_space       = ["10.1.0.0/16"]
  subnets = {
    aks-nodes = {
      address_prefix = "10.1.1.0/24"
    }
    aks-services = {
      address_prefix = "10.1.2.0/24"
    }
  }
  hub_vnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
  hub_vnet_name       = "vnet-hub"
  firewall_private_ip = "10.0.1.4"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "spoke_vnet_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = output.vnet_name != ""
    error_message = "Spoke VNet name output must not be empty"
  }

  assert {
    condition     = azurerm_virtual_network.spoke.name != ""
    error_message = "Spoke VNet resource name must not be empty"
  }
}

run "spoke_vnet_uses_provided_address_space" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = contains(azurerm_virtual_network.spoke.address_space, "10.1.0.0/16")
    error_message = "Spoke VNet must use the provided address space 10.1.0.0/16"
  }
}

run "spoke_creates_peering_to_hub" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = azurerm_virtual_network_peering.spoke_to_hub.remote_virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    error_message = "Spoke must peer to the hub VNet"
  }

  assert {
    condition     = azurerm_virtual_network_peering.spoke_to_hub.allow_forwarded_traffic == true
    error_message = "Spoke-to-hub peering must allow forwarded traffic"
  }

  assert {
    condition     = azurerm_virtual_network_peering.spoke_to_hub.allow_gateway_transit == false
    error_message = "Spoke-to-hub peering must not allow gateway transit from spoke side"
  }

  assert {
    condition     = azurerm_virtual_network_peering.spoke_to_hub.use_remote_gateways == false
    error_message = "Spoke should not use remote gateways by default"
  }
}

run "spoke_creates_route_table_with_default_route" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = azurerm_route.default.address_prefix == "0.0.0.0/0"
    error_message = "Default route must have address prefix 0.0.0.0/0"
  }

  assert {
    condition     = azurerm_route.default.next_hop_type == "VirtualAppliance"
    error_message = "Default route must use VirtualAppliance as next hop type"
  }

  assert {
    condition     = azurerm_route.default.next_hop_in_ip_address == "10.0.1.4"
    error_message = "Default route must point to the firewall private IP 10.0.1.4"
  }
}

run "spoke_vnet_tags_are_applied" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = azurerm_virtual_network.spoke.tags["Environment"] == "dev"
    error_message = "Spoke VNet must carry the Environment tag"
  }

  assert {
    condition     = azurerm_virtual_network.spoke.tags["ManagedBy"] == "terraform"
    error_message = "Spoke VNet must carry the ManagedBy tag"
  }
}

run "spoke_vnet_uses_correct_location" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = azurerm_virtual_network.spoke.location == "eastus2"
    error_message = "Spoke VNet must be deployed to eastus2"
  }
}

run "spoke_creates_nsg_per_subnet" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = azurerm_network_security_group.subnets["aks-nodes"].name != ""
    error_message = "Each spoke subnet must have a dedicated NSG"
  }

  assert {
    condition     = azurerm_network_security_group.subnets["aks-nodes"].location == "eastus2"
    error_message = "NSGs must be deployed to the same location as the spoke VNet"
  }

  assert {
    condition     = azurerm_network_security_group.subnets["aks-nodes"].tags["ManagedBy"] == "terraform"
    error_message = "NSGs must carry the ManagedBy tag"
  }
}

run "spoke_associates_nsg_with_subnet" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  # Association resources have only computed attributes (subnet_id, nsg_id).
  # With mock providers, verifying the resource appears in the plan is sufficient
  # to prove the association is declared.
  assert {
    condition     = azurerm_subnet_network_security_group_association.subnets != null
    error_message = "Each subnet must have an NSG association declared"
  }
}

run "spoke_associates_route_table_with_subnet" {
  command = plan

  module {
    source = "./modules/spoke-network"
  }

  assert {
    condition     = azurerm_subnet_route_table_association.subnets != null
    error_message = "Each subnet must have a route table association for forced tunneling"
  }
}
