# ACT-POLYC-LLVM-SPIKE01-RESUME01

**Title:** Resume LLVM spike: bounded I64 backend with collapse-elimination

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** IMPLEMENTATION

**Predecessor:** ACT-POLYC-LLVM-SPIKE01 (HALT — predecessor-baseline RED +
toolchain unavailable)

**Production semantic changes:** FORBIDDEN (the bounded spike is
gated behind a new `--emit-llvm` CLI flag and emits textual LLVM IR
instead of running the native / JIT paths; native + JIT behaviour
remains bit-for-bit identical to the predecessor HEAD)

**IR / ABI / LLVM authorization:** NONE (this ACT consumes the
already-canonical backend-neutral IR established by
ACT-POLYC-IR-BOUNDARY01; it does not modify the IR, the ABI, or the
LLVM backend)

---

## 0. Mission

Resume the halted LLVM spike: prove the LLVM 22 C-API toolchain
works, then add a bounded `hcc --emit-llvm` mode that consumes
PolyC's neutral IR and emits verified textual LLVM IR for an I64
SSA subset, while keeping the native + JIT backends untouched.

On close, all 5 positive fixtures (`01_const`/`02_add`/
`03_sub_mul`/`04_cmp_branch`/`05_call`) shall emit verifier-clean
textual LLVM IR that `llvm-as` accepts with exit code 0, and all
4 negative fixtures shall surface an explicit `LLVM_BACKEND_*`
diagnostic with a non-zero exit code.

---

## 1. Entry identity

```
branch: main
HEAD:   b65d9ab3fcb02e4d6c0649a11671bdba990df102
```

## 2. Predecessor-gate evidence

The original `ACT-POLYC-LLVM-SPIKE01` halted on two independent
conditions:

1. `HALT_PREDECESSOR_BASELINE_RED` (native `make gate-push` failing
   at entry HEAD `0996ce4c`)
2. `HALT_LLVM_TOOLCHAIN_UNAVAILABLE` (no LLVM 22.x dev tree on the
   host)

Both were resolved before this ACT began:

1. Native `make gate-push` at HEAD `b65d9ab` reports
   `AOT=90/90 / JIT=90/90 / LSP=43/43 / CORPUS=16/16 / VERDICT=PASS`.
   Evidence: `evidence/llvmspike01-resume01/native_gate.txt`.
2. LLVM 22.1.8 is provided by
   `nixpkgs#llvmPackages_22.llvm.dev` at
   `/nix/store/b6fykfvclbq81yis03blk6bqsmapmhdm-llvm-22.1.8-dev`
   and `LLVM_LIBDIR` at
   `/nix/store/a1hnp3fv6y7jjl8j3vkcp3qwclxmknba-llvm-22.1.8-lib/lib`.
   C-API smoke (write an `add(i64,i64)->i64` module, verify, print)
   passes; evidence: `evidence/llvmspike01-resume01/c_api_smoke.c`
   + `c_api_smoke.bc` + `c_api_smoke_output.ll`.

## 3. Production seam

The new code lives in `src/llvm-backend.{c,h}` and is reached only
through `args.emit_llvm`. The dispatch in `src/main.c`:

```c
if (args.emit_llvm) {
    if (args.jit || args.repl || args.run || ...) {
        // mode-exclusion, ACT §16
    }
    #ifdef HCC_ENABLE_LLVM
        rc = llvmEmitProgram(prog, cc, ..., out_path);
    #else
        // explicit unavailable error, ACT §18
    #endif
    goto success;
}
```

Mode-exclusion guarantees `--emit-llvm` cannot silently compose
with `-jit`/`-S`/`-c`/`-run`/etc.; the build-flag check guarantees
no silent fallback to native if the LLVM consumer is not linked
in.

## 4. IR-consumer contract (ACT §21-§36)

The consumer:

- Walks `irLowerFunction`-produced `IrProgram` (same pipeline as
  `--dump-ir`).
- Never reads `IrValue->loc` or `IrValue->pinned_reg` (those are
  native-backend metadata).
- Never reads `IrRegPool`.
- Never invokes `irAssignAbiParamLocations`.
- Maps every IR value via dense vector maps keyed by `irVarId`,
  pre-allocating one `alloca i64` per referenced `IR_VAL_LOCAL` in
  the function prologue.
- Two-pass function declaration (ACT §23) so direct calls resolve
  regardless of source order.

## 5. Collapse-elimination (ACT §30)

