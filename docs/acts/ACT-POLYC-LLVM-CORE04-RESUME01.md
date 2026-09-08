# ACT-POLYC-LLVM-CORE04-RESUME01

**Title:** Unify dispatch discovery scope; per-class execution counters

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-CORE01` (REJECTED, f4ac2e7)
- `ACT-POLYC-LLVM-CORE01-CORRECTION01` (HALT_TOPOLOGY_RECORDED, b05ea7e)
- `ACT-POLYC-LLVM-CORE01-CORRECTION02` (PASS, 75983a8)
- `ACT-POLYC-LLVM-CORE02` (PASS_WITH_NONBLOCKING_RECON_RESIDUE, 8f88938)
- `ACT-POLYC-LLVM-CORE03` (PASS)
- `ACT-POLYC-LLVM-CORE03-CORRECTION01` (PASS — introduced
  `llvm-cap-table-verifier.py` with I2 reverse check)
- `ACT-POLYC-LLVM-CORE03-CORRECTION02` (PASS — added arm-local
  body extractor)
- `ACT-POLYC-LLVM-CORE03-CORRECTION03` (PASS — row-content fixes
  for IR_ALLOCA / IR_CMP_BR; residue: discovery-scope mismatch)
- `ACT-POLYC-LLVM-CORE04` (HALT_RED_NOT_REPRODUCED, 4be5df3)
- `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` (PASS, 0c28b7c)
- `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01` (PASS, f955962)

**Reviewer verdict authorizing RESUME01:**
> ACT-POLYC-LLVM-CORE04 HALT accepted. M1 reformulated to
> the discovery-scope-mismatch seam. M2 preserved unchanged.
> Continue under Factory v2 with one small HALT commit and
> a fresh bounded continuation. No Factory implementation
> changes inside RESUME01 unless a RESUME01 RED demonstrates
> that Factory v2 prevents or invalidates the compiler ACT.

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT — scoped refinement

**Production semantic changes:** **NONE**

**Production diagnostic additions:** **NONE**

**Source change scope (bounded):**
1. `scripts/quality/llvm-cap-table-verifier.py` — unify
   `get_dispatch_arms()` discovery with arm-local body
   extraction around **one scoped dispatch model** (the
   union of `llLowerInstr()` and any explicit switch
   helpers used by `LlFunction()`). The single source of
   truth must be one parser pass producing one set of
   `{op, location, body}` tuples; both forward (I1) and
   reverse (I2) checks consume that set.
2. `src/llvm-backend.c` / `src/llvm-backend.h` — add
   per-class counters to `LLCtx` (`n_support_dispatched`,
   `n_rejected_dispatched`, `n_defensive_trips` — last
   already from CORE03). Increment at the existing
   dispatch arm matches and rejection diagnostic emit
   sites. Do not change semantics.
3. `scripts/quality/llvm-spike-test.sh` — emit
   `=== capability counters ===` block in the harness
   summary with one line per class plus totals.

**LLVM IR lowering additions:** **NONE**

**Language change authorization:** **NONE**

---

## 0. Mission

CORE04 halted with two corrected missions:

```text
M1  Unify get_dispatch_arms() discovery with arm-local
    body extraction into one scoped dispatch model in
    scripts/quality/llvm-cap-table-verifier.py.

M2  Per-class execution counters emitted in the harness
    summary.
