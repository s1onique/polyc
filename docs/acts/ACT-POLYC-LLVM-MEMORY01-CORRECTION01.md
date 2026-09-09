# ACT-POLYC-LLVM-MEMORY01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** MEMORY01 closure-contract correction: NC5 hardening + REJECTED>0 falsification record + topology prose repair

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-MEMORY01` (PASS) — produces the semantic
  capability extension that this ACT hardens at the
  closure-contract layer. NO production code change in this ACT.
- `ACT-POLYC-LLVM-CORE04-RESUME01` (PASS) — establishes the
  per-class counter contract that NC5 inherits from.
- `ACT-POLYC-LLVM-CORE03-CORRECTION02` (PASS) — establishes the
  class-generic vs per-opcode rejection pattern.

**Class:** QUALITY-GATES + DOCUMENTATION (no production code change)

**Production semantic changes:** FORBIDDEN — no `src/` change unless
NC5 probe surfaces a real counter bug.

**IR / ABI / LLVM authorization:** NONE.

---

## 0. Mission

Three small closure-contract corrections to MEMORY01 identified by
the post-closure reviewer:

1. **NC5 (P0)**: harden the counter-regression negative control
   from "weak (aggregate SHAPE_DEPENDENT>=1)" to a strong
   per-fixture attribution with an independent regression probe.
2. **REJECTED>0 expectation (P1)**: explicitly record the falsified
   expectation in ROADMAP / NC summary / HANDOFF; the closure must
   say "REJECTED > 0 expectation = FALSIFIED / NOT APPLICABLE TO
   MEMORY01 MATRIX" rather than silently relaxing the gate.
3. **Stale topology prose (P1)**: ROADMAP says "3 commits + a
   docs/ROADMAP update"; actual range is 5 commits. Fix once.

This is a tiny Factory-v2 correction ACT. If the strong NC5 probe
passes after the test-only hardening, the existing MEMORY01
production code stays untouched.

## 1. Why

Reviewer disposition against the MEMORY01 closure identified:

- NC5 is admitted as weak in
  `evidence/llvm-memory01/negative-controls/nc-summary.md`:
  suppressing the dereference counter could still leave the
  aggregate `SHAPE_DEPENDENT >= 1` because `IR_STORE`
  shape-handling contributes counts. The closure does NOT prove
  the dereference counters increment correctly.

- ACT §11 expected `REJECTED > 0`, but the closure matrix has
  `REJECTED = 0`. The original docstring was "the harness
  deliberately does not enforce REJECTED > 0" without recording
  the reason. Cause: the negative fixture is rejected at the
  class-generic parameter-type seam BEFORE any per-opcode
  dispatch arm runs, so per-opcode REJECTED never increments.
  This is legitimate but must be explicitly recorded, not
  silently relaxed.

- ROADMAP topology prose says "3 commits" but the actual range
  is 5 commits. Stale documentary fact.

These are exactly the kind of small closure defects Factory v2
should make cheap to correct.

## 2. Scope

### allowed

- `scripts/quality/llvm-memory01-test.sh` — add per-fixture counter
  recording + per-fixture NC5 assertions.
- `scripts/quality/llvm-memory01-nc5-probe.sh` (NEW) — independent
  regression probe that mutates source, rebuilds, runs the
  harness, verifies RED.
- `evidence/llvm-memory01/negative-controls/nc-summary.md` —
  replace NC5 section with strong form; archive the historical
  weak form.
- `evidence/llvm-memory01/negative-controls/nc5-weak-historical.md`
  (NEW) — F14-archived historical weak form.
- `docs/ROADMAP.md` — fix stale commit-count prose; record
  REJECTED>0 falsification.
- `evidence/llvm-memory01/closure/HANDOFF.md` — add CORRECTION01
  follow-up section.
- `docs/acts/ACT-POLYC-LLVM-MEMORY01-CORRECTION01.md` (this file).
- `evidence/llvm-memory01-correction01/` (NEW) — closure evidence.

### forbidden

- ANY change to `src/llvm-backend.c`, `src/llvm-backend.h`,
  `src/llvm-backend-cap.c`, `src/llvm-backend-cap.h`.
- ANY change to `src/ir*.c`, `src/ir*.h`, native backends,
  parser, lexer, type checker, language syntax.
- ANY change to `src/tests/llvm-memory01/*` (production
  fixtures are historical evidence; F14).
- ANY change to Factory v2 metadata, gate-fast,
  factory-v2-test, factory-v2-range-check.
- ANY change to `Makefile`, `CMakeLists.txt`.
- CI / framework / container changes.

## 3. Entry gate

```text
git branch --show-current  = main
git status --short         = clean (the post-CLOSE state of MEMORY01)
git rev-parse HEAD         = (MEMORY01 CLOSE SHA)
```

The predecessor `ACT-POLYC-LLVM-MEMORY01` is the only allowed
entry state.

## 4. Principal RED

The principal RED is documentary: the original NC5 prose in
`evidence/llvm-memory01/negative-controls/nc-summary.md` admits
weakness, and a captured closure transcript shows that
suppressing the `LL_INC_SHAPE_DEPENDENT(lc)` call inside
`case IR_LOAD_DEREF:` leaves the existing aggregate counter
gate `SHAPE_DEPENDENT>=1` satisfied (because the IR_STORE
shape-handling path still contributes 4 to the aggregate —
exactly the falsifying witness).

RED transcript (captured before any IMPL change): see
`evidence/llvm-memory01-correction01/red/nc5-weak-red.txt`.

```text
SUPPORTED           : 7
REJECTED            : 0
SHAPE_DEPENDENT     : 4     <-- aggregate >= 1, existing gate PASS
DEFENSIVE_INVARIANT : 0
UNREACHABLE_ON_LLVM : 0
PASS  counter gate: SHAPE_DEPENDENT>=1, SUPPORTED>=1, DEFENSIVE=0, UNREACHABLE=0
=================================
MEMORY01 GREEN summary: PASS=6 FAIL=0   <-- silently GREEN
=================================
```

## 5. Implementation boundary

Minimum change required:

1. In `scripts/quality/llvm-memory01-test.sh`:
   - Extend `parse_and_sum_counters` to write a per-fixture
     counter file (one file per fixture basename).
   - Add a `=== MEMORY01 NC5 per-fixture attribution ===`
     section with `check_nc5_eq` / `check_nc5_min` helpers and
     per-fixture expectations.
2. Add `scripts/quality/llvm-memory01-nc5-probe.sh`:
   - snapshot source; awk-based mutation to delete one
     `LL_INC_SHAPE_DEPENDENT(lc);` inside `case IR_LOAD_DEREF:`;
   - rebuild; run harness; assert harness FAILs on the
     `FAIL  NC5 red_load_deref` line;
   - restore source (cp before rm in the EXIT trap — order
     matters; verified).
3. Update docs (NC summary, ROADMAP, HANDOFF).

Deliberately NOT included:

- per-opcode REJECTED counter for the class-generic rejection
  path (would change the diagnostic flow; out of scope).
- broader NC re-binding (NC1..NC4 are unchanged from MEMORY01
  closure and the reviewer confirmed them).

## 6. Acceptance criteria

AC01: `make clean && make llvm-all` → rc=0.
AC02: `sh scripts/quality/llvm-memory01-test.sh` →
      `PASS=6 FAIL=0` AND
      `PASS  NC5 per-fixture attribution: SHAPE_DEPENDENT uniquely attributable to IR_LOAD_DEREF / IR_STORE_DEREF`.
AC03: `sh scripts/quality/llvm-memory01-nc5-probe.sh` →
      rc=0 AND
      `PASS probe: NC5 strong binding confirmed.`
AC04: negative-control test for the probe: temporarily disable
      the `check_nc5_min red_load_deref     1` line in the
      harness, re-run the probe, observe rc=1 with
      `FAIL probe: NC5 strong binding NOT confirmed.`
      (AC recorded; the actual mutation is reverted at the
      end of the verification phase.)
AC05: `sh scripts/quality/llvm-spike-test.sh` →
      `PASS=18 FAIL=0` (conservation).
AC06: `python3 scripts/quality/llvm-cap-table-verifier.py` →
      `PASS: dispatch <-> capability <-> harness bound`.
AC07: `sh scripts/quality/factory-v2-test.sh` →
      `PASS=35 FAIL=0`.
AC08: `sh scripts/quality/gate-fast.sh` → `VERDICT=PASS`.
AC09: `git diff --check <CORRECTION01-FIRST>..HEAD` → rc=0.
AC10: ROADMAP, NC summary, and HANDOFF each contain the
      REJECTED>0 falsification record AND the corrected
      topology prose.
AC11: `sh scripts/quality/factory-v2-range-check.sh
      ACT-POLYC-LLVM-MEMORY01-CORRECTION01 HEAD` →
      `STATUS=PASS VERDICT=PASS` (single CLOSE).

## 7. Conservation gates

All conservation gates from MEMORY01 must remain PASS:

- llvm-memory01-test.sh: PASS=6 FAIL=0 (now with per-fixture
  NC5 attribution PASS line).
- llvm-spike-test.sh: PASS=18 FAIL=0.
- llvm-cap-table-verifier: PASS.
- factory-v2-test: PASS=35 FAIL=0.
- gate-fast: VERDICT=PASS.
- git diff --check <MEMORY01-FIRST>..HEAD: clean (this ACT
  must not regress MEMORY01 closure hygiene).
- factory-v2-range-check.sh ACT-POLYC-LLVM-MEMORY01 HEAD:
  STATUS=PASS VERDICT=PASS (regression check on the parent
  ACT's verdict).

## 8. Halt taxonomy

- HALT_SCOPE_EXPANSION_REQUIRED — if any required correction
  needs a `src/` change.
- HALT_TEST_WEAKENING — if a per-fixture assertion is removed
  to make a RED go GREEN.
- HALT_RED_NOT_REPRODUCED — if the regression probe fails to
  detect the IR_LOAD_DEREF counter suppression.
- HALT_HISTORICAL_EVIDENCE_MUTATION — if the original weak
  NC5 prose is rewritten rather than archived.

## 9. Residue

P0: any IR_LOAD_DEREF counter-suppression bug exposed by the
regression probe (would be a real counter bug; HALT and
recommend a separate IR ACT).

P1 (carried from MEMORY01): neutral-IR-level fix for the
`as._i64` / `as.var.id` union aliasing is out of scope for
both MEMORY01 and this correction.

P2: N1-N4 in MEMORY01 §14 are still
NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE.

## 10. Commit topology

Factory v2 has no numeric commit cap. The natural ordering for
this correction is:

```text
RED         : docs/acts/ACT-POLYC-LLVM-MEMORY01-CORRECTION01.md
              + evidence/llvm-memory01-correction01/red/nc5-weak-red.txt
              (record the original weak transcript)
IMPL        : scripts/quality/llvm-memory01-test.sh
              + scripts/quality/llvm-memory01-nc5-probe.sh
EVIDENCE    : evidence/llvm-memory01/negative-controls/nc-summary.md
              + nc5-weak-historical.md
              + docs/ROADMAP.md
              + evidence/llvm-memory01/closure/HANDOFF.md
              + evidence/llvm-memory01-correction01/closure/*.txt
CLOSE       : ACT-Verdict: PASS
```

Each commit is a proof step. No commit combines unrelated cleanup.

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md` and write a HANDOFF at
`evidence/llvm-memory01-correction01/HANDOFF.md` (note: under
the new evidence root for this ACT, NOT under the MEMORY01
root). The HANDOFF summary must contain: VERDICT, IDENTITY,
RED, IMPLEMENTATION, GATES, CONSERVATION, REJECTED>0
FALSIFICATION, NC5 STRONG BINDING, TOPOLOGY PROSE, SCOPE,
RESIDUE, NEXT ACT.

## Execution metadata

```
ACT: ACT-POLYC-LLVM-MEMORY01-CORRECTION01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
ACT-Verdict: <token>      (CLOSE only)
```

Lifecycle tokens:

- `OPEN` — file written; no commits yet.
- `IN_FLIGHT` — at least one commit in the range.
- `CLOSED` — CLOSE commit with `ACT-Verdict: PASS` exists;
  Factory v2 range-check returns
  `STATUS=PASS VERDICT=PASS`.
