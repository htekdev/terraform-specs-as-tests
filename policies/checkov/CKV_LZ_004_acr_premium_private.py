from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class ACRPremiumPrivateCheck(BaseResourceCheck):
    """CKV_LZ_004: ACR must be Premium SKU with public access disabled.

    Ensures that azurerm_container_registry resources use the Premium SKU
    (required for private endpoints) and have public_network_access_enabled
    set to False or 'Disabled'.
    """

    def __init__(self):
        name = "Ensure ACR is Premium SKU with public access disabled"
        id = "CKV_LZ_004"
        supported_resources = ["azurerm_container_registry"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        sku = conf.get("sku", ["Basic"])
        if isinstance(sku, list):
            sku = sku[0] if sku else "Basic"

        if sku != "Premium":
            return CheckResult.FAILED

        public_access = conf.get("public_network_access_enabled", [True])
        if isinstance(public_access, list):
            public_access = public_access[0] if public_access else True

        if public_access is False or public_access == "Disabled":
            return CheckResult.PASSED

        return CheckResult.FAILED


check = ACRPremiumPrivateCheck()
