// J03: REPL driver for the static-then-public lifetime test.
//
// chunk1: static Foo -> 11
// chunk2: public Foo -> 22
// chunk3: print Foo() (must see 22, not unresolved)
//
// Run with:
//   hcc -repl --install-dir=<prefix> < j03.HC
// Expected stdout: "22"
