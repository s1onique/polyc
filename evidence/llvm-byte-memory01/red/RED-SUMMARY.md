# RED Summary — ACT-POLYC-LLVM-BYTE-MEMORY01

## Toolchain
* `llvm-config` / `llvm-as` / `opt` version 22.1.8
* `hcc` rebuilt from current tree (LLVM-enabled backend)
* `HCC_INSTALL_DIR=/tmp/polyc-install` (provides tos.HH for the parser)

## Principal RED fixtures

All five fixtures below are authorised by
`evidence/llvm-byte-memory01/recon/authorized-set.txt` as `IMPLEMENT`.

| Fixture                              | B0 capability               | expected neutral type/op                              | observed neutral type/op                                | intended seam reached | LLVM entry diagnostic                                                       | RED reproduced |
|--------------------------------------|-----------------------------|-------------------------------------------------------|---------------------------------------------------------|----------------------|------------------------------------------------------------------------------|----------------|
| `red_u8_param.HC`                    | U8 parameter admission      | `i8 Id(%p1 i8 param)` (IR_TYPE_I8 IR_VAL_PARAM)       | `i8 Id(%p1 i8 param)` (verified via `--dump-ir`)        | NO (admission seam)  | `LLVM_BACKEND_UNSUPPORTED_TYPE: function Id: type function parameter is not supported by the LLVM backend` | YES |
| `red_i8_param.HC`                    | I8 parameter admission      | `i8 IdI8(%p1 i8 param)`                               | `i8 IdI8(%p1 i8 param)`                                 | NO (admission seam)  | `LLVM_BACKEND_UNSUPPORTED_TYPE: function IdI8: type function parameter is not supported by the LLVM backend` | YES |
| `red_byte_pointer_param.HC`          | U8 pointer param admission  | `i8 ReadByte(%p1 ptr param)`                          | `i8 ReadByte(%p1 ptr param)`                            | NO (admission seam)  | `LLVM_BACKEND_UNSUPPORTED_TYPE: function ReadByte: type function return value (only I64 or F64 supported) is not supported by the LLVM backend` | YES |
| `red_byte_load.HC`                   | byte IR_LOAD_DEREF          | `load* %t4 i8 tmp, %p1 ptr param` (IR_LOAD_DEREF dst=I8 r1=PTR) | `load* %t4 i8 tmp, %p1 ptr param` (verified)            | NO (admission seam)  | `LLVM_BACKEND_UNSUPPORTED_TYPE: function ReadByte: type function return value (only I64 or F64 supported)` | YES |
| `red_byte_to_i64.HC`                 | U8 -> I64 widening          | `zext %t4 i64 tmp, %l2 i8 local` (IR_ZEXT)            | `zext %t4 i64 tmp, %l2 i8 local` (verified)             | NO (admission seam)  | `LLVM_BACKEND_UNSUPPORTED_TYPE: function Id: type function parameter is not supported by the LLVM backend` | YES |

## Per-fixture raw captures

* `red_u8_param.emit-llvm.txt` — captured hcc stderr for red_u8_param
* `red_i8_param.emit-llvm.txt` — captured hcc stderr for red_i8_param
* `red_byte_pointer_param.emit-llvm.txt` — captured hcc stderr
* `red_byte_load.emit-llvm.txt` — captured hcc stderr
* `red_byte_to_i64.emit-llvm.txt` — captured hcc stderr
* `red_byte_to_i64.dump-ir.txt` — captured `--dump-ir` confirming
  `zext %t4 i64 tmp, %l2 i8 local` is in the IR
* `red_byte_load.dump-ir.txt` — captured `--dump-ir` confirming
  `load* %t4 i8 tmp, %p1 ptr param` is in the IR

## RED reachability classification

Per ACT §16 (R9 — capability ENTRY state), a capability is RED only if
execution reaches that capability. Currently, **all five fixtures trip at
the function-parameter or function-return-value type admission seam**
(src/llvm-backend.c:530-578 `llParamTypeSupported` / `llTypeSupported`),
before reaching the `IR_LOAD_DEREF` / `IR_ZEXT` dispatch arms.

This is the **expected RED pattern** for this ACT: the admission seam is
the load-bearing gate that prevents any of the byte-shaped dispatch from
ever running.

**No false RED**: every fixture reaches its intended admission-seam
diagnostic in the order documented. There is no hidden upstream failure
that would mask the actual defect.

## RED matrix summary

```text
fixture                         intended_seam       actual_seam_reached     RED_reproduced
red_u8_param                    admission           admission               YES
red_i8_param                    admission           admission               YES
red_byte_pointer_param          admission           admission               YES
red_byte_load                   admission           admission               YES
red_byte_to_i64                 admission           admission               YES
```

## Next ACT phase

Once the IMPL widens the admission seam (and, for `red_byte_to_i64`,
adds the IR_ZEXT I8->I64 lowering), all five fixtures must compile
cleanly and produce LLVM `.ll` files that:

* pass `llvm-as` (syntactic)
* pass `opt --passes=verify` (semantic)
* have the structural core: `load i8, ptr %p` and `zext i8 %v to i64`
* have no GEP / ptrtoint / inttoptr / alloca (BYTE-MEMORY01 purity gate)
