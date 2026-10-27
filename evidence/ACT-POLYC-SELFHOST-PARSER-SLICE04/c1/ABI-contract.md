# THE FROZEN ABI CONTRACT -- ACT-POLYC-SELFHOST-PARSER-SLICE04

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** ABI-contract

```text
SELECTED_CANDIDATE_ID=CAND-019
SELECTED_FUNCTION=astBinOpFromToken
SELECTED_POLYC_SYMBOL=BootstrapAstBinOpFromToken
SELECTED_ABI=I64 BootstrapAstBinOpFromToken(I64 token_value) -> I64
SELECTED_FAILURE_SENTINEL=-1
```

## The PolyC component's ABI

```polyc
I64 BootstrapAstBinOpFromToken(I64 token_value)
```

* Input: one `I64` scalar -- the numeric punct token value.
* Output: one `I64` scalar --
  * `>= 0`: the mapped `AstBinOp` enum value, exactly as the live
    `src/ast.h` defines it;
  * `-1`: the token is NOT a binary operator (the failure sentinel).

The component is TOTAL over the whole `I64` domain: every input has a
defined output, and the function is pure (no state, no allocation, no
callbacks, no recovery dependency).

## The four binding properties of the original C API

The legacy C function is:

```c
int astBinOpFromToken(s64 op, AstBinOp *result);
```

and it has four properties, ALL of which are binding:

| # | Property | Frozen contract |
|---|----------|-----------------|
| 1 | returns `1` when the token maps to an AST operator | `BootstrapAstBinOpFromToken(t) >= 0` |
| 2 | returns `0` otherwise | `BootstrapAstBinOpFromToken(t) == -1` |
| 3 | writes the enum through `result` ONLY on success | the adapter writes `*_result` only when `mapped >= 0` |
| 4 | leaves the caller's existing result value UNCHANGED on failure | the adapter returns before writing `*_result` when `mapped < 0` |

## The production C adapter (ACT section 4.2)

```c
int astBinOpFromToken(s64 op, AstBinOp *_result) {
#ifdef HCC_USE_SELFHOST_PARSER_AST_BINOP
    extern long long BootstrapAstBinOpFromToken(long long token_value);
    long long mapped = BootstrapAstBinOpFromToken((long long)op);
    if (mapped < 0)
        return 0;
    *_result = (AstBinOp)mapped;
    return 1;
#else
    ... the legacy switch, retained for the stage0 / oracle build ...
#endif
}
```

The adapter owns ONLY:

* argument projection (`s64 op` -> `I64 token_value`);
* success conversion (the sentinel -> the boolean return value);
* conditional output storage (the write through `_result`).

The adapter does NOT own semantic classification: the token-to-operator
decision is made by the PolyC component.

The adapter must NOT call the legacy switch before, after, or alongside
the PolyC delegation.  There is no shadow call.

## Why the scalar/sentinel ABI is SAFE

ACT section 4.1 authorizes this ABI only after proving four things.
All four are proven, and the proofs are measurements, not assertions.

### P1 -- Every successful legacy mapping is a NONNEGATIVE enum value

The `AstBinOp` enum values were extracted by COMPILING the live
`src/ast.h` (see `enum-values.tsv`):

```text
AstBinOp spans 0..28
AstUnOp  spans 0..12
```

Every one of the 19 accepted mappings produces a value in `0..18`
(measured by the oracle; see `token-mapping.tsv`).  Therefore every
successful mapping is nonnegative.

```text
EVERY_SUCCESSFUL_MAPPING_IS_NONNEGATIVE=YES
```

### P2 -- `-1` CANNOT be a valid mapped enum

The live `AstBinOp` enum has no `-1` member: its lowest value is `0`
(`AST_BIN_OP_MUL`) and its highest is `28` (`AST_BIN_OP_OR_ASSIGN`).

```text
SENTINEL_IS_A_VALID_ENUM_VALUE=NO
SENTINEL_COLLISION=NONE
```

### P3 -- The C and PolyC representations preserve every accepted enum
value EXACTLY

The C representation of `AstBinOp` is a C `enum`; the PolyC
representation is an `I64`.  The oracle driver prints the C enum's
numeric value, and the PolyC component returns the same number for the
same token.  The C3 differential compares them row by row on the whole
fixture matrix, so any divergence in width, sign or value would be
caught.  The enum values are small non-negative integers, so the
`s64 -> I64 -> s64` projection is exact and lossless.

```text
ENUM_VALUES_BOUND_TO_LIVE_HEADER=YES
INTEGER_WIDTH_CHANGE=NONE
```

### P4 -- The entire legacy decision depends ONLY on the token scalar

The live legacy body reads exactly one thing: the scalar parameter
`op`.  It reads no global, no static, no field of any record, and it
calls nothing.  The disassembly of the freshly built production object
confirms it: the body is a jump table over the scalar, with no memory
reference other than the output-pointer store.

```text
SCALAR_INPUT_COMPLETE=YES
STATE_READS=0 (besides the scalar parameter)
STATE_WRITES=0 (besides the output pointer)
CALLBACK_DEPENDENCIES=0
RECOVERY_DEPENDENCIES=0
```

## The bridgeability proof (ACT section 6.2)

```text
LEGACY_AUTHORITY=YES
ALREADY_SELFHOSTED=NO

SCALAR_INPUT_COMPLETE=YES
OUTPUT_RESULT_BOUNDED=YES

HOST_POINTER_IDENTITY_REQUIRED=NO
HOST_GRAPH_MUTATION=NO
SEMANTIC_CALLBACKS=0
NONLOCAL_RECOVERY=NO

PRODUCTION_CALL_PATH=YES
PRODUCTION_DELEGATION_FEASIBLE=YES
```

The one write through the output pointer is classified as **ABI output
storage**, not as host AST graph mutation: it writes an `int`-sized enum
value into a caller-provided slot.  It transfers NO host pointer into
PolyC and does not mutate any AST node, arena, map or list.  The
PolyC component never sees the pointer at all: the adapter keeps it.

## The NULL output pointer (ACT section 4.3)

The legacy function dereferences the result pointer for successful
tokens.  The adapter does exactly the same and only for successful
tokens, so the migration introduces NO new externally observable
null-pointer contract.  The primary differential uses valid output
storage.  Null-pointer behaviour is NOT used as a required successful
fixture, because undefined C behaviour cannot be a fixture.

```text
NULL_POINTER_CONTRACT_CHANGE=NONE
NULL_POINTER_FIXTURE_USED=NO
```
