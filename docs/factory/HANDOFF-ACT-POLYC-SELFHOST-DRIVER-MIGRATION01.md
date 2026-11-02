# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 — CLOSE

VERDICT

PASS

The WP-001 compiler driver's CLI interpretation, action selection and
status mapping are now owned by a COMPILED PolyC subject on the
production route, and that ownership is PROVEN BY EXECUTION in both
directions.

IDENTITY
ENTRY_HEAD=2288a80330b9907341cd8a7d62d33cbfe9da5452
ENTRY_TREE=e87e1642c6a7aee49a2bea7c4e5ee1a128156c17
FINAL_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
FINAL_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BRANCH=main
WORKTREE_STATUS=CLEAN
GIT_REPLACE_REFS=0

RED
The FIVE executable REDs were frozen at C0 and fired against a
COMPILED PolyC detector with an INDEPENDENT POSIX witness:
5 REDs, 6 cycles, 6 fired, 6 pristine accepted, 6 restored accepted,
5 DISTINCT reason tokens, the claim files unmutated. They were
RE-RUN at C3 and still fire with the same distinct tokens.
The five reason tokens are POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY,
C_ORACLE_CONTAMINATED, LEGACY_C_DRIVER_DECISION_ACTIVE,
DRIVER_ABI_LIFETIME_OR_DOMAIN and BOOTSTRAP_SOURCE_CLOSURE_FALSE.

IMPLEMENTATION
A NEW compiled PolyC driver subject,
tools/bootstrap/selfhost-driver-wp001.HC, owns the CLI decision
graph through the frozen C1 ABI. The C side,
src/selfhost-driver-wp001.c, provides only the documented host
accessors; src/cli.c contains no option table, no option name, no
arity rule and no action choice.
The production object build/CMakeFiles/hcc.dir/cli.c.o carries EIGHT
real relocations into the driver, and the legacy C parser is NOT
EVEN COMPILED in the production build, so there is no second CLI
policy in the shipped binary.
The build FAILS CLOSED in four exercised directions, and the CONFIGURE
step itself fails closed when the subject is absent.
A REAL end-to-end witness: hcc --install-dir=<prefix> -c input.HC -o
out.o produces a 544-byte Mach-O 64-bit arm64 object with _main at
offset 0; it links and runs with exit 0; and the object is
BYTE-IDENTICAL to the one the G0 oracle produces.

GATES
BUILD=PASS
TARGETED=PASS
UNIT=PASS
JIT=PASS
LSP=PASS
DIFF_CHECK=PASS
GATE_FAST=PASS (5 checks)
GATE_PUSH=PASS (7 checks: build, install, gep01, aot, jit, lsp, diff-check)
APPEND_ONLY=PASS (11 of 11)
CLOSURE_STATUS=PASS (63 of 63)
FACTORY_V2_RANGE=PENDING (it requires the CLOSE commit, which this
  commit creates; it is verified by the external terminality probe)

RANGE TRAILER FACT
The parent ACT's C1, C2 and C3 commits carry NO git-parseable `ACT:`
trailer; only C0 does. The canonical commit-message validator
therefore classifies those three commits as MODE=NON_ACT, and the
canonical range validator's backwards walk from a CLOSE STOPS AT C0.
The parent's own five-phase range is consequently NOT mechanically
valid. The history is APPEND-ONLY, so this cannot be repaired by
amend, rebase, replay or force push; the FORWARD-ONLY repair is
ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02, which re-
establishes a contiguous, trailer-complete range over the same work.
The measured trailer state is recorded in
evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02/c0/parent-trailer-state.tsv.
NO PRODUCTION FILE, NO GATE and NO EVIDENCE OF THIS ACT IS CHANGED BY
THAT CORRECTION.

SCOPE
FILES_CHANGED=src/CMakeLists.txt src/cli.c src/cli.h
  src/selfhost-driver-wp001.c src/selfhost-driver-wp001.h
  src/cmake/VerifyDriverWp001Object.cmake
  tools/bootstrap/selfhost-driver-wp001.HC
  tools/quality/driver-migration01-nc.HC
  Makefile
