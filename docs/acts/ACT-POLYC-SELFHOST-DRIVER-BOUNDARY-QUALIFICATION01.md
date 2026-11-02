# `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`

**Title:** Qualify whether PolyC owns the WP-001 compiler-driver
boundary, and independently verify the historical terminality evidence,
WITHOUT modifying production code and WITHOUT crediting new authority.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** AUDIT / QUALIFICATION / EVIDENCE

**Predecessor:** `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01` and its
corrections `CORRECTION01`..`CORRECTION04`

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN**.

**Re-mutation of committed evidence directories:** **FORBIDDEN**
(F14).

---

## 0. Mission

```text
does_polyc_own_the_wp001_driver_boundary     = TO_BE_MEASURED
is_the_historical_terminality_evidence_sound = TO_BE_MEASURED
```

and only that. The audit may conclude that PolyC does **NOT** own the
boundary. An audit that can only say "yes" is not an audit.

---

## 1. Why this ACT exists

The WP-001 driver-migration ACT family CLOSED with a positive
terminality receipt, and the ROADMAP records
`WP001_DRIVER_MIGRATION = ACHIEVED`. Two things were never
independently qualified:

1. **THE BOUNDARY.** The migration claims the PolyC-authored driver
   took over the compiler-driver role. The claim was never qualified
   at BRANCH granularity: it was not established which component
   selects the *behaviour* at each decision point, as opposed to which
   component owns the *function*.

2. **THE TERMINALITY EVIDENCE.** The receipt binds to a path whose
   shape was itself produced by a correction ACT that disclosed a
   duplicate-close defect in its own predecessor. Whether the
   historical terminality claim is sound, and whether the tracked
   outcome file was pre-committed, was not independently examined.

This ACT is a QUALIFICATION ACT. It produces evidence and a verdict.
It produces **no production change**.

---

## 2. Scope

### allowed

