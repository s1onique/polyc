# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02

**Title:** LEXER07 baseline-authority recovery or prospective requalification; closure-identity repair for parser-padding qualification

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** CORRECTION

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01`

**Predecessor close:** `1274f36...`

**Predecessor effective disposition:** `HALT_MANDATORY_AC_NOT_GREEN`

**Production subject:** `BootstrapCalcPadding`

**Production authority at entry:** `LEGACY_C`

**Target production mutation:** **NONE**

**Successor currently blocked:** `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01`

---

# 1. Mission

Repair the two remaining closure-authority defects in
`ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01` without modifying
the qualified parser-padding implementation or repeating already-green
qualification work.

This ACT has exactly two substantive responsibilities:

1. resolve the frozen LEXER07 AC39 baseline-authority problem;
2. establish a single canonical C3 identity for the predecessor closure.

This ACT MUST NOT modify parser-padding semantics.

The mission is complete only when one of two explicitly authorized
terminal branches is reached:

```text
BRANCH_A = HISTORICAL_BASELINE_RECOVERED
  Historical LEXER07 baseline is reproducibly reconstructed.
  Original frozen AC39 is rerun literally.
  AC39 passes literally.
  Result: PASS_TRUE_GREEN.

BRANCH_B = HISTORICAL_BASELINE_UNRECOVERABLE
  Historical baseline is mechanically proven unreconstructible.
  Original AC39 remains UNPROVABLE/FAIL_HISTORICAL.
  A new prospective LEXER07 baseline is mechanically established,
  reproducible, provenance-bound, and negative-control qualified.
  Result: PASS_FORWARD_BASELINE_REQUALIFIED.
```

Under **no circumstances** may Branch B claim:

```text
HISTORICAL_AC39=PASS
```

The historical CORRECTION01 verdict remains false-green if its literal
predicate cannot be recovered.

---

# 2. Why this ACT exists

CORRECTION01 froze:

```text
AC39:
NEW_LEXER07_FAILURES=0
DIVERGED=0
REGRESSION=0
PASS_MISMATCH=0
```

The actual C3 run later observed a different state and classified it as
`PASS_PREEXISTING_DRIFT`.

That is not satisfaction of the frozen predicate.

It changes the question from:

```text
Does the current LEXER07 result exactly conserve the frozen baseline?
```

to:

```text
Did parser-padding cause the observed differences?
```

The latter is useful evidence but is a different predicate.

Therefore:

```text
CORRECTION01_AC39_FROZEN_PREDICATE = FAIL / NOT_SATISFIED
CORRECTION01_PASS_TRUE_GREEN        = OVER_CLAIMED
```

All other repaired parser-padding properties remain outside the defect
surface of this ACT.

---

# 3. Engineering already accepted as green

The following are frozen predecessor results and MUST NOT be
reimplemented merely to obtain new evidence:

```text
BOOTSTRAP_CALC_PADDING_IMPLEMENTATION = GREEN
DIRECT_DIFFERENTIAL                  = GREEN
BOUNDED_MATRIX                       = GREEN
ALGEBRAIC_INVARIANTS                 = TRUE_GREEN
CAUSAL_MUTATIONS_M1_M4               = GREEN
4GEN_OBJECT_FIXEDPOINT               = GREEN
GENERATION_PROVENANCE_CONTROL        = TRUE_GREEN
ORACLE_AUTHORITY_CONTRACT            = SATISFIED

LEXER01_CONSERVATION                 = PASS
LEXER02_CONSERVATION                 = PASS
LEXER03_CONSERVATION                 = PASS
LEXER04_CONSERVATION                 = PASS

