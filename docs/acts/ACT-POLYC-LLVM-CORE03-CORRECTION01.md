# ACT-POLYC-LLVM-CORE03-CORRECTION01

## Status

OPEN — closing CORE03 reviewer P0s and P1s.

Predecessor: ACT-POLYC-LLVM-CORE03 (verdict: HALT_CORE03_CONTRACT_NOT_ACTUALLY_BOUND).

## Verdict at OPEN

CORE03 closed with PASS in commit af4a7af; the reviewer
correctly rejected that PASS because:

  P0-1: validator validates the table against itself, not against
        the dispatch.
  P0-2: validator does not prove "exactly one row per IrOp" (no
        gap check; out-of-range enum ordinals pass).
  P0-3: defensive IR_BR/i64 path silently truncates to i1, which
        miscompiles any i64 value outside {0, 1} via parity semantics.
  P1:   contract-check harness uses hard-coded expectations, not
        kLLVMBackendCapability[].
  P1:   P1-b (IR_NOP/IR_LABEL explicit-arms absence) is documented,
        not mechanically enforced.
  topology: CORE03 declared cap=3, actual=4 (RED+IMPL+DOCS+negative-
        test evidence). Per F4 the breach is recorded; per F14 the
        historical commits are preserved.

CORE03-CORRECTION01 narrows these into a single bounded correction.

## Scope (cap = RED + IMPL + DOCS = 3 commits; strict per F12)

### M1 — make the table structurally exhaustive (closes P0-2)

Replace the current count + duplicates check in
`llValidateCapabilityContract()` with an exact-ordinal assertion:

  for (int i = 0; i < kLLVMBackendCapabilityCount; i++) {
      if ((int)kLLVMBackendCapability[i].op != i) abort(...);
  }

plus a range check 0 <= op <= IR_ASM (the loop above already
proves this for in-range op values; the range check is a belt-and-
braces guard).

Acceptance:
  Mutate IR_AND row's op from IR_AND to (IrOp)99. Validator must
  abort with: "row 22 has op=99, expected op=22".

### M2 — bind dispatch ↔ capability (closes P0-1, P1-b)

Add a new build-time verifier:

  scripts/quality/llvm-cap-table-verifier.py

The verifier:
  1. Parses src/llvm-backend.c for `case IR_X:` arms.
  2. Loads kLLVMBackendCapability[] via a new hcc mode
     (`hcc --print-cap-table` or equivalent, emitting one
     `op class diagnostic name` line per row).
  3. Asserts, for every IrOp:
     - SUPPORTED         -> exactly one explicit `case IR_X:` arm.
     - REJECTED          -> exactly one explicit `case IR_X:` arm
                            that emits the named diagnostic.
     - SHAPE_DEPENDENT   -> exactly one explicit `case IR_X:` arm.
     - UNREACHABLE_ON_LLVM -> zero explicit `case IR_X:` arms.
     - DEFENSIVE_INVARIANT -> exactly one explicit `case IR_X:` arm
                              that emits the
                              LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED
                              diagnostic at runtime when tripped.
  4. Returns rc=0 on PASS, rc=1 with a per-row diagnostic on FAIL.

Acceptance (M2a, P0-1):
  Remove `case IR_AND:` from src/llvm-backend.c. Verifier must
  fail with: "IR_AND is REJECTED but no explicit case arm found;
  falls to default which would emit LLVM_BACKEND_UNSUPPORTED_IR."

Acceptance (M2b, P1-b):
  Add `case IR_NOP: { ... }` to src/llvm-backend.c. Verifier must
  fail with: "IR_NOP is UNREACHABLE_ON_LLVM but has explicit case
  arm; remove it or change the table to SUPPORTED."

### M3 — make defensive IR_BR/i64 fatal (closes P0-3)

Replace the current i64 path in src/llvm-backend.c:

  if (cond_ty == LLVMInt64TypeInContext(lc->ctx)) {
      fprintf(stderr,
          "%s: function %s: IR_BR cond is i64, not i1; "
          "neutral/LLVM boundary violation. Refusing to emit "
          "possibly wrong LLVM (trunc i64 -> i1 would miscompile "
          "any non-{0,1} value).\\n",
          LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED,
          lc->fn->name->data);
      exit(1);
  }

with the trunc path deleted.

