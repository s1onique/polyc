# ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
ACT-Phase: RED

**Title:** Restore Bash-equivalent oracle strength in the
PolyC GEP01 harness — repair predicate weakening that
allowed the C4 CLOSE=PASS verdict to be false-green.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:**
- `ACT-POLYC-TOOLING-MIGRATE-GEP01` (CLOSED PASS — contains
  the defects this ACT repairs; per F14 the predecessor
  evidence tree is NOT mutated by this ACT)

**Class:** TOOLING / TEST-HARNESS-CORRECTION

**Primary production seam:** `tools/quality/llvm-gep01-test.HC`
(test harness only)

**Compiler semantic changes:** FORBIDDEN
**Parser / typechecker changes:** FORBIDDEN
**Neutral-IR changes:** FORBIDDEN
**LLVM backend changes:** FORBIDDEN
**ABI changes:** FORBIDDEN
**Factory-doctrine changes:** FORBIDDEN
**New Bash logic > 0 LOC:** FORBIDDEN
**Historical evidence mutation (any c{1,2,3,4} file under
  evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/):** FORBIDDEN
**Reopening MIGRATE-GEP01 for general amendment:** FORBIDDEN
**Opening SHELL-BUDGET01 or any new Track-B ACT:** FORBIDDEN
**Modifying any other toolchain / harness / seed file
  outside tools/quality/llvm-gep01-test.HC:** FORBIDDEN
**Re-implementing or widening tooling.HC:** FORBIDDEN

---

# 0. Mission

The post-cutover PolyC harness
`tools/quality/llvm-gep01-test.HC` reports
`GEP01_PASS=30 GEP01_FAIL=0 STATUS=PASS rc=0`, but several
of its predicates are strictly weaker than the legacy Bash
contract frozen in
`evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/legacy-source.txt`
(which is the verbatim text of
`scripts/quality/llvm-gep01-test.sh` pre-cutover). The
predicates still accept the genuine GEP01 IR; they also
falsely accept malformed IR that the legacy contract would
reject.

This ACT repairs the predicate equivalence for the
following rows of the c1/oracle-matrix.tsv freeze:

| Row | assertion_id              | Defect |
|-----|---------------------------|--------|
| 04  | readat_dynamic_gep_and_load_i8 | dynamic-index GEP shape `%[0-9]+, i64 %[0-9]+` collapsed to whole-file `Contains("getelementptr i8, ptr %")` |
| 07  | readat_gep_shape          | same as row 04 |
| 08  | gep_used_as_load_address  | `%gep_i8` SSA-value binding collapsed to whole-file `Contains("load i8, ptr %")` |
| 26  | ir_gep_rejected           | opcode-line binding `IR_GEP.*\(REJECTED\)` split into two independent whole-file `StrStr` calls |
| 27  | ir_lea_rejected           | same as row 26 for IR_LEA |
| 28  | ir_iadd_supported         | same as row 26 for IR_IADD / `(SUPPORTED)` |

And one architectural regression (P1):

| P1  | scratch lifecycle         | caller must pre-create `--scratch` dir; legacy Bash harness owned it via `mkdir -p` + `trap rm -rf` |

Success criterion:

```
GEP01_PASS = 30
GEP01_FAIL = 0
STATUS = PASS
```

under:

1. The genuine GEP01 IR (rows 04/07/08/26/27/28 against
   the real hcc-emitted read-at.ll and the real
   cap-verifier output);
2. Each principal-RED malformed fixture from
   `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/red/`
   (which the restored predicates MUST reject).

The harness remains canonical. No compiler / parser / IR /
backend / ABI / Factory doctrine change. No new Bash logic.

---

# 1. Why now

A review of `ACT-POLYC-TOOLING-MIGRATE-GEP01` identified
the predicate-equivalence defects above. F2 / F13
(evidence over prose) require reproducing them against the
real seam before any production change. The defects were
reproduced in this session against:

- the harness source at
  `tools/quality/llvm-gep01-test.HC`
- the legacy Bash contract at
  `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/legacy-source.txt`
- the c1 oracle matrix at
  `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/oracle-matrix.tsv`
- a freshly built harness binary (`/tmp/llvm-gep01-test`)
  exercising the real hcc + llvm-as + opt toolchain

The reproduction protocol and per-row witnesses are in
`evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/red/`.

