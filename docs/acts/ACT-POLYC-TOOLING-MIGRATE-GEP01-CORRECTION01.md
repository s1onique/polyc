# ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
ACT-Phase: RED
ACT-Phase-Notes: C1 RED committed (see §8). A C1.1
  RED-AMEND follow-up commit (still within the RED
  phase; trailer `ACT-Phase: RED`) tightens §3.5 (P1)
  to option B, adds §3.1 pure-local predicate helper
  contract + §3.2 `--predicate-selftest` mode + §3.3
  purity guardrails, and rewrites AC02–AC05 / AC06 to
  reference the selftest. A C1.2 RED-AMEND follow-up
  commit (still within the RED phase; trailer
  `ACT-Phase: RED`) tightens §3.1 by replacing
  `GeShPrefixNumberedI64` with `GepDynamicI8Shape`
  (which checks BOTH numbered SSA operands), adds two
  new committed fixtures (constant-index, symbolic-base,
  plus genuine positive control), adds §3.5 child-path
  containment check, and adds
  `HALT_P1_CONTAINMENT_UNVERIFIED` and
  `HALT_GEP_HELPER_WEAKER_THAN_LEGACY`. ACT remains in
  RED; C2 IMPL has NOT opened. See §8 for the commit
  topology.

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
| 04  | readat_dynamic_gep_and_load_i8 | dynamic-index GEP shape `%[0-9]+, i64 %[0-9]+` collapsed to whole-file `Contains("getelementptr i8, ptr %")`; C1.2 restores via `GepDynamicI8Shape` (both operands numbered on the same line) |
| 07  | readat_gep_shape          | same as row 04; C1.2 restores via `GepDynamicI8Shape` |
| 08  | gep_used_as_load_address  | `%gep_i8` SSA-value binding collapsed to whole-file `Contains("load i8, ptr %")` |
| 26  | ir_gep_rejected           | opcode-line binding `IR_GEP.*\(REJECTED\)` split into two independent whole-file `StrStr` calls |
| 27  | ir_lea_rejected           | same as row 26 for IR_LEA |
| 28  | ir_iadd_supported         | same as row 26 for IR_IADD / `(SUPPORTED)` |

And one architectural regression (P1):

| P1  | scratch lifecycle         | caller must pre-create `--scratch` root; legacy Bash harness owned its own child via `mkdir -p` + `trap rm -rf`. Bound by option B in §3 item 5: caller owns root, harness owns unique run child, never recursive-delete caller root. |

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

