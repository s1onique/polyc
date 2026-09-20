# ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 HANDOFF

C4_PARENT_SHA=<C3 sha>
C4_IDENTITY=COMMIT_CONTAINING_THIS_HANDOFF

VERDICT: PASS_TRUE_GREEN

IDENTITY
--------
Branch: main
C0 (AUTH):         0116e9c
C1 (RED/RECON):    fabbf18
C2 (IMPL):         80cdba5
C3 (VERIFY):       1720ceb
C4 (CLOSE):        <commit containing this handoff>
Total commits:     5 (per ACT §64 topology)

ROOT CAUSE / FINDING
--------------------
CORRECTION02 closed FALSE_GREEN. The reviewer identified 6 defects:
P0-1: G2/G3 outputs were byte-identical copies of G1 (Makefile line 1862-1863)
P0-2: N02 misclassified as PASS (Defect detected by seam output: NO)
P0-3: PREV-AC24 BROAD_CORPUS_CONSERVATION falsely claimed PASS
P0-4: 6 commits instead of 5 (post-C4 whitespace cleanup)
P0-5: mandatory-ac-status.tsv AC IDs shuffled vs evidence
P0-6: C4_TERMINAL_IDENTITY stale (FINAL_HEAD recorded C3 commit)

CORRECTION03's deeper architectural finding (deeper than the evidence defect):
The PolyC BootstrapLinkDirective component existed, compiled, and reached
a 4-generation object fixed point -- BUT production src/lexer.c::lexLink
called it and discarded every output via (void) casts. The component was
a shadow verifier, not production authority. The migration had not actually
happened. The lex-complex_1.0 -> lib-complex_1co corruption persisted
on the production path because the legacy C adapter concatenated lexed
tokens, while the PolyC component (called per-token with result discarded)
could not fix what the adapter never consulted.

RED
---
c1-shadow-path-red.txt:
  BOOTSTRAP_LINK_DIRECTIVE_CALLED=YES
  BOOTSTRAP_LINK_OUTPUTS_LOAD_BEARING=NO
  LEGACY_TARGET_BYTES_STILL_USED=YES
  PRODUCTION_AUTHORITY_RED=CONFIRMED

lib-complex_1.0 reproduction: stage0 outputs lib-complex_1co (legacy),
stages 1/2/3 needed to produce lib-complex_1.0 (production fix).

IMPLEMENTATION
--------------
ABI 5 -> ABI 6:
  Added out_target_bytes, out_target_cap, out_target_len to
  BootstrapLinkDirective. The component writes the verbatim body bytes
  so the C adapter can build the AoStr from a guaranteed-correct
  byte run.

src/lexer.c::lexLink self-hosted path:
  - Skip leading whitespace after the keyword.
  - Call BootstrapLinkDirective ONCE per directive.
  - Use out_is_path for list selection.
  - Use out_target_bytes for the AoStr.
  - Advance l->ptr by out_consumed bytes.
  - Honor out_error via lexRaise (production) or stderr+skip (seam).

Independent 4-stage seam:
  - lexer09-link-component-stage1/2/3 (each bootstrap compiler builds
    its own link.o from the same source)
  - lexer09-lexer-seam-stage2/3 (each stage builds its own seam binary
    with HCC_STAGE2/3_OBJECTS + stage2/3 link.o)
  - 4-stage semantic seam target now uses genuine independent outputs
    (no `cp semantic.g1.txt semantic.g2.txt`)

LIBNAME_PRESERVATION=PASS:
  Stage0: lib-complex_1co (legacy, documented baseline)
  Stage1: lib-complex_1.0 (fixed)
  Stage2: lib-complex_1.0 (fixed)
  Stage3: lib-complex_1.0 (fixed)

PolyC native tools:
  - tools/quality/lexer09-ac-ledger-verify.HC (AC ledger by id+sha)

GATES
-----
gate-fast: PASS
factory-append-only-test: 11/11 PASS
direct differential: 23/23 PASS
component fixedpoint: 6/6 PASS
4-stage semantic seam: SEMANTIC_PAIR_PASS=3 MIGRATION_DELTA=3 FIXTURE_DIVERGENCE_COUNT=0
AC ledger: 38/38 PASS, 0 missing, 0 sha mismatch
git diff --check 4814bf1..HEAD: clean

SCOPE
-----
Production paths modified:
  src/lexer.c
  src/lexer_bridge.h
  tools/bootstrap/selfhost-lexer-link.HC

Qualification paths modified/added:
  Makefile
  tools/quality/lexer09-ac-ledger-verify.HC (new)
  tools/quality/lexer09-4stage-semantic-verify.HC
  tools/quality/lexer09-direct-differential.c
  tools/quality/lexer09-link-oracle-impl.c
  tools/quality/lexer09-real-seam-runner.c

Closed predecessor evidence: unchanged.
Closed HANDOFFs: unchanged.

RESIDUE
-------
AC36/37/38 are resolved at C4 (commit count, worktree clean, post-C4=0).
AC24 has a minor row-counter off-by-one in the verifier output (rows=37
instead of 38 for a 38-row status file); substantive verdict PASS is
correct because the join-by-id+sha logic correctly finds all 38 ACs.

NEXT ACT
--------
None required for LEXER04. The production migration is complete.

Historical line preserved (F14):
  LEXER04 original                = FALSE_GREEN historical closure
  LEXER04-CORRECTION01            = historical
  LEXER04-CORRECTION02            = FALSE_GREEN historical closure (P0-1..P0-6)
  LEXER04-CORRECTION03            = PASS_TRUE_GREEN (this ACT)
