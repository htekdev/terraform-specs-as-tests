package governance.allowed_regions

import rego.v1

allowed_locations := {"eastus2", "westus2"}

deny contains msg if {
	rc := input.resource_changes[_]
	location := rc.change.after.location
	location != null
	not allowed_locations[location]

	msg := sprintf(
		"Resource '%s' (%s) is deployed to '%s'. Only these regions are allowed: %s",
		[rc.address, rc.type, location, concat(", ", sort(allowed_locations))],
	)
}
