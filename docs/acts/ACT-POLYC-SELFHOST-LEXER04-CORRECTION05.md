# ACT-POLYC-SELFHOST-LEXER04-CORRECTION05

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Close the remaining LEXER04 qualification-machinery defects: canonical migration identity, complete predicate witnesses, PolyC-native N02 orchestration, and clean prospective evidence

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / LEXER / QUALIFICATION-INFRA / CORRECTION

**Priority:** P0

---

# 0. Mission

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION04` terminated correctly as:

```text
HALT_MANDATORY_AC_NOT_GREEN
```

The production implementation is not the blocker.

The remaining blocker is qualification machinery.

CORRECTION04 established substantial GREEN engineering:

```text
LEXER04 production authority                 = GREEN
BootstrapLinkDirective load-bearing          = GREEN
direct differential                           = GREEN
component fixed point                         = GREEN
G1/G2/G3 migration equivalence               = GREEN
L07 migration delta                          = GREEN
N02 causal mutation concept                  = GREEN
generation-copy control                      = GREEN
AC identity binding                          = GREEN
evidence SHA binding                         = GREEN
```

But four mandatory CORRECTION04 ACs remain mechanically false:

```text
AC12 = FAIL
  OBSERVED_MIGRATION_FIXTURE_SET schema mismatch:
  authorized canonical id = L07
  emitted id              = L07_angle_complex

AC25 = FAIL
  WITNESS_FAIL    = 3
  WITNESS_MISSING = 20

AC33 = FAIL
  scripts/quality/lexer09-n02-mutation-runner.sh
  = 109 LOC substantive shell
  > 50 LOC F-POLYC-TOOLS ceiling

AC39 = FAIL
  prospective git diff --check reports one trailing blank line in
  CORRECTION04 C3 evidence
```

CORRECTION04 AC35/F14 is accepted as mechanically GREEN:

```text
CLOSED_CORRECTION03_FILES_MODIFIED_COUNT=0
CLOSED_HANDOFF_CORRECTION03_DELTA=0
CLOSED_EVIDENCE_CORRECTION03_DELTA=0
```

CORRECTION04-CORRECTION01 is historical additive reviewer evidence and
shall remain immutable.

Its arithmetic inconsistency is also historical:

```text
listed failed ACs = AC12, AC25, AC33, AC39
mechanical failure count = 4

historical addendum TOTAL_FAIL=5
```

CORRECTION05 SHALL NOT rewrite that artifact.

The new ACT SHALL prospectively establish the correct state.

---

# 1. Terminal objective

Successful CORRECTION05 closure requires:

```text
CORRECTION04_REVIEWED_VERDICT
  = HALT_MANDATORY_AC_NOT_GREEN

CORRECTION04_CONFIRMED_FAIL_SET
  = {AC12, AC25, AC33, AC39}

CORRECTION04_CONFIRMED_FAIL_COUNT
  = 4

CORRECTION04_AC35_F14
  = PASS

MIGRATION_FIXTURE_CANONICALIZATION
  = PASS

AC_WITNESS_SCHEMA
  = COMPLETE

WITNESS_FAIL
  = 0

WITNESS_MISSING
  = 0

N02_ORCHESTRATION_AUTHORITY
  = POLYC

N02_SHELL_DISPATCH_LOC
  <= 50

NEW_SUBSTANTIVE_NON_POLYC_TOOLS
  = 0

CORRECTION05_PATCH_HYGIENE
  = PASS

PRODUCTION_SOURCE_DELTA
  = 0

LEXER04_PRODUCTION_QUALIFICATION
  = TRUE_GREEN

CORRECTION05_VERDICT
  = PASS_TRUE_GREEN
```

---

# 2. Historical truth — immutable

The following predecessor facts SHALL be preserved:

```text
CORRECTION03
  = FALSE_GREEN / HALT_MULTIPLE_BINDING_PREDICATES

CORRECTION04
  = HALT_MANDATORY_AC_NOT_GREEN

CORRECTION04-CORRECTION01
  = additive reviewer-finding re-verification artifact
```

CORRECTION05 SHALL NOT:

```text
edit CORRECTION03 evidence
edit CORRECTION03 HANDOFF
edit CORRECTION04 evidence
edit CORRECTION04 HANDOFF
edit CORRECTION04-CORRECTION01 evidence
delete historical whitespace errors
rewrite historical AC ledgers
rewrite historical totals
amend commits
rebase commits
force-push
reset/recommits
```

History is evidence.

---

# 3. Expected entry

Current observed forward head:

```text
87106d6f79a42e037d89fccf4ecdb8014cfbddf7
```

This is the additive CORRECTION04-CORRECTION01 reviewer finding.

At C0 bind the actual live HEAD.

Run:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git merge-base --is-ancestor 87106d6 HEAD
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN_AT_C0=YES
87106d6_IS_ANCESTOR=YES
```

Freeze:

```text
CORRECTION05_ENTRY_HEAD=<actual clean HEAD>
PATCH_HYGIENE_BASELINE=<same SHA>
```

If dirty:

```text
HALT_ENTRY_DIRTY
```

Do not auto-clean unrelated work.

---

# 4. Complete authorization artifact

This file is the complete binding authorization.

CORRECTION05 SHALL NOT depend on:

```text
chat prompt as hidden contract
commit message as missing ACT body
external prose not committed in repository
"see prior ACT for full specification"
```

Allowed references to prior ACTs are historical references only.

Required:

```text
ACT_BODY_COMPLETE=YES
ACT_BODY_PLACEHOLDER_SECTIONS=0
```

---

# 5. Scope principle

CORRECTION05 is a **qualification-machinery repair ACT**.

Default:

```text
PRODUCTION_MUTATION_AUTHORIZED=NO
```

Production files are read-only:

```text
src/lexer.c
src/lexer_bridge.h
tools/bootstrap/selfhost-lexer-link.HC
```

If fresh verification demonstrates an actual production defect:

```text
HALT_PRODUCTION_DEFECT_DISCOVERED
```

Do not repair it here.

