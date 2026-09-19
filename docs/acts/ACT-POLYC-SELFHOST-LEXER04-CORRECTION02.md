# ACT-POLYC-SELFHOST-LEXER04-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT
Authored-At: 2026-09-19
Entry-Head: ba45528691aa458b21137f7eae7723d81b9d9c92

**Title:** Complete LEXER04 qualification with a genuine four-generation
production `#link` semantic seam, restore PolyC-native proof authority,
replay the original authorized AC01..AC32 contract mechanically, and close
the LEXER04 correction lineage.

---

# 0. Entry authority

Predecessor:

```text
ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04
HEAD = ba45528691aa458b21137f7eae7723d81b9d9c92

LIBTOS_LINEAGE = TRUE_GREEN_FOR_FORWARD_USE
```

Binding LEXER04 predecessor lineage:

```text
ACT-POLYC-SELFHOST-LEXER04
    original engineering result useful
    original PASS_TRUE_GREEN = FALSE_GREEN

ACT-POLYC-SELFHOST-LEXER04-CORRECTION01
    static-function/toolchain repair = GREEN
    terminal result = HALT_MECHANICAL_BLOCKING_B5
    blocker = libtos archive incompleteness

ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04
    libtos substrate = GREEN
    blocker removed
```

This ACT resumes exactly where LEXER04-CORRECTION01 halted.

---

# 1. Mission

LEXER04 migrated `lexLink / #link` directive from legacy C authority
to PolyC `tools/bootstrap/selfhost-lexer-link.HC`.

Existing evidence already established useful partial properties:

```text
direct differential        = GREEN
component fixed point      = GREEN
stage0/stage1 seam         = GREEN
static-function linkage    = repaired
libtos verifier substrate  = repaired
```

But LEXER04 was never truthfully qualified. Six gaps remain:

```text
1. genuine G0/G1/G2/G3 production semantic seam
2. PolyC-native fixedpoint/seam verification authority
3. F-POLYC-TOOLS compliance
4. replay of the actually authorized AC01..AC32 table
5. clean phase separation with no C3 implementation mutation
6. prospective patch hygiene
```

This ACT SHALL close those gaps.

Successful state:

```text
LEXER04_DIRECT_DIFFERENTIAL             = PASS
LEXER04_COMPONENT_FIXED_POINT           = PASS
LEXER04_PRODUCTION_SEAM_G0_G1_G2_G3     = PASS
LEXER04_SEAM_PAIRWISE_EQUIVALENCE       = 6/6 PASS

LEXER04_POLYC_VERIFIER_AUTHORITY        = PASS
LEXER04_POLYC_SHA256_AUTHORITY          = PASS
LEXER04_SUBSTANTIVE_C_VERIFIER          = NONE

AUTHORIZED_AC01_32_REPLAY               = PASS

LEXER04_BOOTSTRAP_QUALIFICATION         = COMPLETE
LEXER04_CORRECTION_LINEAGE              = TRUE_GREEN
```

---

# 2. Non-goals

This ACT SHALL NOT modify libtos, the Factory closure-oracle
implementation, repair the ./hcc ARM64 inline-asm parser regression,
select LEXER05, migrate lexInclude, migrate preprocessor logic,
perform parser migration, redesign lexer ABI, or rewrite closed
LEXER04 evidence/HANDOFFs.

`ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01` remains independent P1
residue.

---

# 3. Historical truth preservation

LEXER04 original PASS_TRUE_GREEN = FALSE_GREEN, with reason classes
including: no prior C0 AUTH, C3 production mutation, replacement AC
table, substantive C quality tools, missing G0/G1/G2/G3 semantic seam,
patch-hygiene failure. This ACT does not rewrite those artifacts; it
proves a new forward qualification over the current tree.

---

# 4. C0 AUTH (this commit)

Before creating evidence or modifying implementation/tooling:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
```

Required expected state:

```text
BRANCH=main
ENTRY_HEAD=ba45528691aa458b21137f7eae7723d81b9d9c92
WORKTREE_CLEAN_AT_C0=YES
```

C0 creates only:

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION02.md

evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION02/c0/
    c0-entry-identity.txt
    c0-scope.txt
```

No production or test-tool mutation before C0 commits.

---

# 5. Prospective patch-hygiene baseline

