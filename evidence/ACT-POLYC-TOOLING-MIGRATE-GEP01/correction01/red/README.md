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
| `read-at-malformed.ll`        | Synthetic read-at IR with constant-index GEP (`ptr %0, i64 2`). Satisfies the weakened PolyC predicates (rows 04/07/08) but FAILS the legacy Bash regex contract for ALL operands. Validated by `llvm-as`. **C1.2 case A (constant-index negative).** |
| `read-at-symbolic-base.ll`    | Synthetic read-at IR with symbolic base (`ptr %base, i64 %1`). FAILS the legacy regex because the base operand is not `%[0-9]+`. **C1.2 case B (symbolic-base negative).** |
| `read-at-genuine.ll`          | Genuine dynamic-shape read-at IR (`ptr %0, i64 %1`). MATCHES the legacy regex. **C1.2 case C (positive control).** |
| `cap-malformed.txt`           | Synthetic cap-verifier output where opcode names and `(REJECTED)` / `(SUPPORTED)` markers appear on separate lines. Satisfies the weakened PolyC predicates (rows 26/27/28) but FAILS the legacy opcode-line binding. |
| `harness-source-excerpt.txt`  | Verbatim harness predicate text + verbatim legacy Bash predicate text + side-by-side summary of all six predicate defects. |
| `predicate-gap-proof.txt`     | Transcript: each malformed fixture is observed to PASS under the weakened PolyC predicate and FAIL under the legacy Bash-equivalent predicate. |
| `scratch-lifecycle-proof.txt` | Transcript proving the P1 regression: the current harness produces a 2/12 noisy FAIL cascade when the `--scratch` directory does NOT pre-exist. The legacy Bash harness owned its scratch dir via `mkdir -p` + `trap rm -rf`. |

## C1.1 amendment (spec only; no fixture changes)

The ACT document was amended in C1.1 RED-AMEND to:

- Tighten the P1 scratch rule to **option B**.
- Add **§3.1 pure-local predicate helper contract**
  (`GeShPrefixNumberedI64`, `LineContainsOpcodeMarker`).
- Add **§3.2 `--predicate-selftest` mode**.
- Rewrite **AC02–AC05 / AC06** accordingly.

## C1.2 amendment (this commit; spec + 2 new fixtures)

The C1.2 review caught a P0 false-green path in the
C1.1 helper `GeShPrefixNumberedI64`: it only checked the
first `%[0-9]+` of the legacy regex
`getelementptr i8, ptr %[0-9]+, i64 %[0-9]+`, so the
constant-index fixture `ptr %0, i64 2` would have been
falsely accepted. C1.2 fixes this by:

- Replacing `GeShPrefixNumberedI64` with
  `GepDynamicI8Shape` (§3.1), which checks BOTH
  numbered SSA operands on the SAME line — matching
  the full legacy regex.
- Adding two new committed fixtures to this directory:
  - `read-at-symbolic-base.ll` (case B: symbolic base,
    numbered index — exercises the FIRST operand side
    of the helper; a helper that only checked the
    second operand would falsely accept this).
  - `read-at-genuine.ll` (case C: positive control —
    prevents a tautological selftest that proves only
    FALSE; a regression that collapsed the predicate
    to always-FALSE would still pass cases A and B).
- Extending §3.2 selftest table with all three cases
  (A constant-index, B symbolic-base, C genuine) plus
  the row-08 / row-26 / row-27 / row-28 cases.
- Adding **§3.5 child-path containment check** (binding
  precondition before `rm -rf <child>`) so the
  `HALT_P1_RECURSIVE_DELETE_CALLER_ROOT` rule is
  executable, not merely doctrinal. New HALT trigger
  `HALT_P1_CONTAINMENT_UNVERIFIED`.
- Adding `HALT_GEP_HELPER_WEAKER_THAN_LEGACY` to §7
  (catches any C2 IMPL helper whose acceptance set
  is a strict superset of the legacy regex).
- Rewriting AC02 and AC03 to reference the new helper
  and all three fixtures.

The original `read-at-malformed.ll` (case A) and
`cap-malformed.txt` fixtures from C1 are UNCHANGED
(F14). C1.2 ADDS two new fixtures to this directory;
it does NOT mutate any prior file.

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
