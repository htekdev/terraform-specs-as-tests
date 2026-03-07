from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class AKSSubnetServiceEndpointCheck(BaseResourceCheck):
    """CKV_LZ_008: AKS subnet must have Microsoft.ContainerRegistry service endpoint.

    Ensures that azurerm_subnet resources whose name contains 'aks'
    include Microsoft.ContainerRegistry in their service_endpoints list,
    enabling direct connectivity to ACR without traversing the public internet.
    """

    def __init__(self):
        name = "Ensure AKS subnet has Microsoft.ContainerRegistry service endpoint"
        id = "CKV_LZ_008"
        supported_resources = ["azurerm_subnet"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        subnet_name = conf.get("name", [""])
        if isinstance(subnet_name, list):
            subnet_name = subnet_name[0] if subnet_name else ""

        if "aks" not in str(subnet_name).lower():
            return CheckResult.UNKNOWN

        service_endpoints = conf.get("service_endpoints", [])
        if isinstance(service_endpoints, list):
            # Checkov may wrap as [["Microsoft.ContainerRegistry", ...]]
            if len(service_endpoints) == 1 and isinstance(service_endpoints[0], list):
                service_endpoints = service_endpoints[0]

            if "Microsoft.ContainerRegistry" in service_endpoints:
                return CheckResult.PASSED

        return CheckResult.FAILED


check = AKSSubnetServiceEndpointCheck()