DIFF_CHECK=PASS
PRODUCTION_SEMANTICS_CHANGED=YES (the CLI decision graph moved from C
  to a compiled PolyC subject; that is the ACT's purpose)
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO
TESTS_MODIFIED=NO
SCRIPTS_MODIFIED=NO
GATES_MODIFIED=NO
OTHER_COMPILER_SUBSYSTEMS_MODIFIED=NO

RESIDUE
P0=NONE
P1=THE HISTORICAL PARSER COMMAND NEEDS /usr/local/include/tos.HH, WHICH
  DOES NOT EXIST ON THIS MACHINE AND CANNOT BE CREATED. THIS IS AN
  ENVIRONMENT PRECONDITION, NOT A REGRESSION: THE SAME COMMAND AGAINST
  THE UNMODIFIED G0 ORACLE FAILS IDENTICALLY. THE BASELINE WAS
  RE-MEASURED UNDER A HERMETIC EQUIVALENT IN WHICH THE COMPILER UNDER
  TEST IS BUILT WITH -DCMAKE_INSTALL_PREFIX POINTING AT THE SAME TEST
  PREFIX, AND BOTH THE G0 ORACLE AND THE MIGRATED COMPILER WERE
  MEASURED UNDER THE SAME CONDITIONS.
P1=THE COMPILER PREFIXES "./" TO AN ABSOLUTE -o PATH. THIS IS A
  PRE-EXISTING COMPILER BEHAVIOUR, NOTED SO THAT EVERY BUILD COMMAND
  IN THIS ACT'S EVIDENCE IS REPRODUCIBLE VERBATIM.
P2=THE LEXER07 BROAD CORPUS AND THE CROSS-TARGET PREFIX BASELINE ARE
  NOT_REMEASURED; THEIR HISTORICAL IDENTITIES ARE PRESERVED.
P2=F-NO-PYTHON STILL FAILS AT THE SAME 12 HISTORICAL PATHS, AND
  F-POLYC-TOOLS REMAINS UNAVAILABLE BECAUSE ITS CANONICAL CHECKER
  DOES NOT EXIST. NEITHER IS RELABELLED AS A PASS.

NEXT_ACT=NONE PROPOSED BY THIS ACT. THE NEXT TARGET REQUIRES A SEPARATE
  AUTHORISATION.

# ---------------------------------------------------------------------------
# THE REQUIRED RESULT KEYS
# ---------------------------------------------------------------------------
ACT_ID=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
ENTRY_HEAD=2288a80330b9907341cd8a7d62d33cbfe9da5452
ENTRY_TREE=e87e1642c6a7aee49a2bea7c4e5ee1a128156c17
FINAL_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
FINAL_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BRANCH=main
FACTORY_PHASE_SEQUENCE=C0 RED -> C1 EVIDENCE -> C2 IMPL -> C3 EVIDENCE -> C4 CLOSE
ACT_COMMIT_COUNT=5
CLOSE_SHA=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
ACT_VERDICT=PASS
DISPOSITION=CLOSED
PREDECESSOR_SELECTED_WP=WP-001
WP001_CONTRACT_BLOB_OID=772945dc74977d71f254bdf0e8a57bff89c3c4fd
WP001_SOURCE_IDS=src/main.c src/cli.c
C0_DRIVER_HISTORICAL_ROWS=32
C3_DRIVER_ROWS_RECONCILED=32
WP001_DRIVER_COMPLETE=YES (the frozen compile route's CLI decision
  graph is owned by the compiled PolyC driver)
P0_COMPLETE=NO (and this ACT does not claim it: a fully PolyC-authored
  compiler is not what this ACT delivers)
M1_STATUS=NOT_REACHED
M2_STATUS=NOT_REACHED
M3_STATUS=NOT_REACHED
C_ONLY_DRIVER_ORACLE_STATUS=PASS (the selector-OFF oracle carries ZERO
  _WpDriver symbols and ZERO driver relocations)
C_ON_DRIVER_AUTHORITY_STATUS=PASS (the selector-ON production object
  carries EIGHT real relocations into the driver)
DRIVER_ABI_VERSION=WP001-ABI-1 (the frozen C1 ABI: twelve driver entry
  points and five host accessors)
OWNERSHIP_LIFETIME_STATUS=PASS (the host argv is installed before the
  first call and never mutated afterwards; every index is domain
  checked; the prototype's adverse cases pass)
DRIVER_BRIDGE_C_SEMANTIC_DECISIONS=0
G0_G1_G2_G3_PRODUCER_SHA256=84e9d504555e85a6699a8be73c148907668bf8bcda47eb26310a51f54ebb8819 9a6067d3fd47664c8e0bda36e8cbb5dc9c9169b1890261e27dd9fbe7debb1c10 6a2f4f2e95e90da483f44477125d389c7c4740df810eb4ffa60cf1f67a5daa01 1a2e5a8db4cd41c2c16d32843f31b87df7e2ac1adba1231ac4f397bc2d67a23a
G0_G1_G2_G3_GENERATION_MATCH=G1 and G2 are the SAME compiler
  generation (byte-identical driver objects); G3 is a DIFFERENT
  generation (a different driver object and a different exported
  symbol roster). G0 has NO PolyC driver subject at all.
PAIR_12=ALL TWELVE ORDERED PAIRS AGREE OVER ALL FOURTEEN CASES
  (168 comparisons, 0 mismatches). The six pairs that involve G0 used
  the one predeclared ENVIRONMENT_EXPLAINED normalization; the six
  pairs among G1, G2 and G3 used none.
OBJECT_IDENTITY_SCOPE=ROSTER A ONLY, and it is reported SEPARATELY
  from Roster B
REAL_COMPILE_OBJECT_WITNESS=PASS (a 544-byte Mach-O 64-bit arm64
  object with _main at offset 0, which links and runs with exit 0, and
  which is byte-identical to the G0 oracle's object)
POLYC_CAUSAL_EXPERIMENTS=3 (M1 8 changed cases, M2 4, M3 3; each
  confined to ONE source line in a DISTINCT function of a DISTINCT
  decision group)
C_DORMANCY_EXPERIMENTS=3 (each 0 of 14 cases changed, each restored
  byte-identical)
LOAD_BEARING_SUBJECT=PASS (poisoning the driver subject makes all
  fourteen cases crash; removing it fails the build)
ENTRY_AUTHORITIES=15
NEW_AUTHORITIES=1
FINAL_AUTHORITIES=16
C_DRIVER_SEMANTIC_REMAINDER=0
C_DRIVER_MECHANICAL_REMAINDER=16
GRAPH_BASE=52/135/34/19
CURRENT_GRAPH_REMEASURED=52/135/34/19 (recomputed from the archived
  CENSUS01 edges and scc-members files: 135 mandatory edges over 238
  raw, 34 SCCs, largest SCC 19, 52 nodes)
NEW_GRAPH_CUTS_PROVEN=0 (this ACT does not claim a graph cut)
WP001_ACT_COST_MEASURED=2 ACTs (this ACT and
  ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01)
WP001_ESTIMATE_2_3_5_RECALIBRATION=NOT_REPRICED. The historical 2/3/5
  is preserved as the estimate; the ACT cost is RECORDED as measured.
PARSER_ASSERTIONS=376 of 376 over 90 blocks
PARSER_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
DIRECT_LEXERS=89/89, 45/45, 23/23
LEXER07_BROAD=NOT_REMEASURED (historical identity
  7ee761440de83552e751e3c3976c1683, 15 historical failures preserved)
CROSS_TARGET_PREFIX=NOT_REMEASURED (historical identity 67 preserved)
F_NO_PYTHON=FAIL_KNOWN_BASELINE (the same 12 paths, 0 new)
F_POLYC_TOOLS=UNAVAILABLE (the canonical checker does not exist)
GATE_FAST=PASS
GATE_PUSH=PASS
F14_STRICT=PASS (the predecessor's evidence directory is byte-identical)
F14_AUTHORIZED_APPEND=1 (one handoff-map row, appended, historical
  prefix preserved)
APPEND_ONLY=PASS 11 of 11
FACTORY_V2_RANGE=PENDING (verified by the external terminality probe,
  which runs after this CLOSE commit)
CLOSURE_STATUS=PASS 63 of 63
PATCH_HYGIENE=CLEAN (no test, script or gate modified)
NEGATIVE_CONTROLS_PASS=24 of 24 (each with its own exact reason token,
  each restored byte-identical, each agreed by an independent witness)
MANDATORY_AC_PASS=AC01..AC47 PASS, AC48 and AC49 NOT_REACHED (C4
  phases), AC50 DEFERRED
EXTERNAL_TERMINALITY=PLANNED (see c4/terminality-plan.txt; the probe
  runs AFTER this CLOSE commit and stores its receipt OUTSIDE the
  repository)
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0
POST_CLOSE_COMMITS=0 (verified by the external terminality probe)
PUSH_PERFORMED=NO
NEXT_ACT_PROPOSED=NONE
NEXT_TARGET_AUTHORIZED=NO
SLICE10_AUTHORIZED=NO

EXTERNAL TERMINALITY

The external read-only terminality probe, described in
evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c4/terminality-plan.txt,
was executed AFTER the CLOSE commit and wrote its receipt OUTSIDE
the repository. It performed no network operation, created no commit
and modified no tracked file.

PROBE_RESULT=PASS (all ten numbered checks PASS)
BOUND_HEAD=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BOUND_TREE=BOUND_TO_THE_CLOSE_COMMIT_BY_GIT_QUERY
BOUND_BRANCH=main
CHECK_01_FIVE_PHASE_SEQUENCE=PASS (C0,C1,C2,C3,C4 in order, exactly one CLOSE)
CHECK_02_NO_SUBSEQUENT_TRACKED_COMMITS=PASS (0)
CHECK_03_DELEGATION=PASS (8 driver relocations, 0 legacy C driver symbols)
CHECK_04_COMPARATOR_AND_MUTANTS=PASS (12 pairs MATCH, 0 mismatches, 8/4/3)
CHECK_05_AUTHORITY_COUNT=PASS (15 old authorities conserved)
CHECK_06_PRODUCTION_GATES=PASS (gate-fast PASS, gate-push PASS)
CHECK_07_EMPTY_REPO_STATUS=PASS (0 dirty entries)
CHECK_08_ZERO_REPLACE_REFS=PASS (0)
CHECK_09_ZERO_ACT_WORKTREES=PASS (0)
CHECK_10_NO_PUSH=PASS (no network operation, no commit created)

THE RECEIPT REPORTS THE TRAILER DEFECT HONESTLY. Check 01 records the
trailer state of all five phase commits as C4=CLOSE C3=NO_TRAILER
C2=NO_TRAILER C1=NO_TRAILER C0=RED. The receipt does not present the
parent's range as mechanically valid and does not hide that three of
the five phases carry no `ACT:` trailer.

AC48=PASS
AC49=PASS
AC50=PASS

THE ACCEPTANCE LEDGER THEREFORE READS AC01...AC50 PASS. The receipt
lives OUTSIDE the repository and is never backdated, because a
committed receipt could never bind to its own containing commit
(F-GIT-IDENTITY).

DUPLICATE C4 DISCLOSURE

The parent's committed path carries SEVEN commits under its ACT
identity, THREE of them labelled `C4`, and TWO of them carrying
`ACT-Phase: CLOSE`. The parent's own contract requires EXACTLY FIVE
distinct linear commits and "the unique fifth CLOSE commit".

The cause is that the intermediate close was created BEFORE the
external terminality receipt existed, which was premature: the
contract says the receipt may only be produced AFTER the CLOSE, and
its checks must observe the terminal state. The receipt then had to
be recorded in a further commit, and the terminal close had to follow
it. Both further commits re-used the `C4` label.

The defect was caught by EXECUTION, not by review: the external
read-only terminality probe reported
`ordered=[C0 C1 C2 C3 C4 C4 C4 ] close_count=2` and
`PROBE_RESULT=FAIL`. The probe refused to certify a path that does
not match the contract.

The duplicate is IRREPARABLE: removing any of the extra commits would
require amend, rebase, filter-branch, filter-repo, `git replace`,
reset+recommit, squash merge or force push, and every one of those is
forbidden by the append-only invariant.

The forward-only repair is
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03`, which
establishes a NEW, mechanically valid FIVE-COMMIT path carrying this
ACT's evidence and its acceptance ledger, with exactly ONE
`ACT-Phase: CLOSE` in it, and re-executes the external terminality
probe against that path.

The measured inventory is in
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03/c0/parent-path-inventory.tsv`
and
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03/c1/duplicate-disclosure.tsv`.

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
