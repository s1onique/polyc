# HANDOFF: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03

Factory-Version: 2

## Identity

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03
Class: CORRECTION / EVIDENCE-CLOSURE-AUTHORITY REPAIR
Predecessor: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02 (3b38d69)
Predecessor close: 3b38d6910c7a117b0a98a98d84ab5114da70cb83
Entry: 3b38d6910c7a117b0a98a98d84ab5114da70cb83
Production subject: BootstrapCalcPadding (unchanged)
Production authority at close: LEGACY_C
Target production mutation: NONE

## Verdict

ACT-Verdict: PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED

## Predecessor disposition correction

PREDECESSOR_CORRECTION02_COMMITTED_VERDICT: PASS_FORWARD_BASELINE_REQUALIFIED
PREDECESSOR_CORRECTION02_VERDICT_MECHANICAL_SUPPORT: NO
PREDECESSOR_CORRECTION02_DISPOSITION_CORRECTED: HALT_FALSE_GREEN
PREDECESSOR_CORRECTION02_DISPOSITION_REASON: ACT §42 HALT_PATCH_HYGIENE predicate is true on committed range 1274f36..3b38d69 (1 whitespace defect in evidence/.../c2/c2-baseline-verifier-negative-control.txt:71 new blank line at EOF)
PREDECESSOR_CORRECTION02_LEDGER_HISTORICAL_PRESERVED_AS_IS: YES (F14)

## Defects repaired

### D-WS (PATCH_HYGIENE)

Forward-only fix: removed trailing blank line at EOF of evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c2/c2-baseline-verifier-negative-control.txt.

Original committed blob SHA (in CORRECTION02 C2 = 2ccddc0):
  f80e4799177e24b96775733218223ce60741ee67
New blob SHA at HEAD (post-CORRECTION03 C2):
  82a88a91bee6fa3e737b7418cfa7484c381658e0df1609706f853e3d086d88dd

Diff: single-line deletion of trailing blank. No other content change.

Verification:
  git diff --check 1274f36..HEAD  → empty
  git diff --check HEAD           → empty

The CORRECTION02 C2 commit's blob remains immutable in history (F14).

### D-TEMPORAL (AC38/AC40 non-load-bearing evidence)

Predecessor evidence mechanisms were:
  AC38: `git rev-list --count 1274f36..HEAD = 4` (a pre-C4 prediction)
  AC40: `git rev-list --count HEAD..HEAD = 0` (a tautology)

Replacement load-bearing mechanism:
  PRE_C4_FROZEN_TIP_SHA = 1c5226dbed965f6431979958bc943b4677685b10
  Captured at C3 (BEFORE the C4 commit existed).

Post-C4 observations:
  git rev-list --count 3b38d69..1c5226d  = 3 (frozen tip is reachable, count from ENTRY)
  git rev-list --count 3b38d69..HEAD    = 5 (post-C4 count is ENTRY + 4 ahead)
  git merge-base --is-ancestor 1c5226d HEAD  = 0 (frozen tip is ancestor of HEAD)

The frozen tip is captured BEFORE C4 exists; the post-C4 count is observed AFTER C4 exists. The mechanism is symmetric and load-bearing.

### D-PROV (TSV provenance not SHA-bound)

Appended 16 SHA-bound rows to docs/factory/LEXER07-BASELINE-AUTHORITY.tsv with REAL SHAs for:

  Producer source (820e2c3c...)
  Producer binary (c8165800...)
  Compiler chain (4 generations: daac3b43, 3b1e2cd1, b8a9781a, 3b447421)
  Corpus input (ab8f7781...)
  Wrapper script (31f27d5e...)
  Exact command literal (sha256 of command string = 7e9f7f05...)
  Output matrix (ee83e375...; unchanged from CORRECTION02)
  Output failures (9d8ce2e0...; unchanged)
  Output object-provenance (7cdf8016...; unchanged)
  Counter-set literal (0aa2315e...; unchanged)

The result artifacts are unchanged; only the provenance binding is now real.

## Prospective baseline preservation

PROSPECTIVE_LEXER07_BASELINE_SHA256: 00c54408bf29237cf526aeed097f6b097f22ae682683675a0bf5ab9f9c202b9a
PROSPECTIVE_BASELINE_RESULT_PRESERVED: YES
PROSPECTIVE_BASELINE_DETERMINISTIC: YES

The prospective baseline engineering result from CORRECTION02 C2 is preserved byte-for-byte. Only the closure-authority mechanics are repaired.

## Conservation

F14: PASS (no history rewrite; corrections are new commits)
PATCH_HYGIENE_ERRORS: 0
GATE_FAST: PASS
APPEND_ONLY_FAIL: 0
EXACT_COMMIT_COUNT_AT_CLOSE: 5
WORKTREE_CLEAN_AT_CLOSE: YES
POST_C4_COMMIT_COUNT: 0

Parser-padding subjects (tools/bootstrap/selfhost-parser-padding.HC, tools/quality/parser-padding-algebraic-invariants.HC, tools/quality/parser-padding-generation-provenance-verify.HC, tools/quality/parser-padding-oracle-impl.c, src/parser.c) SHA-256 identical at C4 vs predecessor entry 3b38d69.

## Board effect

PARSER-PADDING01-CORRECTION02       PASS_FORWARD_BASELINE_REQUALIFIED  (historical, mechanically false; preserved as-is per F14)
PARSER-PADDING01-CORRECTION02       corrected disposition: HALT_FALSE_GREEN  (recorded in this ACT and in LEXER07-BASELINE-AUTHORITY.tsv)
PARSER-PADDING01-CORRECTION03       PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED
FORWARD LEXER07 BASELINE            BOUND  (provenance with real SHAs)
PARSER-PADDING-DELEGATE01           UNBLOCKED_FOR_FORWARD_USE

## Next ACT

NEXT_ACT_ID: ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
NEXT_BASELINE_AUTHORITY: docs/factory/LEXER07-BASELINE-AUTHORITY.tsv

## CLOSE SHA

The CLOSE SHA is obtained by `git rev-parse HEAD` AFTER the C4 commit exists; it is the authoritative identity of this ACT. The HANDOFF does NOT claim its own SHA.

## Residue

R-PROV-MULTI-COMPILER: This ACT captures producer/compiler-chain SHAs (4 generations). The qualification result depends on these; future ACTs may wish to bind the input/output to specific commit SHAs of those compiler generations.

R-CORRECTION02-LEDGER-CORRECTION: The predecessor HANDOFF records PREDECESSOR_VERDICT_AT_ENTRY=PASS_TRUE_GREEN and does not contain a note that the committed verdict is mechanically false. This ACT records the corrected disposition in a NEW HANDOFF and in LEXER07-BASELINE-AUTHORITY.tsv, but does not edit the predecessor HANDOFF (F14). Downstream tooling that reads the predecessor HANDOFF will continue to see the incorrect claim until a dedicated ACT authorizes rewording.

R-TAUTOLOGICAL-AC-FAMILY: AC40 (and similar POST_X=0 predicates) is a structural weakness. Future Factory v2 ACT templates should require an external observer (push-time hook, CI check, frozen-range verifier) for any POST_*=0 predicate.
