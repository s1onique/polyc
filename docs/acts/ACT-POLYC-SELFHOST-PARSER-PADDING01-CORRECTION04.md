# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
ACT-Phase: RED

**Title:** Restore F14 closed-surface immutability, repair Factory-v2
closure geometry, and prospectively requalify the SHA-bound LEXER07
forward baseline

**Class:** CORRECTION / GOVERNANCE-CLOSURE REPAIR

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Entry HEAD:** `9ea5bc4a5919c5a37fc0be8f4f2a57dea7e41b94`

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03`

**Predecessor committed verdict:** `PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED`

**Predecessor corrected disposition:** `HALT_FALSE_GREEN`

**Production subject:** `BootstrapCalcPadding`

**Production authority at entry:** `LEGACY_C`

**Production mutation authorized:** **NONE**

**Blocked successor:** `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01`

---

## 0. Mission

Repair the four binding closure-authority defects remaining after
CORRECTION03 without modifying parser-padding semantics, regenerating
the LEXER07 prospective baseline, or weakening any previously-proven
engineering property.

The four defects are:

```text
D1_F14_CLOSED_SURFACE
D2_RANGE_CHECK_TRAILER_PLACEMENT
D3_EXACT_5_COMMIT_TOPOLOGY
D4_POST_C4_TERMINALITY_MODEL
```

The substantive CORRECTION03 provenance repair is retained unchanged:

```text
CORRECTION03_D_PROV                       = ENGINEERING_GREEN
CORRECTION03_PROSPECTIVE_PATCH_HYGIENE    = ENGINEERING_GREEN
CORRECTION03_PARSER_PADDING_CONSERVATION  = ENGINEERING_GREEN
```

This ACT does **not** repair those again.

The required final state is:

```text
CORRECTION02_CLOSED_SURFACE_RESTORED   = YES
LEXER07_FORWARD_BASELINE_SHA_BOUND     = YES
FACTORY_V2_RANGE_CHECK                 = PASS
CORRECTION04_COMMIT_COUNT              = 5
C4_IS_LAST_COMMIT_IN_ACT_RANGE         = YES
EXTERNAL_TERMINALITY_GATE              = PASS
PARSER_PADDING_DELEGATE01              = READY
```

---

## 1. Predecessor truth disposition

CORRECTION03 remains immutable historical evidence.

Its truthful disposition is:

```text
CORRECTION03_COMMITTED_VERDICT  = PASS_FORWARD_BASELINE_REQUALIFIED_REPAIRED
CORRECTION03_EFFECTIVE_VERDICT  = HALT_FALSE_GREEN
```

Reasons:

```text
AC15_RANGE_CHECK               = FAIL
EXACT_COMMIT_COUNT             = 6, not 5
POST_C4_COMMIT_COUNT           = 1
F14_CLOSED_SURFACE_DELTA       != 0
```

CORRECTION04 MUST NOT edit the CORRECTION03 ACT body, HANDOFF, or
closed evidence in order to make those statements disappear.

---

## 2. Accepted engineering facts

The following facts are carried forward and are not reopened:

```text
PROSPECTIVE_LEXER07_BASELINE_SHA256
  = 00c54408bf29237cf526aeed097f6b097f22ae682683675a0bf5ab9f9c202b9a

PRODUCER_SOURCE_SHA256
  = 820e2c3c808411dd13e06ff2850888811b5389c3f98dadc2878bfad9a685bbd2

PRODUCER_BINARY_SHA256
  = c8165800b15a7e5d326dc1bb53e3579ce7b020174369dc7fc1e7b227f095dea3

COMPILER_FINAL_SHA256
  = daac3b43680a0edb131decaf2745dc8e2bb09d9b42bd34cd58f53270c48c60fe

COMPILER_BOOTSTRAP02_SHA256
  = 3b1e2cd16b027bf533e661567875ae9bf8e626cf74f372355626706601fe785a

COMPILER_BOOTSTRAP03_SHA256
  = b8a9781a7ef68e3da05427d03bc04f4250b76a967fd761147c6ef7100b9acdca

COMPILER_BOOTSTRAP04_SHA256
  = 3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6

INPUT_SHA256
  = ab8f77814e2418a7f99fd531caa02a8e2e2976a519fb84eb4a7adedb186c5f55

WRAPPER_SCRIPT_SHA256
  = 31f27d5e3b038feaa47c8a554efd16682cc3c366e4b7574b210ebb4b415394db

