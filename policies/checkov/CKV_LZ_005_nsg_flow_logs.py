from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class NSGFlowLogsEnabledCheck(BaseResourceCheck):
    """CKV_LZ_005: NSG must have flow logs enabled.

    Ensures that azurerm_network_watcher_flow_log resources have their
    enabled attribute set to True so that NSG traffic is captured for
    security analysis and troubleshooting.
    """

    def __init__(self):
        name = "Ensure NSG flow logs are enabled"
        id = "CKV_LZ_005"
        supported_resources = ["azurerm_network_watcher_flow_log"]
        categories = [CheckCategories.LOGGING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        enabled = conf.get("enabled", [False])
        if isinstance(enabled, list):
            enabled = enabled[0] if enabled else False

        if enabled is True:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = NSGFlowLogsEnabledCheck()
