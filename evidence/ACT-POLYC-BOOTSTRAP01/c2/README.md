# ACT-POLYC-BOOTSTRAP01 — C2 IMPL Evidence Packet

This directory holds the C2 IMPL evidence pack for
`ACT-POLYC-BOOTSTRAP01` (B0 compiler-shaped bootstrap).

C2 implements the B0 subject (a PolyC-written
allocation-free lexer/tokenizer) and the minimum test/build
seam required to compile and run it. C2 has the principal
GREEN witness.

## Files

| File                              | Purpose                                              |
| --------------------------------- | ---------------------------------------------------- |
| `implementation-delta.txt`        | The exact source deltas.                             |
| `subject-build.txt`               | `make bootstrap01-test` transcript.                  |
| `subject-run.stdout`              | Full B0 driver output for the frozen fixture matrix. |
| `emitted-ir.txt`                  | LLVM IR emission attempt (partial; see notes).       |
| `llvm-verification.txt`           | LLVM verification status (path-dependent).           |
| `negative-controls.txt`           | T11/NC6, T12/NC7, NC8 negative control results.      |
| `c2-required-result.txt`          | Required-result block for C2 closure.                |

## Outcome

The native AOT path produces a B0 lexer that compiles
through the current `hcc` and matches the independent C
oracle's token stream exactly for every fixture in
T01..T14 + NC6..NC8. 15/15 cases pass.

The LLVM path emits IR through most of the pipeline but
hits a documented MEMORY01 boundary at
`IR_STORE_DEREF` with non-zero disp (struct field write
through a variable-indexed pointer). This is the same
fence Option-W's C6 closure named as path-dependent and
out of scope for non-widening ACTs. The native path is
the authoritative execution seam per ACT §16.
