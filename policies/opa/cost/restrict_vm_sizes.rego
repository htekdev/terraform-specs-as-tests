package cost.restrict_vm_sizes

import rego.v1

approved_vm_sizes := {
	"Standard_D2s_v5",
	"Standard_D4s_v5",
	"Standard_D8s_v5",
	"Standard_D16s_v5",
	"Standard_E4s_v5",
	"Standard_E8s_v5",
}

# AKS default_node_pool VM size
deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster"
	pool := rc.change.after.default_node_pool[_]
	vm_size := pool.vm_size
	not approved_vm_sizes[vm_size]

	msg := sprintf(
		"AKS cluster '%s' default_node_pool uses VM size '%s' which is not approved. Approved sizes: %s",
		[rc.address, vm_size, concat(", ", sort(approved_vm_sizes))],
	)
}

# Separate AKS node pool resources
deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "azurerm_kubernetes_cluster_node_pool"
	vm_size := rc.change.after.vm_size
	not approved_vm_sizes[vm_size]

	msg := sprintf(
		"AKS node pool '%s' uses VM size '%s' which is not approved. Approved sizes: %s",
		[rc.address, vm_size, concat(", ", sort(approved_vm_sizes))],
	)
}
