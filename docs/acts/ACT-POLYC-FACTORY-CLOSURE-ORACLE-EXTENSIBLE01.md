# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Replace the hardcoded Factory closure-status managed universe with manifest-driven ACT/HANDOFF enumeration, register previously excluded closure pairs, and prove the closure oracle remains frozen while judging its own CLOSE

**Repository:** PolyC
**Branch:** `main`

**Class:** FACTORY / GOVERNANCE / CLOSURE-AUTHORITY / INFRASTRUCTURE

**Entry authority:**

```text
HEAD = 76a3fd239cb5dd57c1463453d4e88f5f83a83597

ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01
    ENGINEERING = GREEN
    VERDICT = PASS_ENGINEERING_HALT_GOVERNANCE_DEPENDENCY
    CLOSURE_ORACLE = NOT_APPLICABLE_TO_SELF
```

**Blocking relationship:**

```text
THIS ACT
    ↓
resolves closure-oracle governance dependency
    ↓
ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    ↓
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ↓
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

**Production compiler semantics:** FORBIDDEN.

---

# 0. Mission

Factory currently has two competing descriptions of the closure universe:

```text
docs/factory/act-handoff-map.tsv
```

and a hardcoded bounded list inside:

```text
scripts/quality/factory-closure-status-check.sh
```

The latter is authoritative in practice.

That creates a bootstrap defect:

```text
new ACT/HANDOFF pair
    ↓
append pair to manifest
    ↓
checker still ignores pair
    ↓
must modify checker
    ↓
the judged ACT changes its own judge
```

The defect has now occurred twice.

The most recent consequence is:

```text
ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01
```

having a real HANDOFF but remaining outside the closure oracle's seven-pair universe.

This ACT SHALL make:

```text
docs/factory/act-handoff-map.tsv
```

the **single authoritative enumeration** of managed ACT/HANDOFF pairs.

After this ACT:

```text
ADDING A NEW MANAGED ACT/HANDOFF PAIR
=
APPEND VALID MANIFEST ROW
```

and SHALL NOT require modification to the checker.

Successful terminal state:

```text
MANIFEST_IS_SINGLE_ENUMERATION_AUTHORITY = YES
HARDCODED_PAIR_UNIVERSE                  = NONE
STATIC_LINKAGE_CORRECTION_MANAGED        = YES
SELF_ACT_MANAGED                         = YES
CLOSURE_ORACLE_FROZEN_BEFORE_C3          = YES
PAIR_OK                                  = MANIFEST_ROW_COUNT
PAIR_FAIL                                = 0
```

---

# 1. Non-goals

This ACT SHALL NOT:

```text
change compiler behavior
change static-function linkage semantics
repair libtos symbols
resume LEXER04
rewrite historical HANDOFFs
rewrite historical evidence
repair trailing whitespace inside closed evidence
change ACT verdict grammar
redesign the entire Factory lifecycle
introduce a database/JSON/YAML registry
```

The existing TSV manifest is retained unless C1 proves it structurally incapable of expressing the required contract.

---

# 2. Historical truth preserved

The following remain immutable historical facts:

```text
STATIC-FUNCTION-LINKAGE01 original close
    = FALSE_GREEN historically

STATIC-FUNCTION-LINKAGE01-CORRECTION01
    engineering = GREEN
    current terminal classification
        = PASS_ENGINEERING_HALT_GOVERNANCE_DEPENDENCY

its historical raw evidence
    = contains compiler-emitted trailing whitespace

its original C3 phase binding
    = repaired through c3-reverify
