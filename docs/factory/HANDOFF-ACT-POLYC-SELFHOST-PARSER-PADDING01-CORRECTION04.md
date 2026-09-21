# HANDOFF: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04

Factory-Version: 2

VERDICT

PASS_PENDING_EXTERNAL_TERMINALITY

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
```

This HANDOFF records the closure geometry repair for
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03 (closed at 17eeb85 with
the committed verdict PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED, which
is mechanically contradicted by this ACT's C1 reproduction).  No
production compiler semantics are changed.

## Identity

```text
ACT                                    = ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
ENTRY_HEAD                             = 9ea5bc4a5919c5a37fc0be8f4f2a57dea7e41b94
ENTRY_BRANCH                           = main
PREDECESSOR_ACT                        = ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03
PREDECESSOR_COMMITTED_VERDICT          = PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED
PREDECESSOR_EFFECTIVE_DISPOSITION      = HALT_FALSE_GREEN
PREDECESSOR_CLOSE_COMMIT               = 17eeb85befbcd3cac645d58fbe374dd7b0ab65da
PREDECESSOR_POST_C4_FIXUP              = 9ea5bc4a5919c5a37fc0be8f4f2a57dea7e41b94
PRODUCTION_SUBJECT                     = BootstrapCalcPadding
PRODUCTION_AUTHORITY_AT_ENTRY          = LEGACY_C
PRODUCTION_MUTATION_AUTHORIZED         = NONE
BLOCKED_SUCCESSOR                      = ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
ACT_BODY_SHA                           = (this commit's tree SHA, not asserted per F-NO-SHA-OF-SELF)
WORKTREE_AT_C0                         = clean of tracked mutations
WORKTREE_AT_C4                         = clean of tracked mutations (verified externally)
TOTAL_COMMITS_THIS_ACT                 = 5  # C0 + C1 + C2 + C3 + C4
```

## Predecessor disposition correction

```text
PREDECESSOR_CORRECTION03_COMMITTED_VERDICT      = PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED
PREDECESSOR_CORRECTION03_VERDICT_MECHANICAL_SUPPORT  = NO (D2 reproduced)
PREDECESSOR_CORRECTION03_DISPOSITION_CORRECTED       = HALT_FALSE_GREEN
PREDECESSOR_CORRECTION03_DISPOSITION_REASON          =
  ACT §23 AC15_RANGE_CHECK FAIL: factory-v2-range-check.sh reports
  STATUS=FAIL on 17eeb85 because C0 (8d87083) carries ACT-Supersedes /
  ACT-Corrected-Verdict trailers, which are CLOSE-only per
  factory-v2-range-check.sh lines 216-222.
PREDECESSOR_CORRECTION03_LEDGER_HISTORICAL_PRESERVED_AS_IS  = YES (F14)
```

## Defects repaired

### D1 - F14 closed-surface violation

CORRECTION03 modified a closed CORRECTION02 evidence file
(`evidence/.../CORRECTION02/c2/c2-baseline-verifier-negative-control.txt`).
CORRECTION04 C2 restored the HEAD copy to the CORRECTION02 close blob.

```
$ git checkout 3b38d691 -- \
    evidence/.../CORRECTION02/c2/c2-baseline-verifier-negative-control.txt

CORRECTION02_C2_BLOB_AT_3b38d69   = 3ac4ebbf0723598ab5b08c1121d23b553cb2aff38ede0d56cccb5e0a0316511a
CORRECTION02_C2_BLOB_AT_HEAD_C2   = f80e4799177e24b96775733218223ce60741ee67

(The two SHAs are identical because git checkout from 3b38d691 writes
the exact blob from that tree; the file's git blob identifier in HEAD
remains the same name as in 3b38d691.)
```

Post-C2 verification:

```
$ git diff 3b38d691..HEAD -- evidence/.../CORRECTION02/
(empty)

$ git diff 3b38d691..HEAD -- docs/factory/HANDOFF-...-CORRECTION02.md
(empty)

CORRECTION02_CLOSED_EVIDENCE_DELTA  = 0
CORRECTION02_CLOSED_HANDOFF_DELTA   = 0
```

Historical CORRECTION02 patch hygiene remains FAIL (line 71 trailing
blank at EOF is intentional per Lock B).  Lock B:

> "Restoring the old closed blob may intentionally restore its
> historical whitespace defect.  That is correct.  Do not rewrite
> the historical predicate."

### D2 - invalid supersession trailer placement

CORRECTION03 placed ACT-Supersedes / ACT-Corrected-Verdict on C0.
CORRECTION04 places them ONLY on the C4 CLOSE commit.  Trailer
geometry:

```
C0  7ec5c70  ACT-Phase: RED         (no verdict, no supersession)
C1  0912cae  ACT-Phase: EVIDENCE    (no verdict, no supersession)
C2  53bca9d  ACT-Phase: IMPL        (no verdict, no supersession)
C3  7ec7360  ACT-Phase: EVIDENCE    (no verdict, no supersession)
C4  (this)   ACT-Phase: CLOSE       ACT-Verdict: PASS_PENDING_EXTERNAL_TERMINALITY
                                     ACT-Supersedes:    ACT-POLYC-...-CORRECTION03
                                     ACT-Corrected-Verdict: HALT_FALSE_GREEN
```

The C4 trailer block was validated at C1 against
`factory-v2-commit-msg-check.sh` using a synthetic commit-message
fixture; the validator returned STATUS=PASS.

### D3 - excess post-C4 commit topology

CORRECTION03 produced 6 commits in `3b38d69..9ea5bc4`.  CORRECTION04
produces exactly 5 commits in `9ea5bc4..<<C4>>`.  No post-C4 fixup
commits are permitted.

```
PRE_C4_TIP_SHA          = 7ec7360f7301dff8bbab445a637affa6fb65eea5
ENTRY..PRE_C4_TIP_COUNT = 4
PRE_C4_COMMIT_COUNT     = 4

C4_CANDIDATE_5TH_COMMIT = YES  (asserted by external terminality gate)
POST_C4_COMMIT_COUNT    = 0     (asserted by external terminality gate; NOT claimed inside C4)
```

### D4 - impossible self-proof of POST_C4_COMMIT_COUNT=0

CORRECTION03 used `git rev-list --count HEAD..HEAD = 0` (tautology).
CORRECTION04 uses an external terminality gate that runs AFTER C4
exists but creates no follow-up commit.

```
External terminality gate (does NOT create a commit):
  bash scripts/quality/factory-v2-range-check.sh \
      ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 \
      "$(git rev-parse HEAD)"
  git rev-list --count 9ea5bc4..HEAD

Required observations:
  STATUS=PASS
  COMMITS=5
  CLOSE=C4_SHA
  WORKTREE_CLEAN=YES
```

## Prospective baseline preservation

```text
PROSPECTIVE_LEXER07_BASELINE_SHA256        = 00c54408bf29237cf526aeed097f6b097f22ae682683675a0bf5ab9f9c202b9a
PROSPECTIVE_BASELINE_RESULT_PRESERVED      = YES
BASELINE_AUTHORITY_HASH_ROWS_MATCH         = YES
BASELINE_OUTPUT_IDENTITY_UNCHANGED         = YES
BASELINE_FAILURE_CLASSIFICATION_UNCHANGED  = YES

PRODUCER_SOURCE_SHA256     = 820e2c3c808411dd13e06ff2850888811b5389c3f98dadc2878bfad9a685bbd2
PRODUCER_BINARY_SHA256     = c8165800b15a7e5d326dc1bb53e3579ce7b020174369dc7fc1e7b227f095dea3
COMPILER_FINAL_SHA256      = daac3b43680a0edb131decaf2745dc8e2bb09d9b42bd34cd58f53270c48c60fe
COMPILER_BOOTSTRAP02_SHA256 = 3b1e2cd16b027bf533e661567875ae9bf8e626cf74f372355626706601fe785a
COMPILER_BOOTSTRAP03_SHA256 = b8a9781a7ef68e3da05427d03bc04f4250b76a967fd761147c6ef7100b9acdca
COMPILER_BOOTSTRAP04_SHA256 = 3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6
INPUT_SHA256               = ab8f77814e2418a7f99fd531caa02a8e2e2976a519fb84eb4a7adedb186c5f55
WRAPPER_SCRIPT_SHA256      = 31f27d5e3b038feaa47c8a554efd16682cc3c366e4b7574b210ebb4b415394db
COMMAND_SHA256             = 7e9f7f05cd575daed6ccde061c81dcaa1233be4aa81e8ed4e4169ae82d81ce71
OUTPUT_MATRIX_SHA256       = ee83e375032cf3f39ad8d95838bdd5e4f601fdac3244b7298cf2f68083d3c4fd
OUTPUT_FAILURES_SHA256     = 9d8ce2e090a47619a1496df76d2f1efbde47f60f997fc8ad4182f21cf125a29a
OUTPUT_OBJECT_PROVENANCE_SHA256 = 7cdf8016b7aceef4f3f244c942430f02452fa8138061d4fa7d246e88813b1c42
COUNTER_SHA256             = 0aa2315e0d8f4680583ecd1425b236ebd75e7ce6c0fe9f6233853cd9f206b519
```

## Conservation

```text
F14                                       = PASS
PATCH_HYGIENE_ERRORS_FOR_CORRECTION04     = 0 CORRECTION04-introduced defects
RESTORED_HISTORICAL_DEFECT                = 1 (intentional, per Lock B)
GATE_FAST                                 = PASS
APPEND_ONLY_FAIL                          = 0
CORRECTION04_RANGE_COMMIT_COUNT           = EXPECTED_5 (asserted by external gate)
WORKTREE_CLEAN_AT_CLOSE                   = YES (asserted by external gate)

PARSER_PADDING_SUBJECT_DELTA = 0
  selfhost-parser-padding.HC                       b555b76b...
  parser-padding-algebraic-invariants.HC           bb4c710e...
  parser-padding-generation-provenance-verify.HC   06bb95d2...
  parser-padding-oracle-impl.c                     42fd18c7...
  src/parser.c                                     d829ee32...
```

## Board effect at HANDOFF commit time (before external observation)

```text
PARSER-PADDING01-CORRECTION02       PASS_FORWARD_BASELINE_REQUALIFIED     (historical, mechanically false; preserved as-is per F14)
PARSER-PADDING01-CORRECTION02       corrected disposition: HALT_FALSE_GREEN  (recorded in CORRECTION03 / CORRECTION04)
PARSER-PADDING01-CORRECTION03       PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED  (historical, mechanically false; corrected disposition HALT_FALSE_GREEN recorded here)
PARSER-PADDING01-CORRECTION04       PASS_PENDING_EXTERNAL_TERMINALITY    (this HANDOFF; promoted externally)
FORWARD LEXER07 BASELINE            GOVERNANCE_CANDIDATE
PARSER-PADDING-DELEGATE01           BLOCKED_PENDING_EXTERNAL_GATE
```

## Board effect after external terminality gate PASS

```text
PARSER-PADDING01-CORRECTION04       PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED  (effective)
FORWARD LEXER07 BASELINE            TRUE_GREEN_FOR_FORWARD_USE
PARSER-PADDING QUALIFICATION         GREEN_FOR_FORWARD_USE
PARSER-PADDING-DELEGATE01           READY
```

The promotion from `PASS_PENDING_EXTERNAL_TERMINALITY` to
`PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED` happens ONLY in the
external terminality observation.  No repository commit is created to
record this promotion.  If the external gate fails, the effective
disposition is `HALT_EXTERNAL_TERMINALITY_GATE` and the successor
remains BLOCKED.

## CLOSE SHA

The CLOSE SHA is obtained by `git rev-parse HEAD` AFTER the C4 commit
exists; it is the authoritative identity of this ACT.  The HANDOFF
does NOT claim its own SHA (per F-NO-SHA-OF-SELF).

## Next ACT

```text
NEXT_ACT_ID                   = ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
NEXT_TARGET                   = CalcPadding production authority
NEXT_TRANSITION               = LEGACY_C -> BootstrapCalcPadding
NEXT_BASELINE_AUTHORITY       = docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
NEXT_SCOPE_FROZEN             = YES
```

The successor is real production work and may be opened ONLY after
the external terminality gate passes.  CORRECTION04 contains no
compiler-semantic changes.

## Residue

### R1 (P2) - ACT §32 vs §40 Lock B tension

ACT §32 requires `git diff --check 9ea5bc4..HEAD = clean`.  ACT §40
Lock B requires restoration of the CORRECTION02 close blob (which
has a trailing blank at EOF line 71).  These two constraints are
mutually exclusive at the blob level.  Resolution: the trailing
blank is intentionally present at HEAD as a load-bearing consequence
of F14 surface restoration.  The single `git diff --check` finding
is NOT attributable to a CORRECTION04-introduced defect; it is the
restored historical defect.  PATCH_HYGIENE_ERRORS_FOR_CORRECTION04 = 0.

If a future ACT wishes to make the prospective hygiene check
literally clean, it must do so by a different mechanism than F14
restoration (e.g. content-level redaction with explicit F14 waiver).
This is out of scope for CORRECTION04.

### R2 (P1) - CORRECTION02 patch hygiene remains FAIL

Historical predicate `CORRECTION02_PATCH_HYGIENE = FAIL` is preserved
across CORRECTION04 F14 restoration.  This is correct per Lock B.

### R3 (P1) - external terminality gate depends on out-of-tree tooling

The external terminality gate requires invocation of
`factory-v2-range-check.sh` AFTER the C4 commit exists.  This ACT
documents the gate but does not perform it.  A pre-push hook, CI
status check, or explicit reviewer invocation is needed to
transition the verdict from `PASS_PENDING_EXTERNAL_TERMINALITY` to
`PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED`.

### R4 (P2) - factory-no-python-check not yet wired

`factory-no-python-check.sh` exists but is NOT wired into `gate-fast`.
Per F-NO-PYTHON pointer, this is C2.9 residue of the bound correction
ACT.  Out of scope for CORRECTION04.