---

# 6. Authorized implementation scope

C2 MAY modify:

```text
tools/quality/lexer09-ac-witness-verify.HC
tools/quality/lexer09-ac-ledger-verify.HC
tools/quality/lexer09-n02-witness-verify.HC
tools/quality/lexer09-4stage-semantic-verify.HC
tools/quality/lexer09-generation-provenance-verify.HC
```

C2 MAY add one PolyC N02 orchestration implementation, preferred:

```text
tools/quality/lexer09-n02-mutation-runner.HC
```

C2 MAY modify:

```text
Makefile
```

for qualification targets only.

Shell modifications are allowed only as:

```text
<=50 LOC
pure dispatch/bootstrap glue
```

Expected shell:

```text
scripts/quality/lexer09-n02-mutation-runner.sh
```

shall become dispatch-only.

---

# 7. Explicitly forbidden scope

Do not modify:

```text
src/lexer.c
src/lexer_bridge.h
tools/bootstrap/selfhost-lexer-link.HC

src/parser.c
src/aarch64.c

libtos implementation

Factory closure-oracle implementation

LEXER01/02/03 production source

lexInclude
parser migration
preprocessor migration
```

Do not repair unrelated historical LEXER07 failures.

---

# 8. Commit topology

Exactly five phase commits:

```text
C0 AUTH
C1 RED/CONTRACT
C2 IMPL
C3 VERIFY
C4 CLOSE
```

Maximum:

```text
5
```

No:

```text
C2.1
C3.1
C4-fill
C4-correct
SHA-fill
whitespace-cleanup commit
reviewer-addendum commit inside CORRECTION05
```

If a sixth commit appears necessary:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

Do not create it.

---

# 9. C0 artifacts

C0 may create only:

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION05.md

evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c0/
  c0-entry-identity.txt
  c0-scope.txt
  c0-predecessor-disposition.txt
  c0-authorization-integrity.txt
```

Required:

```text
C0_AUTH_BEFORE_WORK=YES
```

---

# 10. Prospective patch-hygiene baseline

Binding range:

```text
CORRECTION05_ENTRY_HEAD..HEAD
```

At every phase:

```sh
git diff --check "$CORRECTION05_ENTRY_HEAD"..HEAD
```

Required:

```text
PATCH_HYGIENE_ERRORS=0
```

No exclusions.

No:

```text
--diff-filter=M
```

No evidence-directory exclusion.

Historical predecessor errors are outside the range.

---

# 11. C1 predecessor defect reproduction

Produce:

```text
c1-correction04-defects.tsv
```

Required rows:

```text
D1 AC12 canonical migration id mismatch
D2 AC25 missing/failing witness schema
D3 AC33 substantive shell over budget
D4 AC39 prospective patch hygiene failure
```

Also record:

```text
D5 historical reviewer arithmetic mismatch:
   historical addendum says TOTAL_FAIL=5
   mechanically confirmed fail set has cardinality 4
```

Required:

```text
CORRECTION04_HALT_REPRODUCED=YES
CORRECTION04_CONFIRMED_FAIL_COUNT=4
```

---

# 12. AC35/F14 disposition

C1 SHALL mechanically re-run the exact F14 comparison used for
CORRECTION04 entry→close.

Required:

```text
CLOSED_CORRECTION03_FILES_MODIFIED_COUNT=0
CLOSED_HANDOFF_CORRECTION03_DELTA=0
CLOSED_EVIDENCE_CORRECTION03_DELTA=0

CORRECTION04_AC35=PASS
```

If nonzero:

```text
HALT_F14_REVERIFY_MISMATCH
```

Do not rely only on the addendum prose.

---

# 13. Canonical fixture identity problem

Current mismatch:

```text
contract canonical id:
  L07

verifier/current output:
  L07_angle_complex
```

This is an identity-schema defect, not a semantic discrepancy.

C1 SHALL inventory every LEXER04 fixture alias.

Produce:

```text
c1-fixture-id-map.tsv
```

Columns:

```text
canonical_id
legacy_alias
human_name
input_hash
authorized
```

At minimum:

```text
L07    L07_angle_complex    <hash>    YES
```

---

# 14. Canonical fixture identity rule

All authoritative CORRECTION05 machine-readable output SHALL use:

```text
canonical_id
```

not descriptive aliases.

Required:

```text
EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07
```

Human-facing evidence MAY additionally emit:

```text
OBSERVED_MIGRATION_FIXTURE_NAME=L07_angle_complex
```

but this is non-authoritative metadata.

---

# 15. No hardcoded one-off string replacement

Do not implement:

```text
if name == "L07_angle_complex":
    emit "L07"
