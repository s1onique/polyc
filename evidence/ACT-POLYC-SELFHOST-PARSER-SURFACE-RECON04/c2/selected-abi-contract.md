# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SELECTED ABI CONTRACT

**SELECTED_CANDIDATE:** `SUB-001`
**SELECTED_CANDIDATE_CLASS:** `STRUCTURAL_BOUNDARY`
**SELECTED_ENCLOSING_FUNCTION:** `parseCaseLabel` (`src/parser.c`)
**SELECTED_SOURCE_RANGE:** `src/parser.c:1551..1553`
**SELECTED_SOURCE_SHA256:** `31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707`

---

## 1. The frozen ABI

```text
I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
```

The ABI is `SCALAR -> SCALAR`, which is one of the two shapes the ACT
permits (ACT section 10).

| Property | Value |
|---|---|
| Input fields | one `I64` carrying an `AstKind` enum value |
| Output fields | one `I64`: `1` = terminate the arm, `0` = continue the arm |
| Input domain | the live `AstKind` enum, `256..299`, plus the out-of-enum probes `-4..0` and `296..300` |
| Output domain | `{0, 1}` |
| Maximum size | 8 bytes in, 8 bytes out |
| Pointer crossing | NONE |
| `void *` crossing | NONE |
| Callback table | NONE |
| `jmp_buf` crossing | NONE |

The C-side adapter reads exactly ONE host field -- `stmt->kind` -- and
passes it as the scalar.  It then executes the `break` itself when the
PolyC result is `1`.

**Why the sentinel is unnecessary:** the decision is a BOOLEAN, not a
classification.  There is no "not found" case, so there is no sentinel
that could collide with a valid result.

## 2. The decision being transferred

The live source at `src/parser.c:1551..1553`:

```c
        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE ||
                stmt->kind == AST_DEFAULT || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
                || stmt->kind == AST_GOTO) break;
```

The terminating set is exactly:

```text
AST_COMPOUND_STMT = 274
AST_CASE          = 287
AST_DEFAULT       = 293
AST_BREAK         = 280
AST_RETURN        = 270
AST_GOTO          = 258
```

These six values are the live `src/ast.h` values and are NOT to be
re-derived by the successor; they are FROZEN here.

## 3. The production delegation seam

The seam is the single `if` statement at `src/parser.c:1551..1553`.
After the migration it reads:

```c
        if (BootstrapSwitchArmTerminates((long long)stmt->kind)) break;
```

The legacy C condition is compiled OUT under the dedicated delegation
macro, exactly as the five migrated authorities do it.  The successor
MUST verify that the legacy condition is absent from the production
object, not merely that the PolyC symbol is present.

**The delegation must be LOAD-BEARING.**  If C still evaluates the same
condition after receiving the PolyC result, the migration is a
duplication, not an authority transfer, and the successor FAILS.

## 4. Failure semantics

```text
FAILURE_SEMANTICS=NO_FAILURE_PATH
```

The PolyC component is a total function over the input domain: every
`I64` maps to exactly one of `{0, 1}`.  There is no error return, no
exception, no diagnostic and no recovery interaction.

If the successor's PolyC component ever needs to report a failure, the
ABI MUST be extended with an explicit out-of-band channel and the
contract MUST be re-frozen; it MUST NOT reuse the `0`/`1` result.

## 5. Ownership after the migration

| Authority | Owner |
|---|---|
| Recovery (`jmp_buf`, `cc->current_recovery`) | C |
| AST graph (`body->stms`, the arm's `stmts` list) | C |
| Symbol table (`cc->localenv`) | C |
| Token stream (`cc->token_buffer`) | C |
| Diagnostics | C |
| The `break` that leaves the arm loop | C |
| **The arm-termination DECISION** | **PolyC** |

## 6. The enclosing function stays as it is

`parseCaseLabel` as a whole function remains INELIGIBLE.  It owns the
host case list, the arm statement list, the diagnostics and 20
subordinate host calls.  The successor MUST NOT move any of those.
The successor changes EXACTLY ONE `if` condition.

## 7. What the successor must NOT do

```text
OUT_OF_SCOPE=no change to the AstKind enum values
OUT_OF_SCOPE=no change to any other parser function
OUT_OF_SCOPE=no change to the lexer, the AST allocator or the transpiler
OUT_OF_SCOPE=no change to src/CMakeLists.txt beyond adding the
                dedicated delegation selector and the subject link
OUT_OF_SCOPE=no new Python
OUT_OF_SCOPE=no change to the recovery protocol
OUT_OF_SCOPE=no change to the diagnostic texts
OUT_OF_SCOPE=no change to the arm-loop structure
```
