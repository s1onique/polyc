# ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02
ACT-Phase: RED

Inherits from: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01
(closed PASS at 38f909e; AC10 corrected by ...CORRECTION01 closed at
3a0f2a7).

**Class:** FACTORY / PROCESS / DOCUMENTATION / PRECEDENCE-SCOPE CORRECTION

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:**
`ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01`
(closed PASS at 38f909e).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

**Non-blocking:** YES. This ACT does NOT block execution of the
already-authorized C4 IMPL-B envelope in
`ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01` §9.6, which remains `READY`.

---

## Mission

Correct a precedence-scope defect in the predecessor ACT's
instruction-precedence table.

The predecessor ACT's Instruction precedence section froze:

```text
1. system / platform constraints
2. explicit current user instruction
3. ACT contract
4. AGENTS.md workflow defaults
5. agent priors
```

That table conflates two distinct kinds of "explicit current user
instruction":

- **User scope / authorization** (e.g. "open a new ACT", "forbid
  ARRAY semantics in this ACT", "narrow the allowed files"). This
  mutates the ACT contract itself.
- **User execution directive** (e.g. "START IMPL-B IMMEDIATELY",
  "stop and write the handoff"). This accelerates or decelerates
  execution of the phases that are *already* authorized by the ACT.

Placing both kinds at level 2 (above the ACT at level 3) implies
that a casual user message can override the ACT's
allowed / forbidden / scope sections, which would bypass F15
("never self-authorize scope expansion") and silently expand the
ACT's scope. That is broader than the defect being fixed (the
artificial-halt defect was about execution timing, not scope).

This correction ACT replaces the precedence table with one that
separates the two kinds of user instruction and places user
*scope* changes above the ACT while user *execution directives*
sit below the ACT.

---

## Why this is a bounded correction and not a HALT

- The convergence doctrine's *core* behaviour (the closed halt
  list, the non-halt list, `GO = EXECUTE_NOW`) is unchanged.
- The defect is in one short section of one document
  (`AGENTS.md`).
- The fix is local and surgical.
- F-CONVERGENCE itself is preserved verbatim; only the precedence
  table above it is amended.

Per F14 ("current truth may invalidate history"), the predecessor
ACT body is preserved unchanged; this correction ACT is the new
evidence.

---

## Scope

### allowed

- Editing only the `## Instruction precedence` section of
  `AGENTS.md` to replace the table and the surrounding paragraph.
- Adding this CORRECTION02 ACT document.
- Committing one IMPL commit with the AGENTS.md edit and the new
  ACT document, plus a CLOSE trailer commit.

### forbidden

- Modifying the `## Convergence principle` section.
- Modifying any F1..F15 rule body (F7, F12, F-CONVERGENCE, etc.).
- Modifying any production source, IR, LLVM backend, test, script,
  hook, Makefile, or package.json.
- Modifying any Factory doctrine document.
- Touching C4 IMPL-B scope in
  `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01`. That ACT's §9.6 envelope
  is READY and this correction ACT does not alter it.
- Carrying `ACT-Supersedes:` on any commit other than the CLOSE
  commit.

---

## Principal RED

```text
R-RED-1  AGENTS.md currently places "explicit current user
         instruction" at level 2 and the ACT contract at level 3,
         with no separation between user-scope and user-execution
         directives. (TRUE at entry.)

R-RED-2  A user message such as "while you're there, also change
         ARRAY semantics" could be read under R-RED-1 as overriding
         the active ACT's `FORBIDDEN` section, bypassing F15.
         (TRUE at entry by textual inspection.)

R-RED-3  The convergence doctrine's CORE (closed halt list, non-
         halt list, GO = EXECUTE_NOW, the do-not-override list) is
         NOT affected by this correction. (TRUE at entry and must
         remain TRUE after IMPL.)
```

The RED is GREEN only when R-RED-1 and R-RED-2 are both FALSE after
the IMPL commit, and R-RED-3 remains TRUE.

---

## Acceptance criteria

