# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — what REMAINS OUT OF SCOPE

**Selected candidate:** `SUB-003`

---

## 1. What the SUCCESSOR does NOT implement

The successor implements exactly ONE decision:

```text
THE COMPOUND-BLOCK STATEMENT APPEND/SKIP ROUTING
  at src/parser.c:2049
```

It does **NOT** implement, port, rewrite or enable:

```text
parseStatement                (the whole statement parser)
parseExpr                     (the whole expression loop)
parseCompoundStatementInternal (the whole compound-block builder)
parseCompoundStatement         (its wrapper)
the AST graph or any AST node construction
the token stream or its ownership
the scope / symbol tables
the recovery point and the setjmp protocol
the diagnostics
the list structures
any allocation
```

## 2. What stays in C

Every mutable-state authority stays on the C side of the seam:

| Authority | Owner |
|---|---|
| the host AST graph and `body->stms` | **C** |
| the `listAppend` that appends the statement | **C** |
| the `continue` that implements the SKIP | **C** |
| the token cursor (`cctrlTokenPeek`) | **C** |
| the block scope map (`cc->localenv`) | **C** |
| the recovery point (`cc->current_recovery`) and the `setjmp` | **C** |
| the diagnostics | **C** |
| every allocation | **C** |
| the `parseStatement` dispatch | **C** |
| the `parseDecl` / `parseStatement` routing of SUB-005 | **C** |

## 3. The candidates that are NOT selected

```text
SUB-002	DISQUALIFIED by EXECUTED causal evidence: its decision is
                SEMANTICALLY IDENTICAL to the already-migrated SUB-001
                decision.  It is NOT a distinct decision.
SUB-004	FEASIBLE but ranks BELOW SUB-003 on the canonical ranking.
                It is the RUNNER-UP.
CAND-018	ELIGIBLE SCALAR, not selected: the canonical policy selects
                from the STRUCTURAL class first.
CAND-021	ELIGIBLE SCALAR, not selected; DIAGNOSTICS-ONLY.
CAND-022	ELIGIBLE SCALAR, not selected; DIAGNOSTICS-ONLY.
CAND-023	ELIGIBLE SCALAR, not selected; DIAGNOSTICS-ONLY.
CAND-025	ELIGIBLE SCALAR, not selected.
CAND-026	ELIGIBLE SCALAR, not selected.
CAND-030	ELIGIBLE SCALAR, not selected.
CAND-036	ELIGIBLE SCALAR, not selected.
CAND-037	ELIGIBLE SCALAR, not selected.
CAND-038	ELIGIBLE SCALAR, not selected; HOST STRING boundary.
CAND-039	ELIGIBLE SCALAR, not selected; HOST STRING boundary.
CAND-040	ELIGIBLE SCALAR, not selected; DIAGNOSTICS-ONLY.
SUB-005	INELIGIBLE: mutable symbol-table dependence CONFIRMED live.
SUB-006	INELIGIBLE: owns the setjmp and the AST-list rollback.
SUB-007	INELIGIBLE: the compound body loop owns the host graph.
SUB-008	INELIGIBLE: the whole statement parser.
SUB-009	INELIGIBLE: the whole expression loop.
SUB-010	INELIGIBLE: a recursive control-flow walk.
SUB-011	INELIGIBLE: a recursive control-flow walk.
SUB-012	INELIGIBLE: a three-hop host pointer chain.
SUB-001	ALREADY SELF-HOSTED by the PolyC component
                BootstrapSwitchArmTerminates.
```

**No other candidate is authorized by implication.** The successor
contract is SINGLE-VALUED.

## 4. What this ACT itself did NOT do

```text
IT DID NOT introduce a seventh PolyC parser authority.
IT DID NOT modify any file under src/**.
IT DID NOT modify any file under tools/bootstrap/**.
IT DID NOT modify the canonical checker or the canonical ranker.
IT DID NOT modify any historical ACT, HANDOFF or evidence tree.
IT DID NOT merge or commit any worktree mutation.
IT DID NOT create the successor ACT.
```

The production semantic delta of this ACT is ZERO.
