# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair the systemic Factory-v2 commit metadata validation defect so a conforming `HALT_*` CLOSE commit is accepted by both Factory-v2 validators, and an invalid ACT commit can never be silently accepted as `NON_ACT`

**Repository:** PolyC
**Branch:** `main`

**Class:** FACTORY / QUALITY-TOOLING / SYSTEMIC-REPAIR
**Priority:** P0

**Execution:** C0 -> C1 -> C2 -> C3 -> C4
**Verdict target:** `PASS_TRUE_GREEN`

---

## 1. Mission

Repair the systemic Factory-v2 commit metadata validation defect that has
caused otherwise legitimate PolyC work to enter repeated closure-correction
cycles.

This ACT must achieve four outcomes:

1. A valid `HALT_*` CLOSE commit carrying `HALT_CLASS` and `BLOCKS_NEXT`
   is accepted by both Factory-v2 validators.
2. An invalid ACT commit can never be silently accepted as an ordinary
   `NON_ACT` commit.
3. Existing closed ACTs retain their historical identity, evidence and
   verdicts. No historical commit is rewritten or retroactively promoted.
4. The PolyC roadmap can proceed to
   `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02`, subject to that ACT's own
   engineering gates.

**This is one bounded infrastructure repair, not another parser-padding
correction.**

---

## 2. Verified root cause

The current Factory-v2 grammar contains:

```text
ACT: ACT-POLYC-...
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
ACT-Verdict: PASS|PASS_*|HALT_*

HALT_CLASS: GOVERNANCE|PRODUCTION|SAFETY|AUTHORIZATION|DEPENDENCY
BLOCKS_NEXT: YES|NO
```

`docs/factory/GIT-METADATA.md` section 2.5 already acknowledges that Git's
standard trailer parser does not accept underscores in keys.

However:

- `scripts/quality/factory-v2-commit-msg-check.sh` relies on
  `git interpret-trailers --parse`.
- `scripts/quality/factory-v2-range-check.sh` relies on Git's
  `%(trailers)` formatter.
- `scripts/quality/factory-halt-classification-check.sh` separately
  recognizes the underscore-bearing keys.

Consequently, different validators interpret the same commit differently.

The observed failure class is:

```text
VALID_FACTORY_HALT_COMMIT=YES
GIT_STANDARD_TRAILER_PARSE=EMPTY_OR_INCOMPLETE
FACTORY_V2_RANGE_CHECK=FAIL
FACTORY_V2_COMMIT_MSG_CHECK=MAY_REPORT_NON_ACT
```

The current commit-message checker contains the fail-open rule:

```sh
if no ACT trailer is present in parsed output:
    MODE=NON_ACT
    STATUS=PASS
```

That rule is unsafe when parsing can discard an actual ACT trailer block.

The correction must fix the underlying parsing contract, not invent a
passing verdict for affected historical ACTs.

### 2.1 Measured mechanism (git 2.54.0)

Git's trailer parser rejects a trailer block **in its entirety** when any
key in that block contains an underscore. Because `HALT_CLASS` and
`BLOCKS_NEXT` are mandatory on every conforming `HALT_*` CLOSE, the
*whole* footer is dropped -- including `ACT:`, `ACT-Phase:` and
`ACT-Verdict:`. Measured at C0 (see `c0/historical-failures.txt`):

```text
printf 's\n\nb\n\nACT: A\nACT-Phase: CLOSE\nACT-Verdict: HALT_X\n' \
  | git interpret-trailers --parse
  -> ACT: A / ACT-Phase: CLOSE / ACT-Verdict: HALT_X   (parses)

printf 's\n\nb\n\nACT: A\nACT-Phase: CLOSE\nHALT_CLASS: G\n' \
  | git interpret-trailers --parse
  -> (empty; the whole block is dropped)
```

---

## 3. Binding decisions

### D1 -- Preserve the existing Factory grammar

The canonical Factory keys remain:

```text
HALT_CLASS
BLOCKS_NEXT
```

Do not silently rename them in historical commits.

Do not require changing all existing ACT documents or commit messages.

### D2 -- Shared interpretation

The commit-message validator, range validator, and HALT classifier must
agree on the same canonical trailer field values.

The preferred bounded implementation is a compatibility normalization
layer that translates only the two known underscore-bearing trailer keys
into Git-compatible temporary keys for parsing, then maps them back to
their canonical names.