5. **P1 (scratch lifecycle) — option B (binding):**
   The harness MUST treat scratch ownership as follows:

   - The caller supplies the scratch ROOT (e.g.
     `--scratch=/tmp/correction01-ac06-scratch`). The
     caller retains ownership of that root. The harness
     MUST NOT recursively delete that root on exit.
   - The harness MUST create the root via a local
     `mkdir -p`-equivalent helper if it does not exist
     (so the legacy "no pre-mkdir required" property is
     preserved).
   - The harness MUST own a unique per-run CHILD directory
     beneath the caller-supplied root (e.g.
     `<root>/run-<pid>-<monotonic>`). The harness creates
     the child at startup and removes ONLY that child
     (single-level, non-recursive) on exit / in a finally
     equivalent. The child is the only thing the harness
     owns the lifetime of.
   - The legacy Bash used `mkdir -p` + `trap 'rm -rf
     "$EVID/c3/_tmp"' EXIT`. Option B is the bounded
     PolyC-native equivalent: caller root survives, the
     unique run child is the harness's responsibility.
   - The PolyC restoration may implement the
     `mkdir -p`-equivalent and the child-creation /
     child-cleanup using the local line-oriented helpers
     below plus PolyC's existing `SpawnAndCapture` of
     `mkdir` / `rm -rf <child>` (no `MkDir` / `FileMkDir`
     runtime primitive is introduced; tooling.HC MUST
     NOT be widened).
   - **Child-path containment check (binding):** before
     the harness issues any direct-argv `rm -rf <child>`
     for the per-run child, it MUST mechanically assert
     that the child path is strictly underneath the
     caller-supplied root and is not equal to it. The
     local containment helper MUST check all of the
     following and return TRUE only if all hold:
       1. `child` is non-NULL and non-empty;
       2. `root` is non-NULL and non-empty;
       3. `child` starts with the byte sequence
          `root` followed by `/` (i.e. the path
          separator — `StrOcc(root, '/') == -1`
          implies `child == root` and is rejected;
          a `root` that does not end with `/` is
          implicitly extended with one for the
          prefix check);
       4. `child != root` (the equality check is
          implied by (3) but is stated explicitly so
          the HALT reason is unambiguous);
       5. the suffix after the `<root>/` prefix is
          non-empty (no trailing-slash-as-child
          accepted).
     If ANY check fails, the harness MUST HALT with
     `HALT_P1_CONTAINMENT_UNVERIFIED` (see §7) and
     MUST NOT invoke `rm -rf`. This makes
     `HALT_P1_RECURSIVE_DELETE_CALLER_ROOT` executable
     rather than merely doctrinal: a containment
     failure is a hard precondition, not a
     post-mortem.

   `HALT_P1_RECURSIVE_DELETE_CALLER_ROOT` — if any
   implementation recursive-deletes the caller-supplied
   scratch root, halt immediately and re-classify the
   scratch helper.

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

### 3.1 Predicate helper contract (pure local helpers)

The C2 IMPL of this ACT MUST introduce the following PURE
LOCAL predicate helpers inside
`tools/quality/llvm-gep01-test.HC`. They are local to the
harness source file; they MUST NOT be exported to
`tooling.HC`, `strings.HC`, or any other shared library;
they MUST NOT require new runtime primitives.

| Helper                                       | Legacy semantics it MUST emulate |
|----------------------------------------------|----------------------------------|
| `Bool GepDynamicI8Shape(U8 *text)`           | returns TRUE iff some line of `text` contains, in order and on the SAME line: the literal `"getelementptr i8, ptr %"`, followed immediately by a non-empty decimal digit run, followed by the literal `", i64 %"`, followed immediately by a non-empty decimal digit run. This emulates the legacy Bash regex `getelementptr i8, ptr %[0-9]+, i64 %[0-9]+`. |
| `Bool LineContainsOpcodeMarker(text, opcode, marker)` | returns TRUE iff some line of `text` contains both the literal opcode token and the literal marker token (`(REJECTED)` or `(SUPPORTED)`) on the SAME line, in the order opcode-then-marker (legacy `IR_<X>.*\(MARKER\)` semantics). |

#### Why `GepDynamicI8Shape` and not `GeShPrefixNumberedI64`

The C1.1 RED-AMEND frozen `GeShPrefixNumberedI64` helper
only checked ONE half of the legacy regex (`prefix +
digits`); it proved `getelementptr i8, ptr %123` but said
nothing about the second operand being `i64 %<digits>`.
This was a direct false-green path: the principal
malformed fixture

```text
getelementptr i8, ptr %0, i64 2
```

(constant index, numbered base) would have been falsely
accepted. C1.2 RED-AMEND tightens the contract to
`GepDynamicI8Shape`, which requires BOTH operands
numbered on the same line. This is the smallest helper
that preserves the full legacy regex semantics.

`HALT_GEP_HELPER_WEAKER_THAN_LEGACY` — if the C2 IMPL
introduces any helper whose acceptance set is a strict
superset of the legacy regex's acceptance set (i.e. the
helper accepts some text the legacy regex would reject),
halt and re-classify.

#### Helper purity contract (binding)