COMMAND_SHA256
  = 7e9f7f05cd575daed6ccde061c81dcaa1233be4aa81e8ed4e4169ae82d81ce71

OUTPUT_MATRIX_SHA256
  = ee83e375032cf3f39ad8d95838bdd5e4f601fdac3244b7298cf2f68083d3c4fd

OUTPUT_FAILURES_SHA256
  = 9d8ce2e090a47619a1496df76d2f1efbde47f60f997fc8ad4182f21cf125a29a

OUTPUT_OBJECT_PROVENANCE_SHA256
  = 7cdf8016b7aceef4f3f244c942430f02452fa8138061d4fa7d246e88813b1c42
```

These values are conservation inputs, not subjects for requalification.

---

## 3. Non-goals

This ACT MUST NOT:

* modify `src/parser.c`;
* modify `tools/bootstrap/selfhost-parser-padding.HC`;
* modify parser-padding differential or mutation tools;
* modify parser-padding oracle semantics;
* regenerate or redefine the LEXER07 prospective baseline;
* change any LEXER07 failure classification;
* repair historical CORRECTION02 patch hygiene;
* claim historical CORRECTION02 or CORRECTION03 TRUE_GREEN;
* edit CORRECTION02 HANDOFF;
* edit CORRECTION03 HANDOFF;
* edit CORRECTION03 evidence;
* rebase, amend, reset/recommit, or force-push authoritative history;
* weaken Factory-v2 range validation;
* introduce a sixth CORRECTION04 commit.

---

## 4. Defect D1 - F14 closed-surface violation

CORRECTION03 changed:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/
  c2/c2-baseline-verifier-negative-control.txt
```

The CORRECTION02 close blob is authoritative historical evidence.

CORRECTION04 must restore the HEAD copy exactly to the blob at:

```text
3b38d6910c7a117b0a98a98d84ab5114da70cb83
```

The closed-surface blob (per `git ls-tree 3b38d69:` for that path)
is `3ac4ebbf0723598ab5b08c1121d23b553cb2aff38ede0d56cccb5e0a0316511a`.

Mechanically:

```sh
git checkout 3b38d691 -- \
  evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c2/c2-baseline-verifier-negative-control.txt
```

The purpose is **restoration**, not rewriting history.

After restoration require:

```text
CORRECTION02_C2_BLOB_AT_HEAD  ==  CORRECTION02_C2_BLOB_AT_3b38d69
```

Historical consequence:

```text
CORRECTION02_PATCH_HYGIENE = FAIL
```

and that remains true permanently.

---

## 5. Defect D2 - invalid supersession trailer placement

CORRECTION03 placed supersession/corrected-verdict trailers on C0.

Current Factory-v2 range validation requires such trailers only where
the validator permits them, specifically the CLOSE disposition.

CORRECTION04 C0 MUST NOT contain:

```text
ACT-Supersedes:
ACT-Corrected-Verdict:
```

C0 contains only ordinary ACT identity/phase trailers.

The corrected predecessor disposition appears in:

1. new CORRECTION04 evidence; and
2. CORRECTION04 C4/CLOSE commit trailers.

No existing commit is changed.

Required C4 trailers (literal form captured at C1 from the live
range-check validator; see `evidence/.../c1-range-check-contract.txt`):

```text
ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
ACT-Phase: CLOSE
ACT-Verdict: PASS_PENDING_EXTERNAL_TERMINALITY
ACT-Supersedes: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03
ACT-Corrected-Verdict: HALT_FALSE_GREEN
```

No trailer contract may be guessed.

---

## 6. Defect D3 - excess post-C4 commit topology

CORRECTION03 is permanently:

```text
COMMIT_COUNT=6
POST_C4_COMMIT_COUNT=1
```

CORRECTION04 does not try to reinterpret this.

Its own topology is fresh:

```text
ENTRY = 9ea5bc4

C0 AUTH      -> trailer ACT-Phase: RED
C1 RECON/RED -> trailer ACT-Phase: EVIDENCE
C2 RESTORE   -> trailer ACT-Phase: IMPL
C3 VERIFY    -> trailer ACT-Phase: EVIDENCE
C4 CLOSE     -> trailer ACT-Phase: CLOSE
```

Exactly 5 commits.

The body labels (C0..C4) document the work scope; the trailer
`ACT-Phase:` values use the validator-enum literal
`RED | IMPL | EVIDENCE | CLOSE` (captured from the live checker at
C1). The validator does not accept `C0..C4` or other custom labels.

No:

```text
C2.1
C3.1
C4-fixup
terminal-ledger-fix
whitespace-cleanup
```

