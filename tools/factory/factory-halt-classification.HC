// tools/factory/factory-halt-classification.HC
//
// ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.3 IMPL.
//
// PolyC authoritative implementation of the Factory v2 trailer
// classifier for `HALT_CLASS` and `BLOCKS_NEXT`. Replaces
// scripts/quality/factory-halt-classification.py with byte-identical
// observable behavior on stdout/stderr/exit-code.
//
// Migrated verbatim from the Python oracle (sha256 159df06a96...
// at the closing commit of ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01,
// captured at C2.3 RED before this file was added). Contract
// documented at docs/factory/DOCTRINE.md §25 (F-MECHANICAL-BLOCKING)
// and at docs/factory/GIT-METADATA.md §2.4.
//
// USAGE:
//   factory-halt-classification <commit-message-file>
//   factory-halt-classification --matrix
//   factory-halt-classification --selftest
//
// This PolyC implementation uses NO ternary operator (hcc does not
// implement `?:`); every conditional that would be a ternary in
// Python is expressed as an explicit `if (x) a = p; else a = q;`.

#include "../../src/holyc-lib/tooling.HC"

extern "c" I64 write(I32 fd, U8 *buf, I64 n);

U0 FdPrint(I32 fd, U8 *s)
{
  if (!s) return;
  write(fd, s, StrLen(s));
}

// StrCat: append src to dst (dst must have enough room).
U8 *StrCat(U8 *dst, U8 *src)
{
  if (!dst || !src) return dst;
  I64 dn = StrLen(dst);
  I64 sn = StrLen(src);
  MemCpy(dst + dn, src, sn + 1);
  return dst;
}

// ============================================================
// Trailer parser — direct port of Python regex
//   r"^([A-Za-z][A-Za-z0-9_-]*):[ \t]+(.*)$"
// applied to every line of the input via splitlines().
// ============================================================

class FHCField {
  I64 count;
  U8 *first;
};

#define FHC_MAX_KEY_LEN 64
#define FHC_LINEBUF     65536
#define FHC_MAX_LINES   4096

Bool IsKeyChar(U8 c)
{
  if (c >= 'a' && c <= 'z') return TRUE;
  if (c >= 'A' && c <= 'Z') return TRUE;
  if (c >= '0' && c <= '9') return TRUE;
  if (c == '_' || c == '-') return TRUE;
  return FALSE;
}

Bool ScanTrailer(U8 *line, U8 *key_buf, I64 key_cap,
                 U8 *val_buf, I64 val_cap)
{
  if (!line) return FALSE;
  U8 c0 = line[0];
  if (c0 >= 'a' && c0 <= 'z') goto first_ok;
  if (c0 >= 'A' && c0 <= 'Z') goto first_ok;
  return FALSE;
first_ok:
  I64 k = 0;
  while (line[k]) {
    if (!IsKeyChar(line[k])) break;
    if (k + 1 >= key_cap) return FALSE;
    key_buf[k] = line[k];
    k++;
  }
  if (k == 0) return FALSE;
  if (line[k] != ':') return FALSE;
  key_buf[k] = 0;
  I64 p = k + 1;
  U8 sep = line[p];
  if (sep != ' ' && sep != '\t') return FALSE;
  p++;

  I64 v = 0;
  while (line[p]) {
    if (v + 1 >= val_cap) return FALSE;
    val_buf[v++] = line[p++];
  }
  val_buf[v] = 0;
  return TRUE;
}

// splitlines: matches Python's splitlines() for "", "\n", "a\n",
// "a\nb", "a\nb\n", and strips trailing '\r' from each line so
// that CRLF input behaves like Python ("a\r\nb\r\n" -> ["a","b"]).
U8 *FHC_LINES[FHC_MAX_LINES];
I64 FHC_NLINES;

