// S06: static forward declaration + static definition.
// Drives c3-s06-forward-static.txt; expected: compiles, _Foo non-external.
static I64 Foo();
static I64 Foo() { return 1; }
I64 Main() { return Foo(); }
