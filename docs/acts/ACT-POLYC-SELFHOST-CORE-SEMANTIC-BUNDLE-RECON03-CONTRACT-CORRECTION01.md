# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION ARTIFACT — not an execution report
Class: SELFHOST / ABI_CORE / FORWARD_ONLY_CONTRACT_CORRECTION
Priority: P0 — prerequisite for AArch64 code-generation migration
Prepared: 2026-11-02
Repository: existing local PolyC checkout; branch main
Expected ENTRY_HEAD: 500d2fce1259b03bad7f10795c11346dadcc70d0
Expected ENTRY_TREE: 0fb68fa280a3a405a84a303a5585babf4bfe7c0e
Predecessor: ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02, terminal HALT_SOURCE_RANGE_DIGEST; co-equal blocker HALT_CSET_ABI_NO_OBSERVABLE_OUTPUT
Original selection: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03, PASS / PASS_SELECTED_CORE_BUNDLE
Selected bundle: CAND-CMP-CC-A64
Original ABI: ABI-A64-CMP-CC-1 — INVALID FOR IMPLEMENTATION; immutable history
Proposed successor contract ID: ABI-A64-CMP-CC-2 (new, correction-owned, not a modification of v1)
Known production authorities: 13; historical-at-IMPLEMENT01-CLOSE causal count 12/13; correction-inclusive count 13/13
Production mandatory graph: 52 nodes, 134 active edges, 34 SCCs, largest 19; only previously proven cut E-TYP-0136
Publication: NO push/fetch/rebase/amend/reset/force-update; no new branch absent a proven safety need.

## 0. Mission, non-goals and decision rule

Mission: Supply a forward-only, independently verified replacement for RECON03's contradictory AArch64 successor contract, without changing its historical claims. Correct the byte-range/SHA bindings, settle whether aarch64EmitCSet constitutes an independently countable semantic authority, design an observable and safe replacement ABI, and freeze an implementable successor with honest producer provenance and target authority count.

This ACT is a contract correction, not an implementation ACT. The three selected source locations stay selected as an investigation/implementation scope. The number of semantically independent C decisions in those locations is a separately measured fact, not automatically three. The selection itself is not re-ranked or expanded.

### 0.1 Required possible outcomes

| Terminal disposition | Definition | Future authority target |
|---|---|---|
| PASS_CORRECTED_TWO_PLUS_ADAPTER | FOR and INV are independently source-backed classifications; CSET is a C-owned mechanical emitter that calls the FOR decision without independent classification; corrected ABI and tests frozen | 13 → 15 |
| PASS_CORRECTED_THREE_INDEPENDENT | All three sites contain distinct source-backed semantic decision rules; CSET gets its own observable ABI and a causally discriminating witness that cannot be credited to FOR | 13 → 16 |
| HALT_SOURCE_PROVENANCE | Source identity, function boundaries or complete hashes cannot be independently bound | No future migration authorized |
| HALT_AUTHORITY_CLASSIFICATION | A coherent count of independent decisions cannot be established from live source and distinct witnesses | No future migration authorized |
| HALT_CORRECTED_ABI | Corrected ABI cannot be compiled, linked or safely observed through the real host/PolyC seam | No future migration authorized |
| HALT_PRODUCER_PROVENANCE | Required independent compilation generations or domain distinctions cannot be established | No future migration authorized |
| HALT_FACTORY_OR_CONSERVATION | Mandatory Factory, scope, freeze, conservation or evidence predicates fail | No future migration authorized |

Do not force the three-authority outcome. A CSET mutation that merely substitutes a literal for the aarch64CcFor call proves the emitter is live, not that CSET owns a second condition-code selection. Conversely, do not predeclare two authorities without checking all original emission semantics and any genuine independent policy.

### 0.2 Explicitly forbidden

