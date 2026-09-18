HANDOFF -- ACT-POLYC-SELFHOST-LEXER03-CORRECTION02
====================================================

## VERDICT

PASS_TRUE_GREEN.

The LEXER03 BootstrapScanTrivia component is now mechanically
proven to compile to byte-identical object code under all four
compiler generations (G0 ./hcc, G1 hcc-bootstrap02, G2
hcc-bootstrap03, G3 hcc-bootstrap04).

The LEXER03 bootstrap qualification is COMPLETE.

## IDENTITY

  Branch: main
  HEAD:   c2504a2  (C3 EVIDENCE commit)
  Worktree: clean
  ACT:    docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION02.md
  Predecessor: ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01
               (CLOSED TRUE_GREEN at 1ce0cd63463052ac3f8702a6dcf796b9972dc0f1)

## ROOT CAUSE / FINDING

LEXER03 closed at `746880c` with the engineering claim that the
PolyC BootstrapScanTrivia component is semantically equivalent to
the legacy-C trivia path. The CORRECTION01 closure reclassified
the LEXER03 closure verdict to FALSE_GREEN (mandatory-AC TSV
defect), and CORRECTION01-CORRECTION01 additively repaired the
TSV to TRUE_GREEN.

What neither CORRECTION01 nor its correction ever proved is the
stronger self-hosting predicate:

  "Compiling the exact same selfhost-lexer-trivia.HC source with
   each successive compiler generation produces the same object
   bytes."

