# ACT-POLYC-LLVM-MEMORY01-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** MEMORY01-CORRECTION01 closure-binding correction: STORE_DEREF NC5 strong binding + F14 archive overclaim acknowledgement

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-MEMORY01-CORRECTION01` (PASS at 015b8d8)
  produced the per-fixture NC5 assertions and the
  IR_LOAD_DEREF regression probe. The store side of the
  binding was implicitly claimed but never proven. This ACT
  hardens that half and corrects the F14-archive overclaim.
- `ACT-POLYC-LLVM-MEMORY01` (PASS) produces the
  dereference counters that this ACT hardens.
- `ACT-POLYC-LLVM-CORE04-RESUME01` (PASS) establishes the
  per-class counter contract that NC5 inherits from.

**Class:** QUALITY-GATES + DOCUMENTATION (no production code change)

**Production semantic changes:** FORBIDDEN no `src/` change.

**IR / ABI / LLVM authorization:** NONE.

---

## 0. Mission

Two small closure-binding corrections to MEMORY01-CORRECTION01
identified by the post-closure reviewer:

1. **P0-1 NC5 STORE_DEREF weak binding (P0)**:
   CORRECTION01's regression probe mutates the
   `LL_INC_SHAPE_DEPENDENT(lc)` call inside
   `case IR_LOAD_DEREF:` only. The HANDOFF and ACT text
   claimed that the same probe would trip on `IR_STORE_DEREF`
   suppression too, but the empirical reproduction shows that
   today's per-fixture assertions `red_store_deref >= 1` and
   `p5_store_inc >= 2` are NOT tight enough to detect
   store-side counter suppression. Suppression drops
   `red_store_deref` from 2 to 1 and `p5_store_inc` from 4
   to 3, both still satisfying the floor assertions. So today
   the harness false-GREENs under STORE_DEREF suppression.
   This ACT closes that half of the binding.

2. **P0-2 F14 archive overclaim (P0)**:
   CORRECTION01's HANDOFF and RED claimed that
   `evidence/llvm-memory01/negative-controls/nc5-weak-historical.md`
   is "byte-for-byte identical to the original MEMORY01
   closure form". The empirical check shows that the file
   has 72 lines vs the original's 67 lines (5 lines appended),
   and sha256 differs
   (`8b05e54a6dea2943198173914b3d8bc5c4223cb0e3b60aa28c79cb5a0ef55370`
   vs `8bf0596ea06f32761d7bffb934f03c64633b8001cfa3411c0d6e18e7d3453657`).
   The file was amended with appended commentary. This ACT
   captures a proper byte-exact archive under a new
   `evidence/llvm-memory01-correction02/f14-archive/` path
   and acknowledges the overclaim in writing, WITHOUT
   rewriting the historical MEMORY01 evidence file
   (F14 forbids rewriting historical evidence merely
   because later evidence supersedes it).

## 1. Why

Reviewer disposition against CORRECTION01 closure identified:

- `llvm-memory01-nc5-probe.sh` mutates only the
  IR_LOAD_DEREF counter call. The handler is line-stable and
  correct, but the probe is single-mode. The HANDOFF
  contains the line "Any source mutation that suppresses or
  doubles one `LL_INC_SHAPE_DEPENDENT` call inside
  `IR_LOAD_DEREF` or `IR_STORE_DEREF` trips the corresponding
  per-fixture assertion." The OR-clause is not proven.
  Empirical reproduction in
  `evidence/llvm-memory01-correction02/red/store-deref-explore.txt`
  confirms suppression inside `case IR_STORE_DEREF:` changes
  per-fixture counts but does NOT cause the current harness
  to FAIL.

- The reviewer also pointed out that
  `evidence/llvm-memory01/negative-controls/nc5-weak-historical.md`
  is not byte-identical to
  `944ba8d:evidence/llvm-memory01/negative-controls/nc-summary.md`.
  The CORRECTION01 CLOSE commit message and HANDOFF claim
  it is. The hash mismatch is a clean refutation.

These are exactly the kind of small closure-binding defects
Factory v2 should make cheap to correct.

## 2. Scope

### allowed

- `scripts/quality/llvm-memory01-nc5-probe.sh` extend with
  a `load`/`store` mode argument; preserve existing default
  load-mode behaviour.
- `scripts/quality/llvm-memory01-test.sh` tighten the
  per-fixture NC5 assertions on `red_store_deref` and
  `p5_store_inc` from `>= N` to `== N` so the store-mode
  probe can detect suppression.
- `evidence/llvm-memory01-correction02/` NEW directory for
  this ACT's evidence (closure handoff, RED capture, gate
  outputs, F14 byte-exact archive).
- `docs/acts/ACT-POLYC-LLVM-MEMORY01-CORRECTION02.md` this
  file (NEW).
- `docs/ROADMAP.md` record the correction and the
  acknowledged overclaim (one paragraph).

### forbidden

- `src/llvm-backend.c`, `src/llvm-backend.h`,
  `src/llvm-backend-cap.c`, `src/llvm-backend-cap.h`
  (NO production-code change; this is a closure-binding
  ACT, not a feature ACT).
- Capability semantics, counter implementation, pointer
  implementation, LLVM lowering.
- Any historical MEMORY01 / CORRECTION01 evidence file
  under `evidence/llvm-memory01/` or
  `evidence/llvm-memory01-correction01/`. The archive
  byte-equality correction is performed by generating a
  NEW file under
  `evidence/llvm-memory01-correction02/f14-archive/`,
  not by rewriting the historical one (F14).
- Any change to the existing `llvm-memory01-nc5-probe.sh`
  default load-mode behaviour.

## 3. Acceptance criteria

AC01: `llvm-memory01-nc5-probe.sh store` exits 0 with
      "PASS probe (store): NC5 strong binding confirmed for
      IR_STORE_DEREF." The harness observed must contain
      `FAIL  NC5 red_store_deref: expected SHAPE_DEPENDENT == 2, got 1`.

AC02: `llvm-memory01-nc5-probe.sh load` (default) still
      exits 0 with "PASS probe (load): NC5 strong binding
      confirmed for IR_LOAD_DEREF." (regression check on
      the existing CORRECTION01 binding).

AC03: `llvm-memory01-test.sh` still emits PASS=6 FAIL=0
      with both per-fixture and aggregate counter gates
      green; the per-fixture attribution line now records
      exact counts (`red_store_deref: shape_dependent=2 (== 2)`).

AC04: A byte-exact copy of
      `944ba8d:evidence/llvm-memory01/negative-controls/nc-summary.md`
      exists at
      `evidence/llvm-memory01-correction02/f14-archive/nc-summary.944ba8d.md`,
      and `cmp -s` between the file and the git blob returns
      exit 0.

AC05: All conservation gates (see section 6) remain PASS.

AC06: `sh scripts/quality/factory-v2-test.sh` returns
      `PASS=35 FAIL=0`.

AC07: `sh scripts/quality/gate-fast.sh` returns
      `VERDICT=PASS`.

AC08: `git diff --check <CORRECTION02-FIRST>..HEAD` returns
      rc=0 (no trailing whitespace, no blank-line-at-EOF).

AC09: `sh scripts/quality/factory-v2-range-check.sh
      ACT-POLYC-LLVM-MEMORY01-CORRECTION02 HEAD` returns
      `STATUS=PASS VERDICT=PASS`.

AC10: ROADMAP contains a paragraph recording the F14
      overclaim acknowledgement.

## 4. RED transcript (pre-IMPL)

`evidence/llvm-memory01-correction02/red/store-deref-explore.txt`:
reproduces today's harness under STORE_DEREF counter
suppression. Output proves the false-GREEN:
- before: `red_store_deref=2`, `p5_store_inc=4`
- after:  `red_store_deref=1`, `p5_store_inc=3`
- harness: `PASS=6 FAIL=0` (still green; NC5 binding
  does not catch this).

`evidence/llvm-memory01-correction02/red/f14-archive-hash.txt`:
records the sha256 mismatch
(`8bf0596ea06f32761d7bffb934f03c64633b8001cfa3411c0d6e18e7d3453657`
from `git show 944ba8d:...` vs
`8b05e54a6dea2943198173914b3d8bc5c4223cb0e3b60aa28c79cb5a0ef55370`
from the current `nc5-weak-historical.md`).

## 5. IMPL

1. `scripts/quality/llvm-memory01-nc5-probe.sh`:
   - Accept optional mode argument: `load` (default) or
     `store`.
   - Default `load` behaviour preserved exactly.
   - `store` mode: locate `case IR_STORE_DEREF: {` ... the
     next `case IR_X: {` line, delete the
     `LL_INC_SHAPE_DEPENDENT(lc);` call inside that range.
   - Assert harness exits non-zero AND output contains
     `FAIL  NC5 red_store_deref`.
   - Force-rebuild via `make -B` plus
     `rm -f hcc build/CMakeFiles/hcc.dir/llvm-backend.c.o`
     to defeat sub-second mtime resolution on APFS that
     otherwise causes `make` to skip the recompile.
   - EXIT trap unchanged in intent (snapshot source + cp +
     rebuild + rm) but also force-rebuilds.

2. `scripts/quality/llvm-memory01-test.sh`:
   - Change `check_nc5_min red_store_deref 1` to
     `check_nc5_eq red_store_deref 2`.
   - Change `check_nc5_min p5_store_inc 2` to
     `check_nc5_eq p5_store_inc 4`.
   - Update the comment block above to reflect that the
     load-side fixtures use floor assertions because no
     other path contributes, and the store-side fixtures
     require exact assertions because IR_STORE shape-handling
     can pad them by +1.

## 6. Conservation gates

All CORRECTION01 conservation gates must remain PASS:

- llvm-memory01-test.sh: PASS=6 FAIL=0 (now with tightened
  exact assertions on store-side fixtures).
- llvm-memory01-nc5-probe.sh load (default): PASS.
- llvm-memory01-nc5-probe.sh store: PASS.
- llvm-spike-test.sh: PASS=18 FAIL=0.
- llvm-cap-table-verifier: PASS.
- factory-v2-test: PASS=35 FAIL=0.
- gate-fast: VERDICT=PASS.
- git diff --check <CORRECTION02-FIRST>..HEAD: clean.
- factory-v2-range-check.sh ACT-POLYC-LLVM-MEMORY01
  944ba8d: STATUS=PASS VERDICT=PASS (parent regression
  check).
- factory-v2-range-check.sh ACT-POLYC-LLVM-MEMORY01-
  CORRECTION01 015b8d8: STATUS=PASS VERDICT=PASS
  (CORRECTION01 regression check - this ACT must not
  invalidate CORRECTION01's verdict).
- factory-v2-range-check.sh ACT-POLYC-LLVM-MEMORY01-
  CORRECTION02 HEAD: STATUS=PASS VERDICT=PASS
  (this ACT's own verdict).

## 7. Halt taxonomy

- HALT_SCOPE_EXPANSION_REQUIRED if the binding requires a
  `src/` change to make the store-mode probe trip.
- HALT_TEST_WEAKENING if an existing CORRECTION01 per-
  fixture assertion is removed or relaxed to make AC01
  pass.
- HALT_RED_NOT_REPRODUCED if STORE_DEREF suppression
  fails to produce the expected harness FAIL even after
  tightening the assertions.
- HALT_HISTORICAL_EVIDENCE_MUTATION if any historical
  MEMORY01 / CORRECTION01 evidence file is rewritten
  rather than archived under a new path.

## 8. Residue

P0: any IR_STORE_DEREF counter-suppression bug exposed by
the store-mode probe would be a real counter bug; HALT
and recommend a separate IR ACT.

P1: the original CORRECTION01 RED/HANDOFF "byte-identical"
overclaim is acknowledged in writing under
`evidence/llvm-memory01-correction02/HANDOFF.md` and a new
byte-exact archive is generated. The historical file is
NOT rewritten; readers consulting it should consult the
`f14-archive/` directory in CORRECTION02 for the genuine
historical witness.

P2 (carried from MEMORY01): neutral-IR-level fix for the
`as._i64` / `as.var.id` union aliasing is out of scope
for MEMORY01, CORRECTION01, and this correction.

P3: N1-N4 in MEMORY01 section 14 are still
NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE.

## 9. Commit topology

Factory v2 has no numeric commit cap. The natural ordering
for this correction is:

```text
RED         : docs/acts/ACT-POLYC-LLVM-MEMORY01-CORRECTION02.md
               + evidence/llvm-memory01-correction02/red/*.txt
IMPL        : scripts/quality/llvm-memory01-nc5-probe.sh
               + scripts/quality/llvm-memory01-test.sh
EVIDENCE    : evidence/llvm-memory01-correction02/f14-archive/
               + evidence/llvm-memory01-correction02/closure/*.txt
               + docs/ROADMAP.md (acknowledgement paragraph)
CLOSE       : ACT-Verdict: PASS
```

Each commit is a proof step. No commit combines unrelated
cleanup.

## 10. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md` and write a
HANDOFF at `evidence/llvm-memory01-correction02/HANDOFF.md`.
The HANDOFF summary must contain: VERDICT, IDENTITY, RED,
IMPLEMENTATION, GATES, CONSERVATION, NC5 STRONG BINDING
(LOAD), NC5 STRONG BINDING (STORE), F14 ARCHIVE
ACKNOWLEDGEMENT, SCOPE, RESIDUE, NEXT ACT.

## Execution metadata

```
ACT: ACT-POLYC-LLVM-MEMORY01-CORRECTION02
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
ACT-Verdict: <token>      (CLOSE only)
```

Lifecycle tokens:

- `OPEN` file written; no commits yet.
- `IN_FLIGHT` at least one commit in the range.
- `CLOSED` CLOSE commit with `ACT-Verdict: PASS` exists;
  Factory v2 range-check returns
  `STATUS=PASS VERDICT=PASS`.