U0 SplitLines(U8 *msg)
{
  FHC_NLINES = 0;
  if (!msg) return;
  I64 n = StrLen(msg);
  // Empty input -> zero lines (Python splitlines("") returns []).
  if (n == 0) return;
  // Python's splitlines discards the final empty line if the input
  // ends with '\n' (since "\n" -> ["" ] is the only exception).
  // We walk the input, splitting at every '\n'. For an n-character
  // string with K newlines, Python returns K lines if msg ends with
  // '\n' (since the trailing '\n' creates an empty after-line that
  // is dropped), and K+1 lines otherwise. Special case: "\n" itself
  // returns 1 line, not 0 — so the rule is "drop ONLY the very last
  // empty line if msg ends with '\n'".
  I64 start = 0;
  for (I64 i = 0; i <= n; i++) {
    Bool at_end = (i == n);
    Bool at_nl  = FALSE;
    if (!at_end) {
      if (msg[i] == '\n') at_nl = TRUE;
    }
    if (at_end || at_nl) {
      I64 len = i - start;
      Bool is_trailing_empty = (at_end && len == 0);
      // Skip the trailing empty that Python drops when msg ends with '\n'.
      if (is_trailing_empty && msg[n-1] == '\n') {
        start = i + 1;
        continue;
      }
      if (FHC_NLINES >= FHC_MAX_LINES) return;
      if (len > 0 && msg[i - 1] == '\r') len--;
      U8 *buf = MAlloc(len + 1);
      MemCpy(buf, msg + start, len);
      buf[len] = 0;
      FHC_LINES[FHC_NLINES++] = buf;
      start = i + 1;
    }
  }
}

U0 FreeLines()
{
  for (I64 i = 0; i < FHC_NLINES; i++) Free(FHC_LINES[i]);
  FHC_NLINES = 0;
}

FHCField G_ACT;
FHCField G_PHASE;
FHCField G_VERDICT;
FHCField G_HALT_CLASS;
FHCField G_BLOCKS_NEXT;

U0 CollectTrailers()
{
  G_ACT.count = 0;          G_ACT.first = "";
  G_PHASE.count = 0;        G_PHASE.first = "";
  G_VERDICT.count = 0;      G_VERDICT.first = "";
  G_HALT_CLASS.count = 0;   G_HALT_CLASS.first = "";
  G_BLOCKS_NEXT.count = 0;  G_BLOCKS_NEXT.first = "";

  U8 key[FHC_MAX_KEY_LEN];
  U8 val[FHC_LINEBUF];
  for (I64 i = 0; i < FHC_NLINES; i++) {
    if (!ScanTrailer(FHC_LINES[i], key, FHC_MAX_KEY_LEN,
                     val, FHC_LINEBUF)) continue;
    if (!StrCmp(key, "ACT")) {
      if (G_ACT.count == 0) G_ACT.first = StrNew(val);
      G_ACT.count++;
    } else if (!StrCmp(key, "ACT-Phase")) {
      if (G_PHASE.count == 0) G_PHASE.first = StrNew(val);
      G_PHASE.count++;
    } else if (!StrCmp(key, "ACT-Verdict")) {
      if (G_VERDICT.count == 0) G_VERDICT.first = StrNew(val);
      G_VERDICT.count++;
    } else if (!StrCmp(key, "HALT_CLASS")) {
      if (G_HALT_CLASS.count == 0) G_HALT_CLASS.first = StrNew(val);
      G_HALT_CLASS.count++;
    } else if (!StrCmp(key, "BLOCKS_NEXT")) {
      if (G_BLOCKS_NEXT.count == 0) G_BLOCKS_NEXT.first = StrNew(val);
      G_BLOCKS_NEXT.count++;
    }
  }
}

// ============================================================
// Verdict grammar
// ============================================================

Bool IsHaltVerdict(U8 *v)
{
  if (!v) return FALSE;
  if (v[0] == 0) return FALSE;
  if (StrLen(v) < 6) return FALSE;
  if (StrNCmp(v, "HALT_", 5)) return FALSE;
  for (I64 i = 5; v[i]; i++) {
    U8 c = v[i];
    if (c >= 'A' && c <= 'Z') continue;
    if (c >= '0' && c <= '9') continue;
    if (c == '_') continue;
    return FALSE;
  }
  return TRUE;
}

