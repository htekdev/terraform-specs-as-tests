# Copilot Instructions — terraform-specs-as-tests

## Project Purpose

This project demonstrates the "Specs = Tests = Code" methodology for Terraform.
All tests and policies were written BEFORE any Terraform implementation.
The tests define the golden path — implementation must satisfy every test layer.

Reference article: https://htek.dev/articles/specs-equal-tests-terraform-ai-development

## Architecture

Azure Enterprise Landing Zone with hub-spoke networking:
- Hub VNet with Azure Firewall, Gateway subnet, Management subnet
- 2 Spoke VNets peered to hub with forced tunneling
- AKS private cluster, Key Vault, ACR, Storage — all with private endpoints
- Central Log Analytics, RBAC, Private DNS zones

## 7 Testing Layers (Enforcement Stack)

1. **OPA/Conftest** (`policies/opa/`) — Rego policies validating plan JSON
2. **Checkov** (`policies/checkov/`) — Custom Python policies scanning HCL
3. **terraform test** (`tests/unit/`) — `.tftest.hcl` files with provider mocks
4. **terraform-compliance** (`tests/compliance/`) — BDD/Gherkin feature files
5. **tflint** (`policies/tflint/`) — Static analysis rules
6. **Hookflows** (`.github/hookflows/`) — Agent governance gates
7. **CI/CD** (`.github/workflows/`) — GitHub Actions pipeline gates

## Rules for Implementation

### Every .tf Change MUST Have a Corresponding Test Change
If you modify any `.tf` file in `modules/`, you must also modify or add:
- A `.tftest.hcl` file in `tests/unit/`
- OPA policy coverage in `policies/opa/` (if new resource type)

### Naming Convention (Azure CAF)
All resources follow: `{type}-{project}-{environment}-{region}-{instance}`
Examples:
- `vnet-lz-dev-eastus2-hub`
- `kv-lz-prod-westus2-001`
- `aks-lz-dev-eastus2-001`

### Required Tags on ALL Resources
Every resource must include these tags:
- `Environment` — dev, staging, prod
- `Owner` — team or individual
- `CostCenter` — billing code
- `ManagedBy` — "terraform"
- `Project` — project name

### Security Requirements
- NO public endpoints on PaaS services (Key Vault, Storage, ACR, AKS)
- ALL data encrypted at rest and in transit
- Key Vault: soft delete + purge protection ALWAYS enabled
- AKS: private cluster ONLY
- ACR: admin DISABLED, Premium SKU only
- NSGs: NO wildcard (*) source in allow rules

### Module Structure
Every module in `modules/` must contain:
- `main.tf` — resource definitions
- `variables.tf` — input variables with validation
- `outputs.tf` — output values
- `versions.tf` — provider version constraints
- `README.md` — module documentation

### Allowed Regions
Only `eastus2` and `westus2` are permitted.

### Allowed VM Sizes for AKS
Only D-series v5 and E-series v5 SKUs are approved.

## Testing Commands
```bash
make check       # All local checks (no cloud cost)
make test        # terraform test with mocks
make policy-test # OPA policy unit tests
make lint        # fmt + tflint + Checkov
make compliance  # BDD tests (requires plan)
make policy      # OPA against plan (requires plan)
```
