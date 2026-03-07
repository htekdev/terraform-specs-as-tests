package security_test

import rego.v1

import data.security.deny_acr_admin
import data.security.require_aks_private
import data.security.require_encryption
import data.security.require_keyvault_protection
import data.security.require_private_endpoints

# ---------------------------------------------------------------------------
# require_encryption tests
# ---------------------------------------------------------------------------

test_storage_encryption_enabled_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_storage_account",
		"address": "module.storage.azurerm_storage_account.main",
		"change": {
			"actions": ["create"],
			"after": {"infrastructure_encryption_enabled": true},
		},
	}]}

	result := require_encryption.deny with input as inp
	count(result) == 0
}

test_storage_encryption_disabled_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_storage_account",
		"address": "module.storage.azurerm_storage_account.main",
		"change": {
			"actions": ["create"],
			"after": {"infrastructure_encryption_enabled": false},
		},
	}]}

	result := require_encryption.deny with input as inp
	count(result) > 0
}

test_aks_disk_encryption_set_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.main",
		"change": {
			"actions": ["create"],
			"after": {"disk_encryption_set_id": "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Compute/diskEncryptionSets/des1"},
		},
	}]}

	result := require_encryption.deny with input as inp
	count(result) == 0
}

test_aks_disk_encryption_missing_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.main",
		"change": {
			"actions": ["create"],
			"after": {"disk_encryption_set_id": null},
		},
	}]}

	result := require_encryption.deny with input as inp
	count(result) > 0
}

# ---------------------------------------------------------------------------
# require_private_endpoints tests
# ---------------------------------------------------------------------------

test_storage_public_access_disabled_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_storage_account",
		"address": "module.storage.azurerm_storage_account.main",
		"change": {
			"actions": ["create"],
			"after": {"public_network_access_enabled": false},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) == 0
}

test_storage_network_rules_deny_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_storage_account",
		"address": "module.storage.azurerm_storage_account.main",
		"change": {
			"actions": ["create"],
			"after": {
				"public_network_access_enabled": true,
				"network_rules": [{"default_action": "Deny"}],
			},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) == 0
}

test_storage_public_access_enabled_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_storage_account",
		"address": "module.storage.azurerm_storage_account.main",
		"change": {
			"actions": ["create"],
			"after": {
				"public_network_access_enabled": true,
				"network_rules": [{"default_action": "Allow"}],
			},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) > 0
}

test_keyvault_public_access_disabled_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_key_vault",
		"address": "module.kv.azurerm_key_vault.main",
		"change": {
			"actions": ["create"],
			"after": {"public_network_access_enabled": false},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) == 0
}

test_keyvault_public_access_enabled_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_key_vault",
		"address": "module.kv.azurerm_key_vault.main",
		"change": {
			"actions": ["create"],
			"after": {"public_network_access_enabled": true},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) > 0
}

test_acr_public_access_disabled_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_container_registry",
		"address": "module.acr.azurerm_container_registry.main",
		"change": {
			"actions": ["create"],
			"after": {"public_network_access_enabled": false},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) == 0
}

test_acr_public_access_enabled_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_container_registry",
		"address": "module.acr.azurerm_container_registry.main",
		"change": {
			"actions": ["create"],
			"after": {"public_network_access_enabled": true},
		},
	}]}

	result := require_private_endpoints.deny with input as inp
	count(result) > 0
}

# ---------------------------------------------------------------------------
# require_keyvault_protection tests
# ---------------------------------------------------------------------------

test_keyvault_protection_enabled_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_key_vault",
		"address": "module.kv.azurerm_key_vault.main",
		"change": {
			"actions": ["create"],
			"after": {
				"soft_delete_retention_days": 90,
				"purge_protection_enabled": true,
			},
		},
	}]}

	result := require_keyvault_protection.deny with input as inp
	count(result) == 0
}

test_keyvault_soft_delete_too_low_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_key_vault",
		"address": "module.kv.azurerm_key_vault.main",
		"change": {
			"actions": ["create"],
			"after": {
				"soft_delete_retention_days": 3,
				"purge_protection_enabled": true,
			},
		},
	}]}

	result := require_keyvault_protection.deny with input as inp
	count(result) > 0
}

test_keyvault_purge_protection_disabled_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_key_vault",
		"address": "module.kv.azurerm_key_vault.main",
		"change": {
			"actions": ["create"],
			"after": {
				"soft_delete_retention_days": 90,
				"purge_protection_enabled": false,
			},
		},
	}]}

	result := require_keyvault_protection.deny with input as inp
	count(result) > 0
}

# ---------------------------------------------------------------------------
# deny_acr_admin tests
# ---------------------------------------------------------------------------

test_acr_admin_disabled_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_container_registry",
		"address": "module.acr.azurerm_container_registry.main",
		"change": {
			"actions": ["create"],
			"after": {"admin_enabled": false},
		},
	}]}

	result := deny_acr_admin.deny with input as inp
	count(result) == 0
}

