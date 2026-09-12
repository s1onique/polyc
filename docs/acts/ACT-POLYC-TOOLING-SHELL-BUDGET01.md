# ACT-POLYC-TOOLING-SHELL-BUDGET01

**Title:** Mechanically shrink the PolyC shell-debt budget
with a per-file monotonic ratchet and a deterministic
migration queue

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** TOOLING / POLICY + MEASUREMENT + RATCHET

**Track:** B / TOOLING SELF-HOST

**Predecessor (Track B):**
- `ACT-POLYC-TOOLING-SHELL-INVENTORY01` (CLOSED PASS) -- froze
  the <=50-LOC ratchet and baseline.
- `ACT-POLYC-TOOLING-RUNTIME01` (CLOSED PASS, post-correction) --
  PolyC harness substrate.
- `ACT-POLYC-TOOLING-MIGRATE-GEP01` (CLOSED PASS) -- first
  Bash->PolyC dogfood migration (232 LOC -> 0 LOC).
- `ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01` (CLOSED PASS) --
  doctrine is active for this ACT.

**Successor (mechanically selected at C2 close):**
TBD -- determined by the migration queue at C2 close. Naming
form: `ACT-POLYC-TOOLING-MIGRATE-<SUBJECT>01`.

**Production semantic changes:** FORBIDDEN

**PolyC language change:** FORBIDDEN

**Tooling runtime semantics:** FORBIDDEN

**Shell migration in this ACT:** FORBIDDEN
(this ACT freezes the budget ratchet and the migration queue;
it does NOT itself migrate another harness).

---

## 0. Mission

The repository already knows:

```text
NEW shell file > 50 LOC          => FAIL
existing grandfathered growth    => FAIL
```

and has proven one real migration:

```text
scripts/quality/llvm-gep01-test.sh
232 LOC Bash
   ↓
PolyC-native harness
0 LOC Bash
```

It does NOT yet know:

```text
- how much shell debt may remain?
- which existing files may shrink by how much?
- when does a migration permanently lower the ceiling?
- what is the next-best migration candidate?
- how do we prevent a deleted Bash script from reappearing?
```

This ACT freezes a machine-readable per-file budget manifest,
adds a verifier that enforces a monotonic budget + zero-budget
for migrated paths + unbudgeted-path rejection + migrated-path
zero-ratchet, and produces a mechanically-ranked migration
queue. The top candidate becomes the next Track-B ACT.

This ACT does not migrate another harness. The migration queue
itself is the deliverable, plus the machinery that prevents the
queue from drifting back toward Bash.

---

## 1. Why this ACT exists

Current Track-B state:

```text
SHELL-INVENTORY01                 CLOSED PASS
TOOLING-RUNTIME01                 CLOSED / corrected / usable
MIGRATE-GEP01                     CLOSED production GREEN
MIGRATE-GEP01-CORRECTION01/02     truth reconciled
F-MECHANICAL-BLOCKING             ACTIVE
SHELL-BUDGET01                    NEXT
```

