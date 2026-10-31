# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT — implementation authorization, not an execution or completion report
Class: SELFHOST / ABI_CORE / APPEND_ONLY_EVIDENCE_CORRECTION / CAUSAL_ATTRIBUTION
Priority: P1 — bounded proof-integrity correction; no demonstrated production failure
Repository: existing canonical local PolyC checkout (s1onique/polyc); remote availability not assumed
Branch: existing main; no per-ACT branch
Expected ENTRY_HEAD: 30432271ab1f56079be3a33dbddc415392b5034e
Expected ENTRY_TREE: 2d7793da3ed5df495e18198c920d6abd90629217
Direct predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01, PASS (closure-cardinality correction)
Binding historical defect: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01, misattributed M-POLYC-RO physical mutation
Discovering ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02, HALT_PREDECESSOR_PROOF_INCOMPLETE, GOVERNANCE / BLOCKS_NEXT=NO
Authorized production migrations: ZERO
Authorized persistent production source changes: ZERO
Existing structurally active PolyC decision authorities: 13 (9 parser + 1 CPA + 3 core operator sites)
Historical independent causal backing: 12/13; AUTH-13 unproven in the historical IMPLEMENT01 execution
Next bundle: NONE; SLICE10_AUTHORIZED=NO; SELFHOST_M2_ACHIEVED=NO

## 0. Mission and strict interpretation of PASS

Supply a new, independently executed and independently attributable
post-migration PolyC-source causal experiment for SITE-RANGE-OPERATOR /
AUTH-13. The new physical mutation must occur inside
`AbiCoreIsRangeOperator`, must be compiled into the real selector-ON
production compiler, and must change a discriminating compiled-program
semantic outcome before byte-identical source/object/behavior
restoration.

The historical IMPLEMENT01 experiment labeled `M-POLYC-RO` actually
mutated `AbiCoreIsValidPointerOperator` (the PO site). RECON02
independently matched its recorded source and object digests to the
PO-LT mutation. A historical `.diff` file describing a desired RO
mutation was not the source compiled. This ACT does not rename,
replace, invalidate or rewrite those historical bytes. It creates a
distinct correction execution, joined to the original site and its
original defect.

The two distinct questions must never be conflated:

```text
IMPLEMENT01_HISTORICAL_M_POLYC_RO_EXECUTED_ON_RO = NO
IMPLEMENT01_HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT = AbiCoreIsValidPointerOperator
RECON02_HISTORICAL_HALT = HALT_PREDECESSOR_PROOF_INCOMPLETE (unchanged)
CORRECTION_RO_LITERAL_MUTATION = PROVEN | UNPROVEN  (new execution only)
CORRECTION_RO_OWN_EXECUTION_ID = <unique correction-owned ID>
AUTHORITIES_STRUCTURALLY_ACTIVE = 13
AUTHORITIES_CAUSALLY_BACKED_AT_IMPLEMENT01_CLOSE = 12
AUTHORITIES_CAUSALLY_BACKED_WITH_CORRECTION = 13 | 12
NEW_PRODUCTION_AUTHORITIES = 0
PRODUCTION_SEMANTIC_DELTA = 0
NEW_PROVEN_GRAPH_CUTS = 0
SELECTED_BUNDLE_ID = NONE
```

PASS disposition: `PASS_EVIDENCE_SUPPLEMENTED`, only after the actual
compiled RO mutation, real program outcome, independent PO
discrimination, exact provenance joins, restoration, correction
ACs/controls, gates and external terminality all succeed. Factory-v2
terminal trailer uses `ACT-Verdict: PASS`; the disposition lives in the
correction-owned report/HANDOFF.

HALT dispositions: `HALT_ENTRY_IDENTITY`, `HALT_HISTORICAL_BINDING`,
`HALT_RO_MUTATION_WRONG_SUBJECT`, `HALT_RO_MUTANT_BUILD`,
`HALT_RO_CAUSAL_UNPROVEN`, `HALT_SITE_ISOLATION`, `HALT_RESTORATION`,
`HALT_GATES_OR_BASELINES`, `HALT_FACTORY_OR_TERMINALITY`, or an
explicitly measured more precise reason. No assertion of an executed
correction is permissible on HALT.

### 0.1 Explicit non-goals

- No new migration, compiler feature, ABI extension, parser selection,
  whole-compiler M1/M2 claim or 14th authority.
