# `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01`

**Title:** Reconcile the closure-truth gap of
`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` against the v2
`F-MECHANICAL-BLOCKING` doctrine without re-mutating the
mechanically-GREEN production delta.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** GOVERNANCE / CLOSURE-TRUTH / CORRECTION

**Predecessor:** `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`
**Predecessor outcome:** disputed — committed `ACT-Verdict: PASS`
trailer at the C4 close (commit `2b1786c`) co-exists with an
explicit `AC18 = FAIL` / `AC29 = FAIL` strong-closure block in
`evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c4/acceptance-matrix.txt`.

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN** in this ACT. The
predecessor's `src/aarch64.c` delta is mechanically GREEN and must
not be re-mutated to make prose true (F2; v2 §25 EVIDENCE OVER
PROSE).

**Re-mutation of the predecessor evidence directories:**
**FORBIDDEN** (F14). Corrections live only in
`evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/**`.

---

## 0. Mission

This ACT does not repair a new production defect and does not
relax the predecessor ACT's strong-closure criterion. It records
the mechanically-demonstrable truth of the predecessor's
closure record under the v2 doctrine that became binding on
the predecessor's CLOSE commit (`2b1786c` at 2026-09-12 23:54:xx
+0300, after `ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01` CLOSE at
2026-09-12 19:15:45 +0300).

The single mechanical claim this ACT must establish:

```
predecessor_production_semantic_delta = GREEN
predecessor_gate_push_failure        = ENVIRONMENTAL
predecessor_gate_push_failure_blocks_next = NO
```

and only that.

---

## 1. Why this ACT exists (reviewer verdict 2026-09-12)

The reviewer verdict observed:

1. The predecessor's own `c4/acceptance-matrix.txt` records
   `AC18 = FAIL` (`GEP01_PASS=26 GEP01_FAIL=4`) and
   `AC29 = FAIL` (full gate-push FAIL).
2. The same file's §12 strong-closure block records
   `GEP01 = 26/4 FAIL` and `GATE_PUSH = FAIL`.
3. The committed `ACT-Verdict: PASS` trailer on `2b1786c` and
   the `VERDICT=PASS` claim in `HANDOFF.md` therefore disagree
   with the same packet's own evidence.
4. The gep01 4-failure aggregate is mechanically two distinct
   witnesses, not one:
   - D1: `readat.HC: SHAPE_DEPENDENT counter = ? (expected >= 1):
     shape_dependent marker not found in stderr`
     (single row).
   - D2: `IR_GEP = REJECTED ... could not read cap verifier output`,
     `IR_LEA = REJECTED ... could not read cap verifier output`,
     `IR_IADD = SUPPORTED ... could not read cap verifier output`
     (three rows, all `could not read cap verifier output`).
5. The JIT capture contains three lines
   (`[dbg] slow-path asm_funcs scan for '_FREE'`,
    `[dbg]   cand fname='MAlloc'`,
    `[dbg]   cand fname='Free'`)
   that do not appear in any current source file in `src/`
   (`grep -rn 'slow-path\\|cand fname\\|\\[dbg\\]' src/`
   returns zero matches). They are evidence-packet residue,
   not a current production leak.
6. The fresh build emits seven new warnings in `src/aarch64.c`
   (six `const char *` -> `char *` `mapGetLen` discards-qualifiers
   at lines 307/309/312/315/318/321, and one u64/int sign-compare
   at line 337).

Items 1-3 are the closure-truth gap. Item 4 is the missed
mechanical decomposition. Items 5-6 are hygiene / warning
residue that the predecessor's HANDOFF listed under one
over-broad P1 entry.

---

## 2. Scope

### allowed

- `docs/acts/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01.md`
  (this file)
- `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/**`
- `docs/ROADMAP.md` (status reconciliation only; no new
  roadmap items beyond what already exists)

### forbidden

- `src/aarch64.c` (the production semantic delta is mechanically
  GREEN; v2 §25 forbids prose-driven re-mutation)
- `src/x86_64.c`
- the predecessor ACT's evidence directories
  (`evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c{1,2,3,4}/` and
  `HANDOFF.md`) — F14 forbids mutating any closed ACT's evidence
  directory, including appending "ADDENDUM" blocks to existing
  files (see `AGENTS.md` §F14).
- `scripts/quality/llvm-cap-table-verifier.py` and the
  SHAPE_DEPENDENT stderr marker — this ACT does NOT attempt
  to repair the gep01 infrastructure failure; that is reserved
  for a separate bounded ACT (see `c4/roadmap-transition.txt`
  of the predecessor ACT, and §10 below).
