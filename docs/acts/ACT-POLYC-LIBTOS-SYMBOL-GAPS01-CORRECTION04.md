# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04

## 0. Mission

Close the third-round post-close reviewer audit of
ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03. CORRECTION03's
`PASS_TRUE_GREEN` trailer is hereby reclassified (per F14) to
`FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT`. The remaining binding
defects are pure lifecycle bugs in the AC contract; the libtos
production engineering is GREEN per the reviewer's disposition.

  P0-A: AC02 was never authorized to change.
        CORRECTION03's C2-1 (override + frozen expected SHA)
        defeated the original AC02 literal predicate
        (`make lib-tos HCC=/bin/false` exits nonzero). The
        CORRECTION03 C3 ledger marked AC02 `PASS_BY_DESIGN`,
        but the HANDOFF simultaneously recorded AC02 as
        "cannot be marked PASS until CORRECTION04". This is
        a mechanical contradiction; the ledger cannot be
        `MANDATORY_PASS` while the HANDOFF says
        `NOT_PASS / UNAUTHORIZED_AMENDMENT_REQUIRED`.

  P0-B: AC22 has the same temporal problem AC20 had.
        The AC22 predicate "5 separate commits in C0..C4
        order" can only be true AFTER C4 commits. CORRECTION03
        captured c3-ac22.txt at C3 commit time (3 commits
        visible), recorded FAIL, and promoted to PASS via
        the ledger anyway. The CORRECTION03 §3.4 amendment
        bounded the range but did not move the evidence to
        C4 alongside AC20. Same defect class as AC20 in
        CORRECTION02/CORRECTION03.

This ACT's repair is EXTREMELY SMALL per the reviewer's
instruction: C0 formally supersedes AC02 with the already-
implemented fail-closed + pinned-provenance predicate, and
moves AC22 terminal topology verification to C4 alongside
AC20. NO PRODUCTION MUTATION. NO engineering changes.

After this ACT closes, return to ACT-POLYC-SELFHOST-LEXER04-
CORRECTION02. Stop touching libtos prose.

## 1. Predecessor(s)

  ACT-POLYC-LIBTOS-SYMBOL-GAPS01                 PASS_TRUE_GREEN at 5cbda9b (historical)
  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01    reclassified to FALSE_GREEN
  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02    reclassified to FALSE_GREEN at 0f24900
  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03    reclassified to FALSE_GREEN at 54f932d
  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04    THIS ACT

## 2. Scope

In scope:

  (a) C0-authorize AC02 supersession (per §3.1 below).
  (b) C0-authorize AC22 evidence location move (per §3.2 below).
  (c) Re-run C3 evidence under the new predicates.
  (d) C4 evidence for AC20 (already done in CORRECTION03) and
      AC22 (new, per §3.2).
  (e) Write C4 HANDOFF.

Out of scope (per reviewer: "no production mutation should be necessary"):

  - lib-tos recipe (frozen by CORRECTION03 C2-1).
  - Archive producer-id mechanism (frozen by CORRECTION02).
  - N02 PolyC tool (frozen by CORRECTION02, sandbox tolerance by CORRECTION03).
  - factory-no-python-check-binary target (frozen by CORRECTION03 C2-2).
  - All closed evidence trees and HANDOFFs.

## 3. C0-AUTHORIZED AMENDMENTS

### 3.1 AC02 supersession

The CORRECTION01 §6 original AC02 predicate was:

> PASS iff, with the build cache scrubbed, a `make lib-tos
> HCC=/bin/false` invocation exits nonzero and does not write
> `build/test-prefix/lib/libtos.a`.

CORRECTION03's C2-1 (`override LIBTOS_HCC := ./build/hcc-bootstrap04`)
defeats the command-line override that this predicate depends on.
The CORRECTION03 c3-ac02.txt documented this contradiction and
recorded `PASS_BY_DESIGN`.

This ACT formally SUPERSEDES the original AC02 predicate with the
bounded CORRECTION04 AC02 predicate:

> PASS iff ALL of:
>   (a) Pinned builder `./build/hcc-bootstrap04` is absent.
>       `make lib-tos` exits nonzero with a precondition error
>       that names `HCC_BOOTSTRAP_PROVENANCE_SHA` and
>       `build/hcc-bootstrap04 is REQUIRED for fail-closed lib-tos`.
>       No libtos.a is written.
>   (b) Pinned builder present but with the wrong SHA
>       (substituted or modified). `make lib-tos` exits nonzero
>       with a precondition error that names the measured SHA
>       AND the expected SHA AND `REJECTED: producer identity
>       mismatch (CORRECTION03 C2-1)`. No libtos.a is written.
>   (c) Pinned builder present with the correct SHA.
>       `make lib-tos` exits 0 and writes libtos.a whose
>       producer_id note matches the authorized SHA.

This is the same predicate that CORRECTION03 §6 documented as
residue; it is hereby C0-AUTHORIZED for CORRECTION04 (and for all
future ACTs that supersede AC02). The CORRECTION03 c3-ac02.txt
PASS_BY_DESIGN disposition is promoted to PASS_BY_PREDICATE.

### 3.2 AC22 evidence location move

The CORRECTION03 §3.4 amendment bounded AC22 evidence to the
CORRECTION03 range, but the AC22 predicate "5 separate commits in
C0..C4 order" can only be true AFTER C4 commits (same lifecycle
bug as AC20 in CORRECTION02).

This ACT C0-AUTHORIZES the AC22 evidence location move:

> AC22 evidence lives in `c4/c4-ac22.txt`, captured AFTER the
> C4 commit. The C3 ledger records `AC22 = DEFERRED_TO_C4` and
> the C4 handoff records the final commit count and ordering.

This mirrors the AC20 procedure amendment from CORRECTION03 §3.3.

## 4. Acceptance criteria

AC01..AC22 contract from CORRECTION01 §6 with the amendments:
  - AC02 superseded per §3.1 (this ACT).
  - AC20 evidence in c4/ per CORRECTION03 §3.3.
  - AC22 evidence in c4/ per §3.2 (this ACT).
  - AC03 amended per CORRECTION03 §3.1.
  - AC04 amended per CORRECTION03 §3.5.
  - AC17 amended per CORRECTION03 §3.2.

  AC01..AC22: 22 PASS / 0 FAIL / 0 UNKNOWN / 0 MISSING.

## 5. Conservation gates

  - `make gate-fast`                         RC=0, STATUS=PASS
  - `factory-append-only-test`               PASS=11 FAIL=0
  - `git diff --check ENTRY_HEAD HEAD`       RC=0
  - `git status --short` at C4               empty
  - LEXER08 + LEXER09 fixed-point verifiers  PASS
  - 21/21 runtime-contract-test cases        PASS
  - 10/10 N02 isolation sub-cases            PASS
  - factory-no-python-check wrapper          runs and emits report
  - Wrong-SHA bootstrap substitution         rejected with both SHAs named
  - Predecessor evidence trees untouched per F14
    (gated on `git diff ENTRY_HEAD HEAD -- evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01/`
     returning empty; CORRECTION03 evidence trees may be appended-to but
     not modified, per F14).
