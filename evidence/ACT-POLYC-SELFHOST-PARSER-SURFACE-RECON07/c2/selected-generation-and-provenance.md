# SELECTED GENERATION AND PROVENANCE PLAN

## WHAT IS EXECUTED AND WHAT IS NOT

```text
FUTURE_G1_G2_G3_EXECUTED=NO
FUTURE_G1_G2_G3_FEASIBILITY=PROVEN
```

**THIS ACT DID NOT EXECUTE G1, G2 OR G3.** This ACT did not migrate
the decision at all. It measured the G0 legacy C authority and proved
the causal direction of the SUB-002 decision. The four-generation
plan below is a **PLAN** for the successor, and the successor MUST
execute it.

## THE FOUR GENERATIONS

| Gen | What it is | Producer | Executed by |
|---|---|---|---|
| **G0** | The REAL legacy C authority: `src/parser.c` compiled with the delegation selector OFF. It IS the production translation unit. | the C compiler (`cc`) | **THIS ACT** (the oracle, the fixture and the causal direction) |
| **G1** | The PolyC component compiled by the STAGE0 compiler (`build/bootstrap-stage0/hcc`). | the stage-0 compiler | the SUCCESSOR |
| **G2** | The PolyC component compiled by the PRODUCTION compiler (`./hcc`). | the production compiler | the SUCCESSOR |
| **G3** | The PolyC component compiled by the STAGE-2 compiler (`./build/hcc-bootstrap02`). | the stage-2 compiler | the SUCCESSOR |

Each generation MUST be **BUILT and EXECUTED INDEPENDENTLY**. No
generation's output may be copied as a substitute for another
generation's compilation.

## THE EXPECTED SUBJECT OBJECT IDENTITIES

The successor MUST record, for each generation, the SHA-256 of the
compiled PolyC subject object and MUST show that the three PolyC
generations are **DISTINCT OBJECTS** (or, if two of them are
byte-identical, MUST explain why the identity difference is not
material and MUST still show the third differs). The existing seven
authorities already demonstrate this shape; the successor MUST
reproduce it for the new one.

```text
G1_OBJECT_SHA256=<to be measured by the successor>
G2_OBJECT_SHA256=<to be measured by the successor>
G3_OBJECT_SHA256=<to be measured by the successor>
```

## THE EXACT PRODUCTION SEAM AND BUILD LINKAGE

```text
SELECTOR=HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES
OBJECT_VARIABLE=DEFAULT_ARM_TERMINATES_OBJECT
PRODUCER_VARIABLE=DEFAULT_ARM_TERMINATES_PRODUCER
SOURCE_VARIABLE=DEFAULT_ARM_TERMINATES_SOURCE
PREFIX_VARIABLE=DEFAULT_ARM_TERMINATES_PREFIX
CMAKE_TARGET=hcc
```

The successor MUST add the selector and the four wiring arguments to
`src/CMakeLists.txt` following the seven existing authorities'
pattern, and MUST add the corresponding `Makefile` variables.

## THE PROVENANCE NEGATIVE CONTROLS THE SUCCESSOR MUST EXECUTE

For each generation:

1. **The object-identity control.** The subject object MUST define
   exactly ONE global text symbol named `_BootstrapDefaultArmTerminates`
   (Mach-O) and the count MUST be exactly 1. This is the check the
   repository's gate-push already performs for the seven existing
   authorities.

2. **The provenance control (SL-PV-01).** Each generation's producer
   binary MUST be identified by its ACTUAL SHA-256, and a relabelling
   of one producer as another MUST be rejected.

3. **The function-scoped authority control (SL-CC-04).** The
   compiled decision evidence MUST be attributed to the SELECTED
   function, not to a `cmp`/`tst` elsewhere in the object. **This ACT
   already showed why this matters**: the SUB-001 (case-arm) decision
   and the SUB-002 (default-arm) decision compile to the SAME bitset
   SHAPE, so a detector that counted `cmp`/`tst` instructions
   anywhere in the object would misattribute the evidence. The
   successor MUST attribute by FUNCTION, and MUST show the SUB-002
   site's mask is the one that covers exactly {258, 270, 274, 280,
   287}.

4. **The dormant-branch control.** The C-ON build's production parser
   object MUST be byte-identical whether or not the legacy C branch is
   mutated. This ACT's C2 measurement gives the current value:
   `253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246`.

## THE FIXTURE AND THE SEMANTIC DIFFERENTIAL

The successor MUST run the 41-row fixture against EVERY generation
and MUST show:

* the G0 legacy C oracle reproduces all 41 expected values,
* G1, G2 and G3 each reproduce all 41 expected values,
* the four generations agree with EACH OTHER on all 41 rows.

The semantic differential MUST be a per-row comparison keyed by the
exact row ID, so that a single wrong row is named. This ACT's
per-row differential named row kind 274 exactly.

## THE INDEPENDENT PROVENANCE NEGATIVE CONTROL

The successor MUST include at least one control that would FAIL if a
generation's output were merely COPIED from another generation rather
than compiled by its own producer. The repository's existing
`lexer07-objects-byte-equal` / `parser-slice03-generation-pairs`
tooling is the precedent for this class of control.
