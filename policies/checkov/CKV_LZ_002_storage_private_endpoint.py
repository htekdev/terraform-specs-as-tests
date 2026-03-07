from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class StorageDenyPublicAccessCheck(BaseResourceCheck):
    """CKV_LZ_002: Storage account must deny public access.

    Ensures that azurerm_storage_account resources either have
    public_network_access_enabled set to False, or configure
    network_rules with default_action set to Deny.
    """

    def __init__(self):
        name = "Ensure storage account denies public access"
        id = "CKV_LZ_002"
        supported_resources = ["azurerm_storage_account"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        public_network_access = conf.get("public_network_access_enabled", [True])
        if isinstance(public_network_access, list):
            public_network_access = public_network_access[0] if public_network_access else True

        if public_network_access is False:
            return CheckResult.PASSED

        network_rules = conf.get("network_rules", [{}])
        if isinstance(network_rules, list):
            network_rules = network_rules[0] if network_rules else {}

        if isinstance(network_rules, dict):
            default_action = network_rules.get("default_action", ["Allow"])
            if isinstance(default_action, list):
                default_action = default_action[0] if default_action else "Allow"
            if default_action == "Deny":
                return CheckResult.PASSED

        return CheckResult.FAILED


check = StorageDenyPublicAccessCheck()
