# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SELECTED NEGATIVE CONTROLS

**Selected candidate:** `SUB-003`
**Source:** `src/parser.c:2049`

---

These are the controls the SUCCESSOR must implement, in addition to the
nineteen reconnaissance controls that this ACT already executed.  Each
one must fail for its INTENDED reason, and a pristine PASS is not a
passing control.

## N-01 — the component does not match the real C oracle

```text
MUTATION=Flip the component's AST_GVAR constant (256 -> 257).
DETECTOR=FIXTURE_SEMANTIC_MISMATCH
REASON=The real C oracle reads AST_GVAR = 256 from the live src/ast.h.
        A wrong constant changes the result on exactly the fixture row
        whose declvar_kind is 256.
```

## N-02 — the component range-checks its input

```text
MUTATION=Add an out-of-enum range check to the component.
DETECTOR=FIXTURE_SEMANTIC_MISMATCH
REASON=The legacy condition does NOT range-check.  An out-of-enum
        stmt_kind simply matches none of the constants and the
        statement is APPENDED.  A range check would change the result
        for the out-of-enum fixture rows.
```

## N-03 — the short-circuit is broken

```text
MUTATION=Always evaluate stmt->declvar->kind, even when stmt_kind is
          not AST_DECL.
DETECTOR=FIXTURE_SEMANTIC_MISMATCH or a CRASH at the seam
REASON=The legacy && short-circuits.  The ABI freezes the SAME
        short-circuit semantics (c2/selected-abi.md section 3.1).
```

## N-04 — the delegation is not load-bearing

```text
MUTATION=Leave the legacy C comparison in the delegated branch and
          ALSO call the component.
DETECTOR=FUNCTION_SCOPED_CODE_CLAIM_REJECTED
REASON=The production object's disassembly must show a PURE CALL for
        the wrapper, with no comparison of 263 or 256.  This is the
        same detector as CC-04.
```

## N-05 — the oracle is contaminated

```text
MUTATION=Build the legacy oracle from a source-extracted condition
          instead of from the REAL production translation unit, or
          link it against the PolyC component.
DETECTOR=ORACLE_PROVENANCE_VIOLATION
REASON=the G0 object must carry NO undefined reference to the
        proposed PolyC symbol.  See c2/selected-legacy-oracle.md.
```

## N-06 — the causal direction is not observed

```text
MUTATION=Mutate ONLY the selected C decision in a disposable
          worktree, rebuild the real compiler, and run the witness.
DETECTOR=CAUSAL_DIRECTION_CHANGE
REASON=The EXECUTED experiment in this ACT observed exactly this
        direction; see c2/selected-causal-contract.md section 3.
```

## N-07 — a fixture row is lost or duplicated

```text
MUTATION=Delete one fixture row, or emit it twice.
DETECTOR=FIXTURE_SEMANTIC_MISMATCH
REASON=The fixture coverage is checked by ID against the derived
        partition (c2/selected-fixture-contract.tsv).  A missing ID
        and a duplicated ID are both detected.
```

## N-08 — the fixture expects the wrong semantics

```text
MUTATION=Flip exactly one fixture row's expected outcome.
DETECTOR=FIXTURE_SEMANTIC_MISMATCH
REASON=The differential reports the exact affected semantic input ID
        and the reason.
```

## N-09 — the component is not total

```text
MUTATION=Introduce a "not found" sentinel into the component.
DETECTOR=FIXTURE_SEMANTIC_MISMATCH
REASON=The legacy condition is a BOOLEAN: every AstKind value is
        either in the terminating set or it is not.  There is NO
        "not found" case, so there is NO failure sentinel.
```

## N-10 — the seam is broadened

```text
MUTATION=Pass the host Ast POINTER to the component instead of the
          two copied scalars.
DETECTOR=ABI_CONTRACT_VIOLATION
REASON=The ABI freezes two bounded I64 inputs.  A host pointer would
        transfer the AST graph, which the ACT forbids (AC24).
```
