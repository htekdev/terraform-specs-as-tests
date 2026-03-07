package security.deny_acr_admin

import rego.v1

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_container_registry"
	rc.change.actions[_] != "delete"

	rc.change.after.admin_enabled == true

	msg := sprintf("Container Registry '%s' must not have admin_enabled set to true (use managed identity or service principal instead)", [rc.address])
}
