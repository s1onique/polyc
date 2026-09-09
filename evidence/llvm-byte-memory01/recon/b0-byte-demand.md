# R3 — B0 Byte Demand

## B0 mission (per ACT §0)

The B0 PolyC lexer/tokenizer is the smallest credible PolyC self-hosting
milestone. The INTOPS01 HANDOFF demonstrated that B0's scalar integer
arithmetic + control vocabulary is sufficient with the existing LLVM
backend; the only remaining gap is byte-level memory access for reading
source bytes.

## Existing B0 sketch (from INTOPS01)

`evidence/llvm-intops01/recon/b0-demand.md` defines a single-token
recognizer sketch that reads through an `I64 *src` cursor. That sketch
deliberately uses I64 reads; **the true B0 source-buffer element is a
byte**, addressed through a `U8 *src` (or `I8 *src`) pointer. The
INTOP S01 sketch is therefore I64-only as an explicit interim — the
actual B0 needs byte load + indexed addressing.

## B0 byte-level fragment (this ACT's scope)

The byte-level fragment that B0 actually requires, isolated from indexing:

```polyc
// Conceptual PolyC (B0):
//
//   c = *src;            // direct byte load (no index)
//   if (c == ' ') ...    // byte == constant comparison
//   if (c >= '0') ...    // byte range comparison
//   digit = c - '0';     // byte promotion + subtract
//   v = v * 10 + digit;  // existing scalar arithmetic
//
// All without `src + 1` or `src[i]` — that is GEP01 territory.
```

Mapped to B0 capabilities:

| B0 expression                      | required capability                              | scope       |
|------------------------------------|--------------------------------------------------|-------------|
| `c = *src` (where `src: U8 *`)    | IR_LOAD_DEREF with dst->type == IR_TYPE_I8       | BYTE-MEMORY01 |
| `c == ' '`                         | IR_ICMP on widened byte vs constant              | (already OK after widening) |
| `c >= '0'`                         | IR_ICMP on widened byte vs constant              | (already OK after widening) |
| `c - '0'`                          | IR_ISUB on widened byte (or via ZEXT/SEXT)       | (already OK after widening) |
| `v = v * 10 + digit`               | existing scalar integer arithmetic               | (already SUPPORTED per INTOPS01) |

**Key observation:** the byte comparison and arithmetic all happen
**after** the byte has been promoted to the existing scalar integer
domain via `IR_ZEXT` / `IR_SEXT`. Therefore the only **new** capability
this ACT must provide is the byte load (and potentially the byte store).

## Demand matrix (fragment level)

| B0 expression             | LLVM capability seam              | IR shape required           | in scope? |
|---------------------------|-----------------------------------|-----------------------------|-----------|
| `*src` (byte)             | `IR_LOAD_DEREF` w/ IR_TYPE_I8 dst | load i8, ptr                | YES       |
| `src[0] = x` (byte)       | `IR_STORE_DEREF` w/ IR_TYPE_I8 r1 | store i8 ..., ptr           | DEFER (B0 reads, not writes, source) |
| byte widen to I64         | `IR_ZEXT` / `IR_SEXT`             | zext i8 -> i64 / sext i8 -> i64 | DEFER (IR-level widening is already produced by `irWidenToTargetWidth`) |

## B0 write demand

The INTOPS01 sketch reads from a pointer and writes to a separate output
buffer via `STORE_DEREF` of an `I64` value (token metadata). For B0's
first milestone, **the output is not a byte buffer** — it is a scalar
field representing the parsed integer value. Therefore **byte stores are
not required for B0's first milestone**.

`BYTE_STORE_DEMAND = NO` for the read-only B0 path.
`I64_TO_BYTE_DEMAND = NO` for B0's first milestone.

## Conclusion

`B0_BYTE_DEMAND = OK`. The B0 byte-level fragment requires:

* `IR_LOAD_DEREF` with `IR_TYPE_I8` access type (THE new capability seam)
* (Implicitly) the IR builder's existing `IR_ZEXT` / `IR_SEXT` widening
  (already emitted; only need backend lowering — but see R9 below)

`GEP_REQUIRED_FOR_B0 = NO` for the read-only byte-load fragment.
