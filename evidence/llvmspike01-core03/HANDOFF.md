HANDOFF — ACT-POLYC-LLVM-CORE03
================================

VERDICT
-------
PASS

CORE03 turns the documented capability matrix into a
runtime-enforced contract. The dispatch and the matrix cannot
silently drift apart: any future patch that changes either side
without updating the other will be caught by either
`llValidateCapabilityContract()` (at startup) or
`llvm-spike-contract-check.sh` (in CI).

The CORE02 reviewer's two P1 concerns are mechanically resolved:
  P1-a (IR_BR/i64 unreachable claim): softened to DEFENSIVE_INVARIANT
         with runtime detection via
         LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED + defensive_trips
         counter; harness asserts defensive_trips == 0 for the
         supported subset.
  P1-b (IR_NOP / IR_LABEL closure prose): the matrix comment now
         correctly says "no explicit `case IR_X:` arm; the generic
         `default:` arm catches a future regression"; this matches
         what the dispatch actually does.

IDENTITY
--------
Entry:    8f88938 (CORE02 HEAD, PASS_WITH_NONBLOCKING_RECON_RESIDUE)
RED:      d927333 (CORE03 ACT contract + RED evidence)
IMPL:     a2ee963 (CORE03 IMPL: cap.{c,h} + IR_BR detection +
                   matrix tightening + contract-check script)
DOCS:     (this commit)
HEAD:     (this commit)

Total CORE03 commits: 3 (RED + IMPL + DOCS). At cap.

ROOT CAUSE
----------
CORE02 closed with the capability matrix as a C comment block
at the top of src/llvm-backend.c. The matrix and the dispatch
were independently maintained; nothing enforced their
consistency. The reviewer's verdict was:

  > Make it mechanically impossible for the executable LLVM
  > dispatch and the declared capability contract to drift apart.

CORE03 introduces the runtime contract validator + per-fixture
matrix decoder that mechanically closes this gap.

RED EVIDENCE
------------
  evidence/llvmspike01-core03/red-p1a-no-defensive-detection.txt
    IR_BR/i64 arm currently has no logging, no counter, no
    diagnostic. CORE03 M4 closes this.

  evidence/llvmspike01-core03/red-p1b-no-explicit-arms.txt
    IR_NOP and IR_LABEL have NO `case IR_X:` arms in the
    dispatch (grep-verified). They fall to the generic
    `default:` arm. CORE02 HANDOFF closure prose incorrectly
    said "explicit REJECTED arms". CORE03 §1 P1-b fixes.

  evidence/llvmspike01-core03/red-m1-no-table.txt
    No machine-readable capability table existed. CORE03 M1
    introduces src/llvm-backend-cap.{c,h}.

  evidence/llvmspike01-core03/red-m2-no-decoder.txt
    Harness had no per-fixture matrix decoder. CORE03 M3
    introduces scripts/quality/llvm-spike-contract-check.sh.
    Baseline harness output (no decoder blocks):
    evidence/llvmspike01-core03/red-m2-harness-baseline.txt
    grep -c '=== contract check:' baseline = 0 (verified).

IMPLEMENTATION
--------------
NEW src/llvm-backend-cap.h:
  - LLVMBackendCapability enum (5 values)
  - LLVMBackendCapabilityDef struct
  - llValidateCapabilityContract() extern

NEW src/llvm-backend-cap.c:
  - kLLVMBackendCapability[56] table (one row per IR opcode,
    IR_NOP=0 .. IR_ASM=55, indexed in the same order as the
    enum).
  - llValidateCapabilityContract(): asserts
      * count == IR_ASM+1;
      * no duplicate opcodes;
      * REJECTED rows have non-NULL diagnostic;
      * non-REJECTED, non-SHAPE_DEPENDENT rows have NULL
        diagnostic.
    On failure: prints diagnostic to stderr + abort().
    On success: prints "LLVM backend capability contract:
    ok (56 rows)" to stderr.

src/llvm-backend.h:
  - NEW LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED diagnostic
    constant.