- No changes to src/**, tools/bootstrap/**, Makefile, src/CMakeLists.txt, tests/**, scripts/**, factory doctrine, canonical quality gates, or existing test/quality tools.
- No editing, moving, deleting or overwriting ANY prior ACT, HANDOFF, evidence, selected contract or historical .sha256 sidecar, including RECON03 post-CLOSE ordinary commits.
- No compiling or linking a new production AArch64 PolyC subject; no selector changes; no new production authority or graph cut.
- No status relabeling: IMPLEMENT02 remains HALT, RECON03 remains PASS, ABI-A64-CMP-CC-1 remains historically contradictory, and a future IMPLEMENT02 must not be resumed under v1.
- No Python or new dependencies. No untracked mutant worktrees left behind. No fabricated fixture totals, hashes, producer identities or terminality.
- No push, fetch, rebase, amend, reset, force-push or publication.

### 0.3 Authorized tracked paths (exact)

```
docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01.md
docs/factory/act-handoff-map.tsv                 # exactly one appended mapping row
docs/ROADMAP.md                                  # bounded, append-only correction section
tools/quality/a64-cmp-cc-contract-correction01-*.HC   # new source-derived PolyC validators only
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01/**
```

Temporary isolated C/PolyC seam probes and C mutations must remain outside the tracked repository (disposable detached worktrees/temporary build roots) unless a separate ACT authorizes otherwise. If a production-representative experiment proves impossible without touching forbidden tracked paths, HALT.

## 1. Binding predecessors, source facts and discrepancy ledger

Read AGENTS.md, docs/factory/DOCTRINE.md, docs/factory/GIT-METADATA.md, Factory-v2 range/trailer/closure tools, latest docs/ROADMAP.md, RECON03 ACT/HANDOFF and its C1/C2 selected evidence, IMPLEMENT02 ACT/HANDOFF and its committed C0 audit. The actual committed doctrine prevails in any conflict. Do not rely on this document's paraphrase over source bytes.

The following are reported historical observations to rederive, not newly claimed measurements:

| Site | C1 matching interval, [start,end) | C1 SHA-256 | True whole-definition interval reported by IMPLEMENT02 |
|---|---|---|---|
| FOR aarch64CcFor | [35517,36100) | d22a99b3c85f82f12754582b63ecc0e5429b6ac3dbdff21ff2a960d4b538ccdc | [35517,36571) |
| INV aarch64CcInvFor | [36577,37019) | 5b08df7b9752fd70d8391a300e5d6c9f943be67779f7e75102b788eec7b5d343 | [36577,37490) |
| CSET aarch64EmitCSet | [37566,37718) | 8a1f2573c7eeb598816edcd96830cdd695b733f6ad12c47f859ea46575cec540 | [37566,37714) |

Original C2 incorrect range/hash pairs: FOR [35517,36576), INV [36577,37495), CSET [37566,37719), reusing the respective C1 hashes. The historical committed src/aarch64.c blob was reported as 6a53ac8f2e320aa8b0f7fc23ea9bd90be0334229 (101705 bytes). Derive its live Git object identity and every whole-function digest afresh. The C1 digests are valid for their C1 intervals but must never be relabeled as hashes of whole definitions. Record both concepts in different columns.

Original unobservable third export:

```
U8 *AbiA64CmpCcFor(I64 comparison_kind);
U8 *AbiA64CmpCcInvFor(I64 comparison_kind);
U0  AbiA64CmpCcEmitCSet(I64 comparison_kind, I64 is_float);
```

IMPLEMENT02 established that U0 with two copied scalar arguments and no permitted state/callback/out pointer cannot convey the suffix chosen for an emitted cset. Treat that as a binding negative result; do not reopen it speculatively. The live CSET body cited by the HALT was:

```c
static void aarch64EmitCSet(IrCgCtx *ctx, IrCmpKind cmp, int is_float) {
    aoStrCatFmt(ctx->buf, "cset    x0, %s\n\t", aarch64CcFor(cmp, is_float));
}
```

Inspect the real current Git blob before assuming this excerpt is complete or still exact. Record if it differs.

## 2. C0 — RED, entry, historical freeze and five required adverse observations

### 2.1 Exact entry and ancestry

1. Require the exact ENTRY_HEAD, ENTRY_TREE, branch main, clean tracked/index state, no replace refs, and classify any ignored/untracked residue separately. An entry mismatch is a terminal HALT; do not retarget silently.
2. Locate RECON03 CLOSE by its ACT trailers (git interpret-trailers --parse), enumerate all later ordinary commits and their exact changed paths. Locate IMPLEMENT02 C0 and CLOSE by trailers and verify its two-commit HALT range, no later ACT continuation, append-only ancestry and authorized changed paths.
3. Freeze every predecessor path by path + Git blob OID + SHA-256, with a recorded authorized-post-CLOSE history exception not interpreted as retroactive approval. Distinguish the RECON03-at-CLOSE version from the current post-CLOSE version for each changed blob; no history is erased.
4. Validate the original RECON03 selected contract SHA-256 from its current Git blob (77e2a0d5168f02b9f8b550319e60ea32dc6a9f59064a4f54fd2b209ae735f681 was reported) and separately preserve its old CLOSE blob. Never alter it to make the assertion true.
5. Freeze the entry's 13 production-authority IDs from real object/linked-executable evidence, including the 12/13-at-original-IMPLEMENT01-close versus 13/13-after-correction provenance. Baseline graph stays 52/134/34/19 unless independently remeasured source evidence proves otherwise.

### 2.2 Genuine REDs (pristine → adverse → restored)

Execute five distinctly identified REDs using a compiled PolyC verifier on copies of REAL committed records:

- RED-01: false C1-body hash presented as the whole-function hash → RANGE_SEMANTIC_MISBIND.
- RED-02: a one-byte off-by-one or stale Git blob OID → SOURCE_RANGE_OR_BLOB_MISMATCH.
- RED-03: original U0(I64,I64) CSET counted as an observable independent authority → INERT_CSET_ABI.
- RED-04: a CSET wrapper importing FOR's decision counted twice under two site IDs → DUPLICATE_SEMANTIC_AUTHORITY.
- RED-05: a fabricated G0/G1 producer alias, tampered frozen predecessor, or premature AC50 → specific PRODUCER_ALIAS / F14_REWRITE / PREMATURE_TERMINALITY detectors (at least one; all are independently tested in C3).

Each must be SILENT pristine, FIRED with its own reason adverse, and SILENT restored. The adverse test must not merely replace a PASS field with FAIL; it must alter an actual source-derived fact/digest/structure and recalculate independently.

### 2.3 Fresh non-green baselines

Run with stable TMPDIR and serialized compiler execution. The unit-test prefix must contain the real expected runtime/header and execute the real 90-block runner; exit=0 from an empty or broken prefix is not evidence. Re-run parser (historically 376/376, assertion-sequence MD5 b6f117eb1386ca80f81bc06226e2a741), lexer direct 89/89, 45/45, 23/23, and record actual broad LEXER07 and cross-target status if run. When not run, say NOT_REMEASURED, not PASS. F-NO-PYTHON remains its measured status (historical 12 violations); F-POLYC-TOOLS remains UNAVAILABLE unless its canonical checker actually exists and runs. Failures due to disappearing sandbox TMPDIR must be distinguished from the separate, known shared /tmp/holyc-asm.s race.

Freeze the correction's complete 50-AC and 24-NC roster at C0, with exact IDs, predicates, evidence path, independently implemented checker and phase. A HALT uses honest FAIL/NOT_RUN/UNPROVEN/DEFERRED counts, not a synthesized PASS ledger.

## 3. C1 — EVIDENCE: authoritative source ranges, semantic roles, ABI design

### 3.1 Whole-function provenance

- Determine the zero-based half-open byte ranges of all three whole definitions from the exact committed blob, with a scanner that handles comments, strings, nested braces, and line endings rather than matching the first brace. Record start, end, size, exact extracted text SHA-256, Git blob OID, and function name.
- Independently compute the hashes via a separate POSIX/Git method that does not consult the first scanner's claimed digest. Confirm no overlap and no textual disagreement. Also hash the original C1 slices, retaining their original labels C1_PARTIAL_INTERVAL, not WHOLE_FUNCTION.
- Rehash the old erroneous C2 intervals and record their actual digests as C2_CLAIMED_RANGE_RECOMPUTED to demonstrate the mismatch. The source-bound corrected table must use the correct whole-definition hashes, which are generated, not copied from C1.
- Record the relation of function ranges to call-site ranges, original C1 site IDs, and any comments/newlines outside the true definitions. For every discrepancy, give before/after interval and an exact provenance reason.
- Positive and negative controls must demonstrate that a stale SHA, one-byte extension, forged start offset, wrong Git blob, or body/whole confusion is detected. The frozen historical material remains immutable.

### 3.2 Count semantic authorities, not function names

Construct a source/object-based decision-dependency table for FOR, INV and CSET. For each physical site record inputs, live C branch/switch/table, output, callers, downstream use, reachable code path, mutations, distinguishing witness, transitive call through another selected site, and its semantic decision ownership.

Required independent experiments in disposable source worktrees:

1. FOR: a one-site C mutation that changes the true condition choice; show full compiler rebuild, changed assembly and compiled behavior; restore exactly.
2. INV: a one-site C mutation that changes the inverse choice, under a separate witness; rebuild, observe and restore.
3. CSET: separately mutate ONLY CSET; prove its emitter path is active. Then independently test whether the original CSET code contains an additional choice not already fully determined by FOR's suffix and fixed mechanical formatting. Do not infer that third decision from the fact that CSET produces observable assembly; observable wrapping is not necessarily an independent semantic authority.

For CSET, require a SEMANTIC_DECISION_UNIQUE=YES witness showing a source-backed choice distinguishable from FOR under fixed FOR output. If the live function is only the fixed aoStrCatFmt(... aarch64CcFor(...)), classify C_MECHANICAL_ADAPTER; preserving that call site is still required, but the future authority count is two. Do not create a new policy solely to inflate the count.

Decision rule, to be executed not assumed:

```
FOR independently qualified = YES AND INV independently qualified = YES
AND CSET source-backed independent semantic policy = NO
  => BUNDLE_MODE=TWO_PLUS_ADAPTER; FUTURE_NEW_POLYC_AUTHORITIES=2; FUTURE_TOTAL=15.

FOR independently qualified = YES AND INV independently qualified = YES
AND CSET source-backed independent semantic policy = YES
AND CSET distinguishing witness/real ABI channel proven
  => BUNDLE_MODE=THREE_INDEPENDENT; FUTURE_NEW_POLYC_AUTHORITIES=3; FUTURE_TOTAL=16.

Otherwise => HALT_AUTHORITY_CLASSIFICATION (no estimated partial PASS).
```

If CSET is an adapter, explicitly preserve original three physical site IDs and the selected bundle ID for historical traceability; classify CSET as C_MECHANICAL_ADAPTER in the new successor, do not erase RECON03's recorded selection.

### 3.3 New observable ABI ABI-A64-CMP-CC-2

Freeze a new, versioned ABI from live IrCmpKind values and actual C caller projections. Prefer a simple observable borrowed-suffix return for true and inverse condition selection, with both comparison_kind and is_float explicitly present if the original function uses both; no pointer to mutable IR/AST state crosses the seam. The following is a candidate design, not an authorized hardcoded ABI until compiled and measured:

```c
/* C-facing example only; exact PolyC-compatible declarations must be proven. */
const unsigned char *AbiA64CcForV2(int64_t comparison_kind, int64_t is_float);
const unsigned char *AbiA64CcInvForV2(int64_t comparison_kind, int64_t is_float);
```

For the TWO_PLUS_ADAPTER disposition, C keeps the mechanical aarch64EmitCSet formatter and obtains its condition suffix through the FOR PolyC decision. There is no third export and no third authority claim. An explicit cset emission witness and a host-only formatting anti-control still qualify the adapter preservation.

For THREE_INDEPENDENT only, additionally specify an observable CSET-specific decision export, e.g. a borrowed-suffix-pointer return or a caller-supplied typed out-cell. The third export MUST transmit a distinct source-backed decision, with a site-specific causal witness, not duplicate FOR's mapping. Never use the original U0(I64,I64) declaration. If using a pointer return, the host must not mutate or free the returned static string. If using an out-cell, define initialization, width, validity, and NULL/out-of-range behavior precisely.

Requirements applying to either outcome:

- IR_CMP_INVALID=-1, IR_CMP_EQ=0, and all other IrCmpKind values must be parsed from the live source; no value/status collision. Invalid/unsupported combinations must fail closed, using a NULL pointer status with host termination or an explicitly equivalent measured result. No default condition suffix on unknown kind.
- All integer/float / ordered/unordered valid and invalid partitions must be enumerated. Report historical observation that IR_CMP_OEQ..IR_CMP_ORD have no matching suffix in the existing switches, but verify it against live bytes.
- Prove emitted suffixes assemble with the actual target AArch64 assembler; test invalid suffix rejection. Account for ARM CSET condition semantics when defining equivalence, including condition inversion at instruction encoding.
- Prove AArch64 Darwin C/PolyC calling convention from actual C header declarations, compiled object symbols and calls. Do not call it generic SysV without a target-specific proof.
- Prove returned borrowed literals are NUL-terminated, stable for their documented lifetime, non-allocating, and never freed/written by C; define error domain and link/export symbol spelling.
- The host retains IrCgCtx, AoStr, assembly buffering, register names, emission sequencing, diagnostics, allocation, recovery and process termination. No opaque mutable state crosses into PolyC under this contract.

### 3.4 Bootstrap / independent producer graph

Read actual Makefile and src/CMakeLists.txt producer and link rules; freeze a DAG containing executable path, SHA-256, source/parent producer, subject compilation command, output object, linked binary, and chronology. Distinguish the host C compiler (e.g. /usr/bin/gcc), the host-stage0 PolyC compiler, ./hcc, and later bootstrap compiler binaries. Use unique producer IDs (C_TOOLCHAIN, POLYC_PRODUCER_1..3) and an explicit crosswalk to the predecessor's ambiguous G0/G1/G2/G3 nomenclature; do not reuse G0 for two executables.

Require for the future implementation: one genuine selector-OFF C production oracle, three pairwise-distinct PolyC subject producers, four separately observed semantic result streams, 12 ordered stream comparisons plus the predecessor's 12 heterogeneous invariants tracked as a different roster. A count of 12 in one roster never discharges the other.

## 4. C2 — IMPL: implement the corrected contract, not compiler semantics

Create correction-owned, versioned artifacts:

```
evidence/<THIS_ACT>/c2/corrected-source-ranges.tsv
evidence/<THIS_ACT>/c2/corrected-source-ranges.sha256
evidence/<THIS_ACT>/c2/semantic-authority-vs-adapter.tsv
evidence/<THIS_ACT>/c2/corrected-abi-v2.md
evidence/<THIS_ACT>/c2/corrected-abi-v2.sha256
evidence/<THIS_ACT>/c2/producer-dag-and-crosswalk.tsv
evidence/<THIS_ACT>/c2/corrected-bundle-members.tsv
evidence/<THIS_ACT>/c2/corrected-selection-binding.tsv
evidence/<THIS_ACT>/c2/future-implementation-contract.md
evidence/<THIS_ACT>/c2/contract-correction-join.tsv
```

<THIS_ACT> denotes the literal current ACT ID, not a runtime path wildcard. All files in this table are new; nothing modifies the RECON03 historical C2 files. Hash sidecars must be computed after contents are frozen; do not place a document's SHA-256 inside itself.

Develop one or more PolyC quality tools to parse the real source bytes, extract and hash ranges, classify the output channel/authority count, parse the ABI signature and the producer DAG, independently verify source/contract joins, and fail closed on missing/extra/duplicate IDs. The verifier must be independently sensitive, not a hardcoded status printer. Run a static ABI declaration/subject prototype in disposable external build roots against real C and compiled PolyC producer objects to prove the proposed return/out-cell semantics are implementable. Do not migrate any production source site or add a production subject.

The corrected successor contract must freeze: exact site role/classification, true byte-range/hash table and Git OID, tested ABI signatures, input domain and invalid statuses, C-owned operations and lifetime, absence/presence of CSET independent semantics with actual witness, C-only oracle, producer DAG, fixture specification, future post-migration causal experiments one per actual authority, C-dormancy controls, build/Make/CMake fail-closed plan, and target after future PASS (15 or 16). It must also explicitly supersede only the authorization to implement using ABI v1, not RECON03's historical verdict or original text.

A PASS_CORRECTED_TWO_PLUS_ADAPTER contract MUST remove the impossible third export from the new ABI and scope; that is a legitimate correction, not a partial implementation. A PASS_CORRECTED_THREE_INDEPENDENT contract MUST prove a third source-backed semantic choice, not merely carry three exported symbols.

## 5. C3 — EVIDENCE, adverse controls and conservation

### 5.1 Independent recomputation

Run two genuinely independent methods: compiled PolyC scanner/verifier and separate Git/POSIX/`awk` recomputation. They must independently derive full-definition boundaries, exact SHA-256, source tuple/domain values, site semantic classification, producer executable digests, unique site IDs, and the final authority count without reading each other's PASS columns. For whole-function interval hashes, include a one-byte perturbation and a different-blob anti-control. Include another anti-control that asserts CSET is an authority merely because its assembly output changes: it MUST be rejected absent distinct semantic policy.

### 5.2 Three-category implementation feasibility checks

- Original C semantics: untouched selector-OFF C full compiler accepts/rejects the fixture partitions and produces exact expected assembly/behavior; if full isolated build is unavailable, mark UNPROVEN and HALT instead of treating a static table as equivalent.
- Corrected ABI prototype: real compiled PolyC object linked into a disposable host; check valid, invalid, float, borrowed-lifetime, zero discriminant and observable output. For CSET adapter classification, prove a compiled PolyC FOR result can feed unchanged host cset formatting, with a causal FOR mutant and separate fixed-format anti-control. Do not miscount them as two independent PolyC choices.
- Producer testability: separate C oracle versus distinct PolyC producers; independently validate missing-subject and producer-alias adverse conditions. Preserve future all-12-pairs and separately frozen-12-invariants obligations.

### 5.3 Full qualification

Execute 24 NCs using the frozen roster below (do not invent new IDs mid-run); all must have actual pristine/adverse/restored execution IDs, a named reason-specific detector and a complete source/value/digest join. If a specific control is impossible in a contract-only ACT, HALT or mark unproven according to the frozen contract; never report it as PASS. Perform a separate verifier selftest that rejects dropped AC IDs, duplicated site IDs, false positive whole-function hashes, and an unjustified third-authority claim.

Re-run make gate-fast, serialized make gate-push, the actual parser runner against a populated prefix, the three lexer direct differentials, the applicable AArch64 emitter fixtures and explicit versioned ABI tests. Report unchanged historical non-green statuses without converting them to PASS. Recompute graph from production linked objects: expected 52 nodes, 134 active edges, 34 SCCs, largest 19, new cuts=0; deviations require source/object proof and cannot be attributed to a documentation-only ACT. Recheck all 13 authorities and no production semantic delta. Run append-only, F14 for all frozen predecessors, Factory-v2 range validator, closure status, patch hygiene and source-scoped file diff checks.

### 5.4 Scope and external terminality

No prior ACT/HANDOFF/evidence path may differ in the final tree from this ACT's entry tree. Historical post-CLOSE edits discovered at C0 are preserved as pre-entry facts and not extended by this ACT. All new evidence must exist only under the current ACT namespace. Source/object mutants may exist transiently only in disposable, isolated worktrees and must be removed after all their actual terminal observations are consumed.

## 6. C4 — CLOSE and successor handoff

After C3, freeze HANDOFF-...CONTRACT-CORRECTION01.md, append one map row and one bounded ROADMAP section, write only a plan under tracked c4/terminality-plan.txt, and commit exactly one final CLOSE with the actual PASS/HALT verdict. For PASS use five linear non-merge commits RED → EVIDENCE → IMPL → EVIDENCE → CLOSE, all with real Factory-v2 trailers verified before each commit. A C0/C1/C2 HALT uses the repository's actual permitted shorter HALT lifecycle; do not manufacture five commits or PASS checks.

Terminal PASS trailer form, validated against the actual doctrine:

```
ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