The normalization must preserve:

- Raw commit bytes (no commit mutation)
- Field values
- Field ordering
- Duplicate detection
- Required cardinalities
- Valid trailer-block boundaries

Do not write a new general-purpose Git parser.

### D3 -- Fail closed

If the raw commit-message footer contains apparent ACT metadata that
cannot be parsed faithfully, the validator must return FAIL.

A real ordinary non-ACT commit must continue passing.

A stray literal `ACT:` in ordinary message prose is not sufficient to
classify a commit as an ACT.

### D4 -- Preserve historical failures

A newly passing parser does not retroactively make an invalid historical
commit topology valid.

A historical post-CLOSE continuation remains a violation.

A historical `HALT_GATE_PUSH_NOT_GREEN` remains a HALT.

### D5 -- Do not block self-hosting on unrelated baseline failures

The existing LLVM GEP01 cap-verifier failure is independently owned.

Its status remains FAIL until its own owner repairs it.

This ACT must not disable GEP01, change the full push gate, or declare the
full push gate green.

A clean parser-slice reconnaissance ACT may proceed under the existing
Factory mechanical-blocking rules without claiming unrelated gate
qualification.

---

## 4. Entry recon

Performed at C0; frozen in
`evidence/ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01/c0/`.

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -12 --format='%H %s'
git config --get core.hooksPath
```

The actual entry HEAD is frozen in `c0/entry-identity.txt`. The earlier
observed `baf3e16` is a historical reference, not an unconditional entry
requirement.

### 4.1 Dirty-worktree special case

The previous digest identified one untracked file:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01/c3/factory-v2-range-check.txt
```

If it remains untracked, preserve its exact bytes and SHA-256 under this
ACT's C0 evidence tree, then relocate the original untracked file out of
the closed predecessor directory.

This narrow relocation is explicitly authorized. Do not delete
information, edit tracked predecessor evidence, or run a broad
`git clean`.

If any other working-tree modification exists, classify it before
proceeding. Do not overwrite unrelated work.

---

## 5. Scope

### IN SCOPE

```text
scripts/quality/factory-v2-commit-msg-check.sh
scripts/quality/factory-v2-range-check.sh
scripts/quality/factory-v2-test.sh
scripts/quality/factory-halt-classification-check.sh
docs/factory/GIT-METADATA.md
```

Also authorized:

- A bounded shared trailer-compatibility helper, only if necessary.
- The Makefile test registration, only if necessary.
- New ACT, evidence, HANDOFF and manifest artifacts.
- An explicit forward-only restoration of an already-mutated closed
  HANDOFF, under section 12.

### OUT OF SCOPE

```text
src/**
tools/bootstrap/**
Makefile compiler/bootstrap targets
src/CMakeLists.txt
.github/workflows/release.yml

scripts/quality/gate-push.sh
.githooks/pre-push

LEXER and PARSER production semantics
LLVM GEP01 implementation
```

No production compiler mutation.

No Python.

No large new shell implementation. Existing shell validator maintenance is
permitted; substantial new logic must respect F-POLYC-TOOLS.

No history rewrite, amend, reset/recommit, rebase, Git replacement
objects, or force-push.

---

## 6. C0 -- AUTH

Commit the ACT authorization before implementation.

Capture:

```text
c0/
  entry-identity.txt
  scope.txt
  doctrine-snapshot.txt
  validator-source-identities.tsv
  historical-failures.txt
  predecessor-untracked-observation.txt  (if applicable)
```

Freeze the following baseline predicates:

```text
VALID_HALT_RANGE_ACCEPTED=NO
INVALID_ACT_CAN_BE_NON_ACT=YES
HISTORICAL_POST_CLOSE_VIOLATION=PRESERVED
PRODUCTION_COMPILER_DELTA=0
```

The first two must be demonstrated by C1, not assumed.

Use the live Factory-v2 trailer syntax:

```text
ACT: ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01
ACT-Phase: RED
```

Do not attach `ACT-Verdict` or supersession trailers before CLOSE.

---

## 7. C1 -- RED / CONTRACT

Reproduce the validator bugs against the actual C0 tree.

Use disposable synthetic Git repositories and commit-message files. Do not
alter the authoritative repository's history.

