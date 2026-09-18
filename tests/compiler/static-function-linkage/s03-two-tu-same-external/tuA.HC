// S03/TU-A: external Foo (no static).
// Drives c3-s03-two-tu-external.txt; expected ld -r to FAIL with
// "duplicate symbol '_Foo'" so the static fix does not accidentally
// privatize normal external functions.
I64 Foo() { return 11; }
