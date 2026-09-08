# ACT-POLYC-LLVM-CORE03

**Title:** Machine-enforced capability contract; CORE02 P1 fixes;
per-fixture matrix decoder

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-CORE01` (REJECTED, f4ac2e7)
- `ACT-POLYC-LLVM-CORE01-CORRECTION01` (HALT_TOPOLOGY_RECORDED, b05ea7e)
- `ACT-POLYC-LLVM-CORE01-CORRECTION02` (PASS, 75983a8)
- `ACT-POLYC-LLVM-CORE02` (PASS_WITH_NONBLOCKING_RECON_RESIDUE, 8f88938)

**Reviewer verdict authorizing CORE03:**
> PASS_WITH_NONBLOCKING_RECON_RESIDUE — CORE03 unblocked
> Make it mechanically impossible for the executable LLVM dispatch
> and the declared capability contract to drift apart.

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT

**Production semantic changes:** **NONE**

**Production diagnostic additions:**
- `LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED` — emitted to stderr
  when a defensive invariant guard fires (currently: IR_BR/i64).
  Non-fatal: the dispatch continues with the existing trunc path.

**Source change scope (bounded):**
1. NEW `src/llvm-backend-cap.h` + `src/llvm-backend-cap.c` with:
   - `LLVMBackendCapability` enum: SUPPORTED, REJECTED,
     SHAPE_DEPENDENT, UNREACHABLE_ON_LLVM, DEFENSIVE_INVARIANT;
   - `LLVMBackendCapabilityDef` struct;
   - `kLLVMBackendCapability[]` table (one row per IR opcode);
   - `llValidateCapabilityContract()` runtime assertion.
2. `src/llvm-backend.c` dispatch site: when IR_BR sees a non-i1
   cond, emit `LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED` to
   stderr and continue. Add a counter `lc->defensive_trips` so
   the harness can assert the count is zero for the supported
   subset.
3. `scripts/quality/llvm-spike-test.sh`: per-fixture matrix
   decoder that prints opcode/expected/observed and a
   `=== contract check ===` block.
4. `src/llvm-backend.c` matrix table: tighten the IR_BR / IR_NOP /
   IR_LABEL rows to reflect:
   - IR_BR/i64 is `DEFENSIVE_INVARIANT` (runtime warn + continue);
   - IR_NOP / IR_LABEL have NO explicit REJECTED arm (CORE02
     closure prose bug: HANDOFF said they did, but the dispatch
     has no `case IR_NOP:` / `case IR_LABEL:` arms; they fall to
     the generic default).
5. `src/llvm-backend.h`: add the new diagnostic constant.

**IR / ABI / neutral-IR boundary changes:** **NONE**

**LLVM IR lowering additions:** **NONE**

**Language change authorization:** **NONE**

---

## 0. Mission

CORE02 closed with the observation that the capability matrix is
**documented in a C comment** but not enforced by the compiler.
If a future patch adds a `case IR_NEW_OP:` to the dispatch but
forgets to document it in the matrix, nothing catches the drift.

CORE03 turns the matrix into a **runtime-checkable** contract:

```
M1. Every IR opcode has a capability row in a C table.
M2. The dispatch validates the table at startup.
M3. The harness decodes each fixture into the table and
    asserts: (expected_class, expected_diagnostic) matches
    (observed_class, observed_diagnostic).
M4. The IR_BR/i64 path becomes a runtime-detected DEFENSIVE
    invariant guard with its own diagnostic (was: silent trunc).
M5. CORE02's two P1s are mechanically resolved:
    P1-a IR_BR/i64: softened to DEFENSIVE_INVARIANT with
         runtime detection (no more "proven unreachable" claim).
    P1-b IR_NOP/IR_LABEL closure prose: the contract now
         distinguishes "explicit-rejection fence" (case IR_X:)
         from "generic-unreachable" (default: arm) by
         inspecting the dispatch itself.
```

---

## 1. Reviewer P1 reds (carried into CORE03)

### P1-a — IR_BR/i64

CORE02 claim: "i64→i1 trunc is unreachable on current neutral IR."

CORE03 refinement: mechanically downgrade to
**DEFENSIVE_INVARIANT** and add runtime detection. When the
LLVMTypeOf dispatch observes a non-i1 cond at the IR_BR arm:

```
fprintf(stderr,
    "%s: function %s: IR_BR cond has non-i1 type "
    "(kind=%d width=%d); defensively truncating. "
    "This indicates an upstream regression in "
    "irNormalizeBranchCondition or a future fusion pass "
    "that was added to the LLVM path by mistake.\n",
    LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED,
    lc->fn->name->data, kind, width);
