# ACT-POLYC-SELFHOST-PARSER-SLICE05 -- C1 ORACLE CONTRACT

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** oracle-contract

## 1. What the oracle IS

The oracle is the **REAL legacy C function**, compiled from the live
`src/ast.c` with the PolyC delegation macro **OFF**:

```c
int astUnaryOpFromToken(s64 op, AstUnOp *_result);
```

It is reached through a narrow adapter
(`tools/quality/parser-slice05-oracle-driver.c`) that preinitialises the
caller's output slot to the distinguished value `12345`, calls the real
function, and reports the observed success flag and the final output
value.

## 2. What the oracle is NOT

The oracle driver contains **no mapping table**.  It contains:

* the declaration of the real function,
* the distinguished sentinel constant `12345`,
* a call to the real function,
* the printing of the observed result.

There is no `switch`, no token-to-enum table, and no reimplementation
of the classification anywhere in the driver.

### Why this matters

A handwritten reimplementation of the mapping could share the same
misreading of the legacy source as the PolyC component.  It would then
agree with the PolyC component while BOTH were wrong, and the
differential would be green for the wrong reason.  The oracle is
therefore the byte-identical legacy source, not a copy of it.

## 3. The three properties the oracle must have

### 3.1 The oracle object contains the legacy decision

The selected function in the oracle object must be the legacy C switch.

```text
ORACLE_OBJECT_CONTAINS_LEGACY_DECISION=YES
```

### 3.2 The oracle object does NOT reference the PolyC symbol

The oracle object must not reference `BootstrapAstUnaryOpFromToken`.
If it did, the oracle would be delegating rather than deciding, and
the differential would compare the PolyC component against itself.

```text
ORACLE_OBJECT_REFERENCES_POLYC_SYMBOL=NO
```

This is checked MECHANICALLY at build time with `nm`, and the build
FAILS if the symbol appears.  It is not a claim in a document.

### 3.3 The driver contains no duplicate mapping

```text
ORACLE_DRIVER_HAS_DUPLICATE_MAPPING=NO
```

## 4. The build recipe (frozen)

```sh
# The legacy ast.c object: src/ast.c with the unary delegation OFF.
cc -std=c99 -O2 -Isrc -c -o build/slice05-ast-legacy.o src/ast.c

# The is_terminal stub.
cc -std=c99 -O2 -c -o build/slice05-is-terminal-stub.o \
    tools/quality/parser-slice05-oracle-stub.c

# The oracle driver, linked against the legacy ast.c object and the
# transitive production objects, with main.c.o and ast.c.o EXCLUDED.
cc -std=c99 -O2 -Isrc -o build/slice05-oracle-driver \
    tools/quality/parser-slice05-oracle-driver.c \
    build/slice05-ast-legacy.o build/slice05-is-terminal-stub.o \
    <transitive production objects> \
    -Wl,-undefined,dynamic_lookup
```

`main.c.o` is excluded because it defines `main()` and the
runtime-initialised `is_terminal`.  `ast.c.o` is excluded because the
oracle IS the legacy `ast.c`; including the production object would be
both a duplicate-symbol conflict and a defeat of the oracle.

## 5. The recorded observation format

```text
<token_value>\t<success>\t<output_after_call>
```

* `token_value` -- the exact signed 64-bit token value.
* `success` -- the real function's return value (`1` or `0`).
* `output_after_call` -- the FINAL value of the caller's output slot.

The driver parses its arguments with `strtoll`, never `atoi`, so the
signed 64-bit extremes are exact.

## 6. The measured baseline

The ten accepted tokens, measured by executing the real function:

```text
816	1	2      TK_PRE_PLUS_PLUS   -> AST_UN_OP_PRE_INC
817	1	3      TK_PRE_MINUS_MINUS -> AST_UN_OP_PRE_DEC
773	1	0      TK_PLUS_PLUS       -> AST_UN_OP_POST_INC
774	1	1      TK_MINUS_MINUS     -> AST_UN_OP_POST_DEC
43	1	4      '+'                -> AST_UN_OP_PLUS
45	1	5      '-'                -> AST_UN_OP_MINUS
126	1	7      '~'                -> AST_UN_OP_BIT_NOT
33	1	6      '!'                -> AST_UN_OP_LOG_NOT
38	1	8      '&'                -> AST_UN_OP_ADDR_OF
42	1	9      '*'                -> AST_UN_OP_DEREF
```

Rejected probes, showing the output slot left untouched at `12345`:

```text
999999	0	12345
32	0	12345
0	0	12345
-1	0	12345
772	0	12345
775	0	12345
815	0	12345
818	0	12345
```

## 7. The frozen contract

```text
ORACLE_SOURCE=src/ast.c (live), delegation macro OFF
ORACLE_ADAPTER=tools/quality/parser-slice05-oracle-driver.c
ORACLE_STUB=tools/quality/parser-slice05-oracle-stub.c
ORACLE_DRIVER_HAS_DUPLICATE_MAPPING=NO
ORACLE_OBJECT_CONTAINS_LEGACY_DECISION=YES
ORACLE_OBJECT_REFERENCES_POLYC_SYMBOL=NO
ORACLE_OUTPUT_FORMAT=token_value<TAB>success<TAB>output_after_call
ORACLE_DISTINGUISHED_INITIAL_OUTPUT=12345
```

## 8. The comparison the differential must perform

For **every** fixture row:

```text
LEGACY_SUCCESS  = POLYC_ADAPTER_SUCCESS
LEGACY_OUTPUT   = POLYC_ADAPTER_OUTPUT
```

AND both of them must equal the fixture's own independently frozen
expected values.  The fixture's expectations are therefore checked
against the oracle as well, so an equally wrong fixture cannot mask a
disagreement between the PolyC component and the production oracle.

```text
DIFFERENTIAL_MISMATCHES=0
ORACLE_EXPECTED_MISMATCHES=0
POLYC_EXPECTED_MISMATCHES=0
OUTPUT_PRESERVATION_FAILURES=0
```