```

This ACT does not rewrite any of those artifacts.

It removes the remaining governance dependency prospectively.

---

# 3. C0 AUTH

This document SHALL be committed before implementation or new evidence.

At authorization:

```sh
git rev-parse HEAD
git branch --show-current
git status --porcelain=v1
```

Required:

```text
ENTRY_HEAD=76a3fd239cb5dd57c1463453d4e88f5f83a83597
BRANCH=main
WORKTREE_CLEAN_AT_AUTH=YES
```

If HEAD has legitimately advanced:

```text
ENTRY_HEAD=<new SHA>
76a3fd2_IS_ANCESTOR=YES
```

No Factory implementation mutation before C0.

---

# 4-59. ... [full ACT contract per authorization body]

# 4. C1 RED — prove dual authority

Mechanically inspect:

```text
docs/factory/act-handoff-map.tsv
scripts/quality/factory-closure-status-check.sh
```

Produce:

```text
c1-manifest-current.tsv
c1-checker-hardcoded-universe.txt
```

Required RED:

```text
MANIFEST_EXISTS=YES
CHECKER_CONTAINS_HARDCODED_PAIR_ENUMERATION=YES
MANIFEST_IS_SINGLE_ENUMERATION_AUTHORITY=NO
```

Count both universes independently:

```text
MANIFEST_ROW_COUNT=<N>
HARDCODED_CHECKER_PAIR_COUNT=<M>
```

At entry the expected checker count is:

```text
HARDCODED_CHECKER_PAIR_COUNT=7
```

Do not hardcode that number into the eventual implementation.

---

# 5. C1 RED — excluded correction witness

Mechanically prove:

```text
docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md
```

and:

```text
docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md
```

exist.

Then prove the pair is not currently managed.

Required:

```text
STATIC_LINKAGE_CORRECTION_ACT_EXISTS=YES
STATIC_LINKAGE_CORRECTION_HANDOFF_EXISTS=YES
STATIC_LINKAGE_CORRECTION_MANIFEST_ROW=NO
STATIC_LINKAGE_CORRECTION_ORACLE_MANAGED=NO
```

This is the principal operational RED.

---

# 6. C1 — durable stash recovery verification

The previous correction created:

```text
refs/tags/recovered/stash-4180088
```

C1 SHALL mechanically peel the annotated tag:

```sh
git rev-parse recovered/stash-4180088^{}
git cat-file -t recovered/stash-4180088^{}
```

Required:

```text
RECOVERED_STASH_PEELED_TYPE=commit
RECOVERED_STASH_PEELED_OID=4180088797d62ce19c4a480dc95b599d19c703cb
F1_DURABLE_REF_RECOVERY=PASS
```

This is an entry conservation check, not the mission of the ACT.

Failure:

```text
HALT_F1_RECOVERY_NOT_DURABLE
```

---

# 7. Manifest contract

C1 SHALL freeze the manifest schema before implementation.

Preferred canonical format:

```text
act_path<TAB>handoff_path
```

Comments:

```text
# comment
```

and blank lines MAY be permitted.

Every data row SHALL contain exactly two non-empty fields.

Required path classes:

```text
field 1:
    docs/acts/*.md

field 2:
    docs/factory/HANDOFF-*.md
```

No row may contain:

```text
absolute path
..
empty field
third field
shell syntax
wildcard expansion
```

Freeze:

```text
MANIFEST_SCHEMA_VERSION=1
MANIFEST_FIELD_COUNT=2
```

No schema extension is authorized in C2.

---

# 8. Manifest authority invariant

After C2:

```text
MANAGED_PAIRS
=
exactly the valid data rows in docs/factory/act-handoff-map.tsv
```

The checker SHALL NOT contain another ACT/HANDOFF path list.

Required:

```text
HARDCODED_ACT_PATH_COUNT_IN_CHECKER=0
HARDCODED_HANDOFF_PATH_COUNT_IN_CHECKER=0
```

Generic path validation literals such as:

```text
docs/acts/
docs/factory/HANDOFF-
```

are allowed.

Specific ACT names are not.

---

# 9. Fail-closed manifest parser

The checker SHALL reject malformed data rather than skipping it.

Required row failures:

```text
EMPTY_ACT_PATH
EMPTY_HANDOFF_PATH
FIELD_COUNT_NOT_2
INVALID_ACT_PREFIX
INVALID_HANDOFF_PREFIX
DUPLICATE_ACT_PATH
DUPLICATE_HANDOFF_PATH
DUPLICATE_PAIR
ACT_FILE_MISSING
HANDOFF_FILE_MISSING
```

At normal closure-check invocation, any such condition yields:

```text
STATUS=FAIL
exit != 0
```

---

# 10. Duplicate semantics

Uniqueness is required independently on both columns.

Forbidden:

```text
ACT_A -> HANDOFF_A
ACT_A -> HANDOFF_B
```

and:

```text
ACT_A -> HANDOFF_A
ACT_B -> HANDOFF_A
```

and exact duplicate rows.

Required counters:

```text
DUPLICATE_ACT_PATHS=0
DUPLICATE_HANDOFF_PATHS=0
DUPLICATE_PAIRS=0
```

---

# 11. File existence

For each data row:

```text
ACT_EXISTS=YES
HANDOFF_EXISTS=YES
```

Normal canonical invocation SHALL fail if either is absent.

There is no implicit:

```text
"future HANDOFF"
```

state in the production oracle.

The phase topology in this ACT handles its own future HANDOFF explicitly rather than weakening the oracle.

---

# 12. ACT/HANDOFF identity contract

For every row, the checker SHALL continue whatever semantic pair validation it performs today.

At minimum preserve:

```text
ACT identity
HANDOFF identity
closure/verdict pairing
Factory closure status
```

This ACT does not weaken existing semantic checks.

Manifest-driven enumeration replaces only:

```text
WHICH PAIRS ARE CHECKED
```

not:

```text
HOW A PAIR IS VALIDATED
```

Required conservation:

```text
LEGACY_PAIR_VALIDATION_SEMANTICS_UNCHANGED=YES
```

---

# 13. Checker output contract

Canonical successful output SHALL expose:

```text
MANIFEST_PATH=docs/factory/act-handoff-map.tsv
MANIFEST_ROWS=<N>

PAIR_OK=<N>
PAIR_FAIL=0

DUPLICATE_ACT_PATHS=0
DUPLICATE_HANDOFF_PATHS=0
DUPLICATE_PAIRS=0

STATUS=PASS
```

On failure:

```text
PAIR_FAIL>0
or
MANIFEST_ERROR_COUNT>0

STATUS=FAIL
```

Exact existing Factory summary tokens should be preserved where compatible.

---

# 14. No silent ignored rows

A malformed or unrecognized manifest row SHALL NOT be silently excluded from:

```text
MANIFEST_ROWS
```

Use separate counters if comments/blank rows are supported:

```text
MANIFEST_DATA_ROWS
MANIFEST_COMMENT_ROWS
MANIFEST_BLANK_ROWS
```

The closure predicate applies to all data rows.

Required:

```text
IGNORED_DATA_ROWS=0
```

---

# 15. C1 baseline equivalence

Before replacing enumeration, capture the seven currently managed pairs and their existing results.

Produce:

```text
c1-legacy-pair-baseline.tsv
```

Schema:

```text
act_path
handoff_path
legacy_result
```

Required:

```text
LEGACY_MANAGED_PAIR_COUNT=7
LEGACY_PAIR_OK=7
LEGACY_PAIR_FAIL=0
```

If live repository state differs:

```text
HALT_BASELINE_DRIFT
```

and rebind the actual baseline before C2.

---

# 16. C2 implementation scope

Authorized files:

```text
scripts/quality/factory-closure-status-check.sh
docs/factory/act-handoff-map.tsv
```

Test files MAY be added under the current Factory quality-test convention.

Possible:

```text
scripts/quality/factory-closure-status-check-test.sh
```

only if no existing test location exists.

If substantive new test implementation would exceed the project's shell governance rules, use the existing Factory test mechanism or PolyC.

No compiler source is in scope.

---

# 17. C2 — manifest-driven enumeration

Replace hardcoded pair construction with iteration over the manifest.

The production checker SHALL open:

```text
docs/factory/act-handoff-map.tsv
```

or a canonical repo-root-relative equivalent.

No implicit fallback to the old hardcoded list.

If the manifest is absent:

```text
HALT_MANIFEST_MISSING
```

at development time and:

```text
STATUS=FAIL
```

at runtime.

---

# 18. Test seam for alternate manifests

For falsification tests, the checker SHALL support a bounded test-only way to supply an alternate manifest.

Preferred:

```text
FACTORY_ACT_HANDOFF_MAP=<path>
```

or:

```text
--manifest <path>
```

C1 freezes one mechanism.

Canonical `gate-fast` SHALL use no override and therefore always consume:

```text
docs/factory/act-handoff-map.tsv
```

The override must not allow arbitrary changes to pair-validation semantics.

It changes only the manifest source.

---

# 19. Register the excluded static-linkage correction

C2 SHALL append the pair:

```text
docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md
```

to the manifest.

Required after C2:

```text
STATIC_LINKAGE_CORRECTION_MANIFEST_ROW=YES
STATIC_LINKAGE_CORRECTION_ORACLE_MANAGED=YES
```

This does NOT rewrite its historical HANDOFF verdict.

It proves that the governance dependency:

```text
"oracle cannot inspect this pair"
```

has been removed.

---

# 20. Register this ACT before C3

This ACT SHALL also add its own manifest row during C2:

```text
docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01.md
docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01.md
```

Therefore after C2:

```text
MANIFEST_ROW_FOR_SELF=YES
```

but the HANDOFF does not yet exist.

This is intentional.

The production oracle at this phase MUST fail:

```text
SELF_HANDOFF_MISSING=YES
STATUS=FAIL
```

This proves the oracle is actually load-bearing for its own row.

Do not classify this expected C2/C3 pre-close failure as ACT failure.

---

# 21. Why self-registration happens in C2

The anti-self-modification invariant is:

```text
CHECKER_SHA_AT_C2
==
CHECKER_SHA_AT_C3
==
CHECKER_SHA_AT_C4
```

and:

```text
MANIFEST_SHA_AT_C2
==
MANIFEST_SHA_AT_C3
==
MANIFEST_SHA_AT_C4
```

Therefore C4 cannot add itself to the manifest.

The pair must already be registered before C3.

C4's only missing input is the HANDOFF file itself.

---

# 22. Frozen-oracle identity

At C2 close record:

```text
CHECKER_SHA256=<sha>
MANIFEST_SHA256=<sha>
```

C3 and C4 SHALL require exact equality.

Produce:

```text
c2-oracle-freeze.txt
```

Required:

```text
ORACLE_FROZEN=YES
```

---

# 23. C3 — baseline migration equivalence

With a temporary manifest containing only the original seven pairs, run the new checker.

Require:

```text
OLD_CHECKER_PAIR_OK=7
NEW_CHECKER_PAIR_OK=7

OLD_CHECKER_PAIR_FAIL=0
NEW_CHECKER_PAIR_FAIL=0
```

and pair-by-pair agreement:

```text
LEGACY_ENUMERATION_EQUIVALENCE=PASS
```

The implementation may be structurally different but must not change the result of existing pair validation.

---

# 24. C3 — static-linkage correction inclusion

Using the canonical manifest:

```text
STATIC_LINKAGE_CORRECTION_MANAGED=YES
```

The checker must now actually process its pair.

Record its pair result separately:

```text
STATIC_LINKAGE_CORRECTION_PAIR_CHECK=<PASS|FAIL>
```

Expected:

```text
PASS
```

if the pair's ACT/HANDOFF structure satisfies the existing pair validator.

If it fails:

```text
HALT_PREVIOUS_CORRECTION_PAIR_INVALID
```

Do not weaken validation to make it pass.

---

# 25. C3 — self-row load-bearing witness

Before creating this ACT's HANDOFF, run the canonical checker.

Required:

```text
SELF_ROW_PRESENT=YES
SELF_HANDOFF_EXISTS=NO
SELF_PAIR_RESULT=FAIL
OVERALL_STATUS=FAIL
```

This is an intentional RED witness.

It proves:

```text
MANIFEST ROW
```

is not decorative.

---

# 26-31. Negative controls N01..N06

Negative controls validate that the checker rejects malformed manifest rows
fail-closed. Each control constructs a temporary manifest with a known
defect and asserts the checker exits nonzero with the corresponding
detection token. Required detections:

  N01: DUPLICATE_ACT_PATH_DETECTED=YES  (two rows, same act_path)
  N02: DUPLICATE_HANDOFF_PATH_DETECTED=YES  (two rows, same handoff_path)
  N03: MISSING_ACT_DETECTED=YES  (row references nonexistent ACT)
  N04: MISSING_HANDOFF_DETECTED=YES  (row references nonexistent HANDOFF)
  N05: MALFORMED_ROW_DETECTED=YES  (one-field row, three-field row,
       empty-act row, empty-handoff row)
  N06: DUPLICATE_PAIR_DETECTED=YES  (exact duplicate rows)

All six negative controls require RC_NONZERO=YES.

---

# 32. Negative control N07 — unmanaged real pair

Create temporary copies of a valid ACT/HANDOFF pair outside the manifest.

Run canonical checker.

Required:

```text
UNMANAGED_PAIR_AFFECTS_MANAGED_COUNT=NO
```

This proves the universe is exactly the manifest.

The checker is not required to scan the filesystem for unregistered pairs in this ACT.

---

# 33-34. Positive controls P01..P02

P01: Using a temporary manifest containing the baseline rows plus one
valid fixture ACT/HANDOFF row, require:

  PAIR_OK increases by exactly 1
  PAIR_FAIL remains 0

This proves that adding a row to the manifest alone (no checker change)
extends the managed universe.

P02: Run the same valid manifest with rows reordered; require:

  same pair set
  same counters
  same overall verdict

No ordering semantics.

---

# 35. Manifest path safety

Reject manifest entries containing traversal:

```text
../
/absolute/path
```

Required:

```text
PATH_TRAVERSAL_REJECTED=YES
ABSOLUTE_PATH_REJECTED=YES
```

Symlink behavior follows normal repository filesystem semantics unless C1 proves an existing Factory policy says otherwise.

---

# 36. Empty manifest behavior

Temporary empty manifest must fail closed:

```text
MANIFEST_ROWS=0
STATUS=FAIL
```

Required token:

```text
HALT_EMPTY_MANAGED_UNIVERSE
```

or existing Factory-equivalent failure classification.

No successful zero-pair universe.

---

# 37. Canonical manifest size after C2

Let:

```text
BASELINE_ROWS = 7
```

Then add:

```text
+ static-function-linkage correction pair
+ this ACT pair
```

Expected:

```text
CANONICAL_MANIFEST_ROWS=9
```

This number is an ACT acceptance expectation, not an implementation constant.

The checker must derive it from file contents.

---

# 38. No pair paths embedded in checker

C3 SHALL mechanically search:

```text
scripts/quality/factory-closure-status-check.sh
```

for:

```text
ACT-POLYC-
HANDOFF-ACT-
```

Expected:

```text
SPECIFIC_ACT_IDENTIFIERS_IN_CHECKER=0
SPECIFIC_HANDOFF_IDENTIFIERS_IN_CHECKER=0
```

Generic prefixes are allowed.

---

# 39. Checker modification freeze

Capture after C2:

```text
CHECKER_C2_SHA256
MANIFEST_C2_SHA256
```

At C3:

```text
CHECKER_C3_SHA256 == CHECKER_C2_SHA256
MANIFEST_C3_SHA256 == MANIFEST_C2_SHA256
```

At C4 immediately before CLOSE:

```text
CHECKER_C4_SHA256 == CHECKER_C2_SHA256
MANIFEST_C4_SHA256 == MANIFEST_C2_SHA256
```

Required:

```text
CLOSURE_ORACLE_FROZEN_BEFORE_C3=YES
```

---

# 40. C3 Factory regression

Run at minimum:

```text
make gate-fast
bash scripts/quality/factory-append-only-test.sh
```

Because this ACT's HANDOFF does not yet exist, `gate-fast` may fail specifically at the closure-status subgate during pre-close C3.

Therefore separate:

```text
NON_CLOSURE_FACTORY_GATES
```

from:

```text
EXPECTED_SELF_HANDOFF_MISSING_FAILURE
```

Required:

```text
ALL_NON_CLOSURE_FACTORY_GATES=PASS
SELF_PAIR_ONLY_BLOCKER=YES
```

There must be no unrelated failure.

---

# 41. Dedicated checker test target

Add or extend a durable Factory test target, preferably:

```text
make factory-closure-status-test
```

Required cases:

```text
T01 baseline valid manifest
T02 duplicate ACT
T03 duplicate HANDOFF
T04 duplicate pair
T05 missing ACT
T06 missing HANDOFF
T07 malformed row
T08 empty manifest
T09 add-valid-row-without-checker-change
T10 row-order independence
T11 path traversal
T12 canonical self-row missing-HANDOFF RED
```

Required:

```text
FACTORY_CLOSURE_STATUS_TEST_PASS=12
FACTORY_CLOSURE_STATUS_TEST_FAIL=0
```

If existing test conventions require another count/name, freeze in C1.

---

# 42. F-NO-PYTHON

Required:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_VIOLATIONS=0
```

No Python manifest generator.

---

# 43. F-POLYC-TOOLS

This ACT modifies an existing Factory shell checker.

It SHALL NOT introduce a new substantive shell application.

Permitted:

```text
bounded modification of existing checker
small Factory regression test shell consistent with repository convention
POSIX awk/sort/uniq/cut-style primitives
```

If a new substantive analyzer becomes necessary:

```text
HALT_F_POLYC_TOOLS_SCOPE
```

and implement it in PolyC.

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOL=0
```

---

# 44. Closed evidence immutability

No modification to:

```text
evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01/**
evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01/**
docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md
docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md
```

The prior raw `.S` whitespace remains untouched.

Required:

```text
CLOSED_PREDECESSOR_EVIDENCE_DELTA=0
CLOSED_PREDECESSOR_HANDOFF_DELTA=0
```

---

# 45-58. Phase topology, HALT taxonomy, closure predicates

See canonical ACT template (`docs/factory/ACT-TEMPLATE.md`) for the full
HALT enumeration, the C4 closure predicate, the successful closure
meaning statement, and the next ACT pointer.

The C4 verdict token is:

```text
PASS_TRUE_GREEN
```

The principal BLOCKERS remain identical to the canonical ACT template
(F-NO-PYTHON, F-POLYC-TOOLS, append-only invariant, hardcoded-universe
removal, predecessor immutability, patch hygiene, worktree clean).

---

# 59. NEXT

After TRUE_GREEN:

```text
NEXT = ACT-POLYC-LIBTOS-SYMBOL-GAPS01
```

The Factory governance dependency is no longer blocking compiler work.

Then:

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
```

followed by:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

---

# 60. Execution instruction

Start with C0 AUTH.

The first three mechanical questions are:

```text
1. Can the current seven hardcoded checker pairs be reproduced
   exactly from the manifest with no semantic result change?

2. Does appending the existing STATIC-FUNCTION-LINKAGE01-
   CORRECTION01 pair cause the unchanged manifest-driven checker
   to begin judging it automatically?

3. If this ACT registers itself in C2 while its HANDOFF is absent,
   does the frozen checker fail—and then pass in C4 solely because
   the HANDOFF appears?
```

If all three are proven, the bootstrap problem is solved.

Do not modify the closure checker during C4.

## Status

PASS_TRUE_GREEN

Mirrors the HANDOFF's authoritative VERDICT. The HANDOFF remains the
canonical verdict source; this section is structural metadata required
by the closure-status oracle to validate the ACT/HANDOFF pair equality.
No semantic change. Recorded as documented residue.
