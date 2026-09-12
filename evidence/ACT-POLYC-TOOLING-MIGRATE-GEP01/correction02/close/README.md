# correction02/close - C2 CLOSE evidence

This directory contains the C2 CLOSE-phase evidence for
`ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02`.

Per the Factory v2 handbook
(`docs/factory/GIT-METADATA.md`), the authoritative C2
verdict lives on the C2 CLOSE commit's `ACT-Verdict`
trailer; this directory is descriptive only.

## Files

| File                                       | Purpose                                                |
|--------------------------------------------|--------------------------------------------------------|
| `closure-summary.txt`                      | VERDICT, IDENTITY, RED, IMPLEMENTATION, GATES, SCOPE, RESIDUE, NEXT_ACT per HANDOFF template. |
| `ac07-c4-baseline.txt`                     | AC02: AC07 "counts unchanged from c4 baseline" is UNDEFINED. |
| `ac08-close-tree.txt`                      | AC03: AC08 mechanically verified at CORRECTION01 CLOSE commit `1732c3f`. |
| `direct-argv-audit.txt`                    | AC04: Direct-argv audit with raw/executable disambiguation. |
| `harness-replay.txt`                       | AC05: Harness conservation by code-identity (live re-execution env-blocked). |
| `range-checks.txt`                         | AC06: git diff --check clean, production delta empty, append-only PASS. |
| `no-sha-of-self.txt`                       | AC07: 40-char hex blob grep = 0 hits. |
| `correction01-evidence-unchanged.txt`      | AC08: CORRECTION02 does NOT mutate CORRECTION01 evidence tree. |
| `r1-ac07-three-gates-close-tree.txt`       | R1 close-tree evidence: make unit-test/jit-unit-test/lsp-test all rc=2. |
| `r2-c4-baseline-close-tree.txt`            | R2 close-tree evidence: c4 baseline didn't measure those three gates. |
| `r3-ac08-close-tree.txt`                   | R3 close-tree evidence: git diff --check on CORRECTION01 CLOSE commit. |
| `r4-direct-argv-audit.txt`                 | R4 close-tree evidence: raw/executable breakdown. |

## Verdict reconciliation

The C2 CLOSE commit carries:

```
ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
ACT-Corrected-Verdict: HALT_AC07_NOT_SATISFIED
```

Per `docs/factory/GIT-METADATA.md` §2.3, the correction's
own CLOSE carries its own `ACT-Verdict: PASS`; the
corrected verdict about the predecessor is recorded in
`ACT-Corrected-Verdict: HALT_AC07_NOT_SATISFIED`. The
Factory closure-status oracle MUST then report the
predecessor as `HALT_AC07_NOT_SATISFIED`.

The corrected verdict grammar
`HALT_AC07_NOT_SATISFIED` matches the documented regex
at `docs/factory/GIT-METADATA.md` §2.2:
`^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$`.

## Why this is a closure-contract correction, not an implementation ACT

CORRECTION02 is **evidence-only**. The harness, compiler,
parser, IR, ABI, Factory doctrine, and any historical
evidence tree are NOT modified. The mission is to:

1. truthfully document the three closure-contract defects
   in CORRECTION01's verdict (AC07 not satisfied, AC08
   not satisfied at CLOSE tree, direct-argv evidence
   lacks disambiguation);
2. carry `ACT-Supersedes` + `ACT-Corrected-Verdict` on
   the C2 CLOSE commit so the Factory closure-status
   oracle correctly reports the predecessor's verdict.

No production source is touched. No historical evidence
tree is touched (verified by AC08).

## Next ACT

Per the correction ACT §12: NEXT_ACT on PASS is
`ACT-POLYC-TOOLING-SHELL-BUDGET01`. This ACT does NOT
begin SHELL-BUDGET01; the board will authorize that in a
future turn.