### RED-1 -- valid HALT rejected

Create a synthetic ACT lifecycle:

```text
RED
EVIDENCE
CLOSE
```

The CLOSE must contain:

```text
ACT: ACT-POLYC-FACTORY-V2-TEST01
ACT-Phase: CLOSE
ACT-Verdict: HALT_MANDATORY_AC_NOT_GREEN
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

Run both validators.

Capture exactly how Git parses the message and how Factory interprets it.

Required:

```text
RED_HALT_TRAILER_PARSE_DEFECT_REPRODUCED=YES
```

### RED-2 -- unparseable ACT accepted as NON_ACT

Construct a commit-message fixture with a syntactically complete Factory
HALT footer.

Show whether the current commit-message validator returns:

```text
MODE=NON_ACT
STATUS=PASS
```

If the live implementation already rejects the fixture, record that
observation honestly and adapt the repair scope.

### RED-3 -- malformed split trailer blocks

Test a message where `ACT`, `ACT-Phase`, and `ACT-Verdict` are separated
by extra blank lines.

Required new behavior: reject as malformed.

Do not count a partial trailer block as a valid ACT.

### RED-4 -- historical post-CLOSE continuation

Verify that Factory still rejects a historical same-ACT continuation after
CLOSE.

Test both:

```text
CLOSE -> same-ACT IMPL
```

and:

```text
CLOSE -> ordinary commit -> same-ACT IMPL
```

The latter must not escape detection merely because the immediate child
has no ACT metadata.

### C1 contract freeze

Choose the smallest implementation that fixes the observed defects.

Freeze expected parser output, cardinality rules, and negative-control
behavior before C2.

Do not broaden this ACT into a rewrite of Factory governance.

Commit C1 evidence.

---

## 8. C2 -- IMPLEMENTATION

### Work package A -- canonical trailer extraction

Implement one bounded compatibility mechanism for parsing Factory trailer
metadata.

It may normalize:

```text
HALT_CLASS:  -> HALT-CLASS:
BLOCKS_NEXT: -> BLOCKS-NEXT:
```

for the purpose of Git parsing only, then expose the canonical field
names to the validators.

The raw Git commit message remains unchanged.

Do not normalize arbitrary unknown keys.

Malformed lookalikes must be rejected, not silently corrected.

The parser must preserve exact cardinality:

```text
ACT_COUNT
ACT_PHASE_COUNT
ACT_VERDICT_COUNT
HALT_CLASS_COUNT
BLOCKS_NEXT_COUNT
```

### Work package B -- commit-message validation

Remove the fail-open behavior.

A `NON_ACT` result is valid only when the complete message has been
classified as a genuine non-ACT message.

An ACT-like footer with a parsing failure must return nonzero.

Preserve existing checks for:

- ACT identifier grammar
- Phase grammar
- Verdict grammar
- Supersession-only-on-CLOSE
- Corrected-verdict dependency
- HALT classification combinations

### Work package C -- range validation

Make `factory-v2-range-check.sh` consume the same normalized
interpretation as the commit-message checker.

Do not continue using a separate, incompatible parsing path for CLOSE.

Preserve:

```text
FIRST = first commit of contiguous ACT run
ENTRY = FIRST^
CLOSE = terminal ACT CLOSE
```

Validate every commit in the range.

Reject a same-ACT continuation after CLOSE, including cases with
intervening ordinary commits on a relevant descendant path.

Do not infer historical validity from a new correction ACT.

### Work package D -- classifier consistency

Verify that `factory-halt-classification-check.sh` agrees with the other
two validators for:

```text
HALT + GOVERNANCE + NO
HALT + PRODUCTION + YES
HALT + DEPENDENCY + YES
HALT + DEPENDENCY + NO
PASS + no HALT fields
```

If the existing classifier already behaves correctly, preserve it.

No redundant second parser should be introduced.

---

## 9. Regression matrix

Extend the canonical Factory-v2 tests with these mandatory cases.

| Test | Expected |
|---|---|
| T35 Valid `HALT_CLASS=GOVERNANCE`, `BLOCKS_NEXT=NO` | PASS |
| T36 Valid `HALT_CLASS=PRODUCTION`, `BLOCKS_NEXT=YES` | PASS |
| T37 HALT without `HALT_CLASS` | REJECT |
| T38 HALT without `BLOCKS_NEXT` | REJECT |
| T39 Duplicate `HALT_CLASS` | REJECT |
| T40 Duplicate `BLOCKS_NEXT` | REJECT |
| T41 Invalid classification enum | REJECT |
| T42 `GOVERNANCE` with `BLOCKS_NEXT=YES` | REJECT |
| T43 PASS CLOSE containing HALT-only fields | REJECT |
| T44 ACT footer parsing failure classified `NON_ACT` | REJECT |
| T45 Ordinary non-ACT commit | PASS |
| T46 Literal `ACT:` in ordinary prose | PASS as NON_ACT |
| T47 Split ACT trailer block | REJECT |
| T48 Valid HALT lifecycle range | PASS |
| T49 HALT CLOSE followed by same-ACT continuation | REJECT |
| T50 HALT CLOSE, ordinary commit, same-ACT continuation | REJECT |
| T51 Historical invalid topology remains invalid | REJECT |
| T52 Existing valid PASS lifecycle | PASS |

Test identities T35-T52 are provisional names; align them with the live
suite without overwriting existing tests.

Each negative test must verify the correct nonzero return code and failure
classification, not simply the presence of the string `FAIL`.

An intentionally malformed fixture must not pass because of a different
setup error.

No existing test may be removed or weakened.

---

## 10. C3 -- VERIFY

Run the complete original Factory-v2 suite and the new regression cases.

Required evidence:

```text
c3/
  trailer-parser-positive.txt
  trailer-parser-negative.txt
  commit-msg-fail-open-control.txt
  range-check-halt-control.txt
  post-close-continuation-control.txt
  existing-factory-v2-regression.txt
  halt-classification-consistency.txt
  append-only-conservation.txt
  production-conservation.txt
  f14-conservation.txt
  patch-hygiene.txt
  mandatory-ac-status.tsv
  required-result.txt
