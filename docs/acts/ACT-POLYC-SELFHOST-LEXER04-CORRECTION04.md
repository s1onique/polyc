# ACT-POLYC-SELFHOST-LEXER04-CORRECTION04

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Requalify the load-bearing `BootstrapLinkDirective` production migration with valid causal controls, truthful migration semantics, predicate-bound AC evidence, and a clean terminal lifecycle

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / LEXER / PRODUCTION-QUALIFICATION / CORRECTION

**Priority:** P0

---

# 0. Mission

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION03` performed substantial production work:

```text
BootstrapLinkDirective ABI 5 -> ABI 6
src/lexer.c::lexLink consumes PolyC output
legacy duplicate target reconstruction removed from self-host path
lib-complex_1.0 preserved by G1/G2/G3
G1/G2/G3 built and executed independently
component fixed point proven
```

However CORRECTION03 did **not** earn `PASS_TRUE_GREEN`.

Its truthful terminal classification is:

```text
CORRECTION03_RECORDED_HANDOFF_VERDICT = PASS_TRUE_GREEN
CORRECTION03_REVIEWED_VERDICT         = FALSE_GREEN
CORRECTION03_TERMINAL_CLASS           = HALT_MULTIPLE_BINDING_PREDICATES
CORRECTION03_COMMIT_COUNT             = 6
```

Binding defects:

```text
D1  AC13 N02 causal subject mutation was invalid:
      mutated object build failed
      mutated object SHA was empty
      mutated seam binary did not exist
      evidence nevertheless claimed PASS

D2  AC19 generation-copy negative control was not executed:
      GENERATION_COPY_DETECTED=NO
      evidence nevertheless claimed PASS

D3  AC20 contract demanded:
      SEMANTIC_PAIR_PASS=6
    while the intended migration necessarily produces:
      G0 != G1/G2/G3 on L07
      G1 == G2 == G3

D4  AC truth ledger verified identity binding only:
      ac_id + predicate_sha256
    but did not verify that evidence established the predicate.

D5  AC35 patch hygiene was false before C4:
      range-wide git diff --check reported evidence whitespace errors.

D6  AC36 exact topology failed at final HEAD:
      6 commits instead of 5.

D7  AC38 post-C4 commit count failed:
      one commit followed the first C4.

D8  CORRECTION03's committed authorization artifact is incomplete:
      it is a synopsis referring to the prompt/commit body rather than
      containing the full binding authorization contract.

D9  CORRECTION03 C3 authority-flow evidence is stale:
      it still describes the pre-C2 shadow-verifier architecture instead
      of mechanically proving the post-C2 production-authority state.

D10 Several conservation artifacts are narrative assertions rather than
    captured command/verifier results.
```

This ACT SHALL **not undo CORRECTION03 production work**.

Its principal task is:

> qualify the already-implemented production migration honestly.

Production mutation is forbidden by default.

If fresh qualification discovers a genuine production defect:

```text
HALT_PRODUCTION_DEFECT_DISCOVERED
```

Do not silently repair production in this ACT.

---

# 1. Terminal target

Successful closure requires:

```text
CORRECTION03_REVIEWED_VERDICT              = FALSE_GREEN
CORRECTION03_HISTORY_IMMUTABLE              = YES

LEXER04_POLYC_ROLE                          = PRODUCTION_AUTHORITY
LEXER04_PRODUCTION_AUTHORITY_REPROVEN       = YES
LEXER04_DUPLICATE_SELFHOST_PARSE            = 0

LIB_COMPLEX_G0                              = lib-complex_1co
LIB_COMPLEX_G1                              = lib-complex_1.0
LIB_COMPLEX_G2                              = lib-complex_1.0
LIB_COMPLEX_G3                              = lib-complex_1.0

POST_MIGRATION_PAIR_PASS                    = 3
POST_MIGRATION_PAIR_FAIL                    = 0

EXPECTED_G0_MIGRATION_FIXTURE_COUNT         = 1
UNEXPECTED_G0_MIGRATION_FIXTURE_COUNT       = 0
NON_MIGRATION_G0_DIVERGENCE_COUNT           = 0

N02_MUTATED_COMPONENT_BUILD_RC              = 0
N02_MUTATED_SEAM_LINK_RC                    = 0
N02_MUTATED_SEAM_RUN_RC                     = 0
N02_MUTATED_COMPONENT_SHA_DIFFERS           = YES
N02_MUTATED_SEAM_SHA_PRESENT                = YES
N02_PRODUCTION_DIVERGENCE_DETECTED          = YES

GENERATION_COPY_CONTROL_EXECUTED             = YES
GENERATION_COPY_DETECTED                     = YES
GENERATION_COPY_VERIFIER_RC_NONZERO          = YES

AC_CONTRACT_IDENTITY_BINDING                 = PASS
AC_EVIDENCE_IDENTITY_BINDING                 = PASS
AC_PREDICATE_WITNESS_BINDING                 = PASS

PATCH_HYGIENE                                = PASS
CORRECTION04_COMMIT_COUNT                    = 5
POST_C4_COMMIT_COUNT                         = 0

LEXER04_PRODUCTION_MIGRATION                 = COMPLETE
CORRECTION04_VERDICT                         = PASS_TRUE_GREEN
```

---

# 2. Historical facts are immutable

CORRECTION04 SHALL NOT attempt to make CORRECTION03 green.

Freeze:

```text
CORRECTION03_ENTRY_HEAD = 4814bf1cd67791daec64fb9f5d592e64327ee0db
CORRECTION03_FINAL_HEAD = 0d26e41ea8ba1302fd610db732d900bd218b0569
CORRECTION03_COMMIT_COUNT = 6
```

Bind the complete actual SHA mechanically at C0.

The following remain historical failures:

```text
CORRECTION03_AC13 = FAIL
CORRECTION03_AC19 = FAIL
CORRECTION03_AC20 = FAIL
CORRECTION03_AC35 = FAIL
CORRECTION03_AC36 = FAIL
CORRECTION03_AC38 = FAIL
```

CORRECTION04 SHALL NOT:

```text
rewrite CORRECTION03 evidence
rewrite CORRECTION03 HANDOFF
rewrite CORRECTION03 ACT body
delete 0d26e41
squash history
reset/recommit
amend
rebase
force-push
invent a five-commit CORRECTION03 history
```

---

# 3. Engineering substrate accepted provisionally

The following CORRECTION03 implementation is **retained but not blindly trusted**:

```text
src/lexer.c
src/lexer_bridge.h
tools/bootstrap/selfhost-lexer-link.HC
Makefile four-generation seam targets
tools/quality/lexer09-4stage-semantic-verify.HC
tools/quality/lexer09-ac-ledger-verify.HC
existing seam/oracle maintenance
```

C1/C3 SHALL freshly verify its behavior.

No terminal PASS may rely solely on CORRECTION03 prose.

---

# 4. Entry identity

Expected current parent:

```text
0d26e41...
```

but bind actual HEAD mechanically.

Run:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git merge-base --is-ancestor 0d26e41 HEAD
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN_AT_C0=YES
CORRECTION03_FINAL_IS_ANCESTOR=YES
```

