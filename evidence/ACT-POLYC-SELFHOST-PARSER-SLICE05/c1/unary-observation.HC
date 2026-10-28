// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/unary-observation.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C1 -- the FROZEN production-causal
// observation program.
//
// WHY A REAL PROGRAM, NOT A DIRECT CALL
// =====================================
//
// The witness must show that the PolyC component's decision REACHES
// the compiled program's behaviour.  Calling
// BootstrapAstUnaryOpFromToken directly would only show that the
// function returns a value; it would NOT show that the production
// parser consults it.
//
// This program therefore contains ORDINARY UNARY EXPRESSIONS.  The
// production parser must classify the unary '-' token as
// AST_UN_OP_MINUS for `-x` to evaluate to -7, and as AST_UN_OP_PLUS
// for `+x` to evaluate to +7.
//
// THE OBSERVATION CHANNEL
// =======================
//
// The result is written to STDOUT as a plain decimal number.  The
// observation does NOT rely on a process exit code: on many hosts an
// exit status truncates a negative value, and the mutation's whole
// point is to change a NEGATIVE observation into a POSITIVE one.
//
// THE FROZEN PRISTINE OUTPUT
// ==========================
//
//   UNARY_MINUS_RESULT=-7
//   UNARY_PLUS_RESULT=7
//   UNARY_LOG_NOT_RESULT=0
//   UNARY_BIT_NOT_RESULT=-8
//
// Under the frozen mutation (token '-' maps to AST_UN_OP_PLUS instead
// of AST_UN_OP_MINUS), the FIRST line becomes UNARY_MINUS_RESULT=7,
// because `-x` would then be parsed as `+(x)`.  The other three lines
// are unaffected, which is itself informative: the mutation is
// SPECIFIC, not a blanket corruption of the unary path.
//
// F-POLYC-TOOLS: this is a PolyC program.  No shell glue.

I32 Main(I32 argc, U8 **argv)
{
  I64 x = 7;
  I64 y = -x;
  "UNARY_MINUS_RESULT=%lld\n", y;
  I64 z = +x;
  "UNARY_PLUS_RESULT=%lld\n", z;
  I64 n = !x;
  "UNARY_LOG_NOT_RESULT=%lld\n", n;
  I64 b = ~x;
  "UNARY_BIT_NOT_RESULT=%lld\n", b;
  return 0;
}
