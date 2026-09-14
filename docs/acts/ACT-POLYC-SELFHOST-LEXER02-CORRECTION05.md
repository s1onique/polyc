# ACT-POLYC-SELFHOST-LEXER02-CORRECTION05

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair CORRECTION04 closure-truth defects (FALSE_GREEN
on `58a89cc`): independent verifier surface, mandatory negative
controls, real byte-equality predicate, NIST-vectored PolyC SHA-256,
truthful provenance schema, invariant-vs-snapshot corpus contract,
deterministic TSV serialization, fresh Factory gates, additive
predecessor correction binding, and baseline-delta F-NO-PYTHON
semantics.

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

CORRECTION05 also addresses the eight reviewer-audit findings
issued at C1 (the C1.1 CONTRACT-CORRECTION phase authorized by
the reviewer at `9824027+1`):

1. Generation MUST be separated from verification. A new
   `tools/quality/lexer07-proof-verify.HC` is the **independent
   PolyC verifier**. A generator MUST NOT be the authority that
   accepts its own rc=0 output as evidence.
2. `BYTE_IDENTICAL` means actual bytes. A named helper
   `ObjectsByteEqual(a,asz,b,bsz)` (or an equivalent
   four-object predicate) is required; FNV-1a MUST NOT
   participate in the truth value of `BYTE_IDENTICAL_4`. FNV
   MAY remain informational only.
3. SHA-256 MUST be canonical evidence identity and MUST be
   verified against NIST vectors that cross the 55/56/57-byte
   padding-boundary block transitions (homemade SHA
   implementations commonly fail around padding/block
   transitions; FIPS 180-4 §B.2 publishes test data for
   55/56/57-byte messages).
4. Provenance schema MUST bind: `source`, `stage`,
   `object_path`, `provenance_class`, `object_sha256`,
   `compiler_binary_path`, `compiler_binary_sha256`. For
   `stage0-historical` rows, `producer_compiler_sha256` MUST
   be either the actual historical compiler digest from
   immutable evidence, or literally `UNKNOWN` — never the
   SHA of the current failing `./build/hcc`.
5. The CORRECTION02 literal counts (166/9/175/6/0) MUST be a
   snapshot enforced by the **C05 independent verifier**, NOT
   the permanent success semantics of the reusable
   broad-corpus generator. The generator enforces only the
   semantic invariants; a later genuine improvement (e.g.
   elimination of the 9 historical fallbacks) is an
   improvement, not a regression.
6. AC05/AC06/AC07 negative controls MUST mutate only the
   evidence GENERATOR while leaving the independent verifier
   intact. Replacing the verifier with an rc=0 stub does not
   prove anything about the gate.
7. AC06 MUST NOT derive both "expected" and "actual" SHA
   from the same mutated file. The expected SHA must come
   from an immutable independent baseline; the diagnosis is
   permitted to be `STAGE0_HISTORICAL_BYTE_MISMATCH` or
   `OBJECT_IDENTITY_MISMATCH`.
8. AC10 F-NO-PYTHON MUST use baseline/delta semantics: zero
   new Python sources / invocations / file-violations vs the
   entry commit, NOT a literal `STATUS=PASS` claim from the
   authoritative command (which reports FAIL on the
   grandfathered 12 pre-existing Python files).
9. AC14 MUST preserve the closed CORRECTION04 HANDOFF
   additively. The C04 predecessor field stays `35c67ac`;
   the correction binding lives in the C05 HANDOFF and
   ROADMAP only.
10. `factory-closure-status-check` is bounded to the
    LLVM-CORE03 + status-reconciliation universe and CANNOT
    mechanically close P1-7. A new direct predecessor-
    identity verifier (`tools/quality/lexer07-predecessor-
    verify.HC` or an equivalent PolyC component) is required
    and must itself be exercised by a fresh-trees run.

When this ACT closes, the CORRECTION02 contract (`89 / 33 / 16`
floor inventory and `166+9 / 6 / 0` broad corpus) will be
reproduced from a clean destination with:

* a real `MemCmp`-based byte-equality predicate (not FNV hash
  equality) using a named `ObjectsByteEqual` helper;
* a PolyC-local SHA-256 implementation verified against
  NIST FIPS 180-4 §B.2 vectors including the 55/56/57-byte
  padding-boundary cases;
* three real negative-control mutation tests (AC05/AC06/AC07)
  that mechanically reject (a) a stub generator that returns
  rc=0 with bad evidence, (b) a corrupted stage0 historical
  fallback, and (c) a fixture table with one row removed;
