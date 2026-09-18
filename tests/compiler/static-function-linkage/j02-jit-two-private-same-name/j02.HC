// J02: two private functions of the same name in independent
// compilation units (driven by separate hcc -c invocations).
// Each TU compiles to its own .o; ld -r combines without
// duplicate-symbol error.
//
// Note: a single .HC file cannot host two identically-spelled
// globals even with the static fix; the parser upgrade branch
// would treat them as the same node. S02 covers the multi-TU
// version which is the canonical isolation witness.

static I64 Foo() { return 11; }
I64 A() { return Foo(); }
