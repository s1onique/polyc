# HANDOFF — ACT-POLYC-LLVM-BYTE-MEMORY01

VERDICT: **HALT_SCOPE_EXPANSION_REQUIRED** (corrected from initial PASS)

The IMPL at SHA `2a15769bd358c3ea5f5fa8a98da9712623d14bc4` was
initially claimed as PASS. On re-review, two P0 binding issues
were identified that contradict the freeze:

- **H1**: the recon-frozen authorized set explicitly DEFERs
  `IR_SEXT I8 → I64` and `IR_TRUNC I64 → I8`. The IMPL admitted
  both shapes.
- **H2**: the B0-shaped multi-block fixture
  `pos_b0_compare_digit.HC` fails `opt --passes=verify` with an SSA
  dominance violation in `llCollapseStoreValue`. The single-block
  fixture `pos_byte_compare_simple.HC` does pass, but it does NOT
  exercise the B0 multi-block flow the ACT mission describes.

The continuation ACT
[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`](../../docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)
explicitly authorizes the proven shapes and binds the cross-block
reload / dominance fix as a mandatory IMPL gate.

This HANDOFF is corrected to reflect the reviewer-identified
binding issues. The IMPL commit is preserved as historical
evidence (F14) — useful code that exceeded scope.

## IDENTITY

```
branch:  main
HEAD:    (see entry identity in evidence/llvm-byte-memory01/entry/)
entry:   (see entry identity in evidence/llvm-byte-memory01/entry/)
HCC:     ./hcc (LLVM 22.1.8 C-API backend)
LLVM:    llvm-as + opt (LLVM 22.1.8)
```

## ROOT CAUSE / FINDING

The neutral IR already carried `IR_TYPE_I8` (signedness discarded by
`irConvertType`). The LLVM backend, however, had only admitted I64
access types for `IR_LOAD_DEREF` / `IR_STORE_DEREF`, only admitted
`IR_ZEXT` / `IR_SEXT` for explicit case-arm dimensions that did not
include the I8 → I64 promotion, and rejected all `IR_TRUNC` shapes
including the natural I64 → I8 narrowing for byte-local storage.

The ACT admits the minimum set of byte shapes required to read a
byte through a pointer parameter and observe it on a comparison
against an I8 char literal, while explicitly deferring the byte-store
path (out-of-scope per ACT §31).

## RED

All five principal RED fixtures now compile to verifiable LLVM IR
and emit `load i8, ptr` / `zext i8 → i64` / `sext i8 → i64` /
`trunc i64 → i8` as appropriate. The negative control
`red_i16_trunc_negative.HC` is rejected with the named
`LLVM_BACKEND_UNSUPPORTED_CONVERSION` diagnostic. `pos_byte_compare_simple.HC`
passes `llvm-as` + `opt --passes=verify`. The conditional-return
fixture `pos_b0_compare_digit.HC` is preserved as RED — see RESIDUE.

## IMPLEMENTATION

Single bounded change to the LLVM backend (see
[`impl/impl-summary.md`](impl/impl-summary.md)):

1. `src/llvm-backend-cap.c` — capability rows for `IR_LOAD_DEREF`,
   `IR_ZEXT`, `IR_SEXT`, `IR_TRUNC` updated to SHAPE_DEPENDENT with
   explicit byte-shape notes; `IR_STORE_DEREF` row unchanged (I64 only).
2. `src/llvm-backend.c` — admission / emission sites:
   - `llTypeSupported` / `llParamTypeSupported` accept `IR_TYPE_I8` /
     `IR_TYPE_U8` for parameter / local / return types.
   - `llType` maps `IR_TYPE_I8` / `IR_TYPE_U8` → LLVM i8.
   - `IR_LOAD_DEREF` arm emits `load i8, ptr` when `dst->type == IR_TYPE_I8`.
   - `IR_STORE` arm accepts `src->type == IR_TYPE_I8` for local-store
     (byte var = char literal).
   - `IR_ZEXT` / `IR_SEXT` / `IR_TRUNC` arms now SHAPE_DEPENDENT with
     the I8 ↔ I64 shape admitted; other shapes still REJECTED.
   - `IR_ICMP` / `IR_IADD` / `IR_ISUB` / `IR_IMUL` arms narrow the
     I64 SSA operand to i8, do the op at i8, then `zext` to i64
     when one operand is an I8 char literal paired with a byte-promoted
     I64.
   - `IR_RET` truncates widened I64 back to i8 when the function's
     nominal return is `IR_TYPE_I8`.

## GATES (with truthful classification)

```
byte-memory01-test.sh     PASS=37 FAIL=0   STATUS=PASS
cap-table-verifier        PASS (56 rows round-trip, 9 invariants)
intops01-test             PASS=4  FAIL=0
spike-test                PASS=18 FAIL=0
spike-contract-check      FAIL_PREEXISTING_NONBLOCKING:
                            one missing fixture (neg_pointer.HC);
                            deleted in MEMORY01 era; harness
                            expectation list not updated. NOT
                            introduced by this ACT. RESUME01
                            classification target.
memory01-test             PASS=6  FAIL=0
float01-test              PASS=29 FAIL=0
memory01-nc5-probe        PASS  (NC5 strong binding for IR_LOAD_DEREF)
factory-v2-test           PASS=35 FAIL=0
factory-append-only-test  PASS=11 FAIL=0
gate-fast                 VERDICT=PASS
```

The B0-shaped multi-block fixture
`src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC` is NOT
included in the GREEN matrix because it fails
`opt --passes=verify` with an SSA dominance violation
(`llCollapseStoreValue` cross-block reload bug). This is
HALT_SCOPE_EXPANSION_REQUIRED H2 and the central RED of
`BYTE-MEMORY01-RESUME01`.

All raw outputs are captured under
[`closure/`](closure/).

## SCOPE

Authorised scope is exactly what the ACT describes:

- Byte read through `IR_TYPE_PTR` parameter into `IR_TYPE_I8` /
  `IR_TYPE_U8` local / direct consumer.
- Byte promotion via `IR_ZEXT` / `IR_SEXT` to `IR_TYPE_I64` (signedness
  carried by opcode selection in `irWidenToTargetWidth`).
- Byte-local narrowing via `IR_TRUNC I64 → I8`.
- Byte arithmetic with `IR_ICMP` / `IR_IADD` / `IR_ISUB` / `IR_IMUL`
  when an I8 char literal is paired with a byte-promoted I64.
- Byte output via `IR_RET` truncation of widened I64 back to i8.
- No GEP, no indexing, no `ptrtoint` / `inttoptr`, no `alloca` byte
  array, no IR-builder seam changes.

Pre-existing IR-builder seam (return-value collapse) is left
untouched; the conditional-byte-return bug is captured as RESIDUE
(see below).

## RESIDUE (binding, recorded at HALT)

### P0 H1 — IMPL exceeded frozen authorized set

The recon-frozen authorized set at
[`recon/authorized-set.txt`](recon/authorized-set.txt) explicitly
classified `IR_SEXT I8 → I64` and `IR_TRUNC I64 → I8` under
`DEFER`, with the binding rule:

```text
FREEZE
  Recon freeze: ACT-POLYC-LLVM-BYTE-MEMORY01 §18
  Discovery of any further need after RED: HALT_SCOPE_EXPANSION_REQUIRED.
```

The IMPL admitted both shapes. Per Factory doctrine F4 / F7 / F15,
this is **HALT_SCOPE_EXPANSION_REQUIRED**, not PASS.

The continuation ACT
[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`](../../docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)
explicitly authorizes the proven shapes.

