// c1-rotr-minimal-reproducer.HC
// Two-translation-unit reproducer for the static-function visibility defect.
// Invoke:
//   cd /tmp/repro && cp <repo>/c1-rotr-minimal-reproducer-tuA.HC .
//   cp <repo>/c1-rotr-minimal-reproducer-tuB.HC .
//   hcc --install-dir=<repo>/build/test-prefix -c -o tuA.o tuA.HC
//   hcc --install-dir=<repo>/build/test-prefix -c -o tuB.o tuB.HC
// Result WITHOUT fix:
//   error: Cannot redefine function: ROTR
// Result WITH fix:
//   Two .o files; linker accepts them; no global symbol collision.