* a deterministic 89-data-row TSV (TSV cells escape control
  bytes rather than emitting literal separators);
* a truthful per-object provenance TSV with the schema in
  §6 (700 successful rows, not 181);
* fresh `gate-fast`, `factory-closure-status-check`,
  and the new direct predecessor-identity verifier evidence
  in the C3 closure packet;
* additive predecessor correction binding in the C05 HANDOFF
  (the closed C04 HANDOFF is preserved verbatim, F14).

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

* **Independent PolyC verifier**:
  `tools/quality/lexer07-proof-verify.HC` (≈150 LOC) — a
  new PolyC tool that consumes the output of
  `lexer07-broad-corpus-4-stage` and
  `lexer07-fixture-inventory` and produces a deterministic
  PASS/FAIL verdict. It does NOT call any generator
  internal to those tools; it reads only the on-disk
  evidence files and decides.
* **Direct predecessor-identity verifier**:
  `tools/quality/lexer07-predecessor-verify.HC` (≈80 LOC)
  — a new PolyC tool that walks the closed CORRECTION04
  HANDOFF, parses the `Predecessor (closed)` field, runs
  `git show --no-patch --format='%s'` on the recorded SHA,
  and reports the mismatch against the actual closing SHA
  of CORRECTION03 (`6abde99`). This is the only mechanical
  path to close P1-7, because `factory-closure-status-check`
  is bounded to the LLVM-CORE03 universe.
* **Real byte-equality predicate**:
  `tools/quality/lexer07-broad-corpus-4-stage.HC` is
  modified to expose a named helper
  `ObjectsByteEqual(a,asz,b,bsz) -> Bool` whose
  implementation is:
  ```text
  return (asz == bsz) && (MemCmp(a, b, asz) == 0);
  ```
  The four-object predicate
  `BYTE_IDENTICAL_4(b0,b1,b2,b3)` is built from this helper
  with three pairwise calls. FNV-1a is retained as a
  secondary per-object identifier in the provenance TSV;
  it MUST NOT participate in the truth value of
  `BYTE_IDENTICAL_4`.