PRODUCTION_AUTHORITY                 = LEGACY_C
PRODUCTION_DELEGATION                = NOT_PERFORMED
```

Their evidence may be inspected for conservation and identity, but this
ACT does not reopen their semantics.

---

# 4. Binding defects

## D1 — AC39 frozen predicate was not satisfied

Frozen predicate:

```text
NEW_LEXER07_FAILURES=0
DIVERGED=0
REGRESSION=0
PASS_MISMATCH=0
PROVENANCE_SCHEMA_VALID=1
FAILURE_SCHEMA_VALID=1
```

Observed predecessor result was non-zero.

The assertion:

```text
PARSER_PADDING_INTRODUCED_LEXER07_FAILURES=0
```

does not imply the frozen predicate.

**D1 status at entry:** RED.

---

## D2 — historical LEXER07 baseline authority is unclear

The predecessor attributed the difference to absence of:

```text
build/b02-corpus-A/
```

and specifically to loss of historical S0 fallback material.

This ACT must determine mechanically whether that baseline is:

```text
RECONSTRUCTIBLE
```

or:

```text
UNRECOVERABLE
```

There is no third state such as:

```text
probably historical
likely harmless
pre-existing so PASS
```

---

## D3 — predecessor C3 identity is not single-valued

The immutable CORRECTION01 HANDOFF recorded one C3 SHA, while the
public/terminal commit topology has been reported with another.

The canonical C3 identity MUST be derived from Git topology, not prose:

```sh
git rev-parse 1274f36^
```

The parent commit of C4 is authoritative.

If this produces:

```text
9c1edc90...
```

then that is the canonical public C3 identity.

Any different C3 SHA preserved in immutable historical documentation is
classified:

```text
STALE_PRE_PUSH_OR_PRE_REWRITE_IDENTITY
```

and is not edited.

---

# 5. Non-goals

This ACT MUST NOT:

* edit `tools/bootstrap/selfhost-parser-padding.HC`;
* alter `CalcPadding`;
* alter `ParserLegacyCalcPaddingOracle`;
* change parser-padding differential semantics;
* change the 16640 matrix;
* change mutation M1..M4;
* change fixed-point logic;
* change generation-provenance logic;
* migrate production authority to PolyC;
* modify any closed predecessor evidence;
* modify any predecessor HANDOFF;
* rewrite Git history;
* lower or reinterpret historical AC39;
* "fix" LEXER07 semantic failures unless a newly discovered production
  regression is itself the reason the baseline cannot be reproduced;
* open `PARSER-PADDING-DELEGATE01`.

---

# 6. Entry requirements

Before any mutation:

```sh
git branch --show-current
git rev-parse HEAD
git status --short
git diff --check
git log --oneline --decorate -12
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN=YES
PATCH_HYGIENE_ERRORS=0
ENTRY_HEAD=<recorded SHA>
```

Also capture:

```sh
git rev-parse 1274f36^
git cat-file -t 1274f36
git show --no-patch --format='%H %P %s' 1274f36
git log --format='%H %P %s' 81afe8b..1274f36
```

Required output artifact:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c0/c0-entry-identity.txt
```

---

# 7. F14 preservation boundary

The following are immutable historical evidence:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01/
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01.md
```

At C0, hash their relevant roots/files or capture a tree identity.

At C3 and C4 require:

```text
CLOSED_PREDECESSOR_EVIDENCE_DELTA=0
CLOSED_PREDECESSOR_HANDOFF_DELTA=0
```

---

# 8. C0 AUTH

C0 creates only authorization and entry evidence.

Required new files:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02.md

evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c0/
  c0-entry-identity.txt
  c0-predecessor-disposition.txt
  c0-scope.txt
  c0-required-result.txt
  c0-f14-baseline.txt
```

No implementation work is permitted before the C0 commit.

Commit:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02 C0: AUTH
```

Required trailer:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02
ACT-Phase: C0
ACT-Verdict: OPEN
```

---

# 9. C1 RECON / RED

C1 answers one load-bearing question:

> Can the exact historical LEXER07 baseline required by CORRECTION01
> AC39 be reconstructed from committed authority?

## 9.1 Locate baseline provenance

Search all committed references:

```sh
git grep -n 'b02-corpus-A'
git log --all -S'b02-corpus-A' --oneline --
git log --all -G'b02-corpus-A' --oneline --
git grep -n 'HISTORICAL_S0'
git log --all -S'HISTORICAL_S0' --oneline --
git grep -n 'lexer07-broad-corpus-4-stage'
```

Inspect:

```text
Makefile
scripts/quality/lexer07-broad-corpus-4-stage.sh
tools/quality/lexer07-broad-corpus-4-stage.HC
historical LEXER07 evidence
historical LEXER07 HANDOFF
any committed manifest/index describing build/b02-corpus-A
```

C1 MUST identify for the historical baseline:

```text
BASELINE_PRODUCER
BASELINE_INPUTS
BASELINE_COMMAND
BASELINE_COMPILER_IDENTITY
BASELINE_EXPECTED_OUTPUT
BASELINE_FAILURE_SET
```

Each field is one of:

```text
KNOWN
UNKNOWN
NOT_REQUIRED
```

No inferred value may be promoted to KNOWN.

---

## 9.2 Reconstructibility classification

C1 produces exactly one:

```text
HISTORICAL_BASELINE_RECONSTRUCTIBLE=YES
```

or:

```text
HISTORICAL_BASELINE_RECONSTRUCTIBLE=NO
```

`YES` requires all load-bearing inputs to be available from committed
or deterministically derivable material.

`NO` requires evidence that at least one load-bearing artifact/input is
not recoverable from the Git history and documented build recipes.

Absence from the current `build/` directory alone is **not sufficient**
to prove unrecoverability.

---

## 9.3 Identity drift RED

Mechanically determine:

```sh
CANONICAL_C3_SHA="$(git rev-parse 1274f36^)"
```

Record:

```text
C4_SHA=1274f36...
CANONICAL_C3_SHA=<actual parent>
HISTORICAL_HANDOFF_C3_SHA=4d8c970...
C3_IDENTITY_MATCH=YES|NO
```

If mismatch:

```text
IDENTITY_DRIFT_REPRODUCED=YES
```

No attempt is made to edit historical evidence.

---

## 9.4 C1 required evidence

