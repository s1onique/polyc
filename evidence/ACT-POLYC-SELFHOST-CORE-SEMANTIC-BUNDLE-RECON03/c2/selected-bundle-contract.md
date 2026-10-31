# The selected bundle contract

ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
Phase: C2 IMPL
Disposition: PASS_SELECTED_CORE_BUNDLE (subject to the C3 and C4 gates)

**This contract does not authorize implementation.** It freezes what a
later, separately authorized implementation ACT must build and must
re-verify. It is the successor's input, not its permission.

## 1. The bundle identity and the semantic invariant

```text
BUNDLE_ID           = CAND-CMP-CC-A64
FAMILY              = AARCH64_COMPARISON_CONDITION_CODE
MEMBER_COUNT        = 3
RANK                = 1 (of 4 eligible bundles, over 6 candidates)
NAMED_INVARIANT     = AARCH64_COMPARISON_CONDITION_CODE_AND_BOOLEAN_MATERIALISATION:
                      the same IrCmpKind family maps to one AArch64
                      condition suffix, its inverse, and the cset
                      materialisation
```

The invariant is a NAMED decision family, not a category: all three
members answer "which AArch64 condition code does this comparison
mean?", and the three answers are the true-side suffix, the false-side
(inverse) suffix, and the Boolean materialisation.

## 2. The members, their live source ranges and their causal proof

| Site | Function | Live source range | Source SHA-256 | Execution id | Witness | Pristine -> Mutated |
|------|----------|-------------------|----------------|--------------|---------|--------------------|
| SITE-A64-CC-FOR | `aarch64CcFor` | src/aarch64.c 35517..36576 | d22a99b3c85f82f12754582b63ecc0e5429b6ac3dbdff21ff2a960d4b538ccdc | EXEC-A64-CC-FOR-MUTANT | W-A64-CC-FOR | `cset x0, lt` -> `cset x0, ge`; LT_OK -> LT_BAD |
| SITE-A64-CC-INV | `aarch64CcInvFor` | src/aarch64.c 36577..37495 | 5b08df7b9752fd70d8391a300e5d6c9f943be67779f7e75102b788eec7b5d343 | EXEC-A64-CC-INV-MUTANT | W-A64-CC-INV | `b.ge` -> `b.lt`; LT_OK -> LT_BAD |
| SITE-A64-CSET | `aarch64EmitCSet` | src/aarch64.c 37566..37719 | 8a1f2573c7eeb598816edcd96830cdd695b733f6ad12c47f859ea46575cec540 | EXEC-A64-CSET-MUTANT | W-A64-CSET | `cset x0, lt`/`cset x0, gt` -> `cset x0, ne`/`cset x0, ne`; GT_OK -> GT_BAD |

All three ranges are disjoint, all three mutations were confined to
their own function's byte range, and all three source restorations
returned byte-identically to the pristine source.

## 3. The ABI

```text
ABI_NAME       = ABI-A64-CMP-CC-1
ABI_VERSION    = 1
TARGET_ABI     = aarch64 (AArch64 / Apple arm64 and Linux arm64)
                 The x86_64 backend is a DIFFERENT target ABI and is
                 NOT covered by this contract; the two-backend
                 candidate CAND-CMP-CC-BOTH was excluded for exactly
                 that reason (E16).
ENDIANNESS     = little
WORD_WIDTH     = 64
```

### The exact PolyC exports

```polyc
// The TRUE-side condition-code suffix for a comparison kind.
// Returns a borrowed, immutable string literal owned by the PolyC
// component. The host MUST NOT free it and MUST NOT write through it.
// An out-of-domain kind returns NULL: the host turns NULL into an
// explicit panic. The function is TOTAL over the domain below.
U8 *AbiA64CmpCcFor(I64 comparison_kind);

// The FALSE-side (inverse) condition-code suffix.
// Same ownership, same NULL contract, same totality.
U8 *AbiA64CmpCcInvFor(I64 comparison_kind);

// The Boolean materialisation of a comparison result.
// The comparison kind and the float flag are copied scalars; the
// suffix is the borrowed literal that AbiA64CmpCcFor returns.
// The host passes the borrowed suffix straight into its own
// formatting; the host owns the assembly buffer it writes into.
U0 AbiA64CmpCcEmitCSet(I64 comparison_kind, I64 is_float);
```

### Host projection semantics

