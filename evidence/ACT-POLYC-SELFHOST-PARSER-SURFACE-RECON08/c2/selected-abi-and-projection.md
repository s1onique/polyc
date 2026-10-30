# The Selected Successor Contract — ABI and Projection

**ACT:** ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
**Selected candidate:** `SUB-004`

---

## 1. The single exact PolyC ABI

The successor component is a **pure scalar classifier**. Its ABI is
exactly:

```polyc
I64 BootstrapStatementDispatch(I64 token_type, I64 keyword_id);
```

| Parameter | Width | Signedness | Source | Meaning |
|---|---|---|---|---|
| `token_type` | `I64` | signed | `tok->tk_type` | the lexer's token class; the decision needs only whether it is `TK_KEYWORD` |
| `keyword_id` | `I64` | signed | `tok->i64` | the keyword enum value, meaningful only when `token_type == TK_KEYWORD` |
| return | `I64` | signed | — | the **statement-constructor selector**, a bounded enum value |

`TK_KEYWORD` is `0x332` (`src/lexer.h:62`). The `KW_*` values are the
dense keyword enum in `src/lexer.h`.

The ABI is **total**: every `(token_type, keyword_id)` pair maps to a
value. There is no failure sentinel and no error return. The mapping
is a pure function of its two inputs.

---

## 2. The projection from the C host fields

The C side keeps every host read it has today:

```c
    if (tok->tk_type == TK_KEYWORD) {
        switch (tok->i64) {
            case KW_IF:       return parseIfStatement(cc);
            ...
```

becomes, in the shape the three already-migrated decisions use:

```c
    if (tok->tk_type == TK_KEYWORD) {
        int sel = (int)BootstrapStatementDispatch((long long)tok->tk_type,
                                                  (long long)tok->i64);
        switch (sel) {
            case STMT_IF:       return parseIfStatement(cc);
            ...
        }
    }
```

**Conditional reads are preserved exactly.** `tok->i64` is read only
when `tok->tk_type == TK_KEYWORD`, exactly as the original source
does. The `TK_KEYWORD` test itself stays on the C side: it is the
guard, not the decision.

**Null guards are preserved.** `parseStatement` already raises on
`tok == NULL` *before* the dispatch; the successor is never reached
with a null token.

---

## 3. Ownership: everything stays on the C side

| Thing | Owner after the migration |
|---|---|
| the token (`Lexeme *`) | **C** — never crosses the seam |
| the token cursor | **C** |
| the `Cctrl *` and its mutable symbol table | **C** |
| the host AST construction | **C** — each constructor builds its own `Ast` |
| the statement constructors themselves | **C** — the decision selects them, it does not call them |
| the recovery state (`cc->current_recovery`) | **C** |
| the diagnostics | **C** |
| the allocation of every `Ast` node | **C** |
| the `KW_*` and `TK_*` enum values | **C** — passed by value |

**No pointer crosses the seam.** The ABI is two `I64`s in and one
`I64` out. There is no callback, no recovery interaction, no AST
ownership transfer, no allocation, and no unbounded host string.

This is exactly the shape of the three already-migrated decisions:
`parseSwitchArmTerminates(int kind)`,
`parseCompoundBlockAppendsStatement(int,int)` and
`parseDefaultArmTerminates(int kind)` are pure scalar functions whose
call sites retain every host ownership.

---

## 4. The selector, the enum and the object policy

| Item | Value |
|---|---|
| Selector name | `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH` |
| Selector default | `OFF` — an ACT that flips a production selector is a separate, bounded ACT |
| Subject file | `tools/bootstrap/selfhost-parser-statement-dispatch.HC` |
| Producer object | a new `tools/bootstrap/selfhost-parser-statement-dispatch.o` linked into `hcc` |
| Legacy oracle | the legacy switch body survives as a `ParserLegacyStatementDispatchOracle`, reachable only in a selector-OFF build |
| Fail-closed posture | the C side must **not** fall back to the legacy switch when the selector is ON |

The dedicated selector name (rather than the generic
`HCC_USE_SELFHOST_COMPONENTS`) is required, for the same reason the
three existing migrations each have their own: the generic selector
also activates the lexer delegations, which would require linking the
lexer subjects too.

---

## 5. The bound on the successor's own size

The successor decides among the statement constructors. The exact set
of arms is fixed by the frozen source range
`src/parser.c 1864..1877`, whose digest is
`cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0`.
**Any change to that range invalidates this contract** and requires a
new source-bound verification.

The number of arms is bounded by the `KW_*` enum. The successor is
total over the whole `I64` domain: a `keyword_id` that is not a
keyword maps to the "not a keyword statement" selector, and the C
side's `TK_KEYWORD` guard means that selector is unreachable in
production. It is nevertheless **defined**, so the component has no
undefined behaviour on any input.
