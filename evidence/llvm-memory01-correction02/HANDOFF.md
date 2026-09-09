# ACT-POLYC-LLVM-MEMORY01-CORRECTION02 HANDOFF

Factory-Version: 2

VERDICT: PASS

IDENTITY
--------
- branch:               main
- worktree:             clean (verified at HEAD)
- entry HEAD:           015b8d8 (MEMORY01-CORRECTION01 CLOSE)
- RED commit:           32e2e09
- IMPL commit:          825f7be
- EVIDENCE commit:      (this commit's parent)
- CLOSE commit:         (this commit)
- COMMITS in range:     4 (RED + IMPL + EVIDENCE + CLOSE)
- factory-v2-range-check ACT-POLYC-LLVM-MEMORY01-CORRECTION02 HEAD:
                        STATUS=PASS VERDICT=PASS

Predecessor chain (F14 preserved):
- ACT-POLYC-LLVM-MEMORY01-CORRECTION01 (PASS at 015b8d8):
  the load-side NC5 binding that this ACT extends to the
  store side, and the source of the F14 archive overclaim
  that this ACT acknowledges.
- ACT-POLYC-LLVM-MEMORY01 (PASS at 944ba8d): produces the
  dereference counters that this ACT hardens.
- ACT-POLYC-LLVM-CORE04-RESUME01 (PASS): establishes the
  per-class counter contract that NC5 inherits from.

RED
---
evidence/llvm-memory01-correction02/red/store-deref-explore.txt:
reproduces today's harness under STORE_DEREF counter
suppression. Output proves the false-GREEN:

  Before: red_store_deref=2, p5_store_inc=4
  After:  red_store_deref=1, p5_store_inc=3
  Harness: PASS=6 FAIL=0  (still GREEN, falsely)

The pre-IMPL harness DOES NOT trip on STORE_DEREF counter
suppression because the existing assertions were
floor-only (`>= 1`, `>= 2`) and IR_STORE shape-handling
contributes +1 to both fixtures. This is the exact failure
mode the original NC5 critique identified, surviving on the
store half.

evidence/llvm-memory01-correction02/red/f14-archive-hash.txt:
records the sha256 mismatch that refutes the CORRECTION01
"byte-identical" archive overclaim:

  944ba8d nc-summary.md sha256      = 8bf0596ea06f...
  015b8d8 nc5-weak-historical.md    = 8b05e54a6dea...
  67 vs 72 lines (5 lines appended after the original boundary)

IMPLEMENTATION
--------------
1. scripts/quality/llvm-memory01-nc5-probe.sh:
   - Accept optional mode argument: load (default, existing
     CORRECTION01 behaviour) or store (NEW).
   - Default load-mode behaviour preserved exactly.
   - Store-mode: locate `case IR_STORE_DEREF: {` ... the
     next `case IR_X: {` line, delete the
     LL_INC_SHAPE_DEPENDENT(lc); call inside that range,
     rebuild, run the harness, assert the harness exits
     non-zero AND the output contains
     `FAIL  NC5 red_store_deref`.
   - Force-rebuild fix: `make -B` plus
     `rm -f hcc build/CMakeFiles/hcc.dir/llvm-backend.c.o`
     before each build. Without this, sub-second mtime
     resolution on APFS causes `make` to skip the recompile
     (observed as a flaky false-GREEN).
   - EXIT trap updated to force-rebuild the restored source
     as well.

2. scripts/quality/llvm-memory01-test.sh:
   - `check_nc5_min red_store_deref 1` ->
     `check_nc5_eq red_store_deref 2`.
   - `check_nc5_min p5_store_inc 2` ->
     `check_nc5_eq p5_store_inc 4`.
   - Comment block added explaining why store-side fixtures
     require EXACT assertions (IR_STORE shape-handling
     pads them by +1).
   - Load-side assertions remain `>= 1` because no other
     path contributes to load-only fixtures.

No production code in src/ was changed.

GATES
-----
- llvm-memory01-test.sh:                    PASS=6 FAIL=0
                                            (per-fixture NC5
                                            attribution PASS;
                                            tightened exact
                                            assertions on
                                            red_store_deref=2
                                            and p5_store_inc=4)
- llvm-memory01-nc5-probe.sh load:         PASS
                                            (CORRECTION01
                                            binding intact)
- llvm-memory01-nc5-probe.sh store:        PASS
                                            (NEW CORRECTION02
                                            binding;
                                            observes
                                            FAIL NC5
                                            red_store_deref
                                            after suppression)
- llvm-spike-test.sh:                      PASS=18 FAIL=0
- llvm-cap-table-verifier:                 PASS
- factory-v2-test.sh:                      PASS=35 FAIL=0
- gate-fast.sh:                            VERDICT=PASS
- git diff --check CORRECTION02 range:     rc=0
- factory-v2-range-check.sh
  ACT-POLYC-LLVM-MEMORY01-CORRECTION02 HEAD:
                                           STATUS=PASS
                                           VERDICT=PASS

CONSERVATION
------------
- factory-v2-range-check.sh
  ACT-POLYC-LLVM-MEMORY01 944ba8d:
                  STATUS=PASS VERDICT=PASS
                  (parent regression: MEMORY01 verdict
                  not invalidated by CORRECTION02)
- factory-v2-range-check.sh
  ACT-POLYC-LLVM-MEMORY01-CORRECTION01 015b8d8:
                  STATUS=PASS VERDICT=PASS
                  (CORRECTION01 regression: CORRECTION01
                  verdict not invalidated by CORRECTION02)
- git diff --check 82cde85..944ba8d: rc=0
                  (MEMORY01 hygiene conserved)
- worktree sha256 src/llvm-backend.c = HEAD sha256
                  (no production code change; src restored
                  after every probe run)
- historical MEMORY01 / CORRECTION01 evidence files under
  evidence/llvm-memory01/ and
  evidence/llvm-memory01-correction01/ NOT rewritten
  (F14 conserved)

NC5 STRONG BINDING (LOAD)
-------------------------
ACT-POLYC-LLVM-MEMORY01-CORRECTION01 NC5 binding for
IR_LOAD_DEREF is intact and re-verified by this ACT's
closure gate sweep. The probe was extended with a `store`
mode, but the existing `load` (default) mode is byte-
identical in semantics and behaviour to the CORRECTION01
implementation.

NC5 STRONG BINDING (STORE)
--------------------------
NEW. ACT-POLYC-LLVM-MEMORY01-CORRECTION02 closes the
binding half that CORRECTION01 did not bind. Empirical
witness:

  - Probe run removes the
    `LL_INC_SHAPE_DEPENDENT(lc);` call inside
    `case IR_STORE_DEREF:` (line 1647 of
    src/llvm-backend.c).
  - Rebuild produces a fresh hcc whose counter state
    drops red_store_deref from 2 to 1 and p5_store_inc
    from 4 to 3.
  - The harness now emits `FAIL  NC5 red_store_deref:
    expected SHAPE_DEPENDENT == 2, got 1` and exits
    non-zero.
  - The probe asserts on this exact failure mode and
    passes (i.e. the binding is symmetric).

Symmetry with the load probe is mechanical: the same
script mode argument selects the case range, the same
awk-based mutation, the same build, the same assertion
shape.

F14 ARCHIVE ACKNOWLEDGEMENT
---------------------------
CORRECTION01's CLOSE commit message and HANDOFF claimed
that `evidence/llvm-memory01/negative-controls/
nc5-weak-historical.md` is "byte-for-byte identical to
the original MEMORY01 closure form." This claim was
empirically refuted:

  Reference (944ba8d:nc-summary.md):
    sha256 = 8bf0596ea06f32761d7bffb934f03c64633b8001cfa3411c0d6e18e7d3453657
    lines  = 67
  CORRECTION01 file (nc5-weak-historical.md):
    sha256 = 8b05e54a6dea2943198173914b3d8bc5c4223cb0e3b60aa28c79cb5a0ef55370
    lines  = 72
  Diff:   5 lines of commentary appended after the
          original boundary.

This ACT does NOT rewrite the historical file (F14
forbids rewriting historical evidence merely because
later evidence supersedes it). Instead, a byte-exact
mechanical archive is generated under
`evidence/llvm-memory01-correction02/f14-archive/nc-summary.944ba8d.md`:

  Reference sha256 = 8bf0596ea06f32761d7bffb934f03c64633b8001cfa3411c0d6e18e7d3453657
  Archived sha256  = 8bf0596ea06f32761d7bffb934f03c64633b8001cfa3411c0d6e18e7d3453657
  cmp -s:           PASS

The mechanical verifier capture is at
`evidence/llvm-memory01-correction02/closure/f14-archive-verifier.txt`.

ROADMAP records the overclaim acknowledgement in the
paragraph following the REJECTED=0 falsification note.

SCOPE
-----
- Allowed:
  - scripts/quality/llvm-memory01-nc5-probe.sh
    (extended with mode argument + force-rebuild fix)
  - scripts/quality/llvm-memory01-test.sh
    (tightened store-side assertions)
  - evidence/llvm-memory01-correction02/ (NEW)
  - docs/acts/ACT-POLYC-LLVM-MEMORY01-CORRECTION02.md (NEW)
  - docs/ROADMAP.md (F14 overclaim acknowledgement paragraph)
- Forbidden:
  - src/llvm-backend.c, src/llvm-backend.h,
    src/llvm-backend-cap.c, src/llvm-backend-cap.h
    (NO production code change; zero diff)
  - Capability semantics, counter implementation,
    pointer implementation, LLVM lowering
  - Any historical MEMORY01 / CORRECTION01 evidence
    file under evidence/llvm-memory01/ or
    evidence/llvm-memory01-correction01/

RESIDUE
-------
P0: any IR_STORE_DEREF counter-suppression bug exposed by
the store-mode probe (would be a real counter bug; HALT
and recommend a separate IR ACT). Currently: probe PASS,
no bug observed.

P1: the original CORRECTION01 RED/HANDOFF "byte-identical"
overclaim is acknowledged in writing under this HANDOFF
and a new byte-exact archive is generated. The historical
file is NOT rewritten; readers consulting it should
consult the `f14-archive/` directory in CORRECTION02 for
the genuine historical witness.

P2 (carried from MEMORY01): neutral-IR-level fix for the
`as._i64` / `as.var.id` union aliasing is out of scope
for MEMORY01, CORRECTION01, and this correction.

P3: N1-N4 in MEMORY01 section 14 are still
NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE.

NEXT ACT
--------
ACT-POLYC-LLVM-FLOAT01: F64 parameters / F64 constants /
FADD / FSUB / FMUL / FCMP + branch / F64 return. The
reviewer explicitly approved FLOAT01 as the right next
feature ACT after this correction lands. Per MEMORY01 section 28,
do NOT combine F64 with pointer generalization; close
FLOAT01 separately and only then consider broader
memory/aggregate extension.

FLOAT01 boundary: no fast-math flags and no constrained-FP
machinery. Ordinary LLVM floating-point operations use
LLVM's default floating-point environment; introducing
fast-math would deliberately weaken NaN/infinity/signed-
zero semantics and deserves a separate policy ACT if
PolyC ever wants it.