```text
PATCH_HYGIENE_BASELINE=ENTRY_HEAD (=ba45528)
```

Every phase SHALL run `git diff --check ENTRY_HEAD..HEAD`. Required:
`PATCH_HYGIENE_ERRORS=0`. No alternate historical range may be
substituted later.

---

# 6. Original AC contract is authoritative

A previous LEXER04 failure mode was replacing the authorized AC table
with a convenient new table.

This ACT SHALL NOT manually reconstruct AC01..AC32 from memory.

At C1 mechanically extract the exact AC contract from:

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION01.md  (the §31 contract)
```

Produce:

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION02/c1/
    c1-authorized-ac-snapshot.tsv
    c1-authorized-ac-snapshot.sha256
```

Required: AUTHORIZED_AC_COUNT=32, AUTHORIZED_AC_IDS=AC01..AC32.

Each row records: ac_id, exact_authorized_description,
source_line_or_section, mandatory. The snapshot SHA is frozen before
C2.

---

# 7. AC amendment rule

Allowed without additional authorization: TERMINAL_MOVE_ONLY,
HISTORICAL_WITNESS_REBIND, provided the predicate itself does not
change. Forbidden silently: SEMANTIC_AMENDMENT_REQUIRED. If any AC
requires semantic amendment: HALT_AUTHORIZED_AC_AMENDMENT_REQUIRED.
No C2 work begins.

---

# 8. No substituted mandatory ledger

The C3/C4 mandatory ledger SHALL contain all imported AC01..AC32 with
exact description, exact status, actual evidence path. No renumbering,
no replacement description, no PASS_BY_DESIGN / EQUIVALENT_PASS /
STRUCTURAL_PASS / CARRIED_OVER_PASS. Mandatory predicate is
PASS | FAIL | DEFERRED_TO_C4 (DEFERRED only for inherently terminal).

---

# 9. C1 live-surface recon

Inventory:

```text
src/lexer.c
src/lexer.h
src/lexer_bridge.h
tools/bootstrap/selfhost-lexer-link.HC
tools/quality/lexer09-*
Makefile targets containing lexer09 / link / fixedpoint / seam
```

Produce c1-live-surface.tsv. Capture: legacy lexLink location,
delegation location, PolyC BootstrapLinkDirective implementation,
bridge ABI, direct differential implementation, production seam
implementation, fixedpoint verifier implementation, SHA-256
implementation, all Makefile targets.

---

# 10. C1 prove current engineering baseline

Run the existing LEXER04 controls unchanged.

```text
LEXER04_EXISTING_DIRECT_DIFFERENTIAL=PASS
LEXER04_EXISTING_COMPONENT_FIXEDPOINT=PASS
LEXER04_EXISTING_STAGE0_STAGE1_SEAM=PASS
```

If any previously green engineering property is now red:
HALT_PREDECESSOR_ENGINEERING_REGRESSION.

---

# 11. Principal RED - missing four-generation semantic seam

C1 SHALL mechanically prove current evidence does not establish a
genuine production seam across all four generations.

Required (per-generation output existence + per-pair proof):

```text
G0..G3_PRODUCTION_SEMANTIC_OUTPUT_EXISTS=<YES|NO>
PAIR_G0_G1_PROVEN..PAIR_G2_G3_PROVEN=<YES|NO>
```

Entry expected: LEXER04_4_STAGE_PRODUCTION_SEAM=NOT_PROVEN.


---

# 12. Generation identities

C1 SHALL mechanically bind the actual four compiler generations.

Expected candidates:

```text
G0 = ./hcc
G1 = ./build/hcc-bootstrap02
G2 = ./build/hcc-bootstrap03
G3 = ./build/hcc-bootstrap04
```

Record: generation, compiler_path, sha256, exists, executable,
producer/provenance. No generation may silently alias another path.

---

# 13. Generation independence

Compiler paths must be mechanically bound; SHA identities recorded.
Identical compiler bytes MAY be DOCUMENTED but generation build
topology must be independently bound.

---

# 14. Fresh output requirement

Before each generation run, remove only that generation's ACT-owned
semantic-output artifacts.

```text
G0..G3_OUTPUT_PREEXISTED=NO
STALE_GENERATION_OUTPUTS_REUSED=0
```

---

