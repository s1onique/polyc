# C1 RED — ACT-POLYC-AOT-PIC-EXTERNAL-REFS01

This directory contains the principal RED packet for the ACT.

## Files

| File | Purpose |
|------|---------|
| `ext-provider.c`        | C dylib producer (PolycExtAdd1) |
| `ext-consumer.HC`       | PolyC AOT consumer (E2 path: lea + blr) |
| `local-control.HC`      | PolyC same-image control (L2 path) |
| `red-build.txt`         | hcc -S output for ext-consumer.HC |
| `red-link.txt`          | clang link attempt against libpolyc-extref.dylib |
| `red-run-control.txt`   | local-control run rc |
| `red-relocations.txt`   | Mach-O relocation records for ext-consumer.o |
| `red-relocations-local.txt` | Same for local-control.o (intra-image) |
| `red-disassembly.txt`   | ext-consumer.o disassembly |
| `seam-map.txt`          | F2 recon — production seam + classifier |
| `c1-required-result.txt`| Required pre-C2 matrix + observed |

No binaries are committed to the repository. Intermediate files
(`*.o`, `*.s`, `libpolyc-extref.dylib`, `ext-consumer`, `local-control`)
are produced and consumed in place; the durable evidence is the text
captures above.

## Captured observations (mechanical)

```
RED_REFERENCE_SYMBOL      = _PolycExtAdd1
RED_INSTRUCTION_SHAPE     = adrp X0,_PolycExtAdd1@PAGE
                            add  X0,X0,_PolycExtAdd1@PAGEOFF
RED_RELOCATION_TYPES      = ARM64_RELOC_PAGE21
                            ARM64_RELOC_PAGEOFF12
RED_LINK_RC               = 1
RED_LINK_DIAGNOSTIC       = ld: invalid use of ADRP in '_main' to
                            '_PolycExtAdd1'
LOCAL_CONTROL_RUN_RC      = 0
```

RED reproduces the production defect at minimal scale and isolates
the seam to `src/aarch64.c:1497` (case IR_LEA, IR_VAL_FLAG_FUNC path).

## HALT applied?

None. RED reproduces cleanly; HALT_RED_NOT_REPRODUCED does not apply.

Proceed to F2 (already captured in `seam-map.txt`) and C2 IMPL.
