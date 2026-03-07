package network_test

import data.network.deny_public_ip
import data.network.require_nsg
import data.network.hub_spoke
import data.network.forced_tunneling
import data.network.deny_broad_rules

# ---------------------------------------------------------------------------
# deny_public_ip tests
# ---------------------------------------------------------------------------

test_deny_public_ip_non_firewall if {
	inp := {"resource_changes": [{
		"type": "azurerm_public_ip",
		"address": "module.spoke.azurerm_public_ip.web",
		"change": {
			"actions": ["create"],
			"after": {"name": "pip-web-eastus"},
		},
	}]}
	result := deny_public_ip.deny with input as inp
	count(result) > 0
}

test_allow_public_ip_firewall_fw if {
	inp := {"resource_changes": [{
		"type": "azurerm_public_ip",
		"address": "module.hub.azurerm_public_ip.fw",
		"change": {
			"actions": ["create"],
			"after": {"name": "pip-fw-eastus"},
		},
	}]}
	result := deny_public_ip.deny with input as inp
	count(result) == 0
}

test_allow_public_ip_firewall_full_name if {
	inp := {"resource_changes": [{
		"type": "azurerm_public_ip",
		"address": "module.hub.azurerm_public_ip.firewall",
		"change": {
			"actions": ["create"],
			"after": {"name": "pip-firewall-eastus"},
		},
	}]}
	result := deny_public_ip.deny with input as inp
	count(result) == 0
}

# ---------------------------------------------------------------------------
# require_nsg tests
# ---------------------------------------------------------------------------

test_deny_subnet_without_nsg if {
	inp := {"resource_changes": [{
		"type": "azurerm_subnet",
		"address": "module.spoke.azurerm_subnet.app",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "snet-app",
				"network_security_group_id": null,
			},
		},
	}]}
	result := require_nsg.deny with input as inp
	count(result) > 0
}

test_allow_subnet_with_nsg if {
	inp := {"resource_changes": [{
		"type": "azurerm_subnet",
		"address": "module.spoke.azurerm_subnet.app",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "snet-app",
				"network_security_group_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/networkSecurityGroups/nsg-app",
			},
		},
	}]}
	result := require_nsg.deny with input as inp
	count(result) == 0
}

test_allow_firewall_subnet_without_nsg if {
	inp := {"resource_changes": [{
		"type": "azurerm_subnet",
		"address": "module.hub.azurerm_subnet.fw",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "AzureFirewallSubnet",
				"network_security_group_id": null,
			},
		},
	}]}
	result := require_nsg.deny with input as inp
	count(result) == 0
}

test_allow_gateway_subnet_without_nsg if {
	inp := {"resource_changes": [{
		"type": "azurerm_subnet",
		"address": "module.hub.azurerm_subnet.gw",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "GatewaySubnet",
				"network_security_group_id": null,
			},
		},
	}]}
	result := require_nsg.deny with input as inp
	count(result) == 0
}

# ---------------------------------------------------------------------------
# hub_spoke peering tests
# ---------------------------------------------------------------------------

test_deny_spoke_to_spoke_peering if {
	inp := {"resource_changes": [{
		"type": "azurerm_virtual_network_peering",
		"address": "module.spoke1.azurerm_virtual_network_peering.to_spoke2",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "spoke1-to-spoke2",
				"remote_virtual_network_id": "/subscriptions/00000000/resourceGroups/rg-spoke2/providers/Microsoft.Network/virtualNetworks/vnet-spoke2",
			},
		},
	}]}
	result := hub_spoke.deny with input as inp
	count(result) > 0
}

test_allow_spoke_to_hub_peering_by_name if {
	inp := {"resource_changes": [{
		"type": "azurerm_virtual_network_peering",
		"address": "module.spoke1.azurerm_virtual_network_peering.to_hub",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "spoke1-to-hub",
				"remote_virtual_network_id": "/subscriptions/00000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub",
			},
		},
	}]}
	result := hub_spoke.deny with input as inp
	count(result) == 0
}

test_allow_spoke_to_hub_peering_by_remote_id if {
	inp := {"resource_changes": [{
		"type": "azurerm_virtual_network_peering",
		"address": "module.spoke1.azurerm_virtual_network_peering.peer",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "spoke1-peer",
				"remote_virtual_network_id": "/subscriptions/00000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-hub-eastus",
			},
		},
	}]}
	result := hub_spoke.deny with input as inp
	count(result) == 0
}

