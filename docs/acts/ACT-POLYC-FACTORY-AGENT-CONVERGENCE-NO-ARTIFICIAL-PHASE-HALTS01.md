# ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01
ACT-Phase: RED

**Title:** Eliminate artificial phase / commit -> turn-boundary halts in `AGENTS.md`

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** FACTORY / PROCESS / DOCUMENTATION

**Predecessor:** `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` (the
v2 ACT/HANDOFF mechanics are now canonical, so this ACT can use
trailers and an additive amendment to `AGENTS.md` without re-litigating
lifecycle).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

---

## Mission

Fix the agent-over-conservatism failure mode where `AGENTS.md`'s
phase / commit discipline (F7 scope conservation, F12 small truthful
commits) is misread by LLM agents as "one phase per user turn" or
"stop after every evidence commit", and where explicit
`GO` / `READY` / `UNBLOCKED` verdicts are misread as "tell the user
somebody may execute later" instead of `EXECUTE_NOW`.

The fix is additive and bounded:

1. Add an **Instruction precedence** section to `AGENTS.md` that
   makes explicit-user-instruction priority over `AGENTS.md`
   workflow defaults unambiguous.
2. Add a **Convergence principle** section that defines phase,
   commit, and turn boundaries as three distinct things.
3. Amend F7 and F12 so they explicitly cannot be read as turn-boundary
   rules.
4. Add a new operational law **F-CONVERGENCE — Continue until a real
   halt** with a closed halt list and an explicit non-halt list.
5. Define **`GO = EXECUTE_NOW`** semantics for verdicts such as
   `GO`, `READY`, `UNBLOCKED`, `EXECUTE`.

The amendment is intentionally small. It does not relax F1, F2, F3,
F4, F5, F6, F10, F15, or any other content-discipline rule. It only
clarifies the *temporal ordering* of authorized phases.

---

## Why

A reviewer observed an agent executing an authorized PolyC envelope
that concluded:

```text
C4 envelope closed
        |
agent stopped and waited for the next user turn
        |
user said "START IMPL-B IMMEDIATELY"
```

The envelope itself stated `C4 IMPL-B = GO`. The user instruction was
explicit. The agent's only justification for stopping was a
conservative reading of `AGENTS.md` workflow guidance — particularly
F7 (scope conservation) and F12 (small truthful commits) — that
treated the EVIDENCE commit boundary as a mandatory conversation-stop.

This reading is incorrect, and it is now made impossible to read that
way. The next agent encountering the same shape MUST continue from
the EVIDENCE commit into the authorized IMPL phase in the same
execution session and MUST halt at the next real halt (in the
observed scenario: the locked next envelope `C5 ScanIdent`), not at
the EVIDENCE/IMPL transition.

The defect has two components:

- **Agent interpretation defect:** the agent elevated an `AGENTS.md`
  workflow default above an explicit user instruction. Precedence
  rules bind that mistake.
- **`AGENTS.md` design defect:** the wording made the conservative
  reading plausible. The amendment binds that mistake.

Fixing only one of the two would leave the same failure reproducible
by the next model.


---

## Scope

### allowed

- Adding new sections to `AGENTS.md`:
  `## Instruction precedence`,
  `## Convergence principle`.
- Amending the bodies of F7 and F12 in `AGENTS.md`.
- Adding a new `### F-CONVERGENCE — Continue until a real halt`
  section to `AGENTS.md`, including the closed halt list, the
  non-halt list, and the `GO = EXECUTE_NOW` semantic.
- Adding the new canonical HALT token `HALT_ARTIFICIAL_PHASE_BOUNDARY`
  to the halt taxonomy (declared in this ACT, no other ACT needs to
  change).
- Creating this ACT document itself.

### forbidden

- Changing any production compiler, IR, or LLVM backend code.
- Changing any existing F1..F15 rule's *content discipline* (only
  F7 and F12 receive clarification of what they do *not* mean).