```

The verifier is the canonical seam for the
inverse-coverage story. RESUME01 does **not** add a new
hard-coded runtime C list in `src/llvm-backend-cap.c`.

Mission is observable: after RESUME01 closes, the
verifier's dispatch set is the single source of truth for
both forward (table ↔ arm shape) and reverse (arm ↔ table
row) checks, an adversarial `if (ins->op == IR_X)` placed
*outside* the real dispatch functions is rejected by the
verifier, and the spike harness prints per-class
dispatch counts.

---

## 1. Why

CORE03-CORRECTION03 P1 residue (verbatim):

> `get_dispatch_arms()` still discovers `if (ins->op ==
> IR_X)` short-circuits in any function, while the stricter
> body extractor scopes to `llLowerInstr` / the explicit
> switch helpers used by `LlFunction`. The two scopes are
> not unified.

If the dispatch set the verifier sees is wider than the
set the arm-local diagnostic binder sees, an `if (ins->op
== IR_X)` placed in an unrelated helper function could be
counted as a handler for I2 (reverse) without being checked
for diagnostic emission by I1/M2. That asymmetry creates a
false-green path.

CORE03-CORRECTION03 closes the symptom (bad rows), not the
cause (scope mismatch). RESUME01 closes the cause.

RED-M2 is preserved from CORE04 because the per-class
counter gap is real and still unaddressed.


---

## 2. Scope

### allowed

- `scripts/quality/llvm-cap-table-verifier.py` — refactor
  to a single scoped discovery parser; both I1 and I2
  consume the resulting dispatch set.
- `scripts/quality/llvm-cap-table-verifier.py` — add a
  self-adversarial test fixture (in-file string constants
  outside the parser that exercise the new scope rules;
  the parser must REJECT them).
- `src/llvm-backend.c` — increment `n_support_dispatched`
  on every `case IR_X:` entry classified SUPPORTED;
  increment `n_rejected_dispatched` on every REJECTED
  diagnostic emit. No semantic change.
- `src/llvm-backend.h` — add new counter fields to `LLCtx`.
- `scripts/quality/llvm-spike-test.sh` — emit
  `=== capability counters ===` block in the harness
  summary.
- `docs/ROADMAP.md` — update CORE04 entry to record the
  HALT and point at RESUME01; remove the (now-defunct)
  M1 wording from the previous residue listing.

### forbidden

- Adding a third hand-maintained C-side dispatch list
  (rejected design from CORE04).
- Semantic change to any IR opcode lowering.
- Adding/removing SUPPORTED opcodes.
- Weakening any existing rejection diagnostic.
- Modifying any closed ACT document or HANDOFF (F14).
- Modifying the Factory v2 grammar, range-checker, or
  commit policy.
- Adding dependencies.
- Retroactive edits to CORE01..CORE04 evidence.
- Touching `kLLVMBackendCapability[]` row content (the
  table is closed and tracked by CORRECTION03; do not
  re-litigate row semantics here).

---

## 3. Entry gate

```text
git branch --show-current  → main
git status --short         → clean
git rev-parse HEAD         → recorded (must be on or after 4be5df3)
```

Required state:

- on main;
- worktree clean;
- entry HEAD recorded;
- factory-v2-test PASS=35;
- factory-closure-status PASS;
- `llvm-cap-table-verifier.py` runs rc=0 (verifies the
  pre-RESUME01 baseline is still green).

---

## 4. Principal RED (verified before this ACT)

**RED-M1 — dispatch set has a discovery-scope mismatch.**

The verifier currently exposes this by inspection: at the
predecessor chain end, `get_dispatch_arms()` looks for
`if (ins->op == IR_X)` short-circuits anywhere in
`llvm-backend.c`, while `get_if_arm_bodies()` scopes to
`llLowerInstr` and explicit switch helpers. A unit test
written in `llvm-cap-table-verifier.py` proves the
asymmetry.

**Adversarial RED witness.** A self-test inside the
verifier asserts the asymmetry exists. RESUME01 IMPL must
make this assertion PASS — i.e. the new scoped model
rejects the adversarial fixture and the forward+reverse
checks see a single consistent dispatch set.

The seeded adversarial constant is a labelled, delimited
string constant inside the verifier's own self-test; it is
not present in `llvm-backend.c`. The current verifier has
no scope-tighter, so the self-test will FAIL (RED). After
IMPL unifies the discovery model, the same self-test
PASSes.

**RED-M2 — no per-class execution counters** (carried from
CORE04 §4, still real).

```sh
grep -nE 'n_support|n_rejected|counts_per_class' \
    src/llvm-backend.c src/llvm-backend.h \
    scripts/quality/llvm-spike-test.sh