Both helpers MUST be implemented using only the existing
HolyC primitives already imported by the harness
(`StrStr`, `StrLen`, `StrOcc`, manual byte iteration, and
the same `FileRead` wrapper the harness already uses).
No regex engine, no PCRE, no system(3), no shell. The
helpers MUST be PURE: they take `(text, ...)` and return
`Bool`; they MUST NOT perform I/O, allocation visible
to the caller (a small internal scratch buffer for line
iteration is acceptable), or process forking.

The C2 IMPL MUST replace every weakened predicate
identified in §0 / §5 with a call to one of these helpers
(or a small composition of them) such that the predicate
is at least as strong as the legacy Bash regex contract.
Specifically:

- Rows 04 and 07 MUST require
  `GepDynamicI8Shape(emitted)`. The legacy contract
  enforces both `%[0-9]+` operands on the same line; the
  restored predicate MUST enforce the same constraint.
  No weakening (e.g. by collapsing to a single operand
  or to whole-file `Contains`) is permitted.
- Row 08 MUST require
  `Contains(emitted, "load i8, ptr %gep_i8")` (the
  `%gep_i8` SSA-value binding is mandatory; this is
  literal-substring semantics, not a regex, but it is
  the line-restricted substring the legacy contract
  enforces by `grep -E`).
- Rows 26 / 27 / 28 MUST require
  `LineContainsOpcodeMarker(cap_text, "IR_GEP", "(REJECTED)")`,
  `LineContainsOpcodeMarker(cap_text, "IR_LEA", "(REJECTED)")`,
  and
  `LineContainsOpcodeMarker(cap_text, "IR_IADD", "(SUPPORTED)")`
  respectively (opcode names per the frozen c1 oracle).
  The opcode and marker MUST be on the SAME line; the
  helper's whole-file-stride scan MUST reject the
  malformed fixtures in `correction01/red/`.

---

### 3.2 `--predicate-selftest` mode

The C2 IMPL MUST add a `--predicate-selftest` mode to
`tools/quality/llvm-gep01-test.HC`. In this mode the
harness:

1. Loads each committed principal-RED malformed fixture
   from
   `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/red/`
   via the same local `FileRead` wrapper the harness
   already uses. The fixtures are read-only inputs; the
   selftest MUST NOT mutate them.
2. Calls the same predicate helpers a normal 30-row run
   would call on that text (i.e. it is the SAME helper
   path the production predicate restoration will use;
   not a synthetic mock, per F3).
3. Asserts the expected verdict for each fixture:

   | Fixture                       | Helper call(s)                                          | Expected          | Role |
   |-------------------------------|---------------------------------------------------------|-------------------|------|
   | `read-at-malformed.ll`        | `GepDynamicI8Shape(t)` (rows 04 / 07)                   | FALSE (rejected)  | A — constant-index negative |
   | `read-at-symbolic-base.ll`    | `GepDynamicI8Shape(t)` (rows 04 / 07)                   | FALSE (rejected)  | B — symbolic-base negative  |
   | `read-at-genuine.ll`          | `GepDynamicI8Shape(t)` (rows 04 / 07)                   | TRUE (accepted)   | C — positive control        |
   | `read-at-malformed.ll`        | `Contains(t, "load i8, ptr %gep_i8")` (row 08)          | FALSE (rejected)  | row 08 negative             |
   | `cap-malformed.txt`           | `LineContainsOpcodeMarker(t, "IR_GEP", "(REJECTED)")` (row 26) | FALSE (rejected) | row 26 negative |
   | `cap-malformed.txt`           | `LineContainsOpcodeMarker(t, "IR_LEA", "(REJECTED)")` (row 27) | FALSE (rejected) | row 27 negative |
   | `cap-malformed.txt`           | `LineContainsOpcodeMarker(t, "IR_IADD", "(SUPPORTED)")` (row 28) | FALSE (rejected) | row 28 negative |

   Cases A and B together cover both halves of the legacy
   regex: A exercises the second operand (constant index
   vs `%[0-9]+`), B exercises the first operand (symbolic
   base vs `%[0-9]+`). A helper implementing only the
   first half (the C1.1 `GeShPrefixNumberedI64` bug)
   would pass case B and FAIL case A; a helper
   implementing only the second half would pass case A
   and FAIL case B. Both halves together force the full
   legacy semantics.

   Case C (positive control) prevents a tautological
   selftest that proves only FALSE: a regression that
   collapsed the predicate to always-FALSE would still
   pass cases A, B, and the row-08 / row-26-28 cases; the
   positive control catches that.