* **PolyC-local SHA-256** with NIST FIPS 180-4 §B.2
  test vectors: `tools/quality/lexer07-sha256.HC` (or an
  internal block in `lexer07-broad-corpus-4-stage.HC`)
  implements SHA-256 and is verified at minimum against:
  * `SHA256("")` =
    `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
  * `SHA256("abc")` =
    `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`
  * 55-byte / 56-byte / 57-byte NIST vectors (FIPS 180-4
    §B.2), which cross the 64-byte block-boundary that
    exposes padding-off-by-one defects in homemade SHA
    implementations.
  The SHA-256 output is the canonical hash recorded in
  `corpus-object-provenance.tsv`; FNV-1a is retained
  alongside for cross-check.
* **Three negative-control mutation binaries** that
  exercise AC05/AC06/AC07 by mutating only the evidence
  GENERATOR (or its inputs) while leaving the independent
  verifier intact:
  * `tools/quality/lexer07-mutation-stub.HC` —
    substitutes the broad-corpus generator with an rc=0
    stub that emits missing/incomplete/false evidence;
    the independent verifier must reject.
  * `tools/quality/lexer07-mutation-corrupt.HC` —
    corrupts one byte in a temporary copy of a
    `build/b02-corpus-A/<idx>_<stem>.o` historical
    fallback (the canonical historical object is NEVER
    mutated in place); the independent verifier must
    reject with `OBJECT_IDENTITY_MISMATCH` or
    `STAGE0_HISTORICAL_BYTE_MISMATCH`.
  * `tools/quality/lexer07-mutation-fixture.HC` —
    generates evidence against a temporary copy of
    `tools/quality/lexer07-direct-differential.c` with
    one fixture row removed; the independent verifier
    must reject the snapshot (generator reports TOTAL=88;
    the C05 snapshot requires TOTAL=89).
  Each mutation test produces a deterministic verdict
  file in
  `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/`.
* **TSV-cell escaping function** (`EscapeTsvCell`) that
  replaces CR/LF/tab/backslash with the literal escapes
  `\n`/`\r`/`\t`/`\\` so embedded control characters do
  not split a logical record across two physical lines.
* **Provenance schema** (recorded in the new
  `corpus-object-provenance.tsv`):
  ```text
  source<TAB>stage<TAB>object_path<TAB>provenance_class
  <TAB>object_sha256<TAB>compiler_binary_path
  <TAB>compiler_binary_sha256<TAB>fnv1a64
  ```
  For `stage0-historical` rows,
  `compiler_binary_sha256` MUST be either the actual
  historical compiler digest from immutable evidence, or
  literally `UNKNOWN` — never the SHA of the current
  failing `./build/hcc`. The total row count is
  `175 × 4 = 700` successful object rows; failed rows
  (rc≠0) are recorded separately with empty
  `object_sha256`.
* **Semantic-invariant gate** in the broad-corpus
  generator: success iff
  * `BYTE_IDENTICAL_4` rate has not regressed vs the
    previous entry;
  * `BOTH_FAIL_4` rate has not regressed vs the previous
    entry;
  * `DIVERGED == 0`;
  * `REGRESSION == 0`;
  * `PASS_MISMATCH == 0`;
  * provenance TSV is structurally valid (700 rows +
    header, 8 columns each, no embedded control bytes).
* **C05 independent-verifier snapshot** enforces the
  present-tree literal CORRECTION02 counts:
  * `CURRENT_4_STAGE_BYTE_IDENTICAL == 166`
  * `HISTORICAL_S0_BASELINED_4_WAY_EQ == 9`
  * `TOTAL_EQUIVALENCE_COVERAGE == 175`
  * `BOTH_FAIL_4 == 6`
  * `DIVERGED == 0`
  * `REGRESSION == 0`
  * `PASS_MISMATCH == 0`
  A later genuine improvement (e.g. elimination of the
  9 historical fallbacks) updates the snapshot; the
  generator's invariant gate still passes. The snapshot
  is bound to C05 closure, not to the generator's
  permanent success semantics.
* Fresh `gate-fast`, `factory-closure-status-check`,
  and the new direct predecessor-identity verifier
  evidence in the C3 evidence directory (their absence
  at C04 closure is the P0-6 defect; the predecessor
  verifier is added because `factory-closure-status-check`
  is bounded to LLVM-CORE03).
* **Additive predecessor correction binding**: the
  closed CORRECTION04 HANDOFF is preserved verbatim. The
  C05 HANDOFF records:
  * `C04_RECORDED_PREDECESSOR=35c67ac`
  * `C04_RECORDED_PREDECESSOR_VERDICT=INCORRECT`
  * `CORRECT_PREDECESSOR=6abde99`
  * `CORRECTION_BINDING=C05`
  and the ROADMAP C05 block documents the same
  correction binding. No edit to the C04 HANDOFF is
  authorized (F14 forbids appending to closed ACT
  artifacts; the correction is recorded additively in
  C05).
* **F-NO-PYTHON baseline/delta contract** for AC10: the
  gate evidence records
  `NEW_PYTHON_SOURCES=0`, `NEW_PYTHON_INVOCATIONS=0`,
  `C05_CHANGED_FILES_PYTHON_VIOLATIONS=0`,
  `LEGACY_VIOLATION_SET == ENTRY_LEGACY_VIOLATION_SET`.
  No literal `STATUS=PASS` claim is made; the
  authoritative command reports FAIL on the
  grandfathered 12 pre-existing Python files.
* Update of `docs/ROADMAP.md` with the CORRECTION05
  status block (P0 READY → P0 CLOSED PASS, FALSE_GREEN
  verdict on CORRECTION04, the eight reviewer-audit
  findings from C1.1 marked CLOSED, LEXER03 BLOCKED
  until C05 TRUE GREEN).
* Creation of
  `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05.md`.
* Update of `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv`
  only where the language/loc role of an existing row
  changes (no new shell roles introduced; SHA-256 is
  internal to the existing PolyC tool).

### forbidden

* Production semantic changes to `src/holyc-lib/` lexer,
  parser, IR, codegen, or library headers.
* Touching CORRECTION02 / CORRECTION03 / CORRECTION04
  evidence directories (`evidence/.../CORRECTION0[234]/`).
* **Editing the closed CORRECTION04 HANDOFF document**.
  F14 forbids appending to closed ACT artifacts. The
  correction lives in the C05 HANDOFF and ROADMAP only.
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
  `lexer07-broad-corpus-4-stage.sh` 16 LOC) and may grow
  by ≤10 LOC of optional launcher lines for the three
  new mutation tests.
* Promoting FNV-1a to the canonical byte-equality
  predicate. FNV is a non-cryptographic, finite-width
  hash and is unsuitable as a literal byte-equality
  substitute; it is retained only as a secondary
  identifier (P0-2 closed by `ObjectsByteEqual`; FNV is
  documentation).
* Silent fallback to a different backend/toolchain
  (F6). If libtos is genuinely missing a primitive that
  the implementation needs, the appropriate HALT token
  is emitted.
* Reclassifying any of AC05/AC06/AC07 as residue at
  closure (P0-1 closed by implementing all three).
* Deriving both "expected" and "actual" SHA from the
  same mutated file in AC06; mutating the canonical
  historical object in place.
* Mutating the only verifier in any AC05/AC06/AC07 test.
* Weakening `factory-closure-status-check` or its
  bounded managed universe to make P1-7 invisible.
* Editing `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv` to
  remove the 12 grandfathered Python files; the
  baseline/delta contract is preserved.

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

Minimum production change required (each item lists the
file, the kind of change, and the LOC budget):

| Path | Kind | LOC budget | Why |
| --- | --- | --- | --- |
| `tools/quality/lexer07-broad-corpus-4-stage.HC` | modified | 408 → ≤500 | expose `ObjectsByteEqual` helper; replace FNV equality with `MemCmp`; write the 8-column provenance TSV (700 successful rows + header); integrate SHA-256; emit invariant-gate verdict |
| `tools/quality/lexer07-fixture-inventory.HC` | modified | 395 → ≤420 | `EscapeTsvCell` for CR/LF/tab/backslash |
| `tools/quality/lexer07-sha256.HC` | new | ≤120 | PolyC-local SHA-256 with NIST FIPS 180-4 §B.2 vectors |
| `tools/quality/lexer07-proof-verify.HC` | new | ≤150 | **Independent verifier**: reads on-disk evidence, emits PASS/FAIL |
| `tools/quality/lexer07-predecessor-verify.HC` | new | ≤80 | **Direct predecessor-identity verifier** for P1-7 |
| `tools/quality/lexer07-mutation-stub.HC` | new | ≤40 | AC05 mutation (generator-only, verifier intact) |
| `tools/quality/lexer07-mutation-corrupt.HC` | new | ≤40 | AC06 mutation (temp-file byte corruption; canonical historical object NEVER mutated in place) |
| `tools/quality/lexer07-mutation-fixture.HC` | new | ≤40 | AC07 mutation (fixture row removed in temp differential.c) |
| `scripts/quality/lexer07-broad-corpus-4-stage.sh` | modified | 16 → ≤26 | optional launcher lines for the three mutation tests |
| `scripts/quality/lexer07-fixture-inventory.sh` | unchanged | 14 | (already ≤50 LOC dispatch glue) |
| `scripts/quality/factory-v2-commit-msg-check.sh` | unchanged | — | gate (not in C2) |
| `scripts/quality/factory-no-python-check.sh` | unchanged | — | gate (baseline/delta evidence required; not in C2) |

Minimum production change described in prose:



* `tools/quality/lexer07-broad-corpus-4-stage.HC` —
  Replace the FNV-1a equality test with a named helper
  `ObjectsByteEqual(a,asz,b,bsz) -> Bool` whose body is
  `(asz == bsz) && (MemCmp(a, b, asz) == 0)`. The
  four-object `BYTE_IDENTICAL_4` predicate is built from
  three pairwise calls to this helper. Add a PolyC-local
  SHA-256 implementation (≈120 LOC, internal to the .HC
  file or split into `tools/quality/lexer07-sha256.HC`).
  Record SHA-256 as the canonical hash in
  `corpus-object-provenance.tsv`; retain FNV-1a as a
  secondary `fnv1a64` column for cross-check. The
  provenance schema MUST bind: `source`, `stage`,
  `object_path`, `provenance_class`, `object_sha256`,
  `compiler_binary_path`, `compiler_binary_sha256`,
  `fnv1a64`. Tighten the success predicate to the
  semantic invariants in §2; the literal CORRECTION02
  counts are enforced by the C05 independent verifier,
  not by this generator.
* `tools/quality/lexer07-fixture-inventory.HC` —
  Replace the TSV cell writer with one that escapes CR,
  LF, tab, and backslash so embedded control bytes do
  not split logical records. Re-emit
  `fixture-inventory.tsv` and verify that the on-disk
  artifact has exactly 89 data rows + 1 header (90
  physical lines, 89 of which carry 12 columns and the
  header carries 12 columns).
* Three new mutation-test executables (all PolyC; all
  leave the independent verifier intact):
  * `tools/quality/lexer07-mutation-stub.HC` —
    substitutes the broad-corpus generator with a stub
    that returns rc=0 but emits missing/incomplete/false
    evidence; the test asserts that the
    `lexer07-proof-verify.HC` independent verifier
    rejects the stub with a non-zero exit.
  * `tools/quality/lexer07-mutation-corrupt.HC` —
    corrupts one byte in a temporary COPY of
    `build/b02-corpus-A/<idx>_<stem>.o` (the canonical
    historical file is NEVER mutated in place); the
    test asserts that `lexer07-proof-verify.HC` flags
    the corruption with `OBJECT_IDENTITY_MISMATCH` or
    `STAGE0_HISTORICAL_BYTE_MISMATCH` and exits
    non-zero. The expected SHA is taken from the
    immutable pre-mutation snapshot, NOT derived from
    the mutated file at runtime.
  * `tools/quality/lexer07-mutation-fixture.HC` —
    runs the inventory generator against a temporary
    COPY of `tools/quality/lexer07-direct-differential.c`
    with one fixture row removed; the test asserts that
    the generator reports TOTAL=88 and the C05
    independent-verifier snapshot requires TOTAL=89 and
    therefore rejects.
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
* `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05.md`
  — created at CLOSE with the standard Factory v2
  HANDOFF shape (Result / What changed / Evidence /
  Production delta / Residue / Recommended next ACT).
  The HANDOFF records the additive predecessor
  correction binding
  (`C04_RECORDED_PREDECESSOR=35c67ac`,
  `C04_RECORDED_PREDECESSOR_VERDICT=INCORRECT`,
  `CORRECT_PREDECESSOR=6abde99`,
  `CORRECTION_BINDING=C05`).
* `docs/ROADMAP.md` — CORRECTION05 status block added;
  CORRECTION04 status block annotated with the
  reviewer-verdict cross-reference.

Deliberately not included:

* New production semantic changes to the lexer / parser /
  IR / codegen surface.
* New dependencies. The PolyC SHA-256 is PolyC-local.
* New shell LOC beyond the existing ≤50 budget (+≤10 LOC
  of optional launcher lines for the three mutation tests).
* Touching CORRECTION02 / CORRECTION03 evidence. F14
  forbids rewriting history; corrections live in
  `CORRECTION05/c*` directories.
* **Editing the closed CORRECTION04 HANDOFF document**.
  The predecessor correction is recorded additively in
  the C05 HANDOFF and ROADMAP only.
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
The seven CORRECTION04 defects (P0-1..P1-7) are closed
1-to-1 by AC01..AC07; the eight reviewer-audit findings
from C1.1 are closed 1-to-1 by AC03 split, AC13 NIST
vectors, AC04 schema, AC02 snapshot split, AC05/06/07
generator-only mutation, AC10 baseline/delta, AC14
additive correction, AC11b predecessor verifier.

```text
AC01  CORRECTION02 fixture-inventory contract reproduced
      from a clean destination, with the on-disk TSV
      containing exactly 89 data rows (12 columns each)
      and 1 header (12 columns), where every CR/LF/tab/
      backslash in cell content is escaped to the literal
      sequences \n / \r / \t / \\ :
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
      a clean destination. The reusable broad-corpus
      generator emits an invariant-gate verdict (no
      regression of BYTE_IDENTICAL_4 rate; no regression
      of BOTH_FAIL_4 rate; DIVERGED=0; REGRESSION=0;
      PASS_MISMATCH=0; provenance TSV structurally
      valid). The C05 independent verifier
      (`tools/quality/lexer07-proof-verify.HC`) then
      asserts the literal CORRECTION02 snapshot:
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
          c3-proof-verify-verdict.txt
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          corpus-matrix.tsv
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          corpus-object-provenance.tsv

