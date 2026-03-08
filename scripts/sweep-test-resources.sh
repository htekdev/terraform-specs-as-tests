#!/bin/bash
# Sweep expired test resource groups
# Deletes resource groups matching 'rg-lz-test-*' whose DeleteAfter tag is in the past.
# Safe to run on schedule — only deletes explicitly tagged test resources.

set -euo pipefail

echo "━━━ Sweeping Expired Test Resource Groups ━━━"
echo ""

DELETED=0
KEPT=0
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Find all test resource groups (integration test pattern + E2E pattern)
RGS=$(az group list --query "[?starts_with(name, 'rg-lz-test-') || (starts_with(name, 'rg-lz-dev-') && tags.Purpose == 'integration-test')].{name:name, deleteAfter:tags.DeleteAfter}" -o json 2>/dev/null)

if [ "$RGS" = "[]" ] || [ -z "$RGS" ]; then
  echo "No test resource groups found."
  exit 0
fi

echo "$RGS" | python3 -c "
import json, sys
from datetime import datetime, timezone

rgs = json.load(sys.stdin)
now = datetime.now(timezone.utc)
to_delete = []
to_keep = []

for rg in rgs:
    name = rg['name']
    delete_after = rg.get('deleteAfter')
    
    if not delete_after:
        # No TTL tag — flag but don't delete (manual cleanup needed)
        print(f'  ⚠️  {name}: no DeleteAfter tag (skipping)')
        to_keep.append(name)
        continue
    
    try:
        # Parse ISO 8601 timestamp
        expiry = datetime.fromisoformat(delete_after.replace('Z', '+00:00'))
        if now > expiry:
            print(f'  🗑️  {name}: expired at {delete_after}')
            to_delete.append(name)
        else:
            print(f'  ✅ {name}: valid until {delete_after}')
            to_keep.append(name)
    except (ValueError, TypeError):
        print(f'  ⚠️  {name}: invalid DeleteAfter tag \"{delete_after}\" (skipping)')
        to_keep.append(name)

# Output names for bash to process
with open('/tmp/rgs_to_delete.txt', 'w') as f:
    f.write('\n'.join(to_delete))

print(f'\nTotal: {len(to_delete)} to delete, {len(to_keep)} to keep')
"

# Delete expired resource groups
if [ -f /tmp/rgs_to_delete.txt ] && [ -s /tmp/rgs_to_delete.txt ]; then
  while IFS= read -r rg_name; do
    echo "  Deleting $rg_name..."
    az group delete --name "$rg_name" --yes --no-wait 2>/dev/null && \
      echo "  ✅ Delete initiated: $rg_name" || \
      echo "  ❌ Failed to delete: $rg_name"
    DELETED=$((DELETED + 1))
  done < /tmp/rgs_to_delete.txt
  rm -f /tmp/rgs_to_delete.txt
fi

echo ""
echo "━━━ Sweep Complete: $DELETED resource group(s) queued for deletion ━━━"
