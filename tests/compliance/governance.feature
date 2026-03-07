Feature: Governance and Compliance
  All resources must follow naming conventions, use required tags,
  and deploy only to approved regions.

  Scenario Outline: All taggable resources must have required tags
    Given I have resource that supports tags defined
    When it contains tags
    Then it must contain <tag_key>
    And its value must not be null

    Examples:
      | tag_key     |
      | Environment |
      | Owner       |
      | CostCenter  |
      | ManagedBy   |
      | Project     |

  Scenario: Resources must be in approved regions only
    Given I have resource that has location defined
    Then it must have location
    And its value must match the "eastus2|westus2" regex

  Scenario: Resource groups must follow naming convention
    Given I have azurerm_resource_group defined
    Then it must have name
    And its value must match the "^rg-" regex