The coarse ratchet ("don't grow existing shell, don't add >50
LOC new") is enforced by `scripts/quality/shell-loc-gate.sh`,
but it has three structurally unrecoverable defects:

1. The gate has no per-file **budget** column -- only a no-growth
   check against a snapshot baseline.
2. The gate has no **MIGRATED** state -- a previously deleted
   shell file can be resurrected without detection.
3. The gate has no **migration queue** -- next candidates are
   picked by hand.

This ACT adds the missing second layer without weakening the
first layer.

---

## 2. Bash policy

```text
BASH_POLICY = TRANSITIONAL_ONLY

New Bash:
  <= 50 LOC tiny wrapper only.

Existing grandfathered Bash:
  MUST NOT grow.
  SHOULD shrink.
  Once shrunk, its new smaller size becomes its new maximum.
  Once deleted, its budget becomes 0 permanently.

Logic:
  SHOULD move to PolyC.

Tiny shell wrappers:
  MAY remain when they only:
    - establish environment,
    - exec exactly one deterministic tool,
    - forward argv / stdin / exit status,
    - contain no substantive policy or test logic.
```

Long-term target: `TARGET_GRANDFATHERED_SHELL_LOC = 0`.
This is an architectural goal, not a demand of this ACT.

For migration candidates, the preferred replacement language is
PolyC, unless a future ACT mechanically proves PolyC lacks the
required substrate.

---

## 3. Budget model

Canonical machine-readable artifact:

```text
docs/factory/SHELL-BUDGET.tsv
```

Schema (tab-separated):

```text
path
baseline_loc     (loc at the freeze moment)
budget_loc       (current per-file cap; monotonic non-increasing)
state            (TINY | GRANDFATHERED | MIGRATED | EXEMPT_WRAPPER)
role             (TEST | GATE | FACTORY | TOOL | INSTALL | EVIDENCE | OTHER)
migration_priority (LOW | MEDIUM | HIGH | SKIP)
notes
```

Allowed `state` semantics:

```text
TINY:             budget_loc <= 50
GRANDFATHERED:    current_loc <= budget_loc; budget_loc > 50
MIGRATED:         current file MUST NOT exist; budget_loc = 0
EXEMPT_WRAPPER:   current_loc <= 50
```

Aggregate invariants:

```text
CURRENT_SHELL_DEBT = sum(current_loc for state == GRANDFATHERED)
SHELL_DEBT_BUDGET  = sum(budget_loc for state == GRANDFATHERED)

REQUIRED:
  CURRENT_SHELL_DEBT <= SHELL_DEBT_BUDGET
  SHELL_DEBT_BUDGET(t+1) <= SHELL_DEBT_BUDGET(t)
```

Per-file invariant:

```text
budget_loc MUST NEVER increase.
```

This is the ratchet. Migration ACTs may lower individual rows
or convert them to MIGRATED; they may NOT raise any row.

---

## 4. Migrated-path ratchet

If a budget row says `state=MIGRATED budget_loc=0` for a path
P, then re-introducing path P as a substantive shell script
MUST FAIL.

A new <=50-LOC compatibility wrapper at the same path is
allowed ONLY if a future ACT explicitly authorizes the
EXEMPT_WRAPPER row. The verifier MUST NOT auto-convert
MIGRATED back to shell.

---

## 5. New verifier

```text
scripts/quality/shell-budget-gate.sh
```

Hard cap: <= 50 LOC. If the gate cannot be implemented
honestly within 50 LOC, the logic moves to PolyC and the shell
file becomes a tiny wrapper (still <=50 LOC).

The gate reads `docs/factory/SHELL-BUDGET.tsv` and inspects
the current repository state.

### Required behavior (B1..B9)

| ID | Check                                                            | Verdict  |
|----|------------------------------------------------------------------|----------|
| B1 | GRANDFATHERED row: current_loc > budget_loc                      | FAIL     |
| B2 | Any row: new_budget > old_budget                                 | FAIL     |
| B3 | MIGRATED row: path exists in tree                                | FAIL     |
| B4 | New tracked `*.sh` absent from manifest                          | FAIL     |
| B5 | GRANDFATHERED row: current_loc < budget_loc                      | PASS+RATCHET_AVAILABLE |
| B6 | TINY/EXEMPT_WRAPPER: current_loc <= 50                           | PASS     |
| B7 | TINY/EXEMPT_WRAPPER: current_loc > 50                            | FAIL     |
| B8 | GRANDFATHERED row references absent path                         | FAIL (suggest MIGRATED) |
| B9 | Aggregate: new SHELL_DEBT_BUDGET > old SHELL_DEBT_BUDGET         | FAIL     |

The gate does NOT silently rewrite the budget.

For B2 the gate compares the committed
`docs/factory/SHELL-BUDGET.tsv` against the parent's frozen
budget snapshot. The snapshot is the budget as committed
immediately before the staged change, derived from
`git show HEAD:docs/factory/SHELL-BUDGET.tsv`.

---

## 6. Migration queue scoring

Each grandfathered file is scored on mechanically-observable
inputs (see `evidence/.../c1/migration-score-inputs.tsv`):

```text
score =
    migration_isolation      * 3
  + runtime_substrate_ready  * 3
  + oracle_quality           * 2
  + shell_loc_reduction      * 1
  - external_dependency_complexity * 2
  - destructive_side_effect_risk   * 3
```

Coefficients frozen at C2 BEFORE ranking. The score is NOT a
mathematical optimum; it is a determinism guard against
"LLM felt like migrating this script today".

Each candidate is classified:

```text
READY_NOW
NEEDS_RUNTIME_PRIMITIVE
NEEDS_COMPILER_FEATURE
NEEDS_FACTORY_REDESIGN
KEEP_AS_TINY_WRAPPER_AFTER_MIGRATION
DEFER_HIGH_RISK
```

At least one MUST be `READY_NOW` unless evidence proves
otherwise (HALT_NO_MIGRATION_CANDIDATE).

---

## 7. First migration model

`MIGRATE-GEP01` is the reference architecture:

```text
1. Freeze legacy oracle first.
2. Build PolyC equivalent.
3. Prove row-by-row parity.
4. Prove false-green path (--mode=fail).
5. Preserve direct argv.
6. Own temp/scratch lifecycle.
7. Delete legacy Bash only after parity.
8. Ratchet shell budget down immediately.
```

The next migration ACT shall follow this template.

---

## 8. Direct-argv requirement

Future PolyC harnesses continue TOOLING-RUNTIME doctrine:

```text
NO /bin/sh -c
NO bash -c
NO System()-style shell command strings
NO implicit shell expansion
```

Prefer direct argv execution. Git's own documentation notes
that hook/config commands execute arbitrary shell, and CI /
server-side enforcement (not local hooks) is where policy
becomes authoritative.

```text
LOCAL_GATE = developer feedback
CI_GATE    = authoritative policy
```

This ACT wires the new verifier into `gate-fast.sh` for local
feedback.

---

## 9. Principal RED

C1 RED reproduces six real-seam defects:

```text
R1  no per-file monotonic budget manifest
R2  no per-file downward ratchet (post-shrink)
R3  no MIGRATED-path encoding
R4  resurrected migrated path undetected
R5  no deterministic migration queue
R6  no aggregate monotonic debt invariant
```

All six are demonstrated against the real tree at C1. See
`evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c1/red-reproduction.txt`.

---

## 10. Implementation scope

Allowed:

```text
docs/factory/SHELL-BUDGET.tsv        NEW
scripts/quality/shell-budget-gate.sh NEW (must be <=50 LOC)
evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/**   evidence
docs/ROADMAP.md                       (Track-B transition only)
docs/acts/ACT-POLYC-TOOLING-SHELL-BUDGET01.md  this file
small gate-fast integration point (in-place edit, <=50 LOC)
```

Forbidden:

```text
compiler source, parser, typechecker, neutral IR, LLVM backend
tooling runtime semantics
migration of any grandfathered script
deletion of another shell harness
Factory doctrine unrelated to shell budget
historical evidence rewriting
```

The `gate-fast.sh` integration point MUST stay <=50 LOC.

---

## 11. Negative test packet

```text
N1  current tree                              => PASS
N2  grandfathered +1 LOC                      => FAIL
N3  budget +1 without code change             => FAIL
N4  budget -1 valid shrink                    => PASS
N5  MIGRATED path recreated                   => FAIL
N6  unbudgeted new 20-LOC .sh                 => FAIL budget gate
N7  new 54-LOC .sh                            => FAIL shell-loc-gate
N8  tiny 40 -> 51 LOC                         => FAIL
N9  stale GRANDFATHERED row, file deleted     => FAIL (suggest MIGRATED)
N10 row changed GRANDFATHERED -> MIGRATED,
    file absent                               => PASS
```

Tests assert the verifier's process exit status (not only
emitted text).