4. Exits 0 if and only if every assertion in the table
   matches its expected verdict; otherwise prints
   `SELFTEST_FAIL row=<n> fixture=<name> expected=<BOOL> got=<BOOL>`
   and exits non-zero.

The selftest exercises the helpers WITHOUT requiring the
live hcc / llvm-as / opt toolchain, WITHOUT requiring the
real `read-at.ll` from the harness's own scratch dir, and
WITHOUT requiring the `cap-table-verifier.py` Python run.
This closes the AC02–AC05 mechanical-execution gap noted
by the C1 reviewer: the ACs become checkable through pure
local predicate helpers against committed fixtures, not
through full toolchain substitution.

The selftest MUST be reached via a single CLI flag
(`--predicate-selftest`) and MUST exit before the normal
30-row run begins. The selftest MUST NOT alter the
verdict counters of the 30-row run when run in normal
mode.

---

### 3.3 Purity and scope guardrails

- `HALT_HELPER_NOT_PURE` — if the predicate helpers
  perform I/O, mutate shared state, fork processes, or
  call `tooling.HC` primitives that were not already
  imported by the C2 IMPL commit of MIGRATE-GEP01, halt
  and re-classify.
- `HALT_TOOLING_HC_WIDENED` — if the C2 IMPL introduces
  a new exported function in `src/holyc-lib/tooling.HC`,
  `src/holyc-lib/strings.HC`, or any other shared library
  solely to support these helpers, halt. The helpers
  belong to the harness.
- `HALT_SELFTEST_MOCK` — if the selftest path diverges
  from the predicate path the normal 30-row run uses
  (i.e. the selftest does NOT exercise the production
  helper), halt. The selftest MUST call the SAME helper.

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

AC02. Row 04 predicate rejects the C1.2 RED-AMEND
       fixtures `correction01/red/read-at-malformed.ll`
       (constant index) AND
       `correction01/red/read-at-symbolic-base.ll`
       (symbolic base), and ACCEPTS the positive control
       `correction01/red/read-at-genuine.ll`.
       Reproduction: run the harness in
       `--predicate-selftest` mode (per §3.2). The
       selftest invokes the SAME local `GepDynamicI8Shape`
       helper the normal 30-row run uses.
       ```
       ./hcc --install-dir=$(pwd)/build/test-prefix \
             -o /tmp/llvm-gep01-test \
             tools/quality/llvm-gep01-test.HC
       /tmp/llvm-gep01-test --predicate-selftest
       ```
       Expected: rc=0. Output includes
       `SELFTEST_PASS row=04 fixture=read-at-malformed.ll`
       (case A),
       `SELFTEST_PASS row=04 fixture=read-at-symbolic-base.ll`
       (case B), and
       `SELFTEST_PASS row=04 fixture=read-at-genuine.ll`
       (case C, positive control). The C1.2 helper
       `GepDynamicI8Shape` rejects both adversaries
       (constant index, symbolic base) and accepts the
       genuine dynamic shape.

AC03. Row 07 predicate exercises the same three
       fixtures and the SAME `GepDynamicI8Shape` helper
       as AC02 (rows 04 and 07 share the legacy regex).
       Reproduction: same `--predicate-selftest`
       invocation as AC02.
       Expected: rc=0,
       `SELFTEST_PASS row=07 fixture=read-at-malformed.ll`,
       `SELFTEST_PASS row=07 fixture=read-at-symbolic-base.ll`,
       `SELFTEST_PASS row=07 fixture=read-at-genuine.ll`.

