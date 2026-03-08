package network.deny_public_ip

import rego.v1

# Deny azurerm_public_ip resources unless allocated for Azure Firewall.
# Firewall public IPs are identified by names containing "fw" or "firewall".

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_public_ip"
	rc.change.actions[_] != "delete"
	name := rc.change.after.name
	not is_firewall_pip(name)
	msg := sprintf(
		"Public IP '%s' (%s) is not permitted. Only Azure Firewall public IPs (name must contain 'fw' or 'firewall') are allowed.",
		[name, rc.address],
	)
}

is_firewall_pip(name) if {
	contains(lower(name), "fw")
}

is_firewall_pip(name) if {
	contains(lower(name), "firewall")
}