- No edit to `src/**`, `tools/bootstrap/**`, existing tests, Makefile,
  CMake, canonical verifier/gates, existing ACTs/HANDOFFs/ROADMAP

## 1. Source-of-truth hierarchy and immutable freeze

At C0 read the actual local Git objects and the repository's current
`AGENTS.md`, `docs/factory/DOCTRINE.md`,
`docs/factory/GIT-METADATA.md`, Factory-v2 message/range/closure
checkers, F14 and append-only scripts. The current repository rules win
over inferred prior conventions if they conflict; report a contract
conflict instead of silently changing this authorization.

Mandatory historical evidence to read and preserve byte-for-byte:

```text
docs/acts/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01.md
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/scope-and-mutant-plan.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/semantic-witnesses.md
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c2/selector-build-matrix.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/mutant-ca.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/mutant-po.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/mutant-ro.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/site-isolation.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/c-off-on-dormancy.tsv

docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02.md
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/c0/predecessor-ro-attribution.tsv
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/c0/predecessor-ro-attribution-witness.tsv
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/c0/authority-conservation.tsv
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/c0/predecessor-g0-proof.tsv

docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01.md
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01/c4/terminal-closure-identity.tsv
```

If any listed file has a different name in the actual committed tree,
locate it by verified `git ls-tree` and record the rename/provenance;
do not invent data or silently skip a required historical fact. Freeze
full path+SHA-256 for all closed predecessor artifacts, and report
added predecessor paths separately. F14 must check every path, not only
a summary count.

The historical observations to independently reproduce are:

| Item | Recorded SHA-256 / result | Correct interpretation |
|---|---|---|
| Pristine PolyC core-operator object | `b9a76fe8a23b38468e78b67ed428226592fa270347674299c1be1be57f4de756` | Common object for CA/PO/RO; not three separate objects |
| Historical M-POLYC-RO source | `f0599f79900cf406415283a9742c2b3d794c03f107e7a959ce021db91b916615` | PO-LT mutation, despite RO label |
| Historical M-POLYC-RO object | `2d6a1394dffa8b513af092971338692e113cbf893c4d52a0b554afda9d58c1f8` | Same physical PO-LT mutation |
| RECON02 real RO mutant source | `dc068867b66ded3786531b3755a99438334ef4438d1ab658051337082f88b3d1` | Independent prior exploratory RO experiment; not the historical IMPLEMENT01 execution |
| RECON02 real RO mutant object | `c73e734dc6b735bd738fd2e3f5735f10b577d5048730d586d2892b153ca77eff` | A useful cross-check, never a hardcoded expected output on a different build |
| SITE-RANGE-OPERATOR | `src/ast.c` → `_AbiCoreIsRangeOperator` | Structurally live, missing historical causal attribution |

Source and object digests are build-identity-specific. The correction
must independently compute fresh hashes; matching the previous RECON02
exploratory hashes is corroborating evidence, not a replacement for
demonstrating the new execution. If compiler flags or source root
differ, explain the difference instead of fabricating byte identity.

## 2. Authorized paths and execution isolation

Only the following tracked paths may be added/changed:

```text
docs/acts/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01.md
docs/factory/act-handoff-map.tsv                # exactly one append row
docs/ROADMAP.md                                 # bounded append only
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/**
tools/quality/abi-core-implement01-correction01-*.HC  # only if substantive verifier is needed
```

No Makefile edits to add a convenience target. Run correction tools
directly from the correction evidence directory if needed. If a
substantive verifier is introduced, it must be PolyC-authored and its
own compiled object/execution must be verified. Small POSIX
sh/`awk` control drivers are allowed solely as evidence utilities, not
disguised general-purpose implementations. No Python, dependencies,
generated binaries, external evidence logs or machine-local paths
committed as source.

Mutations may only occur inside disposable detached worktrees of the
verified local entry commit, using `git worktree add --detach`. In each
worktree the sole tracked source change for the experiment is the one
permitted mutation hunk in `tools/bootstrap/selfhost-core-operator.HC`;
experiments must not alter the authoritative checkout. Independent
build and install directories, tool output directories and transient
witness files must be isolated and documented. Do not run any two
compiler invocations concurrently: the known global `/tmp/holyc-asm.s`
temporary path can race even across distinct make commands. Dispose
only of worktrees created by this ACT; never remove another user's

