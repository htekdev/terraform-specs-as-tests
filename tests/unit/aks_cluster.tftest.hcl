# AKS Cluster Module — Unit Tests
# Validates the aks-cluster module enforces private cluster, Azure CNI,
# network policy, and SystemAssigned managed identity.

mock_provider "azurerm" {}

variables {
  resource_group_name        = "rg-lz-dev-eastus2"
  location                   = "eastus2"
  environment                = "dev"
  project                    = "lz"
  subnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-aks-nodes"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "aks_outputs_are_populated" {
  command = apply

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = output.cluster_id != ""
    error_message = "AKS cluster ID output must not be empty"
  }

  assert {
    condition     = output.cluster_name != ""
    error_message = "AKS cluster name output must not be empty"
  }

  assert {
    condition     = output.private_fqdn != ""
    error_message = "AKS private FQDN output must not be empty"
  }

  assert {
    condition     = output.node_resource_group != ""
    error_message = "AKS node resource group output must not be empty"
  }

  assert {
    condition     = output.kubelet_identity != null
    error_message = "AKS kubelet identity output must not be null"
  }
}

run "aks_is_private_cluster" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.private_cluster_enabled == true
    error_message = "AKS cluster must be private (CKV_LZ_001)"
  }
}

run "aks_uses_azure_cni" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.network_profile[0].network_plugin == "azure"
    error_message = "AKS cluster must use Azure CNI network plugin"
  }
}

run "aks_enforces_network_policy" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.network_profile[0].network_policy == "azure"
    error_message = "AKS cluster must enforce Azure network policy"
  }
}

run "aks_uses_system_assigned_identity" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.identity[0].type == "SystemAssigned"
    error_message = "AKS cluster must use SystemAssigned managed identity"
  }
}

run "aks_has_rbac_enabled" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.role_based_access_control_enabled == true
    error_message = "AKS cluster must have RBAC enabled"
  }
}

run "aks_default_node_pool_is_in_correct_subnet" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.default_node_pool[0].vnet_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-aks-nodes"
    error_message = "AKS default node pool must be in the provided subnet"
  }
}

run "aks_tags_are_applied" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.tags["Environment"] == "dev"
    error_message = "AKS cluster must carry the Environment tag"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.tags["ManagedBy"] == "terraform"
    error_message = "AKS cluster must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.tags["Project"] == "lz"
    error_message = "AKS cluster must carry the Project tag"
  }
}

run "aks_uses_correct_location" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.location == "eastus2"
    error_message = "AKS cluster must be deployed to eastus2"
  }
}

run "aks_has_oms_agent_for_monitoring" {
  command = plan

  module {
    source = "./modules/aks-cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.cluster.oms_agent[0].log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
    error_message = "AKS cluster must have OMS agent configured with the provided Log Analytics workspace"
  }
}