```

returns no matches. The harness summary shows only
per-fixture pass/fail.

---

## 5. Implementation boundary

Minimum production change:

1. **Single scoped dispatch parser** in
   `scripts/quality/llvm-cap-table-verifier.py`:
   - Define the dispatch set as the union of
     `llLowerInstr()` body + any function named in the
     `LlFunction()` switch body (e.g. `llLowerBinOp`,
     `llLowerCmp`, `llLowerConversion`, … — whatever the
     real source uses).
   - Both `check_dispatch()` (I1) and `check_reverse()`
     (I2) consume the same dispatch set. The
     `check_dispatch_arm_local_diagnostic()` (M2 of
     CORRECTION02) consumes the bodies from the same set.
   - Drop the file-wide `if (ins->op == IR_X)` scan from
     `get_dispatch_arms()`. Keep it as a *negative*
     assertion: if any `if (ins->op == IR_X)` exists
     *outside* the scoped dispatch set, emit a verifier
     warning (and the new self-adversarial test forces
     this into a FAIL).

2. **Self-adversarial test** in the same verifier
   (RED-M1):
   - A test function `check_dispatch_scope_is_tight()`
     seeds an in-file adversarial string constant
     (clearly delimited and labelled as adversarial),
     parses it as if it were source, and FAILs if the
     parser accepts an `if (ins->op == IR_X)` outside
     the scoped dispatch set. The seeded constant is
     removed after IMPL passes.

3. **Counter fields** in `LLCtx`:
   - `unsigned long n_support_dispatched;`
   - `unsigned long n_rejected_dispatched;`
   - `unsigned long n_defensive_trips;` (already present
     from CORE03; reuse).

4. **Counter increments** in `LlFunction()` (and the
   `llLower*` helpers that are called from the dispatch,
   only at the dispatch entry point):
   - SUPPORTED arm: `lc->n_support_dispatched++`.
   - REJECTED diagnostic emit: `lc->n_rejected_dispatched++`.
   - DEFENSIVE_INVARIANT emit: `lc->n_defensive_trips++`.

5. **Aggregation**:
   - `LLCtx` counters are per-function. For harness-level
     totals, the driver walks all `LLCtx` instances and
     sums. The compiler emits a single line per class
     before exit, format:
     ```
     CAPABILITY_COUNTERS support=<N> rejected=<N> defensive=<N>
     ```
   - The harness parses these lines and prints the
     `=== capability counters ===` block.

6. **Harness summary** in `scripts/quality/llvm-spike-test.sh`:
   - Parse `CAPABILITY_COUNTERS` lines from the compiler
     output (one per invocation, summed across the 18
     fixtures).
   - Print:
     ```
     === capability counters ===
       SUPPORTED          : <N>
       REJECTED           : <N>
       DEFENSIVE_INVARIANT: <N>
       UNREACHABLE_ON_LLVM : <N>
     ==============================
     ```

Explicitly **not** included:

- New hard-coded runtime C-side dispatch list (rejected).
- Per-fixture counter deltas (P2 residue).
- Per-opcode histogram (P2 residue).
- Changes to `kLLVMBackendCapability[]` row content.
- Changes to the dispatch arm semantics.

- `llvm-spike-test.sh` baseline PASS=18 (CORE03 baseline).


---

## 6. Acceptance criteria

| ID    | Command / observation                                                                       | Expected                                   |
|-------|---------------------------------------------------------------------------------------------|--------------------------------------------|
| AC01  | `git diff --check HEAD`                                                                     | rc=0                                        |
| AC02  | `make clean && make`                                                                        | succeeds                                    |
| AC03  | `scripts/quality/llvm-spike-test.sh` (full run)                                             | PASS=18 FAIL=0                              |
| AC04  | harness summary contains `=== capability counters ===` block with non-zero SUPPORTED + REJECTED | printed, non-empty, both > 0              |
| AC05  | `scripts/quality/factory-v2-test.sh`                                                        | PASS=35 FAIL=0                              |
| AC06  | `scripts/quality/factory-closure-status-check.sh`                                           | PASS                                        |
| AC07  | `python3 scripts/quality/llvm-cap-table-verifier.py`                                        | rc=0; PASS for I1, I2, I3                  |
| AC08  | scope-tight self-test: seeded adversarial `if (ins->op == IR_X)` outside the dispatch set is REJECTED | rc=0                        |
| AC09  | before IMPL: seeded adversarial fixture causes the verifier to FAIL the scope-tight test    | observed (RED evidence)                     |
| AC10  | after IMPL: same fixture passes                                                              | observed (GREEN evidence)                   |
| AC11  | `scripts/quality/gate-fast.sh`                                                              | PASS                                        |

AC09/AC10 establish the M1 RED→GREEN cycle inside the
verifier itself (the production source does not contain a
malicious `if (ins->op == IR_X)`, so the RED is a
synthetic adversarial constant inside the verifier's own
self-test).

---

## 7. Conservation gates

- `make unit-test` — expected PASS count unchanged.
- `make jit-unit-test` — expected PASS count unchanged.
- `llvm-spike-test` — PASS=18 (CORE03 baseline preserved).
- `factory-v2-test` — PASS=35 (Factory unchanged).
- `factory-closure-status` — PASS.
- `llvm-cap-table-verifier` — PASS for I1, I2, I3
  (the verifier cannot regress).
- `gate-fast` — PASS.
- `git diff --check HEAD` — rc=0.

---

## 8. Halt taxonomy

- `HALT_RED_NOT_REPRODUCED` — applies to RED-M1 / RED-M2.
- `HALT_DISPATCH_SCOPE_REGRESSION` — the unified scoped
  model is *less* tight than the prior CORRECTION02 body
  extractor (would mean IMPL reintroduced the asymmetry).
- `HALT_COUNTER_REGRESSION` — a per-class counter
  decreases across the 18-fixture run (non-monotonic
  accumulation).
- `HALT_VERIFIER_REGRESSION` — `llvm-cap-table-verifier.py`
  returns rc>0 on the current source.
- `HALT_SCOPE_EXPANSION_REQUIRED` — if closing this ACT

---

## 9. Residue (pre-declared)

- P2 — per-fixture counter deltas (not in this ACT).
- P2 — per-opcode histogram (not in this ACT).
- P2 — moving the verifier into a C runtime check (would
  duplicate source scanning in C — not justified yet).
- P2 — FT1 closure-oracle trust relocation (Factory backlog).
- P2 — FT2 descendant-scan simplification (Factory backlog).
- P2 — FT3 trailer-key casing enforcement (Factory backlog).
- P2 — legacy `factory-closure-status-check.sh` retirement.
- P2 — CI enforcement of v2 trailers.

---

## 10. Commit topology (suggested; not capped)

```text
C1 (RED)
    ACT: ACT-POLYC-LLVM-CORE04-RESUME01
    ACT-Phase: RED

    Add scripts/quality/llvm-cap-table-verifier.py
    scope-tight self-test check_dispatch_scope_is_tight()
    with seeded adversarial fixture.
    Verify RED: rc=1 (scope-tight FAIL on seeded
    adversarial constant).

    Also add scripts/quality/llvm-spike-test.sh line that
    emits "counters=missing" when CAPABILITY_COUNTERS line
    is absent in compiler output.