- `tools/quality/llvm-gep01-test.HC`
- `docs/factory/DOCTRINE.md`
- `docs/factory/HANDOFF-TEMPLATE.md`
- any push to `origin/main`
- opening `ACT-POLYC-BOOTSTRAP01` in this ACT — this ACT
  re-authorizes it for opening under §10 conditions only;
  opening is a separate human action.

---

## 3. Entry gate (F1)

```text
git branch --show-current = main
git status --short        = (empty)
git rev-parse HEAD        = b76f0d8d38d57e950e69e559e486fde0a0555175
                           (HANDOFF for the predecessor ACT;
                            docs-only commit)
```

Recorded before any mutation.

---

## 4. Mechanical claim: predecessor production delta is GREEN

The predecessor's bounded production delta is:
- `src/aarch64.c` only (+136/-28 across C2 and C2.1).
- Two new helpers: `aarch64ExternalSymbolAddr` (GOTPAGE emitter,
  Apple-Darwin only) and `aarch64IsExternalGlobalSymbol`
  (6-stage classifier with slow-path asm-fname -> C-name bridge).
- Routing applied at IR_LEA, IR_LOAD_DEREF, IR_STORE_DEREF.
  IR_CALL (`bl _sym` / BRANCH26) left untouched.
- F2-recon-confirmed: existing same-image control still uses
  `@PAGE / @PAGEOFF` (the classifier returns 0 for `AST_GVAR`
  without `AST_FLAG_EXTERN`).

Mechanical evidence the delta is GREEN on the predecessor's
final tree (`b76f0d8`):

```
make unit-test       PASS  90/90   c3/unit-test.txt
make jit-unit-test   PASS  90/90   c3/jit-unit-test.txt
make lsp-test        PASS  43/43   c3/lsp-test.txt
make gate-fast       PASS          c3/gate-fast.txt
```

External-reference relocation contract verified mechanically:

```
_FREE@GOTPAGE  /  ARM64_RELOC_GOT_LOAD_PAGE21
_FREE@GOTPAGEOFF / ARM64_RELOC_GOT_LOAD_PAGEOFF12
_Fs@GOTPAGE    /  ARM64_RELOC_GOT_LOAD_PAGE21
_Fs@GOTPAGEOFF /  ARM64_RELOC_GOT_LOAD_PAGEOFF12
```

(See `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c3/external-relocations.txt`
and `external-relocations-fixture.HC`.)

Same-image control conservation:

```
local-control.HC            PASS  NC1 (c1 + c2/local-control-post.txt)
missing-external-link.txt   PASS  NC2 (linker rejects _NONEXISTENT)
archive/dylib neutrality    PASS  NC4 (canonical libtos install;
                                       no consumer toggle added)
```

---

## 5. Mechanical claim: gep01 4-failure aggregate is
   byte-identical pre- and post- C2

The predecessor ACT recorded `GEP01_PASS=26 GEP01_FAIL=4` in
`c3/llvm-gep01-test.txt`. The predecessor's own predecessor
(`ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01`)
recorded the **same** `GEP01_PASS=26 GEP01_FAIL=4` in
`c3/gate-push-correction01.log` at line 428-430, against a tree
that did NOT contain the predecessor's production delta
(`src/aarch64.c` was the unfixed `aarch64GlobalAddr` emitting
ordinary `@PAGE / @PAGEOFF` for `_FREE`).

Pre-/post- C2 byte comparison of the failing rows:

```
readat.HC SHAPE_DEPENDENT counter = ? ... marker not found in stderr
    pre-C2:  evidence/.../PREBOOTSTRAP-GATES01-CORRECTION01/c3/gate-push-correction01.log:401
    post-C2: evidence/.../AOT-PIC-EXTERNAL-REFS01/c3/llvm-gep01-test.txt:193
    conclusion: BYTE-IDENTICAL TEXT. Mechanical failure mode is
                unchanged by the production delta.

IR_GEP   could not read cap verifier output
IR_LEA   could not read cap verifier output
IR_IADD  could not read cap verifier output
    pre-C2:  .../gate-push-correction01.log:422-424
    post-C2: .../llvm-gep01-test.txt:214-216
    conclusion: BYTE-IDENTICAL TEXT. Mechanical failure mode is
                unchanged by the production delta.
```

Therefore:

```
production_subject_attribute = NONE
gate_push_failure_attributable_to_production_delta = FALSE
```