# ---------------------------------------------------------------------------
# forced_tunneling tests
# ---------------------------------------------------------------------------

test_deny_route_table_without_default_route if {
	inp := {"resource_changes": [{
		"type": "azurerm_route_table",
		"address": "module.spoke.azurerm_route_table.main",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "rt-spoke-eastus",
				"route": [{
					"address_prefix": "10.1.0.0/16",
					"next_hop_type": "VnetLocal",
				}],
			},
		},
	}]}
	result := forced_tunneling.deny with input as inp
	count(result) > 0
}

test_allow_route_table_with_forced_tunneling if {
	inp := {"resource_changes": [{
		"type": "azurerm_route_table",
		"address": "module.spoke.azurerm_route_table.main",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "rt-spoke-eastus",
				"route": [
					{
						"address_prefix": "10.1.0.0/16",
						"next_hop_type": "VnetLocal",
					},
					{
						"address_prefix": "0.0.0.0/0",
						"next_hop_type": "VirtualAppliance",
					},
				],
			},
		},
	}]}
	result := forced_tunneling.deny with input as inp
	count(result) == 0
}

test_allow_hub_route_table_without_forced_tunneling if {
	inp := {"resource_changes": [{
		"type": "azurerm_route_table",
		"address": "module.hub.azurerm_route_table.main",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "rt-hub-eastus",
				"route": [{
					"address_prefix": "10.0.0.0/8",
					"next_hop_type": "VnetLocal",
				}],
			},
		},
	}]}
	result := forced_tunneling.deny with input as inp
	count(result) == 0
}

# ---------------------------------------------------------------------------
# deny_broad_rules tests
# ---------------------------------------------------------------------------

test_deny_nsg_rule_allow_star_inbound if {
	inp := {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"address": "module.spoke.azurerm_network_security_rule.allow_all",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "AllowAllInbound",
				"access": "Allow",
				"direction": "Inbound",
				"source_address_prefix": "*",
			},
		},
	}]}
	result := deny_broad_rules.deny with input as inp
	count(result) > 0
}

test_deny_nsg_rule_allow_internet_inbound if {
	inp := {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"address": "module.spoke.azurerm_network_security_rule.allow_internet",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "AllowInternetInbound",
				"access": "Allow",
				"direction": "Inbound",
				"source_address_prefix": "Internet",
			},
		},
	}]}
	result := deny_broad_rules.deny with input as inp
	count(result) > 0
}

test_deny_nsg_rule_allow_cidr_any_inbound if {
	inp := {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"address": "module.spoke.azurerm_network_security_rule.allow_any",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "AllowAnyCidrInbound",
				"access": "Allow",
				"direction": "Inbound",
				"source_address_prefix": "0.0.0.0/0",
			},
		},
	}]}
	result := deny_broad_rules.deny with input as inp
	count(result) > 0
}

test_allow_nsg_rule_specific_source if {
	inp := {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"address": "module.spoke.azurerm_network_security_rule.allow_vnet",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "AllowVNetInbound",
				"access": "Allow",
				"direction": "Inbound",
				"source_address_prefix": "10.1.0.0/16",
			},
		},
	}]}
	result := deny_broad_rules.deny with input as inp
	count(result) == 0
}

test_allow_nsg_rule_broad_outbound if {
	inp := {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"address": "module.spoke.azurerm_network_security_rule.allow_out",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "AllowAllOutbound",
				"access": "Allow",
				"direction": "Outbound",
				"source_address_prefix": "*",
			},
		},
	}]}
	result := deny_broad_rules.deny with input as inp
	count(result) == 0
}

test_allow_nsg_rule_deny_star_inbound if {
	inp := {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"address": "module.spoke.azurerm_network_security_rule.deny_all",
		"change": {
			"actions": ["create"],
			"after": {
				"name": "DenyAllInbound",
				"access": "Deny",
				"direction": "Inbound",
				"source_address_prefix": "*",
			},
		},
	}]}
	result := deny_broad_rules.deny with input as inp
	count(result) == 0
}
