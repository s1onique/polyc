# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-SLICE07-SELECTION
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** current main checkout (no ceremonial ACT branch)
**Expected ENTRY_HEAD:** `2bafd875a60fc8347c4f17ca24350d682fd63355`
**Expected ENTRY_TREE:** `76f6908ecb9730a0b20becd289bee54974d27b17`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE07` (closed with
`ACT-Verdict: PASS`)
**Successor:** NONE PRESELECTED. `SLICE08` is conditional on this ACT's
independent selection and terminality.

---

## 0. Mission and terminal contract

Following the seventh production-authoritative compiled PolyC parser
decision (`SUB-003`, `BootstrapCompoundBlockAppendsStatement`),
re-inventory the current production parser/AST decision surface and
select exactly one further bounded, production-reachable, genuinely
independent and causally observable legacy-C authority to migrate into
PolyC; otherwise HALT with a complete exclusion dossier.

**This is a reconnaissance and authorization ACT, not an implementation
ACT.** It MUST NOT add an eighth PolyC production authority, alter any
tracked `src/**` or `tools/bootstrap/**`, implement an alternate
decision, broaden host ownership, or create `SLICE08` as though it were
already executed.

### The additional prerequisite

Independently audit SLICE07's frozen inherited negative control `N-06`,
whose literal C-source mutation obligation appears to have been
represented by the PolyC-source `S7-CC-01` experiment.  The attached
digest omits `c3/inherited-controls-join.tsv`; do not turn an
information gap into either a PASS or a finding of failure.  Audit the
actual committed artifacts before the candidate census.  A material
failure to discharge the frozen obligation is a HALT requiring a
separate append-only correction ACT.  No closed historical artifact may
be rewritten.

---

## 1. The terminal outcome of this ACT

```text
ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06
VERDICT=HALT
HALT_REASON=HALT_N06_FROZEN_OBLIGATION_UNPROVEN
N06_DISPOSITION=N06_UNPROVEN
```

The ACT halted at its **C0 entry audit**, before the candidate census.
The blocking fact is fully characterised in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-literal-control-audit.md`
and machine-verified by the RECON06 PolyC verifier in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-machine-verification.txt`.

### 1.1 The blocking fact, in one paragraph

The frozen RECON05 control `N-06` obliges the successor to *"Mutate
ONLY the selected **C** decision in a disposable worktree, rebuild the
real compiler, and run the witness."*  The committed SLICE07 C3
evidence records, in its own words,
`MUTATION_SCOPE=tools/bootstrap/selfhost-parser-slice07.HC ONLY` and
`MUTATION_IS_IN_SRC_PARSER_C=NO`.  No frozen RECON05 artifact
authorises that subject substitution (the whole frozen `c2/` corpus
contains **zero** such clause), and the frozen
`selected-red-contract.md` RED-05 successor-state column affirmatively
requires *"the C decision is delegated"*, leaving no active C decision
to mutate.  The predecessor's own C1 file states that the single
experiment's result *"is reported under BOTH N-06 and S7-CC-01"*.  The
real compiler WAS rebuilt and the witness DID change, but on the PolyC
subject.  Therefore the frozen control's literal subject has no evidence
of its own, and the disposition is `N06_UNPROVEN`.

### 1.2 What this HALT does NOT say

* It does **not** impeach SLICE07's production result.  The seven PolyC
  parser authorities are independently re-verified at C0 from the live
  build: every selector is ON, every subject object defines its symbol,
  every caller object imports it, the production binary links it, and
  the legacy C comparison is compiled out of the active production path
  (`c0/existing-production-authorities.tsv`).  The SUB-003 migration is
  a fact about the built compiler, not a conclusion drawn from `N-06`.
* It does **not** rewrite, reopen or invalidate SLICE07's historical
  CLOSE (F14).
* It does **not** claim that no candidate exists.  The census, the
  eligibility run, the ranking, the oracle, the fixture and the causal
  proof are **FORWARD OBLIGATIONS** that this ACT never reached.

### 1.3 The mechanical-blocking classification

Per `docs/factory/DOCTRINE.md` §25, the blocking predicates are B1-B5.
This finding is a **historical evidence-hygiene defect**, which §25
lists explicitly among the NON-BLOCKING categories by default:

* not B1 -- no executable gate fails (`gate-fast` and `gate-push` PASS);
* not B2 -- no reproducible semantic/runtime/compiler defect exists in
  the production subject (the compiler is correct and the seven
  authorities are object-verified);
* not B3 -- no safety, integrity, corruption, security or
  destructive-operation invariant is violated;
* not B4 -- no production change is required to correct it;
* not B5 -- the successor's production authority does not mechanically
  depend on the `N-06` *causal-control* evidence; it depends on the
  object-verified delegation, which is sound.

```text
HALT_CLASS=GOVERNANCE
BLOCKS_NEXT=NO
```

The roadmap may proceed.  The correction is an evidence-hygiene
obligation, not a production blocker.

---

## 2. The required correction (narrowly scoped, append-only)

A separate, explicitly authorized correction ACT is required.  It must
be **append-only**; no closed artifact may be edited.

```text
PROPOSED_CORRECTION_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01
PROPOSED_CORRECTION_CLASS=EVIDENCE-HYGIENE (no production change)
```

It must, at minimum:

1. **Execute the literal N-06 experiment** -- mutate ONLY the selected C
   decision in a disposable detached worktree, rebuild the real
   compiler, run the witness -- and record it as N-06's OWN evidence,
   separately from S7-CC-01; **or**
2. **Record an explicit, pre-declared, frozen amendment** that
   authorises the successor-authority analogue, so that the
   substitution is no longer a retroactive reinterpretation.  Such an
   amendment must acknowledge that the frozen RED-05 successor-state
   column requires the C decision to be delegated, and must state
   exactly what is being amended and why the frozen text was
   unsatisfiable as written; **and**
3. **Disambiguate the N-06 / S7-CC-01 double reporting** in the control
   accounting, so that one experiment is not reported as two
   independent control discharges.

The correction is an evidence obligation.  **No production source
change is required, and none is proposed.**

---

## 3. Scope and non-goals

Permitted tracked changes are limited to:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/**
tools/quality/parser-surface-recon06-*.HC
Makefile            # ONLY if a concrete verifier invocation needs it;
                    # no gate weakening
```

No tracked modifications to `src/**`, `tools/bootstrap/**`, closed
quality checkers/rankers, existing `.factory/` gate semantics,
historical ACT/HANDOFF/evidence trees, original tests or original
fixtures.

No new Python, no dependencies, no substantial Bash/shell test logic, no
new branch as ceremony, no historical amend/rebase/reset, no force push.
Substantive new verifiers and independent recomputation must be
PolyC-source `.HC` tools built and executed using an actual compiler.
Bounded shell glue, if unavoidable, is not an eligibility/ranking/oracle
authority.  Do not declare missing F-POLYC-TOOLS as PASS.

The shared `/tmp/holyc-asm.s` is a known race risk: serialize all
build, JIT, test, and gate executions unless isolated temporary
namespaces have been demonstrated.  Do not fix the shared-temp race
within this ACT.

---

## 4. The C0 work that WAS completed

Because the halt occurs at the section 1.1 prerequisite, the following
C0 obligations were discharged and are frozen in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/`:

| Artifact | Content |
|---|---|
| `entry-identity.txt` | exact HEAD, tree, branch, clean state, zero replace refs |
| `predecessor-terminal-verification.txt` | the SLICE07 five-commit range, its trailers, the canonical range check, the external terminality receipt |
| `predecessor-freeze.tsv` | 298 frozen predecessor paths with SHA-256, re-verified |
| `n06-literal-control-audit.tsv` | the machine-joined audit row |
| `n06-literal-control-audit.md` | the five required answers, with the evidence for each |
| `n06-machine-verification.txt` | the PolyC verifier's independent re-derivation |
| `baseline-parser.txt` | 376/376, MD5 `b6f117eb1386ca80f81bc06226e2a741` |
| `baseline-lexer.txt` | 89/89, 45/45, 23/23, all PASS |
| `baseline-lexer07.txt` | 15 failure identities, MD5 `7ee761440de83552e751e3c3976c1683`, STATUS=FAIL |
| `baseline-cross-target.txt` | 67 failed-to-open-file, STATUS=FAIL_ENVIRONMENT_PREFIX |
| `baseline-tool-policy.txt` | F-NO-PYTHON FAIL with exactly 12; F-POLYC-TOOLS UNAVAILABLE |
| `baseline-gates.txt` | gate-fast PASS, gate-push PASS, append-only PASS, range PASS |
| `existing-production-authorities.tsv` | the seven authorities, object-verified |
| `mandatory-ac-contract.tsv` | the 50 predicates, frozen before outcomes |
| `frozen-negative-controls.tsv` | the 20 controls, frozen before outcomes |
| `red-reproduction.txt` | 5 reproduced REDs, 6 forward obligations |

### 4.1 The RECON06 PolyC verifier

`tools/quality/parser-surface-recon06-audit.HC` is the ACT's single new
substantive verifier.  It is a **PolyC** implementation (F-POLYC-TOOLS
compliant), built and executed with the actual compiler:

```text
./hcc --install-dir=./build/test-prefix -c \
      tools/quality/parser-surface-recon06-audit.HC \
      -o build/parser-surface-recon06-audit.o
cc build/parser-surface-recon06-audit.o \
   -L./build/test-prefix/lib -ltos -o build/parser-surface-recon06-audit
```

It has four modes: `FREEZE` (generate a path-hash manifest), `VERIFY`
(re-check a manifest -- the F14 detector), `N06` (mechanically
re-derive the decisive N-06 facts) and `SELFTEST` (known-answer
vectors, so the tool is demonstrably not a no-op).  Its SHA-256 output
was cross-validated against `shasum -a 256` on sampled paths, and its
output for the RECON05 ACT document equals the digest SLICE07 froze.

### 4.2 The forward obligations this ACT did NOT reach

C1 (live census, dependency analysis, candidate registry
reconciliation), C2 (eligibility, ranking, causality, selection freeze),
C3 (independent recomputation, conservation) and C4 (conditional
successor authorization) were **not executed**.  The section 6 twenty
negative controls were **not executed**.  The section 11 fifty
predicates were **not** observed as PASS; the C0 contract is a frozen
definition, not a result.  No candidate was selected and no successor
ACT is authorized.

---

## 5. Halt taxonomy

The halt reason for this ACT is `HALT_N06_FROZEN_OBLIGATION_UNPROVEN`.
The ACT's full taxonomy remains as written:

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_UNVERIFIED
HALT_N06_FROZEN_OBLIGATION_UNPROVEN
HALT_HISTORICAL_ARTIFACT_MUTATED
HALT_INCOMPLETE_CENSUS
HALT_UNBOUND_SOURCE_IDENTITY
HALT_UNCLASSIFIED_DEPENDENCY
HALT_MUTABLE_HOST_STATE_LEAK
HALT_CALLBACK_RECOVERY_OR_GRAPH_OWNERSHIP
HALT_CANONICAL_SCHEMA_UNFIT
HALT_ELIGIBILITY_MISMATCH
HALT_RANKING_MISMATCH
HALT_NO_BOUNDED_CAUSAL_CANDIDATE
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_PRODUCTION_C_OBJECT_NOT_INDEPENDENT
HALT_FIXTURE_OR_ORACLE_UNPROVEN
HALT_COMPILER_MUTANT_FAILED_TO_BUILD
HALT_REAL_COMPILER_CAUSALITY_UNPROVEN
HALT_RESTORATION_NOT_IDENTICAL
HALT_NEW_PARSER_OR_LEXER_FAILURE
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_INVARIANT
HALT_MANDATORY_AC
HALT_TERMINALITY
```

The first actual blocker is reported with all corroborating evidence,
not merely a generic failure.  No observed failure is erased and no
frozen predicate is changed to enable closure.

---

## 6. Terminal report schema

```text
ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06
VERDICT=HALT
HALT_REASON=HALT_N06_FROZEN_OBLIGATION_UNPROVEN
ENTRY_HEAD=2bafd875a60fc8347c4f17ca24350d682fd63355
ENTRY_TREE=76f6908ecb9730a0b20becd289bee54974d27b17
FINAL_HEAD=
FINAL_TREE=
ACT_COMMIT_COUNT=
WORKTREE_CLEAN=
GIT_REPLACE_REFS=0
PREDECESSOR_SLICE07_CLOSE_VERIFIED=YES
PREDECESSOR_ARTIFACT_HASHES_MATCH=YES
N06_DISPOSITION=N06_UNPROVEN
N06_EVIDENCE_JOIN_PATH=evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-literal-control-audit.tsv
LIVE_FUNCTIONS_TOTAL=NOT_MEASURED (C1 not reached)
RECON05_FUNCTIONS_ADDED=NOT_MEASURED
RECON05_FUNCTIONS_REMOVED=NOT_MEASURED
RECON05_FUNCTIONS_CHANGED=NOT_MEASURED
UNCLASSIFIED_FUNCTIONS=NOT_MEASURED
UNCLASSIFIED_SUBSLICES=NOT_MEASURED
UNCLASSIFIED_DEPENDENCIES=NOT_MEASURED
CURRENT_POLYC_PARSER_AUTHORITIES=7
CURRENT_CANDIDATES_TOTAL=NOT_MEASURED
ELIGIBLE_STRUCTURAL=NOT_MEASURED
ELIGIBLE_SCALAR=NOT_MEASURED
INELIGIBLE_STRUCTURAL=NOT_MEASURED
SUB002_DISPOSITION=NOT_MEASURED
SUB003_ALREADY_MIGRATED=YES
SUB004_DISPOSITION=NOT_MEASURED
INDEPENDENT_ELIGIBILITY_JOIN=NOT_REACHED
INDEPENDENT_FULL_RANKING_JOIN=NOT_REACHED
SELECTED_CANDIDATE_ID=NONE
SELECTED_CLASS=NONE
SELECTED_SOURCE_FILE=NONE
SELECTED_SOURCE_RANGE=NONE
SELECTED_SOURCE_SHA256=NONE
SELECTED_ABI=NONE
SELECTED_PRODUCTION_SEAM=NONE
SELECTED_G0_REAL_PRODUCTION_C_OBJECT=NONE
SELECTED_CAUSAL_COMPILER_BUILD=NONE
SELECTED_CAUSAL_OBSERVATION_CHANNEL=NONE
SELECTED_CAUSAL_PRISTINE_HASH=NONE
SELECTED_CAUSAL_MUTANT_HASH=NONE
SELECTED_CAUSAL_RESTORED_HASH=NONE
SELECTED_RESTORATION_BYTE_IDENTICAL=NONE
FUTURE_G1_G2_G3_FEASIBILITY=NOT_REACHED
NEGATIVE_CONTROLS_TOTAL=20
NEGATIVE_CONTROLS_INTENDED_PASS=0
NEGATIVE_CONTROLS_UNPROVEN=20
PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0
PARSER_ASSERTIONS=376/376
PARSER_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0
LEXER07_HISTORICAL_STATUS=FAIL_KNOWN_BASELINE
LEXER07_FAILURE_IDENTITY_MD5=7ee761440de83552e751e3c3976c1683
CROSS_TARGET_PREFIX_STATUS=FAIL_ENVIRONMENT_PREFIX
F_NO_PYTHON=FAIL_KNOWN_BASELINE
F_POLYC_TOOLS=UNAVAILABLE
GATE_FAST=PASS
GATE_PUSH=PASS
APPEND_ONLY=PASS
F14=PASS
FACTORY_V2_RANGE_CHECK=PASS
PATCH_HYGIENE=PASS
MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=0
MANDATORY_AC_FAIL=0
MANDATORY_AC_UNPROVEN=50
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01
NEXT_ACT_STATUS=ACTIVE
NEXT_TARGET=NONE
POST_CLOSE_CONTINUATION=NO
```

**Terminal meaning.**  This ACT's PASS was NOT achieved, and no
selection is claimed.  What IS established is that the seventh PolyC
parser authority is real and conserved, and that the eighth cannot be
honestly selected until the predecessor's frozen `N-06` obligation is
discharged by a separate, append-only correction.

---

## 7. The backlog this ACT did NOT touch

Explicitly not authorized here, and not touched:

* SLICE06 stale `src/CMakeLists.txt` producer `--install-dir` path (P2);
* the historical LEXER07 broad-corpus FAIL, exact 15 failure identities;
* the historical 67 cross-target runtime-prefix failures (`include/tos.HH`);
* the historical 12 F-NO-PYTHON violations and the shell-tool policy debt;
* the F-POLYC-TOOLS checker not landed -- never label UNAVAILABLE as PASS;
* the shared `/tmp/holyc-asm.s` build/JIT race -- serialized execution
  until independently repaired;
* whole-function parser and AST graph ownership, the Dafny trust ladder
  and proof-stability work.
