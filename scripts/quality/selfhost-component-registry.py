#!/usr/bin/env python3
# scripts/quality/selfhost-component-registry.py
#
# ACT-POLYC-SELFHOST-SURFACE01 C2 IMPL — registry validator.
#
# Reads docs/factory/SELF-HOST-COMPONENTS.tsv, validates
# every row mechanically, and emits either:
#
#   PASS lines (one per row, then a summary)
#   or one FAIL line describing the first defect
#
# Exit code:
#   0  registry is well-formed (every row PASS)
#   1  any defect detected
#
# No hidden defaults. No best-effort parsing. Malformed
# registry => FAIL_CLOSED.
#
# Usage:
#   selfhost-component-registry.py [path-to-registry.tsv]
#
# If no path is given, defaults to
# docs/factory/SELF-HOST-COMPONENTS.tsv at the repo root.
#
# This script does NOT touch the build system. It only
# validates metadata. The build driver is
# tools/selfhost/selfhost-component.sh.

import os
import sys
import re

REPO_ROOT = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
)
DEFAULT_REGISTRY = os.path.join(
    REPO_ROOT, "docs", "factory", "SELF-HOST-COMPONENTS.tsv"
)

EXPECTED_HEADER = [
    "component_id",
    "source",
    "symbol",
    "consumer_seam",
    "language",
    "state",
    "oracle",
    "cursor_gate",
    "production_seam_gate",
    "introduced_by",
]

VALID_LANGUAGES = {"POLYC"}
VALID_STATES = {"STABLE", "MIGRATING", "DISABLED"}

# Generator-stage to producer binary map (binding).
# Stage 0 = ./hcc, stage 1 = hcc-bootstrap02, etc.
STAGE_PRODUCERS = {
    0: "./hcc",
    1: "./build/hcc-bootstrap02",
    2: "./build/hcc-bootstrap03",
}

