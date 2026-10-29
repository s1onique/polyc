# ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / EVIDENCE-HYGIENE / FROZEN NEGATIVE-CONTROL DISCHARGE
**Priority:** P1 (historical proof integrity; non-production-blocking under DOCTRINE §25)
**Repository:** `s1onique/polyc`
**Branch:** existing main checkout; no ceremonial branch
**Expected ENTRY_HEAD:** `aa90d34193cd67ace532e743e8fd837e6237d8e3`
**Expected ENTRY_TREE:** `378790c0c93afc6b5866e1464b9b7c1cf140f0b4`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06` — terminal
`HALT_N06_FROZEN_OBLIGATION_UNPROVEN`, `HALT_CLASS=GOVERNANCE`,
`BLOCKS_NEXT=NO`
**Historical subject:** `ACT-POLYC-SELFHOST-PARSER-SLICE07`, frozen inherited
control `N-06`
**Selected migration:** NONE. `SLICE08` is NOT authorized.

---

## 0. Mission and terminal meaning

Supply new, append-only, literal experimental evidence for RECON05's frozen
inherited `N-06`:

> Mutate ONLY the selected **C** decision in a disposable worktree, rebuild
> the real compiler, and run the witness.

The experiment performed in SLICE07 instead mutated the compiled PolyC
source. That proved the production authority transfer but did not execute
the frozen C-mutation. RECON06's C0 read-only audit establishes this
decisively and is the controlling RED.

This ACT must demonstrate, without rewriting any history, the causal effect
of a new legacy C-decision mutant, with its corresponding actual
C-authoritative compiler build, and separately preserve the existing
evidence for the PolyC-authoritative production build. Reconcile the
accounting for `N-06` and `S7-CC-01` as two distinct control IDs whose
historical C3 evidence was only one PolyC mutation experiment.

A new experiment performed today does not mean it ran during SLICE07's
original C3. Report:

```text
SLICE07_HISTORICAL_N06_EXECUTED_AS_WRITTEN=NO
SLICE07_HISTORICAL_S7_CC01_POLYC_MUTATION=PROVEN
CORRECTION_N06_LITERAL_EXPERIMENT=<PROVEN|UNPROVEN>
CORRECTION_OWN_DISTINCT_EXECUTION_ID=<hash / manifest ID>
HISTORICAL_ARTIFACT_REWRITES=0
PRODUCTION_SEMANTIC_DELTA=0
```

### 0.1 Allowed terminal decisions

- `PASS_EVIDENCE_SUPPLEMENTED` — a new independent, literal C-source
  experiment exists, its detector is nonvacuous, the original control
  mismatch and double-reporting are transparently reconciled, and every
  correction acceptance criterion is proved.
- `HALT_LITERAL_C_SUBJECT_UNREACHABLE` — a real C-authoritative
  disabled-selector build cannot be produced without unauthorized
  source/build modifications.
- `HALT_N06_CAUSAL_DIRECTION_UNPROVEN` — a valid C mutant builds but no
  causal witness difference can be demonstrated; do not substitute a
  different subject.
- `HALT_*` — any actual failed invariant, control, conservation gate or
  Factory-v2 obligation.

**There is no historical retroactive PASS.** Keep RECON06's terminal HALT
and SLICE07's terminal PASS unchanged.

---

## 1. Frozen authority and exact source semantics

### 1.1 The frozen artifacts

Read and hash these committed artifacts before any mutation:

1. `evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/selected-negative-controls.md`
   — literal N-06 (frozen SHA-256
   `f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325`).
2. `...RECON05/c2/selected-red-contract.md`, `selected-causal-contract.md`,
   `selected-abi.md`, `selected-production-seam.md`, and
   `selected-conservation-contract.md`.
3. `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/negative-control-contract.tsv`,
   `c1/negative-control-red.txt`, `c3/inherited-controls-join.tsv`,
   `c3/new-controls-join.tsv`, `c3/causal-polyc-mutation-restoration.txt`.
4. `evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-literal-control-audit.{md,tsv}`,
   `n06-machine-verification.txt`, `predecessor-freeze.tsv`,
   `existing-production-authorities.tsv`, and `c4/terminality.txt`.
5. Canonical `docs/factory/DOCTRINE.md` §25, Factory-v2 trailer/range/append-only/F14
   rules, and current build-selector definitions.

### 1.2 The selected C decision

The current source has a C helper containing the legacy decision when
`HCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND` is OFF. Verify actual
preprocessor ownership and the exact source range from the entry tree;
**source line numbers are not stable IDs**. The frozen semantics are:

```c
if (stmt_kind == AST_DECL && declvar_kind == AST_GVAR) return 0;  /* SKIP */
return 1;                                                        /* APPEND */
```

`AST_DECL=263` and `AST_GVAR=256` are historical observations; re-derive
them from the live `src/ast.h`. Preserve the C host's conditional
`stmt->declvar->kind` projection; never introduce an eager dereference.

### 1.3 The two explicit compiler configurations

**C-ON** (the existing production configuration): dedicated selector ON,
the PolyC component is linked, the selected legacy C predicate is compiled
out. This remains production-authoritative and must not change. A mutant
editing only the dormant C branch should be semantically inert here.
Confirm object-level evidence before relying on this condition.

**C-OFF** (a disposable legacy reference configuration): dedicated selector
OFF in an out-of-tree build configuration, with the other six PolyC parser
authorities retained. The selected C predicate is active; the compiled
production C translation unit is the semantic authority. The new C-only
mutation must be causally observable in this real compiler, not merely in a
synthetic function driver. The `SUB-003` PolyC import must be absent from
the C-OFF parser object and the corresponding branch must be present in
function-scoped disassembly.

Changing the build selector to construct C-OFF is permitted as an
invocation/configuration change. Changing any tracked CMake, Makefile or C
source **other than the single selected C decision** in a detached worktree
is not permitted for the causal mutation. If isolation cannot be achieved
using existing build interfaces, HALT; do not fake an oracle or silently
patch build wiring.

**This two-configuration test prevents the misleading claim that mutating a
dormant legacy C branch under the default PolyC-enabled build proves C
decision causality.**

---

## 2. Hard scope

Allowed tracked additions/changes, and no others:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01/**
tools/quality/parser-slice07-evidence-correction01-*.HC   # only if a substantive verifier is necessary
Makefile                                                    # only an additive bounded invocation target, if proven necessary
```

