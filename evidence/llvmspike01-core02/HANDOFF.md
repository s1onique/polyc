HANDOFF — ACT-POLYC-LLVM-CORE02
================================

VERDICT
-------
PASS

This ACT fills the NOT_YET_CLASSIFIED gap, audits shape-dependent
capabilities, finishes the IR_BR capability classification, and
supersedes the CORRECTION01 i64→i1 trunc claim. CORE02 production
code is unchanged in executable surface; only the capability
matrix comment is updated.

IDENTITY
--------
Entry:    75983a8 (CORRECTION02 HEAD, PASS)
RED-IMPL: ce2aaa8 (CORE02 RED+IMPL: ACT contract + recon evidence +
                   1 docs-only matrix comment edit)
DOCS:     (this commit)
HEAD:     (this commit)

Total CORE02 commits: 2 (RED-IMPL + DOCS). Within cap of 3.

ROOT CAUSE
----------
CORE01 closed with `NOT_YET_CLASSIFIED` rows for IR_NOP / IR_LABEL
and a misleading "non-fused fallback" description of IR_BR on the
LLVM path. CORE02 reconciles both with the actual pipeline.

RED EVIDENCE
------------
Mission 1 (classify NOT_YET_CLASSIFIED opcodes):
  evidence/llvmspike01-core02/classify-everything.txt

  IR_NOP      -> UNREACHABLE_ON_LLVM (irRemoveAllNops strips before
                                       emission)
  IR_LABEL    -> UNREACHABLE_ON_LLVM (never created by lowerer;
                                       reserved-but-unused)
  IR_CMP_BR   -> REJECTED with boundary-violation diagnostic (was
                                       already classified; kept as
                                       safety net per F4)
  IR_RMW_DEREF-> REJECTED (was already classified; kept as safety
                                       net per F4)

Mission 3 (IR_BR finish classification):
  evidence/llvmspike01-core02/irbr-i64-vs-i1-reachability.txt

  IR_BR cond is the dst of a preceding IR_ICMP:
    - LLVMBuildICmp returns i1 by API contract;
    - irNormalizeBranchCondition always wraps non-ICMP conds in a
      fresh IR_ICMP (src/ir.c:122-135);
    - irLowerFunction produces no non-ICMP IR_BR;
    - irBasicFunctionOptimisations does NOT call irOptPinResultReg
      (fusion never runs on the LLVM path).

  Fresh observation:
    - 7/7 branched positive fixtures produce `br i1 %cond` in the
      emitted `.ll`;
    - 0 `trunc i64 -> i1` instructions appear in any positive
      fixture's `.ll`;
    - the i64→i1 trunc arm of the LLVMTypeOf dispatch has no
      observable caller under the current architecture.

  Classification:
    - i1 path   : LIVE, normal LLVM-path branch representation;
    - i64 path  : DEFENSIVE_INVARIANT — preserved as a guard against
                  a future regression in irNormalizeBranchCondition
                  or a future native-only fusion pass that gets
                  called on the LLVM path by mistake;
    - other path: REJECTED — explicit diagnostic at
                  src/llvm-backend.c:761-769.

REVIEWER P1 — supersede CORRECTION01 claim:
  CORRECTION01 RED-4 / HANDOFF claim:
      "predicate fixtures exercise i64→i1 trunc"
  STATUS:
      FALSIFIED / SUPERSEDED
  FRESH OBSERVATION:
      predicate fixtures exercise i1 direct-use
  ANNOTATED IN:
      docs/acts/ACT-POLYC-LLVM-CORE02.md §3
      evidence/llvmspike01-core02/irbr-i64-vs-i1-reachability.txt
  NO retroactive edit to CORRECTION01 docs (F14).

IMPLEMENTATION
--------------
1 docs-only comment edit to src/llvm-backend.c:
  - IR_BR row: "non-fused fallback" -> "normal LLVM-path conditional
    branch; cond is i1; i64 arm is defensive invariant";
  - IR_NOP row: NOT_YET_CLASSIFIED -> UNREACHABLE_ON_LLVM;
  - IR_LABEL row: NOT_YET_CLASSIFIED -> UNREACHABLE_ON_LLVM.

Zero executable C changes (verified by filtering the diff to
non-comment lines: 0 additions outside the matrix comment block).
The default: arm of the dispatch stays as a regression safety net
per F4.

GATES (verified at HEAD)
------------------------
* git diff --check HEAD: rc=0
* make clean && make: succeeds
* src/llvm-backend.c diff vs CORRECTION02 HEAD:
    40 lines added, all in the matrix comment block;
    0 executable C changes.
* src/llvm-backend.h diff: empty (unchanged).
* llvm-spike-test: PASS=18 FAIL=0
* Negative matrix covers 6 DISTINCT classes (carried from CORR02):
    LLVM_BACKEND_UNSUPPORTED_TYPE
    LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
    LLVM_BACKEND_UNSUPPORTED_CONVERSION
    LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
    LLVM_BACKEND_UNSUPPORTED_INT_SHIFT

SCOPE
-----
* docs/acts/ACT-POLYC-LLVM-CORE02.md: NEW
* evidence/llvmspike01-core02/*: NEW (4 files)
* src/llvm-backend.c: 1 docs-only comment edit (matrix table at
  top of file, lines 73-148).
* scripts/quality/llvm-spike-test.sh: unchanged.
* src/tests/llvm-spike/*: unchanged.

NOT changed:
* src/llvm-backend.h
* dispatch logic in src/llvm-backend.c
* core01-correction02 / core01-correction01 / core01 evidence
  and contracts (preserved F14)

RESIDUE
-------
P2: IR_CMP_BR / IR_RMW_DEREF / IR_NOP / IR_LABEL still have
    explicit REJECTED arms in the dispatch table (defensive; per
    F5 no test weakening).
P2: the `default:` arm in the dispatch stays as a regression
    safety net (per F4 failures are evidence).
P2: closure oracle trust (FT1) - unchanged.
P2: the unsupported-shape dispatch (e.g. `I32` parameter type)
    stays REJECTED at the boundary check, not added as a new
    class. A future ACT may audit per-type.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE03 (deferred):
  - generalise the capability matrix to a runtime check
    (e.g. assert every dispatch case matches the matrix);
  - add a per-fixture matrix-decoder in the harness;
  - audit per-type (I8/I16/I32) parameter rejection.

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1).