If a defect is discovered after C2:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

If a defect is discovered after C4:

```text
CORRECTION04 remains closed in its observed state;
open CORRECTION05 if necessary.
```

Do not create a sixth commit.

---

## 7. Defect D4 - impossible self-proof of POST_C4_COMMIT_COUNT=0

A C4 commit cannot contain a committed observation that proves there
will be no commit after itself.

Therefore CORRECTION04 explicitly removes:

```text
POST_C4_COMMIT_COUNT=0
```

from the set of facts that must be self-proven inside C4.

Instead closure uses two layers.

### 7.1 In-repository closure predicate

At C4, prove:

```text
PRE_C4_TIP = C3
ENTRY..PRE_C4_TIP = 4 commits
PRE_C4_TIP is parent of candidate C4
candidate ACT range contains exactly C0,C1,C2,C3,C4
```

This establishes:

```text
C4_IS_THE_5TH_ACT_COMMIT=YES
```

### 7.2 External terminality predicate

After C4 exists, but without creating another commit, run:

```sh
bash scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 \
  "$(git rev-parse HEAD)"

git rev-list --count 9ea5bc4..HEAD
```

Require:

```text
STATUS=PASS
COMMITS=5
CLOSE=C4
```

This observation belongs to:

```text
EXTERNAL_TERMINALITY_GATE
```

not to evidence falsely claimed as observed from within C4.

The external observer may be:

* a pre-push hook;
* push-time Factory gate;
* CI status check;
* review harness invocation after C4 exists.

It MUST NOT create a repository commit.

If no external observer is available:

```text
VERDICT=PASS_PENDING_EXTERNAL_TERMINALITY
PARSER_PADDING_DELEGATE01=BLOCKED
```

Only after external observation passes:

```text
EXTERNAL_TERMINALITY_GATE=PASS
PARSER_PADDING_DELEGATE01=READY
```

---

## 8. Entry gate

Before C0:

```sh
git branch --show-current
git rev-parse HEAD
git status --short
git diff --check
git log --oneline -12
```

Require:

```text
BRANCH=main
ENTRY_HEAD=9ea5bc4a5919c5a37fc0be8f4f2a57dea7e41b94
WORKTREE_CLEAN=YES
```

The fact that historical CORRECTION02 evidence differs from its close
is expected at entry and is D1 RED.

Record:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04/c0/
  c0-entry-identity.txt
  c0-scope.txt
  c0-defect-contract.txt
  c0-f14-baseline.txt
  c0-required-result.txt
```

---

## 9. C0 AUTH

Create:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04.md
```

No supersession trailers on C0.

Commit:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 C0: AUTH
```

Trailers (literal form required by Factory-v2 validator; the validator
forbids `ACT-Verdict:` on RED-phase commits):

```text
ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
ACT-Phase: RED
```

---

## 10. C1 RECON / RED

C1 mechanically reproduces all four predecessor defects.

### RED-1 - closed evidence differs

```sh
git diff \
  3b38d691..HEAD -- \
  evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/
```

Require:

```text
CLOSED_CORRECTION02_EVIDENCE_DELTA > 0
```

Specifically identify the modified C2 file.

### RED-2 - predecessor range-check failure

Run against CORRECTION03 terminal HEAD:

```sh
bash scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03 \
  17eeb85
```

and/or the final observed HEAD per checker contract.

Require reproduction of the supersession-trailer defect.

### RED-3 - predecessor topology

```sh
git rev-list --count 3b38d691..9ea5bc4
```

Require:

```text
CORRECTION03_COMMIT_COUNT=6
```

Identify:

```text
C4=17eeb85
POST_C4_FIXUP=9ea5bc4
```

### RED-4 - self-observation impossibility

Record the contradiction:

```text
A C4-contained file can observe only pre-C4 repository state at the
time its contents are written.

A post-C4 observation necessarily occurs after C4 exists.

Committing that observation creates another commit.
```

Therefore:

```text
POST_C4_COMMIT_COUNT=0
```

cannot be both:

```text
committed as an observation after C4
```

and:

```text
true
```

without history rewriting.

The new external-gate model is therefore load-bearing.

---

## 11. C1 live-validator contract

Run the current validator against known good/bad sample commits to
derive, not guess, the allowed CLOSE trailer placement.

Capture:

```text
CLOSE_TRAILER_SCHEMA
C0_TRAILER_SCHEMA
RANGE_CHECK_EXPECTED_FIRST_PHASE
RANGE_CHECK_EXPECTED_CLOSE_PHASE
```

Evidence:

```text
c1-range-check-contract.txt
```

This file determines exact C4 trailers.

If the live checker contract is inconsistent with the ACT:

```text
HALT_VALIDATOR_CONTRACT_AMBIGUOUS
```

---

## 12. C1 evidence

Required:

```text
c1-red-f14.txt
c1-red-range-check.txt
c1-red-topology.txt
c1-red-post-c4-model.txt
c1-range-check-contract.txt
c1-required-result.txt
```

Commit:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 C1: RECON/RED
```