lc->defensive_trips++;
```

No `exit(1)`. The dispatch continues with the existing trunc
so a future regression in upstream code is logged loudly but
not catastrophic. The harness counts these and asserts
`defensive_trips == 0` for the supported subset.

### P1-b — IR_NOP / IR_LABEL closure prose

CORE02 HANDOFF said: "`IR_CMP_BR / IR_RMW_DEREF / IR_NOP /
IR_LABEL` still have explicit REJECTED arms."

CORE03 correction: `IR_NOP` and `IR_LABEL` have **NO explicit
case arms** in the dispatch (verified at CORE03 entry:

```
$ grep -nE 'case IR_(NOP|LABEL):' src/llvm-backend.c
(no output)
```

They fall to the generic `default:` arm in the switch, which
calls `llErrUnsupportedOp` and `exit(1)`. The matrix classifies
them `UNREACHABLE_ON_LLVM` (correct), but the closure prose in
CORE02 wrongly implied they have explicit REJECTED arms. CORE03
fixes this in two places:

1. `src/llvm-backend.c` matrix comment — `IR_NOP` row:
   replace "generic default arm stays as a regression safety
   net" with the more precise "no explicit `case IR_NOP:` arm;
   the generic `default:` arm catches a future regression and
   emits `LLVM_BACKEND_UNSUPPORTED_IR`."
2. `src/llvm-backend.c` matrix comment — `IR_LABEL` row: same
   wording change.

(These are EXACTLY the same rows CORE02 edited; CORE03
tightens their wording without changing their class.)

---

## 2. Mission 1 — machine-readable capability table

NEW `src/llvm-backend-cap.h`:

```c
typedef enum {
    LLVMBC_SUPPORTED          = 0,
    LLVMBC_REJECTED           = 1,
    LLVMBC_SHAPE_DEPENDENT    = 2,
    LLVMBC_UNREACHABLE_ON_LLVM = 3,
    LLVMBC_DEFENSIVE_INVARIANT = 4,
} LLVMBackendCapability;

typedef struct {
    IrOp                       op;
    LLVMBackendCapability      class_;
    const char                *diagnostic;  /* NULL if class_ != REJECTED */
    const char                *note;
} LLVMBackendCapabilityDef;

extern const LLVMBackendCapabilityDef kLLVMBackendCapability[];
extern const int kLLVMBackendCapabilityCount;

/* Runtime validation. Called once from main. Asserts:
 *   - every IrOp value (0 .. IR_ASM) has exactly one row;
 *   - REJECTED rows have non-NULL diagnostic;
 *   - SUPPORTED / UNREACHABLE / DEFENSIVE rows have NULL diagnostic;
 *   - no duplicate opcodes in the table. */
void llValidateCapabilityContract(void);
```

NEW `src/llvm-backend-cap.c`:

- The table itself. One row per IrOp value, in enum order.
- `llValidateCapabilityContract()`:
  - assert `kLLVMBackendCapabilityCount == IR_ASM + 1`;
  - assert no duplicate opcodes (linearly);
  - assert REJECTED has diagnostic, others (except SHAPE_DEPENDENT)
    have NULL diagnostic;
  - print `=== capability contract: ok (N rows) ===` to stderr
    on success.

---

## 3. Mission 2 — runtime enforcement

`src/llvm-backend.c`:

1. Add `LLCtx::defensive_trips` counter (zero-initialised in
   `llFunction`).
2. In the IR_BR arm: when `LLVMTypeOf(cond) != i1`, emit the
   new diagnostic and increment the counter.
3. Call `llValidateCapabilityContract()` once at the top of
   `main()` (in `src/main.c`) before any compile job.

`src/main.c`:

- At the start of `main()`, after argument parsing, before the
  first `--emit-llvm` invocation, call `llValidateCapabilityContract()`.

---

## 4. Mission 3 — per-fixture matrix decoder

`scripts/quality/llvm-spike-test.sh`:

For each positive fixture, after the existing PASS/FAIL:

```
=== contract check: <fixture> ===
expected_class:    SUPPORTED
observed_class:    SUPPORTED     (hcc --emit-llvm rc=0)
expected_diagnostic: -
observed_diagnostic: -
defensive_trips:   0
verdict:           PASS
```

For each negative fixture, after the existing PASS/FAIL:

```
=== contract check: <fixture> ===
expected_class:    REJECTED
observed_class:    REJECTED     (hcc --emit-llvm rc!=0)
expected_diagnostic: LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
observed_diagnostic: LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
defensive_trips:   0
verdict:           PASS
```

The decoder pulls the expected (class, diagnostic) tuple from
the fixture's `.expected` sidecar (NEW files under
`src/tests/llvm-spike/*.expected`). The sidecar is generated
by CORE03 itself from the existing matrix; it is data, not a
hand-written expectation.

---

## 5. Conservation gates

| Gate                                  | expected                |
|---------------------------------------|-------------------------|
| `git diff --check HEAD`               | rc=0                    |
| `make clean && make`                  | succeeds                |
| `llvm-spike-test`                     | PASS=18 FAIL=0          |
| new `contract_check` block per fixture | PASS=18 FAIL=0 (added) |
| defensive_trips count per fixture     | 0 for all positive      |
| CORE03 commits                        | RED + IMPL + DOCS = 3   |

---

## 6. Forbidden

* Adding new SUPPORTED opcodes.
* Weakening the existing 18 PASS.
* Removing any existing rejection diagnostic.
* Claiming i64 IR_BR is "proven unreachable" — must be
  DEFENSIVE_INVARIANT with runtime detection.
* Retroactive edits to CORE01 / CORE02 docs (F14).

---

## 7. Residue

P2: defensive_trips can become >0 in tests, but the supported
    subset must keep it at 0 (harness-enforced).
P2: `LLVMBackendCapability` is a new enum; future ACTs may add
    runtime checks per-class (e.g. assert every SUPPORTED row
    has a matching `case IR_X:` arm in the dispatch).
P2: IR_BR DEFENSIVE_INVARIANT is the only DEFENSIVE row
    currently; future ACTs may add more (none expected; the
    pipeline architecture does not produce other invariants).
P2: the closure-oracle-trust (FT1) investigation is still
    pending — it is now MORE important because CORE03's
    contract check is itself a closure oracle.

---

## 8. Next ACT

ACT-POLYC-LLVM-CORE04 (deferred):
- assert every `case IR_X:` in the dispatch has a matching
  `kLLVMBackendCapability[]` row (the reverse of CORE03 M1);
- per-class execution counters (e.g. `n_rejections_per_class`)
  emitted in the harness summary.

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1).
