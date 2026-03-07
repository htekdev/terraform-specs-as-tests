Feature: Security Hardening
  All PaaS services must use private endpoints, encryption must be
  enabled everywhere, and Key Vault must have deletion protection.

  Scenario: Key Vault must have soft delete enabled
    Given I have azurerm_key_vault defined
    Then it must have soft_delete_retention_days
    And its value must be greater than 6

  Scenario: Key Vault must have purge protection
    Given I have azurerm_key_vault defined
    Then it must have purge_protection_enabled
    And its value must be true

  Scenario: Key Vault must deny public access
    Given I have azurerm_key_vault defined
    Then it must have public_network_access_enabled
    And its value must be false

  Scenario: Storage accounts must deny public access
    Given I have azurerm_storage_account defined
    Then it must have public_network_access_enabled
    And its value must be false

  Scenario: Storage accounts must require secure transfer
    Given I have azurerm_storage_account defined
    Then it must have https_traffic_only_enabled
    And its value must be true

  Scenario: Storage accounts must have minimum TLS 1.2
    Given I have azurerm_storage_account defined
    Then it must have min_tls_version
    And its value must be "TLS1_2"

  Scenario: ACR must deny public access
    Given I have azurerm_container_registry defined
    Then it must have public_network_access_enabled
    And its value must be false

  Scenario: ACR admin must be disabled
    Given I have azurerm_container_registry defined
    Then it must have admin_enabled
    And its value must be false

  Scenario: Azure Firewall must exist
    Given I have azurerm_firewall defined
    Then it must have sku_tier