---

## 13. C2 implementation

C2 has exactly three allowed operations.

### 13.1 Restore CORRECTION02 closed evidence

Restore:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/
  c2/c2-baseline-verifier-negative-control.txt
```

to its blob at `3b38d69`.

Require:

```text
RESTORED_BLOB_EQUAL_TO_CORRECTION02_CLOSE=YES
```

### 13.2 Add CORRECTION04 prospective qualification evidence

Do **not** modify CORRECTION03 evidence.

Create new artifacts describing:

```text
CORRECTION02 historical patch hygiene = FAIL
CORRECTION03 corrected disposition     = HALT_FALSE_GREEN
CORRECTION03 SHA-bound provenance      = RETAINED
```

Suggested:

```text
evidence/.../CORRECTION04/c2/
  c2-f14-restoration.txt
  c2-provenance-conservation.txt
  c2-baseline-authority-conservation.txt
  c2-required-result.txt
```

### 13.3 Preserve baseline authority unchanged

Compute and compare the SHA of the authoritative prospective rows.

Do not append new baseline-result data unless required to record the
governance disposition.

Prefer a separate CORRECTION04 evidence file over rewriting the
authority registry.

If the registry requires an additive disposition row by doctrine,
append only that row.

No changes to existing SHA-bound rows.

---

## 14. C2 F14 proof

After restoration:

```sh
git diff \
  3b38d691..HEAD -- \
  evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/
```

Expected:

```text
EMPTY
```

This is the load-bearing F14 predicate:

```text
CORRECTION02_CLOSED_EVIDENCE_DELTA=0
```

Also:

```sh
git diff \
  3b38d691..HEAD -- \
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02.md
```

Expected:

```text
EMPTY
```

---

## 15. C2 conservation of SHA-bound baseline

Require exact preservation of:

```text
PROSPECTIVE_LEXER07_BASELINE_SHA256
PRODUCER_SOURCE_SHA256
PRODUCER_BINARY_SHA256
COMPILER_FINAL_SHA256
COMPILER_BOOTSTRAP02_SHA256
COMPILER_BOOTSTRAP03_SHA256
COMPILER_BOOTSTRAP04_SHA256
INPUT_SHA256
WRAPPER_SCRIPT_SHA256
COMMAND_SHA256
OUTPUT_MATRIX_SHA256
OUTPUT_FAILURES_SHA256
OUTPUT_OBJECT_PROVENANCE_SHA256
COUNTER_SHA256
```

No baseline regeneration.

No semantic comparison rerun unless a hash mismatch occurs.

Hash mismatch:

```text
HALT_BASELINE_AUTHORITY_CHANGED
```

---

## 16. C2 commit

Commit:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 C2: RESTORE F14 + FREEZE BASELINE AUTHORITY
```

No supersession trailers.

No C2.x.

---

## 17. C3 VERIFY

C3 is evidence-only.

Run:

```sh
git diff --check 9ea5bc4..HEAD
git status --short

bash scripts/quality/gate-fast.sh
bash scripts/quality/factory-append-only-test.sh

git diff \
  3b38d691..HEAD -- \
  evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/

git diff \
  3b38d691..HEAD -- \
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02.md
```

Require:

```text
PATCH_HYGIENE_ERRORS=0
GATE_FAST=PASS
APPEND_ONLY_FAIL=0

CORRECTION02_CLOSED_EVIDENCE_DELTA=0
CORRECTION02_CLOSED_HANDOFF_DELTA=0
```

---

## 18. C3 parser-padding conservation

Hash these subjects at ENTRY and C3:

```text
tools/bootstrap/selfhost-parser-padding.HC
tools/quality/parser-padding-algebraic-invariants.HC
tools/quality/parser-padding-generation-provenance-verify.HC
tools/quality/parser-padding-oracle-impl.c
src/parser.c
```

Require:

```text
PARSER_PADDING_SUBJECT_DELTA=0
```

Do not rerun their huge proof corpus.

