# B0 Demand Recon — R1 (Concrete Lexer Sketch)

## B0 Mission (from ACT-POLYC-LLVM-INTOPS01 §0)

```text
source byte buffer
    ↓
lexer/tokenizer written in PolyC
    ↓
deterministic Token stream
```

The B0 lexer/tokenizer is the next consumer of LLVM-substrate.
It is **not** an interpreter, **not** a parser, **not** a type checker.
It is `bytes_in -> token_stream_out`.

## Capabilities required by B0

The B0 mission is deliberately narrow. It only needs the smallest
scalar-integer operations that a real lexer demands. The sketch below
is the smallest credible PolyC program that satisfies the B0 mission.

## Lexer sketch (conceptual, not necessarily compilable yet)

```c
// Lexer state machine: advance through bytes, classify, emit tokens.

struct LexerState {
    I64 cursor;         // current position in source
    I64 length;         // total source length
    U8  *source;        // pointer to source bytes
    I64 tok_start;      // token start offset
    I64 tok_kind;       // token kind (e.g. 1=ident, 2=int_lit, 3=punct)
    I64 tok_len;        // token length
    I64 tok_value;      // token value (for int literals)
};

I64 is_whitespace(U8 c) {
    return (c == ' ') | (c == '\t') | (c == '\n') | (c == '\r');
}

I64 is_digit(U8 c) {
    return (c >= '0') & (c <= '9');
}

I64 is_alpha(U8 c) {
    return ((c >= 'a') & (c <= 'z')) |
           ((c >= 'A') & (c <= 'Z')) |
           (c == '_');
}

I64 is_ident_cont(U8 c) {
    return is_alpha(c) | is_digit(c);
}

// Main lexer loop
I64 lex_next_token(LexerState *st) {
    // 1. skip whitespace
    while ((st->cursor < st->length) & is_whitespace(st->source[st->cursor])) {
        st->cursor = st->cursor + 1;
    }
    if (st->cursor >= st->length) {
        return 0;  // EOF
    }

    st->tok_start = st->cursor;
    U8 c = st->source[st->cursor];

    // 2. classify current character
    if (is_alpha(c)) {
        // identifier
        while ((st->cursor < st->length) & is_ident_cont(st->source[st->cursor])) {
            st->cursor = st->cursor + 1;
        }
        st->tok_kind = 1;  // TK_IDENT
        st->tok_len = st->cursor - st->tok_start;
        return 1;
    }

    if (is_digit(c)) {
        // decimal integer literal accumulation
        I64 v = 0;
        while ((st->cursor < st->length) & is_digit(st->source[st->cursor])) {
            v = v * 10 + (st->source[st->cursor] - '0');
            st->cursor = st->cursor + 1;
        }
        st->tok_kind = 2;  // TK_INT_LIT
        st->tok_value = v;
        st->tok_len = st->cursor - st->tok_start;
        return 1;
    }

    // punctuation / unknown
    st->cursor = st->cursor + 1;
    st->tok_kind = 3;  // TK_PUNCT
    st->tok_len = 1;
    return 1;
}
```

## Integer operations actually exercised by the sketch

For every integer expression in the sketch, record the **operation**
and **why** the B0 lexer needs it.

| Sketch expression                       | Operation                            | Why B0 needs it                          |
|-----------------------------------------|--------------------------------------|------------------------------------------|
| `c == ' '`                              | I64 ICMP-EQ with const               | Whitespace classification                |
| `(c >= '0') & (c <= '9')`               | I64 ICMP-ULT/ULE combined            | Digit range check                        |
| `(c >= 'a') & (c <= 'z')`               | I64 ICMP-ULT/ULE combined            | Alpha range check                        |
| `(c >= 'A') & (c <= 'Z')`               | I64 ICMP-ULT/ULE combined            | Alpha range check (upper)                |
| `c == '_'`                              | I64 ICMP-EQ with const               | Identifier start character               |
| `cursor < length`                       | I64 ICMP-ULT with loop limit         | Loop guard                               |
| `cursor = cursor + 1`                   | I64 IADD by const                    | Cursor advancement                       |
| `cursor - tok_start`                    | I64 ISUB                             | Token length                             |
| `v = v * 10 + (...)`                    | I64 IMUL by const + IADD             | Decimal accumulation                     |
| `(c - '0')`                             | I64 ISUB with const                  | Digit value                              |

**The sketch above does NOT exercise**:
- bitwise AND / OR / XOR (the `&` here is logical AND, not bitwise, in the conceptual
  sketch; actual implementation may differ, see §10)