No tracked changes to `src/**`, `tools/bootstrap/**`, any closed
ACT/HANDOFF/evidence, any old test/fixture, a canonical quality gate, or
`.factory/` semantics. Never amend/rebase/reset/force-push existing history.
No Python, new dependencies, or substantial shell-based test logic. PolyC
is the implementation language for any new substantive verifier. Do not add
an eighth parser authority or select a parser candidate.

Use detached disposable worktrees for the mutation experiment. Git supports
`git worktree add --detach` and `git worktree remove`; do not create an ACT
branch for ceremony. Use isolated build roots and avoid parallel
compilers/JIT/gates because the shared `/tmp/holyc-asm.s` is known to race.

---

## 3. C0 — RED, entry, freeze, acceptance ledger

1. Verify exact expected ENTRY_HEAD and ENTRY_TREE, current branch, clean
   worktree, no replace refs, valid predecessor two-commit HALT range and
   terminal trailers, `BLOCKS_NEXT=NO`; stop on any mismatch. Confirm the
   correction ACT is not already present.
2. Verify all previously frozen hashes from RECON06's 298-path manifest.
   Extend a new correction-owned SHA-256 manifest to freeze the complete
   closed RECON06 ACT/HANDOFF/evidence and the earlier predecessors; bind by
   byte hashes and count.
3. Independently read frozen N-06 text and the two SLICE07 C3 rows.
   Preserve the five RECON06 answers. Reproduce `N06_UNPROVEN` as a
   historical statement, not as a predicate to be made false by editing
   history.
4. Measure fresh `make unit-test` (376/376 over 90 files, expected assertion
   MD5 `b6f117eb1386ca80f81bc06226e2a741`), the three direct lexer
   differentials (89/89, 45/45, 23/23), broad LEXER07 identities (15, MD5
   `7ee761440de83552e751e3c3976c1683`, historical FAIL), cross-target (67
   missing-prefix failures), tool policy (12 historical Python violations,
   checker UNAVAILABLE) and serialized gates. Do not convert an expected
   nonzero baseline into PASS.
