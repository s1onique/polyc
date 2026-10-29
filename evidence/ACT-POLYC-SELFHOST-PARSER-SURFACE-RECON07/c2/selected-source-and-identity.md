# SELECTED SOURCE AND IDENTITY

```text
SELECTED_CANDIDATE_ID=SUB-002
SELECTED_CLASS=STRUCTURAL
SELECTED_DECISION=DEFAULT_ARM_TERMINATION
SELECTED_SOURCE_FILE=src/parser.c
SELECTED_SOURCE_RANGE=1683..1684
SELECTED_SOURCE_SHA256=a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
SELECTED_ENCLOSING_FUNCTION=parseDefaultStatement
SELECTED_ENCLOSING_FUNCTION_RANGE=1667..1690
SELECTED_CALLER=parseSwitchStatement
SELECTED_CALLER_FILE=src/parser.c
SELECTED_CALLER_LINE=1692
SELECTED_CALL_PATH=parseCompoundStatementInternal -> parseStatement -> (KW_DEFAULT arm) -> parseDefaultStatement
SELECTED_RANK=1
SELECTED_R0=0
SELECTED_R1=1
SELECTED_R2=1
SELECTED_R3=2
SELECTED_R4=1
SELECTED_R5=1
SELECTED_R6=src/parser.c:1683
```

## THE EXACT LIVE SOURCE

```c
        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
                || stmt->kind == AST_GOTO) break;
```

`src/parser.c` lines 1683-1684, inside `parseDefaultStatement` (lines
1667-1690), inside the default-arm statement loop.

## THE FIVE TERMINATING KINDS (live values, from src/ast.h)

```text
AST_GOTO          = 258
AST_RETURN        = 270
AST_COMPOUND_STMT = 274
AST_BREAK         = 280
AST_CASE          = 287
```

`AST_DEFAULT = 293` is **deliberately absent** from this condition,
although it **is** present in the already-migrated SUB-001 (case-arm)
condition. That difference is SUB-002's own distinguishing property
and it is a positive (must-not-terminate) sentinel in the fixture.

## THE IDENTITY PROOF

The range hash `a9fcb6a7...` was recomputed from the live bytes by
`build/parser-surface-recon05-verify RANGE` and is **byte-identical to
the RECON05 recorded range**: the decision itself has not changed
since the RECON05 census. The line numbers are unchanged too. The
only thing that moved in this file since RECON05 is the SLICE07 C1
insertion, which is ABOVE line 1683 in the file only for functions
after `parseCompoundStatementInternal`; the default-arm condition is
untouched.

## WHAT THIS IS NOT

* It is **not** the whole `parseDefaultStatement` function.
* It is **not** the whole `parseStatement` function (that is SUB-008,
  an excluded whole-function blocker).
* It is **not** the SUB-001 case-arm termination, which is already
  PolyC-owned by `BootstrapSwitchArmTerminates`.
* It is **not** a duplicate of any already-migrated authority: the
  C2 experiment proved it is a distinct, independently live decision
  with its own causal effect.
