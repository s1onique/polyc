# C1 — ABI v1.1 compatibility and production ownership

RECON01's v1 contract
(`evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/abi-contract-v1.md`) is
**immutable historical evidence** and is not edited by this ACT. This
document states only what the production consumer needs on top of it.

## 1. What is reused unchanged from v1

```text
representation      one opaque 64-bit value; never a pointer, never dereferenced
field layout (host) bits 0..7 magic 0x5A | 8..15 domain | 16..31 generation
                    | 32..39 kind | 40..47 slot+1 | 48..63 reserved 0xC0DE
host validation     magic, reserved, index range, domain, token kind, slot kind,
                    liveness, generation, and (for AST) the arena epoch, ALL
                    before any dereference
ownership           C owns every object; PolyC receives OPAQUE_BORROW only
mutation            borrowed state is read-only; no mutation capability is exposed
recovery            no setjmp/longjmp across a live PolyC frame
calling convention  Apple ARM64 C ABI, every parameter and return is I64
```

## 2. The v1.1 delta (additive, carried into production)

Exactly two additions, both required by the frozen ABI-safety gates:

| id | delta | reason |
|----|-------|--------|
| D1 | **Fail-closed generation retirement.** v1 wrapped the 16-bit generation with `if (generation == 0) generation = 1;`, which can alias a very old identity. v1.1 sets `retired = 1` instead of wrapping, and issue / lookup / retire all report `-17 ABI_SLOT_RETIRED`. | PD-18, AC21 |
| D2 | **Two additional negative statuses** `-16 ABI_TOKEN_DOMAIN_EXHAUSTED` and `-17 ABI_SLOT_RETIRED`. | PD-18, PD-19 |

No v1 function signature changes. No v1 status value changes. No field of
the handle encoding changes. v1.1 is therefore a strict superset: a v1
consumer still works, and RECON01's contract text remains true of the
subset it describes.

## 3. The selected surface (narrowest possible)

```text
I64 AbiCpaIssueAst(void *ast);        /* mechanical: C -> guarded handle */
I64 AbiCpaAstKind(I64 ast);           /* PolyC -> C: 256..299, or negative status */
I64 AbiCpaShouldPrintAst(I64 ast);    /* COMPILED POLYC: 0 | 1 | negative status */
void AbiCpaRetireAst(I64 ast);        /* mechanical: invalidate the slot */
I64 AbiAbiVersion(void);              /* 1 */
```

Target triple: `arm64-apple-darwin` (measured: `./hcc --version` reports
`arch: aarch64-apple-darwin`; `uname -m` is `arm64`).

## 4. Measured ABI facts on the real target

```text
sizeof(I64) = 8            (an I64 value round-trips 64 bits)
sizeof(Bool) = 1           -> Bool is NEVER used across the boundary
argument passing           every parameter is one 64-bit register (x0..x7)
                           because every parameter is I64
return value               x0, 64 bits
int -> I64 widening        `(I64)ast->kind` sign-extends; all valid AstKind
                           values are 256..299, so sign and zero extension
                           agree and the result is unambiguously positive
symbol decoration          Mach-O C symbols carry one leading underscore:
                           `_AbiCpaShouldPrintAst` (measured with nm)
```

## 5. Signed-result analysis (AC20)

```text
AbiCpaAstKind       : { 256 .. 299 }  U  { -17 .. -1 }     DISJOINT
AbiCpaShouldPrintAst: { 0, 1 }        U  { -17 .. -1 }     DISJOINT
```

No valid payload can be misread as an error and no error can be misread as
a payload, **for this operation**. This is a property of the *selected*
interface, not of v1 in general: `AbiListAt` in RECON01 can legitimately
return a negative list value, which is exactly why this ACT does not put a
signed list payload across the boundary.

## 6. Token sign (AC20, PD-16)

A valid handle encodes `0xC0DE` in bits 48..63, so **as a signed I64 it is
negative**. Therefore:

```text
handle < 0      -> NOT a validity test; a VALID handle IS negative
handle >= 0     -> NOT a validity test; an INVALID handle may be anything
validity        -> established ONLY by the host lookup path
```

The C host and the compiled PolyC subject therefore never sign-test a
handle. The PolyC subject sign-tests only the *result* of
`AbiCpaAstKind`, whose domain is provably disjoint from the negative
status range.

## 7. Ownership, lifetime and recovery (AC18, AC21, AC22, AC23)

```text
owner                C (src/compile.c + src/abi-cpa-host.c)
borrow               one node at a time; issue -> decide -> retire, per node
retire on error      the token is retired on EVERY path, including a
                     negative status from the host
arena lifetime       the AST arena epoch is validated by the host before any
                     dereference; a stale-epoch token is rejected with
                     -8 ABI_EXPIRED_BORROW_OR_ARENA
mutation capability  NONE. The production host exposes no write path at all.
                     There is no append/list-mutate entry point, so the
                     "append without mutation capability" control of the
                     predecessor has no production analogue to abuse.
callback retention   NONE. The PolyC subject is a pure function of one I64.
cross-frame recovery NONE. The host sets no longjmp target across a PolyC
                     frame; the PolyC subject contains no setjmp/longjmp.
slot table           bounded (64 slots in the frozen shadow host); a slot is
                     reused only after retirement, and its generation counter
                     is incremented so a stale token cannot alias a new one.
                     On generation exhaustion the slot is RETIRED and the
                     call fails closed with -17.
exhaustion policy    fail closed with an explicit bounded error. The host
                     NEVER silently skips a node and NEVER silently prints
                     one; a refusal is surfaced, not swallowed.
```

## 8. What v1.1 still does NOT claim

```text
- no second semantic decision is migrated;
- no AST ownership moves into PolyC: the raw Ast* never crosses the
  boundary, only an opaque I64 token;
- no List / Map / AoStr / Cctrl / Arena handle;
- no callback retention;
- no recovery across a PolyC frame;
- no portability: arm64-apple-darwin only;
- no production migration of any other consumer;
- no M2 self-hosting claim.
```
