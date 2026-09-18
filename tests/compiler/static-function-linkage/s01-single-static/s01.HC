// S01: single static function callable from public wrapper.
// Drives c3-s01-single-static.txt:
//   - hcc -c emits _Foo as non-external (local/t).
//   - hcc -o links; program returns 1.
static I64 Foo() { return 1; }
I64 Main() { return Foo(); }
