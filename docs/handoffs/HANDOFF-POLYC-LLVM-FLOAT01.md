# ACT-POLYC-LLVM-FLOAT01 / HANDOFF

VERDICT: PASS

## Identity

- branch: main
- HEAD: (see FLOAT01 CLOSE commit; will be appended by `ACT-Verdict: PASS` trailer)
- predecessor HEAD: 4043579f (MEMORY01-CORRECTION02 CLOSE)
- ACT scope: scalar F64 (param/return/constants/FADD/FSUB/FMUL/FCMP/FCMP→BR)
- companion file: `docs/acts/ACT-POLYC-LLVM-FLOAT01-CORRECTION01.md` (closure contract)
- correction01 evidence: `evidence/llvm-float01/correction01/`

## Root cause / finding

The LLVM backend was rejecting the entire `IR_TYPE_F64` value family at
`llTypeSupported` with `LLVM_BACKEND_UNSUPPORTED_TYPE`, which prevented
any source-level F64 use from compiling. The FLOAT01 ACT authorises a
bounded scalar-F64 slice (param, return, constants, FADD/FSUB/FMUL,
FCMP, FCMP→IR_BR) and binds the comparison semantics to the LLVM
Language Reference Manual (target-independent ordered/unordered
semantics). The aarch64 host oracle is a corroborating witness, not
the authority.

The mapping is:

| PolyC op | LLVM FCmp predicate |
|----------|---------------------|
| ==       | LLVMRealOEQ         |
| !=       | LLVMRealUNE         |
| <        | LLVMRealOLT         |
| <=       | LLVMRealOLE         |
| >        | LLVMRealOGT         |
| >=       | LLVMRealOGE         |

These predicates are bound to the LLVM Language Reference Manual's
target-independent ordered/unordered semantics: `oeq/olt/ole/ogt/oge`
return false when either operand is NaN; `une` returns true when
either operand is NaN. This matches PolyC's docs/CHARTER.md commitment
to the IEEE-754 unordered convention.

The host (aarch64) JIT/AOT oracle is consistent with this binding:
`fcmp NaN, x` sets NZCV=0011 (binary: N=0 Z=0 C=1 V=1), and
`cset mi/ls/gt/ge/eq` all return 0 while `cset ne` returns 1 —
exactly matching the ordered-predicate semantics. This is
recorded as a witness, not as the binding authority. Full
argument in `evidence/llvm-float01/red/recon-ll-semantics.txt`.

Note: the PolyC x86_64 NATIVE backend's IR_FCMP dispatch (see
`src/x86_64.c:670-679` and `x86_64-jit.c:425-433`) emits
`sete/setne/setb/setbe/seta/setae` after `ucomisd`. With
`ZF=PF=CF=1` on NaN, FOUR of six predicates produce the WRONG
IEEE-754 / LangRef result:

  EQ (sete):    NaN -> 1   WRONG; expected 0
  NE (setne):   NaN -> 0   WRONG; expected 1
  LT (setb):    NaN -> 1   WRONG; expected 0
  LE (setbe):   NaN -> 1   WRONG; expected 0
  GT (seta):    NaN -> 0   CORRECT (matches ogt NaN->false)
  GE (setae):   NaN -> 0   CORRECT (matches oge NaN->false)

GT and GE produce the correct result by accident of the UCOMISD
CF=ZF=0 branch (seta/setae require CF=0 and CF=0 respectively,
which is what UCOMISD reports on unordered operands). EQ/NE/LT/LE
must be re-emitted to mask unordered. This DIVERGES from both the
LLVM LangRef binding used by the LLVM backend and from the
aarch64 host oracle for the four broken predicates. The x86_64
native defect is strictly a PolyC native-backend issue and is
recorded as P0 future residue under
`ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01` with defect set:
EQ/NE/LT/LE must change; GT/GE are conservation controls
(must NOT change).

## RED (PR-1 RED commit: 4592d79)

