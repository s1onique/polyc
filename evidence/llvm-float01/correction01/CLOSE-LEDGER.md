ACT-POLYC-LLVM-FLOAT01-CORRECTION01 / CLOSE ledger
==================================================

VERDICT: PASS

== Identity ==
  branch:        main
  HEAD:          (final CLOSE commit SHA; recorded by ACT-Verdict trailer)
  predecessor:   c73400b (FLOAT01 CLOSE -- being corrected)
  ACT contract:  docs/acts/ACT-POLYC-LLVM-FLOAT01-CORRECTION01.md
  evidence:      evidence/llvm-float01/correction01/

== Root cause / finding ==
  Reviewer identified 3 P0s + 3 P1s in the original FLOAT01 closure
  (commit c73400b). All three P0s were addressable WITHOUT
  touching production code:

  P0-1 (mechanical): trailing blank line in evidence file.
  P0-2 (F3 RED discipline): principal RED classification was
    conflated with post-admission qualification checks.
  P0-3 (HALT override): comparison-semantic binding was self-
    authorised by the RED summary without an ACT contract.
  P1-1, P1-2, P1-3: documentation corrections + missing witness.

  The F64 lowering itself (RED+IMPL+EVIDENCE) was GREEN and
  is unchanged.

== RED ==
  48fb1f5  M1 whitespace hygiene
  162d99e  ACT contract
  620e0c5  IMPL phase: documentation corrections + new witness

== Implementation (IMPL) ==
  620e0c5  All seven M-tasks addressed:
            M1 whitespace hygiene           done (48fb1f5)
            M2 truthful RED reclassification done (RED-SUMMARY-corrected.md)
            M3 comparison-semantic HALT     done (recon-ll-semantics.txt)
            M4 correct LLVM/x86 statement   done (comparison-predicate-map-corrected.txt)
            M5 correct fast-math C-API claim done (fast-math-purity-corrected.txt)
            M6 independent IR_FPTOSI witness done (neg_fptosi_witness.HC)
            M7 re-run gates                 done (gates logs)

== Evidence ==
  evidence/llvm-float01/correction01/:
    EVIDENCE-SUMMARY.md           P0/P1 close-out
    RED-SUMMARY-corrected.md      RED classification
    recon-ll-semantics.txt        (also under red/)
    comparison-predicate-map-corrected.txt
    fast-math-purity-corrected.txt
    negative-matrix-corrected.txt
    neg_fptosi_witness.ir.txt     IR dump showing `fptosi`
    neg_fptosi_witness.stderr.txt LLVM backend rejection `opcode fptosi`
    llvm-float01-test.log         FLOAT01_PASS=29 FAIL=0
    llvm-spike-test.log           PASS=18 FAIL=0
    llvm-memory01-test.log        PASS=6 FAIL=0
    llvm-memory01-nc5-probe.log   PASS (NC5 strong binding confirmed)
    cap-table-verifier.log        PASS
    factory-v2.log                PASS=35 FAIL=0
    gate-fast.log                 VERDICT=PASS

== Gates (M7 verification) ==
  ACT-range git diff --check HEAD~7..HEAD      PASS  (rc=0)
  llvm-float01-test.sh                        FLOAT01_PASS=29 FAIL=0
  llvm-spike-test.sh                          PASS=18 FAIL=0
  llvm-memory01-test.sh                       PASS=6 FAIL=0
  llvm-memory01-nc5-probe.sh                  PASS
  llvm-cap-table-verifier.py                  PASS
  factory-v2-test.sh                          PASS=35 FAIL=0
  gate-fast.sh                                VERDICT=PASS

== Scope ==
  In-scope files modified:
    evidence/llvm-float01/red/red-matrix-raw.txt       (M1)
    evidence/llvm-float01/red/RED-SUMMARY.md          (RED taxonomy, in tree)
    evidence/llvm-float01/impl/fast-math-purity.txt   (M5 documentation)
    evidence/llvm-float01/impl/comparison-predicate-map.txt (M4 documentation)
    evidence/llvm-float01/impl/negative-matrix.txt    (M6 documentation)
    evidence/llvm-float01/red/recon-ll-semantics.txt  (M3, NEW)
    evidence/llvm-float01/correction01/*              (NEW)
    scripts/quality/llvm-float01-test.sh              (added neg_fptosi_witness)
    src/tests/llvm-float01/neg_fptosi_witness.HC      (NEW)
    docs/handoffs/HANDOFF-POLYC-LLVM-FLOAT01.md       (corrected refs)
    docs/acts/ACT-POLYC-LLVM-FLOAT01-CORRECTION01.md  (NEW ACT contract)

  Out of scope and NOT modified (per ACT section 2 forbidden):
    src/llvm-backend.c
    src/llvm-backend-cap.c
    src/ir.c
    src/ast.c
    src/prslib.c
    any native backend (aarch64, x86_64, JIT)

== Residue ==
  P0  (recommended next): ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01
       The PolyC x86_64 native backend's IR_FCMP dispatch
       (src/x86_64.c:670-679, src/x86_64-jit.c:425-433) emits
       sete/setne/setb/setbe/seta/setae after `ucomisd`. With
       UCOMISD setting ZF=PF=CF=1 on NaN/unordered operands, FOUR
       of six predicates produce the WRONG IEEE-754 / LangRef result:
         EQ (sete):    NaN -> 1   WRONG; expected 0
         NE (setne):   NaN -> 0   WRONG; expected 1
         LT (setb):    NaN -> 1   WRONG; expected 0
         LE (setbe):   NaN -> 1   WRONG; expected 0
         GT (seta):    NaN -> 0   CORRECT (matches ogt)
         GE (setae):   NaN -> 0   CORRECT (matches oge)
       Defect set for the next ACT: EQ/NE/LT/LE. Conservation
       controls: GT/GE must NOT change. The defect matrix is
       mechanically derived from `ucomisd` flag behaviour in
       evidence/llvm-float01/red/recon-ll-semantics.txt. The LLVM
       backend binds to the LangRef semantics (which coincide with
       the aarch64 host oracle for NaN inputs). A separate ACT
       should repair the four broken x86_64 native predicates.

  P2 (carry-over from original FLOAT01 CLOSE):
       F64 FDIV/FREM via LLVM backend (FLOAT02 candidate)
       F32 arithmetic on LLVM backend (FLOAT02 candidate)
       F64 vector types on LLVM backend (FLOAT02 candidate)

== Reviewer P0/P1 close-out ==
  P0-1 whitespace hygiene          CLOSED (M1, commit 48fb1f5)
  P0-2 RED reclassification        CLOSED (M2, RED-SUMMARY-corrected.md)
  P0-3 HALT comparison semantic    CLOSED (M3, recon-ll-semantics.txt +
                                          corrected residue paragraphs)
  P1-1 LLVM/x86 statement          CLOSED (M4, comparison-predicate-map-corrected.txt
                                          + HANDOFF.md)
  P1-2 fast-math C-API claim       CLOSED (M5, fast-math-purity-corrected.txt)
  P1-3 IR_FPTOSI witness gap       CLOSED (M6, neg_fptosi_witness.HC +
                                          negative-matrix-corrected.txt)

== Next ACT ==
  ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 (recommended P0):
    Repair the PolyC x86_64 native backend's FCMP lowering to
    use ordered-predicate equivalent sequences so the x86_64
    native semantic matches the IEEE-754 / LangRef convention
    that the LLVM backend already binds to.

  Alternative next ACT (carry-over):
    ACT-POLYC-LLVM-FLOAT02: F64 FDIV/FREM, F32 promotion, or
    F64 vector types on the LLVM backend.