```

inside the semantic verifier.

Instead the verifier SHALL consume:

```text
c1-fixture-id-map.tsv
```

or an equivalent frozen data representation.

Required:

```text
FIXTURE_ID_MAP_ENTRIES>=1
UNKNOWN_FIXTURE_ALIAS=0
DUPLICATE_CANONICAL_ID=0
```

---

# 16. Fixture alias negative control

Create a temporary mapping with:

```text
L07_angle_complex -> L99
```

or remove the L07 mapping.

Expected:

```text
FIXTURE_ALIAS_CONTROL_REJECTED=YES
VERIFIER_RC_NONZERO=YES
```

This makes AC12's repair load-bearing.

---

# 17. Witness schema recon

CORRECTION04 defined:

```text
66 witnesses
```

Observed:

```text
WITNESS_TOTAL=66
WITNESS_PASS=43
WITNESS_FAIL=3
WITNESS_MISSING=20
```

C1 SHALL mechanically classify all 23 non-pass witnesses.

Produce:

```text
c1-witness-gap-inventory.tsv
```

Columns:

```text
ac_id
witness_id
expected_key
expected_operator
expected_value
evidence_path
observed_key
classification
repair_owner
```

Classifications:

```text
TOKEN_NAME_DRIFT
TOKEN_VALUE_DRIFT
MISSING_TOKEN
WRONG_EVIDENCE_PATH
WRONG_OPERATOR
REAL_PREDICATE_FAIL
CONTRACT_DEFECT
```

Required:

```text
WITNESS_GAP_TOTAL=23
```

unless live recon mechanically finds a different count.

Bind actual result.

---

# 18. No automatic contract weakening

C2 SHALL NOT solve missing witnesses by:

```text
deleting witness rows
marking mandatory=false
changing expected values to observed failures
removing ACs
adding PASS_BY_DESIGN
```

Every witness contract change requires one of:

```text
CANONICAL_SCHEMA_REPAIR
EVIDENCE_PATH_REPAIR
MECHANICALLY_JUSTIFIED_REDUNDANCY_REMOVAL
```

Any semantic predicate change:

```text
HALT_WITNESS_CONTRACT_SEMANTIC_CHANGE_REQUIRED
```

---

# 19. Canonical witness token namespace

C1 SHALL define:

```text
c1-token-schema.tsv
```

Columns:

```text
token_key
type
producer
consumer
meaning
canonical
legacy_aliases
```

Supported types:

```text
STRING
INTEGER
BOOLEAN
SHA256
SET
RC
```

Every mandatory witness key must appear exactly once.

Required:

```text
TOKEN_SCHEMA_DUPLICATES=0
WITNESS_KEYS_WITHOUT_SCHEMA=0
```

---

# 20. Producer/consumer schema agreement

At C2, all evidence producers and witness consumers SHALL share the same
canonical keys.

Do not independently spell tokens in:

```text
semantic verifier
N02 verifier
generation verifier
ledger verifier
witness verifier
```

Preferred implementation:

```text
one declaration-only PolyC header or data file
```

if repository tooling permits it.

Otherwise mechanically verify schema equivalence.

Required:

```text
TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT=0
```

---

# 21. AC25 terminal requirement

At C3:

```text
WITNESS_TOTAL=<frozen total>
WITNESS_PASS=<same total>
WITNESS_FAIL=0
WITNESS_MISSING=0
```

Required:

```text
AC25=PASS
```

Nothing weaker.

---

# 22. Predicate-lie control retained

The CORRECTION04 design was correct here.

Retain a temporary false PASS row whose evidence contains a contradicting
value.

Expected:

```text
PREDICATE_LIE_DETECTED=YES
VERIFIER_RC_NONZERO=YES
```

This control must pass after the schema repair.

---

# 23. Witness-missing negative control

New regression control:

remove one mandatory evidence token from a temporary evidence copy.

Expected:

```text
WITNESS_MISSING_CONTROL_DETECTED=YES
VERIFIER_RC_NONZERO=YES
```

This specifically proves that AC25 cannot silently return green if one
of the former 20 missing tokens reappears.

---

# 24. Witness-value negative control

Modify one token:

```text
GENERATION_COPY_DETECTED=YES
```

to:

```text
GENERATION_COPY_DETECTED=NO
```

without changing AC identity.

Expected:

```text
WITNESS_VALUE_CONTROL_DETECTED=YES
VERIFIER_RC_NONZERO=YES
```

---

# 25. AC identity negative control retained

Swap AC identities/predicate hashes in a temporary ledger.

Required:

```text
AC_ID_SHUFFLE_DETECTED=YES
```

---

# 26. Evidence SHA negative control retained

Mutate a temporary evidence byte.

Required:

```text
EVIDENCE_SHA_MUTATION_DETECTED=YES
```

---

# 27. N02 architecture defect

Current:

```text
scripts/quality/lexer09-n02-mutation-runner.sh
LOC=109
```

It owns substantive mutation/build/link/run orchestration.

Therefore:

```text
F_POLYC_TOOLS=FAIL
```

in CORRECTION04.

CORRECTION05 SHALL repair authority placement.

---

# 28. N02 target architecture

Required:

```text
tools/quality/lexer09-n02-mutation-runner.HC
```

owns:

```text
temporary directory naming
pristine source read
mutation generation
mutated source write
SHA capture
component compile invocation
component artifact verification
seam link invocation
seam artifact verification
seam execution
stdout/stderr collection
RC classification
pristine-vs-mutated semantic comparison
expected fixture/field comparison
machine-readable result emission
```

Shell wrapper owns only:

```text
environment setup if unavoidable
exec PolyC binary
exit-code propagation
```

---

# 29. N02 shell budget

Required:

```text
scripts/quality/lexer09-n02-mutation-runner.sh
LOC <= 50
```

Preferred:

```text
LOC <= 20
```

The wrapper SHALL contain no:

```text
mutation logic
SHA comparison
fixture classification
PASS/FAIL aggregation
semantic diff logic
```

---

# 30. Shell authority mechanical verifier

C3 SHALL record:

```text
N02_SHELL_LOC=<n>
N02_SHELL_HAS_MUTATION_LOGIC=NO
N02_SHELL_HAS_SHA_LOGIC=NO
N02_SHELL_HAS_PASS_FAIL_LOGIC=NO
N02_SHELL_DISPATCH_ONLY=YES
```

Required:

```text
F_POLYC_TOOLS_N02=PASS
```

---

# 31. PolyC N02 runner input contract

Because PolyC `Main`/argv behavior has historically varied, C1 SHALL first
recon the repository's currently accepted parameter transport.

Allowed:

```text
argv
environment variables
frozen config file
```

Choose one.

Freeze:

```text
N02_CONFIG_TRANSPORT=<...>
```

No shell-side semantic parsing.

---

# 32. N02 mutation semantics unchanged

CORRECTION05 does not redesign N02.

Retain the already-working semantic mutation:

```text
mutation kind = B
fixture       = L07
expected field = link_libs
```

Observed intended mutation example:

```text
pristine = lib-complex_1.0
mutated  = lib-complex_1.
```

Exact mutation is frozen at C1 from live evidence.

---

# 33. N02 terminal chain

Required:

```text
MUTATED_SOURCE_SHA_NONEMPTY=YES
MUTATED_SOURCE_SHA_DIFFERS=YES

