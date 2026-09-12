# HANDOFF -- ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01

Factory-Version: 2

## Result

Reconcile the closure-truth gap of the predecessor ACT
(`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`) under v2 doctrine.

The predecessor's production semantic delta is mechanically
GREEN; its gate-push failure on gep01 is byte-identical
pre-/post- the production delta and is therefore
**environmental, not attributable**. Per v2 §25, the
classification is `HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`,
which is the documented board signal that the roadmap may
proceed.

Closure verdict is authoritative in the `ACT-Corrected-
Verdict` trailer of this ACT's CLOSE commit. Per v2
HANDOFF-TEMPLATE.md, this HANDOFF is descriptive only.

## What changed

- `docs/acts/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01.md`
  (the correction ACT contract)
- `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/`
  (C1..C4 evidence packet; zero production source change)
- `docs/ROADMAP.md` (status reconciliation only; adds
  the v2 corrected-verdict trailer to the predecessor's
  status entry)

The predecessor ACT's evidence directories and HANDOFF.md
are NOT mutated (F14).

## Evidence

- `c1/red-grep-summary.txt` — byte-identical pre-/post- C2
  comparison of the gep01 4 FAIL rows (both `diff` exits 0).
- `c1/red-hygiene-witnesses.txt` — three hygiene witnesses
  (a) [dbg] stale log lines, (b) 7 fresh aarch64.c
  warnings, (c) gep01 D1+D2 four-failure aggregate.
- `c2/green-invariant-check.txt` — F1 identity, AC-C2.x,
  AC-C3.x live re-run on the current tree (`b76f0d8`).
- `c3/c3-evidence-gate-run.txt` — `make gate-fast` PASS,
  plus the predecessor's conservation gates (unit/jit/lsp).
- `c4/acceptance-matrix.txt` — all 18 ACs of this ACT PASS.
- `c4/closure-summary.txt` — full structured handoff.
- `c4/residue.txt` — P0/P1/P2 items, NOT taken into ownership.
- `c4/roadmap-transition.txt` — recommended next-ACT paths.

## Production delta

Zero bytes. This ACT does not re-mutate `src/aarch64.c`,
`src/x86_64.c`, or any predecessor evidence file. Verified
live via `git diff --stat b76f0d8..HEAD -- src/aarch64.c
src/x86_64.c` (empty) and the same against each predecessor
evidence subdirectory.

## Residue

- P1: three hygiene items under c4/residue.txt (a/b/c).
- P2: three deferred items from predecessor (NC1, Linux PIC,
  x86_64 abstraction).

## Recommended next ACT

Either (a) `ACT-POLYC-INTEGRATION-GEP01-GATE-RECOVERY01` to
fix D1 and D2 by mechanical root-cause analysis, then push
`b76f0d8` to origin/main and open `ACT-POLYC-BOOTSTRAP01`;
or (b) open `ACT-POLYC-BOOTSTRAP01` directly with its own
successor-need determination.

Neither is opened by this ACT.
