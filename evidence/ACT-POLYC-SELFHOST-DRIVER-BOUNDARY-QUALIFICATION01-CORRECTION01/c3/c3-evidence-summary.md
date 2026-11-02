# C3 — EVIDENCE / GATES SUMMARY

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01`
**PHASE:** C3 — EVIDENCE / GATES

## The required outcomes

```text
NEGATIVE_CONTROLS = 18/18
INDEPENDENT_FACT_RECOMPUTATION = ALL_AGREE
PRODUCTION_SEMANTICS_CHANGED = NO
HISTORICAL_EVIDENCE_MODIFIED = NO
```

## The negative-control matrix

All 18 controls fire their OWN EXACT reason token on a NONZERO exit.
The pristine run and the restored run are SILENT with exit 0, and the
mutated copy is isolated from the pristine input.

```text
EXACT_TOKEN_MATCHED = 18
PRISTINE_SILENT_EXIT_0 = 18
RESTORED_SILENT_EXIT_0 = 18
MUTATION_ISOLATED = 18
```

## The independent recomputation

The compiled verifier and the independent POSIX/Git witness are
compared fact by fact. They share NO detection algorithm. Every fact
that both measure AGREES.

```text
DISAGREEMENTS = 0
INDEPENDENT_FACT_RECOMPUTATION = ALL_AGREE
```

## The conservation

Every production and historical path set is compared against the
PREDECESSOR CLOSE.

| subject | path set | differing paths | result |
|---|---|---|---|
| PRODUCTION_SOURCE | `src` | 0 | UNCHANGED |
| PRODUCTION_SOURCE | `tools/bootstrap` | 0 | UNCHANGED |
| PRODUCTION_BINARY | `hcc` | sha256 `c59254bf…d4b7fb41` | UNCHANGED |
| HISTORICAL_EVIDENCE | the predecessor evidence tree | 0 | UNCHANGED |
| HISTORICAL_EVIDENCE | the predecessor handoff | 0 | UNCHANGED |
| HISTORICAL_ACT_DOCUMENT | the predecessor closed ACT document | 0 | UNCHANGED |
| HISTORICAL_CLOSE_ANCESTRY | the predecessor close | YES | PASS |
| HISTORICAL_POST_CLOSE_OUTCOME | the predecessor post-close commit | YES | PASS |

## The gates

Every gate RAN against the EXACT subject commit.

| gate | command | measured | result |
|---|---|---|---|
| `GATE_FAST` | `scripts/quality/gate-fast.sh` | 5 checks, rc=0 | PASS |
| `GATE_PUSH` | `scripts/quality/gate-push.sh HEAD` | rc=0 | PASS |
| `APPEND_ONLY` | `scripts/quality/factory-append-only-test.sh` | 11 cases, rc=0 | PASS |
| `COMMIT_MSG_VALIDATOR` | `scripts/quality/factory-v2-commit-msg-check.sh` | 3 commits, 0 invalid | PASS |
| `FACTORY_V2_RANGE_PREDECESSOR` | `scripts/quality/factory-v2-range-check.sh` | rc=0 | PASS |
| `FACTORY_V2_TEST` | `scripts/quality/factory-v2-test.sh` | rc=0 | PASS |
| `F_NO_PYTHON` | `build/factory-no-python-check <git ls-files -z>` | rc=1, 12 violations | **FAIL** |
| `F_NO_PYTHON_DISPOSITION` | the violation set against the predecessor close | 12 pre-existing, 0 introduced | NO_NEW_VIOLATIONS |
| `REPLACE_REFS` | `git replace -l` | 0 | PASS |
| `ACT_WORKTREES` | `git worktree list` | 0 | 0_ACT_WORKTREES |
| `FACTORY_CLOSURE_STATUS` | `scripts/quality/factory-closure-status-check.sh` | rc=0 | PASS |

```text
GATE_FAILURES = 1
GATE_FAILURES_INTRODUCED_BY_THIS_CORRECTION = 0
GATE_STATUS = PASS_WITH_DISCLOSED_PRE_EXISTING_FAILURE
HALT_REQUIRED_GATE_FAILED = NO
```

## THE DISCLOSED PRE-EXISTING FAILURE

`F_NO_PYTHON` is NON-GREEN. It is **NOT** converted into a PASS.

Its twelve violations are ALL present at the predecessor close
`edfc3b16` and NONE of them is touched by this correction. The exact
identity of each is recorded in `c3/no-python-disposition.tsv`:

```text
PRE_EXISTING_AT_PREDECESSOR_CLOSE  scripts/quality/llvm-byte-memory01-test.sh
PRE_EXISTING_AT_PREDECESSOR_CLOSE  scripts/quality/llvm-cap-table-verifier.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  scripts/quality/llvm-intops01-test.sh
PRE_EXISTING_AT_PREDECESSOR_CLOSE  scripts/quality/llvm-memory01-red-test.sh
PRE_EXISTING_AT_PREDECESSOR_CLOSE  scripts/quality/llvm-spike-test.sh
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/bootstrap02-corpus-runner.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/bootstrap02-error-corpus.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/bootstrap03-corpus-runner.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/bootstrap03-error-corpus.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/bootstrap04-corpus-runner.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/bootstrap04-error-corpus.py
PRE_EXISTING_AT_PREDECESSOR_CLOSE  tools/quality/llvm-gep01-test.HC
```

The `F_NO_PYTHON` checker is not yet wired into `gate-fast`, so this
gate is invoked EXPLICITLY here. Its non-green state is a residue of
the repository, not of this correction.

## The artifacts

```text
c3/gate-results.tsv                  the gate measurements
c3/conservation.tsv                  the production and historical conservation
c3/independent-recomputation.tsv     the fact-by-fact comparison
c3/no-python-disposition.tsv         the exact identity of every violation
```
