# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Close the closure-oracle lineage prospectively by freezing a clean patch-hygiene baseline, registering this ACT before verification, proving the self-row is load-bearing, and performing a HANDOFF-only C4 transition

**Repository:** PolyC
**Branch:** `main`

**Class:** FACTORY / GOVERNANCE / CLOSURE-AUTHORITY / FINAL REQUALIFICATION

---

# 0. Entry identity

Binding predecessor:

```text
ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04
HEAD = 0e6c36e2a34867f5a2454fdafa0f6d4c6699c2ed

VERDICT =
PASS_FALSE_GREEN_HALTTED_AT_HANDBOFF_LEVEL

HALT_CLASS = GOVERNANCE
BLOCKS_NEXT = YES
```

CORRECTION04 is an honest terminal HALT.

It established:

```text
CORRECTION03_RECLASSIFICATION       = GREEN
CORRECTION03_P0_1_REPRODUCED       = GREEN
CORRECTION03_P0_2_REPRODUCED       = GREEN

CORRECTION04_ENTRY_CLEAN            = GREEN
CORRECTION04_RANGE_HYGIENE          = GREEN
CORRECTION04_MANIFEST_MUTATION_AUTH = GREEN
CORRECTION04_F14_CONSERVATION       = GREEN
CORRECTION04_12_CASE_REGRESSION     = GREEN

CORRECTION04_PASS_TRUE_GREEN        = NO
```

This ACT is the prospective requalification.

It SHALL NOT attempt to make any historical FALSE_GREEN ACT retroactively green.

---

# 1. Mission

The closure-oracle implementation is now technically sound:

```text
MANIFEST_SINGLE_ENUMERATION_AUTHORITY = YES
HARDCODED_PAIR_UNIVERSE               = REMOVED

POLYC_TEST_AUTHORITY                  = YES
SHELL_DISPATCH_ONLY                   = YES

DUPLICATE_CLASSIFICATION              = NON_SHORT_CIRCUITING
HANDOFF_OWNS_VERDICT                  = YES

12_CASE_REGRESSION                    = PASS
```

The remaining governance problem is lifecycle proof.

CORRECTION04 registered itself only during C4, simultaneously with creation of its HANDOFF.

Therefore it proved:

```text
C3:
    no self row
    oracle 12/12 PASS

C4:
    self row + HANDOFF appear atomically
    oracle 13/13 PASS
```

but did NOT prove the stronger closure invariant:

```text
C3:
    self row already exists
    HANDOFF absent
    self pair FAIL

C4:
    checker unchanged
    manifest unchanged
    ACT unchanged
    HANDOFF appears
    self pair PASS
```

This ACT SHALL prove exactly that invariant.

It SHALL also establish a clean prospective patch-hygiene contract using the immutable entry commit of this ACT.

---

# 2. Binding conceptual invariant

This ACT defines the Factory closure lifecycle as:

```text
ACT BODY
    = prospective authorization contract

MANIFEST ROW
    = declaration that the ACT/HANDOFF pair is managed

CHECKER
    = frozen judge

C3
    = evidence against frozen judge and frozen registration

HANDOFF
    = terminal truth-bearing closure artifact
```

For a closure-managed ACT:

```text
SELF_ROW MUST EXIST BEFORE C3.
```

At C3:

```text
ACT exists
manifest row exists
HANDOFF absent
```

Therefore:

```text
SELF_PAIR = FAIL
```

At C4:

```text
HANDOFF appears
```

and nothing else relevant changes.

Therefore:

```text
SELF_PAIR = PASS
```

The required monotonic transition is:

```text
C3:
    N managed rows
    N-1 PASS
    1 FAIL

C4:
    same N managed rows
    N PASS
    0 FAIL
```

---

# 3. Historical truth is immutable

The following remain historical facts and SHALL NOT be rewritten:

```text
CLOSURE-ORACLE-EXTENSIBLE01
    historical close = FALSE_GREEN

CORRECTION01
    historical close = FALSE_GREEN

CORRECTION02
    historical close = FALSE_GREEN

CORRECTION03
    historical close = FALSE_GREEN

CORRECTION04
    terminal result =
    PASS_FALSE_GREEN_HALTTED_AT_HANDBOFF_LEVEL
```

In particular, this ACT SHALL NOT attempt to make:

```text
git diff --check 0665ada..HEAD
```

green.

That historical predicate was falsified.

It remains evidence of CORRECTION03's defect.

---

# 4. F14 immutable surfaces

This ACT SHALL NOT modify any file under:

```text
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01/
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02/
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03/
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04/
```

Nor any closed HANDOFF or ACT body in those lineages.

Specifically forbidden:

```text
docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01*.md
except this new CORRECTION05 ACT

docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01*.md
except this new CORRECTION05 HANDOFF
```

Historical EOF whitespace remains historical.

No more evidence surgery.

---

# 5. C0 AUTH — authorize first

C0 SHALL be the first commit in this ACT.

Before creating any other CORRECTION05 artifact:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
```

Required:

```text
BRANCH=main

ENTRY_HEAD=
0e6c36e2a34867f5a2454fdafa0f6d4c6699c2ed

WORKTREE_CLEAN_AT_ENTRY=YES
```

If HEAD has legitimately advanced:

```text
ENTRY_HEAD=<actual-clean-head>
0e6c36e_IS_ANCESTOR=YES
```

and bind that actual HEAD before work.

C0 may create only:

```text
docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md

evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/c0/
    c0-entry-identity.txt
```

C0 SHALL NOT modify the manifest.

C0 SHALL NOT create a HANDOFF.

---

# 6. Prospective patch-hygiene baseline

Define:

```text
PATCH_HYGIENE_BASELINE = ENTRY_HEAD
```

For the expected entry:

```text
PATCH_HYGIENE_BASELINE =
0e6c36e2a34867f5a2454fdafa0f6d4c6699c2ed
```

This baseline is prospective.

The terminal predicate is:

```sh
git diff --check "$PATCH_HYGIENE_BASELINE"..HEAD
```

Required at C1, C2, C3 and C4:

```text
PATCH_HYGIENE_ERRORS=0
```

Git's `--check` reports whitespace errors introduced by the selected diff and returns nonzero if such errors exist.

This ACT SHALL NOT substitute another baseline after C0.

Required:

```text
PATCH_HYGIENE_BASELINE_FROZEN=YES
```

---

# 7. C1 RED — current self-registration absence

At C1, this ACT's body exists but it has not yet been registered.

Required observations:

```text
CORRECTION05_ACT_EXISTS=YES
CORRECTION05_MANIFEST_ROW=NO
CORRECTION05_HANDOFF_EXISTS=NO
```

Run the canonical closure oracle.

Expected current universe:

```text
MANIFEST_ROWS=13
PAIR_OK=13
PAIR_FAIL=0
STATUS=PASS
```

If the live count differs because an authorized pair was added between entry and C1, bind the observed baseline instead of blindly asserting `13`.

Freeze:

```text
PRE_SELF_REGISTER_MANIFEST_ROWS=<N>
PRE_SELF_REGISTER_PAIR_OK=<N>
PRE_SELF_REGISTER_PAIR_FAIL=0
```

Required:

```text
SELF_REGISTRATION_RED=CONFIRMED
```

---

# 8. C1 — verify closure machinery conservation

Run:

```text
bash scripts/quality/factory-closure-status-check.sh
sh scripts/quality/factory-closure-status-check-test.sh
```

Required:

```text
FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0

CURRENT_ORACLE_STATUS=PASS
```

Also mechanically prove:

```text
factory-closure-status-test.HC exists
shell dispatch wrapper <=50 LOC
no substantive shell test engine exists
```

Required:

```text
POLYC_TEST_AUTHORITY=PASS
F_POLYC_TOOLS_CONSERVATION=PASS
```

No implementation changes are authorized.

---

# 9. C1 — freeze self-registration lifecycle

C1 SHALL explicitly authorize:

```text
docs/factory/act-handoff-map.tsv
```

for exactly one mutation:

```text
append CORRECTION05 ACT/HANDOFF pair
```

The mutation SHALL occur in C2, before C3.

Required row:

```text
docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md
docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md
```

tab-separated in canonical manifest form.

No other manifest mutation is authorized.

---

# 10. Authorized mutation scope

Only these repository paths may change during this ACT:

```text
docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md

docs/factory/act-handoff-map.tsv

docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md

evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/**
```

Optionally:

```text
docs/ROADMAP.md
```

ONLY if the repository currently requires a roadmap closure signal.

If used, it must be authorized in C0.

Default:

```text
ROADMAP_MUTATION=NOT_AUTHORIZED
```

No checker mutation.

No test implementation mutation.

No Makefile mutation.

No SHELL-BUDGET mutation.

No old evidence mutation.

---

# 11. Explicitly forbidden paths

Forbidden:

```text
scripts/quality/factory-closure-status-check.sh
scripts/quality/factory-closure-status-check-test.sh
scripts/quality/factory-closure-status-test-cases.tsv
tools/quality/factory-closure-status-test.HC
Makefile
docs/factory/SHELL-BUDGET.tsv
```

Forbidden production trees:

```text
src/**
tools/bootstrap/**
```

If the existing closure machinery fails and requires modification:

```text
HALT_ORACLE_IMPLEMENTATION_DEFECT
```

Do not enlarge scope.

---

# 12. C2 — self-register before verification

C2 SHALL append exactly one row to:

```text
docs/factory/act-handoff-map.tsv
```

for CORRECTION05.

Do NOT create the HANDOFF.

Immediately run the canonical checker.

Expected:

```text
MANIFEST_ROWS=<N+1>

PAIR_OK=<N>
PAIR_FAIL=1

SELF_PAIR=FAIL
STATUS=FAIL
```

The failing pair must be exactly:

```text
ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05
```

with cause:

```text
HANDOFF missing
```

Required:

```text
SELF_ROW_LOAD_BEARING=YES
SELF_HANDOFF_ABSENT=YES
SELF_PAIR_FAILS=YES
ONLY_SELF_PAIR_FAILS=YES
```

This is the central RED witness.

---

# 13. C2 — freeze judge, registration and contract

After self-registration, calculate SHA-256 for:

```text
scripts/quality/factory-closure-status-check.sh

docs/factory/act-handoff-map.tsv

docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md

tools/quality/factory-closure-status-test.HC

scripts/quality/factory-closure-status-check-test.sh

scripts/quality/factory-closure-status-test-cases.tsv
```

Create:

```text
c2-freeze.tsv
```

Schema:

```text
role
path
sha256
```

Required:

```text
CHECKER_FROZEN=YES
MANIFEST_FROZEN=YES
ACT_BODY_FROZEN=YES
TEST_IMPLEMENTATION_FROZEN=YES
```

These bytes SHALL NOT change through C4.

---

# 14. C2 terminal hygiene

Before committing C2:

```sh
git diff --check "$PATCH_HYGIENE_BASELINE"..HEAD
```

Required:

```text
PATCH_HYGIENE_C2=PASS
```

Also:

```text
WORKTREE_BOUND_TO_C2_SCOPE=YES
```

No unrelated dirt.

---

# 15. C3 VERIFY — committed boundary

C3 SHALL be a real commit.

Before producing C3 evidence, verify HEAD is the committed C2 SHA and worktree is clean:

```text
C3_ENTRY_HEAD=<C2_COMMIT_SHA>
C3_ENTRY_WORKTREE_CLEAN=YES
```

No C2 implementation may exist only as worktree dirt.

---

# 16. C3 — freeze verification

Recompute all C2 hashes.

Required:

```text
CHECKER_C3_SHA256   = CHECKER_C2_SHA256
MANIFEST_C3_SHA256  = MANIFEST_C2_SHA256
ACT_C3_SHA256       = ACT_C2_SHA256

POLYC_TEST_C3_SHA256 = POLYC_TEST_C2_SHA256
SHELL_WRAPPER_C3_SHA256 = SHELL_WRAPPER_C2_SHA256
CASES_TSV_C3_SHA256 = CASES_TSV_C2_SHA256
```

Required:

```text
C2_TO_C3_FROZEN=YES
```

---

# 17. C3 — self-pair failure

Run canonical checker.

Required:

```text
MANIFEST_ROWS=<N+1>
PAIR_OK=<N>
PAIR_FAIL=1
STATUS=FAIL
```

The only failing pair:

```text
CORRECTION05
```

The failure cause:

```text
HANDOFF missing
```

Required:

```text
C3_SELF_ROW_PRESENT=YES
C3_SELF_HANDOFF_PRESENT=NO
C3_SELF_PAIR_FAIL=YES
C3_UNRELATED_PAIR_FAIL=0
```

---

# 18. C3 — PolyC regression

Run:

```text
sh scripts/quality/factory-closure-status-check-test.sh
```

Required:

```text
FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0
```

No shell/PolyC implementation changes are permitted to make the tests pass.

---

# 19. C3 — predecessor oracle conservation

All prior manifest rows must remain valid.

Required:

```text
PREEXISTING_MANIFEST_ROWS=<N>
PREEXISTING_PAIR_OK=<N>
PREEXISTING_PAIR_FAIL=0
```

This includes CORRECTION04.

The fact that some historical HANDOFFs have later additive reclassifications does not cause this ACT to rewrite them.

The oracle is testing structural managed-pair validity, not historical epistemic truth.

---

# 20. C3 — F14 conservation

Required:

```text
git diff "$PATCH_HYGIENE_BASELINE"..HEAD -- \
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01 \
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02 \
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03 \
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04
```

must be empty.

Required:

```text
CLOSED_EVIDENCE_DELTA=0
```

Also:

```text
CLOSED_HANDOFF_DELTA=0
CLOSED_ACT_BODY_DELTA=0
```

---

# 21. C3 — prospective patch hygiene

Run exactly:

```sh
git diff --check "$PATCH_HYGIENE_BASELINE"..HEAD
```

Required:

```text
PATCH_HYGIENE_C3=PASS
PATCH_HYGIENE_ERRORS=0
```

No alternate baseline.

No exception.

No historical range substitution.

---

# 22. C3 — required-result ledger

Produce:

```text
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/c3/c3-required-result.txt
```

At minimum:

```text
ACT=ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05

ENTRY_HEAD=<entry>
PATCH_HYGIENE_BASELINE=<same entry>

SELF_REGISTRATION_RED=CONFIRMED

SELF_ROW_REGISTERED_BEFORE_C3=YES
SELF_HANDOFF_ABSENT_AT_C3=YES

CHECKER_FROZEN=YES
MANIFEST_FROZEN=YES
ACT_BODY_FROZEN=YES
TEST_IMPLEMENTATION_FROZEN=YES

C2_TO_C3_FROZEN=YES

MANIFEST_ROWS=<N+1>
PAIR_OK=<N>
PAIR_FAIL=1
SELF_PAIR_FAIL=YES
UNRELATED_PAIR_FAIL=0

FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
CLOSED_ACT_BODY_DELTA=0

PATCH_HYGIENE_C3=PASS

VERDICT_PRE_CLOSE=EXPECTED_SELF_HANDOFF_MISSING
```

C3 SHALL NOT claim PASS_TRUE_GREEN.

---

# 23. C3 commit requirements

C3 commit contains only:

```text
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/c3/**
```

No manifest change.

No ACT-body change.

No checker change.

No test implementation change.

No HANDOFF.

After committing C3:

```text
C3_COMMIT_SHA=<sha>
```

and:

```text
git status --short
```

must be empty.

---

# 24. C4 authorization

C4 may create exactly one truth-bearing artifact:

```text
docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md
```

Optionally a C4 identity artifact may be created under this ACT's own evidence namespace ONLY if it can be committed in the same C4 transition without violating:

```text
C3_TO_C4_TRUTH_BEARING_DELTA = HANDOFF_ONLY
```

Preferred:

```text
C4 commit changes exactly one file.
```

No manifest mutation.

No ACT-body mutation.

No checker mutation.

No evidence rewrite.

---

# 25. C4 pre-commit freeze verification

Before adding HANDOFF, record:

```text
CHECKER_PRE_C4_SHA256
MANIFEST_PRE_C4_SHA256
ACT_PRE_C4_SHA256
```

They must equal C2/C3 values.

Required:

```text
PRE_C4_FROZEN=YES
```

Then create HANDOFF.

---

# 26. HANDOFF verdict authority

The HANDOFF SHALL contain:

```text
VERDICT

PASS_TRUE_GREEN
```

only if every mandatory criterion in this ACT has already been mechanically established or will be established by the HANDOFF-only self-transition.

The ACT body itself SHALL NOT gain:

```text
## Status
PASS_TRUE_GREEN
```

or any other post-hoc verdict field.

Required:

```text
ACT_BODY_TERMINAL_MUTATION=0
HANDOFF_OWNS_TERMINAL_VERDICT=YES
```

---

# 27. C4 self-judgment transition

With HANDOFF present and before C4 commit, run the unchanged checker.

Required:

```text
MANIFEST_ROWS=<N+1>
PAIR_OK=<N+1>
PAIR_FAIL=0
STATUS=PASS
VERDICT=PASS
```

Required transition:

```text
C3:
    <N>/1 FAIL

C4:
    <N+1>/0 PASS
```

The only relevant change must be:

```text
HANDOFF_ABSENT -> HANDOFF_PRESENT
```

Required:

```text
SELF_PAIR_LOAD_BEARING=YES
HANDOFF_ONLY_FLIPS_SELF_PAIR=YES
```

---

# 28. C3→C4 diff proof

After C4 commit:

```sh
git diff --name-status <C3_COMMIT>..HEAD
```

Required preferred output:

```text
A docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md
```

Exactly one path.

Required:

```text
C3_TO_C4_CHANGED_FILE_COUNT=1
C3_TO_C4_HANDOFF_ONLY=YES
```

No manifest row in this diff; it was already committed in C2.

---

# 29. C4 freeze proof

Recompute:

```text
CHECKER_C4_SHA256
MANIFEST_C4_SHA256
ACT_C4_SHA256
POLYC_TEST_C4_SHA256
SHELL_WRAPPER_C4_SHA256
CASES_TSV_C4_SHA256
```

All must equal C2.

Required:

```text
CLOSURE_JUDGE_FROZEN_THROUGH_C4=YES
```

---

# 30. C4 patch hygiene

Run exactly:

```sh
git diff --check "$PATCH_HYGIENE_BASELINE"..HEAD
```

Required:

```text
PATCH_HYGIENE_C4=PASS
PATCH_HYGIENE_ERRORS=0
```

No post-C4 cleanup commit is authorized.

If this fails:

```text
HALT_PATCH_HYGIENE
```

The C4 commit remains a HALT boundary.

Do not fix afterward without a new ACT/amendment.

---

# 31. Post-C4 gates

After committing C4:

```text
factory-closure-status-check:
    PAIR_FAIL=0
    STATUS=PASS

factory-closure-status-test:
    12/12 PASS

factory-append-only-test:
    PASS

gate-fast:
    PASS
```

Required:

```text
POST_C4_GATES=PASS
```

---

# 32. Final expected row counts

At CORRECTION04 close:

```text
MANIFEST_ROWS=13
PAIR_OK=13
```

CORRECTION05 adds exactly one row.

Expected:

```text
C2/C3:
    MANIFEST_ROWS=14
    PAIR_OK=13
    PAIR_FAIL=1

C4:
    MANIFEST_ROWS=14
    PAIR_OK=14
    PAIR_FAIL=0
```

These counts are acceptance expectations, not implementation constants.

If live entry count differs legitimately:

```text
BASE_MANIFEST_ROWS=<observed N>
C3=N/1
C4=N+1/0
```

and document why.

---

# 33. No checker change

This ACT explicitly does NOT require a checker change to "ratify" the self-row pattern.

The manifest-driven checker already defines:

```text
MANIFEST ROW = MANAGED PAIR
```

The missing governance proof was lifecycle ordering.

This ACT ratifies the pattern mechanically by proving:

```text
self row before C3
+
HANDOFF absent
=
FAIL

same frozen row
+
HANDOFF present
=
PASS
```

Required:

```text
SELF_REGISTRATION_PATTERN_PROVEN=YES
```

No checker feature is necessary.

---

# 34. No historical whitespace waiver

This ACT does not ratify historical whitespace as generally acceptable.

It states only:

```text
HISTORICAL_0665ada_PREDICATE = FALSE
```

and:

```text
CORRECTION05_PROSPECTIVE_RANGE = CLEAN
```

Historical files remain byte-faithful under F14.

Future ACTs must select their own prospective clean baseline at C0.

No `.gitattributes` whitespace exception is authorized here.

---

# 35. F-NO-PYTHON

Required:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_VIOLATIONS=0
```

---

# 36. F-POLYC-TOOLS

This ACT creates no new tools.

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_SHELL_TOOLS=0
POLYC_TEST_AUTHORITY_UNCHANGED=YES
```

The existing 16-LOC shell dispatch remains untouched.

---

# 37. Append-only invariant

Required throughout:

```text
NO_AMEND=YES
NO_REBASE=YES
NO_FORCE_PUSH=YES
NO_RESET_RECOMMIT=YES
```

Run:

```text
factory-append-only-test
```

Required:

```text
APPEND_ONLY_HISTORY=PASS
```

---

# 38. Mandatory acceptance criteria

## AC01 — C0 clean entry

```text
WORKTREE_CLEAN_AT_C0=YES
```

Mandatory.

## AC02 — correct predecessor identity

```text
ENTRY_HEAD=<frozen C0 parent>
```

Mandatory.

## AC03 — prospective baseline frozen

```text
PATCH_HYGIENE_BASELINE=ENTRY_HEAD
```

Mandatory.

## AC04 — predecessor HALT acknowledged

```text
CORRECTION04_PASS_TRUE_GREEN=NO
CORRECTION04_BLOCKS_NEXT=YES
```

Mandatory.

## AC05 — no historical artifact mutation

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
CLOSED_ACT_BODY_DELTA=0
```

Mandatory.

## AC06 — current oracle regression

```text
FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0
```

Mandatory.

## AC07 — PolyC tooling conservation

```text
POLYC_TEST_AUTHORITY=PASS
```

Mandatory.

## AC08 — manifest mutation explicitly authorized

```text
SELF_ROW_MANIFEST_MUTATION_AUTHORIZED=YES
```

Mandatory.

## AC09 — self row committed before C3

```text
SELF_ROW_REGISTERED_BEFORE_C3=YES
```

Mandatory.

## AC10 — no HANDOFF before C4

```text
SELF_HANDOFF_EXISTS_AT_C2=NO
SELF_HANDOFF_EXISTS_AT_C3=NO
```

Mandatory.

## AC11 — self pair fails at C2

```text
C2_SELF_PAIR_FAIL=YES
```

Mandatory.

## AC12 — self pair fails at C3

```text
C3_SELF_PAIR_FAIL=YES
```

Mandatory.

## AC13 — only self pair fails

```text
C3_UNRELATED_PAIR_FAIL=0
```

Mandatory.

## AC14 — checker frozen

```text
CHECKER_C2=C3=C4
```

Mandatory.

## AC15 — manifest frozen

```text
MANIFEST_C2=C3=C4
```

Mandatory.

## AC16 — ACT body frozen

```text
ACT_BODY_C2=C3=C4
```

Mandatory.

## AC17 — test implementation frozen

```text
POLYC_TEST_C2=C3=C4
SHELL_WRAPPER_C2=C3=C4
CASES_TSV_C2=C3=C4
```

Mandatory.

## AC18 — real C3 commit

```text
C3_COMMIT_EXISTS=YES
```

Mandatory.

## AC19 — C3 enters from clean committed C2

```text
C3_ENTRY_HEAD=C2_COMMIT
C3_ENTRY_WORKTREE_CLEAN=YES
```

Mandatory.

## AC20 — C3 12-case regression

```text
12/12 PASS
```

Mandatory.

## AC21 — C3 patch hygiene

```text
git diff --check ENTRY_HEAD..C3 = clean
```

Mandatory.

## AC22 — C4 adds HANDOFF only

```text
C3_TO_C4_CHANGED_FILE_COUNT=1
C3_TO_C4_HANDOFF_ONLY=YES
```

Mandatory.

## AC23 — C4 self pair passes

```text
C4_SELF_PAIR_PASS=YES
```

Mandatory.

## AC24 — final oracle green

```text
PAIR_FAIL=0
STATUS=PASS
```

Mandatory.

## AC25 — HANDOFF owns verdict

```text
ACT_BODY_TERMINAL_MUTATION=0
HANDOFF_OWNS_TERMINAL_VERDICT=YES
```

Mandatory.

## AC26 — C4 patch hygiene

```text
git diff --check ENTRY_HEAD..HEAD = clean
```

Mandatory.

## AC27 — no post-C4 cleanup

```text
POST_C4_COMMITS=0
```

Mandatory.

## AC28 — F-NO-PYTHON

```text
NEW_PYTHON=0
```

Mandatory.

## AC29 — F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

Mandatory.

## AC30 — append-only

```text
APPEND_ONLY_HISTORY=PASS
```

Mandatory.

## AC31 — worktree clean

```text
WORKTREE_CLEAN_AT_CLOSE=YES
```

Mandatory.

## AC32 — Factory gates

```text
gate-fast=PASS
factory-closure-status-test=PASS
factory-append-only-test=PASS
```

Mandatory.

---

# 39. Mandatory AC table

Create:

```text
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/c3/
mandatory-ac-status.tsv
```

Schema:

```text
ac_id
description
mandatory
status
evidence_path
```

Exactly:

```text
AC01..AC32
```

Required at successful close:

```text
MANDATORY_TOTAL=32
MANDATORY_PASS=32
MANDATORY_FAIL=0
MANDATORY_UNKNOWN=0
MANDATORY_MISSING_EVIDENCE=0
```

No `PARTIAL`.

No `DEFERRED`.

---

# 40. Evidence namespace

Use only:

```text
evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/
```

Suggested:

```text
c0/
  c0-entry-identity.txt

c1/
  c1-self-registration-red.txt
  c1-current-oracle-regression.txt
  c1-scope-freeze.txt
  c1-patch-hygiene-baseline.txt

c2/
  c2-entry-identity.txt
  c2-self-row-red.txt
  c2-freeze.tsv
  c2-patch-hygiene.txt

c3/
  c3-entry-identity.txt
  c3-freeze-verification.txt
  c3-self-row-load-bearing.txt
  c3-12case-regression.txt
  c3-predecessor-conservation.txt
  c3-f14-conservation.txt
  c3-patch-hygiene.txt
  mandatory-ac-status.tsv
  c3-required-result.txt

c4/
  c4-entry-identity.txt
  c4-freeze-verification.txt
  c4-self-pair-flip.txt
  c4-c3-to-c4-diff.txt
  c4-patch-hygiene.txt
  c4-post-gates.txt
  c4-required-result.txt
```

No C4 evidence file is required if creating one would violate HANDOFF-only closure.

The HANDOFF itself records C4.

---

# 41. C3 required-result exact shape

Required:

```text
ACT=ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05

ENTRY_HEAD=<sha>
PATCH_HYGIENE_BASELINE=<same sha>

CORRECTION04_TERMINAL_HALT=ACKNOWLEDGED

SELF_ROW_MANIFEST_MUTATION_AUTHORIZED=YES
SELF_ROW_REGISTERED_BEFORE_C3=YES

SELF_HANDOFF_EXISTS_AT_C3=NO

CHECKER_FROZEN=YES
MANIFEST_FROZEN=YES
ACT_BODY_FROZEN=YES
TEST_IMPLEMENTATION_FROZEN=YES

C3_ENTRY_HEAD=C2_COMMIT
C3_ENTRY_WORKTREE_CLEAN=YES

MANIFEST_ROWS=14
PAIR_OK=13
PAIR_FAIL=1

SELF_PAIR_FAIL=YES
UNRELATED_PAIR_FAIL=0

FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
CLOSED_ACT_BODY_DELTA=0

PATCH_HYGIENE_C3=PASS

VERDICT_PRE_CLOSE=EXPECTED_SELF_HANDOFF_MISSING
```

If base row count is not 13, substitute mechanically bound `N`.

---

# 42. C4 required-result exact shape

After HANDOFF creation:

```text
CHECKER_FROZEN_THROUGH_C4=YES
MANIFEST_FROZEN_THROUGH_C4=YES
ACT_BODY_FROZEN_THROUGH_C4=YES
TEST_IMPLEMENTATION_FROZEN_THROUGH_C4=YES

C3_TO_C4_CHANGED_FILE_COUNT=1
C3_TO_C4_HANDOFF_ONLY=YES

MANIFEST_ROWS=14
PAIR_OK=14
PAIR_FAIL=0
STATUS=PASS

SELF_PAIR_PASS=YES
HANDOFF_ONLY_FLIPS_SELF_PAIR=YES

PATCH_HYGIENE_C4=PASS

FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0

gate-fast=PASS
factory-append-only-test=PASS

WORKTREE_CLEAN=TRUE
POST_C4_COMMITS=0

VERDICT=PASS_TRUE_GREEN
```

---

# 43. Phase topology

## C0 AUTH

Only:

```text
ACT body
c0 entry evidence
```

No manifest.

## C1 RED / CONTRACT

Only evidence.

Freeze:

```text
baseline
scope
expected row counts
current oracle state
```

## C2 SELF-REGISTER / FREEZE

Add:

```text
manifest self row
```

No HANDOFF.

Freeze all authority hashes.

Oracle must become RED on the missing HANDOFF.

## C3 VERIFY

Real commit.

Evidence only.

Oracle remains RED solely because HANDOFF is absent.

## C4 CLOSE

Create exactly:

```text
HANDOFF
```

Nothing else.

Oracle flips green.

Terminal commit.

---

# 44. Commit topology

Maximum:

```text
5 commits
```

Exactly expected:

```text
C0 AUTH
C1 RED/CONTRACT
C2 SELF-REGISTER/FREEZE
C3 VERIFY
C4 CLOSE
```

No combined phase commits.

No C2.5.

No C4 fix.

No fill commit.

No post-C4 hygiene commit.

If one is required:

```text
HALT_PHASE_TOPOLOGY_BROKEN
```

---

# 45. HALT taxonomy

```text
HALT_ENTRY_DIRTY
HALT_ENTRY_IDENTITY_DRIFT
HALT_PREDECESSOR_STATE_DRIFT
HALT_CURRENT_ORACLE_REGRESSION
HALT_CURRENT_POLYC_TEST_REGRESSION
HALT_MANIFEST_MUTATION_UNAUTHORIZED
HALT_SELF_ROW_NOT_LOAD_BEARING
HALT_UNRELATED_PAIR_FAILURE
HALT_ORACLE_IMPLEMENTATION_DEFECT
HALT_CHECKER_CHANGED_AFTER_FREEZE
HALT_MANIFEST_CHANGED_AFTER_FREEZE
HALT_ACT_BODY_CHANGED_AFTER_FREEZE
HALT_TEST_IMPLEMENTATION_CHANGED_AFTER_FREEZE
HALT_C3_NOT_COMMITTED_BOUNDARY
HALT_C3_DIRTY_ENTRY
HALT_F14_VIOLATION
HALT_PATCH_HYGIENE
HALT_C4_NOT_HANDOFF_ONLY
HALT_HANDOFF_DOES_NOT_FLIP_SELF_PAIR
HALT_F_NO_PYTHON_REGRESSION
HALT_F_POLYC_TOOLS_REGRESSION
HALT_APPEND_ONLY_VIOLATION
HALT_PHASE_TOPOLOGY_BROKEN
```

Every HALT records:

```text
HALT_CLASS
BLOCKS_NEXT
OBSERVED
EXPECTED
EVIDENCE
RECOMMENDED_NEXT
```

---

# 46. Terminal predicate

`PASS_TRUE_GREEN` is permitted only if:

```text
C0_CLEAN=YES
C0_AUTH_BEFORE_WORK=YES

PATCH_HYGIENE_BASELINE=ENTRY_HEAD

NO_HISTORICAL_ARTIFACT_MUTATION=YES

SELF_ROW_AUTHORIZED=YES
SELF_ROW_COMMITTED_BEFORE_C3=YES

C2_SELF_PAIR_FAIL=YES
C3_SELF_PAIR_FAIL=YES
C3_UNRELATED_PAIR_FAIL=0

CHECKER_FROZEN_C2_TO_C4=YES
MANIFEST_FROZEN_C2_TO_C4=YES
ACT_BODY_FROZEN_C2_TO_C4=YES
TEST_IMPLEMENTATION_FROZEN_C2_TO_C4=YES

REAL_C3_COMMIT=YES
C3_ENTRY_CLEAN=YES

12_CASE_REGRESSION=PASS

C3_TO_C4_HANDOFF_ONLY=YES

C4_SELF_PAIR_PASS=YES
FINAL_PAIR_FAIL=0
FINAL_STATUS=PASS

PATCH_HYGIENE=PASS

F14=PASS
F_NO_PYTHON=PASS
F_POLYC_TOOLS=PASS
APPEND_ONLY=PASS

MANDATORY_PASS=32
MANDATORY_FAIL=0

WORKTREE_CLEAN=TRUE
POST_C4_COMMITS=0

VERDICT=PASS_TRUE_GREEN
```

Anything weaker is a HALT.

---

# 47. Meaning of successful close

TRUE_GREEN authorizes exactly:

```text
The Factory closure oracle lineage is prospectively qualified.

The checker and manifest were frozen before C3.

The closing ACT was already registered as a managed pair before C3.

At C3, the pair failed solely because the HANDOFF did not exist.

At C4, the only relevant repository change was creation of the HANDOFF.

The unchanged checker over the unchanged manifest then accepted the pair.

The prospective ACT range is patch-clean.

No historical evidence or historical FALSE_GREEN claim was rewritten.

Future managed closure ACTs may follow this lifecycle:
  authorize
  register before verification
  freeze
  verify missing-HANDOFF RED
  close by adding HANDOFF only.
```

It does NOT authorize:

```text
CORRECTION01 was really green
CORRECTION02 was really green
CORRECTION03 was really green
```

Those historical reclassifications remain.

---

# 48. Board effect

On `PASS_TRUE_GREEN`:

```text
FACTORY_CLOSURE_ORACLE_LINEAGE = TRUE_GREEN_FOR_FORWARD_USE
```

Then unblock:

```text
ACT-POLYC-LIBTOS-SYMBOL-GAPS01
```

After that:

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
```

Then:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

No other Factory correction should intervene unless CORRECTION05 itself falsifies one of its mandatory predicates.

---

# 49. Execution instruction

Start at C0 only if:

```text
HEAD = 0e6c36e...
worktree clean
```

Then:

```text
C1:
    prove current 13-pair oracle and 12-case regression are green

C2:
    append CORRECTION05 self-row
    DO NOT create HANDOFF
    prove oracle becomes 13/1 FAIL
    freeze checker + manifest + ACT + tests

C3:
    fresh committed evidence
    prove same 13/1 FAIL
    prove only self pair is red
    prove prospective range hygiene clean

C4:
    add HANDOFF only
    prove 14/0 PASS
    prove C3..C4 exactly one file
    stop
```

No checker changes.

No manifest change in C4.

No historical cleanup.

No post-C4 fix.
