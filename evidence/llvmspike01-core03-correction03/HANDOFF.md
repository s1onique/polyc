HANDOFF — ACT-POLYC-LLVM-CORE03-CORRECTION03
==========================================

VERDICT
-------
PASS

CORRECTION03 closes every defect the reviewer flagged on
CORRECTION02's PASS (HALT_SCOPE_CONTRACT_VIOLATED):

  P0-scope:        CLOSED — the two capability-row edits
                          (IR_ALLOCA -> POINTER, IR_CMP_BR ->
                          INTERNAL) are now authorised by a
                          bounded ACT. The row values that
                          already exist in HEAD (committed by
                          CORRECTION02 IMPL 857ecf2) are kept
                          verbatim and CORRECTION03 legitimises
                          them. Row content stays at the
                          CORRECTION02 values; the only
                          production change in CORRECTION03 is
                          the parser.
  P1-stale-status: CLOSED — CORRECTION02's status now reads
                          HALT_SCOPE_CONTRACT_VIOLATED with a
                          Supersession block pointing to
                          CORRECTION03. The contradiction
                          between ACT status and HANDOFF is
                          resolved.
  P1-ASCII-only:   CLOSED — verifier parser now frames on
                          raw bytes. The C strlen()-written
                          length prefixes are interpreted as
                          byte counts. Multi-byte UTF-8
                          payloads now round-trip
                          correctly.
  topology:        AT CAP — 3 commits (RED + IMPL + DOCS).

CORRECTION02 verdict: HALT_SCOPE_CONTRACT_VIOLATED
  (recorded at evidence/llvmspike01-core03-correction03/halt-correction02-scope-contract-violated.txt).

IDENTITY
--------
Entry:    be53986 (CORRECTION02 DOCS HEAD, the HALT point)
RED:      b382f73 (CORRECTION03 ACT + 4 RED evidence files)
IMPL:     4508f51 (CORRECTION03 M2 byte-mode parser + M3 CORRECTION02 status)
DOCS:     (this commit)
HEAD:     (this commit)

Total CORRECTION03 commits: 3. AT CAP.

Topology ledger:
  CORRECTION03 declared cap = 3, actual = 3.   AT CAP.
  CORRECTION02 declared cap = 3, actual = 3.   AT CAP.
  CORRECTION01 declared cap = 3, actual = 4.   Recorded honestly.
  CORE03       declared cap = 3, actual = 4.   Recorded honestly.

ROOT CAUSE OF CORRECTION03 SCOPE
--------------------------------
A reviewer correctly rejected CORRECTION02's PASS for three reasons:

  1. CORRECTION02's own ACT explicitly listed "Changing the actual
     diagnostic macro values in src/llvm-backend-cap.c" under "Out
     of scope (F7)" (lines 141-145). The IMPL commit 857ecf2
     nonetheless modified two rows (IR_ALLOCA -> POINTER,
     IR_CMP_BR -> INTERNAL). Those edits are mechanically correct
     (they match what the dispatch arms already emit), but they
     were not authorised. This is the F7/F15 failure mode the
     Factory doctrine names: "new evidence discovers additional
     necessary production change ≠ existing ACT automatically
     authorises that change."

  2. CORRECTION02's own ACT/HANDOFF status was contradictory
     (ACT=OPEN, HANDOFF=PASS) — the exact bug CORRECTION02 was
     supposed to close in CORRECTION01.

  3. The wire format's "byte-length-delimited" claim was only true
     for ASCII: C writes strlen() (byte count), Python parsed with
     str.__len__() (code-point count). The two agree for ASCII only.

RED EVIDENCE
------------
evidence/llvmspike01-core03-correction03/
  red-m1-ir-alloca-reverted-to-memory.txt
    Live: revert IR_ALLOCA row to MEMORY -> M2 arm-local checker
    REDs with "diagnostic 'LLVM_BACKEND_UNSUPPORTED_MEMORY' NOT in
    this arm's body. Appears in: <none>". verifier rc=1.
  red-m1-ir-cmp-br-reverted-to-descriptive-string.txt
    Live: revert IR_CMP_BR row to "(boundary violation - native
    fusion)" -> M2 arm-local checker REDs with "diagnostic
    '(boundary violation - native fusion)' NOT in this arm's body".
    verifier rc=1.
  red-m2-non-ascii-note-in-ir-fadd.txt
    Live: append " -> END" (with real U+2192, 3 bytes/1 code point)
    to IR_FADD note -> ASCII-mode parser REDs with "note length
    mismatch: header says 44, actual 42" (C strlen=44 bytes, Python
    len=42 code points). verifier rc=1.
  halt-correction02-scope-contract-violated.txt
    The halt record explaining why CORRECTION02 is HALTED, not PASS.
  impl-acceptance-m2-non-ascii-byte-mode.txt
    Live: same UTF-8 mutation, byte-mode parser in place -> verifier
    PASS. Row 17 (IR_FADD) wire line:
        17  1  36  LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH  44  LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH -> END
    The note length 44 = strlen() of the UTF-8 payload; Python
    parser correctly slices 44 bytes and decodes them as UTF-8.

IMPLEMENTATION
--------------

### M1 — legitimise the two capability-row corrections

NO source code change. The row values already in HEAD (committed
by CORRECTION02 IMPL 857ecf2) are the legitimate values per this
ACT:

  Row IR_ALLOCA:   diagnostic = LLVM_BACKEND_UNSUPPORTED_POINTER
  Row IR_CMP_BR:   diagnostic = LLVM_BACKEND_INTERNAL

The reasoning: the dispatch arms in src/llvm-backend.c emit these
exact macros; the pre-CORRECTION02 table values were a historical
table-vs-dispatch drift. CORRECTION03 is the bounded ACT that
authorises the row corrections CORRECTION02 made out of scope.