MUTATED_COMPONENT_BUILD_RC=0
MUTATED_COMPONENT_SHA_NONEMPTY=YES
MUTATED_COMPONENT_SHA_DIFFERS=YES

MUTATED_SEAM_LINK_RC=0
MUTATED_SEAM_SHA_NONEMPTY=YES

MUTATED_SEAM_RUN_RC=0

EXPECTED_DIVERGENCE_FIXTURE=L07
EXPECTED_DIVERGENCE_FIELD=link_libs

MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES
UNEXPECTED_MUTATION_DIVERGENCE_COUNT=0

PRISTINE_REVERIFY_RC=0
```

AC33 repair must not regress N02.

---

# 34. N02 incomplete-witness control retained

Required:

```text
N02_INCOMPLETE_WITNESS_REJECTED=YES
```

---

# 35. Generation-copy control retained

Execute:

```text
copy real G1 raw output to temporary forged G3 path
retain expected G3 provenance
run provenance verifier
```

Required:

```text
GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES
```

---

# 36. Migration semantic contract retained

Required:

```text
POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0

EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07

NON_MIGRATION_G0_DIVERGENCE_COUNT=0
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0

L07_G0=lib-complex_1co
L07_G1=lib-complex_1.0
L07_G2=lib-complex_1.0
L07_G3=lib-complex_1.0
```

No semantic contract expansion.

---

# 37. Production authority must be freshly reverified

Even though production files are unchanged, C3 SHALL freshly establish:

```text
POLYC_OUTPUTS_CONSUMED_BY_PRODUCTION=YES
SELFHOST_DUPLICATE_TARGET_PARSE=0
```

using the existing production-authority verifier or a read-only check.

Required:

```text
PRODUCTION_AUTHORITY_VERIFY=PASS
```

---

# 38. Production source immutability

Freeze at C0:

```text
sha256(src/lexer.c)
sha256(src/lexer_bridge.h)
sha256(tools/bootstrap/selfhost-lexer-link.HC)
```

Recompute at C3.

Required:

```text
PRODUCTION_SOURCE_DELTA=0
```

---

# 39. Direct differential conservation

Fresh run.

Required:

```text
DIRECT_DIFFERENTIAL_FAIL=0
```

Expected historical:

```text
23/23
```

Bind actual.

---

# 40. Component fixed-point conservation

Fresh run.

Required:

```text
COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0
```

---

# 41. Four-generation run conservation

Freshly run G0/G1/G2/G3 production seams.

Required:

```text
G0_BUILD_RC=0
G0_RUN_RC=0

G1_BUILD_RC=0
G1_RUN_RC=0

G2_BUILD_RC=0
G2_RUN_RC=0

G3_BUILD_RC=0
G3_RUN_RC=0
```

---

# 42. Provenance conservation

Required:

```text
PROVENANCE_ROW_PASS=4
PROVENANCE_ROW_FAIL=0
```

---

# 43. LEXER01 conservation

Run actual canonical gate.

No narrative substitution.

Required:

```text
LEXER01_CONSERVATION=PASS
```

---

# 44. LEXER02 conservation

Run actual canonical targeted gate.

Required:

```text
LEXER02_DIRECT_CONSERVATION=PASS
```

---

# 45. LEXER03 conservation

Run:

```text
direct differential
fixed point
broad corpus
```

Required:

```text
LEXER03_CONSERVATION=PASS
```

---

# 46. LEXER07 broad-corpus baseline

C1 SHALL freeze current entry state:

```text
LEXER07_ENTRY_REGRESSION=<actual>
LEXER07_ENTRY_FAILURE_SET=<actual>
```

Historical expectation:

```text
6 regressions
```

but live evidence wins.

---

# 47. Broad-corpus terminal predicate

Required:

```text
LEXER07_NEW_FAILURES=0
LEXER07_POST_REGRESSION <= LEXER07_ENTRY_REGRESSION

LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS
```

No requirement to solve unrelated historical LEXER07 failures.

---

# 48. F-NO-PYTHON

Required forward predicate:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

Record grandfathered Python separately.

---

# 49. F14

No modifications to closed evidence/HANDOFFs from:

```text
LEXER01
LEXER02
LEXER03
LEXER04
LEXER04-CORRECTION01
LEXER04-CORRECTION02
LEXER04-CORRECTION03
LEXER04-CORRECTION04
LEXER04-CORRECTION04-CORRECTION01
```

Required:

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

---

# 50. CORRECTION05 evidence policy

All CORRECTION05 evidence must be newly created under:

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/
```

Do not create:

```text
v2
fixed
clean
corrected
```

files inside old ACT directories.

---

# 51. Evidence writing hygiene

Every tool producing text evidence SHALL terminate with:

```text
exactly one newline
```

and SHALL NOT emit:

```text
trailing spaces
trailing tabs
extra blank line at EOF
```

For captured compiler/diff text that contains whitespace:

```text
encode/escape it
```

rather than inserting literal trailing whitespace.

---

# 52. Patch-hygiene selftest at C2

Before C2 commit:

generate representative evidence.

Run:

```sh
git diff --check "$CORRECTION05_ENTRY_HEAD"..HEAD
```

Required:

```text
PATCH_HYGIENE_ERRORS=0
```

This makes AC39 repair load-bearing before C3.

---

# 53. C1 AC contract

CORRECTION05 uses the following mandatory acceptance criteria.

## AC01 — clean authorized entry

```text
C0_AUTH_BEFORE_WORK=YES
WORKTREE_CLEAN_AT_C0=YES
```

## AC02 — complete authorization artifact

```text
ACT_BODY_COMPLETE=YES
ACT_BODY_PLACEHOLDER_SECTIONS=0
```

## AC03 — CORRECTION04 truthful disposition

```text
CORRECTION04_HALT_REPRODUCED=YES
CORRECTION04_CONFIRMED_FAIL_COUNT=4
```

## AC04 — CORRECTION04 F14 truth

```text
CORRECTION04_AC35=PASS
```

## AC05 — historical arithmetic defect recorded