AC03  BYTE_IDENTICAL_4 classification is computed by
      `ObjectsByteEqual(a,asz,b,bsz)`, whose body is
      `(asz == bsz) && (MemCmp(a, b, asz) == 0)`, NOT by
      FNV-1a hash equality. FNV MAY remain as a
      secondary per-object identifier.
      Mechanically verified by:
        grep -n 'ObjectsByteEqual' \
          tools/quality/lexer07-broad-corpus-4-stage.HC
          -> a single named helper definition
        grep -n 'BYTE_IDENTICAL_4' \
          tools/quality/lexer07-broad-corpus-4-stage.HC
          -> calls the helper, NOT a raw `h0 == h1`
          FNV equality chain

AC04  corpus-object-provenance.tsv has the schema
        source<TAB>stage<TAB>object_path
        <TAB>provenance_class<TAB>object_sha256
        <TAB>compiler_binary_path
        <TAB>compiler_binary_sha256<TAB>fnv1a64
      and exactly 700 successful object rows
      (`175 × 4`) plus 1 header. For every row where
      `provenance_class` contains `stage0-historical`,
      `compiler_binary_sha256` MUST be the actual
      historical compiler digest from immutable evidence,
      or literally `UNKNOWN`. The current `./build/hcc`
      SHA MUST NOT appear in a `stage0-historical` row.
      Mechanically verified by:
        awk -F'\t' '{print NF}' .../corpus-object-provenance.tsv \
          | sort | uniq -c
          -> 701   8
        awk -F'\t' '$4 ~ /stage0-historical/ {print $7}' \
          .../corpus-object-provenance.tsv \
          | sort -u
          -> [set of historical digests] plus possibly
             UNKNOWN; never the current ./build/hcc SHA

