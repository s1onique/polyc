# Selected ABI Contract — CAND-001 `parseValidPostControlFlowToken`

ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT_PHASE=C2-RANK-SELECT
EVIDENCE_KIND=selected-abi-contract

Legacy C authority (the behaviour that must be reproduced):

```text
src/parser.c:832..864
int parseValidPostControlFlowToken(Lexeme *tok)
```

---

## 1. Symbol and shape

```text
symbol_name            = BootstrapValidPostControlFlowToken
input_field_count      = 3
input_field_types      = I64, I64, I64
output_field_count     = 1
output_field_types     = I64

proposed PolyC declaration:
  I64 BootstrapValidPostControlFlowToken(I64 token_present,
                                         I64 token_kind,
                                         I64 token_value);
```

The PolyC ABI does **not** accept the raw `Lexeme *`. The C caller
projects the three scalars out of the token at the call site; the PolyC
component never sees a host pointer.

---

## 2. Field semantics

| # | Field | Type | Domain | Meaning |
|---|---|---|---|---|
| 1 | `token_present` | `I64` | 0 or 1 | 1 iff the token pointer is non-NULL. 0 means "no token" (EOF). |
| 2 | `token_kind` | `I64` | the `tk_type` domain | The token's `tk_type` value. Meaningful only when `token_present == 1`. |
| 3 | `token_value` | `I64` | the `i64` payload domain | The token's `i64` payload. Meaningful only when `token_present == 1`. |

### Output

| # | Field | Type | Domain | Meaning |
|---|---|---|---|---|
| 1 | *(return)* | `I64` | 0 or 1 | 1 = the token may begin a statement after a control-flow header. 0 = it may not. |

The legacy C function returns `int` with exactly the values 0 and 1. The
PolyC return is `I64` restricted to the same {0,1} set, so the C wrapper
can narrow it without loss.

---

## 3. Null and empty semantics

```text
token_present == 0  ->  return 0
```

This is the legacy behaviour at `src/parser.c:833`:

```c
if (tok == NULL) return 0; /* EOF - caller raises */
```

The NULL/EOF case is **not** an error and **not** a diagnostic inside the
component. The production C caller owns the diagnostic
(`cctrlRaiseException(cc, "Unexpected end of input")` at
`src/parser.c:947`, `:1251`, `:1285`, `:1318`). The PolyC component
returns 0 and the caller raises. Diagnostic ownership does not cross the
boundary.

No other "empty" input exists: the component takes no containers, so
there is no empty-list or empty-record case.

---

## 4. Integer widths, signedness and value ranges

```text
token_present : I64, SIGNED, domain {0, 1}
token_kind    : I64, SIGNED, carries an unsigned 16-bit lexer tag
token_value   : I64, SIGNED, carries a signed 64-bit lexer payload
return value  : I64, SIGNED, domain {0, 1}
```

The legacy `Lexeme.i64` is `s64` (`src/lexer.h`, `union { s64 i64; double f64; }`),
so `token_value` is a faithful signed 64-bit projection. The legacy
`tk_type` is `int`; every `TK_*` tag fits in a small unsigned range, so
an `I64` projection is exact.

**Signedness matters for `token_value`.** The legacy comparison is

```c
switch (tok->i64) { case KW_DO: ... }
```

which is an exact 64-bit signed equality against each keyword constant.
A PolyC implementation that widened to unsigned, or that compared against
a sign-extended constant incorrectly, would disagree on negative
payloads. The contract requires exact signed 64-bit equality.

**`token_present` must not be sign-truncated.** A negative
`token_present` is outside the contract; the C wrapper must pass exactly
0 or 1.

---

## 5. Bound constants (from the CURRENT lexer header, not guessed)

Every constant below is taken from `src/lexer.h` at the entry head.

### Token kind tags

| Constant | Value | Header line | Role |
|---|---|---|---|
| `TK_IDENT` | `0x300` | `src/lexer.h:18` | accepted (any value) |
| `TK_STR` | `0x301` | `src/lexer.h:19` | accepted (any value) |
| `TK_PUNCT` | `0x329` | `src/lexer.h:59` | accepted only for the payload set below |
| `TK_KEYWORD` | `0x332` | `src/lexer.h:62` | accepted only for the payload set below |
| `TK_PLUS_PLUS` | `0x305` | `src/lexer.h:23` | accepted punctuation payload |
| `TK_MINUS_MINUS` | `0x306` | `src/lexer.h:24` | accepted punctuation payload |

