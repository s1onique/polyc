# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT — implementation authorization, not an execution or completion report
Class: SELFHOST / ABI_CORE / COHERENT_OPERATOR_BUNDLE / PRODUCTION_AUTHORITY_TRANSFER
Priority: P0
Repository: the existing canonical local PolyC checkout (s1onique/polyc); remote availability is not assumed
Branch: existing main — no ceremonial per-ACT branch
Expected ENTRY_HEAD: 030e115ce8ed14ce41eacc3019e8787bad06ebfb
Expected ENTRY_TREE: 7f7c87909a2e4375f73408cacfd831c4b0c9d4a1
Binding predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01, five-commit CLOSE/PASS, executor-reported external terminality
Frozen selected bundle: BUNDLE-OPERATOR-CORE-01
Frozen ABI designation: ABI-CORE-OP-1
Frozen proposed selector: HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY
Current production PolyC decision authorities: 10 (9 parser + 1 AbiCpaShouldPrintAst)
Authorized migration: exactly three C-owned core-semantic decision sites, all in the selected bundle; no fourth site
Target if all three proven: 13 production PolyC decision authorities (decision sites, not files/symbols), with the same 9+1 predecessor authorities conserved
Existing graph: 52 nodes / 134 active mandatory edges, 34 SCCs / largest 19; E-TYP-0136 the sole historically proven production cut
SELFHOST_M2_ACHIEVED: NO; SLICE10_AUTHORIZED: NO; NEXT_TARGET: NONE.

## 0. Mission

Implement one coherent three-site production migration selected by RECON01.
The compiled PolyC component shall determine the operator classification for
each of the three frozen decisions, while the real C compiler continues to own
token objects, AST representation and graph mutation, type checking, IR and
code generation, allocation, diagnostics and all recovery.

The resulting production compiler must link and use a genuinely hcc-compiled
PolyC subject; it must not retain an active independent C copy of any of the
three selected decisions.

| Site ID | Historical live source | Frozen source-range SHA-256 | Semantic authority to transfer |
|---|---|---|---|
| SITE-COMPOUND-ASSIGN | src/prslib.c:1328..1348, parseCompoundAssign | 4d941407ee054e207586b3a4fb645caf8917e6b43fa467b79d50a75e1b54bb43 | Classify compound-assignment token and select the compound operator used in desugaring. C still applies compound_assign, type checks and AST construction. |
| SITE-VALID-POINTER-OP | src/ast.c:974..990, astIsValidPointerOp | bc06b0d757538f6c00ce0e96003cf5613823e98f4c48288c727cf9ac1dd82ac5 | Classify operator validity for pointer arithmetic; C still determines consequences, type error paths and AST ownership. |
| SITE-RANGE-OPERATOR | src/ast.c:2348..2358, astIsRangeOperator | 8c1acadaa4f1ae26d27c6be491812db2d16a8dd18528cb5cf2cc81d242b24f99 | Classify relational range operators used by IR/native lowering; C still performs range lowering and native code generation. |

These names, line ranges and digests are entry-selection identities, not
permission to copy stale source or invent numeric enums. The committed,
hash-checked selection contract
(`evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/c2/selected-core-bundle-contract.md`,
SHA-256 `bfffee46394ea2326d75496dce59afd4a7f42d91504d4a22ed82ccaee3df56e1`)
has priority over any summary. If any identity or binding content disagrees,
HALT_SOURCE_CONTRACT_MISMATCH rather than silently updating the contract.

## 0.1 Required PASS predicates

1. Three real production-authority transfers. All three selected C decision
   sites actively delegate to compiled PolyC in the normal production
   configuration. Selector-OFF is a genuine compiler built from the original C
   decisions; selector-ON compiles out those C decisions. Each C caller imports
   and reaches its PolyC decision at runtime; no site merely links an unused
   symbol or stays authoritative in C.
2. One coherent ABI contract. ABI-CORE-OP-1 has a source-derived scalar
   representation, unambiguous result/status domain and exact enum mappings.
   Every site is individually countable and testable.
3. Independence by site. The three semantic rules have separately attributable
   fixtures, live call-site/object evidence, and three independently executed
   post-migration PolyC-source mutations.
