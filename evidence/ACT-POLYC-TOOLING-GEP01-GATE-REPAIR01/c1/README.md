# ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01 — C1 (RED)

## Entry identity

```text
git branch --show-current  -> main
git rev-parse HEAD         -> c734c9c31b3e3a53d6878e67b76809470ac9e1e0
git status --short         -> (clean)
```

`c734c9c` is the CLOSE of `ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01`
(`PASS_TRUE_GREEN`). It is a legitimate local closure whose push was
rejected by the pre-push hook because the mandatory `gep01` gate step
failed. It is left intact.

## Principal RED — reproduced

```text
$ make llvm-gep01-test HCC_ENABLE_LLVM=ON     (via the harness directly)
GEP01_PASS=26
GEP01_FAIL=4
STATUS=FAIL
```

Full harness output: `gep01-red-run.txt`.

The four failing rows are byte-identical to the rows recorded by
`ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01` in
`evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01/c3/gate-push-unmodified.txt`
and by `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` in
`evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c4/residue.txt`.

## Root cause — TWO independent defects behind the four rows

The four rows were previously recorded as one aggregate because the
harness collapses distinct causes into one generic message. The probes
in `../probes/` isolate them.

### Defect A — `io_defs.HH` `FileWrite` declaration/definition mismatch

Evidence: `filewrite-signature-mismatch.txt`

```text
FileWrite(default)                    = 0     <- the harness's call shape
FileWrite(explicit O_CREAT|O_RDWR)    = 1
FileWrite(explicit 0x202)             = 1
FileWrite(explicit ...|O_TRUNC)       = 1
direct open(O_CREAT|O_RDWR, 420)      = fd 3, wrote 5 bytes
```

`src/holyc-lib/io_defs.HH:48` declares the 4th parameter as
`Bool append=FALSE`; `src/holyc-lib/io.HC:211` and the canonical public
header `src/holyc-lib/tos.HH:786` both declare it as
`I64 flags=O_CREAT|O_RDWR`. The harness includes the declaration-only
header, so the defaulted 4th argument is lowered as the boolean `FALSE`
(`0`). The library then issues `open(path, 0, 420)` **without
`O_CREAT`** and the write fails. `readat.err` and `cap-verifier.txt`
are therefore never written.

### Defect B — the cap-table verifier queries a DIFFERENT compiler

Evidence: `compiler-identity-divergence.txt`,
`cap-verifier-wrong-compiler.txt`,
`cap-verifier-stderr-discarded.txt`

`scripts/quality/llvm-cap-table-verifier.py:55` hardcodes
`HCC = REPO_ROOT / "hcc"`, while `tools/quality/llvm-gep01-test.HC`
parameterises the compiler via `--hcc=<path>` and never passes it to the
verifier. On a non-LLVM build `hcc --print-cap-table` is unhandled
(`src/main.c:437`, inside `#ifdef HCC_ENABLE_LLVM`) and the process dies
on SIGSEGV (exit 139).

Additionally the harness frees the verifier's captured stderr without
reading it, so the diagnostic channel is discarded.

## Negative controls required at closure

* **NC-A** — revert only the `io_defs.HH` `FileWrite` declaration; the
  `SHAPE_DEPENDENT` row MUST fail again.
* **NC-B** — point the verifier at the non-LLVM SIGSEGV `hcc`; the three
  capability rows MUST fail again.

## Probes

Both probes are PolyC sources under `../probes/`. They compile against
the canonical installed `libtos` using only the declaration-only headers,
exactly as the GEP01 harness does.

```sh
PREFIX="$PWD/build/test-prefix"
./hcc --install-dir="$PREFIX" \
     evidence/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01/probes/filewrite-signature-probe.HC \
     -o build/gep01-debug/fwprobe
./build/gep01-debug/fwprobe "$PWD/build/gep01-debug/probe-scratch"

./hcc --install-dir="$PREFIX" \
     evidence/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01/probes/cap-verifier-identity-probe.HC \
     -o build/gep01-debug/capprobe
./build/gep01-debug/capprobe "$(which python3)" "$PWD/build/gep01-debug/probe-scratch"
```

## Scope note

No production file was modified in C1. The only tree change in this
phase is the addition of this ACT, its evidence, and its probes.
