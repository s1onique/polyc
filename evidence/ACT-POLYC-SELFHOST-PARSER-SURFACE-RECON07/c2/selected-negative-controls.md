# SELECTED NEGATIVE CONTROLS (for the successor ACT)

These are the controls the successor ACT must execute. They are
FROZEN HERE, BEFORE the successor's own adverse observations, so the
successor cannot invent a control after seeing a favourable outcome.

The successor MUST execute every control below. The successor's C3
stage MUST join each by EXACT ID to a concrete adverse command, the
intended detector class, the observed detector class, the subject,
the object/producer hashes, the exit codes, the restored bytes and a
positive baseline.

**A control that is not executed is UNPROVEN, not PASS.**

## THE INVENTORY CLASS

| ID | Adverse action | Required nonvacuous detector |
|---|---|---|
| SL-IC-01 | Delete one live function from the census | Missing exact source/function ID |
| SL-IC-02 | Duplicate one function/candidate ID | Duplicate exact ID |
| SL-IC-03 | Alter one source-range SHA-256 | Exact source hash mismatch |
| SL-IC-04 | Invalid, out-of-file or overlapping identity range | Invalid range/overlap, not a generic parse failure |

## THE ELIGIBILITY CLASS

| ID | Adverse action | Required nonvacuous detector |
|---|---|---|
| SL-EC-01 | Mark the newly migrated SUB-002 authority as still eligible C | Already-self-hosted exclusion |
| SL-EC-02 | Suppress a transitive mutable-host-state dependence | Source/call-graph dependency detector |
| SL-EC-03 | Insert a nonzero host AST graph write in the candidate facts | Host-graph-write clause |
| SL-EC-04 | Inject callback or recovery ownership | The correct separate eligibility clause |
| SL-EC-05 | Add an unreachable candidate with an excellent rank | Actual reachability exclusion |
| SL-EC-06 | Unknown ID or missing required eligibility fact | Unknown-ID or missing-fact-specific detector |

## THE RANKING CLASS

| ID | Adverse action | Required nonvacuous detector |
|---|---|---|
| SL-RC-01 | Shuffle genuine facts, then submit a forged order-dependent ranking | Genuine ranker invariant AND independent full-order comparator rejects the forged order. **BOTH halves are required.** |
| SL-RC-02 | Give an excluded candidate the lowest numeric rank | Remains excluded, not promoted |
| SL-RC-03 | Remove the provisional feasible leader | Deterministic next selection or explicit NONE, not a stale leader |
| SL-RC-04 | Perturb one controlled R0..R6 dimension | Predicted complete-order change checked |
| SL-RC-05 | Preserve an ID but substitute a stale source range/call site | Source identity/reachability rejection |

## THE CAUSALITY CLASS

| ID | Adverse action | Required nonvacuous detector |
|---|---|---|
| SL-CC-01 | Mutate the selected C decision and rebuild the real compiler | Successful mutant build + the changed witness channel. The compiler build exit, the witness compile exit and the witness run exit MUST be recorded separately. |
| SL-CC-02 | Substitute a handwritten/PolyC-dependent G0 oracle | Production-object provenance rejection |
| SL-CC-03 | Corrupt one fixture expected output | Exact semantic row ID mismatch |
| SL-CC-04 | Put the comparison instructions in an unrelated function/object | Function-scoped authority detector rejects |
| SL-CC-05 | Mutate the compiled POLYC component (the POST-POLYC-MUTANT control) | Successful mutant build + the changed witness channel on the POST-MIGRATION subject |

**SL-CC-01 and SL-CC-05 MUST NOT BE THE SAME EXPERIMENT.** They have
different subjects (the C decision vs the compiled PolyC component)
and different phases. See `selected-causal-contract.md`.

## THE PROVENANCE CLASS

| ID | Adverse action | Required nonvacuous detector |
|---|---|---|
| SL-PV-01 | Relabel one producer compiler as another bootstrap binary | Actual binary identity/provenance rejection |

## THE BOUNDED MUTATION SET FOR THE SELECTED CANDIDATE

The successor MUST use a bounded, SOURCE-DERIVED mutation set that
covers every distinct decision outcome of the SUB-002 condition, and
MUST record, for each mutant, the exact fixture row that changed:

```text
m-compound  AST_COMPOUND_STMT  -> row 16, kind 274
m-case      AST_CASE           -> row 29, kind 287
m-break     AST_BREAK          -> row 22, kind 280
m-return    AST_RETURN         -> row 13, kind 270
m-goto      AST_GOTO           -> row  2, kind 258
```

Each mutant MUST change EXACTLY ONE fixture row and MUST be
classified as `UNOBSERVED`, `UNREACHABLE`, `DUPLICATED_AUTHORITY`,
`FAILED_COMPILER_BUILD` or `INELIGIBLE` -- never as an undocumented
exclusion.
