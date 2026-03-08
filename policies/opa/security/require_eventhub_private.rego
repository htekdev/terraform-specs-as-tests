package security.require_eventhub_private

import rego.v1

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_eventhub_namespace"
	rc.change.actions[_] != "delete"

	not rc.change.after.public_network_access_enabled == false

	msg := sprintf("Event Hub namespace '%s' must have public_network_access_enabled set to false", [rc.address])
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_eventhub_namespace"
	rc.change.actions[_] != "delete"

	tls_version := object.get(rc.change.after, "minimum_tls_version", "")
	not tls_version == "1.2"

	msg := sprintf("Event Hub namespace '%s' must have minimum_tls_version set to '1.2'", [rc.address])
}
