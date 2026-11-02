# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 — CLOSE

VERDICT

PASS_FINDINGS_WITH_REMAINDER

The audit was performed properly and its machinery is sound. The
AUDITED CLAIM does not hold: **PolyC does NOT own the WP-001
compiler-driver boundary.** Two decisive C branches — `main()`'s
action dispatch and `emitFile()`'s output-artifact selection — STILL
SELECT BEHAVIOUR on the WP-001 required route.

The historical terminality evidence is **NOT** confirmed:
`HISTORICAL_ACT_TERMINALITY_CONFIRMED` remains `UNPROVEN`, and the
tracked terminal outcome is a **pre-committed prospective result**,
not an observation.

IDENTITY

ENTRY_HEAD=BOUND_TO_THE_FIRST_COMMIT_OF_THIS_ACT_BY_GIT_QUERY
ENTRY_TREE=BOUND_TO_THE_FIRST_COMMIT_OF_THIS_ACT_BY_GIT_QUERY
FINAL_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
FINAL_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BRANCH=main
WORKTREE_STATUS=CLEAN
GIT_REPLACE_REFS=0

FINDING

**FINDING 1 — THE WP-001 DRIVER BOUNDARY IS NOT OWNED BY POLYC.**

The 32 historical driver rows were classified at BRANCH granularity,
by DECISION OWNER rather than by function ownership:

```text
POLYC_OWNED_DECISION_PROVEN          9
C_MECHANICAL_EXECUTION_PROVEN       12
C_SEMANTIC_RETAINED_WP001             2
DORMANT_OR_UNREACHABLE_PROVEN        9
```

The two `C_SEMANTIC_RETAINED_WP001` rows are `main()` and
`emitFile()`, and BOTH are on the WP-001 required route
(`--install-dir=X -c input.HC -o out.o`). Two LINKED COUNTERFACTUALS
prove it, by re-executing the real production build:

```text
BR_EMITFILE_EMIT_OBJECT   src/main.c:250
  if (args->emit_object) -> if (0 && args->emit_object)
  the artifact type CHANGES from a Mach-O 64-bit OBJECT to a
  Mach-O 64-bit EXECUTABLE

BR_MAIN_PRINT_TOKENS      src/main.c:519
  if (args.print_tokens) -> if (0 && args.print_tokens)
  the token stream DISAPPEARS: 9 stdout lines -> 0
```

Both mutations were COMPILED, LINKED and EXECUTED; the source was
restored and the restoration was proven by digest
(`baseline_digest == restored_digest`) and by a BYTE_IDENTICAL
rebuild of the production binary.

**THE ROUTE-SCOPED AND GLOBAL C-SEMANTIC REMAINDERS ARE COUNTED
SEPARATELY AND BOTH ARE 2.** Neither is asserted to be zero.

**FINDING 2 — THE HISTORICAL TERMINALITY EVIDENCE IS NOT CONFIRMED.**

```text
HISTORICAL_TRACKED_OUTCOME_PROVENANCE  PRECOMMITTED_PROSPECTIVE_RESULT
ORIGINAL_EXTERNAL_RECEIPT              VERIFIED
FRESH_EXTERNAL_REPLAY                  NOT_RUN
HISTORICAL_ACT_TERMINALITY_CONFIRMED   UNPROVEN
```

The tracked terminal outcome was committed BEFORE the probe ran, so it
is a **prospective result that was pre-committed**, not an
observation. The original receipt exists and binds to the correction's
terminal state, but its TIMESTAMP is not topology-backed: historical
execution timing is NOT provable from the current evidence and remains
`UNPROVEN`.

**FINDING 3 — THE WP-001 ACT FAMILY COST IS FIVE, NOT TWO.**

```text
WP001_ALL_ACTS_CONSUMED           5
WP001_IMPLEMENTATION_ACTS         1
WP001_TECHNICAL_CORRECTION_ACTS   1
WP001_GOVERNANCE_CORRECTION_ACTS  3
```

The ROADMAP's `WP001_ACT_COST_MEASURED = 2` understates the family
cost. The five-ACT count is recomputed from the actual commits.

**FINDING 4 — SIX OF THE FROZEN NEGATIVE CONTROLS WERE NEVER
IMPLEMENTED.**

The Q0 frozen roster names 24 controls. Six of their expected reason
tokens had never been implemented in either detector:
`CORRECTION_CLOSE_IDENTITY_WRONG`, `NON_ACT_TRAILER_PROMOTED`,
`HISTORICAL_CLOSE_DUPLICATE_HIDDEN`,
`MUTATION_LINK_PROVENANCE_MISSING`, `G0_DRIVER_CONTAMINATED` and
`COMPILER_SEMANTIC_COMPARATOR_INSENSITIVE`. The gap was closed in the
VERIFIER; the frozen roster was NOT edited. Disclosed.

RED

The five executable REDs fire against a COMPILED PolyC detector, with
an INDEPENDENT POSIX witness that agrees on all five verdicts. The
audit inputs were FROZEN at Q0, before any compiled verifier existed,
so the later phases could not tune their expectations to fit a result.

IMPLEMENTATION

