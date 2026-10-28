# ACT-POLYC-SELFHOST-PARSER-SLICE05 -- C1 ABI CONTRACT

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** ABI-contract

## 1. The frozen PolyC ABI

```text
I64 BootstrapAstUnaryOpFromToken(I64 token_value) -> I64
```

## 2. The return domain

| Condition | Return |
|---|---|
| The token is one of the ten accepted unary tokens | the exact `AstUnOp` enum value, `>= 0` |
| The token is not an accepted unary token | `-1` (the failure sentinel) |

## 3. Why the sentinel is safe

The sentinel is safe **because the live enum was compiled and measured**,
not because a predecessor wrote down a number.

The live `src/ast.h` was compiled by the host C compiler and a probe
printed the values the compiler assigned:

```text
AST_UN_OP_POST_INC  = 0
AST_UN_OP_POST_DEC  = 1
AST_UN_OP_PRE_INC   = 2
AST_UN_OP_PRE_DEC   = 3
AST_UN_OP_PLUS      = 4
AST_UN_OP_MINUS     = 5
AST_UN_OP_LOG_NOT   = 6
AST_UN_OP_BIT_NOT   = 7
AST_UN_OP_ADDR_OF   = 8
AST_UN_OP_DEREF     = 9
AST_UN_OP_SIZEOF    = 10
AST_UN_OP_ALIGNOF   = 11
AST_UN_OP_CAST      = 12
```

```text
ENUM_VALUES_NONNEGATIVE=YES
ENUM_MIN=0
ENUM_MAX=12
FAILURE_SENTINEL=-1
SENTINEL_COLLISION=NO
```

`-1` is not a member of the enum's value set, so it cannot collide with
any successful mapping.  The ten mappings actually produced by the real
legacy function span `0..9`, a strict subset of the enum's `0..12`.

## 4. The boundary conditions the ACT requires

```text
ABI_HOST_POINTER_FIELDS=0
ABI_GLOBAL_STATE_FIELDS=0

ENUM_VALUES_NONNEGATIVE=YES
FAILURE_SENTINEL=-1
SENTINEL_COLLISION=NO

INTEGER_PROJECTION_LOSSLESS=YES
```

### ABI_HOST_POINTER_FIELDS = 0

The PolyC function takes one `I64` and returns one `I64`.  There is no
pointer parameter, no pointer return, no pointer field, and no host
structure in the signature.  The C output pointer is **never** passed
to the PolyC component: it is ABI storage owned by the C adapter.

### ABI_GLOBAL_STATE_FIELDS = 0

The component reads no global.  It is a pure function of its scalar
argument.

### INTEGER_PROJECTION_LOSSLESS = YES

The C adapter's projection is `s64 -> I64 -> long long -> int`.

* `s64` is the project's 64-bit signed integer type.
* `I64` is PolyC's 64-bit signed integer type.
* `long long` is the C type the PolyC ABI is exported as.
* `int` is the C type the mapped enum is stored as.

The projection is lossless **in the direction that matters**:

* **Token in:** the token value is copied from `s64` to `I64` to
  `long long`.  All three are 64-bit signed, so every `s64` value
  survives exactly, including `INT64_MIN` and `INT64_MAX`.  The
  component must therefore handle the whole 64-bit domain, which is
  what the U09 partition exercises.
* **Mapped value out:** the mapped enum is one of `0..9`, and the
  failure sentinel is `-1`.  All of them fit in an `int` without loss.

The measurement that the projection is exact is not an assertion: the
U09 and U11 fixture rows are printed and compared as full 64-bit
values, and the differential compares the legacy function's observed
output against the PolyC adapter's observed output on every row.

## 5. The C adapter contract

The production wrapper **retains the original C signature**:

```c
int astUnaryOpFromToken(s64 op, AstUnOp *_result);
```

The adapter owns exactly three mechanical duties:

1. **Argument projection** -- `s64 op` -> `I64 token_value`.
2. **Success/failure conversion** -- the `-1` sentinel -> the boolean
   return value (`0` for failure, `1` for success).
3. **Conditional enum storage** -- the write through `_result`, and
   ONLY on success.

The adapter must **not** own token classification.  There is no switch,
no table, no range test, and no fallback call to the legacy C mapping
in the production branch.

### The required behaviour

```text
success: return_value=1, output_after_call=<mapped AstUnOp>
failure: return_value=0, output_after_call=output_before_call
```

A failed lookup must **not** overwrite the caller's output storage.
This is the property the legacy function has and that the adapter must
preserve exactly.

## 6. The production switch

```text
HCC_USE_SELFHOST_PARSER_AST_UNARY
```

```text
PRODUCTION_DEFAULT=ON
STAGE0_BUILD=OFF
LEGACY_ORACLE_BUILD=OFF
```

* The **production** compiler defines it.  The `ON` branch delegates.
* The **stage0** compiler does not define it, so the stage0 compiler
  retains the legacy body (the stage0 compiler must not depend on a
  component that does not exist yet).
* The **legacy oracle** does not define it, so the oracle executes the
  REAL legacy switch body.

The switch is **fail-closed**: when the flag is ON, the production
build MUST have a verified PolyC subject object carrying the exported
symbol.  If the object is missing, empty, malformed, weak-only,
local-only, undefined-only, duplicated, or carries the wrong symbol
name, the **build fails**.  There is no automatic fallback to the
legacy C mapping.

## 7. What the component must NOT do

```text
NO_GLOBAL_STATE=YES
NO_ALLOCATION=YES
NO_CALLBACKS=YES
NO_AST_POINTERS=YES
NO_NONLOCAL_RECOVERY=YES

PURE_SCALAR_MAPPING=YES
```

The component is total over the whole `I64` domain: every token value
that is not one of the ten accepted values maps to `-1`.

The component does **not** inspect `tk_type`.  The legacy body decides
on the NUMERIC value alone; adding a `tk_type` check would change the
result for any caller that reaches the function with a non-`TK_PUNCT`
token.

## 8. The ABI is frozen from this point

C2 implements exactly this contract.  Any change to the signature, the
return domain, the sentinel, or the adapter's duties is a contract
change and requires a new bounded decision, not a silent edit.