5. Record the seven active production authorities with real flags, object
   imports/exports and final executable linkage. Verify SUB-003 is
   PolyC-owned in C-ON.
6. Freeze the 28 correction acceptance predicates (AC01–AC28) below, and the
   negative controls NC01–NC08 before executing adverse experiments.
7. Reproduce the RED that there is no SLICE07-era literal C mutant and that
   the existing PolyC mutant cannot be relabeled as one.
8. Commit C0 with correctly validated Factory-v2 `ACT-Phase: RED` trailer.

---

## 4. C1 — EVIDENCE, real C-object oracle and safe build topology

1. Read the real `src/parser.c` branch, exact selection macro, full C
   function/source binding and hashes. Derive enum values from live source.
2. Build two pristine real compilers from the same entry commit with all
   non-target compiler flags held equal: C-ON and C-OFF. Use existing
   supported build configuration (including a complete clean compile)
   rather than a handcrafted object or reimplemented oracle. Record
   commands, CMake cache/compile flags, source/object/executable hashes and
   link maps.
3. For C-ON: verify `BootstrapCompoundBlockAppendsStatement` genuinely
   called from `_parseCompoundStatementInternal`, and the selected `AST_GVAR`
   C comparison absent from that function.
4. For C-OFF: verify `BootstrapCompoundBlockAppendsStatement` is **not**
   imported by the parser object, the original C decision exists in the
   actual translation unit, and the real compiler executes it on the selected
   witness. Do not equate the mere existence of dormant C source with active
   C-authority.
5. Run the committed static SUB-003 witness from RECON05/SLICE07, plus a
   small source-bound fixture with at least: global declaration, local
   declaration, non-declaration with no declvar, and irrelevant declvar_kind
   values. Record baseline compiler build, witness compile, witness
   execution, output and failure channel separately. If a witness is
   unavailable under C-OFF, establish an authentic alternate with a frozen,
   explicit expected semantic direction before seeing mutant results; do not
   rewrite the witness post hoc.
6. Record pristine behavior for both configurations before constructing a
   mutant. Preserve the selected C-only source bytes before mutation.
7. Commit C1 as EVIDENCE.

---

## 5. C2 — EVIDENCE, literal N-06 mutant

1. Create a detached disposable worktree rooted at the actual correction
   entry/predecessor closure. Record its base HEAD and tree. Keep the
   authoritative main checkout untouched.
2. Mutate **only** the source code implementing the selected legacy C
   append/skip decision in `src/parser.c`; do not change the PolyC
   component, C host projection, `src/ast.h`, witness expected data, oracle,
   tests, Makefile or CMakeLists.txt. A permissible adversarial polarity
   flip is the source-bound `AST_DECL && AST_GVAR` SKIP result; bind to exact
   live source bytes rather than relying on a guessed line number. Record an
   exact single-hunk diff and before/after SHA-256.
3. From that same mutated tree, build the real C-OFF production compiler
   successfully. Prove the compiled selected C object was rebuilt and
   re-linked, its hash changed, and that it still has no dependency on the
   PolyC SUB-003 symbol. A compiler build failure is not a successful causal
   witness.
4. Run exactly the frozen witness/fixture against pristine and mutated C-OFF
   compilers. Require a substantive compiler-acceptance difference or
   compiled-program semantic difference for the selected class, without
   introducing an unrelated failure. Record commands and exit statuses as a
   causal triple with explicit observation class. The intended frozen
   detector is `CAUSAL_DIRECTION_CHANGE`; if it does not fire, HALT.
5. Dormant-branch anti-control: build C-ON from the same C-mutated source,
   leaving the compiled PolyC component untouched. Its selected decision must
   remain PolyC-authoritative, and the witness outcome must be identical to
   pristine C-ON. The selected C predicate is compiled out of that path. If
   it affects the production path, the claimed retired-authority invariant is
   false: HALT.
6. Restore the C source byte-identically in the disposable worktree and
   rebuild C-OFF. Require identical witness behavior to pristine and
   verifiable source restoration. Do not leave mutant worktrees, linked
   references or build artifacts that contaminate another test.
7. Preserve the distinct execution identity: the new C mutation is
   `N06_LITERAL_CORRECTION_EXPERIMENT`; the historical PolyC mutation
   remains `S7-CC-01` from SLICE07. They are never represented as having
   been two SLICE07 experiments.