```text
AC01  AGENTS.md precedence table lists six levels, with user SCOPE
      at level 2 and user EXECUTION DIRECTIVE at level 4 (between
      ACT contract at level 3 and AGENTS workflow defaults at
      level 5).
      Command: grep -A8 '^## Instruction precedence' AGENTS.md | \
                  grep -q 'SCOPE / authorization' && \
                  grep -A8 '^## Instruction precedence' AGENTS.md | \
                  grep -q 'EXECUTION DIRECTIVE'

AC02  AGENTS.md contains the explicit user-scope / user-execution
      split paragraph.
      Command: grep -q 'User scope / authorization sits' AGENTS.md && \
               grep -q 'User execution directive within authorized scope sits' AGENTS.md

AC03  AGENTS.md contains the ARRAY-semantics scope-bypass worked
      example.
      Command: grep -q 'also change ARRAY semantics' AGENTS.md && \
               grep -q 'F15' AGENTS.md

AC04  F-CONVERGENCE core (closed halt list, non-halt list,
      GO = EXECUTE_NOW, do-not-override list of F1/F2/F3/F4/F5/F6/
      F15) is unchanged.
      Command: for s in 'Closed halt list' 'Non-halt list' \
                       'GO = EXECUTE_NOW' \
                       'F-CONVERGENCE does NOT override'; do \
                   grep -qF "$s" AGENTS.md || exit 1; done

AC05  No production-code file was modified across the CORRECTION02
      range.
      Command: git diff --numstat <predecessor-CORRECTION01-CLOSE>..HEAD -- \
                  src/ tests/ scripts/ .githooks/ .clinerules/ \
                  Makefile package.json
      Expected: empty

AC06  Only AGENTS.md and this CORRECTION02 ACT document were
      changed by the IMPL commit.
      Command: git diff --name-only <predecessor-CORRECTION01-CLOSE>..HEAD

AC07  All three commit-msg gates (RED, IMPL, CLOSE) pass.
      Expected:
        RED   : MODE=ACT PHASE=RED STATUS=PASS
        IMPL  : MODE=ACT PHASE=IMPL STATUS=PASS (no Supersedes)
        CLOSE : MODE=ACT PHASE=CLOSE VERDICT=PASS STATUS=PASS
                and ACT-Supersedes on this same commit

AC08  CORRECTION02 v2 range check: STATUS=PASS.
      Command: sh scripts/quality/factory-v2-range-check.sh \
                  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02 HEAD

AC09  The Track-A C4 IMPL-B envelope in
      ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 is NOT touched by the
      CORRECTION02 range.
      Command: git diff --numstat <predecessor-CORRECTION01-CLOSE>..HEAD -- \
                  docs/acts/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01.md
      Expected: empty

AC10  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 §9.6 envelope still
      reads "C4 IMPL-B AUTHORIZED" / "Implement C4." / "READY".
      Command: grep -q 'C4 IMPL-B' docs/acts/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01.md && \
               grep -q 'AUTHORIZED' docs/acts/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01.md && \
               grep -q 'Implement C4' docs/acts/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01.md
```

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED` — any AC0* cannot be reproduced.
- `HALT_SCOPE_EXPANSION_REQUIRED` — IMPL would require editing any
  file outside AGENTS.md's `## Instruction precedence` section, the
  Convergence principle section, this ACT document, or the ACT body
  AC lines for AC10 closure.
- `HALT_GIT_IDENTITY_LOST` — append-only invariants violated, or
  the v2 range check fails.

---

## Residue

```text
P2  A future FACTORY-LIFECYCLE-V2-CORRECTION02 ACT could add a
    short cross-reference from DOCTRINE.md and LLM-WORKFLOW.md
    pointing at the new precedence table. Out of scope here.

P2  An automated doctest could parse AGENTS.md and assert the
    six-level precedence table is present in the exact order
    documented in AC01. Out of scope.
```

---

## Commit topology

```text
1. RED   (empty commit; captures R-RED-* textual witnesses)
2. IMPL  (edits AGENTS.md precedence section; adds this ACT doc)
3. CLOSE (empty commit; records ACT-Verdict=PASS and the
         ACT-Supersedes linkage to the predecessor ACT)
```

Three commits total. Bounded. Non-blocking with respect to C4 IMPL-B.

---

## Execution metadata

```text
ACT:           ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02
ACT-Phase:     RED | IMPL | CLOSE
ACT-Verdict:   PASS | HALT_<...>   (CLOSE only)
ACT-Supersedes: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01
                                                       (CLOSE only)
```

`ACT-Supersedes` appears on the CLOSE commit only, per the v2
trailer grammar.

---

## Closure handoff

Factory v2 HANDOFF follows `docs/factory/HANDOFF-TEMPLATE.md`
(Factory v2 section).

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02 HEAD
```
