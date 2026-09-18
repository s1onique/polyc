// S05: same-TU duplicate static definition.
// Drives c3-s05-same-tu-duplicate.txt; expected: REJECTED at
// assembler level with "symbol '_Foo' is already defined".
static I64 Foo() { return 1; }
static I64 Foo() { return 2; }
I64 Main() { return Foo(); }
