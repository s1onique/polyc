// tools/quality/parser-padding-mutation-m3.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
// MUTATION M3 -- remainder returned directly (instead of size - remainder).

I64 BootstrapCalcPadding(I64 offset, I64 size)
{
  if (size == 0) return 0;
  I64 rem = offset % size;
  if (rem == 0) return 0;
  return rem;  // DEFECT: should return size - rem.
}
