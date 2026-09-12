# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: RED
ACT-Phase-Notes: C1.5 RED-AMEND. Incorporates three
  reviewer refinements folded into the C1 RED phase
  before C2 IMPL begins. The literal ACT-Phase trailer
  remains RED because the Factory v2 commit-msg
  grammar (§2.1 of docs/factory/GIT-METADATA.md and
  scripts/quality/factory-v2-commit-msg-check.sh)
  accepts only {RED, IMPL, EVIDENCE, CLOSE}; the
  colloquial "RED-AMEND" label is recorded only in
  this ACT-Phase-Notes body and in the commit
  message, not in the trailer itself.

    R1. SCOPE TIGHTENING. The title and acceptance
        criteria are changed from "roadmap-affecting
        HALT_*" to "every new HALT_* CLOSE verdict".
        This removes an avoidable conditional
        ("who decides whether it affects roadmap
        progression before the metadata exists?").
        The trailer-pair requirement is now a
        unconditional property of every new HALT_*
        CLOSE commit and forbidden on every PASS
        commit.

    R2. GRANDFATHERING BOUNDARY. F-MECHANICAL-BLOCKING
        applies to CLOSE commits created AFTER this
        ACT's closing commit. Historical CLOSE commits
        remain valid evidence under F14; their lack of
        HALT_CLASS / BLOCKS_NEXT trailers is NOT a
        defect. Without this boundary the new
        doctrine would itself become a global
        artificial blocker (F15 violation by
        inversion).

    R3. NO GOVERNANCE RECURSION. The previously
        recommended "TRACK-B-ADVANCE01" authorization
        ACT is REMOVED from §12 (NEXT_ACT). Once
        F-MECHANICAL-BLOCKING is in force, a halt
        with HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO
        IS the documented board signal that no
        additional authorization ACT is required
        for a successor in the same scope to open.
        A second authorization ACT would be
        governance recursion and would partially
        defeat the doctrine being introduced.

  Production / parser / typechecker / neutral-IR /
  LLVM / ABI changes remain FORBIDDEN. Historical
  evidence rewriting remains FORBIDDEN. No new
  Track-B ACT will be opened in this turn.

  Per the precedent set by
  ACT-POLYC-FACTORY-AGENT-GATES01 /
  FACTORY-STATUS-RECONCILIATION and others,
  Factory-doctrine amendments MUST be authored,
  reviewed, and closed as their own ACT before any
  downstream ACT may rely on them. This ACT is
  that ACT.

**Title:** Codify `F-MECHANICAL-BLOCKING` and add a
bounded Factory verifier ensuring every new
`HALT_*` CLOSE verdict carries `HALT_CLASS` and
`BLOCKS_NEXT`, so prose alone cannot block
mechanically-green work. The new rule applies
prospectively from this ACT's CLOSE commit
forward; historical CLOSE commits are
grandfathered under F14.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** FACTORY / DOCTRINE-AND-GATE-AMENDMENT

**Production semantic changes:** FORBIDDEN
**Compiler semantic changes:** FORBIDDEN
**Parser / typechecker changes:** FORBIDDEN
**Neutral-IR changes:** FORBIDDEN
**LLVM backend changes:** FORBIDDEN
**ABI changes:** FORBIDDEN
**Historical evidence rewriting:** FORBIDDEN
**Changing any closed ACT's verdict merely to conform:**
  FORBIDDEN
**Opening `ACT-POLYC-TOOLING-SHELL-BUDGET01` or any new
  Track-B ACT in this turn:** FORBIDDEN
  (per CORRECTION02 §12: "This ACT does NOT begin
  SHELL-BUDGET01; that is the board's authorization to
  issue in a future turn, not this turn's obligation.")
**Authorizing `TRACK_B_ADVANCE` from this turn:** FORBIDDEN
  (per the C1.5 RED-AMEND: the doctrine this ACT
  codifies makes any such authorization ACT a
  governance recursion. The successor ACT opens in a
  future turn by citing F-MECHANICAL-BLOCKING and the
  existing halt's HALT_CLASS / BLOCKS_NEXT pair, not
  by waiting for another authorization ACT.)

---

# 0. Mission

PolyC has repeatedly observed the failure mode in which
a mechanically-green production delta is blocked because
a prose assertion in an ACT, a closure narrative, an
acceptance criterion whose baseline was never measured,
a stale count, or an unrelated environmental failure is
treated as a blocking dependency. F1-F15 already forbid
silently enlarging scope, but they do not currently
give the agent a mechanical rule for separating "this
halt is mechanically demonstrable on the relevant
subject" from "this halt is prose-asserted against an
unrelated seam".

This ACT adds, freezes, and mechanically binds one new
Factory operating law:

```
F-MECHANICAL-BLOCKING — PROSE ALONE NEVER BLOCKS PROGRESS
```

and adds a small deterministic verifier that enforces
the following trailer contract on every CLOSE commit
created AFTER this ACT's CLOSE commit:

```
PASS verdict (effective PASS(_...)*)
    HALT_CLASS  : forbidden
    BLOCKS_NEXT : forbidden

HALT_* verdict (effective HALT_<TOKEN>)
    HALT_CLASS  : required, exactly 1, value in
                  { GOVERNANCE, PRODUCTION, SAFETY,
                    AUTHORIZATION, DEPENDENCY }
    BLOCKS_NEXT : required, exactly 1, value in { YES, NO }
    class / boolean combination valid
```

Two distinct planes of truth are preserved:

```
ACT truth    : did this ACT satisfy its own contract?
Roadmap truth: does that outcome prevent the next
               authorized action?
```

A halt verdict may therefore legitimately read:

```
ACT-Verdict: HALT_<TOKEN>
ACT-Corrected-Verdict: HALT_<TOKEN>
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

which means "this ACT did not satisfy its own contract"
WITHOUT meaning "the successor ACT is mechanically
blocked". Without `HALT_CLASS` + `BLOCKS_NEXT`, the
roadmap state cannot be derived; with them, it is
syntactically derivable and verifiable.

### 0.1 Prospective application (grandfathering)

`F-MECHANICAL-BLOCKING` and its verifier apply to CLOSE
commits whose commit timestamp is at or after the
timestamp of this ACT's CLOSE commit. CLOSE commits
created before this ACT's CLOSE commit are valid
historical evidence under F14 and are NOT re-validated
for the absence of `HALT_CLASS` / `BLOCKS_NEXT`.

This boundary is non-negotiable. Without it, the
doctrine this ACT introduces would itself become a
global artificial blocker on every historical halt in
the repository, inverting F15 ("never self-authorize
scope expansion") into a permanent block rather than a
guard against one.

# 1. Why

Concrete recent evidence:

(a) `ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01`
    closed with `ACT-Verdict: PASS` but its closure
    narrative reclassified three unrelated gates
    (`make unit-test`, `make jit-unit-test`,
    `make lsp-test`) as `ENVIRONMENTALLY_UNAVAILABLE`
    by analogy with two *different* c4-baseline gates.
    The current ACT (`CORRECTION02`) honestly
    reclassified the predecessor to
    `HALT_AC07_NOT_SATISFIED`.

(b) `HALT_AC07_NOT_SATISFIED` carries the bare verdict
    grammar at `docs/factory/GIT-METADATA.md` §2.2. It
    does NOT distinguish a halting predicate that
    mechanically blocks a successor from one that does
    not. The Factory closure-status oracle at
    `scripts/quality/factory-closure-status-check.sh`
    therefore reports this halt as if it were
    universally blocking, even though the only
    successor ACT candidate (`SHELL-BUDGET01`) has no
    mechanically-demonstrated dependency on
    `make unit-test` / `jit-unit-test` / `lsp-test`
    passing on the local checkout.

(c) `ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02`
    explicitly states:

        "If this ACT itself must HALT, the next ACT is
         to recommend the bounded expansion in a
         separate CORRECTION03 (NOT in this turn)."
        "Hard stop after CLOSE."
        "This ACT does NOT begin SHELL-BUDGET01; that
         is the board's authorization to issue in a
         future turn, not this turn's obligation."

    The board therefore needs a doctrine-level answer
    to "given an honest halt verdict on an unrelated
    environmental failure, what stops the next Track-B
    ACT?" The answer today is "whatever prose you
    write"; the answer this ACT codifies is "a
    mechanically demonstrated successor dependency".

# 2. The new rule (verbatim text to be inserted)

The following text MUST be added to
`docs/factory/DOCTRINE.md` as a new section near the
existing F-rule topology (F1-F15 + F-GIT-* addenda),
and a one-paragraph pointer MUST be added to `AGENTS.md`
near the existing pointer block to F1-F15.

```
## 25. F-MECHANICAL-BLOCKING — PROSE ALONE NEVER BLOCKS PROGRESS

Golden rule:

  Prose may AUTHORIZE scope and may CONSTRAIN what an
  ACT is permitted to change.

  Prose alone MUST NOT establish that an implementation
  is defective, that a predecessor is unsafe, or that
  the roadmap must stop.

  A board transition may be BLOCKED only by a
  mechanically demonstrable blocking predicate.

BLOCKING predicates are limited to:

  B1. A required executable gate actually fails on the
      relevant subject and the failure is attributable
      to that subject.

  B2. A reproducible semantic/runtime/compiler defect
      exists in the production subject.

  B3. A mechanically demonstrated safety, integrity,
      corruption, security, or destructive-operation
      invariant is violated.

  B4. The requested implementation requires production
      changes outside the currently authorized scope.
      This is an AUTHORIZATION blocker, not evidence
      that existing production behavior is defective.

  B5. A mechanically required predecessor capability
      is absent and the successor ACT actually depends
      on that capability.

Everything else is NON-BLOCKING by default, including:

  - prose contradictions;
  - stale wording;
  - stale counts in narrative evidence;
  - inaccurate captions;
  - an acceptance criterion whose baseline was never
    measured;
  - historical evidence hygiene defects;
  - SHA / identity wording defects;
  - documentation arithmetic errors;
  - superseded interpretations;
  - closure-packet defects;
  - failed environmental gates proven unrelated to the
    changed production subject;
  - impossible or internally inconsistent acceptance
    wording;
  - metadata / bookkeeping residue;
  - a historical HALT whose underlying production
    dependency is mechanically GREEN.

Such findings MUST be recorded honestly, but MUST be
classified:

  NON_BLOCKING_GOVERNANCE_RESIDUE

unless one of B1-B5 is mechanically demonstrated.

PROSE CANNOT PROMOTE ITSELF TO A BLOCKER.

A prose assertion such as:

  "AC07 requires X"
  "this HALT blocks Y"
  "the predecessor must be PASS"

does not establish a blocking dependency by itself. The
blocking dependency must be represented by a checkable
predicate and evidence showing that the successor ACT
actually relies on it.

HALT CLASSIFICATION

Every HALT that affects roadmap progression MUST carry:

  HALT_CLASS = PRODUCTION | SAFETY | AUTHORIZATION |
               DEPENDENCY | GOVERNANCE
  BLOCKS_NEXT = YES | NO

The HALT CLASS / BLOCKS_NEXT pair is required on every
new HALT_* CLOSE commit and forbidden on every new
PASS CLOSE commit. Historical CLOSE commits are
grandfathered (see §0.1 of the ACT itself).

Defaults:

  GOVERNANCE     -> BLOCKS_NEXT = NO (governance halt
                    is, by default, non-blocking)
  PRODUCTION     -> BLOCKS_NEXT = YES
  SAFETY         -> BLOCKS_NEXT = YES
  AUTHORIZATION  -> BLOCKS_NEXT = YES for the
                    unauthorized mutation
  DEPENDENCY     -> determined mechanically from
                    successor needs; either value
                    allowed (the verifier does not
                    infer successor needs in v1)

Environmental or unavailable failures that are proven
unrelated to the production delta are:

  HALT_CLASS = GOVERNANCE
  BLOCKS_NEXT = NO

unless the successor ACT mechanically depends on the
unavailable facility.

CORRECTIONS

A correction ACT MAY revise a historical verdict truth
while leaving roadmap progression unblocked:

  ACT-Corrected-Verdict: HALT_<...>
  HALT_CLASS:            GOVERNANCE
  BLOCKS_NEXT:           NO

This is not contradictory. The corrected HALT says "the
historical ACT did not satisfy its written contract".
BLOCKS_NEXT = NO says "that contract defect does not
invalidate the mechanically-proven production dependency
required by the successor".

EVIDENCE OVER PROSE

When mechanical evidence and descriptive prose disagree:

  mechanical evidence determines production truth;
  prose is corrected or classified as residue.

Never mutate production merely to make prose become true.
Never halt a mechanically-green successor ACT merely to
repair historical narrative consistency.
```

The corresponding addition to `AGENTS.md` is a single
paragraph pointing to the new section. It MUST NOT
duplicate the rule text (per the canonical
`AGENTS.md`-is-operational / `DOCTRINE.md`-is-rationale
split).

# 3. Scope

### Allowed

- `docs/factory/DOCTRINE.md` (add new section;
  non-disruptive append / insertion near F-rule topology)
- `AGENTS.md` (one-paragraph pointer near the F-rule
  pointer block)
- `docs/factory/GIT-METADATA.md` (add the trailer
  grammar for `HALT_CLASS` and `BLOCKS_NEXT`)
- `scripts/quality/factory-halt-classification-check.sh`
  (new small verifier; first LOC bound: <= 250 LOC)
- `scripts/quality/factory-halt-classification-test.sh`
  (new deterministic test matrix for R1-R7; first LOC
  bound: <= 350 LOC)
- `docs/acts/ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01.md`
  (this ACT)
- `evidence/ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01/`
  (this ACT's evidence tree)

### Forbidden

- Compiler / parser / typechecker / IR / LLVM / ABI
  changes
- Track-A code changes
- Track-B harness / runtime changes
- Historical evidence rewriting of any kind
- Changing any closed ACT's verdict merely to conform
- Opening `ACT-POLYC-TOOLING-SHELL-BUDGET01` or any new
  Track-B ACT in this turn
- Authorizing `TRACK_B_ADVANCE` from this turn
- Modifying the existing Factory v2 verdict grammar at
  `docs/factory/GIT-METADATA.md` §2.2 (the new
  `HALT_CLASS` / `BLOCKS_NEXT` are ADDITIVE trailers on
  the CLOSE commit, NOT a replacement for `ACT-Verdict`)
- Modifying `ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02`
  evidence / trailers
- Re-running or re-classifying AC07 in this turn
- Any change to `make unit-test` / `make jit-unit-test` /
  `make lsp-test` Makefile recipes (that is the
  environmental residue recorded in CORRECTION02 §10,
  deferred to infrastructure scope, NOT this ACT)

# 4. Principal RED

R1 -- `F-MECHANICAL-BLOCKING` is not present in
`docs/factory/DOCTRINE.md` or `AGENTS.md`:

```sh
$ grep -n 'F-MECHANICAL-BLOCKING' \
    docs/factory/DOCTRINE.md AGENTS.md
$ echo rc=$?
# rc=1  (zero matches)
```

R2 -- `HALT_CLASS` and `BLOCKS_NEXT` are not in the
verifier trailer grammar; no Factory verifier currently
checks for them:

```sh
$ grep -n 'HALT_CLASS\|BLOCKS_NEXT' scripts/quality/*.sh
$ echo rc=$?
# rc=1  (zero matches)
```

R3 -- the most recent halt verdict
(`HALT_AC07_NOT_SATISFIED`) on the production tree
(carrying on `bf52316`) has no `HALT_CLASS` and no
`BLOCKS_NEXT`, so a verifier that required them would
correctly FAIL on the current state:

```sh
$ git log --format='%B' -1 1732c3f | \
    grep -E 'HALT_CLASS|BLOCKS_NEXT'
$ echo rc=$?
# rc=1
```

R4 -- the proposed R1-R7 matrix in the new verifier's
test file (R1: governance/no, R2: production/yes,
R3: missing class fails, R4: missing blocks fails,
R5: PASS + BLOCKS_NEXT=YES fails, R6: governance + yes
fails without exemption evidence, R7: production + no
fails without exemption evidence) is mechanically
deterministic and exercises only trailer-text
inspection.


# 5. Implementation boundary (preview only)

C2 IMPL will add:

1. The verbatim section text in section 2 to
   `DOCTRINE.md` (inserted immediately after section 24,
   as section 25).
2. A one-paragraph pointer in `AGENTS.md` under the
   existing F1-F15 block.
3. Two new trailers in `GIT-METADATA.md`:
   `HALT_CLASS` (enum, OPTIONAL on CLOSE only when
   `ACT-Verdict` starts with `HALT_`) and `BLOCKS_NEXT`
   (`YES|NO`, OPTIONAL on CLOSE only when `ACT-Verdict`
   starts with `HALT_`). Both trailers are ADDITIVE on
   the CLOSE commit; the existing `ACT-Verdict` and
   supersession trailers are unchanged.
4. `scripts/quality/factory-halt-classification-check.sh`
   -- a thin validator. Cardinality rules:
   - When `ACT-Verdict` matches `^HALT_[A-Z0-9_]+$`,
     `HALT_CLASS` MUST be present and must be one of
     `PRODUCTION|SAFETY|AUTHORIZATION|DEPENDENCY|GOVERNANCE`,
     and `BLOCKS_NEXT` MUST be present and must be
     `YES` or `NO`.
   - When `ACT-Verdict` is `PASS(...)`, `HALT_CLASS`
     and `BLOCKS_NEXT` MUST NOT be present.
   - When `HALT_CLASS = GOVERNANCE`, `BLOCKS_NEXT`
     MUST be `NO`.
   - When `HALT_CLASS = PRODUCTION`, `BLOCKS_NEXT`
     MUST be `YES`.
   - When `HALT_CLASS = SAFETY`, `BLOCKS_NEXT`
     MUST be `YES`.
   - When `HALT_CLASS = AUTHORIZATION`,
     `BLOCKS_NEXT` MUST be `YES`.
   - When `HALT_CLASS = DEPENDENCY`, either value is
     allowed; the verifier does not infer successor
     needs in v1 (per the user's R6/R7 simplification
     note: "I would keep the first implementation even
     simpler than R6/R7 if necessary: require the fields
     and validate the enum/boolean; don't build an
     ontology engine in v1.").

### 5.1 Activation boundary (grandfathering)

The verifier MUST take a `--since <commit>` argument.
When invoked from `gate-fast.sh` / `gate-push.sh` /
`factory-halt-classification-test.sh`, the boundary is
the commit that adds this verifier to the repository
tree (i.e. the C2 IMPL commit of this ACT). Historical
CLOSE commits at or before that boundary MUST NOT be
checked by the verifier.

Without `--since`, the verifier MUST default to
"current commit only" mode and inspect only the
trailers on its `HEAD` argument. This makes the
default safe for ad-hoc invocation.

The test suite (`factory-halt-classification-test.sh`)
exercises ONLY synthetic commit messages and the
specific commit message of this ACT's CLOSE commit.
It MUST NOT walk the full repository history and
re-flag historical CLOSE commits.

### 5.2 Parsing discipline

The verifier MUST NOT delegate to
`git interpret-trailers --parse` because Git's
built-in trailer parser (as of 2.54.0) does NOT
accept underscores in trailer keys; `HALT_CLASS`
and `BLOCKS_NEXT` are silently dropped by that
parser. The verifier MUST parse trailers directly
with `grep -E` against the documented
`<KEY>:[[:space:]]+<VALUE>` shape.

This implementation choice is a v1 simplification
of the R1.5 RED-AMEND revision. The constraint
preserves all trailer semantics; only the parser
choice changes. Future Factory-v2 versions MAY
revisit this if Git's trailer parser gains
underscore support.

# 6. Acceptance criteria

AC01 -- `F-MECHANICAL-BLOCKING` section present in
`docs/factory/DOCTRINE.md` with the verbatim rule
text from section 2 (modulo typo correction only).
Verified by `grep -c 'F-MECHANICAL-BLOCKING'
docs/factory/DOCTRINE.md` >= 1 and a fixed-string grep
for `BLOCKS_NEXT = YES | NO`.

AC02 -- `AGENTS.md` carries a one-paragraph pointer to
the new section without duplicating its body.
Verified by `grep -c 'F-MECHANICAL-BLOCKING' AGENTS.md`
>= 1.

AC03 -- `GIT-METADATA.md` documents the new
`HALT_CLASS` and `BLOCKS_NEXT` trailers with the
cardinality rules in section 5. Verified by a
fixed-string grep for both keys and for the `YES|NO`
enum.

AC04 -- `factory-halt-classification-check.sh` exists
and is `+x`. Verified by `test -x`.

AC05 -- `factory-halt-classification-test.sh` exists
and exits 0 on a fresh run, with PASS/FAIL counts
matching the R1-R7 matrix.

AC06 -- existing Factory v2 tests
(`factory-v2-test.sh`) remain PASS. Verified by
`sh scripts/quality/factory-v2-test.sh` exit code 0.

AC07 -- existing closure-status check
(`factory-closure-status-check.sh`) remains PASS.
Verified by `sh scripts/quality/factory-closure-status-check.sh`
exit code 0.

AC08 -- the append-only invariant suite
(`factory-append-only-test.sh`) remains PASS. Verified
by `sh scripts/quality/factory-append-only-test.sh`
exit code 0.

AC09 -- `git diff --check HEAD~1..HEAD` exits 0 on the
C2 CLOSE commit.

AC10 -- no `git replace -l` entries (append-only
invariant holds).

AC11 -- the new verifier has a `--since <commit>`
boundary and its default invocation (no `--since`)
inspects only `HEAD`. Verified by `factory-halt-classification-test.sh`
R8 fixture (synthetic historical PASS commit lacking
the new trailers MUST NOT cause FAIL when invoked
without `--since`).

AC12 -- the new test suite does NOT walk full
repository history; it inspects only the synthetic
fixtures and the literal commit message of this
ACT's CLOSE commit. Verified by `grep -c
'git log' scripts/quality/factory-halt-classification-check.sh
scripts/quality/factory-halt-classification-test.sh`
returning 0 matches in those scripts.


# 7. Conservation gates

The following broad gates must remain PASS at C2 IMPL
and C3 CLOSE (or be honestly recorded as unrelated
residue):

- `sh scripts/quality/factory-v2-test.sh`            (PASS)
- `sh scripts/quality/factory-append-only-test.sh`   (PASS)
- `sh scripts/quality/factory-closure-status-check.sh` (PASS)
- `sh scripts/quality/factory-halt-classification-test.sh`
                                                       (PASS, post-IMPL)
- `git diff --check HEAD~1..HEAD`                    (PASS)

Note: `make unit-test` / `make jit-unit-test` /
`make lsp-test` are NOT conservation gates for this
ACT. Per CORRECTION02 section 10 (P1), they fail with
rc=2 on this checkout due to environmental issues
(`/usr/local/include/tos.HH` absent; macOS sandbox `ar`
cache-file permission). That residue is recorded as P1
infrastructure work outside this ACT's scope. Per F10,
the change this ACT introduces is purely textual +
verifier; the conservation predicate is the Factory
verifier matrix and the append-only invariant, not the
PolyC language gates.

# 8. HALT conditions

- `HALT_RED_NOT_REPRODUCED` -- if the principal RED
  cannot be reproduced on the real seam (e.g. the
  doctrine is already present, or the trailer grep
  matches).
- `HALT_SCOPE_EXPANSION_REQUIRED` -- if a correct
  completion requires production code changes,
  Track-B ACT opening, or modifying a closed ACT.
- `HALT_FACTORY_BINDING_BROKEN` -- if the new verifier
  cannot be bound to the existing
  `factory-closure-status-check.sh` regression matrix
  without weakening an existing test (F5).

# 9. Commit topology

1. C1 RED     -- ACT document + RED evidence tree
                  (committed previously).
2. C1.5 RED-AMEND -- this commit. Folds in the three
                  reviewer refinements (scope
                  tightening, grandfathering boundary,
                  removal of the proposed
                  TRACK-B-ADVANCE01 ceremony). Only
                  the ACT document is modified; no
                  production files change in this
                  commit.
3. C2 IMPL    -- adds DOCTRINE.md §25, AGENTS.md
                  pointer, GIT-METADATA.md trailer
                  grammar, two new verifier scripts.
4. C3 CLOSE   -- conservation gates re-verified;
                  verdict trailer added.

Cardinality-1 CLOSE: exactly ONE commit for this ACT
may carry `ACT-Phase: CLOSE` and `ACT-Verdict`.

# 10. Residue (pre-declared per F11)

P0 -- none anticipated beyond the principal RED R1-R4.

P1 -- environmental failure of AC07's three gates
(`make unit-test`, `make jit-unit-test`,
`make lsp-test`) recorded in
`ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02` section
10 is NOT in this ACT's scope. It is inherited residue.
Recorded as `NON_BLOCKING_GOVERNANCE_RESIDUE` per the
new doctrine this ACT codifies.

P1 -- Track B advancement (`ACT-POLYC-TOOLING-SHELL-BUDGET01`):
NOT in this ACT's scope. The doctrine this ACT codifies
means the board can open SHELL-BUDGET01 in a future turn
directly, citing F-MECHANICAL-BLOCKING and the halt
classification of CORRECTION01 as
`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`. No intermediate
"TRACK-B-ADVANCE01" authorization ACT is required or
recommended. Any future reclassification of CORRECTION01's
halt classification must be additive (a new trailer or
correction ACT) and MUST NOT mutate the existing CLOSE
commit (F14).

P2 -- none anticipated.

# 11. Closure handoff (deferred to C3 CLOSE)

Will contain the standard structured fields per
`docs/factory/HANDOFF-TEMPLATE.md`:

```
  VERDICT
  IDENTITY (branch, ACT id, phase, verdict)
  RED (R1-R4 mechanical reproduction)
  IMPLEMENTATION (minimum production diff)
  GATES (FACTORY_V2, APPEND_ONLY, CLOSURE_STATUS,
         HALT_CLASSIFICATION)
  SCOPE (FILES_CHANGED, *_CHANGED=NO)
  RESIDUE (P0/P1/P2)
  NEXT_ACT
```

# 12. Next ACT on PASS

`ACT-POLYC-TOOLING-SHELL-BUDGET01` is NOT in this ACT's
scope (per CORRECTION02 §12). The doctrine this ACT
codifies removes the requirement for an intermediate
"authorization to authorize" ACT.

The recommended NEXT_ACT chain on PASS of this ACT:

1. `ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01-CORRECTION01`
   if any RED-AMEND / CORRECTION is needed to keep the
   verifier honest.
2. Optional: a bounded correction ACT
   `ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION03` (or
   equivalent) that additively records the halt
   classification of CORRECTION01's halt as
   `HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO` using the
   new trailer grammar. F14 still binds: this correction
   MUST NOT mutate the existing CLOSE commit. It can
   only record the classification in a NEW commit.
3. `ACT-POLYC-TOOLING-SHELL-BUDGET01` itself, which can
   open in a future turn by citing F-MECHANICAL-BLOCKING
   and the recorded halt classification.

Step 2 is OPTIONAL because the halt classification is
already mechanically derivable from the production tree:
the halt's `ACT-Verdict` is `HALT_AC07_NOT_SATISFIED`
(see CORRECTION02) on an environmental gate failure
unrelated to the SHELL-BUDGET01 subject. F-MECHANICAL-
BLOCKING explicitly classifies this as
`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO` without
requiring a reclassification commit.

# 13. Commit trailer contract

C1 RED (previous commit):

```
ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: RED
```

C1.5 RED-AMEND (this commit):

```
ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: RED
```

The "RED-AMEND" label is descriptive only; the literal
ACT-Phase trailer remains RED. RED-AMEND commits are a
Factory v2 pattern (see CORRECTION02 closure evidence
and the closure-summary narratives for prior
RED-AMENDs); they occur when the RED phase is being
amended in place without advancing to IMPL, and they
do not introduce a new phase value into the trailer
grammar.

C2 IMPL:

```
ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: IMPL
```

C3 CLOSE PASS:

```
ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

The C3 CLOSE PASS MUST NOT carry `HALT_CLASS` or
`BLOCKS_NEXT` because the verdict is PASS (those
trailers are forbidden on every PASS CLOSE per
§0 of the ACT itself). This documents the
convention.

If at any point during this ACT's lifecycle the
board determines the verifier, doctrine, or scope
is materially wrong, the CLOSE verdict will instead
be one of the HALT_* tokens; the trailers will then
be present and the HALT_CLASS / BLOCKS_NEXT pair will
record what is and is not blocked. The literal
example for that hypothetical close would be:

```
ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: CLOSE
ACT-Verdict: HALT_<TOKEN>
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

The actual C3 trailer is the PASS form.

No SHA-of-self fields. The closing commit's SHA is
queried from Git, not embedded in this document.
