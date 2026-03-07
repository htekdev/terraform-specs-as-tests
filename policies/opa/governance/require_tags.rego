package governance.require_tags

import rego.v1

required_tags := {
	"Environment",
	"Owner",
	"CostCenter",
	"ManagedBy",
	"Project",
}

taggable_resource_types := {
	"azurerm_resource_group",
	"azurerm_virtual_network",
	"azurerm_subnet",
	"azurerm_key_vault",
	"azurerm_kubernetes_cluster",
	"azurerm_container_registry",
	"azurerm_storage_account",
	"azurerm_log_analytics_workspace",
	"azurerm_public_ip",
}

deny contains msg if {
	rc := input.resource_changes[_]
	taggable_resource_types[rc.type]
	tags := object.get(rc.change.after, "tags", {})
	tags != null
	missing := required_tags - {key | tags[key]}
	count(missing) > 0
	msg := sprintf(
		"Resource '%s' (%s) is missing required tags: %s",
		[rc.address, rc.type, concat(", ", sort(missing))],
	)
}

deny contains msg if {
	rc := input.resource_changes[_]
	taggable_resource_types[rc.type]
	tags := object.get(rc.change.after, "tags", null)
	tags == null
	msg := sprintf(
		"Resource '%s' (%s) has no tags defined. Required tags: %s",
		[rc.address, rc.type, concat(", ", sort(required_tags))],
	)
}
