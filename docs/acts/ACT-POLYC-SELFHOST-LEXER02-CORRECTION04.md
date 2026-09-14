# ACT-POLYC-SELFHOST-LEXER02-CORRECTION04

**Title:** Restore substantively equivalent PolyC proof tools after CORRECTION03 functional erasure

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** CORRECTION — P0 closure-truth / Factory-governance

**Predecessor:**
`ACT-POLYC-SELFHOST-LEXER02-CORRECTION03` closed at `6abde99`

**Reviewer verdict on predecessor:**
`CORRECTION03_CLOSE_PASS=FALSE_GREEN`

**Do NOT amend, rewrite, squash, or force-push predecessor history.**

---

## 0. Mission

Replace the two stub PolyC binaries and ≤50-LOC shell wrappers
introduced by CORRECTION03 with substantive PolyC tools that own
the full CORRECTION02 contract:

* `tools/quality/lexer07-fixture-inventory.HC` must OWN:
  spawn `./build/lexer07-direct-differential`, parse its
  `OK name kind=.../... err=.../... slen=.../...` output, join
  with the canonical fixture table from
  `tools/quality/lexer07-direct-differential.c`, compute
  `is_numeric` / `is_char` / `is_negative` / `is_edge` from
  OBSERVED values, write the deterministic 89-row
  `fixture-inventory.tsv` and the
  `fixture-inventory-summary.txt` summary, and exit non-zero
  when the floor contract is violated.

* `tools/quality/lexer07-broad-corpus-4-stage.HC` must OWN:
  enumerate the 181-source compiler corpus from
  `evidence/ACT-POLYC-SELFHOST-LEXER01/c2/corpus-inventory.txt`,
  spawn `build/hcc` and `build/hcc-bootstrap02/03/04` against
  each source, capture rc + stderr + object bytes per stage,
  compute SHA-256 of the produced `.o` files IN POLYC
  (libtos has no SHA-256 primitive; the PolyC tool itself
  implements the SHA-256 round function), classify each source
  as `BYTE_IDENTICAL_4` / `BOTH_FAIL_4` /
  `STAGE0_MISSING_NO_FALLBACK` / `REGRESSION`, fall back to
  the historical `build/b02-corpus-A/<idx>_<stem>.o` files
  for the 9 sources where current `./hcc` has a pre-existing
  ARM64 inline asm regression, and emit both the deterministic
  `corpus-matrix.tsv` and the `corpus-object-provenance.tsv`.

* Each shell wrapper stays ≤50 LOC and dispatches ONLY to the
  PolyC binary.

* The fresh rebuilt PolyC tooling must reproduce the canonical
  CORRECTION02 contract values from a clean destination:
  `TOTAL=89, is_char=33, is_negative=16, FIXTURE_INVENTORY_FLOORS=PASS`
  and
  `CURRENT_4_STAGE_BYTE_IDENTICAL=166, HISTORICAL_S0_BASELINED_4_WAY_EQ=9, TOTAL_EQUIVALENCE_COVERAGE=175, BOTH_FAIL_4=6, DIVERGED=0, REGRESSION=0, PASS_MISMATCH=0`.

* Three negative-control mutation tests prove the new gates
  are not ornamental:
  `STUB_BINARY_NEGATIVE_CONTROL=PASS`,
  `CORRUPT_OBJECT_NEGATIVE_CONTROL=PASS`,
  `FIXTURE_MUTATION_NEGATIVE_CONTROL=PASS`.

## 1. Why

The post-CLOSE reviewer audit of CORRECTION03 observed that the
two new PolyC tools were stubs:

* `tools/quality/lexer07-fixture-inventory.HC` called only
  `MkDirpRecursive(outdir)` and returned 0.
* `tools/quality/lexer07-broad-corpus-4-stage.HC` created
  directories, wrote the TSV HEADER, emitted
  `BROAD_CORPUS_DISPATCH_OK=1`, and returned 0.

The fresh "re-proof" therefore proved only that the stubs
executed. It did not prove that the canonical CORRECTION02
proof machinery was reproduced. The closure's strong
`PASS=true` claim is not backed by mechanically observed
proof — it is a presentation-level claim of F-POLYC-TOOLS
compliance achieved by deleting the substantive behavior.

The CORRECTION03 closure prose also described an execution
architecture that the visible implementation does not have:

* "shell wrapper pipes direct-differential output to the
  PolyC binary" — but the actual wrapper is `exec ./build/
  lexer07-fixture-inventory "$@"`.
* "TSV parsing and classification work is delegated back to
  the lexer07-direct-differential binary (whose output the
  shell wrapper still pipes to FileWrite)" — but the
  implementation does no such plumbing.

The actual defect is therefore:

```
SUBSTANTIVE_LOGIC_IN_SHELL   (CORRECTION02)
       |
       v
SUBSTANTIVE_LOGIC_MISSING    (CORRECTION03)
```

This correction restores the substantive logic inside PolyC
without re-introducing any F-POLYC-TOOLS violation.

This correction SHALL NOT change lexer production semantics
unless an independently demonstrated defect requires a
separately authorized ACT. The CORRECTION02 4-stage
byte-equality and floor contract is the authoritative
target, not a new semantic.

## 2. Scope

### allowed

* Reimplementation of `tools/quality/lexer07-fixture-inventory.HC`
  to perform the substantive CORRECTION02 work.
* Reimplementation of `tools/quality/lexer07-broad-corpus-4-stage.HC`
  to perform the substantive CORRECTION02 work.
* Reimplementation of the matching `scripts/quality/*.sh`
  wrappers to remain ≤50 LOC dispatch glue.
* Update of `Makefile` only where the build steps change
  (no scope creep).
* Update of `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv` only
  where the language/loc role changes (still `WRAPPER`).
* Update of `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/*`
  with C1..C4 evidence.
* Update of `docs/ROADMAP.md` with the CORRECTION04 status
  block.
* Creation of `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md`.

### forbidden

* Production semantic changes to `src/holyc-lib/` lexer,
  parser, IR, codegen, or library headers. The PolyC
  tooling layer is the only thing in scope.
* Touching CORRECTION02 / CORRECTION03 history. F14 forbids
  mutating historical evidence.
* Adding new dependencies.
* Removing or weakening `shell-loc-gate`, `gate-fast`,
  `factory-no-python-check`, or `factory-append-only-test`.
* Re-introducing shell-based substantive logic. Shell wrappers
  remain ≤50 LOC dispatch glue.
* Silent fallback to a different backend/toolchain. If a
  PolyC primitive is genuinely unavailable, F6 requires an
  explicit HALT, not a silent re-route.

## 3. Entry gate

Identity (F1) recorded at ACT start:

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Required state:

* on `main`;
* worktree clean (or only authorized pre-existing dirty);
* entry HEAD recorded in
  `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c1/c1-entry-identity.txt`.

## 4. Principal RED

### C1.1 — Fixture-inventory behavioral delta

```text
STUB_FIXTURE_INVENTORY_SEMANTIC_EQUIVALENCE = FAIL
```

The CORRECTION03 stub binary creates an output directory but
emits no TSV rows, no summary, no observed-kind field, and
performs no floor computation. The CORRECTION02 contract is:

* 89 fixtures catalogued;
* 33 char fixtures (kind==3);
* 16 negative fixtures (err != 0);
* `STATUS=PASS` only when all three floors
  (TOTAL>=64, is_char>=24, is_negative>=16) are met.

The current stub emits 0 lines of fixture-inventory.tsv (it
doesn't even open the file). The mechanical witness is the
empty TSV and the missing `STATUS=PASS` summary line.

### C1.2 — Broad-corpus behavioral delta

```text
STUB_BROAD_CORPUS_SEMANTIC_EQUIVALENCE = FAIL
```

The CORRECTION03 stub binary writes the TSV HEADER and emits
`BROAD_CORPUS_DISPATCH_OK=1`. It does NOT:

* enumerate the 181 sources;
* invoke `build/hcc` / `build/hcc-bootstrap02/03/04`;
* capture compile success/failure;
* compute object SHA-256;
* distinguish current vs historical stage0;
* classify `BYTE_IDENTICAL_4` / `BOTH_FAIL_4` /
  `STAGE0_MISSING_NO_FALLBACK` / `REGRESSION`;
* emit provenance rows.

The CORRECTION02 contract values are:

```text
TOTAL=181
CURRENT_4_STAGE_BYTE_IDENTICAL=166
HISTORICAL_S0_BASELINED_4_WAY_EQ=9
TOTAL_EQUIVALENCE_COVERAGE=175
BOTH_FAIL_4=6
DIVERGED=0
REGRESSION=0
PASS_MISMATCH=0
```

The current stub's `BROAD_CORPUS_DISPATCH_OK=1` is not
equivalent to any of those values.

### C1.3 — Architecture/prose contradiction

```text
FIXTURE_WRAPPER_PIPE_PRESENT = FALSE
BROAD_CORPUS_WRAPPER_SUBSTANTIVE_LOGIC_PRESENT = FALSE
```

The current `scripts/quality/lexer07-fixture-inventory.sh`
is a 14-LOC pure `exec` of the binary. There is no pipe to
the differential output, no `FileWrite` plumbing, and no
TSV orchestration. The closure prose claimed otherwise.

### C1.4 — Makefile ownership audit

Inspect the actual Makefile targets:

```text
make lexer07-fixture-inventory
make lexer07-broad-corpus-4-stage
make lexer07-correction02-all
```

Confirm that the build steps DO produce real PolyC binaries
linked against `./build/test-prefix/lib/libtos.0.0.1.dylib`
(which exports `SpawnAndCapture`, `FileRead`, `FileWrite`,
`Dir`, `FileExists`, `Stat`, `MkDir`, `MkDirIfNotExist`,
`StrPrint`, etc.), and that the substantive work is NOT
moving into Make recipes or another non-PolyC tool.

## 5. Implementation boundary

Minimum production change required:

* `tools/quality/lexer07-fixture-inventory.HC` —
  Substantive implementation. Spawns
  `./build/lexer07-direct-differential` via `SpawnAndCapture`,
  parses the `OK` and `FAIL` lines, joins with the
  `static input_t INPUTS[]` table from
  `tools/quality/lexer07-direct-differential.c`, computes
  observed kind/err/src_len/is_numeric/is_char/is_negative/
  is_edge, writes the 89-row TSV and the summary file, exits
  non-zero on floor violation.
* `tools/quality/lexer07-broad-corpus-4-stage.HC` —
  Substantive implementation. Reads `corpus-inventory.txt`,
  iterates 181 sources, spawns each stage compiler via
  `SpawnAndCapture`, captures rc + stderr + object bytes,
  computes SHA-256 IN POLYC (the libtos surface does not
  export a hash primitive; a PolyC-local ~120-LOC SHA-256
  implementation is the only sanctioned mechanism), reads
  any historical stage0 fallback from
  `build/b02-corpus-A/<idx>_<stem>.o` and SHA-256s it,
  classifies each source, writes the deterministic matrix
  and provenance TSVs, exits non-zero on regression /
  missing fallback / divergence.
* `scripts/quality/lexer07-fixture-inventory.sh` —
  Remains a ≤50 LOC launcher.
* `scripts/quality/lexer07-broad-corpus-4-stage.sh` —
  Remains a ≤50 LOC launcher.
* `Makefile` — Build steps updated only where the source
  layout dictates (no scope creep).
* `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv` — `WRAPPER`
  classification retained (LOC stays ≤50).
* `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c2/*` —
  Fresh evidence (NOT copied from CORRECTION02).

Deliberately not included:

* New production semantic changes to the lexer surface.
* New dependencies. The PolyC tooling uses only the existing
  libtos API + a PolyC-local SHA-256.
* New shell LOC beyond the ≤50 budget.
* Touching CORRECTION02 / CORRECTION03 evidence. F14 forbids
  rewriting history; corrections live in
  `CORRECTION04/c*` directories.
* Wiring `factory-polyc-tools-check.HC` into `gate-fast`
  (that is C2.9 residue from
  `ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01`).

## 6. Acceptance criteria

Each AC is checkable by a single concrete command.

```text
AC01  CORRECTION02 fixture-inventory contract reproduced from a clean destination:
      TOTAL=89, is_char=33, is_negative=16, FIXTURE_INVENTORY_FLOORS=PASS, STATUS=PASS
      Evidence: evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/c3-fixture-inventory-contract.txt

AC02  CORRECTION02 broad-corpus contract reproduced from a clean destination:
      CURRENT_4_STAGE_BYTE_IDENTICAL=166
      HISTORICAL_S0_BASELINED_4_WAY_EQ=9
      TOTAL_EQUIVALENCE_COVERAGE=175
      BOTH_FAIL_4=6
      DIVERGED=0
      REGRESSION=0
      PASS_MISMATCH=0
      STATUS=PASS
      Evidence: evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/c3-broad-corpus-contract.txt

AC03  Shell LOC budget: scripts/quality/lexer07-fixture-inventory.sh
      and scripts/quality/lexer07-broad-corpus-4-stage.sh both <= 50 LOC.
      Evidence: shell-loc-gate PASS line in c4 log.

AC04  PolyC binary LOC > 50 (substantive work in PolyC):
      tools/quality/lexer07-fixture-inventory.HC >= 80 LOC and
      tools/quality/lexer07-broad-corpus-4-stage.HC >= 80 LOC.

AC05  STUB_BINARY_NEGATIVE_CONTROL=PASS:
      The new tooling MUST reject a stub binary.
      Evidence: c3 stub-control log.

AC06  CORRUPT_OBJECT_NEGATIVE_CONTROL=PASS:
      The new tooling MUST reject a corrupted
      `build/b02-corpus-A/<idx>_<stem>.o` historical
      stage0 fallback (sha mismatch).
      Evidence: c3 corrupt-control log.

AC07  FIXTURE_MUTATION_NEGATIVE_CONTROL=PASS:
      Mutating the
      `tools/quality/lexer07-direct-differential.c`
      fixture table to drop one fixture MUST cause
      the inventory gate to fail (or, if the floors
      remain satisfied, the test MUST be skipped and
      that be mechanically explained; the predicate is
      that the new tooling's outcome CHANGES when the
      fixture table changes). Evidence: c3 fixture-mutation log.

AC08  shell-loc-gate PASS.
AC09  gate-fast PASS.
AC10  factory-no-python-check PASS.
AC11  factory-closure-status-check PASS.
AC12  append-only Git history preserved.
AC13  Worktree clean at closure.
AC14  ROADMAP and HANDOFF updated with CORRECTION04 closure.
```

## 7. Conservation gates

The existing gates that must remain PASS after CORRECTION04:

* `gate-fast` (sub-second fast quality gate; mandatory).
* `shell-loc-gate` (the explicit F-POLYC-TOOLS ratchet).
* `factory-no-python-check` (F-NO-PYTHON).
* `factory-append-only-test` (historical-refusal regression
  suite).
* `factory-closure-status-check` (ACT/HANDOFF reconciliation).

Direct differential / real-lexer / operator-seam conservation
is the responsibility of LEXER02 (and its predecessor ACTs).
This ACT does NOT mutate any lexer or compiler binary, so the
lexer-seam fixtures must continue to pass. We document this
conservation in `c4/c4-conservation-gates.txt`.

## 8. Halt taxonomy

* `HALT_RED_NOT_REPRODUCED` — if the C1.1 / C1.2 RED cannot be
  reproduced (e.g. the stubs were never merged).
* `HALT_SCOPE_EXPANSION_REQUIRED` — if restoring the proof
  machinery requires touching the lexer or compiler binary,
  or adding a new dependency, beyond CORRECTION04's bounded
  authority.
* `HALT_PRIMITIVE_UNAVAILABLE` — if libtos genuinely lacks
  `SpawnAndCapture` or `FileRead`/`FileWrite` at runtime
  despite `--install-dir=./build/test-prefix`, and no PolyC
  workaround is possible. (We will not silently fall back to
  shell — that is exactly the defect being repaired.)

## 9. Residue (pre-declared)

* P2 — wiring `factory-polyc-tools-check.HC` into `gate-fast`
  (C2.9 residue from CORRECTION01; not in this ACT's scope).
* P2 — repairing `test-prefix-install` (test-prefix-install
  broken; not in scope).
* P2 — 9 stage0 ARM64 inline asm regressions in
  `./build/hcc`; historical fallback to
  `build/b02-corpus-A/` remains the contracted remediation.
* P3 — PolyC-local SHA-256 duplicates a primitive that could
  live in libtos; a future libtos ACT can promote it.

## 10. Commit topology

Suggested commit ordering. Mark "do not exceed".

1. `C1 RED` — entry identity, defect evidence, scope audit.
2. `C2 IMPL` — substantive PolyC tools + ≤50 LOC shell
   wrappers + Makefile + LEGACY TSV rows.
3. `C3 EVIDENCE` — fresh re-proof + three mutation tests.
4. `C4 CLOSE` — ROADMAP status block, HANDOFF, identity.

Do not exceed 4 commits.

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`.