4. G0–G3 differential. G0 uses genuine C-only production TUs; G1/G2/G3 are
   independently compiled by three distinct compiler executables and agree
   with G0 across a source-derived, boundary-complete fixture and real
   compiled-program witnesses. All 12 ordered pairwise comparisons are
   recorded with each producer's executable digest.
5. Conservation and terminality. All ten predecessor authorities, the 376/376
   parser assertion sequence, historical lexer identities, factory invariants
   and gates remain conserved. Exactly five Factory-v2 commits,
   C0 RED → C1 EVIDENCE → C2 IMPL → C3 EVIDENCE → C4 CLOSE, with an external
   receipt after CLOSE.

A partial transfer of one or two sites is not this ACT's PASS. If a third site
cannot be safely implemented or proven, preserve the evidence and close a
truthfully classified HALT, with a bounded successor proposal. Do not redefine
the bundle to claim success.

## 0.2 What is and is not achieved

- Success transfers three operator decisions, not three full parser/AST
  functions, and not ownership of an AST or IR object.
- Neither a linked PolyC subject nor a pure fixture equivalence proves a
  production authority without active caller reachability and adverse mutation
  evidence.
- Do not claim fewer graph edges, SCC shrinkage or lower M2 ACT estimate merely
  because three decisions become PolyC-owned. A truthful zero additional graph
  cuts is acceptable.
- CSCR01-M1 is the predecessor's C-source experiment for only
  SITE-COMPOUND-ASSIGN (30 → 246 → 30). It may be cited as historical C-side
  evidence but cannot discharge any post-migration PolyC mutation, or the two
  untested C-authority sites.

## 1. C0 entry gate

Required terminal-entry checks (all measured in `evidence/.../c0/`):

```
ENTRY_HEAD=030e115ce8ed14ce41eacc3019e8787bad06ebfb
ENTRY_TREE=7f7c87909a2e4375f73408cacfd831c4b0c9d4a1
BRANCH=main
TRACKED_TREE_AND_INDEX_CLEAN=YES
GIT_REPLACE_REFS=0
RECON01_CLOSE_VERDICT=PASS
RECON01_PHASE_SEQUENCE=RED,EVIDENCE,IMPL,EVIDENCE,CLOSE
RECON01_POST_CLOSE_COMMITS=0
FROZEN_SELECTED_BUNDLE=BUNDLE-OPERATOR-CORE-01
FROZEN_SITE_SET={SITE-COMPOUND-ASSIGN,SITE-VALID-POINTER-OP,SITE-RANGE-OPERATOR}
PRODUCTION_POLYC_AUTHORITIES=10
PRODUCTION_GRAPH_NODES=52
PRODUCTION_ACTIVE_MANDATORY_EDGES=134
PRODUCTION_PROVEN_CUT_IDS={E-TYP-0136}
SCC_COUNT=34
SCC_LARGEST=19
```

Any entry mismatch is HALT_ENTRY_IDENTITY; do not reset, amend, rebase, git
replace, forcibly check out or fetch another HEAD to make the check green.

### 1.2 C0 negative evidence: the ignored exit 127

RECON01's C0 test-prefix-install raw log contains a shell exit 127 for a
malformed/fragmented CPA `-DABI_CPA_OBJECT=...` argument followed by
`make: ... Error 127 (ignored)`. This ACT treats it as an explicit entry
hazard, not as proof the predecessor's final gate was wrong.

The C0 RED reproduces it with an exact detector: the `test-prefix-install`
recipe's CMake invocation is truncated by a missing trailing backslash, so the
`-D` flags that follow it are executed by the shell as a separate command
(shell status 127) and never reach CMake. The current ACT must establish an
independently successful, fail-closed normal production configure/build/install
with the new selector ON, and must add an isolated negative test proving a
broken necessary CMake `-D` argument or subject path yields a nonzero fatal
status. No `-` ignored-error recipe prefix, `|| true`, false-green shell
pipeline or success based on later output is permitted for this build.

## 2. Authorized implementation scope

Permitted tracked paths, narrowly constrained to the selected three-site
migration and evidence:

```
src/prslib.c                                   # selected compound-assignment decision/caller only
src/ast.c                                      # selected pointer-op and range-op decisions only
src/CMakeLists.txt                             # selected new subject/selector/build wiring
Makefile                                       # producer, prerequisites, fail-closed verification
src/*.h                                        # ONLY if a specific selected ABI declaration requires it
src/abi-core-op-*.c, src/abi-core-op-*.h        # optional; only if the frozen scalar ABI needs host glue
src/tests/*                                    # only bounded new core regression tests
tools/bootstrap/selfhost-core-operator-*.HC    # one coherent PolyC subject
tools/quality/core-operator-implement01-*.HC    # substantive new verifiers in PolyC only
docs/acts/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01.md
docs/factory/act-handoff-map.tsv                # exactly one row
docs/ROADMAP.md                                 # one bounded append
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/**
```

Forbidden: unrelated compiler fixes; edits to preexisting bootstrap subjects;
edits to previously closed ACT/HANDOFF/evidence; changes to E-MUT-0137's
historical ledger; a new dependency; Python; weakening existing factory or
quality gates; new raw cross-language pointer layout or ownership; unsafe
callbacks or nonlocal longjmp through active PolyC frames; missing error/status
separation; mutating existing tests to pass; ceremonial ACT branches; direct
source mutation on authoritative main for adverse experiments; unverified
graph-cut or M2 claims.

## 3. Frozen ABI, component boundaries and source-derived fixtures

### 3.1 ABI-CORE-OP-1

At C1 the exact selected predecessor ABI is bound to a single
`abi-core-op-1.tsv` containing: operation/site ID, input count, type and source
enum domain, input extraction order, return type, legal result domain,
invalid-input behavior, status/result separation, normalization, C wrapper,
PolyC exported symbol(s), host object dependencies and permitted side effects.

- PolyC consumes copied scalar `token_type`, `keyword_id`,
  `AstBinOp`/operator values only when the actual site requires them. Never
  pass raw `Lexeme*`, `Ast*`, `List*`, `Map*`, `Cctrl*`, `Arena*`,
  pointer-bitcast handles or callbacks in this scalar-only bundle.
- Preserve the original C evaluation ordering, short-circuiting,
  invalid-input behavior and any out-parameter writes.
- The new component is total for every representable input in its bound domain,
  pure, deterministic, allocation-free, callback-free, with no global mutable
  state and no recovery frames. Legacy C holds all memory, diagnostic and
  recovery responsibilities.
- The actual C-only predicate must remain available only under the
  selector-disabled oracle path; stage0 must explicitly compile with the
  selector OFF and never depend on its own output.
- Record target-specific exported Mach-O symbol names and relocation types
  from the actual produced objects; a textual `extern` alone is not evidence of
  linkage.

If existing PolyC language/type limitations prevent this scalar ABI,
HALT_ABI_UNSAFE_OR_COMPILER_LIMITATION with minimal reproducer.

### 3.2 Complete fixture partitioning

At C1 fixture rows are derived mechanically from live C enum declarations,
actual C conditions and the frozen source ranges. The expected result is
generated from an independent frozen G0 oracle, not by copying the PolyC
implementation or calling PolyC from G0. Each fixture row contains:

```
fixture_id  site_id  source_git_blob  source_range_sha256
input_domain  input_1  input_2_if_present  expected_value
expected_status  semantic_partition  reachable_by_real_compiler
oracle_object_sha256  expected_witness_id
```

Per-site minimum partitions: every enumerated positive classification, every
enumerated negative classification, representative adjacent/boundary values,
unknown/invalid values where the C API defines behavior, and actual
source-reachable contexts for the downstream effect.

### 3.3 Genuine oracle and producer matrix

| Generation | Authorized producer | Subject/oracle property |
|---|---|---|
| G0 | actual C compiler and real selector-OFF production C TUs | All three original C predicates active; no reference to the new PolyC subject |
| G1 | entry-frozen build/host-stage0/hcc or the actual stage0 producer named by the live contract | New PolyC source, no C decision active in selected production ON paths |
| G2 | real ./hcc from a defined generation | Same source/ABI |
| G3 | actual hcc-bootstrap02 producer from the live generation graph | Same source/ABI |