C2 (IMPL)
    ACT: ACT-POLYC-LLVM-CORE04-RESUME01
    ACT-Phase: IMPL

    Refactor verifier to single scoped dispatch model
    (both I1 and I2 consume the same set).
    Add CAPABILITY_COUNTERS emission to compiler driver.
    Increment counters in LlFunction() arms.
    Update harness to parse counters and emit
    === capability counters === block.

    Verify GREEN: scope-tight test PASSes (rc=0);
    spike-test PASS=18 FAIL=0; counters block has
    SUPPORTED > 0, REJECTED > 0.

C3 (EVIDENCE)
    ACT: ACT-POLYC-LLVM-CORE04-RESUME01
    ACT-Phase: EVIDENCE

    Update docs/ROADMAP.md CORE04 entry to record
    HALT + RESUME01; remove defunct M1 wording.
    Capture counter baselines.
    No production code change.

C4 (CLOSE)
    ACT: ACT-POLYC-LLVM-CORE04-RESUME01
    ACT-Phase: CLOSE
    ACT-Verdict: PASS

    Final gate run; submit_and_exit with closure handoff.
```

The 4-commit structure is the *minimum* for proof; an
extra commit is allowed but not a numeric cap.

---

## 11. Closure handoff

Hand off via:

- `scripts/quality/factory-v2-range-check.sh ACT-POLYC-LLVM-CORE04-RESUME01 HEAD`
- a HANDOFF doc under `evidence/llvm-core04-resume01/`
  describing what was added, where, with verbatim gate
  output.

The ACT document is **not** modified at closure.

---

## 12. Execution metadata

Execution identity is stored in Git commit trailers:

```
ACT: ACT-POLYC-LLVM-CORE04-RESUME01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
ACT-Verdict: <token>      (CLOSE only)
```

The original authorization artifact remains historically
stable; there is no OPEN -> PASS / HALT mutation. The ACT
document is NOT modified at closure. Closure happens via
the CLOSE commit's `ACT-Verdict` trailer.

---

## 13. Reviewer discipline rule (per pre-ACT review)

> No Factory implementation changes inside RESUME01 unless
> a RESUME01 RED actually demonstrates that Factory v2
> prevents or invalidates the compiler ACT.

If a Factory-related RED emerges during C1/C2, RESUME01
will HALT with `HALT_FACTORY_V2_INVALIDATES_RESUME01` and a
separate Factory ACT will be opened; RESUME01 will not
silently absorb Factory refactoring.

  requires touching Factory v2 or any closed ACT.
