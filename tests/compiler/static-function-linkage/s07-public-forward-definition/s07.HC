// S07: public forward declaration + public definition.
// Drives c3-s07-forward-public.txt; expected: compiles, _Foo external.
public I64 Foo();
public I64 Foo() { return 1; }
I64 Main() { return Foo(); }
