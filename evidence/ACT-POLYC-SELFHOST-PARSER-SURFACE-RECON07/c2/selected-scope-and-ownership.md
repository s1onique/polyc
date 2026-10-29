# SELECTED SCOPE AND OWNERSHIP

## THE FILES THE SUCCESSOR IS AUTHORIZED TO TOUCH

```text
tools/bootstrap/<the successor's SUB-002 component>.HC     # NEW
src/parser.c                                              # the seam ONLY
src/CMakeLists.txt                                        # the selector and the wiring
Makefile                                                  # the build targets
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/**              # its own evidence
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE08.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
```

## THE FILES THE SUCCESSOR MUST NOT TOUCH

```text
src/ast.c
src/prslib.c
src/prsutil.c
src/cctrl.c
src/lexer.c
src/transpiler.c
src/ir.c
src/x86.c
any OTHER tools/quality/** file
any OTHER tools/bootstrap/** file
any historical evidence/ directory
any closed ACT or HANDOFF document
.githooks/**
scripts/quality/**            (except ADDITIVE new files)
```

The successor's change to `src/parser.c` MUST be limited to:

1. factoring the condition at lines 1683-1684 into the named helper,
2. adding the `#ifdef`-guarded PolyC delegation arm to that helper,
3. adding the object-level oracle wrapper adjacent to it, and
4. changing the ONE call site to call the helper.

It MUST NOT change the `do { ... } while (1)` loop, the
`parseStatement(cc)` call, the `listAppend`, the token-cursor
handling, the diagnostics, or anything else in the file.

## WHO OWNS WHAT AFTER THE MIGRATION

| Concern | Owner after the migration |
|---|---|
| The five-way membership decision | **PolyC** (`BootstrapDefaultArmTerminates`) |
| The default-arm loop | C |
| The `parseStatement(cc)` call and the token cursor | C |
| The host AST (`stmts` list, `listAppend`) | C |
| The `Ast` node allocation | C |
| The `cc->tmp_default_case` / `cc->localenv` / `cc->tmp_locals` scope state | C |
| The recovery state | C |
| The diagnostics (`cctrlRaiseException`) | C |
| The `stmt->kind` field READ | C (the C side performs the projection) |
| The `long long`/`int` conversion of the projection and the result | C (the adapter owns the mechanical conversions, exactly as the seven existing adapters do) |

## THE AUTHORITY LIMITS

* The PolyC component owns the DECISION and NOTHING ELSE.
* The C adapter owns ONLY the two mechanical duties: the argument
  projection (`int kind -> I64 ast_kind`) and the result conversion
  (`I64 -> the legacy boolean`).
* The legacy condition MUST NOT be evaluated before, after or
  alongside the delegation.
* There is no shadow call and no fallback to C.
* The delegation MUST be reachable through exactly ONE production
  selector, and the selector MUST default to the PolyC arm in the
  production build.

## THE SUCCESSOR'S SUCCESSION DELTA

```text
SUCCESSOR_IMPLEMENTATION_DELTA_FOR_RECON07=0
```

RECON07 itself implements NOTHING. This contract is the only thing
RECON07 produces.

## THE FALLBACK

If the successor's implementation of SUB-002 fails its own gates,
the canonical order makes **SUB-004** (the keyword-to-statement
dispatch in `parseStatement`, src/parser.c:1773-1786) the next
candidate to test. It is ELIGIBLE and is NOT claimed to be causally
feasible by this ACT.