NO PRODUCTION IMPLEMENTATION. This ACT changes no production file, no
gate, no script and no test. Its only tool additions are the two
authorised PolyC audit tools under `tools/quality/`.

Its path is:

```text
Q0 RED        the inputs are FROZEN and the FIVE REDs fire
Q1 EVIDENCE   the ownership contract is frozen and the 32-row
              attribution is measured, with TWO LINKED COUNTERFACTUALS
Q2 IMPL       the COMPILED PolyC verifier exists, its TWENTY
              anti-selftests fire, and an INDEPENDENT POSIX/Git
              witness agrees
Q3 EVIDENCE   the NC01..NC24 controls, the acceptance ledger, the
              baselines and the gates are discharged
Q4 CLOSE      the terminality PLAN is committed and the single
              terminal close is made
```

GATES

```text
COMMIT_MSG_VALIDATOR      PASS (3 commits, 0 invalid)
FACTORY_V2_RANGE          the close is the LAST commit carrying the id
NO_ACT_ID_COMMIT_AFTER_CLOSE  the plan commits NO post-close success
CLOSURE_STATUS            PASS
GATE_FAST                 PASS (5 checks)
GATE_PUSH                 PASS (rc=0, against the exact committed tree)
APPEND_ONLY               PASS (11 of 11)
```

```text
ADVERSE_CONTROLS_FIRED        24 of 24
ANTI_SELFTESTS_FIRED          20 of 20, each with its EXACT token
INDEPENDENT_WITNESS_MATCH     44 of 44
INDEPENDENT_RECOMPUTATION     10 of 10 agreements, 0 disagreements
CONSERVATION_MISMATCHES        0
ACCEPTANCE_LEDGER             46 PASS, 0 FAIL, 5 DEFERRED
```

SCOPE

```text
FILES_CHANGED=docs/acts/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md
  docs/factory/act-handoff-map.tsv
  docs/ROADMAP.md
  evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/**
  tools/quality/driver-boundary-qualification01-red.HC
  tools/quality/driver-boundary-qualification01-verify.HC
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
TESTS_MODIFIED=NO
SCRIPTS_MODIFIED=NO
GATES_MODIFIED=NO
COMMITTED_EVIDENCE_MODIFIED=NO
HISTORY_REWRITTEN=NO
```

THE Q1 EVIDENCE FILE WAS RESTORED FORWARD. The Q1 file
`q1/32-row-current-classification-contract.tsv` was committed WITHOUT
its descriptive comment block and WITHOUT its column-header row. Its 32
DATA rows were never affected and are byte-identical. The defect is
disclosed in `q2/q1-header-restoration-record.md` and the header was
restored by a FORWARD Q2 commit. The Q1 commit was NOT rewritten
(F14 and the append-only invariant).

RESIDUE

```text
P0=NONE
P1=THE WP-001 DRIVER MIGRATION'S HISTORIC SUCCESS CLAIM IS NOT
  SUPPORTED BY THE MEASURED BOUNDARY. The ROADMAP's
  `WP001_DRIVER_MIGRATION = ACHIEVED` records the MIGRATION ACT's own
  verdict. This audit does NOT overwrite it: the historic status and
  the audit's verdict are recorded SEPARATELY. The REMAINDER is
  explicit and bounded: 2 C-semantic decisions on the required route,
  2 C-semantic decisions globally, 9 PolyC-owned decisions, 12
  C-mechanical rows, 9 dormant rows.
P1=THE HISTORICAL ACT TERMINALITY REMAINS UNPROVEN. The tracked
  outcome was pre-committed and the original receipt's timestamp is
  not topology-backed. A FRESH external replay has NOT been run. This
  ACT does NOT convert it into a PASS.
P1=THE WP-001 FAMILY COST IS FIVE ACTS, NOT TWO. The ROADMAP's
  `WP001_ACT_COST_MEASURED = 2` understates it. Disclosed; the
  historic value is not rewritten.
P1=SIX OF THE FROZEN NEGATIVE CONTROLS WERE NEVER IMPLEMENTED before
  this ACT. The gap is closed in the verifier and disclosed; the
  frozen roster was not edited.
P1=THE ACT DOCUMENT FOR THIS ACT WAS COMMITTED AT Q2, AFTER the Q0
  and Q1 commits had already been made. Under Factory v2 the ACT
  document owns the authorization. The Q0 and Q1 commits therefore
  preceded their own authorization document. This is disclosed here
  rather than worked around; the document is committed and the phase
  path is intact.
P2=NONE
```

NEXT_ACT

A successor ACT MAY migrate the two remaining C-semantic decisions —
`main()`'s action dispatch and `emitFile()`'s output-artifact
selection — to the PolyC driver. This ACT confers NO authority on it;
it only records what the measurement shows and what the next ACT
would have to change.

A successor ACT MAY also execute a FRESH external terminality replay
against a path whose timing is topology-backed, and record its
outcome by an ORDINARY commit with no ACT trailer.

The six negative controls that this ACT implemented in the verifier
SHOULD be back-ported into the Q0 RED detector, so that the two
detectors carry the same roster of controls.
