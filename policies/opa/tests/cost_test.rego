package cost_test

import rego.v1

import data.cost.restrict_aks_node_count
import data.cost.restrict_vm_sizes

# ============================================================
# restrict_vm_sizes tests
# ============================================================

test_vm_size_approved_default_pool if {
	count(restrict_vm_sizes.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster.main",
		"type": "azurerm_kubernetes_cluster",
		"change": {"after": {"default_node_pool": [{"vm_size": "Standard_D4s_v5"}]}},
	}]}
}

test_vm_size_denied_default_pool if {
	msgs := restrict_vm_sizes.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster.main",
		"type": "azurerm_kubernetes_cluster",
		"change": {"after": {"default_node_pool": [{"vm_size": "Standard_D64s_v5"}]}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "Standard_D64s_v5")
	contains(msgs[_], "not approved")
}

test_vm_size_approved_node_pool_resource if {
	count(restrict_vm_sizes.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster_node_pool.gpu",
		"type": "azurerm_kubernetes_cluster_node_pool",
		"change": {"after": {"vm_size": "Standard_E8s_v5"}},
	}]}
}

test_vm_size_denied_node_pool_resource if {
	msgs := restrict_vm_sizes.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster_node_pool.gpu",
		"type": "azurerm_kubernetes_cluster_node_pool",
		"change": {"after": {"vm_size": "Standard_NC6s_v3"}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "Standard_NC6s_v3")
}

test_vm_size_all_approved_variants if {
	count(restrict_vm_sizes.deny) == 0 with input as {"resource_changes": [
		{
			"address": "azurerm_kubernetes_cluster_node_pool.a",
			"type": "azurerm_kubernetes_cluster_node_pool",
			"change": {"after": {"vm_size": "Standard_D2s_v5"}},
		},
		{
			"address": "azurerm_kubernetes_cluster_node_pool.b",
			"type": "azurerm_kubernetes_cluster_node_pool",
			"change": {"after": {"vm_size": "Standard_D8s_v5"}},
		},
		{
			"address": "azurerm_kubernetes_cluster_node_pool.c",
			"type": "azurerm_kubernetes_cluster_node_pool",
			"change": {"after": {"vm_size": "Standard_D16s_v5"}},
		},
		{
			"address": "azurerm_kubernetes_cluster_node_pool.d",
			"type": "azurerm_kubernetes_cluster_node_pool",
			"change": {"after": {"vm_size": "Standard_E4s_v5"}},
		},
	]}
}

# ============================================================
# restrict_aks_node_count tests
# ============================================================

test_node_count_within_limits if {
	count(restrict_aks_node_count.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster.main",
		"type": "azurerm_kubernetes_cluster",
		"change": {"after": {"default_node_pool": [{
			"min_count": 2,
			"max_count": 8,
		}]}},
	}]}
}

test_node_count_max_exceeded_default_pool if {
	msgs := restrict_aks_node_count.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster.main",
		"type": "azurerm_kubernetes_cluster",
		"change": {"after": {"default_node_pool": [{
			"min_count": 1,
			"max_count": 20,
		}]}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "max_count is 20")
}

test_node_count_min_below_threshold if {
	msgs := restrict_aks_node_count.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster.main",
		"type": "azurerm_kubernetes_cluster",
		"change": {"after": {"default_node_pool": [{
			"min_count": 0,
			"max_count": 5,
		}]}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "min_count is 0")
}

test_node_count_both_violations if {
	msgs := restrict_aks_node_count.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster.main",
		"type": "azurerm_kubernetes_cluster",
		"change": {"after": {"default_node_pool": [{
			"min_count": 0,
			"max_count": 15,
		}]}},
	}]}
	count(msgs) == 2
}

test_node_count_max_exceeded_separate_pool if {
	msgs := restrict_aks_node_count.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster_node_pool.workers",
		"type": "azurerm_kubernetes_cluster_node_pool",
		"change": {"after": {
			"min_count": 1,
			"max_count": 50,
		}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "max_count is 50")
}

test_node_count_min_below_separate_pool if {
	msgs := restrict_aks_node_count.deny with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster_node_pool.workers",
		"type": "azurerm_kubernetes_cluster_node_pool",
		"change": {"after": {
			"min_count": 0,
			"max_count": 5,
		}},
	}]}
	count(msgs) == 1
	contains(msgs[_], "min_count is 0")
}

test_node_count_exactly_at_max_limit if {
	count(restrict_aks_node_count.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster_node_pool.edge",
		"type": "azurerm_kubernetes_cluster_node_pool",
		"change": {"after": {
			"min_count": 1,
			"max_count": 10,
		}},
	}]}
}

test_node_count_exactly_at_min_limit if {
	count(restrict_aks_node_count.deny) == 0 with input as {"resource_changes": [{
		"address": "azurerm_kubernetes_cluster_node_pool.edge",
		"type": "azurerm_kubernetes_cluster_node_pool",
		"change": {"after": {
			"min_count": 1,
			"max_count": 5,
		}},
	}]}
}