Under v2 §25 ("failed environmental gates proven unrelated
to the changed production subject" -> `HALT_CLASS = GOVERNANCE`,
`BLOCKS_NEXT = NO`) and §25 EVIDENCE OVER PROSE
("mechanical evidence determines production truth; prose is
corrected or classified as residue"), the gep01 aggregate is
not a blocker for the predecessor ACT's production claim.

---

## 6. Mechanical claim: gep01 4-failure aggregate is two
   distinct witnesses

Per reviewer's recommendation, the 4-failure aggregate is
decomposed into two mechanically-distinct witnesses:

```
D1  SHAPE_DEPENDENT stderr marker absent
    Failure mode: `tools/quality/llvm-gep01-test.HC` reads the
                  compile-run stderr of readat.HC for
                  `shape_dependent=<N>` (gep01-test.HC:231-240).
                  The marker is not present in stderr.
    Failure count: 1 row.
    Hypothesised root cause: tooling/environment gap in the
                  host sandbox (readat.HC compile-run does not
                  emit the marker for some reason — distinct from
                  cap-verifier output availability).
    This ACT does NOT diagnose D1 further.

D2  cap verifier output unavailable
    Failure mode: `RunCapability()` (in
                  tools/quality/llvm-gep01-test.HC) cannot read
                  the cap verifier's stdout for IR_GEP, IR_LEA,
                  IR_IADD rows.
    Failure count: 3 rows.
    Hypothesised root cause: cap verifier
                  (`scripts/quality/llvm-cap-table-verifier.py`)
                  emits to a path the host sandbox cannot read,
                  or the verifier exits with no stdout before
                  `RunCapability` polls.
    This ACT does NOT diagnose D2 further.
```

The two witnesses share an infrastructure locality
(`tools/quality/`) but do not share a demonstrated root cause.
A successor bounded ACT should treat them as two separate
RED witnesses (R1 for D1, R2 for D2) and not assume one fix
repairs both.

---

## 7. Closure-truth classification (v2 doctrine)

Per v2 doctrine (`docs/factory/DOCTRINE.md` §25 HALT
CLASSIFICATION, CORRECTIONS, EVIDENCE OVER PROSE):

```
predecessor_production_semantic_claim = GREEN
predecessor_strong_closure_prose      = FAIL (AC18, AC29)
predecessor_ACT_truth                 = disputed_prose
predecessor_blocking_predicate        = absent (B1..B5)

v2 classification:
  HALT_CLASS    = GOVERNANCE
  BLOCKS_NEXT   = NO
```

Rationale, by BLOCKING-predicate enumeration:

- **B1**: gep01 fails but §5 shows failure byte-identical
  pre-/post- C2 and not attributable to the production
  subject. B1 NOT satisfied.
- **B2**: production subject (AArch64 AOT external-ref
  materialisation) is GREEN per §4. B2 NOT satisfied.
- **B3**: none. B3 NOT satisfied.
- **B4**: this ACT does not require production changes.
  B4 NOT satisfied.
- **B5**: BOOTSTRAP01's gep01-dependency is a
  successor-need determination belonging to BOOTSTRAP01's
  opening ACT, not this ACT. This ACT does not assert B5.

Therefore `HALT_CLASS = GOVERNANCE / BLOCKS_NEXT = NO`.

The predecessor's C4 CLOSE trailer (`ACT-Verdict: PASS`) is
preserved (F14); this ACT records an additive
`ACT-Corrected-Verdict` per v2 §25 CORRECTIONS rather than
rewriting the historical trailer.

---

## 8. Acceptance criteria

### C1 — Mechanical evidence reproduced

```
AC-C1.1  grep -n 'GEP01_PASS\|GEP01_FAIL' on
         evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/c3/gate-push-correction01.log
         and
         evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c3/llvm-gep01-test.txt
         each show GEP01_PASS=26 GEP01_FAIL=4 with the same
         4 FAIL row text.
AC-C1.2  grep -n 'readat.HC: SHAPE_DEPENDENT' in both
         log files returns one byte-identical row each.
AC-C1.3  grep -n 'could not read cap verifier output'
         in both log files returns three byte-identical
         rows each (IR_GEP, IR_LEA, IR_IADD).
```

### C2 — Production delta not re-mutated

```
AC-C2.1  git diff --stat b76f0d8..HEAD -- src/aarch64.c
         returns empty.
AC-C2.2  git diff --stat b76f0d8..HEAD -- src/x86_64.c
         returns empty.
```

### C3 — Predecessor evidence not mutated (F14)

```
AC-C3.1..C3.5  git diff --stat b76f0d8..HEAD -- against each
               predecessor evidence subdirectory and the
               HANDOFF.md returns empty.
```

### C4 — ROADMAP reconciliation

```
AC-C4.1  The ROADMAP entry for ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
         gains the v2 closure classification:
           ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
           HALT_CLASS:            GOVERNANCE
           BLOCKS_NEXT:           NO
         with a one-line note linking this correction ACT.
```

### C5 — Hygiene residue documented without scope expansion

```
AC-C5.1  c4/residue.txt names three P1 hygiene items:
           (a) `[dbg]` stale log lines in c3/jit-unit-test.txt
               that no longer correspond to source code;
           (b) seven fresh `src/aarch64.c` warnings
               (six const-discards-qualifiers, one u64/int
                sign-compare);
           (c) gep01 D1+D2 four-failure aggregate
               (re-documented under §6 above; out of scope).
AC-C5.2  c4/residue.txt explicitly states that this ACT
         does NOT take ownership of (a), (b), or (c).
```

### C6 — BOOTSTRAP01 re-authorization signal recorded

```
AC-C6.1  c4/roadmap-transition.txt records that, per v2
         doctrine (HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO),
         the predecessor ACT's gate-push failure does NOT
         constitute a mechanical blocker for
         ACT-POLYC-BOOTSTRAP01. BOOTSTRAP01 may open
         against this main (b76f0d8) under its own
         successor-need determination.
AC-C6.2  The correction does NOT itself open BOOTSTRAP01
         and does NOT push to origin/main.
```

---

## 9. Commit topology

```
C1 RED      — capture and freeze the §5 byte-identical
               pre-/post- C2 evidence for D1 and D2.
C2 IMPL     — produce this ACT's evidence packet under
               evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-
               CORRECTION01/{c1,c2,c3,c4}/.
C3 EVIDENCE — final-tree reproduction of the byte-identical
               comparison and the residual-witness list.
C4 CLOSE    — ROADMAP reconciliation + HANDOFF.
```

Do not exceed four commits in this ACT.

---

## 10. Recommended next ACT (informational, not opened here)

Per v2 doctrine + reviewer recommendation, two paths forward:

```
A.  ACT-POLYC-INTEGRATION-GEP01-GATE-RECOVERY01
    Mission:  split D1 and D2 into separate RED witnesses,
              then fix each by mechanical root-cause analysis
              (NOT by relaxing acceptance criteria).
    Required GREEN:
      make llvm-gep01-test
        GEP01_PASS=30
        GEP01_FAIL=0
        STATUS=PASS
      gate-push.sh HEAD
        VERDICT=PASS
    After CLOSE: push b76f0d8 (or its successor) to
                 origin/main and open ACT-POLYC-BOOTSTRAP01.

B.  ACT-POLYC-BOOTSTRAP01
    Mission:  integrate the BOOTSTRAP substrate using this
              main (b76f0d8). BOOTSTRAP01's opening ACT
              decides mechanically whether BOOTSTRAP01's
              mission requires gep01; if yes, GEP01-GATE-
              RECOVERY01 is a binding predecessor and must
              close first.
```

The predecessor ACT's own `c4/roadmap-transition.txt`
recommended (a). This ACT does not weaken that recommendation.
It simply records that v2 doctrine removes the prose-only
blocker on path (B) in case the human reviewer prefers
B-with-binding-predecessor.

---

## 11. HALT taxonomy (this ACT)

```
HALT_GATE_PUSH_FAILED     (does not apply here — predicate not
                           demonstrated; see §7)
HALT_RED_NOT_REPRODUCED   (does not apply — REDs are
                           mechanically captured; see C1 ACs)
HALT_SCOPE_EXPANSION_REQUIRED (does not apply — this ACT is
                           explicitly bounded to docs-only;
                           production re-mutation is forbidden)
```

The default v2 classification for this ACT itself (if any
halt occurred) is `HALT_CLASS = GOVERNANCE / BLOCKS_NEXT = NO`.
This ACT does not anticipate halts because its ACs are
mechanical and the pre-/post- C2 evidence is already on disk.

---

## 12. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md` Factory v2 form
(`HANDOFF.md` is descriptive only; verdict authority is the
`ACT-Corrected-Verdict` trailer on the C4 CLOSE commit).

The CLOSE trailer on this ACT's C4 commit MUST carry:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

Per v2 doctrine §25 HALT CLASSIFICATION, the HALT_CLASS /
BLOCKS_NEXT pair is REQUIRED on a CORRECTION close that
emits an `ACT-Corrected-Verdict`. (Historical v1 CLOSE
commits are grandfathered.)

