# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 -- C4 ROUND 6 STATUS

    VERDICT=C4_ROUND_6_PROBE_COMPLETE
    INDEPENDENT_REVIEW=NOT_RUN
    C4_READY=NO
    NEXT_ACTION=INDEPENDENT_CODEX_REVIEW

## WHAT THIS ROUND ESTABLISHED

The C4 ROUND 6 subject repairs the FIVE P1 findings of the C4 ROUND 5
review, implements the R5-06 diagnostic-precision disposition, and
corrects the R5-07 and R5-08 records FORWARD-ONLY.

    PROBE   tools/quality/driver-required-route-correction03-c4r6-probe.HC
    TARGET  make driver-wp001-correction03-c4r6-probe-test
    GREEN   evidence/.../c4r6/green-c4r6-probe.txt
    PRISTINE evidence/.../c4r6/pristine-vs-subject.txt
    GATES   evidence/.../c4r6/gate-ledger.txt
    REVIEW  evidence/.../c4r6/independent-review-prompt.txt

## THE ENTRY IDENTITY

    ENTRY_HEAD=61bd8d9016c1c991f0936a33f2ee47e53654ccea

The RED witnesses for all five attacks were produced in a DETACHED
WORKTREE at that identity, and the pristine harness is a DIFFERENT
BINARY from the subject's:

    PRISTINE  sha256 fc608e9c3b5d204dc065adc7157eac5879ddb69d4ac8fab5d630086d8fdc79d7
    SUBJECT   sha256 09740eadb694f03dbce679c184d39fd100510af75216896c4e4ade5ff2e2ba24

## THE ARCHITECTURE

The repair is ONE runner-owned `HarnessExecCtx`, not additional check
layers. The runner OWNS the executable path, the argument vector, the
output path and the environment. Caller-supplied provenance never
substitutes for an execution-owned fact.

    R5-01  the source is read ONCE into memory; the snapshot digest is
           taken from THOSE bytes; the bytes are staged to
           `out/source.HC`; the caller's source argument must AGREE
           (resolved comparison); the STAGED path is executed.
    R5-02  the runner owns the basename and CONSTRUCTS the `-o`; an
           absolute, traversing or nested path is REFUSED; containment is
           checked on the RESOLVED path; `-o-` is a stdout special case.
    R5-03  the contract records ONLY file-backed sections for the
           overlap test; a virtual zero-fill section is bounded by the
           address-space wrap, not by the segment's `vmsize`.
    R5-04  the producer is BYTE-COPIED into a private
           `event/stage/producer`; the digest is re-verified IMMEDIATELY
           BEFORE the spawn; the STAGED path is executed. The mechanism
           1 (`fexecve`) is INFEASIBLE on this platform, so mechanism 2
           (copy-and-stage) is used.
    R5-05  the new `envbind` mode calls the PRODUCTION
           `HarnessApplyEnv()` and observes the binding in a REAL CHILD,
           with an optional separate observe-name.
    R5-06  the block extractor carries a STATUS out-parameter; the
           comparator reports the status it was given; the diagnostic
           does not claim a recomputation it did not perform.

The event directory is named by a MONOTONIC COUNTER, not by identity,
to break the circularity between identity-over-argv and
argv-containing-event-dir paths. The identity is still computed over
the FINAL EXECUTED argv.

## THE PROBE

    PROBE_CHECKS   32
    PROBE_FAILURES 0

    exec          16 controls
    macho          5 controls
    envbind        6 controls
    blockstatus    5 controls

## THE P2 DISPOSITIONS

    R5-06  IMPLEMENTED. The five block statuses are DISTINGUISHED, and
           the recomputation diagnostic reports `NOT_COMPUTED` with
           `A_MANDATORY_INPUT_IS_ABSENT` rather than printing a digest
           for a record it could not read. The ACCEPTANCE BEHAVIOUR is
           unchanged: every block failure was refused before and is
           refused now; only the REASON TOKEN is precise.
           See `r5-06-block-status-precision.md`.

    R5-07  DISPOSED AS INCORRECT. `0x18EB1AFA & 0xF000` is `0x1000`,
           and `0x1000` is the CORRECT value. The prior round read the
           observation as an operator defect without checking the
           expected value. No code change is required or made.
           See `r5-07-bitwise-correction.md`.

    R5-08  DISPOSED AS A MISCOUNT. The C4 ROUND 5 RED transcript has
           40 PHYSICAL ROWS = 24 OK + 16 FAIL, 37 UNIQUE CONTROL
           NAMES, and 38 ASSERTED CHECKS. The prior claim "34 OK + 16
           FAIL" sums to 50 and is arithmetically incompatible with the
           transcript. See `r5-08-accounting.md` and
           `r5-08-accounting.tsv`.

