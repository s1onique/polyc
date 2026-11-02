# HANDOFF — ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01

**ACT:** `ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01`
**Class:** SELFHOST / M2 / FORECAST-REBASE / WORK-PACKAGE-DAG / SUCCESSOR-SELECTION
**Predecessor:** `ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01`
**Entry:** `9ba4ba5ddbbfacb10393514874c829c9f21d5ea4` (`78e6c706863aea2858d1dadb850b0fc30f78d6c4`)

VERDICT

PASS

---

Closure verdict authority is the `ACT-Verdict` trailer of the CLOSE commit.
This HANDOFF is a summary. The post-CLOSE terminality receipt is produced
outside the repository after that commit and is not claimed here.

## 1. The outcome in one paragraph

The M2 forecast is rebased on source-derived evidence, and the programme's
first real work is identified and selected. Two findings dominate. First,
the archived forecast's arithmetic is sound but its **load-bearing
assumption was never validated**: it assumed 12 decision sites per
implementation ACT, while the measured rate over the only cohorts that have
ever run is **1.0** — nine PolyC subjects against nine implementation ACTs.
Re-running the archived formula shape over the 1252 real authority rows at
the measured rate prices the full M2 scope at **1897 ACTs**, not 355.
Second, the archived forecast had **no independent critical path at all**:
its `critical_path_length` column equals its `total_effort_sum` in every
milestone row. The rebased model computes the two separately over a real
20-package DAG, with a witness route. The selected successor is the
**PolyC-authored driver** (`WP-001`), which unblocks nineteen of the twenty
packages, is the only R0 package that is qualified with a named witness and
no predecessors, and sits at the head of the critical path. **No migration
is performed by this ACT and no M2 milestone is claimed.**

## 2. The measured basis

```text
GRAPH_BASE_NODES                    52
GRAPH_BASE_RAW_EDGES                238
GRAPH_BASE_MANDATORY_EDGES          135 = 95 TYPE_REPRESENTATION
                                       + 14 MUTABLE_STATE
                                       + 14 CALLBACK
                                       + 12 RECOVERY
GRAPH_HISTORICAL_BASE               52/135/34/19
GRAPH_134_VS_135_DISPOSITION        THE ARCHIVED FILE CARRIES 135; 134 IS A
                                    NARRATIVE TRANSCRIPTION SLIP
SCC_CURRENT_PARTITION               34 components = 33 singletons + one of
                                    size 19, recomputed independently
E_TYP_0136_CURRENT_STATUS           PRESENT_AND_MANDATORY; the evidence is a
                                    HEADER INCLUSION ALONE, so it is an
                                    OBSERVED_LAYOUT_COUPLING candidate and
                                    NOT a proven mandatory atomic-migration
                                    edge
E_MUT_0137_STATUS                   PRESENT_AND_MANDATORY, but its witness
                                    cites the include line rather than a use
                                    site, so it remains an UNSUPPORTED WITNESS

PRODUCTION_LINK_OBJECTS             40 = 28 C objects + 12 PolyC helper subjects
BOUNDARY_A_PRECURSOR_MEMBERS        10 semantic translation units, 14346 LOC
BOUNDARY_B_FULL_SEMANTIC_UNITS      24 semantic translation units, 36677 LOC
MECHANICAL_GLUE                     4 units, 2991 LOC
POLYC_HELPER_SUBJECTS               12 sources, 1612 LOC
OPEN_MISSING_POLYC_SOURCES          24
POLYC_AUTHORED_COMPILER_SOURCE_SET_SIZE  0
EARLIEST_UNSATISFIED_BOOTSTRAP_GATE P0
```

The producer chain is `gcc` → 46 C translation units → C-rooted stage0 →
12 PolyC helper subjects → linker → the hybrid `./hcc`. Stage 0 compiles
PolyC source, but the source it compiles is **helper subjects**, not a
compiler; the output is a library a C compiler links in. That is exactly
the shape the ACT calls "a C-built host-stage0/hcc compiling `.HC` subject
objects", and it is **not** M2.

## 3. The forecast, and what changed

```text
                                  ARCHIVED            REBASED
M2 total effort                    355                1897
  low / base / high            159/355/961     1637/1897/3247
critical path                        355                  75
critical path is a derivation?         NO                 YES
total is a sum over the DAG?          NO                 YES
```

The archived forecast was **reproduced exactly** from the CENSUS01
verifier source — all four milestones, M1 154/348/948, M2 159/355/961,
M3 161/358/967, M4 201/447/1208 — which proves its arithmetic is sound.
Its weakness is its assumptions, and the sensitivity table attacks them
directly:

```text
SENSITIVITY_ROWS                     9, every one a RE-RUN of the real model
sites-per-ACT   1 (MEASURED)      -> 12 (the ARCHIVED assumption)
  effect on the M2 base         1897 ->    257   (delta -1640)
risk multiplier 1.00 -> 1.25 (the ARCHIVED assumption)
  effect on the M2 base         1897 ->   2161   (delta  +264)
correction rate 0.44 -> 0.25 / 0.65 (the ARCHIVED FA-03 band)
  effect on the M2 base         1897 -> 1654 / 2160
joint pessimistic corner                 351
joint optimistic corner                 1654
```

The sites-per-ACT rate is the single most load-bearing number in the model.
The archived 12 has **no measured cohort**; the measured 1.0 does.

The archived forecast's two presentation defects are recorded and NOT
carried forward:

```text
HISTORICAL_355_TOTAL                355
HISTORICAL_290_DISPLAYED_SUM        290  (the six category columns 5..10)
DELTA_65_CLASSIFICATION             A DISPLAY DEFECT, NOT AN ARITHMETIC
                                    DEFECT. The formula reproduces every
                                    milestone exactly. The 65 is the
                                    difference between the per-component
                                    column totals and the bundle base the
                                    total is actually built from. It
                                    represents NO unbudgeted work.
```

A C0 finding is **refined, not rewritten** (F14): C0 observed the 290
against 355 and called the 65 a model defect; C1 showed the model is
arithmetically exact and the 65 is a display artefact, and that the
companion defect is that the archived critical path is a copy of the
total. The rebased model therefore attacks the assumptions and replaces
the critical path with a real one.

## 4. The work-package DAG and the selected successor

```text
DAG_PACKAGES                        20
DAG_EDGES                           37
DAG_DUPLICATE_PACKAGE_IDS           0
DAG_DUPLICATE_EDGES                 0
DAG_DANGLING_REFS                   0
DAG_SELF_LOOPS                      0
DAG_CYCLIC                          0
DAG_TOTAL_EFFORT_LOW/BASE/HIGH      58/121/228
DAG_CRITICAL_PATH_ACTS              75
DAG_CRITICAL_PATH_WITNESS           WP-001 -> WP-002 -> WP-003 -> WP-004
                                    -> WP-005 -> WP-007 -> WP-008 -> WP-017
                                    -> WP-018 -> WP-019 -> WP-020
```

The critical path is 75 and the total is 121. They are **not** equated, and
the two independent implementations — the POSIX generator and the compiled
PolyC verifier — agree on every number.

```text
SELECTED_NEXT_WORK_PACKAGE          WP-001 (DRIVER)
  src/main.c + src/cli.c, 1257 LOC, 32 authority rows
  downstream unblocked              19 of the 20 packages
  qualification                     QUALIFIED (named witness, no predecessor)
  base effort                       3 ACTs (2 low / 3 base / 5 high)
  smallest runnable witness         hcc --install-dir=X -c input.HC -o out.o
NEXT_ACT_PROPOSED                   ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
NEXT_TARGET_AUTHORIZED              NO
```

The full contract, including what the successor must **not** touch, is in
`evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md`.

## 5. The evidence

```text
AC01..AC50                          50 frozen, 50 rostered, exact id-set join
                                    49 PASS, AC50 DEFERRED
NC01..NC24                          24 executed, 24 SENSITIVE, 0 failed
                                    each with its own reason token, each
                                    cross-checked by an independent POSIX
                                    witness that shares no code with the
                                    compiled PolyC detector
INDEPENDENT_RECOMPUTATION            15 checks, 15 match, 0 mismatch
PRODUCTION_SOURCE_CONSERVATION       0 files changed under src/,
                                    tools/bootstrap/, tests/ and
                                    scripts/quality/
GATE_FAST                           exit 0, VERDICT=PASS
GATE_PUSH                           exit 0, VERDICT=PASS (serialized)
APPEND_ONLY                         PASS=11 FAIL=0
FACTORY_V2_RANGE (predecessor)      COMMITS=4, VERDICT=PASS
CLOSURE_STATUS                      MANIFEST_ROWS=60, PAIR_OK=60
PARSER_BASELINE_AT_C3                376/376 over 90 blocks, MD5
                                    b6f117eb1386ca80f81bc06226e2a741
DIRECT_LEXER_AT_C3                   89/89, 45/45, 23/23
F_NO_PYTHON                         FAIL at the same 12 tracked paths, 0 new
F_POLYC_TOOLS                       UNAVAILABLE (the canonical checker does
                                    not exist)
CROSS_TARGET_PREFIX                 NOT_REMEASURED
```

