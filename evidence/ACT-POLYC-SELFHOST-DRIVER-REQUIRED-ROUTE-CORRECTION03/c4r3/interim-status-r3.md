# C4 REMEDIATION ROUND 3 -- INTERIM STATUS

ACT: ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03

This document is the FORWARD-ONLY record of the third remediation round. It
does NOT modify the CORRECTION02 evidence, the CORRECTION03 round-one
evidence, or the CORRECTION03 round-two evidence. The historical documents
remain valid as evidence of what was observed at the time.

## THE TRUST BOUNDARY, STATED HONESTLY

The evidence establishes LOCAL TRACE INTEGRITY. The harness owns the
execution, allocates the event identity, records the actual argv and the
relevant environment, and captures the exact observed bytes before any
comparison. The comparator independently checks the expected run, the case
identity and the producer identity, and it requires the capture record's
event id to be REGISTERED in the run ledger that the harness appends to
during THIS run.

It is NOT a cryptographic attestation against an attacker who can replace
the complete trusted runner and all of its evidence. The run ledger binds
an observation to an execution THAT THIS RUN performed; it cannot bind an
observation to an execution performed by a different program with different
code. The claim is not widened beyond what the mechanism supports.

## THE SEVEN FINDINGS

| Finding | State | Where the observation lives |
|---|---|---|
| F1 -- the event identity was deterministic | ADDRESSED | two deterministic repetitions receive different event ids; `c4r3/forward-only-receipts.tsv` |
| F2 -- the exit codec never reported its reason | ADDRESSED | the presence and the validity of the exit record are DISTINCT facts; the codec's own token is now reported |
| F3 -- the symbol-table check stopped at the first absence | ADDRESSED | the ENTIRE table is checked, and the entries after `_main` are included |
| F4 -- the archive name comparison accepted a prefix | ADDRESSED | EQUAL LENGTHS and EQUAL BYTES are required |
| F5 -- the emission verifier was weaker than the comparator | ADDRESSED | ONE Mach-O validator, ONE exit-status codec, ONE archive decoder |
| F6 -- the runtime archive was published before it was validated | ADDRESSED and EXECUTED | `c4r3/forward-only-receipts.tsv`; the experiment is `INVALID_ARCHIVE -> FIRST_BUILD_FAIL -> RETRY_FAIL` |
| F7 -- the build dependency graph was incomplete | ADDRESSED and EXECUTED | the SEVEN probes of the mutation matrix |

## THE SEVEN P2 FINDINGS

| Finding | State |
|---|---|
| P2-1 -- the subject stamp bound to NO architecture | ADDRESSED: the stamp records `SUBJECT_ARCH ARM64` and the rule REJECTS a value that is not an architecture name |
| P2-2 -- the contract's self-check was NEVER EXECUTED | ADDRESSED: the comparator's `selfcheck` mode executes it and it is a PREREQUISITE of all four CORRECTION03 targets |
| P2-3 -- the "stale stdout" mutation was a NO-OP | ADDRESSED: the witness is physically distinct and the target FAILS if it is not |
| P2-4 -- the ALTERED_CAPTURE probe edited the WRONG field | ADDRESSED: the field is located BY ITS KEY |
| P2-5 -- the alternate archive encoding had NO positive control | ADDRESSED: the self-check builds two encodings and requires them to compare EQUAL |
| P2-6 -- the archive member identity included its NUL padding | ADDRESSED: the padding is trimmed |
| P2-7 -- the runtime-archive rule failed in a PRISTINE checkout | ADDRESSED: the `case` pattern is quoted as ONE word |
| P2-8 -- the pristine runner exceeded the SHELL budget | ADDRESSED: the runner is PolyC and the shell file is REMOVED |

## THE MEASUREMENTS

The shared contract's self-check:

```text
CONTRACT_SELFTEST_CHECKS	20
CONTRACT_SELFTEST_FAILURES	0
```

The eight-case precedence matrix, the emission witness, the causal mutation
and the nineteen adverse controls:

