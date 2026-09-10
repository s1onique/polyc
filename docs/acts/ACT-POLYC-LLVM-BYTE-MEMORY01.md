# ACT-POLYC-LLVM-BYTE-MEMORY01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT (CLOSED via HALT_SCOPE_EXPANSION_REQUIRED)

**Title:** Smallest real LLVM byte slice — `IR_TYPE_I8` load + `IR_ZEXT`
byte→I64 promotion, plus structural-purity discipline (no GEP, no
`ptrtoint`/`inttoptr`, no `alloca`).

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-SPIKE01` + RESUME01 + CORRECTION chains (PASS)
- `ACT-POLYC-LLVM-CORE01` + CORRECTION02 (PASS chain)
- `ACT-POLYC-LLVM-CORE02` (PASS_WITH_NONBLOCKING_RECON_RESIDUE)
- `ACT-POLYC-LLVM-CORE03` + CORRECTION01..05 (PASS chain)
- `ACT-POLYC-LLVM-CORE04` + RESUME01 (PASS chain)
- `ACT-POLYC-LLVM-MEMORY01` + CORRECTION01 + CORRECTION02 (PASS chain)
- `ACT-POLYC-LLVM-FLOAT01` + CORRECTION01 (PASS chain)
- `ACT-POLYC-LLVM-INTOPS01` (PASS)
- `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` + CORRECTION01 (PASS chain)
- `ACT-POLYC-FACTORY-HISTORY-RECONCILE01` (PASS)
- `ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01` + CORRECTION01 (PASS chain)

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT — semantic extension

**Production semantic changes:** **NONE** (language semantics preserved via native backend; LLVM backend adds byte load + unsigned byte→I64 promotion for one proven shape)

**CLOSED verdict:** `HALT_SCOPE_EXPANSION_REQUIRED` (see §0.5 below)

---

## 0. Mission

Extend the LLVM backend's deliberately-supported set with the **smallest
real byte slice**:

```text
pointer parameter carrying address of byte
        ↓
IR_LOAD_DEREF (dst = IR_TYPE_I8)
        ↓
LLVM opaque `ptr`
        ↓
load i8, ptr %p
zext i8 %v to i64     ; unsigned byte → I64 promotion
```

No GEP. No pointer arithmetic. No aggregate access. No arrays. No
structs. No pointer-to-pointer. No global variables. No heap
allocation. No LLVM `alloca`. No PHI. No `ptrtoint` / `inttoptr`.
No bitcast. No byte-store. No multi-byte arbitrary-width memory.

Factory v2 remains frozen.

### 0.5 Closure verdict

`HALT_SCOPE_EXPANSION_REQUIRED` for the following reasons (recorded
per Factory doctrine F4 / F7 / F15):

**H1 — Frozen authorized set was exceeded.**

The recon freeze at
[`evidence/llvm-byte-memory01/recon/authorized-set.txt`](../../evidence/llvm-byte-memory01/recon/authorized-set.txt)
explicitly classifies:

```text
DEFER
  IR_SEXT I8 -> I64 (sext i8 to i64) -- not required for B0 read-only path
  IR_STORE_DEREF byte shape            -- B0 is read-only
  IR_TRUNC I64 -> I8 (trunc i64 to i8) -- not required without byte store
```

with the binding rule:

```text
FREEZE
  Recon freeze: ACT-POLYC-LLVM-BYTE-MEMORY01 §18
  Discovery of any further need after RED: HALT_SCOPE_EXPANSION_REQUIRED.
```

The IMPL shipped at SHA `2a15769bd358c3ea5f5fa8a98da9712623d14bc4`
admitted `IR_SEXT I8 → I64` and `IR_TRUNC I64 → I8` and rewrote
their capability rows from `REJECTED` to `SHAPE_DEPENDENT`. This
contradicts the freeze.

**H2 — B0-shaped multi-block fixture is not actually GREEN.**

`src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC` exercises the
advertised B0-shaped fragment (load byte, compare range, subtract
`'0'`, multiply/add accumulator). The IMPL evidence shows this
fixture fails `opt --passes=verify` with an SSA dominance violation:

```text
Instruction does not dominate all uses:
  %12 = load i8, ptr %AccDigit, align 1
  store i8 %12, ptr %.reload1, align 1
```

LLVM's SSA contract requires a definition to dominate its uses
(see LLVM's `Dominators.h` contract); this is not a cosmetic defect,
it is a verifier reject. The principal positive fixture actually
captured in the GREEN matrix is `pos_byte_compare_simple.HC`, which
is a single-block direct-byte-comparison fragment and **does not
exercise the B0 multi-block flow the ACT mission describes**.

### 0.6 Continuation

The continuation ACT
[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`](ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)
explicitly authorizes the proven `SEXT` and `TRUNC` shapes and
binds the cross-block reload / dominance fix as a mandatory IMPL
gate.

## 1. Why this is the next slice