```text
c1-baseline-reference-search.txt
c1-baseline-provenance.tsv
c1-baseline-input-availability.tsv
c1-historical-failure-contract.txt
c1-reconstructibility-decision.txt
c1-c3-identity-recon.txt
c1-red-ac39.txt
c1-required-result.txt
```

C1 commit:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02 C1: RECON/RED
```

---

# 10. C1 branch decision

After C1, execution follows exactly one branch.

## Branch A — historical baseline reconstructible

Required:

```text
HISTORICAL_BASELINE_RECONSTRUCTIBLE=YES
```

Proceed to §11A.

## Branch B — historical baseline unrecoverable

Required:

```text
HISTORICAL_BASELINE_RECONSTRUCTIBLE=NO
```

Proceed to §11B.

Changing branches after C2 begins requires HALT.

---

# 11A. C2A — historical baseline reconstruction

This branch attempts to satisfy original AC39 literally.

## 11A.1 Recreate the historical baseline

Reconstruction MUST:

* use committed inputs;
* use the historically authorized producer or a byte/semantic-equivalent
  successor whose equivalence is itself demonstrated;
* begin with the output directory absent;
* write into a new correction-scoped temporary/build path;
* not depend on undocumented local files.

Recommended location:

```text
build/correction02-lexer07-baseline/
```

The exact command discovered in C1 is recorded verbatim.

---

## 11A.2 Baseline provenance

Create:

```text
c2-historical-baseline-provenance.tsv
```

with at minimum:

```text
artifact
producer_path
producer_sha256
compiler_path
compiler_sha256
input_path
input_sha256
command
command_sha256
output_path
output_sha256
output_size
```

---

## 11A.3 Determinism control

Reconstruct baseline twice from absent outputs:

```text
RUN_A
RUN_B
```

Require:

```text
BASELINE_REBUILD_A=PASS
BASELINE_REBUILD_B=PASS
BASELINE_A_B_EQUAL=YES
```

Equality MUST include the data AC39 consumes, not merely a top-level
file timestamp or directory name.

---

## 11A.4 Negative control

Mutate one baseline result in a temporary copy.

The comparison mechanism MUST reject it:

```text
BASELINE_MUTATION_DETECTED=YES
```

Restore pristine state and require:

```text
PRISTINE_BASELINE_REVERIFY=PASS
```

---

# 11B. C2B — prospective baseline authority

This branch is permitted only after C1 proves the historical baseline
unrecoverable.

It does **not** repair historical AC39.

It creates a new forward authority boundary.

## 11B.1 Historical disposition

Freeze:

```text
HISTORICAL_AC39=UNPROVABLE
HISTORICAL_CORRECTION01_PASS_TRUE_GREEN=FALSE_GREEN
```

These tokens are permanent and must appear in C3 and C4.

---

## 11B.2 Establish new prospective baseline

Run the canonical LEXER07 corpus from a clean build state twice.

Each run MUST begin with its output directory absent.

Suggested:

```sh
rm -rf build/correction02-lexer07-baseline-a
sh scripts/quality/lexer07-broad-corpus-4-stage.sh \
  build/correction02-lexer07-baseline-a

rm -rf build/correction02-lexer07-baseline-b
sh scripts/quality/lexer07-broad-corpus-4-stage.sh \
  build/correction02-lexer07-baseline-b
```

Use the repository's actual canonical invocation discovered during C1
if different.

Capture complete machine-readable result sets.

---

## 11B.3 Prospective baseline requirements

Require:

```text
PROSPECTIVE_BASELINE_RUN_A_COMPLETE=YES
PROSPECTIVE_BASELINE_RUN_B_COMPLETE=YES
PROSPECTIVE_BASELINE_DETERMINISTIC=YES

BASELINE_FAILURE_COUNT_A=<N>
BASELINE_FAILURE_COUNT_B=<N>

BASELINE_FAILURE_IDENTITY_SET_A_SHA256=<sha>
BASELINE_FAILURE_IDENTITY_SET_B_SHA256=<same sha>

BASELINE_COUNTER_SET_A_SHA256=<sha>
BASELINE_COUNTER_SET_B_SHA256=<same sha>
```

The baseline may contain known failures.

The requirement is:

```text
KNOWN_FAILURE_SET_STABLE=YES
```

not:

```text
FAILURE_COUNT=0
```

---

## 11B.4 Failure classification

Every non-pass case becomes a baseline row:

```text
fixture_id
generation
classification
observed_status
historical_relation
root_cause_class
blocking_forward_conservation
```

Allowed `root_cause_class`:

```text
TEST_INFRASTRUCTURE_DRIFT
KNOWN_LEXER07_SEMANTIC_DEFECT
UNRESOLVED
```

If any case is `UNRESOLVED` and could plausibly represent a current
compiler regression:

```text
HALT_BASELINE_NOT_QUALIFIED
```

---

## 11B.5 Forward conservation predicate

The new prospective contract is:

```text
PROSPECTIVE_LEXER07_BASELINE_SHA256=<sha>

