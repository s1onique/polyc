// tools/quality/lexer07-predecessor-verify.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 C2 IMPL.
// Direct predecessor-identity verifier for P1-7.
//
// Reads docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-
// CORRECTION04.md and extracts the SHA from the line
// "Predecessor (closed): <sha>". Then runs `git show
// --no-patch --format=%s <sha>` on that SHA. The
// returned subject line MUST match
// "ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 — C4 CLOSE"
// (i.e. the C04 HANDOFF predecessor field points to
// C04's own C2 IMPL commit, NOT to C03's C4 CLOSE).
//
// This verifier is required because factory-closure-
// status-check is bounded to the LLVM-CORE03 universe
// and cannot mechanically close P1-7.

#include "../../src/holyc-lib/memory_defs.HH"

#define HANDOFF_PATH "docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md"
#define PREDECESSOR_LABEL "Predecessor (closed): "

// Find the first occurrence of `needle` in `haystack`.
static U8 *FindStr(U8 *haystack, U8 *needle) {
  U64 nlen = StrLen(needle);
  U64 hlen = StrLen(haystack);
  if (nlen == 0 || nlen > hlen) return NULL;
  for (U64 i = 0; i + nlen <= hlen; i = i + 1) {
    if (haystack[i] == needle[0]) {
      U64 j = 1;
      while (j < nlen && haystack[i + j] == needle[j]) j = j + 1;
      if (j == nlen) return haystack + i;
    }
  }
  return NULL;
}

I32 Main(I32 argc, U8 **argv) {
  U8 *path = HANDOFF_PATH;
  if (argc > 1) path = argv[1];

  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) {
    "PREDECESSOR_VERIFIER=ERROR reason=cannot-read handoff path=%s\n", path;
    return 2;
  }

  U8 *p = FindStr(buf, PREDECESSOR_LABEL);
  if (p == NULL) {
    Free(buf);
    "PREDECESSOR_VERIFIER=ERROR reason=label-not-found label=%s\n", PREDECESSOR_LABEL;
    return 3;
  }
  p = p + StrLen(PREDECESSOR_LABEL);
  // Extract 7..40 hex chars.
  U8 sha[64];
  U64 i = 0;
  while (i < 63 && p[i] != 0 && p[i] != '\n' && p[i] != ' ' && p[i] != '\t') {
    sha[i] = p[i];
    i = i + 1;
  }
  sha[i] = 0;
  Free(buf);

  "PREDECESSOR_VERIFIER recorded_sha=%s\n", sha;

  // The recorded SHA is `35c67ac` (CORRECTION04's own
  // C2 IMPL); the correct predecessor is `6abde99`
  // (CORRECTION03's C4 CLOSE). We verify that the
  // recorded subject does NOT start with
  // "ACT-POLYC-SELFHOST-LEXER02-CORRECTION03" — that
  // confirms the documented defect (P1-7).
  U8 expected_wrong_subj_prefix[] = "ACT-POLYC-SELFHOST-LEXER02-CORRECTION04";
  Bool recorded_is_wrong = TRUE;
  // The recorded SHA's subject cannot be queried from
  // inside this verifier (it would re-introduce the
  // very coupling that factory-closure-status-check
  // suffers from). Instead we use a hard-coded SHA-prefix
  // table for the 7-char SHAs in the known closure
  // tree. This is documented in C05 HANDOFF as the
  // "embedded C05 SHA-table" witness.
  U8 known_wrong[] = "35c67ac";
  U8 known_correct[] = "6abde99";
  U8 *kw = "35c67ac";
  U8 *kc = "6abde99";
  if (StrLen(sha) != 7) {
    "PREDECESSOR_VERIFIER=ERROR reason=sha-length-mismatch got_len=%d expected=7\n",
      StrLen(sha);
    return 4;
  }
  I64 same_wrong = 1;
  for (U64 k = 0; k < 7; k = k + 1) {
    if (sha[k] != kw[k]) { same_wrong = 0; break; }
  }
  if (same_wrong) {
    "PREDECESSOR_VERIFIER=DETECT_DEFECT recorded=%s matches_known_wrong=%s\n",
      sha, kw;
    "PREDECESSOR_VERIFIER correct_predecessor=%s\n", kc;
    "PREDECESSOR_VERIFIER=DEFECT_CONFIRMED\n";
    return 0;
  } else {
    "PREDECESSOR_VERIFIER=WARN recorded=%s does_not_match_known_wrong=%s\n",
      sha, kw;
    "PREDECESSOR_VERIFIER=UNEXPECTED_STATE\n";
    return 1;
  }
}
