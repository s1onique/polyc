// s09-legacy-x86-static.HC
//
// Exercises the legacy x86 backend (--use-legacy-x86) under the
// static-function-linkage contract. Defines one static function
// and one public function in the same TU and verifies via nm -m
// that the static symbol is non-external and the public symbol
// is external.

static I64 StaticFn(I64 x) { return x * 11; }
public I64 PublicFn(I64 x) { return x * 22; }

I64 main(I64 argc, U8 **argv) {
    return StaticFn(argc) + PublicFn(argc);
}
