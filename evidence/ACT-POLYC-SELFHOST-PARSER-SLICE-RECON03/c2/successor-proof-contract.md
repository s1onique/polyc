# Successor proof contract — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Selected target:** `parseGetPriority` (`src/prslib.c:1139..1207`)
**Component:** `BootstrapOperatorPrecedence` (PolyC)
**Successor ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE03`

---

## 1. The four-generation model

```text
G0 = legacy/stage0 reference
G1 = stage1 PolyC production path
G2 = independently built stage2
G3 = independently built stage3
```

The successor MUST produce all four and MUST record, for each:

```text
the compiler identity (the binary path AND its SHA-256)
the exact build command
the SHA-256 of every source file that went into it
```

The generations MUST be DISTINCT builds and MUST be executed
independently.  A single binary copied four times is not four
generations.

---

## 2. The six component-object pairwise comparisons

The component object must be byte-compared pairwise:

```text
G0 vs G1
G0 vs G2
G0 vs G3
G1 vs G2
G1 vs G3
G2 vs G3
```

The requirement is that the component's SEMANTICS agree across the
generations.  Whether the objects are byte-identical is a fact to be
MEASURED, not an expectation to be asserted.

**G0 is an intentional legacy reference.**  The G0 component object is
built from the LEGACY C implementation, not from PolyC, so it is NOT
expected to be byte-identical to G1/G2/G3.  The permitted G0-versus-PolyC
comparison contract is therefore SEMANTIC (the oracle differential),
not byte-identity.  This exception MUST be frozen explicitly in the
successor's own evidence, exactly as this contract states it.

The G1/G2/G3 component objects are all built from the SAME PolyC
source, so byte-identity between them is expected; the pairwise
comparison must nevertheless be performed and recorded rather than
assumed.

---

## 3. The six production semantic pair comparisons

For each of the six generation pairs, the successor MUST compare the
PRODUCTION SEMANTIC OUTPUT:

```text
the compiled observation program's output
and, where contractually applicable, the differential result over the
frozen fixture matrix
```

The six pairs are the same six pairs as in §2.  A pair is equivalent
when the production semantic outputs agree.

**A mutation-specific semantic delta does NOT count as normal-generation
equivalence.**  The mutation run is a SEPARATE obligation (§6); it is
never used to satisfy a normal-generation equivalence requirement.

---

## 4. Generation provenance checking

The successor MUST prove that each generation really is the generation
it claims to be, and not a copy of another one.  The proof must
include at least:

```text
the distinct SHA-256 of each generation's COMPILER binary
the distinct build command of each generation
the build log or the build receipt of each generation
```

---

## 5. Copy-forgery rejection

The successor MUST include a negative control that shows the
provenance check can FAIL.  The canonical control substitutes a
BYTE-IDENTICAL OBJECT from another generation (or copies one
generation's component object over another) and requires that the
provenance check REJECTS the substitution.

Without such a control, a provenance check that accepts anything would
report a pass.

---

## 6. Negative control for copied seam outputs

The successor MUST include a negative control that shows the semantic
comparison can FAIL — the same shape the legacy-oracle contract
requires of the differential: a deliberately altered expectation must
produce a REPORTED DISAGREEMENT, not a silent pass.

---

## 7. Direct C-oracle differential

The successor MUST run the direct differential against the REAL legacy-C
function, over the frozen fixture matrix of at least 91 rows, as
specified in `legacy-oracle-contract.md` and `fixture-partitions.tsv`.

The oracle MUST come from a build in which the delegation flag is OFF.

---

## 8. Production-causal mutation

The successor MUST execute the frozen mutation of
`causal-mutation-contract.md` and MUST observe the frozen divergence:

```text
pristine  -> 62
mutated   -> 162
restored  -> 62
```

with the SHA-256 of each output recorded.

---

## 9. Actual production authority transfer

The successor MUST demonstrate that the PRODUCTION binary actually
routes the decision through the PolyC component, in the strong form:

```text
$ nm -u build/CMakeFiles/hcc.dir/prslib.c.o | grep BootstrapOperatorPrecedence
_BootstrapOperatorPrecedence
```

The legacy algorithm body MUST live in the `#else` branch and MUST NOT
be compiled into the production object.  The successor MUST also
confirm that the other two production authorities are unchanged:

```text
_U _BootstrapCalcPadding
_U _BootstrapValidPostControlFlowToken
```

and that the control-flow-token component keeps its five live
production call sites.

---

## 10. The fixture-integrity obligation

Because ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 REPRODUCED a metadata
bypass in the closed control-flow-token qualification tool, the
successor MUST provide an INDEPENDENT witness that every mandatory
fixture is executed, and that an unknown or additional fixture row is
REJECTED rather than skipped.  The witness must not be produced by the
same row-classification path the differential exercises.

---

## 11. Conservation obligations

The successor MUST run and record:

```text
the parser conservation suite
the lexer conservation suite (LEXER01..04 and the LEXER07 broad corpus)
the Factory gates (gate-fast, gate-push, factory-v2, append-only)
the F-NO-PYTHON and F-POLYC-TOOLS checkers
```

with ZERO new failures relative to the baseline that this ACT freezes.