---

## 12. Acceptance criteria (frozen list)

```text
AC01  Complete tracked-shell inventory generated from Git.
AC02  Every tracked .sh has exactly one budget row.
AC03  No budget row refers to an unknown path except MIGRATED.
AC04  Current LOC measured mechanically.
AC05  Every TINY/EXEMPT_WRAPPER file <=50 LOC.
AC06  Every GRANDFATHERED file current_loc <= budget_loc.
AC07  Every MIGRATED row budget_loc=0.
AC08  MIGRATED path existence causes FAIL.
AC09  Unbudgeted tracked shell file causes FAIL.
AC10  Grandfathered file +1 over budget causes FAIL.
AC11  Grandfathered file below budget causes PASS.
AC12  Budget increase vs predecessor causes FAIL.
AC13  Budget decrease vs predecessor causes PASS.
AC14  Aggregate budget increase causes FAIL.
AC15  Aggregate budget equal causes PASS.
AC16  Aggregate budget decrease causes PASS.
AC17  New 54-LOC shell remains rejected by shell-loc-gate.
AC18  New <=50 LOC wrapper remains accepted where otherwise valid.
AC19  Existing grandfathered growth remains rejected.
AC20  llvm-gep01-test.sh remains absent / MIGRATED=0.
AC21  Reintroducing llvm-gep01-test.sh causes FAIL.
AC22  Migration scoring covers every GRANDFATHERED row.
AC23  Every candidate has one readiness category.
AC24  At least one READY_NOW candidate exists.
AC25  Next migration candidate selected mechanically.
AC26  No production/compiler semantic delta.
AC27  New shell files in this ACT <=50 LOC.
AC28  shell-loc-gate remains PASS.
AC29  shell-budget-gate PASS on current tree.
AC30  gate-fast / canonical Factory gate remains PASS.
AC31  GEP PolyC harness PASS (30/0).
```

