# ACT-POLYC-SELFHOST-LEXER02-CORRECTION05

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair CORRECTION04 closure-truth defects (FALSE_GREEN
on `58a89cc`): mandatory negative controls, exact byte-equality
predicate, authorized PolyC SHA-256, exact-vs-invariant corpus
contract, deterministic TSV serialization, fresh Factory gates, and
predecessor identity binding.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** CORRECTION (FACTORY-GOVERNANCE / CLOSURE-TRUTH)

**Predecessor (binding):**
ACT-POLYC-SELFHOST-LEXER02-CORRECTION04 CLOSED at `58a89cc`
(reviewer verdict: `CORRECTION04_CLOSE_PASS=FALSE_GREEN`).
The actual closed predecessor of CORRECTION04 was
ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 CLOSED at `6abde99`;
CORRECTION04's HANDOFF mis-records the predecessor as `35c67ac`
(which is CORRECTION04's own C2 IMPL commit) — that defect is
listed below as P1-7 and is repaired inside CORRECTION05.

**Production semantic changes:** FORBIDDEN.
This ACT mutates only the PolyC tooling layer
(`tools/quality/lexer07-*.HC`, the matching ≤50 LOC shell
wrappers, and the Makefile/LEGACY-TSV bindings where the build
flow dictates), the C05 evidence directory, and this ACT's
hand-off artifact. Production source (lexer, parser, IR, codegen,
library headers) is NOT touched. CORRECTION02 / CORRECTION03 /
CORRECTION04 history is NOT rewritten (F14).

**IR / ABI / LLVM authorization:** NONE.

**ACT-Supersedes:** ACT-POLYC-SELFHOST-LEXER02-CORRECTION04
(for the seven closure-truth defects enumerated below; not for
CORRECTION04's substantive PolyC tooling, which is retained).

**Reviewer verdict on predecessor (`58a89cc`):**
`CORRECTION04_CLOSE_PASS=FALSE_GREEN` (this audit is recorded
verbatim in `docs/ROADMAP.md` under the CORRECTION05 status
block; F14 forbids rewriting the CORRECTION04 evidence
directory).

---

## 0. Mission

Repair the seven closure-truth defects observed at
`ACT-POLYC-SELFHOST-LEXER02-CORRECTION04` (`58a89cc`) WITHOUT
rewriting or amending CORRECTION04 history and WITHOUT touching
the substantive PolyC tooling it introduced. The seven defects
are listed in §1 verbatim from the reviewer audit and matched
1-to-1 against the ACs in §6.

The substantive CORRECTION04 implementation
(`tools/quality/lexer07-fixture-inventory.HC` 395 LOC;
`tools/quality/lexer07-broad-corpus-4-stage.HC` 408 LOC) is
preserved; CORRECTION05 modifies only the predicate surfaces
(hash family, byte-equality test, TSV serialization), the
missing three mutation-test controls, and the missing fresh
gate evidence. Shell wrappers remain ≤50 LOC dispatch glue
(`lexer07-fixture-inventory.sh` 14 LOC;
`lexer07-broad-corpus-4-stage.sh` 16 LOC).

When this ACT closes, the CORRECTION02 contract (`89 / 33 / 16`
floor inventory and `166+9 / 6 / 0` broad corpus) will be
reproduced from a clean destination with:

* a real `MemCmp`-based byte-equality predicate (not FNV hash
  equality);
* a PolyC-local SHA-256 implementation (the ACT-authorized
  primitive; FNV-1a is demoted to a secondary identifier);
* three real negative-control mutation tests
  (AC05/AC06/AC07) that *mechanically* reject a stub binary, a
  corrupted stage0 fallback, and a mutated fixture table;
* a deterministic 89-data-row TSV (TSV cells escape control
  bytes rather than emitting literal separators);
* fresh `gate-fast` and `factory-closure-status-check`
  evidence in the C3 closure packet;
* correct predecessor identity binding in the HANDOFF
  (`6abde99` for CORRECTION03 CLOSE, not `35c67ac`).

## 1. Why — the seven defects observed at `58a89cc`

The reviewer audit (recorded verbatim in the ROADMAP CORRECTION05
status block) enumerated the following defects in CORRECTION04.
Each defect is paired with the AC in §6 that mechanically
closes it. F-NO-PYTHON and append-only history are preserved
throughout; F5 forbids weakening any pre-existing gate.

### P0-1 — Mandatory acceptance criteria silently demoted to residue

CORRECTION04 §6 listed three mandatory acceptance criteria:

* `AC05 STUB_BINARY_NEGATIVE_CONTROL=PASS`
* `AC06 CORRUPT_OBJECT_NEGATIVE_CONTROL=PASS`
* `AC07 FIXTURE_MUTATION_NEGATIVE_CONTROL=PASS`

CORRECTION04's C4 HANDOFF (§RESIDUE P1) reclassifies all three
as *"not implemented in this C2; tracked as residue for the
next ACT"*. An ACT cannot demote its own mandatory ACs to
residue during closure without an explicit, separately
authorized contract revision. The three ACs are therefore
**NOT SATISFIED** at `58a89cc`, and the CORRECTION04 closure
verdict is `FALSE_GREEN` on that ground alone.

### P0-2 — FNV-1a equality is not byte equality

The CORRECTION04 broad-corpus tool classifies a source as
`BYTE_IDENTICAL_4` when the four 64-bit FNV-1a values agree:

```text
h0 == h1 && h1 == h2 && h2 == h3
```

FNV-1a is a non-cryptographic, finite-width hash; collisions
are possible (RFC 9923 explicitly calls FNV
non-cryptographic). The asserted predicate is
`BYTE_IDENTICAL_4`, not `FNV64_EQUAL_4`. The mechanically
correct predicate is:

```text
size0 == size1 == size2 == size3
&& MemCmp(b0,b1,size0) == 0
&& MemCmp(b0,b2,size0) == 0
&& MemCmp(b0,b3,size0) == 0
```

### P0-3 — ACT explicitly required SHA-256; implementation substituted FNV post hoc

CORRECTION04 §0 ("compute SHA-256 of the produced .o files
IN POLYC … the PolyC tool itself implements the SHA-256
round function") and §5 (PolyC-local SHA-256 is the only
sanctioned mechanism) are unambiguous. The implementation
instead uses FNV-1a, and the C4 HANDOFF retroactively labels
SHA-256 as P1 residue. That is contract drift: the
authorized implementation was SHA-256, the implemented
implementation is FNV-1a, and no authorized amendment was
recorded.

### P0-4 — Gate does not enforce the advertised CORRECTION02 contract

At the bottom of the CORRECTION04 broad-corpus tool, success
is effectively `regression == 0 && pass_mismatch == 0`. The
ACT explicitly requires
`CURRENT_4_STAGE_BYTE_IDENTICAL=166,
 HISTORICAL_S0_BASELINED_4_WAY_EQ=9,
 TOTAL_EQUIVALENCE_COVERAGE=175,
 BOTH_FAIL_4=6,
 DIVERGED=0,
 REGRESSION=0,
 PASS_MISMATCH=0`. A regression tool that does not enforce
those literal counts will return PASS even if the asserted
CORRECTION02 contract has silently changed (e.g. all 9
historical failures start compiling successfully and all 181
outputs agree). The tool must therefore expose either:

* an **invariant contract** that does not name literal counts
  but is provably equivalent to "no regression"; or
* the **literal CORRECTION02 counts** as a hard success
  predicate.

CORRECTION05 picks the second (because it is what the ACT
authorized) AND introduces the three negative controls
(P0-1) so that the tool's pass predicate itself is
mechanically exercised.

### P1-5 — TSV with embedded newline is malformed

CORRECTION04 §0 explicitly requires a deterministic
89-row `fixture-inventory.tsv`. The on-disk artifact at
`evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/fixture-inventory.tsv`
contains 91 physical lines but the `hex_0xff_no_semi`
record is split across two physical lines because the
fixture's source text `0xff` was emitted as a literal TSV
cell without escaping the embedded newline that the PolyC
parser converts from C `\n`. The TSV writer
(`SanitizeCell`) only replaces tab characters, not CR/LF.
One logical record is therefore corrupted (11 columns
instead of 12), contradicting the ACT's deterministic
89-row requirement.

### P0-6 — Mandatory Factory gates missing from C4 evidence

The ACT lists four gate ACs:

* `AC08 shell-loc-gate PASS`
* `AC09 gate-fast PASS`
* `AC10 factory-no-python-check PASS`
* `AC11 factory-closure-status-check PASS`

The C3 evidence file at
`evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/c3-required-result.txt`
shows fresh proofs for `shell-loc-gate`,
`factory-no-python-check`, and `factory-append-only-test`,
but **does NOT show fresh `gate-fast` or
`factory-closure-status-check` evidence**. "All gates PASS"
is a stronger claim than the displayed evidence supports.

### P1-7 — Predecessor identity is internally wrong

The CORRECTION04 HANDOFF and `c4-required-result.txt` both
record:

```text
Predecessor (closed): 35c67ac ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
```

But `35c67ac` is **CORRECTION04's own C2 IMPL commit**
(title: `ACT-POLYC-SELFHOST-LEXER02-CORRECTION04 C2 IMPL`).
The actual closed predecessor is `6abde99`
(title: `ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 — C4 CLOSE`).
This is precisely the kind of identity / provenance
corruption that `factory-closure-status-check` is meant to
catch mechanically, and is independent evidence that the
governance layer did not engage at CORRECTION04 CLOSE.

## 2. Scope

### allowed

* Reimplementation of the byte-equality predicate in
  `tools/quality/lexer07-broad-corpus-4-stage.HC` to use
  `MemCmp(b0,b1,size0) == 0 && MemCmp(b0,b2,size0) == 0 &&
  MemCmp(b0,b3,size0) == 0` for the `BYTE_IDENTICAL_4`
  classification; FNV-1a retained as a secondary
  per-object identifier in the provenance TSV.
* A PolyC-local SHA-256 implementation added as a new
  internal primitive (≈120 LOC, matching the ACT-authorized
  mechanism in CORRECTION04 §5) under
  `tools/quality/lexer07-sha256.HC` (or an internal block in
  `lexer07-broad-corpus-4-stage.HC`). The SHA-256 output is
  the canonical hash recorded in
  `corpus-object-provenance.tsv`; FNV-1a is retained
  alongside for cross-check.
* Three new mutation-test binaries that exercise
  AC05/AC06/AC07 against the fresh CORRECTION05 PolyC tools.
  Each binary produces a deterministic PASS/FAIL verdict
  file in
  `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/` and
  the C3 evidence log records all three results.
* A TSV-cell escaping function (`EscapeTsvCell`) that
  replaces CR/LF/tab/backslash with the literal escapes
  `\n`/`\r`/`\t`/`\\` so embedded control characters do not
  split a logical record across two physical lines.
* Exact-CORRECTION02-counts success predicate in the
  broad-corpus tool: success iff
  `CURRENT_4_STAGE_BYTE_IDENTICAL == 166
   && HISTORICAL_S0_BASELINED_4_WAY_EQ == 9
   && TOTAL_EQUIVALENCE_COVERAGE == 175
   && BOTH_FAIL_4 == 6
   && DIVERGED == 0
   && REGRESSION == 0
   && PASS_MISMATCH == 0`
  (or the gate emits an explicit `COUNT_DRIFT` diagnostic
  listing which literal count diverged).
* Fresh `gate-fast` and `factory-closure-status-check`
  evidence in the C3 evidence directory (their absence at
  C04 closure is the P0-6 defect).
* Correction of the CORRECTION04 HANDOFF predecessor
  identity from `35c67ac` to `6abde99` (the actual closed
  predecessor); no rewriting of CORRECTION04 evidence
  beyond this single field in the HANDOFF document is
  authorized (F14 forbids evidence-directory rewrites; the
  HANDOFF is not in the evidence directory and may be
  amended only for the predecessor field).
* Update of `docs/ROADMAP.md` with the CORRECTION05 status
  block (P0 READY → P0 CLOSED PASS, FALSE_GREEN verdict on
  CORRECTION04, LEXER03 BLOCKED until C05 TRUE GREEN).
* Creation of `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05.md`.
* Update of `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv` only
  where the language/loc role of an existing row changes
  (no new shell roles introduced; SHA-256 is internal to
  the existing PolyC tool).

### forbidden

* Production semantic changes to `src/holyc-lib/` lexer,
  parser, IR, codegen, or library headers.
* Touching CORRECTION02 / CORRECTION03 / CORRECTION04
  evidence directories (`evidence/.../CORRECTION0[234]/`)
  except for the single predecessor-identity field of
  CORRECTION04's HANDOFF document (the HANDOFF lives at
  `docs/factory/HANDOFF-ACT-...-CORRECTION04.md`, not in
  the evidence directory).
* Amending, rebasing, force-pushing, or otherwise
  rewriting history. The append-only invariant is
  preserved.
* Adding new dependencies (the PolyC SHA-256 is
  PolyC-local; libtos is unchanged).
* Removing or weakening `shell-loc-gate`, `gate-fast`,
  `factory-no-python-check`, `factory-append-only-test`,
  or `factory-closure-status-check`.
* Re-introducing shell-based substantive logic. Shell
  wrappers remain ≤50 LOC dispatch glue
  (`lexer07-fixture-inventory.sh` 14 LOC;
  `lexer07-broad-corpus-4-stage.sh` 16 LOC).
* Promoting FNV-1a to the canonical byte-equality
  predicate. FNV is a non-cryptographic, finite-width
  hash and is unsuitable as a literal byte-equality
  substitute; it is retained only as a secondary
  identifier (P0-2 closed by MemCmp; FNV is documentation).
* Silent fallback to a different backend/toolchain
  (F6). If libtos is genuinely missing a primitive that
  the implementation needs, the appropriate HALT token is
  emitted.
* Reclassifying any of AC05/AC06/AC07 as residue at closure
  (P0-1 closed by implementing all three).

## 3. Entry gate

Identity (F1) recorded at ACT start:

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Required state:

* on `main`;
* worktree clean;
* entry HEAD recorded in
  `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c1/c1-entry-identity.txt`.

Required pre-state at C1 (already satisfied at `58a89cc`):

* CORRECTION04 closed at `58a89cc` with the seven defects
  enumerated in §1 still on disk (the HANDOFF predecessor
  field, the FNV-1a predicate, the malformed TSV, the
  missing mutation tests, the missing `gate-fast` and
  `factory-closure-status-check` evidence).
* Append-only history preserved through `58a89cc`.

## 4. Principal RED

### C1.1 — Stale FNV-1a predicate

```text
BROAD_CORPUS_PREDICATE_FAMILY = FNV1A_64
REQUIRED_PREDICATE_FAMILY     = MEMCMP_AND_SHA256
```

Mechanical witness: the closure of `corpus-matrix.tsv` in
the CORRECTION04 evidence directory shows the predicate
`h0 == h1 && h1 == h2 && h2 == h3`, where `h0..h3` are
FNV-1a 64-bit hashes. The required predicate is byte
equality (`MemCmp`) plus SHA-256 as the canonical
identifier in the provenance TSV.

### C1.2 — Three mutation tests not implemented

```text
STUB_BINARY_NEGATIVE_CONTROL          = NOT_IMPLEMENTED
CORRUPT_OBJECT_NEGATIVE_CONTROL       = NOT_IMPLEMENTED
FIXTURE_MUTATION_NEGATIVE_CONTROL     = NOT_IMPLEMENTED
```

Mechanical witness: there is no `c3-*negative-control*.log`
file in the CORRECTION04 evidence directory, and the C4
HANDOFF §RESIDUE P1 records the three as residue.

### C1.3 — Fresh `gate-fast` and `factory-closure-status-check` evidence missing

```text
C03_EVIDENCE_HAS_FRESH_GATE_FAST                  = NO
C03_EVIDENCE_HAS_FRESH_FACTORY_CLOSURE_STATUS_CHECK = NO
```

Mechanical witness: `grep -n 'gate-fast\|closure-status-check'
evidence/.../CORRECTION04/c3/c3-required-result.txt`
returns no matches.

### C1.4 — Malformed `fixture-inventory.tsv` (89-row contract violated)

```text
FIXTURE_INVENTORY_TSV_PHYSICAL_LINES  = 91
FIXTURE_INVENTORY_TSV_DATA_ROWS      = 88
REQUIRED_DATA_ROWS                   = 89
```

Mechanical witness:
`awk -F'\t' '{print NF}'
evidence/.../CORRECTION04/c3/fixture-inventory.tsv |
sort | uniq -c` reports one row with 11 columns, one row
with 2 columns, and 89 rows with 12 columns — the
`hex_0xff_no_semi` record is split across two physical
lines by an embedded CR/LF.

### C1.5 — Predecessor identity corruption in CORRECTION04 HANDOFF

```text
C04_HANDOFF_PREDECESSOR_SHA          = 35c67ac
C04_HANDOFF_PREDECESSOR_SUBJECT      = ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
ACTUAL_CORRECTION03_CLOSE_SHA        = 6abde99
```

Mechanical witness: `git show --no-patch --format='%s'
35c67ac` reports `ACT-POLYC-SELFHOST-LEXER02-CORRECTION04
C2 IMPL`; `git show --no-patch --format='%s' 6abde99`
reports `ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 — C4
CLOSE`.

## 5. Implementation boundary

Minimum production change required:

* `tools/quality/lexer07-broad-corpus-4-stage.HC` —
  Replace the FNV-1a equality test with
  `MemCmp(b0,b1,size0) == 0 && MemCmp(b0,b2,size0) == 0 &&
  MemCmp(b0,b3,size0) == 0` for the `BYTE_IDENTICAL_4`
  classification. Add a PolyC-local SHA-256 implementation
  (≈120 LOC, internal to the .HC file or split into
  `tools/quality/lexer07-sha256.HC`). Record SHA-256 as
  the canonical hash in `corpus-object-provenance.tsv`;
  retain FNV-1a as a secondary column for cross-check.
  Tighten the success predicate to require the literal
  CORRECTION02 counts listed in §6 (AC02).
* `tools/quality/lexer07-fixture-inventory.HC` —
  Replace the TSV cell writer with one that escapes CR,
  LF, tab, and backslash so embedded control bytes do
  not split logical records. Re-emit
  `fixture-inventory.tsv` and verify that the on-disk
  artifact has exactly 89 data rows + 1 header (90
  physical lines, 89 of which carry 12 columns and the
  header carries 12 columns).
* Three new mutation-test executables:
  * `tools/quality/lexer07-mutation-stub.HC` — replaces
    `build/lexer07-broad-corpus-4-stage` with a stub
    binary that returns rc=0 without writing the
    contract TSV; the test asserts that the gate rejects
    the stub.
  * `tools/quality/lexer07-mutation-corrupt.HC` —
    corrupts one byte in
    `build/b02-corpus-A/<idx>_<stem>.o` (restored after
    the run); the test asserts that the broad-corpus
    gate flags the corruption as
    `STAGE0_HISTORICAL_SHA_MISMATCH` and exits non-zero.
  * `tools/quality/lexer07-mutation-fixture.HC` — runs
    with a temporary copy of
    `tools/quality/lexer07-direct-differential.c` in
    which one fixture is removed; the test asserts that
    the inventory gate's `TOTAL` count drops by one and
    the test reports `MUTATION_DETECTED`.
* Each mutation test runs as part of `make
  lexer07-correction02-all` and produces a
  `c3-<name>.log` in
  `evidence/.../CORRECTION05/c3/`.
* The existing shell wrappers
  (`scripts/quality/lexer07-fixture-inventory.sh` 14 LOC;
  `scripts/quality/lexer07-broad-corpus-4-stage.sh` 16 LOC)
  remain ≤50 LOC dispatch glue and are extended only with
  optional launcher lines for the three mutation tests
  (each launcher ≤10 LOC of additional glue inside the
  50-LOC envelope).
* `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md` —
  repair only the predecessor-identity field from
  `35c67ac` to `6abde99`. No other field of the
  CORRECTION04 HANDOFF is modified (F14 forbids evidence
  rewrites; the HANDOFF is not in the evidence directory
  and a single-field repair is the minimum fix).
* `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05.md`
  — created at CLOSE with the standard Factory v2
  HANDOFF shape (Result / What changed / Evidence /
  Production delta / Residue / Recommended next ACT).
* `docs/ROADMAP.md` — CORRECTION05 status block added;
  CORRECTION04 status block annotated with the
  reviewer-verdict cross-reference.

Deliberately not included:

* New production semantic changes to the lexer / parser /
  IR / codegen surface.
* New dependencies. The PolyC SHA-256 is PolyC-local.
* New shell LOC beyond the existing ≤50 budget.
* Touching CORRECTION02 / CORRECTION03 evidence. F14
  forbids rewriting history; corrections live in
  `CORRECTION05/c*` directories.
* Rewriting CORRECTION04 evidence beyond the
  predecessor-identity field of its HANDOFF document.
* Removing or weakening any pre-existing gate.
* Wiring `factory-polyc-tools-check.HC` into `gate-fast`
  (still C2.9 residue from
  `ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01`; out of
  scope).
* Parallelizing the 181×4 compiler invocations (still
  P2 performance residue).
* Repairing the 9 current-stage0 ARM64 inline asm
  failures (still P2 residue).

## 6. Acceptance criteria

Each AC is checkable by a single concrete command.

```text
AC01  CORRECTION02 fixture-inventory contract reproduced
      from a clean destination, with the on-disk TSV
      containing exactly 89 data rows (12 columns each)
      and 1 header (12 columns):
        TOTAL=89 is_numeric=42 is_char=33
        is_negative=16 is_edge=3
        FIXTURE_INVENTORY_FLOORS=PASS
        STATUS=PASS
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-fixture-inventory-contract.txt
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          fixture-inventory.tsv
      Mechanically verified by:
        wc -l .../fixture-inventory.tsv     -> 90
        awk -F'\t' '{print NF}' .../fixture-inventory.tsv \
          | sort | uniq -c
          -> 90   12

AC02  CORRECTION02 broad-corpus contract reproduced from
      a clean destination with byte-equality (MemCmp) +
      SHA-256 classification, and a strict count
      predicate that requires the literal CORRECTION02
      counts:
        CURRENT_4_STAGE_BYTE_IDENTICAL   == 166
        HISTORICAL_S0_BASELINED_4_WAY_EQ == 9
        TOTAL_EQUIVALENCE_COVERAGE      == 175
        BOTH_FAIL_4                      == 6
        DIVERGED                         == 0
        REGRESSION                       == 0
        PASS_MISMATCH                    == 0
        STATUS                           == PASS
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-broad-corpus-contract.txt
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          corpus-matrix.tsv
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          corpus-object-provenance.tsv

AC03  BYTE_IDENTICAL_4 classification is computed by
      MemCmp on the full .o bytes, not by FNV-1a hash
      equality.
      Mechanically verified by:
        grep -n 'BYTE_IDENTICAL_4' \
          tools/quality/lexer07-broad-corpus-4-stage.HC \
          | grep -q 'MemCmp'

AC04  SHA-256 is the canonical per-object hash recorded
      in corpus-object-provenance.tsv.
      Mechanically verified by:
        grep -E '^sha256_[0-9a-f]{64}\b' \
          .../corpus-object-provenance.tsv | wc -l \
          -> 181

AC05  STUB_BINARY_NEGATIVE_CONTROL=PASS.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-stub-control.log

AC06  CORRUPT_OBJECT_NEGATIVE_CONTROL=PASS.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-corrupt-control.log

AC07  FIXTURE_MUTATION_NEGATIVE_CONTROL=PASS.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-fixture-mutation.log

AC08  shell-loc-gate PASS.
AC09  gate-fast PASS.
AC10  factory-no-python-check PASS.
AC11  factory-closure-status-check PASS.
AC12  factory-append-only-test PASS.
AC13  PolyC-local SHA-256 passes published test vectors:
        SHA256("")    = e3b0c44298fc1c149afbf4c8996fb924
                        27ae41e4649b934ca495991b7852b855
        SHA256("abc") = ba7816bf8f01cfea414140de5dae2223
                        b00361a396177a9cb410ff61f20015ad
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-sha256-test-vector.log

AC14  Predecessor identity repaired in
      HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md
      to `6abde99`.

AC15  ROADMAP status block for CORRECTION05 records
      CLOSED PASS with the seven CORRECTION04 defects
      marked CLOSED.
AC16  Worktree clean at closure.
AC17  Append-only Git history preserved.
```

## 7. Conservation gates

The existing gates that must remain PASS after CORRECTION05:

* `gate-fast` (sub-second fast quality gate; mandatory).
* `shell-loc-gate` (the explicit F-POLYC-TOOLS ratchet).
* `factory-no-python-check` (F-NO-PYTHON).
* `factory-append-only-test` (historical-refusal regression
  suite, NC1..NC11).
* `factory-closure-status-check` (ACT/HANDOFF
  reconciliation — the very gate that CORRECTION04 omitted).
* `tools/quality/lexer07-direct-differential` direct
  differential (89 fixtures, 4 stages) remains 89/89 PASS.

Direct differential / real-lexer / operator-seam conservation
remains the responsibility of LEXER02 and its predecessor
ACTs. This ACT does NOT mutate any lexer or compiler binary,
so the lexer-seam fixtures must continue to pass. We document
this conservation in `c4/c4-conservation-gates.txt`.

## 8. Halt taxonomy

* `HALT_RED_NOT_REPRODUCED` — if any of C1.1..C1.5 cannot
  be reproduced from the current `58a89cc` tree.
* `HALT_SCOPE_EXPANSION_REQUIRED` — if closing AC01..AC07
  requires touching the lexer or compiler binary,
  reclassifying FNV-1a as the canonical byte-equality
  predicate, or amending CORRECTION04 evidence beyond the
  single HANDOFF predecessor field.
* `HALT_PRIMITIVE_UNAVAILABLE` — if libtos genuinely lacks
  `MemCmp`, `FileRead`, or `FileWrite` at runtime despite
  `--install-dir=./build/test-prefix`, and no PolyC
  workaround is possible.
* `HALT_SHA256_VECTOR_MISMATCH` — if the PolyC-local
  SHA-256 implementation diverges from the published test
  vectors in AC13. This is an F5-class halt: the
  implementation is wrong, not the test.

## 9. Residue (pre-declared)

* P2 — wiring `factory-polyc-tools-check.HC` into
  `gate-fast` (C2.9 residue from CORRECTION01).
* P2 — repairing `test-prefix-install` (not in scope).
* P2 — 9 stage0 ARM64 inline asm regressions in
  `./build/hcc`; historical fallback to
  `build/b02-corpus-A/` remains the contracted remediation.
* P3 — Promote the PolyC-local SHA-256 to libtos so future
  ACTs do not have to re-derive it.
* P3 — Parallelize the 181×4=724 compiler invocations
  (currently ~80s wall-clock; pipeline could reduce to
  ~20s).

## 10. Commit topology

Suggested commit ordering. Mark "do not exceed".

1. `C1 RED` — entry identity, defect evidence (the five
   RED witnesses in §4), scope audit, ancestor of
   `58a89cc`.
2. `C2 IMPL` — MemCmp byte-equality predicate, PolyC-local
   SHA-256, TSV-cell escaping, three mutation-test
   executables, single-field HANDOFF predecessor repair.
3. `C3 EVIDENCE` — fresh re-proof + three mutation tests +
   `gate-fast` + `factory-closure-status-check` fresh
   evidence.
4. `C4 CLOSE` — ROADMAP status block, CORRECTION05
   HANDOFF, identity, ancestor binding to C3.

Do not exceed 4 commits.

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md` (Factory v2
section). Reviewer procedure:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 HEAD
git show --stat <close>
git log <entry>..<close> --format=full
git status --porcelain=v1
git diff --check <entry>..<close>
```

## 12. Next ACT

`ACT-POLYC-SELFHOST-LEXER03` (or successor). LEXER03 remains
**BLOCKED** at `58a89cc` until CORRECTION05 closes PASS.
The mechanical BLOCK signal is the
`factory-closure-status-check` HALT_CLASS=GOVERNANCE
BLOCKS_NEXT=YES verdict that this ACT will close with on
LEXER03's behalf.