| Aspect | Statement |
|--------|-----------|
| Input domain | `comparison_kind` is an `IrCmpKind` value: `IR_CMP_INVALID = -1`, then `EQ=0, NE=1, LT=2, LE=3, GT=4, GE=5, ULT=6, ULE=7, UGT=8, UGE=9, OEQ=10, ONE=11, OLT=12, OLE=13, OGT=14, OGE=15, UNO=16, ORD=17`. |
| Status domain | The return value is a POINTER, never a numeric status. A NULL return is the ONLY failure signal. **A negative numeric status is never used**, so a legitimate zero discriminant (`IR_CMP_EQ == 0`, and `IR_TYPE_VOID == 0` in the type domain) can never be confused with a failure. |
| Data domain | The returned suffix is one of the closed set `eq, ne, lt, le, gt, ge, lo, ls, hi, hs` (integer) or `eq, ne, mi, ls, gt, ge` (float). The suffix is a **borrowed** immutable literal. |
| Zero handling | `IR_CMP_EQ` is the ZERO of `IrCmpKind` and it is a legitimate, live input: the table maps it to `eq`. A status/data separation that used zero as a failure marker would therefore collide with it, which is exactly why the failure signal is a NULL pointer and not a number. |
| Unknown input | An out-of-domain kind returns NULL; the host turns NULL into an explicit `loggerPanic`. The functions are TOTAL: they never read out of bounds and never loop. |
| Float domain | `is_float` selects the float sub-table. The float table has NO entries for the ordered/unordered kinds (`OEQ..ORD`): those are not reachable from the current float lowering, and their absence is an explicit panic, not a silent default. |
| Ownership | No allocation crosses the seam. The suffix is a static literal; the host borrows it for the duration of one formatting call. The host's assembly buffer is owned by the host. |
| Aliasing | The suffix is not writable through the returned pointer; there is no aliasing between the PolyC side and the host's buffer. |
| Callback surface | NONE. No function pointer, no callback table, no `void*` crosses the seam. |
| Recovery crossing | NONE. No site performs a `setjmp`/`longjmp`, no unbounded recursive recovery transfer, no exception-like escape. The panic is a host process termination, not a cross-seam escape. |
| Mutable host state | NONE. No site writes mutable host or global state; the only host buffer written is the host's own assembly buffer, and the write is sequenced by the host. |
| Double evaluation | NONE. Each site's arguments are copied scalars, evaluated once. |

### The load-bearing selector behaviour

The successor MUST keep the same selector discipline as the current
production build: the component is compiled by the REAL production
`./hcc`, linked into the production `./hcc`, and the selector-ON
configuration is the only configuration in which the component is
authoritative. A selector-OFF build MUST keep the legacy C bodies as
an honest, independent C oracle for the differential comparison.

## 4. The producer chain

```text
G0  /usr/bin/gcc
    46 C translation units -> build/host-stage0/hcc
    (the host C compiler; the stage0 compiler is isolated in
     build/host-stage0/ so that building it never overwrites the
     production ./hcc)

G0  build/host-stage0/hcc
    tools/bootstrap/<new-component>.HC  ->  build/<new-subject>.o
    (the PolyC component is compiled BY the stage0 compiler)

G1  the G0 subject, compiled by build/host-stage0/hcc, must produce a
    BYTE-IDENTICAL subject object to the G0 subject. The three
    independently identified compiler binary digests required of the
    successor are:
      - the stage0 compiler's own digest,
      - the production ./hcc's digest,
      - the G1 compiler's digest.

G2  the G1 compiler must produce a byte-identical subject object to
    the G0 subject.

G3  the G2 compiler must produce a byte-identical subject object to
    the G0 subject.
```

**Twelve ordered differential comparisons are REQUIRED of the
successor.** They are NOT executed by this ACT, and this ACT does not
claim they pass. The required set is:

```text
 1. G0 subject  == G1 subject   (byte identity of the .o)
 2. G0 subject  == G2 subject
 3. G0 subject  == G3 subject
 4. G1 compiler produces the same assembly as G0 on the G0 fixture set
 5. G2 compiler produces the same assembly as G0 on the G0 fixture set
 6. G3 compiler produces the same assembly as G0 on the G0 fixture set
 7. G1 compiler produces the same OBJECT as G0 on the G0 fixture set
 8. G2 compiler produces the same OBJECT as G0 on the G0 fixture set
 9. G3 compiler produces the same OBJECT as G0 on the G0 fixture set
10. G1..G3 executables produce the same PROGRAM OUTPUT as G0
11. G1..G3 executables produce the same EXIT STATUS as G0
12. the legacy C oracle (selector-OFF) and the PolyC subject agree
    on every fixture case
```

## 5. The fixture specification

The fixture domain is derived from the LIVE source, not invented:

```text
FIXTURE_INPUT_DOMAIN = IrCmpKind (18 named values, including
                       IR_CMP_INVALID = -1 and the implicit-zero
                       IR_CMP_EQ = 0)
                     x is_float in {0, 1}
                     x the compiler's own comparison contexts
```

Required partitions:

| Partition | Content |
|-----------|---------|
| VALID | every named `IrCmpKind` in the signed-integer domain, and in the float domain |
| INVALID | `IR_CMP_INVALID` (-1) and every value outside the enum's range |
| BOUNDARY | `IR_CMP_EQ` (the implicit zero), `IR_CMP_EQ - 1`, `IR_CMP_ORD` (the maximum) and `IR_CMP_ORD + 1` |
| FALLBACK | the out-of-domain kind, which must produce the explicit panic rather than a silent default |
| ZERO-DISCRIMINANT | `IR_CMP_EQ` used as a discriminant, to prove that the zero is a legitimate live value and that the NULL failure signal does not collide with it |