AC05  STUB_BINARY_NEGATIVE_CONTROL=PASS.
      The mutation test substitutes the broad-corpus
      GENERATOR with a stub that returns rc=0 but emits
      missing/incomplete/false evidence. The
      INDEPENDENT VERIFIER (`lexer07-proof-verify.HC`)
      rejects the stub with a non-zero exit. Replacing
      the verifier itself is forbidden.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-stub-control.log

AC06  CORRUPT_OBJECT_NEGATIVE_CONTROL=PASS.
      The mutation test corrupts one byte in a TEMPORARY
      COPY of a `build/b02-corpus-A/<idx>_<stem>.o`
      historical fallback. The expected SHA is taken
      from the immutable pre-mutation snapshot, NOT
      derived from the mutated file at runtime. The
      independent verifier rejects with
      `OBJECT_IDENTITY_MISMATCH` or
      `STAGE0_HISTORICAL_BYTE_MISMATCH`. The canonical
      historical object is NEVER mutated in place.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-corrupt-control.log

AC07  FIXTURE_MUTATION_NEGATIVE_CONTROL=PASS.
      The mutation test runs the inventory generator
      against a TEMPORARY COPY of
      `tools/quality/lexer07-direct-differential.c` with
      one fixture row removed. The generator reports
      TOTAL=88; the C05 independent-verifier snapshot
      requires TOTAL=89 and therefore rejects.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-fixture-mutation.log

