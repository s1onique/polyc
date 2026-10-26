# Successor ABI contract — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Selected target:** `parseGetPriority` (`src/prslib.c:1139..1207`)
**Candidate id:** `CAND-017`
**Successor ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE03`

---

## 1. Frozen ABI

```text
POLYC_SYMBOL         = BootstrapOperatorPrecedence
INPUT_COUNT          = 1
INPUT_TYPES          = I64 punct_value
OUTPUT_COUNT         = 1
OUTPUT_TYPES         = I64 precedence

INTEGER_WIDTHS       = 64
SIGNEDNESS           = SIGNED (I64)

NULL_AND_EMPTY_BEHAVIOR
                     = NOT APPLICABLE.  The ABI has no pointer, no
                       length and no buffer, so there is no NULL case
                       and no empty case.  Every I64 is a defined
                       input.

INVALID_INPUT_BEHAVIOR
                     = The function is TOTAL over the whole I64
                       domain: every input value has exactly one
                       defined output.  An input that is not a
                       recognised punct value returns -1, which is the
                       legacy sentinel for "this token is not a binary
                       operator".  There is no error path, no
                       exception and no diagnostic inside the ABI.

BUFFER_OWNERSHIP     = NOT APPLICABLE (no buffer).
BUFFER_CAPACITY      = NOT APPLICABLE (no buffer).
ALLOCATION_OWNERSHIP  = NONE.  The component performs no allocation.

ERROR_REPORTING_OWNER = The C CALLER.  The legacy C decision site
                       (src/prslib.c:1363) keeps the token and the
                       surrounding error reporting; the component never
                       raises, never reports and never aborts.
RECOVERY_OWNER       = The C CALLER.  The component owns no recovery
                       point, installs no setjmp and cannot longjmp.
```

`ABI_HOST_IDENTITY_FIELDS = 0`.
`ABI_ALLOCATION_SITES = 0`.

---

## 2. The input projection is mechanically complete

The legacy C signature is `static int parseGetPriority(Lexeme *tok)`.
The legacy body reads **exactly one field**:

```text
$ sed -n '1139,1207p' src/prslib.c | grep -n 'tok->'
2:    switch (tok->i64) {
```

That is the ONLY field access in the whole 69-line body, and there is
no other identifier in the body at all.  Therefore the complete input
projection is:

```text
punct_value = tok->i64
```

and the caller-side adapter is:

```c
int parseGetPriority(Lexeme *tok) {
    return (int)BootstrapOperatorPrecedence((long long)tok->i64);
}
```

The `Lexeme *` never crosses the component boundary, so no host
pointer identity is exposed and no zero-copy projection is used.

**Why `tok->i64` is the right field and not `tk_type`:**
`parseGetPriority` is only ever reached from `parseExpr` after the
caller has established `tok->tk_type == TK_PUNCT`
(`src/prslib.c:1358` returns early for any other kind).  For a
`TK_PUNCT` lexeme the lexer stores the punct value in `i64`
(`src/lexer.c:222`: `le->i64 = op; /* instead of 'char'*/`).  The
legacy function therefore never inspects `tk_type`, and the PolyC
component must not add a `tk_type` check that the legacy function does
not perform: adding one would change the result for any caller that
reaches the function with a non-`TK_PUNCT` token.

---

## 3. The exact semantic contract

The PolyC component is a transcription of the legacy table.  The
complete table, with the live `src/lexer.h` constant values:

```text
precedence 1  : TK_ARROW (0x328), '.' (0x2E), '(' (0x28)
precedence 2  : '[' (0x5B)
precedence 3  : '!' (0x21), '~' (0x7E),
                TK_PLUS_PLUS (0x305), TK_MINUS_MINUS (0x306),
                TK_PRE_PLUS_PLUS (0x330), TK_PRE_MINUS_MINUS (0x331)
precedence 4  : '*' (0x2A), '/' (0x2F), '%' (0x25)
precedence 5  : '-' (0x2D), '+' (0x2B)
precedence 6  : TK_SHL (0x309), TK_SHR (0x30A)
precedence 7  : TK_LESS_EQU (0x30D), TK_GREATER_EQU (0x30E),
                '<' (0x3C), '>' (0x3E)
precedence 8  : TK_EQU_EQU (0x30B), TK_NOT_EQU (0x30C)
precedence 9  : '^' (0x5E)
precedence 10 : '&' (0x26)
precedence 11 : '|' (0x7C)
precedence 12 : TK_AND_AND (0x30F)
precedence 13 : TK_OR_OR (0x310)
precedence 14 : '=' (0x3D), TK_ADD_EQU (0x319), TK_SUB_EQU (0x31A),
                TK_MUL_EQU (0x314), TK_DIV_EQU (0x315),
                TK_MOD_EQU (0x322), TK_AND_EQU (0x316),
                TK_OR_EQU (0x317), TK_XOR_EQU (0x318),
                TK_SHL_EQU (0x312), TK_SHR_EQU (0x313)
any other    : -1
```

The constants are written as **numbers** in the PolyC component, for
the same reason the control-flow-token component writes its constants
as numbers: the PolyC component cannot include the legacy C header, and
the binding that matters is the numeric one.  Every value above was
read from the live `src/lexer.h` at the frozen C0 baseline
(`src/lexer.h` SHA-256
`6bc46f3be938c6fae99095d8cf0b1f07104bbf9fc1dfb248aaa3cd5dd721c5f9`).

**Aliasing that MUST be honoured:** `src/lexer.h:15` defines
`TK_SUPERSCRIPT 0x301` and `src/lexer.h:19` defines `TK_STR 0x301`.
Neither value appears in the precedence table, so the aliasing does not
affect this component — but the successor MUST NOT add a check that
distinguishes them.  The precedence table is defined on the NUMERIC
punct value and nothing else.

---

## 4. The output projection is complete

The legacy function returns `int`, in the range `{-1} ∪ {1..14}`.  The
PolyC component returns `I64` in exactly the same set.  The caller-side
cast is `(int)BootstrapOperatorPrecedence(...)`, which is exact because
every value in the domain fits in an `int` without loss.

`parseExpr` consumes the value in exactly three ways
(`src/prslib.c:1364`, `:1430`, `:1431`):

```text
if (prec2 < 0 || prec <= prec2) { rewind; return LHS; }   // -1 means
next_prec = prec2;                                          // "not a
if (tok->i64 == '=') next_prec++;                           //  binary op"
```

so the `-1` sentinel is load-bearing and must be preserved exactly.

---

## 5. Delegation seam

```text
src/prslib.c:1363     prec2 = parseGetPriority(tok);
```

becomes

```text
#ifdef HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE
    prec2 = (int)BootstrapOperatorPrecedence((long long)tok->i64);
#else
    prec2 = parseGetPriority(tok);
#endif
```

The legacy body lives in the `#else` branch, so it is NOT COMPILED
into the production object when the delegation flag is on — the same
fail-closed shape the two existing parser migrations use
(`src/parser.c:431` and `src/parser.c:833`).

The caller and the error-reporting seam stay C-owned.  The component
never reports a diagnostic and never transfers control.

---

## 6. Out of scope for the successor

```text
No change to the precedence VALUES.
No change to the -1 sentinel.
No addition of a tk_type check.
No change to parseExpr, to the recursion, or to the AST.
No change to the legacy C function's body (it moves behind #else).
No new runtime machinery.
No change to the other nine eligible candidates.
```
