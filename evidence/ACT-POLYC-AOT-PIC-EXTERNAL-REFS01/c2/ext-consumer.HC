/*
 * ACT-POLYC-AOT-PIC-EXTERNAL-REFS01 C1 / §3.2 PolyC AOT consumer.
 *
 * Smallest PolyC source that references an external function and
 * observes its result. The function pointer is taken (lea of a global
 * with IR_VAL_FLAG_FUNC) and called indirectly so the codegen exercises
 * the IR_LEA -> aarch64GlobalAddr path.
 *
 * External declaration is the binding; the actual definition lives in
 * libpolyc-extref.dylib. No libtos linkage is required for this RED.
 */
extern "c" I64 PolycExtAdd1(I64 x);

I64 Main() {
    I64 (*fp)(I64) = &PolycExtAdd1;
    I64 r = fp(41);
    if (r != 42) return 1;
    return 0;
}
