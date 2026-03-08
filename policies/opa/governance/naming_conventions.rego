package governance.naming_conventions

import rego.v1

# Azure CAF naming pattern: {type_prefix}-{project}-{environment}-{region}-{instance}
# Instance portion is flexible (alphanumeric, optional).

type_prefixes := {
	"azurerm_virtual_network": "vnet",
	"azurerm_subnet": "snet",
	"azurerm_network_security_group": "nsg",
	"azurerm_firewall": "fw",
	"azurerm_public_ip": "pip",
	"azurerm_key_vault": "kv",
	"azurerm_kubernetes_cluster": "aks",
	"azurerm_container_registry": "acr",
	"azurerm_storage_account": "st",
	"azurerm_log_analytics_workspace": "log",
	"azurerm_resource_group": "rg",
	"azurerm_private_endpoint": "pe",
	"azurerm_private_dns_zone": "pdn",
	"azurerm_eventhub_namespace": "evhns",
}

# Pattern: {prefix}-{project}-{env}-{region} with optional -{instance} suffix.
# Project, env, region are one or more lowercase alphanumeric/hyphen segments.
naming_pattern(prefix) := pattern if {
	pattern := sprintf(`^%s-[a-z0-9]+-[a-z0-9]+-[a-z0-9]+(-[a-z0-9]+)?$`, [prefix])
}

# Storage accounts have special rules (no hyphens, 3-24 chars, lowercase alphanumeric only).
storage_pattern := `^st[a-z0-9]{2,22}$`

# Container registries also have no hyphens.
acr_pattern := `^acr[a-z0-9]+$`

deny contains msg if {
	rc := input.resource_changes[_]
	prefix := type_prefixes[rc.type]
	name := rc.change.after.name

	rc.type != "azurerm_storage_account"
	rc.type != "azurerm_container_registry"

	pattern := naming_pattern(prefix)
	not regex.match(pattern, name)

	msg := sprintf(
		"Resource '%s' (%s) name '%s' does not follow CAF naming convention. Expected pattern: %s-<project>-<environment>-<region>[-<instance>]",
		[rc.address, rc.type, name, prefix],
	)
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_storage_account"
	name := rc.change.after.name
	not regex.match(storage_pattern, name)

	msg := sprintf(
		"Storage account '%s' name '%s' does not follow CAF naming convention. Expected pattern: st<project><env><region>[<instance>] (lowercase alphanumeric, no hyphens, 3-24 chars)",
		[rc.address, name],
	)
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_container_registry"
	name := rc.change.after.name
	not regex.match(acr_pattern, name)

	msg := sprintf(
		"Container registry '%s' name '%s' does not follow CAF naming convention. Expected pattern: acr<project><env><region>[<instance>] (lowercase alphanumeric, no hyphens)",
		[rc.address, name],
	)
}
