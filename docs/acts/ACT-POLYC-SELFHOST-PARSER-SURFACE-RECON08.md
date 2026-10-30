# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT / fresh successor selection
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-SLICE08 / INDEPENDENT-SELECTION
**Priority:** P1 (next parser-programme ACT)
**Repository:** `s1onique/polyc` (canonical local checkout; remote visibility not assumed)
**Branch:** existing `main` checkout; no ceremonial branch
**Expected ENTRY_HEAD:** `4e01dbac59f18223efc5d168d07d232c6c7f0c42`
**Expected ENTRY_TREE:** `f72d358fe3b033c350cf9a7a841be5bb3333e56e`
**Immediate predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01`
— terminal `PASS` / disposition `PASS_EVIDENCE_CORRECTED` (reported; verify live).
**Historical implementation predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE08`
— CLOSE/`PASS`; byte-immutable.
**Historical HALT:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06`
— `HALT_N06_FROZEN_OBLIGATION_UNPROVEN`; preserve verbatim.
**Possible successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE09`, conditional,
target `NONE` until this ACT selects and freezes one.
**New production authority added by this ACT:** NONE.
**Production semantic delta:** 0.

---

## 0. Mission and the decision to be made

Select exactly one remaining production-reachable, semantically distinct,
causally load-bearing, source-bound, sufficiently bounded legacy-C
parser/AST decision to migrate to compiled PolyC after eight
production-authoritative parser decision sites. If none qualifies, report
a truthful, evidence-backed HALT with no successor target.

This ACT does not implement a ninth authority. It performs a full fresh
census, raw 13-clause eligibility calculation, unmodified canonical
R0–R6 ranking, independent verification of the whole order, real
C-authoritative compiler mutation(s) to validate causal feasibility,
explicit rejection/qualification of ranked candidates, and a frozen
successor contract. "Next number in the SUB series" is not a selection
rule.

### 0.1 Decision invariants

1. Entry is the exact HEAD/tree above; do not accept an intervening commit
   by amending, replaying, resetting or silently updating this ACT. If
   the entry differs: `HALT_ENTRY_IDENTITY` and request a separately
   approved rebase/authorization.
2. Current production parser authority count is **8** until proven
   otherwise by object-level inspection. RECON08 adds **0**.
3. No candidate — including historical `SUB-004` — is preselected.
   Previously ineligible `SUB-005` remains ineligible unless new
   source-bound dependency facts prove otherwise.
4. Treat previously migrated decision sites separately from C functions
   which survive as forwarding adapters. "Function still in C" is not
   proof of unmigrated C semantic authority.
5. A mechanically computed rank is an order of investigation, not proof of
   eligibility beyond the independent checker and not proof of causality.
   A candidate advances only after actual compiler causality and
   ABI/ownership/recovery checks pass.
6. Observations about compiler acceptance are distinct from changed output
   of a compiled witness. A successfully built mutant compiler rejecting a
   witness is a valid reported acceptance change, not a fabricated runtime
   output.
7. Every evidence claim binds its actual Git tree, file/range/semantic
   subject and phase. Source line numbers and source bytes must not be
   presumed stable across the phases or borrowed from RECON07/SLICE08 C2.
8. Pre-migration C mutant experiments cannot discharge a future
   post-migration PolyC mutation. Distinct source/phase/selector/producer/
   execution IDs are frozen in the successor contract.
9. No original historical defect, even if now supplemented, is relabelled
   as having been historically proven. Preserve both the RECON06 HALT and
   the SLICE08 original self-referential C3 rows as immutable history.
10. Frozen control contracts must have a mechanically joined, exact-ID
    witness ledger. Every required row has an independent provenance
    binding, not a path pointing only to itself.

### 0.2 Dispositions

- `PASS_SELECTED` — new ACT passes all 50 acceptance criteria (including
  external terminality); exactly one qualifying candidate and successor
  contract frozen; zero production semantic delta.
- `HALT_NO_CAUSAL_CANDIDATE` — no eligible candidate met bounded

## 1. Binding authority and entry qualification

Read the committed bytes before implementing tools, selecting candidates,
freezing outcomes or mutating experiments.

1. `AGENTS.md`, `docs/factory/DOCTRINE.md`, repository Factory-v2
   range/trailer/closure status rules, F14, append-only invariant,
   `docs/ROADMAP.md`.
2. `docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07.md`, its HANDOFF,
   `evidence/.../RECON07/c2/selected-*` contracts, actual source census,
   source-range corrections, eligibility/ranking and selected causal
   proof. RECON07 selected `SUB-002`; SLICE08 has now consumed it.
3. `docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08.md`, HANDOFF, frozen C0
   control/AC contracts, C1 G0 oracle/fixture, C2 production
   object/delegation, C3 G0–G3, and post-migration PolyC causal evidence.
4. `docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01.md`,
   its HANDOFF, correction C1 three-way control-ID set difference,
   Git-object hash chronology, `c2/correction-owned-control-ledger.tsv`,
   `c2/executed-adverse-witnesses.tsv`, `c3/independent-control-join.tsv`,
   `c3/independent-git-object-recompute.tsv`, the exact C4 plan and the
   reported external CLOSE receipt if accessible. Do not demand a receipt
   from inside the terminal commit.
5. Previous RECON05/RECON06/SLICE07 histories and source-of-truth freezes
   read-only. RECON06's unexecuted candidate stages stay unexecuted; the
   later N-06 supplement remains separate.
6. Live `src/parser.c`, `src/prslib.c`, `src/prsutil.c`, `src/ast.c`,
   `src/ast.h`, active call sites, Makefile/CMake build graph and the
   actual, unmodified canonical 13-clause checker plus R0–R6 ranker
   (discover their exact paths/digests in the repository; do not fabricate
   names).

The source precedence is: actual Git objects and executable observations >
original frozen contracts > new raw source-derived facts > new independent
verification > HANDOFF/digest narrative. The provided LEAMAS range digest
is non-authoritative and cannot substitute for committed files or
executable evidence.

### 1.1 Entry and predecessor audit

