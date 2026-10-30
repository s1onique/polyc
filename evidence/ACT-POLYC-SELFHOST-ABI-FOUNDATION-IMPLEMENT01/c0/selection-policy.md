# C0 frozen selection policy

**ACT:** ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01
**Phase:** C0 (frozen BEFORE any candidate-specific implementation)
**Status:** frozen at C0; no post-hoc edit is permitted after C1 freezes a
`SELECTED_EDGE_ID`. If the selected consumer proves unimplementable, this ACT
HALTs (`HALT_NO_SAFE_SOURCE_REPRESENTATIVE_CONSUMER` /
`HALT_EDGE_NOT_FULLY_RETIRED`) and a successor must re-authorize.

---

## 1. Admissibility (all five must hold, else the candidate is disqualified)

| id | criterion | mechanical test |
|----|-----------|-----------------|
| AD-1 | candidate edge is in the exact RECON01 14-ID set | exact-ID membership in `c0/recon01-14-candidates.tsv`; any other ID ⇒ `CANDIDATE_NOT_FROZEN` (AI-02) |
| AD-2 | the consumer is a source-representative C translation unit that is actually compiled and linked into the production compiler | the TU appears in `build/compile_commands.json` **and** its object is an input of the `hcc` link line (`build/CMakeFiles/hcc.dir/<tu>.o`) |
| AD-3 | the TU has a **direct, semantic** dependence on a real AST (or List) layout, not only an incidental `#include` | a measured member access / offset use in the TU's own object code, not merely a header name in the preprocessed output |
| AD-4 | the smallest bounded semantic operation using AST kinds/children or List state is identifiable inside the TU, has a reachable compiler caller, and is observable with a stable corpus | a named function, an AST node kind read, `argc`-independent test input, deterministic stdout |
| AD-5 | the operation can be expressed with scalar/opaque-handle ABI only | no `Cctrl`/`longjmp` crossing a PolyC frame, no callback retention, no `Map`/`AoStr` handle, no arbitrary shared mutable state, no arena allocation ownership transfer |

## 2. Danger ranking (applied only to admissible candidates)

Ordered, most preferred first. Each key is compared before the next:

1. **Ownership / recovery boundary safety** — first prefer a *pure read* of
   host state with no mutation capability, no allocation, no recovery escape,
   no callback. Then read-with-bounded-count. Mutation of host containers and
   any recovery/`longjmp` surface rank strictly worse.
2. **Strength of the end-to-end witness** — first prefer an operation whose
   effect is observable on a real compiler invocation (stdout / accepted-vs-
   rejected source / diagnostic identity), then an operation observable only
   through a component fixture.
3. **Graph criticality** — prefer the edge whose `src_id` subsystem has fewer
   *other* mandatory out-edges to the same destination, so that the selected
   edge is genuinely per-TU rather than an aggregate subsystem relation.
4. **Smaller patch** — fewer changed lines, fewer touched headers, smaller
   transitive include closure.

Ties are broken by ascending `edge_id` (a stable, source-bound order).

## 3. Disqualification reasons (recorded per candidate, never dropped)

```text
DQ_NOT_LINKED_TU            AD-2 fails
DQ_INCIDENTAL_INCLUDE_ONLY  AD-3 fails (include present, no layout use)
DQ_NO_BOUNDED_OPERATION     AD-4 fails
DQ_ABI_INFEASIBLE           AD-5 fails (recovery/callback/ownership)
DQ_TRANSITIVE_INCLUDE_TRAP  the TU's AST dependency is re-imported by another
                            header in its own closure, so removing the literal
                            include would leave the layout in the preprocessed
                            TU (this is the AI-10 failure mode; it is a
                            *disqualifier at C1*, not something to paper over)
```

`DQ_TRANSITIVE_INCLUDE_TRAP` is deliberately part of the frozen policy: the
ACT forbids the "hide the header elsewhere" manoeuvre, so a candidate whose AST
dependency arrives through a header the change set may not touch is not
selectable.

## 4. Required C1 freeze fields

By the end of C1 the following are frozen and may not be re-chosen without a
new authorization:

```text
SELECTED_EDGE_ID
SELECTED_CONSUMER_TU
SELECTED_OPERATION
SELECTED_SOURCE_SHA256
SELECTED_TU_BLOB_SHA1
EXPECTED_POST_CHANGE_CONSTRAINTS   (what must be true of the shadow TU)
```

## 5. Explicit non-goals of the ranking

- "easiest to fake" is not a tiebreaker;
- a fixture-only or component-only demonstration never upgrades a candidate;
- a candidate that requires widening the tracked production scope is
  disqualified, not silently widened.
