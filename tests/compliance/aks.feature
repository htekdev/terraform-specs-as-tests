Feature: AKS Private Cluster Configuration
  The AKS cluster must be private, use Azure CNI, enforce network
  policies, and follow node pool sizing constraints.

  Scenario: AKS must be a private cluster
    Given I have azurerm_kubernetes_cluster defined
    Then it must have private_cluster_enabled
    And its value must be true

  Scenario: AKS must use Azure CNI networking
    Given I have azurerm_kubernetes_cluster defined
    When it contains network_profile
    Then it must have network_plugin
    And its value must be "azure"

  Scenario: AKS must enforce network policy
    Given I have azurerm_kubernetes_cluster defined
    When it contains network_profile
    Then it must have network_policy
    And its value must be "azure"

  Scenario: AKS must use managed identity
    Given I have azurerm_kubernetes_cluster defined
    When it contains identity
    Then it must have type
    And its value must be "SystemAssigned"

  Scenario: AKS must have RBAC enabled
    Given I have azurerm_kubernetes_cluster defined
    Then it must have role_based_access_control_enabled
    And its value must be true

  Scenario: AKS default node pool must use approved VM size
    Given I have azurerm_kubernetes_cluster defined
    When it contains default_node_pool
    Then it must have vm_size
    And its value must match the "Standard_D[0-9]+s_v5|Standard_E[0-9]+s_v5" regex
