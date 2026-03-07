package security.require_private_endpoints

import rego.v1

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_storage_account"
	rc.change.actions[_] != "delete"

	not storage_network_restricted(rc)

	msg := sprintf("Storage account '%s' must disable public network access (set public_network_access_enabled = false or network_rules.default_action = \"Deny\")", [rc.address])
}

storage_network_restricted(rc) if {
	rc.change.after.public_network_access_enabled == false
}

storage_network_restricted(rc) if {
	rules := rc.change.after.network_rules[_]
	rules.default_action == "Deny"
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_key_vault"
	rc.change.actions[_] != "delete"

	not rc.change.after.public_network_access_enabled == false

	msg := sprintf("Key Vault '%s' must have public_network_access_enabled set to false", [rc.address])
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_container_registry"
	rc.change.actions[_] != "delete"

	not rc.change.after.public_network_access_enabled == false

	msg := sprintf("Container Registry '%s' must have public_network_access_enabled set to false", [rc.address])
}
