/* RED-BYTE-4: U8 pointer read is currently rejected. Even if the
 * pointer parameter were admitted, the IR_LOAD_DEREF dispatch arm
 * at src/llvm-backend.c:1775-1785 only accepts dst->type ==
 * IR_TYPE_I64 (it explicitly says "MEMORY01 only supports I64
 * loads"). The IR for `*p` is `load* %t4 i8 tmp, %p1 ptr param`
 * with dst->type = IR_TYPE_I8.
 *
 * Expected behavior under BYTE-MEMORY01 §24: this should compile
 * to `load i8, ptr %p`.
 *
 * Source semantically equivalent to:
 *   U8 ReadByte(U8 *p) { return *p; }
 *
 * This fixture is the canonical reachability probe for the byte
 * load seam. Without the byte admission, this fixture fails at
 * the parameter-admission seam (LLVM_BACKEND_UNSUPPORTED_TYPE).
 * Once admission is widened, it reaches IR_LOAD_DEREF and
 * requires the byte-shape handling.
 */
U8 ReadByte(U8 *p)
{
    return *p;
}