AC08  shell-loc-gate PASS.

AC09  gate-fast PASS.

AC10  factory-no-python-check baseline/delta PASS:
        NEW_PYTHON_SOURCES              == 0
        NEW_PYTHON_INVOCATIONS          == 0
        C05_CHANGED_FILES_PYTHON_VIOLATIONS == 0
        LEGACY_VIOLATION_SET            == ENTRY_LEGACY_VIOLATION_SET
      The authoritative command's literal `STATUS=`
      line is recorded as evidence (it MAY legitimately
      be `FAIL` on the grandfathered 12 pre-existing
      Python files; the contract above is the
      closure-binding verdict).
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-no-python-baseline.txt

AC11  factory-closure-status-check PASS.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-closure-status.txt

AC11b Direct predecessor-identity verifier
      (`tools/quality/lexer07-predecessor-verify.HC`)
      reports the CORRECTION04 HANDOFF predecessor as
      INCORRECT and identifies the correct successor as
      `6abde99`. The verifier runs from a fresh tree
      (F9) and exits 0 on a clean reproduction.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-predecessor-verify.txt

AC12  factory-append-only-test PASS.

AC13  PolyC-local SHA-256 passes published FIPS 180-4 §B.2
      vectors AND the 55/56/57-byte padding-boundary
      vectors (homemade SHA implementations commonly
      fail around padding/block transitions):
        SHA256("")    = e3b0c44298fc1c149afbf4c8996fb924
                        27ae41e4649b934ca495991b7852b855
        SHA256("abc") = ba7816bf8f01cfea414140de5dae2223
                        b00361a396177a9cb410ff61f20015ad
        SHA256(56-byte 'a' string) = the NIST 56-byte
          vector (one full block, padding in second block)
        SHA256(55-byte 'a' string) = the NIST 55-byte
          vector (just under block boundary)
        SHA256(57-byte 'a' string) = the NIST 57-byte
          vector (just over block boundary)
      A failure of any vector halts with
      `HALT_SHA256_VECTOR_MISMATCH` (F5: the
      implementation is wrong, not the test).
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-sha256-test-vector.log