The tracked CLOSE is the last ACT change. Generate the terminality receipt by an external read-only observer after CLOSE, store it outside the repository, and bind it to the exact HEAD SHA, TREE, five ACT trailers, frozen paths, acceptance/NC joins, graph and source/ABI digests. AC50 remains DEFERRED until this receipt exists; do not backdate it or add a compensating ordinary commit containing it. Do not push.

### 6.1 Required successor designation

On terminal PASS, propose but DO NOT create/execute:

```
ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01
```

Its entry shall be the actual correction CLOSE and its sole binding implementation contract ABI-A64-CMP-CC-2. If BUNDLE_MODE=TWO_PLUS_ADAPTER, its target is 13 → 15, with the emitter kept C-mechanical. If BUNDLE_MODE=THREE_INDEPENDENT, its target is 13 → 16, with independent semantic CSET evidence. Either way, implementation must have independent G0-G3 comparisons, per-authority PolyC causal experiments and C dormancy. SLICE10_AUTHORIZED=NO; SELFHOST_M2_ACHIEVED=NO.

### 6.2 Required terminal report keys

ACT_ID / ENTRY_HEAD / ENTRY_TREE / FINAL_HEAD / FINAL_TREE / BRANCH
ACT_COMMIT_COUNT / ACT_PHASE_SEQUENCE / ACT_VERDICT / DISPOSITION
ORIGINAL_RECON03_CLOSE_SHA / ORIGINAL_IMPLEMENT02_HALT_SHA
HISTORICAL_RECON03_VERDICT / HISTORICAL_IMPLEMENT02_VERDICT
HISTORICAL_CONTRACT_SHA256 / CORRECTED_CONTRACT_SHA256 / CORRECTED_ABI_VERSION
SOURCE_BLOB_OID / SOURCE_BLOB_BYTES / RANGE_CONVENTION
FOR_WHOLE_RANGE / FOR_WHOLE_SHA256 / INV_WHOLE_RANGE / INV_WHOLE_SHA256
CSET_WHOLE_RANGE / CSET_WHOLE_SHA256 / C1_PARTIAL_DIGESTS_REPRODUCED
C2_HISTORICAL_RANGE_DIGEST_MISMATCHES / SOURCE_PROVENANCE_VERDICT
CSET_ORIGINAL_U0_INERT / CSET_DISTINCT_SOURCE_POLICY_PROVEN
CSET_SEMANTIC_CLASSIFICATION / BUNDLE_MODE / CORRECTED_ABI_OBSERVABLE
PRODUCER_IDS_AND_DIGESTS / G0_G3_PLAN / PAIR12_VS_FROZEN12_DISTINCT
C_ORACLE_PROVEN / PROTOTYPE_REAL_LINK_PROVEN
PRODUCTION_AUTHORITIES / CORRECTION_INCLUSIVE_CAUSAL_AUTHORITIES
FUTURE_NEW_AUTHORITIES / FUTURE_TOTAL_AUTHORITIES / NEW_PRODUCTION_AUTHORITIES
PRODUCTION_SEMANTIC_DELTA / NEW_PROVEN_GRAPH_CUTS / GRAPH_52_134_34_19
PARSER_ASSERTIONS / PARSER_SEQUENCE_MD5 / LEXER_DIRECT_AND_BROAD_STATUS
CROSS_TARGET_PREFIX / F_NO_PYTHON / F_POLYC_TOOLS
NEGATIVE_CONTROLS_PASS / NEGATIVE_CONTROLS_NOT_RUN
AC_PASS / AC_FAIL / AC_NOT_RUN / AC_UNPROVEN / AC_DEFERRED
GATE_FAST / GATE_PUSH / APPEND_ONLY / F14 / FACTORY_V2 / PATCH_HYGIENE
EXTERNAL_TERMINALITY / WORKTREE_CLEAN / REPLACE_REFS / ACT_WORKTREES_REMAINING
POST_CLOSE_ACT_COMMITS / POST_CLOSE_ALL_COMMITS / PUSH_PERFORMED
NEXT_ACT_PROPOSED / NEXT_TARGET_AUTHORIZED / SELFHOST_M2_ACHIEVED