Freeze:

```text
CORRECTION04_ENTRY_HEAD=<actual HEAD>
PATCH_HYGIENE_BASELINE=<same HEAD>
```

If dirty:

```text
HALT_ENTRY_DIRTY
```

Do not clean unrelated work automatically.

---

# 5. Authorization artifact integrity

Unlike CORRECTION03, this file itself is the complete authorization artifact.

Required C0 check:

```text
ACT_BODY_CONTAINS_FULL_CONTRACT=YES
ACT_BODY_PLACEHOLDER_SECTIONS=0
ACT_BODY_EXTERNAL_PROMPT_DEPENDENCY=0
```

Forbidden phrases as contract substitution:

```text
"see prompt"
"see commit body"
"full ACT omitted"
"matches user-provided spec"
```

The Git blob committed at C0 is authoritative.

---

# 6. Allowed scope

## 6.1 Default permitted modifications

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION04.md

tools/quality/lexer09-ac-ledger-verify.HC
tools/quality/lexer09-ac-witness-verify.HC         optional new PolyC tool
tools/quality/lexer09-generation-provenance-verify.HC optional PolyC tool
tools/quality/lexer09-4stage-semantic-verify.HC    qualification-only changes

Makefile                                           qualification targets only

scripts/quality/lexer09-*.sh                       <=50 LOC dispatch only

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION04.md

evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/**
```

## 6.2 Production files are read-only

```text
src/lexer.c
src/lexer_bridge.h
tools/bootstrap/selfhost-lexer-link.HC
```

Required:

```text
PRODUCTION_SOURCE_DELTA=0
```

If fresh evidence finds an actual defect in these files:

```text
HALT_PRODUCTION_DEFECT_DISCOVERED
```

A later production ACT may repair it.

## 6.3 Forbidden unrelated scope

```text
lexInclude
parser migration
JIT
LLVM
AArch64 asm parser
libtos
Factory closure oracle
old evidence trees
old HANDOFFs
```

---

# 7. Commit topology

Exactly five commits:

```text
C0 AUTH
# 8. C0 artifacts

Commit before any C1/C2 work:

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION04.md

evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c0/
  c0-entry-identity.txt
  c0-scope.txt
  c0-predecessor-reclassification.txt
  c0-authorization-integrity.txt
```

Required:

```text
C0_AUTH_BEFORE_WORK=YES
```

---

# 9. Patch-hygiene rule

The authoritative prospective range is:

```text
CORRECTION04_ENTRY_HEAD..HEAD
```

At every phase:

```sh
git diff --check "$CORRECTION04_ENTRY_HEAD"..HEAD
```

Required:

```text
PATCH_HYGIENE_ERRORS=0
```

There is no evidence-file exemption.

Do not use:

```text
--diff-filter=M
```

to narrow the binding predicate.

Do not exclude:

```text
evidence/**
```

Historical CORRECTION03 whitespace is outside the prospective range and
therefore does not block CORRECTION04.

---

# 10. C1 -- reproduce CORRECTION03 failures

Produce:

```text
c1-correction03-defects.tsv
```

Columns:

```text
defect_id
authorized_predicate
historical_expected
historical_observed
historical_evidence
corr04_disposition
```

Required rows D1..D10 from §0.

Required:

```text
CORRECTION03_FALSE_GREEN_REPRODUCED=YES
```

---

# 11. C1 -- production-authority recon

Freshly inspect the committed production code.

Produce:

```text
c1-production-authority.tsv
```

Columns:

```text
responsibility
production_source
owner
polyC_output_used
legacy_duplicate_parse
mechanical_evidence
```

At minimum verify:

```text
target form
target bytes
target length
path/library classification
consumed length
error result
cursor advance
AoStr construction
link_libs insertion
shared_object_files insertion
duplicate suppression
```

Required:

```text
POLYC_OUTPUTS_CONSUMED_BY_PRODUCTION=YES
SELFHOST_DUPLICATE_TARGET_PARSE=0
```

Do not copy CORRECTION03 C1 authority-flow.

This is a post-implementation measurement.

---

# 12. Production-authority mechanical verifier

C1 SHALL identify machine-checkable source predicates for §11.

Prefer a PolyC source-inspection verifier if one already exists.

Otherwise C2 MAY add:

```text
tools/quality/lexer09-production-authority-verify.HC
```

It must check concrete syntax/AST-independent invariants such as:
# 15. Post-migration equivalence contract

For every fixture:

```text
normalize(G1) == normalize(G2)
normalize(G1) == normalize(G3)
normalize(G2) == normalize(G3)
```

Required:

```text
POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0
POLYC_FIXTURE_DIVERGENCE_COUNT=0
```

---

# 16. Legacy conservation contract

For every fixture except `L07`:

```text
normalize(G0) == normalize(G1)
normalize(G0) == normalize(G2)
normalize(G0) == normalize(G3)
```

Required:

```text
NON_MIGRATION_G0_DIVERGENCE_COUNT=0
```

For L07:

```text
G0_MIGRATION_EXPECTED=YES
G0_MIGRATION_ACTUAL=YES
```

Required total:

```text
G0_EXPECTED_MIGRATION_PAIR_COUNT=3
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0
```

---

# 17. Four-generation execution remains independently required

For G0..G3 record:

```text
compiler path
compiler SHA-256
component object path
component object SHA-256
seam binary path
seam binary SHA-256
run receipt path
raw output SHA-256
normalized output SHA-256
build RC
link RC
run RC
```

Required:

```text
GENERATION_ROWS=4
GENERATION_BUILD_FAIL=0
GENERATION_LINK_FAIL=0
GENERATION_RUN_FAIL=0
```

G1/G2/G3 seam-binary SHAs need not be equal.

They SHALL be genuinely independently produced.

---

# 18. Provenance binding

Produce:

```text
c3-stage-provenance.tsv
```

and an authoritative PolyC verifier.

For every generation recompute and validate:

```text
expected compiler SHA == actual compiler SHA
recorded seam SHA == actual seam SHA
recorded raw-output SHA == actual raw-output SHA
generation identity == expected row
```

Required:

```text
PROVENANCE_ROW_PASS=4
PROVENANCE_ROW_FAIL=0
```

---

# 19. NC-GENERATION-COPY -- actual control

CORRECTION04 SHALL execute the control that CORRECTION03 omitted.

Procedure:

```text
1. Preserve genuine G3 raw output.
2. Copy G1 raw output to a TEMPORARY path pretending to be G3 payload.
3. Retain expected G3 provenance identity and expected G3 execution binding.
4. Run provenance verifier on the forged tuple.
5. Require rejection.
6. Restore/use untouched genuine G3 artifact.
```

Never overwrite committed historical evidence.

Required:

```text
GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES
```

Forbidden substitute:

```text
"G1/G3 SHAs already differ, therefore no copy occurred"
```

Independence observation is not the negative control.

---

# 20. NC-GENERATION-COPY causal reason

The control proves:

```text
semantic equality cannot hide artifact substitution.
```

# 22. N02 mutation class

Use a semantic mutation, not a build-destruction mutation.

Preferred target:

```text
fixture = L07
```

Choose at C1 exactly one mutation from:

```text
A. Change one deterministic byte written to out_target_bytes.

B. Reduce out_target_len by exactly one while preserving successful status.

C. Substitute a deterministic target byte sequence of equal length.
```

Avoid cursor mutation as the primary control because it may conflate:

```text
semantic authority
parser desynchronization
crash behavior
```

Freeze:

```text
N02_MUTATION_KIND=<A|B|C>
N02_MUTATION_EXPECTED_FIELD=link_libs
N02_MUTATION_EXPECTED_FIXTURE=L07
```

before execution.

---

# 23. N02 mutation must use a temporary source

Do not edit and restore the tracked production subject in place.

Create:

```text
build/tmp/lexer04-correction04/
```

or another ignored temporary directory.

Procedure:

```text
copy pristine selfhost-lexer-link.HC
apply deterministic mutation to temporary copy
compile temporary copy
link seam against temporary object
execute temporary seam
```

Required:

```text
TRACKED_SUBJECT_MUTATED_DURING_N02=NO
```

---

# 24. N02 evidence

Produce:

```text
c3-n02-production-causal-control.txt
```

Required machine-readable tokens:

```text
N02_MUTATION_KIND=<...>

PRISTINE_SOURCE_SHA256=<64 hex>
MUTATED_SOURCE_SHA256=<64 hex>
SOURCE_SHA_DIFFERS=YES

PRISTINE_COMPONENT_SHA256=<64 hex>
MUTATED_COMPONENT_SHA256=<64 hex>
COMPONENT_SHA_DIFFERS=YES

MUTATED_COMPONENT_BUILD_RC=0

MUTATED_SEAM_SHA256=<64 hex>
MUTATED_SEAM_LINK_RC=0
MUTATED_SEAM_RUN_RC=0

EXPECTED_DIVERGENCE_FIXTURE=L07
EXPECTED_DIVERGENCE_FIELD=link_libs

MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES
UNEXPECTED_MUTATION_DIVERGENCE_COUNT=0

PRISTINE_REVERIFY_RC=0

N02_OUTCOME=PASS
```

Empty SHA values are an automatic failure.

---

# 25. N02 verifier

The witness verifier SHALL reject:

```text
empty SHA
missing artifact
build RC != 0
link RC != 0
run RC != 0
no semantic difference
difference on wrong fixture
difference on wrong field only
unexpected additional fixture differences
```

Required negative selftest:

remove the mutated object SHA from a temporary witness.

Expected:

```text
N02_INCOMPLETE_WITNESS_REJECTED=YES
```

This directly guards the CORRECTION03 defect.

---

# 26. N01 retained

Freshly run existing output-mutation verifier control.

Required:
# 28. AC truth architecture

CORRECTION04 replaces:

```text
"status TSV says PASS"
```

with three independent bindings:

```text
1. CONTRACT BINDING
   ac_id + predicate_sha256

2. EVIDENCE BINDING
   exact evidence path + evidence SHA-256

3. PREDICATE WITNESS BINDING
   machine-readable values extracted from evidence and compared to
   expected operators/values
```

Terminal PASS requires all three.

---

# 29. AC contract file

C1 produces:

```text
c1-mandatory-ac-contract.tsv
```

Columns:

```text
ac_id
exact_predicate
predicate_sha256
mandatory
phase
```

No row-order semantics.

---

# 30. Witness contract file

C1 produces:

```text
c1-ac-witness-contract.tsv
```

Columns:

```text
ac_id
witness_id
evidence_path
witness_kind
key
operator
expected_value
mandatory
```

Supported generic `witness_kind`:

```text
KV
FILE_EXISTS
FILE_SHA256
NONEMPTY
INTEGER
```

Supported operators:

```text
EQ
NE
GT
GE
LT
LE
MATCH_HEX64
```

No AC-specific code branches unless genuinely unavoidable and explicitly
authorized before C2.

---

# 31. Evidence format

Authoritative evidence files used by the witness checker must expose
canonical machine-readable tokens:

```text
KEY=value
```

one per line.

Human prose may follow but is non-authoritative.

No token may be derived by manually typing the expected answer when a
machine can compute it.

---

# 32. Evidence SHA binding

C3 produces:

```text
mandatory-ac-status.tsv
```

Columns:

```text
ac_id
predicate_sha256
status
evidence_path
evidence_sha256
```

The verifier SHALL recompute every `evidence_sha256`.

Required:

```text
EVIDENCE_SHA_MISMATCH=0
```

---

# 33. Witness result file

Verifier outputs:

```text
ac-witness-results.tsv
```

# 35. Ledger negative controls

## NC-AC-ID-SHUFFLE

Swap an AC identity/predicate binding.

Required:

```text
AC_ID_SHUFFLE_DETECTED=YES
```

## NC-EVIDENCE-SHA

Modify a temporary evidence byte without updating recorded SHA.

Required:

```text
EVIDENCE_SHA_MUTATION_DETECTED=YES
```

## NC-PREDICATE-LIE

Create a temporary status row saying PASS while its evidence says, for
example:

```text
GENERATION_COPY_DETECTED=NO
```

Expected:

```text
PREDICATE_LIE_DETECTED=YES
VERIFIER_RC_NONZERO=YES
```

This is the direct regression control for CORRECTION03.

---

# 36. C2 qualification-tool scope

C2 may implement/modify only qualification machinery necessary for:

```text
production authority inspection
generation provenance
generation-copy detection
AC evidence hash binding
generic witness verification
correct post-migration semantic comparison
```

C2 must not change production behavior.

Required:

```text
PRODUCTION_SOURCE_DELTA=0
```

---

# 37. Correct semantic verifier output

The semantic verifier shall report separately:

```text
POST_MIGRATION_PAIR_PASS
POST_MIGRATION_PAIR_FAIL

G0_EXPECTED_MIGRATION_PAIR_COUNT
G0_UNEXPECTED_MIGRATION_PAIR_COUNT

NON_MIGRATION_G0_DIVERGENCE_COUNT

EXPECTED_MIGRATION_FIXTURE_COUNT
OBSERVED_MIGRATION_FIXTURE_COUNT
EXPECTED_MIGRATION_FIXTURE_SET
OBSERVED_MIGRATION_FIXTURE_SET
```

Do not report:

```text
SEMANTIC_PAIR_PASS=6
```

unless six equality relations are actually required and true.

---

# 38. Expected semantic terminal values

Required:

```text
POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0

EXPECTED_MIGRATION_FIXTURE_COUNT=1
OBSERVED_MIGRATION_FIXTURE_COUNT=1

EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07

G0_EXPECTED_MIGRATION_PAIR_COUNT=3
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0

NON_MIGRATION_G0_DIVERGENCE_COUNT=0
```

---

# 39. L07 required values

Required:

```text
L07_G0=lib-complex_1co
L07_G1=lib-complex_1.0
L07_G2=lib-complex_1.0
L07_G3=lib-complex_1.0
```

Any other result:

```text
HALT_MIGRATION_SEMANTICS
```

---

Columns:

```text
ac_id
witness_id
observed_value
operator
expected_value
result
```

Required:

```text
WITNESS_TOTAL=<frozen count>
# 40. Production-authority terminal proof

Fresh C3 evidence must establish:

```text
POLYC_OUTPUTS_CONSUMED_BY_PRODUCTION=YES
SELFHOST_DUPLICATE_TARGET_PARSE=0
```

and must represent the **post-C2/CORRECTION03 implementation**, not C1 RED.

If C3 authority-flow still describes:

```text
component called but output discarded
legacy target bytes still used
```

then:

```text
HALT_STALE_EVIDENCE
```

---

# 41. Direct differential

Run freshly.

Historical expected count:

```text
23/23
```

Bind actual.

Required:

```text
DIRECT_DIFFERENTIAL_FAIL=0
```

---

# 42. Component fixed point

Freshly build four component objects and compare all six pairs.

Required:

```text
COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0
```

---

# 43. Generation execution

Freshly build/run:

```text
G0 ./hcc
G1 ./build/hcc-bootstrap02
G2 ./build/hcc-bootstrap03
G3 ./build/hcc-bootstrap04
```

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

# 44. Broad-corpus baseline

Historical frozen LEXER07 baseline:

```text
REGRESSION=6
```

C1 SHALL freshly confirm the current entry baseline.

Freeze actual:

```text
LEXER07_ENTRY_REGRESSION=<n>
LEXER07_ENTRY_FAILURE_SET=<exact set>
```

---

# 45. Broad-corpus prospective condition

At C3:

```text
LEXER07_POST_REGRESSION <= LEXER07_ENTRY_REGRESSION
LEXER07_NEW_FAILURES=0

LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS
```

Required:

```text
BROAD_CORPUS_DELTA=NO_REGRESSION
```

---

# 46. LEXER01 conservation must be executed

Do not write only:

```text
"unrelated, therefore unaffected"
```

Run the canonical command/test.

Capture stdout/stderr + RC.

Required:

```text
LEXER01_CONSERVATION_RC=0
LEXER01_CONSERVATION=PASS
```

Bind current fixture count.

---

# 54. C1 AC contract

CORRECTION04 defines the following mandatory ACs.

## AC01 -- authorized clean entry

```text
C0_AUTH_BEFORE_WORK=YES
WORKTREE_CLEAN_AT_C0=YES
```

## AC02 -- complete authorization artifact

```text
ACT_BODY_CONTAINS_FULL_CONTRACT=YES
ACT_BODY_PLACEHOLDER_SECTIONS=0
```

## AC03 -- CORRECTION03 truthful reclassification

```text
CORRECTION03_FALSE_GREEN_REPRODUCED=YES
CORRECTION03_COMMIT_COUNT=6
```

## AC04 -- historical immutability

```text
CORRECTION03_HISTORY_IMMUTABLE=YES
```

## AC05 -- production source unchanged

```text
PRODUCTION_SOURCE_DELTA=0
```

## AC06 -- production authority

```text
POLYC_OUTPUTS_CONSUMED_BY_PRODUCTION=YES
```

## AC07 -- duplicate selfhost target parser retired

```text
SELFHOST_DUPLICATE_TARGET_PARSE=0
```

## AC08 -- authority verifier

```text
PRODUCTION_AUTHORITY_VERIFY=PASS
```

## AC09 -- direct differential

```text
DIRECT_DIFFERENTIAL_FAIL=0
```

## AC10 -- component fixed point

```text
COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0
```

## AC11 -- post-migration G1/G2/G3 equivalence

```text
POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0
```

## AC12 -- migration fixture set exact

```text
EXPECTED_MIGRATION_FIXTURE_SET=L07
OBSERVED_MIGRATION_FIXTURE_SET=L07
```

## AC13 -- no unapproved G0 migration

```text
NON_MIGRATION_G0_DIVERGENCE_COUNT=0
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0
```

## AC14 -- L07 semantics

```text
L07_G0=lib-complex_1co
L07_G1=lib-complex_1.0
L07_G2=lib-complex_1.0
L07_G3=lib-complex_1.0
```

## AC15 -- N01

```text
SEMANTIC_OUTPUT_MUTATION_DETECTED=YES
```

## AC16 -- N02 build

```text
N02_MUTATED_COMPONENT_BUILD_RC=0
N02_MUTATED_SEAM_LINK_RC=0
N02_MUTATED_SEAM_RUN_RC=0
```

## AC17 -- N02 artifact identity

```text
N02_MUTATED_COMPONENT_SHA_NONEMPTY=YES
N02_MUTATED_COMPONENT_SHA_DIFFERS=YES
N02_MUTATED_SEAM_SHA_NONEMPTY=YES
```

## AC18 -- N02 causal result

```text
N02_PRODUCTION_DIVERGENCE_DETECTED=YES
N02_UNEXPECTED_DIVERGENCE_COUNT=0
```

## AC19 -- N02 incomplete witness negative control

```text
N02_INCOMPLETE_WITNESS_REJECTED=YES
```

## AC20 -- N03 architecture control

```text
LEGACY_BYPASS_CONTROL_PROVES_ARCHITECTURE=YES
```

## AC21 -- generation provenance

```text
PROVENANCE_ROW_PASS=4
PROVENANCE_ROW_FAIL=0
```

## AC22 -- actual generation-copy control

```text
GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES
```

## AC23 -- AC identity binding

```text
AC_IDENTITY_BINDING=PASS
```

## AC24 -- evidence SHA binding

```text
EVIDENCE_SHA_MISMATCH=0
```

## AC25 -- predicate witness binding

```text
WITNESS_FAIL=0
WITNESS_MISSING=0
```

## AC26 -- AC shuffle negative control

```text
AC_ID_SHUFFLE_DETECTED=YES
```

## AC27 -- evidence SHA negative control

```text
EVIDENCE_SHA_MUTATION_DETECTED=YES
```

## AC28 -- false-PASS negative control

```text
PREDICATE_LIE_DETECTED=YES
```

## AC29 -- LEXER01 conservation

```text
LEXER01_CONSERVATION=PASS
```

## AC30 -- LEXER02 conservation

```text
LEXER02_DIRECT_CONSERVATION=PASS
```

## AC31 -- LEXER03 conservation

```text
LEXER03_CONSERVATION=PASS
```

## AC32 -- broad-corpus delta

```text
LEXER07_NEW_FAILURES=0
LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS
```

## AC33 -- F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

## AC34 -- F-NO-PYTHON

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

## AC35 -- F14

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

## AC36 -- C2 to C3 freeze

```text
C2_TO_C3_FROZEN=YES
```

## AC37 -- C3 phase purity

```text
C3_PHASE_PURITY=PASS
```

## AC38 -- Factory gates

```text
GATE_FAST=PASS
APPEND_ONLY_FAIL=0
```

## AC39 -- full prospective patch hygiene

```text
PATCH_HYGIENE_ERRORS=0
```

## AC40 -- exact CORRECTION04 topology

```text
CORRECTION04_COMMIT_COUNT=5
C0_C1_C2_C3_C4_ORDER=YES
```

## AC41 -- terminal worktree

```text
WORKTREE_CLEAN_AFTER_C4=YES
```

## AC42 -- no post-C4 commit

```text
POST_C4_COMMIT_COUNT=0
```

All AC01..AC42 are mandatory.

---

# 47. LEXER02 conservation must be executed

Fresh command output required.

Required:

```text
LEXER02_CONSERVATION_RC=0
LEXER02_DIRECT_CONSERVATION=PASS
```

---

# 48. LEXER03 conservation must be executed

Freshly run its canonical:

```text
direct differential
fixed point
broad corpus
```

Required:

```text
LEXER03_CONSERVATION=PASS
```

Narrative "unrelated" evidence is insufficient.

---

# 49. Factory gates

Freshly run:

```text
make gate-fast
bash scripts/quality/factory-append-only-test.sh
```

If current Factory supports the closure regression:

```text
make factory-closure-status-test
```

Required:

```text
GATE_FAST=PASS
APPEND_ONLY_PASS=11
APPEND_ONLY_FAIL=0
```

Bind actual current closure regression count.

---

# 50. F-POLYC-TOOLS

All new substantive tooling SHALL be PolyC.

Allowed shell:

```text
<=50 LOC pure dispatch
```

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

---

# 51. F-NO-PYTHON

Required forward delta:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

Do not reinterpret grandfathered files as new defects.

---

# 52. F14

No modifications to closed evidence/HANDOFFs from:

```text
LEXER01
LEXER02
# 55. C1 required artifacts

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c1/

c1-entry-reverify.txt
c1-correction03-defects.tsv
c1-production-authority.tsv

c1-generation-identities.tsv
c1-migration-contract.tsv
c1-production-fixtures.tsv

c1-broad-corpus-baseline.txt

c1-n02-mutation-contract.txt

c1-mandatory-ac-contract.tsv
c1-ac-witness-contract.tsv

c1-required-result.txt
```

C1 is RED/CONTRACT only.

No qualification-tool implementation yet.

---

# 56. C1 required-result

```text
ACT=ACT-POLYC-SELFHOST-LEXER04-CORRECTION04

CORRECTION03_REVIEWED_VERDICT=FALSE_GREEN
CORRECTION03_TERMINAL_CLASS=HALT_MULTIPLE_BINDING_PREDICATES
CORRECTION03_COMMIT_COUNT=6

PRODUCTION_AUTHORITY_EXPECTED=YES

EXPECTED_MIGRATION_FIXTURE_COUNT=1
EXPECTED_MIGRATION_FIXTURE_SET=L07

N02_MUTATION_KIND=<A|B|C>
N02_EXPECTED_FIXTURE=L07
N02_EXPECTED_FIELD=link_libs

AC_TOTAL=42
```

---

# 57. C2 implementation

C2 implements only the qualification machinery required to satisfy:

```text
production authority mechanical inspection
generation provenance verification
actual generation-copy rejection
correct migration-aware semantic comparison
AC evidence SHA verification
generic AC predicate witness verification
```

C2 SHALL NOT change production files.

Before C2 commit:

```text
PRODUCTION_SOURCE_DELTA=0
```

---

# 58. C2 developer proof

Before committing C2, run the full qualification suite at least once.

Required provisional:

```text
N02_VALID_CHAIN=PASS
GENERATION_COPY_CONTROL=PASS
MIGRATION_AWARE_SEMANTIC_VERIFY=PASS
AC_WITNESS_SELFTEST=PASS
```

If production defect is exposed:

```text
HALT_PRODUCTION_DEFECT_DISCOVERED
```

---

# 59. C2 freeze

At C2 commit record SHA-256 for:

```text
ACT body
AC contract
AC witness contract
migration contract
fixture contract

all changed qualification tools
Makefile qualification targets

src/lexer.c
src/lexer_bridge.h
selfhost-lexer-link.HC
```

Produce:

```text
c2-freeze.tsv
```

C3 must reproduce identical hashes.

---

# 60. C3 entry

Required:

```text
C3_ENTRY_HEAD=C2_COMMIT
C3_ENTRY_WORKTREE_CLEAN=YES
```

Record literal command results.

Do not store unevaluated shell syntax such as:

```text
$(git status ...)
```

as evidence.

---

# 61. C3 phase purity

C3 is evidence-only.

Forbidden C3 mutations:

```text
src/**
tools/bootstrap/**
tools/quality/**
Makefile
scripts/**
ACT body
C1 contracts
```

If any verifier/tool/source needs repair:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

Do not patch and continue.

---

# 62. C3 evidence tree

At minimum:

```text
c3-entry-identity.txt
c3-c2-freeze-replay.tsv

c3-production-authority.txt
c3-production-source-delta.txt

c3-direct-differential.txt
c3-component-fixedpoint.txt

c3-generation-provenance.tsv
c3-generation-provenance-verify.txt

c3-seam-g0.raw.txt
c3-seam-g1.raw.txt
c3-seam-g2.raw.txt
c3-seam-g3.raw.txt

c3-semantic-postmigration.txt
c3-semantic-g0-migration-delta.txt
c3-semantic-per-fixture.tsv

c3-n01-output-mutation.txt
c3-n02-production-causal-control.txt
c3-n02-incomplete-witness-control.txt
c3-n03-legacy-bypass.txt

c3-nc-generation-copy.txt

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
ac-witness-results.tsv
c3-required-result.txt
```

---

# 63. C3 mandatory status

At C3:

```text
AC01..AC39 = PASS

AC40 = DEFERRED_TO_C4
AC41 = DEFERRED_TO_C4
AC42 = DEFERRED_TO_C4
```

No other AC may be deferred.

If any AC01..AC39 fails:

```text
HALT_MANDATORY_AC_NOT_GREEN
```

Do not proceed to C4.

---

# 64. C3 required-result

```text
ACT=ACT-POLYC-SELFHOST-LEXER04-CORRECTION04

CORRECTION03_REVIEWED_VERDICT=FALSE_GREEN
CORRECTION03_HISTORY_IMMUTABLE=YES

PRODUCTION_SOURCE_DELTA=0

POLYC_OUTPUTS_CONSUMED_BY_PRODUCTION=YES
SELFHOST_DUPLICATE_TARGET_PARSE=0

DIRECT_DIFFERENTIAL_FAIL=0

COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0

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

N02_MUTATED_COMPONENT_BUILD_RC=0
N02_MUTATED_SEAM_LINK_RC=0
N02_MUTATED_SEAM_RUN_RC=0
N02_MUTATED_COMPONENT_SHA_NONEMPTY=YES
N02_MUTATED_COMPONENT_SHA_DIFFERS=YES
N02_MUTATED_SEAM_SHA_NONEMPTY=YES
N02_PRODUCTION_DIVERGENCE_DETECTED=YES
N02_UNEXPECTED_DIVERGENCE_COUNT=0

N02_INCOMPLETE_WITNESS_REJECTED=YES

GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES

AC_IDENTITY_BINDING=PASS
EVIDENCE_SHA_MISMATCH=0
WITNESS_FAIL=0
WITNESS_MISSING=0

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

AC_TOTAL=42
AC_PASS=39
AC_FAIL=0
AC_DEFERRED=3
```

---

LEXER03
LEXER04
LEXER04-CORRECTION01
LEXER04-CORRECTION02
LEXER04-CORRECTION03
libtos correction lineage
static-function-linkage lineage
Factory closure-oracle lineage
```

Required:

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

---

# 53. CORRECTION03 N02 evidence treatment

The old file:

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION03/c3/
  c3-n02-subject-mutation.txt
```

is immutable historical evidence.

Do not clean its trailing whitespace.

Do not create `v2` inside CORRECTION03.

CORRECTION04 owns:

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c3/
  c3-n02-production-causal-control.txt
```

This avoids F14 ambiguity entirely.

# 65. C4 preparation

Before writing C4 artifacts:

```sh
git status --short
git diff --check "$CORRECTION04_ENTRY_HEAD"..HEAD
```

Required:

```text
C4_PREP_WORKTREE_CLEAN=YES
C4_PREP_PATCH_HYGIENE_ERRORS=0
```

Then prepare only:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION04.md

evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c4/
  c4-parent-identity.txt
  c4-terminal-ledger.txt
```

No implementation mutation.

---

# 66. C4 HANDOFF identity

Do not put a fictional self-SHA in the HANDOFF.

Allowed:

```text
C4_PARENT_SHA=<C3 commit>
C4_IDENTITY=COMMIT_CONTAINING_THIS_HANDOFF
```

Do not later add a SHA-fill commit.

---

# 67. C4 terminal topology verification

Immediately after C4:

```sh
git rev-list --count "$CORRECTION04_ENTRY_HEAD"..HEAD
```

Required:

```text
CORRECTION04_COMMIT_COUNT=5
```

Verify phase order from commit trailers/subjects.

Required:

```text
C0_C1_C2_C3_C4_ORDER=YES
```

---

# 68. C4 terminal worktree

Immediately after C4:

```text
WORKTREE_CLEAN_AFTER_C4=YES
```

If dirty:

the ACT is not closed.

Do not create a sixth cleanup commit.

---

# 69. AC42 semantics

Within the C4 HANDOFF, AC42 cannot prove the future.

Therefore terminal protocol is:

```text
C4 commit exists
worktree clean
commit count = 5
```

External/reviewer post-close observation then establishes:

```text
POST_C4_COMMIT_COUNT=0
```

No repository mutation is needed to backfill it.

The HANDOFF may state:

```text
POST_C4_MUTATION_AUTHORIZED=NO
# 71. HALT taxonomy

```text
HALT_ENTRY_DIRTY
HALT_ENTRY_IDENTITY_DRIFT

HALT_AUTHORIZATION_ARTIFACT_INCOMPLETE

HALT_CORRECTION03_RECLASSIFICATION_MISMATCH
HALT_F14_VIOLATION

HALT_PRODUCTION_DEFECT_DISCOVERED
HALT_PRODUCTION_AUTHORITY_NOT_PROVEN
HALT_DUPLICATE_LEGACY_SEMANTICS_REMAIN

HALT_DIRECT_DIFFERENTIAL
HALT_COMPONENT_FIXEDPOINT

HALT_GENERATION_BUILD
HALT_GENERATION_LINK
HALT_GENERATION_RUN
HALT_GENERATION_PROVENANCE

HALT_MIGRATION_CONTRACT_INCOMPLETE
HALT_MIGRATION_SEMANTICS
HALT_POST_MIGRATION_DIVERGENCE
HALT_UNEXPECTED_G0_DIVERGENCE

HALT_N02_MUTATION_BUILD
HALT_N02_MUTATION_LINK
HALT_N02_MUTATION_RUN
HALT_N02_EMPTY_ARTIFACT_SHA
HALT_NEGATIVE_CONTROL_NOT_LOAD_BEARING
HALT_N02_UNEXPECTED_DIVERGENCE
HALT_N02_INCOMPLETE_WITNESS_NOT_REJECTED

HALT_GENERATION_COPY_CONTROL
HALT_GENERATION_COPY_NOT_DETECTED

HALT_AC_MAPPING_INTEGRITY
HALT_EVIDENCE_SHA_BINDING
HALT_PREDICATE_WITNESS_BINDING

HALT_AC_ID_SHUFFLE_CONTROL
HALT_EVIDENCE_SHA_CONTROL
HALT_PREDICATE_LIE_CONTROL

HALT_LEXER01_CONSERVATION
HALT_LEXER02_CONSERVATION
HALT_LEXER03_CONSERVATION
HALT_BROAD_CORPUS_NEW_REGRESSION

HALT_F_POLYC_TOOLS
HALT_F_NO_PYTHON

HALT_C2_TO_C3_DRIFT
HALT_C2_DEFECT_FOUND_DURING_C3
HALT_C3_PHASE_PURITY

HALT_FACTORY_GATE
HALT_APPEND_ONLY
HALT_PATCH_HYGIENE

HALT_MANDATORY_AC_NOT_GREEN

HALT_PHASE_CORRECTION_REQUIRED
HALT_TERMINAL_WORKTREE_DIRTY
```

A HALT is a successful Factory outcome when the corresponding predicate
is genuinely red.

---

# 72. Commit trailer discipline

Use the repository's existing accepted trailer grammar.

Semantic mapping:

```text
C0 -> authorization phase supported by current checker
C1 -> RED
C2 -> IMPL
C3 -> EVIDENCE
C4 -> CLOSE
```

Only C4 may carry:

```text
ACT-Verdict: PASS_TRUE_GREEN
```

and only if terminal ACs are genuinely green.

Do not invent unsupported phase tokens.

---

# 73. C4 HANDOFF required sections

```text
VERDICT
IDENTITY
PREDECESSOR RECLASSIFICATION
MISSION
SCOPE
PRODUCTION AUTHORITY
MIGRATION CONTRACT
N02 CAUSAL CONTROL
GENERATION COPY CONTROL
GENERATION PROVENANCE
# 75. Successful engineering interpretation

On PASS:

```text
The CORRECTION03 production migration is now qualified prospectively.

BootstrapLinkDirective remains the production authority for #link.

The migration from the G0 legacy representation to the PolyC representation
is explicitly bounded to L07.

All migrated generations G1/G2/G3 are semantically equivalent.

All non-migration fixtures remain conserved against G0.

A compile-valid mutation of the PolyC subject changes observable production
semantics, proving the component is causally load-bearing.

A forged generation artifact is rejected by provenance verification.

The AC system cannot mark PASS solely from an identity-correct status row;
it must validate the bound evidence and predicate witnesses.

CORRECTION03 remains FALSE_GREEN historical evidence.

CORRECTION04 is the first truthful qualification closure of the production
migration.
```

---

# 76. Board effect on PASS

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION03
  = FALSE_GREEN / HALT_MULTIPLE_BINDING_PREDICATES

ACT-POLYC-SELFHOST-LEXER04-CORRECTION04
  = CLOSED PASS_TRUE_GREEN

LEXER04_COMPONENT_FIXEDPOINT
  = TRUE_GREEN

LEXER04_PRODUCTION_AUTHORITY
  = TRUE_GREEN

LEXER04_POST_MIGRATION_G1_G2_G3_EQUIVALENCE
  = TRUE_GREEN

LEXER04_PRODUCTION_MIGRATION
  = COMPLETE
```

Then unblock:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

Do not select the next lexer number without recon.

---

# 77. Independent residue

The following remains independent unless C1 proves otherwise:

```text
ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
```

Historical LEXER07 baseline regressions remain separately tracked:

```text
LEXER07_BASELINE_REGRESSION=<C1 frozen value>
```

CORRECTION04 must introduce zero new regressions but need not repair that
independent historical set.

---

# 78. Execution order

## C0 AUTH

Commit this full ACT and C0 entry evidence.

No other work first.

## C1 RED / CONTRACT

Reproduce CORRECTION03 defects.

Freshly measure production authority.

Freeze:

```text
migration contract
generation identities
N02 mutation
AC contract
witness contract
broad-corpus baseline
```

No implementation.

## C2 QUALIFICATION TOOLS

Implement only test/verifier machinery.

No production semantic mutation.

Run developer proof.

Commit once.

## C3 VERIFY

Fresh committed-C2 verification.

Evidence only.

Any tool or implementation repair need:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

## C4 CLOSE

Only terminal artifacts.

Exactly one C4 commit.

No follow-up commit.

---

# 79. First C0 commands

```sh
git status --short
git branch --show-current
git rev-parse HEAD
git merge-base --is-ancestor 0d26e41 HEAD
git rev-list --count 4814bf1..0d26e41
```

Record outputs verbatim.

Then:

```sh
git diff --check 0d26e41..HEAD
```

At C0 with HEAD equal to entry this is expected clean/empty.

Historical CORRECTION03 range hygiene is recorded separately and remains
historically FAIL.

---

# 80. First C1 commands

Inspect the real post-CORRECTION03 authority:

```sh
grep -n "BootstrapLinkDirective" src/lexer.c
grep -n "out_target_bytes\|out_target_len\|out_consumed\|out_is_path\|out_error" src/lexer.c
```

Inspect historical invalid controls:

```sh
grep -n "mutated  link.o SHA\|Error 1\|MUTATED_SEAM_BINARY_LINKS\|N02_OUTCOME" \
  evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION03/c3/c3-n02-subject-mutation.txt

grep -n "GENERATION_COPY_DETECTED" \
  evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION03/c3/c3-nc-generation-copy.txt

grep -n "SEMANTIC_PAIR_PASS\|MIGRATION_DELTA" \
  evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION03/c3/c3-production-seam-pairwise.txt
```

These establish the RED lineage.

---

# 81. Governing principle

This ACT is intentionally stricter than CORRECTION03.

The terminal question is no longer:

```text
"Does a ledger contain 42 PASS rows?"
```

It is:

```text
"Can every mandatory PASS be traced through an exact AC identity,
to an exact immutable evidence artifact, to a machine-readable witness
whose observed value actually satisfies the authorized predicate?"
```

For LEXER04 specifically:

```text
"Can we prove that production behavior causally depends on the PolyC
BootstrapLinkDirective, that G1/G2/G3 reproduce the same migrated semantics,
that G0 differs only where the migration intentionally repairs behavior,
and that our qualification machinery detects deliberate lies?"
```

If yes:

```text
PASS_TRUE_GREEN
```

If not:

```text
HALT
```

with the exact failed predicate preserved as evidence.

AC TRUTH BINDING
CONSERVATION
FACTORY GATES
PATCH HYGIENE
F14
COMMIT TOPOLOGY
RESIDUE
NEXT
```

---

# 74. What the HANDOFF must not say

Forbidden unless literally true:

```text
"all substantive ACs pass" when a binding AC fails

"generation-copy control pass" when no copy was injected

"N02 pass" if build/link/run did not all return zero

"patch hygiene clean" if git diff --check is nonzero

"42/42 PASS" merely because a TSV says PASS

"5 commits" if rev-list says otherwise

"no post-C4 commit" before an external observation can establish it
```

---

```

but must not pretend to observe the future.

---

# 70. PASS_TRUE_GREEN predicate

CORRECTION04 may claim `PASS_TRUE_GREEN` only if:

```text
AC_TOTAL=42
AC_PASS=42
AC_FAIL=0
AC_DEFERRED=0

CONTRACT_BINDING=PASS
EVIDENCE_BINDING=PASS
PREDICATE_BINDING=PASS

PRODUCTION_SOURCE_DELTA=0

PRODUCTION_AUTHORITY_VERIFY=PASS

DIRECT_DIFFERENTIAL_FAIL=0

COMPONENT_PAIR_PASS=6
COMPONENT_PAIR_FAIL=0

POST_MIGRATION_PAIR_PASS=3
POST_MIGRATION_PAIR_FAIL=0

OBSERVED_MIGRATION_FIXTURE_SET=L07
NON_MIGRATION_G0_DIVERGENCE_COUNT=0
G0_UNEXPECTED_MIGRATION_PAIR_COUNT=0

N02_MUTATED_COMPONENT_BUILD_RC=0
N02_MUTATED_SEAM_LINK_RC=0
N02_MUTATED_SEAM_RUN_RC=0
N02_MUTATED_COMPONENT_SHA_NONEMPTY=YES
N02_MUTATED_COMPONENT_SHA_DIFFERS=YES
N02_MUTATED_SEAM_SHA_NONEMPTY=YES
N02_PRODUCTION_DIVERGENCE_DETECTED=YES
N02_UNEXPECTED_DIVERGENCE_COUNT=0

GENERATION_COPY_CONTROL_EXECUTED=YES
GENERATION_COPY_DETECTED=YES
GENERATION_COPY_VERIFIER_RC_NONZERO=YES

AC_ID_SHUFFLE_DETECTED=YES
EVIDENCE_SHA_MUTATION_DETECTED=YES
PREDICATE_LIE_DETECTED=YES

LEXER01_CONSERVATION=PASS
LEXER02_DIRECT_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER07_NEW_FAILURES=0
LEXER08_BROAD_CORPUS=PASS
LEXER09_BROAD_CORPUS=PASS

F_POLYC_TOOLS=PASS
F_NO_PYTHON=PASS
F14=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

CORRECTION04_COMMIT_COUNT=5
WORKTREE_CLEAN_AFTER_C4=YES
POST_C4_COMMIT_COUNT=0
```

Anything less is HALT.

---

---

WITNESS_FAIL=0
WITNESS_MISSING=0
```

An AC is PASS only if all mandatory witnesses belonging to it PASS.

---

# 34. AC status must be derived

`mandatory-ac-status.tsv` SHALL be generated from witness results or
validated against them.

A manually authored:

```text
status=PASS
```

cannot override a failed witness.

Required causal invariant:

```text
ANY_MANDATORY_WITNESS_FAIL
  =>
AC_STATUS=FAIL
  =>
ACT_TERMINAL_PASS=FORBIDDEN
```

---


```text
SEMANTIC_OUTPUT_MUTATION_DETECTED=YES
SEMANTIC_OUTPUT_MUTATION_VERIFIER_RC_NONZERO=YES
```

N01 and N02 remain distinct:

```text
N01 -> verifier sensitivity
N02 -> production subject causality
```

---

# 27. N03 architecture control

Freshly re-run the legacy-vs-selfhost distinction.

Required:

```text
LEGACY_BYPASS_CONTROL_PROVES_ARCHITECTURE=YES
```

But evidence must be generated by a test/control, not inferred only from
historical G0/G1 output.

---

Even if G1 and G3 normalize identically, provenance must detect that a
G1-generated artifact was supplied where G3 was required.

---

# 21. N02 production-causal control -- requirements

CORRECTION03's N02 is invalid and SHALL NOT be reused as PASS evidence.

CORRECTION04 N02 must satisfy the entire chain:

```text
mutated source exists
mutated source differs from pristine
mutated source compiles successfully
mutated component object exists
mutated component SHA is non-empty
mutated component SHA differs from pristine
mutated seam binary links successfully
mutated seam binary exists
mutated seam binary SHA is non-empty
mutated seam executes successfully
mutated output exists
mutated production semantic output differs from pristine
difference matches predicted mutation
pristine rerun passes after control
```

All are mandatory.

---


```text
BootstrapLinkDirective call exists in selfhost branch
out_target_bytes participates in AoStr construction
out_target_len participates in AoStr construction
out_consumed advances production cursor
out_is_path selects destination list
out_error controls error path
legacy token-by-token target reconstruction is absent from selfhost branch
```

Required:

```text
PRODUCTION_AUTHORITY_VERIFY=PASS
```

Narrative inspection alone is insufficient at C3.

---

# 13. Correct semantic-generation model

CORRECTION03's six-way equality contract is prospectively superseded.

Binding CORRECTION04 model:

```text
G0 = legacy control
G1 = migrated selfhost implementation built by bootstrap02
G2 = migrated selfhost implementation built by bootstrap03
G3 = migrated selfhost implementation built by bootstrap04
```

The intended relation is:

```text
G1 == G2 == G3

G0 differs from G1/G2/G3 only on explicitly frozen migration fixtures.
```

---

# 14. Frozen migration fixture

Exactly one intentional semantic migration is currently authorized:

```text
fixture_id = L07
input      = #link <lib-complex_1.0>

G0 link_libs = lib-complex_1co

G1 link_libs = lib-complex_1.0
G2 link_libs = lib-complex_1.0
G3 link_libs = lib-complex_1.0
```

Freeze:

```text
EXPECTED_G0_MIGRATION_FIXTURE_COUNT=1
EXPECTED_G0_MIGRATION_FIXTURE_SET={L07}
```

If C1 finds more intentional migration fixtures:

```text
HALT_MIGRATION_CONTRACT_INCOMPLETE
```

Do not expand the set during C3.

---

C1 RED/CONTRACT
C2 QUALIFICATION-TOOLS
C3 VERIFY
C4 CLOSE
```

Maximum = 5.

Required terminal command:

```sh
git rev-list --count "$CORRECTION04_ENTRY_HEAD"..HEAD
```

Expected:

```text
5
```

No:

```text
C2.1
C3.1
C4-fill
C4-correct
whitespace cleanup
SHA backfill
post-C4 ledger fix
```

If a sixth commit seems necessary:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

Do not create it.

---

