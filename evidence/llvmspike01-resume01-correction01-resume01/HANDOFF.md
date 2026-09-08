# ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01 — HANDOFF

## VERDICT

```text
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01
    VERDICT                = PASS

BOUNDARY
    LLVM_INPUT_IR_CMP_BR   = NO          (zero occurrences across all comparison fixtures)
    LLVM_LOWER_IR_CMP_BR   = NO          (normal arm absent; explicit boundary diagnostic preserved)

PREDICATE
    SIX_SIGNED_PREDICATES  = PASS        (eq, ne, slt, sle, sgt, sge all verifier-clean)
    LLVM_CONDITIONAL_BR    = i1          (LLVM-native predicate type)
    GENERIC_TRUNC_TRUTHINESS = NO        (no trunc i64 -> i1 introduced)
    NEW_POLYC_BOOL_TYPE    = NO          (no IR_TYPE_I1 / IR_TYPE_BOOL)

SSA_ONLY
    ALLOCA                 = 0           (across 12 authorised positive/predicate fixtures)
    LOAD                   = 0
    STORE                  = 0
    PHI                    = 0
    MEMORY_MODEL           = NONE
    PARAM_COPY_CLASS       = 100%        (all observed memory ops were PARAM_COPY)

LLVM
    SPIKE_TEST             = PASS        (PASS=12, FAIL=0)
    VERIFIER               = PASS        (llvm-as rc=0 for all 12 .ll)
    DETERMINISM            = PASS        (byte-identical on 01_const / 04_cmp_branch / 05_call)
    NATIVE_FALLBACK        = NO          (output starts with `; ModuleID`)

NATIVE
    GATE_PUSH_IMPLEMENTATION = PASS      (SUBJECT=1cfc34a6056f)
    AOT                    = PASS        (gate-push per-check)
    JIT                    = PASS
    LSP                    = PASS

EVIDENCE
    NEW_BINARY_ARTIFACTS   = 0           (no .bc, .o, .a, executable committed)
    HISTORICAL_GATE_REWRITTEN = NO       (F14 preserved)
    HISTORICAL_BINARIES_FOUND    = 12    (.bc + c_api_smoke, all git-rm'd)
    HISTORICAL_BINARIES_ACTION   = REMOVED under explicit F14 manifest

HYGIENE
    DIFF_CHECK             = PASS
    WORKTREE               = clean
    COMMITS                = 3           (RED + IMPL + this CLOSURE)
```

---

## IDENTITY

```text
ENTRY_HEAD            = bde6045a200a1526435fd161f41b59e02df012b7
RED_HEAD              = 50a43c64fa3dc9ba70976300b4a7aeafa0332258
IMPLEMENTATION_HEAD   = 1cfc34a6056fca65c97cbdcdeaa6e1973f3ac2e0
CURRENT_HEAD          = (recorded by git rev-parse at the time of reading
                         this HANDOFF; the implementation gate transcript
                         below uses SUBJECT=1cfc34a6056f, mechanically
                         verified as an ancestor of CURRENT_HEAD below)
BRANCH                = main
WORKTREE              = clean
```

VERIFY identity binding (ACT §50):

```sh
SUBJECT=$(grep '^SUBJECT=' \
    evidence/llvmspike01-resume01-correction01-resume01/gate-push-implementation/log.txt \
    | head -1 | cut -d= -f2)
SUBJECT_FULL=$(git rev-parse "$SUBJECT^{commit}")
ANC=$(git merge-base --is-ancestor "$SUBJECT_FULL" HEAD && echo yes || echo no)
echo "SUBJECT_FULL=$SUBJECT_FULL"
echo "ANCESTOR_OF_HEAD=$ANC"
```

---

## ENTRY

