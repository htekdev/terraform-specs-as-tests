# RBAC Module — Unit Tests
# Validates the rbac module creates role assignments for AKS -> ACR pull
# and AKS -> Key Vault access following least-privilege principles.

mock_provider "azurerm" {}

variables {
  aks_kubelet_identity_id = "00000000-0000-0000-0000-000000000099"
  acr_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ContainerRegistry/registries/acrmock"
  key_vault_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
}

run "rbac_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/rbac"
  }

  assert {
    condition     = length(output.role_assignment_ids) > 0
    error_message = "RBAC role_assignment_ids output must contain at least one entry"
  }
}

run "rbac_creates_acr_pull_assignment" {
  command = plan

  module {
    source = "./modules/rbac"
  }

  assert {
    condition     = azurerm_role_assignment.acr_pull.scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ContainerRegistry/registries/acrmock"
    error_message = "AKS -> ACR role assignment must be scoped to the ACR resource"
  }

  assert {
    condition     = azurerm_role_assignment.acr_pull.role_definition_name == "AcrPull"
    error_message = "AKS -> ACR role assignment must use the AcrPull role"
  }

  assert {
    condition     = azurerm_role_assignment.acr_pull.principal_id == "00000000-0000-0000-0000-000000000099"
    error_message = "AKS -> ACR role assignment must use the AKS kubelet identity as principal"
  }
}

run "rbac_creates_key_vault_access_assignment" {
  command = plan

  module {
    source = "./modules/rbac"
  }

  assert {
    condition     = azurerm_role_assignment.kv_access.scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
    error_message = "AKS -> Key Vault role assignment must be scoped to the Key Vault resource"
  }

  assert {
    condition     = azurerm_role_assignment.kv_access.role_definition_name == "Key Vault Secrets User"
    error_message = "AKS -> Key Vault role assignment must use Key Vault Secrets User role (least privilege)"
  }

  assert {
    condition     = azurerm_role_assignment.kv_access.principal_id == "00000000-0000-0000-0000-000000000099"
    error_message = "AKS -> Key Vault role assignment must use the AKS kubelet identity as principal"
  }
}

run "rbac_uses_least_privilege_roles" {
  command = plan

  module {
    source = "./modules/rbac"
  }

  # AcrPull is the minimum role needed for pulling images
  assert {
    condition     = azurerm_role_assignment.acr_pull.role_definition_name == "AcrPull"
    error_message = "ACR role must be AcrPull (not Contributor or Owner) for least privilege"
  }

  # Key Vault Secrets User is the minimum role for reading secrets
  assert {
    condition     = azurerm_role_assignment.kv_access.role_definition_name == "Key Vault Secrets User"
    error_message = "Key Vault role must be Key Vault Secrets User (not Key Vault Administrator) for least privilege"
  }
}
