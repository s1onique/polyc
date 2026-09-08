# ACT-POLYC-LLVM-CORE04

**Title:** Reverse capability contract; per-class execution counters

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-CORE01` (REJECTED, f4ac2e7)
- `ACT-POLYC-LLVM-CORE01-CORRECTION01` (HALT_TOPOLOGY_RECORDED, b05ea7e)
- `ACT-POLYC-LLVM-CORE01-CORRECTION02` (PASS, 75983a8)
- `ACT-POLYC-LLVM-CORE02` (PASS_WITH_NONBLOCKING_RECON_RESIDUE, 8f88938)
- `ACT-POLYC-LLVM-CORE03` (PASS, recorded in ACT §8)
- `ACT-POLYC-LLVM-CORE03-CORRECTION01..05` (F14 preserved)
- `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` (PASS, 0c28b7c)
- `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01` (PASS, f955962)

**Reviewer verdict authorizing CORE04:**
> ACT-POLYC-LLVM-CORE04 unblocked.
> CORE04 should exercise Factory v2 as currently implemented.
> No Factory implementation changes inside CORE04 unless a
> CORE04 RED actually demonstrates that Factory v2 prevents
> or invalidates the compiler ACT.

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT — extension

**Production semantic changes:** **NONE**

**Production diagnostic additions:** **NONE**

**Source change scope (bounded):**
1. NEW `src/llvm-backend-cap-inv.c` (or extension to existing
   cap module) with:
   - `llValidateDispatchCoverage()` — runtime assertion that
     every `case IR_X:` arm in `src/llvm-backend.c` has a
     matching row in `kLLVMBackendCapability[]`, AND every
     non-`UNREACHABLE_ON_LLVM` row in the capability table has
     a matching dispatch arm or grouped dispatch arm.
   - per-class counters `LLCtx::n_support_dispatched`,
     `LLCtx::n_rejected_dispatched`, `LLCtx::n_defensive_trips`
     (the last one is already in CORE03; reuse).
2. `src/llvm-backend.c` dispatch site: increment the
   appropriate per-class counter on each arm match
   (`SUPPORTED` on every successful arm; `REJECTED` on every
   diagnostic-emit path).
3. `scripts/quality/llvm-spike-test.sh` harness summary:
   emit `=== capability counters ===` block with one line per
   class plus totals.

**IR / ABI / neutral-IR boundary changes:** **NONE**

**LLVM IR lowering additions:** **NONE**

**Language change authorization:** **NONE**

---

## 0. Mission

CORE03 closed with two explicit residue items (CORE03 ACT §8):

> **CORE04:**
> - assert every `case IR_X:` in the dispatch has a matching
>   `kLLVMBackendCapability[]` row (the reverse of CORE03 M1);
> - per-class execution counters (e.g. `n_rejections_per_class`)
>   emitted in the harness summary.

CORE04 closes both.

Mission is observable: after CORE04 closes, every dispatched
IR opcode is provably documented in the capability table, and
the spike harness prints per-class dispatch counts.

---

## 1. Why

CORE03 M1 asserts that every IR opcode has a capability row.
CORE03 does **not** assert the inverse: that every dispatch
arm has a capability row. A future patch could add
`case IR_NEW_OP:` and forget the table — exactly the
drift CORE03 was created to prevent. CORE04 plugs that hole.

CORE03 also lacks per-class execution visibility. Today the
harness only reports per-fixture pass/fail. Operators cannot
tell from a run whether the rejection matrix is being
exercised, whether SUPPORTED ops dominate, or whether any
DEFENSIVE_INVARIANT has fired. CORE04 adds the counters and
prints them.

---

## 2. Scope

### allowed

- `src/llvm-backend.c` — increment per-class counters on each
  arm; do not change semantics.
- `src/llvm-backend.h` — add new counter fields to `LLCtx`.
- `src/llvm-backend-cap.c` — add `llValidateDispatchCoverage()`
  and call site wiring.
- `src/llvm-backend-cap.h` — declare the new function.
- `src/main.c` — call `llValidateDispatchCoverage()` once at
  startup, alongside the existing `llValidateCapabilityContract()`.
- `scripts/quality/llvm-spike-test.sh` — emit the
  `=== capability counters ===` summary block.
- `docs/ROADMAP.md` — update CORE03/CORE04 P2 residue rows if
  and only if the new RED demonstrates they are no longer P2.

### forbidden

- Semantic change to any IR opcode lowering.
- Adding/removing SUPPORTED opcodes.
- Weakening any existing rejection diagnostic.
- Modifying any closed ACT document or HANDOFF (F14).
- Modifying the Factory v2 grammar, range-checker, or commit
  policy (F7 + reviewer discipline: Factory changes only
  inside dedicated Factory ACTs).
- Adding dependencies.
- Retroactive edits to CORE01/CORE02/CORE03 evidence.

---

## 3. Entry gate

```text
git branch --show-current  → main
git status --short         → clean
git rev-parse HEAD         → recorded before C1
```

Required state:

- on main;
- worktree clean;
- entry HEAD recorded;
- factory-v2-test PASS=35 (verified by `scripts/quality/factory-v2-test.sh`).

---

## 4. Principal RED (verified before this ACT)

**RED-M1 — dispatch has no inverse-coverage check.**

```sh
grep -nE 'inverse|dispatch_count|case_count' \
    src/llvm-backend-cap.c src/llvm-backend.c