Hash conservation is sufficient because this ACT forbids changes.

---

## 19. C3 baseline-authority conservation

Verify every accepted SHA in §2 against the current artifacts.

Require:

```text
BASELINE_AUTHORITY_HASH_ROWS_MATCH=YES
BASELINE_OUTPUT_IDENTITY_UNCHANGED=YES
BASELINE_FAILURE_CLASSIFICATION_UNCHANGED=YES
```

This does not regenerate the baseline.

---

## 20. C3 range-check dry run

At C3, HEAD is the fourth CORRECTION04 commit.

Run the checker in whatever pre-close/dry-run mode the current tool
supports.

If no dry-run mode exists, verify commit trailers independently.

Require:

```text
C0_TRAILERS_VALID=YES
C1_TRAILERS_VALID=YES
C2_TRAILERS_VALID=YES
C3_TRAILERS_VALID=YES
CLOSE_TRAILER_CONTRACT_FROZEN=YES
```

---

## 21. C3 pre-C4 topology witness

Capture:

```sh
PRE_C4_TIP="$(git rev-parse HEAD)"
git rev-list --count 9ea5bc4.."$PRE_C4_TIP"
```

Require:

```text
PRE_C4_COMMIT_COUNT=4
```

Record:

```text
PRE_C4_TIP_SHA=<C3 SHA>
```

This is a valid precondition for the candidate C4.

It does not claim anything about future commits.

---

## 22. C3 evidence

Required:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04/c3/
  c3-f14.txt
  c3-patch-hygiene.txt
  c3-factory-gates.txt
  c3-subject-conservation.txt
  c3-baseline-authority-conservation.txt
  c3-range-check-contract.txt
  c3-pre-c4-tip.txt
  c3-required-result.txt
  mandatory-ac-status.tsv
```

Commit:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 C3: VERIFY
```

---

## 23. Mandatory acceptance criteria

### Entry / identity

```text
AC01 ENTRY_HEAD=9ea5bc4...
AC02 BRANCH=main
AC03 WORKTREE_CLEAN_AT_C0=YES
AC04 C0_AUTH_BEFORE_REPAIR=YES
```

### RED

```text
AC05 D1_F14_RED_REPRODUCED=YES
AC06 D2_RANGE_CHECK_RED_REPRODUCED=YES
AC07 D3_SIX_COMMIT_RED_REPRODUCED=YES
AC08 D4_POST_C4_MODEL_RED_REPRODUCED=YES
```

### F14 restoration

```text
AC09 RESTORED_CORRECTION02_C2_BLOB_MATCH=YES
AC10 CORRECTION02_CLOSED_EVIDENCE_DELTA=0
AC11 CORRECTION02_CLOSED_HANDOFF_DELTA=0
```

### Baseline authority

```text
AC12 PROSPECTIVE_LEXER07_BASELINE_SHA256_UNCHANGED=YES
AC13 PRODUCER_SOURCE_SHA256_UNCHANGED=YES
AC14 PRODUCER_BINARY_SHA256_UNCHANGED=YES
AC15 ALL_4_COMPILER_SHA256_UNCHANGED=YES
AC16 INPUT_SHA256_UNCHANGED=YES
AC17 WRAPPER_SHA256_UNCHANGED=YES
AC18 COMMAND_SHA256_UNCHANGED=YES
AC19 OUTPUT_SHAS_UNCHANGED=YES
AC20 COUNTER_SHA256_UNCHANGED=YES
```

### Parser-padding conservation

```text
AC21 BOOTSTRAP_CALC_PADDING_DELTA=0
AC22 ALGEBRAIC_VERIFIER_DELTA=0
AC23 GENERATION_PROVENANCE_VERIFIER_DELTA=0
AC24 ORACLE_IMPL_DELTA=0
AC25 SRC_PARSER_DELTA=0
```

### Factory gates

```text
AC26 PATCH_HYGIENE_ERRORS=0
AC27 GATE_FAST=PASS
AC28 APPEND_ONLY_FAIL=0
AC29 F14=PASS
```

### Trailer/range contract

```text
AC30 C0_HAS_NO_SUPERSESSION_TRAILERS=YES
AC31 C1_HAS_NO_SUPERSESSION_TRAILERS=YES
AC32 C2_HAS_NO_SUPERSESSION_TRAILERS=YES
AC33 C3_HAS_NO_SUPERSESSION_TRAILERS=YES
AC34 C4_TRAILER_SCHEMA_FROZEN_FROM_LIVE_VALIDATOR=YES
```

### Lifecycle

