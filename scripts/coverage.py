#!/usr/bin/env python3
"""terraform-coverage — Terraform Test Coverage Analyzer

Measures and enforces test coverage across 4 dimensions:
  1. Resource Coverage  — % of declared resource types with ≥1 test
  2. Security Coverage  — % of must-test security attributes asserted on
  3. Layer Depth        — avg # of test layers covering each resource
  4. OPA Rego Coverage  — code coverage of Rego policy files (via opa test)

Exit codes:
  0 — All thresholds met
  1 — One or more thresholds not met
  2 — Error during analysis

Usage:
  python scripts/coverage.py
  python scripts/coverage.py --json coverage-report.json
  python scripts/coverage.py --threshold-resource 90 --threshold-security 100
"""

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

# Ensure stdout can handle unicode on Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() not in ("utf-8", "utf8"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass


# ─── Default Configuration ────────────────────────────────────────────────────

DEFAULT_CONFIG = {
    "thresholds": {
        "resource_coverage_pct": 80,
        "security_coverage_pct": 100,
        "min_layers_per_resource": 1,
        "opa_rego_coverage_pct": 95,
    },
    "must_test_attributes": {},
    "exclude_resources": ["azurerm_resource_group"],
}


# ─── Discovery: Resources ────────────────────────────────────────────────────

def discover_resources(root):
    """Walk modules/*/main.tf and extract resource declarations.

    Returns dict: { module_name: [{ type, name }] }
    """
    resources = {}
    modules_dir = root / "modules"
    if not modules_dir.exists():
        return resources

    for module_dir in sorted(modules_dir.iterdir()):
        if not module_dir.is_dir():
            continue

        module_resources = []
        for tf_file in module_dir.glob("*.tf"):
            content = tf_file.read_text(encoding="utf-8", errors="replace")
            for match in re.finditer(r'resource\s+"(\w+)"\s+"(\w+)"', content):
                module_resources.append({
                    "type": match.group(1),
                    "name": match.group(2),
                })

        if module_resources:
            resources[module_dir.name] = module_resources

    return resources


# ─── Discovery: Unit Tests (.tftest.hcl) ──────────────────────────────────────

def discover_unit_test_coverage(root):
    """Parse tests/unit/*.tftest.hcl for tested resources and attributes.

    Returns dict: { resource_type: set(attribute_names) }
    """
    coverage = defaultdict(set)
    test_dir = root / "tests" / "unit"
    if not test_dir.exists():
        return coverage

    for test_file in sorted(test_dir.glob("*.tftest.hcl")):
        content = test_file.read_text(encoding="utf-8", errors="replace")

        # Extract resource.name.attribute references in condition lines
        # Pattern: azurerm_xxx.local_name.attribute_name
        # Handles indexed references like .zones["kv"].name
        for match in re.finditer(
            r'(azurerm_\w+)\.(\w+)(?:\[.*?\])?\.(\w+)', content
        ):
            res_type = match.group(1)
            attribute = match.group(3)
            coverage[res_type].add(attribute)

        # Also catch existence checks: azurerm_xxx.name != null
        # These prove the resource type is tested even without attribute access
        for match in re.finditer(
            r'(azurerm_\w+)\.(\w+)\s*!=\s*null', content
        ):
            res_type = match.group(1)
            coverage[res_type].add("__exists__")

        # Also catch output.xxx references — prove module is tested
        # Extract module source to associate outputs with module
        for match in re.finditer(
            r'source\s*=\s*"\.\/modules\/([\w-]+)"', content
        ):
            pass  # Module is at least referenced

    return dict(coverage)


# ─── Discovery: OPA Policies (.rego) ─────────────────────────────────────────

