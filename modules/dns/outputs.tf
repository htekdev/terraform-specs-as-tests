output "zone_ids" {
  description = "Map of DNS zone keys to their resource IDs"
  value       = { for k, zone in azurerm_private_dns_zone.zones : k => zone.id }
}