```text
AC35 PRE_C4_COMMIT_COUNT=4
AC36 C4_IS_DIRECT_CHILD_OF_PRE_C4_TIP=YES
AC37 CORRECTION04_RANGE_COMMIT_COUNT=5
AC38 FACTORY_V2_RANGE_CHECK=PASS
AC39 EXTERNAL_TERMINALITY_GATE=PASS
AC40 WORKTREE_CLEAN_AFTER_C4=YES
```

AC37-AC40 are not falsely claimed at C3.

AC39 is explicitly external.

---

## 23a. Trailer phase mapping (validator-enum)

Per Factory-v2 doctrine (`docs/factory/GIT-METADATA.md` §2.1 and
`scripts/quality/factory-v2-range-check.sh` line 174/210):

```text
ACT-Phase values are LITERALLY one of:
  RED | IMPL | EVIDENCE | CLOSE
```

CORRECTION04 therefore maps its body labels to validator-enum phases:

```text
C0 AUTH      -> ACT-Phase: RED
C1 RECON/RED -> ACT-Phase: EVIDENCE
C2 RESTORE   -> ACT-Phase: IMPL
C3 VERIFY    -> ACT-Phase: EVIDENCE
C4 CLOSE     -> ACT-Phase: CLOSE
```

`ACT-Verdict:` is forbidden on RED/IMPL/EVIDENCE; required on CLOSE.
The body labels (C0..C4) live in the commit subject line and body
for human readability and are not enforced by the validator.

---

## 24. C3 ledger rules

Allowed statuses:

```text
PASS
FAIL
DEFERRED_TO_C4
DEFERRED_TO_EXTERNAL
```

At C3:

```text
AC37 DEFERRED_TO_C4
AC38 DEFERRED_TO_EXTERNAL
AC39 DEFERRED_TO_EXTERNAL
AC40 DEFERRED_TO_EXTERNAL
```

No:

```text
PASS_BY_DESIGN
PASS_PREEXISTING
PASS_EXPECTED
PASS_INTENT
```

---

## 25. C4 preconditions

Before preparing C4 files require:

```text
AC01..AC36 = PASS
WORKTREE contains only authorized C4 artifacts
PRE_C4_TIP_SHA = current committed C3
```

If not:

```text
HALT_MANDATORY_AC_NOT_GREEN
```

---

## 26. C4 allowed changes

Only:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04.md

evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04/c4/
  c4-entry-identity.txt
  c4-required-result.txt
  mandatory-ac-status-c4-candidate.tsv

docs/factory/act-handoff-map.tsv
```

plus a ROADMAP/board append **only if current doctrine requires it at
CLOSE**.

No source.

No baseline data.

No old evidence.

---

## 27. C4 HANDOFF verdict before external observation

The committed HANDOFF verdict is:

```text
PASS_PENDING_EXTERNAL_TERMINALITY
```

not final `PASS_*_REQUALIFIED`.

Reason:

```text
the C4 commit cannot observe its own terminality without an external
observer.
```

The HANDOFF records:

```text
ENGINEERING_RESULT=GREEN
F14_RESTORATION=GREEN
BASELINE_AUTHORITY=GREEN
TRAILER_GEOMETRY=GREEN
CANDIDATE_COMMIT_COUNT_AFTER_C4=EXPECTED_5
EXTERNAL_TERMINALITY_GATE=PENDING
PARSER_PADDING_DELEGATE01=BLOCKED_PENDING_EXTERNAL_GATE
```

This avoids another false-green.

---

## 28. C4 trailers

Use the exact schema captured from the live validator.

Conceptually:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
ACT-Phase: CLOSE
ACT-Verdict: PASS_PENDING_EXTERNAL_TERMINALITY
ACT-Supersedes: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION03
ACT-Corrected-Verdict: HALT_FALSE_GREEN
```

If current checker vocabulary differs, use its exact accepted form.

Do not guess.

---

## 29. External terminality gate

After C4 commit exists, **do not commit anything else**.

Run:

```sh
C4_SHA="$(git rev-parse HEAD)"

git rev-list --count 9ea5bc4.."$C4_SHA"

git merge-base --is-ancestor \
  "$(git rev-parse "$C4_SHA"^)" \
  "$C4_SHA"

bash scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04 \
  "$C4_SHA"

git status --short
```

Required:

```text
CORRECTION04_RANGE_COMMIT_COUNT=5
C4_DIRECT_PARENT_IS_C3=YES
FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
```

The external gate also verifies that the pushed/local candidate ref is
still exactly `C4_SHA`.

