# ACT-POLYC-SELFHOST-PARSER-SLICE08

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-BOUNDARY / PRODUCTION-AUTHORITY-TRANSFER
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main` (no ACT branch is created as ceremony)
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07`
(closed with `ACT-Verdict: PASS`; its evidence tree, HANDOFF and ACT
document are closed evidence under F14 and are NOT modified here)
**Expected ENTRY_HEAD:** `3eb8afa4f02ae4c5ff9e86cc32ac34fb4f8c2f9b`
**Expected ENTRY_TREE:** `24655e17d83e82957bc9a8330bf0487c13b05028`
**Target:** `SUB-002` -- the default-arm termination decision
**Successor:** none preselected

---

## 0. Mission

Migrate exactly ONE legacy-C semantic decision -- the one that
determines whether a parsed statement TERMINATES a `default:` arm --
from production-authoritative C into production-authoritative, compiled
PolyC.

The predecessor has already migrated SEVEN parser authorities:

```text
BootstrapCalcPadding                   -> POLYC production authority
BootstrapValidPostControlFlowToken     -> POLYC production authority
BootstrapOperatorPrecedence             -> POLYC production authority
BootstrapAstBinOpFromToken              -> POLYC production authority
BootstrapAstUnaryOpFromToken            -> POLYC production authority
BootstrapSwitchArmTerminates            -> POLYC production authority (SUB-001)
BootstrapCompoundBlockAppendsStatement  -> POLYC production authority
```

SLICE08 must migrate exactly ONE more:

```text
the default-arm termination decision
  -> BootstrapDefaultArmTerminates
  -> POLYC production authority
```

This ACT does NOT claim whole-parser self-hosting.  It does NOT
implement `parseStatement`, `parseExpr`, `parseDefaultStatement` or
`parseSwitchStatement`, and it does NOT transfer any AST node, list,
allocation, recovery, diagnostic, callback, symbol-table or token-stream
ownership.

### Required final result

```text
DEFAULT_ARM_TERMINATION_AUTHORITY = POLYC
LEGACY_DEFAULT_ARM_C_AUTHORITY    = RETIRED
EIGHTH_POLYC_PARSER_AUTHORITY     = ESTABLISHED
```

### The frozen target

```text
CANDIDATE   = SUB-002
DECISION    = DEFAULT_ARM_TERMINATION
SOURCE      = src/parser.c:1683..1684
SHA256      = a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
FUNCTION    = parseDefaultStatement
CALLER      = parseSwitchStatement
ABI         = I64 ast_kind -> I64 terminate
SEAM        = the single `if (...) break;` in the default-arm loop
SELECTOR    = HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES
```

The exact live source at the entry commit:

```c
        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
                || stmt->kind == AST_GOTO) break;
```

The five terminating kinds are the live `src/ast.h` values
`AST_COMPOUND_STMT` 274, `AST_CASE` 287, `AST_BREAK` 280,
`AST_RETURN` 270, `AST_GOTO` 258.

`AST_DEFAULT` 293 is **deliberately absent** from this condition,
although it **is** present in the already-migrated SUB-001 condition.
That difference is SUB-002's own distinguishing property, and it is a
positive (must-not-terminate) sentinel in the frozen fixture.

---

## 1. Binding authority

The repository's actual, unmodified RECON07 `c2/selected-*` contract
set and `selected-contract-hashes.tsv` OVERRIDE any secondary summary.
Every exact exported symbol, selector spelling, enum value, fixture row
identity, failure detector, expected output and witness command is read
from those committed files at C0.

The frozen contract set is:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/
  selected-source-and-identity.md
  selected-production-seam.md
  selected-abi.md
  selected-enums-fixture.tsv
  selected-real-c-oracle.md
  selected-causal-contract.md
  selected-generation-and-provenance.md
  selected-negative-controls.md
  selected-conservation-contract.md
  selected-red-contract.md
  selected-scope-and-ownership.md
  selected-ranking-and-exclusions.tsv
  successor-authorization.md
  selected-contract-hashes.tsv