The c4 PASS verdict for MIGRATE-GEP01 is preserved as
historical evidence (F14). The current truth supersedes
the historical record; this ACT is the correction.

---

# 2. Source-of-truth hierarchy for the corrections

In descending order of authority:

1. The legacy Bash contract (verbatim at c1/legacy-source.txt)
   for predicates;
2. The c1 oracle matrix (verbatim at c1/oracle-matrix.tsv)
   for assertion_ids and observable text;
3. The principal RED witnesses at
   correction01/red/ for the predicate gap;
4. The c4 polyC harness source for the current weakened
   predicate text.

If any conflict emerges, items 1–2 are binding. F5 forbids
weakening the legacy contract to obtain PASS.

---

# 3. Allowed production change (bounded)

Only the predicate bodies and the scratch-lifecycle block
of `tools/quality/llvm-gep01-test.HC` may change. The
minimum required restorations are:

1. **Row 04 (readat_dynamic_gep_and_load_i8):** The combined
   predicate must require both:
   - `getelementptr i8, ptr %[0-9]+, i64 %[0-9]+`
   - `load i8, ptr %`
   to be present in the emitted `read-at.ll`. (Legacy
   contract: `grep -qE 'getelementptr i8, ptr %[0-9]+, i64 %[0-9]+'`
   AND `grep -qE 'load i8, ptr %'`.)

2. **Row 07 (readat_gep_shape):** The predicate must require
   `getelementptr i8, ptr %[0-9]+, i64 %[0-9]+` in
   `read-at.ll`. (Legacy contract: `grep -qE 'getelementptr i8, ptr %[0-9]+, i64 %[0-9]+'`.)

3. **Row 08 (gep_used_as_load_address):** The predicate must
   require `load i8, ptr %gep_i8` in `read-at.ll`. The
   `%gep_i8` SSA-value binding is mandatory. (Legacy
   contract: `grep -qE 'load i8, ptr %gep_i8'`.)

4. **Rows 26 / 27 / 28 (capability status):** Each predicate
   must bind the opcode name to the marker on the SAME
   line. The legacy contract uses the regex
   `IR_<X>.*\(REJECTED\)` / `IR_<X>.*\(SUPPORTED\)`, which
   rejects malformed verifier output where the opcode and
   the marker appear on different lines. The PolyC
   restoration must enforce the same line-binding.

5. **P1 (scratch lifecycle):** The harness MUST create its
   scratch directory if absent and MUST clean it on exit
   (or document explicit ownership otherwise). The legacy
   Bash used `mkdir -p` + `trap 'rm -rf "$EVID/c3/_tmp"' EXIT`.
   The PolyC restoration may use `mkdir -p` (via PolyC's
   `MkDir` or `FileMkDir` primitive) + `atexit`-style
   cleanup, but MUST NOT require the caller to pre-create
   the scratch dir.

The restoration MAY introduce a small local helper (e.g.
`RegExContains` or line-scanning utility) inside
`tools/quality/llvm-gep01-test.HC` to express the regex
predicates. F8 forbids introducing a general-purpose
regex engine in `src/holyc-lib/tooling.HC` for this ACT.

All other harness source text (CLI parsing, Toolchain check,
ll-as / opt pipeline, no-ptrtoint / no-inbounds fences,
negative i64idx check, determinism, verdict channel,
seed-failure mode) is OUT OF SCOPE for this ACT.

---

# 4. Forbidden production changes (F7, F15)

This ACT MUST NOT:

- modify compiler semantics, parser, typechecker, IR,
  backend, or ABI (per original ACT §27);
- reopen MIGRATE-GEP01 for any general amendment;
- modify `scripts/quality/llvm-cap-table-verifier.py`
  (the verifier is the contract; predicates must adapt to
  it, not vice versa);
- modify any historical evidence file under
  `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c{1,2,3,4}/`
  (F14, and original ACT §33);
- introduce shell, `/bin/sh`, `bash -c`, `System`, `Sh`,
  `Shlurp` usage in production source;
- rewrite GEP01 fixtures or the cap-table verifier to
  make the predicates pass (per original ACT §27);
