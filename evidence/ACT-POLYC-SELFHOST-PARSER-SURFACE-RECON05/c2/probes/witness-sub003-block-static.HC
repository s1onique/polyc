// THE SUB-003 CAUSAL WITNESS.
//
// A `static` declaration INSIDE a compound block.  The static is a
// GLOBAL variable (AST_GVAR), so the SUB-003 decision at
// src/parser.c:2049 SKIPS it instead of appending it to the block's
// statement list.
//
// The witness exercises the block, so a wrong block statement list
// changes the observable output.

I64 g_calls = 0;

I64 Helper(I64 x)
{
  g_calls = g_calls + 1;
  return x * 2;
}

I64 f(I64 n)
{
  I64 r = 0;
  {
    static I64 hidden = 7;
    r = Helper(n) + hidden;
  }
  return r;
}

I64 main()
{
  I64 a = f(3);
  I64 b = f(4);
  "WITNESS_OUTPUT=%d %d %d\n", a, b, g_calls;
  return 0;
}
