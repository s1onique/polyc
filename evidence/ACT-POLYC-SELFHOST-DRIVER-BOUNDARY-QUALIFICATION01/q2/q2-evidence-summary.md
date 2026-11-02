# Q2 EVIDENCE SUMMARY

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`
**Phase:** Q2-IMPL

## WHAT Q2 PRODUCES

| artifact | what it is |
|---|---|
| `tools/quality/driver-boundary-qualification01-verify.HC` | the COMPILED PolyC qualification verifier, ten modes |
| `audit-tool-build-and-selftest.tsv` | the build result and the ten primary modes on the pristine inputs |
| `detector-anti-selftests.tsv` | the 20 anti-selftests and the reason token each one fired |
| `independent-witness.tsv` | the INDEPENDENT POSIX/Git recomputation of every measured fact |
| `causal-execution-and-provenance.tsv` | the two discriminating counterfactuals, re-executed |
| `q2-convergence-table.tsv` | the PolyC verifier / independent witness comparison |
| `q1-header-restoration-record.md` | the forward-record of the Q1 header defect |
| `run-verifier.sh`, `run-antiselftests.sh`, `run-independent-witness.sh`, `run-causal-execution.sh` | the four executable evidence producers |

## THE COMPILED VERIFIER

The verifier is compiled by the **real production compiler** (`./hcc`),
not by a foreign toolchain:

```sh
./hcc --install-dir=$PWD/build/test-prefix -c \
      tools/quality/driver-boundary-qualification01-verify.HC \
      -o build/driver-boundary-qualification01-verify.o
```

Ten modes: `SELFTEST`, `IDENTITY`, `ROSTER`, `HISTCLASS`, `OWNERSHIP`,
`SCOPE`, `AUTHORITY`, `FAMILY`, `CHRONOLOGY`, `ACCEPT`, `M2CLASS`.

All ten are SILENT (exit 0) on the pristine measured inputs.

## THE 20 ANTI-SELFTESTS

Every anti-selftest mutates ONE cell of ONE row, or ONE field of ONE
keyed table, and then asserts that the verifier fires **its own reason
token** and exits non-zero.

```text
AS01_CORRUPTED_ROW_ID        -> DRIVER_ROSTER_ID_MISSING
AS02_DUPLICATE_ROW_ID        -> DRIVER_ROSTER_ID_DUPLICATE
AS03_WRONG_FUNCTION_RANGE    -> ENTRY_BRANCH_CAUSAL_UNPROVEN
AS04_STALE_OBJECT            -> UNREACHABILITY_NOT_PROVEN
AS05_MISSING_C_DECISION      -> DECISION_OWNER_NOT_TRACED
AS06_FALSIFIED_BRANCH_PROV   -> DECISION_OWNER_NOT_TRACED
AS07_BOGUS_ACTIVE_DECISION   -> DECISION_OWNER_NOT_TRACED
AS08_REWRITTEN_HIST_CLASS    -> HISTORICAL_CLASS_REWRITTEN
AS09_MISSING_ROW             -> DRIVER_ROSTER_ID_MISSING
AS10_WRONG_SCOPE             -> GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED
AS11_FORGED_RECEIPT_TIMING   -> PRECOMMITTED_RESULT_LAUNDERED
AS12_REPLAY_AS_ORIGINAL      -> REPLAY_PROVENANCE_CONFLATED
AS13_RECEIPT_NOT_MEASURED    -> RECEIPT_EXISTENCE_NOT_PROVEN
AS14_POST_CLOSE_SCAN_OMITTED -> POST_CLOSE_ID_CARRIER_OMITTED
AS15_FORGED_ENTRY_IDENTITY   -> ENTRY_IDENTITY_FORGED
AS16_AUTHORITY_UNIT_MISMATCH -> AUTHORITY_UNIT_MISMATCH
AS17_OMITTED_CORRECTION      -> ACT_FAMILY_COST_UNDERCOUNTED
AS18_FORGED_AC_SET           -> FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED
AS19_M2_OVERCLAIM            -> M2_BOOTSTRAP_MISCLASSIFIED
AS20_FALSE_GREEN_BASELINE    -> KNOWN_BASELINE_FALSE_GREEN
```

**20 of 20 fire, each with its EXACT expected token.** The reason
tokens are DISJOINT per mode, so a mutation that fires the wrong
token is a failure, not a near-miss.

## THE INDEPENDENT WITNESS

`run-independent-witness.sh` recomputes every measured fact with POSIX
shell, awk, sort, uniq, comm and git ONLY. The compiled PolyC
verifier is **not invoked** by it.

The two implementations share **no detection algorithm**:

```text
POLYC VERIFIER   load each table into a shared field store, scan
                 cells with an exact-string equality predicate