- "clean up" historical whitespace or unrelated style;
- introduce mandatory runtime machinery in `tooling.HC`;
- add a new dependency, framework, or external tool;
- begin SHELL-BUDGET01 or any other downstream ACT;
- commit generated test binaries as evidence;
- mutate `Makefile`, `docs/ROADMAP.md` (ROADMAP update is
  a CLOSE-phase concern), or any Factory-doctrine
  document;
- weaken any predicate to obtain PASS (F5).

---

# 5. Principal RED (per F3)

The RED phase must establish that each of the six
predicate defects and the P1 scratch regression is
observable against the real seam BEFORE any production
change.

The RED packet is at:
```
evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/red/
```

Contents (created during the RED phase of this ACT):

| File                          | Purpose |
|-------------------------------|---------|
| `read-at-malformed.ll`        | Synthetic read-at IR that satisfies the weakened predicates but fails the legacy contract for rows 04 / 07 / 08. |
| `cap-malformed.txt`           | Synthetic cap-verifier output where opcode names and `(REJECTED)` / `(SUPPORTED)` markers appear on separate lines (passes weakened predicates; fails legacy line-binding for rows 26 / 27 / 28). |
| `predicate-gap-proof.txt`     | Step-by-step transcript of the cross-witness exercise: legacy `grep -E` vs weakened `StrStr` on each malformed fixture. |
| `scratch-lifecycle-proof.txt` | Transcript proving that the current harness produces a noisy FAIL cascade when `--scratch` is absent. |

The principal RED is satisfied when each malformed
fixture is observed to:

- PASS under the current weakened harness predicate;
- FAIL under the legacy Bash-equivalent predicate.

(For P1: FAIL when the caller omits `mkdir -p`; the
legacy harness owned the scratch dir and succeeded.)

---

# 6. Acceptance criteria

Each AC is checkable by a single concrete command per the
template.

AC01. The current harness reports
       `GEP01_PASS=30 GEP01_FAIL=0 STATUS=PASS rc=0` on
       the genuine GEP01 IR.
       Reproduction:
       ```
       ./hcc --install-dir=$(pwd)/build/test-prefix \
             -o /tmp/llvm-gep01-test \
             tools/quality/llvm-gep01-test.HC
       rm -rf /tmp/correction01-ac01-scratch
       /tmp/llvm-gep01-test \
           --hcc=./hcc \
           --llvm-install-dir=$(pwd)/build/test-prefix \
           --scratch=/tmp/correction01-ac01-scratch
       ```
       Expected: GEP01_PASS=30 GEP01_FAIL=0 STATUS=PASS
       and rc=0. Note that the harness now owns the
       scratch dir, so `rm -rf` beforehand is fine.

AC02. Row 04 predicate rejects
       `correction01/red/read-at-malformed.ll` when that
       file is substituted for the hcc-emitted
       `read-at.ll`. Reproduction: AC01 with a final
       `cp correction01/red/read-at-malformed.ll \
          /tmp/correction01-ac01-scratch/read-at.ll`
       step inserted BEFORE the harness runs the
       llvm-textual-structure block.
       Expected: row-04 fails (predicate gap closed).

AC03. Row 07 predicate rejects the same malformed
       `read-at.ll`.
       Reproduction: as AC02 but for row 07.

AC04. Row 08 predicate rejects the same malformed
       `read-at.ll` (asserts `%gep_i8` SSA binding).
       Reproduction: as AC02 but for row 08.

AC05. Rows 26 / 27 / 28 predicates reject a malformed
       cap-verifier output where opcode and marker are
       on separate lines.
       Reproduction: substitute
       `correction01/red/cap-malformed.txt` for
       `cap-verifier.txt` in the harness scratch dir
       before running.

AC06. P1 regression closed: harness succeeds when its
       `--scratch` directory does NOT pre-exist.
       Reproduction: `rm -rf /tmp/correction01-ac06-scratch`
       (no `mkdir -p`) followed by harness invocation.
       Expected: GEP01_PASS=30 (not the prior 2/12
       cascade).

AC07. Conservation: `make unit-test`, `make jit-unit-test`,
       `make lsp-test` (where applicable) all PASS with
       counts unchanged from the c4 close-tree baseline.

AC08. Patch hygiene: `git diff --check` on the closing
       commit is clean.

AC09. Worktree: clean after the closing commit.

AC10. Append-only invariant: still PASS
       (`sh scripts/quality/factory-append-only-test.sh`).