# Generic output paths (binding, deterministic).
GENERIC_OUTPUT_TEMPLATE = "build/selfhost/stage{stage}/{component_id}.o"


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def validate_registry(path):
    if not os.path.isfile(path):
        fail(f"registry not found: {path}")

    with open(path, "r", encoding="utf-8") as fh:
        raw_lines = [ln.rstrip("\r\n") for ln in fh]
    lines = [ln for ln in raw_lines if ln.strip() != ""]
    if not lines:
        fail("registry is empty")

    header = lines[0].split("\t")
    if header != EXPECTED_HEADER:
        fail(
            "registry header mismatch.\n"
            f"  expected ({len(EXPECTED_HEADER)} fields): {EXPECTED_HEADER}\n"
            f"  got      ({len(header)} fields): {header}"
        )

    rows = lines[1:]
    component_ids = set()
    parsed_rows = []

    for idx, line in enumerate(rows, start=2):
        fields = line.split("\t")
        if len(fields) != len(EXPECTED_HEADER):
            fail(
                f"row {idx}: malformed field count "
                f"(expected {len(EXPECTED_HEADER)}, got {len(fields)}): {line!r}"
            )
        row = dict(zip(EXPECTED_HEADER, fields))

        cid = row["component_id"].strip()
        if cid == "":
            fail(f"row {idx}: component_id is empty")
        if cid in component_ids:
            fail(f"row {idx}: duplicate component_id {cid!r}")
        component_ids.add(cid)

        src = row["source"].strip()
        if src == "":
            fail(f"row {idx}: source is empty for {cid!r}")
        if os.path.isabs(src):
            fail(f"row {idx}: source {src!r} must be repository-relative")
        parts = src.split("/")
        if ".." in parts:
            fail(f"row {idx}: source {src!r} contains '..'; refuses to escape repo")
        full_src = os.path.join(REPO_ROOT, src)
        if not os.path.isfile(full_src):
            fail(f"row {idx}: source file does not exist: {src}")

        sym = row["symbol"].strip()
        if sym == "":
            fail(f"row {idx}: symbol is empty for {cid!r}")
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", sym):
            fail(f"row {idx}: symbol {sym!r} is not a valid C identifier")

        csm = row["consumer_seam"].strip()
        if csm == "":
            fail(f"row {idx}: consumer_seam is empty for {cid!r}")
        if "::" not in csm:
            fail(f"row {idx}: consumer_seam {csm!r} must be path::function form")

        lang = row["language"].strip()
        if lang not in VALID_LANGUAGES:
            fail(
                f"row {idx}: invalid language {lang!r} "
                f"(expected one of {sorted(VALID_LANGUAGES)})"
            )

        st = row["state"].strip()
        if st not in VALID_STATES:
            fail(
                f"row {idx}: invalid state {st!r} "
                f"(expected one of {sorted(VALID_STATES)})"
            )

        for key in (
            "oracle",
            "cursor_gate",
            "production_seam_gate",
            "introduced_by",
        ):
            v = row[key].strip()
            if v == "":
                fail(f"row {idx}: {key} is empty for {cid!r}")

        # Output-aliases-source guard. Because the generic
        # template always appends ".o", a literal alias
        # requires the source to also end in ".o". Since
        # all real PolyC sources end in ".HC", a literal
        # alias is structurally impossible today. We keep
        # this guard as a future-proofing check for the
        # day a source ends in ".o" (e.g. a PolyC-built
        # object that needs to be re-emitted). Construct a
        # temporary source path that ends in ".o" and
        # attempt an alias; if it cannot be constructed
        # because the file doesn't exist, we skip the
        # alias probe here (the source-existence check
        # above already enforces reality).
        generic_out = GENERIC_OUTPUT_TEMPLATE.format(stage=0, component_id=cid)
        if src.endswith(".o") and os.path.normpath(generic_out) == os.path.normpath(src):
            fail(
                f"row {idx}: generic output {generic_out!r} "
                f"aliases source {src!r}"
            )

        parsed_rows.append({
            "lineno": idx,
            "component_id": cid,
            "source": src,
            "symbol": sym,
            "consumer_seam": csm,
            "language": lang,
            "state": st,
            "oracle": row["oracle"].strip(),
            "cursor_gate": row["cursor_gate"].strip(),
            "production_seam_gate": row["production_seam_gate"].strip(),
            "introduced_by": row["introduced_by"].strip(),
        })

    return parsed_rows


def lookup_component(rows, component_id):
    matches = [r for r in rows if r["component_id"] == component_id]
    if not matches:
        fail(f"unknown component_id: {component_id!r}")
    if len(matches) > 1:
        fail(f"multiple rows match component_id {component_id!r}")
    return matches[0]


def resolve_producer(stage):
    if stage not in STAGE_PRODUCERS:
        fail(
            f"unknown producer stage: {stage} "
            f"(expected one of {sorted(STAGE_PRODUCERS)})"
        )
    return STAGE_PRODUCERS[stage]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_REGISTRY
    rows = validate_registry(path)

    makefile = os.path.join(REPO_ROOT, "Makefile")
    if not os.path.isfile(makefile):
        fail(f"Makefile not found at {makefile}")

    with open(makefile, "r", encoding="utf-8") as fh:
        makefile_text = fh.read()

    for r in rows:
        if r["state"] == "DISABLED":
            print(
                f"DISABLED: {r['component_id']} (registered; no build/test)"
            )
            continue
        for key in ("oracle", "cursor_gate", "production_seam_gate"):
            target = r[key]
            pat = re.compile(
                rf"^{re.escape(target)}\s*:", re.MULTILINE
            )
            if not pat.search(makefile_text):
                fail(
                    f"row {r['lineno']}: Makefile target for "
                    f"{key} {target!r} not found "
                    f"(component {r['component_id']!r})"
                )

    print(f"PASS: {len(rows)} component row(s) validated against {path}")
    for r in rows:
        print(
            f"  - {r['component_id']} [{r['state']}] "
            f"source={r['source']} symbol={r['symbol']}"
        )


if __name__ == "__main__":
    main()