The principal RED is RED-A: 16 reproducer fixtures rejected at
`LLVM_BACKEND_UNSUPPORTED_TYPE` rc=1 at `llTypeSupported` /
`llParamTypeSupported` in the pre-IMPL tree, captured in
`evidence/llvm-float01/red/`. The recon
(`evidence/llvm-float01/red/recon-f64-type.txt`,
`recon-comparison-semantics.txt`, and
`recon-ll-semantics.txt`) captures:

- F64 neutral-IR shape (F64 params become `double %0`, F64 constants
  become `double 0x...`).
- `as._f64` representation in the IR value struct (aliasing with
  `as.var` — same union overlap MEMORY01 fixed for `as.var`).
- IR_FCMP returns i1 in LLVM, but IR_VAL_TMP target is i64 (the IR's
  neutral type for comparison results). The bridge uses `irDstVarId`
  which already handles i1-into-i64 binding.
- The 6-op comparison-semantic binding to the LLVM LangRef (authority)
  with the aarch64 host oracle as a corroborating witness. The x86_64
  native defect is recorded separately under
  `ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01`.

Post-admission qualification checks (Q-3..Q-7) exercise the
FADD/FSUB/FMUL/FCMP/FCMP→BR dispatch arms against the IR shape and
were never independently reproducible in the pre-IMPL tree. They are
documented for traceability, not as principal REDs.

RED summary: `evidence/llvm-float01/red/RED-SUMMARY.md` (and the
corrected taxonomy at
`evidence/llvm-float01/correction01/RED-SUMMARY-corrected.md`).

## Implementation (IMPL commit: 99391c4)

Production changes (additive; F7 ledger: `evidence/llvm-float01/impl/scope.txt`):

