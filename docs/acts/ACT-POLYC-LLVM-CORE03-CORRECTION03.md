# ACT-POLYC-LLVM-CORE03-CORRECTION03

## Status

OPEN — legitimising CORRECTION02's two out-of-scope row corrections
and tightening the wire parser to byte-mode (closing the ASCII-only
false-claim). Bounded, minimal.

Predecessor: ACT-POLYC-LLVM-CORE03-CORRECTION02 (verdict:
HALT_SCOPE_CONTRACT_VIOLATED at HEAD be53986).

## Verdict at OPEN

A reviewer correctly rejected CORRECTION02's PASS. CORRECTION02's
ACT (docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md lines 141-145
and 154) explicitly authorised only the M1 wire-format hardening of
src/llvm-backend-cap.c, and placed "Changing the actual diagnostic
macro values" under Out of scope. The IMPL commit 857ecf2 nonetheless
modified two capability rows:

  IR_ALLOCA:  LLVM_BACKEND_UNSUPPORTED_MEMORY  ->  POINTER
  IR_CMP_BR:  "(boundary violation ...)"      ->  LLVM_BACKEND_INTERNAL

Those are pre-existing binding defects (the dispatch arms already
emit POINTER / INTERNAL; only the table said otherwise). They are
mechanically correct, but procedurally out of scope under F7/F15.
CORRECTION03 legitimises them.

Two further reviewer findings:

  P1-stale-status: CORRECTION02's own ACT says "Status: OPEN" while
                   its HANDOFF says VERDICT: PASS. Reproduces the
                   very bug CORRECTION02 was supposed to close in
                   CORRECTION01. (CORRECTION02 is HALTED in IMPL of
                   this ACT; see M3.)

  P1-ASCII-only:   The "length-delimited" wire format uses C
                   strlen() (byte count) for length prefixes, but
                   the Python verifier decodes the stream as UTF-8
                   and uses Python len() (code-point count). For
                   today's ASCII-only rows the two are equal; for
                   any future non-ASCII payload (e.g. UTF-8 "→" =
                   3 bytes / 1 code point) the verifier rejects a
                   valid C-produced record. CORRECTION03 tightens
                   the parser to byte-mode. (See M2.)

A fourth reviewer observation noted that get_dispatch_arms() still
discovers `if (ins->op == IR_X)` ANYWHERE in src/llvm-backend.c
while the stricter body extractor scopes to llLowerInstr /
llLowerBlock. This is real but P1, not P0; recorded as residue for
CORE04 (unify discovery around one scoped dispatch model).

## Scope (cap = RED + IMPL + DOCS = 3 commits; strict per F12)

### M1 — legitimise the two capability-row corrections

The CORRECTION02 ACT identified these as binding defects surfaced
by M2's arm-local check. CORRECTION03 is the bounded ACT that
authorises the actual table edits. The values already in HEAD
be53986 from CORRECTION02 are kept verbatim; M1 authorises them.

  Row IR_ALLOCA (ordinal 1):
    diagnostic -> LLVM_BACKEND_UNSUPPORTED_POINTER
    note       -> LLVM_BACKEND_UNSUPPORTED_POINTER (grouped with
                  IR_LOAD_DEREF/STORE_DEREF/RMW_DEREF/LEA in the
                  dispatch; POINTER, not MEMORY.)

  Row IR_CMP_BR (ordinal 45):
    diagnostic -> LLVM_BACKEND_INTERNAL
    note       -> LLVM_BACKEND_INTERNAL (the if-arm in llLowerBlock
                  that handles branch-on-comparison emits INTERNAL
                  because reaching this arm means the
                  neutral/native boundary has been crossed).

RED: revert one of the two rows to its pre-CORRECTION02 value and
### M2 — byte-mode wire parser

The C emitter writes byte-lengths via strlen(); the verifier should
frame by bytes and decode field payloads only after slicing by byte
length. Today the parser reads text=True from subprocess and uses
str.__len__(), which counts code points.

Fix: scripts/quality/llvm-cap-table-verifier.py — open the wire
output as raw bytes, parse lengths as ASCII decimal integers, slice
fields as bytes via those integer offsets, and decode each field as
UTF-8 after framing. The M1 round-trip test continues to assert
byte-equality of the raw wire line.

RED: temporarily inject a non-ASCII note payload into one capability
row (e.g. append " -> END" with a UTF-8 arrow to the note for a
single row), rebuild hcc, run the existing ASCII-mode parser (in the
IMPL commit, restore byte-mode), and capture the RED:

  - ASCII-mode parser: re-encodes each field via field.encode("utf-8")
    and re-compares the line. A row whose note contains a multi-byte
    UTF-8 codepoint has len(field) < len(field.encode("utf-8")), so
    the slice in the wire format consumes only code-point-many bytes,
    not byte-many bytes. Round-trip fails.