## 3. Factory-v2 lifecycle — exactly five commits

Execute C0 RED → C1 EVIDENCE → C2 IMPL → C3 EVIDENCE → C4 CLOSE as one
linear non-merge chain of five commits, each with validated ACT and
ACT-Phase trailers. C4 carries `ACT-Verdict: PASS` only if the contract
is fully satisfied; otherwise use the repository's actual HALT trailer
convention. The external receipt is created after C4 outside the
repository and never backdated into C3 or CLOSE.

### C0 — RED: entry, freeze and reproduction

1. Check: `git branch --show-current` == main, `git rev-parse HEAD` ==
   30432271ab1f56079be3a33dbddc415392b5034e, `git rev-parse HEAD^{tree}`
   == 2d7793da3ed5df495e18198c920d6abd90629217, clean index/worktree
   (tracked and untracked distinguished), zero replace refs, and no
   dangling ACT-owned worktrees. If identity differs, HALT.
   `origin/main` may lag; verify ancestry only if the remote-tracking
   ref is present, without networking.
2. Verify RECON02 terminal technical HALT and its forward-only closure
   correction PASS: the RECON02 duplicate CLOSE remains historically
   present; the correction ACT has exactly one CLOSE and carries
   ACT-Supersedes and ACT-Corrected-Verdict forward without modifying
   history.
3. Read and hash-check the full historical bundle/ABI, original
   M-POLYC-RO and PO records, RECON02 C0 attribution, current PolyC
   subject bytes, caller source and production object/link identity.
4. Independently reproduce the RED: historical M-POLYC-RO actual
   compiled mutation is PO-LT; original evidence contains no executed
   RO-site mutant. Detector must fail when an intended `.diff` is
   substituted for a compiled source/object hash.
5. Freeze an exact-ID acceptance contract (AC01..AC28) and 12
   correction-owned negative controls (NC01..NC12) before running any
   correction experiment. Store explicit required paths, execution IDs,
   detector classes and expected clean/adverse/restored results.
6. Measure fresh, correctly installed parser and lexer baselines with
   known full-prefix configuration. A test wrapper returning zero with
   missing tests or unpopulated prefix is a FAIL; capture actual
   per-test outcomes and runner identities.
7. Record all 13 structurally active production PolyC decision sites
   and the state `HISTORICAL_CAUSAL_BACKING=12/13`; do not report
   13/13 at C0.
8. Commit C0 RED only after the frozen contract and the reproducing
   failure are real.

### C1 — EVIDENCE: actual RO source site, semantic discriminator, builds

1. Locate function `AbiCoreIsRangeOperator` in the actual committed
   PolyC source `tools/bootstrap/selfhost-core-operator.HC`. Derive the
   complete function byte/line range and SHA-256 from the C0 Git blob.
   Independently locate `AbiCoreIsValidPointerOperator`; prove their
   source ranges are disjoint, even though both reference
   AST_BIN_OP_LT.
2. Freeze exactly one intended mutation: remove AST_BIN_OP_LT from the
   range operator's recognized cases, preserving valid syntax and every
   other case. The mutation detector must prove all changed bytes lie
   inside `AbiCoreIsRangeOperator`, exactly one named operator membership
   changes, and neither the pointer nor compound-assignment function
   changes. Do not perform a global search/replace.
3. Derive numeric AST_BIN_OP_LT and all other affected enum values from
   live `src/ast.h`, including implicit values. Preserve the
   ABI-CORE-OP-1 status/out-parameter semantics and
   `AST_BIN_OP_MUL == 0`; no accidental status/data collision.
4. Freeze a new correction-owned discriminating witness
   `W-CORR-RO-DISCRIM` built for this compiler; semantic core is the
   chained-range expression `5 < 1 < 3`. Document the actual executable
   source syntax, result channel and expected compilation/execution
   procedure from an executable pristine run, not a hand-written logical
   assertion.
5. Freeze an independent pointer-site discriminator `W-CORR-PO-LT`, and
   a compound-assignment control `W-CORR-CA`. The historical `1 < 2 < 3`
   is retained as `W-HISTORICAL-NONDISCRIM`, explicitly insufficient to
   prove RO causality.

### C2 — IMPL (supplementary evidence only): new physical causal experiment

