#!/bin/bash
# Post-deployment validation script for Azure Landing Zone
# Checks real Azure resource state via az CLI
# Usage: ./scripts/validate-deployed.sh <resource_group_name> [location]
#
# Exit codes: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

RG_NAME="${1:?Usage: validate-deployed.sh <resource_group_name> [location]}"
LOCATION="${2:-eastus2}"
FAILURES=0

pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAILURES=$((FAILURES + 1)); }
section() { echo ""; echo "━━━ $1 ━━━"; }

# ── Event Hub Namespace ──────────────────────────────────────────────────────
section "Event Hub Namespace"

EVHNS_NAME=$(az eventhubs namespace list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -z "$EVHNS_NAME" ]; then
  fail "No Event Hub namespace found in $RG_NAME"
else
  pass "Event Hub namespace exists: $EVHNS_NAME"

  # Public access disabled
  PUBLIC_ACCESS=$(az eventhubs namespace show -g "$RG_NAME" -n "$EVHNS_NAME" --query "publicNetworkAccess" -o tsv 2>/dev/null)
  if [ "$PUBLIC_ACCESS" = "Disabled" ] || [ "$PUBLIC_ACCESS" = "SecuredByPerimeter" ]; then
    pass "Public network access: $PUBLIC_ACCESS"
  else
    fail "Public network access should be Disabled, got: $PUBLIC_ACCESS"
  fi

  # TLS 1.2
  MIN_TLS=$(az eventhubs namespace show -g "$RG_NAME" -n "$EVHNS_NAME" --query "minimumTlsVersion" -o tsv 2>/dev/null)
  if [ "$MIN_TLS" = "1.2" ]; then
    pass "Minimum TLS version: $MIN_TLS"
  else
    fail "Minimum TLS should be 1.2, got: $MIN_TLS"
  fi

  # SKU
  SKU=$(az eventhubs namespace show -g "$RG_NAME" -n "$EVHNS_NAME" --query "sku.name" -o tsv 2>/dev/null)
  if [ "$SKU" = "Standard" ]; then
    pass "SKU: $SKU"
  else
    fail "SKU should be Standard, got: $SKU"
  fi
fi

# ── Key Vault ────────────────────────────────────────────────────────────────
section "Key Vault"

KV_NAME=$(az keyvault list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -z "$KV_NAME" ]; then
  echo "  ⏭️  No Key Vault found in $RG_NAME (skipped)"
else
  pass "Key Vault exists: $KV_NAME"

  # Purge protection
  PURGE=$(az keyvault show -n "$KV_NAME" --query "properties.enablePurgeProtection" -o tsv 2>/dev/null)
  if [ "$PURGE" = "true" ]; then
    pass "Purge protection enabled"
  else
    fail "Purge protection should be enabled, got: $PURGE"
  fi

  # Public access
  KV_PUBLIC=$(az keyvault show -n "$KV_NAME" --query "properties.publicNetworkAccess" -o tsv 2>/dev/null)
  if [ "$KV_PUBLIC" = "Disabled" ]; then
    pass "Public network access: Disabled"
  else
    fail "Public network access should be Disabled, got: $KV_PUBLIC"
  fi
fi

# ── Private Endpoints ────────────────────────────────────────────────────────
section "Private Endpoints"

PE_COUNT=$(az network private-endpoint list -g "$RG_NAME" --query "length(@)" -o tsv 2>/dev/null)
if [ "$PE_COUNT" -gt 0 ] 2>/dev/null; then
  pass "$PE_COUNT private endpoint(s) found"

  # Check connection status for each endpoint
  az network private-endpoint list -g "$RG_NAME" --query "[].{name:name, status:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" -o json 2>/dev/null | \
  python3 -c "
import json, sys
endpoints = json.load(sys.stdin)
for ep in endpoints:
    name = ep.get('name', 'unknown')
    status = ep.get('status', 'unknown')
    if status == 'Approved':
        print(f'  ✅ {name}: connection {status}')
    else:
        print(f'  ❌ {name}: connection {status} (expected Approved)')
        sys.exit(1)
" || FAILURES=$((FAILURES + 1))
else
  echo "  ⏭️  No private endpoints found in $RG_NAME (skipped)"
fi

# ── Diagnostic Settings ──────────────────────────────────────────────────────
section "Diagnostic Settings"

if [ -n "$EVHNS_NAME" ]; then
  EVHNS_ID=$(az eventhubs namespace show -g "$RG_NAME" -n "$EVHNS_NAME" --query "id" -o tsv 2>/dev/null)
  DIAG_COUNT=$(az monitor diagnostic-settings list --resource "$EVHNS_ID" --query "length(value)" -o tsv 2>/dev/null || echo "0")
  if [ "$DIAG_COUNT" -gt 0 ] 2>/dev/null; then
    pass "Event Hub namespace has $DIAG_COUNT diagnostic setting(s)"

    # Verify workspace target
    DIAG_WS=$(az monitor diagnostic-settings list --resource "$EVHNS_ID" --query "value[0].workspaceId" -o tsv 2>/dev/null)
    if [ -n "$DIAG_WS" ] && [ "$DIAG_WS" != "None" ]; then
      pass "Diagnostic logs target Log Analytics workspace"
    else
      fail "Diagnostic setting should target a Log Analytics workspace"
    fi
  else
    fail "Event Hub namespace should have diagnostic settings configured"
  fi
fi

# ── Tags ─────────────────────────────────────────────────────────────────────
section "Required Tags"

REQUIRED_TAGS=("Environment" "Owner" "CostCenter" "ManagedBy" "Project")

if [ -n "$EVHNS_NAME" ]; then
  TAGS_JSON=$(az eventhubs namespace show -g "$RG_NAME" -n "$EVHNS_NAME" --query "tags" -o json 2>/dev/null)
  for tag in "${REQUIRED_TAGS[@]}"; do
    HAS_TAG=$(echo "$TAGS_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if '$tag' in d else 'no')" 2>/dev/null)
    if [ "$HAS_TAG" = "yes" ]; then
      pass "Tag '$tag' present on Event Hub namespace"
    else
      fail "Required tag '$tag' missing from Event Hub namespace"
    fi
  done
fi

# ── Summary ──────────────────────────────────────────────────────────────────
section "Summary"
if [ "$FAILURES" -eq 0 ]; then
  echo "  🎉 All validation checks passed!"
  exit 0
else
  echo "  💥 $FAILURES check(s) failed"
  exit 1
fi
