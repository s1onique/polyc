// S04/TU-A: static Foo coexisting with an external Foo in TU B.
static I64 Foo() { return 11; }
I64 A() { return Foo(); }
