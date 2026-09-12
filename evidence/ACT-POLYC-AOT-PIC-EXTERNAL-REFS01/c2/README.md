# C2 IMPL — ACT-POLYC-AOT-PIC-EXTERNAL-REFS01

This directory contains the implementation delta and GREEN packet.

## Files

| File | Purpose |
|------|---------|
| `ext-provider.c`        | C dylib producer (PolycExtAdd1) |
| `ext-consumer.HC`       | PolyC AOT consumer (E2 path) |
| `local-control.HC`      | PolyC same-image control (L2 path) |
| `implementation-delta.txt` | F2-bounded src/aarch64.c diff |
| `green-build.txt`       | hcc -S output for ext-consumer.HC post-C2 |
| `green-link.txt`        | clang link attempt against libpolyc-extref.dylib |
| `green-runtime.txt`     | run rc |
| `green-relocations.txt` | Mach-O relocation records for ext-consumer.o |
| `green-disassembly.txt` | disassembly of ext-consumer.o |
| `local-control-post.txt`| same-image control + relocations (unchanged from C1) |
| `missing-provider-negative.txt` | NC2 missing provider link FAIL |
| `gep-symbol-intersection.txt` | NC3 layer-1 invariant |
| `libpolyc-extref.dylib` | C dylib (binary; consumed in place) |
| `ext-consumer.o` / `ext-consumer` / `local-control.o` / `local-control` | build outputs (consumed in place) |

## Captured observations (mechanical, post-C2)

```
GREEN_BUILD_RC        = 0
GREEN_RELOCATION_TYPES = ARM64_RELOC_GOT_LOAD_PAGE21
                        ARM64_RELOC_GOT_LOAD_PAGEOFF12
                        (llvm-objdump prints GOTLDP / GOTLDPOF)
GREEN_LINK_RC         = 0
GREEN_RUNTIME_RC      = 0  (returns 0, computed 41+1 = 42)

LOCAL_CONTROL_RUN_RC  = 0
LOCAL_CONTROL_RELOCATIONS = PAGE21 + PAGEOFF12   (unchanged from C1)

MISSING_PROVIDER_LINK_RC = 1   (NC2 PASS)
```

AC05 PASS: classifier inspects AST kind, not symbol spelling.
AC06 PASS: change is bounded to src/aarch64.c IR_LEA arm + new helper.
AC07 PASS: external-dylib fixture links (rc=0).
AC08 PASS: external-dylib fixture executes (rc=0).
AC09 PASS: relocations are now ARM64_RELOC_GOT_LOAD_* (Mach-O-valid).
AC10 PASS: same-image control still compiles/links/runs.
AC11 PASS: same-image control still emits PAGE21+PAGEOFF12 (unchanged).
