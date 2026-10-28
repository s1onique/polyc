# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SELECTED ABI

**Selected candidate:** `SUB-003`
**Source:** `src/parser.c:2049`
**SHA-256 of the source range:** `378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8`

---

## 1. The decision

The live decision, at `src/parser.c:2049`, inside
`parseCompoundStatementInternal`:

```c
if (stmt->kind == AST_DECL && stmt->declvar->kind == AST_GVAR) {
    tok = cctrlTokenPeek(cc);
    continue;
}
listAppend(body->stms,stmt);
```

It answers one question: **is the statement just parsed a
global-variable declaration?** If yes, the statement is **SKIPPED**
(it is not appended to the block's statement list). If no, it is
**APPENDED**.

## 2. The frozen PolyC ABI

```text
I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind) -> I64;
```

| Parameter        | Type | Domain                                                        |
|------------------|------|---------------------------------------------------------------|
| `stmt_kind`      | I64  | the numeric `AstKind` of the parsed statement                |
| `declvar_kind`   | I64  | the numeric `AstKind` of `stmt->declvar`                      |

| Result | Meaning                                                            |
|--------|--------------------------------------------------------------------|
| `1`    | APPEND the statement to the block statement list (the C side acts) |
| `0`    | SKIP the statement (the C side acts)                               |

## 3. Exactness of the projection

The projection is **copy-only, bounded, deterministic and unaliased**:

- `stmt->kind` is read from the host AST node and **copied out** as an
  `int` before the call. The PolyC component never sees a host pointer.
- `stmt->declvar->kind` is read the same way.
- The component reads **no** host state: no symbol table, no scope map,
  no token stream, no recovery point, no host AST graph.
- The component performs **no** allocation, **no** callback and **no**
  I/O.
- The component is **TOTAL** over the whole `I64` domain: every pair of
  inputs maps to exactly one of `{0, 1}`. There is **no failure
  sentinel** and **no error return**.

### 3.1 The `declvar_kind` null question

The live code reads `stmt->declvar->kind` **only** when
`stmt->kind == AST_DECL` is already true, because `&&` short-circuits.
The projection MUST preserve that short-circuit. The frozen ABI is
therefore defined with the SAME short-circuit semantics:

```text
if (stmt_kind == AST_DECL && declvar_kind == AST_GVAR) return 0;  /* SKIP */
return 1;                                                        /* APPEND */
```

The component never dereferences `declvar`; the C side evaluates
`stmt->declvar->kind` **only** in the `stmt_kind == AST_DECL` case and
passes the resulting scalar. When `stmt_kind != AST_DECL` the C side
passes a value that is **not consulted**, and the component's
short-circuit ignores it. This keeps the ABI total without inventing a
null case.

## 4. The enum values

The two `AstKind` values are compared by the live source against
`AST_DECL` and `AST_GVAR`. Their **numeric** values are bound from the
live `src/ast.h` by **compiling** it, and are recorded in
`c2/selected-fixture-contract.tsv`. The PolyC component cannot include
the legacy C header, so the constants are written as their NUMERIC
values, exactly as the six already-migrated components do.

## 5. The cast chain

The legacy C decision is `int`. The PolyC ABI is `I64 -> I64`.

```text
(int stmt->kind)  ->  (I64 stmt_kind)
(int stmt->declvar->kind)  ->  (I64 declvar_kind)
(I64 result)  ->  (int append)
```

The cast chain is **exact**: the `AstKind` values are small
non-negative integers and the result is a boolean, all of which fit in
an `int` without loss.

## 6. What the ABI does NOT transfer

| Concern                                   | Owner after the migration |
|-------------------------------------------|---------------------------|
| The host AST graph and its list structure  | **C**                     |
| The `body->stms` list mutation             | **C**                     |
| The token stream                           | **C**                     |
| The scope / symbol tables                  | **C**                     |
| The recovery point (`cc->current_recovery`)| **C**                     |
| The diagnostics                            | **C**                     |
| The allocation                             | **C**                     |
| The `continue` / `listAppend` ACTIONS      | **C**                     |

The PolyC component **decides**; the C side **acts**.