- `src/llvm-backend.c`:
  - `llType`, `llTypeSupported`, `llParamTypeSupported` accept
    `IR_TYPE_F64`; mapped to `LLVMDoubleTypeInContext`.
  - `llPass1` derives the return type from `fn->return_value->type`
    (was hard-coded i64).
  - `llLowerValue` adds `IR_VAL_CONST_FLOAT` arm with cache-bypass
    (extends MEMORY01's union-aliasing fix to F64 constants).
  - `llDetectCollapsibleReturn` accepts F64 return slots.
  - `llLowerInstr` gains `IR_FADD/IR_FSUB/IR_FMUL/IR_FCMP` arms
    (LL_INC_SUPPORTED) with explicit F64 operand guards, zero
    fast-math flags, and the `llFloatCmpKindToLLVMPred` helper for
    `FCmp` predicates. `IR_RET` and `IR_STORE` accept `IR_TYPE_F64`.
  - `IR_FDIV` and `IR_FNEG` remain REJECTED with FLOAT01-annotated
    diagnostics.
- `src/llvm-backend-cap.c`: `IR_FADD/IR_FSUB/IR_FMUL/IR_FCMP` →
  SUPPORTED with notes; `IR_FDIV/IR_FNEG` remain REJECTED with
  FLOAT01-annotated notes.

Predecessor evidence conservation:

- `src/tests/llvm-spike/neg_f64.HC` re-scoped to F32 params
  (still rejected as `LLVM_BACKEND_UNSUPPORTED_TYPE` for F32 float
  arithmetic; the previous F64-with-I64-return shape is now caught
  by the LLVM verifier — a strict superset of `UNSUPPORTED_TYPE`).

## Test harness

- `scripts/quality/llvm-float01-test.sh` (NEW): 13 positive + 6
  comparison-predicate + 1 branch + 1 mixed + 4 negative fixtures
  (neg_fdiv, neg_float_to_int, neg_fptosi_witness, neg_int_to_float).
  Per-fixture SUPPORTED attribution (7 attributions). 3 determinism
  fixtures. llvm-as + opt --passes=verify. Fast-math purity grep.
  DEFENSIVE/UNREACHABLE counter gates.

- `src/tests/llvm-float01/` (NEW): 13 positive .HC + 1 special_values.HC
  + 4 negative .HC. Total 18 fixtures. The `neg_fptosi_witness.HC`
  fixture was added in CORRECTION01 to close the IR_FPTOSI gap.

## Gates

```
scripts/quality/llvm-float01-test.sh        FLOAT01_PASS=29 FAIL=0
scripts/quality/llvm-spike-test.sh          PASS=18  FAIL=0
scripts/quality/llvm-memory01-test.sh       PASS=6   FAIL=0
scripts/quality/llvm-memory01-nc5-probe.sh  PASS  (NC5 strong binding confirmed for IR_LOAD_DEREF)
scripts/quality/llvm-cap-table-verifier.py  PASS  (IR_FCMP + new helper detected)
scripts/quality/factory-v2-test.sh          PASS=35 FAIL=0
scripts/quality/gate-fast.sh                VERDICT=PASS
```

## Scope (F7 ledger)

In-scope files modified:
- `src/llvm-backend.c` (additive F64 paths only)
- `src/llvm-backend-cap.c` (F64 promotion rows)
- `src/tests/llvm-float01/*.HC` (13 + 1 + 4 = 18 new fixtures)
- `src/tests/llvm-spike/neg_f64.HC` (predecessor conservation redirect)
- `scripts/quality/llvm-float01-test.sh` (new harness)
- `evidence/llvm-float01/{red,impl,correction01}/*` (capture)

Out of scope and NOT modified:
- `src/aarch64*.c`, `src/x86_64*.c`, `src/asm/*`, `src/cli.c`,
  `src/main.c`, `src/ir*.c`, `src/ir-types.{c,h}`.

## Residue (F11, classified)

P0 (recommended next ACT): ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01
  The PolyC x86_64 native backend's IR_FCMP dispatch (src/x86_64.c:670-679,
  src/x86_64-jit.c:425-433) emits sete/setne/setb/setbe/seta/setae
  after ucomisd. With UCOMISD setting ZF=PF=CF=1 on NaN/unordered
  operands, FOUR of six predicates produce the WRONG IEEE-754 /
  LangRef result:
    EQ (sete):    NaN -> 1   WRONG; expected 0
    NE (setne):   NaN -> 0   WRONG; expected 1
    LT (setb):    NaN -> 1   WRONG; expected 0
    LE (setbe):   NaN -> 1   WRONG; expected 0
    GT (seta):    NaN -> 0   CORRECT (matches ogt)
    GE (setae):   NaN -> 0   CORRECT (matches oge)
  The defect matrix is mechanically derived in
  evidence/llvm-float01/red/recon-ll-semantics.txt (Observed residue
  section). Defect set for the next ACT: EQ, NE, LT, LE must be
  re-emitted to mask unordered. GT and GE are CONSERVATION
  CONTROLS — the next ACT must verify they remain unchanged on
  finite and unordered inputs. The next ACT should re-emit the
  x86_64 native FCMP lowering using ordered-predicate equivalent
  sequences so == and the four orderings return 0 on NaN and !=
  returns 1 on NaN,
  matching both IEEE-754 and the LLVM LangRef.

P2 (acknowledged, NOT silently fixed):
- `IR_FDIV` / `IR_FREM` on F64 via LLVM backend. Authorized by
  future ACT.
- F32 arithmetic on LLVM backend. Authorized by future ACT.
- F64 vector types. Out of scope of this ACT.

## Next ACT (recommendation)

`ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01` (P0): repair the x86_64
native backend's IR_FCMP lowering for the four broken predicates
(EQ, NE, LT, LE) so they match the LLVM LangRef / IEEE-754
ordered-predicate convention. GT and GE are CONSERVATION CONTROLS
and must NOT change. Principal defect set and conservation controls
are documented in the Residue section above and in
`evidence/llvm-float01/red/recon-ll-semantics.txt`.

`ACT-POLYC-LLVM-FLOAT02` (P2 carry-over): F64 FDIV/FREM, F32
promotion, and F64 vector types via the LLVM backend. Authorized
by future ACTs after the native-backend parity ACT closes.