- Verify `main`, full HEAD and tree, index/working-tree clean before this
  ACT's own authorized untracked artifacts, zero `git replace` refs, no
  unexpected parent/branch divergence, no post-CLOSE continuation at the
  entry.
- Verify the correction's C0–C4 five-commit range and trailer grammar and
  `PASS_EVIDENCE_CORRECTED` HANDOFF; capture exact end commit/tree and the
  real predecessor path/hash set. Report terminality as
  external-receipt verified, executor-reported, or unavailable; do not
  invent a repository-local receipt.
- Confirm the correction's F=24, B=23, J=24, F\B=J\B={SL-EC-06} and the
  two distinct E8-EC06-A/B experiments. Confirm that old C3 TOTAL=23 /
  EXTRA=0 was false, and that the correction preserves the original
  files. Do not repeat full SLICE08 proof reconstruction as a new programme
  gate unless these facts are materially contradicted.
- Confirm the three distinct source range/time identities: pre-C2
  1683..1684/`a9fcb6a7...`, post-C2 same lines/`a9a33ff1...`, moved
  predicate 1736..1738/`dc43f25e...`. Resolve full values from blobs if
  needed; do not treat any as an authority for the current candidate.
- Reprove all eight active PolyC parser decision sites from current
  selector states, producer objects, exported/imported symbols, successful
  link and (where appropriate) compiled-out C decisions. Do not count a
  library symbol as production authority without a real caller/import and
  active selector.
- Freeze complete closed predecessor ACT/HANDOFF/evidence paths, Git blob
  IDs and SHA-256 values; derive count from live tree rather than copying
  prior reported 231, 5,201 or other stage-specific counts. Retain F14
  checks on the entire enumerated frozen set.

Failure of identity, missing correction evidence, historical hash conflict,
or eight-authority object conservation: **HALT before candidate
selection**. Existing 15 self-referential historical SLICE08 rows are
documented residue, not by themselves an automatic second correction/HALT
if the correction's independent supplementary evidence is verifiable.

---

  observable-causality requirements; full attempted order and reasons
  preserved.
- `HALT_UNBOUNDED_DEPENDENCY` — a shortlisted candidate actually needs AST
  ownership, mutable symbol tables, callbacks, recovery, parser token
  state or unbounded host-state transfer.
- `HALT_*` — other specific entry, source, controls, provenance,
  conservation, gate, or terminality failure listed in §12.

Record the specific disposition in HANDOFF; the terminal commit's
`ACT-Verdict` trailer must use the repo-approved trailer value `PASS` or
`HALT`, not the disposition string. A HALT is not a production regression
claim.

---


## 2. Change scope and runtime discipline

