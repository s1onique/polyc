# CORRECTION03 C4 ROUND 2 -- THE POLYC CAUSAL MUTATION CORRECTION

This file is FORWARD-ONLY evidence. It does NOT modify, rewrite, or
endorse any earlier committed artifact. The C0, C1, C2, C3 and the first
C4 remediation commits and their source bytes are preserved exactly as
committed.

## 1. THE DISCREPANCY

The second independent Codex review raised a P2 finding: the PolyC causal
mutation's DESCRIPTION disagreed with its recorded RESULT.

| record | mutation description | mutated class |
| --- | --- | --- |
| C3 `c3/causal-and-dormancy.tsv` | force assembly when object and assembly are both present | `ASSEMBLER_TEXT` |
| C4 remediation `c4/causal-and-dormancy.tsv` | force assembly when object and assembly are both present | `MACHO_EXECUTABLE` |

The DESCRIPTION and the C3 RESULT agree with each other. The C4
re-run's `MACHO_EXECUTABLE` disagrees with both.

`MACHO_EXECUTABLE` is the class of the PRISTINE `-c -S` artifact on the
`-c -S` route ONLY IF the mutation did not take effect: an unchanged
driver still selects the object, and an object artifact is not an
executable. The C4 re-run's value is therefore the signature of a
mutation that was NOT APPLIED to the compiler that produced the
measured artifact.

## 2. THE RECONSTRUCTION

The mutation was reconstructed FROM THE CURRENT TREE, not copied from the
historical record.

The mutation is the MINIMAL change that implements the C3 description.
The driver collects the object request and the assembly request, and the
mutated driver makes the ASSEMBLY request win when both are present. It
is the single line

```text
    if (saw_object == 1) emission = WP_EMIT_COMPILE_OBJECT;
```

replaced by

```text
    if (saw_assembly == 1) emission = WP_EMIT_ASSEMBLY;
```

The reconstruction is MECHANICAL and FAIL-CLOSED:

* the anchor line MUST be present in the current driver source, or the
  reconstruction is refused;
* the mutated source MUST DIFFER from the pristine source, or the
  reconstruction is refused;
* the mutated driver object MUST be produced by the SAME digest-bound
  stage0 producer that builds the production subjects;
* the MUTATED selector-ON compiler is built by the SAME cmake
  configuration as the pristine one, with the MUTATED driver object and
  the MUTATED driver source;
* the MUTATED compiler MUST exist, or the measurement is refused.

The target does NOT modify the repository's working tree. It writes the
mutated source and the mutated compiler into the work directory.

## 3. THE MEASUREMENT

The measurement is produced by `make driver-wp001-correction03-causal-test`
against the repaired head.

```text
CAUSAL_OFF_CLASS=MACHO_OBJECT
CAUSAL_MUTATED_CLASS=ASSEMBLER_TEXT
CAUSAL_MUTATED_EXIT=0
CAUSAL_VERDICT=CAUSAL (the ON observable CHANGED under the PolyC mutation)
```

## 4. THE RESOLUTION

```text
The PolyC causal mutation DOES change the observable outcome, and the
mutated observable is ASSEMBLER TEXT with exit 0.
```

This CONFIRMS the C3 description and the C3 recorded result. The C4
remediation's `MACHO_EXECUTABLE` value was a MEASUREMENT ERROR in that
re-run, and it is NOT reproduced by an independent reconstruction from
the current tree.

The historical C3 and C4 records are NOT modified. The C4 remediation's
value remains in its committed file exactly as written, because F14
forbids rewriting historical evidence. This file is the CORRECTION.

## 5. WHAT THE CORRECTION DOES NOT CHANGE

* The C4 remediation's causal verdict ("CAUSAL") was CORRECT in its
  conclusion, even though its recorded class was not. The reconstruction
  reaches the same verdict with the correct class.
* The production precedence decision in
  `tools/bootstrap/selfhost-driver-wp001.HC` is NOT modified. The
  reconstruction mutates a COPY in the work directory.
* No claim of pre-implementation freezing is made. The reconstruction is
  a measurement made AFTER the implementation, and it is labelled as
  such.
