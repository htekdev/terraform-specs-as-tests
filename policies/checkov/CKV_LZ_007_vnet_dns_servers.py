from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class VNetCustomDNSCheck(BaseResourceCheck):
    """CKV_LZ_007: Hub VNet should configure custom DNS servers.

    Ensures that azurerm_virtual_network resources have the dns_servers
    attribute set with at least one custom DNS server address, which is
    essential for hub VNets in a landing zone architecture.
    """

    def __init__(self):
        name = "Ensure VNet configures custom DNS servers"
        id = "CKV_LZ_007"
        supported_resources = ["azurerm_virtual_network"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        dns_servers = conf.get("dns_servers", [])
        if isinstance(dns_servers, list):
            # Checkov wraps values in lists, so dns_servers may be [["10.0.0.4"]]
            if len(dns_servers) == 1 and isinstance(dns_servers[0], list):
                dns_servers = dns_servers[0]

            # Filter out empty strings and None values
            actual_servers = [s for s in dns_servers if s]
            if len(actual_servers) > 0:
                return CheckResult.PASSED

        return CheckResult.FAILED


check = VNetCustomDNSCheck()