```

returns no matches. There is no runtime check that
`{ case IR_X: }` in the dispatch corresponds to a row in
`kLLVMBackendCapability[]`.

Reproduction: add a fictitious `case IR_FAKE_OP:` to
`src/llvm-backend.c::LlFunction` without adding a capability
row. The compiler builds cleanly; `llValidateCapabilityContract()`
passes. CORE04 must catch this.

**RED-M2 — no per-class execution counters.**

```sh
grep -nE 'n_support|n_rejected|counts_per_class|rejections_per_class' \
    src/llvm-backend.c src/llvm-backend.h \
    scripts/quality/llvm-spike-test.sh
```

returns no matches. The harness summary shows only per-fixture
PASS/FAIL counts; it does not show how many SUPPORTED,
REJECTED, or DEFENSIVE_INVARIANT dispatches occurred.

Reproduction: run `scripts/quality/llvm-spike-test.sh` and
observe that no `=== capability counters ===` block is
emitted.

---

## 5. Implementation boundary

Minimum production change:

1. **Counter fields** in `LLCtx` (`src/llvm-backend.h`):
   - `unsigned long n_support_dispatched;`
   - `unsigned long n_rejected_dispatched;`
   - `unsigned long n_defensive_trips;` (already present from CORE03; reuse)
2. **Counter increments** in `src/llvm-backend.c::LlFunction`:
   - On entry to every `case IR_X:` arm classified SUPPORTED,
     `lc->n_support_dispatched++`.
   - On every REJECTED diagnostic emit, `lc->n_rejected_dispatched++`.
   - (defensive_trips already incremented at IR_BR/i64.)
3. **Inverse validation** in `src/llvm-backend-cap.c`:
   - `llValidateDispatchCoverage()` walks the dispatch (a
     hardcoded list of `{IrOp, has_explicit_arm}` pairs in
     `src/llvm-backend-cap.c` — data, not parsed at compile
     time of the validator itself).
   - Asserts: every row in `kLLVMBackendCapability[]` whose
     class is `LLVMBC_SUPPORTED` or `LLVMBC_REJECTED` has a
     matching entry in the dispatch list.
   - Asserts: every dispatch list entry has a matching
     capability row.
   - On assertion failure, emit a clear diagnostic to stderr
     and exit non-zero.
4. **Startup wiring** in `src/main.c`: call
   `llValidateDispatchCoverage()` immediately after
   `llValidateCapabilityContract()`.
5. **Harness summary** in `scripts/quality/llvm-spike-test.sh`:
   - Parse the per-class totals from the compiler's stderr
     (or expose them via a new `--emit-cap-counts` flag, TBD
     in IMPL phase).
   - Emit `=== capability counters ===` block listing:
     ```
     SUPPORTED          : <N>
     REJECTED           : <N>
     DEFENSIVE_INVARIANT: <N>
     UNREACHABLE_ON_LLVM : <N>
     ```

Explicitly **not** included:

- Per-fixture counter deltas (P2 residue if requested).
- Per-class histogram of which specific opcodes dispatched.
- Any change to the matrix / dispatch table content.
- Anything that depends on parsing the dispatch at runtime
  (the dispatch list is hand-maintained data, same as
  `kLLVMBackendCapability`).



---

## 6. Acceptance criteria

| ID    | Command / observation                                                                              | Expected                                  |
|-------|----------------------------------------------------------------------------------------------------|-------------------------------------------|
| AC01  | `git diff --check HEAD`                                                                            | rc=0                                       |
| AC02  | `make clean && make`                                                                               | succeeds                                   |
| AC03  | `scripts/quality/llvm-spike-test.sh` (full run)                                                    | PASS=18 FAIL=0                             |
| AC04  | harness summary contains `=== capability counters ===` block                                       | printed, non-empty                         |
| AC05  | harness summary counters: `SUPPORTED + REJECTED + DEFENSIVE_INVARIANT > 0` for the 18-fixture set  | true                                       |
| AC06  | `scripts/quality/factory-v2-test.sh`                                                               | PASS=35 FAIL=0                             |
| AC07  | `scripts/quality/gate-fast.sh`                                                                     | PASS                                       |
| AC08  | `factory-closure-status` (legacy v1)                                                               | PASS (no regression)                       |
| AC09  | fictitious `case IR_FAKE_OP:` without a capability row causes `llValidateDispatchCoverage()` to fail | exit non-zero, stderr names IR_FAKE_OP    |
| AC10  | removing a capability row without removing the dispatch arm causes `llValidateDispatchCoverage()` to fail | exit non-zero, stderr names the missing row |

AC09 and AC10 are exercised by ad-hoc rows committed inside
`scripts/quality/llvm-spike-test.sh`; they are not part of
the 18-fixture pass count but must be present in the
harness summary as `inverse=ok`.

---

## 7. Conservation gates

- `make unit-test` — expected PASS count unchanged from CORE03 close.
- `make jit-unit-test` — expected PASS count unchanged.
- `llvm-spike-test` — PASS=18 (CORE03 baseline preserved).
- `factory-v2-test` — PASS=35 (Factory unchanged).
- `gate-fast` — PASS.
- `git diff --check HEAD` — rc=0.

---

## 8. Halt taxonomy

- `HALT_RED_NOT_REPRODUCED` — applies to RED-M1 / RED-M2.
- `HALT_COUNTER_REGRESSION` — a per-class counter decreases
  across the 18-fixture run (would indicate non-monotonic
  accumulation; not expected).
- `HALT_DISPATCH_COVERAGE_REGRESSION` — the inverse check
  fails on the existing dispatch (would mean CORE03 left a
  drift; CORE04 must halt, not paper over).
- `HALT_SCOPE_EXPANSION_REQUIRED` — if closing this ACT
  requires touching Factory v2 or any closed ACT.

---

## 9. Residue (pre-declared)

- P2 — per-fixture counter deltas (not in this ACT).
- P2 — per-opcode histogram (not in this ACT).
- P2 — dispatch list being hand-maintained data (acceptable;
  could become auto-derived from a clang AST dump later if
  drift recurs).
- P2 — FT1 closure-oracle trust relocation (Factory backlog;
  non-blocking).
- P2 — FT2 descendant-scan simplification (Factory backlog;
  non-blocking).
- P2 — FT3 trailer-key casing enforcement (Factory backlog;
  non-blocking).


---

## 10. Commit topology (suggested; not capped)

```text
C1 (RED)
    ACT: ACT-POLYC-LLVM-CORE04
    ACT-Phase: RED

    Add scripts/quality/llvm-spike-test.sh assertions
    AC09 and AC10 (inverse-coverage checks) PLUS harness
    summary line that prints "inverse=missing" when the
    compiled dispatch lacks a matching capability row.
    Also add the `=== capability counters ===` parser that
    prints "counters=missing" when the compiler does not
    emit them.

    Verify: spike-test now reports
      inverse=missing
      counters=missing
    PASS=18 FAIL=2 (two new harness rows report FAIL).