- Relaxing F2 (real seam recon), F3 (RED before production fix),
  F4 (HALT as a successful outcome), F5 (no test weakening),
  F6 (no silent fallback), or F15 (no scope expansion).
- Adding new tooling, scripts, hooks, dependencies, or CI surfaces.
- Modifying `docs/factory/DOCTRINE.md`, `LLM-WORKFLOW.md`,
  `GIT-METADATA.md`, or any other Factory document in this commit.
  The doctrine body is amended in a separate follow-up ACT only if
  reviewers find it necessary after this one closes.
- Modifying any historical ACT or HANDOFF.
- Touching any source file under `src/`, `tests/`, `scripts/`,
  `.githooks/`, `.clinerules/`, `Makefile`, or `package.json`.

---

## Principal RED

The principal RED is a textual-witness test against `AGENTS.md`. It
is RED at entry because each of the failure-mode phrases below can
currently appear in an LLM's reasoning chain without contradicting
`AGENTS.md`:

```text
R-RED-1  AGENTS.md does not state that an explicit user instruction
         outranks its own workflow defaults.
R-RED-2  AGENTS.md does not state that a phase boundary is not a turn
         boundary.
R-RED-3  AGENTS.md does not state that a commit boundary is not a turn
         boundary.
R-RED-4  F7 is silent on the temporal ordering of authorized phases
         inside one execution session.
R-RED-5  F12 is silent on the difference between commit content
         discipline and commit count per turn.
R-RED-6  AGENTS.md does not contain a closed halt list.
R-RED-7  AGENTS.md does not contain a non-halt list.
R-RED-8  AGENTS.md does not define what `GO` / `READY` / `UNBLOCKED`
         means.
R-RED-9  AGENTS.md does not declare a convergence principle.
R-RED-10 AGENTS.md does not declare that "different phase" / "next
         phase is implementation" / "fresh conversation would be
         cleaner" is explicitly NOT a halt reason.
```

The RED is preserved by recording these ten items verbatim in the
ACT's `R-RED-*` lines above, dated at entry. They are GREEN only
when `git grep` against `AGENTS.md` at the IMPL commit produces
matches for the corresponding binding phrases listed in the
acceptance criteria.

This ACT is documentation-only and therefore has no production seam.
The textual-witness test is the appropriate RED for a documentation
amendment; no synthetic mock is substituted for a real seam because
the real seam is the document itself.


---

## Acceptance criteria

Each AC is checkable by a single concrete command.

