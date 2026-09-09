# ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** IMPLEMENTATION

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** (none — first PARITY-class ACT for the native x86_64 backend)

**Production semantic changes:** AUTHORIZED (scoped)

- Float EQ / NE / LT / LE on NaN inputs must return the IEEE-754
  ordered-comparison result (0, 1, 0, 0 respectively).
- Float GT / GE behaviour must remain unchanged
  (unordered already rejected by the underlying ucomisd flag semantics).
- Applies to both the AOT encoder (`src/x86_64.c`) and the JIT
  encoder (`src/x86_64-jit.c`).

**IR / ABI / LLVM authorization:** SCOPED

- The IR_FCMP / IR_CMP_BR instruction semantics are unchanged.
- The x86_64 native backend's encoding of those IR operations
  is corrected.
- LLVM backend is out of scope (see Residue P1).

---

## Mission

Repair PolyC's native x86_64 backend so that float EQ / NE / LT / LE
match IEEE-754 / LangRef "ordered" semantics on NaN inputs
(==/!=/<,<= on NaN → 0/1/0/0), preserving GT / GE behaviour.
The fix must apply identically to AOT and JIT code emission.
A regression must be caught if either the encoder or either copy
of the float-setcc composition is reverted.

## Scope

### allowed

- `src/asm/enc_x86_64.c` — encoder correctness fix for SETcc ModR/M.
- `src/asm/enc_x86_64.h` — declaration / comment alignment.
- `src/x86_64.c` — float-setcc composition table for both FCMP and
  CMP_BR dispatch sites.
- `src/x86_64-jit.c` — mirror the corrected composition into the JIT.
- `src/tests/native-x86-float-cmp-parity01/` — fixtures and the
  IR_FCMP-only witness.
- `scripts/quality/native-x86-float-cmp-parity01-test.sh` — single
  bounded harness (positive + NC).
- `evidence/native-x86-float-cmp-parity01/` — RED / IMPL evidence.

### forbidden

- Semantic change to GT / GE float comparisons.
- Change to IR_FCMP / IR_CMP_BR instruction semantics.
- LLVM backend changes (out of scope, see Residue P1).
- Any new dependency.
- Refactoring unrelated IR_CMP_* cases or adjacent encoder code.
- Pre-existing IR_FPTOSI bug must not be widened — it is observed
  but not fixed here.

## Principal RED

**File:** `src/tests/native-x86-float-cmp-parity01/red_nan.HC`

For NaN (qnan) compared to 1.0:

```text
NaN == 1.0 -> expected FALSE, observed TRUE  (RED)
NaN != 1.0 -> expected TRUE,  observed FALSE (RED)
NaN <  1.0 -> expected FALSE, observed TRUE  (RED)
NaN <= 1.0 -> expected FALSE, observed TRUE  (RED)
NaN >  1.0 -> FALSE (CONSERVATION)
NaN >= 1.0 -> FALSE (CONSERVATION)
```

**Reproduction (AOT):**

```sh
DYLD_LIBRARY_PATH=/tmp/polyc-install/lib \
  arch -x86_64 ./hcc --install-dir=/tmp/polyc-install \
  -o /tmp/red_nan.bin src/tests/native-x86-float-cmp-parity01/red_nan.HC
DYLD_LIBRARY_PATH=/tmp/polyc-install/lib arch -x86_64 /tmp/red_nan.bin
```

**Reproduction (JIT):**

```sh
DYLD_LIBRARY_PATH=/tmp/polyc-install/lib \
  arch -x86_64 ./hcc --install-dir=/tmp/polyc-install \
  -jit src/tests/native-x86-float-cmp-parity01/red_nan.HC
```

## Root cause

Two defects, both observed in fresh tree:

1. **`x86_64_enc_setcc_cl` ModR/M byte.**
   In `src/asm/enc_x86_64.c`, the encoder emitted
   `modrm(3, 1 /* CL */, 0 /* AL */)` = `0xC8`.
   Per Intel SDM, ModR/M.reg for the SETcc opcode group is
   reserved / must-be-zero; the destination is encoded in
   ModR/M.rm. `0xC8` therefore targets `%al`, not `%cl`.
   The two SETcc ops (primary + PF helper) were therefore
   both writing to `%al`, with the PF helper clobbering the
   primary result. This is the single root cause that produces
   the floating-comparison RED.

2. **Two divergent copies of the float-setcc composition table.**
   `src/x86_64.c` carries the same switch in two places —
   `x86_64EmitFloatSetCC` (called by `IR_FCMP` dispatch) and
   the inline composition inside the `IR_CMP_BR` arm.
   The two copies were inconsistent (e.g. the FCMP-side LE
   had `pf_helper = NULL` / `combiner = NULL` while the
   CMP_BR-side LE had the correct `setnp` / `andb`).
   Both must be repaired in lockstep.

### Boolean equations (correct composition)

For inputs `a`, `b` (unordered iff PF=1 after `ucomisd`):

