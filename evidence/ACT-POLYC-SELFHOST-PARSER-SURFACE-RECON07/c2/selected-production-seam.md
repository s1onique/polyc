# SELECTED PRODUCTION SEAM

## WHERE THE DECISION LIVES NOW

```c
Ast *parseDefaultStatement(Cctrl *cc) {
    ...
    do {
        Ast *stmt = parseStatement(cc);
        if (stmt && stmt->kind != AST_CASE) {
            listAppend(stmts,stmt);
        }
        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
                || stmt->kind == AST_GOTO) break;              /* <-- THE DECISION */
        peek = cctrlTokenPeek(cc);
        if (tokenPunctIs(peek,'}')) break;
    } while (1);
    return cc->tmp_default_case;
}
```

## THE SEAM

The seam is the single `if (...) break;` at `src/parser.c:1683-1684`.

The successor ACT MUST NOT delegate the whole `parseDefaultStatement`
function, and MUST NOT delegate the whole `parseStatement` function.
It MUST delegate exactly this bounded condition, by the same
factoring pattern the repository already uses twice:

```c
static int parseDefaultArmTerminates(int kind) {
#ifdef HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES
    extern long long BootstrapDefaultArmTerminates(long long ast_kind);
    return (int)BootstrapDefaultArmTerminates((long long)kind);
#else
    if (kind == AST_COMPOUND_STMT || kind == AST_CASE || kind == AST_BREAK || kind == AST_RETURN
            || kind == AST_GOTO) return 1;
    return 0;
#endif
}
```

and the call site becomes:

```c
        if (parseDefaultArmTerminates((int)stmt->kind)) break;
```

**The legacy condition must NOT be evaluated before, after or
alongside the delegation.** There is no shadow call and no fallback to
C. This is the exact invariant that SLICE06 (SUB-001) and SLICE07
(SUB-003) already establish, and it is the invariant that the
`C_ON_DORMANT_BRANCH_INVARIANCE` control exists to protect.

## THE C SIDE RETAINS EVERYTHING

The delegated decision owns ONLY the comparison of one bounded
`AstKind` value against five constants. Everything else stays on the
C side of the seam:

* the `do { ... } while (1)` default-arm loop,
* the `parseStatement(cc)` call and the token cursor,
* the `listAppend(stmts, stmt)` host AST write,
* `cctrlTokenPeek(cc)` and `tokenPunctIs(peek, '}')`,
* `cc->tmp_default_case`, `cc->tmp_locals`, `cc->localenv`,
* `cctrlRaiseException` diagnostics,
* the recovery state.

## THE SELECTOR

A NEW, DEDICATED selector, following the repository's established
naming:

```text
HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES
```

It MUST be a dedicated macro, NOT the generic
`HCC_USE_SELFHOST_COMPONENTS`, because that generic selector also
activates the lexer delegations in `src/lexer.c`, which would require
linking the lexer subjects too. This migration is independent of the
lexer migrations and is scoped to its own flag. This is the same
reasoning SLICE06 and SLICE07 recorded.

The successor ACT MUST add the selector to `src/CMakeLists.txt` and
MUST wire the PolyC subject object into the `hcc` target with the
`-D<SELECTOR>_OBJECT`, `-D<SELECTOR>_PRODUCER`,
`-D<SELECTOR>_SOURCE` and `-D<SELECTOR>_PREFIX` arguments, exactly as
the seven existing authorities are wired.

## THE C-ON / C-OFF SEPARATION

The successor MUST provide a genuine **C-OFF** configuration in which
the selector is OFF and the legacy C body executes. This is what
makes the G0 oracle a real production object rather than a copy. The
existing CMake options already provide this pattern
(`-DHCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND=OFF`).

## THE AUTHORITATIVE MAIN CHECKOUT

This seam is described against the CURRENT tree. The successor MUST
re-derive the source range and its hash from its OWN entry tree and
MUST HALT if they differ. The range hash recorded here is a
**precondition**, not a constant to copy.