After MEMORY01, the LLVM backend has verifier-clean scalar-I64
memory access through opaque pointer parameters. The bootstrap
mission `BOOTSTRAP-RECON01` requires byte-level memory access for
the B0 lexer fragment:

```c
load byte from pointer
promote via ZEXT (unsigned byte → I64)
compare to char-literal constants
branch
subtract '0'
multiply/add accumulator
```

The byte slice is the smallest step that adds `IR_TYPE_I8` as a
load access type and admits the unsigned-byte→I64 promotion. It
deliberately defers the signed-byte path and the byte-store path.

## 2. Frozen authorized set (recon freeze)

See [`evidence/llvm-byte-memory01/recon/authorized-set.txt`](../../evidence/llvm-byte-memory01/recon/authorized-set.txt)
for the verbatim freeze. The IMPL commit at `2a15769b` exceeded the
DEFER list (see §0.5 H1).

## 3. RED (frozen)

Principal RED fixtures (`src/tests/llvm-byte-memory01/`):

- `red_byte_load.HC` — U8 pointer read
- `red_byte_pointer_param.HC` — U8 pointer parameter
- `red_byte_to_i64.HC` — U8 promotion to I64
- `red_u8_param.HC` — U8 parameter admission
- `red_i8_param.HC` — I8 parameter admission
- `red_i16_trunc_negative.HC` — I64→I16 narrowing boundary
- `pos_byte_compare_simple.HC` — direct byte comparison with char literal
- `pos_b0_compare_digit.HC` — B0-shaped multi-block fragment

Observed (post-IMPL): the first six fixtures compile and verify;
`pos_byte_compare_simple.HC` compiles and verifies; `pos_b0_compare_digit.HC`
fails verifier with SSA dominance violation (see §0.5 H2).

## 4. IMPL (frozen, scope-violated)

The IMPL commit at SHA `2a15769bd358c3ea5f5fa8a98da9712623d14bc4`
is preserved as historical evidence (F14). It contains useful code
but exceeded the authorized set. The continuation ACT
`BYTE-MEMORY01-RESUME01` re-authorizes the proven shapes.

## 5. CAPABILITY COUNTERS evidence

The IMPL shows non-zero `shape_dependent` for every positive byte
fixture, consistent with SHAPE_DEPENDENT capability class binding
(CORE04 §30 binding). See
[`evidence/llvm-byte-memory01/impl/positive-matrix.txt`](../../evidence/llvm-byte-memory01/impl/positive-matrix.txt).

## 6. Closure gates (frozen)

| Gate                         | Status                                        |
|------------------------------|-----------------------------------------------|
| `byte-memory01-test.sh`      | PASS=37 FAIL=0 (within authorized scope only) |
| `cap-table-verifier`         | PASS                                          |
| `intops01-test`              | PASS=4 FAIL=0                                 |
| `spike-test`                 | PASS=18 FAIL=0                                |
| `spike-contract-check`       | PRE-EXISTING FAIL on `neg_pointer.HC` (resolved in RESUME01) |
| `memory01-test`              | PASS=6 FAIL=0                                 |
| `float01-test`               | PASS=29 FAIL=0                                |
| `memory01-nc5-probe`         | PASS                                          |
| `factory-v2-test`            | PASS=35 FAIL=0                                |
| `factory-append-only-test`   | PASS=11 FAIL=0                                |
| `gate-fast`                  | VERDICT=PASS                                  |

## 7. RESIDUE

| Priority | Item                                                                  |
|----------|-----------------------------------------------------------------------|
| **P0 H1** | IMPL exceeded the frozen authorized set: `SEXT` and `TRUNC` shapes admitted although DEFER. RESUME01 must re-authorize. |
| **P0 H2** | `pos_b0_compare_digit.HC` fails LLVM verifier (cross-block reload SSA dominance bug in `llCollapseStoreValue`). The B0 mission is not GREEN. RESUME01 must repair the IR builder seam. |
| P1       | `spike-contract-check` carries a pre-existing FAIL on `neg_pointer.HC` (deleted in MEMORY01 era); not introduced by this ACT. RESUME01 will classify this truthfully as FAIL_PREEXISTING / NONBLOCKING_HISTORICAL or repair the contract-check expectation list. |
| P1       | `evidence/llvm-byte-memory01/impl/impl-summary.md` carries documentation contradictions (lists `IR_TRUNC I64 → I8` under DEFERRED although it is admitted; uses `IR_TYPE_U8` wording although there is no such neutral IR type — both `I8` and `U8` source map to `IR_TYPE_I8`). RESUME01 will publish a corrected `impl-summary.md`. |

## 8. NEXT ACT

[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`](ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)
— explicitly authorize the proven `SEXT`/`TRUNC` shapes, repair
`llCollapseStoreValue` cross-block reload dominance, make
`pos_b0_compare_digit.HC` a mandatory GREEN fixture, classify
`spike-contract-check` truthfully, and fix the documentation
contradictions.
