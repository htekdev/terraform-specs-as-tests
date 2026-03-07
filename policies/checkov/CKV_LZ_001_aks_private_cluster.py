from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class AKSPrivateClusterCheck(BaseResourceCheck):
    """CKV_LZ_001: AKS cluster must be private.

    Ensures that azurerm_kubernetes_cluster resources have
    private_cluster_enabled set to True, preventing the API server
    from being exposed on a public IP address.
    """

    def __init__(self):
        name = "Ensure AKS cluster is private"
        id = "CKV_LZ_001"
        supported_resources = ["azurerm_kubernetes_cluster"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        private_cluster_enabled = conf.get("private_cluster_enabled", [False])
        if isinstance(private_cluster_enabled, list):
            private_cluster_enabled = private_cluster_enabled[0] if private_cluster_enabled else False

        if private_cluster_enabled is True:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = AKSPrivateClusterCheck()
