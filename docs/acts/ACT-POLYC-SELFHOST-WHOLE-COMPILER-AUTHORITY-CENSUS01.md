# ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / WHOLE-COMPILER / AUTHORITY-INVENTORY / DEPENDENCY-GRAPH / BOOTSTRAP-ROADMAP
**Priority:** P0 — replaces automatic parser-only reconnaissance as the next planning step
**Repository:** `s1onique/polyc` — the canonical local checkout; remote access is not presumed
**Branch:** existing `main` (no ceremonial branch)
**Expected ENTRY_HEAD:** `a7f5648077b27b9af2f29f034eb27b4aba6941f8`
**Expected ENTRY_TREE:** `ce428215cf8e8ec6376782aad7c7182ca188deb7`
**Binding predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE09` — historical CLOSE/PASS, re-verified
**Existing production PolyC parser authorities:** 9, independently re-proved from executable objects
**New production authorities authorized:** 0
**Production semantic delta:** 0
**Migration successor:** NONE until this ACT closes and a specific successor receives separate authorization

---

## 0. Mission

Establish the first complete, evidence-bound whole-compiler semantic
authority census for the actual production PolyC compiler and its
bootstrap configurations — not another census limited to `src/parser.c`,
`src/prslib.c`, `src/prsutil.c` and `src/ast.c`.

From that census: a typed dependency graph, coherent migration bundles,
a minimal plausible route to a first genuinely self-hosted compiler
generation, and reproducible low/base/high ACT forecasts by bundle and
bootstrap-critical path.

Success is a trustworthy map and an evidence-derived plan. It is NOT a
compiler migration, a PASS claim for whole self-hosting, or a
preselected parser successor.

### 0.1 Questions this ACT answers

1. Which concrete production-linked decisions still obtain their
   semantics from C, which from compiled PolyC, and which are C
   mechanical adapters?
2. Which compiler components exist in the real active build graph, and
   which are used by stage0, production, JIT/AOT and other supported
   variants?
3. Which remaining C decisions are on the minimum dependency path to
   compiling a PolyC-authored compiler implementation with PolyC itself?
4. Which decisions can migrate together behind bounded ABIs without
   hiding AST ownership, mutable symbols, callbacks, recovery, target
   state or stage provenance?
5. Which dependencies form inseparable strongly connected groups, which
   are optional/external, and what must be solved first?
6. What is the defensible ACT-count distribution and critical path for
   (A) semantics transfer, (B) first self-hosted compiler, (C)
   reproducible bootstrap convergence and (D) legacy-C elimination?
7. Is the previous hypothesis of fewer than 100 additional ACTs
   plausible? If not substantiated, say UNPROVEN rather than rounding.

## 1. Entry and predecessor gates

At C0: read the actual committed bytes in order — `AGENTS.md`,
`docs/factory/DOCTRINE.md`, Factory-v2 commit/trailer/range/HALT/closure
rules, F14, the append-only policy, `docs/ROADMAP.md`, the canonical
board ownership — then SLICE09's five-commit range and its C0..C4
evidence, then RECON04..RECON08 / SLICE06..SLICE08 as read-only
precedent (RECON06 remains HALT, never retroactively PASS), then the
live CMake/Make recipes, link commands, compile database, `src/**`,
`tools/bootstrap/**`, generated inputs and stage-specific targets.

Entry gates: current HEAD and `HEAD^{tree}` exactly equal the expected
values; branch `main`; clean index/tree; zero replace refs; no
unauthorized intervening commits; SLICE09 an authentic five-commit
CLOSE/PASS; all nine parser decision sites object-proven. A mismatch is
`HALT_ENTRY_IDENTITY` / `HALT_PREDECESSOR_INTEGRITY` /
`HALT_NINE_AUTHORITY_CONSERVATION`. Never reset, replay or amend to make
entry match.

## 2. Permitted scope

```text
docs/acts/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01.md
docs/factory/act-handoff-map.tsv        # one additive mapping row
docs/ROADMAP.md                         # bounded additive planning section
evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/**
tools/quality/whole-compiler-census01-*.HC   # new PolyC producer/verifier(s)
Makefile                                # additive census-only targets, if proven required
```

No tracked `src/**`, `tools/bootstrap/**`, runtime header, existing
tool/test, canonical checker/ranker, CI/gate script, CMake config,
toolchain, dependency manifest, `.githooks` or historical
ACT/HANDOFF/evidence modification. `.factory/epic-board.md` does not
exist in this checkout; the proposed board entry is written in the
HANDOFF instead.

No new Python, no new third-party dependency, no large Bash
orchestration. Substantive source, graph and planning logic is PolyC
(`.HC`); short POSIX shell/`awk`/`nm`/`otool`/`git`/build-system
invocations transport evidence only. Pointer-valued PolyC ternaries are
avoided (known OOM lead).

All compiler/JIT/AOT/test/gate builds are serialized across all
worktrees/processes because `/tmp/holyc-asm.s` is a shared filename.

## 3. Deliverables

A complete versioned source-derived corpus, machine-readable (TSV where
the repository already uses TSV), with row-derived counts:

```text
c0/  entry identity, predecessor freeze, nine-authority object proof,
     frozen baselines, frozen 50-AC contract, frozen 24-control
     contract, five REDs, scope/milestone definitions
c1/  build-targets, build-configs, link inputs and archive members,
     compiler generation chain, semantic coverage, authorities,
     authority/function/object joins, graph nodes/edges, unknown edges,
     subsystem inventory and exclusions, coverage verification
c2/  verifier build and selftest, classification consistency,
     SCC members, condensed migration DAG, topological order, bundles,
     bundle members, bootstrap milestones/blockers, first-generation
     feasibility, forecast assumptions/forecast/scenarios, next ACT class
c3/  independent joins, independent SCC/DAG, independent bundle and
     forecast recomputation, uncertainty sensitivity, negative-control
     raw results, control execution join, source/history conservation,
     parser/lexer conservation, gate-fast, gate-push, factory-v2/F14/
     append-only, mandatory 50-AC status
c4/  terminality plan
```

## 4. Factory-v2 lifecycle

Exactly five forward commits on the existing checkout:

| Commit | Phase | Primary deliverables |
|---|---|---|
| C0 | RED | entry + predecessor freeze, 50-AC and 24-control contract, baselines, five real REDs |
| C1 | EVIDENCE | source/build inventory, accounted reachable census, typed graph raw facts |
| C2 | IMPL | new substantive PolyC census/graph/forecast verifier, SCCs, bundles, scenarios, M2 feasibility contract |
| C3 | EVIDENCE | independent recomputation, 24 adverse controls, baselines/gates, forecast sensitivity, AC01–AC49 ledger |
| C4 | CLOSE | one HANDOFF, additive roadmap/map entry, terminality plan, one CLOSE |

No C2 compiler-production implementation: IMPL means the new
census/verification tooling, not migration. If source coverage cannot be
established, stop with an evidence-backed HALT rather than manufacturing
a five-commit PASS.

## 5. Frozen acceptance contract and negative controls

The 50 acceptance criteria (`AC01`..`AC50`) and the 24 negative controls
(`WC-IC-01`..`WC-FC-04`) are frozen in
`evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c0/` as
machine-readable TSVs before any derived conclusion. Each control has a
pristine PASS -> targeted adverse FAIL with an exact detector class ->
restoration PASS, executed on injected copies, never on closed evidence
or the production checkout. Controls requiring real object provenance
inspect real produced objects or genuinely altered duplicates, not table
flags.

`AC50` is `DEFERRED` at C3 and becomes `PASS` only after an actually
observed external read-only post-CLOSE receipt.

## 6. HALT dispositions

```text
PASS_CENSUS_AND_ROADMAP
HALT_ENTRY_IDENTITY · HALT_PREDECESSOR_INTEGRITY
HALT_NINE_AUTHORITY_CONSERVATION · HALT_INCOMPLETE_BUILD_CLOSURE
HALT_UNBOUND_REACHABLE_SEMANTICS · HALT_SOURCE_ID_OR_PHASE_HASH
HALT_GRAPH_EDGE_OR_SCC · HALT_UNJUSTIFIED_BUNDLE
HALT_UNREPRODUCIBLE_FORECAST · HALT_BOOTSTRAP_MILESTONE_FALSE_CLAIM
HALT_WRONG_SUBJECT_OR_DORMANT_AUTHORITY
HALT_CONTROL_UNEXECUTED_OR_WRONG_REASON
HALT_NEW_PARSER_OR_LEXER_REGRESSION · HALT_GATE_FAST · HALT_GATE_PUSH
HALT_FACTORY_V2_F14_APPEND_ONLY · HALT_MANDATORY_AC_UNPROVEN
HALT_TERMINALITY
```

A HALT records the observed AC/control counts and one reason; it never
asserts PASS or pretends a skipped phase ran. No second migration is
authorized merely because the graph has a rank-1 bundle.

## 7. Known technical debt — inventory, never fix here

* initialized file-scope scalar / `Main(argc, argv)` storage collision —
  a real compiler-correctness lead and possible bootstrap blocker;
* pointer-valued ternary / `Bool`-`I64` inference and the reported
  16 GB OOM — a language-feature feasibility classification, not a
  source workaround counted as a fix;
* shared `/tmp/holyc-asm.s` race — serialize here; estimate as separate
  infrastructure if on the critical path;
* SLICE06 stale CMake producer path; canonical checker lacking
  source-range-hash validation; ranker trusting caller-provided
  eligibility; original handwritten/weak G0 provenance;
* LEXER07 (15 identities), cross-target prefix (67), F-NO-PYTHON (12),
  absent F-POLYC-TOOLS, the standalone factory-halt-classification
  inline-assembly build failure and the historical SLICE08
  self-referential controls stay distinct — measure whether each
  blocks M2, do not merge them.

## 8. Activation rule

`PARSER-SURFACE-RECON09`, a bundle implementation and `SLICE10` are NOT
authorized by this ACT. After a valid census PASS, the next ACT class is
selected from the measured critical path; a concrete implementation
still requires its own bounded authorization.
