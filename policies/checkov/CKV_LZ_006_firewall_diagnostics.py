from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class FirewallDiagnosticsCheck(BaseResourceCheck):
    """CKV_LZ_006: Azure Firewall must have diagnostic settings.

    Ensures that azurerm_monitor_diagnostic_setting resources that target
    an Azure Firewall have at least one log or metric category enabled,
    confirming that firewall traffic is being monitored.
    """

    def __init__(self):
        name = "Ensure Azure Firewall has diagnostic settings configured"
        id = "CKV_LZ_006"
        supported_resources = ["azurerm_monitor_diagnostic_setting"]
        categories = [CheckCategories.LOGGING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        target_resource_id = conf.get("target_resource_id", [""])
        if isinstance(target_resource_id, list):
            target_resource_id = target_resource_id[0] if target_resource_id else ""

        target_str = str(target_resource_id).lower()
        is_firewall = (
            "azurerm_firewall" in target_str
            or "microsoft.network/azurefirewalls" in target_str
        )

        if not is_firewall:
            return CheckResult.UNKNOWN

        has_log = False
        enabled_logs = conf.get("enabled_log", [])
        if isinstance(enabled_logs, list):
            for log_entry in enabled_logs:
                if isinstance(log_entry, dict):
                    has_log = True
                    break

        log_blocks = conf.get("log", [])
        if isinstance(log_blocks, list):
            for log_entry in log_blocks:
                if isinstance(log_entry, dict):
                    enabled = log_entry.get("enabled", [True])
                    if isinstance(enabled, list):
                        enabled = enabled[0] if enabled else True
                    if enabled is True:
                        has_log = True
                        break

        has_metric = False
        metric_blocks = conf.get("metric", [])
        if isinstance(metric_blocks, list):
            for metric_entry in metric_blocks:
                if isinstance(metric_entry, dict):
                    enabled = metric_entry.get("enabled", [True])
                    if isinstance(enabled, list):
                        enabled = enabled[0] if enabled else True
                    if enabled is True:
                        has_metric = True
                        break

        if has_log or has_metric:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = FirewallDiagnosticsCheck()
