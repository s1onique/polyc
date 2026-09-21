// tools/quality/parser-padding-mutation-m2.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
// MUTATION M2 -- aligned case wrong (returns `size` instead of 0).

I64 BootstrapCalcPadding(I64 offset, I64 size)
{
  if (size == 0) return 0;
  I64 rem = offset % size;
  if (rem == 0) return size;  // DEFECT: should return 0 for aligned.
  return size - rem;
}
