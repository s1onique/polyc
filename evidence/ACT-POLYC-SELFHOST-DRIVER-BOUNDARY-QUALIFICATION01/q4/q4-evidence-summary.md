# Q4 EVIDENCE SUMMARY

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`
**Phase:** Q4-CLOSE

## WHAT Q4 PRODUCES

| artifact | what it is |
|---|---|
| `terminality-plan.txt` | the PLAN for the external post-CLOSE probe |
| `q4-evidence-summary.md` | this file |

## THE TERMINALITY PLAN, NOT A PRE-COMMITTED SUCCESS

The canonical range validator enforces two rules that are in tension
with each other:

```text
rule 4  exactly ONE `ACT-Phase: CLOSE` in the range, and it is the
        LAST commit of the range
rule 6  NO commit descending from the CLOSE may carry `ACT:<id>`
```

A receipt that must be recorded **after** the close can therefore
neither carry the ACT id nor be recorded **before** the close without
making the close premature. This is the same root cause that
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04` identified and
resolved structurally.

**THE RESOLUTION IS STRUCTURAL:**

```text
THE CLOSE COMMITS ONLY THIS PLAN;
THE PROBE IS EXECUTED AFTER THE CLOSE;
THE RECEIPT LIVES OUTSIDE THE REPOSITORY AND IS NEVER BACKDATED;
THE OUTCOME IS REPORTED TO THE OPERATOR AND, WHEN CONVENIENT,
RECORDED IN THE ROADMAP BY AN ORDINARY COMMIT WITH NO ACT TRAILER.
```

An ordinary commit carries no ACT trailer, so rule 6 — which counts
only commits that carry `ACT:<id>` — is satisfied exactly.

## WHAT THE PLAN CONTAINS, AND WHAT IT MUST NOT

The plan names TWELVE numbered checks and their expected outcome
shape. It contains **no** PASS for the probe, because the probe has
not run.

It explicitly forbids the probe from:

- creating a commit, a branch, a tag or a stash;
- performing a network operation;
- modifying a tracked file;
- rewriting history;
- claiming that the **historical** terminality is CONFIRMED. The
  historical timing remains `UNPROVEN`: the tracked outcome was
  committed before the probe ran and its timestamp is not
  topology-backed.

Check 11 is the self-check on this ACT's own conduct: the tracked
terminality artifact must contain a PLAN and no pre-committed
post-close success.

Check 12 is the self-check on the ROADMAP: the audit's verdict must
be recorded **separately** from the historic `WP001_DRIVER_MIGRATION`
status.

## THE DISPOSITION

```text
AUDIT_VERDICT                       = PASS_FINDINGS_WITH_REMAINDER
WP001_BOUNDARY_CONFIRMED            = NO
WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER = 2
WP001_GLOBAL_C_SEMANTIC_REMAINDER        = 2
HISTORICAL_ACT_TERMINALITY_CONFIRMED = UNPROVEN
```

The audit machinery is sound; the audited claim does not hold. The
remainder is explicit and bounded.

## WHAT Q4 DOES NOT DO

- It does NOT run the external probe. The probe runs after the close.
- It does NOT record a probe outcome.
- It does NOT modify any production file.
- It does NOT rewrite the history it examined.
- It does NOT confer authority on any successor ACT.