### 2.1 Allowed tracked changes

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08.md
docs/factory/act-handoff-map.tsv          # precisely one new additive mapping
docs/ROADMAP.md                           # bounded, additive disposition
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08/**
tools/quality/parser-surface-recon08-*.HC # new bounded substantive PolyC verifier(s)
Makefile                                 # only additive targets needed to build/run new tools
```

Forbidden: tracked `src/**` (including `CMakeLists`), `tools/bootstrap/**`,
original tests/fixtures, original canonical checker/ranker, historical
ACT/HANDOFF/evidence, existing gate scripts, `.githooks`, compiler/runtime
ABI, dependencies, production selector policy, and unapproved source
edits. No Python introduced, no new third-party dependencies, no large
Bash orchestration, no new ACT branch as ceremony, no
reset/amend/rebase/force-push.

Only isolated, untracked/disposable detached worktrees may mutate
production C source to test candidate causality. No authoritative checkout
source mutation. Remove all temporary worktrees before CLOSE, and prove the
working tree and index clean.

### 2.2 Builds and test execution

- Serialise compiler/JIT/test/gate processes because `/tmp/holyc-asm.s`
  has a known shared-path race. Separate actual output roots, install
  prefixes, caches and object files; do not pretend environment isolation
  is a change to production build wiring.
- If a new Makefile target is needed, check its effective prerequisite
  graph, object production and exit semantics (ordinary prerequisites are
  expanded while reading rules), and check for backslash continuation
  swallowing another command. A target with no executed subject is not
  evidence.
- Verify known local `INSTALL_PREFIX` effects rather than classifying a
  wrong-prefix test failure as a new parser regression; preserve any
  genuine new failure identity as HALT. Do not patch historical SLICE06's
  stale CMake producer branch under this ACT.
- Use a fresh source/binary build in every relevant pristine/mutant/
  restored worktree. No cached or foreign subject object may silently
  satisfy the test. Record producer executable SHA, build flags, object
  digest, process exit and witness result separately.
- Avoid pointer-valued PolyC ternaries (`cond ? ptrA : ptrB`) in new
  quality tools where the previous correction reported an OOM. Use
  explicit `if` assignments for bounded tooling, record the compiler
  limitation as separate debt, and never report a hang as successful
  completion.

---

## 3. Frozen baseline / conservation contract

Freshly measure at C0 and again at C3; old values below are the expected
identities, not preexecuted checks.

| Dimension | Frozen historical value | C0/C3 treatment |
|---|---|---|
| Parser production PolyC authorities | 8 | Reprove selector, exact object symbol, caller import, link, retired legacy decision for each |
| Parser tests | 376/376, 90 files; ordered MD5 `b6f117eb1386ca80f81bc06226e2a741` | Exact sequence/ID equality, not aggregate-only |
| Lexer direct differentials | 89/89, 45/45, 23/23 | Re-run and preserve exact outcomes |
| LEXER07 broad | `FAIL_KNOWN_BASELINE`, 15 failure identities, MD5 `7ee761440de83552e751e3c3976c1683` | Record full failure identity set, zero new, zero divergence; never call suite PASS |
| Cross-target | `FAIL_ENVIRONMENT_PREFIX`, 67 missing `tos.HH` cases | Distinguish runner exit 0 from failed cases, zero new failure IDs |
| F-NO-PYTHON | `FAIL`, exactly 12 historical paths, zero new | Exact set comparison, not just number |
| F-POLYC-TOOLS | `UNAVAILABLE` (checker not landed) | Report as unavailable if still absent; no invented PASS |
| Gate-fast / gate-push | Prior PASS | Re-run serially against RECON08 tree, record exit and each check |
| Factory-v2 / F14 / append-only / closure status | Prior PASS | Re-run source-bound against new exact range and frozen predecessors |

A passing conservation check means **no new regression** while known
historical failures remain nonzero; it does not mean all compiler tests
are green.

---

## 4. C0 — RED: exact identity, historical correction, frozen obligations

1. Verify entry and predecessors per §1; if different, HALT without
   modifying the checkout or inventing a successful RED.
2. Recompute source-of-truth historical correction facts, including
   SL-EC-06 supplementation and source chronology, from committed objects.
   Record any unverified external terminality receipt truthfully.
3. Derive the entire frozen historical path inventory (IDs and byte
   hashes), not a subset. Verify no missing paths or changes.
4. Re-measure the §3 compiler and quality baselines with actual exit
   codes. Object-prove all eight production authorities.
5. Freeze exactly 50 acceptance criteria (AC01..AC50, §10) and 24
   executable negative controls (R8-IC-01..04, R8-EC-01..06, R8-RC-01..05,
   R8-CC-01..04, R8-PV-01, R8-XC-01..04; §8) as committed tables. Every
   control specifies input mutation, exact expected detector class,
   subject, phase, physical execution ID, restoration and witness
   provenance. A frozen definition is not an executed result.
6. Reproduce five RED conditions using existing read-only tools/source
   facts or a small transparent independent pre-C2 read-only check: missing
   live-function ID, stale source-range hash/phase, forged eligible flag,
   forged rank order, and self-referential control evidence. Record
   observed reason-specific rejections; do not claim the C2 auditor already
   ran.
7. Verify Factory-v2 trailer grammar with the repo's actual checker before
   creating the C0 RED commit. Commit only authorized C0 artifacts,
   without unapproved scope creep.

**C0 stop:** unverified entry, predecessor corruption, failure to freeze
contracts, zero real C0 observations, unexpected new parser/lexer
failures, or eight-authority conservation failure.

---

## 5. C1 — EVIDENCE: full source-bound parser/AST census and candidate facts

### 5.1 Complete census

- Enumerate every live function from the current bytes of `src/parser.c`,
  `src/prslib.c`, `src/prsutil.c`, `src/ast.c`. Use actual function
  boundaries and source range SHA-256. Record file, start/end lines, byte
  offsets, semantic anchor, function signature, reachability root,
  exported/call context and whether the remaining C function has active C
  semantic authority or is a forwarding adapter.
- Reconcile to RECON07's reported 272 function rows by explicit
  added/removed/changed/unchanged sets, using stable file/function
  identifiers and source hashes; no invented current total or
  subtraction-based reconciliation. SLICE08 support functions may change
  the total; determine, do not assume.
- Independently verify 100% of census rows against source bytes using an
  algorithm/procedure distinct from the producer (e.g. two PolyC parsers
  with independent range normalization, or PolyC producer plus
  source-bound independent witness). Show MISSING=0, EXTRA=0, DUPLICATE=0,
  UNKNOWN=0, OVERLAP=0, OUT_OF_RANGE=0. Allow multiple legitimate
  declarations only under unique explicit identities, never conflated by
  name alone.
- Record two separate identities: immutable `ENTRY_SOURCE_SHA256` measured
  on entry tree and `CURRENT_PHASE_SOURCE_SHA256` measured at every later
  tree; recon should have no tracked source changes, so any difference is
  an unexplained scope violation. A `line_start..line_end` hash alone never
  identifies a semantic decision without an anchor and function binding.

### 5.2 Candidate universe

- Recover all RECON07 source-bound structural sub-slices and scalar
  candidates, including rejected/excluded candidates; re-evaluate
  historical `SUB-004`, `SUB-005`, previously migrated `SUB-001/002/003`,
  and all other prior structural/scalar entries as historical IDs, not
  assumed current verdicts. Discover the actual registry from committed
  files; do not invent `SUB-006` or a new candidate ID without source
  evidence.
- Include any new parser/AST semantic boundaries found in the current
  census with deterministic IDs that do not collide with historical ones.
  Record why each new candidate was discovered and why any prior candidate
  disappeared or changed range.
- Analyze actual production call paths and transitive dependencies on
  mutable symbol tables, AST graph ownership/aliasing, callbacks, jump
  buffers, diagnostics, token stream/cursor, error recovery, lexical scope
  and conditional field reads. A `cctrlIsKeyword` path is not bounded
  simply because its visible signature accepts scalars.
- Identify reachability, semantic distinctness, and observability
  separately. Two sites can share a boolean rule but be semantically
  distinct decision sites, as SUB-001 vs SUB-002 were shown to be;

## 6. C2 — IMPL: canonical checker/ranker, causal selection, successor contract

### 6.1 Eligibility, rank, and independent algorithms

1. Locate/check the existing canonical 13-clause eligibility tool and
   R0–R6 ranker by path, source SHA and actual producer. Use them
   unmodified. If either missing or not executable on this checkout,
   HALT; do not silently create a replacement called canonical.
2. Feed the checker all raw C1 rows, including ineligible/migrated
   candidates. Record exact per-clause truth values and reasons. The
   ranker's `eligible` input must be a joined value from the checker's
   actual output, not caller-supplied `eligible=1` and not a prose rank.
3. Run the ranker; record the full eligible and ineligible population, sort
   keys, exclusions and complete deterministic order. The ranker itself
   trusting `eligible` is a known design property — prove that the
   pipeline prevents a forged flag from promoting an excluded candidate.
4. Implement a new PolyC independent verifier that re-derives each of 13
   clauses directly from C1 raw source facts, **without reading the
   checker's eligibility output**, and recomputes the complete R0–R6 order
   **without reading the ranker's order**. Use independent parsing and
   comparison paths. Require `ELIGIBILITY_MISMATCH=0`,
   `FULL_ORDER_MISMATCH=0`, `UNBOUND_ID=0`, `MALFORMED=0`.
5. Freeze its actual code/producer, compile it with real compiler, run
   selftests including known-answer hashes and malformed input, and ensure
   it does not hardcode current candidate IDs/counts or expected
   selections. A tool using the canonical tool's own PASS fields as oracle
   is not independent.

### 6.2 Causal qualification procedure

Work down the verified ranking. Before touching a candidate, record its
complete bounded source contract, proposed ABI, real compiler witness and
predeclared bounded mutation cases (at least one meaningful reachable
branch flip and any known duplicate/unreachable branch alternative),
observation channels and stop rule. The provisional top-ranked candidate
is not selected yet.

For each candidate being causally qualified:

- Prove the chosen region is the real production C decision, not an oracle
  wrapper, dead code, already delegated PolyC, fixture helper, or
  unreachable path. Capture exact entry Git blob/source SHA, scoped
  disassembly/calls and actual production call path.
- Derive a genuine C-only G0 oracle by compiling the real production
  translation unit with any candidate-specific PolyC selector OFF, rather
  than hand-transcribing a rule. Fail the build if this G0 object imports
  the proposed PolyC successor symbol. For candidate sites with no
  selector yet, record the real baseline C authority directly.
- Independently derive a source/enum-bound fixture covering every
  predicate branch and relevant invalid/sentinel/alias/short-circuit case.
  If a full enumerated domain is huge, justify exact bounded partitions
  and stable row IDs. Show one canonical expected value per input and
  independent witness derivation.
- In a temporary detached worktree at the exact candidate source commit,
  mutate only that legacy C decision. Rebuild the real production
  compiler, requiring successful compiler build for both pristine and
  mutant. Execute the same frozen witness against pristine, mutant and
  restored; independently measure actual compiler acceptance, diagnostics,
  AST/compiled code or runtime output as applicable. Record object/source
  digest change, fixture affected row IDs and actual exit codes. Restore
  source then recompile; show byte-identical source, object (where
  deterministic), and witness observations. If build fails, mark that
  mutant `UNQUALIFIED_BUILD_FAILURE` and do not claim causal success.
- Prove mutated source was truly in the linked binary (relocation, symbol,
  function-scoped disassembly, executed change) and not just a fixture or
  detached unlinked object. Prove unrelated comparison instructions
  cannot forge detector PASS.
- If an attempted mutation has no observation, do not automatically
  disqualify the candidate as dead. Execute remaining predeclared, finite
  mutation/witness cases; if all show no effect, classify
  `NOT_CAUSALLY_DEMONSTRATED`, record full evidence and move to next rank.
  Never expand mutation choices after seeing outcomes without recording a
  new contract phase and treating resulting evidence honestly.
- If an attempted region is unbounded, source-stale or duplicates an
  already-migrated site without independent production decision authority,
  reject with precise cause and continue in rank order. No silent skips
  and no manual winner override.
- A selected candidate must have one successful, causally distinctive,
  restored real-compiler experiment and be demonstrably migratable through
  a bounded scalar ABI without moving AST ownership or recovery state.
  Record all higher-ranked candidate dispositions.

If no candidate survives, emit `HALT_NO_CAUSAL_CANDIDATE` or the actual
blocking class; never choose the least-bad one merely to make SLICE09
possible.

### 6.3 Freeze exactly one successor contract

For the selected candidate (only), produce immutable `c2/selected-*` files
with:

1. Stable ID, class, original file/function/byte+line range, actual entry
   commit/tree, original source SHA-256, semantic anchor and
   branch/witness identity.
2. A single exact PolyC ABI, including integer widths, AST-kind enum
   values and signedness; projection from C host fields with all
   conditional reads and null guards preserved, ownership of every
   pointer/allocation/callback/recovery operation staying on C side.
3. Full production seam diagram and exact selector/compiler object/binary
   policy for eventual implementation; source G0 oracle, fixture
   schema/partitions, independent enum/source witness, and selected C
   mutation's object/exit/output/restore data.
4. Separate time-scoped controls: `PRE-C-MUTANT` (RECON08's
   C-authoritative source), `POST-POLYC-MUTANT` (mandatory new SLICE09
   compiled-PolyC source experiment), and `C-OFF-C-MUTANT` only if
   explicitly demanded by the frozen successor contract. Each includes
   subject path, selector state, producer, object identity, phase,
   execution ID, outcome channel, allowed historical citation/sharing and
   restoration. **No RECON08 C experiment may be relabelled as a SLICE09
   experiment.**
5. Four-generation plan only: G0 genuine C oracle plus G1/G2/G3 distinct
   compiler binary provenance, isolated builds, fixture/differential
   comparison of all 12 ordered pairs, anti-self-reference/provenance
   controls. RECON08 does not pretend that future post-migration G1/G2/G3
   were executed.
6. Exact inherited control-ID set and content, including an explicit
   24-control roster for this RECON08 and any candidate-specific extras
   to be supplied by SLICE09. Freeze semantic obligations and IDs.
   Provide a machine-readable manifest whose count is derived from its
   rows, and an exact join invariant that would reject an omitted ID
   (the SLICE08 SL-EC-06 mistake).
7. An explicit `SELECTED_CANDIDATE_ID` with deterministic rank, all
   higher-ranked rejections and independent checker/ranker provenance. If
   ranker changes order under genuine input permutation, HALT instead of
   publishing selection.

Commit C2 IMPL (new PolyC auditor and own C2 evidence). No tracked
production source modified; no ninth authority added.

---

## 7. C3 — EVIDENCE: separate independent adjudication

- Reconstruct the full C1 census and C2 eligibility/ranking without
  reading C2 conclusion fields. Independently recompute stable
  function/range/source identities, 13-clause decisions and full eligible
  rank order from frozen C1 raw facts, including ties. Verify selected
  candidate and every rejection from actual data.
- Verify 24/24 frozen negative-control IDs by exact-ID join to raw actual
  adverse execution records. Reject any missing, extra, duplicate,
  unexpected alias, incorrect detector, PASS without executed adverse
  effect, self-citing evidence, subject substitution, unbound
  compiler/object or unrestored mutation. If two IDs legitimately share a

## 8. The frozen 24 executable negative controls

Freeze these exact IDs and semantics at C0; the C3 join must be exact-ID
and reason-specific, with pristine PASS → targeted adverse FAIL → restored
PASS for each applicable control. A detector may use read-only injected
copies; causal C mutants use real isolated compiler builds. All controls
must record physical execution IDs and bounded restoration, without
conflating detector-level and actual compiler-level claims.

| ID | Adverse action | Required reason-specific rejection |
|---|---|---|
| R8-IC-01 | Delete a live function from the census | `MISSING_FUNCTION_ID` |
| R8-IC-02 | Duplicate a source/function/candidate ID | `DUPLICATE_ID` |
| R8-IC-03 | Change one source range SHA-256 | `SOURCE_HASH_MISMATCH` |
| R8-IC-04 | Use out-of-range or overlapping semantic boundary | `INVALID_RANGE_OR_OVERLAP` |
| R8-EC-01 | Falsely classify an already-migrated authority as active legacy C | `ALREADY_POLYC_AUTHORITY` |
| R8-EC-02 | Remove an actual transitive mutable-host-state dependence | `TRANSITIVE_DEPENDENCY_MISSING` |
| R8-EC-03 | Conceal a candidate host AST graph write | `HOST_GRAPH_WRITE` |
| R8-EC-04 | Conceal required callback/recovery ownership | `CALLBACK_OR_RECOVERY_DEPENDENCE` (exact clause identified) |
| R8-EC-05 | Mark an unreachable candidate high-ranked | `NOT_PRODUCTION_REACHABLE` |
| R8-EC-06 | Inject one unknown candidate ID **and** separately remove one required eligibility fact | `UNKNOWN_CANDIDATE_ID` **and** `MISSING_ELIGIBILITY_FACT` — two distinct adverse executions |
| R8-RC-01 | Shuffle facts, then forge order-dependent output | True order invariant; forged order rejected `RANK_ORDER_MISMATCH` |
| R8-RC-02 | Give an excluded candidate an artificially best score | `INELIGIBLE_CANDIDATE_NOT_PROMOTED` |
| R8-RC-03 | Remove provisional leader | Next deterministic qualified leader or `NONE`, never stale selection |
| R8-RC-04 | Perturb one R0..R6 dimension | Predicted full sorted-order delta, independent recomputation |
| R8-RC-05 | Keep candidate ID, substitute stale phase/range/call site | `SOURCE_SUBJECT_OR_PHASE_MISMATCH` |
| R8-CC-01 | Mutate selected C decision, build actual compiler, run witness | Successful compiler build plus candidate-specific observed causal change |
| R8-CC-02 | Supply handmade or PolyC-importing G0 oracle | `G0_NOT_GENUINE_C_TU` |
| R8-CC-03 | Corrupt one source-derived fixture expectation | `FIXTURE_ROW_MISMATCH` with exact row |
| R8-CC-04 | Move target comparison into unrelated function | `FUNCTION_SCOPED_AUTHORITY_MISMATCH` |
| R8-PV-01 | Relabel one producer binary as different compiler generation | `PRODUCER_DIGEST_OR_IDENTITY_MISMATCH` |
| R8-XC-01 | Omit one frozen control ID but keep TOTAL/PASS unchanged | `FROZEN_CONTROL_MISSING`, exact-ID diff |
| R8-XC-02 | Point execution evidence only to its own JOIN row | `SELF_REFERENTIAL_WITNESS`, reject claimed adverse execution |
| R8-XC-03 | Claim post-phase source hash existed at C0/C1 | `SOURCE_CHRONOLOGY_MISMATCH` from immutable Git objects |
| R8-XC-04 | Replace linked selected C mutation with a dormant/unreachable mutation | `NONCAUSAL_OR_UNLINKED_MUTANT` despite fixture changes |

**Important execution semantics:** R8-EC-06 is one control ID with two
required physical executions; both detectors must independently fire.
R8-CC-01..04 must concern the **actual final selected candidate**; if the
provisional rank leader is rejected, rebind and re-execute subject-specific
controls on the final one. For R8-XC-04, require the injected fake positive
to be rejected, while the genuine R8-CC-01 remains observable. No
"selected candidate" exists if any selected-subject control is
unexecuted.


## 9. Evidence inventory (mandatory semantic coverage)

Create additive evidence in exactly this ACT-owned namespace, adapting
filenames only as the repo's canonical policy demands and freezing exact
inventory at C0:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08/
  c0/
    entry-identity.txt
    predecessor-close-and-correction-audit.tsv
    predecessor-hash-freeze.tsv
    baseline-parser-lexer-cross-target.txt
    baseline-tool-policy-gates.txt
    eight-authorities-object-proof.tsv
    frozen-50-ac-contract.tsv
    frozen-24-negative-controls.tsv
    five-red-reproduction.txt
  c1/
    live-function-census.tsv
    census-recon07-set-differences.tsv
    independent-census-verification.txt
    structural-subslices.tsv
    scalar-and-new-candidates.tsv
    raw-13-clause-facts.tsv
    raw-r0-r6-facts.tsv
    transitive-dependencies.tsv
    semantic-distinctness-reachability.tsv
    source-anchor-and-phase-hashes.tsv
  c2/
    canonical-checker-provenance.txt
    canonical-eligibility-all-rows.tsv
    canonical-ranker-full-order.tsv
    independent-polyc-recompute.txt
    attempted-candidate-dispositions.tsv
    candidate-causal-build-and-witness.tsv
    candidate-mutation-restoration.tsv
    selected-source-contract.md
    selected-abi-and-projection.md
    selected-g0-oracle-and-fixture.md
    selected-production-seam.md
    selected-negative-controls.md
    selected-stage-provenance-and-causal-contract.md
    selection-qualification.tsv
  c3/
    independent-census-and-eligibility.tsv
    independent-full-order.tsv
    independent-selected-causality.txt

## 10. Frozen 50 acceptance criteria

C0 must freeze exactly AC01..AC50 as machine-readable rows with immutable
full criterion text and anticipated evidence phase. C3 must join by exact
AC ID, not row order. Only AC50 is deferred until after CLOSE.

| AC | Mandatory predicate |
|---|---|
| AC01 | Exact expected entry HEAD, TREE, branch, worktree/index and no replace refs. |
| AC02 | Immediate SLICE08 correction CLOSE, five-commit range, trailers and actual predecessor tree verified. |
| AC03 | Historical RECON06 HALT and all predecessor CLOSE statuses preserved; no retroactive PASS. |
| AC04 | Correction's 24/23/24 control reconciliation and EC06 supplement checked from committed bytes. |
| AC05 | SLICE08 source hash chronology defect and corrected phase/ranges acknowledged without historical rewrite. |
| AC06 | Complete closed-predecessor path+SHA/blob freeze computed and verified. |
| AC07 | Eight production PolyC authorities object/linkage verified at entry. |
| AC08 | C0 baseline exact parser assertion sequence measured; historic nonzero failures not hidden. |
| AC09 | C0 freeze of exactly 50 AC IDs before conclusions. |
| AC10 | C0 freeze of exactly 24 control IDs, subjects and detectors before executions. |
| AC11 | Five actual C0 RED observations, reason-specific rather than planned-only. |
| AC12 | Source census covers all four required translation units with exact live function identities. |
| AC13 | Source ranges and hashes bound to semantic function anchors and actual entry commit/tree. |
| AC14 | Census reconciliation against RECON07 uses measured set differences, no invented totals. |
| AC15 | Census independent verification: zero missing/extra/duplicates/overlaps/out-of-bounds. |
| AC16 | Migrated production decisions distinguished from surviving legacy C forwarding adapters. |
| AC17 | Complete old and new structural/scalar candidate registry with unique IDs. |
| AC18 | All historical selected/rejected candidates reconciled, including SUB-001/002/003/004/005. |
| AC19 | Full transitive mutable-state, graph, callback, recovery and token dependency inventory. |
| AC20 | Source-derived production reachability and semantic-distinctness facts for every candidate. |
| AC21 | Raw 13-clause and R0..R6 inputs frozen at C1 before checker/ranker outcomes. |
| AC22 | Existing canonical checker and ranker located, hashed and used unmodified. |
| AC23 | Canonical eligibility covers all candidates and yields named per-clause exclusions. |
| AC24 | Ranker input eligible is joined to the checker's output; forged flags fail pipeline. |
| AC25 | Canonical full ordering and ties computed deterministically over eligible population. |
| AC26 | Independent PolyC verifier computes eligibility from raw facts, not checker output. |
| AC27 | Independent PolyC ranker recomputes entire order without original ordered rows. |
| AC28 | Zero independent eligibility, roster and full-order mismatches. |
| AC29 | Highest-ranked attempted candidate not automatically treated as selected. |
| AC30 | Every attempted candidate has predeclared finite mutation/witness contract and disposition. |
| AC31 | Selected candidate real production C authority, source/hash and call path verified. |
| AC32 | Selected G0 object from real production C TU with no PolyC successor import. |
| AC33 | Selected source-derived fixture and independent source/enum witness agree row-for-row. |
| AC34 | Selected candidate's pristine, mutant and restored REAL compiler builds succeed. |
| AC35 | Real compiler witness demonstrates distinct, accurately classified candidate causal effect. |
| AC36 | Mutation is selected C decision only, with linked object provenance and byte-restored source. |
| AC37 | Unobservable/duplicate/unbounded candidates rejected with precise measured causes. |
| AC38 | Selected ABI is bounded, total for documented inputs and ownership-safe. |
| AC39 | Conditional host reads, pointer lifetimes, recovery and diagnostics remain on C side. |
| AC40 | Selected contract freezes source/tree/anchor/range/SHA, ABI, selector and witness. |
| AC41 | Selected contract freezes separate PRE-C and future POST-POLYC experiment IDs. |
| AC42 | Four-generation G0–G3 execution plan and independent provenance controls frozen, no false claim of G1–G3 execution. |
| AC43 | All 24 frozen negative controls executed and sensitive for exact intended reasons. |
| AC44 | No self-referential execution evidence, frozen-ID omissions, false duplicate independence or stale phase hashes. |
| AC45 | Parser 376/376 sequence, direct lexer and broad historical failure identities conserved. |

## 11. C4 — CLOSE and external terminality

Only after C3's read-only independent adjudication and AC01..AC49=PASS:

1. Write `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08.md`,
   with actual selected ID or `NONE`, its exact source/ABI/source SHA and
   raw causal decision, higher-ranked rejections, complete 24-control
   join, 50-AC ledger, source chronology, eight-authority preservation,
   known baseline failures, gates and next-ACT status.
2. Append one unique ACT/HANDOFF map row. Add a bounded roadmap/epic-board
   entry only under canonical ownership; no edits to historical text or
   statuses.
3. Validate phase messages/trailer grammar before committing. For a
   successful path the range must be exactly five forward commits: C0 RED,
   C1 EVIDENCE, C2 IMPL (quality tooling), C3 EVIDENCE, C4 CLOSE. One
   terminal CLOSE with `ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08`,
   `ACT-Phase: CLOSE`, `ACT-Verdict: PASS`. If a genuine earlier HALT
   occurs, follow repository's valid shorter HALT lifecycle, do not
   manufacture missing phases or PASS evidence.
4. Commit a C4 `terminality-plan.txt` explicitly labelled plan, never a
   report of already executed post-CLOSE checks. Do not commit anything
   after CLOSE.
5. After terminal CLOSE, execute a genuinely external, read-only
   terminality probe against HEAD, `HEAD^{tree}`, clean worktree and index,
   zero replace refs/worktrees, exact phase range/trailers, no post-CLOSE
   commit, complete frozen predecessor path hashes, Factory-v2, F14,
   append-only, closure-status and gate status. Keep receipt outside the
   repo (e.g. an operator-controlled temporary file). Only after a
   successful probe may AC50 be reported PASS.
6. Do not invent access to the user's background jobs or an external
   receipt. Consume pending job results before terminal reporting, with
   actual exit status and outcome binding. A failed external check is a
   terminality failure requiring an honestly recorded disposition, not a
   stealth post-CLOSE fix.

### Terminal report schema

```text
ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
VERDICT=PASS|HALT
DISPOSITION=PASS_SELECTED|HALT_...
ENTRY_HEAD=4e01dbac59f18223efc5d168d07d232c6c7f0c42
ENTRY_TREE=f72d358fe3b033c350cf9a7a841be5bb3333e56e
FINAL_HEAD=<actual>
FINAL_TREE=<actual>
BRANCH=<actual>
ACT_COMMIT_COUNT=<actual>
PHASE_SEQUENCE=<actual>
WORKTREE_CLEAN=<YES|NO>
GIT_REPLACE_REFS=<count>
POST_CLOSE_COMMITS=<count>
PREDECESSOR_FROZEN_PATHS=<measured>
PREDECESSOR_HASH_MISMATCHES=<count>
PARSER_FUNCTIONS_CENSUSED=<measured>
CANDIDATES_TOTAL=<measured>
ELIGIBLE_TOTAL=<measured>
INELIGIBLE_TOTAL=<measured>
ELIGIBILITY_MISMATCH=<count>
FULL_ORDER_MISMATCH=<count>
SELECTED_CANDIDATE_ID=<ID|NONE>
SELECTED_SOURCE_COMMIT/TREE/RANGE/SHA256=<exact|NONE>
SELECTED_ABI=<exact|NONE>
CAUSAL_BUILD_STATUS=<actual|NOT_RUN>
CAUSAL_OBSERVATION_CLASS=<RUNTIME_OUTPUT_CHANGED|COMPILER_ACCEPTANCE_CHANGED|OTHER_EXACT|NONE>
CAUSAL_MUTANT_EXECUTION_ID=<actual|NONE>
NEGATIVE_CONTROLS=24/24 (or executed/unproven counts on HALT)
NEGATIVE_CONTROLS_PHYSICAL_EXECUTIONS=<measured>
MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=<measured>
MANDATORY_AC_FAIL=<measured>
MANDATORY_AC_UNPROVEN=<measured>
POLYC_PARSER_AUTHORITIES=8
PRODUCTION_SEMANTIC_DELTA=0
PARSER_ASSERTIONS=376/376
PARSER_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
LEXER_DIRECT=89/89,45/45,23/23
LEXER07_STATUS=FAIL_KNOWN_BASELINE
LEXER07_FAILURE_IDENTITY_MD5=7ee761440de83552e751e3c3976c1683

## 12. HALT codes and residue separation

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_NOT_VERIFIED
HALT_CLOSED_ARTIFACT_MUTATED
HALT_EIGHT_AUTHORITY_CONSERVATION
HALT_SOURCE_CENSUS_UNBOUND
HALT_SOURCE_RANGE_OR_CHRONOLOGY
HALT_CANDIDATE_ROSTER_OR_DEPENDENCY_UNBOUND
HALT_CANONICAL_CHECKER_OR_RANKER_MISSING
HALT_ELIGIBILITY_OR_RANKING_MISMATCH
HALT_FORGED_ELIGIBILITY_ACCEPTED
HALT_NO_CAUSAL_CANDIDATE
HALT_UNBOUNDED_DEPENDENCY
HALT_G0_PROVENANCE
HALT_MUTANT_COMPILER_BUILD_FAILED
HALT_WRONG_SUBJECT_OR_DORMANT_MUTANT
HALT_CONTROL_UNEXECUTED_OR_WRONG_REASON
HALT_FROZEN_ID_JOIN_OR_SELF_REFERENCE
HALT_NEW_REGRESSION
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_V2_F14_APPEND_ONLY
HALT_MANDATORY_AC_UNPROVEN
HALT_TERMINALITY
```

**Pre-existing issues not to fix or relabel under RECON08:** 15 LEXER07
identities, 67 missing-prefix cross-target cases, 12 Python-policy
violations, absent F-POLYC-TOOLS checker, SLICE06's stale CMake producer
path, shared tmp assembly collision, factory-halt-classification
standalone inline-asm failure, the pointer-valued ternary OOM lead, and
the historical SLICE08 self-referential C3 rows. If any new failure is
observed, classify it by exact identity and stop rather than calling it
historical.

---

## 13. Operator examples and provenance conventions

These commands are illustrative; source-of-truth repo tooling and actual
observed exits govern:

```sh
# Read-only entry identity: never reset to force a match.
git rev-parse HEAD 'HEAD^{tree}'
git branch --show-current
git status --short
git replace -l

# Historical immutable blobs; bind every source/range measurement to its commit.
git show '4e01dbac59f18223efc5d168d07d232c6c7f0c42:src/parser.c'
git show 'a43348acc481146853b771609c75e4e0d324e375:src/parser.c'

# Only disposable mutations, on detached worktrees, never on authoritative main.
git worktree add --detach /tmp/polyc-recon08-candidate 4e01dbac59f18223efc5d168d07d232c6c7f0c42
# Apply bounded C mutation in /tmp/polyc-recon08-candidate only.
# Rebuild real compiler in an isolated output root; run pristine/mutant/restored witnesses.
# Remove normally after byte-restoration and proof collection.
git worktree remove /tmp/polyc-recon08-candidate

# After C3, serially (not in parallel with another compiler process):
make gate-fast
make gate-push
```

Do not rely on `make` target names where repo conventions differ;
discover real targets and bind exits. A Git object read is authoritative
for the contents of that commit, not for a separate current working-tree
state. A detached worktree enables isolated experiments but does not
automatically isolate shared compiler temp files, so builds remain serial.

---

## 14. Explicit successor rule

SLICE09 may be proposed/activated only after RECON08 has produced a
single source-bound selected candidate, a valid committed PASS CLOSE, and
successful external post-CLOSE terminality. This ACT never implements it.
Do not create SLICE09 merely because RECON08 was drafted, executed C0, or
reached a provisional rank-1 candidate.

CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX (67 historical)
F_NO_PYTHON=FAIL_KNOWN_BASELINE (12 historical, 0 new)
F_POLYC_TOOLS=UNAVAILABLE (unless real checker independently landed)
GATE_FAST=<status+exit>
GATE_PUSH=<status+exit>
F14=<status>
APPEND_ONLY=<status>
FACTORY_V2_RANGE_CHECK=<status>
EXTERNAL_TERMINALITY=<PASS|FAIL|UNAVAILABLE>
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE09 (only if PASS_SELECTED)
SLICE09_IMPLEMENTED=NO
```

All counter values must be measured, not copied from this schema. For
HALT, do not present `24/24`/`376/376`/eight-authority values unless
actually observed in the HALT execution. Report `NOT_RUN` where
appropriate.

---

| AC46 | Eight authority/object linkage conserved; zero new production semantic changes or new failure IDs. |
| AC47 | Gate-fast and gate-push each actually executed serially and PASS with exit and check identities. |
| AC48 | Factory-v2, F14, append-only, closure status, exact permitted scope, patch hygiene PASS. |
| AC49 | Exactly one selected successor contract (or a truthful HALT); C3 AC01–AC49 independently joined. |
| AC50 | One valid terminal CLOSE, external post-CLOSE terminality PASS, no post-CLOSE continuation. |

On PASS, every criterion is required; the only post-CLOSE deferred
criterion is AC50. If no candidate qualifies, AC31–AC42/AC49 cannot be
claimed PASS; perform honest HALT under the repository's canonical
lifecycle semantics rather than forcing an all-green ledger.

---

    frozen-control-execution-join.tsv
    negative-control-raw-results.tsv
    selected-source-phase-recompute.tsv
    parser-lexer-conservation.txt
    cross-target-and-policy-status.txt
    eight-authorities-conservation.txt
    gate-fast.txt
    gate-push.txt
    factory-v2-f14-append-only.txt
    immutable-predecessor-check.txt
    mandatory-50-ac-status.tsv
  c4/
    terminality-plan.txt
```

- The `selected-*` files exist on a successful selected path. For HALT,
  preserve the attempted candidates and reasons; do not fabricate
  `selected-*` or a `SELECTED_CANDIDATE_ID`.
- Each actual mutation/witness/negative control needs inputs, command, real
  exit, positive baseline, adverse observation, precise detector and
  restored state. Keep evidence files small but substantive and
  independently machine-readable. An assertion-only join cell is UNPROVEN,
  not PASS.
- C3 verifier must compute `FROZEN_CONTROL_COUNT=24`,
  `OBSERVED_CONTROL_IDS=24`, `MISSING=0`, `EXTRA=0`, `DUPLICATE=0`,
  `UNEXECUTED=0`, `SELF_REFERENTIAL=0`, `WRONG_SUBJECT=0`, and a
  separately derived count of physical executions. Do not assert the
  latter is 24 if IDs share work or R8-EC-06 has two adverse executions.

---

---

  physical experiment, keep both IDs but mark the same `execution_id` and
  explicitly not independent; ensure both frozen semantics permit
  sharing. No fake "24 independent experiments" claim.
- Recompute candidate source hashes from C0/C1/C2/C3 Git objects and bind
  the actual candidate's semantic anchor; no post-phase blob may
  masquerade as an earlier phase. Confirm `PRODUCTION_SEMANTIC_DELTA=0`
  and frozen previous files byte-identical.
- Re-run all §3 baselines; preserve exact historical LEXER07 identity MD5
  and cross-target/Python counts, report nonzero status as failures, not
  PASS. Require zero new parser/lexer IDs.
- Verify eight and only eight active PolyC parser production decision
  authorities in current compiler. Record exact code/object linked
  evidence, not a symbols-only count.
- Run `gate-fast` and `gate-push` serially against appropriate RECON08 C3
  tree; capture process exit, check-level output, compiler/tool
  provenance, no shared tmp contention, and `git diff --check`.
- Run append-only 11/11 (or rederive actual current roster), F14 on the
  entire frozen predecessor set, closure-status, commit trailer grammar,
  patch hygiene, exact authorized path scope and zero replace refs. Do not
  weaken a failing checker or mask a nonzero result.
- Independently join the frozen 50 AC IDs, proving AC01–AC49 only with real
  evidence. AC50 is strictly deferred to external post-CLOSE receipt. If
  any C3 AC fails or remains unproven: HALT and do not claim PASS.

Commit C3 EVIDENCE with raw checks, a distinct independent verifier report
and actual outcomes. A calculated ranking is not a license to implement
the winner within this ACT.

---


---

  conversely a candidate may admit only an unreachable mutation. Do not
  confuse structural duplications with lack of causal effect based on one
  insufficient mutation.
- Keep whole-function PARSER01 blockers (`parseCompoundStatementInternal`,
  `parseStatement`, `parseExpr`, recursive flows) in the registry with
  named constraints. A small genuine boundary inside one blocked function
  may qualify; a wholesale graph/recovery migration does not.

### 5.3 Frozen C1 facts (no eligibility conclusions yet)

For each candidate, write canonical source rows with `candidate_id`,
`source_commit`, `source_tree`, `source_blob`, `file`, `function`,
`line_range`, `byte_range`, `source_sha256`, `semantic_anchor`,
`actual_call_path`, `active_C_authority`, `13_raw_eligibility_facts`,
`R0..R6_raw_rank_facts`, `transitive_dependencies`, `graph_writes`,
`recovery_callbacks`, `ABI_projection`, `side_effects`,
`short_circuit_reads`, `observable_witness_hypothesis` and
`status_of_existing_adapters`. Every exclusion includes named causal
facts, not just a score.

Do not author the eligible or final rank fields by hand into raw facts.
Commit C1 EVIDENCE with complete inventory, facts, graph, derived-source
and independent-census evidence. **No candidate is selected at C1.**

---
