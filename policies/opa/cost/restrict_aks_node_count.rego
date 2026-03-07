package cost.restrict_aks_node_count

import rego.v1

max_allowed_nodes := 10

min_allowed_nodes := 1

# AKS default_node_pool max_count must not exceed limit
deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster"
	pool := rc.change.after.default_node_pool[_]
	pool.max_count > max_allowed_nodes

	msg := sprintf(
		"AKS cluster '%s' default_node_pool max_count is %d, which exceeds the maximum allowed (%d)",
		[rc.address, pool.max_count, max_allowed_nodes],
	)
}

# AKS default_node_pool min_count must be at least minimum
deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster"
	pool := rc.change.after.default_node_pool[_]
	pool.min_count < min_allowed_nodes

	msg := sprintf(
		"AKS cluster '%s' default_node_pool min_count is %d, which is below the minimum allowed (%d)",
		[rc.address, pool.min_count, min_allowed_nodes],
	)
}

# Separate AKS node pool max_count must not exceed limit
deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster_node_pool"
	rc.change.after.max_count > max_allowed_nodes

	msg := sprintf(
		"AKS node pool '%s' max_count is %d, which exceeds the maximum allowed (%d)",
		[rc.address, rc.change.after.max_count, max_allowed_nodes],
	)
}

# Separate AKS node pool min_count must be at least minimum
deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster_node_pool"
	rc.change.after.min_count < min_allowed_nodes

	msg := sprintf(
		"AKS node pool '%s' min_count is %d, which is below the minimum allowed (%d)",
		[rc.address, rc.change.after.min_count, min_allowed_nodes],
	)
}
