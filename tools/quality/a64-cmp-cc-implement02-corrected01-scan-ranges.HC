// tools/quality/a64-cmp-cc-implement02-corrected01-scan-ranges.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01 C0.
//
// A GENUINE POLYC BYTE-LEVEL LEXICAL SOURCE SCANNER.
//
// It reads the committed src/aarch64.c blob as BYTES and derives the
// whole-definition half-open byte intervals of the three selected
// functions by lexical scanning: it tracks C comments, string literals,
// character literals and preprocessor lines, so a brace inside a comment
// or a string can never be mistaken for a function-body brace.
//
// For every site it prints the DERIVED start, the DERIVED end, the
// DERIVED length, and the SHA-256 of the extracted bytes. The digest is
// produced by the real POSIX `shasum` run over the exact byte slice this
// scanner extracted, so the digest comes from an INDEPENDENT
// implementation while the byte boundary is proven by this scanner.
//
// The tool NEVER echoes an asserted PASS. It prints DERIVED FACTS only.
//
// BUILD:
//   ./build/host-stage0/hcc --install-dir=<prefix> -c \
//     tools/quality/a64-cmp-cc-implement02-corrected01-scan-ranges.HC \
//     -o build/a64-cmp-cc-scan-ranges.o
//   cc build/a64-cmp-cc-scan-ranges.o -L<prefix>/lib -ltos \
//     -o build/a64-cmp-cc-scan-ranges
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real compiler.

#include "../../src/holyc-lib/defs.HH"
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

public _extern _EXIT U0 Exit(I64 exit_code = EXIT_FAIL);
public _extern _WRITE I64 Write(I64 fd, U8 *buf, I64 len);

#define MAXSRC (256 * 1024)

// Write1 formats exactly one string argument into a bounded buffer and
// returns the new length. HolyC's StrPrint takes varargs, so the
// argument count must be fixed per helper to keep the call sites typed.
public I64 Write1(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a)
{
  U8 *piece = StrPrint(NULL, fmt, a);
  I64 pl = StrLen(piece);
  I64 k = 0;
  while (k < pl && n < cap - 1) { buf[n] = piece[k]; n++; k++; }
  buf[n] = 0;
  return n;
}

// WriteI64 formats exactly one integer argument into a bounded buffer.
public I64 WriteI64(U8 *buf, I64 n, I64 cap, U8 *fmt, I64 v)
{
  U8 *piece = StrPrint(NULL, fmt, v);
  I64 pl = StrLen(piece);
  I64 k = 0;
  while (k < pl && n < cap - 1) { buf[n] = piece[k]; n++; k++; }
  buf[n] = 0;
  return n;
}



static U8 *SRC;
static I64 SRCLEN;