AC14  Predecessor correction is recorded ADDITIVELY in
      the C05 HANDOFF (the closed CORRECTION04 HANDOFF
      is preserved verbatim per F14):
        C04_RECORDED_PREDECESSOR         = 35c67ac
        C04_RECORDED_PREDECESSOR_VERDICT = INCORRECT
        CORRECT_PREDECESSOR              = 6abde99
        CORRECTION_BINDING               = C05
      The ROADMAP C05 block documents the same binding.
      Evidence:
        docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION05.md
        git show HEAD~0:docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md
          -> line 14 unchanged from `35c67ac` (F14)

AC15  ROADMAP status block for CORRECTION05 records
      CLOSED PASS with the seven CORRECTION04 defects
      AND the eight reviewer-audit findings from C1.1
      marked CLOSED.
AC16  Worktree clean at closure.
AC17  Append-only Git history preserved.

AC18  ObjectsByteEqual helper passes its executable
      self-tests:
        equal same-size buffers      -> TRUE
        one-byte-different buffers   -> FALSE
        different-size buffers       -> FALSE
      The self-test is part of the C2 IMPL artifact and
      its log is part of the C3 evidence packet.
      Evidence:
        evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3/
          c3-objects-byte-equal-tests.log

AC19  `tools/quality/lexer07-proof-verify.HC` exists as a
      separate PolyC binary. It is NOT a wrapper that
      calls `lexer07-broad-corpus-4-stage`; it reads only
      the on-disk evidence files
      (corpus-matrix.tsv,
       corpus-object-provenance.tsv,
       fixture-inventory.tsv,
       fixture-inventory-summary.txt) and emits its own
      PASS/FAIL verdict. Replacing this verifier in any
      AC05/AC06/AC07 test is forbidden.
      Evidence:
        build/lexer07-proof-verify (PolyC-built binary)
        file -b build/lexer07-proof-verify
          -> Mach-O 64-bit executable arm64
             (or current host arch)

AC20  Provenance `compiler_binary_sha256` for
      `stage0-historical` rows is either an
      evidence-derived historical digest or literally
      `UNKNOWN`; never the SHA of the current
      `./build/hcc`.
      Evidence:
        awk -F'\t' '$4 ~ /stage0-historical/ {print $7}' \
          .../corpus-object-provenance.tsv \
          | sort -u
        # combined with:
        sha256sum build/hcc