## 7. Frozen NC01–NC24: reason-specific negative controls

| NC | Adverse condition | Reason token |
|---|---|---|
| NC01 | Wrong entry HEAD/tree or branch | ENTRY_IDENTITY_MISMATCH |
| NC02 | Forgery or alias of an ACT CLOSE trailer | TRAILER_PROVENANCE_FAILURE |
| NC03 | Historical selected-contract blob modified in place | F14_HISTORICAL_REWRITE |
| NC04 | Original C1 partial digest passed as whole definition | RANGE_SEMANTIC_MISBIND |
| NC05 | Whole-definition interval extended one byte | SOURCE_RANGE_OFF_BY_ONE |
| NC06 | Correct hash paired with a different source blob OID | SOURCE_BLOB_PROVENANCE_MISMATCH |
| NC07 | C2 stale interval/digest reported as matching | FROZEN_RANGE_DIGEST_FALSE_PASS |
| NC08 | One of the three member rows omitted or duplicated | MEMBER_CARDINALITY_MISMATCH |
| NC09 | Original U0 two-scalar CSET export counted as observable | INERT_CSET_ABI |
| NC10 | CSET emitter activity counted as independent selection | DUPLICATE_SEMANTIC_AUTHORITY |
| NC11 | Same FOR mutation/witness reused for CSET authority | CAUSAL_SITE_DOUBLE_COUNT |
| NC12 | CSET independent policy claimed without source rule | SOURCE_RULE_ABSENT |
| NC13 | No real compiled PolyC value crosses corrected ABI | UNOBSERVABLE_CORRECTED_ABI |
| NC14 | Invalid or zero IrCmpKind mapped to fake error/suffix | DOMAIN_STATUS_COLLISION |
| NC15 | Borrowed suffix not terminated or written/freed by host | BORROWED_LITERAL_LIFETIME_VIOLATION |
| NC16 | Invalid float/integer condition accepted by default mapping | INVALID_CONDITION_NOT_FAIL_CLOSED |
| NC17 | Unassemblable suffix accepted as AArch64 condition | ASSEMBLER_SUFFIX_FALSE_PASS |
| NC18 | Two producer labels point to same executable digest | PRODUCER_ALIAS |
| NC19 | PAIR12 stream comparisons conflated with FROZEN12 checks | DIFFERENTIAL_SCHEMA_CONFLATION |
| NC20 | C-only oracle accidentally imports new PolyC subject | C_ONLY_ORACLE_CONTAMINATION |
| NC21 | Contract prototype object linked but caller does not read result | DORMANT_PROTOTYPE_AUTHORITY |
| NC22 | Unchanged production edge counted as a new graph cut | UNPROVEN_GRAPH_CUT |
| NC23 | Missing/duplicate acceptance ID or fabricated PASS field | AC_LEDGER_FALSE_PASS |
| NC24 | External AC50 receipt claimed before CLOSE or from wrong tree | PREMATURE_OR_MISBOUND_TERMINALITY |