---

## 13. Conservation gates

```text
factory-v2-test
factory-append-only-test
factory-closure-status-check
factory-halt-classification-test
shell-loc-gate
shell-budget-gate          (new)
gate-fast
PolyC llvm-gep01 harness   PASS 30/0
```

---

## 14. Halt taxonomy

```text
HALT_INVENTORY_INCOMPLETE
HALT_BUDGET_BASELINE_INVALID
HALT_BUDGET_INCREASE
HALT_MIGRATED_PATH_REAPPEARED
HALT_GATE_FALSE_GREEN
HALT_NO_MIGRATION_CANDIDATE
HALT_SCOPE_EXPANSION_REQUIRED
HALT_GIT_INTEGRITY
```

Mechanical only; prose imperfections are not halts. Under
F-MECHANICAL-BLOCKING:

```text
HALT_CLASS = GOVERNANCE
BLOCKS_NEXT = NO
```

for non-semantic documentation residue.

---

## 15. Commit topology

```text
C1 RED      ACT + C1 evidence
C2 IMPL     budget manifest + verifier + negative tests +
            migration queue + gate integration
C3 CLOSE    fresh measurements + acceptance matrix +
            ROADMAP transition + verdict
```

No artificial EVIDENCE phase. No post-CLOSE commits carrying
this ACT id.

---

## 16. C3 closure truth

```text
ACT_VERDICT                 = PASS
ROADMAP_STATE               = CLOSED

TRACKED_SHELL_FILES         = <measured>
TOTAL_SHELL_LOC             = <measured>
GRANDFATHERED_FILES         = <measured>
CURRENT_SHELL_DEBT          = <measured>
SHELL_DEBT_BUDGET           = <measured>

NEW_SHELL_MAX_LOC           = 50
GRANDFATHERED_GROWTH        = FORBIDDEN
PER_FILE_BUDGET_INCREASE    = FORBIDDEN
AGGREGATE_BUDGET_INCREASE   = FORBIDDEN
MIGRATED_PATH_REAPPEARANCE  = FORBIDDEN

SHELL_LOC_GATE              = PASS
SHELL_BUDGET_GATE           = PASS
NEGATIVE_TESTS              = PASS
GEP_POLYC_HARNESS           = PASS (30/0)

NEXT_MIGRATION_CANDIDATE    = <mechanically selected path>
NEXT_ACT                    = ACT-POLYC-TOOLING-MIGRATE-<SUBJECT>01
```

No SHA-of-self (per AGENTS.md / DOCTRINE §22 / §25).

---

## 17. ROADMAP update (Track B after this ACT)

```text
SHELL-INVENTORY01     ✅ CLOSED
TOOLING-RUNTIME01     ✅ CLOSED
MIGRATE-GEP01         ✅ CLOSED (first PolyC dogfood)
MECHANICAL-BLOCKING01 ✅ CLOSED (doctrine active)
SHELL-BUDGET01        🟢 NEXT (this ACT)
--------------------------------------------
MIGRATE-<NEXT>01      🔓 selected by C2 ranking
```
