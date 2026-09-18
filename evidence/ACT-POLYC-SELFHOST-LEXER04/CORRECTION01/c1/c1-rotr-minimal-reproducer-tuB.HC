static U32 ROTR(U32 x, U32 n)
{
  U32 hi = x >> n;
  U32 lo = (x << (32 - n)) & 0xffffffff;
  return (hi | lo) & 0xffffffff;
}
public U32 B_ROTR(U32 x) { return ROTR(x, 13); }
public U0 Main()
{
  "A_ROTR(0xdeadbeef)=%d B_ROTR(0xdeadbeef)=%d\n", A_ROTR(0xdeadbeef), B_ROTR(0xdeadbeef);
}
