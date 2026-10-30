# C1 — the frozen selection

**Frozen at C1. May not be re-chosen after an implementation failure.**

```text
SELECTED_EDGE_ID        = E-TYP-0136
SELECTED_EDGE_SRC       = SYS-COMPILE_DRIVER
SELECTED_EDGE_DST       = SYS-AST
SELECTED_EDGE_TYPE      = TYPE_REPRESENTATION
SELECTED_CONSUMER_TU    = src/compile.c
SELECTED_TU_BLOB_SHA1   = ba5468da287c9a1f04e8de8eac0231b792b75591
SELECTED_SOURCE_SHA256  = 07fb25024ff058b2c0dbbeaa33cd7af827650e796e7dd7e7a3176cb88101c39b
SELECTED_OPERATION      = compilePrintAst node-visibility decision:
                          "is this top-level Ast in cc->ast_list printed by the
                          -ast dump, or suppressed because of its kind?"
SELECTED_FUNCTION       = compilePrintAst (src/compile.c:17-40)
SELECTED_DECISION_SITE  = src/compile.c:31-33
SELECTED_CALLER         = src/main.c:541  (`if (args.print_ast) compilePrintAst(cc);`)
SELECTED_CLI_FLAG       = -ast   (src/cli.c:102 -> CLI_PRINT_AST -> args.print_ast)
```

## 1. Why this edge is per-TU and therefore fully retirable

The predecessor witness for `E-TYP-0136` is

```text
#include "ast.h" in src/compile.c   (callsite src/compile.c:1)
```

It is a **single-translation-unit** witness. There is no second consumer of
`SYS-COMPILE_DRIVER -> SYS-AST` of this type: the sibling rows are
`E-MUT-0137` (a `MUTABLE_STATE` edge with its own, different witness) and
`E-TYP-0135` (to `SYS-ASSEMBLER`). Because the granularity of
`E-TYP-0136` is exactly "`src/compile.c` requires the `Ast` layout", removing
that requirement from `src/compile.c` removes the edge, and no
`PARTIAL_CONSUMER_DECOUPLING_ONLY` caveat is needed.

## 2. The operation actually performed here

`compilePrintAst` walks `cc->ast_list` and, for each top-level node, decides
whether to render it with `astToString`. The decision is this predicate:

```c
if (ast->kind != AST_FUN_PROTO &&
    ast->kind != AST_EXTERN_FUNC &&
    ast->kind != AST_ASM_FUNC_BIND)
{ tmp = astToString(ast); printf("%s\n", tmp); }
```

**Measured at C1 (not assumed), after correcting an initial guess:**

```text
AST_FUN_PROTO      comparison  : DEAD at this call site
                                 src/parser.c:3470 already filters it:
                                 `} else if (ast->kind != AST_FUN_PROTO) {
                                    listAppend(cc->ast_list, ast); }`
AST_EXTERN_FUNC    comparison  : LIVE and load-bearing
                                 constructed by parseExternFunctionProto
                                 (src/parser.c:2874) from `extern "c" ...;`
AST_ASM_FUNC_BIND  comparison  : LIVE and load-bearing on every compilation
                                 constructed by astAsmFunctionBind
                                 (src/ast.c:862) from `_extern _LABEL Type
                                 Name(...);`, which src/holyc-lib/tos.HH:590
                                 emits and the compiler force-includes.
```

The first draft of this section guessed that `astAsmFunctionBind` had no
caller. That guess was wrong (`src/parser.c:2668` and `src/parser.c:2998` both
call it), and the corrected measurement above replaces it. This is recorded
rather than silently edited because it is the kind of claim that must be
measured, not inferred.

All three comparisons are still migrated, because the decision must remain
identical for any future parser change. Two of the three produce an observable
difference today (suppressed `extern "c"` declarations and suppressed
`_extern` asm bindings), and that is what the behavioural differential measures.


## 3. Expected post-change constraints (frozen)

After the shadow change, all of the following must hold or this ACT HALTs:

```text
P1  src/compile.c 's EFFECTIVE preprocessed TU contains ZERO src/ast.h frames.
P2  No member access of an Ast appears in src/compile.c.
P3  The three kind comparisons appear in the COMPILED POLYC SUBJECT, not in C.
P4  src/compile.c still calls astToString(Ast*) with an opaque pointer only.
P5  The shadow binary's compilePrintAst calls the PolyC symbol, and that call
    is reachable from `hcc -ast <file>`.
P6  G0 and G1 produce byte-identical -ast output on the frozen corpus.
P7  No other candidate TU loses ast.h (the header cut is not over-claimed).
P8  The rest of the compiler still builds; only the selected decision changes.
```

P1..P8 were already measured as *feasible* at C1 in an external scratch copy
(`c1/feasibility-header-cut.txt`: effective `ast.h` frames in `compile.c` drop
from 1 to 0 while 53 of 54 non-LLVM TUs still compile and the single remaining
error is exactly the `ast->kind` dereference being migrated).

## 4. Candidates rejected during selection

`c0/recon01-14-candidates.tsv` retains all 14 with their witnesses.
`c1/candidate-eligibility-and-ranking.tsv` records the per-candidate verdict.
The only outright disqualification is `CAND-8` / `E-TYP-0177`
(`src/main.c`), which contains **zero** Ast dereferences and zero `AST_*`
symbol uses: that edge is an include artifact, not a semantic dependence, so
migrating anything there would be a fabricated cut.

`CAND-10` (`src/prsasm.c`, 2 dereferences) is the runner-up; it loses on
witness strength because its effect is visible only in emitted assembly rather
than in a first-class observable AST dump.
