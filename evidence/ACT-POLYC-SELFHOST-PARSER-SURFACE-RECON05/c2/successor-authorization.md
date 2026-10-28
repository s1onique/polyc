# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SUCCESSOR AUTHORIZATION

**This is CONDITIONAL.** It authorizes NOTHING until the ACT's own C4
CLOSE has been executed and the external terminality check has
passed.

---

## 1. The single selected candidate

```text
SELECTED_CANDIDATE_ID=SUB-003
SELECTED_CLASS=STRUCTURAL_BOUNDARY
SELECTED_SOURCE_FILE=src/parser.c
SELECTED_SOURCE_RANGE=2049..2049
SELECTED_SOURCE_SHA256=378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8
SELECTED_ABI=I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind) -> I64
SELECTED_RANK=2
SELECTED_RANK_WITHIN_FEASIBLE_STRUCTURAL=1
```

## 2. The frozen successor contract

The successor inherits, UNCHANGED, from this ACT's C2 freeze:

```text
c2/selected-id-and-source.tsv
c2/selected-abi.md
c2/selected-production-seam.md
c2/selected-state-and-ownership.tsv
c2/selected-legacy-oracle.md
c2/selected-fixture-contract.tsv
c2/selected-red-contract.md
c2/selected-causal-contract.md
c2/selected-negative-controls.md
c2/selected-provenance-contract.md
c2/selected-conservation-contract.md
c2/selected-out-of-scope.md
```

## 3. The successor ACT name

```text
PROPOSED_NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE07
PROPOSED_NEXT_ACT_TARGET=SUB-003
PROPOSED_NEXT_ACT_STATUS=INACTIVE_UNTIL_TERMINALITY
```

The ACT name is PROVISIONAL.  It is recorded here so that a later ACT
can be opened under a stable name, and it is **not** an authorization
to execute.

## 4. The conditions

```text
CONDITION_1=This ACT's C3 must have demonstrated AC01..AC49.
CONDITION_2=Exactly ONE complete frozen selected-candidate contract
            must exist.  It does.
CONDITION_3=This ACT's C4 CLOSE must have been executed with valid
            Factory trailers.
CONDITION_4=The EXTERNAL post-CLOSE terminality check must have
            passed.
```

If ANY condition fails, the proposed successor remains **INACTIVE** and
is **NOT** authorized to execute.

## 5. What the successor must NOT do

```text
IT MUST NOT reopen the ranking to choose an easier target.
IT MUST NOT implement SUB-002, SUB-004 or any CAND-nnn candidate.
IT MUST NOT widen the boundary to the enclosing function.
IT MUST NOT transfer AST-graph mutation, allocation, recovery,
        callbacks, diagnostics, the token stream or the scope maps.
IT MUST NOT introduce a second PolyC authority for the SUB-001
        decision.
```

## 6. The authorization state at the time of writing

```text
AUTHORIZATION_STATE=CONDITIONAL_PENDING_C4_TERMINALITY
AUTHORIZED_TO_EXECUTE=NO
```

This document does not implement the successor and does not create it.
