# The Selected Successor Contract — Source Identity

**ACT:** ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
**Phase:** C2 IMPL
**Selected candidate:** `SUB-004`

---

## 1. The stable identity

| Field | Value |
|---|---|
| `CANDIDATE_ID` | `SUB-004` |
| `CLASS` | `STRUCTURAL` |
| `DECISION` | `STATEMENT_DISPATCH` |
| `FILE` | `src/parser.c` |
| `FUNCTION` | `parseStatement` |
| `LINE_RANGE` | `1864..1877` |
| `BYTE_RANGE` | the bytes of lines 1864..1877, inclusive of their trailing newlines |
| `SOURCE_SHA256` | `cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0` |
| `ENTRY_COMMIT` | `4e01dbac59f18223efc5d168d07d232c6c7f0c42` |
| `ENTRY_TREE` | `f72d358fe3b033c350cf9a7a841be5bb3333e56e` |
| `ENTRY_SRC_PARSER_C_SHA256` | `8e68487e1fd351cb888c5044cfb71871628d904dd089305d59138b2f017bee00` |
| `SEMANTIC_ANCHOR` | the `switch (tok->i64)` over the `KW_*` keyword enum, inside the `if (tok->tk_type == TK_KEYWORD)` guard, in `parseStatement` |

The range is **measured**, not inherited. It was verified by two
independent verifiers with different algorithms, and its digest is
recomputed from the live bytes by the RECON08 `ANCHOR` mode — a
capability the canonical checker and the RECON07 recomputer do not
have.

**A line number alone never identifies a semantic decision.** The
range carries a semantic anchor (the function name, checked against
the live function census by the `MISSING_FUNCTION` detector) and a
content digest.

---

## 2. The decision, verbatim

```c
    if (tok->tk_type == TK_KEYWORD) {
        switch (tok->i64) {
            case KW_IF:       return parseIfStatement(cc);
            case KW_FOR:      return parseForStatement(cc);
            case KW_WHILE:    return parseWhileStatement(cc);
            case KW_DO:       return parseDoWhileStatement(cc);
            case KW_RETURN:   return parseReturnStatement(cc);
            case KW_TRY:      return parseTryStatement(cc);
            case KW_THROW:    return parseThrowStatement(cc);
            case KW_SWITCH:   return parseSwitchStatement(cc);
            case KW_CASE:     return parseCaseLabel(cc,tok);
            case KW_DEFAULT:  return parseDefaultStatement(cc);
            case KW_BREAK:    return parseBreakStatement(cc);
            case KW_CONTINUE: return parseContinueStatement(cc);
            ...
```

The migration target is the **dispatch decision**, not the twelve
constructors. The decision reads one bounded token pair and selects
one bounded constructor. The constructors are the dispatch **targets**,
not calls made *by* the decision.

---

## 3. The witness identity

| Witness | Source | Pristine | Mutant |
|---|---|---|---|
| `w1` | an `if` with a block body | accepted; object `c5f0c938…` | accepted; object `e0e4ddc8…` (**different**) |
| `w2` | an `if` with a declaration body | rejected: *"while parsing **if** body"* | rejected: *"while parsing **while loop** body"* (**different**) |

`w2` is the discriminating witness: both compilers reject the same
source, but each names the constructor that actually ran, so the
observation is about the **decision's outcome**, not merely its
presence.

---

## 4. What is NOT selected

The selection is `SUB-004` because it was **rank 1 in a computed
order** and it **qualified**. It is not selected because it is the
next `SUB-` number, and it is not selected by assertion. Nine other
candidates are also eligible and qualified; they remain candidates for
a future ACT.
