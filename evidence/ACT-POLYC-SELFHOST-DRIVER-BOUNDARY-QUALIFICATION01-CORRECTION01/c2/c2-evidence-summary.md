# C2 — IMPL EVIDENCE SUMMARY

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01`
**PHASE:** C2 — IMPL

## The required outcomes

```text
VERIFIER_BUILDS = PASS
VERIFIER_SELFTESTS = PASS
INDEPENDENT_WITNESS = PASS

AC_PREDICATE_COMPARISON = EXECUTED
AC_WITNESS_BINDING = EXECUTED

BRANCH_ROUTE_QUALIFICATION = EXECUTED
DECISION_OWNER_QUALIFICATION = EXECUTED
```

## The compiled verifier

`tools/quality/driver-boundary-qualification01-correction01-verify.HC` is
compiled by the REAL production compiler (`./hcc`). It is distinct from
the predecessor's Q2 verifier, which is NOT modified.

| mode | exit | verdict |
|---|---|---|
| `BUILD` | 0 | PASS |
| `SELFTEST` | 0 | SILENT |
| `ACSET` | 0 | SILENT |
| `ACPHASE` | 0 | SILENT |
| `ACPREDICATE` | 0 | SILENT |
| `ACWITNESS` | 0 | SILENT |
| `ACCOUNTING` | 0 | SILENT |
| `ROUTES` | 0 | SILENT |
| `DECISION` | 0 | SILENT |
| `BASELINE` | 0 | SILENT |
| `CHRONOLOGY` | 0 | SILENT |

### The verifier FAILS CLOSED

Every mode checks that the columns it needs are PRESENT, and rejects a
table that lacks one. A mode that skipped a row it could not check
would be a mode that always passes. Three defects of this kind were
found and repaired during C2:

* `ACWITNESS` read the ledger's `cited_witness` and `frozen_phase`
  columns, which the ledger did not carry, and therefore skipped every
  row. It now consumes the 50-row witness binding table BY NAME.
* `ACPREDICATE` compared the ledger's `frozen_predicate` against a
  `ledger_claim` column that did not exist, and therefore compared
  nothing. It now compares the ledger against the frozen table against
  the immutable C0 contract.
* `ACWITNESS` read the existence table POSITIONALLY, so it
  reinterpreted the chronology column as the relevance column. It now
  addresses every column BY NAME.

### THE C0 CONTRACT IS THE ANCHOR

`ACPREDICATE` compares THREE tables, not two:

```text
the ledger predicate  ==  the frozen table predicate  ==  the C0 contract predicate
```

With only two tables, a predicate substituted on the ledger side and a
predicate rewritten in the frozen contract are indistinguishable. The
C0 contract is the immutable anchor that separates the two conditions,
and each condition produces its OWN reason token.

## The 18 negative controls

All 18 fire their OWN EXACT reason token, on a NONZERO exit. The
pristine run and the restored run are SILENT with exit 0.

```text
EXACT_TOKEN_MATCHED = 18
PRISTINE_SILENT_EXIT_0 = 18
RESTORED_SILENT_EXIT_0 = 18
MUTATION_ISOLATED = 18
```

## The independent POSIX/Git witness

The independent witness shares NO detection algorithm with the compiled
verifier. It recomputes from the Git object store.

| fact | independent value |
|---|---|
| `AC_IDENTITY` | frozen=50 ledger=50 missing=0 extra=0 duplicate=0 |
| `AC_PHASES` | drift_rows=5 ids: AC14 AC15 AC16 AC17 AC18 |
| `AC_PREDICATE_BINDING` | adjudications_bound=4 unbound=5 artifact_absent=0 |
| `BINDING_INVARIANT` | proven_rows=35 binding_ok=35 binding_hole=0 |
| `AC_COUNTS` | rows=PASS:49 FAIL:0 DEFERRED:1; summary=49/0/2; handoff=46/0/5 |
| `WITNESS_PATH_EXISTENCE` | cited_paths=50 absent_from_close_tree=2 |
| `WITNESS_CHRONOLOGY` | phase_differs=10 ids: AC14..AC18 AC19 AC39 AC40 AC41 AC45 |
| `BRANCH_ROUTE_SCOPES` | reachable=3 unreachable=14 unproven=0 |
| `BASELINE_STATUS` | not_remeasured_rows=6 known_failure_rows=1 |

The three count representations of the predecessor STILL DISAGREE, and
the independent witness reproduces that disagreement rather than
resolving it by fiat.

## The ownership qualification

| branch | required route | ownership |
|---|---|---|
| `BR_EMITFILE_EMIT_OBJECT` | PROVEN_REACHABLE | `C_SEMANTIC_OWNER_PROVEN` |
| `BR_MAIN_PRINT_TOKENS` | PROVEN_UNREACHABLE | `C_SEMANTIC_OWNER_PROVEN` |
| `BR_MAIN_COMPILE_TO_AST` | PROVEN_REACHABLE | `SHARED_DECISION_OR_INSUFFICIENT_SEPARATION` |
| `BR_POLYC_FIELD_FOR_ACTION` | — | `POLYC_SEMANTIC_OWNER_C_EXECUTOR` |

## The remainder crosswalk

The historical FUNCTION-level classification and the branch-level
classification are reported SEPARATELY and are NOT conflated.

```text
HISTORICAL_RETAINED_C_ROWS = 2                     (function level)
RETAINED_C_SEMANTIC_BRANCHES_PROVEN_GLOBAL = 2     (branch level)
RETAINED_C_SEMANTIC_BRANCHES_PROVEN_REQUIRED_ROUTE = 1
```

The historical count of two and the branch-level required-route count
of one COEXIST. The predecessor counted `main()` and `emitFile()` as
two retained-C rows on the required route; the branch-level
measurement shows that of the two C-semantic branches, only
`BR_EMITFILE_EMIT_OBJECT` is PROVEN_REACHABLE on the required route.
`BR_MAIN_PRINT_TOKENS` is a WHOLE-CLI-scope branch: it is reached by
the token route and not by the required route.

All 32 historical rows are crosswalked to the branches that discharge
them, or to NONE. The historical rows are preserved as recorded, and no
new measurement is substituted for a historical row.

## The detector capability matrix

The predecessor's Q0 detector and the correction detector are compared
by WHOLE-TOKEN presence in the detector SOURCE and by EXECUTION in the
predecessor's own Q3 matrix.

```text
Q0 roster:        24 rows, 24 supported by the Q0 source, 24 execution-proven
CORRECTION roster: 18 rows, 18 supported by the correction source, execution pending C3
```

The two rosters are DISJOINT BY DESIGN: the Q0 roster names the
PREDECESSOR defects and the correction roster names the CORRECTION
defects. A historical Q0 capability is NOT backdated by a correction.

## The artifacts

```text
c2/verifier-build-and-selftest.tsv     the build and the ten modes
c2/negative-control-execution.tsv      the eighteen controls
c2/negative-control-inputs/             the eighteen mutated inputs
c2/detector-capability-matrix.tsv      the Q0/correction capability comparison
c2/independent-witness.tsv              the independent POSIX/Git facts
c2/ownership-remainder-crosswalk.tsv    the counts and the 32-row crosswalk
c2/inputs/                             the measured inputs the verifier reads
```
