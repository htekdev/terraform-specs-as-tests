package network.hub_spoke

import rego.v1

# Validate that VNet peerings only connect spokes to the hub.
# Spoke-to-spoke peering is denied. A peering is considered
# hub-bound when the peering name or remote_virtual_network_id
# contains "hub".

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_virtual_network_peering"
	rc.change.actions[_] != "delete"
	peering_name := rc.change.after.name
	remote_vnet_id := rc.change.after.remote_virtual_network_id
	not references_hub(peering_name, remote_vnet_id)
	msg := sprintf(
		"VNet peering '%s' (%s) does not reference the hub VNet. Spoke-to-spoke peering is not allowed; all peerings must connect to the hub.",
		[peering_name, rc.address],
	)
}

references_hub(peering_name, _) if {
	contains(lower(peering_name), "hub")
}

references_hub(_, remote_vnet_id) if {
	contains(lower(remote_vnet_id), "hub")
}