```text
DRIVER_WP001_CORRECTION03_TEST_STATUS=PASS
DRIVER_WP001_CORRECTION03_EMISSION_TEST_STATUS=PASS
DRIVER_WP001_CORRECTION03_CAUSAL_TEST_STATUS=PASS
DRIVER_WP001_CORRECTION03_ADVERSE_TEST_STATUS=PASS
```

The F6 adverse experiment:

```text
F6_PHASE_A=PUBLISHED
F6_PHASE_B=FAILED_AND_NOT_PUBLISHED
F6_PHASE_C=RETRY_FAILED
F6_EXPERIMENT=INVALID_ARCHIVE -> FIRST_BUILD_FAIL -> RETRY_FAIL
```

The F7 mutation matrix:

```text
MATRIX_REJECTED DELETED_HEADER make_exit=1
MATRIX_REJECTED CHANGED_HEADER stamp_rebuilt=YES
MATRIX_REJECTED PRODUCER_CHANGE make_exit=126
MATRIX_REJECTED CORRUPTED_ARCHIVE make_exit=1
MATRIX_ACCEPTED WARM_BUILD
MATRIX_REJECTED FAILED_RETRY first=1 retry=1
MATRIX_SERIALIZED_CLEAN_BUILD round=1 OBSERVATIONS=OK
MATRIX_SERIALIZED_CLEAN_BUILD round=2 OBSERVATIONS=OK
```

The conservation gates:

```text
DRIVER_WP001_REQUIRED_ROUTE_TEST_STATUS=PASS
DRIVER_WP001_PRECEDENCE_TEST_STATUS=PASS
DRIVER_WP001_FAIL_CLOSED_STATUS=PASS
```

The quality gates, run SERIALLY against the subject commit
(`c4r3/gate-fast-checks.tsv`, `c4r3/gate-ledger.tsv`):

```text
CHECK=diff-check STATUS=PASS
CHECK=shell-syntax STATUS=PASS
CHECK=doc-invariants STATUS=PASS
CHECK=large-file-guard STATUS=PASS
CHECK=factory-closure-status STATUS=PASS
```

The push gate, run ALONE and SERIALLY
(`c4r3/gate-push-checks.tsv`):

```text
CHECK=aot STATUS=PASS
CHECK=build STATUS=PASS
CHECK=diff-check STATUS=PASS
CHECK=install STATUS=PASS
CHECK=jit STATUS=PASS
CHECK=lsp STATUS=PASS
VERDICT=PASS
```

The pristine isolated checkout, at the subject commit, with an EMPTY build
directory and a `git worktree` that shares no build state with the working
tree (`c4r3/pristine-isolated-suite.tsv`):

```text
driver-wp001-correction03-contract-test	0	PASS
driver-wp001-correction03-test	0	PASS
driver-wp001-correction03-emission-test	0	PASS
driver-wp001-correction03-causal-test	0	PASS
driver-wp001-correction03-adverse-test	0	PASS
driver-wp001-correction03-publish-test	0	PASS
driver-wp001-correction03-matrix-test	0	PASS
PRISTINE_TARGETS=7
PRISTINE_FAILURES=0
PRISTINE_SUITE_STATUS=PASS
```

The runner that produces it is `tools/quality/driver-required-route-correction03-pristine.HC`, which is **PolyC**. The first draft of the runner was a shell file of 131 lines, which the `F-POLYC-TOOLS` doctrine forbids: shell is permitted only as bootstrap glue, with a hard maximum of fifty lines, and a new shell file may not implement a test matrix or a multi-step orchestration. The runner was rewritten in PolyC and the shell file was removed. The runner's behaviour is unchanged, and its cleanup is verified: the exclusive lock is released, the isolated worktree is removed, and the repository is left exactly as it was found.

## THE ENVIRONMENTAL CLASSIFICATION OF TWO FAILURES

Two failures were observed during this round and are recorded here with
their classification, because "an intermittent failure remains a failure
unless its environmental classification is independently demonstrated"
(AC10).

### THE PARALLEL-BUILD RACES -- PRE-EXISTING, NOT A REGRESSION