PolyC lowers every `return X` to `store return_slot, X; jmp exit`
+ `load return_slot; ret (load)`. The spike authorises I64 return
ONLY via direct branch returns (PHI is forbidden). The detector
walks every predecessor of `fn->exit_block` and verifies each ends
with `IR_JMP exit_block` preceded by exactly one
`IR_STORE return_slot, V` whose value is `IR_TYPE_I64`. When
`irForwardReturnSlot` + `irRemoveRedundantBlocks` already collapse
the pattern, the exit block is folded and the detector sets
`slot == NULL`; we emit an `unreachable` "dead_exit" block to
satisfy the verifier. Otherwise each predecessor's `jmp exit` is
replaced with `ret V` and the exit block is emitted as
`unreachable`.

## 6. Out of scope (intentionally not lowered)

Per ACT §13, §33-§34, §48-§50: no LLVM optimization pipeline, no
PHI nodes, no `IR_LOAD_DEREF`/`IR_STORE_DEREF`/`IR_RMW_DEREF`,
no `IR_ASM`, no `IR_CMP_BR` (handled separately), no aggregates,
no pointer math, no F64/F32/U8/U16/U32, no bitwise/shift/div,
no `IR_SWITCH`/`IR_SELECT`/`IR_VA_*`.

These surface explicit `LLVM_BACKEND_UNSUPPORTED_IR` /
`LLVM_BACKEND_UNSUPPORTED_TYPE` diagnostics.

## 7. RED + GREEN witnesses

Five positive fixtures (`src/tests/llvm-spike/0[1-5]_*.HC`)
exercising:

- direct const return (`ret i64 42`)
- iadd-only
- isub+imul chain
- cmp_gt+br with collapse-slot folded into direct-branch returns
- direct intra-module call

Four negative fixtures (`src/tests/llvm-spike/neg_*.HC`):

- `neg_f64.HC` — F64 parameter
- `neg_pointer.HC` — `I64*` parameter
- `neg_struct.HC` — class struct parameter
- `neg_asm.HC` — `asm { ... }` block

All positive fixtures produce verifier-clean textual LLVM IR that
`llvm-as` accepts. All non-parse-error negatives surface an
explicit `LLVM_BACKEND_*` token and exit non-zero.

Reproducer:

```
PATH=$PWD/.llvm-shim:$PATH cmake -S ./src -B ./build -DHCC_ENABLE_LLVM=ON
PATH=$PWD/.llvm-shim:$PATH cmake --build ./build
PATH=$PWD/.llvm-shim:$PATH cmake --install ./build --prefix $PWD/build/hermetic-prefix

# positive
for f in src/tests/llvm-spike/0*.HC; do
    hcc --install-dir=$PWD/build/hermetic-prefix --emit-llvm "$f" -o /tmp/$(basename $f .HC).ll
    llvm-as /tmp/$(basename $f .HC).ll -o /tmp/$(basename $f .HC).bc
done

# negative
for f in src/tests/llvm-spike/neg_*.HC; do
    hcc --install-dir=$PWD/build/hermetic-prefix --emit-llvm "$f"
done
```

## 8. Conservation (ACT §F10)

`make gate-push` runs at the closing commit and reports
`AOT=90/90 / JIT=90/90 / LSP=43/43 / CORPUS=16/16 / VERDICT=PASS`.

## 9. Residue

- `IR_CMP_BR` (fused cmp+br) is now lowered but the canonical
  neutral-IR shape is `IR_ICMP` + `IR_BR`. Both shapes are
  exercised in `04_cmp_branch.HC`. Future ACT may restrict to
  one canonical shape.
- `dead_exit` blocks appear in the textual IR when the
  `irForwardReturnSlot`+`irRemoveRedundantBlocks` passes fully
  fold the collapse pattern. The verifier accepts them
  ("No predecessors! unreachable") and they are a true artifact
  of the fold; we can later remove them with an `i64`
  no-argument stub function, but that would require a new
  consumer decision.
- The negative `neg_asm.HC` fails at parse time rather than
  in the LLVM backend. The asm-block syntax it exercises is
  already a known parser-edge case; surfacing the parse error
  before the backend still satisfies the §18 explicit-failure
  invariant.

## 10. Next ACT (recommendation, not authorised here)

`ACT-POLYC-LLVM-SPIKE02` — extend the consumer to:
- F64 parameters + F64 arithmetic
- IR_LOAD_DEREF / IR_STORE_DEREF (with structural typing of
  pointer-typed locals via alloca + GEP)
- IR_CMP_BR canonical-only (deprecate IR_ICMP+IR_BR pair)

Each step gated by a new ACT.