The three PolyC producer executables must have pairwise distinct digests or the
declared independence property is UNPROVEN. All 12 ordered G0/G1/G2/G3
pairwise comparisons must be row-by-row equal and include each site
separately.

## 4. Production source and build-graph constraints

### 4.1 One bundle, three sites

Refactor each selected decision into the smallest dedicated wrapper/delegation
seam preserving its exact original callers and C-side state changes. When
`HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY=ON`, the decision itself is made
exclusively in compiled PolyC. The callsite must not secretly repeat the legacy
C predicate to choose whether to use the PolyC result. The selector-OFF arm is
a behaviorally faithful C oracle.

For each site independently demonstrate:

- G0: caller decision is C, PolyC symbol references = 0
- G1 ON: caller imports the actual PolyC decision; the real production binary links it
- G1 ON: the legacy C decision's condition/mask/comparison is absent from the active caller
- G1 ON: mutation of the PolyC rule changes the intended compiler semantic channel
- G1 ON: mutation of the dormant C-only legacy rule does NOT change the caller object/semantic result

The two `src/ast.c` functions are called outside `src/ast.c` in relevant
compiler subsystems. All production call sites must reach the new exported
wrapper/decision and no other C duplicates may remain active.

### 4.2 Effective Makefile/CMake graph

Every object prerequisite must be present at rule parse time; GNU Make ordinary
prerequisites are immediately expanded. Place variables before consuming
rules. For CMake, ensure the generated object has an explicit
producer/dependency in the same effective build graph; link the subject once.

Required adverse build probes (in disposable build roots): remove/corrupt the
PolyC object, omit its producer, change its source after initial build,
substitute an object with a wrong exported symbol, introduce a duplicate
symbol, pass a malformed CMake `-D` argument, and force a selector-ON link
without the subject.

## 5. Executable Factory-v2 lifecycle

Exactly one non-merge, append-only commit per phase: C0 RED, C1 EVIDENCE,
C2 IMPL, C3 EVIDENCE, C4 CLOSE. Every message is validated with the current
Factory-v2 trailer checker before committing.

### C0 — RED
Identity, freeze and five falsifiable prerequisites. See
`evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c0/`.

### C1 — EVIDENCE
Source-bound three-way oracle and implementation plan: enum domains, per-site
fixtures, the ABI-CORE-OP-1 contract, the exact producer graph, the fail-closed
build proof and the mutant plan.

### C2 — IMPL
Coherent production delegation: one PolyC operator component under
`tools/bootstrap/`, narrowly bounded wrapper/callsite changes to
`src/prslib.c` and `src/ast.c`, and the Makefile/`src/CMakeLists.txt` wiring.

### C3 — EVIDENCE
Four generations, mutations, controls and conservation: all 12 ordered
differentials, three independent PolyC mutations, C-OFF/C-ON dormancy
controls, NC-01..NC-24, and every baseline.

### C4 — CLOSE
Immutable handoff and external terminality.

## 6. Frozen negative-control contract — 24 IDs