### Accepted punctuation payloads (exact signed equality)

| Payload | Value | Source |
|---|---|---|
| `TK_MINUS_MINUS` | `0x306` = 774 | `src/lexer.h:24` |
| `TK_PLUS_PLUS` | `0x305` = 773 | `src/lexer.h:23` |
| `'{'` | 123 | ASCII literal in `src/parser.c:840` |
| `';'` | 59 | ASCII literal in `src/parser.c:841` |
| `'*'` | 42 | ASCII literal in `src/parser.c:842` |

Note on the `TK_PLUS_PLUS` / `TK_MINUS_MINUS` payloads: the legacy code
uses the *lexer token tags* `TK_MINUS_MINUS` (`0x306`) and
`TK_PLUS_PLUS` (`0x305`) as the `i64` payload values of a `TK_PUNCT`
token, i.e. the lexer encodes the multi-character operators in the
payload field. The successor MUST bind to those exact tag values
(`0x306` and `0x305` respectively) and MUST NOT assume they equal the
ASCII codes of `-` or `+`. This is a live source binding, not an
inference:

```c
case TK_MINUS_MINUS:
case TK_PLUS_PLUS:
case '{':
case ';':
case '*':
```

### Accepted keyword payloads (exact signed equality)

| Constant | Value | Header line |
|---|---|---|
| `KW_RETURN` | 18 | `src/lexer.h:85` |
| `KW_SWITCH` | 20 | `src/lexer.h:86` |
| `KW_BREAK` | 24 | `src/lexer.h:88` |
| `KW_CONTINUE` | 26 | `src/lexer.h:89` |
| `KW_ASM` | 28 | `src/lexer.h:90` |
| `KW_FOR` | 38 | `src/lexer.h:95` |
| `KW_WHILE` | 40 | `src/lexer.h:96` |
| `KW_GOTO` | 44 | `src/lexer.h:98` |
| `KW_IF` | 46 | `src/lexer.h:99` |
| `KW_DO` | 66 | `src/lexer.h:109` |
| `KW_TRY` | 80 | `src/lexer.h:124` |
| `KW_THROW` | 82 | `src/lexer.h:126` |

---

## 6. Decision table (exhaustive over the contract domain)

| `token_present` | `token_kind` | `token_value` | Result | Legacy source |
|---|---|---|---|---|
| 0 | (any) | (any) | **0** | `src/parser.c:833` |
| 1 | `TK_IDENT` (0x300) | (any) | **1** | `:834` |
| 1 | `TK_STR` (0x301) | (any) | **1** | `:835` |
| 1 | `TK_PUNCT` (0x329) | `TK_MINUS_MINUS` (0x306) | **1** | `:838` |
| 1 | `TK_PUNCT` (0x329) | `TK_PLUS_PLUS` (0x305) | **1** | `:839` |
| 1 | `TK_PUNCT` (0x329) | `'{'` (123) | **1** | `:840` |
| 1 | `TK_PUNCT` (0x329) | `';'` (59) | **1** | `:841` |
| 1 | `TK_PUNCT` (0x329) | `'*'` (42) | **1** | `:842` |
| 1 | `TK_PUNCT` (0x329) | any other value | **0** | falls through |
| 1 | `TK_KEYWORD` (0x332) | any of the 12 accepted keywords | **1** | `:847..858` |
| 1 | `TK_KEYWORD` (0x332) | any other value | **0** | falls through |
| 1 | any other kind | (any) | **0** | falls through |

### Required fixture coverage (ACT SECT_9)

The successor's fixture matrix MUST cover every row above, and MUST
additionally cover:

- **Unknown token kinds**: `TK_I64` (0x302), `TK_F64` (0x304),
  `TK_CHAR_CONST` (0x303), `TK_EOF` (0), `TK_COMMENT` (0x333),
  `TK_SUBSCRIPT` (0x302... see note), `TK_NORMALSCRIPT` (0x303... see
  note) and any other tag — each with an arbitrary payload. All must
  yield 0.