## THE RESIDUE

    P1  THE PRODUCTION COMPILER PREFIXES `./` TO AN ABSOLUTE `-o` PATH.
        `make -B production-hcc` therefore fails with
        `.//Volumes/.../build/...`. The `hcc` binary used by the gates
        is the restored `build/hcc` (777472 bytes, all SIXTEEN
        production authorities present). This is a defect in the
        COMPILER, not in the evidence tooling, and fixing it would
        change the production compiler's semantics. OUT OF SCOPE.

    P1  A HEX-LITERAL ARITHMETIC EXPRESSION FORM PRODUCES THE WRONG
        BYTES. `48 + (i / div) - (i / div) * 10` produced
        `118, 39, 151, 18, 10` where a decimal digit and a newline were
        intended. It was found while building the R5-06 witness, whose
        oversized-block body was therefore rewritten to use a FIXED-WIDTH
        entry with no digit encoding at all. The repaired code does not
        rely on the expression form. A general audit of the compiler's
        arithmetic is OUT OF SCOPE.

    P2  THE RUNNER'S EVENT DIRECTORY DEFENCE FIRES BEFORE THE OUTPUT
        PATH CHECK (carried forward from C4 ROUND 5). The defence CHAIN
        is sound -- the stale artifact is never registered -- but the
        three refusal tokens are not independently reachable.

    P2  THE PROBE'S ASSERTED-CHECK COUNT AND ITS PHYSICAL-ROW COUNT
        ARE COUNTED AT DIFFERENT POINTS (38 against 40). This is an
        observation about the probe's accounting shape, recorded in
        `r5-08-accounting.md`, and NOT a defect.

## THE CORRECTIONS TO THIS ROUND'S OWN SUBJECT

Two defects in THIS round's subject were found and repaired before
closure, and both are recorded here so a reviewer does not have to
discover them:

  1. THE REPO'S ZERO-FILL FIXTURE DID NOT CARRY THE 256 KiB SECTION.
     The first version of
     `tools/quality/fixtures/driver-required-route-correction03-zerofill-fixture.c`
     declared `int huge_bss[65536]`, which the arm64 compiler DROPS
     entirely: an unreferenced plain `bss` array is not emitted, and an
     explicitly named one is emitted as an ordinary file-backed
     `S_REGULAR` section with a file offset. The fixture therefore
     carried NO zero-fill section at all, and the R5-03 control passed
     for the WRONG REASON. The fixture was rewritten to use a
     thread-local zero-fill array, which the arm64 target emits
     RELIABLY as `S_THREAD_LOCAL_ZEROFILL` (0x12) with a file offset of
     ZERO and a virtual size of 256 KiB. The corrected fixture is
     REFUSED by the PRISTINE validator with
     `MACHO_SECTION_EXTENT_INVALID` and ACCEPTED by the subject's.

  2. THE C4 ROUND 5 PROBE'S EMPTY-BLOCK CONTROL. The R5-06 status
     distinction introduced `CAPTURE_BLOCK_EMPTY` for a well-formed
     block with zero entries, which the C4 ROUND 5 control's
     `bstatus == CAPTURE_BLOCK_OK` check would have rejected. The
     control was NOT WEAKENED: the count must still be EXACTLY N, the
     array must still be non-NULL, and every element must still be
     readable. Only the token that identifies a well-formed block
     changed.

## WHAT THE NEXT ROUND MUST DO

    1. RUN THE INDEPENDENT CODEX REVIEW, READ-ONLY, against the subject
       tree, using `independent-review-prompt.txt`. The reviewer
       re-executes ALL SIX attacks and does not modify the tree.
    2. ADDRESS THE REVIEWER'S FINDINGS.
    3. CLOSE C4 ONLY WHEN THE REVIEWER'S VERDICT IS `C4_READY=YES`.