### M2 — byte-mode wire parser

scripts/quality/llvm-cap-table-verifier.py get_cap_table_via_hcc():
  - subprocess.check_output returns bytes (unchanged call site).
  - raw_bytes = out (no decode).
  - splitlines() now operates on bytes.
  - Each line is split on b'\t' (6 byte fields).
  - Length fields are parsed from ASCII-decimal bytes.
  - Field payload slicing uses len(f4) (byte count) and compares to
    the integer length the C emitter wrote. If they match, the
    field is correct as bytes.
  - Decode to UTF-8 ONLY after framing, for downstream use.
  - The literal "-" sentinel is detected as b'-' (1 byte) with
    header length 1, treated as NULL.
  - The round-trip test in check_wire_format_roundtrip() now
    constructs expected as bytes using len(field.encode("utf-8"))
    and compares against row["_raw"] (bytes). UTF-8 payloads
    round-trip exactly.

The check_wire_format_roundtrip round-trip assertion continues to
guarantee byte-equality between printer and parser.

### M3 — close CORRECTION02's stale ACT/HANDOFF status

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md status block:
  - Status: OPEN -> HALT_SCOPE_CONTRACT_VIOLATED
  - Added Supersession block pointing to CORRECTION03.
  - Verdict-at-HALT breakdown: in-scope items PASS, out-of-scope
    items deferred to CORRECTION03.
  - Commit history preserved (F14): b42480d, 857ecf2, be53986.

GATES (verified at HEAD)
------------------------
* git diff --check HEAD:        rc=0
* git diff --check HEAD~3..HEAD: rc=0
* existing llvm-spike-test.sh:  PASS=18 FAIL=0
* contract-check harness:        PASS=20 FAIL=0
* M2 cap-table verifier:         PASS (rc=0)
* All three gates reproducible after `rm -f *.o hcc && make -C build`

ACCEPTANCE (live witnesses)
---------------------------
A1. With IMPL applied: verifier PASS; 18/0; 20/0.        PASS
A2. Revert IR_ALLOCA to MEMORY -> M2 arm-local REDs.    PASS (rc=1)
A3. Revert IR_CMP_BR to descriptive string -> REDs.     PASS (rc=1)
A4. Inject non-ASCII note -> ASCII-mode parser REDs.    PASS (rc=1)
    Same injection -> byte-mode parser GREENs.          PASS (rc=0)
A5. CORRECTION02 status reconciled.                    PASS
A6. git diff --check clean across 3-commit range.       PASS

SCOPE
-----
NEW:
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md
* evidence/llvmspike01-core03-correction03/* (5 files)

MODIFIED (HARDENING — check made stricter, not weaker):
* scripts/quality/llvm-cap-table-verifier.py (M2 byte-mode parser;
   round-trip test now uses UTF-8 byte lengths)
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md (M3 status
   reconciled; commit history preserved per F14)

NOT changed:
* src/llvm-backend-cap.c — row values were already correct in HEAD
  from CORRECTION02 IMPL 857ecf2; CORRECTION03 legitimises them
  but does not alter them. (Authorisation, not re-implementation.)
* src/llvm-backend.c (dispatch stays exactly as is)
* src/ir*.{c,h}
* The native backend
* The matrix comment in src/llvm-backend.c
* scripts/quality/llvm-spike-test.sh
* scripts/quality/llvm-spike-contract-check.sh
* CORE01-CORE02 invariants (preserved)
* CORRECTION01 / CORRECTION02 commit chains (F14)

RESIDUE
-------
P1: get_dispatch_arms() still discovers `if (ins->op == IR_X)`
    anywhere in src/llvm-backend.c while the stricter arm-local
    body extractor scopes to llLowerInstr / llLowerBlock. A future
    REJECTED opcode without a real handler could be satisfied by an
    unrelated `if (ins->op == ...)` elsewhere. CORE04 should unify
    discovery around one scoped dispatch model.

P2: Closure status reconciliation should become a fast-gate
    invariant: if evidence/<act>/HANDOFF says VERDICT=PASS then
    docs/acts/<act>.md must not say Status: OPEN. Currently
    checked manually for each ACT. (Could be encoded as a
    gate-fast check that greps for "Status: OPEN" in ACTs whose
    HANDOFF says PASS.)

P2: CORE03 and CORRECTION01 each breached declared topology cap
    (declared 3, actual 4, recorded honestly). CORRECTION02 = 3 == 3
    (AT CAP). CORRECTION03 = 3 == 3 (AT CAP). The Factory pattern
    of "declared 3, actual 4" deserves a separate investigation.

P2: Pre-CORE03 history (CORE01, CORE02) preserved (F14).

NEXT ACT
--------
ACT-POLYC-LLVM-CORE04 (deferred):
- Replace per-fixture `expected_opcodes` with automatic
  native-mode opcode-set introspection.
- Consolidate fixture lists between the two harnesses.
- Unify get_dispatch_arms() discovery with arm-local body
  extraction (close reviewer P1).
- Per-class execution counters in the harness summary.
- Replace matrix comment in src/llvm-backend.c with a generated
  comment.

Also tracked (Factory-tooling):
- ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1) — the validator
  abort, the verifier exit code, and the harness set-membership
  check are three closure oracles. Their mutual trust warrants
  separate investigation.
- ACT-POLYC-FACTORY-STATUS-RECONCILIATION (new) — promote the
  "ACT status must match HANDOFF verdict" check to a fast gate.
- ACT-POLYC-FACTORY-TOPOLOGY-CAP-HONESTY — investigate the
  pattern of declared-cap-3-actual-4 across CORE03, CORRECTION01.