# 15. Define the production semantic seam

Subject: actual lexer.c production path with BootstrapLinkDirective
delegation active where appropriate. Each generation runs the same
fixture corpus through the real lexer/directive path.

Stable semantic fields only: fixture_id, return/status class, token
kind, directive recognized yes/no, #link payload bytes, payload
length, cursor/remaining-input position, link-state mutation, error
class.

Forbidden in payload: raw pointers, heap/arena addresses, ASLR-
sensitive values, process IDs, timestamps, BUILD_LABEL.

---

# 16. No post-hoc normalization

C1 freezes the semantic serialization schema before C2.
Produce c1-semantic-schema.tsv. SEMANTIC_FIELDS_FROZEN=YES. If a field
proves nondeterministic: HALT_SEMANTIC_SCHEMA_DEFECT.

---

# 17. Fixture corpus authority

Inventory the existing LEXER04 direct/seam fixtures. Do not hardcode
counts until recon. Produce c1-fixture-inventory.tsv with:
fixture_id, input, category, present_in_direct_differential,
present_in_stage01_seam, required_in_4stage_seam. Every existing
production-seam fixture is mandatory.

---

# 18. Minimum fixture classes

Corpus must cover LEXER04 contract classes present in current test
suite: valid #link string directive, spacing variants, trivia
before/after directive, invalid/malformed directive, non-#link input,
EOF boundary, string token path, error path. Do not invent semantics
unsupported by current source.

---

# 19. TK_STR regression witness

Historical LEXER04 implementation briefly used next.len - 2 despite
lexString() already exposing quote-stripped body bytes. A dedicated
fixture SHALL remain load-bearing against that defect. C3 SHALL show
it identical at G0/G1/G2/G3.

---

# 20. PolyC-native proof authority RED

C1 SHALL inventory the currently authoritative verifier and SHA
implementation. Historical violating tools included
tools/quality/lexer09-fixedpoint-verify.c and
tools/quality/sha256-tool.c.

Classify: CURRENT_FIXEDPOINT_VERIFIER_LANGUAGE,
CURRENT_SEAM_VERIFIER_LANGUAGE, CURRENT_SHA256_AUTHORITY_LANGUAGE.
Required RED if any substantive authoritative verifier remains C:
F_POLYC_TOOLS_LEXER04_RED=CONFIRMED.

---

# 21. Existing PolyC SHA reuse first

Before adding a new SHA implementation, inspect existing PolyC
implementations, including historically tools/quality/lexer07-sha256.HC.
REUSE_EXISTING_POLYC_SHA256=YES if it satisfies the API.

---

# 22. Static-function/link substrate conservation

A PolyC SHA implementation containing static helper functions must:
compile, link against canonical libtos.a, execute, pass SHA vectors.
POLYC_SHA_STATIC_HELPER_LINK=PASS. No C fallback authorized.

---

# 23. Libtos substrate conservation

Before C2 qualification work: make lib-tos must pass under the
currently qualified fail-closed/provenance contract.
LIBTOS_SUBSTRATE=PASS. If libtos regresses:
HALT_LIBTOS_SUBSTRATE_REGRESSION. Do not repair libtos inside this
ACT.


---

# 24. C2 implementation scope

Authorized C2 paths:

```text
tools/quality/lexer09-*.HC
tools/quality/<reused-or-bounded-sha>.HC
scripts/quality/lexer09-*.sh   only <=50 LOC dispatch
Makefile
```

Existing LEXER04 C verifier/helper files may be deleted, retired from
authoritative targets, or retained only as explicitly non-authoritative
historical oracle code, but SHALL NOT participate in closure authority.

---

# 25. Production source mutation rule

PRODUCTION_SEMANTIC_MUTATION=0. This is a qualification ACT. If the
four-generation production seam exposes a real semantic defect in
src/lexer.c, src/lexer_bridge.h, or
tools/bootstrap/selfhost-lexer-link.HC, then
HALT_LEXER04_SEMANTIC_DEFECT. Do not patch production during C3.
Do not silently expand C2. Open a bounded correction if necessary.

---

# 26. PolyC fixedpoint verifier

Authoritative fixedpoint verification SHALL be PolyC. It must: read
G0/G1/G2/G3 object files, compare bytes directly, compute/report
SHA-256, report file lengths, evaluate all 6 pairwise comparisons,
exit nonzero on any mismatch.

