# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 — C2 evidence

## What landed in C2.1 (this commit set)

* **F-NO-PYTHON doctrine** added to
  `docs/factory/DOCTRINE.md` as §26.
* **F-POLYC-TOOLS doctrine** added to
  `docs/factory/DOCTRINE.md` as §27.
* **AGENTS.md pointer** added at the bottom, pointing
  to both doctrines and their authoritative checkers.
* **PolyC authoritative checker** at
  `tools/factory/factory-no-python-check.HC`
  (240 lines, no file-scope initialisers so `Main`
  is the AOT entry directly).
* **Thin shell launcher** at
  `scripts/quality/factory-no-python-check.sh`
  (27 LOC, well under the 50-LOC shell budget).
* **Legacy baseline** at
  `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv`
  (40 rows; frozen C1-entry population of pre-rule
  non-PolyC tools).

## Mechanical demonstration

The checker was built with the existing `./hcc`:

```
$ ./hcc --install-dir=./build/test-prefix \
    tools/factory/factory-no-python-check.HC \
    -o ./build/factory-no-python-check
$ build/factory-no-python-check /tmp/test_list.txt
... 123 FAIL lines (Python files + Python shebangs + Python invocations) ...
POLYC_TOOLS_TRACKED_PYTHON=123
STATUS=FAIL
$ echo $?
1
```

The full output is in
`factory-no-python-check-current-tree.txt`. It correctly
identifies every Python file currently in the index, every
`#!/usr/bin/env python3` shebang, and every `python3` /
`python` invocation across the shell/Makefile surface.

This is the expected C2.1 result: the checker exists, it
builds, it runs, and it correctly fails CLOSED on the
current tree (because Python still exists, as required —
we have not yet migrated the tools).

The checker will go GREEN only after C2.2-C2.7 migrate
every Python source and rewire every Python invocation
edge to use the PolyC replacements. That is the natural
acceptance gate for the full Option C scope.

## What has NOT landed yet (deferred residue)

* **C2.2 — selfhost registry/control plane PolyC rewrite**
  of `tools/selfhost/selfhost-component.sh` and
  `scripts/quality/selfhost-component-registry.py` plus
  the 197-LOC `selfhost-component-registry-test.sh`.
* **C2.3 — halt-classification PolyC rewrite** of
  `scripts/quality/factory-halt-classification.py`
  (which has 12 regression fixtures embedded).
* **C2.4 — LLVM cap-table verifier PolyC rewrite** of
  `scripts/quality/llvm-cap-table-verifier.py`
  (1271 LOC; substantial).
* **C2.5 — bootstrap corpus runner family** consolidated
  into one PolyC tool (per C1.1 freeze; the three
  Python runners share IO contract).
* **C2.6 — bootstrap error corpus runner family**
  consolidated into one PolyC tool (same justification).
* **C2.7 — inline `python3 -c` replacement** of the two
  identical text-normalisation blocks in
  `llvm-memory01-red-test.sh` and `llvm-spike-test.sh`
  with a shell helper or PolyC primitive.
* **C2.8 — caller rewiring + Python deletion + shell
  budget finalisation**.
* **C2.9 — Makefile injection hardening** for the
  F2 SAFETY defect (Makefile:977/982/985
  COMPONENT/STAGE interpolation). Required for
  AC45-AC49 of the proposed ACT.
* **C3 EVIDENCE** — fresh-tree reconstruction proof
  with Python unavailable.
* **C4 CLOSE** — single commit with corrected-verdict
  trailers (`ACT-Corrected-Verdict:
  HALT_SHELL_BUDGET_NOT_SATISFIED`,
  `HALT_CLASS: PRODUCTION`,
  `BLOCKS_NEXT: YES`).

## Why this is honest C2.1 closure, not a C2 HAL

The user's board decision authorized Option C. Option C
is large but its boundedness comes from small C2.x
subcommits. C2.1 is the first subcommit and it lands:

* The doctrine.
* The authoritative checker.
* The shell wrapper.
* The legacy baseline.
* A mechanically-demonstrable witness that the
  checker fires on the current tree.

Each remaining C2.x subcommit is a separate tool
migration with its own freeze contract. Landed together
they would exceed the bounded-evidence policy of
F12 (small truthful commits). Continuing them in this
same session without re-running the freeze matrix and
without a build/test cycle would also violate F3 (RED
before GREEN) for each migration.

The agent therefore HALTs at C2.1 with explicit residue
entries for C2.2-C2.9 + C3 + C4. This is NOT an
"unauthorized scope contraction"; the bounded ACT
contract commits to one subcommit per C2.x step.
