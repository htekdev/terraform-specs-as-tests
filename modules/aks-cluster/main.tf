locals {
  tags = merge(var.tags, {
    Module = "aks-cluster"
  })
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                              = "aks-${var.project}-${var.environment}-${var.location}-001"
  resource_group_name               = var.resource_group_name
  location                          = var.location
  dns_prefix                        = "aks-${var.project}-${var.environment}"
  kubernetes_version                = var.kubernetes_version
  private_cluster_enabled           = true
  role_based_access_control_enabled = true
  tags                              = local.tags

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "system"
    node_count     = var.system_node_count
    vm_size        = var.system_vm_size
    vnet_subnet_id = var.subnet_id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  count                            = var.acr_id != null ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
