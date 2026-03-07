package security.require_keyvault_protection

import rego.v1

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_key_vault"
	rc.change.actions[_] != "delete"

	days := object.get(rc.change.after, "soft_delete_retention_days", 0)
	days < 7

	msg := sprintf("Key Vault '%s' must have soft_delete_retention_days >= 7 (found %d)", [rc.address, days])
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_key_vault"
	rc.change.actions[_] != "delete"

	not rc.change.after.purge_protection_enabled == true

	msg := sprintf("Key Vault '%s' must have purge_protection_enabled set to true", [rc.address])
}
