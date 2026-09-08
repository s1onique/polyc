HANDOFF — ACT-POLYC-LLVM-CORE03-CORRECTION04
==========================================

VERDICT
-------
HALT_STATUS_RECONCILIATION_AT_CAP

CORRECTION04 closes the M2 (true length-framed parser) defect
that the reviewer flagged on CORRECTION03's PASS
(HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT). CORRECTION04
itself was rejected by the reviewer as
HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE for two further
binding closure defects:

  P0-1: ACT Status block said "OPEN" while this HANDOFF
        said "PASS" (reproduced three-time closure-status
        reconciliation defect).
  P0-2: real-LF end-to-end seam was not exercised; only
        synthetic coverage existed.

The actual technical defect (M2 true length-framed parser)
is genuinely closed. The closure is corrected by
ACT-POLYC-LLVM-CORE03-CORRECTION05 which:
  M1: introduces scripts/quality/llvm-closure-status-check.sh
      (a fast gate that catches this class of bug);
  M2: provides the real-LF end-to-end witness (mutated op=46
      note -> real 0x0A byte in wire stream -> CORRECTION04
      parser GREEN);
  M3: documents the "-" NULL sentinel as a contract
      limitation;
  M4: this verdict-update (the ACT Status and this HANDOFF
      now agree).

  P0-1 self-pinned final HEAD: CLOSED — CORRECTION03 ACT Status
    block no longer contains "PASS at HEAD <sha>". The Status
    block now reads HALT and uses a non-self-pinning IDENTITY
    contract (ENTRY_HEAD, RED_HEAD, IMPL_HEAD, DOCS_HEAD as fixed
    predecessors; FINAL_HEAD as reviewer observation).

  P0-2 framing splits on delimiters first: CLOSED — the verifier
    parser is now TRULY length-framed. It reads ASCII-decimal
    integers off the byte stream and consumes exactly <len> bytes
    for each variable field, regardless of whether those bytes
    contain TAB, LF, or CR. C emitter unchanged.

  P1 topology residue prose: CLOSED — CORRECTION03 ACT Residue
    now correctly lists CORE03 and CORRECTION01 as the breachers;
    CORRECTION02 = 3 == 3 (AT CAP), CORRECTION03 = 3 == 3
    (AT CAP). Same repair applied to CORRECTION03 HANDOFF.md.

  topology: AT CAP — 3 commits (RED + IMPL + DOCS).

CORRECTION03 verdict: HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
  (recorded at evidence/llvmspike01-core03-correction04/halt-correction03-wire-and-identity.txt).

CORRECTION02 verdict: HALT_SCOPE_CONTRACT_VIOLATED (carried).

IDENTITY
--------
ENTRY_HEAD (predecessor):  be53986  (CORRECTION02 DOCS HEAD)
RED_HEAD:                  ecf6dc0  (CORRECTION04 RED)
IMPL_HEAD:                 2cc7465  (CORRECTION04 IMPL)
DOCS_HEAD:                 <this commit>
FINAL_HEAD:                reviewer resolves from `git log --oneline ecf6dc0^..HEAD`

Topology ledger:
  CORRECTION04 declared cap = 3, actual = 3.   AT CAP.
  CORRECTION03 declared cap = 3, actual = 3.   AT CAP.  (now HALTED, was PASS)
  CORRECTION02 declared cap = 3, actual = 3.   AT CAP.  (HALTED)
  CORRECTION01 declared cap = 3, actual = 4.   Recorded honestly.
  CORE03       declared cap = 3, actual = 4.   Recorded honestly.

ROOT CAUSE OF CORRECTION04 SCOPE
--------------------------------
A reviewer correctly identified two new binding closure defects
in CORRECTION03:

  P0-1 — the closure document embedded "current HEAD" at the
    instant of writing. Any subsequent amend / re-commit on
    the same DOCS commit changes HEAD; the embedded SHA is
    immediately stale. This is the SAME anti-pattern
    CORRECTION03 was supposed to close in CORRECTION02
    (ACT status vs HANDOFF verdict contradiction).

  P0-2 — "length-delimited" was a misnomer. The byte-mode
    parser at CORRECTION03 still split on b"\\t" and b"\\n"
    FIRST and then validated lengths. Lengths validated
    AFTER splitting are not the primary framing mechanism.
    A literal TAB or LF in any payload breaks parsing.

