ACT-POLYC-LLVM-FLOAT01-CORRECTION01 / EVIDENCE summary
======================================================

Mission tasks completed:
  M1 whitespace hygiene                    DONE (commit 48fb1f5)
  M2 truthful RED reclassification        DONE (RED-SUMMARY-corrected.md)
  M3 comparison-semantic HALT decision    DONE (recon-ll-semantics.txt)
  M4 correct LLVM/x86 statement           DONE (comparison-predicate-map-corrected.txt)
  M5 correct fast-math C-API claim        DONE (fast-math-purity-corrected.txt)
  M6 independent IR_FPTOSI witness        DONE (neg_fptosi_witness.HC + .ir.txt + .stderr.txt)
  M7 re-run gates                         DONE (this summary)

== Final gate state (M7) ==

All gates run from /tmp with HCC_INSTALL_DIR set:

  scripts/quality/llvm-float01-test.sh         FLOAT01_PASS=29 FAIL=0
  scripts/quality/llvm-spike-test.sh           PASS=18  FAIL=0
  scripts/quality/llvm-memory01-test.sh        PASS=6   FAIL=0
  scripts/quality/llvm-memory01-nc5-probe.sh   PASS  (NC5 strong binding confirmed)
  scripts/quality/llvm-cap-table-verifier.py   PASS  (no contract drift)
  scripts/quality/factory-v2-test.sh           PASS=35 FAIL=0
  scripts/quality/gate-fast.sh                 VERDICT=PASS
  ACT-range git diff --check HEAD~5..HEAD      PASS  (rc=0; whitespace hygiene)

The FLOAT01 PASS count grew from 28 to 29 because the new
neg_fptosi_witness fixture is now part of the negative matrix.

== Files added by CORRECTION01 ==

  docs/acts/ACT-POLYC-LLVM-FLOAT01-CORRECTION01.md       (the bounded ACT contract)
  src/tests/llvm-float01/neg_fptosi_witness.HC          (independent IR_FPTOSI witness)
  evidence/llvm-float01/red/recon-ll-semantics.txt      (LangRef binding)
  evidence/llvm-float01/correction01/*.md,txt,log       (correction captures)

== Files modified by CORRECTION01 ==

  evidence/llvm-float01/red/red-matrix-raw.txt          (M1: trailing blank trimmed)
  scripts/quality/llvm-float01-test.sh                  (added neg_fptosi_witness)

== Production code changes: NONE ==

Per ACT section 2 forbidden list:
  src/llvm-backend.c               UNTOUCHED
  src/llvm-backend-cap.c           UNTOUCHED
  src/ir.c / src/ast.c / src/prslib.c  UNTOUCHED
  any other src/                   UNTOUCHED

The F64 lowering implementation that was already in tree
(RED+IMPL commits 4592d79 and 99391c4) is unchanged.

== Reviewer P0/P1 close-out ==

  P0-1 whitespace hygiene             CLOSED (M1)
  P0-2 RED reclassification          CLOSED (M2 + RED-SUMMARY-corrected.md)
  P0-3 HALT comparison semantic      CLOSED (M3 + recon-ll-semantics.txt
                                       + corrected residue paragraphs)
  P1-1 LLVM/x86 statement            CLOSED (M4 + comparison-predicate-map-corrected.txt)
  P1-2 fast-math C-API claim         CLOSED (M5 + fast-math-purity-corrected.txt)
  P1-3 IR_FPTOSI witness gap         CLOSED (M6 + neg_fptosi_witness.HC)

== Residue ==

  P0 ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01:
    The PolyC x86_64 NATIVE backend's IR_FCMP dispatch
    (src/x86_64.c:670-679, src/x86_64-jit.c:425-433) emits
    sete/setne/setb/setbe/seta/setae after `ucomisd`. With
    UCOMISD setting ZF=PF=CF=1 on NaN/unordered operands, all
    six predicates produce the WRONG IEEE-754 / LangRef result:
    ==, <, <= return 1; !=, >, >= return 0. The defect matrix
    is mechanically derived in
    evidence/llvm-float01/red/recon-ll-semantics.txt (Observed
    residue section). Out of scope for this ACT; recorded as
    future work.

== Next ACT ==

  ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 (P0 recommended):
    Repair the PolyC x86_64 native backend's FCMP lowering to
    use ordered-predicate equivalent sequences
    (`ucomisd + setnp + setz / setnz`) so the x86_64 native
    semantic matches the IEEE-754 / LangRef convention that
    the LLVM backend already binds to.
