# ACT-POLYC-SELFHOST-SURFACE-RECON02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Reconstruct the live PolyC self-host boundary after LEXER03, inventory all remaining authoritative non-self-hosted compiler surfaces, rank them mechanically, and select exactly one next bounded migration ACT.

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / RECON / DEPENDENCY-SELECTION

**Predecessor authority:**

```text
ACT-POLYC-SELFHOST-LEXER03-CORRECTION02
  C0 AUTH      = c6e56fd
  C1 RED/RECON = a674b1f
  C2 IMPL      = 9037741
  C3 EVIDENCE  = c2504a2
  C4 CLOSE     = 4fa66c7
  hygiene      = 4783fa0
VERDICT = PASS_TRUE_GREEN

LEXER03_STAGE0_STAGE1_SEMANTIC_EQUIVALENCE = PASS
LEXER03_4_GENERATION_BUILD_SMOKE           = PASS
LEXER03_COMPONENT_OBJECT_FIXED_POINT       = PASS
LEXER03_BOOTSTRAP_QUALIFICATION            = COMPLETE
```

**Production compiler-semantic changes:** FORBIDDEN.

**Purpose:** Determine the next real self-hosting target. This ACT shall not assume that the next ACT is `LEXER04`. A successful close freezes exactly one successor ACT ID and its scope.

**Acceptance criteria** are enumerated in §28 and tracked mechanically in `evidence/ACT-POLYC-SELFHOST-SURFACE-RECON02/c3/mandatory-ac-status.tsv`. The C3 required-result ledger in §34 is the closure contract.

**Terminal outcomes:**

```text
PASS_TARGET_SELECTED:
  SELFHOST_SURFACE_RECON02 = COMPLETE
  SELECTED_TARGET = <surface_id>
  SELECTED_TARGET_RANK = 1
  NEXT_ACT_ID = <exact ACT>
  NEXT_ACT_SCOPE_FROZEN = YES
  VERDICT = PASS_TRUE_GREEN

HALT_NO_ATOMIC_SELFHOST_TARGET:
  BLOCKERS_EXIST = YES
  ATOMIC_CANDIDATES = 0
  RECOMMENDED_ENABLING_ACT = <id>

HALT_SELFHOST_FRONTIER_COMPLETE:
  (positive architectural finding; must be mechanically proven)
```

**Phase topology:**

```text
C0 AUTH      (this document)
C1 INVENTORY (observation only; no production mutation)
C2 RANK/SELECT (still no compiler implementation)
C3 VERIFY (controls, conservation, Factory gates)
C4 CLOSE   (HANDOFF + additive ROADMAP + closure metadata)
```

**Commit topology:**

```text
C0 AUTH      one commit
C1 INVENTORY one commit
C2 RANK/SELECT one commit
C3 VERIFY    one commit
C4 CLOSE     one commit
```

No implementation commit exists in this ACT. No amend, rebase, force-push, or reset+recommit.

**Recon tooling constraints:**

The ACT prefers existing tools (`grep`, `find`, `git grep`, `nm`, existing repository quality tools, existing PolyC inspection tools).

If substantive new automation is required, it must be PolyC:

```text
tools/quality/selfhost-surface-recon.HC  (or equivalent)
```

Shell is permitted only as ≤50 LOC dispatch/orchestration.

Forbidden:

```text
new Python recon implementation
large shell analyzer
awk/sed as the semantic classifier
```

F-POLYC-TOOLS applies. F-NO-PYTHON delta semantics:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_VIOLATIONS=0
```

**Evidence namespace:**

```text
evidence/ACT-POLYC-SELFHOST-SURFACE-RECON02/
```

`LEXER01/02/03` evidence is F14-protected and must not be mutated.

**HALT taxonomy (full list, see §30 of this ACT):**

```text
HALT_ENTRY_DIRTY
HALT_PREDECESSOR_BASELINE_DRIFT
HALT_SURFACE_AUTHORITY_UNKNOWN
HALT_STAGE_OWNERSHIP_UNKNOWN
HALT_NO_ATOMIC_SELFHOST_TARGET
HALT_SELECTED_TARGET_NOT_FALSIFIABLE
HALT_RANKING_NOT_MECHANICAL
HALT_RECON_FALSE_NEGATIVE
HALT_RECON_CHANGED_COMPILER_BEHAVIOR
HALT_SCOPE_EXPANSION_REQUIRED
HALT_SELFHOST_FRONTIER_COMPLETE
HALT_FACTORY_GATE_REGRESSION
```

Every HALT records `HALT_CLASS`, `BLOCKS_NEXT`, `OBSERVED`, `EXPECTED`, `EVIDENCE`, `RECOMMENDED_NEXT`.