```text
AC01  AGENTS.md contains the heading "## Instruction precedence".
      Command: grep -q '^## Instruction precedence' AGENTS.md

AC02  AGENTS.md states that an explicit user instruction outranks
      AGENTS.md workflow defaults.
      Command: grep -q 'outranks' AGENTS.md

AC03  AGENTS.md contains the heading "## Convergence principle".
      Command: grep -q '^## Convergence principle' AGENTS.md

AC04  AGENTS.md states that a phase boundary is not a mandatory STOP.
      Command: grep -q 'phase boundary is NOT a mandatory STOP' AGENTS.md

AC05  AGENTS.md states that a commit boundary is not a mandatory STOP.
      Command: grep -q 'commit boundary is NOT a mandatory STOP' AGENTS.md

AC06  F7 in AGENTS.md states that it constrains what may change, not
      how many phases may execute per session.
      Command: grep -q 'constrains \*\*WHAT\*\* may change' AGENTS.md

AC07  F12 in AGENTS.md states that it MUST NOT be interpreted as
      "one phase per conversation" or "stop after every evidence
      commit".
      Command: grep -q 'one phase per conversation' AGENTS.md

AC08  AGENTS.md contains a new section "### F-CONVERGENCE — Continue
      until a real halt".
      Command: grep -q '^### F-CONVERGENCE — Continue until a real halt' AGENTS.md

AC09  AGENTS.md contains a "Closed halt list" with the seven named
      halt conditions.
      Command: grep -q 'Closed halt list' AGENTS.md && \
               grep -q 'HALT_SCOPE_EXPANSION_REQUIRED' AGENTS.md

AC10  AGENTS.md contains a "Non-halt list" with the eight named
      non-halt phrases including "next phase is a different phase",
      "next phase deserves its own commit", "fresh conversation would
      be cleaner", and "`AGENTS.md` says commits should be truthful".
      Command: grep -q 'Non-halt list' AGENTS.md && \
               grep -q '"the next phase is a different phase"' AGENTS.md && \
               grep -q '"a fresh conversation would be cleaner"' AGENTS.md && \
               grep -qF '`AGENTS.md` says commits should be truthful' AGENTS.md
      Note: the filename in the literal phrase is wrapped in Markdown
      backticks in the implementation; the un-backticked form is not
      the intent of this witness. The corrected form above is the
      canonical AC10 grep and is the source of truth.

AC11  AGENTS.md contains the exact string "GO = EXECUTE_NOW".
      Command: grep -q 'GO = EXECUTE_NOW' AGENTS.md

AC12  F-CONVERGENCE explicitly names F1, F2, F3, F4, F5, F6, and F15
      as rules it does NOT override.
      Command: grep -A1 'F-CONVERGENCE does NOT override' AGENTS.md

AC13  Sentinel scenario block is present in this ACT and named
      unambiguously.
      Command: grep -q 'C4 envelope closed' \
                  docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01.md && \
               grep -q 'START IMPL-B IMMEDIATELY' \
                  docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01.md && \
               grep -q 'C5 ScanIdent' \
                  docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01.md

AC14  The canonical HALT token HALT_ARTIFICIAL_PHASE_BOUNDARY is
      declared.
      Command: grep -q 'HALT_ARTIFICIAL_PHASE_BOUNDARY' \
                  docs/acts/ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01.md

AC15  No production-code file was modified.
      Command: git diff --stat <entry-HEAD>..HEAD -- src/ tests/ scripts/ \
                  .githooks/ .clinerules/ Makefile package.json | wc -l
      Expected: 0
```

---

## Sentinel scenario (concrete, derived from the observed failure)

This scenario is the canonical fixture. If a future reviewer reads
this ACT and asks "what behavior does F-CONVERGENCE actually
require?", the answer is: the scenario below. If a future agent
fails the scenario, it has misread `AGENTS.md` again.

```text
GIVEN
  an ACT in phase C4 EVIDENCE
  C4 envelope has just closed (EVIDENCE commit recorded)
  the same envelope verdict declares:
      C4 IMPL-B = GO
  the user has written, in the same session:
      START IMPL-B IMMEDIATELY
  C5 ScanIdent is explicitly LOCKED at the next envelope

EXPECTED
  the agent commits the EVIDENCE step if F12 requires it
  the agent immediately enters C4 IMPL-B
  the agent edits the authorized LLVM seam
  the agent runs a real hcc build
  the agent records the 13-fence witness
  the agent commits C4 IMPL-B as its own truthful commit
  the agent produces the closure packet
  the agent STOPS before C5 ScanIdent
  no step in this sequence requests user re-authorization

FORBIDDEN
  stop after the EVIDENCE commit because "implementation is another turn"
  request user authorization before entering IMPL-B
  treat the C4 EVIDENCE->IMPL-B transition as a conversation boundary
  emit any of the non-halt phrases from F-CONVERGENCE as a stop reason
  cross into C5 ScanIdent scope before C5 is unlocked
```

The hard stop in this scenario is C5 ScanIdent, not the C4 EVIDENCE
-> C4 IMPL-B transition.

---

## New HALT token

```text
HALT_ARTIFICIAL_PHASE_BOUNDARY
```

Declared when the agent stops execution of an already-authorized ACT
phase without an entry on the closed halt list. The agent must
declare which non-halt phrase from F-CONVERGENCE was its
justification. The corrective ACT typically only needs to re-run the
missed phase; no scope expansion is required.

