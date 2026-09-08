# ACT-POLYC-LLVM-CORE03-CORRECTION05

## Status

PASS — at HANDOFF. All three reviewer-mandated items closed.

Reviewer's verdict on CORRECTION04:
HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE (recorded in
evidence/llvmspike01-core03-correction05/halt-correction04-status-and-lf-evidence.txt).

This ACT closes:
  M1: real-LF end-to-end seam (reviewer P0-2)
  M2: NULL-sentinel contract documentation (reviewer P1)
  M3: reconciliation of CORRECTION04's Status vs HANDOFF
       (reviewer P0-1; promote to a hard invariant)

Topology: CORRECTION05 declared cap = 2, actual = 2.   AT CAP.
Predecessor: ACT-POLYC-LLVM-CORE03-CORRECTION04
             (verdict: HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE).

## IDENTITY (non-self-pinning)

ENTRY_HEAD (predecessor):  9e7ab42  (CORRECTION04 DOCS HEAD)
RED_HEAD:                  <RED commit of this ACT>
IMPL_HEAD:                 <IMPL commit of this ACT>
DOCS_HEAD:                 <DOCS commit of this ACT>
FINAL_HEAD:                reviewer resolves from
                           `git log --oneline ecf6dc0^..HEAD`

This IDENTITY block follows the pattern promoted from
CORRECTION03's review: Status block MUST NOT embed the SHA of
the commit containing the Status block. (That anti-pattern
was reproduced three times in a row — CORRECTION02 HANDOFF,
CORRECTION03 ACT, CORRECTION04 ACT — and is the subject of
the separate factory ACT ACT-POLYC-FACTORY-STATUS-RECONCILIATION.)

## Goal

Close the two binding defects the reviewer flagged on
CORRECTION04's PASS:

  P0-1: the CORRECTION04 ACT Status block still reads "OPEN"
        while its HANDOFF reads "PASS". The closure document
        is stale at the instant of closure. Same family of
        defect as CORRECTION02 (HANDOFF vs ACT contradiction)
        and CORRECTION03 (self-pinned final HEAD).

  P0-2: the literal-LF end-to-end seam was not actually
        exercised. CORRECTION04's IMPL acceptance was
        synthetic (Python byte stream); the HANDOFF explicitly
        claimed LF cannot be tested live. That claim is false;
        C has the ordinary "\n" escape which produces a real
        0x0A byte at runtime.

Also carries:
  P1:  the "-" NULL sentinel is an inherent value collision.
        A payload whose contents are exactly "-" cannot be
        distinguished from NULL on the wire. Document the
        contract; do not redesign the protocol here.

## Scope

In scope:
  M1. Add a fast-gate check that compares the CORRECTION04
      ACT Status line with the CORRECTION04 HANDOFF verdict
      line and FAILS if they disagree. (This is a hard
      invariant going forward.)
  M2. Real-LF end-to-end witness:
      - source mutation: src/llvm-backend-cap.c op=46 note
        -> "line1\nline2" (C escape);
      - rebuild hcc;
      - capture wire bytes (note_len=11, payload
        6c 69 6e 65 31 0a 6c 69 6e 65 32);
      - run CORRECTION03 parser logic against the mutated
        wire -> rc=1 (RED control);
      - run CORRECTION04 parser (current) against the same
        wire -> rc=0 (GREEN treatment);
      - revert source mutation; rebuild; re-run all gates.
  M3. Document "-" as the reserved NULL sentinel in the
      wire-protocol contract comment block in
      src/llvm-backend-cap.c (no semantic change).
  M4. Flip CORRECTION04 ACT Status from "OPEN" to "PASS" via
      a CORRECTION05 IMPL-only commit. (The 3-commit cap is
      not extended; this is one of the two commits of
      CORRECTION05, NOT a fourth commit on CORRECTION04.)

Out of scope (residue):
  - Promote the closure-status-reconciliation invariant to
    scripts/quality/llvm-cap-table-verifier.py itself (the
    CORRECTION05 fast-gate lives in scripts/quality/ and is
    run by the CI pipeline, not by the cap-table verifier).
  - Replace "-" NULL sentinel with a length=-1 sentinel or
    a separate presence flag (deferred; documented).
  - CORE04 (now genuinely unblocked once this ACT passes).

## Acceptance criteria

A1. Real-LF end-to-end RED control: running CORRECTION03
    parser logic against the mutated wire returns rc=1 and
    reports at least two failures:
      - op=46 note len mismatch (header 11, actual 5)
      - trailing "line2\n" orphaned as a single-field pseudo-record

