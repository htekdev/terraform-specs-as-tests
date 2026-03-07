Feature: Centralized Monitoring and Diagnostics
  All resources must send diagnostic logs to a central Log Analytics workspace.

  Scenario: Log Analytics workspace must exist
    Given I have azurerm_log_analytics_workspace defined
    Then it must have sku
    And its value must be "PerGB2018"

  Scenario: Log Analytics must have adequate retention
    Given I have azurerm_log_analytics_workspace defined
    Then it must have retention_in_days
    And its value must be greater than 29

  Scenario: Diagnostic settings must target Log Analytics
    Given I have azurerm_monitor_diagnostic_setting defined
    Then it must have log_analytics_workspace_id
    And its value must not be null
