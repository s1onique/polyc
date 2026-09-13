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

==========================================================
C1.1 RED-AMEND APPENDED (commit c5e2e89)
==========================================================

VERDICT (C1.1): RED PATCH HYGIENE GREEN; READY FOR C2.

C1.1 repairs the four items the user's board response
named:

1. Two decorative `=======` underlines replaced with
   `-------` so `git diff --check bb99732..HEAD` returns
   rc=0.

2. Predecessor post-CLOSE evidence mutation recorded as
   governance residue in predecessor-false-green.txt
   (CLASS=GOVERNANCE, BLOCKS_C2=NO). The closed
   predecessor evidence is NOT touched again.

3. Option C is now recorded as the user-authorized
   decision (F7 / F15 / CONVERGENCE all SATISFIED for
   explicit scope expansion). The agent's earlier
   framing of Option C as "accepting F7/F15/CONVERGENCE
   violations" was incorrect and is superseded.

4. Tool behavior freeze expanded from 9 placeholder
   rows to a complete mechanically-observed contract
   matrix for all 7 tool families:

     a. factory-halt-classification (single + --matrix)
     b. llvm-cap-table-verifier
     c. selfhost-component-registry
     d. bootstrap-corpus-runner (b02/b03/b04 unified)
     e. bootstrap-error-corpus (b02/b03/b04 unified)
     f. inline-normalize (2x identical python3 -c)
     g. (selfhost-component.sh tooling; recorded in
        selfhost-behavior-freeze.txt)

   The freeze establishes that the 6 bootstrap scripts
   and 2 inline `python3 -c` blocks are candidates for
   consolidation in C2, not 9 unrelated systems.

5. Inline `python3 -c` execution edges counted: 2 (in
   llvm-memory01-red-test.sh and llvm-spike-test.sh).

C2 ENTRY GATE
=============

  C2_TO_C3_GATE = OPEN
  C1_TO_C2_GATE = OPEN

The agent MAY proceed to C2.x IMPL per the user's
directive without another authorization halt, stopping
only if a declared halt condition fires.

NEXT ACT (post-CLOSE of this ACT): ACT-POLYC-SELFHOST-LEXER01

==========================================================
C2.1 IMPL (commit c6ff985)
==========================================================

VERDICT (C2.1): IMPL SUBSTANTIAL; REMAINING C2.x/C3/C4 RESIDUE.

Landed in C2.1:

  * F-NO-PYTHON doctrine (DOCTRINE.md §26)
  * F-POLYC-TOOLS doctrine (DOCTRINE.md §27)
  * AGENTS.md pointer
  * PolyC authoritative checker
    tools/factory/factory-no-python-check.HC (240 LOC)
    + 27-LOC shell wrapper
    scripts/quality/factory-no-python-check.sh
  * Legacy baseline docs/factory/LEGACY-NON-POLYC-TOOLS.tsv
    (40 rows)
  * Makefile recipe injection hardening
    (F2 SAFETY defect from predecessor C2 IMPL)
  * Argument validation in selfhost-component.sh

Mechanically demonstrated:

  * PolyC checker builds and runs on this tree.
  * PolyC checker fails CLOSED on 123 current Python
    violations.
  * COMPONENT/STAGE shell-metachar injection is rejected
    with rc=2 and no sentinel created.

Remaining residue (bounded follow-on subcommits in this
same ACT; per the user's directive "do not halt again
after every migration subcommit"):

  C2.2  selfhost-component-registry.py + .sh + .test.sh
        -> PolyC
  C2.3  factory-halt-classification.py -> PolyC
  C2.4  llvm-cap-table-verifier.py -> PolyC
  C2.5  bootstrap02/03/04-corpus-runner.py
        -> consolidated bootstrap-corpus-runner.HC
  C2.6  bootstrap02/03/04-error-corpus.py
        -> consolidated bootstrap-error-corpus.HC
  C2.7  inline python3 -c blocks (2x identical) ->
        shell helper or PolyC primitive
  C2.8  full caller rewiring + Python deletion
  C2.9  shell-loc-gate baseline.txt update + Makefile
        wiring of factory-no-python-check + policy
        checker wiring of factory-polyc-tools-check
  C3    EVIDENCE: fresh-tree Python-less re-proof
  C4    CLOSE: single commit with corrected-verdict
        trailers (ACT-Corrected-Verdict:
        HALT_SHELL_BUDGET_NOT_SATISFIED;
        HALT_CLASS: PRODUCTION; BLOCKS_NEXT: YES)

IDENTITY (C2.1)
================

  Branch:        main
  C1 RED:        47ea352
  C1.1:          c5e2e89
  C2.1:          c6ff985
  HANDOFF:       this file (committed at C1.1; C2.1
                appended here for narrative continuity)
  HEAD:          c6ff985

NO PRODUCTION SEMANTIC MUTATION.
NO NEW BOOTSTRAP STAGE.
NO COMPILER LEXER/PARSER/AST/IR/BACKEND CHANGE.
