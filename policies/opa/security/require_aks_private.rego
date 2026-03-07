package security.require_aks_private

import rego.v1

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster"
	rc.change.actions[_] != "delete"

	not rc.change.after.private_cluster_enabled == true

	msg := sprintf("AKS cluster '%s' must have private_cluster_enabled set to true", [rc.address])
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster"
	rc.change.actions[_] != "delete"

	not has_api_server_restrictions(rc)

	msg := sprintf("AKS cluster '%s' must have api_server_access_profile with authorized_ip_ranges or vnet_integration_enabled", [rc.address])
}

has_api_server_restrictions(rc) if {
	profile := rc.change.after.api_server_access_profile[_]
	count(profile.authorized_ip_ranges) > 0
}

has_api_server_restrictions(rc) if {
	profile := rc.change.after.api_server_access_profile[_]
	profile.vnet_integration_enabled == true
}
