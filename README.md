# terraform-specs-as-tests

> **Specs = Tests = Code** — An Azure Enterprise Landing Zone where every test was written before the implementation.

This project proves that specifications for infrastructure should be expressed as executable tests, not prose documents. All 7 testing layers were defined before a single line of Terraform was written. The tests **are** the spec — the only enforceable, deterministic expression of what the infrastructure must look like.

📝 **Article**: [The Spec-Driven Development Debate Has It Backwards](https://htek.dev/articles/specs-equal-tests-terraform-ai-development)

## The Testing Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CI/CD Pipeline Gates                     │
│           (GitHub Actions — final verification)              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │   OPA/   │ │ Checkov  │ │ terraform│ │  terraform-   │  │
│  │ Conftest │ │  Custom  │ │   test   │ │  compliance   │  │
│  │  (Rego)  │ │ (Python) │ │ (mocks)  │ │  (Gherkin)    │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────┘  │
│       │             │            │              │            │
│       ▼             ▼            ▼              ▼            │
│  Plan JSON     HCL Source   Module Contracts  Plan JSON      │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│            tflint (Static Analysis on HCL)                   │
├─────────────────────────────────────────────────────────────┤
│         Hookflows (Agent-Time Governance Gates)              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Terraform Modules   │
              │  (Implementation)     │
              └───────────────────────┘
```

## What Gets Deployed

An Azure Enterprise Landing Zone with hub-spoke architecture:

| Component | Description |
|-----------|-------------|
| Hub Network | VNet with Azure Firewall, Gateway, and Management subnets |
| Spoke Networks | 2 workload VNets peered to hub with forced tunneling |
| Azure Firewall | Central firewall with application and network rule collections |
| Key Vault | Secret management with private endpoint, soft delete, purge protection |
| AKS Cluster | Private Kubernetes cluster with Azure CNI and network policy |
| Container Registry | Premium ACR with private endpoint, admin disabled |
| Storage | Encrypted storage with private endpoint, deny public access |
| Monitoring | Central Log Analytics workspace with diagnostic settings |
| Private DNS | Private DNS zones for all private endpoint services |
| RBAC | Least-privilege role definitions and assignments |

## Test Results

All tests pass locally with zero cloud cost:

| Layer | Tool | Tests | Status |
|-------|------|-------|--------|
| OPA/Conftest | `opa test` | 82 unit tests across 4 policy domains | ✅ 82/82 |
| terraform test | `terraform test` | 93 assertions across 11 modules | ✅ 93/93 |
| Checkov | `checkov` | 9 custom Python policies (CKV_LZ_001–009) | ✅ Written |
| terraform-compliance | `terraform-compliance` | 6 BDD feature files (~32 scenarios) | ✅ Written |
| tflint | `tflint` | Azure-specific static analysis rules | ✅ Configured |
| Hookflows | `gh hookflow` | 6 agent governance workflows | ✅ Validated |
| CI/CD | GitHub Actions | 7 pipeline workflows | ✅ Configured |
| Integration | `terraform test` (real Azure) | 4 per-module live tests | ✅ Nightly |
| E2E | `terraform test` (real Azure) | Full landing zone deploy | ✅ Nightly |

## 7 Testing Layers

### 1. OPA/Conftest Policies (Rego)
Policy-as-code validating `terraform plan` JSON. 15 policies across 4 domains with 77 unit tests.

**Domains:**
- **Network** (5 policies): Deny public IPs, require NSGs on subnets, enforce hub-spoke peering, require forced tunneling, deny broad NSG rules
- **Security** (5 policies): Require encryption, require private endpoints, Key Vault purge protection, deny ACR admin, require AKS private cluster
- **Governance** (3 policies): Required tags on all resources, CAF naming conventions, allowed regions only
- **Cost** (2 policies): Restrict AKS VM sizes to D/E-series v5, enforce max node count per pool

```bash
make policy-test  # Unit test the policies (77/77 pass)
make policy       # Evaluate against terraform plan
```

### 2. Checkov Custom Policies (Python)
8 custom security checks (CKV_LZ_001–008) scanning HCL source directly.

| Check ID | Description |
|----------|-------------|
| CKV_LZ_001 | AKS must be private cluster |
| CKV_LZ_002 | Storage must have private endpoint |
| CKV_LZ_003 | Key Vault purge protection required |
| CKV_LZ_004 | ACR must be Premium + private |
| CKV_LZ_005 | NSG flow logs must be enabled |
| CKV_LZ_006 | Firewall diagnostic settings required |
| CKV_LZ_007 | Hub VNet must configure custom DNS |
| CKV_LZ_008 | AKS subnet must have service delegation |

```bash
make lint  # Includes Checkov scan
```

### 3. terraform test (Native)
10 `.tftest.hcl` files with mock providers testing module contracts. Zero cloud cost.

Validates: outputs, resource attributes, security settings, tags, location constraints, and module-specific behavior (private endpoints, encryption, RBAC roles, DNS zones, firewall rules).

```bash
make test  # 73/73 pass
```

### 4. terraform-compliance (BDD/Gherkin)
6 feature files with human-readable Given/When/Then scenarios covering networking, security, governance, AKS, monitoring, and storage.

```bash
make compliance  # Requires plan JSON
```

### 5. tflint
Static analysis with Azure-specific rules for naming, module sources, and deprecated attributes.

```bash
make lint
```

### 6. Hookflows (Agent Governance)
5 hookflow workflows providing real-time guardrails during Copilot sessions:

- **enforce-test-with-code** — Blocks `.tf` changes without corresponding test changes
- **validate-terraform-format** — Runs `terraform fmt` on every edit
- **block-dangerous-patterns** — No hardcoded secrets, no `public_network_access = true`
- **enforce-module-structure** — Modules must have variables.tf, outputs.tf, README.md
- **require-policy-coverage** — New resources must have OPA policy coverage

### 7. CI/CD Pipeline (GitHub Actions)
7 workflow files creating a multi-stage gate: lint → test → compliance → policy → plan → apply → integration.

### 8. Integration Tests (Real Azure)
4 per-module integration tests deploying real Azure resources and validating live state:
- **Log-Forwarding**: Event Hub namespace with private endpoint, diagnostic settings, auth rules
- **Key Vault**: Private Key Vault with purge protection
- **Monitoring**: Log Analytics workspace with correct SKU and retention
- **DNS**: All 5 private DNS zones with VNet links

Uses `terraform test` with `command = apply` (auto-destroys after assertions). Runs nightly via OIDC-authenticated GitHub Actions.

### 9. E2E Landing Zone Test
Full deployment of all 11 modules validating cross-module integration. Runs nightly after integration tests pass.

```bash
make integration  # Per-module tests (requires az login)
make e2e          # Full landing zone (requires az login, ~30 min)
```

## Quick Start

```bash
# Install tools
brew install terraform tflint opa conftest checkov
pip install terraform-compliance

# Run all local checks (no cloud cost)
make check

# Individual test layers
make test        # terraform test with mocks (93 tests)
make policy-test # OPA policy unit tests (82 tests)
make coverage    # Test coverage analysis (4 dimensions)
make lint        # fmt + tflint + Checkov
make compliance  # BDD tests (requires plan JSON)
make policy      # OPA against plan (requires plan JSON)

# Live tests (requires Azure credentials)
make integration      # Per-module integration tests
make e2e              # Full landing zone E2E test
make validate-deployed RG=rg-lz-dev-eastus2  # Post-deploy validation
make sweep            # Clean up expired test resource groups
```

## Test Coverage Enforcement

Unlike traditional code coverage (line/branch instrumentation), Terraform has no native coverage tooling. This project introduces a **4-dimensional coverage analyzer** (`scripts/coverage.py`) that measures:

| Dimension | What It Measures | Threshold |
|-----------|-----------------|-----------|
| **Resource Coverage** | % of declared resource types with ≥1 test | 80% |
| **Security Attribute Coverage** | % of must-test security attributes asserted on | 100% |
| **OPA Rego Coverage** | Code coverage of Rego policy files | 95% |
| **Layer Depth** | Minimum # of test layers covering each resource | ≥1 |

The security attribute manifest (`scripts/coverage_config.json`) defines which attributes **must** be tested — if you add a new PaaS resource without testing its `public_network_access_enabled`, the coverage gate blocks your commit.

```bash
# Run coverage analysis
make coverage

# Generate JSON report for CI
python scripts/coverage.py --json coverage-report.json

# Override thresholds
python scripts/coverage.py --threshold-resource 90 --threshold-security 100
```

Coverage is enforced at 3 levels:
1. **Locally** via `make coverage` (part of `make check`)
2. **Agent-time** via hookflow gate (blocks commits when thresholds not met)
3. **CI/CD** via GitHub Actions (uploads coverage report as artifact)

## Project Structure

```
terraform-specs-as-tests/
├── modules/                    # 11 Terraform modules
│   ├── hub-network/            # Hub VNet + subnets + NSG
│   ├── spoke-network/          # Spoke VNets + peering + routes
│   ├── firewall/               # Azure Firewall + policy + diagnostics
│   ├── key-vault/              # Key Vault + private endpoint
│   ├── aks-cluster/            # Private AKS + managed identity
│   ├── container-registry/     # Premium ACR + private endpoint
│   ├── storage/                # Storage + private endpoint + encryption
│   ├── monitoring/             # Log Analytics workspace
│   ├── dns/                    # Private DNS zones + VNet links
│   ├── rbac/                   # Role assignments (ACR pull, KV access)
│   └── log-forwarding/         # Event Hub namespace + SIEM streaming
├── policies/
│   ├── opa/                    # 16 Rego policies + 82 unit tests
│   │   ├── network/            # 5 network policies
│   │   ├── security/           # 6 security policies
│   │   ├── governance/         # 3 governance policies
│   │   ├── cost/               # 2 cost policies
│   │   └── tests/              # 4 test files (82 tests total)
│   ├── checkov/                # 9 custom Python policies
│   └── tflint/                 # tflint config + rules
├── tests/
│   ├── unit/                   # 11 .tftest.hcl + mock provider (93 tests)
│   ├── integration/            # 4 per-module live tests (real Azure)
│   │   ├── setup/              # Shared test infrastructure module
│   │   ├── log_forwarding.tftest.hcl
│   │   ├── key_vault.tftest.hcl
│   │   ├── monitoring.tftest.hcl
│   │   └── dns.tftest.hcl
│   ├── e2e/                    # Full landing zone E2E test
│   │   └── landing_zone.tftest.hcl
│   └── compliance/             # 6 BDD/Gherkin feature files
├── scripts/
│   ├── coverage.py             # Test coverage analyzer (4 dimensions)
│   ├── coverage_config.json    # Coverage thresholds + must-test manifest
│   ├── validate-deployed.sh    # Post-deploy az CLI validation
│   └── sweep-test-resources.sh # TTL-based test resource cleanup
├── environments/
│   ├── dev/                    # Dev variable values
│   └── prod/                   # Prod variable values
├── .github/
│   ├── hookflows/              # 6 agent governance workflows
│   └── workflows/              # 7 CI/CD pipeline workflows
├── main.tf                     # Root composition (all 11 modules)
├── variables.tf                # Root variables with validation
├── outputs.tf                  # Root outputs
├── versions.tf                 # Provider version constraints
├── providers.tf                # Azure provider config
└── Makefile                    # Test runner commands
```

## Development Methodology

This project was built using the **Specs = Tests = Code** methodology:

1. **Phases 1-8** (Tests First): All 7 testing layers were written before any Terraform module code
2. **Phase 9** (Implementation): Terraform modules were implemented constrained by the pre-existing tests
3. **Phase 10** (Validation): Full test suite run to verify the golden path works

The result: an AI agent (Copilot) implementing the Terraform modules was structurally forced to produce correct, secure, compliant infrastructure by satisfying every test layer simultaneously.

## License

MIT
