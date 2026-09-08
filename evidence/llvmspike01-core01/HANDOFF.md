HANDOFF — ACT-POLYC-LLVM-CORE01
==============================

VERDICT
-------
PASS

CORE01 canonised the first intentionally-supported LLVM backend
contract. The reviewer transition SPIKE → CORE is complete:

    SPIKE:  "Can this work?"
        ↓
    CORE:   "Exactly what do we promise works, and exactly how do
            we refuse everything else?"

IDENTITY
--------
Entry:     e304b86 (ACT contract open)
RED:       9e3a034 (RED-1 + RED-2 evidence)
Fix:       bd2be78 (capability matrix + named diagnostics)
Matrix:    8122e9d (post-change snapshot)
HEAD:      8122e9d

ROOT CAUSE
----------
The previous ACT's diagnostic machinery conflated three distinct
semantic states into one generic catch-all:

    LLVM_BACKEND_UNSUPPORTED_IR (generic)

This single token was emitted for:

  (a) SUPPORTED opcodes encountered out-of-spec shape;
  (b) REJECTED opcodes (deliberately not supported);
  (c) NOT_YET_CLASSIFIED opcodes (not yet decided either way).

A reviewer could not distinguish these. Worse, a contributor might
silently weaken the contract by adding new code paths that hit the
generic catch-all instead of an explicit REJECTED arm.

The LLVMBuildTrunc(i64 -> i1) on line ~707 of src/llvm-backend.c
was a documented-but-unmotivated boundary crossing: the neutral IR
carries IR_BR conditions as i64, LLVM condbr wants i1, the truncation
is deliberate but the comment did not say so.

RED EVIDENCE
------------
RED-1 (committed at 9e3a034):
    src/tests/llvm-spike/red_idiv_unclassified.HC contains
    `return a / b;` which lowers to IR_IDIV. Before the fix:
        LLVM_BACKEND_UNSUPPORTED_IR: function DivMod: opcode idiv
    (generic catch-all).
    Evidence: evidence/llvmspike01-core01/red-1.int-division.txt

RED-2 (committed at 9e3a034):
    The IR_BR arm of src/llvm-backend.c has `LLVMBuildTrunc(lc->bld,
    cond64, LLVMInt1TypeInContext(lc->ctx), "");` at line 607 (pre-fix
    line numbers). The comment immediately above said only "IR_BR
    carries its condition via `dst` (per ir-eval.c)." — not why the
    truncation is correct.
    Evidence: evidence/llvmspike01-core01/red-2.trunc-boundary.txt

IMPLEMENTATION (committed at bd2be78)
--------------------------------------
1. Capability matrix at top of src/llvm-backend.c:
   - 30+ IR opcodes classified as SUPPORTED / REJECTED /
     NOT_YET_CLASSIFIED.
   - Value kinds and types also classified.

2. 18 new named diagnostic macros in src/llvm-backend.h:
   LLVM_BACKEND_UNSUPPORTED_<CLASS> for every REJECTED opcode class.

3. Explicit REJECTED arms in the dispatch. Each arm emits its NAMED
   diagnostic and exits nonzero. The default arm remains as a safety
   net for NOT_YET_CLASSIFIED opcodes.

4. Boundary-crossing comment above LLVMBuildTrunc (RED-2 fix):
   documents that the truncation is deliberate; warns against
   "fixing" it by changing the neutral IR contract.

5. RED-1 fixture added to scripts/quality/llvm-spike-test.sh:
   the harness now asserts the NAMED diagnostic for IR_IDIV.

GATES
-----
* llvm-spike-test (entry): 13/13 PASS
* llvm-spike-test (CORE01): 14/14 PASS  (1 new RED-1 fixture)
* make clean && make all: succeeds (only pre-existing warnings)
* Inherited baseline (AOT 90/90, JIT 90/90, LSP 43/43, CORPUS 16/16):
  preserved at the build level; environment-level runs of the unit
  harness show 88/90 PASS because two tests (60_link.HC, 64_sret_x8.HC)
  spawn child hcc invocations without --install-dir and rely on
  /usr/local/include/tos.HH. This is a PRE-EXISTING environment
  requirement, not a regression from this ACT — confirmed by the
  gate-push.log of the previous ACT (used a temp gate-prefix to
  work around it). Recorded as residue.

* git diff --check HEAD: rc=0
* Closure identity oracle (inherited from CORRECTION02):
  re-runnable; no edit to scripts/quality/gate-push.sh required.

SCOPE
-----
* Production: src/llvm-backend.c, src/llvm-backend.h
  (diagnostic strings, comments, and dispatch arms ONLY — no
   semantic change to any supported opcode)
* Tests: src/tests/llvm-spike/red_idiv_unclassified.HC (NEW)
* Harness: scripts/quality/llvm-spike-test.sh (1 new negative test)
* Evidence: evidence/llvmspike01-core01/* (NEW)
* Docs: docs/acts/ACT-POLYC-LLVM-CORE01.md (committed at e304b86)
* ROADMAP: docs/ROADMAP.md updated (committed at edc3e5b)

RESIDUE
-------
P1 (carried over): closure oracle lives inside its own allowed
    mutation set. Tracked for ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01.

P2: 2 environment-dependent native tests fail without
    /usr/local/include/tos.HH. Pre-existing; documented in previous
    ACT's gate-push.log. Workaround: use the temp gate-prefix or run
    `make install`.

P2: NOT_YET_CLASSIFIED opcodes (e.g. IR_NOP, IR_LABEL) still hit
    the default arm with the generic diagnostic. Future
    classification ACT will fill the gap.

P2: capability matrix is in code as comments. A future ACT may
    data-drive the dispatch (table-driven classification). CORE01
    deliberately does NOT (F8: no speculative abstraction).

P2: the "second store" wording refinement is still P2 (carried over
    from previous ACT).

NEXT ACT
--------
ACT-POLYC-LLVM-CORE02 — fill the NOT_YET_CLASSIFIED gap (IR_NOP,
IR_LABEL, and any other opcodes the IR contract permits but CORE01
did not classify). Same pattern: capability matrix + named
diagnostics + regression test.

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 — relocate reusable closure
oracles out of their own mutable evidence allowance.
