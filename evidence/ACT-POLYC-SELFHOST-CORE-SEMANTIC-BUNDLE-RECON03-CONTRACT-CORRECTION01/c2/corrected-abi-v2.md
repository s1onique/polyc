# The corrected AArch64 comparison-condition-code ABI

ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01
Phase: C2 IMPL
ABI version: **ABI-A64-CMP-CC-2**
Disposition: PASS_CORRECTED_TWO_PLUS_ADAPTER (subject to the C3 and C4 gates)

**This document does not authorize implementation.** It freezes what a
later, separately authorized implementation ACT must build and must
re-verify. It is the successor's input, not its permission.

It SUPERSEDES the authorization to implement using ABI-A64-CMP-CC-1
**only**. It does not supersede, rewrite or reinterpret RECON03's
historical verdict, its original text, or IMPLEMENT02's historical
HALT.

## 1. Why v1 could not be implemented

ABI-A64-CMP-CC-1 declared three exports:

```
U8 *AbiA64CmpCcFor(I64 comparison_kind);
U8 *AbiA64CmpCcInvFor(I64 comparison_kind);
U0  AbiA64CmpCcEmitCSet(I64 comparison_kind, I64 is_float);
```

Two defects were measured by IMPLEMENT02 and are binding here:

1. **The third export has no observable output channel.** Its
   parameters are two copied scalars, its return type is `U0`, and the
   frozen contract forbade a callback, a global write, an
   assembly-buffer pointer and turning the return into a suffix
   pointer. A suffix choice cannot be transported. **This ACT does not
   reopen that result.** The third export is REMOVED, not repaired.

2. **The source-range/digest table was internally inconsistent.** The
   C1 record and the C2 contract paired the same digest with two
   different byte ranges, and neither C2 range hashed to the digest
   the contract claimed. **This ACT does not repair the historical
   text.** It supplies a new, separately generated table.

A third defect was found by THIS ACT and is the reason the authority
count is two rather than three:

3. **The third export was also semantically unnecessary.** The C site
   it would have carried, `aarch64EmitCSet`, contains no condition
   selection of its own. Its whole 152-byte definition is one call to
   `aarch64CcFor` plus a fixed format string. It is a **C-OWNED
   MECHANICAL ADAPTER**, not a semantic authority.

## 2. The corrected exports

```c
/* ABI-A64-CMP-CC-2 -- the TRUE-side condition-code suffix.
 *
 * comparison_kind is an IrCmpKind value.
 * is_float is 0 for the integer table and 1 for the float table.
 *
 * Returns a BORROWED, IMMUTABLE, NUL-TERMINATED string literal owned
 * by the PolyC component. The host MUST NOT free it and MUST NOT
 * write through it.
 *
 * Returns NULL for every out-of-domain combination. NULL is a FAIL
 * CLOSED signal; it is a POINTER status, never a numeric status, so
 * it can never collide with the IR_CMP_EQ == 0 discriminant.
 */
const unsigned char *AbiA64CcForV2(int64_t comparison_kind, int64_t is_float);

/* ABI-A64-CMP-CC-2 -- the FALSE-side (inverse) condition-code suffix.
 * Same ownership, same NULL contract, same totality.
 */
const unsigned char *AbiA64CcInvForV2(int64_t comparison_kind, int64_t is_float);
```

**There is NO third export.** Under the TWO_PLUS_ADAPTER disposition
the CSET emitter stays in C and obtains its condition suffix through
the FOR export. A third export would be an invented authority, and
the ACT forbids inventing one.

### The exact link/export spelling

The PolyC component defines `AbiA64CcForV2` and `AbiA64CcInvForV2`;
the C host declares them with the leading underscore that the Mach-O
ABI requires, so the linked symbol is `_AbiA64CcForV2` and
`_AbiA64CcInvForV2`. This spelling was **verified in the compiled
object**, not assumed.

## 3. The input domain

The domain is derived from the LIVE `src/ir-types.h` by an independent
parser: 19 enumerators, `IR_CMP_INVALID = -1`, `IR_CMP_EQ = 0`,
`IR_CMP_NE = 1` ... `IR_CMP_ORD = 17`.

| Partition | Kinds | FOR (integer) | FOR (float) | INV (integer) | INV (float) |
|---|---|---|---|---|---|
| Integer, signed | EQ NE LT LE GT GE | eq ne lt le gt ge | mi ls gt ge | ne eq ge gt le lt | ne eq pl hi le lt |
| Integer, unsigned | ULT ULE UGT UGE | lo ls hi hs | **none** | hs hi ls lo | **none** |
| Float, ordered/unordered | OEQ ONE OLT OLE OGT OGE UNO ORD | **none** | **none** | **none** | **none** |
| Invalid | IR_CMP_INVALID (-1) | **none** | **none** | **none** | **none** |

