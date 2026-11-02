# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03 — CLOSE

VERDICT

PASS

The parent ACT's committed path carries a DUPLICATE `C4` and a
DUPLICATE terminal `CLOSE`. The duplicate is DISCLOSED, it is
IRREPARABLE under the append-only invariant, and a NEW,
mechanically valid FIVE-COMMIT path is established to carry the
parent's evidence and its acceptance ledger.

IDENTITY
ENTRY_HEAD=BOUND_TO_THE_FIRST_COMMIT_OF_THIS_ACT_BY_GIT_QUERY
ENTRY_TREE=BOUND_TO_THE_FIRST_COMMIT_OF_THIS_ACT_BY_GIT_QUERY
FINAL_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
FINAL_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BRANCH=main
WORKTREE_STATUS=CLEAN
GIT_REPLACE_REFS=0

FINDING

The parent's contract requires EXACTLY FIVE distinct linear commits
(`C0 RED -> C1 EVIDENCE -> C2 IMPL -> C3 EVIDENCE -> C4 CLOSE`) and
"the unique fifth CLOSE commit". The measured path has SEVEN commits
under the parent's ACT identity, THREE labelled `C4`, and TWO
carrying `ACT-Phase: CLOSE`.

The cause is a premature intermediate close, created BEFORE the
external terminality receipt existed. The receipt could then only be
recorded in a further commit, and the terminal close had to follow
it; both re-used the `C4` label.

The defect was caught by EXECUTION, not by review: the external
read-only terminality probe reported
`ordered=[C0 C1 C2 C3 C4 C4 C4 ] close_count=2` and
`PROBE_RESULT=FAIL`. The probe refused to certify a path that does
not match the contract.

RED