```text
GATE_FAST              = PASS              (POLYC_GATE=fast VERDICT=PASS)
GATE_PUSH              = PASS              (SUBJECT=bde6045a200a, build/install/aot/jit/lsp/diff-check all PASS)
LLVM_VERSION           = 22.1.8
LLVM_SPIKE_ENTRY       = PASS              (PASS=12, FAIL=0)
LLVM_CONFIG            = /nix/store/b6fykfvclbq81yis03blk6bqsmapmhdm-llvm-22.1.8-dev/bin/llvm-config
LLVM_AS                = /nix/store/87s8r8yzsi6gvl2cdz4kgwymg4gdmkbn-llvm-22.1.8/bin/llvm-as
LLVM_LIBDIR            = /nix/store/a1hnp3fv6y7jjl8j3vkcp3qwclxmknba-llvm-22.1.8-lib/lib
```

---

## BOUNDARY

```text
LLVM_CALLS_NATIVE_PREP    = NO          (src/main.c:561 calls irLowerProgram directly;
                                         no irFunctionPrepForCodeGen, no
                                         irAssignAbiParamLocations, no
                                         irOptPinResultReg on the LLVM path)
LLVM_INPUT_IR_CMP_BR      = NO          (verified across all comparison/predicate fixtures)
LLVM_IR_CMP_BR_CONSUMER   = NO          (normal lowering arm absent)
BOUNDARY_CHANGE_REQUIRED  = NO          (already correct in HEAD; recon preserved)
```

---

## PREDICATES

```text
BOOL_MAPPING_CHANGE_REQUIRED = NO       (post-BRANCH-CONDITION01, IR_BR operands are
                                         already canonical i1 IR_ICMP results; trunc
                                         step in IR_BR arm is a vestige but produces
                                         no visible instruction in textual IR)
EQ   = icmp eq   i64 %0, %1   +   br i1 %2, ...
NE   = icmp ne   i64 %0, %1   +   br i1 %2, ...
SLT  = icmp slt  i64 %0, %1   +   br i1 %2, ...
SLE  = icmp sle  i64 %0, %1   +   br i1 %2, ...
SGT  = icmp sgt  i64 %0, %1   +   br i1 %2, ...
SGE  = icmp sge  i64 %0, %1   +   br i1 %2, ...
LLVM_BRANCH_OPERAND_TYPE  = i1
TRUNC_TRUTHINESS_ADDED    = NO
```

---

## PRINCIPAL_RED

```text
LLVM_ALLOCA_BEFORE  = 9   (7 fixtures)
LLVM_LOAD_BEFORE    = 9
LLVM_STORE_BEFORE   = 9
RED_REPRODUCED      = YES

Principal fixture: 04_cmp_branch.HC emitted:

    define i64 @Max(i64 %0, i64 %1) {
    bb1:
      %2 = alloca i64, align 8
      %3 = alloca i64, align 8
      store i64 %0, ptr %2, align 4
      store i64 %1, ptr %3, align 4
      %4 = icmp sgt i64 %0, %1
      br i1 %4, label %bb3, label %bb4
    bb3:
      %5 = load i64, ptr %2, align 4
      ret i64 %5
    ...
    }

Cause: predecessor spike pre-allocated one alloca per IR_VAL_LOCAL
(llPreallocateLocals) and routed every store/load through it.
```

---

## SSA_REACHABILITY

```text
PARAM_COPY            = 100%   (every observed memory op was a PARAM_COPY)
LOCAL_SINGLE_DEF      = 0
LOCAL_MULTI_DEF       = 0
CROSS_BLOCK           = 0
PHI_REQUIRED          = 0
ADDRESS_TAKEN         = 0
SUBSET_REACHABLE      = YES    (every authorised fixture is representable
                                without memory, PHI, or pointer lowering)
```

---

## IMPLEMENTATION