```text
HISTORICAL_ADDENDUM_TOTAL_FAIL_RECORDED=5
MECHANICAL_CORRECTION04_FAIL_COUNT=4
```

## AC06 — production source immutable

```text
PRODUCTION_SOURCE_DELTA=0
```

## AC07 — production authority

```text
PRODUCTION_AUTHORITY_VERIFY=PASS
```

## AC08 — direct differential

```text
DIRECT_DIFFERENTIAL_FAIL=0
```

## AC09 — component fixed point

```text
COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0
```

## AC10 — post-migration equivalence

```text
POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0
```

## AC11 — canonical migration fixture

```text
EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07
```

## AC12 — canonical fixture map integrity

```text
UNKNOWN_FIXTURE_ALIAS=0
DUPLICATE_CANONICAL_ID=0
```

## AC13 — fixture alias negative control

```text
FIXTURE_ALIAS_CONTROL_REJECTED=YES
```

## AC14 — G0 non-migration conservation

```text
NON_MIGRATION_G0_DIVERGENCE_COUNT=0
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0
```

## AC15 — L07 semantic values

```text
L07_G0=lib-complex_1co
L07_G1=lib-complex_1.0
L07_G2=lib-complex_1.0
L07_G3=lib-complex_1.0
```

## AC16 — N01

```text
SEMANTIC_OUTPUT_MUTATION_DETECTED=YES
```

## AC17 — N02 PolyC authority

```text
N02_ORCHESTRATION_AUTHORITY=POLYC
N02_SHELL_DISPATCH_ONLY=YES
N02_SHELL_LOC<=50
```

## AC18 — N02 build/link/run

```text
MUTATED_COMPONENT_BUILD_RC=0
MUTATED_SEAM_LINK_RC=0
MUTATED_SEAM_RUN_RC=0
```

## AC19 — N02 artifact identities

```text
MUTATED_COMPONENT_SHA_NONEMPTY=YES
MUTATED_COMPONENT_SHA_DIFFERS=YES
MUTATED_SEAM_SHA_NONEMPTY=YES
```

## AC20 — N02 causal effect

```text
MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES
UNEXPECTED_MUTATION_DIVERGENCE_COUNT=0
```

## AC21 — N02 incomplete witness

```text
N02_INCOMPLETE_WITNESS_REJECTED=YES
```

## AC22 — generation provenance

```text
PROVENANCE_ROW_PASS=4
PROVENANCE_ROW_FAIL=0
```

## AC23 — generation-copy control

```text
GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES
```

## AC24 — token schema integrity

```text
TOKEN_SCHEMA_DUPLICATES=0
WITNESS_KEYS_WITHOUT_SCHEMA=0
TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT=0
```

## AC25 — complete witness coverage

```text
WITNESS_FAIL=0
WITNESS_MISSING=0
```

## AC26 — witness-missing negative control

```text
WITNESS_MISSING_CONTROL_DETECTED=YES
```

## AC27 — witness-value negative control

```text
WITNESS_VALUE_CONTROL_DETECTED=YES
```

## AC28 — AC identity negative control

```text
AC_ID_SHUFFLE_DETECTED=YES
```

## AC29 — evidence SHA negative control

```text
EVIDENCE_SHA_MUTATION_DETECTED=YES
```

## AC30 — predicate lie negative control

```text
PREDICATE_LIE_DETECTED=YES
```

## AC31 — LEXER01 conservation

```text
LEXER01_CONSERVATION=PASS
```

## AC32 — LEXER02 conservation

```text
LEXER02_DIRECT_CONSERVATION=PASS
```

## AC33 — LEXER03 conservation

```text
LEXER03_CONSERVATION=PASS
```

## AC34 — broad-corpus delta

```text
LEXER07_NEW_FAILURES=0
LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS
```

## AC35 — F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

## AC36 — F-NO-PYTHON

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

## AC37 — F14

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

## AC38 — C2→C3 freeze

```text
C2_TO_C3_FROZEN=YES
```

## AC39 — C3 phase purity

```text
C3_PHASE_PURITY=PASS
```

## AC40 — Factory gates

```text
GATE_FAST=PASS
APPEND_ONLY_FAIL=0
```

## AC41 — prospective patch hygiene

```text
PATCH_HYGIENE_ERRORS=0
```

## AC42 — exact CORRECTION05 topology

```text
CORRECTION05_COMMIT_COUNT=5
C0_C1_C2_C3_C4_ORDER=YES
```

## AC43 — terminal clean worktree

```text
WORKTREE_CLEAN_AFTER_C4=YES
```

## AC44 — no post-C4 mutation

```text
POST_C4_COMMIT_COUNT=0
```

All AC01..AC44 are mandatory.

---

# 54. Witness contract

C1 SHALL create:

```text
c1-mandatory-ac-contract.tsv
c1-ac-witness-contract.tsv
c1-token-schema.tsv
c1-fixture-id-map.tsv
```

Every AC predicate receives:

```text
ac_id
predicate_sha256
```

Every witness receives:

```text
ac_id
witness_id
evidence_path
key
operator
expected_value
mandatory
```

---

# 55. Evidence SHA binding retained

C3 status rows:

```text
ac_id
predicate_sha256
status
evidence_path
evidence_sha256
```

Required:

```text
EVIDENCE_SHA_MISMATCH=0
```

---

# 56. AC status derivation

An AC is PASS iff:

```text
identity binding passes
AND
evidence SHA binding passes
AND
all mandatory witnesses pass
```

Required invariant:

```text
MANDATORY_WITNESS_FAIL_OR_MISSING
  =>
AC_STATUS=FAIL
```

The status TSV is not independent authority.

---

# 57. C2 implementation target

C2 closes only when developer verification establishes:

```text
N02_POLYC_RUNNER_BUILDS=YES
N02_SHELL_LOC<=50
N02_VALID_CHAIN=PASS

FIXTURE_CANONICALIZATION=PASS
FIXTURE_ALIAS_CONTROL=PASS

WITNESS_FAIL=0
WITNESS_MISSING=0

WITNESS_MISSING_CONTROL=PASS
WITNESS_VALUE_CONTROL=PASS

AC_ID_SHUFFLE_CONTROL=PASS
EVIDENCE_SHA_CONTROL=PASS
PREDICATE_LIE_CONTROL=PASS

PATCH_HYGIENE_ERRORS=0

PRODUCTION_SOURCE_DELTA=0
```