Run the following separate physical executions with unique
correction-owned IDs. An execution ID must bind source diff SHA,
actual source SHA, object SHA, compiler executable SHA, build
command/exit, witness binary, exit/output and restoration identity.
Never reuse the historical M-POLYC-RO ID.

**EXEC-RO-CORR01-PRISTINE**

1. From the frozen entry identity, perform a fresh selector-ON
   production compiler build with a unique build/install prefix.
   Require successful executable install and a full, nonempty subject
   object/link map.
2. Record the exact original PolyC source and subject object SHA-256;
   verify the `src/ast.c` caller relocates to `_AbiCoreIsRangeOperator`
   and not a still-live C duplicate rule.
3. Build and run W-CORR-RO-DISCRIM: expected program exit 0; record
   actual stdout/stderr and compiled assembly/IR alongside source and
   compiler identity. Run W-CORR-PO-LT and W-CORR-CA and freeze pristine
   results.

**EXEC-RO-CORR01-MUTANT**

1. Create a new detached worktree at frozen entry; apply only the
   C1-frozen `AbiCoreIsRangeOperator` mutation within that worktree;
   record actual `git diff --binary`, full source hash and exact changed
   function range hash.
2. Verify by independent read of mutated source bytes that the
   recognized RO set changed and the pointer/compound functions are
   byte-identical. The intended patch is not proof of applied bytes.
3. Rebuild and install the entire real production compiler with
   selector ON, using the same recorded effective flags and
   independent, clean build prefix. Compilation must succeed; missing
   subject object or stale unchanged object is a HALT.
4. Check the actual compiled PolyC subject object is different, the
   actual linked production executable is different, and the real
   `ast.c` caller's RO delegation remains live. Use symbols and
   function-scoped disassembly/relocations as available on this target;
   explicitly account for deterministic identical caller object when
   only subject changes.
5. Recompile and run the exact same chained-range witness. Required
   measured semantic discriminator: pristine exit 0 → actual RO mutant
   exit 1. Its emitted assembly/IR must independently show changed
   range-lowering behavior (e.g. loss of the short-circuit block),
   without relying on a fixed assembler label or a copied string
   comparison.
6. Verify PO and CA control witnesses retain their pristine outcomes.
   An RO mutation that changes only a pointer-specific witness, changes
   the PO function, or fails to change W-CORR-RO-DISCRIM is NOT PROVEN.

**EXEC-PO-CORR01-ANTI (distinct adverse control)**

In another detached worktree, independently mutate the pointer-site LT
membership only, build the full selector-ON compiler successfully, and
run the same witness set. W-CORR-RO-DISCRIM must remain at exit 0 while
the pointer-specific witness must change in its expected manner. Record
separate physical execution/source/object identities. This prevents a
repeated M-POLYC-RO misbinding; it does not count as a second RO
experiment.

**EXEC-RO-CORR01-RESTORED**

Remove the RO mutant worktree using safe Git worktree operations, or
restore its source bytes explicitly before cleanup, then rebuild the
exact pristine configuration. Require original tracked source bytes,
subject object (given identical producer/environment), compiled witness
output and semantic results restored. When object determinism is not
reproducible, demonstrate exact controlled build-environment differences
and demand semantic/normalized-object equivalence; never label that
byte-identical. Confirm main's tracked tree/working index remain
untouched and all ACT-owned mutant worktrees removed.

Optional fresh C-dormancy anti-control, if needed by C1's frozen oracle
obligation: mutate the legacy RO C decision only in a disposable

### C3 — EVIDENCE: independent audit, controls and conservation

1. Independently recompute the actual source range, enum semantics,
   mutation target, source diff SHA, compiler object/program hashes and
   witness outcomes from raw experiment artifacts without trusting the
   correction driver's PASS fields.
2. Join by exact site ID and physical execution ID:
   `AUTH-13 ⇄ SITE-RANGE-OPERATOR ⇄ _AbiCoreIsRangeOperator ⇄
   EXEC-RO-CORR01-MUTANT ⇄ W-CORR-RO-DISCRIM`. Explicitly reject the
   predecessor's mislabeled M-POLYC-RO as a substitute.
3. Run 12 adverse controls with pristine→adverse→restored
   reason-specific outputs and separate physical execution IDs (or
   explicit shared-experiment disclosure). Prove the verifier rejects
   deletion/duplication/unknown IDs, forged PASS and swapped witness
   attributions. An always-green detector is prohibited.