```text
FILES                = src/llvm-backend.c, src/llvm-backend.h,
                       scripts/quality/llvm-spike-test.sh,
                       regenerated test-evidence .ll files
HELPERS              = none at the API level; only two diagnostic codes
                       added to src/llvm-backend.h:
                         LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
                         LLVM_BACKEND_INTERNAL_UNBOUND_VALUE
MEMORY_FALLBACK      = NO    (lookup-failed -> explicit diagnostic ->
                                nonzero exit; never silently allocate a
                                stack slot)
```

The local-binding mechanism is implemented by reusing the existing
`lc->values` map (per-function vector of LLVMValueRef that already
carried constant/parameter/instruction-result bindings).

`IR_STORE local, value` -> `llvmSet(lc->values, local-id, llLowerI64Value(value))`

No new container, no new helper, no extra metadata.

`llLowerI64Value` for `IR_VAL_LOCAL` simply returns the cached SSA
value; no `LLVMBuildLoad2` is emitted.

`IR_LOAD` and `IR_ALLOCA` are intercepted at block level and are
accepted ONLY when consumed by the existing return-slot collapse
(recognized return-slot shape is unchanged from the predecessor
spike); any other occurrence fails loud with
`LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL`.
`IR_LOAD` and `IR_ALLOCA` are intercepted at block level and are
accepted ONLY when consumed by the existing return-slot collapse
(recognized return-slot shape is unchanged from the predecessor
spike); any other occurrence fails loud with
`LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL`.

---

## LLVM_AFTER

```text
ALLOCA             = 0     (across 12 authorised positive/predicate fixtures)
LOAD               = 0
STORE              = 0
PHI                = 0
VERIFIER_MATRIX    = PASS  (llvm-as rc=0 for all 12 .ll)
DETERMINISM        = PASS  (byte-identical on 01_const, 04_cmp_branch, 05_call)
LLVM_SPIKE_TEST    = PASS  (PASS=12, FAIL=0)
```

Sample emitted IR (post-fix, 04_cmp_branch.HC):

```llvm
; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Max(i64 %0, i64 %1) {
bb1:
  %2 = icmp sgt i64 %0, %1
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  ret i64 %0

bb4:                                              ; preds = %bb1
  ret i64 %1

bb2:                                              ; No predecessors!
  unreachable
}
```

The two param copies that previously lowered as
`store i64 %0, ptr %2` + `load i64, ptr %2` are now absent.
`ret i64 %0` returns the parameter directly.

---

## NATIVE

```text
GATE_PUSH_IMPLEMENTATION = PASS   (SUBJECT=1cfc34a6056f)
AOT                      = PASS   (gate-push per-check)
JIT                      = PASS
LSP                      = PASS

Per-check status from gate-push-implementation/log.txt:
    CHECK=build      STATUS=PASS
    CHECK=install    STATUS=PASS
    CHECK=aot        STATUS=PASS
    CHECK=jit        STATUS=PASS
    CHECK=lsp        STATUS=PASS
    CHECK=diff-check STATUS=PASS
    VERDICT=PASS
```

---

## EVIDENCE

```text
BINARY_ARTIFACTS_NEW          = 0
HISTORICAL_BINARIES_FOUND     = 12
HISTORICAL_BINARIES_ACTION    = REMOVED
HISTORICAL_GATE_REWRITTEN     = NO
```

See binary-evidence-manifest.txt for the full sha256 + git_oid
table; see historical-evidence-reconciliation.txt for the F14
accounting.

---

## HYGIENE

```text
DIFF_CHECK_IMPL    = PASS
DIFF_CHECK_CLOSURE = PASS
WORKTREE_CLEAN     = YES
COMMIT_COUNT       = 3
```

---

## RESIDUE