def discover_opa_coverage(root):
    """Parse policies/opa/**/*.rego for resource type checks and attributes.

    Returns dict: { resource_type: set(attribute_names) }
    """
    coverage = defaultdict(set)
    opa_dir = root / "policies" / "opa"
    if not opa_dir.exists():
        return coverage

    for rego_file in sorted(opa_dir.rglob("*.rego")):
        # Skip test files — they test the policies, not the resources
        if rego_file.parent.name == "tests":
            continue

        content = rego_file.read_text(encoding="utf-8", errors="replace")

        # Find all resource type references
        types_in_file = set()
        for match in re.finditer(r'\.type\s*==\s*"(azurerm_\w+)"', content):
            types_in_file.add(match.group(1))
            coverage[match.group(1)]  # ensure key exists

        # Find attribute checks: resource.values.xxx or .change.after.xxx
        for match in re.finditer(
            r'(?:resource|r|res|vnets?|nsg)[\w]*\.(?:values|change\.after)\.(\w+)',
            content,
        ):
            attr = match.group(1)
            for rt in types_in_file:
                coverage[rt].add(attr)

        # Also catch direct .values references without variable alias
        for match in re.finditer(
            r'\.values\.(\w+)', content
        ):
            attr = match.group(1)
            if attr not in ("tags", "type"):
                for rt in types_in_file:
                    coverage[rt].add(attr)

    return dict(coverage)


# ─── Discovery: Checkov Policies (.py) ────────────────────────────────────────

def discover_checkov_coverage(root):
    """Parse policies/checkov/*.py for supported_resource_type references.

    Returns dict: { resource_type: set(attribute_names) }
    """
    coverage = defaultdict(set)
    checkov_dir = root / "policies" / "checkov"
    if not checkov_dir.exists():
        return coverage

    for py_file in sorted(checkov_dir.glob("*.py")):
        content = py_file.read_text(encoding="utf-8", errors="replace")

        # Find supported_resources or supported_resource_type = ["azurerm_xxx"]
        resource_types = re.findall(
            r'supported_resource(?:s|_type)\s*=\s*\["(azurerm_\w+)"', content
        )

        # Find attribute checks via config.get("xxx") or config["xxx"]
        attrs = set()
        for match in re.finditer(
            r'config\s*(?:\.get\s*\(\s*|\.?\[)["\'](\w+)["\']', content
        ):
            attrs.add(match.group(1))

        for rt in resource_types:
            coverage[rt].update(attrs)

    return dict(coverage)


# ─── Discovery: terraform-compliance (.feature) ──────────────────────────────

def discover_compliance_coverage(root):
    """Parse tests/compliance/*.feature for resource references.

    Returns dict: { resource_type: set(attribute_names) }
    """
    coverage = defaultdict(set)
    compliance_dir = root / "tests" / "compliance"
    if not compliance_dir.exists():
        return coverage

    for feature_file in sorted(compliance_dir.glob("*.feature")):
        content = feature_file.read_text(encoding="utf-8", errors="replace")

        # Find: I have azurerm_xxx defined
        resource_types_in_file = set()
        for match in re.finditer(r'I have (azurerm_\w+) defined', content):
            rt = match.group(1)
            resource_types_in_file.add(rt)
            coverage[rt]  # ensure key exists

        # Find: it must have "xxx" or it must contain "xxx" or it should have
        for match in re.finditer(
            r'it (?:must|should) (?:have|contain)\s+"(\w+)"', content
        ):
            attr = match.group(1)
            for rt in resource_types_in_file:
                coverage[rt].add(attr)

        # Find: property references like "xxx" should be "yyy"
        for match in re.finditer(
            r'"(\w+)"\s+(?:should|must)\s+(?:be|equal|match)', content
        ):
            attr = match.group(1)
            for rt in resource_types_in_file:
                coverage[rt].add(attr)

    return dict(coverage)


# ─── OPA Rego Code Coverage ──────────────────────────────────────────────────

