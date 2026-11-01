# ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02

Factory-Version: 2
Lifecycle: AUTHORIZATION ARTIFACT — implementation contract; not an execution report
Class: SELFHOST / ABI_CORE / BUNDLED_CODEGEN_AUTHORITY_MIGRATION
Priority: P0
Prepared: 2026-11-01
Repository: existing local PolyC checkout
Branch: existing main, no per-ACT branch
Expected ENTRY_HEAD: fd8d32e2a295f1a4b9239f552d20f12f416b33f0
Expected ENTRY_TREE: cd467e521def0633d5aa88a71b97b739ccadb12b
Predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03, PASS / PASS_SELECTED_CORE_BUNDLE
Selected bundle: CAND-CMP-CC-A64
Frozen ABI: ABI-A64-CMP-CC-1
Frozen contract SHA-256: 77e2a0d5168f02b9f8b550319e60ea32dc6a9f59064a4f54fd2b209ae735f681
Production PolyC authorities: 13
Correction-inclusive causally backed authorities: 13
Production graph: 52 nodes, 134 mandatory edges, 34 SCCs, largest 19; sole historical proven cut E-TYP-0136
SELFHOST_M2_ACHIEVED=NO; SLICE10_AUTHORIZED=NO
Publication: No push, fetch, rebase, amend, reset or force-update.

## 0. Mission and decision boundary

Promote the three members of the source-selected CAND-CMP-CC-A64
AArch64 comparison/condition-code bundle from production-authoritative C
to production-authoritative compiled PolyC through ABI-A64-CMP-CC-1,
preserving the independently operating selector-OFF C oracle.

This ACT authorizes the implementation ONLY if the frozen RECON03
successor contract proves internally coherent under an independent C0
audit. The contract's own words are binding: it "does not authorize
implementation", and the successor "may not assume anything in this
contract that it has not re-measured".

Only PASS qualifies as three new production authorities. The target is
13 -> 16, but the count is earned by three distinct, load-bearing
compiler decisions and three independent post-migration causal
experiments; neither three exports nor one linked object alone
suffices. NEW_GRAPH_CUTS is determined by actual edge removal and may
be zero. No M2/self-hosted generation claim is authorized.

### 0.1 Fail-closed prerequisite

Four discrepancies identified in RECON03's supplied frozen material must
be audited before any authoritative production edit. If the frozen
contract is contradictory or the third authority cannot be implemented
without changing its exact ABI, HALT_CONTRACT_INCONSISTENT /
HALT_CSET_ABI_NO_OBSERVABLE_OUTPUT, preserve the evidence, and propose a
separately authorized forward-only successor-contract correction. Do not
make up a U0 output channel, mutate closed evidence, or relax the
three-site pass criterion.

### 0.2 Frozen bundle membership

```text
SITE-A64-CC-FOR   aarch64CcFor      src/aarch64.c
SITE-A64-CC-INV   aarch64CcInvFor   src/aarch64.c
SITE-A64-CSET     aarch64EmitCSet   src/aarch64.c
```

RECON03 reported three separate successfully rebuilt C-mutant compilers
with byte-identical source restorations, and acknowledged the coupling:
aarch64EmitCSet calls aarch64CcFor. These are pre-migration C
experiments, not substitutes for three new post-migration PolyC
experiments.

### 0.3 Authorized tracked paths

```text
src/aarch64.c                       # only three selected seams and justified adjacent host projection
src/CMakeLists.txt                  # dedicated selector, correct object/link configuration
Makefile                            # subject build, effective prerequisites and fail-closed checks
tools/bootstrap/selfhost-a64-cmp-cc.HC  # one new PolyC component
tools/quality/abi-core-bundle-implement02-*.HC  # bounded PolyC verifiers/fixtures
docs/acts/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02.md
docs/factory/act-handoff-map.tsv   # one append row
docs/ROADMAP.md                     # bounded append only
evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02/**
```

