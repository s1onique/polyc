# correction01/red — principal RED witnesses

This directory freezes the principal RED witnesses for
`ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01` (RED
phase). All witnesses are cross-references between the
legacy Bash contract (verbatim at
`evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/legacy-source.txt`)
and the current PolyC harness source
(`tools/quality/llvm-gep01-test.HC`).

## Contents

| File                          | Purpose |
|-------------------------------|---------|
| `read-at-malformed.ll`        | Synthetic read-at IR that satisfies the weakened PolyC predicates (rows 04/07/08) but FAILS the legacy Bash regex contract. Validated by `llvm-as`. |
| `cap-malformed.txt`           | Synthetic cap-verifier output where opcode names and `(REJECTED)` / `(SUPPORTED)` markers appear on separate lines. Satisfies the weakened PolyC predicates (rows 26/27/28) but FAILS the legacy opcode-line binding. |
| `harness-source-excerpt.txt`  | Verbatim harness predicate text + verbatim legacy Bash predicate text + side-by-side summary of all six predicate defects. |
| `predicate-gap-proof.txt`     | Transcript: each malformed fixture is observed to PASS under the weakened PolyC predicate and FAIL under the legacy Bash-equivalent predicate. |
| `scratch-lifecycle-proof.txt` | Transcript proving the P1 regression: the current harness produces a 2/12 noisy FAIL cascade when the `--scratch` directory does NOT pre-exist. The legacy Bash harness owned its scratch dir via `mkdir -p` + `trap rm -rf`. |

## C1.1 amendment (this directory is unchanged; ACT §3.x is the new spec)

The ACT document (`docs/acts/ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01.md`)
was amended in C1.1 RED-AMEND to:

- Tighten the P1 scratch rule to **option B**: the
  caller owns the `--scratch` root; the harness owns a
  unique per-run child beneath it; the harness MUST NOT
  recursively delete the caller root. See ACT §3 item 5.
- Add **§3.1 pure-local predicate helper contract**:
  `GeShPrefixNumberedI64(text, prefix)` and
  `LineContainsOpcodeMarker(text, opcode, marker)` —
  both pure local helpers, both implemented using only
  the existing HolyC primitives already imported by the
  harness. `tooling.HC` is NOT widened. HALT triggers
  `HALT_HELPER_NOT_PURE`, `HALT_TOOLING_HC_WIDENED`,
  `HALT_SELFTEST_MOCK`, `HALT_P1_RECURSIVE_DELETE_CALLER_ROOT`
  added to §7.
- Add **§3.2 `--predicate-selftest` mode**: a CLI flag
  that loads each malformed fixture in this directory
  via the harness's existing `FileRead` wrapper and
  invokes the SAME helper the normal 30-row run will
  invoke. Asserts each fixture's expected per-row
  verdict. Exits 0 only if all match.
- Rewrite **AC02–AC05** so verification is
  `--predicate-selftest`-driven (closing the
  mechanical-execution gap the C1 reviewer noted:
  ACs are now checkable through pure local predicate
  helpers against committed fixtures, not via full
  toolchain substitution).
- Rewrite **AC06** to additionally verify the caller
  root SURVIVES the harness exit (option B).

This directory's principal-RED fixtures are UNCHANGED
in C1.1. They remain the inputs the production
restoration MUST reject, and they become the inputs
the `--predicate-selftest` mode loads in C2. The C1.1
amendment adds spec only; it adds NO new fixture and
mutates NO existing fixture (F14).

## Reproduction protocol (F2 evidence)

All transcripts in this directory were produced by the
agent before any production change, against:

- the live harness binary (`/tmp/llvm-gep01-test`) built
  from the current tree,
- the live `hcc`, `llvm-as`, `opt`, `python3` toolchain
  on this host,
- the real `read-at.ll` emitted by the current hcc
  (`build/quality/gep01/read-at.ll`),
- the real `cap-verifier.txt` from the most recent
  harness run (`build/quality/gep01/cap-verifier.txt`).

No production source was modified during RED capture.

## Relationship to the legacy evidence tree (F14)

The c1 legacy-source.txt, c1 oracle-matrix.tsv, and
c2/c3/c4 evidence directories are F14-protected. They
are read-only references for this ACT. This directory
adds new evidence; it does NOT mutate the historical
record. The c4 PASS verdict for MIGRATE-GEP01 remains
in the historical record as evidence of what was
previously observed; this ACT is the correction.
