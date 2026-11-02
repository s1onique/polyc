# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01 — CLOSE

VERDICT

PASS

This correction corrected ONE row of the parent ACT's committed C1
contract and completed ONE production change the parent ACT already
required. Both defects were found BY EXECUTION at the parent ACT's C3
phase, and both are now corrected and MEASURED.

IDENTITY
BRANCH=main
WORKTREE_STATUS=CLEAN
GIT_REPLACE_REFS=0

RED
THE DEFECT WAS FOUND BY EXECUTION, NOT INFERRED. The parent ACT's C1
M3 row named this construct as the status-propagation target:

  if (action == WP_ACTION_NONE) {
    if (WpDriverUnknownArgCount() > 0) return WP_STATUS_USAGE;
    return WP_STATUS_NO_INPUT;
  }

The row's stated MUTATION INTENT was correct -- "force the NO_INPUT
status for an argv that holds an UNKNOWN argument" -- but the named
CONSTRUCT is not reached for such an argv, because the
unknown-argument status is produced EARLIER, by the check that runs
before the action mapping:

  if (WpDriverHasUnknownArgument() == 1) return WP_STATUS_USAGE;

Applying the mutation to the named construct produced ZERO changed
cases over the frozen fourteen-case corpus. A DECORATIVE mutation
target is exactly what the parent ACT forbids: "A PolyC driver that
merely returns a fixed exit status cannot PASS."

THE SAME EXECUTION FINDING SHOWED A SECOND DEFECT. The M2 mutation
target -- the action mapping for the emit-object options -- was also
not observable, because the parent ACT's C2 implementation mapped
those options to the emit-object CliArgs field DIRECTLY, without going
through the action. The action was computed but never consulted, so
site (b) was decorative as well. The parent ACT explicitly requires
the three sites to be load-bearing, so this was an INCOMPLETE
IMPLEMENTATION of the parent ACT and not a new feature.

IMPLEMENTATION
THE CORRECTED M3 TARGET is the status propagation
`if (WpDriverHasUnknownArgument() == 1) return WP_STATUS_USAGE;` in
WpDriverMapStatus, which IS on the causal path.

THE PRODUCTION CHANGE IS CONFINED TO THE DRIVER SUBJECT.
WpDriverOptionField no longer names the emit-object field directly
for the compile-object options; it DERIVES the field from the action
through the new WpDriverFieldForAction, so that a mutation of the
action mapping changes the field and therefore the retained C
compilation engine's behaviour. The change touches
tools/bootstrap/selfhost-driver-wp001.HC ONLY. The C side is NOT
touched and still contains no option table, no option name, no arity
rule and no action choice.

THE PARENT ACT'S COMMITTED C1 EVIDENCE IS NOT EDITED (F14). The
correction and its measured justification live in this ACT's own
evidence directory.

GATES
BUILD=PASS
TARGETED=PASS (all three mutations are load-bearing)
UNIT=PASS
JIT=PASS
LSP=PASS
DIFF_CHECK=PASS

SCOPE
FILES_CHANGED=tools/bootstrap/selfhost-driver-wp001.HC
  docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01.md
  evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01/**
DIFF_CHECK=PASS
PRODUCTION_SEMANTICS_CHANGED=YES (the action dispatch became
  load-bearing, which the parent ACT requires)
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO
TESTS_MODIFIED=NO
SCRIPTS_MODIFIED=NO
GATES_MODIFIED=NO
OTHER_COMPILER_SUBSYSTEMS_MODIFIED=NO

RESIDUE
P0=NONE
P1=NONE
P2=NONE

NEXT_ACT=NONE PROPOSED BY THIS ACT. THE PARENT ACT CONTINUES WITH THE
  CORRECTED CONTRACT.

# ---------------------------------------------------------------------------
# THE MEASURED RESULTS
# ---------------------------------------------------------------------------
ACT_ID=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01
PARENT_ACT=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
PARENT_C1_M3_CONSTRUCT_ON_CAUSAL_PATH=NO
CORRECTED_M3_CONSTRUCT_ON_CAUSAL_PATH=YES
PARENT_C2_ACTION_DISPATCH_LOAD_BEARING=NO
CORRECTED_C2_ACTION_DISPATCH_LOAD_BEARING=YES
M1_CHANGED_CASES=8
M2_CHANGED_CASES=4
M3_CHANGED_CASES=3
M1_M2_M3_PAIRWISE_DISTINCT=YES
DECORATIVE_SITE_REMAINS=NONE
CHANGED_BYTES_CONFINED_TO_ONE_LINE_EACH=YES
M1_ENCLOSING_FUNCTION=WpDriverOptMatches
M2_ENCLOSING_FUNCTION=WpDriverOptionAction
M3_ENCLOSING_FUNCTION=WpDriverMapStatus
THREE_DISTINCT_DECISION_GROUPS=YES
PARENT_CORPUS_DIFFERENTIAL=STILL GREEN (13 of 14 exact, the one
  ENVIRONMENT_EXPLAINED commit-hash line)