test_acr_admin_not_set_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_container_registry",
		"address": "module.acr.azurerm_container_registry.main",
		"change": {
			"actions": ["create"],
			"after": {},
		},
	}]}

	result := deny_acr_admin.deny with input as inp
	count(result) == 0
}

test_acr_admin_enabled_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_container_registry",
		"address": "module.acr.azurerm_container_registry.main",
		"change": {
			"actions": ["create"],
			"after": {"admin_enabled": true},
		},
	}]}

	result := deny_acr_admin.deny with input as inp
	count(result) > 0
}

# ---------------------------------------------------------------------------
# require_aks_private tests
# ---------------------------------------------------------------------------

test_aks_private_cluster_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.main",
		"change": {
			"actions": ["create"],
			"after": {
				"private_cluster_enabled": true,
				"api_server_access_profile": [{"authorized_ip_ranges": ["10.0.0.0/8"], "vnet_integration_enabled": false}],
			},
		},
	}]}

	result := require_aks_private.deny with input as inp
	count(result) == 0
}

test_aks_private_with_vnet_integration_passes if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.main",
		"change": {
			"actions": ["create"],
			"after": {
				"private_cluster_enabled": true,
				"api_server_access_profile": [{"authorized_ip_ranges": [], "vnet_integration_enabled": true}],
			},
		},
	}]}

	result := require_aks_private.deny with input as inp
	count(result) == 0
}

test_aks_not_private_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.main",
		"change": {
			"actions": ["create"],
			"after": {
				"private_cluster_enabled": false,
				"api_server_access_profile": [{"authorized_ip_ranges": ["10.0.0.0/8"], "vnet_integration_enabled": false}],
			},
		},
	}]}

	result := require_aks_private.deny with input as inp
	count(result) > 0
}

test_aks_no_api_server_restrictions_fails if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.main",
		"change": {
			"actions": ["create"],
			"after": {
				"private_cluster_enabled": true,
				"api_server_access_profile": [{"authorized_ip_ranges": [], "vnet_integration_enabled": false}],
			},
		},
	}]}

	result := require_aks_private.deny with input as inp
	count(result) > 0
}

# ---------------------------------------------------------------------------
# Cross-cutting: deleted resources should not trigger denials
# ---------------------------------------------------------------------------

test_deleted_resources_not_denied_encryption if {
	inp := {"resource_changes": [
		{
			"type": "azurerm_storage_account",
			"address": "module.storage.azurerm_storage_account.old",
			"change": {"actions": ["delete"], "after": {}},
		},
		{
			"type": "azurerm_key_vault",
			"address": "module.kv.azurerm_key_vault.old",
			"change": {"actions": ["delete"], "after": {}},
		},
		{
			"type": "azurerm_kubernetes_cluster",
			"address": "module.aks.azurerm_kubernetes_cluster.old",
			"change": {"actions": ["delete"], "after": {}},
		},
	]}

	result := require_encryption.deny with input as inp
	count(result) == 0
}

test_deleted_resources_not_denied_private_endpoints if {
	inp := {"resource_changes": [
		{
			"type": "azurerm_storage_account",
			"address": "module.storage.azurerm_storage_account.old",
			"change": {"actions": ["delete"], "after": {}},
		},
		{
			"type": "azurerm_key_vault",
			"address": "module.kv.azurerm_key_vault.old",
			"change": {"actions": ["delete"], "after": {}},
		},
		{
			"type": "azurerm_container_registry",
			"address": "module.acr.azurerm_container_registry.old",
			"change": {"actions": ["delete"], "after": {}},
		},
	]}

	result := require_private_endpoints.deny with input as inp
	count(result) == 0
}

test_deleted_resources_not_denied_keyvault_protection if {
	inp := {"resource_changes": [{
		"type": "azurerm_key_vault",
		"address": "module.kv.azurerm_key_vault.old",
		"change": {"actions": ["delete"], "after": {}},
	}]}

	result := require_keyvault_protection.deny with input as inp
	count(result) == 0
}

test_deleted_resources_not_denied_acr_admin if {
	inp := {"resource_changes": [{
		"type": "azurerm_container_registry",
		"address": "module.acr.azurerm_container_registry.old",
		"change": {"actions": ["delete"], "after": {}},
	}]}

	result := deny_acr_admin.deny with input as inp
	count(result) == 0
}

test_deleted_resources_not_denied_aks_private if {
	inp := {"resource_changes": [{
		"type": "azurerm_kubernetes_cluster",
		"address": "module.aks.azurerm_kubernetes_cluster.old",
		"change": {"actions": ["delete"], "after": {}},
	}]}

	result := require_aks_private.deny with input as inp
	count(result) == 0
}