Then commit C2.

---

# 58. C2 freeze

At C2 freeze SHA-256 of:

```text
ACT body

AC contract
witness contract
token schema
fixture id map

all C2 tool sources
Makefile

src/lexer.c
src/lexer_bridge.h
selfhost-lexer-link.HC
```

Produce:

```text
c2-freeze.tsv
```

---

# 59. C3 entry

Required:

```text
C3_ENTRY_HEAD=C2_COMMIT
C3_ENTRY_WORKTREE_CLEAN=YES
```

C3 is evidence-only.

---

# 60. C3 phase purity

C3 SHALL NOT modify:

```text
src/**
tools/bootstrap/**
tools/quality/**
Makefile
scripts/**
ACT body
C1 contracts
```

If a repair is needed:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

No C3 fix commit.

---

# 61. C3 evidence tree

At minimum:

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/

c3-entry-identity.txt
c3-c2-freeze-replay.tsv

c3-correction04-disposition.txt
c3-f14-reverify.txt

c3-production-authority.txt
c3-production-source-delta.txt

c3-direct-differential.txt
c3-component-fixedpoint.txt

c3-generation-provenance.tsv
c3-generation-copy-control.txt

c3-semantic-postmigration.txt
c3-semantic-g0-delta.txt
c3-fixture-id-map-verify.txt
c3-fixture-alias-control.txt

c3-n01-output-mutation.txt
c3-n02-production-causal-control.txt
c3-n02-incomplete-witness.txt
c3-n02-shell-authority.txt

c3-token-schema-verify.txt
c3-witness-gap-result.tsv
c3-ac-witness-results.tsv

c3-witness-missing-control.txt
c3-witness-value-control.txt
c3-ac-id-shuffle.txt
c3-evidence-sha-mutation.txt
c3-predicate-lie-control.txt

c3-lexer01-conservation.txt
c3-lexer02-conservation.txt
c3-lexer03-conservation.txt
c3-broad-corpus-delta.txt

c3-f-polyc-tools.txt
c3-f-no-python.txt
c3-f14.txt

c3-factory-gates.txt
c3-append-only.txt
c3-patch-hygiene.txt
c3-phase-purity.txt

mandatory-ac-status.tsv
c3-required-result.txt
```

---

# 62. C3 expected AC state

At C3:

```text
AC01..AC41 = PASS

AC42 = DEFERRED_TO_C4
AC43 = DEFERRED_TO_C4
AC44 = DEFERRED_TO_C4
```

Required:

```text
AC_PASS=41
AC_FAIL=0
AC_DEFERRED=3
```

Any failure among AC01..AC41:

```text
HALT_MANDATORY_AC_NOT_GREEN
```

Do not enter C4.

---

# 63. C3 required result

```text
ACT=ACT-POLYC-SELFHOST-LEXER04-CORRECTION05

CORRECTION04_REVIEWED_VERDICT=HALT_MANDATORY_AC_NOT_GREEN
CORRECTION04_CONFIRMED_FAIL_COUNT=4
CORRECTION04_AC35=PASS

PRODUCTION_SOURCE_DELTA=0
PRODUCTION_AUTHORITY_VERIFY=PASS

DIRECT_DIFFERENTIAL_FAIL=0

COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0

POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0

EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07

UNKNOWN_FIXTURE_ALIAS=0
DUPLICATE_CANONICAL_ID=0

NON_MIGRATION_G0_DIVERGENCE_COUNT=0
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0

L07_G0=lib-complex_1co
L07_G1=lib-complex_1.0
L07_G2=lib-complex_1.0
L07_G3=lib-complex_1.0

N02_ORCHESTRATION_AUTHORITY=POLYC
N02_SHELL_DISPATCH_ONLY=YES
N02_SHELL_LOC<=50

MUTATED_COMPONENT_BUILD_RC=0
MUTATED_SEAM_LINK_RC=0
MUTATED_SEAM_RUN_RC=0

MUTATED_COMPONENT_SHA_NONEMPTY=YES
MUTATED_COMPONENT_SHA_DIFFERS=YES
MUTATED_SEAM_SHA_NONEMPTY=YES

MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES
UNEXPECTED_MUTATION_DIVERGENCE_COUNT=0
N02_INCOMPLETE_WITNESS_REJECTED=YES

PROVENANCE_ROW_PASS=4
PROVENANCE_ROW_FAIL=0

GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES

TOKEN_SCHEMA_DUPLICATES=0
WITNESS_KEYS_WITHOUT_SCHEMA=0
TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT=0

WITNESS_FAIL=0
WITNESS_MISSING=0

WITNESS_MISSING_CONTROL_DETECTED=YES
WITNESS_VALUE_CONTROL_DETECTED=YES
AC_ID_SHUFFLE_DETECTED=YES
EVIDENCE_SHA_MUTATION_DETECTED=YES
PREDICATE_LIE_DETECTED=YES

LEXER01_CONSERVATION=PASS
LEXER02_DIRECT_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS

LEXER07_NEW_FAILURES=0
LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

C2_TO_C3_FROZEN=YES
C3_PHASE_PURITY=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

AC_TOTAL=44
AC_PASS=41
AC_FAIL=0
AC_DEFERRED=3
```

---

# 64. C4 preparation

Before creating C4 artifacts:

```sh
git status --short
git diff --check "$CORRECTION05_ENTRY_HEAD"..HEAD
```

Required:

```text
C4_PREP_WORKTREE_CLEAN=YES
C4_PREP_PATCH_HYGIENE_ERRORS=0
```

If not:

```text
HALT_C4_PRECONDITION
```

Do not create C4.

---

# 65. C4 artifact scope

C4 may add only:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION05.md

evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c4/
  c4-parent-identity.txt
  c4-terminal-ledger.txt
```