A pre-push hook is suitable because it receives both the local object
ID and the remote object ID and can reject the push without altering
history.

---

## 30. External verdict promotion

If external terminality gate passes:

```text
CORRECTION04_EFFECTIVE_VERDICT
  = PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED

PARSER_PADDING_DELEGATE01
  = READY
```

No repository commit is created to record this promotion.

The evidence of promotion belongs to the external gate/run/check.

If the external gate fails:

```text
CORRECTION04_EFFECTIVE_VERDICT
  = HALT_EXTERNAL_TERMINALITY_GATE

PARSER_PADDING_DELEGATE01
  = BLOCKED
```

Again: no follow-up commit.

---

## 31. Why no post-C4 metadata commit is permitted

Any follow-up repository commit would make:

```text
CORRECTION04_RANGE_COMMIT_COUNT > 5
```

and invalidate the closure.

Therefore:

```text
NO_C4_FIXUP
NO_C4_SHA_BACKFILL
NO_TERMINAL_LEDGER_COMMIT
NO_WHITESPACE_FIX_AFTER_C4
NO_ROADMAP_FIX_AFTER_C4
```

Anything requiring a new commit becomes CORRECTION05.

---

## 32. F14 final predicate

After C2 restoration and at candidate C4:

```sh
git diff \
  3b38d691..HEAD -- \
  evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/
```

MUST be empty.

This deliberately means the old trailing blank line is back at HEAD.

That is correct.

Historical CORRECTION02 patch hygiene remains:

```text
FAIL
```

CORRECTION04 prospective patch hygiene is measured from:

```text
9ea5bc4..HEAD
```

not from the historical range that intentionally contains the old
failure.

Required:

```text
git diff --check 9ea5bc4..HEAD = clean
```

These are different predicates.

---

## 33. Negative controls

### NC1 - F14 mutation detection

Temporarily mutate a copied representation of the restored closed blob.

Verifier must detect mismatch:

```text
F14_MUTATION_DETECTED=YES
```

Do not mutate the actual closed file after restoration.

### NC2 - baseline hash mutation

Alter one expected SHA in a temporary copy of the baseline authority.

Require:

```text
BASELINE_HASH_MUTATION_DETECTED=YES
```

### NC3 - illegal C0 supersession trailer

Run the range checker against a temporary/synthetic commit-message
fixture containing supersession trailers on C0.

Require rejection:

```text
ILLEGAL_C0_SUPERSESSION_DETECTED=YES
```

If current verifier tooling cannot test commit-message fixtures without
creating history, C1's live reproduction of CORRECTION03 may serve as
this control.

### NC4 - six-commit range

Run range-check against CORRECTION03:

```text
3b38d69..9ea5bc4
```

Require:

```text
SIX_COMMIT_RANGE_REJECTED=YES
```

---

## 34. Halt taxonomy

```text
HALT_ENTRY_DIRTY
HALT_RED_NOT_REPRODUCED
HALT_F14_RESTORATION_FAILED
HALT_BASELINE_AUTHORITY_CHANGED
HALT_PARSER_PADDING_SUBJECT_CHANGED
HALT_VALIDATOR_CONTRACT_AMBIGUOUS
HALT_FACTORY_GATE_FAILED
HALT_PATCH_HYGIENE
HALT_PHASE_CORRECTION_REQUIRED
HALT_MANDATORY_AC_NOT_GREEN
HALT_EXTERNAL_TERMINALITY_GATE
```

A HALT is a valid execution outcome.

---

## 35. Commit topology

Binding:

```text
ENTRY  9ea5bc4

C0  AUTH      (body) -> trailer ACT-Phase: RED
C1  RECON/RED (body) -> trailer ACT-Phase: EVIDENCE
C2  RESTORE   (body) -> trailer ACT-Phase: IMPL
C3  VERIFY    (body) -> trailer ACT-Phase: EVIDENCE
C4  CLOSE     (body) -> trailer ACT-Phase: CLOSE
```

Exactly five CORRECTION04 commits.

---

## 36. Required C4 candidate result

Inside committed C4 evidence:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04

COMMITTED_VERDICT=PASS_PENDING_EXTERNAL_TERMINALITY

PREDECESSOR_CORRECTION03_EFFECTIVE_VERDICT=HALT_FALSE_GREEN

CORRECTION02_CLOSED_EVIDENCE_RESTORED=YES
CORRECTION02_CLOSED_EVIDENCE_DELTA=0