4. Re-measure full baseline and gates serially, using valid installed
   test prefixes, not stale binaries. Preserve 376/376 parser assertions
   across 90 files with exact MD5 `b6f117eb1386ca80f81bc06226e2a741`;
   lexer direct 89/89, 45/45, 23/23; broad LEXER07 historical 15
   failure IDs and MD5 `7ee761440de83552e751e3c3976c1683`; cross-target
   67 prefix failures if unchanged; F-NO-PYTHON 12 historical/0 new;
   F-POLYC-TOOLS UNAVAILABLE unless actually landed.
5. Verify 13 structurally active, 12 causally backed historically, and
   13 backed when the new supplement is included. No new production
   authorities, no production byte or semantics changes, and graph stays
   52 nodes / 134 active mandatory edges / 34 SCC / largest 19 / sole
   historic E-TYP-0136 cut. E-MUT-0137 remains UNSUPPORTED_WITNESS.
6. Run gate-fast, serialized gate-push, append-only 11/11, F14 path
   freeze, closure-status, patch hygiene, Factory-v2 commit-trailer
   validation. Treat the current in-progress ACT range as
   NOT_TERMINAL_EXPECTED until C4; never falsify a PASS before CLOSE.
   Record an exact AC01–AC27 correction ledger; AC28 remains DEFERRED
   until post-CLOSE receipt.

### C4 — CLOSE: append-only correction and external terminality

Produce exactly one correction-owned ACT, HANDOFF, one new map row, one
bounded ROADMAP append, frozen evidence tree, and one terminal C4 CLOSE
commit with trailers:

```text
ACT: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

Use the current committed Factory-v2 message validator before each
commit. If repository rules require extra correction metadata (e.g. an
evidence-supplement trailer), add only the defined trailer; do not
assert supersession of the historical technical verdict unless doctrine
specifically requires it. The new ACT supplements evidence and preserves
both the historical IMPLEMENT01 PASS and later RECON02 HALT. Do not
create a second CLOSE to store terminal checks.

After C4, run an external read-only verifier; keep its immutable receipt
outside the repository, bound to the exact terminal SHA/tree, five
commit trailers, F14 manifest, corrected execution IDs/source/object/
witness digests, conservation, final gates and absence of later commits.
Only then can AC28 be PASS and terminal disposition
`PASS_EVIDENCE_SUPPLEMENTED` be reported.

If AC28 or any other criterion remains unproven, report the actual
failure/HALT; do not create a follow-up commit under the same ACT to

## 4. Frozen twelve negative controls — must be executable, reason-specific

| ID | Adverse condition | Required rejecting detector |
|---|---|---|
| NC01 | Replace correction entry HEAD/tree with predecessor or wrong tree | ENTRY_IDENTITY_MISMATCH |
| NC02 | Change one closed predecessor evidence byte or freeze-path digest | F14_PREDECESSOR_TAMPER |
| NC03 | Claim historical M-POLYC-RO mutated the RO function | HISTORICAL_MUTATION_SUBJECT_MISMATCH |
| NC04 | Present intended `.diff` instead of actual compiled mutant source | APPLIED_SOURCE_DIFF_PROVENANCE_FAILURE |
| NC05 | Apply LT mutation in `AbiCoreIsValidPointerOperator` instead of RO | RO_WRONG_FUNCTION_MUTATED |
| NC06 | Accept an unlinked, stale or failed subject/full-compiler build | RO_BUILD_OR_LINK_PROVENANCE_FAILURE |
| NC07 | Substitute nondiscriminating `1 < 2 < 3` as sole witness | RO_SEMANTIC_WITNESS_NONDISCRIMINATING |
| NC08 | Accept pointer-site witness change as range-site proof | SITE_ISOLATION_OR_WITNESS_MISBIND |
| NC09 | Reuse one execution ID for both RO and PO mutant | DUPLICATE_PHYSICAL_EXECUTION_ID |
| NC10 | Forge PASS without pristine/mutant/restored object or exit matrix | CAUSAL_RESTORATION_OR_EVIDENCE_MISSING |
| NC11 | Claim 14th authority, new graph cut or historical 13/13 evidence | AUTHORITY_OR_HISTORICAL_OVERCLAIM |
| NC12 | Omit control/AC ID, relabel known FAIL, or claim external receipt before CLOSE | LEDGER_OR_TERMINALITY_FALSE_PASS |

All twelve require a detector that is SILENT on genuine pristine, FIRED
on the specified adverse input for the named reason, and SILENT again
after restoration. For document/ledger mutation controls, isolated
copies suffice; for actual semantic attribution use the full real
compiler. Record physical execution identities; test the control
checker itself against missing/duplicate/swapped IDs.

## 5. Exactly 28 mandatory correction acceptance criteria

Frozen verbatim at C0 with id, phase, predicate, evidence path,
independent checker and status. Distinguish PASS / FAIL / NOT_RUN /
UNPROVEN / DEFERRED. Do not derive counts from summary declarations
alone.

| ID | Phase | Mandatory predicate |
|---|---|---|
| AC01 | C0 | Exact HEAD/tree, branch, clean state, zero replace refs and correct unpublished-local predecessor chain verified |
| AC02 | C0 | RECON02 historical HALT and its forward-only cardinality correction PASS bound to actual commits/trailers |
| AC03 | C0 | Entire closed-predecessor path/byte F14 freeze independently recorded and matched |
| AC04 | C0 | Original IMPLEMENT01 RO source+object digests recomputed and shown to represent a PO mutation |
| AC05 | C0 | Historical RO causality remains UNPROVEN_AS_RECORDED, without rewriting any predecessor status |
| AC06 | C0 | 13 structural authorities, 12 historical causal authorities, all recorded accurately |
| AC07 | C0 | Historical conservation and fresh baseline measured with real test-prefix installation |
| AC08 | C0 | Frozen 28-AC/12-NC contracts, no missing, duplicate or unexpected IDs; real RED detector sensitive |
| AC09 | C1 | Actual `AbiCoreIsRangeOperator` and pointer function source ranges separately bound by Git OID/SHA |
| AC10 | C1 | RO-only mutation removes AST_BIN_OP_LT without modifying pointer/CA function or ABI behavior |
| AC11 | C1 | Actual working discriminating chained-range witness defined, compiled, executed and frozen |
| AC12 | C1 | Independent pointer and compound controls, including nondiscriminating historical witness, recorded |
| AC13 | C1 | Real selector-ON production compiler and genuine selector-OFF C-only oracle, objects and link provenance established |
| AC14 | C1 | Full isolated build topology, producer identity, flags, source-hash/witness matrix and rollback frozen |
| AC15 | C2 | New RO mutant applied in detached worktree, exact actual applied bytes/diff verified within RO only |
| AC16 | C2 | Full real selector-ON mutant compiler rebuilt successfully; new subject object and executable truly linked |
| AC17 | C2 | New RO mutant changes real compiled-program semantic exit from 0 to 1 and independently changes lowering IR/assembly |
| AC18 | C2 | PO and CA witnesses remain unchanged under RO mutation; site isolation proved |
| AC19 | C2 | Distinct pointer mutant changes pointer witness but not the discriminating RO witness |
| AC20 | C2 | RO source, compiled object and witness restored with exact provenance; byte identity reported only when demonstrated |
| AC21 | C2 | Corrected site-isolation matrix binds each site to its own actual physical experiment, without changing history |
| AC22 | C3 | Independent verifier rederives source/object/compiler/witness and exact-ID/site joins, rejecting historical mislabeled experiment |
| AC23 | C3 | All 12 reason-sensitive negative controls plus verifier anti-selftests executed, no vacuous PASS |
| AC24 | C3 | 13 structural / 12 historical causal / 13 correction-inclusive causal authority accounting verified |
| AC25 | C3 | Parser and lexer identities, historical non-green baselines and normal production source semantics conserved |
| AC26 | C3 | No new graph cut/SCC claim; E-TYP-0136 only and E-MUT-0137 unsupported; no forbidden tracked changes |

## 6. Minimum evidence structure

```text
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/
  c0/
    entry-identity.txt
    predecessor-closure-identity.tsv
    predecessor-f14-freeze.tsv
    historical-ro-reconstruction.tsv
    historical-physical-execution-join.tsv
    baseline-parser.txt
    baseline-non-green.txt
    existing-authorities.tsv
    frozen-28-ac.tsv
    frozen-12-nc.tsv
    red-detector-pristine-adverse-restored.tsv
  c1/
    source-function-identity.tsv
    enum-domain-source.tsv
    intended-ro-only-mutation.diff
    source-ownership-and-abi.tsv
    discriminating-witness-source.HC
    semantic-witness-contract.tsv
    genuine-selector-on-off-builds.tsv
    producer-and-link-provenance.tsv
    experiment-plan-and-rollback.md
  c2/
    pristine-source-object-compiler.tsv
    applied-ro-mutation.diff
    applied-ro-source-hashes.tsv
    ro-mutant-full-build.txt
    ro-mutant-object-link-provenance.tsv
    ro-pristine-mutated-restored-witness.tsv
    po-anti-mutant-full-build.txt
    po-anti-control-witness.tsv
    ca-po-ro-site-isolation-corrected.tsv
    restoration-identity.tsv
    source-object-witness-execution-join.tsv
  c3/
    independent-verification.tsv
    verifier-selftests.tsv
    negative-control-executions.tsv
    negative-control-id-join.tsv
    corrected-causal-evidence-ledger.tsv
    authority-conservation.tsv
    graph-and-f14-recheck.tsv
    parser-lexer-conservation.txt
    historical-non-green-conservation.txt
    gates-and-factory.txt
    ac01-ac27-ledger.tsv
  c4/
    terminality-plan.txt             # explicitly a PLAN, not a receipt
