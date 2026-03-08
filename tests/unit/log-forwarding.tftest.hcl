# Log-Forwarding Module — Unit Tests
# Validates the log-forwarding module creates an Event Hub namespace,
# event hub, authorization rules, private endpoint, and diagnostic settings.

mock_provider "azurerm" {}

variables {
  resource_group_name        = "rg-lz-dev-eastus2"
  location                   = "eastus2"
  environment                = "dev"
  project                    = "lz"
  subnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-endpoints"
  private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    CostCenter  = "CC001"
    ManagedBy   = "terraform"
    Project     = "lz"
  }
}

run "log_forwarding_outputs_are_populated" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = output.namespace_name == "evhns-lz-dev-eastus2-001"
    error_message = "Event Hub namespace name output must be populated"
  }

  assert {
    condition     = output.hub_name == "evh-lz-dev-eastus2-logs"
    error_message = "Event Hub name output must be populated"
  }
}

run "log_forwarding_namespace_follows_naming_convention" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.name == "evhns-lz-dev-eastus2-001"
    error_message = "Event Hub namespace must follow CAF naming: evhns-{project}-{env}-{region}-001"
  }
}

run "log_forwarding_namespace_uses_standard_sku" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.sku == "Standard"
    error_message = "Event Hub namespace must use Standard SKU for private endpoint and partition support"
  }
}

run "log_forwarding_namespace_denies_public_access" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.public_network_access_enabled == false
    error_message = "Event Hub namespace must deny public network access"
  }
}

run "log_forwarding_namespace_requires_tls_12" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.minimum_tls_version == "1.2"
    error_message = "Event Hub namespace must require minimum TLS 1.2"
  }
}

run "log_forwarding_hub_has_correct_name" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub.logs.name == "evh-lz-dev-eastus2-logs"
    error_message = "Diagnostic logs event hub must follow naming convention"
  }
}

run "log_forwarding_hub_has_adequate_partitions" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub.logs.partition_count >= 2
    error_message = "Event hub must have at least 2 partitions for throughput"
  }
}

run "log_forwarding_hub_has_message_retention" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub.logs.message_retention >= 1
    error_message = "Event hub must retain messages for at least 1 day"
  }
}

run "log_forwarding_send_rule_is_least_privilege" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.send.send == true
    error_message = "Send authorization rule must have send permission"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.send.listen == false
    error_message = "Send authorization rule must NOT have listen permission (least privilege)"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.send.manage == false
    error_message = "Send authorization rule must NOT have manage permission (least privilege)"
  }
}

run "log_forwarding_listen_rule_is_least_privilege" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.listen.listen == true
    error_message = "Listen authorization rule must have listen permission"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.listen.send == false
    error_message = "Listen authorization rule must NOT have send permission (least privilege)"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.listen.manage == false
    error_message = "Listen authorization rule must NOT have manage permission (least privilege)"
  }
}

run "log_forwarding_auth_rules_scoped_to_event_hub" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.send.eventhub_name == "evh-lz-dev-eastus2-logs"
    error_message = "Send rule must be scoped to the specific event hub, not the namespace"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.listen.eventhub_name == "evh-lz-dev-eastus2-logs"
    error_message = "Listen rule must be scoped to the specific event hub, not the namespace"
  }
}

run "log_forwarding_private_endpoint_targets_namespace" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_private_endpoint.evhns.private_service_connection[0].subresource_names[0] == "namespace"
    error_message = "Private endpoint must target the 'namespace' subresource"
  }

  assert {
    condition     = azurerm_private_endpoint.evhns.private_service_connection[0].is_manual_connection == false
    error_message = "Private endpoint connection must be automatic (not manual)"
  }
}

run "log_forwarding_tags_are_applied" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.tags["Environment"] == "dev"
    error_message = "Event Hub namespace must carry the Environment tag"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.tags["ManagedBy"] == "terraform"
    error_message = "Event Hub namespace must carry the ManagedBy tag"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.tags["Module"] == "log-forwarding"
    error_message = "Event Hub namespace must carry the Module tag"
  }
}

run "log_forwarding_auto_inflate_defaults_enabled" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.auto_inflate_enabled == true
    error_message = "Auto-inflate must be enabled by default for elastic throughput"
  }
}

run "log_forwarding_uses_correct_location" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_eventhub_namespace.main.location == "eastus2"
    error_message = "Event Hub namespace must be deployed to eastus2"
  }
}

run "log_forwarding_diagnostic_setting_targets_namespace" {
  command = plan

  module {
    source = "./modules/log-forwarding"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.evhns.log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
    error_message = "Diagnostic setting must forward to the Log Analytics workspace"
  }
}