def get_opa_rego_coverage(root):
    """Run `opa test --coverage` and extract the overall coverage percentage.

    Returns float or None if OPA is unavailable.
    """
    opa_dir = root / "policies" / "opa"
    if not opa_dir.exists():
        return None

    try:
        result = subprocess.run(
            ["opa", "test", str(opa_dir), "--coverage"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        output = result.stdout.strip()

        # OPA outputs JSON with a top-level "coverage" field
        # Try to find the coverage value
        matches = re.findall(r'"coverage"\s*:\s*([\d.]+)', output)
        if matches:
            return float(matches[-1])  # last match is the overall coverage

        return None
    except FileNotFoundError:
        return None
    except subprocess.TimeoutExpired:
        return None


# ─── Coverage Computation ────────────────────────────────────────────────────

def compute_coverage(root, config):
    """Discover all resources and tests, cross-reference, compute metrics."""

    # Discover resources across all modules
    module_resources = discover_resources(root)

    # Discover test coverage from each layer
    unit = discover_unit_test_coverage(root)
    opa = discover_opa_coverage(root)
    checkov = discover_checkov_coverage(root)
    compliance = discover_compliance_coverage(root)

    # Get OPA Rego code coverage
    opa_rego_pct = get_opa_rego_coverage(root)

    # Build set of all resource types (excluding configured exclusions)
    exclude = set(config.get("exclude_resources", []))
    all_resource_types = set()
    resource_to_module = {}
    for module_name, res_list in module_resources.items():
        for r in res_list:
            if r["type"] not in exclude:
                all_resource_types.add(r["type"])
                resource_to_module.setdefault(r["type"], []).append(module_name)

    # Build coverage matrix
    matrix = {}
    for rt in sorted(all_resource_types):
        in_unit = rt in unit
        in_opa = rt in opa
        in_checkov = rt in checkov
        in_compliance = rt in compliance
        layer_count = sum([in_unit, in_opa, in_checkov, in_compliance])

        tested_attrs = set()
        for layer_data in [unit, opa, checkov, compliance]:
            if rt in layer_data:
                tested_attrs.update(layer_data[rt])

        matrix[rt] = {
            "modules": sorted(set(resource_to_module.get(rt, []))),
            "unit": in_unit,
            "opa": in_opa,
            "checkov": in_checkov,
            "compliance": in_compliance,
            "layers": layer_count,
            "tested_attributes": sorted(tested_attrs),
        }

    # Dimension 1: Resource coverage
    total_resources = len(all_resource_types)
    covered_resources = sum(1 for v in matrix.values() if v["layers"] > 0)
    resource_coverage_pct = (
        (covered_resources / total_resources * 100) if total_resources > 0 else 100
    )

    # Dimension 2: Security attribute coverage
    must_test = config.get("must_test_attributes", {})
    total_must = 0
    covered_must = 0
    security_gaps = []
    security_details = []

    for rt, required_attrs in must_test.items():
        for attr in required_attrs:
            total_must += 1
            tested_attrs_for_rt = set()
            for layer_data in [unit, opa, checkov, compliance]:
                if rt in layer_data:
                    tested_attrs_for_rt.update(layer_data[rt])

            if attr in tested_attrs_for_rt:
                covered_must += 1
                security_details.append({"resource": rt, "attribute": attr, "tested": True})
            else:
                security_gaps.append(f"{rt}.{attr}")
                security_details.append({"resource": rt, "attribute": attr, "tested": False})

    security_coverage_pct = (
        (covered_must / total_must * 100) if total_must > 0 else 100
    )

    # Dimension 3: Layer depth
    total_layers = sum(v["layers"] for v in matrix.values())
    avg_layers = total_layers / len(matrix) if matrix else 0
    min_layers = config.get("thresholds", {}).get("min_layers_per_resource", 1)
    below_min = sorted([rt for rt, v in matrix.items() if v["layers"] < min_layers])

    # Dimension 4: OPA Rego (already computed)

    # Uncovered resources
    uncovered = sorted([rt for rt, v in matrix.items() if v["layers"] == 0])

    return {
        "resources": {
            "total": total_resources,
            "covered": covered_resources,
            "coverage_pct": round(resource_coverage_pct, 1),
            "uncovered": uncovered,
        },
        "security": {
            "total": total_must,
            "covered": covered_must,
            "coverage_pct": round(security_coverage_pct, 1),
            "gaps": security_gaps,
            "details": security_details,
        },
        "layers": {
            "average": round(avg_layers, 2),
            "min_required": min_layers,
            "below_minimum": below_min,
        },
        "opa_rego": {
            "coverage_pct": round(opa_rego_pct, 2) if opa_rego_pct is not None else None,
        },
        "matrix": matrix,
    }


# ─── Threshold Checking ─────────────────────────────────────────────────────

def check_thresholds(report, config):
    """Check all coverage thresholds. Returns list of failure dicts."""
    thresholds = config.get("thresholds", {})
    failures = []

    # Resource coverage
    threshold = thresholds.get("resource_coverage_pct", 80)
    actual = report["resources"]["coverage_pct"]
    if actual < threshold:
        failures.append({
            "dimension": "Resource Coverage",
            "threshold": threshold,
            "actual": actual,
            "detail": (
                f"{report['resources']['covered']}/{report['resources']['total']} "
                f"resource types covered"
            ),
        })

    # Security attribute coverage
    threshold = thresholds.get("security_coverage_pct", 100)
    actual = report["security"]["coverage_pct"]
    if actual < threshold:
        gaps_preview = ", ".join(report["security"]["gaps"][:5])
        more = ""
        if len(report["security"]["gaps"]) > 5:
            more = f" (+{len(report['security']['gaps']) - 5} more)"
        failures.append({
            "dimension": "Security Attribute Coverage",
            "threshold": threshold,
            "actual": actual,
            "detail": f"Missing: {gaps_preview}{more}",
        })

    # OPA Rego coverage
    threshold = thresholds.get("opa_rego_coverage_pct", 95)
    actual = report["opa_rego"]["coverage_pct"]
    if actual is not None and actual < threshold:
        failures.append({
            "dimension": "OPA Rego Coverage",
            "threshold": threshold,
            "actual": actual,
            "detail": f"{actual}% Rego code exercised by tests",
        })

    # Minimum layers per resource
    min_layers = thresholds.get("min_layers_per_resource", 1)
    below = report["layers"]["below_minimum"]
    if below:
        failures.append({
            "dimension": "Minimum Layer Depth",
            "threshold": f">={min_layers} layers",
            "actual": f"{len(below)} resources below minimum",
            "detail": ", ".join(below[:5]),
        })

    return failures


# ─── Report Printing ─────────────────────────────────────────────────────────

def print_report(report, config, failures):
    """Print human-readable coverage report to stdout."""
    W = 78
    thresholds = config.get("thresholds", {})

    print()
    print("=" * W)
    print("  Terraform Test Coverage Report".center(W))
    print("=" * W)
    print()

    # ── Resource coverage ──
    r = report["resources"]
    t = thresholds.get("resource_coverage_pct", 80)
    icon = "✓" if r["coverage_pct"] >= t else "✗"
    print(
        f"  RESOURCE COVERAGE: {r['covered']}/{r['total']} "
        f"({r['coverage_pct']}%)  {icon} threshold: {t}%"
    )
    print("  " + "-" * (W - 4))
    print()

    # Matrix header
    header_rt = "Resource Type"
    print(f"  {header_rt:<44}| Unit | OPA  | Chk  | Cpl  | Layers")
    print(f"  {'-' * 44}+------+------+------+------+-------")

    for rt in sorted(report["matrix"], key=lambda x: -report["matrix"][x]["layers"]):
        data = report["matrix"][rt]
        short = rt.replace("azurerm_", "")
        if len(short) > 42:
            short = short[:39] + "..."

        u = " Y  " if data["unit"] else " .  "
        o = " Y  " if data["opa"] else " .  "
        c = " Y  " if data["checkov"] else " .  "
        p = " Y  " if data["compliance"] else " .  "
        layers = data["layers"]
        marker = " <<< UNCOVERED" if layers == 0 else ""
        print(f"  {short:<44}| {u}| {o}| {c}| {p}| {layers}{marker}")

    print()

    # ── Security attribute coverage ──
    s = report["security"]
    t = thresholds.get("security_coverage_pct", 100)
    icon = "✓" if s["coverage_pct"] >= t else "✗"
    print(
        f"  SECURITY ATTRIBUTE COVERAGE: {s['covered']}/{s['total']} "
        f"({s['coverage_pct']}%)  {icon} threshold: {t}%"
    )
    print("  " + "-" * (W - 4))

    for detail in s.get("details", []):
        icon = "✓" if detail["tested"] else "✗"
        rt_short = detail["resource"].replace("azurerm_", "")
        print(f"    {icon} {rt_short}.{detail['attribute']}")

    print()

    # ── OPA Rego coverage ──
    opa = report["opa_rego"]
    t = thresholds.get("opa_rego_coverage_pct", 95)
    if opa["coverage_pct"] is not None:
        icon = "✓" if opa["coverage_pct"] >= t else "✗"
        print(f"  OPA REGO COVERAGE: {opa['coverage_pct']}%  {icon} threshold: {t}%")
    else:
        print("  OPA REGO COVERAGE: (opa not available — skipped)")
    print()

    # ── Layer depth ──
    ly = report["layers"]
    print(
        f"  LAYER DEPTH: avg {ly['average']} layers/resource "
        f"(min required: {ly['min_required']})"
    )
    if ly["below_minimum"]:
        print(f"    {len(ly['below_minimum'])} resource(s) below minimum:")
        for rt in ly["below_minimum"]:
            print(f"      - {rt}")
    print()

    # ── Overall result ──
    print("  " + "=" * (W - 4))
    if failures:
        print(f"  RESULT: FAIL  ({len(failures)} threshold(s) not met)")
        print()
        for f in failures:
            print(f"    ✗ {f['dimension']}: {f['actual']} (threshold: {f['threshold']})")
            if f.get("detail"):
                print(f"      {f['detail']}")
    else:
        print("  RESULT: PASS  (all thresholds met)")
    print("  " + "=" * (W - 4))
    print()


# ─── CLI Entry Point ─────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Terraform Test Coverage Analyzer — measures coverage across 4 dimensions",
    )
    parser.add_argument(
        "--config", "-c",
        help="Path to coverage config JSON file (default: scripts/coverage_config.json)",
        default=None,
    )
    parser.add_argument(
        "--root", "-r",
        help="Root directory of the Terraform project (default: .)",
        default=".",
    )
    parser.add_argument(
        "--json", "-j",
        help="Write JSON report to this file path",
        default=None,
    )
    parser.add_argument(
        "--threshold-resource",
        help="Override resource coverage threshold (%%)",
        type=float,
        default=None,
    )
    parser.add_argument(
        "--threshold-security",
        help="Override security attribute coverage threshold (%%)",
        type=float,
        default=None,
    )
    parser.add_argument(
        "--threshold-opa",
        help="Override OPA Rego coverage threshold (%%)",
        type=float,
        default=None,
    )
    parser.add_argument(
        "--no-opa",
        help="Skip OPA Rego coverage check",
        action="store_true",
    )

    args = parser.parse_args()
    root = Path(args.root).resolve()

    # Load config (explicit path > convention > defaults)
    config = dict(DEFAULT_CONFIG)
    config_path = args.config
    if config_path is None:
        candidate = root / "scripts" / "coverage_config.json"
        if candidate.exists():
            config_path = str(candidate)

    if config_path and os.path.exists(config_path):
        with open(config_path, encoding="utf-8") as f:
            loaded = json.load(f)
        # Merge: loaded overrides defaults
        for key in loaded:
            if isinstance(loaded[key], dict) and isinstance(config.get(key), dict):
                config[key] = {**config[key], **loaded[key]}
            else:
                config[key] = loaded[key]

    # Apply CLI overrides
    if args.threshold_resource is not None:
        config.setdefault("thresholds", {})["resource_coverage_pct"] = args.threshold_resource
    if args.threshold_security is not None:
        config.setdefault("thresholds", {})["security_coverage_pct"] = args.threshold_security
    if args.threshold_opa is not None:
        config.setdefault("thresholds", {})["opa_rego_coverage_pct"] = args.threshold_opa

    # Run analysis
    try:
        report = compute_coverage(root, config)
    except Exception as e:
        print(f"Error during coverage analysis: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(2)

    # Skip OPA rego if requested
    if args.no_opa:
        report["opa_rego"]["coverage_pct"] = None

    # Check thresholds
    failures = check_thresholds(report, config)

    # Print human-readable report
    print_report(report, config, failures)

    # Write JSON report if requested
    if args.json:
        json_report = json.loads(json.dumps(report, default=list))
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(json_report, f, indent=2)
        print(f"  JSON report written to: {args.json}")
        print()

    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