- `docs/acts/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md`
- `evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/**`
- `tools/quality/driver-boundary-qualification01-red.HC`
- `tools/quality/driver-boundary-qualification01-verify.HC`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md`
- `docs/factory/act-handoff-map.tsv` (one appended row)
- `docs/ROADMAP.md`

### forbidden

- Any modification of ANY production file: `src/**`.
- Any modification of the canonical gates, scripts or tests.
- Any amendment, rebase, replay or history rewrite of ANY commit.
- Any commit AFTER this ACT's terminal close that carries this ACT's
  ACT id.
- Any claim that this ACT confers new authority. It qualifies; it does
  not authorise.
- Any conversion of a historical non-green, an `UNPROVEN` or a
  `NOT_REMEASURED` into a PASS.

---

## 3. The measurement contract

### 3.1 The decision-owner axis

A row is classified by **DECISION OWNER**, not by function ownership
and not by whether a source file was touched. A function may contain
both mechanical operations and independent policy, so the
classification is made at BRANCH granularity.

The five classes, their definitions and their required proofs are
frozen in
`evidence/.../q1/branch-and-decision-contract.tsv`.

### 3.2 The two axes that must not be collapsed

```text
FUNCTION-LEVEL OWNER  which component owns the function
DECISION-LEVEL OWNER  which component owns the BEHAVIOUR SELECTED
                      at the branch
```

A function can be function-level C and decision-level C, or
function-level C and decision-level PolyC, or it can read a
PolyC-produced value and ADD its own policy — which is
`C_SEMANTIC_RETAINED_WP001`, NOT `POLYC_OWNED_DECISION_PROVEN`.

### 3.3 The route-scope axis

```text
WP001_REQUIRED_ROUTE  the frozen route: --install-dir=X -c in.HC -o out.o
WHOLE_CLI_SURFACE    every route the CLI can take
```

A live but OFF-ROUTE C semantic choice is reported in the GLOBAL
count and is NOT folded into the route-scoped count. The global count
is never asserted to be zero without its own evidence.

---

## 4. The phase path

```text
Q0 RED        the audit inputs are FROZEN and the FIVE executable
              REDs fire against a COMPILED PolyC detector, with an
              INDEPENDENT POSIX witness
Q1 EVIDENCE   the ownership contract is frozen and the 32-row
              attribution is measured, with TWO LINKED COUNTERFACTUALS
Q2 IMPL       the compiled PolyC verifier exists, its anti-selftests
              fire, and an INDEPENDENT POSIX/Git witness agrees
Q3 EVIDENCE   the gates, the NC01..NC24 controls, the baselines and
              the acceptance ledger are discharged
Q4 CLOSE      the terminality PLAN is committed and the single
              terminal close is made
```

Every commit carries a complete git-parseable trailer block. The
terminal close is the LAST commit carrying this ACT's id. NO commit
after it carries this ACT's id.

---

## 5. The Q4 terminality plan (AC49)

The external read-only terminality probe MUST be executed **AFTER**
this ACT's terminal close, because a probe executed before the close
cannot attest to the close.

The rule-4 / rule-6 tension identified by
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04` applies here
too. Therefore:

```text
THE CLOSE COMMIT carries ONLY the terminality PLAN.
THE PROBE is executed after the close.
THE RECEIPT lives OUTSIDE the repository and is never backdated.
THE OUTCOME is reported to the operator and, when convenient,
recorded in the ROADMAP by an ORDINARY commit with NO ACT trailer.
```

This ACT's close therefore commits a **PLAN**, never a
pre-committed post-CLOSE success. The tracked outcome of this ACT
MUST NOT contain a PASS for an event that has not happened yet.

---

## 6. The three terminality claims, kept distinct

```text
HISTORICAL_TRACKED_OUTCOME_PROVENANCE  PRECOMMITTED_PROSPECTIVE_RESULT
ORIGINAL_EXTERNAL_RECEIPT              VERIFIED
FRESH_EXTERNAL_REPLAY                  NOT_RUN
HISTORICAL_ACT_TERMINALITY_CONFIRMED   UNPROVEN
```

The historical tracked outcome was committed BEFORE the probe ran. It
is therefore a **prospective result that was pre-committed**, not an
observation. The original receipt exists and binds to the correction's
terminal state, but its TIMESTAMP is not topology-backed. Historical
execution timing is NOT provable from the current evidence and
remains `UNPROVEN`.

---

## 7. Exit gate

This ACT closes when, MEASURED BY EXECUTION:

1. the compiled PolyC verifier builds and executes with the actual
   subject compiler, and all of its primary modes pass on the
   measured inputs;
2. the 20 anti-selftests each fire their OWN reason token and exit
   non-zero, and the verifier is SILENT on the pristine inputs;
3. the independent POSIX/Git witness agrees with the PolyC verifier on
   every measured fact, sharing no detection algorithm;
4. the 32-row join has 0 missing, 0 duplicate and 0 extra IDs;
5. every `main` and `emitFile` decision is either classified with a
   concrete witness or explicitly `UNPROVEN`;
6. the route-scoped and global C semantic remainders are counted
   SEPARATELY and neither is asserted to be zero without its own
   evidence;
7. the five-ACT WP-001 cost is independently recomputed from the
   actual commits;
8. NC01..NC24 execute pristine/adverse/restored with a specific
   reason each;
9. `gate-fast` and the serialised `gate-push` pass, and the Factory,
   F14 and append-only checks are clean;
10. exactly ONE terminal close exists, carrying a complete trailer
    block, and NO commit after it carries this ACT's ACT id;
11. the close carries the terminality PLAN and NO pre-committed
    post-close success;
12. the external read-only probe is executed after the close and its
    receipt binds to the exact close HEAD/TREE.

---

## 8. What this ACT does NOT claim

- It does NOT claim PolyC owns the WP-001 driver boundary unless the
  branch-level measurement supports it.
- It does NOT claim the historical terminality evidence is sound. It
  measures whether it is.
- It does NOT change any compiler behaviour.
- It does NOT confer authority on any successor ACT.
- It does NOT rewrite the history it examines. Where it finds a
  defect, it DISCLOSES it forward.