PROSPECTIVE_LEXER07_BASELINE_SHA256=
00c54408bf29237cf526aeed097f6b097f22ae682683675a0bf5ab9f9c202b9a

BASELINE_PROVENANCE_HASHES_UNCHANGED=YES
PARSER_PADDING_SUBJECT_DELTA=0

PATCH_HYGIENE_PROSPECTIVE=PASS
GATE_FAST=PASS
APPEND_ONLY_FAIL=0

PRE_C4_TIP_SHA=<C3 SHA>
C4_IS_CANDIDATE_5TH_COMMIT=YES

EXTERNAL_TERMINALITY_GATE=PENDING

PARSER_PADDING_DELEGATE01=BLOCKED_PENDING_EXTERNAL_GATE
```

No claim of:

```text
POST_C4_COMMIT_COUNT=0
```

inside C4.

---

## 37. Required external terminal result

External observer emits:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04
C4_SHA=<actual C4 SHA>

ENTRY_HEAD=9ea5bc4...

ACT_COMMIT_COUNT=5
C4_DIRECT_PARENT_IS_C3=YES
FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
LOCAL_REF_STILL_EQUALS_C4_SHA=YES

EXTERNAL_TERMINALITY_GATE=PASS

EFFECTIVE_VERDICT=PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED

PARSER_PADDING_DELEGATE01=READY
```

This output must not be committed as a sixth commit.

---

## 38. Board effect

Before:

```text
PARSER-PADDING01-CORRECTION02
  = HALT_FALSE_GREEN

PARSER-PADDING01-CORRECTION03
  = HALT_FALSE_GREEN

FORWARD LEXER07 BASELINE
  = ENGINEERING_BOUND / GOVERNANCE_NOT_REQUALIFIED

PARSER-PADDING-DELEGATE01
  = BLOCKED
```

After C4 but before external observation:

```text
PARSER-PADDING01-CORRECTION04
  = PASS_PENDING_EXTERNAL_TERMINALITY

FORWARD LEXER07 BASELINE
  = GOVERNANCE_CANDIDATE

PARSER-PADDING-DELEGATE01
  = BLOCKED_PENDING_EXTERNAL_GATE
```

After external gate PASS:

```text
PARSER-PADDING01-CORRECTION04
  = PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED

FORWARD LEXER07 BASELINE
  = TRUE_GREEN_FOR_FORWARD_USE

PARSER-PADDING QUALIFICATION
  = GREEN_FOR_FORWARD_USE

PARSER-PADDING-DELEGATE01
  = READY
```

---

## 39. Next ACT

Only after the external terminality gate passes:

```text
NEXT_ACT_ID
  = ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01

NEXT_TARGET
  = CalcPadding production authority

NEXT_TRANSITION
  = LEGACY_C -> BootstrapCalcPadding

NEXT_BASELINE_AUTHORITY
  = docs/factory/LEXER07-BASELINE-AUTHORITY.tsv

NEXT_SCOPE_FROZEN
  = YES
```

That successor is **real production work**.

CORRECTION04 contains no compiler-semantic changes.

---

## 40. Doctrine locks

### Lock A - closed evidence means closed surface

F14 does not merely mean:

```text
old blob still exists somewhere in Git history
```

It means:

```text
closed evidence surface at HEAD matches the closed authoritative state
```

Corrections live in new evidence namespaces.

### Lock B - historical hygiene failure remains historical failure

Restoring the old closed blob may intentionally restore its historical
whitespace defect.

That is correct.

Do not rewrite the historical predicate.

### Lock C - C4 cannot prove that no future commit will exist

`POST_C4_COMMIT_COUNT=0` is an **external terminality property**.

It must be checked outside the C4 commit.

### Lock D - no sixth-commit fixups

If C4 is wrong, the ACT is wrong.

Open another correction.

### Lock E - engineering authority and governance authority are distinct

The LEXER07 SHA-bound baseline data is already engineering-valid.

CORRECTION04 repairs its governance qualification.

No baseline regeneration is required.

---

## 41. Final instruction to executing agent

Do not touch parser code.

Do not touch parser-padding qualification code.

Do not regenerate LEXER07.

Do not "clean" historical CORRECTION02 evidence.

Restore it exactly.

Do not put supersession trailers on C0.

Do not make C4 claim knowledge about future commits.

Close with `PASS_PENDING_EXTERNAL_TERMINALITY`.

Run the external terminality check after C4 without committing anything.

If it passes, the effective verdict becomes:

```text
PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED
```

and then, finally, return to production work:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
```