8. Commit C2 as EVIDENCE with the full adverse experiment record.

### Mandatory independent adverse controls, frozen at C0

| ID | Adverse condition | Required detector |
|----|-------------------|-------------------|
| NC01 | Omit the actual source C mutation while relabeling the build | Source-hash and scope mismatch |
| NC02 | Reuse a C-ON object as the purported C-OFF oracle | Selector/import/disassembly provenance rejection |
| NC03 | Reuse the same C-OFF executable for pristine and mutant | Object/executable identity and causal non-change detector |
| NC04 | Mutate an unrelated C comparison and claim SUB-003 causality | Selected source-range/symbol and witness-subject mismatch |
| NC05 | Corrupt one witness expected result or input row | Fixture exact-ID/semantic mismatch |
| NC06 | Claim a failed compiler build as changed witness behavior | Build-success precondition failure |
| NC07 | Restore C source incompletely | Byte-hash restoration rejection |
| NC08 | Re-label the historical PolyC C3 experiment as the new C experiment, or count it as independent C evidence | Subject + execution-ID + evidence-path join rejection |

Every NC must have an actual adverse execution, exact observed failure class,
and pristine/restore positive control. **A PASS inferred from only a pristine
object is vacuous.**

---

## 6. C3 — EVIDENCE, independent accounting and gates

1. Use an independent PolyC verifier if needed to join the frozen control
   contract, new raw experiment results and exact object/source/evidence
   identifiers. Do not accept merely self-reported labels from the
   experiment driver. Independently verify all eight NC cases.
2. Produce a control reconciliation with columns: `control_id`,
   `frozen_subject`, `historical_observed_subject`,
   `historical_execution_id`, `supplement_execution_id`,
   `compiler_configuration`, `source_diff_hash`, `observed_detector`,
   `historical_disposition`, `new_disposition`, and `provenance_path`.
3. Record without ambiguity:

```text
N06_FROZEN_SUBJECT=selected C decision
N06_HISTORICAL_SUBJECT=PolyC source
N06_HISTORICAL_DISPOSITION=UNPROVEN_AS_WRITTEN
N06_NEW_LITERAL_C_MUTANT=EXECUTED
N06_NEW_C_ONLY_BUILD=SUCCESS
N06_NEW_CAUSAL_DIRECTION=OBSERVED
S7_CC01_HISTORICAL_POLYC_CAUSALITY=PRESERVED
N06_AND_S7_CC01_HISTORICALLY_INDEPENDENT=NO
NEW_C_MUTANT_AND_HISTORICAL_POLYC_MUTANT_INDEPENDENT=YES
```

4. Recheck the seven existing production authorities and confirm no tracked
   production changes. Re-run the 376/376 assertion baseline with
   byte-identical sequence, lexer differentials, LEXER07 exact failing
   identity file, 67-failure cross-target prefix baseline, historical
   Python/tool policy counters, and no new failure identities.
5. Re-run serialized `gate-fast`, `gate-push`, append-only, F14,
   closure-status, patch hygiene and the relevant Factory-v2 checks. Collect
   full commands/exits and separate known historical FAIL/UNAVAILABLE values
   from newly introduced regressions.
6. Independently verify the previous RECON06 HALT still has its exact literal
   trailer, and that the correction does not delete or overwrite any
   predecessor data.
7. Join AC01–AC28: AC01–AC27 must be evidenced PASS by C3; AC28 alone is
   `DEFERRED_TO_CLOSE` until the external read-only terminal check.
8. Commit C3 EVIDENCE. Do not CLOSE with an unproven frozen N-06 or a
   false-green negative control.

---

## 7. C4 — single terminal CLOSE

1. Add correction-owned HANDOFF, managed handoff-map entry and bounded
   roadmap update. The roadmap must preserve RECON06 HALT and SLICE07
   historical PASS, while recording a later supplemental evidence correction.
2. Validate the intended commit message and every C0–C3 trailer with the
   repository's canonical Factory-v2 validators before committing.
3. Produce exactly one terminal C4 CLOSE with appropriate verdict trailer
   (PASS only if every required claim is proved; otherwise an exact `HALT_*`
   with governance classification as required by the current doctrine). No
   amend, rebase or replay.
