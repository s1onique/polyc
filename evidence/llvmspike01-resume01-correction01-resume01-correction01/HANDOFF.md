HANDOFF — ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01
==========================================================================

VERDICT
-------
PASS

The HALT_LLVM_SSA_BINDING_CONTRACT review raised two P0s against
the previous IMPL (1cfc34a). Both are now closed:

  P0-1: SSA-local multiple reaching stores are now rejected
         with LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL.
  P0-2: Three historical C1 RED evidence files are restored
         byte-for-byte from bde6045a200a1526435fd161f41b59e02df012b7.

IDENTITY
--------
ENTRY_HEAD  = bde6045a200a1526435fd161f41b59e02df012b7
RED_HEAD    = 910c6ecb45e07e9e48bb91ad1c06564fc6c941d5
IMPL_HEAD   = 5eed2af8eb5c853cbd5f61d67190c956788f634f
CLOSURE     = f703cecab5c58ed178e427cb23e703f9c03932bc
             (also includes the harness EVID_CORR redirection fix)
HEAD        = f703cecab5c58ed178e427cb23e703f9c03932bc (currently)

Verified: IMPL_HEAD is an ancestor of HEAD via
git merge-base --is-ancestor.

ROOT CAUSE OF P0-1
------------------
The previous IMPL claimed in its commentary that "if multiple
reaching definitions exist, fail with LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL",
but the actual IR_STORE handler in src/llvm-backend.c unconditionally
called `llvmSet(&lc->values, irDstVarId(ins), v)`, overwriting the
binding for the same local id. A second IR_STORE targeting the same
IR_VAL_LOCAL silently picked whichever store was lowered last in
block iteration order.

Concrete witness (before IMPL):

    I64 MultiDef(I64 a, I64 b, I64 c) {
        I64 x = a;
        I64 y = b;
        if (c > 0) y = a;
        return x + y;
    }

compiled to:

    bb4:
      %4 = add i64 %0, %0
      ret i64 %4

This is wrong: the function should return a+b when c<=0 and a+a when
c>0. The produced IR returns a+a in both branches. The bug is silent:
LLVM verifier accepts the IR because the IR is locally well-formed;
the bug is in our producer's contract.

ROOT CAUSE OF P0-2
------------------
The previous IMPL (1cfc34a6) regenerated three C1 RED evidence files
in evidence/llvmspike01-resume01-correction01/ with post-IMPL output
to make the harness's matrix after-state "consistent". F14 forbids
this: historical evidence is a record of the predecessor spike against
a different commit tree and must remain historically truthful.