The existing LEXER03 evidence explicitly recorded this as
P0 residue ("LEXER03-specific stage2/stage3 fixed-point evidence
(out of CORRECTION01 scope)"). CORRECTION02 exists to close
that residue.

This ACT is the bounded, additive proof that the four-generation
object-code fixed point holds. The real experiment was performed
end-to-end on the host: G0..G3 each compiled
tools/bootstrap/selfhost-lexer-trivia.HC from absent output,
producing four 3880-byte objects whose bytes are pairwise
identical and whose SHA-256 is identical:

  object_sha256 (all four):
    560e98bf20277d1cedde553ee4cb3ef67f62dc9a5f4d3145813a55e7921f39c0

## RED

  evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION02/c1/

  c1-entry-identity.txt           : HEAD=c6e56fd, worktree clean
  c1-source-identity.txt          : source SHA-256 bound (one immutable blob)
  c1-compiler-identities.tsv      : G0..G3 SHA-256 bound
  c1-canonical-compile-contract.txt : frozen compile template
  c1-red-evidence-shortfall.txt   : principal RED (only one Make rule
                                     compiles selfhost-lexer-trivia.HC;
                                     only ./build/lexer08-trivia.o exists;
                                     build/lexer08-fixedpoint does not exist)
  c1-summary.txt                  : AC01..AC04 PASS; RED firmly closed

## IMPLEMENTATION

  Makefile (C2 IMPL): added 7 new targets under the lexer08 family
    lexer08-trivia-fixedpoint-g{0,1,2,3}    (per-generation compile)
    lexer08-trivia-fixedpoint-build         (4-output aggregator)
    lexer08-trivia-fixedpoint-verify        (PolyC verifier invocation)
    lexer08-trivia-fixedpoint               (composite: build + symbols
                                             + verifier + summary tokens)
    build/lexer08-fixedpoint-verify         (PolyC verifier binary)

  tools/quality/lexer08-fixedpoint-verify.HC (C2 IMPL):
    PolyC tool. Reads N files (4 or 5 for negative control). Pairwise
    MemCmp-based ObjectsByteEqual. SHA-256 per file via subprocess
    call to ./build/lexer07-sha256. Closes closed-evidence path guard.
    On pristine 4-file run: exit 0 + LEXER03_TRIVIA_FIXED_POINT_4_GENERATIONS=PASS.
    On 5-file negative-control run with 5th != 4th: exit 1 +
    NEGATIVE_CONTROL=PASS + BYTE_MISMATCH_DETECTED=YES.

  scripts/quality/lexer08-trivia-fixedpoint.sh (C2 IMPL):
    <=20 LOC dispatch glue. F-POLYC-TOOLS compliant.

No production lexer source was modified. No Python was added.

## GATES

  evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION02/c3/

  Required result ledger:
    G0_COMPILE = PASS   (G0_COMPILE_RC=0)
    G1_COMPILE = PASS   (G1_COMPILE_RC=0)
    G2_COMPILE = PASS   (G2_COMPILE_RC=0)
    G3_COMPILE = PASS   (G3_COMPILE_RC=0)
    G0_G1_BYTE_EQUAL = YES
    G0_G2_BYTE_EQUAL = YES
    G0_G3_BYTE_EQUAL = YES
    G1_G2_BYTE_EQUAL = YES
    G1_G3_BYTE_EQUAL = YES
    G2_G3_BYTE_EQUAL = YES
    OBJECT_SHA256_UNIQUE_COUNT = 1
    OBJECT_SIZE_UNIQUE_COUNT  = 1
    BOOTSTRAP_SCAN_TRIVIA_PRESENT_ALL_GENERATIONS = YES
    G3_REPEAT_BYTE_EQUAL = YES
    NEGATIVE_CONTROL = PASS
    LEXER08_DIRECT_DIFFERENTIAL              = 45/45 PASS
    LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1 = PASS
    LEXER01_CONSERVATION                     = 47/47 PASS
    LEXER02_CONSERVATION                     = 89/89 PASS
    LEXER07_PRODUCTION_SEAM_4_STAGES         = PASS
    LEXER08_BROAD_CORPUS_4_STAGE             = PASS

  Factory gates:
    gate-fast                 = PASS (VERDICT=PASS)
    factory-append-only-test  = PASS=11 FAIL=0
    factory-no-python-check   = baseline parity (no new Python)

  Patch hygiene:
    git diff --check          clean
    git diff src/ tools/bootstrap/selfhost-lexer-trivia.HC  empty

  mandatory-ac-status.tsv:
    PASS=27  NONPASS=0  TOTAL=27

## SCOPE

  Source files NOT modified (forbidden; F7 / scope conservation):
    src/lexer.c
    src/lexer_bridge.h
    tools/bootstrap/selfhost-lexer-trivia.HC

  Files added/modified (all in-scope):
    Makefile                                                          (build orchestration)
    tools/quality/lexer08-fixedpoint-verify.HC                        (PolyC verifier)
    scripts/quality/lexer08-trivia-fixedpoint.sh                      (shell launcher)
    docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION02.md              (this ACT)
    docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION02.md   (this HANDOFF)
    docs/ROADMAP.md                                                   (additive amendment)
    evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION02/c1/              (C1 RED evidence)
    evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION02/c3/              (C3 EVIDENCE)

  No F14-protected file was rewritten. All closed LEXER03,
  CORRECTION01, and CORRECTION01-CORRECTION01 evidence is
  preserved verbatim.

## RESIDUE

  Resolved:
    P0: LEXER03-specific stage2/stage3 fixed-point evidence
        -> RESOLVED by this ACT (LEXER03_BOOTSTRAP_QUALIFICATION=COMPLETE).

  Outstanding (unchanged from prior ACTs):
    P1: test-prefix-install failure (pre-existing, unrelated to this ACT)
    P1: ACT-after-work governance (already documented in prior HANDOFFs)
    P2: broader self-host recon refresh
    P2: Python baseline (12 grandfathered files; unchanged)

  New (introduced by this ACT):
    P2: Verify the fixed-point proof remains green on x86_64 Linux.
        This ACT's evidence was captured on arm64-apple-darwin.

## NEXT ACT

  Per ACT §30: only after TRUE GREEN, run fresh SELFHOST surface
  recon to select the next actual self-host blocker. LEXER04 is
  a candidate but must not be auto-selected by numbering alone.

  Recommendation:
    NEXT = ACT-POLYC-SELFHOST-SURFACE-RECON02 (fresh recon)
    then select LEXER04 or whichever region wins the ranking.