- **Kind-value aliasing (LIVE HEADER FACT, MUST be honoured)**:
  `TK_SUPERSCRIPT` is defined as `0x301` (`src/lexer.h:15`) and
  `TK_STR` is ALSO defined as `0x301` (`src/lexer.h:19`). At the ABI
  level the kind is the NUMBER, so `0x301` is `TK_STR` and is
  **ACCEPTED**. A successor that assumed a distinct "superscript" kind
  value would produce a DIFFERENT result and FAIL the differential.
  The successor MUST bind the kind constants by their numeric value
  exactly as the live header defines them, and MUST NOT assume the
  constant names are unique. The same aliasing applies to other
  duplicated tags in `src/lexer.h` (for example `TK_SUBSCRIPT`/`TK_I64`
  and `TK_NORMALSCRIPT`/`TK_CHAR_CONST` share `0x302`/`0x303`).
- **Unknown numeric payload values**: a `TK_PUNCT` with payload 0, 1,
  -1, `INT64_MIN`, `INT64_MAX`, 999999 — all must yield 0. A `TK_KEYWORD`
  with the same values — all must yield 0.
- **Structurally valid but semantically rejected kind/value
  combinations**: e.g. `TK_PUNCT` with payload `KW_DO` (66) — a keyword
  constant appearing in the punctuation payload slot — must yield 0;
  `TK_KEYWORD` with payload `'{'` (123) must yield 0; `TK_IDENT` is
  accepted regardless of payload, so `TK_IDENT` with payload `KW_DO` must
  yield **1** (the legacy code returns 1 on `tk_type == TK_IDENT` before
  ever looking at the payload).
- **Negative payloads**: `TK_PUNCT` with payload -1 must yield 0 (the
  switch compares by exact signed equality, so a negative payload matches
  nothing).

---

## 7. Allocation, pointer ownership, error semantics

```text
allocation_ownership   = NONE.  The component allocates nothing.
                          The C caller owns every allocation.
pointer_ownership      = NONE.  No pointer crosses the boundary in either
                          direction.  The PolyC ABI takes three scalars and
                          returns one scalar.
error_semantics        = NONE.  The component never raises, never
                          longjmps, never writes to a diagnostic
                          accumulator, and never mutates the token.
                          The caller observes 0 and owns the diagnostic.
side_effects           = NONE.
determinism            = TOTAL.  The result is a pure function of
                          (token_present, token_kind, token_value).
```

### Forbidden ABI fields (must be absent)

| Field | Status |
|---|---|
| `Cctrl *` | NOT PRESENT |
| `Ast *` | NOT PRESENT |
| `Map *` | NOT PRESENT |
| `List *` | NOT PRESENT |
| `Lexeme *` | NOT PRESENT (this is the whole point of the projection) |
| `jmp_buf *` | NOT PRESENT |
| function-pointer callback table | NOT PRESENT |
| `void *` host context | NOT PRESENT |
| opaque integer encoding of a host pointer | NOT PRESENT |

`ABI_HOST_IDENTITY_FIELDS = 0`

---

## 8. Equivalence obligation

The successor MUST prove `BootstrapValidPostControlFlowToken` is
equivalent to `src/parser.c::parseValidPostControlFlowToken` by running
the **actual C function** as the reference side of a direct differential
over the fixture matrix in section 6.

A handwritten C re-implementation of the decision table is NOT an
acceptable reference (ACT SECT_11, "Legacy reference"). The reference
side must call the real production C function.

---

## 9. C-side wrapper shape (for the successor's design, NOT implemented here)

The successor will need a C-side projection. The shape below is
illustrative and is NOT part of this ACT's deliverable:

```c
/* illustrative only */
static int validPostControlFlowTokenPolyC(Lexeme *tok) {
    extern long long BootstrapValidPostControlFlowToken(
        long long present, long long kind, long long value);
    if (!tok) return (int)BootstrapValidPostControlFlowToken(0, 0, 0);
    return (int)BootstrapValidPostControlFlowToken(
        1, (long long)tok->tk_type, (long long)tok->i64);
}
```

The successor ACT decides the exact wrapper, the build switch, and the
delegation mechanism. This ACT freezes only the ABI shape and the
decision table.
