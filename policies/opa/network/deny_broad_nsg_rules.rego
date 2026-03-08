package network.deny_broad_rules

import rego.v1

# Deny NSG rules that allow inbound traffic from overly broad
# sources: "*", "0.0.0.0/0", or "Internet".

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_network_security_rule"
	rc.change.actions[_] != "delete"
	rule := rc.change.after
	rule.access == "Allow"
	rule.direction == "Inbound"
	is_broad_source(rule.source_address_prefix)
	msg := sprintf(
		"NSG rule '%s' (%s) allows inbound traffic from '%s'. Broad inbound Allow rules are not permitted.",
		[rule.name, rc.address, rule.source_address_prefix],
	)
}

broad_sources := {"*", "0.0.0.0/0", "Internet"}

is_broad_source(prefix) if {
	prefix in broad_sources
}