```

## 7. Conservation gates

The existing gates that must remain PASS after CORRECTION05:

* `gate-fast` (sub-second fast quality gate; mandatory).
* `shell-loc-gate` (the explicit F-POLYC-TOOLS ratchet).
* `factory-no-python-check` (F-NO-PYTHON, baseline/delta
  contract per AC10; the literal `STATUS=FAIL` on the
  grandfathered 12 pre-existing Python files is
  contractually expected and is NOT a regression).
* `factory-append-only-test` (historical-refusal regression
  suite, NC1..NC11).
* `factory-closure-status-check` (ACT/HANDOFF
  reconciliation — the very gate that CORRECTION04 omitted).
* **NEW** `lexer07-predecessor-verify.HC` direct
  predecessor-identity verifier — required because
  `factory-closure-status-check` is bounded to the
  LLVM-CORE03 universe and CANNOT mechanically close P1-7.
* `tools/quality/lexer07-direct-differential` direct
  differential (89 fixtures, 4 stages) remains 89/89 PASS.
* `tools/quality/lexer07-proof-verify.HC` independent
  verifier (NEW) — its PASS verdict is part of the C05
  closure contract (AC02 + AC19); it is verified to remain
  bit-identical under re-execution against the same
  on-disk evidence.

Direct differential / real-lexer / operator-seam conservation
remains the responsibility of LEXER02 and its predecessor
ACTs. This ACT does NOT mutate any lexer or compiler binary,
so the lexer-seam fixtures must continue to pass. We document
this conservation in `c4/c4-conservation-gates.txt`.

## 8. Halt taxonomy

* `HALT_RED_NOT_REPRODUCED` — if any of C1.1..C1.5 cannot
  be reproduced from the current `58a89cc` tree.
* `HALT_SCOPE_EXPANSION_REQUIRED` — if closing
  AC01..AC20 requires touching the lexer or compiler
  binary, reclassifying FNV-1a as the canonical
  byte-equality predicate, **editing the closed CORRECTION04
  HANDOFF**, weakening `factory-closure-status-check` to
  make P1-7 invisible, or removing the 12 grandfathered
  Python files from `LEGACY-NON-POLYC-TOOLS.tsv`.
* `HALT_PRIMITIVE_UNAVAILABLE` — if libtos genuinely lacks
  `MemCmp`, `FileRead`, or `FileWrite` at runtime despite
  `--install-dir=./build/test-prefix`, and no PolyC
  workaround is possible.
* `HALT_SHA256_VECTOR_MISMATCH` — if the PolyC-local
  SHA-256 implementation diverges from the published test
  vectors in AC13 (including the 55/56/57-byte
  padding-boundary cases). This is an F5-class halt: the
  implementation is wrong, not the test.
* `HALT_OBJECTS_BYTE_EQUAL_TEST_FAIL` — if the
  `ObjectsByteEqual` helper fails any of its executable
  self-tests (AC18: equal same-size buffers returns TRUE,
  one-byte-different buffers returns FALSE, different-size
  buffers returns FALSE, etc.).
* `HALT_PROVENANCE_SCHEMA_FAIL` — if
  `corpus-object-provenance.tsv` does not satisfy the AC04
  schema (8 columns, 700 successful rows + 1 header,
  `stage0-historical` rows use UNKNOWN or an
  evidence-derived historical digest, never the current
  `./build/hcc` SHA).
* `HALT_PREDECESSOR_VERIFIER_FAIL` — if
  `lexer07-predecessor-verify.HC` reports the CORRECTION04
  HANDOFF predecessor as CORRECT (i.e. cannot reproduce
  the documented defect). This is F2-class: the verifier
  must reproduce the defect against the closed C04
  HANDOFF.
* `HALT_INDEPENDENT_VERIFIER_RC_ZERO_ON_STUB` — if the
  AC05 stub-generator test exits with rc=0 from the
  independent verifier (i.e. the verifier is incorrectly
  accepting rc=0 stubs). This is the F5-equivalent of
  AC05's exact predicate.

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
   `58a89cc`. Trailer `ACT-Phase: RED`.
2. `C1.1 CONTRACT-CORRECTION` — revision of the
   authorization artifact in response to the eight
   reviewer-audit findings (see §0 items 1-10 and §2
   scope corrections). **Single intermediate commit
   authorized by the reviewer at the C1 RED review.**
   The commit-msg-check grammar (`RED | IMPL | EVIDENCE |
   CLOSE`) does not permit a `CONTRACT-CORRECTION` phase
   token, so the trailer is `ACT-Phase: RED` (the change
   is contract-only and pre-production). The commit
   subject records the C1.1 phase descriptively. Evidence
   under
   `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c1.1/`
   records the ten reviewer-audit findings and the
   contract corrections.
3. `C2 IMPL` — `ObjectsByteEqual` helper + executable
   self-tests; PolyC-local SHA-256 with NIST vectors
   including 55/56/57-byte padding boundary; 8-column
   provenance schema (700 successful rows + header);
   `EscapeTsvCell`; three negative-control mutation
   binaries; the new independent verifier
   `tools/quality/lexer07-proof-verify.HC`; the new
   direct predecessor-identity verifier
   `tools/quality/lexer07-predecessor-verify.HC`;
   additive predecessor correction binding recorded in
   the C05 HANDOFF and ROADMAP (no edit to the closed
   C04 HANDOFF). Trailer `ACT-Phase: IMPL`.
4. `C3 EVIDENCE` — fresh re-proof + three mutation
   tests + `gate-fast` + `factory-closure-status-check`
   + the new direct predecessor-identity verifier fresh
   evidence. Trailer `ACT-Phase: EVIDENCE`.
5. `C4 CLOSE` — ROADMAP status block (CLOSED PASS,
   FALSE_GREEN cross-reference), CORRECTION05 HANDOFF,
   identity, ancestor binding to C3. Trailer
   `ACT-Phase: CLOSE` + `ACT-Verdict: PASS_TRUE_GREEN`.

Do not exceed 5 commits. The append-only invariant is
preserved across all five commits (no amend, no rebase,
no force-push, no reset+recommit).

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
