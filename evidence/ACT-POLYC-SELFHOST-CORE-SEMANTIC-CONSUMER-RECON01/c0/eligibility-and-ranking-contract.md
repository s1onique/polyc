# Eligibility and ranking contract — C0 freeze

ACT: `ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01`
Phase: `C0-RED`

This contract is frozen before candidate ranking. Eligibility is recomputed from
source/object facts; a pre-filled eligible flag is never an input.

## Population boundary

The population is every production-linked C-owned semantic decision in the
actual `CFG-PROD-HCC-JIT-ON` compiler. Parser, AST construction with semantic
effect, type/symbol checking, CFG/IR, optimization when actually linked, and
code generation are core families. Driver/debug-only, logging, formatting,
REPL, LSP, vendored code, platform/runtime glue, the already-migrated nine
parser authorities and the one CPA authority are separately classified and do
not count as remaining C candidates.

Function rows, semantic-site rows, compiler authority decisions, build objects,
and graph edges are counted separately. Helper functions and raw symbols are not
new authorities. Whole-function parser blockers remain explicit candidates or
blocked work even when their boundary is difficult.

## E01–E14

| ID | Frozen predicate |
|---|---|
| E01 | Every site is live in the declared normal production configuration; source, object, and reachability joins are complete. |
| E02 | Every selected decision is C-authoritative at entry, not already delegated to compiled PolyC or an external provider. |
| E03 | The effect changes compiled-program behavior, acceptance, emitted IR/assembly/object, or a compiler semantic invariant; diagnostics/debug/formatting alone do not qualify. |
| E04 | The semantic rule and site boundaries are exact and source-hashed at the frozen entry tree. |
| E05 | A callable, bounded PolyC/C seam can be expressed without exposing raw AST/Map/List/Cctrl/Arena layout to PolyC. |
| E06 | Host reads/writes, aliases, arenas, epochs, borrowed handles, error statuses, and lifetime transitions are enumerated. |
| E07 | Recovery and callbacks cannot cross an active PolyC frame unsafely; a verified boundary exists or a blocking dependency is explicitly resolved by the plan. |
| E08 | G0 genuinely compiles the unchanged C rule, with source/object provenance and no dependency on the future PolyC subject. |
| E09 | Source-derived fixtures include reachable positive, negative, boundary, and invalid-input behavior as applicable. |
| E10 | A bounded C-side adverse mutation rebuilds the real compiler and produces a core semantic observable difference; restoration is source/object-identical. |
| E11 | A plausible selector-OFF/ON producer and link plan exists, including stage0 OFF, without make prerequisite-expansion hazards. |
| E12 | Scope has finite, named touched source/caller/header/host paths, or it is explicitly deferred as an ABI-foundation blocker. |
| E13 | The bundle measurably affects a bootstrap-critical dependency or the actual C-owned core semantic decision set, without inventing an SCC reduction. |
| E14 | The proposal does not rewrite frozen predecessor evidence, fix unrelated compiler defects, or require another unauthorized semantic migration. |

Any failed predicate makes the bundle `INELIGIBLE` with the exact reason.

## Deterministic ranker R0–R6

Eligible bundles are sorted lexicographically. The tuple is not a weighted sum.

1. `R0` bootstrap semantic criticality, descending: `2` direct M2-critical,
   `1` plausible M1/core enabling, `0` none. E13 excludes `0`.
2. `R1` number of distinct C-owned core semantic decisions retireable in one
   bounded ABI, descending; exact site-ID union, excluding adapters,
   existing authorities, and diagnostics.
3. `R2` independent core-semantic causal witnesses, descending; rebuilt real
   C-mutant channels only, one physical experiment counted once.
4. `R3` number of current core dependencies meaningfully replaceable,
   descending; replacement only, not completed cuts.
5. `R4` safety readiness, descending; complete lifetime/status/recovery/
   ownership contract preferred, while E05–E07 remain hard gates.
6. `R5` bounded implementation surface and reversibility, ascending; touched
   source/host/producer files, selector strategy, and bounded witness cost.
7. `R6` source-stable tie-break, ascending; exact bundle ID, then source IDs.

The canonical checker and an independent implementation consume measured fact
rows, independently recompute eligibility, and reproduce the entire ordered
list and selection.

## Fail-closed rules

Missing rows, malformed SHA-256, duplicate IDs, absent source files,
phase-stale blobs, unknown statuses, forged eligible flags, orphan graph edge
IDs, ambiguous build configuration, or an unexplained candidate-set difference
are explicit non-PASS conditions. No preferred candidate may be inserted or
promoted after ranking.

## Causal qualification

The eventual selected bundle requires a source-bound C mutation in a unique
detached worktree at the frozen tree. The real full compiler must rebuild, the
changed object must be proven linked, and the witness must differ in semantic
acceptance, generated IR/object, or executed compiled-program behavior.
Cosmetic, diagnostic-only, stale-object, fixture-only, dormant-branch, and
compile-failure outcomes do not qualify. If the first mutation is build-invalid
or inert, its transcript is preserved and at least one additional bounded live
mutation is attempted before disqualification.