Bool IsPassVerdict(U8 *v)
{
  if (!v) return FALSE;
  if (v[0] == 0) return FALSE;
  I64 n = StrLen(v);
  if (StrNCmp(v, "PASS", 4)) return FALSE;
  if (n == 4) return TRUE;
  if (v[4] != '_') return FALSE;
  if (n < 6) return FALSE;  // "PASS_" with no token after underscore is invalid
  for (I64 i = 5; i < n; i++) {
    U8 c = v[i];
    if (c >= 'A' && c <= 'Z') continue;
    if (c >= '0' && c <= '9') continue;
    if (c == '_') continue;
    return FALSE;
  }
  return TRUE;
}

// Required BLOCKS_NEXT for a given HALT_CLASS.
//   0  = NO
//   1  = YES
//  -1  = either (DEPENDENCY)
//  -2  = invalid class
I64 RequiredBlocksNext(U8 *hc)
{
  if (!StrCmp(hc, "GOVERNANCE"))    return 0;
  if (!StrCmp(hc, "PRODUCTION"))    return 1;
  if (!StrCmp(hc, "SAFETY"))        return 1;
  if (!StrCmp(hc, "AUTHORIZATION")) return 1;
  if (!StrCmp(hc, "DEPENDENCY"))    return -1;
  return -2;
}

U8 *RequiredBlocksNextStr(U8 *hc)
{
  if (!StrCmp(hc, "GOVERNANCE"))    return "NO";
  if (!StrCmp(hc, "PRODUCTION"))    return "YES";
  if (!StrCmp(hc, "SAFETY"))        return "YES";
  if (!StrCmp(hc, "AUTHORIZATION")) return "YES";
  return "";
}

// ============================================================
// Verdict accumulator + emit
// ============================================================

class Verdict {
  U8 *mode;
  U8 *status;
  U8 *reason;
  U8 *act;
  U8 *phase;
  U8 *verdict;
  U8 *halt_class;
  U8 *blocks_next;
};

Verdict G_VERD;

// Returns the field as a printable string. Empty fields are
// surfaced as the empty literal so a NULL pointer does not
// crash FdPrint.
U8 *FieldOrEmpty(U8 *f)
{
  if (f) return f;
  return "";
}

U0 EmitVerdict()
{
  FdPrint(1, "MODE=");       FdPrint(1, FieldOrEmpty(G_VERD.mode));        FdPrint(1, "\n");
  FdPrint(1, "STATUS=");     FdPrint(1, FieldOrEmpty(G_VERD.status));      FdPrint(1, "\n");
  if (G_VERD.reason) {
    if (G_VERD.reason[0]) {
      FdPrint(1, "REASON="); FdPrint(1, G_VERD.reason);                    FdPrint(1, "\n");
    }
  }
  FdPrint(1, "ACT=");        FdPrint(1, FieldOrEmpty(G_VERD.act));         FdPrint(1, "\n");
  FdPrint(1, "PHASE=");      FdPrint(1, FieldOrEmpty(G_VERD.phase));       FdPrint(1, "\n");
  FdPrint(1, "VERDICT=");    FdPrint(1, FieldOrEmpty(G_VERD.verdict));     FdPrint(1, "\n");
  FdPrint(1, "HALT_CLASS="); FdPrint(1, FieldOrEmpty(G_VERD.halt_class));  FdPrint(1, "\n");
  FdPrint(1, "BLOCKS_NEXT=");FdPrint(1, FieldOrEmpty(G_VERD.blocks_next)); FdPrint(1, "\n");
}

U8 REASON_BUF[512];