An **independent source parser** must parse the fixture specification
from the live `src/ir-types.h`; the fixture generator must not be
allowed to share the table under test.

## 6. The per-site post-migration checks the successor MUST perform

For EACH of the three members:

- a **post-migration PolyC mutation** of the migrated decision, which
  must reproduce the SAME discriminating witness transition that this
  ACT's C mutation produced (the witness and the expected transition
  are recorded above, per site);
- a **legacy C-dormancy anti-control**: the legacy C body must be
  shown to be DORMANT (not called) in the selector-ON production
  build, so that the PolyC component is genuinely authoritative and the
  legacy body is not silently doing the work.

## 7. The permitted production paths and the build prerequisites

```text
PERMITTED_SOURCE_PATHS  = tools/bootstrap/<new-component>.HC   (new)
                           src/aarch64.c                        (modified:
                           the three sites are replaced by calls into
                           the component)
                           src/CMakeLists.txt                   (the
                           component's object is added to the link)
                           Makefile                              (the
                           component's subject rule is added)

FORBIDDEN                = src/x86_64.c (a different target ABI)
                           src/asm/**   (the libtasm assembler backend)
                           the canonical gates
```

**Fail-closed build prerequisites:**

- The component's subject object MUST exist and MUST export the
  expected symbols BEFORE the production `./hcc` is linked. A missing
  symbol MUST fail the link, not silently fall back to the C body.
- The component's `.o` MUST be a prerequisite of the production
  `./hcc` in the Makefile, and the Makefile MUST expand that
  prerequisite list at rule-read time. A late-defined variable can
  silently drop the subject from the build graph, which is a known
  failure mode in this repository.
- The production link MUST verify the component's symbol is present,
  in the same way the existing nine parser authorities are verified.
- **The `/tmp/holyc-asm.s` collision is OPEN.** The compiler writes a
  FIXED shared scratch path, so concurrent compiler invocations race.
  Until that is fixed by a separately authorized ACT, every build,
  every fixture run and every differential comparison MUST be
  SERIALIZED. A successor that runs the compiler in parallel will
  produce spurious failures.

## 8. The workload estimate, the blockers and the graph impact

```text
ESTIMATED_WORKLOAD = BASE
  Rationale: three sites in ONE translation unit, one new PolyC
  component of about three small functions, one new build rule, one
  new link entry, one symbol verification, a fixture generator and
  twelve ordered differential comparisons. The three sites share one
  header-free enum domain and one string-literal output type, so the
  ABI is small and there is no layout or ownership negotiation.

REMAINING_BLOCKERS =
  - the /tmp/holyc-asm.s shared-scratch race is OPEN and must be
    worked around by serialisation until it is fixed;
  - the parallel `make -j` object race is OPEN;
  - F-POLYC-TOOLS has no landed authoritative checker;
  - the ARM64 indexed-byte-load defect is OPEN and is not in this
    bundle's path;
  - the historical M-POLYC-RO misattribution is a CLOSED historical
    record and is NOT re-opened by this bundle.

GRAPH_IMPACT = POTENTIAL_ONLY
  The three sites are the source witnesses of 3 production graph
  edges (recorded in c1/core-dependencies.tsv as POT-CG-A64CC*). The
  number 3 is a POTENTIAL reduction. NO CUT IS PROVEN. The edge
  E-MUT-0137 remains UNSUPPORTED_WITNESS and is not weighted.

M1_IMPACT = REAL AND DEMONSTRATED
  The three sites are C-authoritative compiler-core semantic
  decisions today, and each has been shown by a physical C-source
  mutation to change the emitted assembly and the compiled program's
  behaviour. Migrating them is genuine M1 progress.

M2_IMPACT = NOT DEMONSTRATED
  The M2 producer is ABSENT in this tree: no PolyC-authored compiler
  source set exists, so the first genuinely self-compiled compiler
  generation cannot be produced yet. No critical-path percentage is
  claimed, because there is no measured path to attach it to.

SELFHOST_M2_ACHIEVED = NO
SLICE10_AUTHORIZED = NO
```

## 9. What the successor must re-verify

The successor may not assume anything in this contract that it has not
re-measured. In particular it must re-verify: the source ranges and
digests of the three sites; the ABI's status/data separation against
the LIVE enum domain (including the implicit zeros); the C oracle's
presence and dormancy; the four generator identities; the twelve
ordered differential comparisons; and the F14 freeze of every path this
ACT added.

## 10. The hashes this contract freezes

```text
CONTRACT_SHA256     = adcbcab6a4d2f41a9ecfc86c247bfce8d289bd38bf0c95655559b83adafb708b
```

The successor MUST bind to this contract's SHA-256 and to the three
member source digests above, and MUST re-derive the three member
ranges from the live source rather than trusting the ranges recorded
here.