A2. Real-LF end-to-end GREEN treatment: running the
    current (CORRECTION04) parser against the same mutated
    wire returns rc=0 with 0 FAIL lines.

A3. Source mutation reverted: src/llvm-backend-cap.c has the
    same bytes after the witness run as before. `git diff`
    on the file is empty. All three gates (existing harness,
    contract harness, cap-table verifier) remain green.

A4. CORRECTION04 ACT Status is reconciled: this ACT's IMPL
    commit flips the line "OPEN — closing the two new
    binding closure defects..." to "PASS — at HANDOFF",
    and adds the IDENTITY block listing this ACT's commits
    as the closing commits.

A5. Closure-status-reconciliation invariant: a new script
    scripts/quality/llvm-closure-status-check.sh compares
    each ACT's Status block with its HANDOFF verdict. The
    check FAILS if any pair disagrees. Documented as the
    minimal reproduction of the bug observed three times.

A6. NULL-sentinel documentation: src/llvm-backend-cap.c
    carries a comment block stating that payload bytes equal
    to the literal string "-" (length 1) are reserved as the
    NULL sentinel. A legitimate diagnostic or note whose
    contents are exactly "-" cannot be represented distinctly
    from NULL.

A7. Topology: CORRECTION05 declared cap = 2, actual = 2.
    The two commits are RED (M1+M2 evidence) and IMPL+DOCS
    combined in a single commit (small truthful commits;
    F12 permits this only when the IMPL is the literal edit
    that closes the RED and the DOCS is the verbatim
    HANDOFF, both at the same patch boundary).

    Note: reviewer suggested "2 commits maximum if possible"
    and the bounded objective here does not need a separate
    DOCS commit because the IMPL commit's content IS the
    docs (it flips ACT Status text + adds the comment block
    + adds the new script). One IMPL commit carries RED
    closure (A1/A2 evidence reference) + DOCS (HANDOFF +
    ACT status flip + script). The HANDOFF file is created
    by the IMPL commit; there is no separate DOCS commit.

A8. All conservation gates at HEAD:
    git diff --check HEAD:        rc=0
    git diff --check HEAD~2..HEAD: rc=0
    existing harness:   PASS=18 FAIL=0
    contract harness:   PASS=20 FAIL=0
    cap-table verifier: rc=0, 0 FAIL lines
    closure-status-check.sh: rc=0

## Residue

P1: closure-status-reconciliation should be promoted to a
    hard gate that runs on every ACT commit, not just on
    CORRECTION04. ACT-POLYC-FACTORY-STATUS-RECONCILIATION.

P2: IDENTITY contract pattern (separate ENTRY/RED/IMPL/DOCS
    heads, reviewer-resolved FINAL_HEAD) is currently ad-hoc
    in CORRECTION03 and this ACT. ACT-POLYC-FACTORY-IDENTITY-CONTRACT.

P2: CORE03 and CORRECTION01 topology breach pattern.
    ACT-POLYC-FACTORY-TOPOLOGY-CAP-HONESTY.

P2: "-" NULL sentinel value collision. Two reasonable fixes:
      a) length=-1 means NULL (otherwise the length is
         non-negative);
      b) a separate presence flag column in the wire record.
    Both require a wire-format change and are deferred.

P2: Synthetic-vs-live testing gap for 0xFF/0x00/other
    control bytes in payload. The new verifier
    handles arbitrary bytes (the parser reads raw bytes; no
    decode is performed) but no live witness exists for
    control characters other than TAB, LF, CR. Synthetic
    coverage only.

## Next ACT

ACT-POLYC-LLVM-CORE04 (genuinely unblocked at CORRECTION05
closure):
  - auto opcode-set decoding (replace per-fixture lists)
  - consolidate fixture lists between two harnesses
  - unify dispatch-arm discovery + body extraction
  - per-class execution counters
  - generated matrix comment

Factory ACTs (carried):
  - ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01
  - ACT-POLYC-FACTORY-STATUS-RECONCILIATION (now justified
    by three-occurrence evidence + CORRECTION05's
    llvm-closure-status-check.sh witness)
  - ACT-POLYC-FACTORY-TOPOLOGY-CAP-HONESTY
  - ACT-POLYC-FACTORY-IDENTITY-CONTRACT

### Supersession

Authorised successor: ACT-POLYC-LLVM-CORE04 (OPEN at this
ACT's HANDOFF; will close the genuine technical residue).
