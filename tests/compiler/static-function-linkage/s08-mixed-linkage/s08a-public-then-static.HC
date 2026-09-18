// S08a: public forward decl then static definition.
// Drives c3-s08-mixed-linkage.txt; expected: _Foo non-external
// (the static upgrade wins, per the parser branch at parser.c:2240).
public I64 Foo();
static I64 Foo() { return 1; }
