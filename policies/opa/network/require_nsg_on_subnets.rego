package network.require_nsg

# Every azurerm_subnet must have a network_security_group_id set.
# AzureFirewallSubnet and GatewaySubnet are exempt because Azure
# does not allow NSGs on those special-purpose subnets.

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_subnet"
	rc.change.actions[_] != "delete"
	subnet_name := rc.change.after.name
	not is_exempt_subnet(subnet_name)
	not has_nsg(rc)
	msg := sprintf(
		"Subnet '%s' (%s) must have a network_security_group_id assigned.",
		[subnet_name, rc.address],
	)
}

is_exempt_subnet(name) if {
	name == "AzureFirewallSubnet"
}

is_exempt_subnet(name) if {
	name == "GatewaySubnet"
}

has_nsg(rc) if {
	rc.change.after.network_security_group_id != null
	rc.change.after.network_security_group_id != ""
}
