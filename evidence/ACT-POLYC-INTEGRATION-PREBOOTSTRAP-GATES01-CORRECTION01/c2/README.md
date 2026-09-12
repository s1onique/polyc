# C2 IMPL — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01

## Strategy

Per reviewer feedback (Mach-O/arm64 linker engineer +
compiler/toolchain engineer + Factory reviewer), the
predecessor ACT's HANDOFF was updated to identify **Option C
(declaration-only tooling header)** as the bounded repair
for the Layer 1 boundary-ownership defect, with **Option B
(ELF/GNU-linker-only `-Bsymbolic`) REJECTED** and Option A
demoted to a future standalone backend ACT
(`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`).

This C2 IMPL realizes Option C as three declaration-only
headers that restore the library boundary without touching
production codegen, linker flags, or test predicates:

| New file                       | Replaces                  | Pulls in              |
|--------------------------------|---------------------------|-----------------------|
| `src/holyc-lib/memory_defs.HH` | `src/holyc-lib/memory.HC` | nothing (pure decls)  |
| `src/holyc-lib/tooling_defs.HH`| `src/holyc-lib/tooling.HC`| nothing (pure decls)  |
| `src/holyc-lib/io_defs.HH`     | `src/holyc-lib/io.HC`     | nothing (pure decls)  |

The harness (`tools/quality/llvm-gep01-test.HC`) is updated
to include the three declaration-only headers instead of the
three implementation source files. The harness's compiled
translation unit therefore contains **only harness-local
symbol definitions** — it no longer transitively drags in
libtos implementation source.

The canonical install dance in `src/CMakeLists.txt` is
untouched. The three implementation source files
(`memory.HC`, `tooling.HC`, `io.HC`) are also untouched.
Only the harness's `#include` lines change.

## Files changed (production)

| File                                         | Lines (pre -> post) | Why                                 |
|----------------------------------------------|---------------------|-------------------------------------|
| `tools/quality/llvm-gep01-test.HC`           | 49-50: 2 -> 3       | Replace `.HC` includes with `.HH` declaration-only headers |
| `src/holyc-lib/memory_defs.HH`               | NEW                 | Declaration-only surface of memory.HC |
| `src/holyc-lib/tooling_defs.HH`              | NEW                 | Declaration-only surface of tooling.HC |
| `src/holyc-lib/io_defs.HH`                   | NEW                 | Declaration-only surface of io.HC |

No file under `src/aarch64.c`, `src/x86_64.c`,
`src/CMakeLists.txt`, `src/holyc-lib/tooling.HC`,
`src/holyc-lib/memory.HC`, `src/holyc-lib/io.HC`, no
production codegen, no compiler / parser / IR / ABI.

## G1 — harness/libtos defined-symbol intersection = 0

```
harness defined globals : 31  (down from 57 with the .HC includes)
libtos  defined globals : 317
intersection (comm -12) :  0
```

The 26-symbol collision reported by gate-push GPUSH-GEP01
under the predecessor ACT is fully eliminated. Captured in
`green-symbol-intersection.txt`.

## G7 — Harness links against `-ltos` (archive)

```sh
cc harness.o -L$TEST_PREFIX/lib -ltos -lpthread -lc -lm -o harness_bin
# Produces: 228 KB Mach-O 64-bit executable arm64
# No duplicate symbols. No undefined symbols.
```

## G7-bis — Harness links against `-ltos` (dylib) too

With the canonical install's `libtos.dylib -> libtos.0.0.1.dylib`
symlink restored (the very state that previously caused
FAILURE MODE A's ADRP defect for `unit-test`), the
**harness itself** still links cleanly:

```sh
ln -sf libtos.0.0.1.dylib $TEST_PREFIX/lib/libtos.dylib
cc harness.o -L$TEST_PREFIX/lib -ltos -lpthread -lc -lm -o harness_bin
# Produces: 64 KB Mach-O 64-bit executable arm64
# No duplicate symbols. No undefined symbols.
```

The smaller executable size (64 KB vs 228 KB) is because the
dylib path pulls fewer libtos symbols into the executable
image at static-link time. This confirms the boundary repair
works against BOTH consumer paths without modification.

## G11 — `test-prefix-install` no longer deletes libtos.dylib

(applied in this commit; verified separately under c3 evidence)

The `Makefile` change removes the C2.1 `rm -f
$(TEST_PREFIX)/lib/libtos.dylib` line. The canonical install
now keeps the dylib symlink as `src/CMakeLists.txt` produces
it. Per reviewer feedback: this is what proves the boundary
repair is real and not a workaround.

## What was deliberately NOT done

- `src/aarch64.c`, `src/x86_64.c` — AOT codegen Layer 2
  (ADRP/ADD against dylib's `nreloc=0` __text) is OUT OF
  SCOPE for this ACT. If `make unit-test` still fails after
  the boundary repair, the ACT HALTs to
  `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`.
- `src/CMakeLists.txt` — install dance is canonical.
- `src/holyc-lib/tooling.HC` / `memory.HC` / `io.HC` body
  changes — public API preserved verbatim.
- Linker flag hacks (`-Bsymbolic`, `-flat_namespace`, etc.)
  — out of scope; reviewer-rejected.
- GEP01 oracle reduction / predicate weakening — out of
  scope.
- `Makefile` `test-prefix-install` recipe structure beyond
  the `rm -f` removal.

## hcc built-in awareness

Note: `StrLen`, `StrCmp`, `StrNCmp`, `StrFirstOcc`,
`StrPrint`, `mkdir`, `unlink`, `opendir`, `readdir`,
`closedir`, `getpid`, `getenv`, `getcwd`, `chdir`, `isatty`,
`lseek`, `read`, `write`, `close`, `creat`, `fcntl`, `pipe`,
`dup2`, `fork`, `execv`, `waitpid`, `poll`, `mkstemp`,
`_exit`, `memchr`, `memcmp`, `memcpy`, `memmove`, `memset`,
`malloc`, `calloc`, `realloc`, `free`, `strlen`, `strcmp`,
`strncmp`, `strstr` are all known to hcc as built-ins
(verified: `mkdir` compiles to `U _mkdir` without any
explicit declaration; `StrLen` compiles to
`U _STRLEN_FAST`).

Therefore the declaration-only headers do NOT redeclare
these built-ins — that would shadow the built-ins' symbol
mapping. We rely on the built-ins where available and
declare only what hcc does not know about (the libtos-
specific wrappers like `PollIntr`, `SpawnAndCapture`,
`FileExists`, etc.).

## Mechanical verification recipe

```sh
cd /tmp/polyc-green

# Build the harness against the canonical install
hcc --install-dir=$TEST_PREFIX \
    tools/quality/llvm-gep01-test.HC \
    -o harness.o -c

# Inspect symbol intersection
nm -g harness.o | awk '$2 ~ /^[TBD]$/ { print $3 }' \
  | sort -u > harness.defs
nm -g $TEST_PREFIX/lib/libtos.a 2>/dev/null \
  | awk '$2 ~ /^[TBD]$/ { print $3 }' \
  | sort -u > libtos.defs

comm -12 harness.defs libtos.defs   # Expected: empty output

# Link against -ltos
cc harness.o -L$TEST_PREFIX/lib -ltos -lpthread -lc -lm -o harness_bin

# Verify the binary is a valid Mach-O executable
file harness_bin
# Expected: "Mach-O 64-bit executable arm64"
```
