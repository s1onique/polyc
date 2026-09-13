ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 — HANDOFF (C1 RED)
==========================================================

VERDICT
-------

The C1 RED commit is the authoritative C1 boundary;
this document is descriptive. Per F-CONVERGENCE / F7 /
F15, the C2 entry gate is **OPEN subject to user
authorization of the decomposition decision** recorded
in `c1/scope-decomposition-note.txt`.

The agent does NOT self-authorize any further production
mutation.

IDENTITY
--------

```
Branch:        main
C1 RED commit: 47ea352
Predecessor:   ACT-POLYC-SELFHOST-SURFACE01 (defee14)
Entry:         bb99732 (post-patch-hygiene predecessor tree)
```

PRE-ACT STATE (F1 recon)
------------------------

* 9 tracked `.py` files (all with `#!/usr/bin/env python3`).
* 0 `__pycache__` directories in the index.
* 0 Python env metadata files (no `requirements*.txt`,
  `Pipfile`, `setup.py`, `tox.ini`, `pytest.ini`,
  `.python-version`).
* 10 caller→callee edges involving Python runtime.
  Includes one PolyC→Python subprocess from
  `tools/quality/llvm-gep01-test.HC:445..1338` to
  `scripts/quality/llvm-cap-table-verifier.py`.
* 40 existing C1-entry tool implementations (excluding
  Python) recorded in `c1/legacy-tool-baseline.tsv`.

ROOT CAUSE / FINDING
--------------------

The predecessor ACT (`ACT-POLYC-SELFHOST-SURFACE01`,
CLOSED PASS at `defee14`) is engineering-correct
(functionally delivers the S0 component framework with
conserved B3 corpus / error / cursor / lexer-seam
evidence), but its CLOSE failed to invoke two binding
checks against its own C2 IMPL surface:

1. `shell-loc-gate` — added a 197-LOC shell file
   (`selfhost-component-registry-test.sh`) without
   updating the gate's baseline.txt. (B1 PRODUCTION)
2. `make-argument-injection` — Makefile recipes at
   lines 977/982/985 interpolate `$(COMPONENT)` and
   `$(STAGE)` into recipe command text before the shell
   sees them. Reproduced: `make selfhost-component-build
   COMPONENT='x;touch /tmp/sentinel_C' STAGE='0;touch
   /tmp/sentinel_S'` creates both sentinels. (B1+B3 SAFETY)

RED
---

All C1 evidence is in
`evidence/ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01/c1/`:

| File | Demonstrates |
|------|-------------|
| `predecessor-false-green.txt` | F1/F2/F3 mechanical attribution |
| `python-inventory.tsv`        | 9-row tracked Python inventory |
| `python-invocations.tsv`      | 45-row invocation surface |
| `python-callgraph.tsv`        | 10-row caller/callee graph |
| `legacy-tool-baseline.tsv`    | 40-row existing tool baseline (excluding Python) |
| `shell-budget-red.txt`        | B1 shell-loc-gate FAIL reproduction |
| `make-argument-red.txt`       | B1+B3 Make injection reproduction |
| `selfhost-registry-baseline.txt` | Predecessor behavior freeze (1/1 PASS) |
| `selfhost-registry-test-baseline.txt` | 13/13 negative-control freeze |
| `selfhost-behavior-freeze.txt` | Full S0/B3 freeze target |
| `tool-behavior-freeze.tsv`    | Python tool contract freeze |
| `c1-required-result.txt`      | C1 binding result + extra findings |
| `scope-decomposition-note.txt`| Three execution options + recommendation |
| `README.md`                   | Index |

IMPLEMENTATION
--------------

NONE. C1 is RED-only. No production mutation has
occurred in this ACT.

GATES
-----

C1 RED did not require gate runs. The C1 evidence
itself reproduces the predecessor's CLOSE gate output
from `evidence/ACT-POLYC-SELFHOST-SURFACE01/c4/factory-gates.txt`:

```
factory-v2-test             PASS 35/35
factory-append-only-test    PASS 11/11
factory-halt-classification PASS 12/12
factory-closure-status      PASS 6/6 pairs
```

These pass on the current tree at C1 entry (47ea352).
`gate-fast` does NOT invoke `shell-loc-gate`; this is
F3 (GOVERNANCE, BLOCKS_NEXT=NO, carry-forward from
SHELL-INVENTORY01).

SCOPE
-----

C1 committed only:
* `docs/acts/ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01.md`
  (authorization artifact)
* `evidence/ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01/c1/*`
  (14 evidence files)
* this HANDOFF.md

No production code modified. No `.py`, `.sh`, `.HC`,
`.c`, `.h` modifications. No Makefile modification. No
ROADMAP.md modification.

RESIDUE
-------

P0: none — defects are mechanically demonstrated, not
prose-asserted.

P1:
* F3 gate-fast does not invoke shell-loc-gate
  (GOVERNANCE, BLOCKS_NEXT=NO; carry-forward).
* llvm-gep01-test.HC subprocess-calls Python
  (PRODUCTION if F-NO-PYTHON is enforced under Option C;
  GOVERNANCE otherwise).

P2 (deferred, future bounded ACTs):
* Migration of 9 tracked Python tools (one bounded ACT
  per tool, per MIGRATE-GEP01 precedent).
* Full F-NO-PYTHON / F-POLYC-TOOLS doctrine
  enforcement across CI.
* Comprehensive Makefile audit for unsanitised $(VAR)
  interpolations inherited from prior ACTs.
* Carried-forward residue: unit/jit runner
  (BOOTSTRAP0[1-4]); GEP01 push 26/4 (MIGRATE-GEP01);
  whitespace hygiene.

NEXT ACT
--------

The C2 IMPL commit(s) for this ACT depend on the user's
choice of decomposition option (A / B / C). The agent
recommends Option B (narrow correction only; doctrine
and migration as separate bounded ACTs) and records the
rationale in `c1/scope-decomposition-note.txt`.

If the user chooses Option A or C, the C2 IMPL strategy
is documented in the proposed ACT (§14-§41).

If the user chooses Option B, the C2 IMPL scope is:

* Either migrate `selfhost-component-registry-test.sh`
  to a PolyC harness or refactor it to ≤50 LOC and
  record it in the shell-loc-gate baseline.
* Either migrate `tools/selfhost/selfhost-component.sh`
  to a PolyC harness or split it into a ≤50 LOC
  bootstrap wrapper + PolyC core.
* Hardened the Make recipe so COMPONENT and STAGE are
  passed via exported environment / argv, validated by
  the receiving program, and rejected on shell-metachar
  input. Add a negative-control fixture to
  `evidence/.../c2/` proving `make selfhost-component-build
  COMPONENT='x;touch sentinel'` does NOT create the
  sentinel.
* Update
  `evidence/ACT-POLYC-TOOLING-SHELL-INVENTORY01/c1/baseline.txt`
  to reflect any net additions or removals.
* CLOSE this ACT exactly once with the
  `ACT-Corrected-Verdict: HALT_SHELL_BUDGET_NOT_SATISFIED`
  trailer per Factory v2 doctrine §25 (correction
  grammar; BLOCKS_NEXT=YES because the HALT is
  PRODUCTION).
* After CLOSE: HALT. The next ACT is
  `ACT-POLYC-SELFHOST-LEXER01`.

HALT TOKEN
----------

None. C2 entry gate OPEN, awaiting user authorization.