// FmtReason1: substitute one %s with `a`. Python style.
U8 *FmtReason1(U8 *fmt, U8 *a)
{
  REASON_BUF[0] = 0;
  if (!fmt) return REASON_BUF;
  I64 fl = StrLen(fmt);
  I64 n = 0;
  for (I64 i = 0; i < fl; i++) {
    if (fmt[i] == '%' && i + 1 < fl && fmt[i+1] == 's') {
      if (a) StrCat(REASON_BUF + n, a);
      n += StrLen(REASON_BUF + n);
      i++;
    } else {
      REASON_BUF[n++] = fmt[i];
    }
  }
  REASON_BUF[n] = 0;
  return REASON_BUF;
}

// FmtReasonI64: substitute one %d with `v`. Python style.
U8 *FmtReasonI64(U8 *fmt, I64 v)
{
  REASON_BUF[0] = 0;
  if (!fmt) return REASON_BUF;
  U8 numbuf[32];
  I64ToStr(numbuf, v, NULL, 31);
  I64 fl = StrLen(fmt);
  I64 n = 0;
  for (I64 i = 0; i < fl; i++) {
    if (fmt[i] == '%' && i + 1 < fl && fmt[i+1] == 'd') {
      StrCat(REASON_BUF + n, numbuf);
      n += StrLen(numbuf);
      i++;
    } else {
      REASON_BUF[n++] = fmt[i];
    }
  }
  REASON_BUF[n] = 0;
  return REASON_BUF;
}

// FmtReasonHcBn: "%s requires BLOCKS_NEXT=%s"
U8 *FmtReasonHcBn(U8 *hc, U8 *req)
{
  REASON_BUF[0] = 0;
  if (hc)  StrCat(REASON_BUF, hc);
  StrCat(REASON_BUF, " requires BLOCKS_NEXT=");
  if (req) StrCat(REASON_BUF, req);
  return REASON_BUF;
}

// ============================================================
// classify(msg): trailer classifier on an in-memory string.
// Mirrors Python's classify() byte-for-byte.
// ============================================================

U0 ClassifyMessage(U8 *msg)
{
  G_VERD.mode        = "ACT";
  G_VERD.status      = "";
  G_VERD.reason      = "";
  G_VERD.act         = "";
  G_VERD.phase       = "";
  G_VERD.verdict     = "";
  G_VERD.halt_class  = "";
  G_VERD.blocks_next = "";

  SplitLines(msg);
  CollectTrailers();

  if (G_ACT.count == 0) {
    G_VERD.mode   = "NON_ACT";
    G_VERD.status = "PASS";
    FreeLines();
    return;
  }

  // Copy first values; FieldOrEmpty handles NULLs.
  if (G_ACT.first)         G_VERD.act         = G_ACT.first;        else G_VERD.act         = "";
  if (G_PHASE.first)       G_VERD.phase       = G_PHASE.first;      else G_VERD.phase       = "";
  if (G_VERDICT.first)     G_VERD.verdict     = G_VERDICT.first;    else G_VERD.verdict     = "";
  if (G_HALT_CLASS.first)  G_VERD.halt_class  = G_HALT_CLASS.first; else G_VERD.halt_class  = "";
  if (G_BLOCKS_NEXT.first) G_VERD.blocks_next = G_BLOCKS_NEXT.first;else G_VERD.blocks_next = "";

  if (StrCmp(G_VERD.phase, "CLOSE")) {
    G_VERD.status = "PASS";
    FreeLines();
    return;
  }

  if (IsHaltVerdict(G_VERD.verdict)) {
    if (G_HALT_CLASS.count != 1) {
      G_VERD.status = "FAIL";
      G_VERD.reason = FmtReasonI64(
        "HALT_CLASS count=%d, expected 1 for HALT verdict",
        G_HALT_CLASS.count);
      FreeLines();
      return;
    }
    if (G_BLOCKS_NEXT.count != 1) {
      G_VERD.status = "FAIL";
      G_VERD.reason = FmtReasonI64(
        "BLOCKS_NEXT count=%d, expected 1 for HALT verdict",
        G_BLOCKS_NEXT.count);
      FreeLines();
      return;
    }
    if (RequiredBlocksNext(G_VERD.halt_class) == -2) {
      G_VERD.status = "FAIL";
      G_VERD.reason = FmtReason1(
        "HALT_CLASS '%s' not in enum", G_VERD.halt_class);
      FreeLines();
      return;
    }
    Bool bn_yes = !StrCmp(G_VERD.blocks_next, "YES");
    Bool bn_no  = !StrCmp(G_VERD.blocks_next, "NO");
    if (!bn_yes && !bn_no) {
      G_VERD.status = "FAIL";
      G_VERD.reason = FmtReason1(
        "BLOCKS_NEXT '%s' not in {YES, NO}", G_VERD.blocks_next);
      FreeLines();
      return;
    }
    I64 req = RequiredBlocksNext(G_VERD.halt_class);
    if (req != -1) {
      U8 *req_str = RequiredBlocksNextStr(G_VERD.halt_class);
      if (StrCmp(G_VERD.blocks_next, req_str)) {
        G_VERD.status = "FAIL";
        G_VERD.reason = FmtReasonHcBn(G_VERD.halt_class, req_str);
        FreeLines();
        return;
      }
    }
  } else if (IsPassVerdict(G_VERD.verdict)) {
    if (G_HALT_CLASS.count != 0) {
      G_VERD.status = "FAIL";
      G_VERD.reason = FmtReasonI64(
        "PASS verdict forbids HALT_CLASS (count=%d)",
        G_HALT_CLASS.count);
      FreeLines();
      return;
    }
    if (G_BLOCKS_NEXT.count != 0) {
      G_VERD.status = "FAIL";
      G_VERD.reason = FmtReasonI64(
        "PASS verdict forbids BLOCKS_NEXT (count=%d)",
        G_BLOCKS_NEXT.count);
      FreeLines();
      return;
    }
  }

  G_VERD.status = "PASS";
  FreeLines();
}