// ---------------------------------------------------------------------------
// Derive the half-open byte interval of the whole definition of the
// function whose name is `name`. The interval starts at the first byte
// of the function name and ends at the byte AFTER the matching closing
// brace of the body, so the closing brace is the LAST byte of the
// interval. A `;` before any `{` means this is a prototype, not a
// definition, and is rejected.
// ---------------------------------------------------------------------------
static I64 DeriveOne(U8 *name, I64 namelen, I64 *out_start, I64 *out_end) {
  I64 i = 0;

  while (i < SRCLEN) {
    I64 instr = 0;    // inside a string literal
    I64 inchar = 0;   // inside a character literal
    I64 incmt = 0;    // 0 none, 1 line comment, 2 block comment
    I64 inpre = 0;    // inside a preprocessor line
    I64 j;
    I64 found = 0;

    // Scan forward to the next normal code position.
    while (i < SRCLEN) {
      U8 c = SRC[i];
      if (incmt == 1) { if (c == '\n') incmt = 0; i++; continue; }
      if (incmt == 2) {
        if (c == '*' && i + 1 < SRCLEN && SRC[i + 1] == '/') { incmt = 0; i += 2; continue; }
        i++; continue;
      }
      if (instr) { if (c == '\\') { i += 2; continue; } if (c == '"') instr = 0; i++; continue; }
      if (inchar) { if (c == '\\') { i += 2; continue; } if (c == '\'') inchar = 0; i++; continue; }
      if (inpre) { if (c == '\n') inpre = 0; i++; continue; }

      if (c == '/' && i + 1 < SRCLEN) {
        if (SRC[i + 1] == '/') { incmt = 1; i += 2; continue; }
        if (SRC[i + 1] == '*') { incmt = 2; i += 2; continue; }
      }
      if (c == '"')  { instr = 1; i++; continue; }
      if (c == '\'') { inchar = 1; i++; continue; }
      if (c == '#')  { inpre = 1; i++; continue; }

      // Normal code position.
      break;
    }
    if (i >= SRCLEN) return -1;

    // Is the identifier at `i` the wanted name?
    if (i + namelen < SRCLEN) {
      I64 k = 0;
      I64 ok = 1;
      while (k < namelen) { if (SRC[i + k] != name[k]) { ok = 0; break; } k++; }
      if (ok) {
        I64 before_ok = 1;
        if (i > 0) {
          U8 b = SRC[i - 1];
          if ((b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z') ||
              (b >= '0' && b <= '9') || b == '_') before_ok = 0;
        }
        I64 after_ok = 0;
        if (i + namelen < SRCLEN && SRC[i + namelen] == '(') after_ok = 1;
        if (before_ok && after_ok) found = 1;
      }
    }

    if (!found) { i++; continue; }

    // The WHOLE definition begins at the start of the DECLARATION, not
    // at the function name. Walk backwards from the name over the
    // declarator text (return type, pointer stars, storage class) to the
    // last statement boundary, which is the byte after the ';' or '}'
    // that ends the previous declaration, or the start of the file.
    //
    // The walk is bounded by the lexical rules: it stops at a byte that
    // cannot appear inside a declarator (newline, ';', '{', '}', '#')
    // and it never crosses a comment or a string, because those bytes
    // are not valid declarator bytes.
    {
      I64 b = i - 1;
      while (b >= 0) {
        U8 c = SRC[b];
        if (c == '\n' || c == ';' || c == '{' || c == '}' || c == '#') break;
        // A '/' that starts a comment also ends the declarator text.
        if (c == '/' && b + 1 < SRCLEN && (SRC[b + 1] == '/' || SRC[b + 1] == '*')) break;
        b--;
      }
      // b is the last byte that is NOT part of the declarator, so the
      // declaration starts at b+1.
      i = b + 1;
      // Skip leading blanks so the interval starts at the first
      // non-space byte of the declaration.
      while (i < SRCLEN && (SRC[i] == ' ' || SRC[i] == '\t')) i++;
    }

    // Find the opening brace of the body.
    j = i + namelen;
    while (j < SRCLEN && SRC[j] != '{' && SRC[j] != ';') j++;
    if (j >= SRCLEN) return -1;
    if (SRC[j] == ';') { i = j + 1; continue; }   // a prototype, not a definition

    // The declaration start moved back; recompute the name offset so the
    // body search starts from the right place.
    {
      I64 k = i;
      I64 d = 0;
      I64 s2 = 0; I64 c2 = 0; I64 cm2 = 0; I64 p2 = 0;
      while (k < SRCLEN) {
        U8 e = SRC[k];
        if (cm2 == 1) { if (e == '\n') cm2 = 0; k++; continue; }
        if (cm2 == 2) {
          if (e == '*' && k + 1 < SRCLEN && SRC[k + 1] == '/') { cm2 = 0; k += 2; continue; }
          k++; continue;
        }
        if (s2) { if (e == '\\') { k += 2; continue; } if (e == '"') s2 = 0; k++; continue; }
        if (c2) { if (e == '\\') { k += 2; continue; } if (e == '\'') c2 = 0; k++; continue; }
        if (p2) { if (e == '\n') p2 = 0; k++; continue; }
        if (e == '/' && k + 1 < SRCLEN) {
          if (SRC[k + 1] == '/') { cm2 = 1; k += 2; continue; }
          if (SRC[k + 1] == '*') { cm2 = 2; k += 2; continue; }
        }
        if (e == '"')  { s2 = 1; k++; continue; }
        if (e == '\'') { c2 = 1; k++; continue; }
        if (e == '#')  { p2 = 1; k++; continue; }
        if (e == '(') { d = k; break; }
        k++;
      }
      if (d == 0) return -1;
      j = d;
    }

    // Match the braces.
    {
      I64 depth = 0;
      I64 k = j;
      I64 s2 = 0; I64 c2 = 0; I64 cm2 = 0; I64 p2 = 0;
      while (k < SRCLEN) {
        U8 d = SRC[k];
        if (cm2 == 1) { if (d == '\n') cm2 = 0; k++; continue; }
        if (cm2 == 2) {
          if (d == '*' && k + 1 < SRCLEN && SRC[k + 1] == '/') { cm2 = 0; k += 2; continue; }
          k++; continue;
        }
        if (s2) { if (d == '\\') { k += 2; continue; } if (d == '"') s2 = 0; k++; continue; }
        if (c2) { if (d == '\\') { k += 2; continue; } if (d == '\'') c2 = 0; k++; continue; }
        if (p2) { if (d == '\n') p2 = 0; k++; continue; }
        if (d == '/' && k + 1 < SRCLEN) {
          if (SRC[k + 1] == '/') { cm2 = 1; k += 2; continue; }
          if (SRC[k + 1] == '*') { cm2 = 2; k += 2; continue; }
        }
        if (d == '"')  { s2 = 1; k++; continue; }
        if (d == '\'') { c2 = 1; k++; continue; }
        if (d == '#')  { p2 = 1; k++; continue; }
        if (d == '{') depth++;
        if (d == '}') {
          depth--;
          if (depth == 0) {
            *out_start = i;
            *out_end = k + 1;
            return 0;
          }
        }
        k++;
      }
    }
    return -1;
  }
  return -1;
}

// Write the byte slice [start,end) into a file so that an INDEPENDENT
// SHA-256 implementation can digest exactly those bytes.
static I64 WriteSlice(U8 *path, I64 start, I64 end) {
  I64 n = end - start;
  U8 *buf = MAlloc(n + 1);
  I64 k;
  for (k = 0; k < n; k++) buf[k] = SRC[start + k];
  buf[n] = 0;
  if (!FileWrite(path, buf, n, O_CREAT | O_TRUNC | O_WRONLY)) return -1;
  return 0;
}

I32 Main(I32 argc, U8 **argv) {
  I64 i;
  U8 *path;
  I64 sz = 0;
  U8 *tmp;
  U8 *outbuf;
  I64 outn = 0;

  if (argc < 2) {
    U8 *m = StrPrint(NULL, "usage: scan-ranges <src/aarch64.c path>\n");
    Write(1, m, StrLen(m));
    return 2;
  }
  path = argv[1];

  SRC = FileRead(path, &sz);
  if (SRC == NULL) {
    U8 *m = StrPrint(NULL, "scan-ranges: cannot read source\n");
    Write(2, m, StrLen(m));
    return 3;
  }
  SRCLEN = sz;

  outbuf = MAlloc(8192);
  outn = Write1(outbuf, outn, 8192, "SOURCE_PATH\t%s\n", path);
  outn = WriteI64(outbuf, outn, 8192, "SOURCE_BYTES\t%d\n", SRCLEN);

  tmp = "/tmp/a64-cmp-cc-scan-slice.bin";

  for (i = 0; i < 3; i++) {
    I64 st = 0;
    I64 en = 0;
    U8 *nm;
    I64 nl;
    U8 *cmd;
    U8 *digest;

    if (i == 0)      { nm = "aarch64CcFor";    nl = 12; }
    else if (i == 1) { nm = "aarch64CcInvFor"; nl = 15; }
    else             { nm = "aarch64EmitCSet"; nl = 15; }

    if (DeriveOne(nm, nl, &st, &en) != 0) {
      outn = Write1(outbuf, outn, 8192, "DERIVE_FAILED\t%s\n", nm);
      Write(1, outbuf, outn);
      return 4;
    }

    if (WriteSlice(tmp, st, en) != 0) {
      outn = Write1(outbuf, outn, 8192, "SLICE_WRITE_FAILED\t%s\n", nm);
      Write(1, outbuf, outn);
      return 5;
    }

    cmd = StrPrint(NULL, "shasum -a 256 %s > /tmp/a64-cmp-cc-scan-shasum.txt 2>/dev/null", tmp);
    System(cmd);
    digest = FileRead("/tmp/a64-cmp-cc-scan-shasum.txt", NULL);
    if (digest == NULL) {
      outn = Write1(outbuf, outn, 8192, "SHASUM_FAILED\t%s\n", nm);
      Write(1, outbuf, outn);
      return 6;
    }

    // The digest file holds "<hex>  <path>\n". Keep only the hex part.
    {
      I64 d = 0;
      while (digest[d] != 0 && digest[d] != ' ' && digest[d] != '\n') d++;
      digest[d] = 0;
    }

    outn = Write1(outbuf, outn, 8192, "SITE\t%s\t", nm);
    outn = WriteI64(outbuf, outn, 8192, "%d\t", st);
    outn = WriteI64(outbuf, outn, 8192, "%d\t", en);
    outn = WriteI64(outbuf, outn, 8192, "%d\t", en - st);
    outn = Write1(outbuf, outn, 8192, "%s\n", digest);
  }

  Write(1, outbuf, outn);
  return 0;
}
