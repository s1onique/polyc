# ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION03
ACT-Phase: RED

Inherits from: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02
(closed PASS at 299e9b0).

**Class:** DOCUMENTATION / ACCEPTANCE-CRITERIA WORDING CORRECTION

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:**
`ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02`
(closed PASS at 299e9b0).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

**Non-blocking:** YES. C4 IMPL-B in ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01
remains READY.

---

## Mission

Correct two acceptance-criteria wording defects in the predecessor
ACT body. The implementation in `AGENTS.md` is correct; only the
test patterns need adjustment.

- **AC01**: the predecessor uses `grep -A8 '^## Instruction
  precedence' AGENTS.md` to inspect the precedence table, but
  the table sits 7..12 lines after the heading (after the prose
  intro). The correct window is `grep -A12`.
- **AC02**: the predecessor uses literal-text grep for
  `User scope / authorization sits` and `User execution directive
  within authorized scope sits`. The implementation wraps both
  phrases in Markdown bold markers (`**...**`). The corrected
  fixed-string form is `**User scope / authorization** sits` and
  `**User execution directive within authorized scope** sits`.

This correction ACT updates the AC01 and AC02 wording in the
predecessor ACT body. It does NOT modify `AGENTS.md`, any other
ACT or HANDOFF, or any production file.

---

## Scope

### allowed

- Editing only the AC01 and AC02 lines in the predecessor ACT
  body.
- Adding this CORRECTION03 ACT document.
- Committing one IMPL commit with the AC-line edits and the new
  ACT document, plus a CLOSE trailer commit.

### forbidden

- Modifying `AGENTS.md`.
- Modifying any production source, IR, LLVM backend, test, script,
  hook, Makefile, or package.json.
- Modifying any Factory doctrine document.
- Touching C4 IMPL-B scope.
- Carrying `ACT-Supersedes:` on any commit other than the CLOSE
  commit.

---

## Principal RED

```text
R-RED-1  Predecessor ACT body's AC01 grep uses -A8 but the table
         is on lines 7..12 of the matched block. (TRUE at entry.)

R-RED-2  Predecessor ACT body's AC02 grep uses literal-text forms
         that omit Markdown bold markers present in the
         implementation. (TRUE at entry.)

R-RED-3  Implementation in AGENTS.md is correct: six-level table,
         user SCOPE at L2, user EXECUTION DIRECTIVE at L4, bold-
         marked split paragraph. (TRUE at entry and remains TRUE
         after IMPL.)
```

RED is GREEN only when R-RED-1 and R-RED-2 are FALSE after IMPL,
and R-RED-3 remains TRUE.

---

## Acceptance criteria

```text
AC01  The corrected AC01 grep window (-A12) matches both SCOPE
      and EXECUTION DIRECTIVE in AGENTS.md.
      Command: grep -A12 '^## Instruction precedence' AGENTS.md | \
                  grep -q 'SCOPE / authorization' && \
                  grep -A12 '^## Instruction precedence' AGENTS.md | \
                  grep -q 'EXECUTION DIRECTIVE'

AC02  The corrected AC02 fixed-string greps match AGENTS.md.
      Command: grep -qF '**User scope / authorization** sits' AGENTS.md && \
               grep -qF '**User execution directive within authorized scope** sits' AGENTS.md

AC03  AGENTS.md unchanged across the CORRECTION03 range.
      Command: git diff --numstat <predecessor-CORRECTION02-CLOSE>..HEAD -- AGENTS.md
      Expected: empty

AC04  No production-code change across the CORRECTION03 range.
      Command: git diff --numstat <predecessor-CORRECTION02-CLOSE>..HEAD -- \
                  src/ tests/ scripts/ .githooks/ .clinerules/ \
                  Makefile package.json
      Expected: empty

AC05  Only the predecessor ACT body and this CORRECTION03 ACT
      document changed.
      Command: git diff --name-only <predecessor-CORRECTION02-CLOSE>..HEAD

AC06  RED, IMPL, CLOSE commit-msg gates all pass; ACT-Supersedes
      only on CLOSE.

AC07  CORRECTION03 v2 range check: STATUS=PASS.
      Command: sh scripts/quality/factory-v2-range-check.sh \
                  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION03 HEAD
```

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED`
- `HALT_SCOPE_EXPANSION_REQUIRED`
- `HALT_GIT_IDENTITY_LOST`

---

## Residue

```text
P2  A future ACT template could include a small Markdown-aware
    grep helper (strip ** and ` and other inline markers before
    matching). Out of scope here.
```

---

## Commit topology

```text
1. RED   (empty commit)
2. IMPL  (edits AC01/AC02 lines in predecessor ACT body; adds
         this ACT doc)
3. CLOSE (empty trailer commit; ACT-Verdict=PASS; ACT-Supersedes
         on the predecessor ACT)
```

Three commits. Bounded. Non-blocking.

---

## Execution metadata

```text
ACT:           ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION03
ACT-Phase:     RED | IMPL | CLOSE
ACT-Verdict:   PASS | HALT_<...>   (CLOSE only)
ACT-Supersedes: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION02
                                                       (CLOSE only)
```

---

## Closure handoff

Factory v2 HANDOFF follows `docs/factory/HANDOFF-TEMPLATE.md`
(Factory v2 section).

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01-CORRECTION03 HEAD
```
