# The deterministic rank contract (ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03)

This contract is FROZEN at C1, BEFORE any candidate is observed to be
eligible and BEFORE the final selection is made. The rubric, its input
sources and its tie-break are fixed here; the C2 ranker implements
exactly this and the independent PolyC ranker re-derives it
independently.

## Rank key

Every provisionally eligible bundle is scored on R0..R6. The bundles are
then ordered by:

```text
R0 descending, R1 descending, R2 descending, R3 descending,
R4 descending, R5 ascending, R6 ascending
```

R6 is the exact candidate identity in bytewise ascending order and is
the tie-break only. The order is total: two distinct candidates can
never tie, because their identities differ.

## The score definitions, and where each input comes from

| Score | Meaning | Input source | Rubric |
|-------|---------|--------------|--------|
| R0 | bootstrap dependency | `c1/bootstrap-path.tsv` | 2 = shown to be on an OBSERVED M2-critical path; 1 = compiler-core semantic progress that is NOT demonstrated M2-critical; 0 = neither. |
| R1 | semantic impact diversity | the OBSERVED channel of each member, measured on the pristine entry compiler, recorded in `c1/eligibility-input-facts.tsv` | the number of DISTINCT observed channels among the members, counted from actual entry compiler runs, not from predicted mutant results. The three channels are COMPILER_ACCEPTANCE, IR_ASSEMBLY_OBJECT, RUNTIME_BEHAVIOUR. |
| R2 | independently testable C authority site count | the member count of the candidate | the number of uniquely identifiable, independently testable C authority sites, CAPPED AT SIX. This is a pre-mutation ranking proxy, NOT a claim of causal qualification. At C2 the selected member count must equal the number of independently proven physical causal experiments. |
| R3 | coherence of the shared ABI and invariants | `c1/eligibility-input-facts.tsv` plus the candidate's `abi_shape` | 2 = a single bounded scalar ABI covers every member, the invariant is named and shared, the input domain is total and source-derived, and ownership is explicit (no pointer crosses the seam); 1 = a single ABI covers the members but the invariant is weaker or one member needs a second projection; 0 = no single ABI covers the members. |
| R4 | graph reduction potential | the committed 134-edge production graph | the number of production graph edges whose SOURCE witness is one of the candidate's members, counted against the CURRENT graph. Every such edge is recorded as POTENTIAL_ONLY, never as CUT_PROVEN: no cut is proven by a planned ABI. The unsupported edge E-MUT-0137 is NOT weighted at all. |
| R5 | implementation complexity / risk | `c1/eligibility-input-facts.tsv` | the SUM over the members of (host_state_writes + recovery_crossing + ptr_derefs). Ascending: a LOWER risk score is better. All three dimensions are source-derived counts of the actual host state the member touches. |
| R6 | candidate identity | the candidate id | the exact candidate id in bytewise ascending order. Tie-break only. |

## Frozen rubrics that must not be silently amended

- **R0=2 is unavailable to every candidate in this ACT.** The M2
  producer is absent (`c1/bootstrap-path.tsv`, GC-14): no PolyC-authored
  compiler source set exists, so there is no observed M2-critical path
  for ANY candidate to sit on. Being inside the 19-subsystem SCC does
  NOT make R0=2. The maximum honest R0 is 1.
- **R4 never claims a cut.** A candidate whose members are the source
  witnesses of N production edges scores N on R4 and records N
  POTENTIAL_ONLY edges. It scores 0 on any "proven cut" notion, because
  no cut is proven by this ACT.
- **R2 is capped at six** and never exceeds the member count.

## The RANKER's inputs are mechanical

The ranker consumes the candidate ids from the ELIGIBILITY CHECKER's
output and joins them by stable candidate id against
`c1/core-candidates.tsv` and `c1/eligibility-input-facts.tsv`. It never
reads a freehand "eligible" flag, and it never re-derives eligibility:
that is the checker's job, and the independent PolyC recomputation
re-derives it separately from the C1 source facts.