Required output: G0_G1..G2_G3=YES, PAIR_PASS=6, PAIR_FAIL=0,
STATUS=PASS. Byte equality is authoritative. SHA is supplemental.

---

# 27. ObjectsByteEqual authority

Use explicit ObjectsByteEqual(a,b): length(a)==length(b) AND
MemCmp(a,b,length)==0. BYTE_EQUALITY_IS_MEMCMP_BASED=YES. No FNV-
only equality. No SHA-only equality.

---

# 28. Fixedpoint negative control

Pristine G0..G3 -> VERIFIER_RC=0. Mutate exactly one byte in a
temporary copy of one generation object -> VERIFIER_RC!=0,
PAIR_FAIL>=1. Pristine rerun -> VERIFIER_RC=0.
FIXEDPOINT_VERIFIER_LOAD_BEARING=YES.

---

# 29. Four-generation semantic runner

Implement or extend a bounded production seam runner that produces
G0/G1/G2/G3 semantic output for every frozen fixture. The runner
may use existing legacy C oracle/seam infrastructure if already
grandfathered and non-authoritative. The verifier deciding
equivalence SHALL be PolyC.

---

# 30. Semantic output format

Prefer line-oriented deterministic records: fixture_id<TAB>field<TAB>value...
or another existing repository convention. Output must be byte-stable.
No pointer-valued fields. No timestamps. No absolute temporary paths.
No compiler label inside the semantic payload.

---

# 31. Semantic pairwise verifier

PolyC verifier SHALL compare all 6 pairs: G0-G1, G0-G2, G0-G3, G1-G2,
G1-G3, G2-G3. SEMANTIC_PAIR_PASS=6, SEMANTIC_PAIR_FAIL=0. For each
pair emit: pair, bytes_a, bytes_b, equal, first_difference_offset.

---

# 32. Per-fixture four-way equivalence

Verifier SHALL also report per fixture: fixture_id, G0, G1, G2, G3,
four_way_equal=YES|NO. FIXTURE_DIVERGENCE_COUNT=0.

---

# 33. Semantic negative control N01

Mutate one temporary semantic output record from one generation.
Expected: SEMANTIC_PAIR_FAIL>=1, FIXTURE_DIVERGENCE_COUNT>=1,
VERIFIER_RC!=0. Restore pristine: VERIFIER_RC=0.
SEMANTIC_VERIFIER_LOAD_BEARING=YES.

---

# 34. Production causal negative control N02

Use a temporary mutation of the test subject, not committed
production source. Preferred mutation reproduces the historical
TK_STR defect. Build the temporary mutated component/stage outside
tracked source. Run seam.
MUTATED_SUBJECT_DIVERGENCE_DETECTED=YES. Then pristine subject:
SEMANTIC_PAIR_FAIL=0. Proves the production seam is sensitive to
LEXER04 semantics rather than merely output-file corruption.

---

# 35. Stage provenance

For every G0..G3 semantic output record: generation, compiler_path,
compiler_sha256, subject_source_sha256, bridge_source_sha256,
runner_source_sha256, output_sha256. Produce
c3-stage-provenance.tsv. No historical-baseline substitution. All
outputs must be produced during this ACT.


---

# 36. Build artifact freshness

Each generation output SHALL be generated after rm <that ACT-owned
output>. Record before/after existence.
STALE_GENERATION_OUTPUTS_REUSED=0.

---

# 37. Component fixedpoint rerun

Re-run existing four-generation component-object fixed point.
Subject: BootstrapLinkDirective. COMPONENT_FIXEDPOINT_PAIR_PASS=6,
COMPONENT_FIXEDPOINT_PAIR_FAIL=0.

---

# 38. Direct differential rerun

Run existing LEXER04 direct differential. Bind actual count. Expected
historical: 23/23 PASS. DIRECT_DIFFERENTIAL_FAIL=0.

---

# 39. Existing stage0/stage1 seam rerun

Run predecessor seam as conservation. STAGE0_STAGE1_SEAM=PASS.

---

# 40. LEXER03 conservation

Run lexer08 direct differential + lexer08 fixedpoint verify.
LEXER03_CONSERVATION=PASS. Expected known differential count: 45/45.