C2 (IMPL)
    ACT: ACT-POLYC-LLVM-CORE04
    ACT-Phase: IMPL

    Add counter fields + increments + llValidateDispatchCoverage
    + startup wiring + compiler-side counter emission.

    Verify: spike-test reports
      inverse=ok
      counters=N (non-zero)
    PASS=18 FAIL=0 (and the two harness rows now PASS).

C3 (EVIDENCE)
    ACT: ACT-POLYC-LLVM-CORE04
    ACT-Phase: EVIDENCE

    Update scripts/quality/llvm-spike-test.sh with concrete
    counter baselines captured from this run; add to ROADMAP
    the CORE04 closure note under P2 residue section.
    No production code change.

C4 (CLOSE)
    ACT: ACT-POLYC-LLVM-CORE04
    ACT-Phase: CLOSE
    ACT-Verdict: PASS

    Final gate run; submit_and_exit with closure handoff.
```

The 4-commit structure is the *minimum* for proof; an
extra commit is allowed (e.g. to add a counter-emission
helper) but not a numeric cap.

---

## 11. Closure handoff

Hand off via:

- `scripts/quality/factory-v2-range-check.sh ACT-POLYC-LLVM-CORE04 HEAD`
- a short HANDOFF doc under `evidence/llvm-core04/` describing
  what was added, where, with verbatim gate output.

The ACT document is **not** modified at closure.

---

## 12. Execution metadata

Execution identity is stored in Git commit trailers:

```
ACT: ACT-POLYC-LLVM-CORE04
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
ACT-Verdict: <token>      (CLOSE only)
```

The original authorization artifact remains historically
stable; there is no OPEN -> PASS / HALT mutation. The ACT
document is NOT modified at closure. Closure happens via
the CLOSE commit's `ACT-Verdict` trailer.

---

## 13. Reviewer discipline rule (per pre-ACT review)

> No Factory implementation changes inside CORE04 unless a
> CORE04 RED actually demonstrates that Factory v2 prevents
> or invalidates the compiler ACT.

If a Factory-related RED emerges during C1/C2, CORE04 will
HALT with `HALT_FACTORY_V2_INVALIDATES_CORE04` and a separate
Factory ACT will be opened; CORE04 will not silently absorb
Factory refactoring.