```

Run:

```sh
bash scripts/quality/factory-v2-test.sh
bash scripts/quality/factory-append-only-test.sh
make gate-fast
```

Run the live commit-message and range validators on the synthetic
fixtures.

Check both return codes and output fields.

### Mandatory acceptance criteria

```text
AC01 C0 authorization precedes implementation
AC02 Actual entry identity captured
AC03 Root cause reproduced
AC04 Valid HALT trailers accepted
AC05 Invalid HALT trailers rejected
AC06 ACT-like parse failure never returns NON_ACT
AC07 Genuine non-ACT commits remain valid
AC08 Duplicate mandatory fields rejected
AC09 Incorrect HALT combinations rejected
AC10 PASS with HALT-only fields rejected
AC11 Existing PASS ACTs remain valid
AC12 Valid HALT lifecycle range accepted
AC13 Same-ACT post-CLOSE continuation rejected
AC14 Intervening ordinary commit does not hide continuation
AC15 Historical invalid topology stays invalid
AC16 All existing Factory-v2 regression cases pass
AC17 All new regression cases pass
AC18 HALT classifier and Factory-v2 validators agree
AC19 No production compiler files modified
AC20 No historical commit rewritten
AC21 Closed predecessor evidence preserved
AC22 F14 HANDOFF preservation/restoration demonstrated
AC23 No new Python or substantive non-PolyC shell tool
AC24 Patch hygiene clean
AC25 Factory append-only 11/11 PASS
AC26 gate-fast PASS
AC27 Closure verdict matches measured evidence
AC28 No post-CLOSE mutation of this ACT
```

AC28 is externally evaluated after C4, not pre-marked PASS at C3.

---

## 11. Historical bootstrap disposition

Do not repair the old `BOOTSTRAP-BUILD01` commit sequence.

The following historical observations remain authoritative:

```text
BOOTSTRAP_COLD_BUILD=ENGINEERING_GREEN
PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC
BOOTSTRAP_DEPENDENCY_GRAPH=ACYCLIC

BOOTSTRAP_FULL_GATE_PUSH=FAIL
GEP01_PREEXISTING_FAILURE=UNRESOLVED