---

# 41. LEXER02 conservation

Run canonical LEXER02 qualification targets. Expected known direct
count: 89/89. LEXER02_CONSERVATION=PASS.

---

# 42. LEXER01 conservation

Run canonical LEXER01 target. Expected known count: 47/47.
LEXER01_CONSERVATION=PASS.

---

# 43. Broad corpus conservation

Run current four-generation broad-corpus target relevant to the
self-host lexer chain. BROAD_CORPUS_REGRESSION=0.

---

# 44. No C proof authority

```text
AUTHORITATIVE_C_FIXEDPOINT_VERIFIER=0
AUTHORITATIVE_C_SEMANTIC_VERIFIER=0
AUTHORITATIVE_C_SHA256_TOOL=0
```

Existing C oracle code MAY remain if ORACLE_ONLY=YES and
NOT_USED_FOR_TERMINAL_VERDICT=YES.

---

# 45. F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

Any new shell must be <=50 LOC, dispatch/bootstrap only.

---

# 46. F-NO-PYTHON

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

Run canonical checker. Record baseline/delta honestly.

---

# 47. F14 conservation

No mutation to closed: LEXER01-03 evidence/HANDOFFs, LEXER03
corrections evidence/HANDOFFs, LEXER04 original evidence/HANDOFF,
LEXER04-CORRECTION01 evidence/HANDOFF, libtos closed
evidence/HANDOFFs, static-function-linkage closed
evidence/HANDOFFs, Factory closure-oracle closed evidence/HANDOFFs.

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```


---

# 48. Factory closure self-registration

If this ACT is managed by docs/factory/act-handoff-map.tsv, the self
row SHALL be registered before C3. C2 may append exactly:

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION02.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION02.md
```

No HANDOFF yet.

At C3 expected closure-oracle state: SELF_ROW_PRESENT=YES,
SELF_HANDOFF_PRESENT=NO, SELF_PAIR_FAIL=YES. Only this self pair may
fail.

---

# 49. C2 freeze

At C2 commit, freeze SHA-256 of ACT body, manifest, closure checker,
PolyC fixedpoint verifier, PolyC semantic verifier, PolyC SHA
implementation, semantic schema, fixture inventory, production
LEXER04 subject files. C3 SHALL reproduce the same hashes. Any
unexpected change: HALT_C2_TO_C3_DRIFT.

---

# 50. C3 phase purity