This token is added to the canonical halt taxonomy by this ACT. No
other ACT or HANDOFF needs to be amended.


---

## HALT conditions (this ACT's halt taxonomy)

The ACT halts with the matching token if any of the following is
true at any point during execution:

- `HALT_RED_NOT_REPRODUCED` — any `AC0*` cannot be reproduced
  against the IMPL commit.
- `HALT_SCOPE_EXPANSION_REQUIRED` — closure would require editing
  any file under `src/`, `tests/`, `scripts/`, `.githooks/`,
  `.clinerules/`, `Makefile`, `package.json`, or any Factory
  document other than `AGENTS.md`.
- `HALT_GIT_IDENTITY_LOST` — the append-only pre-push hook refuses
  the proposed commit graph (entry identity lost).
- `HALT_ARTIFICIAL_PHASE_BOUNDARY` — the agent stops before
  recording the IMPL commit on a non-halt-list justification
  (self-applied; this ACT should not trigger this on itself).

---

## Residue

Pre-declared side observations.

```text
P1  docs/factory/DOCTRINE.md may need a one-paragraph cross-reference
    update pointing at F-CONVERGENCE. Deferred to a follow-up
    correction ACT if reviewers request it.

P1  docs/factory/LLM-WORKFLOW.md may need a one-line clarification
    in its lifecycle diagram that the stage sequence is intra-session
    unless a real halt intervenes. Deferred.

P2  A future regression test in scripts/quality/ could mechanically
    parse AGENTS.md to assert the F-CONVERGENCE heading and the
    closed/non-halt lists. Out of scope here; the textual AC0*
    commands are sufficient for this bounded ACT.

P2  A future FACTORY-LIFECYCLE-V2-CORRECTION02 ACT could rebrand
    HALT_ARTIFICIAL_PHASE_BOUNDARY if a more canonical name is
    preferred. Out of scope here.
```

---

## Commit topology

Single commit. The amendment to `AGENTS.md` and the ACT document
itself are inseparable for closure (the ACT authorizes the
amendment; the amendment implements the ACT). No production file
changes; no Factory document other than `AGENTS.md` is touched.

```text
1. AGENTS.md amendment + this ACT document
   trailer: ACT: ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01
            ACT-Phase: IMPL
   (no CLOSE trailer in this commit; see CLOSE commit below)
```

If the IMPL commit reproduces all AC0* cleanly, a CLOSE commit is
added on top with the `ACT-Verdict: PASS` trailer and the IMPL
commit's trailer `ACT-Phase` upgraded to `CLOSE` would be an
amend — which is forbidden by F12 / append-only rules. Instead, a
second non-amend commit records the verdict via trailer per Factory
v2 mechanics. Bounded scope means at most two commits total.

---

## Execution metadata

Execution identity is stored in Git commit trailers.

```text
ACT:      ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01
ACT-Phase: IMPL | CLOSE
ACT-Verdict: PASS | HALT_<...>
```

The original authorization artifact (this document) remains
historically stable; there is no OPEN -> PASS / HALT mutation. The
ACT document is NOT modified at closure. The verdict authority is
the CLOSE commit's `ACT-Verdict` trailer.

---

## Closure handoff

Factory v2 HANDOFF follows `docs/factory/HANDOFF-TEMPLATE.md`
(Factory v2 section).

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-FACTORY-AGENT-CONVERGENCE-NO-ARTIFICIAL-PHASE-HALTS01 HEAD
```

HANDOFF shall include:

```text
VERDICT
IDENTITY (entry HEAD, final HEAD, worktree state)
RED (the R-RED-* textual witnesses above)
IMPLEMENTATION (the AGENTS.md amendment diff summary)
GATES (AC01..AC15 results, verbatim command output)
SCOPE (only AGENTS.md and this ACT touched)
RESIDUE (P1/P2 deferred items above, updated if any)
NEXT ACT (recommended follow-up correction ACT for DOCTRINE.md and
          LLM-WORKFLOW.md cross-references, if reviewers want them)
```