```

If any of these is missing, contradictory or hash-invalid, the ACT
HALTs (`HALT_FROZEN_SUCCESSOR_CONTRACT_MISMATCH` /
`HALT_FROZEN_ARTIFACT_MUTATED`) rather than reconciling a conflict.

---

## 2. The shared-rule question (SUB-001 vs SUB-002)

SUB-002 shares a five-kind membership SHAPE with the already-migrated
SUB-001, but the two production call sites are NOT interchangeable:
SUB-001 terminates the `case:` arm and includes `AST_DEFAULT` 293;
SUB-002 terminates the `default:` arm and excludes it.

`RECON07` proved SUB-002 is causal by a DIFFERENT arm mutation than
SUB-001's, and this ACT's C0 RED-5 (executed) proves by REAL EXECUTION
that the existing SUB-001 PolyC component returns the WRONG answer for
the frozen SUB-002 fixture at row 35 (kind 293, `AST_DEFAULT`).

---

## 3. Scope

### Authorized to change

```text
src/parser.c                                       # the seam ONLY
src/CMakeLists.txt                                 # the selector and the wiring
Makefile                                           # the build targets
tools/bootstrap/selfhost-parser-slice08.HC         # NEW: the PolyC component
tools/quality/parser-slice08-*.HC                  # NEW: the PolyC verifiers
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE08.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/**
```

### Forbidden

```text
src/ast.c src/prslib.c src/prsutil.c src/cctrl.c src/lexer.c
src/transpiler.c src/ir.c src/x86.c
any OTHER tools/quality/** or tools/bootstrap/** file
any historical evidence/ directory
any closed ACT or HANDOFF document
.githooks/**
```

No new dependency.  No Python.  No new ACT branch.  No unrelated
refactor.  No rewriting of any existing test or fixture.

The change to `src/parser.c` is limited to:

1. factoring the condition at lines 1683-1684 into the named helper,
2. adding the `#ifdef`-guarded PolyC delegation arm to that helper,
3. adding the object-level oracle wrapper adjacent to it, and
4. changing the ONE call site to call the helper.

It MUST NOT change the `do { ... } while (1)` loop, the
`parseStatement(cc)` call, the `listAppend`, the token-cursor
handling, the diagnostics, or anything else in the file.

---

## 4. The commit lifecycle

| Commit | Phase | Binding output |
|---|---|---|
| C0 | RED | Entry, predecessor SHA freeze, exact contract lock, fresh baselines, inherited/new controls, five executable RED witnesses |
| C1 | EVIDENCE | Genuine G0 C oracle, tight source binding, 41-row fixture, independent enum checker, production-build wiring design, provenance plan |
| C2 | IMPL | Single PolyC SUB-002 component/adapter, selector, object/link rules, first real GREEN and production-authority evidence |
| C3 | EVIDENCE | G0-G3 distinct producer proof, full differential, negative controls, POST-POLYC mutation/restoration, conservation, Factory gates, independent AC join |
| C4 | CLOSE | HANDOFF/roadmap/map, exactly one terminal Factory-v2 CLOSE, external read-only terminality |

Do not commence C1 if the exact entry, source binding or frozen contract

---

## 5. The mandatory acceptance criteria

Exactly FIFTY predicates, frozen at C0 in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c0/mandatory-ac-contract.tsv`,
joined by exact ID to observed facts at C3.  No predicate is waived and
no predicate is counted twice.

```text
AC01 Exact entry HEAD/tree/main, clean worktree and zero replace refs.
AC02 RECON07 five-commit PASS CLOSE and successor authorization genuinely verified.
AC03 All RECON07 selected-* path/hash bindings verified from actual committed bytes.
AC04 All earlier closed/HALT predecessors frozen and preserved without rewrite or relabel.
AC05 Seven predecessor PolyC production parser authorities independently re-proven.
AC06 Fresh parser, lexer, broad corpus, cross-target, policy and gate baseline recorded.
AC07 Only SUB-002 authorized; no unauthorized source, Python, dependency or ACT branch.
AC08 Exactly 50 AC IDs, inherited control IDs and 18 new IDs frozen before outcomes.
AC09 Exact SUB-002 range/SHA/function and five-kind rule rebound to live source.
AC10 Five independent C0 REDs executed and reason-specific failures recorded.
AC11 Genuine real production src/parser.c C-only G0 object exists, selected selector OFF.
AC12 G0 imports no new SUB-002 PolyC symbol and has bound host compiler provenance.
AC13 Live AstKind constants/bitset and 41-row fixture independently source-derived.
AC14 Frozen 41-row fixture IDs, partitions and expected semantics preserved exactly.
AC15 Independent fixture checker detects missing/duplicate/unknown/wrong expected IDs.
AC16 All G0 fixture outputs match source-derived legacy decision on exact row IDs.
AC17 Real pristine compiler witness established on RECON07's frozen observation channel.
AC18 ABI scalar projection, return encoding and host AST/cursor ownership conserved.
AC19 Existing SUB-001 decision site proven separate and semantically conserved.
AC20 New PolyC component exports frozen symbol and implements entire five-kind rule.
AC21 Dedicated selector ON/OFF genuinely controls selected production branch.
AC22 Active parser object imports new symbol; subject defines it; executable links and calls.
AC23 Active C termination predicate retired; no decorative or parallel C authority.
AC24 Function-scoped disassembly/relocations exclude unrelated comparisons as proof.
AC25 Host AST, allocation, callbacks, token, recovery, diagnostics stay C-owned.
AC26 Missing, stale, wrong-arch, wrong-symbol provider demonstrably fails closed.
AC27 OFF mode is real C-authoritative production TU with no new PolyC reference.
AC28 G1/G2/G3 compiler binaries distinct in actual bytes and verifiable ancestry.
AC29 Each generation compiles the newly migrated real .HC component independently.
AC30 G0-G3 each execute all frozen 41 rows with bound input/output identities.
AC31 All 12 ordered G0-G3 pairwise semantic comparisons identical row by row.
AC32 Deterministic identical objects do not replace producer-independence evidence.
AC33 All RECON07 frozen successor controls executed/verified by unchanged IDs and subjects.
AC34 All 18 new S8 negative controls executed, sensitive, restored/contained.
AC35 No vacuous control, double-discharge, wrong-subject or forged prior event.
AC36 PRE-C-MUTANT cited as RECON07 prior only with authentic execution identity.
AC37 POST-POLYC-MUTANT newly executed on the target PolyC source after delegation.
AC38 PolyC-mutant real production compiler build succeeds and target object changes.
AC39 Real witness changes on frozen declared channel; semantic fixture row IDs differ as predicted.
AC40 Byte-identical source/object restoration recovers pristine fixture and witness.
AC41 Conditional fresh C-OFF C-mutant executed separately if required by frozen contract.
AC42 All generation/object/caller/provenance and subject/phase/execution-ID joins independently checked.
AC43 Parser 376/376 over 90 files, unchanged ordered MD5, no new parser failure IDs.
AC44 Lexer direct differentials and unchanged historical LEXER07 failure identities.
AC45 Cross-target 67, Python 12 and F-POLYC-TOOLS availability reported truthfully.
AC46 gate-fast and gate-push actually execute serially and PASS with subject authority.

---

## 6. The negative controls

### Inherited (23)

Copied VERBATIM, with unchanged IDs and subjects, from the committed
RECON07 bytes:

* `c2/selected-negative-controls.md` -- `SL-IC-01..04`,
  `SL-EC-01..06`, `SL-RC-01..05`, `SL-CC-01..05`, `SL-PV-01` (20)
* `c2/selected-causal-contract.md` --
  `RECON07-SUB-002-PRE-C-MUTANT`,
  `RECON07-SUB-002-POST-POLYC-MUTANT`,
  `RECON07-SUB-002-SLICE08-C-OFF-C-MUTANT` (3)

`SL-CC-01` (subject: the C decision, phase: PRE-MIGRATION) and
`SL-CC-05` (subject: the compiled PolyC component, phase:
POST-MIGRATION) MUST NOT be the same experiment.

### New (18), in a disjoint `S8-*` namespace

```text
S8-FC-01 Delete one of the frozen 41 fixture IDs
S8-FC-02 Duplicate a fixture row ID
S8-FC-03 Inject unknown fixture ID
S8-FC-04 Flip expected result on one five-kind positive row
S8-FC-05 Change source-bound enum value/source digest
S8-SA-01 Selector ON but legacy C predicate still drives termination
S8-SA-02 PolyC symbol linked but unused by SUB-002 caller
S8-SA-03 Selector OFF but new PolyC subject still used as G0
S8-SA-04 Reuse SUB-001 subject as if separately proven SUB-002
S8-SA-05 Flip one frozen five-kind outcome in the SUB-002 PolyC function
S8-PV-01 Relabel G1 binary/object as G2
S8-PV-02 Relabel G2 as G3 or reuse one binary
S8-PV-03 Link wrong symbol or omit provider subject
S8-PV-04 Insert unrelated cmp/tst outside selected function
S8-PV-05 Alter one stage fixture result or delete generation ID
S8-CC-01 Mutate only PolyC predicate in actual production
S8-CC-02 Attempt to credit RECON07 C mutant as new S8 PolyC mutant
S8-CC-03 Fail to restore one PolyC source byte or leave mutant object linked
```

A control that is not executed is UNPROVEN, not PASS.  If two control
IDs are discharged by ONE physical experiment, BOTH rows MUST say so
explicitly, name the shared execution ID, and MUST NOT claim
independence.

---

## 7. The HALT taxonomy

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_CLOSE_UNVERIFIED
HALT_FROZEN_SUCCESSOR_CONTRACT_MISMATCH
HALT_FROZEN_ARTIFACT_MUTATED
HALT_EXISTING_SEVEN_AUTHORITIES_UNVERIFIED
HALT_SOURCE_RANGE_OR_ENUM_MISMATCH
HALT_SUBJECT_AUTHORITY_AMBIGUOUS
HALT_ABI_OR_HOST_OWNERSHIP_MISMATCH
HALT_G0_NOT_REAL_PRODUCTION_OBJECT
HALT_FIXTURE_OR_ORACLE_UNPROVEN
HALT_WITNESS_NOT_BOUND
HALT_BUILD_GRAPH_MISSING_SUBJECT
HALT_PRODUCTION_DELEGATION_UNPROVEN
HALT_LEGACY_C_AUTHORITY_STILL_ACTIVE
HALT_G1_G2_G3_PROVENANCE
HALT_FOUR_STAGE_DIFFERENTIAL
HALT_FROZEN_CONTROL_WRONG_SUBJECT
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_POLYC_MUTANT_COMPILER_BUILD_FAILURE
HALT_CAUSAL_OBSERVATION_CHANNEL
HALT_MUTATION_RESTORATION
HALT_NEW_PARSER_OR_LEXER_FAILURE
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_V2_OR_F14_OR_APPEND_ONLY
HALT_MANDATORY_AC
HALT_TERMINALITY
```

A HALT does NOT undo the seven already-verified production authorities,
does NOT turn historical failures into regressions, and does NOT grant a
fallback target.  `NEXT_TARGET=NONE` if SLICE08 HALTs.  Any remedy
requiring work outside scope is a separate new ACT, not a stealth
extension of this one.

---

## 8. The evidence tree

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/
  c0/  entry-identity.txt predecessor-close-verification.txt
       predecessor-freeze.tsv selected-contract-bindings.tsv
       selected-contract-hashes-verification.tsv
       mandatory-ac-contract.tsv inherited-controls-contract.tsv
       new-controls-contract.tsv seven-production-authorities.tsv
       baseline-parser.txt baseline-lexer.txt baseline-lexer07.txt
       baseline-cross-target.txt baseline-tool-policy.txt
       baseline-gates.txt red-reproduction.txt
  c1/  selected-source-and-abi.txt c-only-g0-production-object.txt
       live-enums-and-rule.tsv source-bound-fixture.tsv
       independent-fixture-verification.txt
       witness-and-observation-contract.txt
       stage-compiler-provenance-plan.tsv build-prerequisite-preflight.txt
  c2/  production-source-delta.txt polyc-subject-source-and-symbol.txt
       selector-and-build-graph.txt effective-cmake-and-make-commands.txt
       production-function-disassembly.txt object-import-export-linkage.txt
       fixture-first-green.txt seven-authorities-conservation.txt
       provider-fail-closed.txt
  c3/  generation-provenance.tsv g0-g3-41-row-differential.tsv
       all-12-ordered-pairs.tsv independent-live-enum-recompute.txt
       inherited-controls-join.tsv new-controls-join.tsv
       pre-c-mutant-citation.txt post-polyc-mutation-and-restoration.txt
       conditional-c-off-mutation.txt function-scoped-authority-audit.txt
       producer-build-graph-audit.txt parser-conservation.txt
       lexer-direct-conservation.txt lexer07-failure-identities.txt
       cross-target-and-tool-policy.txt gate-fast.txt gate-push.txt
       factory-invariants.txt immutable-predecessor-check.txt
       mandatory-ac-status.tsv
  c4/  terminality-plan.txt
```

`c4/terminality-plan.txt` is written BEFORE the CLOSE commit and is a
PLAN, not a fabricated after-CLOSE receipt.  The external post-CLOSE
receipt must remain OUTSIDE the tracked terminal commit.

---

## 9. Serial execution

`/tmp/holyc-asm.s` is shared in this compiler.  Compiler rebuilds, JIT
runs, tests and gates MUST NOT overlap unless their scratch paths are
proven disjoint.  Every command and exit code is captured.

AC47 Factory-v2, append-only, F14, closure status, patch hygiene, freeze all PASS.
AC48 C0-C3 commits valid phases/trailers, no amend/replay/unauthorized migration.
AC49 Exactly 49 ACs independently evidenced PASS at C3, AC50 only DEFERRED_TO_CLOSE.
AC50 One terminal CLOSE, correct trailer/range and independent external post-CLOSE terminality PASS.
```

AC01..AC49 MUST be proven PASS before C4.  AC50 alone is
`DEFERRED_TO_CLOSE` and is discharged only by an external, read-only,
post-CLOSE observation that is NOT written back into the terminal commit.

fails C0.  Do not commence C2 if a genuine G0 oracle cannot be built and
source-verified.  No commit is rewritten, amended, replayed or
force-pushed.


Therefore this ACT creates a DISTINCT exported PolyC entry point,
`BootstrapDefaultArmTerminates`, in its own source file
`tools/bootstrap/selfhost-parser-slice08.HC`.  Duplicating a tiny pure
rule is preferable to an unprovable shared authority.

`HALT_SUBJECT_AUTHORITY_AMBIGUOUS` applies if the frozen contract
cannot be honoured without deviating from it.