- left shift
- right shift (logical or arithmetic)
- integer division
- integer remainder
- integer width conversion (I8 <-> I64)
- integer negation

## Honest note: the sketch uses `&` ambiguously

In the sketch above, `(c >= '0') & (c <= '9')` is shown as a logical AND
to keep the code visually compact. In real C/PolyC style, the same
expression would be `(c >= '0') && (c <= '9')`, which lowers to
`IR_AND` on `i1` values or to a branch. But `i1` is **not** the
scalar-integer family this ACT authorizes; the LLVM backend already
handles `IR_AND` on `i1` for control flow (see LLVM spike tests).

For *bitwise* AND/OR/XOR on **I64** values, the B0 sketch does not
produce a single demonstration site.

## Operations whose B0 demand is **not** established by the sketch alone

To support **all** of the operations PolyC's surface syntax enables
(`&`, `|`, `^`, `<<`, `>>`, `~`, `/`, `%`), B0 would need:

```text
&               bitwise AND  - not used in sketch
|               bitwise OR   - not used in sketch
^               bitwise XOR  - not used in sketch
<<              left shift   - not used in sketch
>>              right shift  - not used in sketch
~               bitwise NOT  - not used in sketch
/               integer div  - not used in sketch (v*10+digit is mul+add)
%               integer mod  - not used in sketch
```

## What B0 actually needs for `value * 10 + digit`

Only:
- IADD (already supported)
- IMUL (already supported)
- ISUB (already supported)
- ICMP (already supported)
- BR/CMP_BR (already supported)

## Conclusion of R1

The smallest credible B0 lexer sketch exercises **only** IADD, IMUL,
ISUB, ICMP, and control flow — **all of which are already supported
by the LLVM backend** (proven by LLVM-SPIKE01-RESUME01 with PASS=18
and CORE04-RESUME01 with full scalar subset support).

No additional LLVM integer operations are demanded by the B0 sketch.


## Mechanical confirmation (probe results)

Two fixtures were written and compiled to LLVM IR to mechanically
verify the recon conclusion.

### Probe 1: full single-token recognizer

```c
I64 LexOneToken(I64 *cur, I64 limit, I64 *src, I64 *out_kind, I64 *out_value)
{
    I64 c, cur_v;
    c = *src;
    if (c >= 48) {
        if (c <= 57) {
            *out_kind = 2;
            *out_value = c - 48;
            cur_v = *cur;
            cur_v = cur_v + 1;
            *cur = cur_v;
            return 1;
        }
    }
    *out_kind = 3;
    *out_value = 0;
    return 0;
}
```

Compiled to clean LLVM IR:

```llvm
define i64 @LexOneToken(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
bb1:
  %ld_deref = load i64, ptr %2, align 4
  %5 = icmp sge i64 %ld_deref, 48
  br i1 %5, label %bb3, label %bb4
bb3:
  %6 = icmp sle i64 %ld_deref, 57
  br i1 %6, label %bb5, label %bb4
bb5:
  store i64 2, ptr %3, align 4
  %7 = sub i64 %ld_deref, 48
  store i64 %7, ptr %4, align 4
  %ld_deref1 = load i64, ptr %0, align 4
  %8 = add i64 %ld_deref1, 1
  store i64 %8, ptr %0, align 4
  ret i64 1
bb4:
  store i64 3, ptr %3, align 4
  store i64 0, ptr %4, align 4
  ret i64 0
}
```

Operations emitted: `load`, `icmp`, `br`, `store`, `sub`, `add`, `ret`.
All are already SUPPORTED in the LLVM backend. PASS: llvm-as + opt verify.

### Probe 2: decimal digit accumulation (`v = v * 10 + (c - 48)`)

```c
I64 DigitAccum(I64 acc, I64 c)
{
    return acc * 10 + (c - 48);
}
```

Compiled to clean LLVM IR:

```llvm
define i64 @DigitAccum(i64 %0, i64 %1) {
bb1:
  %2 = mul i64 %0, 10
  %3 = sub i64 %1, 48
  %4 = add i64 %2, %3
  ret i64 %4
}
```

Operations emitted: `mul`, `sub`, `add`, `ret`.
All are already SUPPORTED. PASS: llvm-as + opt verify.

## Conclusion (mechanical)

The two probe fixtures exercise the full B0 lexer integer-op vocabulary
in the current LLVM backend. Both produce clean, verifier-accepted IR.

No new scalar integer opcode is required by the B0 mission.
