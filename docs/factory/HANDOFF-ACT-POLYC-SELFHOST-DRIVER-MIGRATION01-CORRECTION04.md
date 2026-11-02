# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04 — CLOSE

VERDICT

PASS

A **terminally sound** Factory-v2 phase path exists for the WP-001
driver migration: the ACT id appears on exactly the phase commits,
the terminal close is the last commit carrying it, and nothing after
it carries it.

IDENTITY
ENTRY_HEAD=BOUND_TO_THE_FIRST_COMMIT_OF_THIS_ACT_BY_GIT_QUERY
ENTRY_TREE=BOUND_TO_THE_FIRST_COMMIT_OF_THIS_ACT_BY_GIT_QUERY
FINAL_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
FINAL_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BRANCH=main
WORKTREE_STATUS=CLEAN
GIT_REPLACE_REFS=0

FINDING

THREE defects with ONE root cause.

1. THE PARENT'S PATH IS DUPLICATED. Its contract requires exactly
   five distinct linear commits and "the unique fifth CLOSE commit".
   The measured path carries THREE `C4` labels and TWO
   `ACT-Phase: CLOSE` commits.

2. THE PARENT'S C1, C2 AND C3 CARRY NO `ACT:` TRAILER. They put the
   ACT identity in the subject line only, so the canonical
   commit-message validator classified them as `MODE=NON_ACT`.

3. THE SAME DUPLICATE-CLOSE DEFECT WAS REPRODUCED INSIDE
   `CORRECTION03` BY THE AGENT THAT WAS CORRECTING IT.
   `CORRECTION03` committed its own terminal close, then recorded the
   re-executed receipt's outcome in a further commit, then committed a
   further close. Its range therefore contains two CLOSEs, and the
   canonical validator reports
   `REASON=expected exactly 1 CLOSE commit in range, found 2`.

THE ROOT CAUSE. The canonical range validator enforces rule 4
(exactly one `ACT-Phase: CLOSE`, and it is the last commit of the
range) and rule 6 (no commit descending from the CLOSE may carry
`ACT:<id>`). A receipt that must be recorded AFTER the close can
therefore neither carry the ACT id nor be recorded before the close
without making the close premature.

THE RESOLUTION IS STRUCTURAL, NOT PROCEDURAL: the ACT's path ends at
its terminal close; the close is the last commit carrying the ACT id;
and everything after it is an ordinary commit with no ACT trailer at
all. This ACT is built to that shape from the start.

RED

The three defects and their root cause were MEASURED from the git
object history, not asserted. The measurements are in
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04/c0/`
and the derived structural rule is in
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04/c1/`.

IMPLEMENTATION

NO PRODUCTION IMPLEMENTATION. This ACT changes no production file,
no gate, no script and no test.

Its path is:

```text
S0 RED        the three defects and the root cause, measured
S1 EVIDENCE   the structural rule, derived from the canonical validator
S2 IMPL       the parent's acceptance ledger discharge and the handoff
S3 EVIDENCE   the conservation measurement and the gate results
S4 CLOSE      the single terminal close
```

GATES

COMMIT_MSG_VALIDATOR=PASS (MODE=ACT on every commit of this ACT)
FACTORY_V2_RANGE=PASS (this ACT's own range; exactly one CLOSE)
NO_ACT_ID_COMMIT_AFTER_THE_CLOSE=PASS
CLOSURE_STATUS=PASS (66 of 66)
GATE_FAST=PASS
APPEND_ONLY=PASS (11 of 11)

SCOPE

FILES_CHANGED=docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04.md
  docs/factory/act-handoff-map.tsv
  docs/ROADMAP.md
  evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04/**
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
TESTS_MODIFIED=NO
SCRIPTS_MODIFIED=NO
GATES_MODIFIED=NO
COMMITTED_EVIDENCE_MODIFIED=NO
PARENT_PRODUCTION_DELTA_CHANGED=NO
HISTORY_REWRITTEN=NO

RESIDUE

P0=NONE
P1=THE PARENT ACT'S ORIGINAL COMMITTED PATH REMAINS DUPLICATED:
  THREE `C4` labels and TWO terminal CLOSEs where the contract
  requires one. IRREPARABLE under the append-only invariant. Disclosed
  in the parent's handoff, in the ROADMAP and in this ACT's evidence.
P1=THE PARENT ACT'S C1, C2 AND C3 COMMITS REMAIN TRAILER-LESS.
  IRREPARABLE. Disclosed. Measured by CORRECTION02.
P1=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03's PATH REMAINS
  DUPLICATED, carrying TWO `ACT-Phase: CLOSE` commits, because that
  ACT reproduced the defect it was correcting. IRREPARABLE. Disclosed.
  Its own handoff and the ROADMAP record it.
P2=NONE

NEXT_ACT

The external read-only terminality receipt produced against this
ACT's terminal close is the terminal artifact. It lives OUTSIDE the
repository and is never backdated.
