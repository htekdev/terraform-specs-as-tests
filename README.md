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
| OPA/Conftest | `opa test` | 77 unit tests across 4 policy domains | ✅ 77/77 |
| terraform test | `terraform test` | 73 assertions across 10 modules | ✅ 73/73 |
| Checkov | `checkov` | 8 custom Python policies (CKV_LZ_001–008) | ✅ Written |
| terraform-compliance | `terraform-compliance` | 6 BDD feature files (~30 scenarios) | ✅ Written |
| tflint | `tflint` | Azure-specific static analysis rules | ✅ Configured |
| Hookflows | `gh hookflow` | 5 agent governance workflows | ✅ Validated |
| CI/CD | GitHub Actions | 6 pipeline workflows | ✅ Configured |

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
6 workflow files creating a multi-stage gate: lint → test → compliance → policy → plan → apply.

## Quick Start

```bash
# Install tools
brew install terraform tflint opa conftest checkov
pip install terraform-compliance

# Run all local checks (no cloud cost)
make check

# Individual test layers
make test        # terraform test with mocks (73 tests)
make policy-test # OPA policy unit tests (77 tests)
make coverage    # Test coverage analysis (4 dimensions)
make lint        # fmt + tflint + Checkov
make compliance  # BDD tests (requires plan JSON)
make policy      # OPA against plan (requires plan JSON)
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
├── modules/                    # 10 Terraform modules
│   ├── hub-network/            # Hub VNet + subnets + NSG
│   ├── spoke-network/          # Spoke VNets + peering + routes
│   ├── firewall/               # Azure Firewall + policy + diagnostics
│   ├── key-vault/              # Key Vault + private endpoint
│   ├── aks-cluster/            # Private AKS + managed identity
│   ├── container-registry/     # Premium ACR + private endpoint
│   ├── storage/                # Storage + private endpoint + encryption
│   ├── monitoring/             # Log Analytics workspace
│   ├── dns/                    # Private DNS zones + VNet links
│   └── rbac/                   # Role assignments (ACR pull, KV access)
├── policies/
│   ├── opa/                    # 15 Rego policies + 77 unit tests
│   │   ├── network/            # 5 network policies
│   │   ├── security/           # 5 security policies
│   │   ├── governance/         # 3 governance policies
│   │   ├── cost/               # 2 cost policies
│   │   └── tests/              # 4 test files (77 tests total)
│   ├── checkov/                # 8 custom Python policies
│   └── tflint/                 # tflint config + rules
├── tests/
│   ├── unit/                   # 10 .tftest.hcl + mock provider (73 tests)
│   └── compliance/             # 6 BDD/Gherkin feature files
├── scripts/
│   ├── coverage.py             # Test coverage analyzer (4 dimensions)
│   └── coverage_config.json    # Coverage thresholds + must-test manifest
├── environments/
│   ├── dev/                    # Dev variable values
│   └── prod/                   # Prod variable values
├── .github/
│   ├── hookflows/              # 5 agent governance workflows
│   └── workflows/              # 6 CI/CD pipeline workflows
├── main.tf                     # Root composition (all 10 modules)
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