FOR_FUTURE_ACTS:
  NEW_FAILURE_IDENTITIES=0
  REMOVED_PASS_IDENTITIES=0
  NEW_DIVERGENCES=0
  NEW_PASS_MISMATCHES=0
```

This contract does not rewrite historical AC39.

---

# 12. F-POLYC-TOOLS

No new substantive non-PolyC tooling is preferred.

If the existing LEXER07 tool already emits sufficient machine-readable
failure identities, reuse it.

If a comparator is required, substantive comparison logic MUST be
implemented in PolyC, e.g.:

```text
tools/quality/lexer07-baseline-authority-verify.HC
```

An optional shell dispatcher MUST remain:

```text
<= 50 LOC
```

and contain no substantive classification logic.

No Python.

---

# 13. C2 permitted modifications

Branch A:

```text
Makefile                                      only if a bounded target is needed
tools/quality/lexer07-baseline-authority-verify.HC   only if needed
scripts/quality/<dispatch>.sh                 <=50 LOC if needed
new CORRECTION02 evidence
```

Branch B permits the same plus a new **prospective baseline authority
artifact**, for example:

```text
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

or an existing canonical Factory baseline registry if one already
exists.

Do not invent a second authority location if the repository already has
one.

C1 recon decides the canonical location.

---

# 14. C2 forbidden modifications

Forbidden:

```text
src/parser.c
tools/bootstrap/selfhost-parser-padding.HC
tools/quality/parser-padding-algebraic-invariants.HC
tools/quality/parser-padding-generation-provenance-verify.HC
tools/quality/parser-padding-oracle-impl.c
parser-padding differential fixtures
parser-padding mutation fixtures
LEXER07 corpus semantic contents
closed evidence
closed HANDOFFs
```

Exception:

If recon proves the LEXER07 baseline generator itself contains a
mechanical reproducibility defect, HALT and open a dedicated ACT.

Do not fix that defect silently inside CORRECTION02.

---

# 15. C2 commit

Exactly one C2 implementation commit.

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02 C2: BASELINE AUTHORITY
```

No C2.x commit.

If an implementation defect is discovered after the C2 commit:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

unless the repository's current Factory v2 doctrine explicitly
authorizes another topology.

---

# 16. C3 VERIFY — common gates

Regardless of branch:

```sh
git status --short
git diff --check <ENTRY_HEAD>..HEAD
make gate-fast
bash scripts/quality/factory-append-only-test.sh
```

Require:

```text
PATCH_HYGIENE_ERRORS=0
GATE_FAST=PASS
APPEND_ONLY_FAIL=0
F14=PASS
```

Also require:

```text
PARSER_PADDING_PRODUCTION_SOURCE_DELTA=0
BOOTSTRAP_CALC_PADDING_DELTA=0
CALC_PADDING_BODY_DELTA=0
PARSER_PADDING_QUALIFICATION_TOOL_DELTA=0
```

Any unexpected delta is a HALT.

---

# 17. C3 VERIFY — Branch A

Run the current canonical LEXER07 corpus using the reconstructed
historical baseline.

The **literal original AC39 predicate** must be evaluated:

```text
NEW_LEXER07_FAILURES=0
DIVERGED=0
REGRESSION=0
PASS_MISMATCH=0
PROVENANCE_SCHEMA_VALID=1
FAILURE_SCHEMA_VALID=1
```

No aliases.

No `PASS_PREEXISTING_DRIFT`.

No "introduced by this ACT".

No narrative substitution.

Branch A terminal condition:

```text
ORIGINAL_AC39_LITERAL_PASS=YES
```

Otherwise:

```text
HALT_AC39_STILL_RED
```

---

# 18. C3 VERIFY — Branch B

Branch B MUST preserve:

```text
HISTORICAL_AC39=UNPROVABLE
```

Then verify prospective baseline authority.

Run a third clean corpus:

```text
RUN_C
```

Compare against frozen prospective baseline.

Require:

```text
PROSPECTIVE_BASELINE_MATCH=YES
NEW_FAILURE_IDENTITIES=0
REMOVED_PASS_IDENTITIES=0
NEW_DIVERGENCES=0
NEW_PASS_MISMATCHES=0
```

Also execute a negative control:

1. clone the prospective baseline;
2. mutate one fixture classification/counter;
3. verifier must reject;
4. restore pristine;
5. verifier must pass.

Required:

```text
BASELINE_VERIFIER_NEGATIVE_CONTROL=PASS
PRISTINE_REVERIFY=PASS
```

---

# 19. Closure-identity verification

At C3 capture:

```sh
git show --no-patch --format='%H %P %s' 1274f36
git rev-parse 1274f36^
```

Produce:

```text
PREDECESSOR_C4_SHA=1274f36...
PREDECESSOR_CANONICAL_C3_SHA=<parent>
HISTORICAL_HANDOFF_C3_SHA=4d8c970...
IDENTITY_DRIFT_PRESENT=YES|NO
```

If mismatch:

```text
CANONICAL_C3_IDENTITY_SOURCE=GIT_PARENT_EDGE
HISTORICAL_C3_IDENTITY_DISPOSITION=STALE_IMMUTABLE_RECORD
```

The new CORRECTION02 HANDOFF must use only the canonical Git parent
identity.

---

# 20. C3 evidence

Required:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c3/
  c3-entry-identity.txt
  c3-branch.txt
  c3-baseline-provenance.tsv
  c3-baseline-determinism.txt
  c3-baseline-verifier-negative-control.txt
  c3-lexer07-current-run.txt
  c3-ac39-literal-evaluation.txt
  c3-c3-identity-resolution.txt
  c3-f14.txt
  c3-patch-hygiene.txt
  c3-factory-gates.txt
  c3-required-result.txt
  mandatory-ac-status.tsv
```

