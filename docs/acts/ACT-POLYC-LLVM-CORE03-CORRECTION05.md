# ACT-POLYC-LLVM-CORE03-CORRECTION05

## Status

HALT_CORRECTION05_OWN_GATE_RED — reviewer-flagged.

The technical work is sound. The LLVM/wire and closure
artifacts all stand:
  - Real-LF end-to-end seam: PASS (mutated wire captures
    byte-exact 0x0A from C "\n" escape; reviewer-required
    hex 6c 69 6e 65 31 0a 6c 69 6e 65 32 matched; both
    parser logics tested on the same wire).
  - CORRECTION03 parser RED control: rc=1, two FAIL lines.
  - CORRECTION04 parser GREEN treatment: rc=0, 117 PASS / 0 FAIL.
  - NULL-sentinel documentation: in src/llvm-backend-cap.c.
  - CORRECTION04 reconciliation: ACT Status and HANDOFF
    VERDICT both now read HALT_*. The closure-status
    gate (M1 below) OKs the CORRECTION04 pair.

    SUPERSEDED (by ACT-POLYC-FACTORY-STATUS-RECONCILIATION):
    The previous sentence described CORRECTION04 as "OK" under
    the legacy seed oracle's lossy lifecycle normalization, which
    collapsed both HALT_* tokens to "HALT" and therefore reported
    OK. Under the new exact-token contract, CORRECTION04's
    authoritative ACT token is HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
    and the HANDOFF verdict token is now reconciled to match
    exactly. The pair still agrees (PASS under the new oracle),
    but for the substantive reason of exact-token equality rather
    than lossy normalization. This note is preserved per F14
    (historical documents are historical evidence; current truth
    is recorded in current docs and the new HANDOFF Supersession
    block).

But the new hard gate introduced by this ACT is RED at
closure:

```text
llvm-closure-status-check.sh
  OK   = 2
  FAIL = 3   (CORRECTION01 HALT/PASS, CORRECTION02 HALT/PASS,
              CORRECTION03 HALT/PASS)
  rc   = 1
```

That rc=1 contradicts the ACT's own A5 ("FAILS if any pair
disagrees") and A8 ("closure-status-check.sh: rc=0"), and
contradicts the VERDICT declared PASS. The "three failures
are out-of-scope residue" line does not rescue the contract,
because the gate's documented semantics are "iterate paired
ACTs and FAIL if any disagreement exists" — not "FAIL if
any disagreement exists within the current ACT family".

This is the F3/F4 territory the reviewer correctly named:
the new oracle is RED at closure, so closure is HALT,
not PASS. Per F15, fixing the three pre-existing mismatches
is out of scope here; that work is the next ACT (see
"Next ACT" below).

Recorded as:
  evidence/llvmspike01-core03-correction05/halt-correction05-own-gate-red.txt

CORRECTION04 verdict (unchanged by this HALT):
  HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE (recorded in
  evidence/llvmspike01-core03-correction05/halt-correction04-status-and-lf-evidence.txt).

This ACT records:
  M1: closure-status-reconciliation gate (reviewer P0-1
      was the third occurrence of the same defect; this
      ACT introduces the reproducer).
  M2: real-LF end-to-end seam (reviewer P0-2 closed).
  M3: NULL-sentinel contract documentation (reviewer P1
      closed).
  M4: CORRECTION04 ACT/HANDOFF reconciliation (in scope;
      HANDOFF now reads HALT_STATUS_RECONCILIATION_AT_CAP
      matching the ACT HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE).

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
  - CORE04 is NOT unblocked here. The reviewer's sequencing
    recommendation is correct: STATUS-RECONCILIATION is the
    next ACT, then CORE04.

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
    binding closure defects..." to "HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
    — at CORRECTION05", and adds the IDENTITY block listing
    this ACT's commits as the closing commits. The HANDOFF
    VERDICT also flips PASS -> HALT_STATUS_RECONCILIATION_AT_CAP
    so that the closure-status-reconciliation gate (A5) OKs
    the CORRECTION04 pair. ACHIEVED.