AC11. Direct-argv audit: forbidden-token count remains
       zero in production source.

AC12. F1–F15 still intact; F-GIT-IDENTITY honored (no
       SHA-of-self claims in any new closure artifact).

---

# 7. HALT conditions

- `HALT_RED_NOT_REPRODUCED` — if any of the six
  predicate defects cannot be reproduced against the
  real seam in the principal-RED phase, halt.
- `HALT_SCOPE_EXPANSION_REQUIRED` — if correct
  completion requires changes outside
  `tools/quality/llvm-gep01-test.HC` (other than the
  c1 frozen legacy-source.txt which is read-only).
- `HALT_TOOLING_RUNTIME_GAP` — if the regex-equivalent
  predicate strictly requires a new primitive in
  `tooling.HC` (it must NOT — PolyC's `StrStr` plus
  line iteration suffice).
- `HALT_EVIDENCE_MUTATION` — if any change to the
  c1/c2/c3/c4 evidence tree appears necessary; halt
  instead and classify as residue.
- `HALT_VERDICT_CHANNEL_FALSE_GREEN` — if the
  --mode=fail seed still does not flip exactly one row
  to FAIL with rc=1.
- `HALT_CONSERVATION_GATE_REGRESSION` — if any existing
  conservation gate regresses.

---

# 8. Commit topology (per F12)

Small truthful commits. The RED commit establishes the
principal RED; the IMPL commit restores each predicate
to its legacy contract strength; the CLOSE commit
verifies the conservation gates and reports verdict.

C1 RED       (this commit)  — ACT document +
                                correction01/red/ principal
                                RED witnesses.
C2 IMPL      (deferred)     — restore rows 04/07/08 to
                                legacy regex-bound form;
                                restore rows 26/27/28 to
                                opcode-line-bound form;
                                restore P1 scratch
                                lifecycle to harness-owned.
C3 CLOSE     (deferred)     — conservation gates
                                re-verified; verdict.

Cardinality-1 CLOSE: exactly ONE commit for this ACT
may carry `ACT-Phase: CLOSE` (and `ACT-Verdict: PASS`).

---

# 9. Commit trailer contract

C1 (this commit):

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
    ACT-Phase: RED

C2:

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
    ACT-Phase: IMPL

C3:

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
    ACT-Phase: CLOSE
    ACT-Verdict: PASS

No SHA-of-self fields. The closing commit's SHA is
queried from Git, not embedded in this document.

---

# 10. Residue (pre-declared per F11)

P0 — none anticipated beyond the six predicate defects
and the P1 lifecycle regression (which are this ACT's
mandatory scope).

P1 — the c2/c3/c4 historical evidence tree at
`evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c{1,2,3,4}/`
records the false-green closure. Per F14 it is preserved
immutably; downstream ACTs MUST treat it as historical
evidence, not as current truth.

P2 — none anticipated. The existing P2 entries from the
c4 close (two ENVIRONMENTALLY_UNAVAILABLE gates requiring
`/usr/local`-installed hcc; legacy scratch path note) are
not affected by this ACT.

---

# 11. Closure handoff (deferred to C3)

Will contain the standard structured fields:

    VERDICT
    IDENTITY (branch, predecessor, ACT id, phase, verdict)
    RED (principal RED summary, with reproduction commands)
    IMPLEMENTATION (minimum source diff)
    GATES (BUILD, TARGETED, UNIT, JIT, LSP, DIFF_CHECK)
    SCOPE (FILES_CHANGED, *_CHANGED=NO)
    RESIDUE (P0/P1/P2)
    NEXT_ACT

Per the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md`. The authoritative
verdict lives on the C3 commit's `ACT-Verdict` trailer,
not on the HANDOFF file.

---

# 12. Next ACT on PASS

This ACT does NOT begin the next Track-B step. On PASS,
NEXT = `ACT-POLYC-TOOLING-SHELL-BUDGET01`, exactly as
recorded in the c4 closure-summary for MIGRATE-GEP01.

If this ACT itself must HALT (e.g. on
`HALT_RED_NOT_REPRODUCED` because no real defect was
found, or on `HALT_SCOPE_EXPANSION_REQUIRED`), the
next ACT is to recommend the bounded expansion in a
separate CORRECTION02 (NOT in this turn).

HARD STOP after C3 CLOSE.
