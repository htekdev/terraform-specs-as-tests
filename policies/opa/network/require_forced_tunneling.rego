package network.forced_tunneling

import rego.v1

# All azurerm_route_table resources in spoke VNets must contain a
# default route (0.0.0.0/0) with next_hop_type "VirtualAppliance"
# to force traffic through the hub firewall.

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_route_table"
	rc.change.actions[_] != "delete"
	not is_hub_route_table(rc)
	not has_default_route_to_firewall(rc)
	msg := sprintf(
		"Route table '%s' (%s) must include a default route (0.0.0.0/0) with next_hop_type 'VirtualAppliance' for forced tunneling through the hub firewall.",
		[rc.change.after.name, rc.address],
	)
}

is_hub_route_table(rc) if {
	contains(lower(rc.address), "hub")
}

is_hub_route_table(rc) if {
	contains(lower(rc.change.after.name), "hub")
}

has_default_route_to_firewall(rc) if {
	route := rc.change.after.route[_]
	route.address_prefix == "0.0.0.0/0"
	route.next_hop_type == "VirtualAppliance"
}