C3 is verification only. Permitted: new evidence files. Forbidden:
src/**, tools/bootstrap/**, tools/quality implementation, Makefile,
scripts implementation, ACT body, manifest. If C3 discovers a defect:
HALT_C2_DEFECT_FOUND_DURING_C3. Do not patch and continue.

---

# 51. C3 evidence namespace

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION02/c3/
```

At minimum:

```text
c3-entry-identity.txt
c3-authorized-ac-replay.tsv
c3-authorized-ac-replay.sha256
c3-generation-identities.tsv
c3-source-identities.tsv
c3-stage-provenance.tsv
c3-direct-differential.txt
c3-component-fixedpoint.txt
c3-component-fixedpoint-negative.txt
c3-production-seam-g0.txt
c3-production-seam-g1.txt
c3-production-seam-g2.txt
c3-production-seam-g3.txt
c3-production-seam-pairwise.txt
c3-production-seam-per-fixture.tsv
c3-production-seam-negative-output.txt
c3-production-seam-negative-subject.txt
c3-polyc-verifier-authority.txt
c3-polyc-sha-selftest.txt
c3-lexer01-conservation.txt
c3-lexer02-conservation.txt
c3-lexer03-conservation.txt
c3-broad-corpus.txt
c3-f-polyc-tools.txt
c3-f-no-python.txt
c3-f14-conservation.txt
c3-factory-gates.txt
c3-append-only.txt
c3-patch-hygiene.txt
c3-phase-purity.txt
mandatory-ac-status.tsv
c3-required-result.txt
```

---

# 52. PolyC SHA self-tests

If SHA-256 is used for provenance, the PolyC implementation SHALL
pass known vectors already established in the repository. At minimum:
empty input, "abc", 55-byte padding boundary, 56-byte padding
boundary, 57-byte padding boundary. SHA256_SELFTEST_FAIL=0. SHA
remains provenance evidence; it is not a substitute for MemCmp object
equality.


---

# 53. C3 required-result ledger

Required high-level shape:

```text
ACT=ACT-POLYC-SELFHOST-LEXER04-CORRECTION02

ENTRY_HEAD=<sha>
PATCH_HYGIENE_BASELINE=<same sha>

AUTHORIZED_AC_COUNT=32
AUTHORIZED_AC_REPLAY=PASS
AUTHORIZED_AC_SUBSTITUTIONS=0

DIRECT_DIFFERENTIAL=PASS

COMPONENT_FIXEDPOINT_PAIR_PASS=6
COMPONENT_FIXEDPOINT_PAIR_FAIL=0
FIXEDPOINT_VERIFIER_LOAD_BEARING=YES

G0_SEMANTIC_OUTPUT=PASS
G1_SEMANTIC_OUTPUT=PASS
G2_SEMANTIC_OUTPUT=PASS
G3_SEMANTIC_OUTPUT=PASS

SEMANTIC_PAIR_PASS=6
SEMANTIC_PAIR_FAIL=0
FIXTURE_DIVERGENCE_COUNT=0

SEMANTIC_VERIFIER_LOAD_BEARING=YES
MUTATED_SUBJECT_DIVERGENCE_DETECTED=YES

STAGE0_STAGE1_SEAM=PASS

POLYC_FIXEDPOINT_VERIFIER=PASS
POLYC_SEMANTIC_VERIFIER=PASS
POLYC_SHA256=PASS

AUTHORITATIVE_C_FIXEDPOINT_VERIFIER=0
AUTHORITATIVE_C_SEMANTIC_VERIFIER=0
AUTHORITATIVE_C_SHA256_TOOL=0

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS

BROAD_CORPUS_REGRESSION=0

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

C2_TO_C3_FROZEN=YES
C3_PHASE_PURITY=PASS

PATCH_HYGIENE=PASS
APPEND_ONLY=PASS
```

If self-registered:

```text
SELF_PAIR_FAIL=YES
UNRELATED_PAIR_FAIL=0
```

at C3.

---

# 54. Mandatory AC ledger

Mechanically generated from c1-authorized-ac-snapshot.tsv for AC01..AC32.
Columns: ac_id, exact_authorized_description, mandatory, status,
evidence_path, source_contract_location.

At C3: AUTHORIZED_AC_COUNT=32, SUBSTITUTED_AC_COUNT=0,
DUPLICATE_AC_COUNT=0, MISSING_AC_COUNT=0. Terminal predicates may be
DEFERRED_TO_C4 only if C0/C1 classification identified them as
inherently terminal without changing semantics.

---

# 55. C4 terminal evidence

Resolve legitimate terminal deferrals. C4 must not retroactively
promote a C3 FAIL into PASS. Allowed: DEFERRED_TO_C4 -> PASS.
Forbidden: FAIL -> PASS without new authorized implementation phase.

---

# 56. C4 HANDOFF-only preference

HANDOFF + strictly necessary C4 terminal evidence. No implementation.
No manifest mutation. No ACT-body amendment. No C3 evidence rewrite.
If managed by closure oracle, self row already exists from C2.

---

# 57. Final closure oracle transition

If self-registered:

C3: N rows, N-1 OK, 1 FAIL (cause = missing CORRECTION02 HANDOFF)
C4: same N rows, N OK, 0 FAIL

HANDOFF_CREATION_FLIPS_SELF_PAIR=YES.


---

# 58. C4 final gates

Run after C4 commit:

```text
make gate-fast
factory-closure-status-test
factory-append-only-test
git diff --check ENTRY_HEAD..HEAD
git status --short
```

Required: gate-fast=PASS, closure-status-test=PASS, append-only=PASS,
patch-hygiene=PASS, worktree-clean=YES. No post-C4 cleanup commit.

---

# 59. Acceptance criteria - contract replay

Authoritative acceptance criteria are the imported LEXER04-CORRECTION01
AC01..AC32. This ACT adds qualification invariants, not replacement AC
numbers. Every imported AC SHALL map to evidence.

META01..META22 are mandatory:

```text
META01 AUTHORIZED_AC_COUNT=32
META02 SUBSTITUTED_AC_COUNT=0
META03 PRODUCTION_SEAM_G0_G1_G2_G3=PASS
META04 SEMANTIC_PAIR_PASS=6
META05 FIXTURE_DIVERGENCE_COUNT=0
META06 POLYC_FIXEDPOINT_VERIFIER=PASS
META07 POLYC_SEMANTIC_VERIFIER=PASS
META08 AUTHORITATIVE_SUBSTANTIVE_C_VERIFIERS=0
META09 FIXEDPOINT_NEGATIVE_CONTROL=PASS
META10 SEMANTIC_OUTPUT_NEGATIVE_CONTROL=PASS
META11 SEMANTIC_SUBJECT_NEGATIVE_CONTROL=PASS
META12 C2_TO_C3_FROZEN=YES
META13 C3_PHASE_PURITY=PASS
META14 LEXER01_CONSERVATION=PASS
META15 LEXER02_CONSERVATION=PASS
META16 LEXER03_CONSERVATION=PASS
META17 F_POLYC_TOOLS=PASS
META18 F_NO_PYTHON_FORWARD_DELTA=PASS
META19 F14=PASS
META20 PATCH_HYGIENE=PASS
META21 APPEND_ONLY=PASS
META22 WORKTREE_CLEAN=YES
```

---

# 60. C1 RED success condition

C1 closes when:

```text
AUTHORIZED_AC01_32_SNAPSHOTTED=YES
4_STAGE_PRODUCTION_SEAM_NOT_PROVEN=YES
CURRENT_C_VERIFIER_AUTHORITY_STATUS=KNOWN
CURRENT_POLYC_VERIFIER_BUILDABILITY=KNOWN
COMPILER_G0_G1_G2_G3_IDENTITIES_BOUND=YES
FIXTURE_CORPUS_FROZEN=YES
SEMANTIC_SCHEMA_FROZEN=YES
LIBTOS_SUBSTRATE=PASS
```

No implementation before this point.

---

# 61. C2 success condition

C2 closes only when PolyC fixedpoint/semantic verifiers build/run,
PolyC SHA self-tests pass, G0..G3 outputs can be produced, pristine
pairwise seam passes in developer run, negative controls mechanically
capable of failing, authoritative Makefile paths use PolyC verifiers,
no C verifier is terminal authority, self row registered if required,
all authority hashes frozen.

---

# 62. C3 success condition

C3 SHALL use a clean committed C2 tree. C3_ENTRY_HEAD=C2_COMMIT,
C3_ENTRY_WORKTREE_CLEAN=YES. Then DIRECT_DIFFERENTIAL=PASS,
COMPONENT_FIXEDPOINT=PASS, 4_STAGE_PRODUCTION_SEAM=PASS,
6_PAIR_SEMANTIC_EQUIVALENCE=PASS, PER_FIXTURE_EQUIVALENCE=PASS,
NEGATIVE_CONTROLS=PASS, POLYC_AUTHORITY=PASS,
LEXER01_02_03_CONSERVATION=PASS, AUTHORIZED_AC_REPLAY=PASS,
C3_PHASE_PURITY=PASS. Any implementation mutation discovered
necessary during C3 means HALT.


---

# 63. Phase topology

C0 AUTH (authorization only).
C1 RED/RECON (no implementation).
C2 IMPL (build qualification machinery).
C3 VERIFY (evidence only).
C4 CLOSE (HANDOFF + terminal evidence only).

---

# 64. Commit topology

Maximum and expected: 5 commits (C0, C1, C2, C3, C4). No amend,
rebase, force-push, reset/recommit. If extra implementation is
required: HALT_PHASE_CORRECTION_REQUIRED.

---

# 65. HALT taxonomy

HALT tokens: HALT_ENTRY_DIRTY, HALT_ENTRY_IDENTITY_DRIFT,
HALT_AUTHORIZED_AC_COUNT_NOT_32,
HALT_AUTHORIZED_AC_AMENDMENT_REQUIRED,
HALT_AC_SUBSTITUTION_DETECTED,
HALT_PREDECESSOR_ENGINEERING_REGRESSION,
HALT_LIBTOS_SUBSTRATE_REGRESSION, HALT_GENERATION_IDENTITY_UNKNOWN,
HALT_STALE_GENERATION_OUTPUT, HALT_SEMANTIC_SCHEMA_DEFECT,
HALT_POLYC_SHA_BUILD, HALT_POLYC_VERIFIER_BUILD,
HALT_F_POLYC_TOOLS_REGRESSION, HALT_COMPONENT_FIXEDPOINT,
HALT_DIRECT_DIFFERENTIAL, HALT_PRODUCTION_SEAM_DIVERGENCE,
HALT_FIXTURE_DIVERGENCE, HALT_LEXER04_SEMANTIC_DEFECT,
HALT_NEGATIVE_CONTROL_NOT_LOAD_BEARING,
HALT_LEXER01_CONSERVATION, HALT_LEXER02_CONSERVATION,
HALT_LEXER03_CONSERVATION, HALT_BROAD_CORPUS_REGRESSION,
HALT_F_NO_PYTHON_REGRESSION, HALT_F14_VIOLATION,
HALT_C2_TO_C3_DRIFT, HALT_C2_DEFECT_FOUND_DURING_C3,
HALT_C3_PHASE_PURITY, HALT_FACTORY_GATE_REGRESSION,
HALT_PATCH_HYGIENE, HALT_APPEND_ONLY_VIOLATION,
HALT_PHASE_CORRECTION_REQUIRED.

Every HALT records: HALT_CLASS, BLOCKS_NEXT, OBSERVED, EXPECTED,
ROOT_CAUSE, EVIDENCE, RECOMMENDED_NEXT.

---

# 66. Terminal predicate

PASS_TRUE_GREEN is authorized only if all imported AC01..AC32 are
PASS (or terminal-deferred PASS at C4), all six pairwise component
pairs PASS, all six pairwise semantic pairs PASS,
FIXEDPOINT_VERIFIER_LOAD_BEARING=YES,
SEMANTIC_VERIFIER_LOAD_BEARING=YES,
MUTATED_SUBJECT_DIVERGENCE_DETECTED=YES, PolyC verifiers PASS, no
substantive C verifiers in authority, LEXER01/02/03 conservation
PASS, libtos substrate PASS, F-POLYC-TOOLS PASS,
F-NO-PYTHON forward delta PASS, F14 PASS, C2-to-C3 frozen, C3 phase
purity PASS, factory gates PASS, patch-hygiene PASS, append-only
PASS, worktree-clean YES. VERDICT=PASS_TRUE_GREEN.

---

# 67. Meaning of successful close

LEXER04's #link production implementation is semantically equivalent
across G0/G1/G2/G3 on the frozen production-seam fixture corpus. The
component object reaches the four-generation fixed point. The semantic
seam itself reaches four-generation equivalence. Both object equality
and semantic equality are decided by PolyC-native verification
machinery. No substantive C verifier or C SHA helper participates in
terminal authority. The originally authorized LEXER04 AC01..AC32
contract has been replayed without substitution. C3 contains
verification only. All predecessor lexer qualifications remain green.
LEXER04_BOOTSTRAP_QUALIFICATION=COMPLETE.

It does NOT claim: all lexer surfaces are self-hosted, lexInclude is
migrated, preprocessor is migrated, parser is migrated, ./hcc ARM64
asm parser regression is fixed.

---

# 68. Board effect

On TRUE_GREEN:

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 = CLOSED
LEXER04_CORRECTION_LINEAGE = TRUE_GREEN
LEXER04_BOOTSTRAP_QUALIFICATION = COMPLETE
```

Then NEXT = ACT-POLYC-SELFHOST-SURFACE-RECON03. SURFACE-RECON03 must
mechanically inventory and rank the new remaining self-host boundary.
Do not automatically open LEXER05 by numbering.

---

# 69. Independent P1 residue

ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01 recommended but does not
block this ACT unless encountered during C1.

---

# 70. Execution instruction

C0 only from clean tree. C1 first answers mechanically: exact
authorized AC01..AC32 predicates, live G0..G3 compiler binaries and
hashes, exact fixture corpus, semantic fields, current C tools
remaining, PolyC SHA buildability, the missing G0..G3 seam as the
only remaining gap. Then C2 implements only required proof machinery.
Then C3 fresh verification only. If C3 needs a code fix: HALT. C4
closes only after all six semantic pairs, all six component-object
pairs, all 32 imported ACs, and all conservation gates are
mechanically green.