The compiler writes its intermediary assembly to the FIXED path
`/tmp/holyc-asm.s` (`src/main.c`, `ASM_TMP_FILE`). Two compiler
invocations that OVERLAP therefore destroy each other's scratch file, and
the second one fails with `no such file or directory: '/tmp/holyc-asm.s'`.

Under `make -j8` the build fails on a bootstrap subject whose symbol is
missing from the produced object, because the subject was compiled while
the bootstrap prefix was being rewritten. The SAME failure is observed at
the PRE-C4R3 BASELINE commit `d69454b3` and at the pre-round-two baseline
`b5fe5386`, so the race is PRE-EXISTING and is NOT introduced by this
round's changes. The round's own targets are therefore run SERIALLY, which
is the constraint the ACT already records.

The reproduction at the pre-round-two baseline `b5fe5386`, with the full
CORRECTION03 target and an empty build directory, is:

```text
parser-operator-precedence-subject: symbol _BootstrapOperatorPrecedence not found in build/parser-operator-precedence-subject.o
parser-compound-block-subject: symbol _BootstrapCompoundBlockAppendsStatement not found in object
parser-ast-unary-subject: symbol _BootstrapAstUnaryOpFromToken not found in object
parser-ast-binop-subject: symbol _BootstrapAstBinOpFromToken not found in build/parser-ast-binop-subject.o
parser-control-flow-token-subject: symbol _BootstrapValidPostControlFlowToken not found in build/parser-control-flow-token-subject.o
parser-default-arm-subject: symbol _BootstrapDefaultArmTerminates not found in object
parser-switch-arm-subject: symbol _BootstrapSwitchArmTerminates not found in object
```

with the make exit status 2. The same seven subjects fail at this round's
subject commit under the same parallelism, and none of them fails when the
build is serialized. The reproduction is recorded in
`c4r3/parallel-race-baseline-b5fe5386.txt`.

### THE FIRST `gate-push` FAILURE -- THE RUNNER'S OWN INTERFERENCE

The first `gate-push` run in this round failed with

```text
CHECK=aot STATUS=FAIL
REASON=aot emitted test-failure markers despite zero exit status
```

with the underlying cause visible in the log:

```text
clang: error: no such file or directory: '/tmp/holyc-asm.s'
```

The cause was that the pristine suite was running CONCURRENTLY with the
gate, and the two destroyed each other's scratch file. The gate was re-run
ALONE and passed with every check. The pristine runner now takes an
EXCLUSIVE LOCK on the scratch path, so the interference cannot recur.

## WHAT IS NOT CLAIMED

- No claim of strict M2 self-hosting.
- No claim of WP-002 authorization or of WP-001 completion.
- No claim of whole-CLI compiler ownership.
- No claim of evidence reconciliation. CORRECTION02's contradictory frozen
  predictions, generation matrix, NC17 conflict and acceptance ledgers
  remain a separate evidence-reconciliation ACT.
- The closure verdict does not claim that the archive's timestamp
  nondeterminism is eliminated. The timestamp is the ONE explicitly
  permitted nondeterminism and it is reported as such.

## THE RESIDUE

- **P1** -- CORRECTION02's contradictory frozen predictions, generation
  matrix, NC17 conflict and acceptance ledgers require a separate
  evidence-reconciliation ACT.
- **P1** -- Whole-CLI compiler ownership remains incomplete and out of
  scope.
- **P2** -- A reusable evidence verifier distinguishing PASS, FAIL,
  UNRESOLVED and UNSUPPORTED is deferred to the evidence-reconciliation
  ACT.
- **P2** -- The shared assembly scratch path `/tmp/holyc-asm.s` is a FIXED
  path, and concurrent compiler invocations therefore interfere. A
  per-invocation scratch path would remove the interference at the source.
  It is out of scope here, because the change would touch the production
  compiler's file handling.
- **P2** -- The bootstrap prefix's rule rewrites the prefix directory, and
  a parallel build can read it mid-rewrite. The same remedy applies.

## C4_READY

```text
C4_READY=NO
```

C4 is NOT ready. The independent Codex review of this round's evidence has
not been run. The ACT remains OPEN.
