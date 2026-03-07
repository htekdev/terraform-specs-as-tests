output "role_assignment_ids" {
  description = "Map of role assignment names to their IDs"
  value = {
    acr_pull  = azurerm_role_assignment.acr_pull.id
    kv_access = azurerm_role_assignment.kv_access.id
  }
}