The non-ASCII injection is reverted before IMPL closes (per F3 RED
must use real production seam; the injection is a real seam
mutation, reverted before commit per F8/F13).

### M3 — close CORRECTION02's stale ACT/HANDOFF status

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md is updated in IMPL
of this ACT so that the contradiction with its HANDOFF is resolved:
status is set to HALT_SCOPE_CONTRACT_VIOLATED with a Supersession
block pointing to CORRECTION03. Commit history preserved (F14).

## Out of scope (F7)

  - Full fixture -> opcode-set automatic decoding. (CORE04.)
  - Replacing the matrix comment in src/llvm-backend.c with a
    generated comment. (CORE04.)
  - Per-class execution counters in the harness. (CORE04.)
  - Consolidating fixture list between the two harnesses. (CORE04.)
  - Unifying get_dispatch_arms() discovery with arm-local body
    extraction into one scoped dispatch model. (CORE04.)
  - Any other row content edits in src/llvm-backend-cap.c.
  - Any edits to src/llvm-backend.c (dispatch stays exactly as is).
  - Any edits to src/ir*.{c,h}.
  - The native backend.
  - Adding new LLVM_BACKEND_* macros.
  - Refactoring llPrintCapabilityTable beyond what's needed for the
    byte-mode round-trip to remain true (no wider format changes).
  - Resurrecting CORRECTION02's HANDOFF as PASS — it is preserved
    for F14 evidence only.

## Files authorised for change

NEW:
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md (this file)
  evidence/llvmspike01-core03-correction03/* (RED + IMPL evidence)

MODIFIED:
  src/llvm-backend-cap.c
                            (M1: legitimise IR_ALLOCA -> POINTER and
                             IR_CMP_BR -> INTERNAL. Values already
                             in HEAD be53986 from CORRECTION02 are
                             kept verbatim; M1 authorises them.)
  scripts/quality/llvm-cap-table-verifier.py
                            (M2: parse wire as raw bytes; decode
                             field payloads after framing)
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md
                            (M3: Status -> HALT_SCOPE_CONTRACT_VIOLATED,
                             Supersession block to CORRECTION03)

NOT authorised (F7):
  - src/ir*.{c,h}
  - src/llvm-backend.c
  - The native backend
  - scripts/quality/llvm-spike-test.sh
  - scripts/quality/llvm-spike-contract-check.sh
  - Any other capability row in src/llvm-backend-cap.c

## Gate profile

  git diff --check HEAD~N..HEAD: rc=0   (N = CORRECTION03 commits = 3)
  make clean && make llvm-all: succeeds
  existing llvm-spike-test.sh: PASS=18 FAIL=0
  contract-check harness:      PASS=20 FAIL=0
  cap-table verifier:          PASS (rc=0)
  M1 RED witness:              one row reverted -> verifier REDs
  M2 RED witness:              non-ASCII note -> ASCII-mode parser
                                REDs on byte-vs-codepoint mismatch
  Topology:                    ACTUAL <= cap (strict, declared = 3)

## Acceptance criteria

  A1. With IMPL applied: verifier PASS; 18/0; 20/0.
  A2. Revert IR_ALLOCA row to MEMORY -> verifier REDs with
      "diagnostic NOT in this arm's body" (M1 proof).
  A3. Revert IR_CMP_BR row to descriptive string -> verifier REDs
      with same shape (M1 proof).
  A4. Inject non-ASCII note payload into one row; run ASCII-mode
      parser (revert parser) -> round-trip REDs (M2 proof).
  A5. CORRECTION02.md status reconciled (no longer contradicts its
      HANDOFF).
  A6. git diff --check clean across the 3-commit range.

## Residue

P1: get_dispatch_arms() still discovers `if (ins->op == IR_X)`
    anywhere in src/llvm-backend.c while the stricter arm-local
    body extractor scopes to llLowerInstr / llLowerBlock. A future
    REJECTED opcode without a real handler could be satisfied by an
    unrelated `if (ins->op == ...)` elsewhere. CORE04 should unify
    discovery around one scoped dispatch model.

P2: Closure status reconciliation should become a fast-gate
    invariant: if evidence/<act>/HANDOFF says VERDICT=PASS then
    docs/acts/<act>.md must not say Status: OPEN. Currently checked
    manually for each ACT.

P2: CORE03, CORRECTION01, and CORRECTION02 all breached their
    declared topology cap (declared 3, actual 4 in each case,
    recorded honestly). CORE03-CORRECTION03 declares 3 and aims for
    3. (Reviewer noted this as a pattern worth addressing at the
    factory level — out of scope here.)

P2: Pre-CORE03 history (CORE01, CORE02) preserved (F14).
observe the M2 arm-local checker REDs with the exact "diagnostic
NOT in this arm's body" message for that row.
