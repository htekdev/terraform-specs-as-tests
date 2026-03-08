.PHONY: all lint test compliance policy coverage integration e2e validate-deployed help

SHELL := /bin/bash

# ─── Help ────────────────────────────────────────────────────────────────────
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Layer 1: Static Analysis ────────────────────────────────────────────────
fmt: ## Run terraform fmt
	terraform fmt -recursive -check

lint: fmt ## Run tflint + Checkov
	tflint --recursive --config policies/tflint/.tflint.hcl
	checkov -d . --framework terraform --external-checks-dir policies/checkov --compact

validate: ## Run terraform validate
	terraform init -backend=false
	terraform validate

# ─── Layer 2: Unit Tests (No Cloud Resources) ────────────────────────────────
test: ## Run terraform test with provider mocks
	terraform test -test-directory=tests/unit

# ─── Layer 3: Policy Tests ────────────────────────────────────────────────────
policy-test: ## Run OPA policy unit tests
	opa test policies/opa/ -v

policy: ## Run OPA/Conftest against terraform plan
	terraform plan -out=tfplan -input=false
	terraform show -json tfplan > tfplan.json
	conftest test tfplan.json -p policies/opa/ --all-namespaces
	@rm -f tfplan tfplan.json

# ─── Layer 4: BDD Compliance Tests ───────────────────────────────────────────
compliance: ## Run terraform-compliance BDD tests
	terraform plan -out=tfplan -input=false
	terraform show -json tfplan > tfplan.json
	terraform-compliance -f tests/compliance/ -p tfplan.json
	@rm -f tfplan tfplan.json

# ─── Layer 5: Integration Tests (Real Azure) ────────────────────────────────
integration: ## Run integration tests against real Azure (requires az login)
	terraform init -backend=false -test-directory=tests/integration
	terraform test -test-directory=tests/integration -verbose

# ─── Layer 6: E2E Tests (Full Landing Zone) ──────────────────────────────────
e2e: ## Run full E2E landing zone test (requires az login, ~30 min)
	terraform init -backend=false -test-directory=tests/e2e
	terraform test -test-directory=tests/e2e -verbose

# ─── Post-Deploy Validation ──────────────────────────────────────────────────
validate-deployed: ## Validate deployed resources via az CLI (usage: make validate-deployed RG=<name>)
	bash scripts/validate-deployed.sh $(RG)

sweep: ## Delete expired test resource groups
	bash scripts/sweep-test-resources.sh

# ─── Coverage Analysis ────────────────────────────────────────────────────────
coverage: ## Run test coverage analysis across all layers
	python scripts/coverage.py

coverage-report: ## Generate JSON coverage report
	python scripts/coverage.py --json coverage-report.json

# ─── Combined Targets ────────────────────────────────────────────────────────
check: fmt lint validate test policy-test coverage ## Run all local checks (no cloud)
all: check policy compliance ## Run everything including plan-based tests