Each NC must have a physical execution ID, actual adverse input, reason-specific detector, pristine/adverse/restored outcomes and an independently computed restoration digest. No generic parser failure is a substitute for the named reason. The AC and NC contracts must be sealed before implementation-phase evidence is produced.

## 8. Exactly 50 binding acceptance criteria

| AC | Phase | Criterion |
|---|---|---|
| AC01 | C0 | Exact entry HEAD, TREE, branch and clean classified residue. |
| AC02 | C0 | Actual RECON03 CLOSE and IMPLEMENT02 HALT found by trailers and ancestry. |
| AC03 | C0 | All ordinary post-CLOSE commits explicitly enumerated with blob changes. |
| AC04 | C0 | Historical RECON03 and IMPLEMENT02 verdicts and contracts preserved unchanged. |
| AC05 | C0 | F14 entry freeze includes all predecessor paths and reports zero new mismatches. |
| AC06 | C0 | All 13 production PolyC authorities verified; historical and correction-inclusive counts separated. |
| AC07 | C0 | Historical source blob OID and original C1/C2 interval claims bound to Git objects. |
| AC08 | C0 | Five real negative REDs executed reason-specifically, with restoration. |
| AC09 | C0 | Full AC01..AC50 and NC01..NC24 frozen with exact ID coverage. |
| AC10 | C0 | Populated-prefix parser and direct-lexer baselines freshly measured. |
| AC11 | C0 | Historical non-green baselines carried honestly and not silently greenwashed. |
| AC12 | C0 | No production edits or unauthorized source/quality-tool modifications at C0. |
| AC13 | C1 | Three complete source definitions extracted by source-aware scanner. |
| AC14 | C1 | Whole-function zero-based half-open ranges independently reproduced. |
| AC15 | C1 | New whole-function SHA-256 and Git OID bindings reproduced by second method. |
| AC16 | C1 | Original C1 partial digest matches its precise historical partial interval. |
| AC17 | C1 | Original erroneous C2 range pairs independently rehashed and shown mismatched. |
| AC18 | C1 | All three member and call-site boundaries nonoverlapping and classified. |
| AC19 | C1 | FOR and INV are production-reachable and have distinct semantic witnesses. |
| AC20 | C1 | CSET original source role measured separately from FOR dependency. |
| AC21 | C1 | CSET independence justified by distinct source-backed policy or denied as adapter. |
| AC22 | C1 | Corrected input domain includes zero, invalid, integer, float and unsupported partitions. |
| AC23 | C1 | Borrowed suffix, NULL/status, target ABI and C-owned lifetime contract fully specified. |
| AC24 | C1 | Producer executable DAG and PAIR12/FROZEN12 rosters unambiguously distinguished. |
| AC25 | C2 | Corrected source-boundary/hash contract is written only in new ACT evidence. |
| AC26 | C2 | Corrected ABI version ABI-A64-CMP-CC-2 is sealed in a separate new file. |
| AC27 | C2 | ABI has a genuine observable output path for every claimed PolyC authority. |
| AC28 | C2 | CSET classification mechanically maps to TWO_PLUS_ADAPTER or THREE_INDEPENDENT. |
| AC29 | C2 | TWO_PLUS_ADAPTER has no invented third export or third authority. |
| AC30 | C2 | THREE_INDEPENDENT has actual unique CSET source rule and witness. |
| AC31 | C2 | Real compiled PolyC plus C host prototype links and executes for the corrected ABI. |
| AC32 | C2 | Invalid input fails closed with no IR_CMP_EQ=0 collision. |
| AC33 | C2 | Static suffix ownership, lifetime and byte-exact formatting are tested. |
| AC34 | C2 | All corrected member rows, producer paths and fixtures have stable IDs and hashes. |
| AC35 | C2 | The future implementation contract binds exact 15 or 16 authority target. |
| AC36 | C2 | No production selector, object, source, test or linked authority changed. |
| AC37 | C3 | Independent PolyC verifier and separate Git/POSIX verifier agree on all ranges and SHA values. |
| AC38 | C3 | Negative source/hash/byte-boundary controls fire their correct reasons. |
| AC39 | C3 | All 24 distinct negative controls execute pristine/adverse/restored with no vacuity. |
| AC40 | C3 | Verifier anti-selftests reject missing AC IDs and false third-authority claims. |
| AC41 | C3 | Genuine selector-OFF C compiler oracle behavior and provenance established. |
| AC42 | C3 | Corrected prototype behavior verified against independent C baseline. |
| AC43 | C3 | All relevant AArch64 suffixes assemble, and invalid suffix is rejected. |
| AC44 | C3 | Future G0-G3 producer DAG and two separate 12-check rosters independently recomputed. |
| AC45 | C3 | All original 13 production authorities and graph baseline conserved; no new cut. |
| AC46 | C3 | Parser, lexer and known non-green baselines reported with exact identities. |
| AC47 | C3 | gate-fast and serialized gate-push pass with no skipped checks relabeled. |
| AC48 | C3 | F14, append-only, Factory-v2 pre-CLOSE validation and patch hygiene pass. |
| AC49 | C3 | Exactly 50 acceptance rows and 24 NC rows joined by ID; AC50 DEFERRED. |
| AC50 | C4 | External read-only post-CLOSE receipt validates terminal identity, scope, evidence, one CLOSE and no post-CLOSE ACT continuation. |