Forbidden without a new ACT: edits to src/x86_64.c, src/asm/**, other
src/**, existing tests, old tools/bootstrap/** components, factory
doctrine, canonical quality gates, historical ACT/HANDOFF/evidence, and
the predecessor's selected contract. No Python or new dependencies. No
history rewrite, amend, rebase, reset, force-update, fetch, push or
publication. Work in the existing checkout/branch; use detached
disposable worktrees for mutants and generation comparisons. Any
exception requires an independently authorized ACT, never an implicit
repair.

### 0.4 Terminal dispositions

```text
PASS_THREE_A64_CODEGEN_AUTHORITIES
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_HISTORY_OR_F14
HALT_CONTRACT_INCONSISTENT
HALT_SOURCE_RANGE_DIGEST
HALT_CSET_ABI_NO_OBSERVABLE_OUTPUT
HALT_GENERATION_CONTRACT_AMBIGUOUS
HALT_ABI_DOMAIN_OR_LIFETIME
HALT_C_ONLY_ORACLE
HALT_BUILD_PROVENANCE
HALT_AUTHORITY_NOT_TRANSFERRED
HALT_SITE_CAUSAL_UNPROVEN
HALT_C_DORMANCY_UNPROVEN
HALT_DIFFERENTIAL
HALT_CONTROLS
HALT_CONSERVATION
HALT_FACTORY_OR_TERMINALITY
```

A measured HALT is the correct outcome if a frozen prerequisite cannot
be met. Do not switch to a two-member PASS, count a wrapper as an
authority, or silently modify ABI semantics.

## 1. C0 entry identity, historical freeze, and real baselines

Read the current AGENTS.md, docs/factory/DOCTRINE.md,
docs/factory/GIT-METADATA.md, the canonical Factory-v2 commit/range/
closure tools, docs/ROADMAP.md, the predecessor ACT and HANDOFF. In a
conflict, actual committed doctrine prevails; HALT rather than privately
relaxing either contract.

Require the exact expected HEAD/tree and main, or HALT_ENTRY_IDENTITY.
Record any tracked, staged, untracked or ignored residue independently;
an untracked ACT file created by the executor is not necessarily
predecessor dirt, but it must be explained. Zero replace refs.

Post-CLOSE audit: identify the predecessor's unique terminal CLOSE
commit by its ACT trailer and all descendants. Measure
POST_CLOSE_ALL_COMMITS and POST_CLOSE_THIS_ACT_COMMITS separately. For
each descendant record parent(s), subject, trailers, paths, tree delta,
changed blobs, and exact status under append-only/F14/doctrine.

Freeze: compute path+SHA-256 of all predecessor paths including its
c2/selected-bundle-contract.md, c2/selected-bundle-contract.sha256,
c2/selected-bundle-members.tsv, c1/core-sites.tsv,
c2/abi-and-bootstrap-successor-contract.tsv, three C-mutant evidence
subtrees and all prior closed evidence. Validate their actual Git
object identities; do not use the narrative digest as a hash oracle. F14
must report zero unauthorized altered predecessor paths at every phase.

Fresh baseline: build using the established selector-ON production
configuration with a real isolated installed test prefix. Verify the
runner exists and executes 90 test blocks; do not accept a fail-open
unit-test wrapper returning 0 with an empty prefix. Run with a single
compiler process at a time, because /tmp/holyc-asm.s and parallel
object races remain open.

## 2. Mandatory C0 contract audit — no production edits until resolved

### C0-P1. Source interval and digest identity

Define exactly whether recorded intervals are zero-based/one-based and
inclusive/half-open before calculating. Recompute both interval hashes,
total bytes, function-extraction ranges and call-site boundaries with
two genuinely independent methods (PolyC and Git/POSIX). Check that
the C1/C2 records may instead describe different concepts (body versus
whole definition), with separately named hashes, and that no sibling
source interval overlaps. A label-only explanation does not permit equal
hashes over different bytes.

Accept only: one mechanically determined authoritative
function-boundary table, its exact bytes/hash/OID and an independently
demonstrated, already authorized mapping to the frozen contract. If the
binding frozen contract contains invalid source-range/hash claims
requiring changed bytes, no hidden correction inside IMPLEMENT02:
HALT_SOURCE_RANGE_DIGEST and propose a forward-only RECON03-contract
correction.

### C0-P2. A third observable ABI authority

The frozen contract declares:

```polyc
U8 *AbiA64CmpCcFor(I64 comparison_kind);
U8 *AbiA64CmpCcInvFor(I64 comparison_kind);
U0  AbiA64CmpCcEmitCSet(I64 comparison_kind, I64 is_float);
```

FOR and INV return borrowed immutable NUL-terminated suffix literals;
unsupported inputs return NULL, with C performing explicit host panic.
In contrast, the third export takes only two copied scalar inputs,
returns U0, and the same contract forbids callbacks, mutable host
state, and an assembly-buffer pointer across the seam. Such a call has
no apparent output channel through which its decision can authoritatively
affect CSET emission.

C0 must establish an executable source-bound contract interpretation in
the predecessor's already committed evidence that gives
AbiA64CmpCcEmitCSet a load-bearing observable result while preserving
its exact declared signature, ownership and no-callback/no-state-write
restrictions. Test the proposed interpretation on an isolated build with
a real compiled PolyC subject, host call site and output-difference
anti-control. It must NOT merely call an inert U0 function while C
continues selecting the cset condition, nor count the FOR suffix reused
by C as a third independently selected authority.

If no such interpretation exists, HALT_CSET_ABI_NO_OBSERVABLE_OUTPUT
before changing production. Do not invent an output argument, turn the
return into a suffix pointer, add a callback, write a global, or change
the semantics of U0 under this ACT.

### C0-P3. Generations, naming, and comparison identity

Bind the actual production Make/CMake compiler-producing rules and emit
a producer DAG: node ID, compiler executable path, SHA-256, source tree,
compiler input set, resulting subject object, linked compiler output and
proof that the producer existed before its output. Define unambiguous
roles such as C_ORACLE, P1, P2, P3 while retaining the frozen textual
labels in an explicit mapping. Do not conflate the C compiler that
constructs stage0 with a PolyC compiler that compiles the subject.
Confirm three pairwise distinct producer executable digests, and four
independently observed semantic result streams (C oracle plus three
PolyC produced subjects).

Require both: (a) all 12 ordered value comparisons among C-oracle and
three PolyC producer streams, for every fixture row, and (b) each
distinct frozen source/object/assembly/output/exit invariant from the
predecessor's 12-item heterogeneous list, with crosswalk IDs
FROZEN-01..12 and PAIR-01..12. They are not interchangeable.

### C0-P4. Data domain, ABI and host target

Read live src/ir-types.h and src/aarch64.c to enumerate all IrCmpKind
values. Construct a source-derived input-validity matrix by
integer/float/ordered/unordered form and the actual code path; explicitly
identify unreachable combinations rather than silently mapping them.
Validate NULL failure, static literal lifetime, NUL termination,
signedness, width and pointer ABI for the actual host/target. Check
AArch64 suffix validity using a real assembler and verify numeric zero
is valid input, not a status code. An I64 negative error or
NULL-for-zero mapping is forbidden.

### C0 gate verdict

Write c0/contract-audit.tsv with each premise, exact committed source,
independent measured result and PASS|FAIL|UNPROVEN, plus a
machine-enforced aggregate. This prerequisite is blocking; no C2
production implementation while a C0 discrepancy remains FAIL or
UNPROVEN. On failure, complete a bounded Factory-v2 HALT with honest
remaining ACs/controls NOT_RUN, explicit correction recommendation and
no production changes. Do not claim the expected 16 authorities.

## 3. C0 RED and frozen verification contracts

Before implementation, freeze exact AC01..AC50 and NC01..NC24, distinct
reason classes, source hashes, branch/entry identity, mutation and
fixture plans. Execute at least five pristine -> adverse -> restored
REDs against actual entry records, requiring their own reason-specific
failures.

REDS and negative controls must use independent detector calculations,
not compare a claimed PASS value against itself. All adversarial source
mutations run on isolated copies/worktrees, never the canonical
predecessor.

## 4. C1 EVIDENCE — oracle, seam and fixture freeze

### 4.1 Genuine selector-OFF C-only production oracle

Capture the exact supported production flags/objects for a dedicated
HCC_USE_SELFHOST_A64_CMP_CC=OFF. It is a whole compiler built from
source with the C rules live, no new PolyC subject linked or symbol
imported, and no new component dependency in the link line. The C-only
object must be the actual src/aarch64.c translation unit and the oracle
must exercise every selected live site.

### 4.2 Three-source semantic contract, including coupling

Freeze original C semantics for all valid/invalid IrCmpKind values and
integer/float contexts. Reconstruct source-derived true suffixes,
inverse suffixes and CSET materialization and verify the true/inverse
relationship where applicable. The aarch64EmitCSet -> aarch64CcFor call
is a real coupling; freeze which behavior belongs to each site. Host-side
responsibilities: format/write assembly, preserve register naming and
output buffer, sequencing, error diagnostics and allocation. PolyC
responsibilities: only the decisions actually authorized by an
executable ABI.

### 4.3 Frozen build/ABI contract

Establish effective Makefile prerequisites at rule read time. Use an
explicit CMake selector with default OFF for host stage0 and the C-only
oracle; normal production enables the selector after the PolyC subject
is built. Verify the target's actual C ABI/pointer representation, the
exported unmangled symbols, C declarations and PolyC definitions, all
borrowed-string lifetime constraints, and process-termination behavior
on unsupported values.

## 5. C2 IMPL — exactly three production-authoritative decisions

Only when C0/C1 pass, create exactly one new bounded PolyC component
under tools/bootstrap/ implementing the frozen ABI, with three truly
semantic operations. Modify only the three named seams in src/aarch64.c
plus minimal adjacent scalar host projections needed to invoke them. The
C side retains the assembly writer, IR objects, comparisons' input
extraction, branch control, registers, allocation, diagnostics and
recovery. No target-agnostic IR refactor or x86_64 migration.

Create one dedicated selector whose OFF branch is the unchanged C
oracle, and whose ON branch invokes compiled PolyC. In the ON compiled
aarch64.c object, legacy condition-selection bodies must be compiled
out for all three decisions.

C2 gate: If FOR and INV migrate but CSET cannot satisfy the frozen U0
contract, do not close PASS_PARTIAL, do not invent a third authority, and
do not leave a misleading claim. Prefer HALT with an explicit
partial-work inventory and no production-authoritative rollout.

## 6. C3 EVIDENCE — four-generation differential, mutations and dormancy

### 6.1 Four-result-stream equivalence

Compare C-only G0 semantics with PolyC G1/G2/G3 streams on every fixture
row and every failed-domain partition; perform all 12 ordered pairwise
comparisons. Separately discharge all 12 distinct items from the RECON03
frozen heterogeneous checks.

### 6.2 Three independent post-migration PolyC causal experiments

For EACH selected site perform a separate physical experiment in its own
detached disposable worktree from the migrated production tree. Change
only the actual compiled PolyC decision for that site.

```text
SITE    Required independently discriminating post-migration witness
FOR     True signed LT: cset x0, lt -> cset x0, ge, LT_OK -> LT_BAD
INV     Inverted signed LT: b.ge -> b.lt, LT_OK -> LT_BAD
CSET    Boolean materialization: observed cset decision changes, GT_OK -> GT_BAD
```

The documented coupling CSET -> FOR is allowed only with a separately
discriminating CSET witness; a FOR mutation changing CSET output does
not count as a second CSET causal experiment.

### 6.3 Three legacy-C dormancy anti-controls

For each site mutate the original selector-OFF C rule in its own
isolated worktree. The selector-OFF oracle must change its own real
witness; the selector-ON compiled PolyC production object and witness
must remain unaffected.

### 6.4 Conservation, graph and gates

Run full parser/lexer conservation against populated isolated prefix,
complete unit and backend tests relevant to AArch64 cset and inverse
conditions, and the real gate-fast / gate-push checks. Recompute the
production dependency graph from the modified linked TUs. Full production
authority count requires 13 existing + exactly 3 new sites.

## 7. Frozen negative controls — NC01..NC24

Each control must be executed once with a stable physical execution ID,
explicit injected adverse state, named reason-specific detector, SILENT
pristine -> FIRED adverse -> SILENT restored, and no generic-parse-error
false positive.

## 8. Exactly 50 acceptance criteria (binding)

The frozen c0/acceptance-contract.tsv carries AC01..AC50 with phase,
predicate, evidence file, independent checker, and status. PASS|FAIL|
NOT_RUN|UNPROVEN|DEFERRED only. AC50 remains DEFERRED until external
terminality.

## 9. C3 independent verification and baseline gates

Require two independent implementations: (A) new PolyC verifier(s) that
parse live source/enums, reconstruct fixtures and authority/link/
provenance joins; (B) Git/POSIX/`awk` read-only verification that
recomputes source-range digests, producer identities, object symbols/
relocations, fixture hashes and causal join without reading the first
verifier's claimed PASS fields.

Run make gate-fast and make gate-push with the real supported
environment. Verify Factory-v2 range, closure-status, append-only, F14,
patch hygiene and source-scoped restrictions on actual Git trees.
Preserve all known non-green baseline identities.

## 10. Factory-v2 C0–C4 lifecycle and closure

Exactly five linear, non-merge ACT commits. On a C0 HALT, use the
repository's valid HALT structure, record actual executed phase count
and unfinished checks honestly; the five-commit PASS lifecycle is NOT
required or fabricated when halted early.

Terminal PASS trailers, when and only when every mandatory gate is
discharged:

```text
ACT: ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

AC50 is DEFERRED at C3, discharged only by an external read-only
terminality probe after C4 CLOSE.

## 11. Required terminal report

The terminal report carries the entry identity, the predecessor's CLOSE
SHA, the two post-CLOSE counts, the F14 verdict, the frozen contract
digest, the C0 range-hash audit, the C0 CSET output channel, the C0
generation DAG, the C0 contract verdict, the frozen bundle and ABI, the
verdict and disposition, the final HEAD/tree/branch, the ACT commit
count, worktree cleanliness, the replace-ref count, the post-CLOSE
counts, the production and new authority counts, the three per-site
production-authority verdicts, the C-only oracle verdict, producer
independence, the directed-differential and frozen-heterogeneous check
counts, the three PolyC causal verdicts, the legacy-dormancy verdict,
the production graph, the new proven graph cuts, the parser assertions
and their sequence MD5, the lexer and cross-target and Python and
PolyC-tools statuses, the negative-control count, the four AC counters,
the gate verdicts, F14, append-only, the Factory-v2 range check, the
external terminality verdict, and the two standing NO claims.

## 12. Exit rules and next proposed work

- PASS: Exactly three AArch64 production decisions are PolyC-authoritative,
  their C bodies are dormant in selector-ON, all original 13 authorities
  remain, three new PolyC mutations have separately verified causal
  impact and restoration, G0–G3 semantics agree, all 50 AC and 24 NC
  are proven, gates/Factory terminality PASS.
- HALT at C0: Report the precise frozen-contract contradiction or
  post-CLOSE evidence problem; complete only the authorized bounded HALT
  record and propose
  ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01
  as a separate forward-only correction. In particular, the U0 CSET
  output gap cannot be solved by secretly editing the ABI within
  IMPLEMENT02.
- HALT later: Preserve exact evidence and actual mutated/clean tree
  status, but never claim a partial three-site PASS.
- After successful PASS: propose a new evidence-backed core bundle, or a
  separate infrastructure ACT for compiler scratch/temp and fail-open
  test behavior. Do not automatically authorize SLICE10.
