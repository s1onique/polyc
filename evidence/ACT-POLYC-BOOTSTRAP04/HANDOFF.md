# ACT-POLYC-BOOTSTRAP04 — HANDOFF

This HANDOFF is a **descriptive** summary of
`ACT-POLYC-BOOTSTRAP04` (B3 bootstrap stability).

The authoritative verdict lives on the CLOSE commit's
`ACT-Verdict:` trailer. See `evidence/ACT-POLYC-BOOTSTRAP04/c4/closure-summary.txt`
for the binding closure block.

---

## One-paragraph summary

The PolyC bootstrap chain has reached **bootstrap
stability** over its currently self-hosted domain.
A third compiler generation (`build/hcc-bootstrap04`)
was constructed that consumes the exact B1 component
produced by the second generation (`build/hcc-bootstrap03`)
and runs it through the production lexer dispatch. The
two later generations agree byte-for-byte on the entire
frozen evidence domain: 15/15 component differential,
6/6 cursor model, 6/6 production Lexer seam, 175/175
successful-corpus sources byte-equal, 6/6 baseline
failures equivalent, 4/4 explicit error corpus fixtures
equivalent, and `stage2(B1 source) == stage3(B1 source)`
byte-for-byte. Two independent clean constructions
reproduce the result. B0/B1/B2 conservation remains
green.

## What B3 does — and does not — claim

B3 establishes:

- `BOOTSTRAP_STABILITY = PASS`
- `BOOTSTRAP_STABILITY_DOMAIN =
   CURRENT_SELF_HOSTED_COMPILER_COMPONENT`
- `FIRST_SELF_HOST = YES` (carried from B2)
- `REPRODUCIBILITY = PASS`

B3 explicitly does **not** claim:

- `FULL_SELF_HOST = YES` (still NO — host-C dominates)
- `COMPILER_IMPLEMENTED_POLYC = YES`
- `HOST_C_DEPENDENCY = ZERO`
- `TRUSTING_TRUST_RESOLVED = YES`

## Generation chain (canonical)

```text
stage0 (./hcc)
  -> compiles PolyC B1 source -> S0 (build/bootstrap02-ident.o)
  -> links S0 into stage1 (build/hcc-bootstrap02)

stage1 (build/hcc-bootstrap02)
  -> compiles same PolyC B1 source -> S1 (build/bootstrap03-ident.stage1.o)
  -> links S1 into stage2 (build/hcc-bootstrap03)

stage2 (build/hcc-bootstrap03)
  -> compiles same PolyC B1 source -> S2 (build/bootstrap04-ident.stage2.o)
  -> links S2 into stage3 (build/hcc-bootstrap04)

stage3 (build/hcc-bootstrap04)
  -> consumes exact S2
  -> uses S2 in production lexIdentifier dispatch
```

All four B1 objects are byte-identical
(`a1b620c076e81d898f953889f2b9db97f0bf8f6228af3b4a10644e2e78cd854f`).

## Stability evidence

| Domain                    | Result                  |
|---------------------------|-------------------------|
| Component differential    | 15/15 byte-equal PASS   |
| Cursor model              | 6/6 byte-equal PASS     |
| Production Lexer seam     | 6/6 byte-equal PASS     |
| Broad corpus (181)        | 175/175 byte-equal PASS |
| Baseline failures (6)     | 6/6 equivalent PASS     |
| Error corpus (4)          | 4/4 equivalent PASS     |
| Stage3 self-source        | byte-equal to S2 PASS   |
| Two-build reproducibility | Build A == Build B PASS |

## What changed in this ACT

| File                            | Change                                |
|---------------------------------|---------------------------------------|
| `src/CMakeLists.txt`            | New `HCC_ENABLE_BOOTSTRAP04_STAGE3` option + `hcc-bootstrap04` target |
| `Makefile`                      | New `bootstrap04-component-build`, `bootstrap04-stage3`, `bootstrap04-test`, `bootstrap04-cursor-test`, `bootstrap04-lexer-seam-test` targets |
| `tools/quality/bootstrap04-corpus-runner.py`  | New driver script (analogous to bootstrap03-)  |
| `tools/quality/bootstrap04-error-corpus.py`   | New driver script                              |
| `docs/ROADMAP.md`               | B3 transition to GREEN, B3 outcome block added |
| `docs/acts/ACT-POLYC-BOOTSTRAP04.md`          | New ACT document                |
| `evidence/ACT-POLYC-BOOTSTRAP04/**`           | Full C1/C2/C3/C4 evidence packets |
| `evidence/ACT-POLYC-BOOTSTRAP04/HANDOFF.md`   | This file (text only, no verdict) |

No compiler semantic files modified:

- `src/lexer.c` FROZEN
- `src/lexer_bridge.h` FROZEN
- `tools/bootstrap/bootstrap02-ident.HC` FROZEN
- parser/AST/IR/backend FROZEN

## Commit topology

```text
21fa04c  ACT-POLYC-BOOTSTRAP04 — C1 RED
c01c9bf  ACT-POLYC-BOOTSTRAP04 — C2 IMPL
f036ba0  ACT-POLYC-BOOTSTRAP04 — C3 EVIDENCE
<this>   ACT-POLYC-BOOTSTRAP04 — C4 CLOSE
```

Exactly one commit carries `ACT-Phase: CLOSE`.

## What comes next

Per ACT §52 (hard stop): after the B3 CLOSE the correct
next operation is **board design**. Do not:

- create stage4
- migrate another compiler subsystem to PolyC
- declare FULL_SELF_HOST
- repair unit/jit runner, GEP01, or unrelated residue
- rewrite previous evidence
- invent B4 scope
- push without separate authorization

The post-B3 roadmap is not yet authored; any new milestone
requires a fresh ACT with its own scope and acceptance
criteria.

## Pointer to authoritative verdict

The binding verdict (`ACT-Verdict: PASS`) is on the
C4 CLOSE commit trailer; not on this HANDOFF.
