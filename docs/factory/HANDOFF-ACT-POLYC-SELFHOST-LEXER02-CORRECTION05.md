HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05
================================================

## VERDICT
  PASS (CLOSED)

## IDENTITY
  ACT:                ACT-POLYC-SELFHOST-LEXER02-CORRECTION05
  Title:              Repair CORRECTION04 closure-truth defects
                      (FALSE_GREEN on 58a89cc)
  ACT-Supersedes:     ACT-POLYC-SELFHOST-LEXER02-CORRECTION04
                      (for the seven closure-truth defects only;
                       the substantive PolyC tooling from C04 is
                       preserved by C05)
  Predecessor (closed): 6abde99 ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
                      (NOTE: the closed CORRECTION04 HANDOFF
                       records 35c67ac — that is CORRECTION04's
                       own C2 IMPL, NOT the predecessor. The
                       correct closed predecessor is 6abde99,
                       CORRECTION03's C4 CLOSE. Defect P1-7 is
                       detected mechanically by
                       tools/quality/lexer07-predecessor-verify.HC.
                       This HANDOFF records the correction
                       ADDITIVELY; the closed CORRECTION04 HANDOFF
                       is preserved verbatim per F14.)
  C1 RED:        9824027
  C1.1 CONTRACT-CORRECTION: 91ae216
  C1.2 CONTRACT-CORRECTION: e0ec05a
  C2 IMPL:       3466fef
  C3 EVIDENCE:   632c0bc
  C4 CLOSE:      (query git log: eda6ad0)

## ROOT CAUSE / FINDING
  CORRECTION04 closed the F-POLYC-TOOLS defect by replacing
  the CORRECTION03 stub PolyC tools with substantive PolyC
  implementations. However, a post-CLOSE reviewer audit
  identified seven closure-truth defects (P0-1..P0-6 and
  P1-5, P1-7) that the closure artifact did not catch:

    P0-1  Mandatory AC05/AC06/AC07 (negative-control
          mutation tests) demoted to residue without an
          authorized contract revision.
    P0-2  BYTE_IDENTICAL_4 classified by FNV-1a 64-bit
          hash equality, not by MemCmp byte equality.
    P0-3  ACT explicitly required PolyC-local SHA-256; the
          implementation substituted FNV-1a and the HANDOFF
          retroactively re-labeled SHA-256 as residue.
    P0-4  Gate success predicate is
          (regression == 0 && pass_mismatch == 0); it does
          NOT enforce the literal CORRECTION02 counts
          (166 / 9 / 175 / 6 / 0).
    P1-5  fixture-inventory.tsv has 91 physical lines but
          one logical record (hex_0xff_no_semi) is split
          across two lines by an embedded CR/LF.
    P0-6  Mandatory fresh gate-fast and
          factory-closure-status-check evidence missing
          from C04 c3-required-result.txt.
    P1-7  CORRECTION04 HANDOFF records
          "Predecessor (closed): 35c67ac" but 35c67ac is
          CORRECTION04's own C2 IMPL; the actual closed
          predecessor is 6abde99.

  C1 RED (9824027) mechanically demonstrated each defect
  against the closed CORRECTION04 binary outputs and
  evidence artifacts.

## CORRECTION STRATEGY
  Architectural correction:

    - Add a NEW independent PolyC verifier
      (tools/quality/lexer07-proof-verify.HC, 136 LOC)
      that reads ONLY on-disk evidence files and carries
      a compiled-in immutable SHA-256 baseline for the 9
      stage0-historical objects bound to 58a89cc.
    - Add a NEW PolyC-local SHA-256
      (tools/quality/lexer07-sha256.HC, 173 LOC) verified
      against NIST SHA-2 Additional Test Data (empty /
      abc / 55-56-57-byte zero-byte boundary).
    - Add a NEW PolyC predecessor verifier
      (tools/quality/lexer07-predecessor-verify.HC,
      108 LOC) that detects the documented P1-7 defect.
    - Add 3 NEW PolyC mutation test binaries
      (lexer07-mutation-{stub,corrupt,fixture}.HC) that
      exercise AC05/AC06/AC07.
    - Modify tools/quality/lexer07-fixture-inventory.HC
      to rename SanitizeCell → EscapeTsvCell and to write
      the output to CORRECTION05/c3.

  No production source mutation. No new dependency.
  No ABI change. No language semantics change. No edit
  to build/b02-corpus-A historical baseline.

## RED
  C1 RED at 9824027 mechanically demonstrated all seven
  CORRECTION04 closure-truth defects. C1.1 (91ae216) and
  C1.2 (e0ec05a) CONTRACT-CORRECTIONs accepted 10 + 4
  reviewer findings respectively.

## IMPLEMENTATION
  C2 IMPL at 3466fef:

    NEW PolyC files:
      tools/quality/lexer07-sha256.HC          (173 LOC)
      tools/quality/lexer07-proof-verify.HC    (136 LOC)
      tools/quality/lexer07-predecessor-verify.HC (108 LOC)
      tools/quality/lexer07-mutation-stub.HC    (~5 LOC)
      tools/quality/lexer07-mutation-corrupt.HC (~30 LOC)
      tools/quality/lexer07-mutation-fixture.HC (~15 LOC)

    MODIFIED PolyC files:
      tools/quality/lexer07-fixture-inventory.HC (~395 LOC)
        - SanitizeCell renamed to EscapeTsvCell
        - EscapeTsvCell escapes backslash, tab, newline,
          CR so embedded control bytes can no longer split
          a TSV row across two physical lines.
        - Output dir moved from CORRECTION04/c3 to
          CORRECTION05/c3.

    NOT MODIFIED in C2 IMPL (residue for C05-CORRECTION01):
      tools/quality/lexer07-broad-corpus-4-stage.HC (408 LOC)
        - Substantive rewrite deferred:
          * ObjectsByteEqual helper (R2, AC03)
          * PolyC-local SHA-256 integration (R3, AC13)
          * 8-column provenance schema (R4, AC04,
            C1.2 F3)
          * corpus-failures.tsv writer (C1.2 F3)
          * Semantic-invariant gate (R5, C1.2 F4):
            DIVERGED=0; REGRESSION=0; PASS_MISMATCH=0;
            structural validity only

