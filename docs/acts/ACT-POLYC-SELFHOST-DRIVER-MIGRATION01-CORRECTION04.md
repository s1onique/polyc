# `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04`

**Title:** Establish a TERMINALLY-SOUND Factory-v2 phase path for the
WP-001 driver migration, in which the ACT id appears on EXACTLY the
phase commits and on NOTHING after the terminal close.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** GOVERNANCE / GIT-METADATA / CORRECTION

**Predecessor:** `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01` and its
corrections `CORRECTION01`, `CORRECTION02`, `CORRECTION03`

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN**.

**Re-mutation of committed evidence directories:** **FORBIDDEN**
(F14).

---

## 0. Mission

```text
the_prior_paths_are_terminally_sound = NO
the_prior_defects_are_irreparable     = YES
a_terminally_sound_path_exists        = YES
```

and only that.

---

## 1. Why this ACT exists

Three independent defects have now been found in this ACT family,
and all three have the SAME root cause.

### 1.1 The trailer defect (CORRECTION02)

The parent ACT's C1, C2 and C3 commits put the ACT identity in the
SUBJECT line only. That is not a git trailer block, so the canonical
commit-message validator classified them as `MODE=NON_ACT` and the
range validator's backwards walk stopped at C0.

### 1.2 The duplicate-C4 defect (CORRECTION03)

The parent's committed path carries SEVEN commits under its ACT
identity, THREE labelled `C4`, and TWO carrying `ACT-Phase: CLOSE`.
The cause was a premature intermediate close: the external
terminality receipt may only be produced AFTER the close, but it then
had to be recorded in a further commit, and the terminal close had to
follow it. Both further commits re-used the `C4` label.

### 1.3 The SAME defect, reproduced inside CORRECTION03 itself

CORRECTION03 committed its own terminal close, then recorded the
re-executed receipt's outcome in a further commit, then committed a
further close. The result is that CORRECTION03's path carries SEVEN
commits and TWO `ACT-Phase: CLOSE` commits, and the canonical range
validator reports:

```text
REASON=expected exactly 1 CLOSE commit in range, found 2
```

and, for the earlier close, rule 6:

```text
commit <sha> after CLOSE still carries ACT: <id>;
ACT must not continue past CLOSE
```

THE AGENT REPRODUCED THE VERY DEFECT IT WAS CORRECTING. That is
recorded here plainly.

### 1.4 THE ROOT CAUSE, STATED ONCE

The Factory-v2 range validator enforces two rules that pull in
opposite directions when a receipt must follow a close:

```text
rule 4  exactly ONE ACT-Phase: CLOSE exists in FIRST..CLOSE, and it
        is the LAST commit of the range;
rule 6  NO commit that DESCENDS FROM the CLOSE may carry ACT:<id>.
```

A receipt that must be recorded AFTER the close therefore cannot be
recorded with the ACT id, and cannot be recorded before the close
without making the close premature. THE RESOLUTION IS STRUCTURAL,
NOT PROCEDURAL:

```text
THE ACT'S OWN PATH ENDS AT ITS TERMINAL CLOSE.
THE CLOSE IS THE LAST COMMIT THAT CARRIES THE ACT ID.
EVERYTHING AFTER IT -- the receipt outcome, the ROADMAP note -- is an
ORDINARY COMMIT WITH NO ACT TRAILER AT ALL.
```

THIS ACT IS BUILT TO THAT SHAPE FROM THE START. Its own commits are
the phase commits and its terminal close, and NOTHING after it
carries its ACT id.

---

## 2. Scope

### allowed

- `docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04.md`
- `evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04/**`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04.md`
- `docs/factory/act-handoff-map.tsv` (one appended row)
- `docs/ROADMAP.md`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03.md`

### forbidden

- Any modification of ANY production file: `src/**`, `tools/**`.
- Any modification of the canonical gates, scripts or tests.
- Any modification of ANY committed evidence directory.
- Any amendment, rebase, replay or history rewrite of ANY commit.
- Any commit AFTER this ACT's terminal close that carries this ACT's
  ACT id.

---

## 3. The correction

### 3.1 The disclosure

This ACT's handoff and the ROADMAP MUST state, plainly:

- the parent ACT's path carries SEVEN commits, THREE `C4` labels and
  TWO terminal CLOSEs;
- `CORRECTION02`, `CORRECTION03` and `CORRECTION04` each carry the
  ACT id on commits that follow their own terminal close, and each
  therefore has TWO CLOSEs in its range;
- all of these are IRREPARABLE under the append-only invariant;
- the root cause is the rule 4 / rule 6 tension described in 1.4.

### 3.2 The terminally sound path

THIS ACT's path is:

```text
S0 RED        the three defects and the root cause, measured
S1 EVIDENCE   the structural rule, derived from the canonical validator
S2 IMPL       the parent's acceptance ledger discharge and the handoff
S3 EVIDENCE   the conservation measurement and the gate results
S4 CLOSE      the single terminal close
```

Every commit carries a complete git-parseable trailer block. The
terminal close is the LAST commit carrying this ACT's id. NO commit
after it carries this ACT's id.

### 3.3 The receipt

The external read-only terminality probe is executed AFTER the
terminal close, as it must be. Its receipt lives OUTSIDE the
repository and is never backdated. Its OUTCOME is reported to the
operator and, when convenient, recorded in the ROADMAP by an
ORDINARY commit with NO ACT trailer -- which satisfies rule 6
exactly, because rule 6 only counts commits that carry `ACT:<id>`.

### 3.4 What this ACT does NOT claim

- It does NOT claim the parent's path was valid.
- It does NOT claim CORRECTION02's, CORRECTION03's or its OWN
  predecessor path was valid.
- It does NOT change any compiler behaviour.
- It does NOT hide the reproduced defect.

---

## 4. Exit gate

This ACT closes when, MEASURED BY EXECUTION:

1. the canonical commit-message validator reports `MODE=ACT` and
   `STATUS=PASS` for every commit of this ACT;
2. the canonical range validator reports `STATUS=PASS` for this
   ACT's own range, with `COMMITS` equal to the number of this ACT's
   phase commits and exactly one CLOSE;
3. no commit descending from this ACT's terminal close carries this
   ACT's ACT id;
4. the external read-only terminality probe is executed after this
   ACT's terminal close and reports `PROBE_RESULT=PASS`;
5. the parent's production delta is byte-identical;
6. no committed evidence file was modified.