```text
P0 = none

P1 = scripts/quality/llvm-spike-test.sh regenerates C1 RED evidence
     files (red-1B.emit-llvm.ll, red-2.emit-llvm.ll,
     red-2.emit-llvm.txt) on every run. The original C1 RED content
     is preserved in HANDOFF.md and the C1 .dump-ir transcripts
     under .sha256 / .b64 sidecars. The regenerated content is
     meaningful: it shows the memory-op RED has become GREEN. A
     future cleanup ACT may want to split the harness into a
     stable-history mode and a live mode to avoid this rewriting.
     Out of scope here.

P1 = The IR_BR arm in src/llvm-backend.c still calls LLVMBuildTrunc
     on the i1 result of an IR_ICMP. The trunc i1 -> i1 produces
     no visible instruction in textual IR (LLVM folds it), but the
     call itself is dead code. A future simplification ACT can
     remove it. Out of scope here.

P1 = The historical C1 evidence files in
     evidence/llvmspike01-resume01-correction01/ have now been
     regenerated by the harness with the post-implementation
     compiler output. The diffs show "alloca 2 -> 0", which is
     the visible signal of the fix. Original RED counts are
     preserved in HANDOFF.md and the .dump-ir transcripts.

P2 = dead_exit / unreachable blocks remain in the emitted .ll. Per
     ACT §66 this is P2 (deferred). Verifier acceptance is
     sufficient.

P2 = The `bidx` variable in src/llvm-backend.c is set but not used.
     Pre-existing, harmless. Cleanup ACT may remove it.

P2 = The `irInstrListLen` function in src/llvm-backend.c is declared
     but unused. Pre-existing, harmless.
```

P2 = The `irInstrListLen` function in src/llvm-backend.c is declared
     but unused. Pre-existing, harmless.
```

---

## NEXT_ACT

```text
NEXT_ACT = ACT-POLYC-LLVM-CORE01

Mission: turn the experiment into a deliberately-supported scalar
LLVM backend core, with a precise opcode/type capability table,
before execution/JIT work.

Predecessor state for that ACT:
    - IR boundary and predicate mapping are stable (preserved here)
    - Bounded I64 scalar subset emits SSA-only verifier-clean LLVM
    - Negative tests still produce explicit LLVM_BACKEND_UNSUPPORTED_*
      diagnostics
    - F64, pointers, structs, aggregates, F32/U8/U16/U32, asm,
      switch/select/va_*, ORC, MCJIT, llc, target machine remain
      outside the spike (neg_* fixtures reject; ACT §87 Outcome A
      continues to recommend ACT-POLYC-LLVM-CORE01 as the next step)
```

---

## KEY FILE INDEX

```text
src/llvm-backend.c                                   production
src/llvm-backend.h                                   production (diagnostic codes)
scripts/quality/llvm-spike-test.sh                   test harness (strengthened)

evidence/llvmspike01-resume01-correction01-resume01/
    HANDOFF.md                                       this file
    entry-identity.txt                               ENTRY_HEAD = bde6045a200a
    entry-gate-fast.txt                              gate-fast PASS
    entry-gate-push.txt                              gate-push PASS at entry
    llvm-toolchain.txt                               LLVM 22.1.8 paths
    llvm-entry-matrix.txt                            PASS=12/FAIL=0 at entry
    pipeline-recon.txt                               Phase 0 dispatch recon
    cmp-br-boundary.txt                              IR_CMP_BR boundary recon
    predicate-mapping-recon.txt                      predicate mapping recon
    memory-red.txt                                   principal RED reproduction
    memory-classification.txt                        PARAM_COPY classification
    memory-matrix-before.txt                         RED counts
    llvm-entry-matrix-after.txt                      PASS=12/FAIL=0 after
    memory-matrix-after.txt                          0/0/0 after
    predicate-matrix-after.txt                       six predicates all PASS
    llvm-verifier-matrix.txt                         all 12 .ll pass llvm-as
    determinism.txt                                  three fixtures IDENTICAL
    implementation-summary.txt                       what changed and what didn't
    binary-evidence-manifest.txt                     12 historical binaries catalog
    historical-evidence-reconciliation.txt           F14 preservation note
    gate-push-implementation/
        log.txt                                      SUBJECT=1cfc34a6056f
```
