# HANDOFF -- ACT-POLYC-BOOTSTRAP01

Factory-Version: 2

## Result

B0 compiler-shaped bootstrap CLOSED PASS. A PolyC-written,
allocation-free lexer/tokenizer (BootstrapLex) compiles
through the current hcc (native AOT path), executes, and
produces token streams equivalent to an independent C
reference oracle across the frozen 15-fixture matrix
(T01..T14 + NC6/NC7/NC8). 15/15 fixtures pass with
run1 == run2 (determinism), src bytewise unchanged
before/after (immutability), and bounded writes
(out_count <= out_cap).

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

Production additions (frozen B0 scope only):

  tools/bootstrap/bootstrap01-lexer.HC
    Allocation-free, single-pass PolyC lexer/tokenizer.
    Public class BootstrapToken { kind, start, len }.
    Public function BootstrapLex(src, src_len, out,
                                 out_cap, out_count).
    Frozen BTK_* kind ABI (BTK_EOF=0 .. BTK_ASSIGN=15)
    and frozen BLEX_* status codes.

  tools/quality/bootstrap01-lexer-oracle.c
    Independent C99 reference lexer (no dependencies).

  tools/quality/bootstrap01-lexer-test.HC
    Differential driver. Loads frozen fixtures, runs
    BootstrapLex twice, compares to frozen oracle
    baseline, prints SUB streams in canonical format.

  Makefile
    New phony targets bootstrap01-oracle and
    bootstrap01-test. No other Makefile changes.

Documentation:

  docs/acts/ACT-POLYC-BOOTSTRAP01.md
    The B0 authorization artifact (Factory v2).
    Lexer-only scope; parser/AST/codegen forbidden.

  evidence/ACT-POLYC-BOOTSTRAP01/c1/  C1 RED packet
  evidence/ACT-POLYC-BOOTSTRAP01/c2/  C2 IMPL packet
  evidence/ACT-POLYC-BOOTSTRAP01/c3/  C3 EVIDENCE packet
  evidence/ACT-POLYC-BOOTSTRAP01/c4/  C4 CLOSE packet
  evidence/ACT-POLYC-BOOTSTRAP01/HANDOFF.md  this file

No compiler / parser / AST / codegen / LLVM / AOT / IR /
backend / ABI / runtime / historical evidence source
was modified.

## Evidence

Predecessor chain:

  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01         CLOSED PASS
  ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01  CLOSED PASS
  ACT-POLYC-AOT-PIC-EXTERNAL-REFS01           CLOSED PASS
  ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 CLOSED PASS
  ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02 CLOSED PASS

B0-specific evidence:

  c1/successor-dependency.txt
    B0_REQUIRES_GEP_COMPILER_FEATURE = YES
    B0_REQUIRES_GEP01_HARNESS        = NO  (Outcome A)
    GEP01_D1_BLOCKS_B0               = NO
    GEP01_D2_BLOCKS_B0               = NO

  c1/allocation-decision.txt
    B0_ALLOCATION = NOT_REQUIRED

  c2/subject-build.txt + c2/subject-run.stdout
    BOOTSTRAP01_CASES=15 PASS=15 FAIL=0 STATUS=PASS

  c3/differential-results.txt
    15/15 fixtures: run2_eq=yes, src_eq=yes, exp_eq=yes

  c4/acceptance-matrix.txt
    AC01..AC44 all PASS or INHERITED; no FAIL

  c4/closure-summary.txt
    Canonical verdict block

Conservation gates (fresh in this environment):

  factory-v2-test                PASS  PASS=35 FAIL=0
  factory-append-only-test       PASS  PASS=11 FAIL=0
  factory-closure-status-check   PASS  PAIR_OK=6 PAIR_FAIL=0
  factory-halt-classification     PASS  PASS=12 FAIL=0
  shell-loc-gate                 PASS
  gate-fast                      PASS

Inherited (per predecessor ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
c3 evidence at b76f0d8):

  make unit-test       INHERITED 90/90 PASS
  make jit-unit-test   INHERITED 90/90 PASS
  make lsp-test        INHERITED 43/43 PASS

The inherited gates cannot be re-run fresh via `make` in
this sandbox because /usr/local/include/tos.HH does not
exist (the inherited src/tests/run.HC invokes hcc without
--install-dir, expecting the compile-time default).
This is pre-existing environmental residue, identical at
the pre-B0 commit (72f61e3), and is classified as
NON_BLOCKING_GOVERNANCE_RESIDUE per ACT §22.

## Production delta

Total production source delta:

  tools/bootstrap/bootstrap01-lexer.HC        +B0 subject
  tools/quality/bootstrap01-lexer-oracle.c    +C oracle
  tools/quality/bootstrap01-lexer-test.HC     +PolyC driver
  Makefile                                    +2 phony targets
  docs/acts/ACT-POLYC-BOOTSTRAP01.md          +ACT doc
  evidence/ACT-POLYC-BOOTSTRAP01/             +full evidence pack

Total src/ delta: 0 bytes.

The current production compiler lexer is unchanged (ACT §31).

## Residue

P0: NONE.

P1:

  R-P1-1  GEP01 cap-verifier (26/4 pre-existing).
  R-P1-2  LLVM-backend IR_STORE_DEREF for variable-indexed
          struct field writes (MEMORY01 fence). Path-
          dependent per Option-W C6.
  R-P1-3  Inherited src/tests/run.HC spawn path (no
          --install-dir). Environmental /usr/local/include/
          tos.HH absence. Pre-existing, identical at pre-B0.

P2:

  R-P2-1  LLVM-capable B0 variant (after MEMORY01 widens).
  R-P2-2  `make bootstrap01-oracle-all` target to loop the
          C oracle over the full fixture matrix.

## Recommended next ACT

ACT-POLYC-BOOTSTRAP02 (or equivalent bounded B1 ACT):
replace one bounded production lexer path with the proven
B0 lexer and pass differential tests against the current
compiler. Do NOT open until the B0 evidence is audited
and the LLVM-path question (R-P1-2) is decided if the
B1 target needs the LLVM path.