A5. Closure-status-reconciliation invariant: a new script
    scripts/quality/llvm-closure-status-check.sh compares
    each ACT's Status block with its HANDOFF verdict. The
    check exits 1 if any pair disagrees. Documented as the
    minimal reproduction of the bug observed three times.
    The script itself exists and behaves as specified. The
    current ACT family outcome is OK=2 FAIL=3 (CORRECTION04
    and CORRECTION05 agree; CORRECTION01/02/03 disagree —
    the three pre-existing mismatches).

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
    closure-status-check.sh:
        rc=1   (FAIL: 3 pre-existing CORRECTION01/02/03
                     ACT/HANDOFF mismatches; OK: 2 in-scope
                     pairs)
        The gate itself works as specified (FAILS on
        disagreement); it is RED at closure because of
        out-of-scope residue. This is the F3/F4 finding
        that graduates STATUS-RECONCILIATION from P1
        residue to the immediate next ACT.

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

PROMOTED (immediate, gated): ACT-POLYC-FACTORY-STATUS-RECONCILIATION.

The closure-status-check.sh gate introduced by this ACT
is RED at closure (OK=2 FAIL=3). Per F3/F4 the ACT
therefore halts rather than passes. The three
FAIL pairs are:

  CORRECTION01 ACT   HALT_CORE03_CORRECTION01_BINDING_STILL_PARTIAL
  CORRECTION01 HAND  VERDICT: PASS
  CORRECTION02 ACT   HALT_SCOPE_CONTRACT_VIOLATED
  CORRECTION02 HAND  VERDICT: PASS
  CORRECTION03 ACT   HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
  CORRECTION03 HAND  VERDICT: PASS

STATUS-RECONCILIATION mission (bounded):

  1. Reproduce OK=2 FAIL=3 on the current tree.
  2. Reconcile each of the three historical ACT/HANDOFF
     mismatches under F14 (no rewriting of history; status
     updates to fresh ACT commits only).
  3. Decide whether the oracle compares:
        a) lifecycle class (PASS / HALT / OPEN), or
        b) exact verdict token (HALT_<reason>).
     Reviewer recommends exact verdict token; rationale
     to be recorded.
  4. Establish an authoritative ACT<->HANDOFF mapping
     rather than relying on filename heuristics. The
     current scripts/quality/llvm-closure-status-check.sh
     is a seed; the production gate should consume an
     explicit manifest (e.g. docs/factory/act-handoff-map.tsv
     or equivalent).
  5. Wire into scripts/quality/gate-fast.sh so every ACT
     commit's closure status is checked before merge.
  6. Required closure criterion:
        llvm-closure-status-check.sh
        OK = N, FAIL = 0, rc = 0
     (or N = total paired ACTs and FAIL = 0).
  7. Only then resume ACT-POLYC-LLVM-CORE04.

Following this gate, CORE04 may resume:
  - auto opcode-set decoding (replace per-fixture lists)
  - consolidate fixture lists between two harnesses
  - unify dispatch-arm discovery + body extraction
  - per-class execution counters
  - generated matrix comment

Other Factory ACTs (carried):
  - ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1)
  - ACT-POLYC-FACTORY-TOPOLOGY-CAP-HONESTY (P2)
  - ACT-POLYC-FACTORY-IDENTITY-CONTRACT (P2)

Reviewer observations on this ACT's seed oracle (recorded
as P1 to be addressed in STATUS-RECONCILIATION):

  P1a. The current ACT<->HANDOFF pairing in the seed gate
       is inferred from filename conventions
       (LLVM-* -> llvmspike01-*, IR-* -> ir-*, FACTORY-* ->
       factory-*) and silently skips pairs whose HANDOFF
       is missing. Reasonable for a seed; not the general
       Factory hard gate. STATUS-RECONCILIATION should
       replace this with an explicit manifest.

  P1b. The seed gate normalises HALT_*, PASS, OPEN to
       lifecycle classes. If "ACT Status and HANDOFF
       VERDICT agree" is the invariant, exact verdict
       tokens must agree; otherwise
       HALT_SCOPE_CONTRACT_VIOLATED vs HALT_TOPOLOGY_RECORDED
       would (incorrectly) pass. Reviewer recommends exact
       verdict token. STATUS-RECONCILIATION must decide.

### Supersession

Authorised successor: ACT-POLYC-FACTORY-STATUS-RECONCILIATION
(immediate, gated; will resolve the closure-status gate
RED and unlock CORE04).