AC04. Row 08 predicate rejects the same malformed
       `read-at.ll` (asserts `%gep_i8` SSA binding).
       Reproduction: same `--predicate-selftest`
       invocation as AC02; row 08 is covered via
       `Contains(t, "load i8, ptr %gep_i8")` on
       `read-at-malformed.ll`.
       Expected: rc=0,
       `SELFTEST_PASS row=08 fixture=read-at-malformed.ll`.

AC05. Rows 26 / 27 / 28 predicates reject a malformed
       cap-verifier output where opcode and marker are
       on separate lines.
       Reproduction: same `--predicate-selftest`
       invocation as AC02; rows 26 / 27 / 28 are covered
       via three `LineContainsOpcodeMarker` calls on
       `cap-malformed.txt`.
       Expected: rc=0,
       `SELFTEST_PASS row=26`,
       `SELFTEST_PASS row=27`,
       `SELFTEST_PASS row=28`.

AC06. P1 regression closed: harness succeeds when its
       `--scratch` ROOT does NOT pre-exist, and the
       harness does NOT recursively delete the
       caller-supplied root on exit (option B, §3
       item 5).
       Reproduction:
       ```
       rm -rf /tmp/correction01-ac06-scratch
       /tmp/llvm-gep01-test \
           --hcc=./hcc \
           --llvm-install-dir=$(pwd)/build/test-prefix \
           --scratch=/tmp/correction01-ac06-scratch
       test -d /tmp/correction01-ac06-scratch && \
           echo ROOT_SURVIVED
       ```
       Expected:
       - GEP01_PASS=30 (not the prior 2/12 cascade);
       - `/tmp/correction01-ac06-scratch` still exists
         after the harness exits
         (`ROOT_SURVIVED` is printed);
       - the harness's per-run unique child directory
         (e.g. `/tmp/correction01-ac06-scratch/run-<pid>-<n>`)
         was created at startup and was the only thing
         removed at exit;
       - `HALT_P1_RECURSIVE_DELETE_CALLER_ROOT` did NOT
         trigger.

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
- `HALT_HELPER_NOT_PURE` — if the predicate helpers
  defined in §3.1 perform I/O, mutate shared state,
  fork processes, or call `tooling.HC` primitives that
  were not already imported by the C2 IMPL commit of
  MIGRATE-GEP01.
- `HALT_TOOLING_HC_WIDENED` — if the C2 IMPL introduces
  a new exported function in `src/holyc-lib/tooling.HC`,
  `src/holyc-lib/strings.HC`, or any other shared
  library solely to support these helpers.
- `HALT_SELFTEST_MOCK` — if the `--predicate-selftest`
  path diverges from the predicate path the normal
  30-row run uses (the selftest MUST call the SAME
  helpers the production predicate restoration calls).
- `HALT_P1_RECURSIVE_DELETE_CALLER_ROOT` — if any
  implementation recursive-deletes the caller-supplied
  scratch root (option B, §3 item 5, forbids this).
- `HALT_P1_CONTAINMENT_UNVERIFIED` — if the harness
  reaches a `rm -rf <child>` site without the
  containment check (§3 item 5, child-path
  containment check) having returned TRUE for the
  proposed child path.
- `HALT_GEP_HELPER_WEAKER_THAN_LEGACY` — if the C2
  IMPL introduces a rows-04/07 helper whose acceptance
  set is a strict superset of the legacy Bash regex
  `getelementptr i8, ptr %[0-9]+, i64 %[0-9]+` (§3.1).
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

Per the Factory v2 grammar (`docs/factory/GIT-METADATA.md`),
`ACT-Phase` may only be one of `RED | IMPL | EVIDENCE |
CLOSE`. The C1.1 and C1.2 follow-ups are therefore still
RED-phase work; their distinction from C1 is carried by
the commit message body and by §8 / §9 of this ACT, NOT
by the `ACT-Phase` trailer.

