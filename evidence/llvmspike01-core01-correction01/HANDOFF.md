HANDOFF — ACT-POLYC-LLVM-CORE01-CORRECTION01
==============================================

VERDICT
-------
PASS

CORE01 closure was REJECTED at f4ac2e7 with four P0 defects. This
CORRECTION01 ACT closes them honestly:

    P0-1  blank-at-EOF removed; git diff --check returns rc=0
    P0-2  CORRECTION01 caps at 1 production + 1 docs/evidence
    P0-3  IR_LOAD/IR_STORE matrix updated to SHAPE-DEPENDENT
    P0-4  IR_BR arm uses LLVMTypeOf dispatch; honest comment
    AC06  negative matrix widened to six real backend witnesses

IDENTITY
--------
Entry:      f4ac2e7 (CORE01 HEAD, REJECTED)
RED:        2d5b626 (CORRECTION01 RED - 4 P0 defects recorded)
IMPL:       99a8531 (matrix + dispatch + harness wired + blank-EOF fix)
HEAD:       99a8531

Total commits this ACT: 2 (RED + IMPL). Within cap.

ROOT CAUSE
----------
CORE01 closed with a PASS claim while:
  - having a whitespace defect (blank-at-EOF) that violates git
    diff --check (AC09 contract);
  - shipping 5 commits while declaring caps of 3 (§10) and 2 (AC11);
  - claiming IR_STORE is REJECTED in the matrix while supporting 2
    distinct shapes via two separate code paths;
  - claiming the IR_BR trunc is a "deliberate boundary crossing"
    while the IR_BR arm is dead code (IR_ICMP+IR_BR fuses to
    IR_CMP_BR before dispatch).

Each defect is documented as RED evidence under
evidence/llvmspike01-core01-correction01/red-*.txt.

RED EVIDENCE
------------
P0-1: red-p01-blank-eof.txt  (git diff --check stdout at entry)
P0-2: red-p02-topology.txt   (commit chain + cap table)
P0-3: red-p03-irstore-matrix-vs-code.txt  (matrix vs actual shapes)
P0-4: red-p04-irbr-dead.txt  (dump-ir transcripts + fusion analysis)

IMPLEMENTATION (committed at 99a8531)
--------------------------------------
1. docs/acts/ACT-POLYC-LLVM-CORE01.md:
   - trailing blank line removed (P0-1)

2. src/llvm-backend.c matrix (top-of-file):
   - IR_LOAD and IR_STORE rows: SHAPE-DEPENDENT with shape table
     below (P0-3)
   - IR_BR row: note about non-fused fallback + LLVMTypeOf dispatch
     (P0-4)

3. src/llvm-backend.c IR_BR arm:
   - replaced the "deliberate boundary crossing" comment with
     honest dispatch (P0-4):
       LLVMTypeOf(cond) -> {
         i1: use directly,
         i64: trunc to i1,
         other: reject with named boundary diagnostic
       }
   - the i64 guard on the neutral-IR side stays (correct contract)

4. src/tests/llvm-spike/red_conversion_trunc.HC: NEW fixture that
   exercises IR_TRUNC -> CONVERSION class rejection.

5. scripts/quality/llvm-spike-test.sh:
   - red_local_multi_def.HC promoted to the canonical negative
     matrix (was a separate section)
   - red_conversion_trunc.HC added to the negative matrix

GATES (verified at 99a8531)
---------------------------
* git diff --check HEAD..HEAD~2: rc=0 (P0-1 fixed)
* git diff --check HEAD~2..HEAD: rc=0 (history preserved)
* make clean && make: succeeds (with JIT=on, the only working
  config when LLVM_ENABLE=on; CMakeLists.txt quirk: target_link
  _libraries(hcc tasm ...) is inside if(HCC_ENABLE_JIT))
* llvm-spike-test: PASS=16 FAIL=0
  (was 14 in CORE01; +red_local_multi_def, +red_conversion_trunc)
* 04_cmp_branch.HC: emits verifier-clean LLVM IR
  (llvm-as rc=0; trunc i64 -> i1 path is exercised by historical
   pred_*.HC fixtures)
* IR_BR dead-code analysis: unchanged from RED-4. The dispatch
  improvement is correct-by-construction but is NOT exercised by
  current spike fixtures. CORE02-classification ACT may construct
  a controlled unfused path.

SCOPE
-----
* src/llvm-backend.c: matrix (comments) + IR_BR dispatch (no new
  SUPPORTED opcode/type)
* src/llvm-backend.h: unchanged
* docs/acts/ACT-POLYC-LLVM-CORE01.md: trailing whitespace fix
* docs/acts/ACT-POLYC-LLVM-CORE01-CORRECTION01.md: NEW (this ACT)
* src/tests/llvm-spike/red_conversion_trunc.HC: NEW
* scripts/quality/llvm-spike-test.sh: 2 new negative matrix entries
* evidence/llvmspike01-core01-correction01/*: NEW

No neutral IR contract change. No target machine/execution/ORC.
No data-driven dispatch framework (F8 preserved).

RESIDUE
-------
P1 (carried over): closure oracle trust (FT1).
P2: IR_BR is the dead-code non-fused fallback. Future CORE02 may
    construct a controlled unfused path to exercise the dispatch.
P2: NOT_YET_CLASSIFIED opcodes (IR_NOP, IR_LABEL) still hit the
    generic arm.
P2: "second store" wording refinement (carried over).

NEXT ACT
--------
ACT-POLYC-LLVM-CORE02:
  - fill the NOT_YET_CLASSIFIED gap (IR_NOP, IR_LABEL);
  - construct a controlled IR_BR path to verify the dispatch;
  - audit any other opcode whose supported/rejected status depends
    on operand/value shape (the SHAPE-DEPENDENT pattern from
    CORRECTION01 may apply elsewhere).

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01