## 6. What this ACT did not do

* It performed **no migration**. `src/**`, `tools/bootstrap/**`, `tests/**`
  and `scripts/quality/**` are byte-identical to the entry.
* It created **no new production authority** and claimed **no new cut**.
* It claimed **no M2 milestone**. `M0_SELFHOST = ACHIEVED`,
  `M1_SELFHOST = NOT ACHIEVED`, `M2_SELFHOST = NOT ACHIEVED`.
* It wrote **no successor code**.
* It did **not** rewrite any historical ACT or evidence file.

## 7. The predecessor's debt, recorded and not inherited

The predecessor `ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01`
has four real phase-bearing commits, `RED, IMPL, EVIDENCE, CLOSE`, and the
canonical range check returns `COMMITS=4 VERDICT=PASS`. Its own frozen AC50
text demands **five** trailers, so:

```text
PREDECESSOR_FOUR_COMMIT_RANGE       CONFIRMED (4 commits, read from git
                                    object history, not from narrative)
PREDECESSOR_CANONICAL_RANGE_STATUS  PASS
PREDECESSOR_FROZEN_AC50_LITERAL_STATUS  NOT_SATISFIED_AS_WRITTEN
PREDECESSOR_TERMINALITY_BINDING     BOUND_EXACT_HEAD_AND_TREE (the external
                                    receipt at
                                    /tmp/a64cc-terminality-receipt-20261102T023649.txt
                                    really exists outside the tree and its
                                    BOUND_HEAD/BOUND_TREE are byte-equal to
                                    the entry)
C1_EVIDENCE_COMMIT_PRESENT          NO
```

This is **historical governance debt**, classified `HISTORICAL_GOVERNANCE_DEBT`
with `BLOCKS_NEXT=NO`: the predecessor was neither backdated nor rewritten,
and its receipt was not fabricated. A new ACT was opened rather than
this one rewriting a closed predecessor's evidence.

## 8. The next ACT

`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01`, scoping `WP-001`: the PolyC-authored
driver. It is a bounded migration of the argument handling and the compile
entry point, with the real production invocation as its witness.

It is the right first step for three measured reasons: it unblocks nineteen
of twenty packages; the P0 bootstrap gate is about a **compiler-producing
source set**, which cannot begin with a lexer; and the lexer already has six
dormant PolyC prototypes that are selector-OFF today, so it has precedent
and can wait for its own turn.

## 9. The residue this ACT leaves behind

```text
P1  The archived CENSUS01 forecast still carries its unvalidated FA-04
    assumption and its critical-path-is-the-total defect. This ACT does not
    rewrite it (F14). A bounded correction to CENSUS01 may record the
    measured sites-per-ACT rate and the display defect.
P1  The cross-target prefix baseline is NOT_REMEASURED. It was not
    re-measured here because the environment was not available.
P2  tools/factory/factory-polyc-tools-check.HC does not exist, so
    F-POLYC-TOOLS remains unenforceable.
P2  /tmp/holyc-asm.s is a shared hard-coded scratch path. This ACT avoided
    it by serialisation and did not fix it.
```

## 10. The required final report keys