4. In an external read-only post-CLOSE check: verify exact HEAD/tree,
   expected linear ACT range, no post-CLOSE commits, zero replace refs,
   clean worktree, 28/28 AC discharge (AC28 terminally), append-only and
   F14, and zero closed-artifact changes. Do not add a tracked commit
   afterward to store the external receipt.
5. NEXT: the correction closure allows a fresh selection ACT, not a SLICE08
   implementation. The prior RECON06 HALT cannot be converted into PASS and
   must not be resumed by adding commits after its CLOSE.

---

## 8. The exact 28 acceptance predicates

| ID | Mandatory predicate | Phase |
|----|---------------------|-------|
| AC01 | Exact entry HEAD/tree/branch/cleanliness and zero replace refs | C0 |
| AC02 | RECON06 HALT and SLICE07 PASS ranges/trailers verified | C0 |
| AC03 | Closed predecessor byte-hash freeze created and valid | C0 |
| AC04 | Literal RECON05 N-06 contract read directly and unchanged | C0 |
| AC05 | Historical PolyC mutation / double-reporting discrepancy independently reproduced | C0 |
| AC06 | Current seven PolyC production authorities objectively reverified | C0 |
| AC07 | Parser/lexer/LEXER07/cross-target/tool-policy baseline honestly measured | C0 |
| AC08 | Eight controls and 28 ACs frozen before adverse execution | C0 |
| AC09 | Actual legacy C decision source bytes, macro and enum constants bound | C1 |
| AC10 | Real C-ON production compiler proves active PolyC delegation | C1 |
| AC11 | Real C-OFF production compiler proves active C authority, absent PolyC import | C1 |
| AC12 | C-ON and C-OFF pristine witness and fixture results frozen | C1 |
| AC13 | C-only mutation is one exact selected semantic change in a detached worktree | C2 |
| AC14 | Mutated C-OFF real production compiler builds successfully and selected object changes | C2 |
| AC15 | Mutation changes selected real witness/compiler acceptance or semantic output | C2 |
| AC16 | Mutation leaves C-ON PolyC-authoritative production behavior unchanged | C2 |
| AC17 | Pristine C-only source and observed behavior restored byte-identically | C2 |
| AC18 | Historic S7-CC-01 and new literal N-06 experiments have distinct provenance | C2 |
| AC19 | All 8 negative controls actually executed and sensitive for intended detector | C3 |
| AC20 | Independent exact-ID proof ledger excludes vacuous PASS and unsupported double counting | C3 |
| AC21 | All predecessor ACT/HANDOFF/evidence path hashes remain unchanged | C3 |
| AC22 | Production source delta=0; seven compiler authorities remain active | C3 |
| AC23 | Parser 376/376 and assertion-sequence MD5 conserved; zero new parser IDs | C3 |
| AC24 | Lexer differential and exact historical LEXER07 failures conserved | C3 |
| AC25 | Cross-target 67, F-NO-PYTHON 12 and F-POLYC-TOOLS UNAVAILABLE reported truthfully | C3 |
| AC26 | Real serialized gate-fast/gate-push PASS, plus F14/append-only/hygiene | C3 |
| AC27 | Exact AC ledger joined: 27 PASS, AC28 alone deferred to CLOSE | C3 |
| AC28 | Single valid terminal CLOSE; external post-CLOSE read-only checks PASS | C4 |

No acceptance criterion may be weakened, renamed, post-hoc rewritten or
counted as PASS based only on prose.

---

## 9. Evidence ownership

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01/
  c0/ entry-identity.txt  predecessor-freeze.tsv  frozen-n06-contract.md
      historical-n06-reproduction.tsv  baseline-*.txt
      mandatory-ac-contract.tsv  negative-controls-contract.tsv
  c1/ source-binding.tsv  pristine-c-on.txt  pristine-c-off.txt
      compiled-oracle-and-provenance.tsv  witness-contract.tsv
  c2/ c-only-mutation.diff  c-only-build-and-causality.txt
      dormant-branch-anti-control.txt  source-restoration.txt
      negative-controls-raw.tsv
  c3/ independent-n06-join.tsv  independent-controls-join.tsv
      conservation.txt  gate-fast.txt  gate-push.txt
      factory-invariants.txt  mandatory-ac-status.tsv
  c4/ terminality.txt  # optional pre-CLOSE plan only; external receipt remains outside the repo
