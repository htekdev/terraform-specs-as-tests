package governance_test

import rego.v1

import data.governance.allowed_regions
import data.governance.naming_conventions
import data.governance.require_tags

# ============================================================
# require_tags tests
# ============================================================

test_require_tags_all_present if {
	count(require_tags.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_resource_group.test",
		"type": "azurerm_resource_group",
		"change": {"after": {"tags": {
			"Environment": "dev",
			"Owner": "team-a",
			"CostCenter": "CC-1234",
			"ManagedBy": "terraform",
			"Project": "landing-zone",
		}}},
	}]}
}

test_require_tags_missing_some if {
	msgs := require_tags.deny with input as {"resource_changes": [{
		"address": "azurerm_virtual_network.test",
		"type": "azurerm_virtual_network",
		"change": {"after": {"tags": {
			"Environment": "dev",
			"Owner": "team-a",
		}}},
	}]}
	count(msgs) == 1
	msg := msgs[_]
	contains(msg, "CostCenter")
	contains(msg, "ManagedBy")
	contains(msg, "Project")
}

test_require_tags_null_tags if {
	msgs := require_tags.deny with input as {"resource_changes": [{
		"address": "azurerm_key_vault.test",
		"type": "azurerm_key_vault",
		"change": {"after": {"tags": null}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "has no tags defined")
}

test_require_tags_ignores_non_taggable if {
	count(require_tags.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_route_table.test",
		"type": "azurerm_route_table",
		"change": {"after": {"tags": {}}},
	}]}
}

test_require_tags_storage_account if {
	msgs := require_tags.deny with input as {"resource_changes": [{
		"address": "azurerm_storage_account.test",
		"type": "azurerm_storage_account",
		"change": {"after": {"tags": {"Environment": "prod"}}},
	}]}
	count(msgs) == 1
}

# ============================================================
# naming_conventions tests
# ============================================================

test_naming_valid_vnet if {
	count(naming_conventions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_virtual_network.main",
		"type": "azurerm_virtual_network",
		"change": {"after": {"name": "vnet-myproject-dev-eastus2"}},
	}]}
}

test_naming_valid_vnet_with_instance if {
	count(naming_conventions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_virtual_network.main",
		"type": "azurerm_virtual_network",
		"change": {"after": {"name": "vnet-myproject-dev-eastus2-001"}},
	}]}
}

test_naming_invalid_vnet if {
	msgs := naming_conventions.deny with input as {"resource_changes": [{
		"address": "azurerm_virtual_network.main",
		"type": "azurerm_virtual_network",
		"change": {"after": {"name": "my-bad-vnet-name"}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "does not follow CAF naming convention")
}

test_naming_valid_storage if {
	count(naming_conventions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_storage_account.main",
		"type": "azurerm_storage_account",
		"change": {"after": {"name": "stmyprojectdeveus2"}},
	}]}
}

test_naming_invalid_storage_with_hyphens if {
	msgs := naming_conventions.deny with input as {"resource_changes": [{
		"address": "azurerm_storage_account.main",
		"type": "azurerm_storage_account",
		"change": {"after": {"name": "st-my-project-dev"}},
	}]}
	count(msgs) == 1
}

test_naming_valid_acr if {
	count(naming_conventions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_container_registry.main",
		"type": "azurerm_container_registry",
		"change": {"after": {"name": "acrprojdeveus2"}},
	}]}
}

test_naming_invalid_acr_with_hyphens if {
	msgs := naming_conventions.deny with input as {"resource_changes": [{
		"address": "azurerm_container_registry.main",
		"type": "azurerm_container_registry",
		"change": {"after": {"name": "acr-proj-dev"}},
	}]}
	count(msgs) == 1
}

test_naming_valid_rg if {
	count(naming_conventions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_resource_group.main",
		"type": "azurerm_resource_group",
		"change": {"after": {"name": "rg-lz-prod-westus2"}},
	}]}
}

test_naming_ignores_unknown_type if {
	count(naming_conventions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_some_other_resource.main",
		"type": "azurerm_some_other_resource",
		"change": {"after": {"name": "whatever-name"}},
	}]}
}

# ============================================================
# allowed_regions tests
# ============================================================

test_region_allowed_eastus2 if {
	count(allowed_regions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_resource_group.test",
		"type": "azurerm_resource_group",
		"change": {"after": {"location": "eastus2"}},
	}]}
}

test_region_allowed_westus2 if {
	count(allowed_regions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_resource_group.test",
		"type": "azurerm_resource_group",
		"change": {"after": {"location": "westus2"}},
	}]}
}

test_region_denied_centralus if {
	msgs := allowed_regions.deny with input as {"resource_changes": [{
		"address": "azurerm_resource_group.test",
		"type": "azurerm_resource_group",
		"change": {"after": {"location": "centralus"}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "centralus")
}

test_region_denied_westeurope if {
	msgs := allowed_regions.deny with input as {"resource_changes": [{
		"address": "azurerm_virtual_network.test",
		"type": "azurerm_virtual_network",
		"change": {"after": {"location": "westeurope"}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "westeurope")
}

test_region_null_location_no_deny if {
	count(allowed_regions.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_subnet.test",
		"type": "azurerm_subnet",
		"change": {"after": {"location": null}},
	}]}
}