```text
ACT_ID                            ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01
ENTRY_HEAD                        9ba4ba5ddbbfacb10393514874c829c9f21d5ea4
ENTRY_TREE                        78e6c706863aea2858d1dadb850b0fc30f78d6c4
FINAL_HEAD                        the CLOSE commit; queried from git history
FINAL_TREE                        the CLOSE tree; queried from git history
BRANCH                            main
FACTORY_PHASE_SEQUENCE            C0 RED -> C1 EVIDENCE -> C2 IMPL ->
                                  C3 EVIDENCE -> C4 CLOSE
ACT_COMMIT_COUNT                  5
CLOSE_SHA                         the CLOSE commit; queried from git history
ACT_VERDICT                       PASS
DISPOSITION                       CONTINUE
PREDECESSOR_FOUR_COMMIT_RANGE     CONFIRMED
PREDECESSOR_FROZEN_AC50_LITERAL_STATUS  NOT_SATISFIED_AS_WRITTEN
PREDECESSOR_CANONICAL_RANGE_STATUS     PASS
PREDECESSOR_TERMINALITY_BINDING        BOUND_EXACT_HEAD_AND_TREE
PRODUCTION_POLYC_AUTHORITIES_ENTRY     9
PRODUCTION_POLYC_AUTHORITIES_FINAL     9
CSET_ADAPTER_NOT_COUNTED               YES
NEW_PRODUCTION_AUTHORITIES              0
PRODUCTION_SEMANTIC_DELTA               0
CENSUS01_HISTORICAL_AUTHORITY_ROWS      2233
CURRENT_RECONCILED_REMAINING_SEMANTIC_SCOPE  2218 C_AUTHORITY rows
VENDORED_EXCLUDED_COUNT                 2
UNKNOWN_AUTHORITY_COUNT                 3 nodes + 4 unknown-bearing edges
COARSE_SITE_UNCERTAINTY                 1006 coarse + 901 straight-line rows
GRAPH_HISTORICAL_BASE                   52/135/34/19
GRAPH_CURRENT_PRODUCTION                NOT_ESTABLISHED
GRAPH_SHADOW                            ABI_FOUNDATION_RECON01_CUT_LEDGER_SCOPE
GRAPH_CONTRACT                          PER_CONTRACT_SUBSET_SCOPE
GRAPH_134_VS_135_DISPOSITION            THE_ARCHIVED_FILE_CARRIES_135__134_IS_A_NARRATIVE_TRANSCRIPTION_SLIP
E_TYP_0136_CURRENT_STATUS              PRESENT_AND_MANDATORY__HEADER_INCLUSION_ONLY
E_MUT_0137_STATUS                      PRESENT_AND_MANDATORY__UNSUPPORTED_WITNESS
SCC_CURRENT_PARTITION                  34 (33 singletons + one of size 19)
BOOTSTRAP_DAG_NODES_EDGES              5 stages, 4 edges
BOOTSTRAP_CRITICAL_PATH_WITNESS        GC-01 -> GC-02 -> GC-03 -> GC-04 (GC-04 ABSENT)
M2_PRECURSOR_SOURCE_SET                10 semantic units, 14346 LOC
M2_FULL_SEMANTIC_SOURCE_SET            24 semantic units, 36677 LOC
PERMITTED_C_GLUE                       4 units, 2991 LOC
GENERATION_CHAIN_IDENTITIES             GC-01 gcc; GC-02 C-rooted stage0;
                                       GC-03 linker; GC-04 ABSENT; GC-05 ABSENT
EARLIEST_UNSATISFIED_BOOTSTRAP_GATE    P0
BB_01_TO_BB_04_DISPOSITION              BB-04 BLOCKS; BB-01/02/03 do not block
                                       the selected slice
RES_01_TO_RES_04_DISPOSITION           RES-04 CONFIRMED_BY_MEASUREMENT as
                                       UNSUPPORTED GRAMMAR and does not block
                                       the selected slice; RES-01/02/03 are
                                       HISTORICAL_ONLY_NOT_REMEASURED
NEW_BLOCKERS                           0
HISTORICAL_355_TOTAL                   355
HISTORICAL_290_DISPLAYED_SUM           290
DELTA_65_CLASSIFICATION                DISPLAY_DEFECT__THE_FORMULA_REPRODUCES_EVERY_MILESTONE_EXACTLY
FORECAST_SCENARIOS                     5 (S01 the selected step, S02, S03 the
                                       front end, S04 the precursor, S05 the
                                       full scope)
FORECAST_LOW_BASE_HIGH_OR_UNBOUNDED   1637/1897/3247 for the full scope
TOTAL_VS_CRITICAL_PATH                 1897 total vs 75 critical path
FORECAST_ASSUMPTION_COHORTS           sites-per-ACT 1 MEASURED (9 subjects
                                       against 9 ACTs); risk multiplier
                                       ASSUMED; correction rate 0.44 MEASURED
                                       on the parser-slice cohort only
BELOW_100_HYPOTHESIS_DISPOSITION       NOT_SUPPORTED. The archived verdict
                                       holds, and under the measured rate the
                                       optimistic corner is 351, still above
                                       100.
SELECTED_NEXT_WORK_PACKAGE             WP-001
NEXT_ACT_PROPOSED                      ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
NEXT_TARGET_AUTHORIZED                 NO
```

## 11. The AC50 discharge

AC50 is discharged **only** from the external read-only terminality
receipt, which is generated AFTER the CLOSE commit, outside the repository,
and bound to the exact terminal HEAD and TREE. This HANDOFF does not claim
it. The receipt verifies the fifteen unchanged authorities, zero production
semantic delta, accurate bootstrap milestone labels, the full
source/producer/DAG/forecast joins, all AC and NC, the five-commit
sequence, no post-CLOSE continuation, no ACT-created worktrees, no replace
refs, a clean index and worktree, and no push.

If the receipt fails, the disposition is `HALT_EXTERNAL_TERMINALITY`: no
second CLOSE, no Git history rewrite, no ordinary receipt commit.
