// J04: REPL driver for the public-then-static lifetime test.
//
// chunk1: public Foo -> 11
// chunk2: static Bar -> 22
// chunk3: print Foo() (must still see 11)
//
// Run with:
//   hcc -repl --install-dir=<prefix> < j04.HC
// Expected stdout: "11"