No C3 evidence edits.

No tool edits.

No Makefile edits.

No ACT-body edits.

---

# 66. C4 identity

HANDOFF records:

```text
C4_PARENT_SHA=<C3 commit>
C4_IDENTITY=COMMIT_CONTAINING_THIS_HANDOFF
```

Do not record fictional self-SHA.

No SHA-fill commit.

---

# 67. AC42 terminal topology

After C4:

```sh
git rev-list --count "$CORRECTION05_ENTRY_HEAD"..HEAD
```

Required:

```text
CORRECTION05_COMMIT_COUNT=5
```

Verify:

```text
C0_C1_C2_C3_C4_ORDER=YES
```

---

# 68. AC43 terminal worktree

Immediately after C4:

```text
WORKTREE_CLEAN_AFTER_C4=YES
```

If not clean:

```text
HALT_TERMINAL_WORKTREE_DIRTY
```

Do not commit cleanup.

---

# 69. AC44 no post-C4 mutation

Repository-side C4 records:

```text
POST_C4_MUTATION_AUTHORIZED=NO
```

External terminal/reviewer observation establishes:

```text
POST_C4_COMMIT_COUNT=0
```

No backfill commit.

---

# 70. Final AC state

Successful terminal:

```text
AC_TOTAL=44
AC_PASS=44
AC_FAIL=0
AC_DEFERRED=0
```

---

# 71. PASS_TRUE_GREEN predicate

`PASS_TRUE_GREEN` requires all of:

```text
C0_AUTH_BEFORE_WORK=YES

CORRECTION04_HALT_REPRODUCED=YES
CORRECTION04_CONFIRMED_FAIL_COUNT=4
CORRECTION04_AC35=PASS

PRODUCTION_SOURCE_DELTA=0
PRODUCTION_AUTHORITY_VERIFY=PASS

DIRECT_DIFFERENTIAL_FAIL=0

COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0

POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0

EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07

UNKNOWN_FIXTURE_ALIAS=0
DUPLICATE_CANONICAL_ID=0

NON_MIGRATION_G0_DIVERGENCE_COUNT=0
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0

N02_ORCHESTRATION_AUTHORITY=POLYC
N02_SHELL_DISPATCH_ONLY=YES
N02_SHELL_LOC<=50

MUTATED_COMPONENT_BUILD_RC=0
MUTATED_SEAM_LINK_RC=0
MUTATED_SEAM_RUN_RC=0
MUTATED_COMPONENT_SHA_NONEMPTY=YES
MUTATED_COMPONENT_SHA_DIFFERS=YES
MUTATED_SEAM_SHA_NONEMPTY=YES
MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES
UNEXPECTED_MUTATION_DIVERGENCE_COUNT=0

N02_INCOMPLETE_WITNESS_REJECTED=YES

PROVENANCE_ROW_PASS=4
PROVENANCE_ROW_FAIL=0
GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES

TOKEN_SCHEMA_DUPLICATES=0
WITNESS_KEYS_WITHOUT_SCHEMA=0
TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT=0

WITNESS_FAIL=0
WITNESS_MISSING=0

WITNESS_MISSING_CONTROL_DETECTED=YES
WITNESS_VALUE_CONTROL_DETECTED=YES
AC_ID_SHUFFLE_DETECTED=YES
EVIDENCE_SHA_MUTATION_DETECTED=YES
PREDICATE_LIE_DETECTED=YES

LEXER01_CONSERVATION=PASS
LEXER02_DIRECT_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS

LEXER07_NEW_FAILURES=0
LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

C2_TO_C3_FROZEN=YES
C3_PHASE_PURITY=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

CORRECTION05_COMMIT_COUNT=5
WORKTREE_CLEAN_AFTER_C4=YES
POST_C4_COMMIT_COUNT=0

AC_TOTAL=44
AC_PASS=44
AC_FAIL=0
AC_DEFERRED=0
```

Anything weaker:

```text
HALT
```

---

# 72. HALT taxonomy

```text
HALT_ENTRY_DIRTY
HALT_ENTRY_IDENTITY_DRIFT

HALT_AUTHORIZATION_ARTIFACT_INCOMPLETE

HALT_CORRECTION04_RECLASSIFICATION_MISMATCH
HALT_F14_REVERIFY_MISMATCH

HALT_PRODUCTION_DEFECT_DISCOVERED
HALT_PRODUCTION_AUTHORITY_REGRESSION

HALT_DIRECT_DIFFERENTIAL
HALT_COMPONENT_FIXEDPOINT
HALT_MIGRATION_SEMANTICS

HALT_FIXTURE_ID_SCHEMA
HALT_FIXTURE_ALIAS_CONTROL

HALT_N02_CONFIG_TRANSPORT
HALT_N02_POLYC_BUILD
HALT_N02_MUTATION_BUILD
HALT_N02_MUTATION_LINK
HALT_N02_MUTATION_RUN
HALT_N02_ARTIFACT_IDENTITY
HALT_N02_CAUSAL_CONTROL
HALT_N02_INCOMPLETE_WITNESS

HALT_GENERATION_PROVENANCE
HALT_GENERATION_COPY_CONTROL

HALT_TOKEN_SCHEMA
HALT_WITNESS_CONTRACT_SEMANTIC_CHANGE_REQUIRED
HALT_WITNESS_COVERAGE
HALT_WITNESS_MISSING_CONTROL
HALT_WITNESS_VALUE_CONTROL

HALT_AC_ID_SHUFFLE_CONTROL
HALT_EVIDENCE_SHA_CONTROL
HALT_PREDICATE_LIE_CONTROL

HALT_LEXER01_CONSERVATION
HALT_LEXER02_CONSERVATION
HALT_LEXER03_CONSERVATION
HALT_BROAD_CORPUS_NEW_REGRESSION

HALT_F_POLYC_TOOLS
HALT_F_NO_PYTHON
HALT_F14_VIOLATION

HALT_C2_TO_C3_DRIFT
HALT_C2_DEFECT_FOUND_DURING_C3
HALT_C3_PHASE_PURITY

HALT_FACTORY_GATE
HALT_APPEND_ONLY
HALT_PATCH_HYGIENE

HALT_MANDATORY_AC_NOT_GREEN

HALT_C4_PRECONDITION
HALT_TERMINAL_WORKTREE_DIRTY
HALT_PHASE_CORRECTION_REQUIRED
```

