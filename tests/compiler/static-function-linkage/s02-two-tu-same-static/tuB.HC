// S02/TU-B: same static name in two TUs (TU B side).
// Drives c3-s02-two-tu-static.txt; B() returns 22.
static I64 Foo() { return 22; }
I64 B() { return Foo(); }