// ============================================================
// Matrix (12 fixtures) — verbatim port from mod._FIXTURES
// ============================================================

U8 *FIX_NAMES[12];
I64 FIX_WANT_RC[12];
U8 *FIX_MSGS[12];

U0 InitFixtures()
{
  FIX_NAMES[0]  = "R1 governance halt, NO block";   FIX_WANT_RC[0]  = 0;
  FIX_NAMES[1]  = "R2 production halt, YES block";  FIX_WANT_RC[1]  = 0;
  FIX_NAMES[2]  = "R3 halt missing HALT_CLASS";     FIX_WANT_RC[2]  = 1;
  FIX_NAMES[3]  = "R4 halt missing BLOCKS_NEXT";    FIX_WANT_RC[3]  = 1;
  FIX_NAMES[4]  = "R5 PASS verdict with BLOCKS_NEXT"; FIX_WANT_RC[4] = 1;
  FIX_NAMES[5]  = "R6 GOVERNANCE/YES rejected";     FIX_WANT_RC[5]  = 1;
  FIX_NAMES[6]  = "R7 PRODUCTION/NO rejected";      FIX_WANT_RC[6]  = 1;
  FIX_NAMES[7]  = "R8 historical-style PASS, no trailers"; FIX_WANT_RC[7] = 0;
  FIX_NAMES[8]  = "R9 DEPENDENCY/YES allowed";      FIX_WANT_RC[8]  = 0;
  FIX_NAMES[9]  = "R10 DEPENDENCY/NO allowed";      FIX_WANT_RC[9]  = 0;
  FIX_NAMES[10] = "R11 non-ACT commit";             FIX_WANT_RC[10] = 0;
  FIX_NAMES[11] = "R12 RED phase, halt verdict, no trailers"; FIX_WANT_RC[11] = 0;

  FIX_MSGS[0] =
    "subject\n\nbody\n\n"
    "ACT: ACT-POLYC-EXAMPLE01\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
    "HALT_CLASS: GOVERNANCE\n"
    "BLOCKS_NEXT: NO";

  FIX_MSGS[1] =
    "subject\n\nbody\n\n"
    "ACT: ACT-POLYC-EXAMPLE02\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
    "HALT_CLASS: PRODUCTION\n"
    "BLOCKS_NEXT: YES";

  FIX_MSGS[2] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE03\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_X\n"
    "BLOCKS_NEXT: YES";

  FIX_MSGS[3] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE04\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_X\n"
    "HALT_CLASS: PRODUCTION";

  FIX_MSGS[4] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE05\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: PASS\n"
    "BLOCKS_NEXT: YES";

  FIX_MSGS[5] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE06\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
    "HALT_CLASS: GOVERNANCE\n"
    "BLOCKS_NEXT: YES";

  FIX_MSGS[6] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE07\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
    "HALT_CLASS: PRODUCTION\n"
    "BLOCKS_NEXT: NO";

  FIX_MSGS[7] =
    "subject\n\nbody\n\n"
    "ACT: ACT-POLYC-EXAMPLE08\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: PASS";

  FIX_MSGS[8] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE09\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_DEPENDENCY_HALT\n"
    "HALT_CLASS: DEPENDENCY\n"
    "BLOCKS_NEXT: YES";

  FIX_MSGS[9] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE10\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_DEPENDENCY_HALT\n"
    "HALT_CLASS: DEPENDENCY\n"
    "BLOCKS_NEXT: NO";

  FIX_MSGS[10] =
    "ordinary commit message\n\nno trailers here";

  FIX_MSGS[11] =
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE12\n"
    "ACT-Phase: RED\n"
    "ACT-Verdict: HALT_DRAFT";
}