A HALT is a successful Factory outcome when the predicate is genuinely red.

---

# 73. Commit trailer discipline

Use only phase/verdict tokens accepted by the current Factory checker.

Semantic phases:

```text
C0 AUTH
C1 RED
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

Only C4 may carry:

```text
ACT-Verdict: PASS_TRUE_GREEN
```

and only if AC01..AC44 are terminal PASS.

---

# 74. C4 HANDOFF sections

Required:

```text
VERDICT
IDENTITY
PREDECESSOR DISPOSITION
MISSION
SCOPE
PRODUCTION IMMUTABILITY
FIXTURE CANONICALIZATION
N02 POLYC AUTHORITY
N02 CAUSAL CONTROL
GENERATION COPY CONTROL
TOKEN SCHEMA
WITNESS COVERAGE
AC TRUTH BINDING
CONSERVATION
F-POLYC-TOOLS
F-NO-PYTHON
F14
FACTORY GATES
PATCH HYGIENE
COMMIT TOPOLOGY
RESIDUE
NEXT
```

---

# 75. Meaning of successful close

A PASS proves:

```text
CORRECTION04's production qualification advances were valid,
but its qualification infrastructure was incomplete.

The LEXER04 migration fixture has one canonical machine identity: L07.

Every mandatory predicate witness is present and passes.

No status row can greenwash a missing or contradictory witness.

N02 mutation/build/link/run orchestration is substantive PolyC code,
not a shell application hidden behind the LOC cap.

The <=50 LOC shell wrapper is dispatch-only.

The production source is unchanged from the already-migrated
CORRECTION03/CORRECTION04 substrate.

The causal N02 mutation remains genuinely load-bearing.

The forged-generation negative control remains load-bearing.

All evidence introduced by CORRECTION05 is whitespace-clean over the
full prospective range.

LEXER04 qualification machinery and production migration are both
TRUE_GREEN.
```

---

# 76. Board effect on PASS

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION03
  = FALSE_GREEN / HALT_MULTIPLE_BINDING_PREDICATES

ACT-POLYC-SELFHOST-LEXER04-CORRECTION04
  = HALT_MANDATORY_AC_NOT_GREEN

ACT-POLYC-SELFHOST-LEXER04-CORRECTION04-CORRECTION01
  = historical additive reviewer re-verification

ACT-POLYC-SELFHOST-LEXER04-CORRECTION05
  = CLOSED PASS_TRUE_GREEN

LEXER04_PRODUCTION_AUTHORITY
  = TRUE_GREEN

LEXER04_QUALIFICATION
  = TRUE_GREEN

LEXER04_PRODUCTION_MIGRATION
  = COMPLETE
```

Then:

```text
NEXT = ACT-POLYC-SELFHOST-SURFACE-RECON03
```

Do not pick LEXER05 merely by numbering.

---

# 77. Residue not blocking CORRECTION05

Independent:

```text
ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
```

Historical LEXER07 broad-corpus failures remain tracked by baseline/delta.

No requirement to repair those failures unless CORRECTION05 introduces a
new one.

---

# 78. Execution order

## C0 AUTH

Commit this full ACT first.

## C1 RED / CONTRACT

Mechanically establish:

```text
four CORRECTION04 failures
AC35/F14 PASS
historical arithmetic mismatch
fixture canonical-id map
23 witness gaps
token schema
N02 authority defect
broad-corpus baseline
44-AC contract
witness contract
```

No implementation.

## C2 IMPL

Move N02 substantive orchestration into PolyC.

Canonicalize fixture identities through data/schema.

Reconcile every witness producer/consumer token.

Add negative controls.

No production mutation.

Developer-run full qualification.

Commit once.

## C3 VERIFY

Fresh committed-C2 evidence only.

If any implementation repair is required:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

Do not patch.

## C4 CLOSE

Only HANDOFF + terminal evidence.

Exactly one C4 commit.

No later commit.

---

# 79. First C0 commands

```sh
git status --short
git branch --show-current
git rev-parse HEAD
git merge-base --is-ancestor 87106d6 HEAD
```

Record verbatim.

Then:

```sh
git diff --check "$(git rev-parse HEAD)"..HEAD
```

which should be empty at entry.

Freeze that HEAD.

---

# 80. First C1 commands

Reproduce the blockers mechanically:

```sh
grep -n "OBSERVED_MIGRATION_FIXTURE_SET" \
  evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c3/*

grep -n "WITNESS_TOTAL\|WITNESS_FAIL\|WITNESS_MISSING" \
  evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c3/*

wc -l scripts/quality/lexer09-n02-mutation-runner.sh

git diff --check <CORRECTION04_ENTRY_HEAD>..<CORRECTION04_C4_HEAD>
```

Then mechanically re-run F14 comparison.

Do not start implementation until C1's defect inventory and contracts are
committed.

---

# 81. Governing principle

CORRECTION05 exists because the previous qualification machinery became
much stronger but still allowed three kinds of drift:

```text
identity naming drift
producer/consumer token drift
implementation-authority drift
```

The intended final invariant is:

```text
one semantic fact
  ->
one canonical token
  ->
one machine-produced evidence value
  ->
one immutable evidence hash
  ->
one witness comparison
  ->
one AC status
```

No prose promotion exists between those stages.

For the shell-authority problem:

```text
substantive behavior belongs in PolyC
dispatch glue may remain shell
```

For patch hygiene:

```text
historical bad evidence remains historical
new evidence must be clean when first committed
```

For closure:

```text
five commits means five commits
```

If those invariants hold, close TRUE_GREEN.

If any do not, HALT with the exact failing predicate.