| Pred | Primary       | PF helper | Combiner | Result for `a OP b`     |
|------|---------------|-----------|----------|-------------------------|
| EQ   | sete          | setnp     | andb     | (a==b) & ~(unordered)   |
| NE   | setne         | setp      | orb      | (a!=b) | (unordered)    |
| LT   | setb          | setnp     | andb     | (a<b)  & ~(unordered)   |
| LE   | setbe         | setnp     | andb     | (a<=b) & ~(unordered)   |
| GT   | seta          | —         | —        | (a>b)  (CF=0 ∧ ZF=0; unordered rejected) |
| GE   | setae         | —         | —        | (a>=b) (CF=0; unordered rejected) |

## Acceptance criteria

- **AC01** Encoder ModR/M byte is `0xC1` (reg=0 reserved, rm=CL).
  Witness: `grep -c 'modrm(3, 0 /\* reg reserved \*/, 1 /\* CL = rm \*/)' src/asm/enc_x86_64.c` returns `1`.
- **AC02** All four "ordered" predicates (EQ/NE/LT/LE) have
  `pf_helper` set in **both** copies of the float-setcc table
  in `src/x86_64.c`.
- **AC03** `red_nan.HC` (AOT + JIT) output matches
  `evidence/.../impl/red-nan-{aot,jit}-after.txt`.
- **AC04** `ir_fcmp_witness.HC` (AOT + JIT) output matches
  `evidence/.../impl/ir-fcmp-{aot,jit}-after.txt` — covers
  the IR_FCMP dispatch arm directly (bypassing FPTOSI).
- **AC05** `finite_baseline.HC` (AOT + JIT) output matches
  `evidence/.../impl/finite-baseline-{aot,jit}-after.txt`.
- **AC06** `special_values.HC` (AOT + JIT) output matches
  `evidence/.../impl/special-values-{aot,jit}-after.txt`
  (conservation: +0.0/-0.0, ±Inf must remain correct).
- **AC07** `HCC_X86_64=./hcc-x86_64 PARITY01_RUN_NC=1
  scripts/quality/native-x86-float-cmp-parity01-test.sh`
  reports `PARITY01_PASS=8 PARITY01_FAIL=0` and
  `PARITY01_NC_PASS=8 PARITY01_NC_FAIL=0 PARITY01_NC_TOTAL=8`.
- **AC08** All eight NCs catch their respective regression:
  - NC1: encoder revert (ModR/M = `0xC8`) — fingerprint
    `0f 9[b|a] c8` in JIT dump.
  - NC2–NC5: AOT `x86_64EmitFloatSetCC` reverts
    (one per predicate) — caught via `ir_fcmp_witness.HC`.
  - NC6–NC8: AOT `IR_CMP_BR` reverts (one per predicate) —
    caught via `red_nan.HC` (the `if`-form exercises CMP_BR).

## Conservation gates

- `scripts/quality/gate-fast.sh` — must remain GREEN.
- `scripts/quality/factory-v2-test.sh` — must remain GREEN.
- All pre-existing float-comparison tests must remain
  semantically identical:
  - `scripts/quality/llvm-float01-test.sh`
  - `scripts/quality/llvm-spike-test.sh`
  - `scripts/quality/llvm-memory01-test.sh`
- LangRef-mandated behaviour for GT / GE on NaN (must remain 0).

## HALT conditions

- `HALT_RED_NOT_REPRODUCED` — if the RED in `red_nan.HC` no
  longer reproduces against a fresh build of the unmodified
  tree, halt before any production change.
- `HALT_SCOPE_EXPANSION_REQUIRED` — if completing this ACT
  requires touching LLVM, FPTOSI, or any non-x86_64 backend.

## Residue

- **P0** none observed during this ACT.
- **P1** Pre-existing IR_FPTOSI bug: `I64 x = (I64)some_float;`
  patterns hit a broken conversion path; observed independently
  during NC development (`I64 x = NaN == 1.0; print x;` masks
  the float-cmp bug because it routes through FPTOSI). This ACT
  documents it but does not fix it.
- **P1** LLVM backend parity: `src/llvm/` has not been audited
  for the same composition. A future `ACT-POLYC-LLVM-FLOAT02`
  should verify LLVM EQ/NE/LT/LE on NaN matches IEEE-754.
- **P2** NC1 uses JIT byte fingerprint (`HCC_JIT_DUMP=1`) rather
  than a behavioural diff because the buggy encoder's output is
  register-clobber dependent and therefore flaky.

## Execution metadata

Execution identity is stored in Git commit trailers. The CLOSE
commit trailer must include:

```text
ACT: ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

This document is **not** mutated at closure.

## Closure handoff

Use the Factory v2 HANDOFF template
(`docs/factory/HANDOFF-TEMPLATE.md` Factory v2 section).

Reviewer command:

```sh
sh scripts/quality/factory-v2-range-check.sh \
   ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 HEAD
```

## Commit topology

Three commits are expected:

1. **RED**: fixtures (`red_nan.HC`, `finite_baseline.HC`,
   `special_values.HC`, `ir_fcmp_witness.HC`) + harness
   (`native-x86-float-cmp-parity01-test.sh`) + RED evidence.
2. **IMPL**: production fix to `src/asm/enc_x86_64.c`,
   `src/x86_64.c`, `src/x86_64-jit.c`.
3. **EVIDENCE**: regenerated evidence + this ACT document.

Commits should be honest and bounded — no unrelated cleanup.
