# ACT-POLYC-LLVM-CORE01

**Title:** Canonise the First Intentionally-Supported LLVM Backend Contract

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02`
(PASS at `38c4fdd`, reviewer verdict PASS_WITH_P1, CORE01 authorised 2026-09-08)

**Class:** IMPLEMENTATION / CONTRACT-CANONISATION / DIAGNOSTIC-HARDENING

**Production semantic changes:** **FORBIDDEN** (this ACT does not add
new lowering; it canonises what already lowers)

**IR / ABI / neutral-IR boundary changes:** **FORBIDDEN** (the
neutral IR contract is unchanged; the IR_BR i64-condition shape is
preserved)

**LLVM IR lowering additions:** **FORBIDDEN** (no new opcodes or
types; this ACT does not enable floats, division, shifts, memory,
pointers, or aggregates)

**Target machine / execution / ORC:** **FORBIDDEN** (still emit
textual LLVM IR only; verifier-clean; no lli, no clang, no JIT)

**Language change authorization:** **NONE**

---

## 0. Mission

Turn the LLVM spike into a small backend whose supported subset has
**explicit semantic fences**. The reviewer captured the transition:

    SPIKE: "Can this work?"
        ↓
    CORE:  "Exactly what do we promise works, and exactly how do
            we refuse everything else?"

The CORE backend MUST:

1. Declare, in source, the full capability matrix
   (SUPPORTED / REJECTED / NOT_YET_CLASSIFIED) for every IR opcode
   and every IR value-kind the backend can encounter.
2. Reject every REJECTED opcode with a **named** diagnostic
   (`LLVM_BACKEND_UNSUPPORTED_<THING>`), not a generic message, and
   exit nonzero. No silent acceptance.
3. Resolve the documented `LLVMBuildTrunc(i1 → i1)` residue by
   recording that the truncation is a deliberate boundary crossing
   (neutral IR BR cond is i64; LLVM condbr wants i1), not a bug.
4. Be verifiable by a test that exercises the REJECTED fence as
   seriously as a SUPPORTED path.

## 1. Why

The spike established the technical fact (the neutral IR CAN lower
to verifier-clean textual LLVM IR). It did not establish a contract.
Three reviewer observations:

* "You have not built 'LLVM support' in the broad sense yet. You now
  have something more useful: a **small backend whose supported
  subset has explicit semantic fences**."
* The current code rejects unsupported ops via
  `llErrUnsupportedOp` / `llErrUnsupportedType`, but the matrix is
  implicit in the dispatch; an opcode that is *not* handled in the
  dispatch falls through to the generic catch-all (line 922 in
  `src/llvm-backend.c`). A reviewer cannot tell at a glance which
  opcodes are SUPPORTED vs deliberately REJECTED vs simply not yet
  classified.
* The `LLVMBuildTrunc(i64 → i1)` on line 607 looks like a bug; it
  isn't, but the code does not say so. A future contributor might
  "fix" it by changing the IR_BR dst type to i1 — which would
  change the neutral IR contract and cross the boundary this ACT
  forbids.

The CORE contract fixes these by making the implicit explicit.

## 2. Scope

### allowed

- `src/llvm-backend.c` — add a static capability matrix table at the
  top, make the dispatch mark each arm with its classification,
  ensure every non-classified opcode hits a named diagnostic, and
  document the `LLVMBuildTrunc(i64 → i1)` boundary crossing.
- `src/llvm-backend.h` — add a public macro or constant for each
  `LLVM_BACKEND_UNSUPPORTED_*` token used by tests/diagnostics.
- `src/tests/llvm_*.HC` (NEW) — test fixtures that exercise the
  REJECTED fence. Minimum one fixture per REJECTED opcode class
  (memory, float, division, shift, bitwise, conversion, switch,
  select, va_*, asm, phi, cmp_br, load_deref, store_deref, etc.).
- `docs/acts/ACT-POLYC-LLVM-CORE01.md` — this contract.
- `evidence/llvmspike01-core01/` (NEW) — oracle runs, RED evidence,
  capability matrix snapshot.

### forbidden

- adding any new SUPPORTED opcode or type (no F32, F64, division,
  shifts, bitwise, pointer, struct, aggregate, sign-extension,
  zero-extension, truncation, fp casts, ptrtoint, inttoptr, bitcast,
  switch, select, va_*, asm, phi, memory ops beyond the current
  PARAM_COPY/return-slot pattern, globals, external function
  declarations);
- changing the neutral IR contract (IR_BR condition stays i64;
  IR_VAL_LOCAL stays single-definition; the IR_CMP_BR boundary
  diagnostic stays in place);
- adding target machine, object emission, ORC, JIT, ExecutionEngine,
  PassBuilder, opt-level, lli, clang, or any execution path;
- enabling U8/U16/U32/U64 signedness mixing (still i64 only);
- removing or weakening the LLVM_BACKEND_UNSUPPORTED_* diagnostics;
- dependency additions (still only LLVM 22 C-API headers used).

## 3. Entry gate

```text
git branch --show-current   # main
git status --short          # clean (modulo uncommitted evidence/)
git rev-parse HEAD          # recorded as entry identity
```

Required state:

- on main;
- worktree clean (or only uncommitted evidence/ snapshots);
- entry HEAD recorded;
- the previous ACT's identity oracle
  (`evidence/.../identity.sh`) still exits 0 at HEAD;
- `make clean && make` succeeds;
- `make unit-test` shows the inherited baseline
  (AOT 90/90, JIT 90/90, LSP 43/43, CORPUS 16/16);
- LLVM 22 development tooling still available
  (`llvm-config --version` ≥ 22).

## 4. Principal RED

This ACT has TWO REDs. Both must exist before any production change.

### RED-1: Rejection-boundary fixture for an unclassified opcode

Pick an opcode that is currently NOT in the dispatch at all
(e.g. `IR_FADD` if it isn't there, or `IR_AND`). Build a minimal
`.HC` source that lowers to that opcode, run it through the LLVM
backend, and observe that it currently EITHER:

  (a) falls through to the generic catch-all on line 922
      (with message "opcode %s is not supported"), or
  (b) silently succeeds in an unintended way (worse).

Either outcome proves that the current dispatch is not contractually
explicit. The fix is to add the opcode to the capability matrix
explicitly as REJECTED and route it to a named
`LLVM_BACKEND_UNSUPPORTED_<CLASS>` diagnostic (not the generic
catch-all).

Concretely, RED-1 demonstrates: at the entry commit, the
diagnostic emitted for `IR_FADD` does NOT contain the token
`LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH`. After the production fix,
it MUST.

### RED-2: `LLVMBuildTrunc(i64 → i1)` residue is undocumented

The current `IR_BR` arm (lines 596–613) emits `LLVMBuildTrunc` on
the condition value. There is no comment explaining WHY this is
correct (neutral IR BR cond is i64; LLVM condbr wants i1). A
reviewer reading the code would flag it as a bug.

RED-2 demonstrates: at the entry commit, the comment immediately
above the `LLVMBuildTrunc` call does NOT state that the truncation
is a deliberate neutral→LLVM boundary crossing. After the fix, the
comment MUST make that boundary crossing explicit and reference
the IR contract (`src/ir-types.h` / `ir-eval.c`).

RED-2 is satisfied by a documentation change in the same arm; it
requires no IR or ABI change.

## 5. Implementation boundary

### minimum production change

Three things, each independently small:

  1. Add a `static const char *const LL_CAPABILITY_MATRIX`
     table at the top of `src/llvm-backend.c` (after the existing
     scope comment), with one row per IR opcode reachable by the
     dispatch. Format:

     ```c
     /* IR opcode                 classification   diagnostic
      * IR_IADD                   SUPPORTED        -
      * IR_FADD                   REJECTED         LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH
      * IR_IDIV                   NOT_YET_CLASSIFIED (TBD, deferred to CORE02)
      * ...
      */
     ```

  2. Wrap the existing dispatch in a per-arm classification
     comment (`/* CLASSIFICATION: SUPPORTED */`,
     `/* CLASSIFICATION: REJECTED — <diagnostic> */`).
     No behaviour change.

  3. Add a one-paragraph comment above the
     `LLVMBuildTrunc(i64 → i1)` call in the `IR_BR` arm
     documenting it as a deliberate boundary crossing (RED-2 fix).

  4. Add `LLVM_BACKEND_UNSUPPORTED_*` macros to
     `src/llvm-backend.h` for every diagnostic token currently
     used in `src/llvm-backend.c` AND every token that will be
     used after RED-1. The header becomes the contract surface.

### what is deliberately NOT in this ACT

* no new SUPPORTED opcode (F15 / forbidden list above);
* no neutral-IR contract change (F7);
* no diagnostic weakening (F5);
* no "support matrix as code" framework (F8 — no speculative
  abstraction; the table is plain comments, not data-driven
  dispatch);
* no removal of the catch-all; the catch-all remains as a safety
  net for truly unclassified opcodes (it just becomes the
  diagnostic of last resort, not the primary path).

## 6. Acceptance criteria

AC01: the capability matrix table exists at the top of
      `src/llvm-backend.c` and lists at least 30 IR opcodes
      (the full neutral IR vocabulary, modulo the IMPURE-ONLY
      fusions).

AC02: every dispatch arm in `src/llvm-backend.c` is annotated
      with its classification (SUPPORTED / REJECTED /
      NOT_YET_CLASSIFIED).

AC03: `LLVM_BACKEND_UNSUPPORTED_*` macros are defined in
      `src/llvm-backend.h` for every diagnostic token used in
      `src/llvm-backend.c` (command:
      `grep -oE 'LLVM_BACKEND_UNSUPPORTED_[A-Z_]+' src/llvm-backend.c | sort -u | wc -l`
      must equal
      `grep -cE 'define LLVM_BACKEND_UNSUPPORTED_' src/llvm-backend.h`).

AC04: RED-1 regression test passes:
      `src/tests/llvm_reject_float_arith.HC` (or equivalent) is
      compiled via the LLVM backend, fails with a non-zero exit,
      and the diagnostic contains
      `LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH` (or the corresponding
      class for whichever unclassified opcode was chosen).

AC05: RED-2 is satisfied: the comment above the `LLVMBuildTrunc`
      in the `IR_BR` arm explicitly states the truncation is a
      neutral→LLVM boundary crossing. `grep -n 'boundary' src/llvm-backend.c`
      finds the comment.

AC06: at HEAD, `make clean && make` succeeds.

AC07: at HEAD, the inherited baseline is preserved:
      AOT 90/90, JIT 90/90, LSP 43/43, CORPUS 16/16.

AC08: at HEAD, `src/tests/llvm_reject_*.HC` test fixtures
      (one per REJECTED class, minimum 6) all FAIL on the LLVM
      backend with a named diagnostic, FAIL on the native backend
      only if the native backend also rejects (otherwise the
      fixture is LLVM-only — recorded as such).

AC09: at HEAD, `git diff --check` returns rc=0.

AC10: at HEAD, the closure identity oracle
      (`evidence/.../identity.sh`) still exits 0 (snapshot.txt
      and identity.txt are explicitly NOT authoritative).

AC11: this ACT adds at most one production commit (the matrix +
      dispatch annotations + boundary-crossing comment + macros
      + RED-1 regression test) and one docs/evidence commit
      (this ACT + snapshots + topology).

## 7. Conservation gates

| Gate                              | expected                                       |
|-----------------------------------|------------------------------------------------|
| `make clean && make`              | succeeds                                       |
| `make unit-test`                  | AOT 90/90, JIT 90/90, LSP 43/43, CORPUS 16/16 |
| `make jit-unit-test`              | 90/90                                          |
| `make lsp-test`                   | 43/43                                          |
| `make corpus-test`                | 16/16 byte-identical AOT=JIT                   |
| `LLVM matrix` (committed)         | PASS=13 FAIL=0 (re-run at HEAD)                |
| `identity.sh` oracle (entry ACT)  | exit 0                                         |
| `git diff --check HEAD`           | rc=0                                           |

The LLVM matrix will be re-recorded against the entry HEAD; the
existing 13 PASS / 0 FAIL is the minimum acceptance bar.

## 8. Halt taxonomy

This ACT may HALT on:

* `HALT_PREDECESSOR_BASELINE_RED` — inherited baseline broken
  on a fresh tree;
* `HALT_LLVM_TOOLCHAIN_UNAVAILABLE` — LLVM 22 dev headers not
  present;
* `HALT_RED_NOT_REPRODUCED` — RED-1 or RED-2 cannot be reproduced
  as stated;
* `HALT_SCOPE_EXPANSION_REQUIRED` — the contract cannot be
  canonised without changing the neutral IR contract;
* `HALT_TOO_MANY_PRODUCTION_COMMITS` — AC11 violated;
* `HALT_LEDGER_DRIFT` — disallowed production change sneaks in
  (e.g. a SUPPORTED opcode gets accidentally added).

The previous ACTs' halt tokens remain active but inapplicable here
(closure is PASS).

## 9. Residue (pre-declared)

P2: the IR_BR i64→i1 truncation remains a deliberate boundary
    crossing. If a future ACT wants to make IR_BR's condition i1
    natively, that is a neutral-IR contract change and belongs in
    a separate boundary ACT.

P2: the catch-all "opcode %s is not supported" diagnostic remains
    as a safety net. CORE01 does not delete it.

P2: the capability matrix is in code as comments. A future ACT
    may data-drive the dispatch; CORE01 does NOT (F8).

P2: NOT_YET_CLASSIFIED opcodes (the IR vocabulary minus the
    SUPPORTED and REJECTED sets) are left for a future
    CORE02-classification ACT.

P1 (non-blocking, carried over from previous ACT): the closure
    oracle (`identity.sh`) lives inside its own allowed mutation
    set. Tracked for `ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01`.

## 10. Commit topology

```text
1. RED-1: src/tests/llvm_reject_float_arith.HC + tiny harness
          that runs the LLVM backend on it and asserts the
          diagnostic lacks the named token. Commit fails.
2. Implementation: capability matrix, dispatch annotations,
   boundary-crossing comment, header macros. RED-1 now passes.
3. Docs + evidence: this ACT, snapshots, topology.
   Existing identity.sh continues to gate (now on a larger
   allowed set since this ACT may edit src/llvm-backend.c).
```

Three commits maximum. The RED-1 commit MUST exist before the
implementation commit. Per F3 the principal RED precedes the
principal production fix.

## 11. Closure handoff

A HANDOFF.md in `evidence/llvmspike01-core01/` records:

- ENTRY_HEAD, IMPLEMENTATION_HEAD, CLOSURE_HEAD;
- capability matrix (snapshot, NOT authoritative — same
  authority distinction as the previous ACT);
- full RED-1 and RED-2 reproductions with command output;
- commit topology that actually shipped;
- conservation gate results (table);
- residue (P0/P1/P2) with priority tags;
- next ACT recommendation.

The HANDOFF.md is a SNAPSHOT. The authoritative oracle for this
ACT's closure is the script exit status (inherited from the
previous ACT's `identity.sh`, or a CORE01-specific equivalent if
the reviewer P1 is addressed first).

