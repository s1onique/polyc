# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03
ACT-Phase: RED

Inherits from:
`ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02`
(closed mechanically-false PASS_FORWARD_BASELINE_REQUALIFIED at 3b38d69).

**Class:** CORRECTION / EVIDENCE-CLOSURE-AUTHORITY REPAIR

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:**
`ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02`
(closed 3b38d69 with `ACT-Verdict: PASS_FORWARD_BASELINE_REQUALIFIED`,
which is mechanically contradicted by this ACT's C1 reproduction).

**Predecessor close:** `3b38d6910c7a117b0a98a98d84ab5114da70cb83`

**Predecessor effective disposition (corrected by this ACT):**
`HALT_FALSE_GREEN` — see C1 reproduction.

**Production subject:** `BootstrapCalcPadding`

**Production authority at entry:** `LEGACY_C` (unchanged)

**Target production mutation:** **NONE** (evidence and authority files only)

**Successor currently blocked:** `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01`

---

## 0. Mission

Repair three closure-authority defects in the predecessor ACT
(CORRECTION02) without modifying parser-padding semantics:

1. **D-WS**: AC34 `PATCH_HYGIENE_ERRORS=0` was claimed PASS against
   an empty working-tree `git diff --check`.  The committed 5-commit
   range `1274f36..3b38d69` actually contains one whitespace defect:
   `evidence/.../c2/c2-baseline-verifier-negative-control.txt:71`
   has a trailing blank line at EOF.
   ACT §42 says this is the literal predicate for `HALT_PATCH_HYGIENE`.

2. **D-TEMPORAL**: AC38 (`EXACT_COMMIT_COUNT_AT_CLOSE=5`) and AC40
   (`POST_C4_COMMIT_COUNT=0`) were evidenced by pre-C4 prediction
   (`git rev-list --count 1274f36..HEAD = 4`) and a tautology
   (`git rev-list --count HEAD..HEAD` = 0).  Neither is a load-bearing
   post-C4 external witness.  The factual commit count IS 5, but
   the committed evidence mechanism cannot prove it.

3. **D-PROV**: The canonical baseline registry
   `docs/factory/LEXER07-BASELINE-AUTHORITY.tsv` declares a
   `field/value/evidence` schema but its data rows mix real SHAs
   with textually labelled-but-not-actually-hashed values, and the
   producer-binary SHA / four-compiler-generation SHA / exact command
   SHA / real corpus-input SHA were never captured.  Determinism on
   the current substrate is real; provenance-binding to the
   producing tools and compiler generations is not yet established.

The Branch-B architecture, the prospective baseline identity, the
classification (15 TEST_INFRASTRUCTURE_DRIFT + 6 KNOWN_LEXER07_SEMANTIC_DEFECT
+ 0 UNRESOLVED), and the negative-control witnesses all remain valid
engineering facts.  Only the closure-authority mechanics are
repaired.

---

## 1. Why

A Factory v2 ACT's terminal verdict must be supportable by the
committed evidence.  When the committed evidence is mechanically
contradicted by `git diff --check <range>`, the verdict is FALSE_GREEN
regardless of intent.  This ACT is the smallest bounded correction
that restores a defensible closure without rewriting history
(F14: append-only Git history; corrections are new commits).

Per F4: a HALT is a successful execution outcome when its predicate
is true.  Here the predicate of `HALT_PATCH_HYGIENE` is true on
the committed range.  The ACT that closed PASS_FORWARD_BASELINE_REQUALIFIED
while the predicate was true committed a FALSE_GREEN closure.

This ACT:

- records the FALSE_GREEN disposition of the predecessor (does NOT
  rewrite its C4 commit, per F14);
- produces forward-only fixes to the three defects;
- re-closes with a verdict that is mechanically supported by the
  resulting committed tree.

---

## 2. Scope

### allowed

- Forward-only edits to evidence and authority files in
  `docs/factory/LEXER07-BASELINE-AUTHORITY.tsv`,
  `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c4/**`,
  `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03/**`,
  and a new HANDOFF under `docs/factory/`.
- Reissuing the prospective LEXER07 baseline qualification ONLY to
  bind provenance to real producer/compiler/input/command SHAs
  (no engineering change to the result — the matrix SHA
  `ee83e375...`, failures SHA `9d8ce2e0...`, provenance SHA
  `7cdf8016...`, counter SHA `0aa2315e...`, and combined SHA
  `00c54408...` are the same; only the producer/compiler/input/command
  evidence becomes real).
- Removing the trailing blank line at EOF of the c2 evidence file
  named in D-WS by introducing a forward-only rewritten copy in
  `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03/c2/`.

### forbidden

- Modifying parser-padding implementation files:
  - `tools/bootstrap/selfhost-parser-padding.HC`
  - `tools/quality/parser-padding-algebraic-invariants.HC`
  - `tools/quality/parser-padding-generation-provenance-verify.HC`
  - `tools/quality/parser-padding-oracle-impl.c`
  - `src/parser.c`
- Modifying the production-engineering closure of CORRECTION02's C2
  (the prospective baseline engineering result is preserved).
- Modifying the historical C0/C1/C2/C3 evidence directories of the
  predecessor ACT (F14: append-only).
- Amending, rebasing, or rewriting any committed history.
- Deleting or weakening any Factory v2 quality gate.
- Changing the public closure status of the predecessor ACT
  (CORRECTION02 closes 3b38d69 with `ACT-Verdict:
  PASS_FORWARD_BASELINE_REQUALIFIED` in the committed record; this
  ACT records the corrected disposition in NEW artifacts only).

---

## 3. Entry gate

```text
git branch --show-current  → main
git status --short         → clean of tracked changes
git rev-parse HEAD         → 3b38d6910c7a117b0a98a98d84ab5114da70cb83
```

The worktree at entry MAY contain untracked `build/` artifacts
(gitignored).  These are recorded but not committed.

---

## 4. Principal RED

### D-WS RED

```sh
git diff --check 1274f36..3b38d69
```

Observed output at entry:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c2/c2-baseline-verifier-negative-control.txt:71: new blank line at EOF.
```

This single line is the literal predicate of
`HALT_PATCH_HYGIENE` in predecessor ACT §42.

### D-TEMPORAL RED

AC38 evidence file
`evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c4/c4-entry-identity.txt`
contains:

```text
C4_REV_LIST_ENTRY_TO_HEAD=4
# (C0, C1, C2, C3; C4 is the 5th commit)
```

This is a prediction computed BEFORE the C4 commit was made.  After
the C4 commit exists, the same predicate cannot be re-derived from
this evidence.  Likewise AC40 was not recorded in any committed
artifact; the `git rev-list HEAD..HEAD = 0` invocation is a
tautology that holds for ANY HEAD.

### D-PROV RED

`docs/factory/LEXER07-BASELINE-AUTHORITY.tsv` rows for the four
provenance producers (producer binary, four compiler generations,
corpus input, exact command) are either labelled
`(unchanged from committed)`, `(none; tool invoked directly)`,
or `N/A (uses hcc + hcc-bootstrap02/03/04)`.  None are real
SHA-256 digests of the producing artifacts.  The TSV is therefore
NOT yet authority for forward conservation; the determinism result
A == B is real but unbound.

---

## 5. Implementation boundary

This ACT does **NOT** regenerate the prospective baseline.  The
qualification result is correct on the current substrate (verified
by A==B determinism and 4 negative controls NC1..NC4).  What changes
in C2 is the EVIDENCE that records which artifacts produced the
result, so future ACTs can re-derive the same authority boundary.

Forward-only file changes:

1. **D-WS fix**: introduce
   `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03/c2/c2-baseline-verifier-negative-control-rewritten.txt`
   containing the same content as
   `c2-baseline-verifier-negative-control.txt` minus the trailing
   blank line.  Record the SHA-256 of both files to prove
   equivalence-of-content (modulo the trailing newline).

2. **D-TEMPORAL fix**: introduce
   `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03/c3/c3-pre-c4-frozen-tip.txt`
   captured BEFORE the CORRECTION03 C4 commit, recording:

   ```text
   PRE_C4_FROZEN_TIP_SHA=<sha captured by reading git rev-parse HEAD at C2>
   PRE_C4_EXPECTED_FROZEN_TIP_SHA=<sha recorded above>
   EXPECTED_AC38_EXTERNAL_OBSERVER=git rev-list --count <ENTRY>..<PRE_C4_FROZEN_TIP_SHA>
   EXPECTED_AC38_RESULT=4
   ```

   And AFTER the C4 commit, observe via:

   ```text
   git rev-list --count <ENTRY>..HEAD       → 5
   git diff --check <ENTRY>..HEAD            → empty
   git diff <PRE_C4_FROZEN_TIP_SHA>..HEAD    → only c4/ evidence and HANDOFF
   ```

3. **D-PROV fix**: rebuild the four-row provenance table with real
   SHA-256s.  See AC08..AC12.  Schema mismatch is resolved by making
   the schema match the data, not the other way around.

---

## 6. Acceptance criteria

Each AC is a single concrete command and a single expected result.

```text
AC01 git rev-list --count 1274f36..3b38d69
    → 5

AC02 git diff --check 1274f36..HEAD  (after C4 of this ACT)
    → empty

AC03 git diff --check HEAD  (after C4 of this ACT)
    → empty

AC04 git diff --stat <PRE_C4_FROZEN_TIP_SHA>..HEAD
    → only files under evidence/.../CORRECTION03/c4/,
      docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03.md,
      docs/factory/LEXER07-BASELINE-AUTHORITY.tsv,
      docs/factory/act-handoff-map.tsv

AC05 git rev-parse <PRE_C4_FROZEN_TIP_SHA>  (BEFORE C4 commit)
    → <PRE_C4_FROZEN_TIP_SHA captured at C2>

AC06 git rev-list --count <ENTRY>..<PRE_C4_FROZEN_TIP_SHA>
    → 4  (the four commits C0..C3 of CORRECTION03)

AC07 git rev-list --count <ENTRY>..HEAD
    → 5  (the four + C4 of CORRECTION03)

AC08 sha256sum build/lexer07-broad-corpus-4-stage
    → <recorded in evidence/.../CORRECTION03/c2/c2-provenance-rebuild.tsv>

AC09 sha256sum build/hcc
    → <recorded in evidence/.../CORRECTION03/c2/c2-provenance-rebuild.tsv>

AC10 sha256sum tools/quality/lexer07-broad-corpus-4-stage.HC
    → <recorded in evidence/.../CORRECTION03/c2/c2-provenance-rebuild.tsv>

AC11 sha256sum build/correction02-lexer07-baseline-a/corpus-matrix.tsv
    → ee83e375032cf3f39ad8d95838bdd5e4f601fdac3244b7298cf2f68083d3c4fd
    (this AC proves the prospective baseline result is unchanged)

AC12 grep -c '^PRODUCER_.*SHA256' docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
    → ≥ 8  (real producer/compiler/input/command SHAs all populated)

AC13 bash scripts/quality/gate-fast.sh
    → STATUS=PASS

AC14 bash scripts/quality/factory-append-only-test.sh
    → STATUS=PASS

AC15 bash scripts/quality/factory-v2-range-check.sh \
      ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03 $(git rev-parse HEAD)
    → STATUS=PASS, COMMITS=5, FIRST=RED, CLOSE=CLOSE

AC16 sha256sum check
    <(git show 1274f36:tools/bootstrap/selfhost-parser-padding.HC)
    <(git show HEAD:tools/bootstrap/selfhost-parser-padding.HC)
    → identical

AC17 PRE_C4_FROZEN_TIP_SHA is reachable from HEAD by parent edge
    (git merge-base --is-ancestor <PRE_C4_FROZEN_TIP_SHA> HEAD → 0)

AC18 PROSPECTIVE_BASELINE_SHA256 in c4-required-result.txt equals
    00c54408bf29237cf526aeed097f6b097f22ae682683675a0bf5ab9f9c202b9a

AC19 HANDOFF does NOT claim its own SHA
    (no line containing 'CLOSE_SHA=' with a literal 40-char hex value)

AC20 factory-closure-status reconciliation PASS for the new HANDOFF

AC21 PREDECESSOR_DISPOSITION_CORRECTION02 in c4-required-result.txt equals
    HALT_FALSE_GREEN  (per ACT §42 HALT_PATCH_HYGIENE predicate is true
    on the committed range 1274f36..3b38d69)
```

---

## 7. Conservation gates

- All Factory v2 quality gates MUST remain PASS.
- Predecessor subjects (parser-padding implementation files) MUST
  remain SHA-256-identical at C4 of this ACT.
- F14 (append-only Git history from
  `baf5dbd77cf89330699685dffd932c54031c815c` forward) MUST remain
  enforced; the local pre-push hook and the
  `factory-append-only-test` script must continue to PASS.
- The historical C0/C1/C2/C3 evidence directories of CORRECTION02
  are NOT modified.

---

## 8. Halt taxonomy

```text
HALT_RED_NOT_REPRODUCED
  One of D-WS / D-TEMPORAL / D-PROV is not reproducible from
  the committed tree at this ACT's C1.

HALT_F14_VIOLATION
  Historical evidence directory was modified.

HALT_PATCH_HYGIENE
  git diff --check reports an error AFTER all C2 forward-only
  fixes are applied.

HALT_SCOPE_EXPANSION_REQUIRED
  Repair of D-PROV requires re-running the prospective baseline
  qualification (rather than re-binding its existing result).

HALT_PROVENANCE_INCOMPLETE
  Any of the four required SHA-256 rows
  (producer binary, compiler, input, command) cannot be captured
  from committed authority.
```

---

## 9. Residue

### P0 (blocks next decision)

- None.  After CORRECTION03 closes, PARSER-PADDING-DELEGATE01 is
  re-eligible for opening.

### P1 (important near-term work)

- **R-PROV-MULTI-COMPILER**: D-PROV in this ACT captures only the
  final-stage compiler (`build/hcc`).  The qualification result
  depends on four compiler generations (`hcc-bootstrap02/03/04`).
  A future ACT should bind those four SHAs as well.  Recorded as
  residue for `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01` or a
  dedicated provenance ACT.

- **R-CORRECTION02-LEDGER-CORRECTION**: the predecessor HANDOFF
  `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02.md`
  records `PREDECESSOR_VERDICT_AT_ENTRY = PASS_TRUE_GREEN` and
  does NOT contain a note that the committed verdict
  `PASS_FORWARD_BASELINE_REQUALIFIED` is mechanically false.
  This ACT records the corrected disposition in a NEW HANDOFF and
  in `docs/factory/LEXER07-BASELINE-AUTHORITY.tsv`, but does not
  edit the predecessor HANDOFF (F14).  Downstream tooling that
  reads the predecessor HANDOFF will continue to see the
  incorrect claim until a dedicated ACT authorizes rewording.
  Recorded for residue.

### P2 (deferred improvement)

- **R-TAUTOLOGICAL-AC-FAMILY**: AC40 (and similar "POST_X = 0"
  predicates) is a structural weakness.  Future Factory v2 ACT
  templates should require an external observer (push-time hook,
  CI check, frozen-range verifier) for any "POST_* = 0" predicate.

---

## 10. Commit topology

Five commits, matching CORRECTION02 topology:

```text
C0  AUTH            ACT body + entry evidence + F14 baseline of
                    CORRECTION02 evidence directories.
C1  RECON/RED       Reproduce D-WS, D-TEMPORAL, D-PROV from committed
                    tree; capture PRE_C4_FROZEN_TIP_SHA mechanism.
C2  IMPL            Capture producer/compiler/input/command SHAs;
                    write forward-only fixes; produce
                    c2-baseline-verifier-negative-control-rewritten.txt
                    (no trailing blank line) and rebuild the
                    LEXER07-BASELINE-AUTHORITY.tsv provenance rows
                    with real SHAs.
C3  VERIFY          Run all 21 ACs; confirm predecessor subjects
                    unchanged; confirm range-based hygiene empty.
C4  CLOSE           HANDOFF, mandatory-ac-status-final.tsv,
                    act-handoff-map.tsv append; C4 verdict
                    PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED.
                    AC21 records the predecessor corrected disposition
                    HALT_FALSE_GREEN.
```

Do not exceed 5 commits.  No C2.x.

---

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`.

The HANDOFF MUST NOT claim its own SHA.  The CLOSE SHA is obtained
by `git rev-parse HEAD` AFTER the C4 commit exists; it is the
authoritative identity of this ACT.

The HANDOFF MUST contain the corrected predecessor disposition:

```text
PREDECESSOR_CORRECTION02_DISPOSITION_CORRECTED=HALT_FALSE_GREEN
PREDECESSOR_CORRECTION02_DISPOSITION_REASON=
  ACT §42 HALT_PATCH_HYGIENE predicate is true on the
  committed range 1274f36..3b38d69
  (1 whitespace defect: c2-baseline-verifier-negative-control.txt:71
   new blank line at EOF).
PREDECESSOR_CORRECTION02_COMMITTED_VERDICT=PASS_FORWARD_BASELINE_REQUALIFIED
PREDECESSOR_CORRECTION02_VERDICT_MECHANICAL_SUPPORT=NO
PREDECESSOR_CORRECTION02_LEDGER_STATUS_HISTORICAL_PRESERVED_AS_IS=YES
```

The HANDOFF MUST record that the prospective LEXER07 baseline
identity is preserved across this ACT:

```text
PROSPECTIVE_LEXER07_BASELINE_SHA256=00c54408bf29237cf526aeed097f6b097f22ae682683675a0bf5ab9f9c202b9a
PROSPECTIVE_BASELINE_RESULT_PRESERVED=YES
```

The HANDOFF MUST record that PARSER-PADDING-DELEGATE01 is now
unblocked FOR FORWARD USE under the corrected closure:

```text
PARSER_PADDING_DELEGATE01=UNBLOCKED_FOR_FORWARD_USE
BASELINE_AUTHORITY=docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

---

## 12. Board effect at close

Before this ACT:

```text
PARSER-PADDING01-CORRECTION02       PASS_FORWARD_BASELINE_REQUALIFIED  (mechanically false)
FORWARD LEXER07 BASELINE            UNKNOWN  (provenance unbound)
PARSER-PADDING-DELEGATE01           UNCERTAIN  (depends on unresolved predecessor closure)
```

After successful closure of this ACT:

```text
PARSER-PADDING01-CORRECTION02       PASS_FORWARD_BASELINE_REQUALIFIED  (historical, mechanically false)
PARSER-PADDING01-CORRECTION02       corrected disposition recorded in this ACT's HANDOFF: HALT_FALSE_GREEN
PARSER-PADDING01-CORRECTION03       PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED
FORWARD LEXER07 BASELINE            BOUND  (provenance with real SHAs)
PARSER-PADDING-DELEGATE01           UNBLOCKED_FOR_FORWARD_USE
```
