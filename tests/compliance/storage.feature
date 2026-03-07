Feature: Secure Storage Configuration
  Storage accounts must be encrypted, versioned, and accessible
  only through private endpoints.

  Scenario: Storage must use Standard_LRS or Standard_GRS replication
    Given I have azurerm_storage_account defined
    Then it must have account_replication_type
    And its value must match the "LRS|GRS|RAGRS" regex

  Scenario: Storage account tier must be Standard
    Given I have azurerm_storage_account defined
    Then it must have account_tier
    And its value must be "Standard"

  Scenario: Blob versioning should be enabled
    Given I have azurerm_storage_account defined
    When it contains blob_properties
    Then it must have versioning_enabled
    And its value must be true

  Scenario: Blob soft delete must be enabled
    Given I have azurerm_storage_account defined
    When it contains blob_properties
    When it contains delete_retention_policy
    Then it must have days
    And its value must be greater than 6
