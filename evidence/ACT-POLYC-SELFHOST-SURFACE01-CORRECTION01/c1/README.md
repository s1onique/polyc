# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 — C1 evidence

## Mission

Record the C1 RED evidence for the proposed correction ACT
that aims to (a) repair the false-green closure of
`ACT-POLYC-SELFHOST-SURFACE01` and (b) establish the permanent
Factory invariants `F-NO-PYTHON` and `F-POLYC-TOOLS`.

## Files

| File | Purpose |
|------|---------|
| `predecessor-false-green.txt` | F1/F2/F3 attribution of defects to the predecessor ACT |
| `python-inventory.tsv`        | 9 tracked `.py` files in the index at C1 entry |
| `python-invocations.tsv`      | 45 invocation sites across Make/shell/PolyC |
| `python-callgraph.tsv`        | 10 caller/callee edges for Python runtime dependency |
| `legacy-tool-baseline.tsv`    | 40 existing C1-entry tool implementations (excluding Python) |
| `shell-budget-red.txt`        | B1 reproduction: shell-loc-gate FAIL on the predecessor's added file |
| `selfhost-registry-baseline.txt` | predecessor registry validator behavior freeze (1/1 PASS) |
| `selfhost-registry-test-baseline.txt` | predecessor 13/13 negative-control matrix freeze |
| `make-argument-red.txt`       | B1+B3 reproduction: Make recipe injection via COMPONENT/STAGE |
| `c1-required-result.txt`      | Binding C1 result block + additional C1 findings |
| `scope-decomposition-note.txt`| Six logically distinct concerns; three execution options |

## Predecessor false-green findings (mechanically demonstrable)

* **F1 (PRODUCTION, BLOCKS_NEXT=YES)**: predecessor ACT C2 IMPL added
  `scripts/quality/selfhost-component-registry-test.sh` (197 LOC)
  without updating the `shell-loc-gate` baseline; gate fails on
  the predecessor's own added file.
* **F2 (SAFETY, BLOCKS_NEXT=YES)**: predecessor ACT C2 IMPL added
  Makefile recipes (lines 977/982/985) that interpolate
  `COMPONENT=$(COMPONENT)` and `STAGE=$(STAGE)` into recipe
  command text, allowing argument injection. Reproduced with
  sentinels.
* **F3 (GOVERNANCE, BLOCKS_NEXT=NO)**: `gate-fast` does not
  invoke `shell-loc-gate`. Pre-existing wiring gap from
  `SHELL-INVENTORY01`; not attributable to the predecessor
  ACT alone.

## Python census (mechanically derived from `git ls-files`)

* 9 tracked `.py` files (all with `#!/usr/bin/env python3`).
* 0 `__pycache__` directories in the index.
* 0 `requirements*.txt`, `Pipfile`, `setup.py`, `tox.ini`,
  `pytest.ini`, `.python-version`.
* 10 caller→callee edges with Python runtime dependency.
  Notable: `tools/quality/llvm-gep01-test.HC` shells out
  to `scripts/quality/llvm-cap-table-verifier.py` (the
  PolyC harness itself is a Python consumer).

## C1→C2 gate

**Status:** OPEN, subject to the user's authorization of the
decomposition decision recorded in
`scope-decomposition-note.txt`.

The agent MUST NOT silently choose Option A, B, or C. The
C1 RED packet is sufficient evidence for Options A and B;
Option C requires additional behavior-freeze documentation
that is not captured here.
