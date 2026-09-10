# ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT (OPEN)

**Title:** Resume BYTE-MEMORY01 — authorize proven `SEXT`/`TRUNC` shapes,
repair cross-block reload SSA dominance, and bind `pos_b0_compare_digit`
as the mandatory B0-shaped GREEN fixture.

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
- `ACT-POLYC-LLVM-BYTE-MEMORY01` — `HALT_SCOPE_EXPANSION_REQUIRED`
  (H1 frozen-set exceeded; H2 B0 multi-block SSA dominance bug).
  See [`ACT-POLYC-LLVM-BYTE-MEMORY01.md`](ACT-POLYC-LLVM-BYTE-MEMORY01.md) §0.5.

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT — semantic extension +
IR-builder seam repair

**Production semantic changes:** **NONE** (the byte lowering semantics
are already correct; this ACT formalizes the proven `SEXT`/`TRUNC`
shapes and repairs the IR builder's reload dominance for conditional
byte returns).

---

## 0. Mission

This RESUME01 ACT addresses the two HALT reasons recorded against
`BYTE-MEMORY01`:

**Mission 1 — explicitly authorize the proven shapes.**

The `BYTE-MEMORY01` recon freeze classified `IR_SEXT I8 → I64` and
`IR_TRUNC I64 → I8` under DEFER. The IMPL commit at `2a15769b`
admitted both shapes. This ACT explicitly authorizes both shapes and
binds them under a single, named, capability-row signature.

**Mission 2 — repair cross-block reload SSA dominance.**

The IMPL evidence shows `pos_b0_compare_digit.HC` fails LLVM
verifier with an SSA dominance violation. The defect is in the
backend's reload-store collapse optimization (`llCollapseStoreValue`
in `src/llvm-backend.c`). This ACT repairs the IR-builder seam so
the B0-shaped multi-block byte fragment produces verifier-valid
LLVM IR.

**Mission 3 — bind `pos_b0_compare_digit.HC` as a mandatory GREEN
fixture, not an advisory positive.**

The `BYTE-MEMORY01` IMPL marked this fixture as DEFERRED (residue).
The B0 mission is incomplete without it. This ACT requires
`pos_b0_compare_digit.HC` to pass `llvm-as` + `opt --passes=verify`
as a closure-critical gate.

**Mission 4 — fix documentation hygiene.**

- Classify `spike-contract-check` truthfully as
  FAIL_PREEXISTING / NONBLOCKING_HISTORICAL (or repair the
  contract-check expectation list).
- Replace the contradictory `impl-summary.md` (which lists
  `IR_TRUNC I64 → I8` under DEFERRED while simultaneously documenting
  its admission, and uses the `IR_TYPE_U8` wording although no such
  neutral IR type exists — both source `I8` and `U8` map to
  `IR_TYPE_I8`).
- Apply trailing-whitespace hygiene to the `spike-contract-check`
  output (the harness's `expected_opcodes:` empty-list format
  produces 20 whitespace errors that gate `git diff --check`).

## 1. Authorized set (delta from `BYTE-MEMORY01` recon freeze)

The recon freeze at
[`evidence/llvm-byte-memory01/recon/authorized-set.txt`](../../evidence/llvm-byte-memory01/recon/authorized-set.txt)
is REPLACED by the following authorized set:

```text
IMPLEMENT
  byte scalar admission (IR_TYPE_I8 in llType / llTypeSupported /
                         llParamTypeSupported)
    -- source I8 AND U8 both map to neutral IR_TYPE_I8; signedness
       is carried by IR_ZEXT vs IR_SEXT, not by a separate neutral type.
  byte pointer parameter admission (already IR_TYPE_PTR; access type is byte)
  IR_LOAD_DEREF byte shape (load i8, ptr %p)
  IR_ZEXT I8 -> I64 (zext i8 to i64)  -- unsigned promotion
  IR_SEXT I8 -> I64 (sext i8 to i64)  -- signed promotion
  IR_TRUNC I64 -> I8 (trunc i64 to i8) -- byte-local narrowing
  IR_STORE local IR_TYPE_I8 (char literal -> byte local; in-memory only,
                              not via pointer)

DEFER
  IR_STORE_DEREF byte shape (store i8 %v, ptr %p) -- B0 is read-only
  IR_TRUNC I64 -> arbitrary byte shape (e.g. I64 -> I16 / I32)
  multi-byte arbitrary-width memory (I16, I32 support)
  byte constants as IR-level byte (char literals remain I64 in the
    neutral IR per ACT §7)

ALREADY_SUPPORTED
  IR_LOAD / IR_STORE (I64 SSA scalar shape)
  IR_IADD / IR_ISUB / IR_IMUL
  IR_ICMP (signed eq/ne/lt/le/gt/ge)
  IR_BR / IR_RET
  opaque ptr (IR_TYPE_PTR) for parameter identity

FORBIDDEN (in this ACT)
  GEP / getelementptr (IR_GEP / LLVMBuildGEP*)
  pointer arithmetic (p++, src + n)
  ptrtoint / inttoptr
  alloca / malloc / free
  multi-byte arbitrary-width memory (I16, I32 support)
  byte constants as IR-level byte (char literals remain I64 per ACT §7)
  F32 / F64 widening work
  bitwise / shift / division opcodes
  new frontend syntax, neutral IR opcode, neutral IR redesign
  new native backend semantics
  unaligned / volatile / atomic memory
  general pointer aliasing machinery, TBAA metadata
  IR-builder seam changes OUTSIDE the llCollapseStoreValue reload
    selection repair
```