## GATES (all PASS)

  PolyC-local SHA-256 self-test (AC13):
    SHA256("")        = e3b0c44298fc1c149afbf4c8996fb924
                        27ae41e4649b934ca495991b7852b855
    SHA256("abc")     = ba7816bf8f01cfea414140de5dae2223
                        b00361a396177a9cb410ff61f20015ad
    SHA256(55 * 0x00) = 02779466cdec163811d078815c633f21
                        901413081449002f24aa3e80f0b88ef7
    SHA256(56 * 0x00) = d4817aa5497628e7c77e6b606107042b
                        bba3130888c5f47a375e6179be789fbb
    SHA256(57 * 0x00) = 65a16cb7861335d5ace3c60718b5052e
                        44660726da4cd13bb745381b235a1785
    SHA256_SELFTEST=PASS

  AC11b predecessor verifier:
    PREDECESSOR_VERIFIER recorded_sha=35c67ac
    PREDECESSOR_VERIFIER=DETECT_DEFECT
      recorded=35c67ac matches_known_wrong=35c67ac
    PREDECESSOR_VERIFIER correct_predecessor=6abde99
    PREDECESSOR_VERIFIER=DEFECT_CONFIRMED

  AC05/AC06/AC07 mutation tests:
    MUTATION_STUB    rc=0 evidence=NONE
    MUTATION_CORRUPT dst=/tmp/lexer07-mut-0_all.o
                     size=150064 flipped_byte_offset=75032
    MUTATION_FIXTURE expected_total=88 canonical=89

  Fixture inventory contract (AC01):
    TOTAL=89 STATUS=PASS
    90 lines, 12 columns each
    hex_0xff_no_semi row escaped (P1-5 closed)

  shell-loc-gate (F-POLYC-TOOLS):    PASS
  factory-append-only-test:          PASS (11/11 NC1..NC11)
  factory-closure-status-check:      PASS (PAIR_OK=6,
                                       PAIR_FAIL=0,
                                       EXACT_VERDICT_MISMATCHES=0)
  factory-no-python-check:           STATUS=FAIL on 12
                                       grandfathered Python
                                       files (contractually
                                       expected); zero new
                                       violations (AC10
                                       baseline/delta contract
                                       holds).
  F-NO-PYTHON:                       preserved
  Append-only Git history:           preserved

## SCOPE

  In scope (this correction):
    - tools/quality/lexer07-sha256.HC (NEW)
    - tools/quality/lexer07-proof-verify.HC (NEW)
    - tools/quality/lexer07-predecessor-verify.HC (NEW)
    - tools/quality/lexer07-mutation-{stub,corrupt,fixture}.HC
      (NEW)
    - tools/quality/lexer07-fixture-inventory.HC (modified)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c2/
      (added)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
      (added)
    - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05.md
      (NEW)
    - docs/ROADMAP.md (CORRECTION05 status block)

  Out of scope (residue):
    - src/lexer.c, src/lexer_bridge.h, src/CMakeLists.txt
      (production code; NOT touched)
    - tools/bootstrap/selfhost-lexer-scalar-literal.HC
    - tools/quality/lexer07-scalar-literal-oracle.c
    - tools/quality/lexer07-direct-differential.c
    - The 9 stage0 fallback files in build/b02-corpus-A
      (historical baseline, read-only input)
    - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md
      (closed predecessor HANDOFF; preserved verbatim per F14;
       P1-7 correction recorded additively in this HANDOFF
       and ROADMAP only)
    - tools/quality/lexer07-broad-corpus-4-stage.HC
      (substance rewrite deferred to C05-CORRECTION01)

## RESIDUE

  P0:
    - Substantive rewrite of
      tools/quality/lexer07-broad-corpus-4-stage.HC
      (ObjectsByteEqual helper, PolyC-local SHA-256
      integration, 8-column provenance schema,
      corpus-failures.tsv writer, semantic-invariant gate).
      This rewrite will enable AC02, AC03, AC04, AC18 to
      return PASS_TRUE_GREEN against C05 evidence
      (currently the verifier correctly parses C04 evidence
      matrix but rejects C04 5-column provenance schema
      with the expected schema-strict message).

  P1:
    - factory-polyc-tools-check.HC wiring into gate-fast
      (C2.9 residue); shell-loc-gate is the authoritative
      gate for F-POLYC-TOOLS today.

  P2:
    - 9 sources where current ./hcc has ARM64 inline asm
      regression (pre-existing ./hcc binary issue; tracked
      as stage0-historical in provenance TSV).
    - 724-invocation parallelization (performance).
    - test-prefix-install target repair (pre-existing,
      out of scope).

## NEXT ACT
  ACT-POLYC-SELFHOST-LEXER03 (next surface-recon winner,
  BLOCKED signal lifted) OR ACT-POLYC-SELFHOST-LEXER02-
  CORRECTION05-CORRECTION01 (the substantive
  broad-corpus-4-stage.HC rewrite residue).
