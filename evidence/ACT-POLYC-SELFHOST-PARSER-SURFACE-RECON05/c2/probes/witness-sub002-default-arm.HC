// THE SUB-002 CAUSAL WITNESS.
//
// A switch with a DEFAULT arm whose body contains a nested switch with
// its own default arm.  This is the shape that reaches the
// parseDefaultStatement decision with a non-trivial statement kind.
//
// The witness prints the observable result so that the PRISTINE and the
// MUTANT compilers can be compared byte-for-byte.

I64 f(I64 x)
{
  I64 r = 0;
  switch (x) {
    case 1:
      r = 1;
      break;
    case 2:
      r = 2;
      break;
    default:
      switch (x + 100) {
        case 7:
          r = 7;
          break;
        default:
          r = 99;
          break;
      }
      break;
  }
  return r;
}

I64 g(I64 x)
{
  I64 r = 0;
  switch (x) {
    case 5:
      r = 50;
      break;
    default:
      r = 60;
      break;
  }
  return r;
}

I64 main()
{
  I64 v = f(1) * 1000 + f(2) * 100 + f(3) * 10 + g(5) + g(6);
  "WITNESS_OUTPUT=%d\n", v;
  return 0;
}