Branch B additionally requires:

```text
  c3-historical-ac39-disposition.txt
  c3-prospective-baseline.tsv
  c3-prospective-baseline-reverify.txt
```

---

# 21. No unnecessary conservation replay

This ACT does not rerun AC18/AC29/parser-padding differential merely for
ceremony.

Instead mechanically prove the relevant subjects did not change:

```text
BOOTSTRAP_CALC_PADDING_SHA_ENTRY=<sha>
BOOTSTRAP_CALC_PADDING_SHA_C3=<same>

ALGEBRAIC_VERIFIER_SHA_ENTRY=<sha>
ALGEBRAIC_VERIFIER_SHA_C3=<same>

PROVENANCE_VERIFIER_SHA_ENTRY=<sha>
PROVENANCE_VERIFIER_SHA_C3=<same>

ORACLE_IMPL_SHA_ENTRY=<sha>
ORACLE_IMPL_SHA_C3=<same>
```

If any differ unexpectedly:

```text
HALT_SCOPE_VIOLATION
```

---

# 22. Acceptance criteria

## Identity and entry

```text
AC01  BRANCH=main
AC02  WORKTREE_CLEAN_AT_C0=YES
AC03  C0_AUTH_BEFORE_WORK=YES
AC04  ENTRY_HEAD_RECORDED=YES
AC05  PREDECESSOR_C4_SHA_VERIFIED=YES
```

## F14 / scope

```text
AC06  CLOSED_PREDECESSOR_EVIDENCE_DELTA=0
AC07  CLOSED_PREDECESSOR_HANDOFF_DELTA=0
AC08  BOOTSTRAP_CALC_PADDING_DELTA=0
AC09  CALC_PADDING_BODY_DELTA=0
AC10  PARSER_PADDING_PRODUCTION_AUTHORITY=LEGACY_C
AC11  PARSER_PADDING_PRODUCTION_DELEGATION=NOT_PERFORMED
```

## Baseline recon

```text
AC12  HISTORICAL_BASELINE_REFERENCES_INVENTORIED=YES
AC13  HISTORICAL_BASELINE_INPUTS_CLASSIFIED=YES
AC14  RECONSTRUCTIBILITY_DECISION_SINGLE_VALUED=YES
AC15  C1_BRANCH_FROZEN=YES
```

## Identity repair

```text
AC16  CANONICAL_C3_SHA_FROM_C4_PARENT=YES
AC17  C3_IDENTITY_DRIFT_DISPOSITION_RECORDED=YES
AC18  NO_HISTORICAL_ARTIFACT_EDIT_FOR_IDENTITY=YES
```

## Branch A

For Branch A only:

```text
AC19A HISTORICAL_BASELINE_RECONSTRUCTED=YES
AC20A BASELINE_A_B_EQUAL=YES
AC21A BASELINE_MUTATION_DETECTED=YES
AC22A PRISTINE_BASELINE_REVERIFY=PASS
AC23A ORIGINAL_AC39_LITERAL_PASS=YES
AC24A NEW_LEXER07_FAILURES=0
AC25A DIVERGED=0
AC26A REGRESSION=0
AC27A PASS_MISMATCH=0
```

## Branch B

For Branch B only:

```text
AC19B HISTORICAL_BASELINE_RECONSTRUCTIBLE=NO
AC20B HISTORICAL_AC39=UNPROVABLE
AC21B HISTORICAL_FALSE_GREEN_PRESERVED=YES
AC22B PROSPECTIVE_BASELINE_RUN_A_COMPLETE=YES
AC23B PROSPECTIVE_BASELINE_RUN_B_COMPLETE=YES
AC24B PROSPECTIVE_BASELINE_DETERMINISTIC=YES
AC25B KNOWN_FAILURE_SET_STABLE=YES
AC26B UNRESOLVED_POSSIBLE_COMPILER_REGRESSIONS=0
AC27B PROSPECTIVE_BASELINE_SHA256_RECORDED=YES
AC28B BASELINE_VERIFIER_NEGATIVE_CONTROL=PASS
AC29B PROSPECTIVE_BASELINE_REVERIFY=PASS
```

## Tool discipline

```text
AC30  NEW_PYTHON_SOURCES=0
AC31  NEW_PYTHON_INVOCATIONS=0
AC32  NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
AC33  NEW_SHELL_DISPATCH_MAX_LOC<=50
```

