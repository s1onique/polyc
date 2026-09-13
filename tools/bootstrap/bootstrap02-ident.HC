// tools/bootstrap/bootstrap02-ident.HC
//
// ACT-POLYC-BOOTSTRAP02 C2 IMPL — PolyC B1 identifier-span
// component.
//
// This file is the B1 SUBJECT. It is a self-contained
// compiler-shaped executable proof: bytes in, identifier
// span out, written in PolyC, allocation-free.
//
// Frozen B1 contract (see evidence/ACT-POLYC-BOOTSTRAP02/
// c1/identifier-contract.txt and ACT-POLYC-BOOTSTRAP02-
// C1-CORRECTION01):
//
//   B1_IDENTIFIER_CHARACTER_DOMAIN = ASCII
//   B1_CTYPE_DEPENDENCY            = NONE
//   B1_NON_ASCII_EQUIVALENCE       = NOT_CLAIMED
//
// Production grammar (ASCII subset, frozen):
//
//   first byte   ('A'..'Z') | ('a'..'z') | '_'
//   rest byte*   ('A'..'Z') | ('a'..'z') | '_' |
//                 '$'         | ('0'..'9')
//
// In one regex line:
//
//   b1_ident = [A-Za-z_][A-Za-z0-9_$]*
//
// Note: this grammar is intentionally a strict superset
// of the B0 grammar ([A-Za-z_][A-Za-z0-9_]*); production
// sources such as src/holyc-lib/dir.HC contain real
// `$`-bearing identifiers (e.g. `_opendir$INODE64`).
//
// API:
//
//   I64 BootstrapScanIdent(
//       U8  *src,        // caller-owned, read-only
//       I64  src_len,    // explicit byte length
//       I64  start,      // cursor into src
//       I64 *out_end     // first byte after identifier
//   );
//
// Returns 1 on success, 0 on invalid input. On success:
//   *out_end = start + N   (N >= 1)
//   no mutation of *src
//   no global state, no allocation
//
// Implementation requirements (all met):
//   - single forward scan
//   - no recursion
//   - no dynamic allocation (no MAlloc, no Free)
//   - no source mutation
//   - no global mutable state
//   - bounded reads (src_len is hard-capped)
//   - deterministic result
//   - ASCII-only byte comparisons (NO ctype.h)
//
// ABI proof: see evidence/ACT-POLYC-BOOTSTRAP02/c1/
// abi-witness.txt. This ABI lowers, links, and runs
// correctly via stage0 hcc.
//
// Oracle: see tools/quality/bootstrap02-ident-oracle.c
// (independent C99 reference model — REFERENCE_MODEL,
// not a verbatim transcription).
//
// Test matrix: see evidence/ACT-POLYC-BOOTSTRAP02/c1/
// legacy-ident-oracle.tsv (15 fixtures I01..I15).

// ----------------------------------------------------------------
// ASCII byte predicates (no ctype.h)
// ----------------------------------------------------------------
//
// These are the only identifier-classification predicates
// in the B1 component. They are written as explicit byte
// range comparisons so the result is independent of the
// active C locale and of the signedness of `char`.
// Per ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01 §1.P1:
//   B1_NON_ASCII_EQUIVALENCE = NOT_CLAIMED
// Bytes >= 0x80 are never classified as identifier bytes
// here.

I64 B02IsAsciiUpper(U8 c)
{
  if (c >= 'A' && c <= 'Z') return 1;
  return 0;
}

I64 B02IsAsciiLower(U8 c)
{
  if (c >= 'a' && c <= 'z') return 1;
  return 0;
}

I64 B02IsAsciiAlpha(U8 c)
{
  if (B02IsAsciiUpper(c)) return 1;
  if (B02IsAsciiLower(c)) return 1;
  return 0;
}

I64 B02IsAsciiDigit(U8 c)
{
  if (c >= '0' && c <= '9') return 1;
  return 0;
}

I64 B02IsIdentStart(U8 c)
{
  if (B02IsAsciiAlpha(c)) return 1;
  if (c == '_')           return 1;
  return 0;
}

I64 B02IsIdentRest(U8 c)
{
  if (B02IsAsciiAlpha(c)) return 1;
  if (B02IsAsciiDigit(c)) return 1;
  if (c == '_')           return 1;
  if (c == '$')           return 1;
  return 0;
}

// ----------------------------------------------------------------
// BootstrapScanIdent: the B1 subject proper.
// ----------------------------------------------------------------
//
// Allocation-free, single-pass, deterministic, ASCII-only.

public I64 BootstrapScanIdent(U8 *src, I64 src_len,
                              I64 start, I64 *out_end)
{
  if (src == NULL)         return 0;
  if (out_end == NULL)     return 0;
  if (start < 0)           return 0;
  if (start >= src_len)    return 0;

  U8 first = src[start];
  if (!B02IsIdentStart(first)) return 0;

  I64 i = start + 1;
  while (i < src_len) {
    U8 c = src[i];
    if (!B02IsIdentRest(c)) break;
    i = i + 1;
  }
  *out_end = i;
  return 1;
}
