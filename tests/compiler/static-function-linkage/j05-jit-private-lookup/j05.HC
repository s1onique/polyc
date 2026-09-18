// J05: REPL driver proving a private function is not globally
// exposed via hccJitLookup.
//
// After the static helper Foo is compiled in chunk1, the only
// way to recover its address is via a static-aware lookup that
// filters names against private_fns. The REPL's `replFindFn`
// walks cc->global_env, not jit->symbols; this fixture simply
// documents that the per-chunk scope is intact.
//
// Run with:
//   hcc -repl --install-dir=<prefix> < j05.HC
// Expected: chunk1 compiles; chunk2 can NOT reach _Foo even
// though it was emitted.
