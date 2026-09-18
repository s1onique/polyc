// S02/TU-A: same static name in two TUs (TU A side).
// Drives c3-s02-two-tu-static.txt; A() returns 11.
static I64 Foo() { return 11; }
I64 A() { return Foo(); }
