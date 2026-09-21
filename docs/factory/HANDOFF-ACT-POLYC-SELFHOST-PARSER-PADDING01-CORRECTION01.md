# HANDOFF: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01

Factory-Version: 2

VERDICT

OPEN

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01
```

This hand-off documents the **FALSE_GREEN** finding at the closure
ledger of ACT-POLYC-SELFHOST-PARSER-PADDING01 (closed at `81afe8b`)
and the bounded proof-repair scope of this correction ACT.

## Verdicts disposition

PARSER-PADDING01 closed with `PASS_TRUE_GREEN` at `81afe8b`.
Independent factory-causal review against the committed C3 evidence
(not the summary) found three binding closure defects and one P1
contract drift. The implementation itself is sound; the closure ledger
over-claims.

### Defect ledger (recorded, not yet repaired)

```text
P0-1  AC29 GENERATION_COPY_CONTROL = FAIL
      c3/c3-generation-copy-control.txt itself records
      PARSER_PADDING_NEGATIVE_CONTROL=FAIL reason=verifier-accepted-mutation.
      The byte-equality verifier CANNOT reject a byte-identical
      forgery. The control was satisfied only by writing a
      contradictory PASS into c3/mandatory-ac-status.tsv.

P0-2  AC18 ALGEBRAIC_INVARIANT = NOT_PROVEN_AS_AUTHORIZED
      C3-S48 forbade "invariants proven by simple equality with the
      C result". The committed witness
      ("16640/16640 oracle-equal -> invariants by construction")
      is exactly that.

P0-3  AC35..AC39 LEXER_CONSERVATION = NOT_EXECUTED_AS_AUTHORIZED
      C3-S57 / C3-S58 required "run canonical current conservation"
      and a lexer07 baseline comparison. The committed evidence
      rests the entire argument on a git-diff being empty
      ("by-construction"), then declares PASS without running the
      corpus.

P1    ORACLE_AUTHORITY_CONTRACT = CONTRACT_DRIFT
      C3-S31 forbade a second independent expected-value algorithm
      and required the oracle to call or expose the actual legacy
      CalcPadding. The committed oracle contains a verbatim copy of
      the legacy body, with the type widened from int to I64.
```


### What remains genuinely green (reviewer-confirmed)

```text
BOOTSTRAP_CALC_PADDING_IMPLEMENTATION   = GREEN
DIRECT_DIFFERENTIAL                    = GREEN
BOUNDED_MATRIX                         = GREEN
CAUSAL_MUTATIONS_M1_M4                 = GREEN
4GEN_OBJECT_FIXEDPOINT                 = GREEN
PRODUCTION_AUTHORITY_PRESERVED         = GREEN
PARSER_LAYOUT_CONSERVATION             = GREEN
PATCH_HYGIENE                          = GREEN
EXACT_5_COMMIT_TOPOLOGY                = GREEN
```

These are not in dispute.

## Identity

```text
ENTRY_HEAD                  = 81afe8b102fba7300daed90c609f5bec38accbfc
ENTRY_BRANCH                = main
PREDECESSOR_ACT             = ACT-POLYC-SELFHOST-PARSER-PADDING01
PREDECESSOR_VERDICT_AT_CLOSE= PASS_TRUE_GREEN
PREDECESSOR_CLOSE_COMMIT    = 81afe8b102fba7300daed90c609f5bec38accbfc
PREDECESSOR_ENTRY_HEAD      = b2d750b713fc64c41db89b5adf418ddaa777944c
ACT_BODY_SHA                = (this commit's tree SHA, not asserted)
WORKTREE_AT_OPEN            = clean of pre-existing tracked files
```

## Red

Reproduced all three P0 defects and the P1 drift against the actual
committed evidence of the predecessor ACT. The defect ledger above
is anchored to specific files and lines that are immutable under the
append-only invariant. This ACT does not produce new REDs; it
documents existing REDs that were discharged by the predecessor ACT
without authorization.

## Implementation

Not yet. This ACT is at the C0 boundary. C1 RED, C2 IMPL, C3 VERIFY,
C4 CLOSE phases remain.

## Gates

```text
BUILD          = (deferred to C3)
TARGETED       = (deferred to C3)
UNIT           = (deferred to C3)
JIT            = N/A
LSP            = N/A
DIFF_CHECK     = (deferred to C4)
gate-fast      = PASS (verified at this commit)
append-only    = PASS (verified at this commit)
```

## Scope

```text
FILES_CHANGED                = docs/acts/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01.md (NEW),
                              docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01.md (NEW),
                              docs/factory/act-handoff-map.tsv (APPEND ONLY),
                              evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01/ (NEW)
DIFF_CHECK                   = clean (this commit)
PRODUCTION_SEMANTICS_CHANGED = NO
LLVM_CHANGED                 = NO
ABI_REPAIR_CHANGED           = NO
```

## Residue

```text
P0 = AC18, AC29, AC35..AC39, oracle-authority drift  (in scope, this ACT)
P1 = (none yet)
P2 = AC49 / AC50 deferred-to-C4 status inherited from predecessor
        (re-observationally satisfied; recorded here as residue)
```

## Next ACT

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01-C1 (C1 RED)
  Reproduce the four defects against THIS ACT's entry head.

Subsequent phases (C2 IMPL, C3 VERIFY, C4 CLOSE) of THIS ACT.

ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
  (Only after THIS ACT closes with TRUE_GREEN.)
```