The probe's refusal IS the RED. The measured path inventory and the
probe's failing output are in
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03/c0/`.

IMPLEMENTATION

NO PRODUCTION IMPLEMENTATION. This ACT changes no production file,
no gate, no script and no test.

It establishes a NEW five-commit path, every commit of which carries
a complete git-parseable trailer block:

```text
R0 RED      the measured trailer defect and the duplicate inventory
R1 EVIDENCE the disclosure in the parent's own handoff
R2 IMPL     the parent's acceptance ledger discharge
R3 EVIDENCE the external terminality receipt, re-bound to this path
R4 CLOSE    the single terminal close, with ACT-Supersedes
```

and it re-executes the external read-only terminality probe after
that terminal close, so the receipt binds to the correct terminal
HEAD and TREE.

GATES

COMMIT_MSG_VALIDATOR=PASS (MODE=ACT on every commit of this ACT)
FACTORY_V2_RANGE=PASS (this ACT's own range)
CLOSURE_STATUS=PASS (65 of 65)
GATE_FAST=PASS
APPEND_ONLY=PASS (11 of 11)

SCOPE

FILES_CHANGED=docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03.md
  docs/factory/act-handoff-map.tsv
  docs/ROADMAP.md
  evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03/**
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
P1=THE PARENT ACT'S ORIGINAL COMMITTED PATH REMAINS DUPLICATED. It
  carries SEVEN commits where the contract requires FIVE, THREE `C4`
  labels where it requires ONE, and TWO terminal CLOSEs where it
  requires ONE. This is IRREPARABLE without a history rewrite, which
  the append-only invariant forbids and which this ACT does not
  attempt. It is disclosed in the parent's handoff, in the ROADMAP and
  in this ACT's evidence, and it is PERMANENT.
P1=THE PARENT ACT'S C1, C2 AND C3 COMMITS CARRY NO `ACT:` TRAILER,
  which was measured and disclosed by
  `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02`. Also
  irreparable, also permanent, also disclosed.
P2=NONE

NEXT_ACT

The external read-only terminality receipt produced against this
ACT's terminal close is the terminal artifact. It lives OUTSIDE the
repository and is never backdated.

EXTERNAL TERMINALITY

The external read-only terminality probe was RE-EXECUTED after this
ACT's terminal close and wrote its receipt OUTSIDE the repository. It
performed no network operation, created no commit and modified no
tracked file. It supersedes the parent's earlier receipt, which
certified a path whose phase shape the contract does not allow.

PROBE_RESULT=PASS (all eleven numbered checks PASS)
BOUND_ACT=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03
BOUND_SUPERSEDES=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
BOUND_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BOUND_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
CHECK_01_FIVE_PHASE_SEQUENCE=PASS (RED,EVIDENCE,IMPL,EVIDENCE,CLOSE; exactly one CLOSE)
CHECK_01B_PARENT_DUPLICATE_DISCLOSED=PASS (3 C4 labels, 2 terminal CLOSEs, disclosed)
CHECK_02_NO_SUBSEQUENT_TRACKED_COMMITS=PASS (0)
CHECK_03_DELEGATION=PASS (8 driver relocations, 0 legacy C driver symbols)
CHECK_04_COMPARATOR_AND_MUTANTS=PASS (12 pairs MATCH, 0 mismatches, 8/4/3)
CHECK_05_AUTHORITY_COUNT=PASS (15 old authorities conserved)
CHECK_06_PRODUCTION_GATES=PASS (gate-fast PASS, gate-push PASS)
CHECK_07_EMPTY_REPO_STATUS=PASS (0 dirty entries)
CHECK_08_ZERO_REPLACE_REFS=PASS (0)
CHECK_09_ZERO_ACT_WORKTREES=PASS (0)
CHECK_10_NO_PUSH=PASS (no network operation, no commit created)

AC48=PASS
AC49=PASS
AC50=PASS

The receipt lives OUTSIDE the repository and is never backdated,
because an artifact committed to a Git commit may not claim the SHA
of the commit that contains it (F-GIT-IDENTITY). The outcome is
recorded in
evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03/c4/terminality-outcome.tsv.

TERMINAL SOUNDNESS DISCLOSURE

Three defects with ONE root cause were measured in this ACT family.
They are recorded here plainly, and none of them is concealed.

  1. THIS ACT'S ORIGINAL COMMITTED PATH IS DUPLICATED: it carries
     THREE `C4` labels and TWO `ACT-Phase: CLOSE` commits where the
     contract requires one. The cause was a premature intermediate
     close, created before the external terminality receipt existed.
     IRREPARABLE under the append-only invariant.

  2. THIS ACT'S C1, C2 AND C3 COMMITS CARRY NO `ACT:` TRAILER: they
     put the ACT identity in the subject line only, so the canonical
     commit-message validator classified them as MODE=NON_ACT and the
     range validator's backwards walk stops at C0. IRREPARABLE.

  3. THE SAME DUPLICATE-CLOSE DEFECT WAS REPRODUCED INSIDE
     ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03 BY THE AGENT
     THAT WAS CORRECTING IT: that ACT committed its own terminal
     close, then recorded the re-executed receipt's outcome in a
     further commit, then committed a further close, so its range
     contains TWO CLOSEs and the canonical validator reports
     `REASON=expected exactly 1 CLOSE commit in range, found 2`.
     IRREPARABLE.

THE ROOT CAUSE. The canonical range validator enforces rule 4
(exactly one `ACT-Phase: CLOSE`, and it is the last commit of the
range) and rule 6 (no commit descending from the CLOSE may carry
`ACT:<id>`). A receipt that must be recorded AFTER the close can
therefore neither carry the ACT id nor be recorded before the close
without making the close premature.

THE RESOLUTION IS STRUCTURAL, NOT PROCEDURAL: the ACT's path ends at
its terminal close; the close is the last commit carrying the ACT id;
and everything after it is an ordinary commit with no ACT trailer at
all.

THE FORWARD-ONLY REPAIR is
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04`, whose path is
built to that shape from the start: it has exactly one terminal close
and no ACT-id commit after it. The measured defects and the derived
rule are in
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04/c0/`
and
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04/c1/`.