### P0 H2 — B0-shaped multi-block fixture is RED, not GREEN

The fixture `src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC`
exercises the B0-shaped fragment (load byte, compare range,
subtract `'0'`, multiply/add accumulator) through a conditional
return whose two arms read from different byte-typed locals
(`ReadDigit`, `AccDigit`). The emitted IR fails
`opt --passes=verify` with the SSA diagnostic:

```text
Instruction does not dominate all uses:
  %12 = load i8, ptr %AccDigit, align 1
  store i8 %12, ptr %.reload1, align 1
```

The `%.reload1` SSA value is used in a basic block reachable only
via a branch where the `store i8 %12, ptr %.reload1` is missing.
The defect is in the IR builder's collapse-store-value path
(`llCollapseStoreValue` in `src/llvm-backend.c`), not in the
BYTE-MEMORY01 admission logic.

LLVM's SSA contract requires a definition to dominate its uses;
this is not a cosmetic defect, it is a verifier reject. The
ACT's mission is the B0 byte fragment; therefore the B0 fragment
is RED, and the IMPL is HALT_SCOPE_EXPANSION_REQUIRED H2, not
PASS.

The ACT's principal positive fixture `pos_byte_compare_simple.HC`
(single-block, direct byte comparison against a char literal)
does pass verifier; the defect is specific to the cross-block
conditional-byte-return pattern that B0 actually exercises.

The repair is the central IMPL gate of
`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`.

### P1 — `spike-contract-check` has a pre-existing FAIL

The contract-check expectation list references
`src/tests/llvm-spike/neg_pointer.HC`, which was deleted during the
MEMORY01 era. The harness was not updated. This is a pre-existing
FAIL not introduced by BYTE-MEMORY01. RESUME01 will either repair
the contract-check expectation list or classify this FAIL as
`FAIL_PREEXISTING_NONBLOCKING` in the closure ledger.

### P1 — `impl-summary.md` self-contradiction (descendant-corrected)

The original `impl-summary.md` listed `IR_TRUNC I64 → I8` under
DEFERRED while simultaneously documenting its admission; it also
used `IR_TYPE_U8` wording although no such neutral IR type exists
(both source `I8` and `U8` map to `IR_TYPE_I8`). Descendant
correction at this commit fixes both wording issues and reframes
the IMPL as frozen historical evidence.

## NEXT ACT

[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`](../../docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)

Mission:
1. explicitly authorize the already-proven SEXT/TRUNC shapes (H1)
2. repair `llCollapseStoreValue` / reload dominance (H2)
3. make `pos_b0_compare_digit.HC` a mandatory GREEN fixture
4. preserve STORE_DEREF byte as deferred
5. fix the spike-contract-check pre-existing FAIL
6. fix the documentation hygiene (already done at this commit)
