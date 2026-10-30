# C1 — ABI v1 compatibility and the (narrow) v1.1 delta

RECON01's v1 contract (`evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/abi-contract-v1.md`)
is **immutable historical evidence** and is not edited by this ACT. This
document states only what the shadow consumer needs on top of it.

## 1. What is reused unchanged from v1

```text
representation      one opaque 64-bit value; never a pointer, never dereferenced
field layout (host) bits 0..7 magic 0x5A | 8..15 domain | 16..31 generation
                    | 32..39 kind | 40..47 slot+1 | 48..63 reserved 0xC0DE
host validation     magic, reserved, index range, domain, token kind, slot kind,
                    liveness, generation, and (for AST) the arena epoch, ALL
                    before any dereference
ownership           C owns every object; PolyC receives OPAQUE_BORROW only
mutation            borrowed state is read-only unless the host grants capability
recovery            no setjmp/longjmp across a live PolyC frame
calling convention  Apple ARM64 C ABI, every parameter and return is I64
```

## 2. The v1.1 delta (additive, experimental, non-production)

Exactly two additions, both required by the frozen C1 ABI-safety gates:

| id | delta | reason |
|----|-------|--------|
| D1 | **Fail-closed generation retirement.** v1 wrapped the 16-bit generation with `if (generation == 0) generation = 1;`, which can alias a very old identity. v1.1 sets `retired = 1` instead of wrapping, and `Register()` / `Lookup()` / `AbiRelease()` all report `-17 ABI_SLOT_RETIRED`. | AI-15 / AC22 |
| D2 | **Two additional negative statuses** `-16 ABI_TOKEN_DOMAIN_EXHAUSTED` and `-17 ABI_SLOT_RETIRED`, plus the fixture-only accelerated near-wrap hook `AbiHostSetGeneration`. | AI-15, AI-16 |

No v1 function signature changes. No v1 status value changes. No field of the
handle encoding changes. v1.1 is therefore a strict superset: a v1 consumer
still works, and RECON01's contract text remains true of the subset it
describes.

## 3. The selected surface (narrowest possible)

```text
I64 AbiCpaIssueAst(void *ast);        /* fixture/mechanical: C -> guarded handle */
I64 AbiCpaAstKind(I64 ast);           /* PolyC -> C: 256..299, or negative status */
I64 AbiCpaShouldPrintAst(I64 ast);    /* COMPILED POLYC: 0 | 1 | negative status */
void AbiCpaRetireAst(I64 ast);        /* mechanical: invalidate the slot */
I64 AbiAbiVersion(void);              /* 1 */
```

Target triple: `arm64-apple-darwin` (measured: `./hcc --version` reports
`arch: aarch64-apple-darwin`; `uname -m` is `arm64`; macOS 14.7.4).

## 4. Measured ABI facts on the real target

```text
sizeof(I64) = 8            (c0 probe: I64 values round-trip 64 bits)
sizeof(Bool) = 1           -> Bool is NEVER used across the boundary
argument passing           every parameter is one 64-bit register (x0..x7)
                           because every parameter is I64
return value               x0, 64 bits
int -> I64 widening        `(I64)ast->kind` sign-extends; all valid AstKind
                           values are 256..299, so sign and zero extension agree
                           and the result is unambiguously positive
symbol decoration          Mach-O C symbols carry one leading underscore:
                           `_AbiCpaShouldPrintAst` (measured with nm in C0/C2)
```

## 5. Signed-result analysis (AC23)

```text
AbiCpaAstKind       : { 256 .. 299 }  U  { -17 .. -1 }     DISJOINT
AbiCpaShouldPrintAst: { 0, 1 }        U  { -17 .. -1 }     DISJOINT
```

No valid payload can be misread as an error and no error can be misread as a
payload, **for this operation**. This is a property of the *selected* interface,
not of v1 in general: `AbiListAt` in RECON01 can legitimately return a negative
list value, which is exactly why this ACT does not put a signed list payload
across the boundary. See `token-saturation-and-signed-results-plan.md`.

## 6. What v1.1 still does NOT claim

```text
- no production consumer is migrated;
- no arbitrary capacity: the slot table is 4 entries in the probe and 64 in
  the shadow host, both bounded and documented;
- no portability: arm64-apple-darwin only;
- no Map / AoStr / Cctrl / Arena handle;
- no callback retention;
- no recovery across a PolyC frame.
```
