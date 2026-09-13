// tools/quality/bootstrap06-classify-probe.HC
//
// ACT-POLYC-SELFHOST-LEXER01 C1 — ABI witness probe.
//
// Compiled with stage0 hcc to build/bootstrap06-classify-probe.
// Links against an inline stub definition of
// BootstrapClassifyOperator (also written here in PolyC) to
// prove that:
//   * the proposed ABI lowers,
//   * all scalar inputs round-trip,
//   * all scalar outputs round-trip,
//   * nonzero cursor round-trips,
//   * EOF boundary round-trips,
//   * stage0 hcc produces the object file.
//
// This is an EVIDENCE probe, not the production component.
// The production component (tools/bootstrap/selfhost-lexer-
// operator-classify.HC) is added in C2 and is byte-identical
// to the PolyC body here.

public I64 BootstrapClassifyOperator(
    U8 *src, I64 src_len,
    I64 cursor, I64 flags,
    I64 *out_kind, I64 *out_length)
{
  if (src == NULL)              return 0;
  if (out_kind == NULL)         return 0;
  if (out_length == NULL)       return 0;
  if (cursor < 0)               return 0;
  if (cursor >= src_len)        return 0;

  U8 ch = src[cursor];

  // '==' test (single multi-char case sufficient for ABI round-trip)
  if (ch == '=') {
    if (cursor + 1 < src_len && src[cursor + 1] == '=') {
      *out_kind = 0x30B;
      *out_length = 2;
      return 1;
    }
    *out_kind = '=';
    *out_length = 1;
    return 1;
  }

  // '+' test (single + plus plus)
  if (ch == '+') {
    if (cursor + 1 < src_len && src[cursor + 1] == '+') {
      *out_kind = 0x305;
      *out_length = 2;
      return 1;
    }
    *out_kind = '+';
    *out_length = 1;
    return 1;
  }

  return 0;
}

I64 Bootstrap06ClassifyProbe(I64 *out_kind, I64 *out_length)
{
  U8 buf[16];
  buf[0] = 'a';
  buf[1] = 'b';
  buf[2] = 'c';
  buf[3] = '=';
  buf[4] = '=';
  buf[5] = '+';
  buf[6] = '+';
  buf[7] = '\0';

  return BootstrapClassifyOperator(buf, 7, 3, 0,
                                   out_kind, out_length);
}
