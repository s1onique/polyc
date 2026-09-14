// tools/quality/lexer07-mutation-stub.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 C2 IMPL.
// AC05 mutation test: stub-generator that returns rc=0
// but emits missing/incomplete/false evidence.
// The independent verifier (lexer07-proof-verify.HC)
// MUST reject this stub with non-zero exit.
// This binary is a test harness ONLY; it is never used
// as the actual corpus generator.
//
// How it is exercised: `make lexer07-mutation-stub` then
// the test driver renames build/lexer07-broad-corpus-4-stage
// to .bak and copies this binary in its place, then runs
// the test pipeline. The verifier rejects because the
// stub's evidence (empty corpus-matrix.tsv, missing
// corpus-object-provenance.tsv) does not match the
// AC02 snapshot.

#include "../../src/holyc-lib/memory_defs.HH"

I32 Main(I32 argc, U8 **argv)
{
  "MUTATION_STUB ok rc=0 evidence=NONE\n";
  return 0;
}