INDEPENDENT      sort whole lines, compare with the `comm` SET
                 ALGEBRA, count with `sort | uniq -c`
```

**36 of 36 independent checks MATCH the PolyC verifier's verdicts.**

## THE TWO DISCRIMINATING COUNTERFACTUALS

Both were RE-EXECUTED at Q2 against the real production build system
(the CMake tree in `build/`), not against an ad-hoc link:

| branch | mutation | observed |
|---|---|---|
| `BR_EMITFILE_EMIT_OBJECT` (`src/main.c:250`) | `if (args->emit_object)` -> `if (0 && args->emit_object)` | the artifact type CHANGES from a Mach-O 64-bit OBJECT to a Mach-O 64-bit EXECUTABLE |
| `BR_MAIN_PRINT_TOKENS` (`src/main.c:519`) | `if (args.print_tokens)` -> `if (0 && args.print_tokens)` | the token stream DISAPPEARS: 9 stdout lines -> 0 |

Both produce `C_SEMANTIC_RETAINED_WP001`.

The mutation is a compile-time disable of exactly one C branch. The
stage0 producer is held pristine so the mutation cannot break the
toolchain.

### THE RESTORATION IS PROVEN, NOT ASSERTED

```text
baseline_digest == restored_digest            YES (both branches)
rebuilt production binary == baseline binary  BYTE_IDENTICAL
production files modified                     0
```

The source is restored on **every** exit path, including a signal,
via a shell `trap`. The restored file is `touch`ed AND the mutated
object is deleted, so a stale mutated object can never survive the
restore: a timestamp-based build system would otherwise keep it.

### TWO DEFECTS THE SCRIPT CAUGHT IN ITSELF

Both were caught by the script's own guards, not by inspection:

1. **The baseline could itself be a mutant.** The first build left the
   mutated binary in the production `./hcc` slot, so the second
   branch's "baseline" was already mutated. The guard now compares
   the mutant binary's digest against the baseline's and reports
   `MUTANT_BINARY_IDENTICAL_TO_BASELINE`; the build now MOVES the
   binary out of the tree.

2. **A missing artifact is not a difference.** An earlier run reported
   `ARTIFACT_TYPE_CHANGED` when the mutant produced NO artifact at
   all. The verdict now requires BOTH sides to have produced an
   artifact; an absent artifact is reported as `ARTIFACT_MISSING` and
   is never counted as a discriminating observation.

## THE Q1 HEADER DEFECT

The Q1 evidence file was committed without its descriptive comment
block and without its column-header row. Its 32 DATA rows were never
affected. The defect is disclosed and corrected **forward** in the Q2
commit; the Q1 commit is not rewritten (F14, append-only). See
`q1-header-restoration-record.md`.

## WHAT Q2 DOES NOT ESTABLISH

- Q2 does **NOT** establish that PolyC owns the WP-001 boundary. The
  measured attribution points the other way for the two decisive
  branches. The final disposition belongs to Q3/Q4.
- Q2 does **NOT** establish that the historical terminality evidence
  is sound. `HISTORICAL_ACT_TERMINALITY_CONFIRMED` remains `UNPROVEN`
  and `FRESH_EXTERNAL_REPLAY` remains `NOT_RUN`.
- Q2 does **NOT** modify any production file.