| ID | Adverse condition | Required reason-specific detector |
|---|---|---|
| NC-01 | Wrong entry HEAD/TREE, branch or fabricated predecessor CLOSE | ENTRY_OR_PREDECESSOR_IDENTITY_MISMATCH |
| NC-02 | Change one frozen predecessor path SHA | F14_FROZEN_PREDECESSOR_MISMATCH |
| NC-03 | Drop or invent one of the three frozen site IDs | FROZEN_BUNDLE_SITE_SET_MISMATCH |
| NC-04 | Substitute a different original source-range hash or later-phase blob | SOURCE_OR_PHASE_PROVENANCE_MISMATCH |
| NC-05 | Forge an input enum or selector code not derived from source | ENUM_OR_ABI_DOMAIN_MISMATCH |
| NC-06 | Alias an invalid return status with a valid scalar value | ABI_STATUS_RESULT_COLLISION |
| NC-07 | Replace scalar ABI with raw AST/Map/List/Cctrl/Arena layout | UNSAFE_HOST_LAYOUT_TRANSFER |
| NC-08 | Add unsafe callback or cross-PolyC-frame longjmp/recovery | UNSAFE_RECOVERY_OR_CALLBACK |
| NC-09 | G0 oracle references or links the PolyC subject | G0_ORACLE_NOT_C_INDEPENDENT |
| NC-10 | Substitute one G1–G3 producer binary with another or fake producer digest | PRODUCER_GENERATION_NOT_INDEPENDENT |
| NC-11 | Change a fixture expected value or omit a positive/negative partition | SOURCE_BOUND_FIXTURE_MISMATCH |
| NC-12 | Drop/duplicate one row/site in joined fixture population | FIXTURE_SET_INTEGRITY_FAILURE |
| NC-13 | Production selector ON still executes C compound-assignment decision | CA_C_AUTHORITY_NOT_RETIRED |
| NC-14 | Production selector ON still executes C pointer-operation decision | PO_C_AUTHORITY_NOT_RETIRED |
| NC-15 | Production selector ON still executes C range-operation decision | RO_C_AUTHORITY_NOT_RETIRED |
| NC-16 | Link correct PolyC subject but call it nowhere for one site | DORMANT_LINKED_POLYC_SUBJECT |
| NC-17 | Missing/stale/wrong/duplicate subject or Makefile prerequisite expanded empty | BUILD_GRAPH_SUBJECT_PROVENANCE_FAILURE |
| NC-18 | Ignore a failed CMake argument/recipe (including the prior exit 127 pattern) | IGNORED_BUILD_FAILURE |
| NC-19 | Count one PolyC mutation as proof for all three sites | CAUSAL_EXECUTION_ID_DOUBLE_COUNT |
| NC-20 | Mutate subject source without changing linked object or semantic behavior | CAUSAL_MUTANT_UNLINKED_OR_DORMANT |
| NC-21 | Call failed mutant compiler build a semantic difference | UNQUALIFIED_MUTANT_BUILD_FAILURE |
| NC-22 | Retire C-OFF oracle or claim C-ON affected by dormant C mutation | ORACLE_OR_C_DORMANCY_INVALID |
| NC-23 | Claim 13 authorities from symbols only, or invent graph cut/SCC change | AUTHORITY_OR_GRAPH_FALSE_CREDIT |
| NC-24 | Forge an AC PASS, missing control, clean-prefix claim or known FAIL relabel | FALSE_PASS_OR_BASELINE_RECLASSIFICATION |

Mandatory verifier selftests: delete one frozen control row, change one ID,
substitute one mutated source hash, fabricate a PASS line, misbind a physical
experiment ID to a different site, and suppress one prerequisite object. All
must reject the false claim for the intended reasons.

## 7. Exactly 50 mandatory acceptance criteria

All 50 IDs and owners are frozen at C0 in
`evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c0/frozen-contracts.tsv`;
every row has source/command/object/fixture/evidence paths and a measured
status. C3 can discharge AC01–AC49; only external post-CLOSE terminality
discharges AC50.

The acceptance ledger must distinguish NOT_RUN, FAIL, UNPROVEN, DEFERRED and
PASS. An absent evidence path is never PASS. No control can be silently
dropped or repurposed to reach 50/50.

## 8. Minimum machine-readable evidence and replay protocol

Every table must include exact IDs and source/producer/object digests where
appropriate. Record the raw command, exit code, stdout/stderr identity,
mutation source difference and restored hash. Evidence must be independently
replayable without calling a hardcoded status printer.