```

Require raw outputs or exact reproducible artifact references for all
compiler builds and witnesses; summaries alone are not proof. Avoid
committing generated binaries or giant raw logs into the repository without
repository policy authorization.

---

## 10. Execution discipline and HALT guards

- Fail closed if the exact selected C decision cannot be reached in a real
  C-OFF compiler without changing unauthorized source or build wiring.
- Fail closed if the C mutant is not compiled into the real selected parser
  object, the compiler itself fails to build, or the witness exhibits no
  targeted observable difference.
- Fail closed if mutating the dormant legacy C decision affects the active
  C-ON production compiler, suggesting legacy C authority was not fully
  retired.
- Fail closed if N-06 and S7-CC-01 remain indistinguishable as executions or
  any original frozen evidence is edited.
- Preserve `HALT_CLASS=GOVERNANCE`, `BLOCKS_NEXT=NO` for historical RECON06;
  classification of any new HALT must follow current doctrine, not guesswork.
- Do not label a successful correction experiment as an event that occurred
  in SLICE07's historical C3.
- Do not silently convert LEXER07, cross-target, F-NO-PYTHON or F-POLYC-TOOLS
  residual statuses into PASS.
- No unrelated SLICE06 CMake producer repair, shared temp race repair,
  inline assembly repair, parser migration or candidate selection.

---

## 11. Terminal reporting schema

```text
ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01
VERDICT=<PASS|HALT_...>
DISPOSITION=<PASS_EVIDENCE_SUPPLEMENTED|HALT_...>
ENTRY_HEAD=aa90d34193cd67ace532e743e8fd837e6237d8e3
FINAL_HEAD=<measured>
FINAL_TREE=<measured>
ACT_COMMIT_COUNT=<measured>
WORKTREE_CLEAN=<YES|NO>
GIT_REPLACE_REFS=0
SLICE07_HISTORICAL_N06_EXECUTED_AS_WRITTEN=NO
N06_HISTORICAL_SUBJECT=POLYC_SOURCE
N06_CORRECTION_LITERAL_C_MUTATION=<PROVEN|UNPROVEN>
C_ON_PRODUCTION_POLYC_AUTHORITY=<YES|NO>
C_OFF_LEGACY_C_AUTHORITY=<YES|NO>
C_OFF_MUTANT_BUILD=<PASS|FAIL>
C_OFF_CAUSAL_OBSERVATION=<channel, identity and result>
C_ON_DORMANT_BRANCH_INVARIANCE=<PASS|FAIL>
RESTORATION_BYTE_IDENTICAL=<YES|NO>
N06_S7CC01_HISTORICAL_DISTINCT_EXPERIMENTS=NO
N06_CORRECTION_DISTINCT_FROM_S7CC01=<YES|NO>
NEGATIVE_CONTROLS_TOTAL=8
NEGATIVE_CONTROLS_PASS=<measured>
MANDATORY_AC_TOTAL=28
MANDATORY_AC_PASS=<measured>
CURRENT_POLYC_PARSER_AUTHORITIES=7
PRODUCTION_SEMANTIC_DELTA=0
PARSER_ASSERTIONS=376/376
LEXER07_HISTORICAL_STATUS=FAIL_KNOWN_BASELINE
CROSS_TARGET_PREFIX_STATUS=FAIL_ENVIRONMENT_PREFIX
F_NO_PYTHON=FAIL_KNOWN_BASELINE
F_POLYC_TOOLS=UNAVAILABLE
GATE_FAST=<PASS|FAIL>
GATE_PUSH=<PASS|FAIL>
FACTORY_V2_RANGE_CHECK=<PASS|FAIL>
F14=<PASS|FAIL>
APPEND_ONLY=<PASS|FAIL>
NEXT_PARSER_TARGET=NONE
SLICE08_AUTHORIZED=NO
POST_CLOSE_CONTINUATION=NO
```

**Terminal interpretation:** a successful correction extends the evidence
record without inventing a historical experiment or erasing RECON06's HALT.
No additional compiler authority is migrated by this ACT.