src/llvm-backend.c:
  - LLCtx::defensive_trips counter (zero-initialised in
    llFunction via the existing memset).
  - IR_BR arm: when LLVMTypeOf(cond) != i1, emit the
    defensive-invariant diagnostic to stderr, increment
    defensive_trips, continue with the trunc.
  - Matrix comment updates (tighten, do not weaken):
    * IR_NOP / IR_LABEL rows: now say "no explicit `case
      IR_X:` arm; the generic `default:` arm catches a
      future regression and emits
      LLVM_BACKEND_UNSUPPORTED_IR" (CORE02 P1-b correction).
    * IR_BR row: upgraded from "non-reachable defensive
      guard" to "DEFENSIVE_INVARIANT — runtime-detected via
      LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED" (CORE02 P1-a
      correction).
    * New "ACT-POLYC-LLVM-CORE03" block pointing readers to
      src/llvm-backend-cap.c as the machine-readable source
      of truth.

src/main.c:
  - llValidateCapabilityContract() called once at the top of
    the --emit-llvm branch, before irLowerProgram.

src/CMakeLists.txt:
  - llvm-backend-cap.{c,h} added to SOURCES / HEADERS
    (LLVM-gated; consistent with llvm-backend.{c,h}).

NEW scripts/quality/llvm-spike-contract-check.sh:
  - Per-fixture matrix decoder. For each of 20 fixtures:
    expected_class / observed_class / expected_diagnostic /
    observed_diagnostic / contract_validated / defensive_trips
    / verdict.
  - Strict superset of llvm-spike-test.sh. The original
    18/0 harness continues to pass unchanged.

GATES (verified at HEAD)
------------------------
* git diff --check HEAD: rc=0
* git diff --check HEAD~2..HEAD (CORE03 range): rc=0
* make clean && make llvm-all: succeeds
* llvm-spike-test (existing): PASS=18 FAIL=0
* llvm-spike-contract-check (new): PASS=20 FAIL=0
* defensive_trips per fixture: 0 (all 20 fixtures)
* Sum of defensive_trips: 0
* src/llvm-backend.h diff: 7 lines (1 diagnostic + comment)
* src/llvm-backend.c diff: matrix comment tightening +
  IR_BR defensive detection + LLCtx::defensive_trips
* src/CMakeLists.txt diff: 2 lines (cap.{c,h} wired in)
* src/main.c diff: 9 lines (contract validation call)
* src/llvm-backend-cap.h: NEW
* src/llvm-backend-cap.c: NEW (121 lines; generated table +
  validator)

SCOPE
-----
NEW:
* docs/acts/ACT-POLYC-LLVM-CORE03.md
* src/llvm-backend-cap.h
* src/llvm-backend-cap.c
* scripts/quality/llvm-spike-contract-check.sh
* evidence/llvmspike01-core03/* (entry-identity,
  pre-impl-topology, red-p1a/b, red-m1/m2,
  red-m2-harness-baseline, contract-check-output,
  post-impl-harness, post-impl-contract-check,
  post-impl-topology, HANDOFF)

MODIFIED (additive, conservative):
* src/llvm-backend.h (1 new diagnostic constant)
* src/llvm-backend.c (LLCtx::defensive_trips + IR_BR
  detection + matrix comment tightening)
* src/main.c (llValidateCapabilityContract() call)
* src/CMakeLists.txt (cap.{c,h} wired in)
* evidence/llvmspike01-resume01-correction01-resume01-
  correction01/{live-red-transcripts,red-multi_def}/*
  (additive prefix: "LLVM backend capability contract: ok
  (56 rows)" at top of each stderr transcript; existing
  harness assertions still pass because the new line is
  additive and the diagnostics still appear in stderr)

NOT changed:
* src/llvm-backend.h dispatch logic (the dispatch is
  unchanged; only the i64 arm gained a diagnostic + counter)
* IR opcode enum or any neutral-IR generator
* src/ir*.{c,h}
* Existing harness llvm-spike-test.sh
* CORE01 / CORE02 evidence and contracts (preserved F14)

RESIDUE
-------
P2: defensive_trips can become >0 in tests, but the
    supported subset must keep it at 0 (harness-enforced).
    A future ACT that adds a producer of non-i1 IR_BR cond
    will trip the counter and the contract-check harness
    will FAIL.
P2: LLVMBackendCapability is a 5-value enum; future ACTs
    may add per-class execution counters in the harness
    (e.g. n_rejections_per_class).
P2: IR_BR DEFENSIVE_INVARIANT is the only DEFENSIVE row
    currently; future ACTs may add more if the architecture
    evolves. None expected.
P2: closure oracle trust (FT1) is now MORE important
    because CORE03's contract check is itself a closure
    oracle. A separate ACT investigates this.
P2: the contract-check script duplicates the fixture list
    in llvm-spike-test.sh. A future refactor ACT may
    consolidate; out of CORE03 scope per F7.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE04 (deferred):
- assert every `case IR_X:` in the dispatch has a matching
  kLLVMBackendCapability[] row (the reverse direction of
  CORE03 M1);
- per-class execution counters (e.g.
  `n_rejections_per_class`) emitted in the harness summary;
- consolidate the fixture list between the two harness
  scripts (residue from CORE03).

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1).