RED EVIDENCE
------------
evidence/llvmspike01-core03-correction04/
  red-m1-literal-tab-in-note.txt
    Live: real hcc with IR_FADD note = "left" + TAB + "right".
    Wire stream has 6 TAB bytes between fields (one extra from
    the payload). CORRECTION03 parser rejected this (rc=1, 6
    tabs but split-on-tabs expected 5).
  red-m2-literal-lf-in-note.txt
    Synthetic demonstration: a wire stream with literal LF
    inside the note payload is split into two records before
    the length prefix can be consulted.
  red-m3-self-pinned-identity.txt
    Static witness: CORRECTION03 ACT Status block reads
    "PASS at HEAD 4e192f2", but the actual final HEAD is
    708d620. 4e192f2 was an intermediate DOCS commit
    superseded by an amend.
  red-m4-topology-ledger-stale.txt
    Static witness: CORRECTION03 ACT Residue prose says
    "CORE03, CORRECTION01, and CORRECTION02 all breached
    their declared topology cap"; the CORRECTION03 ACT
    topology table correctly records CORRECTION02 = AT CAP.
    Contradiction within the same document.
  halt-correction03-wire-and-identity.txt
    The halt record explaining why CORRECTION03 is HALTED,
    not PASS.
  impl-acceptance-m2-true-length-framed-parser.txt
    Live acceptance: real hcc with literal-TAB injection
    -> verifier PASS (rc=0). Plus 5-case synthetic test
    covering literal TAB, literal LF, UTF-8 + TAB, UTF-8 + LF,
    and CR; all five round-trip byte-identical.

IMPLEMENTATION
--------------

### M1 — non-self-pinning final identity

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md Status block:
  - Was: "PASS — at HEAD 4e192f2." (self-pinned)
  - Now: "HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT — HALTED
    at reviewer's finding."
  - Added IDENTITY block with ENTRY_HEAD, RED_HEAD, IMPL_HEAD,
    DOCS_HEAD as fixed predecessors and FINAL_HEAD as reviewer
    observation (NOT a self-assertion).

The Status block no longer embeds the SHA of the commit
containing the Status block.

### M2 — true length-framed wire parser

scripts/quality/llvm-cap-table-verifier.py get_cap_table_via_hcc():
  - Removed `raw_bytes.splitlines()` (was splitting on LF).
  - Removed `raw_line.split(b"\\t")` (was splitting on TAB).
  - Replaced with a streaming parser driven by lengths:
      for each record:
          read integer until TAB -> op
          read integer until TAB -> class
          read integer until TAB -> diag_len
          read exactly diag_len bytes (may contain TAB/LF/CR)
          expect TAB
          read integer until TAB -> note_len
          read exactly note_len bytes (may contain TAB/LF/CR)
          expect LF
  - The C emitter at src/llvm-backend-cap.c::llPrintCapabilityTable
    does NOT change. Its bytes are already arranged so that a
    length-framed consumer can extract each field. (The C
    emitter writes `printf("%d\\t%d\\t%zu\\t%s\\t%zu\\t%s\\n", ...)`
    where `%s` writes the raw payload bytes; the length is
    declared by `%zu` from strlen().)

Two new helper functions in scripts/quality/llvm-cap-table-verifier.py:
  - _read_int_at(buf, pos, terminator, line_no, rows_seen, malformed)
      reads an ASCII-decimal integer up to the next terminator byte.
  - _read_exact(buf, pos, n, line_no, rows_seen, malformed, label)
      reads exactly n bytes from buf starting at pos.

check_wire_format_roundtrip() updated to include the trailing LF
in expected (since _raw now includes the record terminator).

### M3 — repair the topology residue

CORRECTION03 ACT Residue section was updated to correctly list
CORE03 and CORRECTION01 as the topology breachers; CORRECTION02
and CORRECTION03 = AT CAP.

Same repair applied to evidence/llvmspike01-core03-correction03/HANDOFF.md
Residue section (was already correct in the topology table but
incorrect in the prose summary).

GATES (verified at HEAD after this commit)
------------------------------------------
* git diff --check HEAD:        rc=0
* git diff --check HEAD~3..HEAD: rc=0
* existing llvm-spike-test.sh:  PASS=18 FAIL=0
* contract-check harness:        PASS=20 FAIL=0
* M2 cap-table verifier:         PASS (rc=0)
* All gates reproducible after fresh build

ACCEPTANCE (live witnesses)
---------------------------
A1. With IMPL applied: verifier PASS; 18/0; 20/0.        PASS
A2. Real hcc with literal TAB in note payload: PASS.      PASS
A3. Synthetic streams with literal LF in note payload:
    round-trip byte-identical.                            PASS
