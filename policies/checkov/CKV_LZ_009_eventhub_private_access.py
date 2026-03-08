from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class EventHubPrivateAccessCheck(BaseResourceCheck):
    """CKV_LZ_009: Event Hub namespace must deny public network access.

    Ensures that azurerm_eventhub_namespace resources have
    public_network_access_enabled set to False, requiring all access
    to flow through private endpoints.
    """

    def __init__(self):
        name = "Ensure Event Hub namespace denies public network access"
        id = "CKV_LZ_009"
        supported_resources = ["azurerm_eventhub_namespace"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        public_access = conf.get("public_network_access_enabled", [True])
        if isinstance(public_access, list):
            public_access = public_access[0] if public_access else True

        if public_access is False:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = EventHubPrivateAccessCheck()
