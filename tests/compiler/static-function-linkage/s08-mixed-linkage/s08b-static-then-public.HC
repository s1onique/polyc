// S08b: static forward decl then public definition.
// Drives c3-s08-mixed-linkage.txt; expected: _Foo external
// (the public upgrade wins, per parser.c:2240).
static I64 Foo();
public I64 Foo() { return 1; }
