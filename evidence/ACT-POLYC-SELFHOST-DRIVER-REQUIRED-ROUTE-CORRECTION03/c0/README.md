# CORRECTION03 C0 RED

Fresh isolated selector-OFF and selector-ON production compilers were built
from the same source tree. The OFF compiler has zero
`WpDriverSelectedEmission` symbols; the ON compiler has one.

The mandatory `-c -S` witness exited 0 in both compilers. The OFF C oracle
produced a Mach-O object. The ON PolyC compiler produced assembly text.
Artifact class and byte equality therefore failed before any production
change.

`c0-red.log` is the exact command output. The OFF stderr stream contains a
pre-existing assembler warning because the legacy C object command includes
link-only flags; this is P1 residue and is not part of the emission-selection
fix.