BOOTSTRAP_HISTORICAL_POST_CLOSE_DEFECT=PRESERVED
```

The known parser-padding engineering result may be used as input to new
work, but no previous `HALT_*` is retroactively promoted.

The Factory parser fix must make historical HALT messages readable while
still rejecting genuinely invalid historical topologies.

---

## 12. F14 restoration, if needed

The latest digests indicate that `BOOTSTRAP-BUILD01-CORRECTION01` modified
the predecessor's closed HANDOFF.

If that mutation remains in the current tree:

1. Identify the original C4 blob of the closed HANDOFF.
2. Capture the current modified version into new additive evidence under
   this ACT.
3. Restore the predecessor HANDOFF to its original C4 bytes using a new
   forward-only commit.
4. Verify byte equality against the canonical C4 blob.
5. Do not modify the predecessor's closed evidence tree.

This restoration is authorized specifically because it re-establishes the
closed historical artifact's original bytes.

It does not rewrite historical commits or make the historical closure
valid.

Do not append a new correction notice to the restored HANDOFF.

---

## 13. C4 -- CLOSE

Create the new ACT HANDOFF.

It is descriptive only; the authoritative verdict belongs in the CLOSE
commit trailer.

The HANDOFF must distinguish:

```text
FACTORY_V2_TRAILER_PARSER=REPAIRED
FACTORY_V2_FAIL_OPEN=REPAIRED
HALT_CLASSIFICATION=CONSISTENT

HISTORICAL_BOOTSTRAP_TOPOLOGY=UNCHANGED
HISTORICAL_BOOTSTRAP_GATE_PUSH=FAIL

PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC
```

If every mandatory acceptance criterion is green, CLOSE with:

```text
ACT: ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01
ACT-Phase: CLOSE
ACT-Verdict: PASS_TRUE_GREEN
```

If a requirement fails, issue the appropriate truthful HALT result. Do not
invent a PASS to avoid the HALT parser.

### External terminality

After CLOSE, perform read-only validation:

```sh
bash scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 HEAD

git status --porcelain=v1
git diff --check <ENTRY>..HEAD
```

Run the final Factory tests again.

Do not commit external terminality evidence after CLOSE using this ACT's
identity.

Do not reopen the ACT to correct its HANDOFF formatting.

If an external observation detects a failure, report it truthfully and
stop. Do not automatically generate a `CORRECTION01`.

---

## 14. Explicit convergence rule

**This section is binding.**

No automated successor correction may be generated merely because the
current ACT encountered a validator failure.

A failure must be classified as one of:

```text
IMPLEMENTATION_DEFECT
TEST_DEFECT
HISTORICAL_INVALIDITY
ENVIRONMENT_DEPENDENCY
UNRELATED_BASELINE_FAILURE
```

The agent may repair an implementation or test defect within the
authorized, still-open ACT scope.

Historical invalidity must not be repaired by pretending new commits
change old history.

An unrelated baseline failure must retain its own owner.

A correction ACT may be opened only with separate authorization.

The agent must not respond to a failed validator by changing the verdict
token until the validator accepts it.

**No more green-by-token-selection.**

---

## 15. Board disposition

After this ACT:

```text
FACTORY_V2_HALT_TRAILER_PARSER=QUALIFIED
FACTORY_V2_FAIL_OPEN=ELIMINATED

BOOTSTRAP_BUILD_ENGINEERING=GREEN
BOOTSTRAP_FULL_GATE_PUSH=FAIL_UNRELATED_GEP01
BOOTSTRAP_HISTORICAL_TOPOLOGY=IMMUTABLE_RESIDUE

PARSER_PADDING_AUTHORITY=POLYC

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02` must conduct a fresh selection
of the next parser semantic slice.

It must not automatically retry the failed
`parseCompoundStatementInternal` whole-function migration.

Reuse the established R0 state-boundary ranking model from
`PARSER-SLICE-RECON01`. Exclude already-migrated `CalcPadding`.

Select the next genuinely bridgeable legacy-C semantic authority, then
authorize its production migration as a separate engineering ACT.

---

## 16. Final instruction to executor

Execute this bounded Factory repair.

Do not perform unrelated compiler work.

Do not rewrite Git history.

Do not modify or weaken the full push gate.

Do not recursively open correction ACTs.

Do not manufacture evidence or repair a verdict by changing its wording.

Once the shared parser tests are green and the remaining historical
failures have been honestly classified, stop working on the bootstrap
lineage.

**Return to actual PolyC compiler self-hosting.**
