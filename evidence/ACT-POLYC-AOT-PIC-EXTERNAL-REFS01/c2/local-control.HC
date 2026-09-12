/*
 * ACT-POLYC-AOT-PIC-EXTERNAL-REFS01 C1 / §3.3 same-image control.
 *
 * Structurally equivalent to ext-consumer.HC, but the callee is
 * defined in the same translation unit. The address materialises via
 * IR_LEA -> aarch64GlobalAddr for a local symbol; this should compile,
 * link, and run cleanly with no dylib dependency.
 */
I64 LocalAdd1(I64 x) {
    return x + 1;
}

I64 Main() {
    I64 (*fp)(I64) = &LocalAdd1;
    I64 r = fp(41);
    if (r != 42) return 1;
    return 0;
}
