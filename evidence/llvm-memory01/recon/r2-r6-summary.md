# MEMORY01 Phase 0 Recon Summary

Authoritative source: real PolyC compiler + neutral IR + LLVM 22 backend.

## R1 - source-level pointer spelling

Real existing fixture (src/tests/llvm-spike/neg_pointer.HC):

```c
I64 Deref(I64 *p)
{
    return *p;
}
```

PolyC uses C-style `I64 *p` for pointer-to-I64 parameter and `*p` for
pointer-dereference read. Writes via `*p = x;` are expressible via the
existing parser.

## R2 - neutral IR type representation

For `I64 *p`:
- IR value kind: IR_VAL_PARAM
- IR value type: IR_TYPE_PTR
- size: 8 bytes (pointer width on x86_64/aarch64)
- param_kind: IR_PARAM_KIND_NORMAL (no special ABI classification)
- pinned_reg: NULL
- No address-space metadata; PolyC IR has no address-space concept.
- Pointee type is NOT carried on the IR_TYPE_PTR value itself; it is
  inferred from the IR_LOAD_DEREF/IR_STORE_DEREF access instruction's
  dst->type (for load) or r1->type (for store).

## R3 - load dereference shape

`--dump-ir` for `Deref(I64 *p) { return *p; }`:

```text
i64 Deref(%p1 ptr param) {
  ...
    load*    %t4 i64 tmp, %p1 ptr param  ; line 3
  ...
}
```

After basic optimisations the `load*` directly reads from the parameter:
- IR op: IR_LOAD_DEREF
- dst: IR_VAL_TMP, type=IR_TYPE_I64, size=8
- r1: IR_VAL_PARAM (`p1`), kind=IR_VAL_PARAM, type=IR_TYPE_PTR
- r2: NULL
- disp: 0
- idx: NULL, scale: 0
- extra.cmp_kind: unused

The textual dump operator `load*` corresponds to IR_LOAD_DEREF (the
`*` distinguishes from IR_LOAD which is local-slot-based).

## R4 - store dereference shape

A real source fixture `Store(I64 *p, I64 x) { *p = x; }` lowers to:

```text
i64 Store(%p1 ptr param, %x2 i64 param) {
  bb1:
    store*   %p1 ptr param, %x2 i64 param  ; line 1
    jmp      bb2
  bb2:
    ret      0 i64 const int  ; line 2
}
```

- IR op: IR_STORE_DEREF
- dst: IR_VAL_PARAM (`p1`), kind=IR_VAL_PARAM, type=IR_TYPE_PTR
- r1: IR_VAL_PARAM (`x2`), kind=IR_VAL_PARAM, type=IR_TYPE_I64
- r2: NULL
- disp: 0, idx: NULL, scale: 0

(Captured below via --dump-ir on the fixture file.)

## R5 - pointee-type authority

**Answer: B** (operand/result type provides a unique access type).

For `IR_LOAD_DEREF`: `dst->type` is the access type. The compiler
guarantees the load's destination IR type equals the pointee type
(I64 for `*p` of type `I64 *`).

For `IR_STORE_DEREF`: `r1->type` is the access type. The value being
stored carries its own type and must match pointee.

The compiler already enforces I64 promotion/narrowing via
`irPromoteNarrowInt`/`irNarrowToTargetWidth`, so by the time the
LLVM backend sees IR_LOAD_DEREF/IR_STORE_DEREF, dst->type (for load)
or r1->type (for store) IS the canonical pointee type. No source-AST
smuggling required.

## R6 - parameter lowering seam

Current code in `src/llvm-backend.c:517-554`:

```c
for (u64 p = 0; p < fn->params->size; ++p) {
    IrValue *pv = vecGet(IrValue*, fn->params, p);
    if (!pv || !llTypeSupported(pv->type)) {
        llErrUnsupportedType(pv, fn, "function parameter");
        ...
    }
}
...
for (u32 p = 0; p < np; ++p) {
    param_tys[p] = i64;          // <-- forces all params to i64
}
LLVMTypeRef fty = LLVMFunctionType(i64, param_tys, (unsigned)np, 0);
LLVMAddFunction(lc->mod, fn->name->data, fty);
```

And in `llBindParams`:
```c
LLVMValueRef lv = LLVMGetParam(lc->cur_fn_value, (unsigned)p);
llvmSet(&lc->values, irVarId(pv), lv);
```

The LLVMValueRef returned by `LLVMGetParam` is **already** an LLVM
`ptr` value when the function type signature uses opaque `ptr`.
No `alloca`, no `store-to-local`, no `load-from-local`, no
`inttoptr`, no `ptrtoint` is required. The only change needed is to
map `IR_TYPE_PTR` to opaque `ptr` in the function signature.

## Conclusion

All six recon questions resolve to A/B/C (or trivially yes) for the
authorized MEMORY01 subset:

- R1: source syntax already exists.
- R2: IR_TYPE_PTR + IR_VAL_PARAM representation is in place.
- R3/R4: real source already emits IR_LOAD_DEREF / IR_STORE_DEREF.
- R5: pointee type is derivable from IR_LOAD_DEREF/IR_STORE_DEREF
  operand/result type. Answer: B.
- R6: parameter lowering seam is direct; no forbidden machinery needed.

No HALT condition from Phase 0 recon. RED phase authorized.