```

If the repository prefers a source-derived alternative filename, record
an exact path mapping. Never commit temporary compiler binaries or copy
megabytes of raw output into the evidence tree without a bounded
hash/index. If raw logs live outside the repo, include exact hash,
replay command, location and note their retention limitations; commit
enough bounded evidence to support independent audit even if /tmp is
reclaimed. A raw log path alone is not proof.

## 7. Final report schema

```text
ACT_ID=ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01
ENTRY_HEAD=30432271ab1f56079be3a33dbddc415392b5034e
ENTRY_TREE=2d7793da3ed5df495e18198c920d6abd90629217
FINAL_HEAD=<actual 40-character SHA>
FINAL_TREE=<actual 40-character SHA>
VERDICT=<PASS|HALT>
DISPOSITION=<PASS_EVIDENCE_SUPPLEMENTED|measured HALT reason>
HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT=AbiCoreIsValidPointerOperator
HISTORICAL_RO_CAUSAL=UNPROVEN_AS_RECORDED
CORRECTION_RO_ACTUAL_SUBJECT=AbiCoreIsRangeOperator
CORRECTION_RO_EXECUTION_ID=<unique physical ID>
CORRECTION_RO_CAUSAL=<PROVEN|UNPROVEN>
WITNESS_RO_PRISTINE_EXIT=<observed>
WITNESS_RO_MUTANT_EXIT=<observed>
WITNESS_RO_RESTORED_EXIT=<observed>
PO_ANTI_CONTROL_RO_WITNESS_EXIT=<observed>
CORRECTION_RO_SOURCE_SHA256=<actual>
CORRECTION_RO_OBJECT_SHA256=<actual>
SOURCE_OBJECT_WITNESS_JOIN=<PASS|FAIL>
SITE_ISOLATION=<PASS|FAIL>
SOURCE_RESTORATION=<BYTE_IDENTICAL|NOT_PROVEN>
OBJECT_RESTORATION=<BYTE_IDENTICAL|ENVIRONMENT_EXPLAINED|NOT_PROVEN>
PRODUCTION_AUTHORITIES_STRUCTURAL=13
HISTORICAL_AUTHORITIES_WITH_CAUSAL_PROOF=12
CORRECTION_INCLUSIVE_AUTHORITIES_WITH_CAUSAL_PROOF=<13|12>
NEW_PRODUCTION_AUTHORITIES=0
PRODUCTION_SEMANTIC_DELTA=0
NEW_PROVEN_GRAPH_CUTS=0
PRODUCTION_GRAPH=52_NODES_134_EDGES_34_SCC_LARGEST_19
SELFHOST_M2_ACHIEVED=NO
SELECTED_BUNDLE_ID=NONE
SLICE10_AUTHORIZED=NO
F14=<PASS|FAIL>
GATE_FAST=<PASS|FAIL>
GATE_PUSH=<PASS|FAIL>
NEGATIVE_CONTROLS=<N/12>
MANDATORY_AC=<N/28>
FACTORY_V2_RANGE_CHECK=<PASS|FAIL>
EXTERNAL_TERMINALITY=<PASS|FAIL|UNPROVEN>
BRANCH=main
WORKTREE_CLEAN=<YES|NO>
REPLACE_REFS=<integer>
POST_CLOSE_COMMITS=<integer>
PUSH_PERFORMED=NO
```

## 8. Handoff and roadmap

On PASS, HANDOFF must state that the historical IMPLEMENT01 defect
remains true, but correction-owned physical experiment
EXEC-RO-CORR01-MUTANT supplies the missing evidence going forward. Do
not claim the historical M-POLYC-RO was a range mutation, nor rewrite
RECON02's terminal HALT or its correction's PASS. State precisely that
13 live authorities are now supplemented to 13/13 causal evidence by
later execution, not that 13/13 was true at IMPLEMENT01 CLOSE.

Next proposed (not authorized) ACT:
`ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03`, a fresh selection
ACT. It must perform a fresh source/object census because RECON02
halted before C1; no inherited selected bundle exists. The separately
recognized unit-test fail-open issue and shared `/tmp/holyc-asm.s`
race remain backlog items and cannot be silently fixed here.

No push or publication under this ACT. Preserve the local append-only
chain and its existing origin/main lag. A future fast-forward
publication requires separate operator authorization and ancestry
verification.

## 9. External references (procedural only)

- Git git-worktree documentation — detached worktrees and explicit removal: https://git-scm.com/docs/git-worktree
- Git git-show documentation — historic commit/blob content and object provenance: https://git-scm.com/docs/git-show
- GNU Make manual — rule prerequisite read-in expansion: https://www.gnu.org/software/make/manual/html_node/Reading-Makefiles.html

Project semantics, names, sha256s, historical dispositions and
authority counts are grounded in the local repository/digest, not in
these external references. In case of discrepancy, the actual committed
Git objects and verified physical experiments decide.

| AC27 | C3 | gate-fast/gate-push, append-only, F14, patch hygiene and pre-CLOSE Factory checks verified; HANDOFF/roadmap prepared |
| AC28 | External | Post-CLOSE read-only receipt proves final HEAD/tree, five phases, single CLOSE, final gates, corrected experiment, F14 and zero post-CLOSE commits |

PASS requires AC01–AC28 all independently PASS, not 27 PASS plus an
unobserved external check. At C3 the honest maximum is 27 PASS, 1
DEFERRED. If any factual obligation fails, do not invent a substitute
witness or waive it.

change an already terminal CLOSE.

selector-ON/OFF build pair; OFF must change, ON must be inert. Never
substitute this for the required PolyC RO mutant. Reuse existing
validated OFF evidence only with explicit frozen source/object
attribution.

Generate a new site-isolation ledger with one row each for CA, PO and
RO, plus the correction execution IDs, asserting RO's specific
source/object/witness identity and independence. State explicitly that
the original historical `site-isolation.tsv` is false as written and
unchanged. Preserve the original historical verdict and failure
identity; do not transform RECON02 HALT into PASS.

6. Establish real production selector-ON and selector-OFF build
   identities using supported existing flags; verify ON links the
   PolyC subject and imports `_AbiCoreIsRangeOperator` from the actual
   `src/ast.c` caller, while OFF uses the live C legacy rule with no RO
   subject reference from the caller. A copied standalone C oracle is
   insufficient for an OFF proof.
7. Record source/OID, build configurations, real compiler producers,
   object-to-binary linkage, expected failure mode, C1 witness matrix,
   and isolated worktree lifecycle before the C2 experiment. If a real
   clean build is impossible, HALT rather than using a stale object.

worktree.

  history or closed evidence on the authoritative checkout.
- No rewriting `M-POLYC-RO`, `site-isolation.tsv`, its recorded diff or
  the misleading historical PASS claims. No retroactive correction of
  the predecessor's execution date.
- No repair of RECON02's duplicate CLOSE (already forward-corrected),
  the unit-test fail-open prefix, the `/tmp/holyc-asm.s` collision,
  E-MUT-0137, F-NO-PYTHON or F-POLYC-TOOLS.
- No `git push`, `fetch`, `pull`, `rebase`, `reset`, `amend`, `replace`
  or history rewrite. Existing local unpushed commits remain intact.
