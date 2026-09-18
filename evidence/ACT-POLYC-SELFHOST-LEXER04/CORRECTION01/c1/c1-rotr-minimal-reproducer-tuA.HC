static U32 ROTR(U32 x, U32 n)
{
  U32 hi = x >> n;
  U32 lo = (x << (32 - n)) & 0xffffffff;
  return (hi | lo) & 0xffffffff;
}
public U32 A_ROTR(U32 x) { return ROTR(x, 7); }