// Emit an indented key=value line for the FAIL-block.
U0 EmitMatrixFailLine(U8 *key, U8 *val)
{
  U8 buf[512];
  buf[0] = 0;
  StrCat(buf, "  ");
  StrCat(buf, key);
  StrCat(buf, "=");
  if (val) StrCat(buf, val);
  StrCat(buf, "\n");
  FdPrint(1, buf);
}

I32 RunMatrixInline()
{
  InitFixtures();
  I64 passed = 0;
  I64 failed = 0;

  for (I64 i = 0; i < 12; i++) {
    ClassifyMessage(FIX_MSGS[i]);
    U8 *st = FieldOrEmpty(G_VERD.status);
    I64 got_rc;
    if (G_VERD.status && !StrCmp(G_VERD.status, "PASS")) got_rc = 0;
    else                                                   got_rc = 1;
    if (got_rc == FIX_WANT_RC[i]) {
      passed++;
      "  PASS  %s  (rc=%d status=%s)\n", FIX_NAMES[i], got_rc, st;
    } else {
      failed++;
      "  FAIL  %s  want rc=%d got rc=%d status=%s\n",
        FIX_NAMES[i], FIX_WANT_RC[i], got_rc, st;
      EmitMatrixFailLine("MODE",        FieldOrEmpty(G_VERD.mode));
      EmitMatrixFailLine("STATUS",      FieldOrEmpty(G_VERD.status));
      EmitMatrixFailLine("REASON",      FieldOrEmpty(G_VERD.reason));
      EmitMatrixFailLine("ACT",         FieldOrEmpty(G_VERD.act));
      EmitMatrixFailLine("PHASE",       FieldOrEmpty(G_VERD.phase));
      EmitMatrixFailLine("VERDICT",     FieldOrEmpty(G_VERD.verdict));
      EmitMatrixFailLine("HALT_CLASS",  FieldOrEmpty(G_VERD.halt_class));
      EmitMatrixFailLine("BLOCKS_NEXT", FieldOrEmpty(G_VERD.blocks_next));
    }
  }
  "--- summary ---\n";
  "PASS=%d\n", passed;
  "FAIL=%d\n", failed;
  if (failed == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ============================================================
// Selftest
// ============================================================

I32 RunSelfTests()
{
  I64 fails = 0;
  U8 key[64];
  U8 val[256];

  if (!ScanTrailer("ACT: foo", key, 64, val, 256))  { "FAIL  selftest: scan positive\n"; fails++; }
  else if (StrCmp(key,"ACT") || StrCmp(val,"foo"))  { "FAIL  selftest: scan positive content\n"; fails++; }
  if (ScanTrailer(" ACT: foo", key, 64, val, 256))  { "FAIL  selftest: scan leading ws\n"; fails++; }
  if (ScanTrailer("ACT:", key, 64, val, 256))       { "FAIL  selftest: scan no space\n"; fails++; }
  if (!ScanTrailer("ACT:\tfoo", key, 64, val, 256)) { "FAIL  selftest: scan tab\n"; fails++; }
  else if (StrCmp(val,"foo"))                       { "FAIL  selftest: scan tab content\n"; fails++; }
  if (!ScanTrailer("BLOCKS_NEXT: YES: extra", key, 64, val, 256))
                                                     { "FAIL  selftest: scan embedded colon\n"; fails++; }
  else if (StrCmp(val, "YES: extra"))               { "FAIL  selftest: scan embedded colon content\n"; fails++; }
  if (!ScanTrailer("ACT-Phase: CLOSE", key, 64, val, 256))
                                                     { "FAIL  selftest: scan hyphen\n"; fails++; }
  else if (StrCmp(val,"CLOSE"))                     { "FAIL  selftest: scan hyphen content\n"; fails++; }
  if (!ScanTrailer("HALT_CLASS: PRODUCTION", key, 64, val, 256))
                                                     { "FAIL  selftest: scan underscore\n"; fails++; }
  else if (StrCmp(val,"PRODUCTION"))                { "FAIL  selftest: scan underscore content\n"; fails++; }
  if (ScanTrailer("1ACT: foo", key, 64, val, 256))  { "FAIL  selftest: scan leading digit\n"; fails++; }
  if (!ScanTrailer("ACT: ", key, 64, val, 256))     { "FAIL  selftest: scan empty value\n"; fails++; }
  else if (StrCmp(val,""))                          { "FAIL  selftest: scan empty value content\n"; fails++; }

  if (!IsHaltVerdict("HALT_X"))                     { "FAIL  selftest: halt X\n"; fails++; }
  if (!IsHaltVerdict("HALT_PRODUCTION_DEFECT"))     { "FAIL  selftest: halt long\n"; fails++; }
  if (IsHaltVerdict("HALT_x"))                      { "FAIL  selftest: halt lowercase\n"; fails++; }
  if (IsHaltVerdict("HALT_"))                       { "FAIL  selftest: halt empty token\n"; fails++; }
  if (IsHaltVerdict("halt_x"))                      { "FAIL  selftest: halt leading lowercase\n"; fails++; }
  if (IsHaltVerdict("PASS"))                        { "FAIL  selftest: halt=pass\n"; fails++; }

  if (!IsPassVerdict("PASS"))                       { "FAIL  selftest: pass\n"; fails++; }
  if (!IsPassVerdict("PASS_FOO"))                   { "FAIL  selftest: pass foo\n"; fails++; }
  if (!IsPassVerdict("PASS_FOO_BAR"))               { "FAIL  selftest: pass foo bar\n"; fails++; }
  if (IsPassVerdict("PASS_"))                       { "FAIL  selftest: pass trailing underscore\n"; fails++; }
  if (IsPassVerdict("PASS_foo"))                    { "FAIL  selftest: pass lowercase token\n"; fails++; }
  if (IsPassVerdict("PASS-"))                       { "FAIL  selftest: pass hyphen\n"; fails++; }

  if (RequiredBlocksNext("GOVERNANCE")    != 0)     { "FAIL  selftest: rbn governance\n"; fails++; }
  if (RequiredBlocksNext("PRODUCTION")    != 1)     { "FAIL  selftest: rbn production\n"; fails++; }
  if (RequiredBlocksNext("SAFETY")        != 1)     { "FAIL  selftest: rbn safety\n"; fails++; }
  if (RequiredBlocksNext("AUTHORIZATION") != 1)     { "FAIL  selftest: rbn authorization\n"; fails++; }
  if (RequiredBlocksNext("DEPENDENCY")    != -1)    { "FAIL  selftest: rbn dependency\n"; fails++; }
  if (RequiredBlocksNext("BOGUS")         != -2)    { "FAIL  selftest: rbn bogus\n"; fails++; }

  SplitLines("");
  if (FHC_NLINES != 0) { "FAIL  selftest: splitlines empty\n"; fails++; }
  FreeLines();

  SplitLines("\n");
  if (FHC_NLINES != 1) { "FAIL  selftest: splitlines newline count\n"; fails++; }
  if (FHC_NLINES >= 1 && StrCmp(FHC_LINES[0], ""))
    { "FAIL  selftest: splitlines newline content\n"; fails++; }
  FreeLines();

  SplitLines("a\r\nb\r\n");
  if (FHC_NLINES != 2) { "FAIL  selftest: splitlines crlf count\n"; fails++; }
  if (FHC_NLINES >= 2 && (StrCmp(FHC_LINES[0],"a") || StrCmp(FHC_LINES[1],"b")))
    { "FAIL  selftest: splitlines crlf content\n"; fails++; }
  FreeLines();

  ClassifyMessage(
    "subject\n\nbody\n\n"
    "ACT: ACT-POLYC-EXAMPLE01\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
    "HALT_CLASS: GOVERNANCE\n"
    "BLOCKS_NEXT: NO");
  if (StrCmp(G_VERD.status, "PASS"))
    { "FAIL  selftest: classify R1 status\n"; fails++; }

  ClassifyMessage(
    "subject\n\n"
    "ACT: ACT-POLYC-EXAMPLE03\n"
    "ACT-Phase: CLOSE\n"
    "ACT-Verdict: HALT_X\n"
    "BLOCKS_NEXT: YES");
  if (StrCmp(G_VERD.status, "FAIL"))
    { "FAIL  selftest: classify R3 status\n"; fails++; }

  ClassifyMessage(
    "ordinary commit message\n\nno trailers here");
  if (StrCmp(G_VERD.mode, "NON_ACT") || StrCmp(G_VERD.status, "PASS"))
    { "FAIL  selftest: classify R11\n"; fails++; }

  if (fails == 0) {
    "FHC_SELFTEST_PASS=28\n";
    "FHC_SELFTEST_FAIL=0\n";
    "STATUS=PASS\n";
    return 0;
  }
  "FHC_SELFTEST_FAIL=%d\n", fails;
  "STATUS=FAIL\n";
  return 1;
}

// ============================================================
// Main
// ============================================================

I32 UsageErr()
{
  FdPrint(1, "STATUS=ERROR\n");
  FdPrint(1, "REASON=usage: factory-halt-classification <commit-message>\n");
  return 2;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc >= 2 && !StrCmp(argv[1], "--selftest")) return RunSelfTests();
  if (argc >= 2 && !StrCmp(argv[1], "--matrix"))   return RunMatrixInline();
  if (argc != 2) return UsageErr();

  U8 *path = argv[1];
  I64 total = 0;
  U8 *body = FileRead(path, &total);
  if (!body) {
    FdPrint(1, "STATUS=ERROR\n");
    FdPrint(1, "REASON=commit message file not found: ");
    FdPrint(1, path);
    FdPrint(1, " ([Errno 2] No such file or directory: '");
    FdPrint(1, path);
    FdPrint(1, "')\n");
    return 2;
  }

  ClassifyMessage(body);
  EmitVerdict();
  if (G_VERD.status && !StrCmp(G_VERD.status, "PASS")) return 0;
  return 1;
}