The counter `lc->defensive_trips` is removed (or repurposed as a
static-failure counter initialised to 0). The contract-check
harness's assertion changes from `defensive_trips == 0` to
`defensive_trips` counter absent (or `defensive_trips == 0`).

Acceptance:
  A live runtime test seam that bypasses irNormalizeBranchCondition
  and emits raw IR_BR with i64 cond. Hcc must exit non-zero with
  the new diagnostic.

  Implementation: a new spike fixture
  `src/tests/llvm-spike-core03-corr/red_p0_3_irbr_i64_fatal.HC`
  that exercises the seam via an internal helper (acceptable per
  reviewer note). The harness asserts non-zero rc + the diagnostic
  appears in stderr.

  Alternative (if a seam is too invasive): rely on textual review
  of the patch and add a static-only check that the i64 branch
  has `exit(1)` (not `continue`) immediately after the diagnostic.
  This is weaker than a live witness; prefer the live seam.

### M4 — bind the harness to the table (closes P1 decoder)

Refactor `scripts/quality/llvm-spike-contract-check.sh` so the
expected class for each fixture is queried from
`kLLVMBackendCapability[]` rather than hard-coded.

Implementation:
  - Add a new hcc mode: `hcc --print-cap-table` that prints one
    line per row: `<op> <class> <diagnostic> <name>`.
  - The harness queries this table at startup and uses it to
    validate per-fixture outcomes.

Acceptance:
  Change kLLVMBackendCapability[IR_ALLOCA].class_ to SUPPORTED.
  Rebuild. Run contract-check harness. Expected: FAIL with
  "table says IR_ALLOCA = SUPPORTED, but fixture observed
  REJECTED."

### M5 — preserve all CORE01-CORE02 invariant rows

The corrections MUST NOT alter the existing PASS verdicts:
  - 18/0 existing harness PASS
  - 20/0 contract-check harness PASS
  - 6 distinct rejection classes preserved
  - IR_BR i1 path unchanged

M5 acceptance: re-run both harnesses after M2-M4 lands; both
PASS unchanged.

## Out of scope (F7)

  - Replacing the matrix comment in src/llvm-backend.c with a
    generated comment. (Deferred to a later ACT.)
  - Per-class execution counters in the harness. (CORE04.)
  - Consolidating the fixture list between the two harness scripts.
    (CORE04.)

## Files authorised for change

NEW:
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
  evidence/llvmspike01-core03-correction01/*
  scripts/quality/llvm-cap-table-verifier.py

MODIFIED:
  src/llvm-backend-cap.h        (new hcc mode print_cap_table)
  src/llvm-backend-cap.c        (M1: ordinal check; cap-table printer)
  src/llvm-backend.c            (M3: make defensive i64 fatal)
  src/main.c                    (wire --print-cap-table mode)
  scripts/quality/llvm-spike-contract-check.sh (M4: query table)
  scripts/quality/llvm-spike-test.sh            (possibly: add new
                                                  RED fixture for M3)

NOT authorised (F7):
  - src/ir*.{c,h} (no IR opcode semantics changes)
  - The native backend
  - The LLVM SPIKE work unrelated to CORE03
  - Refactoring the matrix comment
  - Adding new rejection classes

## Gate profile

  git diff --check HEAD~N..HEAD: rc=0   (N = number of commits)
  make clean && make llvm-all: succeeds
  existing llvm-spike-test.sh: PASS=18 FAIL=0
  contract-check harness:      PASS=20 FAIL=0
  NEW cap-table verifier:      PASS (rc=0)
  RED M1 witness:              reproduces validator false-GREEN
  RED M2a witness:             reproduces dispatch-can-drift
  RED M2b witness:             reproduces P1-b not bound
  RED M3 witness:              reproduces defensive-trunc miscompile
  RED M4 witness:              reproduces hard-coded expectations
  Topology:                    ACTUAL ≤ cap (strict)

## Topology cap

  RED  = 1 commit (RED evidence + this ACT contract)
  IMPL = 1 commit (M1+M2+M3+M4 together — they are mutually
         dependent: the harness fix M4 needs the new --print-cap-
         table from M1; the verifier from M2 needs the ordinal
         check from M1)
  DOCS = 1 commit (HANDOFF + post-impl harness snapshot +
         verifier snapshot)

  TOTAL = 3 commits, AT CAP.

  Topology breach of CORE03 is documented separately (not in
  CORE03-CORRECTION01's commit chain).
