# HCC Lexer Demand — R2

## What the existing HCC lexer (src/lexer.c) actually uses

The existing HCC lexer is the closest analogue to the proposed B0
lexer. It is written in C and currently lowers through both the
x86 and aarch64 native backends and through the LLVM backend.

This section enumerates the **integer operations** the lexer
performs, mapped to the neutral IR opcodes the PolyC compiler
emits for equivalent PolyC source.

### Character classification (macros in src/lexer.c)

```c
#define isNum(ch) ((ch) >= '0' && (ch) <= '9')
#define isHex(ch) (isNum(ch) || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F'))
```

These lower (in C -> PolyC translation) to:
- `IR_ICMP` with `IR_CMP_ULT` / `IR_CMP_ULE` (range checks against constants)
- `IR_AND` on `i1` values for the conjunction (already supported for i1)

Note: `IR_AND` on `i64` is **not** exercised by these macros; they
operate on chars/bools.

### Numeric accumulation in `lexCharConst`

```c
char_const |= (unsigned long)ch << (unsigned long)(idx);
```

Equivalent PolyC:
```c
char_const = char_const | (ch << idx);
```

This **is** the only site in the existing lexer that exercises
bitwise OR (IR_OR) and shift-left (IR_SHL) on I64 values. However:

- `lexCharConst` is for **character constants** like `'abc'`, not
  integer literals.
- Character constants are not on the B0 critical path: B0 only
  needs to recognize decimal integer literals, identifiers, and
  punctuation. Char-const lexing is an extension that B0 can
  defer.

### Hex digit accumulation

```c
hex_num = (hex_num << 4) + ch - '0';     // or with A-F
```

Equivalent PolyC:
```c
hex_num = (hex_num << 4) + (ch - '0');
```

This **does** exercise IR_SHL on I64 values. However:

- B0 only needs **decimal** integer literals per the sketch.
- Hex literals can be deferred to a later ACT or remain supported
  by the native backends only.

### Cursor advancement

```c
l->ptr += numlen - 1;
```

Equivalent PolyC:
```c
l->ptr = l->ptr + (numlen - 1);
```

Exercises IR_IADD and IR_ISUB (already supported).

### `lexIdentifier`

```c
while (ch && (isalnum(ch) || ch == '_' || ch == '$')) {
    i++;
    ch = lexNextChar(l);
}
```

This uses host-C `isalnum` which is a library function. In a
PolyC B0 implementation, the analogous check would be:

```c
while (is_alpha(c) | is_digit(c) | (c == '_')) {
    c = source[cursor];
    cursor = cursor + 1;
}
```

The `|` here is the **logical or** in PolyC's HolyC-influenced
grammar (since `||` is also valid). Either way, on `i1` operands,
this is already supported.

### Summary of HCC lexer demand

| Operation                              | Used in HCC lexer? | B0-critical? |
|----------------------------------------|--------------------|--------------|
| IADD on I64                            | Yes (ptr advance)  | Yes          |
| ISUB on I64                            | Yes (cursor - start)| Yes         |
| IMUL on I64                            | No (uses strtoll)  | No           |
| ICMP on I64                            | Yes (range checks) | Yes          |
| IR_AND on I1 (logical AND)             | Yes                | Yes (already supported on i1) |
| IR_AND on I64 (bitwise AND)            | No                 | **No**       |
| IR_OR on I64 (bitwise OR)              | Yes (lexCharConst) | **No**       |
| IR_XOR on I64                          | No                 | **No**       |
| IR_SHL on I64                          | Yes (lexCharConst) | **No**       |
| IR_SHR on I64                          | No                 | **No**       |
| IR_SAR on I64                          | No                 | **No**       |
| IR_NOT on I64                          | No                 | **No**       |
| IR_IDIV / IR_UDIV                      | No (uses strtoll)  | **No**       |
| IR_IREM / IR_UREM                      | No                 | **No**       |
| IR_TRUNC / IR_ZEXT / IR_SEXT           | No                 | **No**       |
| IR_INEG                                | No                 | **No**       |
