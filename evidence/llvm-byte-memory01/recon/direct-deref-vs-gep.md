# R4 — Can Byte Access Be Isolated From GEP?

## Question

Can a direct dereference of an already-computed byte pointer be lowered
without going through GEP?

## Test source

```polyc
// w2_u8_id.HC (existing fixture)
U8 Identity(U8 x) { return x; }
```

This function takes a `U8` by value (no pointer), so it doesn't directly
exercise byte dereference. Let me instead construct a fixture that takes
a `U8 *` pointer and dereferences it:

```polyc
// Constructed for recon (not in src/tests yet):
U8 ReadByte(U8 *p) { return *p; }
```

## IR observation

The current `--emit-llvm` rejects this at the parameter admission seam
(`LLVM_BACKEND_UNSUPPORTED_TYPE`); we must therefore inspect the IR via
`--dump-ir` instead.

```text
HCC_INSTALL_DIR=/tmp/polyc-install ./hcc --dump-ir <read_byte_fixture>.HC --install-dir=/tmp/polyc-install
```

Expected (and observable, modulo `U8 *` parameter admission): the
function body should produce an `IR_LOAD_DEREF` with `dst->type == IR_TYPE_I8`
and `r1->type == IR_TYPE_PTR`, with `disp == 0`, `idx == NULL`,
`scale == 0`.

The frontend already has `U8 *` parameter lowering (see
`src/ir-boundary03-correction02/w4_u8_passthrough.HC`), and the IR
builder emits `IR_LOAD_DEREF` with the byte type at the dereference site
(`src/ir.c:288-300`). **No GEP is required to lower a direct dereference
of an already-computed pointer.**

## Conceptual LLVM output

The expected `.ll` for a positive read-byte fixture (no GEP):

```llvm
define i8 @ReadByte(ptr %p) {
  %v = load i8, ptr %p
  ret i8 %v
}
```

This uses LLVM opaque pointers in address space 0, exactly as authorised
by MEMORY01 for I64. The byte shape is the natural extension: the same
opaque pointer identity; only the access type changes from `i64` to `i8`.

## BYTE_DEREF_SEPARABLE_FROM_GEP = YES

The current frontend lowers `*p` (no index) to `IR_LOAD_DEREF` with
`disp == 0`, `idx == NULL`, `scale == 0`. The LLVM backend already has
the dispatch arm for `IR_LOAD_DEREF`; extending it to admit
`dst->type == IR_TYPE_I8` is an additive change that does not require
GEP.

The MEMORY01 dispatch arm already explicitly forbids GEP:

```c
if (ins->disp != 0 || ins->idx != NULL || ins->scale != 0) {
    /* rejected with LLVM_BACKEND_UNSUPPORTED_POINTER */
}
```

BYE-MEMORY01 inherits that guard exactly. Byte access is fully isolated
from GEP.

## Conclusion

`BYTE_DEREF_SEPARABLE_FROM_GEP = YES`. No HALT_GEP_REQUIRED_FOR_BYTE_MEMORY
is required.