At C3 require AC01..AC49=PASS, AC50=DEFERRED, NC01..NC24=PASS. After the external receipt require all 50 PASS. If this ACT HALTs, count unfinished rows as NOT_RUN/UNPROVEN/DEFERRED as applicable; never claim 50 PASS from an early stop.

## 9. Evidence layout (new namespace only)

```
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01/
  c0/ entry-identity.tsv
      historical-ancestry-and-post-close.tsv
      predecessor-f14-freeze.tsv
      original-contract-identity.tsv
      thirteen-authorities.tsv
      baseline-parser-lexer.txt
      baseline-non-green.txt
      five-red-executions.tsv
      frozen-50-ac.tsv
      frozen-24-nc.tsv
  c1/ whole-definition-boundaries.tsv
      partial-vs-whole-digest-audit.tsv
      source-blob-and-callsite-provenance.tsv
      semantic-authority-cset-classification.tsv
      c-only-mutants-and-site-isolation.tsv
      input-domain-and-abi-ownership.tsv
      producer-dag-and-12plus12-crosswalk.tsv
  c2/ corrected-source-ranges.tsv
      corrected-source-ranges.sha256
      corrected-abi-v2.md
      corrected-abi-v2.sha256
      corrected-bundle-members.tsv
      corrected-selection-binding.tsv
      corrected-producer-dag.tsv
      future-implementation-contract.md
      real-seam-prototype-and-observability.tsv
  c3/ independent-rehash-and-join.tsv
      full-50-ac-ledger.tsv
      negative-controls-executed.tsv
      verifier-anti-selftests.tsv
      conservation-and-graph.txt
      gates-f14-append-only.txt
      implementation-readiness-verdict.tsv
  c4/ terminality-plan.txt
```

## 10. Non-binding documentation consulted

- Arm A64 CSET: instruction is an alias of CSINC; condition-code behavior affects 0/1 materialization: https://support.arm.com/documentation/100069/0602/A64-General-Instructions/CSET?lang=en
- Git git-interpret-trailers: https://git-scm.com/docs/git-interpret-trailers
- Git git-worktree (detached isolated experiments): https://git-scm.com/docs/git-worktree
- GNU make prerequisite semantics: https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html

These public references explain relevant tooling and ISA semantics. They do not replace the actual PolyC source, Factory doctrine, or commit/proof evidence as the authority for this ACT.

Final safety condition: This correction ACT may establish a new implementation authorization contract, but it must not perform the implementation. NEXT_TARGET_AUTHORIZED=NO, SELFHOST_M2_ACHIEVED=NO, and SLICE10_AUTHORIZED=NO are binding throughout.
