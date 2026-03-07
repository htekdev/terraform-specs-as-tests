Feature: Hub-Spoke Network Architecture
  The landing zone must implement a hub-spoke network topology with
  centralized firewall, forced tunneling, and NSG enforcement.

  Scenario: Hub VNet must exist with required subnets
    Given I have azurerm_virtual_network defined
    Then it must have address_space
    And its value must not be null

  Scenario: All subnets must have NSGs (except firewall and gateway)
    Given I have azurerm_subnet defined
    When its name is not "AzureFirewallSubnet"
    And its name is not "GatewaySubnet"
    Then it must have network_security_group_id

  Scenario: Spoke VNets must peer to hub
    Given I have azurerm_virtual_network_peering defined
    Then it must have allow_forwarded_traffic
    And its value must be true

  Scenario: Route tables must force traffic through firewall
    Given I have azurerm_route defined
    When its address_prefix is "0.0.0.0/0"
    Then it must have next_hop_type
    And its value must be "VirtualAppliance"

  Scenario: No broad NSG inbound rules from Internet
    Given I have azurerm_network_security_rule defined
    When its direction is "Inbound"
    And its access is "Allow"
    Then its source_address_prefix must not be "*"
    And its source_address_prefix must not be "0.0.0.0/0"
    And its source_address_prefix must not be "Internet"
