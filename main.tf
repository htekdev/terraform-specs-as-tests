locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Project     = var.project
  })
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}-${var.location}"
  location = var.location
  tags     = local.common_tags
}

# ─── Monitoring (deployed first — other modules reference the workspace) ─────

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  tags                = local.common_tags
}

# ─── Hub Network ─────────────────────────────────────────────────────────────

module "hub_network" {
  source = "./modules/hub-network"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  address_space       = var.hub_vnet_address_space
  tags                = local.common_tags
}

# ─── Private DNS Zones (linked to hub) ───────────────────────────────────────

module "dns" {
  source = "./modules/dns"

  resource_group_name = azurerm_resource_group.main.name
  hub_vnet_id         = module.hub_network.vnet_id
  tags                = local.common_tags
}

# ─── Azure Firewall ──────────────────────────────────────────────────────────

module "firewall" {
  source = "./modules/firewall"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  environment                = var.environment
  project                    = var.project
  subnet_id                  = module.hub_network.firewall_subnet_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = local.common_tags
}

# ─── Spoke Networks ──────────────────────────────────────────────────────────

module "spoke_network" {
  source   = "./modules/spoke-network"
  for_each = var.spoke_configs

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  name                = each.key
  address_space       = each.value.address_space
  subnets = {
    for name, prefix in each.value.subnet_prefixes : name => {
      address_prefix = prefix
    }
  }
  hub_vnet_id         = module.hub_network.vnet_id
  hub_vnet_name       = module.hub_network.vnet_name
  firewall_private_ip = module.firewall.private_ip_address
  tags                = local.common_tags
}

# ─── Key Vault ───────────────────────────────────────────────────────────────

module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  subnet_id           = module.spoke_network["workload-2"].subnet_ids["endpoints"]
  private_dns_zone_id = module.dns.zone_ids["kv"]
  tags                = local.common_tags
}

# ─── Container Registry ─────────────────────────────────────────────────────

module "container_registry" {
  source = "./modules/container-registry"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  subnet_id           = module.spoke_network["workload-2"].subnet_ids["endpoints"]
  private_dns_zone_id = module.dns.zone_ids["acr"]
  tags                = local.common_tags
}

# ─── Storage ─────────────────────────────────────────────────────────────────

module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  subnet_id           = module.spoke_network["workload-2"].subnet_ids["endpoints"]
  private_dns_zone_id = module.dns.zone_ids["st"]
  tags                = local.common_tags
}

# ─── AKS Cluster ─────────────────────────────────────────────────────────────

module "aks_cluster" {
  source = "./modules/aks-cluster"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  environment                = var.environment
  project                    = var.project
  subnet_id                  = module.spoke_network["workload-1"].subnet_ids["aks"]
  log_analytics_workspace_id = module.monitoring.workspace_id
  acr_id                     = module.container_registry.registry_id
  kubernetes_version         = var.aks_config.kubernetes_version
  system_node_count          = var.aks_config.system_node_count
  system_vm_size             = var.aks_config.system_vm_size
  tags                       = local.common_tags
}

# ─── RBAC ────────────────────────────────────────────────────────────────────

module "rbac" {
  source = "./modules/rbac"

  aks_kubelet_identity_id = module.aks_cluster.kubelet_identity[0].object_id
  acr_id                  = module.container_registry.registry_id
  key_vault_id            = module.key_vault.vault_id
}