A second-order problem (caught during this ACT's closure) was that
the harness itself was wired to write those transcripts into the
C1 dir on every run, not just during the original IMPL commit. Even
after restoring the C1 files in commit 910c6ec, the very next harness
run during the previous closure (1b63225) overwrote them again.
The harness's `$EVID_CORR` was redirected to this ACT's evidence
dir in commit f703cec so the harness can no longer mutate the C1
files at all.

RED
---
Commit 910c6ec:

* Captured RED for P0-1 in src/tests/llvm-spike/red_local_multi_def.HC
  and evidence/llvmspike01-resume01-correction01-resume01-correction01/red-multi_def/.
* Restored three C1 RED evidence files byte-for-byte from ENTRY.
* Mechanical AC for P0-2 recorded in C1-RESTORATION.txt.

IMPLEMENTATION
--------------
Commit 5eed2af:

* src/llvm-backend.c: added lc->local_defs (u8 bitmap, lazy alloc,
  freed per-function) and the second-store check inside IR_STORE
  PARAM_COPY branch. Diagnostic: LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL.
* scripts/quality/llvm-spike-test.sh: new multi-def section that
  exercises the new fixture and writes ONLY into this ACT's
  evidence dir (no longer into C1).

Commit f703cec (closure):

* scripts/quality/llvm-spike-test.sh: redirected EVID_CORR (the
  cmp predicate matrix's transcript destination) from the C1
  evidence dir to this ACT's live-red-transcripts/ subdir. This
  decouples harness execution from C1 immutability: harness runs
  no longer mutate the historical RED files.
* Re-restored the three C1 files (a second time) to the bde6045a
  blob, since the previous closure (1b63225) had re-broken them
  by running the harness during the closure phase.

GATES
-----
* gate-fast: PASS (untouched from previous ACT)
* gate-push HEAD: VERDICT=PASS
    SUBJECT=f703cecab5c58ed178e427cb23e703f9c03932bc
    CHECK=build STATUS=PASS
    CHECK=install STATUS=PASS
    CHECK=aot STATUS=PASS
    CHECK=jit STATUS=PASS
    CHECK=lsp STATUS=PASS
    CHECK=diff-check STATUS=PASS
* llvm-spike-test harness: PASS=13/FAIL=0
    - 5 positive fixtures (01_const ... 05_call)
    - 1 cmp predicate matrix (04_cmp_branch: icmp sgt)
    - 3 negative fixtures (neg_f64 / neg_pointer / neg_struct)
    - 1 neg_asm (parse-time rejection, not a backend witness)
    - 1 conservation: starts with LLVM ModuleID
    - 1 determinism: 01_const twice
    - 1 multi-def rejection (NEW: this ACT)
* LLVM verifier: all 5 positive .ll files pass llvm-as.
* Memory-op matrix after: alloca=0 store=0 load=0 across all 12
  original fixtures (the 13th is rejection, no .ll emitted).
* diff-check HEAD: rc=0.
* P0-2 mechanical AC (the one the reviewer demanded):
    git diff bde6045a200a1526435fd161f41b59e02df012b7..HEAD -- \
        evidence/llvmspike01-resume01-correction01/red-1B.emit-llvm.ll \
        evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.ll \
        evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.txt
    (empty) — confirmed after the final harness run.

SCOPE
-----
Authorised ACT scope only. No refactor of adjacent code. No fix
of unrelated style. No rename of abstractions. No hooks for
anticipated future work.

Production:
    src/llvm-backend.c          (LLCtx + IR_STORE rejection)
Tests:
    src/tests/llvm-spike/red_local_multi_def.HC  (NEW)
    scripts/quality/llvm-spike-test.sh           (multi-def section,
                                                  EVID_CORR redirect)
Evidence:
    evidence/llvmspike01-resume01-correction01-resume01-correction01/
        HANDOFF.md, identity.txt, implementation-summary.txt,
        C1-RESTORATION.txt, diff-check.txt,
        gate-push-implementation.log (+ .sha256, .b64),
        llvm-spike-test.matrix-after.txt,
        live-red-transcripts/  (harness transcripts, live only)
        red-multi_def/         (P0-1 RED + live rejection summary)
Restored (3 C1 files):
    evidence/llvmspike01-resume01-correction01/red-1B.emit-llvm.ll
    evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.ll
    evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.txt
    SHA256s verified equal to bde6045a200a entries (see C1-RESTORATION.txt).

RESIDUE
-------
P1: `LLVMBuildTrunc(i1 -> i1)` in IR_BR handler.
    The trunc is conceptually wrong (LLVM trunc is for integer bit
    width reduction, not predicate marking) but the C API happens
    to fold/no-op it on the test fixtures. Reviewer explicitly
    accepted this as residue for LLVM-CORE01. Not addressed here.

P1: `LLVMBuildTrunc(i64 -> i1)` shape vs `LLVMBuildICmp` directly.
    Same root cause as above. Folded into LLVM-CORE01 backlog.

P2: dominance-aware SSA construction. Closed off (rejection), not
    implemented. Needed for the full SSA pipeline if/when the spike
    graduates to LLVM-CORE01. Not in scope.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE01 (per previous ACT §87 Outcome A) — turn the
bounded experiment into a deliberately-supported scalar LLVM backend
core. This ACT has confirmed the SSA-only local contract is the right
boundary; CORE01 should canonise it and address the trunc residue.
