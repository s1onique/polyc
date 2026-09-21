// tools/quality/parser-padding-mutation-m4.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
// MUTATION M4 -- boolean classifier returned as I64.

I64 BootstrapCalcPadding(I64 offset, I64 size)
{
  if (size == 0) return 0;
  // DEFECT: returns boolean (0 or 1) instead of pad-byte count.
  return offset % size == 0;
}