Every "none" is a **NULL, fail closed** result. There is **no default
condition suffix on an unknown kind** in either table.

The eight ordered/unordered kinds have no suffix in EITHER switch in
the LIVE source. This was verified against the live bytes, not
inherited as a claim.

## 4. Ownership, lifetime and the host's retained operations

The PolyC component owns exactly one thing: the mapping from
`(comparison_kind, is_float)` to a condition suffix, and the choice
of the true-side versus the inverse-side table.

The **host retains**, unchanged:

- `IrCgCtx` construction and lifetime;
- the `AoStr` assembly buffer;
- `aoStrCatFmt` formatting and the fixed `"cset    x0, %s\n\t"` literal;
- the `cset` instruction selection (the emitter stays in C);
- register names (`x0`, `x1`, ...);
- emission sequencing;
- diagnostics (`loggerPanic` and friends);
- allocation and recovery;
- process termination on a panic.

**No opaque mutable state crosses the seam.** No pointer to mutable
IR or AST state crosses the seam. The only value that crosses is an
immutable borrowed string literal.

The returned literal is a **static** string literal in the PolyC
component's data. It is NUL-terminated, its content is stable for
the lifetime of the process, it is never allocated, and it is never
freed or written by the host.

## 5. The CSET site stays C-mechanical

Under the TWO_PLUS_ADAPTER disposition:

```c
/* The host keeps the emitter. Only the SUFFIX comes from PolyC. */
static void aarch64EmitCSet(IrCgCtx *ctx, IrCmpKind cmp, int is_float) {
    aoStrCatFmt(ctx->buf, "cset    x0, %s\n\t",
                AbiA64CcForV2((int64_t)cmp, (int64_t)is_float));
}
```

The C site is **preserved** and its call to the condition decision is
preserved. What changes is only WHICH implementation supplies the
suffix: the C table becomes the PolyC table. The number of semantic
authorities in the bundle is **two**, not three.

This is a legitimate correction, not a partial implementation: the
impossible third export is REMOVED from the ABI and from the scope,
and no authority is invented to replace it.

## 6. Target and calling convention

- Target: **aarch64** (AArch64 / Apple arm64 and Linux arm64).
- The x86_64 backend is a DIFFERENT target ABI and is NOT covered.
- The AArch64 **Darwin** calling convention is used, proven from the
  actual C header declarations, the compiled object symbols and the
  real calls. This contract does **not** call it "generic SysV".

The prototype was compiled with the production `./hcc` for
`--target=aarch64-apple-darwin` and produced a Mach-O 64-bit arm64
object exporting `_AbiA64CcForV2` and `_AbiA64CcInvForV2`.

## 7. The suffixes assemble

All twelve condition suffixes were checked against the real AArch64
assembler:

```
eq ne lt le gt ge lo ls hi hs mi pl    -> all assemble
xx                                      -> rejected: "invalid condition code"
```

`CSET` is an alias of `CSINC`; the condition code selects between 0
and 1 materialisation, and the condition inversion at the instruction
encoding is accounted for by the fact that the FOR table supplies the
TRUE side and the INV table supplies the FALSE side, exactly as the
original C tables did.

## 8. The producer obligation

The future implementation ACT must satisfy, independently:

1. one genuine **selector-OFF C production oracle**, verified to
   import NO PolyC subject symbol;
2. three **pairwise-distinct** PolyC subject producers (distinct
   executable digests);
3. four separately observed semantic result streams;
4. all **12 ordered stream comparisons** (PAIR-01..12);
5. all **12 heterogeneous invariants** (FROZEN-01..12), tracked as a
   DIFFERENT roster -- a count of 12 in one roster NEVER discharges
   the other;
6. one post-migration causal experiment **per actual authority**, that
   is **two**, not three;
7. the legacy C body shown **DORMANT** in the selector-ON build for
   each migrated authority.

The producer identities are named unambiguously as `C_TOOLCHAIN` and
`POLYC_PRODUCER_1..5`, with an explicit crosswalk away from the
predecessor's self-referential `G0`/`G1`/`G2`/`G3` labels, which
assigned the label `G0` to two different executables.

## 9. The target after a future PASS

```
PRODUCTION_AUTHORITIES_BEFORE     = 13
FUTURE_NEW_POLYC_AUTHORITIES      = 2   (FOR and INV)
FUTURE_TOTAL_AUTHORITIES_AFTER    = 15
NEW_PRODUCTION_AUTHORITIES_BY_THIS_ACT = 0
NEW_PROVEN_GRAPH_CUTS_BY_THIS_ACT      = 0
```

This ACT itself adds **no** production authority, **no** production
subject, **no** selector and **no** graph cut.