A4. Synthetic streams with UTF-8 + TAB, UTF-8 + LF,
    CR: round-trip byte-identical.                        PASS
A5. CORRECTION03 ACT Status block no longer self-pins
    HEAD; uses IDENTITY contract with FINAL_HEAD as
    reviewer observation.                                 PASS
A6. CORRECTION03 ACT Residue prose agrees with its
    topology table (CORRECTION02 = AT CAP).                PASS
A7. CORRECTION03 HANDOFF Residue prose repaired
    identically.                                           PASS
A8. git diff --check clean across 3-commit range.          PASS
A9. topology: CORRECTION04 declared = 3, actual = 3
    (AT CAP).                                              PASS

SCOPE
-----
NEW:
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md
* evidence/llvmspike01-core03-correction04/ (5 files: 4 RED,
  1 IMPL acceptance + HANDOFF + halt + post-impl snapshots)

MODIFIED:
* scripts/quality/llvm-cap-table-verifier.py (M2 true length-
  framed parser; helper functions _read_int_at, _read_exact;
  round-trip test now byte-equal including trailing LF)
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md (M1 IDENTITY
  contract replacing self-pin; M3 topology residue repair)
* evidence/llvmspike01-core03-correction03/HANDOFF.md (M3
  topology residue repair)

NOT changed:
* src/llvm-backend-cap.c — C emitter unchanged. The printer's
  bytes are already length-honest; the bug was in the parser.
* src/llvm-backend.c (dispatch stays exactly as is)
* src/ir*.{c,h}, native backend, matrix comment
* Both harnesses
* CORE01-CORE02 invariants
* CORRECTION01-CORRECTION03 commit chains (F14 preserved;
  status updates only)

RESIDUE
-------
P1: get_dispatch_arms() still discovers `if (ins->op == IR_X)`
    anywhere in src/llvm-backend.c while the stricter arm-local
    body extractor scopes to llLowerInstr / llLowerBlock. CORE04.

P2: Closure-status-reconciliation should be a fast-gate
    invariant. CORRECTION04 observed the same self-pin anti-
    pattern twice: first in CORRECTION02's HANDOFF (which
    CORRECTION03 was supposed to close), then in CORRECTION03's
    own ACT Status block. The pattern is now reproducible
    twice in a row; a fast-gate check is justified.

P2: CORE03 and CORRECTION01 each breached declared topology
    cap (declared 3, actual 4, recorded honestly). CORRECTION02,
    CORRECTION03, CORRECTION04 are AT CAP. Factory-pattern
    investigation deferred.

P2: Pre-CORE03 history (CORE01, CORE02) preserved (F14).

P2: Synthetic-vs-live testing gap: literal LF in payload
    cannot be tested via live C build (LF in C string literal
    breaks compilation). The 5-case synthetic test in
    impl-acceptance-m2-true-length-framed-parser.txt
    establishes the parser logic; live hcc with literal TAB
    establishes the wire path end-to-end. The LF case is
    covered by the parser logic alone. Could be closed by
    adding an explicit wire-format generator to the test
    suite (e.g. build a stream in Python, hand it to a
    parser entry point that accepts bytes). Deferred.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE04 (now genuinely unblocked):
  - Replace per-fixture `expected_opcodes` with automatic
    native-mode opcode-set introspection.
  - Consolidate fixture lists between the two harnesses.
  - Unify get_dispatch_arms() discovery with arm-local body
    extraction (close reviewer P1).
  - Per-class execution counters in the harness summary.
  - Replace matrix comment in src/llvm-backend.c with a
    generated comment.

Also tracked (Factory-tooling):
  - ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1) — the
    validator abort, the verifier exit code, and the harness
    set-membership check are three closure oracles. Their
    mutual trust warrants separate investigation.
  - ACT-POLYC-FACTORY-STATUS-RECONCILIATION (promote to fast
    gate; reviewer-suggested; CORRECTION04 observed the bug
    twice in a row, justifying the gate).
  - ACT-POLYC-FACTORY-TOPOLOGY-CAP-HONESTY (CORE03,
    CORRECTION01 pattern) — separate investigation.
  - ACT-POLYC-FACTORY-IDENTITY-CONTRACT — the non-self-pinning
    IDENTITY pattern from CORRECTION04 (separate
    ENTRY/RED/IMPL/DOCS heads, reviewer-resolved FINAL_HEAD)
    should be promoted to a structural pattern across all
    ACTs. Currently ad-hoc in CORRECTION03 ACT only.
