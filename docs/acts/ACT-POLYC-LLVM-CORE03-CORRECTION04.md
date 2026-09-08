# ACT-POLYC-LLVM-CORE03-CORRECTION04

## Status

HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE — at CORRECTION05
closure. Two binding closure defects identified by the
reviewer:

  P0-1: this Status block previously read "OPEN" while the
         HANDOFF read "PASS". The reviewer correctly observed
         that the closure-status-reconciliation defect has
         now been reproduced three times in a row
         (CORRECTION02, CORRECTION03, CORRECTION04). Closed
         by ACT-POLYC-LLVM-CORE03-CORRECTION05 M1
         (scripts/quality/llvm-closure-status-check.sh).
  P0-2: A5's "literal LF end-to-end" claim was only backed by
         a synthetic witness; the C emitter's "
" escape
         was not exercised. Closed by CORRECTION05 M2
         (evidence/llvmspike01-core03-correction05/red-m1-real-lf-in-runtime-payload.txt).
  P1:  the "-" NULL sentinel is an inherent value-collision;
         documented by CORRECTION05 M3 as a contract
         limitation (no protocol redesign in this ACT).
  P0-2: framing still splits on delimiters first; lengths are
         validated, not used to slice. A literal TAB or LF in
         the payload breaks parsing.

Plus one P1 docs defect:

  P1:   CORRECTION03 ACT Residue prose incorrectly claims
         CORRECTION02 breached its declared topology cap.
         CORRECTION02 is AT CAP (3 == 3); only CORE03 and
         CORRECTION01 breached.

Predecessor: ACT-POLYC-LLVM-CORE03-CORRECTION03
(verdict: HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT at
HEAD 708d620).

## Mission

### M1 — non-self-pinning final identity

Replace the `PASS at HEAD <sha>` form with a non-self-referential
identity contract:

```text
Status: PASS

IDENTITY:
    ENTRY_HEAD = <fixed predecessor>     ; resolved at RED time
    RED_HEAD   = <fixed at RED commit>
    IMPL_HEAD  = <fixed at IMPL commit>
    FINAL_HEAD = reviewer resolves from repository topology
```

The Status block SHALL NOT contain a SHA that resolves to the
commit containing the Status block. FINAL_HEAD is a reviewer
observation, not a self-assertion.

### M2 — true length-framed wire parser

Today the verifier's `get_cap_table_via_hcc()` parses rows by:

  split on b"\\n"  ->  split on b"\\t"  ->  validate lengths

So the delimiters (TAB, LF) are read as structure, not as data.
That fails for any payload containing a literal TAB or LF.

Make it genuinely length-framed: the parser consumes exactly
`<diag_len>` bytes after the `<diag_len>\\t` prefix, and exactly
`<note_len>` bytes after the `<note_len>\\t` prefix, regardless
of whether those bytes contain TAB or LF.

```text
for each record:
    read integer until TAB             -> op
    read integer until TAB             -> class
    read integer until TAB             -> diag_len
    read exactly diag_len bytes        -> diag payload (may contain TAB/LF)
    expect TAB
    read integer until TAB             -> note_len
    read exactly note_len bytes        -> note payload (may contain TAB/LF)
    expect LF (or EOF if last record)
```

The C emitter (src/llvm-backend-cap.c::llPrintCapabilityTable) does
NOT need to change — its `printf("%d\\t%d\\t%zu\\t%s\\t%zu\\t%s\\n", ...)`
already produces a sequence that a length-framed parser can
consume. The only required change is in the verifier.

After M2 the parser MUST handle:

  * `note = "left\\tright"`         (literal TAB in payload)
  * `note = "line1\\nline2"`        (literal LF in payload)
  * `note = "→"`                     (3-byte UTF-8; covered by M2-ASCII test)
  * `note = "→\\tEND"`              (multi-byte + literal TAB)

### M3 — repair the topology residue

CORRECTION03 ACT Residue section currently says:

> P2: CORE03, CORRECTION01, and CORRECTION02 all breached their
>     declared topology cap (declared 3, actual 4 in each case...)

This is false for CORRECTION02 (actual = 3, AT CAP). The CORRECTION03
HANDOFF already correctly says CORRECTION02 = AT CAP, but the
ACT Residue contradicts the HANDOFF ledger.

Repair CORRECTION03 ACT Residue prose so it agrees with the
CORRECTION03 ACT topology table (which already records CORRECTION02
correctly). No historical rewriting of CORRECTION02 commit chain
(F14).

### M4 — wire-format round-trip test that handles literal TAB/LF

The current `check_wire_format_roundtrip()` re-emits the parsed
row and compares to the original wire line. After M2, it must
compare byte-equal even when the original payload contained
literal TAB or LF.

## Out of scope (F7)

  - Replacing the wire format entirely (no escape protocol).
  - Tightening the C emitter's `%zu` printing (already byte-correct).
  - Core04 work (auto decoding, fixture consolidation, etc.).
  - CORRECTION01/CORRECTION02 commit chains (F14 preserved).
  - The native backend.

## Files authorised for change

NEW:
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md (this file)
  evidence/llvmspike01-core03-correction04/* (RED + IMPL + halt)

MODIFIED:
  scripts/quality/llvm-cap-table-verifier.py
                              (M2: true length-framed parser;
                               M4: round-trip survives TAB/LF in payload)
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md
                              (M1: replace self-pinned HEAD with IDENTITY
                                   contract;
                               M3: repair topology residue prose;
                               Status: -> PASS at CORRECTION04 closure)
  evidence/llvmspike01-core03-correction03/HANDOFF.md
                              (M3: status sync with CORRECTION03 ACT)

NOT authorised (F7):
  - src/llvm-backend-cap.c  (C emitter is already length-honest;
                             the bug is in the Python parser.)
  - src/llvm-backend.c, src/ir*.{c,h}, native backend
  - Both harnesses
  - CORE01-CORE02 invariants
  - CORRECTION01-CORRECTION03 commit chains (F14 preserved;
    status updates only)

## Acceptance criteria

A1. After IMPL: existing harness PASS=18, FAIL=0.
A2. After IMPL: contract harness PASS=20, FAIL=0.
A3. After IMPL: cap-table verifier PASS (rc=0).
A4. RED witness `red-m1-literal-tab-in-note.txt` (rc=1) reproduces on
    the pre-IMPL parser; the same mutation GREENs the post-IMPL
    parser.
A5. RED witness `red-m2-literal-lf-in-note.txt` (rc=1) reproduces on
    the pre-IMPL parser; the same mutation GREENs the post-IMPL
    parser.
A6. CORRECTION03 ACT status block: "PASS" with IDENTITY contract;
    no SHA pinned to the commit containing the status block.
A7. CORRECTION03 ACT Residue prose agrees with its topology table
    (CORRECTION02 = AT CAP).
A8. git diff --check clean across the CORRECTION04 commit range.
A9. topology: CORRECTION04 declared cap = 3, actual = 3 (AT CAP).

## Residue (carried from CORRECTION03)

P1: get_dispatch_arms() still discovers `if (ins->op == IR_X)`
    anywhere in src/llvm-backend.c while the stricter arm-local
    body extractor scopes to llLowerInstr / llLowerBlock. CORE04.
P2: Closure-status-reconciliation should be a fast-gate invariant
    (this ACT itself observed the bug twice; first in CORRECTION02
    HANDOFF, then in CORRECTION03 ACT's self-pinned HEAD).

## Topology

CORRECTION04 declared cap: 3 commits (RED + IMPL + DOCS).