If no new tool is needed, AC32/AC33 pass trivially with zero additions.

## Factory gates

```text
AC34  PATCH_HYGIENE_ERRORS=0
AC35  GATE_FAST=PASS
AC36  APPEND_ONLY_FAIL=0
AC37  F14=PASS
```

## Lifecycle

```text
AC38  EXACT_COMMIT_COUNT_AT_CLOSE=5
AC39  WORKTREE_CLEAN_AT_CLOSE=YES
AC40  POST_C4_COMMIT_COUNT=0
```

`AC38..AC40` are C4-observable and MUST NOT be prematurely promoted at
C3.

---

# 23. Required result — Branch A

Branch A may close:

```text
VERDICT=PASS_TRUE_GREEN
```

only when:

```text
HISTORICAL_BASELINE_RECONSTRUCTIBLE=YES
ORIGINAL_AC39_LITERAL_PASS=YES

NEW_LEXER07_FAILURES=0
DIVERGED=0
REGRESSION=0
PASS_MISMATCH=0

CANONICAL_C3_IDENTITY_RESOLVED=YES

PARSER_PADDING_ENGINEERING_REOPENED=NO
PRODUCTION_DELEGATION=NOT_PERFORMED

FACTORY_GATES=PASS
PATCH_HYGIENE_ERRORS=0
WORKTREE_CLEAN_AT_CLOSE=YES
EXACT_COMMIT_COUNT_AT_CLOSE=5
POST_C4_COMMIT_COUNT=0
```

Effect:

```text
PARSER_PADDING_QUALIFICATION=TRUE_GREEN
PARSER_PADDING_DELEGATE01=UNBLOCKED
```

---

# 24. Required result — Branch B

Branch B may close:

```text
VERDICT=PASS_FORWARD_BASELINE_REQUALIFIED
```

only when:

```text
HISTORICAL_BASELINE_RECONSTRUCTIBLE=NO
HISTORICAL_AC39=UNPROVABLE
HISTORICAL_CORRECTION01=FALSE_GREEN

PROSPECTIVE_LEXER07_BASELINE_QUALIFIED=YES
PROSPECTIVE_BASELINE_DETERMINISTIC=YES
UNRESOLVED_POSSIBLE_COMPILER_REGRESSIONS=0
BASELINE_VERIFIER_NEGATIVE_CONTROL=PASS

CANONICAL_C3_IDENTITY_RESOLVED=YES

FACTORY_GATES=PASS
PATCH_HYGIENE_ERRORS=0
WORKTREE_CLEAN_AT_CLOSE=YES
EXACT_COMMIT_COUNT_AT_CLOSE=5
POST_C4_COMMIT_COUNT=0
```

Effect:

```text
HISTORICAL_CORRECTION01_TRUE_GREEN=NO
FORWARD_LEXER07_CONSERVATION_AUTHORITY=TRUE_GREEN
PARSER_PADDING_ENGINEERING_QUALIFICATION=GREEN
PARSER_PADDING_DELEGATE01=UNBLOCKED_FOR_FORWARD_USE
```

This is **not** a retroactive PASS for historical AC39.

---

# 25. Halt taxonomy

Immediate HALT conditions:

```text
HALT_SCOPE_VIOLATION
  Parser-padding production or qualified proof substrate changed.

HALT_BASELINE_RECON_AMBIGUOUS
  C1 cannot classify historical baseline reconstructibility.

HALT_HISTORICAL_BASELINE_NONDETERMINISTIC
  Branch A reconstruction differs across clean rebuilds.

HALT_AC39_STILL_RED
  Branch A reconstructs baseline but literal AC39 remains non-zero.

HALT_BASELINE_NOT_QUALIFIED
  Branch B contains unresolved failures that may represent a current
  compiler regression.

HALT_BASELINE_VERIFIER_NOT_LOAD_BEARING
  Negative-control mutation is accepted.

HALT_IDENTITY_AMBIGUOUS
  C4 parent does not provide a single canonical C3 commit.

HALT_F14_VIOLATION
  Closed evidence/HANDOFF changed.

HALT_F_POLYC_TOOLS
  New substantive shell/C/Python authority introduced outside policy.

HALT_PATCH_HYGIENE
  git diff --check reports an error.

HALT_PHASE_CORRECTION_REQUIRED
  Extra implementation is discovered after its authorized phase.
```

A HALT is a successful execution outcome when its predicate is true.

---

# 26. Negative controls

At least these controls are mandatory.

## NC1 — baseline mutation

Mutate one baseline fixture result.

Require verifier rejection.

```text
BASELINE_MUTATION_DETECTED=YES
```

## NC2 — failure-set omission

Delete one known failing fixture from a temporary baseline.

Require rejection:

```text
BASELINE_OMISSION_DETECTED=YES
```

## NC3 — fake identity repair

Substitute the stale C3 SHA as canonical expected C3.

Verifier/reconciliation logic must reject because it is not the parent
edge of C4:

```text
STALE_C3_IDENTITY_REJECTED=YES
```

