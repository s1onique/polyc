# ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION01
ACT-Phase: RED

Inherits from: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01
(closed PASS at 38f909e).

**Class:** DOCUMENTATION / ACCEPTANCE-CRITERIA CORRECTION

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:**
`ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01`
(closed PASS at 38f909e).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

---

## Mission

Correct a single self-test defect in the predecessor ACT's
acceptance-criteria block (AC10) without altering any other ACT,
`AGENTS.md`, or production file.

The predecessor ACT's AC10 specifies the textual witness

```text
"AGENTS.md says commits should be truthful"
```

as one of the four phrases that the non-halt list in `AGENTS.md`
MUST contain. The actual implementation in `AGENTS.md` writes that
phrase as

```text
"`AGENTS.md` says commits should be truthful"
```

— i.e. wrapping the filename in Markdown backticks, which is the
idiomatic inline-code form used throughout the same document.

The implementation is correct. The acceptance-criteria pattern is
under-specified: a literal-text grep for the un-backticked form
does not match the backticked form even though the meaning is
identical.

This correction ACT replaces the AC10 specification in the
predecessor ACT body with one that matches the actual
implementation (a literal grep using backticks) and adds an
explicit note recording that the original un-backticked form was
the under-specified witness, not an unrelated text.

---

## Why this is a bounded correction and not a HALT

- The AGENTS.md amendment is correct on its merits.
- AC01..AC09, AC11..AC15 textual gates all PASS against the
  committed `AGENTS.md` as shown in the predecessor CLOSE commit
  at 38f909e.
- AC10's *implementation* matches the *intent* (the non-halt list
  contains the exact phrase the ACT meant to require, modulo
  Markdown backticks).
- AC10's *test spec* in the predecessor ACT body was loose.

Per F14 ("current truth may invalidate history"), the predecessor
ACT is preserved; this correction ACT is the new evidence.

---

## Scope

### allowed

- Editing only the predecessor ACT body, specifically: the AC10
  textual-witness line that names the four non-halt phrases, and
  the AC10 grep command block, and the addition of a one-paragraph
  explanatory note immediately after the AC10 command block.
- Adding this CORRECTION01 ACT document.
- Committing one IMPL commit that performs the AC10 edit and adds
  this ACT document.

### forbidden

- Modifying `AGENTS.md` in any way.
- Modifying any other ACT or HANDOFF.
- Modifying any production source, IR, LLVM backend, test, script,
  hook, Makefile, or package.json.
- Modifying any Factory doctrine or workflow document
  (`docs/factory/DOCTRINE.md`, `LLM-WORKFLOW.md`, `GIT-METADATA.md`,
  `ACT-TEMPLATE.md`, `HANDOFF-TEMPLATE.md`).
- Introducing new tooling or dependencies.
- Carrying `ACT-Supersedes:` on any commit other than the CLOSE
  commit (per the v2 trailer grammar).

---

## Principal RED

The principal RED is the textual-witness test for the corrected
AC10 grep pattern against the committed AGENTS.md:

```text
R-RED-1  AGENTS.md non-halt list currently contains the phrase
         "`AGENTS.md` says commits should be truthful" with
         Markdown backticks. (TRUE at entry.)

R-RED-2  The predecessor ACT body's AC10 grep pattern does NOT
         use backticks; an exact-match grep against AGENTS.md
         therefore misses the canonical phrase. (TRUE at entry.)

R-RED-3  The corrected AC10 grep pattern (with backticks) DOES
         match AGENTS.md. (FALSE at entry; becomes TRUE after
         the IMPL commit updates the predecessor ACT body.)

R-RED-4  The un-corrected AC10 grep pattern (no backticks) still
         does NOT match AGENTS.md. (TRUE at entry; remains TRUE
         after IMPL; this is preserved as evidence the original
         was loose, not redundant.)
```

The RED is GREEN only when, after the IMPL commit, R-RED-3 and
R-RED-4 both hold.

---

## Acceptance criteria

```text
AC01  The corrected AC10 grep pattern (with backticks) is present
      in the predecessor ACT body.
      Command: grep -qF '`AGENTS.md` says commits should be truthful' \
                  docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01.md

AC02  The corrected AC10 grep pattern matches AGENTS.md.
      Command: grep -qF '`AGENTS.md` says commits should be truthful' \
                  AGENTS.md

AC03  The un-corrected AC10 grep pattern (no backticks) still does
      NOT match AGENTS.md, proving the original was loose not
      redundant.
      Command: if grep -qF '"AGENTS.md" says commits should be truthful' \
                  AGENTS.md; then exit 1; else exit 0; fi

AC04  AGENTS.md is unchanged across the CORRECTION01 range.
      Command: git diff --numstat <predecessor-CLOSE>..HEAD -- AGENTS.md
      Expected: empty output

AC05  No production-code file is changed across the CORRECTION01
      range.
      Command: git diff --numstat <predecessor-CLOSE>..HEAD -- \
                  src/ tests/ scripts/ .githooks/ .clinerules/ \
                  Makefile package.json
      Expected: empty output

AC06  The only files changed by the IMPL commit are:
      - docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01.md
        (predecessor AC10 edit)
      - docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION01.md
        (this ACT document)
      Command: git diff --name-only <predecessor-CLOSE>..HEAD

AC07  All three commit-msg gates (RED, IMPL, CLOSE) pass.
      Each trailer grammar check uses
      scripts/quality/factory-v2-commit-msg-check.sh.
      Expected:
        RED   : MODE=ACT PHASE=RED STATUS=PASS
        IMPL  : MODE=ACT PHASE=IMPL STATUS=PASS (no Supersedes)
        CLOSE : MODE=ACT PHASE=CLOSE VERDICT=PASS STATUS=PASS
                and ACT-Supersedes on this same commit

AC08  The CORRECTION01 range passes the v2 range check.
      Command: sh scripts/quality/factory-v2-range-check.sh \
                  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION01 HEAD
      Expected: STATUS=PASS
```

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED` — any AC0* cannot be reproduced.
- `HALT_SCOPE_EXPANSION_REQUIRED` — IMPL would require editing
  any file outside the predecessor ACT body and this CORRECTION01
  ACT document.
- `HALT_GIT_IDENTITY_LOST` — append-only invariants violated, or
  the v2 range check fails.

---

## Residue

```text
P2  The same backticks-vs-no-backticks hazard exists in AC10's
    other three phrases. They currently match because they do
    not contain a filename. No correction needed; flagging only.

P2  A future ACT template could add a Markdown-aware grep helper
    (strip backticks before pattern match) to make acceptance-
    criteria patterns less fragile. Out of scope here.
```

---

## Commit topology

```text
1. RED   (empty commit; captures the R-RED-* textual witnesses)
2. IMPL  (edits the predecessor ACT body's AC10 line; adds this
         CORRECTION01 ACT document; no ACT-Supersedes trailer)
3. CLOSE (empty commit; records ACT-Verdict=PASS and the
         ACT-Supersedes linkage to the predecessor)
```

Three commits total. Bounded.

---

## Execution metadata

```text
ACT:           ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION01
ACT-Phase:     RED | IMPL | CLOSE
ACT-Verdict:   PASS | HALT_<...>   (CLOSE only)
ACT-Supersedes: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01   (CLOSE only)
```

`ACT-Supersedes` appears on the CLOSE commit only, per the v2
trailer grammar enforced by
`scripts/quality/factory-v2-commit-msg-check.sh`. The IMPL commit
does NOT carry it.

---

## Closure handoff

Factory v2 HANDOFF follows `docs/factory/HANDOFF-TEMPLATE.md`
(Factory v2 section).

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION01 HEAD
```
