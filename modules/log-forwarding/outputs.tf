output "namespace_id" {
  description = "Resource ID of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.id
}

output "namespace_name" {
  description = "Name of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.name
}

output "hub_name" {
  description = "Name of the diagnostic logs event hub"
  value       = azurerm_eventhub.logs.name
}

output "send_rule_id" {
  description = "Resource ID of the send authorization rule (for diagnostic settings)"
  value       = azurerm_eventhub_authorization_rule.send.id
}

output "listen_rule_id" {
  description = "Resource ID of the listen authorization rule (for SIEM integration)"
  value       = azurerm_eventhub_authorization_rule.listen.id
}