## NC4 — pristine recheck

After all negative controls:

```text
PRISTINE_REVERIFY=PASS
```

---

# 27. C3 phase purity

C3 is evidence only.

Permitted:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c3/**
```

No production/tool changes in C3.

If a tool defect is discovered during C3:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

Do not patch and continue.

---

# 28. C3 mandatory ledger

`mandatory-ac-status.tsv` MUST contain:

```text
ac_id
predicate
status
evidence
observed_value
```

Allowed statuses:

```text
PASS
FAIL
N/A
DEFERRED_TO_C4
```

No:

```text
PASS_PREEXISTING_DRIFT
PASS_BY_DESIGN
PASS_EQUIVALENT
PASS_INTENT
```

For branch-specific ACs, the inactive branch rows are `N/A`.

C3 may have:

```text
AC38 DEFERRED_TO_C4
AC39 DEFERRED_TO_C4
AC40 DEFERRED_TO_C4
```

C4 must resolve them from actual C4 state.

---

# 29. C4 preconditions

Before creating the HANDOFF:

```text
ALL_NON_TEMPORAL_MANDATORY_ACS_GREEN=YES

ACTIVE_BRANCH=A|B
BRANCH_REQUIRED_RESULT=PASS

PATCH_HYGIENE_ERRORS=0
F14=PASS
GATE_FAST=PASS
APPEND_ONLY_FAIL=0

WORKTREE_CONTAINS_ONLY_AUTHORIZED_C4_ARTIFACTS=YES
```

If not:

```text
HALT_MANDATORY_AC_NOT_GREEN
```

---

# 30. C4 CLOSE

C4 creates:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02.md
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c4/c4-entry-identity.txt
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c4/c4-required-result.txt
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02/c4/mandatory-ac-status-final.tsv
```

and the canonical manifest/ROADMAP append if required by current
Factory doctrine.

Do not mutate older HANDOFFs to point at this ACT.

---

# 31. C4 temporal proof

At C4 verify:

```sh
git rev-list --count <ENTRY_HEAD>..HEAD
```

Before C4 commit it must be:

```text
4
```

After C4 exists, the ACT range must contain exactly:

```text
5
```

commits:

```text
C0
C1
C2
C3
C4
```

The HANDOFF does not claim its own SHA.

After C4:

```text
POST_C4_COMMIT_COUNT=0
```

No cleanup commit.

No whitespace-fix commit.

No terminal-ledger fixup commit.

---

# 32. Commit topology

Binding expected topology:

```text
<ENTRY_HEAD>

C0  AUTH
C1  RECON/RED
C2  BASELINE AUTHORITY
C3  VERIFY
C4  CLOSE
```

Exactly five commits.

---

# 33. HANDOFF required sections

The C4 HANDOFF MUST contain:

```text
VERDICT
IDENTITY
PREDECESSOR DISPOSITION
ACTIVE BRANCH
BASELINE AUTHORITY
AC39
C3 IDENTITY RECONCILIATION
NEGATIVE CONTROLS
FACTORY GATES
SCOPE
F14
RESIDUE
NEXT ACT
```

---

# 34. HANDOFF truth requirements — Branch A

It must say explicitly:

```text
HISTORICAL_BASELINE_RECOVERED=YES
ORIGINAL_AC39_LITERAL_PASS=YES

CORRECTION01_AC39_REPAIRED=YES
CORRECTION01_EFFECTIVE_QUALIFICATION=TRUE_GREEN
```

Only Branch A may say that.

---

# 35. HANDOFF truth requirements — Branch B

It must say explicitly:

```text
HISTORICAL_BASELINE_RECOVERED=NO
HISTORICAL_AC39=UNPROVABLE
CORRECTION01_PASS_TRUE_GREEN=FALSE_GREEN

PROSPECTIVE_BASELINE_AUTHORITY=TRUE_GREEN
PARSER_PADDING_FORWARD_QUALIFICATION=GREEN
```

It MUST NOT contain:

```text
AC39 historical PASS
CORRECTION01 retroactively PASS_TRUE_GREEN
historical predicate repaired
```

---

# 36. Successor authorization

`ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01` remains blocked until
CORRECTION02 reaches C4.

It is unblocked under either:

```text
Branch A:
  ORIGINAL_AC39_LITERAL_PASS=YES
```

or:

```text
Branch B:
  PROSPECTIVE_LEXER07_BASELINE_QUALIFIED=YES
  UNRESOLVED_POSSIBLE_COMPILER_REGRESSIONS=0
```

The successor MUST bind to the baseline authority established by this
ACT.

It MUST NOT use the stale CORRECTION01 AC39 interpretation.

---

# 37. Next production ACT contract

Once unblocked:

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
NEXT_TARGET=CalcPadding production authority
NEXT_OPERATION=LEGACY_C -> BootstrapCalcPadding delegation
NEXT_BASELINE_AUTHORITY=<CORRECTION02 qualified baseline>
NEXT_SCOPE_FROZEN=YES
```

That ACT is where production code changes resume.

Not here.

---

# 38. Required final ledger

The C4 required-result artifact must be single-valued.

Branch A:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02
BRANCH=HISTORICAL_BASELINE_RECOVERED
VERDICT=PASS_TRUE_GREEN

HISTORICAL_BASELINE_RECONSTRUCTIBLE=YES
ORIGINAL_AC39_LITERAL_PASS=YES

NEW_LEXER07_FAILURES=0
DIVERGED=0
REGRESSION=0
PASS_MISMATCH=0

C3_IDENTITY_CANONICAL=YES
F14=PASS
PATCH_HYGIENE_ERRORS=0
GATE_FAST=PASS
APPEND_ONLY_FAIL=0
EXACT_COMMIT_COUNT_AT_CLOSE=5
WORKTREE_CLEAN_AT_CLOSE=YES
POST_C4_COMMIT_COUNT=0

PARSER_PADDING_DELEGATE01=UNBLOCKED
```

Branch B:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02
BRANCH=PROSPECTIVE_BASELINE_REQUALIFIED
VERDICT=PASS_FORWARD_BASELINE_REQUALIFIED

HISTORICAL_BASELINE_RECONSTRUCTIBLE=NO
HISTORICAL_AC39=UNPROVABLE
HISTORICAL_CORRECTION01=FALSE_GREEN

PROSPECTIVE_LEXER07_BASELINE_QUALIFIED=YES
KNOWN_FAILURE_SET_STABLE=YES
UNRESOLVED_POSSIBLE_COMPILER_REGRESSIONS=0

C3_IDENTITY_CANONICAL=YES
F14=PASS
PATCH_HYGIENE_ERRORS=0
GATE_FAST=PASS
APPEND_ONLY_FAIL=0
EXACT_COMMIT_COUNT_AT_CLOSE=5
WORKTREE_CLEAN_AT_CLOSE=YES
POST_C4_COMMIT_COUNT=0

PARSER_PADDING_DELEGATE01=UNBLOCKED_FOR_FORWARD_USE
```

---

# 39. Doctrine locks

This ACT establishes the following locks.

### Lock 1 — exact frozen predicates are literal

A frozen acceptance predicate cannot be replaced after execution by a
different, arguably more reasonable predicate.

```text
NEW_FAILURES_VS_BASELINE=0
```

is not equivalent to:

```text
NEW_FAILURES_CAUSED_BY_THIS_ACT=0
```

---

### Lock 2 — historical unprovability is an acceptable result

If a historical baseline is genuinely unrecoverable, Factory does not
manufacture a historical PASS.

It records:

```text
UNPROVABLE
```

and establishes a new prospective authority boundary.

---

### Lock 3 — build/ is not authority

An untracked/generated `build/` directory disappearing is not itself a
valid explanation for changing an acceptance predicate.

Its reconstruction path must be derived from committed authority.

---

### Lock 4 — Git topology owns commit identity

When prose and Git disagree about a phase SHA:

```text
C4 parent edge
```

is authoritative for C3 identity.

Historical prose is preserved but classified stale.

---

### Lock 5 — qualification and migration remain separate

This ACT qualifies the evidence boundary.

It does not migrate production.

`PARSER-PADDING-DELEGATE01` is a distinct ACT.

---

# 40. Expected outcome

Preferred outcome:

```text
Branch A
```

if the historical baseline can actually be reconstructed.

But Branch B is a fully legitimate terminal result if the historical
baseline authority was never made reproducible.

The unacceptable result is:

```text
PASS_TRUE_GREEN
```

obtained by silently replacing AC39 again.

---

# 41. Board effect at close

Before:

```text
PARSER-PADDING01                    FALSE_GREEN historically
PARSER-PADDING01-CORRECTION01       HALT_MANDATORY_AC_NOT_GREEN
PARSER-PADDING-DELEGATE01           BLOCKED
```

After successful Branch A:

```text
PARSER-PADDING01-CORRECTION02       PASS_TRUE_GREEN
PARSER-PADDING QUALIFICATION        TRUE_GREEN
PARSER-PADDING-DELEGATE01           READY
```

After successful Branch B:

```text
PARSER-PADDING01-CORRECTION01       remains historical FALSE_GREEN
PARSER-PADDING01-CORRECTION02       PASS_FORWARD_BASELINE_REQUALIFIED
FORWARD LEXER07 BASELINE            TRUE_GREEN
PARSER-PADDING QUALIFICATION        GREEN FOR FORWARD USE
PARSER-PADDING-DELEGATE01           READY
```

After any HALT:

```text
PARSER-PADDING-DELEGATE01           BLOCKED
```

---

# 42. Final instruction to executing agent

Do not repair prose.

Do not rerun already-qualified parser-padding proofs merely to create
more evidence.

Do not touch parser production semantics.

Find the historical LEXER07 baseline authority.

Either reconstruct it and satisfy AC39 literally, or prove that it
cannot be reconstructed and create an explicitly new prospective
baseline.

Then close truthfully.

Only after that do we return to production work.