## 2. RED (mandatory, all must compile to verifier-valid LLVM IR)

```text
red_byte_load           -- U8 pointer read
red_byte_pointer_param  -- U8 pointer parameter admission
red_byte_to_i64         -- U8 promotion to I64
red_u8_param            -- U8 parameter admission
red_i8_param            -- I8 parameter admission
red_i16_trunc_negative  -- I64 -> I16 boundary REJECTED
pos_byte_compare_simple -- single-block direct byte compare
pos_b0_compare_digit    -- B0-shaped multi-block conditional byte return
                            MANDATORY GREEN (was RED in IMPL)
```

`pos_b0_compare_digit.HC` failure under `opt --passes=verify` is
P0 H2 and is the central RED of this ACT.

## 3. Source change scope (bounded)

1. `src/llvm-backend.c` — `llCollapseStoreValue` repair: ensure the
   reload-store sequence dominates every consumer block. The repair
   is block-aware: when a reload SSA value `%.reload1` is created for
   a byte local, the corresponding `store` must be emitted in every
   predecessor block whose branch reaches a consumer.

2. `src/llvm-backend-cap.c` — note rewrite for `IR_SEXT`, `IR_TRUNC`
   rows to reflect the RESUME01 authorized set; rationale + line refs.

3. `evidence/llvm-byte-memory01/impl/impl-summary.md` — replace the
   contradictory text with a single coherent summary:
   - State once that source `I8`/`U8` map to neutral `IR_TYPE_I8`.
   - Remove `IR_TRUNC I64 → I8` from the DEFERRED list (it is admitted).
   - State that `IR_SEXT` and `IR_TRUNC` are admitted under RESUME01
     (citing the SHA of this ACT's IMPL commit), not the prior IMPL.

4. `scripts/quality/llvm-spike-contract-check.sh` — repair the
   contract-check expectation list to remove the `neg_pointer.HC`
   reference (file was deleted in MEMORY01 era; harness was never
   updated). This converts the pre-existing FAIL into a clean PASS
   on a contract check that matches the actual spike evidence tree.

5. `scripts/quality/llvm-byte-memory01-test.sh` — extend to assert
   that `pos_b0_compare_digit.HC` passes `llvm-as` + `opt --passes=verify`.

## 4. IR / ABI / neutral-IR boundary changes

**NONE.** The neutral IR is unchanged. The `IR_TYPE_I8` carrier
already exists; signedness is carried by `IR_ZEXT` vs `IR_SEXT`
in `irWidenToTargetWidth`. No new opcode, no new neutral-IR type.

## 5. CAPABILITY COUNTERS binding

Every positive byte fixture must increment SHAPE_DEPENDENT at the
dispatch seam (CORE04 §30 binding):

```
IR_LOAD_DEREF   SHAPE_DEPENDENT (admit I64 + I8 access types)
IR_STORE_DEREF  SHAPE_DEPENDENT (I64 only; byte store still DEFERRED)
IR_ZEXT         SHAPE_DEPENDENT (admit I8 -> I64 promotion)
IR_SEXT         SHAPE_DEPENDENT (admit I8 -> I64 promotion)
IR_TRUNC        SHAPE_DEPENDENT (admit I64 -> I8 narrowing)
```

## 6. Closure gates

| Gate                         | Status requirement                                        |
|------------------------------|-----------------------------------------------------------|
| `byte-memory01-test.sh`      | PASS — including `pos_b0_compare_digit` mandatory GREEN  |
| `cap-table-verifier`         | PASS — `IR_SEXT`, `IR_TRUNC` rows bound as SHAPE_DEPENDENT |
| `intops01-test`              | PASS=4 FAIL=0                                             |
| `spike-test`                 | PASS=18 FAIL=0                                            |
| `spike-contract-check`       | PASS=18 FAIL=0 (no pre-existing FAIL)                    |
| `memory01-test`              | PASS=6 FAIL=0                                             |
| `float01-test`               | PASS=29 FAIL=0                                            |
| `memory01-nc5-probe`         | PASS                                                      |
| `factory-v2-test`            | PASS=35 FAIL=0                                            |
| `factory-append-only-test`   | PASS=11 FAIL=0                                            |
| `gate-fast`                  | VERDICT=PASS, `git diff --check` clean                    |

## 7. Out-of-scope

- GEP / pointer indexing
- `ptrtoint` / `inttoptr`
- `alloca` byte array
- IR_STORE_DEREF byte shape
- bitwise / shift / division opcodes
- multi-byte arbitrary-width memory
- F32 / F64 widening
- new frontend syntax
- new neutral IR opcode
- new native backend semantics
- unaligned / volatile / atomic memory

## 8. NEXT ACT (provisional)

After RESUME01 closes, the next ACT should be either:

- `ACT-POLYC-LLVM-GEP01` — bounded GEP/indexing for arrays / structs,
  **only if** RESUME01 has already repaired the IR builder seam
  (otherwise GEP01 will inherit the same cross-block dominance bug).

`GEP01` will immediately produce more multi-block lexer code;
carrying a known SSA dominance bug into it will make debugging
much harder (per the ACT reviewer).
