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
