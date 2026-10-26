# ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Correct the five binding contract defects found in the
ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02 closure (a frozen fixture
expectation that contradicts the legacy C oracle, two ranking controls
operated on the wrong candidate set, an inventory count that did not
match the inventory, and a LEXER07 failure count that conflated the
baseline with the current) so that the successor ACT inherits a
satisfiable contract.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** GOVERNANCE / CORRECTION / CONTRACT

**Predecessor:** ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02 (closed
`PASS_TRUE_GREEN`; verdict corrected by this ACT through the
`ACT-Supersedes` / `ACT-Corrected-Verdict` trailers)

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## 0. Mission

Publish a corrected, forward-only successor-facing contract for
`CAND-001 parseValidPostControlFlowToken`, and correct the
predecessor's verdict, without mutating any production source, without
rebuilding any compiler generation, without rewriting any history, and
without regenerating any unrelated evidence.

## 1. Why

An independent review of the predecessor's closure found five defects.
Two of them are **binding**: the predecessor's committed claims are
false against the predecessor's own committed evidence.

**P0-1 — the frozen fixture matrix contradicts the legacy C oracle.**
The predecessor's `c2-selected-fixture-model.tsv` row F041
(`UNKNOWN_KIND_SUPERSCRIPT`) states `expected_result = 0`. But
`src/lexer.h:15` defines `TK_SUPERSCRIPT` as `0x301` and
`src/lexer.h:19` defines `TK_STR` as `0x301` — the same number — and
`src/parser.c:835` is `if (tok->tk_type == TK_STR) return 1;`. The
kind is compared **by number**, so kind `0x301` is `TK_STR` and is
**accepted**, whatever the payload. Calling the **real** production
function over the whole frozen matrix returns 23 accept / 19 reject
and disagrees with exactly **one** row: F041.

The predecessor's own ABI contract already said so — its decision
table lists `| 1 | TK_STR (0x301) | (any) | **1** | :835 |` and its
section 6 prose says "0x301 is `TK_STR` and is **ACCEPTED**". The
predecessor's C2 phase therefore contradicted **itself**: the contract
was right and the matrix was wrong.

This is binding because the successor is required to satisfy **both**
the frozen fixtures and the actual legacy-C oracle. Under the
predecessor's matrix those two requirements **conflict**, so no
correct implementation can satisfy both.

**P0-2 — ranking CONTROL 6 selected an ineligible candidate.**
The predecessor's `c2-ranking-controls.txt` CONTROL 6 claims
`NEXT_ELIGIBLE_CANDIDATE_WINS` and reports `CAND-004`. But
`c2-eligibility-results.tsv` records CAND-004 as
`production_delegation_feasible = POSSIBLE_BUT_NARROW`, failing
`production_delegation_feasible == YES`, hence `eligible = NO`. The
control was run over `rank-input-full.tsv` — the *state-boundary* set,
whose six rows all carry a hard-coded `eligible=YES` — rather than
over the full hard-eligibility predicate the control claims to test.
The claimed "next eligible winner" is therefore not demonstrated.

**P1-1 — ranking CONTROL 5 perturbed the wrong set.** The same
set substitution: raising CAND-001's R0 changes the leader of the
broad ranking, but the fully eligible set has exactly one member, so
the eligible set's leader does not change.

**P1-2 — inventory accounting.** `c1-candidate-inventory.tsv` declares
`INVENTORY_TOTAL=16` while carrying **17** candidate rows. The
predecessor's own breakdown ("14 historical + 1 hypothetical + 2 new")
sums to 17, and the predecessor's C3 recomputation lists 17 — so the
breakdown and the recomputation are right and only the TOTAL line is
wrong.

**P1-3 — LEXER07 failure counts conflated.** The predecessor's C3
comparison states "21 sources fail (9 stage0-only + 6 all-4 + 6
resolved-since-baseline)". The 21 is the **baseline** count. The
**current** failing set is 15 (9 `NO_FALLBACK` + 6 `ALL_FAIL`): the six
`S0_DIVERGED_FROM_S1_S2_S3` sources (fzf, json, net, set, sqllite,
stat) now pass all four stages and are not current failures.

None of the five defects touches the selection, the ABI, the
eligibility conjunction or the scoring. `CAND-001
parseValidPostControlFlowToken` remains the unique eligible candidate
and the proposed PolyC ABI is unchanged.

## 2. Scope

