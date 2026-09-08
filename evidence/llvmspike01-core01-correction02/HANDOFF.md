HANDOFF — ACT-POLYC-LLVM-CORE01-CORRECTION02
==============================================

VERDICT
-------
PASS

This ACT reconciles CORRECTION01's false-GREEN closure, performs
fresh IR_BR seam recon, and widens the negative matrix to six
distinct backend rejection classes. CORE01 implementation is
preserved; only docs/evidence/test-fixtures changed.

IDENTITY
--------
Entry:  b05ea7e (CORRECTION01 HEAD, HALT_TOPOLOGY_RECORDED)
RED:    19872d5 (CORRECTION02 RED + IR_BR recon + 2 fixtures)
DOCS:   (this commit)
HEAD:   (this commit)

Total CORRECTION02 commits: 2 (RED + DOCS). Within cap.

ROOT CAUSE
----------
CORRECTION01 closed with a false-GREEN premise (P0-3 in the
reviewer's CORRECTION02 verdict): it asserted IR_BR is dead code,
contradicting the established pipeline recon that the LLVM path
does not invoke native fusion. The IMPL change at 99a8531 was
correct, but the RED justification was wrong.

RED EVIDENCE
------------
Mission 1 (IR_BR seam recon):
  evidence/llvmspike01-core01-correction02/red-p04-irbr-live.txt

  Findings:
    IR_BR reached for 7/7 branched positive fixtures
    IR_CMP_BR reached for ZERO fixtures on the LLVM path
    Cond physical type = i1 (LLVMIntegerTypeKind width 1)

IMPLEMENTATION
--------------
Mission 2 (rejected-class coverage): 2 new RED fixtures added.
  src/tests/llvm-spike/red_remainder_mod.HC
    -> LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
  src/tests/llvm-spike/red_shift_shl.HC
    -> LLVM_BACKEND_UNSUPPORTED_INT_SHIFT

  scripts/quality/llvm-spike-test.sh wired to assert both
  diagnostics + nonzero RC. NO source code change in
  src/llvm-backend.c (the dispatch arms for both classes already
  exist; this ACT only adds witnesses per the reviewer's "no
  source change unless fresh RED proves 99a8531 wrong" directive).

Mission 3 (docs-only closure reconciliation): CORRECTION01's
HALT_TOPOLOGY_RECORDED state is preserved in this ACT's evidence
(post-impl-topology.txt). NO retroactive rewriting of CORRECTION01
commits (F14).

GATES (verified at HEAD)
------------------------
* git diff --check HEAD: rc=0
* git diff src/llvm-backend.c: empty (no source change)
* git diff src/llvm-backend.h: empty (no source change)
* make clean && make: succeeds
* llvm-spike-test: PASS=18 FAIL=0
  (was 16 in CORRECTION01; +red_remainder_mod, +red_shift_shl)
* Negative matrix now covers 6 DISTINCT classes:
    LLVM_BACKEND_UNSUPPORTED_TYPE
    LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
    LLVM_BACKEND_UNSUPPORTED_CONVERSION
    LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
    LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
* 04_cmp_branch.HC still emits verifier-clean LLVM IR (llvm-as rc=0)

SCOPE
-----
* docs/acts/ACT-POLYC-LLVM-CORE01-CORRECTION02.md: NEW
* src/tests/llvm-spike/red_remainder_mod.HC: NEW
* src/tests/llvm-spike/red_shift_shl.HC: NEW
* scripts/quality/llvm-spike-test.sh: +2 negative witnesses
* evidence/llvmspike01-core01-correction02/*: NEW

NOT changed:
* src/llvm-backend.c (byte-identical to CORRECTION01 HEAD)
* src/llvm-backend.h (byte-identical to CORRECTION01 HEAD)
* docs/acts/ACT-POLYC-LLVM-CORE01.md (preserved, F14)
* docs/acts/ACT-POLYC-LLVM-CORE01-CORRECTION01.md (preserved, F14)
* evidence/llvmspike01-core01-correction01/* (preserved, F14)

RESIDUE
-------
P1: closure oracle trust (FT1) - unchanged.
P2: NOT_YET_CLASSIFIED opcodes (IR_NOP, IR_LABEL) - unchanged.
P2: CORE01's matrix comment for IR_BR mentions "non-fused fallback"
    which is misleading (fusion never happens on the LLVM path; the
    code path IS the only path). A future cleanup ACT may correct
    the comment to reflect live use.
P2: "second store" wording refinement (carried over).
P2: CORE01 closure remains REJECTED in the audit trail (F14).

NEXT ACT
--------
ACT-POLYC-LLVM-CORE02:
  - fill the NOT_YET_CLASSIFIED gap (IR_NOP, IR_LABEL);
  - audit any other opcode whose supported/rejected status depends
    on operand/value shape;
  - clean up the IR_BR matrix comment ("non-fused fallback" is
    misleading since fusion never happens on the LLVM path).

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1).
