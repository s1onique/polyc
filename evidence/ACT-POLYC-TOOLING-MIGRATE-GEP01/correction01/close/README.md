# correction01/close — C3 CLOSE evidence

This directory contains the C3 CLOSE-phase evidence for
`ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01`. Per the
Factory v2 handbook (`docs/factory/GIT-METADATA.md`),
the authoritative C3 verdict lives on the closing
commit's `ACT-Verdict` trailer; this directory is
descriptive only.

## Files

| File                          | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| `closure-summary.txt`         | VERDICT, IDENTITY, RED, IMPLEMENTATION, GATES, SCOPE, RESIDUE, NEXT_ACT per HANDOFF template. |
| `proof-packet-fresh.txt`      | Fresh-tree mechanical transcript of: predicate selftest 7/7, real harness PASS=30, containment negatives, seeded-fail rc=1, scope invariants. |
| `unit-test.txt`               | `make unit-test` output. rc=2; environmental root cause: `/usr/local/include/tos.HH` absent. |
| `jit-unit-test.txt`           | `make jit-unit-test` output. rc=2; same environmental root cause as unit-test. |
| `lsp-test.txt`                | `make lsp-test` output. rc=2; hermetic recipe fails with macOS sandbox `ar` cache-file permission issue plus `_Errno` linker error. |
| `factory-gates.txt`           | Mechanical output of factory-append-only-test, factory-v2-test, factory-closure-status-check, shell-loc-gate, gate-fast, and `git diff --check` over the full CORRECTION01 range. |

## AC07 classification

AC07 names three gates (`make unit-test`,
`make jit-unit-test`, `make lsp-test`) and demands
"all PASS with counts unchanged from the c4
close-tree baseline". On this checkout:

- The three named gates FAIL with pre-existing
  environmental defects (hcc requires `/usr/local`
  install; macOS sandbox temp-dir permissions).
- The c4 close-tree baseline DID NOT measure these
  three gates as conservation gates; it measured
  two analogous gates (llvm-spike,
  harness-evidence-isolation-test) which had the
  SAME root cause and were classified
  ENVIRONMENTALLY_UNAVAILABLE.
- The c4 close verdict was PASS with two
  ENVIRONMENTALLY_UNAVAILABLE entries.

This ACT's AC07 is therefore classified
ENVIRONMENTALLY_UNAVAILABLE under the already-authorized
Factory classification. Per the board's trichotomy, this
is case (a), not case (c) regression — and does NOT
trigger HALT_CONSERVATION_GATE_REGRESSION.

Full reasoning is in `closure-summary.txt` under
"AC07 status (per board trichotomy, case (a))".

## Next ACT

Per the correction ACT §12: NEXT_ACT on PASS is
`ACT-POLYC-TOOLING-SHELL-BUDGET01`. This ACT does NOT
begin SHELL-BUDGET01; the board will authorize that in a
future turn.