C1 RED       (committed)   — ACT document +
                                correction01/red/ principal
                                RED witnesses.
C1.1 RED-AMEND (committed, trailer `ACT-Phase: RED`)
                              — narrow amendment per
                                reviewer's C1.1
                                recommendation. Adds:
                                §3.1 pure-local predicate
                                helper contract
                                (`GeShPrefixNumberedI64` +
                                `LineContainsOpcodeMarker`);
                                §3.2 `--predicate-selftest`
                                mode;
                                §3.3 purity / scope
                                guardrails (HALT triggers);
                                tightens §3.5 (P1) to
                                option B (caller-owned
                                root, harness-owned unique
                                run child, never
                                recursive-delete caller
                                root);
                                rewrites AC02–AC05 to
                                delegate verification to
                                `--predicate-selftest`;
                                rewrites AC06 to verify
                                option-B survival of the
                                caller root;
                                updates the §0 P1 row and
                                §7 HALT list.
                                No production source
                                change. C1 RED itself
                                remains in force (per F14
                                and the append-only
                                invariant at
                                `baf5dbd77c…`); this
                                commit is a follow-up
                                RED-phase amendment, NOT
                                a git amend.
C1.2 RED-AMEND (this commit, trailer `ACT-Phase: RED`)
                              — narrow amendment per
                                reviewer's C1.2
                                recommendation after
                                C1.1 was published. The
                                C1.1 helper
                                `GeShPrefixNumberedI64`
                                only checked the first
                                half of the legacy regex
                                (base `%[0-9]+`) and
                                would falsely accept
                                `getelementptr i8, ptr
                                %0, i64 2`. C1.2 fixes
                                the helper contract:
                                - replaces
                                  `GeShPrefixNumberedI64`
                                  with
                                  `GepDynamicI8Shape`
                                  (§3.1) which checks
                                  BOTH numbered SSA
                                  operands on the same
                                  line;
                                - adds two committed
                                  fixtures to
                                  `correction01/red/`:
                                  `read-at-symbolic-base.ll`
                                  (negative B: symbolic
                                  base) and
                                  `read-at-genuine.ll`
                                  (positive C: genuine
                                  dynamic shape);
                                - extends §3.2 selftest
                                  table with cases A
                                  (constant index),
                                  B (symbolic base), and
                                  C (genuine positive
                                  control), and explains
                                  why each is necessary
                                  (force both halves +
                                  prevent tautological
                                  always-FALSE selftest);
                                - adds §3.5 child-path
                                  containment check
                                  (binding precondition
                                  before `rm -rf <child>`)
                                  plus
                                  `HALT_P1_CONTAINMENT_UNVERIFIED`;
                                - adds
                                  `HALT_GEP_HELPER_WEAKER_THAN_LEGACY`
                                  to §7;
                                - rewrites AC02 and
                                  AC03 to reference the
                                  new helper and all
                                  three fixtures.
                                No production source
                                change. C1 and C1.1
                                remain in force per F14
                                and the append-only
                                invariant.
C2 IMPL      (deferred)     — restore rows 04/07/08 to
                                legacy regex-bound form
                                via the helpers from §3.1;
                                restore rows 26/27/28 to
                                opcode-line-bound form
                                via the helpers from §3.1;
                                restore P1 scratch
                                lifecycle to option B
                                (caller root + harness-
                                owned unique run child);
                                wire `--predicate-selftest`
                                into the CLI per §3.2.
C3 CLOSE     (deferred)     — conservation gates
                                re-verified; verdict.

Cardinality-1 CLOSE: exactly ONE commit for this ACT
may carry `ACT-Phase: CLOSE` (and `ACT-Verdict: PASS`).

---

# 9. Commit trailer contract

C1 (initial RED — preserved per append-only invariant):

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
    ACT-Phase: RED

C1.1 (RED-AMEND label, RED-phase trailer):

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
    ACT-Phase: RED

C1.2 (this commit — RED-AMEND label, RED-phase trailer):

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
