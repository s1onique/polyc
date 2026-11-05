# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 -- C4 ROUND 5 STATUS

    VERDICT=C4_ROUND_5_PROBE_COMPLETE
    C4_READY=NO
    NEXT_ACTION=INDEPENDENT_CODEX_REVIEW

## WHAT THIS ROUND ESTABLISHED

The C4 ROUND 5 counterexample probe is in place, it exercises the
PRODUCTION functions, and it has a RED witness at the entry HEAD and a
GREEN witness at the current tree.

    PROBE   tools/quality/driver-required-route-correction03-c4r5-probe.HC
    TARGET  make driver-wp001-correction03-c4r5-probe-test
    RED     evidence/.../c4r5/red-c4r5-probe.txt
    GREEN   evidence/.../c4r5/green-c4r5-probe.txt
    MATRIX  evidence/.../c4r5/regression-matrix.tsv
    GATES  evidence/.../c4r5/gate-ledger.txt
    REVIEW evidence/.../c4r5/independent-review-prompt.txt

## THE ENTRY HEAD

    ENTRY_HEAD=c73e92f33fd61e9241c02d3ca4ea2250097e51b8
    SUBJECT_HEAD=b35253ed2a7b4fb5fd1cec8aa526acec3580e0f3

The RED witness was produced in a DETACHED WORKTREE at the entry HEAD. The
probe was compiled with `-DC4R5_RED_COMPAT`, under which

  * the capture, ledger and event-identity primitives come from
    `driver-required-route-correction03-c4r5-red-primitives.HC`, which
    carries them EXTRACTED VERBATIM from the entry HEAD's comparator; and

  * the emission roster control is compiled out, because the roster did
    not exist at the entry HEAD.

The extraction was byte-verified: the extracted text and the source text
have the SAME SHA-256, `282d7ac9b534fd23533964d98333b1eb765dca0c4bb5d4b756cd5a056bed7b67`.

## THE MATRIX

    RED   34 controls OK,  16 controls FAIL
    GREEN 42 controls OK,   0 controls FAIL

The SIXTEEN failing controls cover ALL TEN findings:

    R4-01  R4_01_CAPTURE_BLOCK_65, R4_01_CAPTURE_BLOCK_128
    R4-02  R4_02_PRODUCER_SUBSTITUTED, R4_02_PRODUCER_IS_SYMLINK
    R4-03  (the event-directory defence was already present at the entry
            HEAD; the controls pass on both sides)
    R4-04  R4_04_LEDGER_MISSING_TERMINATOR
    R4-05  R4_05_EVENT_ID_AMBIGUITY
    R4-06  R4_06_DYSYMTAB_TOC_WIDTH, R4_06_DYSYMTAB_MODULE_WIDTH
    R4-07  R4_07_ZERO_SYMBOL_RANGE
    R4-08  R4_08_ARCHIVE_MEMBER_IS_EXECUTABLE
    R4-09  R4_09_DOMAIN_ROSTER_ABSENT
    R4-10  R4_10_SECTION_0x13_FILE_EXTENT,
           R4_10_SECTION_TLS_VAR_PTRS_FILE_EXTENT,
           R4_10_SECTION_TLS_INIT_PTRS_FILE_EXTENT,
           R4_10_SECTION_INIT_FUNC_OFFSETS_FILE_EXTENT,
           R4_10_GENUINE_TLS_OBJECT_ACCEPTED

R4-11 is covered by the existing `driver-wp001-correction03-envcheck-test`
target, which runs the four mandatory cases.

## THE GENUINE arm64 THREAD-LOCAL FIXTURE

    SOURCE  tools/quality/fixtures/driver-required-route-correction03-tls-fixture.c
    OBJECT  tools/quality/fixtures/driver-required-route-correction03-tls-fixture.o

The fixture is compiled by the PLATFORM'S OWN compiler for the arm64
target, because the production compiler does not spell a thread-local
variable. The object carries a `__thread_data` section, whose type is
`S_THREAD_LOCAL_REGULAR` (0x11), and a `__thread_vars` section, whose type
is `S_THREAD_LOCAL_VARIABLES` (0x13).

The control `R4_10_GENUINE_TLS_OBJECT_ACCEPTED` is the STRONGEST R4-10
witness: the PRE-REPAIR validator REJECTED this genuine, platform-compiled
arm64 thread-local object with `MACHO_SECTION_EXTENT_OUT_OF_BOUNDS`, and
the CORRECTED validator ACCEPTS it. The pre-repair defect was therefore
not only a missed bound; it also broke a legitimate artifact.

## A DEFECT FOUND BY THIS ROUND

The R4-02 repair DOCUMENTED a symlink policy for the producer path, and
the production harness DECLARED `lstat(2)` -- but it never CALLED it. A
symlinked producer was therefore accepted, even though a symlink can be
repointed between the validation and the invocation.

The policy is now IMPLEMENTED in `HarnessCheckProducerPath`, and the
control `R4_02_PRODUCER_IS_SYMLINK` witnesses it.

## RESIDUE

    P1  THE PRODUCTION COMPILER'S CALLING CONVENTION IS INCONSISTENT FOR A
        POINTER-TO-POINTER ARGUMENT AT PARAMETER POSITION EIGHT OR LATER.
        The call site places it on the STACK and the callee's prologue
        reads it from a REGISTER, so the arguments that follow are
        shifted. Every function added or changed in this round therefore
        takes at most SEVEN parameters, or carries its inputs in a context
        object that is filled BY NAME. This is OUT OF SCOPE for this ACT:
        it is a defect in the COMPILER, not in the evidence tooling, and
        fixing it would change the production compiler's semantics.

    P1  THE PRODUCTION COMPILER'S `&` OPERATOR DOES NOT BEHAVE AS A BITWISE
        AND ON A HEX LITERAL. `0x18EB1AFA & 0xF000` evaluates to `0x1000`.
        The shared contract already avoids the operator for this reason
        -- `ContractWordAt` reads its fields arithmetically -- and the
        harness's new file-type check does the same. A general audit of
        the `&` operator's semantics is OUT OF SCOPE for this ACT.

    P2  THE RUNNER'S EVENT DIRECTORY DEFENSE FIRES BEFORE THE OUTPUT
        PATH CHECK. `HARNESS_OUTPUT_PREEXISTS` is therefore reachable
        only when the event directory is fresh but its output directory
        already exists, which the runner's own allocation prevents. The
        defence CHAIN is sound -- the stale artifact is never registered
        -- but the three refusal tokens are not independently reachable.

## WHAT THE NEXT ROUND MUST DO

    1. RUN THE INDEPENDENT CODEX REVIEW, READ-ONLY, against the subject
       tree. The reviewer re-executes ALL TEN attacks and does not
       modify the tree.
    2. ADDRESS THE REVIEWER'S FINDINGS.
    3. CLOSE C4 ONLY WHEN THE REVIEWER'S VERDICT IS `C4_READY=YES`.

## THE COMMANDS

    make driver-wp001-correction03-c4r5-probe-test
    make driver-wp001-correction03-test
    make gate-fast
    make gate-push
