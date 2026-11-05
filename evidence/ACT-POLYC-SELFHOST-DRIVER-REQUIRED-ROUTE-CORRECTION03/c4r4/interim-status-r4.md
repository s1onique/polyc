# C4 REMEDIATION ROUND 4 -- INTERIM STATUS

ACT: ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03

This document is the FORWARD-ONLY record of the fourth remediation round.
It does NOT modify the CORRECTION02 evidence, the CORRECTION03 round-one
evidence, the round-two evidence or the round-three evidence. The historical
documents remain valid as evidence of what was observed at the time.

## WHAT THIS ROUND REPAIRED

Eight defects, each independently reproduced, each repaired, each covered
by its own adverse probe.

| Finding | The defect | The repair | Fix commit |
|---|---|---|---|
| F01 | the ledger membership accepted a PREFIX of a record | the record must have the same LENGTH, the same BYTES and a terminated line | `ecd8c7ef` |
| F02 | the archive member name was bounded by the sixteen-byte name field | the name is bounded by the SOURCE SLICE and allocated from the decoded length | `ecd8c7ef` |
| F03 | the Mach-O segment and section extents were read at the wrong width, and the thirty-two-bit section offset was read at the wrong width | each field is read at its own width | `ecd8c7ef` |
| F04 | the LC_DYSYMTAB tables were not all validated and the symbol-range relationships were not checked | all six tables are validated with the correct widths and the relationships | `ecd8c7ef` |
| F05 | the archive's real members' EMBEDDED objects were never validated | each real member's payload is validated as an embedded Mach-O object, on each side independently | `56fb49e4` |
| F06 | a warm build accepted a stale producer and a stale archive | both are requalified at the acceptance boundary, on every run | `8e0aa142` |
| F07 | the archive name allocation could overrun | the decoded length is used, the source copy is bounded and the allocation is guarded | `ecd8c7ef` |
| F08 | the execution provenance did not bind the observation to the execution | see THE EXECUTION PROVENANCE below | `9f030c1b` |

## THE EXECUTION PROVENANCE

F08 was FIVE defects, each independently reproduced.

1. The comparator never RECOMPUTED the event identity. It checked that the
   identity was REGISTERED in the ledger and that the digests matched the
   bytes, so a FORGED record -- a genuine record whose contents were
   changed while its identity was left alone -- satisfied both checks. The
   comparator now recomputes the identity from the record's own fields,
   using its own independent copy of the construction, and requires the two
   to agree.

2. The harness RECORDED an environment it never APPLIED. The child ran
   with the runner's ambient environment, and the recorded environment
   described one that was never in force. Each binding is now applied with
   setenv BEFORE the spawn.

3. The runner did not check the producer it was about to execute. It now
   establishes, FROM THE BYTES ON DISK, that the producer exists, that it
   is an executable file, and that it is a Mach-O image for the
   architecture of the artifacts the evidence is about. Each property has
   its own reason token.

4. The event directory was not allocated EXCLUSIVELY; the result of mkdir
   was ignored. It now must succeed.

5. The event identity was computed over a REVERSED counter. The digits
   were produced in reverse order and were never reversed back, so for a
   one-digit counter the defect was invisible, and from the tenth event of
   a run the identity described a counter the record did not state. This
   was FOUND by the new recomputation check.

The GENUINE capture record still PASSES the recomputation, and every
FORGERY of it is REJECTED. The check is not simply always failing.

## THE ADVERSE ROSTER

The roster carries an EXPLICIT probe identity, N01 through N28, and every
probe is rejected for its OWN DISTINGUISHING reason. The measured ledger
is `c4r4/adverse-roster-n01-n28.tsv`.

The nine F08 probes are N20 through N28.

## THE MEASUREMENTS

    CONTRACT_SELFTEST_FAILURES                  0
    LEDGER_SELFTEST_FAILURES                    0
    PROBE_FAILURES                              0
    CORRECTION03_COMPARE_FAILURES               0
    CORRECTION03_ABI_PROBE_FAILURES             0
    DRIVER_WP001_CORRECTION03_TEST_STATUS       PASS
    DRIVER_WP001_CORRECTION03_C4R4_PROBE_TEST_STATUS   PASS
    DRIVER_WP001_CORRECTION03_WARM_PRODUCER_STATUS      PASS
    DRIVER_WP001_CORRECTION03_ADVERSE_TEST_STATUS       PASS

    make driver-wp001-required-route-test        PASS
    make driver-wp001-precedence-test            PASS
    sh scripts/quality/factory-v2-test.sh        PASS=55 FAIL=0
    make gate-fast                               VERDICT=PASS
    make gate-push                               VERDICT=PASS

The Factory-v2 range checker is qualified against SYNTHETIC GIT FIXTURES,
which is the only way to exercise a topology that has not happened yet.
The 55 cases include the interrupted-ACT and the historical-invalid-
topology scenarios.

The 16 PRODUCTION POLYC AUTHORITIES were re-censused fresh over the real
production link line and the real production C objects. All sixteen are
VERIFIED.

## THE PRODUCTION IS UNTOUCHED

`src/**` and `tools/bootstrap/**` are BYTE-IDENTICAL to the ACT's entry
identity `b7711f68f8a66ccd76278df5cbd1a0d0d0aace8b`. Every changed line
of this ACT is in `tools/quality/`, `Makefile` or `evidence/`.

## WHAT IS STILL OUTSTANDING

THE INDEPENDENT REVIEW REQUIRED BY AC11 DID NOT RUN.

The Codex reviewer is installed -- two builds, 0.166.0 and the 0.163.0
bundled with the ChatGPT desktop application -- and both were ATTEMPTED.
Both fail, because the macOS configuration loader requires
CFPreferencesAppSynchronize to succeed and this environment DENIES the
write-back to `~/Library/Preferences`. The measurement is in
`c4r4/independent-review-harness-unavailable.txt`, and it is reproducible
with a four-line C program that does not involve Codex at all.

NO SILENT FALLBACK WAS USED. The review was NOT replaced by a self-review,
and no reviewer-shaped artifact was fabricated.

AC11 IS NOT SATISFIED. C4 IS NOT AUTHORIZED. NO CLOSE IS CLAIMED.

The review instructions are COMMITTED, in
`c4r4/independent-review-prompt.txt`, so that the scope and the questions
the reviewer was asked cannot be adjusted after its findings are known.

## THE NEXT ACTION

Run the committed review instructions in an environment in which the Codex
reviewer can start, and bring its findings back as a new remediation
round. Nothing is pushed.
