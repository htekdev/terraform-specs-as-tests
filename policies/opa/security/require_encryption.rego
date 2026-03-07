package security.require_encryption

import rego.v1

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_storage_account"
	rc.change.actions[_] != "delete"

	not object.get(rc.change.after, "infrastructure_encryption_enabled", false)

	msg := sprintf("Storage account '%s' must have infrastructure_encryption_enabled set to true", [rc.address])
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_key_vault"
	rc.change.actions[_] != "delete"

	not has_keyvault_encryption(rc)

	msg := sprintf("Key Vault '%s' must not disable encryption (enable_rbac_authorization or default service-managed encryption required)", [rc.address])
}

has_keyvault_encryption(rc) if {
	not rc.change.after.purge_protection_enabled == false
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster"
	rc.change.actions[_] != "delete"

	rc.change.after.disk_encryption_set_id == null

	msg := sprintf("AKS cluster '%s' must have disk_encryption_set_id configured for disk encryption", [rc.address])
}