### allowed

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/**`
  (new evidence for this ACT only)
- `docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01.md`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01.md`
- `docs/factory/act-handoff-map.tsv` (one appended row)
- `docs/ROADMAP.md` (one appended status section)

### forbidden

- any mutation under `src/`, `tools/`, `scripts/`, `src/CMakeLists.txt`
- any mutation of the predecessor's closed evidence directory, ACT
  document or HANDOFF (F14)
- any history rewrite: no amend, rebase, reset, force-push,
  filter-branch, filter-repo or git replace
- rebuilding any compiler generation
- regenerating evidence unrelated to the five defects
- changing the selected candidate, the ABI, the eligibility
  conjunction or the scoring

## 3. Entry gate

```text
git branch --show-current   -> main
git status --short          -> (empty)
git rev-parse HEAD          -> ac639d06d8e0a24ff01d09e90c68290add0231d0
```

## 4. Principal RED

`c1/c1-f041-red.txt` and `c1/c1-fixture-oracle.txt`: the predecessor's
frozen matrix is checked row-by-row against the **real** production
`parseValidPostControlFlowToken`, linked from
`build/CMakeFiles/hcc.dir/parser.c.o` (compiled from `src/parser.c`).
The witness is the production function itself — the predecessor's ABI
contract section 8 forbids a handwritten re-implementation of the
decision table as the reference.

The oracle harness is **committed** (`c1/c1-oracle-harness.c`), and
`c1-fixture-oracle.txt` records the exact build, link and run commands,
so the witness is reproducible by a reviewer rather than merely
transcribed. The live re-run is byte-identical to the recorded
transcripts (verified by `diff` in `c3/c3-required-result.txt`).

```text
ROWS=42 ACCEPT=23 REJECT=19 DISAGREE=1     (predecessor matrix)
ROWS=42 ACCEPT=23 REJECT=19 DISAGREE=0     (corrected matrix)
```

## 5. Implementation boundary

No production change. This ACT publishes corrected **contract
artifacts** and corrects a **verdict**. The corrected fixture matrix
agrees with the production oracle on every row, so the successor's
direct differential becomes satisfiable.

## 6. Acceptance criteria

See `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c3/mandatory-ac-status.tsv`
(AC01..AC14, each with a concrete re-runnable command).

**AC14 is DEFERRED at the C3 snapshot.** It asserts that the
predecessor's verdict has been corrected through the
`ACT-Supersedes` / `ACT-Corrected-Verdict` trailers, and that is true
only once this ACT's CLOSE commit exists and carries them. A validated
*proposed* commit message is not a committed CLOSE. AC14 is established
in the CLOSE phase, against the actual CLOSE commit.

## 7. Conservation gates

- `make gate-fast` -> RC=0
- `sh scripts/quality/factory-v2-test.sh` -> PASS=53 FAIL=0
- `sh scripts/quality/factory-append-only-test.sh` -> PASS=11 FAIL=0
- `git diff --check <first>..<close>` -> RC=0, over the **committed**
  correction range, so the new files are covered by construction
  (a working-tree-only `git diff --check HEAD` does not see untracked
  files, and a `git add -N` check found three trailing-blank-line-at-EOF
  defects in this ACT's own new files)
- predecessor evidence / ACT document / HANDOFF deltas -> 0

## 8. Halt taxonomy

- `HALT_SCOPE_EXPANSION_REQUIRED`
- `HALT_F14_VIOLATION`
- `HALT_PRODUCTION_MUTATION`
- `HALT_MANDATORY_AC_NOT_GREEN`
- `HALT_CONTRACT_DEFECT_UNRESOLVED` (the predecessor's, resolved here)

## 9. Residue

- The review observed that the digest it read omitted ten evidence
  files, including the final AC ledger and the C4 terminal ledger.
  Those files **do exist** in the predecessor's evidence directory
  (50 files in total). This is a completeness observation about the
  digest, not a defect in the evidence, and this ACT does not
  regenerate them.
- The `F-NO-PYTHON` and `F-POLYC-TOOLS` checkers fail on PRE-EXISTING
  baseline violations in files this ACT does not touch. They are
  recorded, not waived.

## 10. Commit topology

```text
1. RED      (the F041 defect, reproduced against the real C oracle)
2. EVIDENCE (the corrected contract artifacts and their verification)
3. CLOSE    (the HANDOFF and the corrected predecessor verdict)
```

## 11. Closure handoff

`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01.md`.

The CLOSE commit carries:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT-Corrected-Verdict: HALT_CONTRACT_DEFECT_UNRESOLVED
```

A `PASS` verdict forbids `HALT_CLASS` and `BLOCKS_NEXT`
(`tools/factory/factory-halt-classification.HC`); the canonical
example in `docs/factory/GIT-METADATA.md` section 2.3 has exactly this
shape. The trailer set is validated by
`scripts/quality/factory-v2-commit-msg-check.sh` (STATUS=PASS, RC=0).
