// tools/bootstrap/selfhost-parser-padding.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL -- PolyC CalcPadding.
//
// WINNER SUBJECT. Computes the number of padding bytes required to align
// the next field at a given `size`-byte boundary.
//
// Frozen ABI (ACT §3):
//   I64 BootstrapCalcPadding(I64 offset, I64 size);
//
// Inputs:
//   offset : I64,  >= 0 (frozen qualified domain)
//   size   : I64,  >= 0
//
// Output:
//   pad_bytes : I64
//
// Mathematical contract (ACT §2):
//   size == 0              => 0
//   size > 0 && aligned    => 0            iff (offset % size) == 0
//   size > 0 && unaligned  => size - rem   where rem = offset % size
//
// The zero-size guard MUST precede any `offset % size` computation to
// preserve portability across `x86_64` (which traps on `% 0`) and
// `aarch64` (which returns the dividend and would silently zero the
// class size). ACT §29 forbids compressing the guard with the unaligned
// branch into a single expression.
//
// Purity constraints (ACT §29):
//   - no external dependencies on parser / lexer / cctrl / ast
//   - no allocation
//   - no global mutable state
//
// This file is a candidate self-hosted PolyC component. ACT-...
// PADDING01 qualifies it. Production authority remains the legacy C
// `src/parser.c::CalcPadding` until a separate delegation ACT closes.

I64 BootstrapCalcPadding(I64 offset, I64 size)
{
  if (size == 0) return 0;
  I64 rem = offset % size;
  if (rem == 0) return 0;
  return size - rem;
}