```
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/
  c0/ entry-identity.txt predecessor-terminal.tsv predecessor-freeze.tsv
       selected-site-freeze.tsv authorities.tsv graph-baseline.tsv
       hermetic-baseline.txt baselines.txt five-reds.tsv frozen-contracts.tsv
  c1/ enum-domain.tsv oracle-site-provenance.tsv ownership-effects.tsv
       g0-oracle-build.txt fixture-ca.tsv fixture-po.tsv fixture-ro.tsv
       fixture-independent.tsv semantic-witnesses.md abi-core-op-1.tsv
       generation-plan.tsv producer-build-graph.txt strict-build-negative.txt
       scope-and-mutant-plan.tsv
  c2/ polyc-subject-build.txt site-ca-linkage.tsv site-po-linkage.tsv
       site-ro-linkage.tsv ownership-conservation.tsv selector-build-matrix.tsv
       build-negative-controls.tsv production-object-relocations.tsv
       effective-compile-and-link-commands.txt
  c3/ generation-fixture-differential.tsv generation-producer-proof.tsv
       mutant-ca.tsv mutant-po.tsv mutant-ro.tsv mutant-restoration.tsv
       site-isolation.tsv c-off-on-dormancy.tsv independent-authority-proof.tsv
       semantic-conservation.tsv negative-control-join.tsv
       control-verifier-selftest.tsv predecessor-authorities.tsv
       authority-ledger.tsv graph-after.tsv parser-conservation.txt
       non-green-conservation.txt gates-and-factory.txt ac01-ac49-ledger.tsv
  c4/ terminality-plan.txt
```

New substantive verifier code is PolyC under `tools/quality/`; POSIX shell/AWK
may act as bounded independent evidence drivers but not as an untested
replacement for the substantive verifier. No Python.

## 9. Explicit HALT classifications

```
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_EVIDENCE_UNAVAILABLE
HALT_SOURCE_CONTRACT_MISMATCH
HALT_F14_FROZEN_PREDECESSOR_MISMATCH
HALT_UNAUTHORIZED_SOURCE_SCOPE
HALT_ABI_UNSAFE_OR_COMPILER_LIMITATION
HALT_G0_NOT_C_INDEPENDENT
HALT_FIXTURE_SOURCE_OR_STATUS_MISMATCH
HALT_G1_G2_G3_PRODUCER_NOT_INDEPENDENT
HALT_SELECTOR_OR_EFFECTIVE_PREREQUISITE_INVALID
HALT_IGNORED_BUILD_FAILURE
HALT_SUBJECT_MISSING_STALE_OR_WRONG_SYMBOL
HALT_INCOMPLETE_THREE_SITE_AUTHORITY_TRANSFER
HALT_CORE_SEMANTIC_DIFFERENTIAL
HALT_CAUSAL_MUTANT_BUILD_FAILURE
HALT_CAUSAL_MUTANT_DORMANT_OR_UNLINKED
HALT_CAUSAL_WITNESS_UNPROVEN_CA
HALT_CAUSAL_WITNESS_UNPROVEN_PO
HALT_CAUSAL_WITNESS_UNPROVEN_RO
HALT_MUTATION_NOT_RESTORED
HALT_SITE_ISOLATION_FAILURE
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_PREDECESSOR_AUTHORITY_REGRESSION
HALT_PARSER_LEXER_OR_GATE_REGRESSION
HALT_EVIDENCE_ID_JOIN_OR_FALSE_PASS
HALT_FACTORY_V2_RANGE_APPEND_ONLY_TRAILERS
HALT_EXTERNAL_POST_CLOSE_TERMINALITY
```

A terminal HALT may truthfully preserve which of three sites were implemented
and which verified, but must not label the bundle complete or claim three new
authorities. No unauthorized sixth commit, history rewrite, gate weakening or
opportunistic scope expansion is permitted to turn HALT into PASS.

## 10. HANDOFF, programme implications and next authorization

The terminal HANDOFF must distinguish (a) source-derived three-site completion
from a three-export-symbol count, (b) the predecessor's original C mutation
from each new post-transfer PolyC mutation, (c) behavioral conservation from
semantic-authority retirement, and (d) genuine production graph cuts from mere
operator delegation.

A PASS would constitute a first proven multi-site core-semantic implementation
ACT, enabling more coherent bundles in type/IR/codegen. It does not complete
whole-parser self-hosting, eliminate shared C data structures, demonstrate M2,
or establish a validated future ACT count.

No further successor is preselected. The proposed next class, after successful
closure and independent review, is an evidence-backed
CORE_SEMANTIC_BUNDLE_RECON or an ABI prerequisite selected by the actual
remaining bootstrap-critical graph — not an automatic SLICE10.
