# HANDOFF -- ACT-POLYC-LLVM-MEMORY01-CORRECTION01

Factory-Version: 2

## Result

PASS. Three small closure-contract corrections to MEMORY01
identified by the post-closure reviewer disposition are now
bound, falsified, or corrected:

1. **NC5 hardening** (P0): the counter-regression negative
   control is now strongly bound by per-fixture
   SHAPE_DEPENDENT assertions plus an independent regression
   probe that mutates the source, rebuilds, runs the harness,
   and verifies the harness REDs on the specific
   `red_load_deref` per-fixture assertion.
2. **REJECTED>0 falsification record** (P1): the
   `REJECTED > 0` expectation from ACT §11 is now explicitly
   recorded as "FALSIFIED / NOT APPLICABLE TO MEMORY01
   MATRIX" in ROADMAP, the NC summary, and this HANDOFF.
3. **Stale topology prose** (P1): ROADMAP now correctly says
   "5 commits across RED + IMPL + EVIDENCE + CLOSE phases
   (plus an in-range whitespace-normalisation fixup)".

The closure verdict is authoritative in the `ACT-Verdict`
trailer of the CLOSE commit.

## What changed

### Tooling

- `scripts/quality/llvm-memory01-test.sh`:
  - `parse_and_sum_counters` now writes a per-fixture
    counter file (`$EVID/_tmp/per_fixture/<bn>`) containing
    `supported=`, `rejected=`, `shape_dependent=`,
    `defensive=`, `unreachable=` lines.
  - New `=== MEMORY01 NC5 per-fixture attribution ===`
    section with `check_nc5_eq` / `check_nc5_min` helpers and
    per-fixture assertions:
    `red_pointer_param==0`, `red_load_deref>=1`,
    `red_store_deref>=1`, `p4_load_add>=1`, `p5_store_inc>=2`.
- `scripts/quality/llvm-memory01-nc5-probe.sh` (NEW):
  - Snapshots `src/llvm-backend.c`, mutates one
    `LL_INC_SHAPE_DEPENDENT(lc);` call inside `case IR_LOAD_DEREF:`
    via awk (precise, line-stable), rebuilds, runs the GREEN
    harness, asserts the harness FAILs on the
    `FAIL  NC5 red_load_deref` line. EXIT trap restores
    source (cp before rm — order matters).

### Docs

- `docs/acts/ACT-POLYC-LLVM-MEMORY01-CORRECTION01.md` (NEW).
- `evidence/llvm-memory01-correction01/red/nc5-weak-red.txt`
  (NEW): the pre-IMPL RED transcript proving the original
  counter gate was weak (harness silently GREEN with
  IR_LOAD_DEREF counter suppressed).
- `evidence/llvm-memory01-correction01/closure/`: captured
  closure gate outputs.
- `evidence/llvm-memory01/negative-controls/nc-summary.md`:
  replaced NC5 section with strong form; preserved NC1..NC4.
- `evidence/llvm-memory01/negative-controls/nc5-weak-historical.md`
  (NEW): F14-archived historical weak NC5 prose.
- `docs/ROADMAP.md`:
  - Replaced stale "3 commits + a docs/ROADMAP update" with
    the actual 5-commit range description.
  - Added explicit `REJECTED > 0` falsification note.
- `evidence/llvm-memory01/closure/HANDOFF.md`: added
  CORRECTION01 follow-up section.

### NOT changed (per scope)

- `src/llvm-backend.c` / `.h`: zero source diff. The probe
  does mutate the source temporarily but the EXIT trap
  restores it; no committed diff.
- `src/llvm-backend-cap.c` / `.h`: zero source diff.
- `src/tests/llvm-memory01/*`: zero fixture diff.
- Factory v2 metadata / gate-fast / factory-v2-test /
  factory-v2-range-check: zero diff.

## RED

The principal RED is documentary: the original NC5 prose
admits weakness, and a captured transcript (under
`evidence/llvm-memory01-correction01/red/`) shows that
suppressing the `LL_INC_SHAPE_DEPENDENT(lc)` call inside
`case IR_LOAD_DEREF:` leaves the existing aggregate counter
gate `SHAPE_DEPENDENT>=1` satisfied (the IR_STORE
shape-handling path still contributes 4 to the aggregate):

```text
SUPPORTED           : 7
REJECTED            : 0
SHAPE_DEPENDENT     : 4
DEFENSIVE_INVARIANT : 0
UNREACHABLE_ON_LLVM : 0
PASS  counter gate: SHAPE_DEPENDENT>=1, SUPPORTED>=1, DEFENSIVE=0, UNREACHABLE=0
=================================
MEMORY01 GREEN summary: PASS=6 FAIL=0   <-- silently GREEN
=================================
```

The RED is a documented weakness, not a transient
malfunction: the existing counter gate is provably
insensitive to the suppression.

## Implementation

Two-surface change, both in tooling:

1. Per-fixture assertions in the GREEN harness give the
   counter gate a per-fixture attribution. Any source mutation
   that suppresses or doubles one `LL_INC_SHAPE_DEPENDENT`
   call inside `IR_LOAD_DEREF` or `IR_STORE_DEREF` trips the
   corresponding per-fixture assertion.

2. The regression probe is an independent, self-restoring
   test: it runs `make llvm-all`, runs the harness, and
   asserts the harness exits non-zero AND emits the
   `FAIL  NC5 red_load_deref` line. The EXIT trap restores
   source before removing its temp dir (ordering verified).

