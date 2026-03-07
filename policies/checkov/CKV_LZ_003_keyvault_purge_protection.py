from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class KeyVaultPurgeProtectionCheck(BaseResourceCheck):
    """CKV_LZ_003: Key Vault must have purge protection enabled.

    Ensures that azurerm_key_vault resources have purge_protection_enabled
    set to True, preventing permanent deletion of secrets, keys, and
    certificates during the retention period.
    """

    def __init__(self):
        name = "Ensure Key Vault has purge protection enabled"
        id = "CKV_LZ_003"
        supported_resources = ["azurerm_key_vault"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        purge_protection = conf.get("purge_protection_enabled", [False])
        if isinstance(purge_protection, list):
            purge_protection = purge_protection[0] if purge_protection else False

        if purge_protection is True:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = KeyVaultPurgeProtectionCheck()
