# HANDOFF -- ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01

Factory-Version: 2

## Result

Float EQ/NE/LT/LE on NaN now produce the IEEE-754 ordered-comparison
result on both AOT and JIT. 16/16 gate checks pass (8 positive + 8 NC).

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

### Production code

- `src/asm/enc_x86_64.c` — added four byte-level helpers
  (`x86_64_enc_setcc_cl`, `x86_64_enc_andb_al_cl`,
  `x86_64_enc_orb_al_cl`, `x86_64_enc_testb_al`); fixed
  `x86_64_enc_setcc_cl` ModR/M from `modrm(3,1,0)` = `0xC8`
  to `modrm(3,0,1)` = `0xC1` so SETNP / SETP actually write to
  `%cl` (per Intel SDM: ModR/M.reg is reserved for SETcc).
- `src/asm/enc_x86_64.h` — declared the four new helpers.
- `src/x86_64.c` — float-setcc composition for FCMP dispatch
  (`x86_64EmitFloatSetCC`) and for the `IR_CMP_BR` arm both
  apply PF-mask correctly: EQ=sete+setnp+andb, NE=setne+setp+orb,
  LT=setb+setnp+andb, LE=setbe+setnp+andb. GT/GE unchanged.
- `src/x86_64-jit.c` — mirrors the corrected composition into
  the JIT code emitter.

### Tests + harness

- `src/tests/native-x86-float-cmp-parity01/red_nan.HC` —
  principal RED (NaN vs 1.0 in both orders; uses `if` → CMP_BR).
- `src/tests/native-x86-float-cmp-parity01/finite_baseline.HC` —
  non-NaN baseline (catches encoder bug that accidentally passes
  NaN by PF coincidence).
- `src/tests/native-x86-float-cmp-parity01/special_values.HC` —
  conservation: +0/-0, ±Inf must remain correct.
- `src/tests/native-x86-float-cmp-parity01/ir_fcmp_witness.HC` —
  IR_FCMP-only witness using `printf("%d")` to bypass the
  pre-existing FPTOSI bug; covers the FCMP dispatch arm.
- `scripts/quality/native-x86-float-cmp-parity01-test.sh` —
  bounded harness (positive + 8 NC).

### Documentation

- `docs/acts/ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01.md` —
  ACT authorization artifact (Factory v2).
- `docs/handoff/ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01.md` —
  this handoff.

## Evidence

- `evidence/native-x86-float-cmp-parity01/impl/red-nan-{aot,jit}-after.txt`
- `evidence/native-x86-float-cmp-parity01/impl/ir-fcmp-{aot,jit}-after.txt`
- `evidence/native-x86-float-cmp-parity01/impl/finite-baseline-{aot,jit}-after.txt`
- `evidence/native-x86-float-cmp-parity01/impl/special-values-{aot,jit}-after.txt`
- `evidence/native-x86-float-cmp-parity01/impl/assembly-after/*.s`
  — SETcc destinations are `%al` (primary) and `%cl` (PF helper);
  no `0F 9B C8` / `0F 9A C8` fingerprint present.
- `evidence/native-x86-float-cmp-parity01/impl/truth-table-after.txt`
- `evidence/native-x86-float-cmp-parity01/impl/scope.txt`
- `evidence/native-x86-float-cmp-parity01/impl/gates.txt`

Gate result:

```text
PARITY01_PASS=8 PARITY01_FAIL=0 PARITY01_SKIP=0
PARITY01_NC_PASS=8 PARITY01_NC_FAIL=0 PARITY01_NC_TOTAL=8
```

Each NC catches a distinct regression (encoder revert, FCMP-side
revert per predicate, CMP_BR-side revert per predicate).

## Production delta

Float comparison semantics on NaN inputs now match IEEE-754
"ordered" rules:

```text
NaN == x -> 0
NaN != x -> 1
NaN <  x -> 0
NaN <= x -> 0
NaN >  x -> 0   (unchanged)
NaN >= x -> 0   (unchanged)
```

The change is scoped to the x86_64 native backend (AOT + JIT).
LLVM backend is untouched (out of scope, see Residue).

## Residue

- **P1** Pre-existing IR_FPTOSI bug: `I64 x = (I64)f; print x;`
  patterns hit a broken conversion path. The IR_FCMP-witness
  fixture deliberately bypasses FPTOSI to expose the float-cmp
  bug independently. Documented but not fixed in this ACT.
- **P1** LLVM backend (`src/llvm/`) has not been audited for
  the same composition. Future `ACT-POLYC-LLVM-FLOAT02` should
  verify LLVM EQ/NE/LT/LE on NaN matches IEEE-754.
- **P2** NC1 uses JIT byte fingerprint (`HCC_JIT_DUMP=1` +
  `grep 0f 9[b|a] c8`) rather than a behavioural diff because
  the buggy encoder's output is register-clobber dependent and
  flaky. Documented in the harness comments.

## Recommended next ACT

`ACT-POLYC-LLVM-FLOAT02` — audit the LLVM backend for the same
float-comparison composition. Also fold in the pre-existing
IR_FPTOSI bug as a separate scoped ACT if desired.