The probe itself is symmetric: it FAILS if the per-fixture
assertion is weakened (see `nc5-probe-broken-assertion.txt`
under closure/).

## Gates

- `make clean && make llvm-all` → rc=0
- `sh scripts/quality/llvm-memory01-test.sh` → rc=0
  - PASS=6 FAIL=0
  - per-fixture NC5 attribution PASS line emitted
- `sh scripts/quality/llvm-memory01-nc5-probe.sh` → rc=0
- `sh scripts/quality/llvm-spike-test.sh` → rc=0
  (PASS=18 FAIL=0; conservation)
- `python3 scripts/quality/llvm-cap-table-verifier.py` →
  rc=0 (dispatch <-> capability <-> harness bound)
- `sh scripts/quality/factory-v2-test.sh` → rc=0
  (PASS=35 FAIL=0)
- `sh scripts/quality/gate-fast.sh` → rc=0 (VERDICT=PASS)
- `git diff --check <CORRECTION01-FIRST>..HEAD` → rc=0
- `sh scripts/quality/factory-v2-range-check.sh
  ACT-POLYC-LLVM-MEMORY01-CORRECTION01 HEAD` →
  STATUS=PASS VERDICT=PASS
- `sh scripts/quality/factory-v2-range-check.sh
  ACT-POLYC-LLVM-MEMORY01 HEAD` →
  STATUS=PASS VERDICT=PASS (parent ACT regression check)

## Conservation

- `llvm-memory01-test.sh` exits 0 (was 0 in MEMORY01 CLOSE).
- `llvm-spike-test.sh` exits 0 (was 0).
- `llvm-cap-table-verifier` exits 0.
- `factory-v2-test` exits 0 (PASS=35 FAIL=0).
- `gate-fast` exits 0 (VERDICT=PASS).
- `git diff --check <MEMORY01-FIRST>..HEAD` rc=0 (was rc=0).
- `factory-v2-range-check.sh ACT-POLYC-LLVM-MEMORY01 HEAD`
  STATUS=PASS VERDICT=PASS (was PASS; no regression).
- Worktree post-closure: clean.

## REJECTED>0 falsification

ACT §11 expected `REJECTED > 0`. The MEMORY01 closure matrix
exercises exactly one negative fixture (`neg_struct.HC`)
which is rejected at the function-parameter type admission
seam (`llPass1`) BEFORE any per-opcode dispatch arm runs. The
class-generic rejection fires `LLVM_BACKEND_UNSUPPORTED_TYPE`
and exits, but does not increment the per-opcode REJECTED
counter. The per-opcode REJECTED counter exists in the
capability table and is exercised by the predecessor
`llvm-spike-test.sh` negative matrix. The MEMORY01 matrix
is intentionally narrow: supported path + exactly one
class-generic rejection.

Therefore `REJECTED > 0` is FALSIFIED / NOT APPLICABLE TO
MEMORY01 MATRIX. No code or counter bug exists. Recorded
in `docs/ROADMAP.md` and `evidence/llvm-memory01/negative-controls/nc-summary.md`.

## NC5 strong binding

The per-fixture assertions + the regression probe together
bind NC5 in three independent ways:

- The harness's per-fixture assertions fail loudly when a
  counter is suppressed (RED transcript under `red/`).
- The probe exercises the harness and asserts the harness
  emits the specific `FAIL  NC5 red_load_deref` line.
- The probe's own assertion (`grep -q 'FAIL  NC5 red_load_deref'`)
  guarantees the attribution is to the specific fixture that
  exercises IR_LOAD_DEREF, not to any other per-fixture
  assertion or aggregate counter.

## Topology prose

ROADMAP now says:

```
Closure commit count: 5 commits across RED + IMPL +
EVIDENCE + CLOSE phases (plus an in-range whitespace-
normalisation fixup; see ACT-POLYC-LLVM-MEMORY01-CORRECTION01
for the NC5 hardening that required a fresh tree). Factory v2
has no numeric commit cap; this number is descriptive only.
```

This is descriptive only and has no Factory v2 topology
consequence (Factory v2 wisely has no numeric commit cap).

## Scope

- Allowed: tooling (harness, probe), docs (ACT, NC summary,
  ROADMAP, HANDOFF), new evidence dir.
- Forbidden: src/, native backends, IR, parser, language,
  fixtures, Factory metadata, Makefile, CI.

## Residue

- P0: any IR_LOAD_DEREF counter-suppression bug exposed by
  the regression probe (would be a real counter bug; HALT
  and recommend a separate IR ACT). The probe at IMPL run
  passed; no bug exposed.
- P1 (carried from MEMORY01): neutral-IR-level fix for the
  `as._i64` / `as.var.id` union aliasing is out of scope for
  both MEMORY01 and this correction.
- P2: N1-N4 in MEMORY01 §14 are still
  NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE.
- P2: `LLVM_SPIKE_EVID_OVERRIDE` /
  `LLVM_SPIKE_EVID_CORR_OVERRIDE` env vars added to
  `llvm-spike-test.sh` so future ACTs can isolate the spike
  evidence without touching the historical dirs (carried
  from MEMORY01).

## Next ACT

`ACT-POLYC-LLVM-FLOAT01` (F64 parameters / F64 constants /
FADD / FSUB / FMUL / FCMP + branch / F64 return). Per
ACT-POLYC-LLVM-MEMORY01 §28, do NOT combine F64 with pointer
generalization; close FLOAT01 separately and only then
consider broader memory/aggregate extension.

The reviewer explicitly approved FLOAT01 as the right next
feature ACT after this correction lands.
