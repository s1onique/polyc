// J01: single private function in one JIT chunk.
// Expected: rc = 1 (Foo executes; Entry publishes the result).
// Driving c3-jit-linkage.txt's J01_SINGLE_STATIC entry.
static I64 Foo() { return 1; }
I64 Main() { return Foo(); }
