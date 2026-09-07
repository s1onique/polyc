# R1 RED: `IrRegPool` consultation inside the IR lowering path

**Status (pre-ACT): RED**
**Demonstrated by:**
- `evidence/boundary/red/red_r1_param_loc_native.txt` (with fake pool injected — params carry `loc=reg rdi` / `loc=reg rsi`)
- `evidence/boundary/red/red_r1_param_loc_neutral.txt` (no pool — params carry no `loc=`)
- `src/ir.c:2799-3024` (the offending code)

## The offending block

`irLowerFunction` (`src/ir.c:2768`) begins with a **target-neutral typed-SSA** prologue (front-end SSA, typed values, CFG). Lines 2799–3024 are the parameter-arrival section. This is where the contamination lives.

| line | what happens |
|------|--------------|
| 2799 | `IrRegPool *pool = irRegPoolGet();` — pool is consulted *during lowering*. |
| 2812 | `if (has_hidden_out_ptr && !(pool && pool->sret_reg)) int_arg_idx = 1;` — ABI decision. |
| 2823 | `int apple_aarch64_va = pool && pool->variadic_on_stack;` — target-specific decision. |
| 2830-2832 | `argc_arrive->loc.kind = IR_LOC_REG; argc_arrive->loc.as.reg = vecGet(...pool->int_arg_regs, int_arg_idx);` — physical register identity stamped into the IR's neutral representation. |
| 2871-2916 | AArch64 vs x86-64 ABI classification via `astAapcsClassify` / `astSysvClassify` — target-aware. |
| 2921-2936 | ABI arg-register lookup from `pool->int_arg_regs[i]` / `pool->float_arg_regs[i]` — physical register identity. |
| 2974-2976, 2984-2986 | `arrive->loc.kind = IR_LOC_REG; arrive->loc.as.reg = abi_reg;` — physical register identity stamped into the IR. |
| 3007-3013 | `out_arrive->loc.kind = IR_LOC_REG; out_arrive->loc.as.reg = pool->sret_reg / pool->int_arg_regs[0]` — physical register identity for the hidden struct-return out-pointer. |

**Five `loc.kind = IR_LOC_REG` assignment statements** are inside the generic IR-lowering path. They are guarded only by `if (pool)`, meaning once any backend has run (which sets the global pool via `irRegPoolSet` in `src/x86_64.c:114`, `src/aarch64.c:119`, `src/x86_64-jit.c:1675`, `src/aarch64-jit.c:1800`), every subsequent `irLowerFunction` call stamps physical register names into the IR.

## Why this matters for an LLVM-style neutral consumer

A backend that wants to consume the IR without knowing PolyC's native ABI must be able to read the function's parameters in source-order with their semantic types and identities, without first parsing `AoStr*` register names like `"rdi"`, `"x0"`, `"x8"`, etc.

The current IR provides both views at once:
- semantic view: `func->params` order, types, by-value struct types
- physical view: `arrive->loc.as.reg` (the AoStr from the pool)

The physical view is *embedded in the same struct* as the semantic view. There is no way to consume the IR without examining the physical-view field, because that's how the codegen's spill-folding forwarding pass (`irOptPinResultReg`, `src/ir-optimise.c:1079`) decides whether to keep a value live in the ABI register or fall back to a stack slot.

## The fix in outline (Commit 2)

1. `irLowerFunction` produces arrive-values with `loc.kind = IR_LOC_NONE` and an `extra.param_idx` set to the scalar-in-order ABI position (so neutral consumers can still recover call-site argument order).
2. A new function `irAssignAbiParamLocations(fn, pool)` (called from `irFunctionPrepForCodeGen` when a pool is present, only on the native path) walks the IR and stamps physical-register locations.
3. The neutral dump path (`irDump` without a pool) then shows IR where no param carries a physical register — proving the boundary.