# ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT / evidence-only correction
**Class:** SELFHOST / PARSER / EVIDENCE-INTEGRITY / APPEND-ONLY
**Priority:** P1
**Repository:** `s1onique/polyc`
**Checkout:** existing `main` checkout; no ceremonial branch
**Expected ENTRY_HEAD:** `a43348acc481146853b771609c75e4e0d324e375`
**Expected ENTRY_TREE:** `b4447a6bf8adbfc177ad7991dc7593833ad224f9`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE08` (CLOSE/`PASS`; never rewritten)
**New production authority:** NONE
**Next implementation target:** NONE
**Production semantic delta:** 0
**Successor authorization:** NONE

---

## 0. Mission, evidence authority and scope

Reconcile two evidence-integrity defects in `SLICE08` **without**
retroactively repairing its committed files:

1. `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c0/inherited-controls-contract.tsv`
   freezes 23 inherited control IDs, but
   `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c3/inherited-controls-join.tsv`
   appears to contain 24 data rows, including `SL-EC-06`, while claiming
   `INHERITED_CONTROLS_JOINED=23` and `INHERITED_CONTROLS_EXTRA=0`.
   Determine from committed bytes whether `SL-EC-06` was part of the
   predecessor's frozen obligation, an extra supplementary experiment, a
   C0 omission, or another condition. **Do not assume which before
   executing C0.**
2. `c1/selected-source-and-abi.txt` reports source-range SHA-256
   `a9a33ff1c3993560f5504582ec372c3f64573caca630e8cda32f58755bbd0fea`
   beside RECON07's frozen
   `a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199`,
   and calls them `IDENTICAL`. Reconstruct the bytes, source range and
   commit/tree chronology; distinguish entry range, C1 range, C2
   post-factoring location, and any reflowed same-numbered line range.
   Treat an ungrounded chronology as `UNPROVEN`, not a harmless typo by
   assertion.

Do not challenge the already-demonstrated production transfer merely
because its historical proof accounting contains errors. Conversely, do not
promote `SLICE08` `AC33`/`AC35`/`AC42`/`AC49`/`AC50 = PASS` as
independently reconstructed until the corresponding evidence obligations
have been proved.

### 0.0 Authority order

1. current repository commit graph and exact blobs;
2. frozen RECON07 `c2/selected-*` contracts and RECON07 CLOSE;
3. `SLICE08` C0 frozen controls and the 50-AC contract;
4. literal `SLICE08` C3 observations and control joins;
5. this correction's own new independent experiments;
6. historical handoffs/digests (secondary).

The supplied LEAMAS range digest is a non-authoritative starting lead, not
a substitute for the committed bytes.

### 0.1 Explicit non-goals and forbidden modifications

Never modify tracked:

- `src/**`, including `src/parser.c` and `src/CMakeLists.txt`;
- `tools/bootstrap/**`;
- existing files under `tools/quality/**`, `tools/factory/**`,
  `scripts/**`, `.githooks/**`;
- any prior `evidence/**` directory (including all `SLICE08` C0-C4
  contents);
- previously closed ACTs/HANDOFFs, RECON06 HALT, previous roadmap
  history or previously published commit messages;
- tests, fixtures, dependencies, runtime, provider/selector settings,
  CMake/Make rules, compiler flags or the eight active parser-authority
  source paths.

Allowed changes are only:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01.md
docs/factory/act-handoff-map.tsv             # exactly one additive row
docs/ROADMAP.md                              # bounded, additive disposition
.factory/epic-board.md                      # ONLY if canonically board-owned
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/**
tools/quality/parser-slice08-evidence-correction01-*.HC   # NEW substantive tools
```

No Python; no new dependency; no new branch by default; no hidden
shell-budget workaround. Small operator shell commands for Git/read-only
diagnostics are permitted, but substantive evidence
reconciliation/checkers must be PolyC and independent of the rows they
judge. **Do not add a new gate or change gate semantics inside this
ACT.**

### 0.2 Outcome vocabulary

- `PASS_EVIDENCE_CORRECTED` -- independent evidence proves all frozen
  obligations, explains both inconsistencies exactly, and supplies
  truthful new correction-owned reconciliations. No claim that C0/C3
  historical files were fixed.
- `PASS_REVIEW_ONLY` -- independent checks demonstrate the apparent
  anomalies were false positives caused by the digest/parsing, with raw
  committed evidence for every correction AC. This outcome requires no
  actual historical contradiction; it is **not** a waiver.
- `HALT_FROZEN_CONTROL_UNPROVEN` -- one or more original, truly frozen
  obligations remain unproved and cannot be discharged independently
  within this evidence-only ACT.
- `HALT_PROVENANCE_UNBOUND` -- required historical source measurement
  cannot be assigned to an actual tree/range/time, or a source assertion
  is unprovable under the frozen contract.
- Other specific HALT codes in section 9.

Use the repository's actual approved `ACT-Verdict` trailer grammar
(usually `PASS` or `HALT`). Record the exact disposition separately in
the HANDOFF. **Never invent a new trailer enum.**

---

## 1. C0 -- RED: entry, preservation freeze and exact defect reproduction

Must happen before writing any correction result or creating a new
verifier.

1. Check `main`, expected full HEAD/tree, pristine tracked/index state,
   zero replace refs, and exact prior `SLICE08` CLOSE trailers. If any
   unexpected tracked change, staged material, ancestry gap or
   intervening commit exists, HALT; do not reset, amend, rebase or
   force-push.
2. Re-read `docs/factory/DOCTRINE.md`, Factory-v2 ACT/trailer rules,
   F14, append-only rules, the `SLICE08` ACT's exact
   `AC33`/`AC35`/`AC42`/`AC49`/`AC50` wording, and the RECON07 selected
   contract. Existing repo rules override this proposal on mechanics;
   HALT if irreconcilable.
3. Freeze the SHA-256 plus Git blob IDs of every closed predecessor
   path, including RECON07's negative-control contract, RECON06 HALT,
   `SLICE07` correction, and the complete `SLICE08` C0/C1/C3/C4 set.
   Store source tree/ref and path count; later compare the **entire**
   frozen set, not merely a sample.
4. Read three actual committed sources:
   - `evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-negative-controls.md`
   - `evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-causal-contract.md`
   - `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c0/inherited-controls-contract.tsv`
   - `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c3/inherited-controls-join.tsv`
5. Parse only valid tab-separated data rows with exact expected column
   counts; skip comments, field explanations, blank lines and summary
   `KEY=VALUE`. Preserve original bytes; produce ordered IDs, duplicates,
   counts and multiset/set differences for all three (RECON07
   obligations, `SLICE08` C0, `SLICE08` C3). **No hardcoded expected ID
   list in the verifier.** The parser must reject malformed data rather
   than silently discard it.
6. Identify `SL-EC-06` in each source by exact ID, compare full semantic
   contract (subject, phase, adverse edit, detector, provenance) and
   never infer that a similarly named control existed just because a C3
   row asserts it did.
7. Reproduce the exact hash contradiction from committed
   `c1/selected-source-and-abi.txt` and the frozen RECON07 source-range
   contract. Preserve both complete SHA-256 strings and their
   corresponding quoted commands.
8. Freeze a new 28-ID correction acceptance contract (`CAC01..CAC28`)
   and the 10-ID correction control contract (`E8-NC-01..10`) before
   outcomes. Freeze names, subject, detector, expected adverse result,
   command type and witness provenance. **Never change these contracts
   after C0.**
9. Record five REDs: (R1) join accepts extra `SL-EC-06`; (R2) inherited
   claimed count disagrees with actual data rows; (R3) source SHA strings
   differ but equality is asserted; (R4) a wrong phase/range can be
   mistaken for entry-source identity; (R5) a fabricated cross-phase
   execution credit can masquerade as an independent control. Each RED
   must be an **actual observed failure of the historical claim**,
   demonstrated with read-only committed-byte comparisons or an existing
   verifier. The new PolyC auditor is built only at C2; never claim to
   have executed it at C0. If a lead is disproven, record that
   explicitly rather than falsifying a RED.
10. Record fresh, reason-specific baseline results (as this is an
    evidence-only ACT, these may be reused read-only at C1/C3 but must
    be measured at the correction entry): parser 376/376 over 90 files
    and ordered MD5 `b6f117eb1386ca80f81bc06226e2a741`, three direct
    lexer differentials, `LEXER07` failure-identity MD5
    `7ee761440de83552e751e3c3976c1683`, known cross-target failure count
    67, known Python policy violations 12, `F-POLYC-TOOLS=UNAVAILABLE`,
    `gate-fast` and `gate-push`. Any unexpected new failure is a HALT,
    never renamed historical.

Write `c0/` evidence and make a RED commit with valid Factory-v2
trailers. **Freeze C0 contracts once committed.** If entry itself fails,
follow the repository's approved pre-entry HALT procedure rather than
inventing a successful RED commit.

---

## 2. C1 -- EVIDENCE: committed-byte and source-chronology reconstruction

### 2.1 Control inventory authority

Produce a three-way ID reconciliation with **actual counts, not expected
literals**:

- `F` = exact obligations extracted from the committed RECON07 frozen
  `selected-negative-controls.md` and `selected-causal-contract.md`,
  after determining whether multiple names describe a shared obligation.
- `B` = all IDs from `SLICE08` C0 `inherited-controls-contract.tsv`
  (reported 23).
- `J` = all IDs from `SLICE08` C3 `inherited-controls-join.tsv`
  (reported 24).

Compute and output `F\B`, `B\F`, `B\J`, `J\B`, ID duplicates, content
mismatches, and `(row_count, distinct_ID_count)` per source. Note that
shared physical experiments do not permit two different ID rows to
silently vanish; keep `control_id` and `physical_execution_id` as
separate fields.

For each ID present in `J`, bind its adverse execution (if any) to
actual command/exit, subject file, compiler/object identity, detector,
positive baseline, observed adverse outcome, restoration, and source
evidence. If a row only says `YES` without external execution evidence,
classify it `ASSERTION_ONLY` until independently checked.

Classify `SL-EC-06` by evidence, with one of:

1. `SUPPLEMENTAL_NOT_FROZEN` -- a new real control added in C3; not part
   of the 23-ID C0 obligation. It must be excluded from the frozen join
   but may be retained in a separate appendix and counted truthfully.
2. `FROZEN_OMITTED_FROM_C0` -- RECON07 really froze it but `SLICE08` C0
   omitted it. Preserve the missing obligation and perform a new, named
   adverse test in this correction if feasible; never backdate it to
   C0/C3.
3. `DUPLICATE_OR_ALIAS` -- prove the exact frozen equivalence/alias
   clause, not successor-authored substitution. An alias is not a second
   physical experiment.
4. `UNPROVEN_OR_INVENTED` -- not grounded in frozen authority and not
   independently executed. Record as extra/unproven, never a PASS.

If any frozen obligation cannot be proven by its required subject and
detector under this correction's allowed scope, HALT. **A supplemental C3
row alone cannot repair a missing C0 frozen obligation.**

### 2.2 Exact source-hash / phase reconstruction

Use Git object reads for each point in the five-commit `SLICE08` chain,
not whichever `src/parser.c` is currently in the workspace:

```sh
git show <SLICE08_C0_SHA>:src/parser.c | sed -n '1683,1684p' | shasum -a 256
git show <SLICE08_C1_SHA>:src/parser.c | sed -n '1683,1684p' | shasum -a 256
git show <SLICE08_C2_SHA>:src/parser.c | sed -n '1683,1684p' | shasum -a 256
git show <SLICE08_C4_SHA>:src/parser.c | sed -n '1683,1684p' | shasum -a 256
```

Also derive the RECON07 frozen range at its CLOSE commit, and identify
the actual post-refactor helper and call-site by source text/function
boundaries rather than assuming old line numbers retain semantic
meaning. Compute SHA-256 **separately** for: the original `1683..1684`
slice, the current `1683..1684` slice, and the moved legacy predicate
under the selector-OFF arm. These are different byte-range identities
unless proven equal.

For each claimed SHA value, output `sha256`, `commit`, `tree`, `file`,
`range`, range-finding method, `phase`, actual bytes count, and semantic
subject. If `a9a33ff1...` is demonstrably the moved/shifted or stale
line-range hash, label it as such; do not call it identical to
`a9fcb6a7....` If neither claimed hash is reproducible, or the evidence
asserted it existed at a phase where the subject did not, record the
exact provenance defect and HALT unless a new independent correction
measurement proves the required historical fact.

Prove whether `c1/selected-source-and-abi.txt` was committed in C1 and
whether the source text it describes actually existed at that commit. A
C1 document describing post-C2 source is an evidence chronology defect,
not just a typographical mismatch. Document the earliest commit where
the helper/call site existed, using Git's file-object history. **Do not
infer intent.**

### 2.3 Reproduce production conservation read-only

Check current `main` has all eight PolyC production authorities by exact
exported symbols/caller relocations (where available), and preserve
`BootstrapDefaultArmTerminates` evidence. Re-read
`c3/post-polyc-mutation-and-restoration.txt` to confirm it concerns a
**newly executed** PolyC mutant, separate from RECON07's C mutant; do not
re-run or re-label them.

Write C1 evidence, commit EVIDENCE. **No source mutation is authorized
in the project checkout.**

---

## 3. C2 -- IMPL: independent PolyC proof auditor + fresh adverse tests

Implement exactly one bounded substantive quality tool if needed:

```text
tools/quality/parser-slice08-evidence-correction01-verify.HC
```

Required modes (or equivalent documented CLI): `FREEZE`, `JOIN`,
`PROVENANCE`, `NEGATIVE`, `VERIFY`, `SELFTEST`. The verifier must derive
IDs and facts by parsing file bytes; **do not hardcode `SL-EC-06` as a
special-case rejection or hardcode expected output summaries.** The tool
must be able to report both historical-original and corrected supplemental
ledgers as distinct namespaces. It must detect contradictory claims,
truncated rows and unexpected extra controls **even when the
`INHERITED_CONTROLS_EXTRA` summary falsely says zero**.

Run ten correction-owned negative controls with a pristine `PASS` ->
targeted adverse `FAIL` -> restored `PASS` sequence on disposable fixture
copies/read-only historical blobs:

| ID | Injected defect | Required reason-specific rejection |
|---|---|---|
| `E8-NC-01` | Add one ID to J absent from B | `EXTRA_ID` with that exact ID |
| `E8-NC-02` | Delete one expected B ID from J | `MISSING_ID` with that exact ID |
| `E8-NC-03` | Duplicate one J row ID | `DUPLICATE_ID` |
| `E8-NC-04` | Keep ID, alter subject or phase | `SUBJECT_OR_PHASE_MISMATCH` |
| `E8-NC-05` | Keep ID, alter frozen detector/adverse action | `FROZEN_SEMANTICS_MISMATCH` |
| `E8-NC-06` | Change summary JOINED/EXTRA without changing rows | `CLAIMED_COUNT_CONTRADICTS_ROWS` |
| `E8-NC-07` | Supply two unequal SHA-256 values with IDENTICAL | `FALSE_HASH_EQUALITY` |
| `E8-NC-08` | Relabel post-C2 range as pre-C2 original range | `SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH` |
| `E8-NC-09` | Backdate a C3 experiment to an unexecuted C0 obligation | `UNPROVEN_EXECUTION_PROVENANCE` |
| `E8-NC-10` | Tamper source digest, drop a frozen predecessor path or truncate evidence | `IMMUTABILITY_OR_TRUNCATION_FAILURE` |

For each, report exact physical execution ID, relevant file digests,
input mutation, expected and actual failure class, actual exit status,
isolation and restoration. A synthetic test may prove the auditor's
detector; it **cannot itself discharge a historically frozen
adverse-execution obligation.** Perform an actual new adverse experiment
in a detached temporary worktree or disposable copy if `F` includes a
previously untested obligation and it is within this ACT's evidence-only
authorization. If it would require tracked production changes or a
different semantic subject, HALT and split the work into a separately
authorized ACT.

Create a correction-owned truth table, not an edited predecessor file:

```text
control_id | frozen_source | frozen_phase | original_C0_status |
original_C3_status | correction_disposition | execution_id |
subject | detector | original_evidence | new_evidence |
independent_witness | counted_as_independent_experiment
```

Use accurate statuses such as `ORIGINAL_EXTRAROW_NOT_FROZEN`,
`ORIGINAL_UNPROVEN`, `SUPPLEMENTAL_EXECUTED`, `CORRECTION_EXECUTED`,
`CITED_PRIOR`, `FROZEN_DISCHARGED`, `NOT_REQUIRED_BY_FROZEN_CLAUSE`; do
not manufacture historical PASS. **Recompute summary from these data
rows, not the other way around.**

Produce a separate provenance table identifying original C0/C1/C2/C3/CLOSE
ranges, hashes, moved helper, and the truthful correction to the C1
claim. Preserve the two original SHA strings and a machine-verifiable
statement `ORIGINAL_HASH_EQUALITY_CLAIM=FALSE` if disproven.

Commit IMPL with valid Factory-v2 trailers. If only a read-only review
proves both leads false and no code is needed, follow the repo's
prescribed non-empty evidence-only phase discipline instead of inventing
a code change.

---

## 4. C3 -- EVIDENCE: independent verification, conservation and gates

The independent witness **must NOT** use the verifier's reported `PASS`
fields as ground truth. It must recompute set differences from source data
and digests from historical Git blobs. Verify the exact same ID sets,
source chronology and contradiction classification using two distinct
implementations or methods, with at least one independent PolyC
implementation. If complete independence cannot be demonstrated, mark it
`UNPROVEN`.

- Read and independently join all `B` controls to their authentic frozen
  predecessor contract and new evidence. Any non-frozen C3 row is
  explicitly extra in the historical join even if independently useful;
  **never claim the original `EXTRA=0` was an accurate row-set
  measurement.**
- Verify C0 frozen correction contracts have not changed since C0.
- Verify all 10 new adverse controls by **reason**, not solely their exit
  codes.
- Bind historical `SLICE08` 50 AC IDs to the actual historical ledger and
  identify exactly those whose proof accounting this correction
  supplements (at least `AC33`, `AC35`, `AC42`, `AC49`, plus
  `AC09`/source provenance as applicable). Do not edit the ledger or
  inherit its PASS blindly.
- Record production authority count 8, with no new code or selector
  change. Parser expected 376/376, 90 files, identical ordered MD5
  `b6f117eb1386ca80f81bc06226e2a741`; direct lexer 89/89, 45/45, 23/23;
  broad `LEXER07` remains FAIL with exact 15 identities, MD5
  `7ee761440de83552e751e3c3976c1683`, zero new; cross-target remains 67
  environment-prefix failures; F-NO-PYTHON remains 12 violations, zero
  new; F-POLYC-TOOLS remains `UNAVAILABLE` if still absent.
- Run `gate-fast` and `gate-push` **serially**, with actual exit codes
  and per-check results. In particular do not contend for shared
  `/tmp/holyc-asm.s` and do not weaken any check. Verify
  source/test/build/evidence path scopes and F14/append-only against the
  complete frozen predecessor set.
- Check `git diff --check`, exact no-production-source delta, no stray
  test/Make/CMake change, no hidden index modifications, zero replace refs
  and valid Factory-v2 phase trailers.
- Prove correction `CAC01..CAC27` PASS by exact IDs; `CAC28` is the only
  `DEFERRED_TO_CLOSE` criterion. Preserve HALT if any required criterion
  cannot be demonstrated.

Commit EVIDENCE.

---

## 5. C4 -- CLOSE: append-only disposition and post-CLOSE terminality

Write the new HANDOFF, exactly one additive `act-handoff-map.tsv` row and
bounded `docs/ROADMAP.md` update. Update the canonical epic board only if
under the allowed set and consistent with its existing authoritative
ownership. **The historical `SLICE08` CLOSE is never changed.**

HANDOFF must explicitly print:

```text
SLICE08_HISTORICAL_CLOSE_VERDICT=PASS_UNCHANGED
SLICE08_C0_FROZEN_CONTROL_ROWS=<measured>
SLICE08_C3_ACTUAL_CONTROL_ROWS=<measured>
SLICE08_C3_HISTORICAL_EXTRA_IDS=<computed list>
SL_EC_06_FROZEN_STATUS=<actual classification>
SLICE08_HISTORICAL_AC33_AC35_DISPOSITION=<truthful assessment>
CORRECTION_FROZEN_CONTROL_OBLIGATIONS_PROVEN=<count>
CORRECTION_SUPPLEMENTAL_CONTROLS=<count>
ORIGINAL_C1_PRINTED_SHA256=a9a33ff1c3993560f5504582ec372c3f64573caca630e8cda32f58755bbd0fea
FROZEN_RECON07_SOURCE_SHA256=a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
SOURCE_HASH_CHRONOLOGY=<exact tree/range/phase result>
PRODUCTION_SEMANTIC_DELTA=0
CURRENT_POLYC_PARSER_AUTHORITIES=8
NEXT_TARGET=NONE
SLICE09_AUTHORIZED=NO
```

The single terminal CLOSE commit requires a repository-valid ACT,
`ACT-Phase: CLOSE`, `ACT-Verdict` trailer, and an evidence-backed
`DISPOSITION` in the HANDOFF. Keep the C4 pre-commit terminality plan as a
**plan**; after the CLOSE run an external read-only check for HEAD/tree,
range length and phases, worktree clean, zero replace refs, no post-CLOSE
commits, correct trailer, all frozen historical files byte-unchanged,
F14, append-only, gate state. **Store the external receipt outside the
terminal commit.** A failed external check cannot be hidden or repaired
by appending a stealth post-CLOSE commit.

Only then discharge `CAC28`. If an obligation remains unproven, close with
an honest HALT and its precise reason, not a PASS of convenience.

---

## 6. Frozen correction acceptance criteria (28)

The C0 TSV must contain exactly the following IDs and semantic
obligations. At C3 verify each ID by independent evidence bindings, not
prose-only statements.

| ID | Obligation |
|---|---|
| `CAC01` | Exact entry HEAD/tree/branch/worktree; no Git replace refs. |
| `CAC02` | `SLICE08` predecessor five-commit CLOSE/trailers/range verified. |
| `CAC03` | RECON07, RECON06 HALT and all closed predecessors byte-frozen. |
| `CAC04` | Only correction-owned paths changed, no production semantic delta. |
| `CAC05` | Original `SLICE08` C0/C3 control files read from actual commit blobs. |
| `CAC06` | Original RECON07 frozen selected-negative/causal contracts read and hashed. |
| `CAC07` | C0 freezes exactly 28 correction AC IDs before observations. |
| `CAC08` | C0 freezes exactly 10 new control IDs, subjects and target detectors. |
| `CAC09` | Exact data-row parsing rejects malformed/truncated unknown content. |
| `CAC10` | All source control ID counts/dedup/set differences mechanically computed. |
| `CAC11` | `SL-EC-06` classified against RECON07 and `SLICE08` frozen authorities. |
| `CAC12` | Frozen IDs' subjects/phases/detectors bound, not successor-reinterpreted. |
| `CAC13` | Supplementary experiment separated from frozen control obligation. |
| `CAC14` | Historical control-sharing vs independent physical executions truthful. |
| `CAC15` | Every frozen obligation independently discharged or HALT. |
| `CAC16` | Original SHA strings and false-equality assertion captured verbatim. |
| `CAC17` | Entry, C0, C1, C2, C3, CLOSE tree/range hashes independently recomputed. |
| `CAC18` | Moved helper and source chronology shown with actual Git object identity. |
| `CAC19` | Any historical chronology defect explicitly classified, not retroactively edited. |
| `CAC20` | PolyC auditor is substantive, source-derived, independently self-tested. |
| `CAC21` | All ten new reason-specific negative controls actually sensitive. |
| `CAC22` | No vacuous PASS, unknown IDs, duplicate IDs, false `EXTRA=0` or alias inflation. |
| `CAC23` | Corrected AC33/AC35/AC42/AC49 proof statement independently checked. |
| `CAC24` | Eight current production PolyC authorities conserved; zero added. |
| `CAC25` | Parser/lexer/conservation/failure-identity baselines unchanged and honestly reported. |
| `CAC26` | `gate-fast` and `gate-push` executed serially and PASS; all exits recorded. |
| `CAC27` | F14/append-only/Factory-v2/patch hygiene/freeze PASS; C0-C3 complete. |
| `CAC28` | One terminal CLOSE and external post-CLOSE terminality PASS, never preclaimed. |

Any AC that requires independent verification but has only a prose
assertion is `UNPROVEN`. **No waiver.** The correction may finish
`PASS_EVIDENCE_CORRECTED`, `PASS_REVIEW_ONLY`, or an honest HALT under
section 0.2.

---

## 7. Evidence inventory

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/
  c0/
    entry-identity.txt
    predecessor-close-and-freeze.tsv
    frozen-28-ac-contract.tsv
    frozen-10-negative-controls.tsv
    original-c0-c3-raw-counts.tsv
    original-hash-contradiction.txt
    red-reproduction.txt
    baseline-parser-and-lexer.txt
    baseline-cross-target-policy-gates.txt
  c1/
    predecessor-frozen-controls.tsv
    three-way-control-id-set-difference.tsv
    control-subject-detector-provenance.tsv
    sl-ec-06-classification.md
    git-commit-tree-chronology.tsv
    entry-vs-moved-source-range-hashes.tsv
    historical-phase-integrity.txt
    production-eight-authority-conservation.txt
  c2/
    auditor-source-build-selftest.txt
    correction-owned-control-ledger.tsv
    supplemental-vs-frozen-disposition.tsv
    source-hash-correction-proof.tsv
    ten-negative-controls-results.tsv
    executed-adverse-witnesses.tsv
  c3/
    independent-control-join.tsv
    independent-git-object-recompute.tsv
    independent-negative-control-join.tsv
    original-ac-impact-disposition.tsv
    parser-lexer-identity.txt
    cross-target-tool-policy.txt
    gate-fast.txt
    gate-push.txt
    factory-v2-f14-append-only.txt
    immutable-predecessor-hashes.tsv
    correction-28-ac-status.tsv
  c4/
    terminality-plan.txt
```

Names can be adapted to exact canonical repository conventions before C0
freeze, but the semantic coverage, subject/ID provenance and phase
sequencing are binding. **Do not fabricate logs or backfill absent
evidence.**

---

## 8. Operator checks (examples, not a replacement for the PolyC auditor)

```sh
# Read-only: verify live identity first.
git status --short
git rev-parse HEAD 'HEAD^{tree}'
git branch --show-current
git replace -l

# Read-only historical blob examples.
git show 'a43348acc481146853b771609c75e4e0d324e375:evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c0/inherited-controls-contract.tsv'
git show 'a43348acc481146853b771609c75e4e0d324e375:evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c3/inherited-controls-join.tsv'

# Source range SHA-256 is NOT the Git object ID:
git show '3eb8afa4f02ae4c5ff9e86cc32ac34fb4f8c2f9b:src/parser.c' \
  | sed -n '1683,1684p' | shasum -a 256
```

Git's documented `git show <commit>:<path>` reads an immutable versioned
blob; this avoids confusing current line numbers with predecessor source
ranges. Detaching a worktree for disposable adverse tests is likewise
supported; **do not modify tracked main during experiments.**

---

## 9. HALT taxonomy and terminal report

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_CLOSE_UNVERIFIED
HALT_FROZEN_ARTIFACT_MUTATED
HALT_FROZEN_CONTROL_UNPROVEN
HALT_CONTROL_SUBJECT_SUBSTITUTED
HALT_CONTROL_ID_JOIN_OR_PROVENANCE
HALT_PROVENANCE_UNBOUND
HALT_PHASE_CHRONOLOGY_MISMATCH
HALT_VERIFIER_NO_OP_OR_INSENSITIVE
HALT_NEGATIVE_CONTROL_INCOMPLETE
HALT_PRODUCTION_SCOPE_VIOLATION
HALT_NEW_REGRESSION
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_V2_F14_APPEND_ONLY
HALT_MANDATORY_AC_UNPROVEN
HALT_TERMINALITY
```

Terminal report must contain exact ACT/entry/final HEAD/TREE, phase
commits, clean/replace-ref/continuation status, disposition, F/B/J actual
row and unique-ID counts and differences, `SL-EC-06` classification,
actual source hash/tree/range chronology, number of independent physical
experiments, 10-control result, 28-AC result, pre/post parser/lexer
identities, new failure identities, all named gate statuses, immutable
predecessor path/hash count, and `NEXT_TARGET=NONE`.

**Never claim SLICE08 historically executed controls or proof steps that
were first supplied by this correction.** The correction may supplement
their evidentiary sufficiency; it cannot change the historical time at
which an experiment took place.

---

## 10. Explicit successor rule

When this correction closes, the next proposed ACT is
`ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08`: fresh source-bound
reconnaissance and selection after eight authorities. **Do not assume
SUB-004, do not implement SLICE09, and do not make either a side effect
of this evidence-only correction.** If this correction HALTs, report the
governance-versus-production-blocking class using the canonical doctrine
rather than guessing.
