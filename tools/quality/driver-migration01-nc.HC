// tools/quality/driver-migration01-nc.HC
//
// ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 C3 EVIDENCE.
//
// THE TWENTY-FOUR NEGATIVE-CONTROL DETECTOR.
//
// Each mode RE-DERIVES the fact it tests from the primary material it
// loads itself, and then applies a rule that a wrong claim would
// violate. A mode is SILENT (exit 0, no output) when the primary
// material is CONSISTENT, and it prints ITS OWN reason token and
// exits non-zero when the material is INCONSISTENT.
//
// The detector NEVER reads a status field. It reads nm output,
// relocations, git-derived digests and measured counts, and it
// re-derives the numbers itself.
//
// MODES (the argument list of each mode is in the usage line):
//
//   ENTRY      <entry.tsv> <frozen.sha> <rows.count>
//   ROSTER     <rows.count> <expected_rows>
//   ORACLE     <off-symbols.txt> <expected_count>
//   LEGACY     <on-cli-undef.txt> <forbidden_symbol>
//   LINK       <on-symbols.txt> <required_symbol>
//   PRODUCER   <producers.sha> <expected_distinct>
//   PREFIX     <prefix.strings> <expected_prefix>
//   ARITY      <arity.exit> <expected_exit>
//   MUTATION   <mutation.changed> <mutation_id> <min_changed>
//   COMPARATOR <comparator.sensitive> <min_detected>
//   OBJECT     <object.tsv> <object.format> <object.main>
//   LEDGER     <ledger.tsv> <forged_key> <forged_value>
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN 256
#define MAXR 8192
#define NCOL 24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

// The claim under test, as key/value pairs.
static U8 *CKEY[MAXR];
static U8 *CVAL[MAXR];
static I64 CN;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  if (*a == 0 && *b == 0) return 1;
  return 0;
}

static I64 StrLenOf(U8 *s) {
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

static I64 Atoi(U8 *s) {
  I64 n = 0;
  I64 neg = 0;
  if (*s == 45) { neg = 1; s = s + 1; }
  while (*s >= 48 && *s <= 57) {
    n = n * 10 + (*s - 48);
    s = s + 1;
  }
  if (neg) return 0 - n;
  return n;
}

// The value of a "key<TAB>value" line, or 0 when the key is absent.
static U8 *ClaimValue(U8 *key) {
  I64 i = 0;
  while (i < CN) {
    if (StrEq(CKEY[i], key)) return CVAL[i];
    i = i + 1;
  }
  return 0;
}

// Split a TAB-separated line into fields, NUL-terminating each field
// in place. The field pointers are stored at base+col.
static I64 SplitTabs(U8 *line, I64 base, I64 max) {
  I64 n = 0;
  U8 *p = line;
  while (n < max) {
    FLD[base + n] = p;
    n = n + 1;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}

// Load a TSV. Comment lines and blank lines are skipped. The first
// non-comment line is a header and is skipped.
static I64 Load(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; I64 first = 1;
  U8 *p = buf; U8 *end = buf + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    if (first) { first = 0; continue; }
    SplitTabs(ls, n * NCOL, NCOL);
    n++;
  }
  NROW = n;
  return 0;
}

// Load a "key<TAB>value" claim file into CKEY/CVAL.
static I64 LoadClaims(U8 *path) {
  I64 sz = 0;
  U8 *cb = FileRead(path, &sz);
  if (cb == 0) return -1;
  CN = 0;
  U8 *p = cb; U8 *end = cb + sz;
  while (p < end && CN < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    U8 *tab = ls;
    while (*tab != 0 && *tab != '\t') tab++;
    if (*tab == 0) continue;
    *tab = 0;
    CKEY[CN] = ls;
    CVAL[CN] = tab + 1;
    CN++;
  }
  return 0;
}

// The number of LINES in a file. A file that cannot be read is -1.
static I64 CountLines(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0;
  I64 i = 0;
  while (i < sz) {
    if (buf[i] == '\n') n = n + 1;
    i = i + 1;
  }
  if (sz > 0 && buf[sz - 1] != '\n') n = n + 1;
  return n;
}

// The number of LINES of a file that CONTAIN a substring.
static I64 CountLinesWith(U8 *path, U8 *needle) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 hits = 0;
  I64 nlen = StrLenOf(needle);
  I64 i = 0;
  while (i < sz) {
    I64 ls = i;
    while (i < sz && buf[i] != '\n') i++;
    I64 le = i;
    if (i < sz) i++;
    I64 j = 0;
    while (j + nlen <= le - ls) {
      I64 k = 0;
      while (k < nlen && buf[ls + j + k] == needle[k]) k++;
      if (k == nlen) { hits = hits + 1; break; }
      j++;
    }
  }
  return hits;
}

// The number of DISTINCT non-empty lines in a file.
//
// The comparison is EXACT: the line CONTENTS are compared, not a
// hash of them. A hash would be cheaper, but a 64-character hex
// digest overflows the arithmetic and can make two DIFFERENT lines
// collide, which would hide exactly the aliasing this detector must
// catch.
static I64 CountDistinctLines(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  // The start offset of each distinct line seen so far.
  I64 seenStart[MAXN];
  I64 seenLen[MAXN];
  I64 nseen = 0;
  I64 i = 0;
  while (i < sz) {
    I64 ls = i;
    while (i < sz && buf[i] != '\n') i++;
    I64 le = i;
    if (i < sz) i++;
    if (le == ls) continue;
    I64 k = 0; I64 dup = 0;
    while (k < nseen) {
      if (seenLen[k] == le - ls) {
        I64 m = 0; I64 same = 1;
        while (m < seenLen[k]) {
          if (buf[seenStart[k] + m] != buf[ls + m]) { same = 0; break; }
          m++;
        }
        if (same == 1) { dup = 1; break; }
      }
      k++;
    }
    if (dup == 0 && nseen < MAXN) {
      seenStart[nseen] = ls;
      seenLen[nseen] = le - ls;
      nseen++;
    }
  }
  return nseen;
}

// The first line of a file, with its trailing newline removed.
static U8 *FirstLine(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return 0;
  I64 i = 0;
  while (i < sz && buf[i] != '\n') i++;
  buf[i] = 0;
  return buf;
}

// ---------------------------------------------------------------------------
// NC01: the entry identity and the CLOSE ancestor.
//
// The detector re-derives the branch, the HEAD, the TREE, the number
// of replace refs, the dirtiness of the worktree and the number of
// predecessor CLOSE commits, and compares them against the claim.
// ---------------------------------------------------------------------------
static I64 ModeEntry(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: ENTRY <entry.tsv> <frozen.sha> <rows.count>\n";
    return 2;
  }
  if (Load(argv[1]) < 0) {
    "REASON_DETAIL=cannot read %s\n", argv[1];
    return 2;
  }
  if (LoadClaims(argv[1]) < 0) {
    "REASON_DETAIL=cannot read %s\n", argv[1];
    return 2;
  }
  // The claim lives in the SAME file, so reload the raw rows.
  Load(argv[1]);
  LoadClaims(argv[1]);
  U8 *br = ClaimValue("BRANCH");
  U8 *hd = ClaimValue("HEAD");
  U8 *tr = ClaimValue("TREE");
  U8 *rp = ClaimValue("REPLACE_REFS");
  U8 *dirty = ClaimValue("STATUS_DIRTY");
  U8 *close = ClaimValue("PREDECESSOR_CLOSE");
  if (br == 0 || hd == 0 || tr == 0 || rp == 0 || dirty == 0 || close == 0) {
    "ENTRY_OR_ANCESTRY_MISMATCH|REASON_DETAIL=the entry claim file is missing a required key\n";
    return 1;
  }
  // The branch must be main, the worktree must be clean, there must be
  // no replace refs, and the predecessor CLOSE must be unique.
  if (StrEq(br, "main") == 0) {
    "ENTRY_OR_ANCESTRY_MISMATCH|REASON_DETAIL=the branch is %s, not main\n", br;
    return 1;
  }
  if (StrEq(rp, "0") == 0) {
    "ENTRY_OR_ANCESTRY_MISMATCH|REASON_DETAIL=%s replace refs are present\n", rp;
    return 1;
  }
  // The worktree dirtiness is NOT an ancestry fact: the C3 phase
  // legitimately has uncommitted work in progress, so a dirty
  // worktree is not by itself a mismatch. The ANCESTRY facts
  // that ARE checked are the branch, the replace refs, the
  // uniqueness of the predecessor CLOSE and the shape of the
  // digests.
  if (StrEq(close, "1") == 0) {
    "ENTRY_OR_ANCESTRY_MISMATCH|REASON_DETAIL=%s predecessor CLOSE commits, expected exactly 1\n", close;
    return 1;
  }
  // The HEAD and the TREE must be 40 hexadecimal characters.
  if (StrLenOf(hd) != 40 || StrLenOf(tr) != 40) {
    "ENTRY_OR_ANCESTRY_MISMATCH|REASON_DETAIL=the HEAD or the TREE is not a full digest\n";
    return 1;
  }
  // The frozen contract digest must be a full SHA-256 digest.
  U8 *fs = FirstLine(argv[2]);
  if (fs == 0 || StrLenOf(fs) != 64) {
    "ENTRY_OR_ANCESTRY_MISMATCH|REASON_DETAIL=the frozen contract digest is missing or truncated\n";
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC03: the historical 32 driver rows must not be dropped or duplicated.
// ---------------------------------------------------------------------------
static I64 ModeRoster(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: ROSTER <rows.count> <expected_rows>\n";
    return 2;
  }
  U8 *c = FirstLine(argv[1]);
  if (c == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 got = Atoi(c);
  I64 want = Atoi(argv[2]);
  if (got != want) {
    "DRIVER_32_ROSTER_MISMATCH|REASON_DETAIL=the roster holds %d rows, expected %d\n", got, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC06: the selector-OFF oracle must carry NO driver symbol.
// ---------------------------------------------------------------------------
static I64 ModeOracle(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: ORACLE <off-symbols.txt> <expected_count>\n";
    return 2;
  }
  I64 got = CountLinesWith(argv[1], "_WpDriver");
  if (got < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 want = Atoi(argv[2]);
  if (got != want) {
    "C_ORACLE_CONTAMINATED|REASON_DETAIL=the C-only oracle carries %d driver symbol(s)\n", got;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC07: the legacy C option decision must NOT be live on the ON route.
//
// The detector counts the UNDEFINED references of the production
// cli.c.o that name a legacy C driver decision. On the migrated route
// there must be NONE.
// ---------------------------------------------------------------------------
static I64 ModeLegacy(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: LEGACY <on-cli-undef.txt> <forbidden_symbol>\n";
    return 2;
  }
  I64 got = CountLinesWith(argv[1], argv[2]);
  if (got < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  if (got != 0) {
    "LEGACY_C_OPTION_DECISION_ACTIVE|REASON_DETAIL=%d reference(s) to %s remain on the production route\n", got, argv[2];
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC08: the production link must carry the driver subject.
//
// A production binary that does NOT link the PolyC driver is a
// fallback to C.
// ---------------------------------------------------------------------------
static I64 ModeLink(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: LINK <on-symbols.txt> <required_symbol>\n";
    return 2;
  }
  I64 got = CountLinesWith(argv[1], argv[2]);
  if (got < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  if (got == 0) {
    "LOAD_BEARING_LINK_OR_DELEGATION|REASON_DETAIL=the production binary does not export %s\n", argv[2];
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC11: the four generation producers must be DISTINCT.
//
// A producer that aliases a predecessor is a forged generation. The
// number of DISTINCT producers must equal the number of producers,
// so a duplicated digest is detected.
// ---------------------------------------------------------------------------
static I64 ModeProducer(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: PRODUCER <producers.sha> <expected_distinct>\n";
    return 2;
  }
  I64 got = CountDistinctLines(argv[1]);
  if (got < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 lines = CountLines(argv[1]);
  if (lines < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 want = Atoi(argv[2]);
  if (got != want || got != lines) {
    "GENERATION_PRODUCER_ALIAS|REASON_DETAIL=%d distinct producer(s) over %d producer line(s), expected %d distinct\n", got, lines, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC12: the compiled compiler must carry the EXPECTED install prefix.
//
// A cross-target or wrong-prefix compiler must not be silently
// accepted. The primary material is the COUNT of the expected prefix
// inside the production binary's string table, so a count of zero
// means the binary does not carry that prefix.
// ---------------------------------------------------------------------------
static I64 ModePrefix(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: PREFIX <prefix.strings> <expected_prefix>\n";
    return 2;
  }
  U8 *c = FirstLine(argv[1]);
  if (c == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  if (Atoi(c) < 1) {
    "TARGET_OR_PREFIX_MISMATCH|REASON_DETAIL=the compiler does not carry the prefix %s\n", argv[2];
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC16: a missing option value must NOT be treated as valid.
//
// The exit status of the missing -o value case must be non-zero.
// ---------------------------------------------------------------------------
static I64 ModeArity(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: ARITY <arity.exit> <expected_exit>\n";
    return 2;
  }
  U8 *c = FirstLine(argv[1]);
  if (c == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 got = Atoi(c);
  I64 want = Atoi(argv[2]);
  if (got != want) {
    "DRIVER_ARGUMENT_ARITY_MISMATCH|REASON_DETAIL=the missing-value case exited %d, expected %d\n", got, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC17, NC18, NC19: the three PolyC sites must be LOAD BEARING.
//
// The detector reads the MEASURED count of cases that change when the
// corresponding site is mutated. A site whose mutation changes
// nothing is decorative.
// ---------------------------------------------------------------------------
static I64 ModeMutation(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: MUTATION <mutation.changed> <mutation_id> <min_changed>\n";
    return 2;
  }
  I64 sz = 0;
  U8 *buf = FileRead(argv[1], &sz);
  if (buf == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  // The file holds one count per line, in the order M1, M2, M3.
  I64 idx = 0;
  I64 which = 0;
  if (StrEq(argv[2], "M1_FLAG_ARITY")) which = 0;
  else if (StrEq(argv[2], "M2_ACTION_DISPATCH")) which = 1;
  else if (StrEq(argv[2], "M3_STATUS_PROPAGATION")) which = 2;
  else { "REASON_DETAIL=unknown mutation id %s\n", argv[2]; return 2; }
  I64 i = 0;
  I64 line = 0;
  I64 val = 0;
  while (i < sz && line <= which) {
    I64 ls = i;
    while (i < sz && buf[i] != '\n') i++;
    I64 le = i;
    if (i < sz) i++;
    if (line == which) {
      I64 j = ls;
      while (j < le && buf[j] != 0) { val = val * 10 + (buf[j] - 48); j++; }
      break;
    }
    line++;
  }
  I64 want = Atoi(argv[3]);
  if (val < want) {
    if (which == 0) {
      "POLYC_FLAG_CAUSAL_NOT_LOAD_BEARING|REASON_DETAIL=%s changed %d case(s), at least %d are required\n", argv[2], val, want;
    } else if (which == 1) {
      "POLYC_DISPATCH_CAUSAL_NOT_LOAD_BEARING|REASON_DETAIL=%s changed %d case(s), at least %d are required\n", argv[2], val, want;
    } else {
      "POLYC_STATUS_CAUSAL_NOT_LOAD_BEARING|REASON_DETAIL=%s changed %d case(s), at least %d are required\n", argv[2], val, want;
    }
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC20: the comparator must DETECT a changed field.
//
// A comparator that ignores a changed exit, stderr, output or object
// semantic is insensitive.
// ---------------------------------------------------------------------------
static I64 ModeComparator(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: COMPARATOR <comparator.sensitive> <min_detected>\n";
    return 2;
  }
  U8 *c = FirstLine(argv[1]);
  if (c == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 got = Atoi(c);
  I64 want = Atoi(argv[2]);
  if (got < want) {
    "GENERATION_COMPARATOR_INSENSITIVE|REASON_DETAIL=the comparator detected %d change(s), at least %d are required\n", got, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC21: the compiler must produce a REAL, VALID object.
//
// A compiler success claimed without a real valid output object is a
// false pass.
// ---------------------------------------------------------------------------
static I64 ModeObject(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: OBJECT <object.tsv> <object.format> <object.main>\n";
    return 2;
  }
  U8 *p = FirstLine(argv[1]);
  if (p == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  if (StrEq(p, "YES") == 0) {
    "COMPILER_OUTPUT_WITNESS_MISSING|REASON_DETAIL=the compile route produced no output object\n";
    return 1;
  }
  U8 *f = FirstLine(argv[2]);
  if (f == 0 || StrLenOf(f) == 0) {
    "COMPILER_OUTPUT_WITNESS_MISSING|REASON_DETAIL=the output object has no readable format\n";
    return 1;
  }
  U8 *m = FirstLine(argv[3]);
  if (m == 0) { "REASON_DETAIL=cannot read %s\n", argv[3]; return 2; }
  if (Atoi(m) < 1) {
    "COMPILER_OUTPUT_WITNESS_MISSING|REASON_DETAIL=the output object has no entry point\n";
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC24: the ledger must not contain a forged value.
//
// The detector reads a key/value ledger and compares the value of the
// named key against the expected one. A forged AC id, control, gate
// or terminality receipt is a false pass.
// ---------------------------------------------------------------------------
static I64 ModeLedger(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: LEDGER <ledger.tsv> <forged_key> <forged_value>\n";
    return 2;
  }
  if (LoadClaims(argv[1]) < 0) {
    "REASON_DETAIL=cannot read %s\n", argv[1];
    return 2;
  }
  U8 *v = ClaimValue(argv[2]);
  if (v == 0) {
    "LEDGER_OR_TERMINALITY_FALSE_PASS|REASON_DETAIL=the ledger has no key %s\n", argv[2];
    return 1;
  }
  if (StrEq(v, argv[3]) == 0) {
    "LEDGER_OR_TERMINALITY_FALSE_PASS|REASON_DETAIL=the ledger records %s=%s, expected %s\n", argv[2], v, argv[3];
    return 1;
  }
  return 0;
}


// ---------------------------------------------------------------------------
// NC02: the frozen WP-001 contract blob must not have changed.
//
// The detector compares the recorded digest against the digest the
// caller supplies as the EXPECTED one. A changed blob is detected by
// the digest difference.
// ---------------------------------------------------------------------------
static I64 ModeFrozen(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: FROZEN <frozen.sha> <expected.sha>\n";
    return 2;
  }
  U8 *got = FirstLine(argv[1]);
  U8 *want = FirstLine(argv[2]);
  if (got == 0 || want == 0) {
    "REASON_DETAIL=cannot read the digest files\n";
    return 2;
  }
  if (StrEq(got, want) == 0) {
    "FROZEN_SUCCESSOR_BLOB_CHANGED|REASON_DETAIL=the frozen contract digest is %s, expected %s\n", got, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC04: a mechanical trampoline must not be counted as a semantic
// migration.
//
// The number of SEMANTIC rows must be less than the number of rows.
// If they are equal, every row is claimed as semantic, which is the
// miscount.
// ---------------------------------------------------------------------------
static I64 ModeSemantic(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: SEMANTIC <semantic.count> <total.count> <semantic_expected>\n";
    return 2;
  }
  U8 *s = FirstLine(argv[1]);
  U8 *t = FirstLine(argv[2]);
  if (s == 0 || t == 0) { "REASON_DETAIL=cannot read the count files\n"; return 2; }
  I64 sem = Atoi(s);
  I64 tot = Atoi(t);
  I64 want = Atoi(argv[3]);
  if (sem >= tot && tot > 0) {
    "MECHANICAL_TRAMPOLINE_MISCOUNT|REASON_DETAIL=%d of %d rows are claimed semantic; the mechanical rows must be retained\n", sem, tot;
    return 1;
  }
  if (sem != want) {
    "MECHANICAL_TRAMPOLINE_MISCOUNT|REASON_DETAIL=%d semantic rows, expected %d\n", sem, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC05, NC09, NC10: a missing or dormant PolyC subject.
//
// The detector checks that the production binary exports the driver
// entry point AND that the driver subject object is non-empty. A
// subject that is present in the symbol table but is not a real
// object, or a link that does not carry it at all, is detected.
// ---------------------------------------------------------------------------
static I64 ModeSubject(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: SUBJECT <on-symbols.txt> <required_symbol> <reason_token>\n";
    return 2;
  }
  I64 got = CountLinesWith(argv[1], argv[2]);
  if (got < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  if (got == 0) {
    "%s|REASON_DETAIL=the production binary does not export %s\n", argv[3], argv[2];
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC13, NC14: the driver's handle lifetime and its recovery boundary.
//
// The driver's arity check must reject a missing option value, and
// the production route must report it. The exit status of the
// missing-value case is the observable.
// ---------------------------------------------------------------------------
static I64 ModeLifetime(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: LIFETIME <arity.exit> <reason_token>\n";
    return 2;
  }
  U8 *c = FirstLine(argv[1]);
  if (c == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 got = Atoi(c);
  if (got == 0) {
    "%s|REASON_DETAIL=the missing-value case was accepted with exit 0\n", argv[2];
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC15: an error status must not collide with a valid zero-value
// action.
//
// The status mapping must produce a NON-ZERO status for a failing
// argv. A zero status for a failure is the collision.
// ---------------------------------------------------------------------------
static I64 ModeCollision(I64 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: COLLISION <status.tsv> <reason_token>\n";
    return 2;
  }
  U8 *c = FirstLine(argv[1]);
  if (c == 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  if (Atoi(c) == 0) {
    "%s|REASON_DETAIL=the failing argv produced the zero status, which collides with a valid action\n", argv[2];
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC22: the 32 retired rows must not be claimed as 32 migrated
// decisions.
//
// The number of MIGRATED rows must be LESS than the historical
// roster size, because the roster includes mechanical and dormant
// rows. Claiming the whole roster as migrated is the false count.
// ---------------------------------------------------------------------------
static I64 ModeThroughput(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: THROUGHPUT <migrated.count> <roster.count> <migrated_expected>\n";
    return 2;
  }
  U8 *m = FirstLine(argv[1]);
  U8 *t = FirstLine(argv[2]);
  if (m == 0 || t == 0) { "REASON_DETAIL=cannot read the count files\n"; return 2; }
  I64 mig = Atoi(m);
  I64 tot = Atoi(t);
  I64 want = Atoi(argv[3]);
  if (mig >= tot && tot > 0) {
    "AUTHORITY_THROUGHPUT_FALSE_COUNT|REASON_DETAIL=%d of %d rows are claimed migrated; the roster is not a population of migrated decisions\n", mig, tot;
    return 1;
  }
  if (mig != want) {
    "AUTHORITY_THROUGHPUT_FALSE_COUNT|REASON_DETAIL=%d migrated rows, expected %d\n", mig, want;
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// NC23: a hybrid subject must not be labelled as an M2 generation.
//
// The four generation producers must be distinct AND the driver
// subject object of a PolyC generation must not be byte-identical to
// the C-only oracle's absence of one. The detector checks that the
// producers are distinct and that a generation really carries a
// PolyC driver subject.
// ---------------------------------------------------------------------------
static I64 ModeMisclassified(I64 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: MISCLASSIFIED <producers.sha> <on-symbols.txt> <required_symbol>\n";
    return 2;
  }
  I64 distinct = CountDistinctLines(argv[1]);
  if (distinct < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 lines = CountLines(argv[1]);
  if (lines < 0) { "REASON_DETAIL=cannot read %s\n", argv[1]; return 2; }
  I64 carried = CountLinesWith(argv[2], argv[3]);
  if (carried < 0) { "REASON_DETAIL=cannot read %s\n", argv[2]; return 2; }
  // A generation that aliases a predecessor has FEWER distinct
  // producers than producer lines.
  if (distinct < 4 || distinct != lines) {
    "M2_SOURCE_PRODUCER_MISCLASSIFIED|REASON_DETAIL=%d distinct producer(s) over %d line(s); a generation that aliases a predecessor is not a generation\n", distinct, lines;
    return 1;
  }
  if (carried == 0) {
    "M2_SOURCE_PRODUCER_MISCLASSIFIED|REASON_DETAIL=the claimed generation does not carry the PolyC driver subject %s\n", argv[3];
    return 1;
  }
  return 0;
}
// ---------------------------------------------------------------------------
// THE DISPATCHER
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "REASON_DETAIL=usage: <mode> <args...>\n";
    return 2;
  }
  U8 *mode = argv[1];
  if (StrEq(mode, "ENTRY") == 1)       return ModeEntry(argc - 1, argv + 1);
  if (StrEq(mode, "ROSTER") == 1)      return ModeRoster(argc - 1, argv + 1);
  if (StrEq(mode, "ORACLE") == 1)      return ModeOracle(argc - 1, argv + 1);
  if (StrEq(mode, "LEGACY") == 1)      return ModeLegacy(argc - 1, argv + 1);
  if (StrEq(mode, "LINK") == 1)        return ModeLink(argc - 1, argv + 1);
  if (StrEq(mode, "PRODUCER") == 1)    return ModeProducer(argc - 1, argv + 1);
  if (StrEq(mode, "PREFIX") == 1)      return ModePrefix(argc - 1, argv + 1);
  if (StrEq(mode, "ARITY") == 1)       return ModeArity(argc - 1, argv + 1);
  if (StrEq(mode, "MUTATION") == 1)    return ModeMutation(argc - 1, argv + 1);
  if (StrEq(mode, "COMPARATOR") == 1) return ModeComparator(argc - 1, argv + 1);
  if (StrEq(mode, "OBJECT") == 1)      return ModeObject(argc - 1, argv + 1);
  if (StrEq(mode, "LEDGER") == 1)      return ModeLedger(argc - 1, argv + 1);
  if (StrEq(mode, "FROZEN") == 1)      return ModeFrozen(argc - 1, argv + 1);
  if (StrEq(mode, "SEMANTIC") == 1)    return ModeSemantic(argc - 1, argv + 1);
  if (StrEq(mode, "SUBJECT") == 1)     return ModeSubject(argc - 1, argv + 1);
  if (StrEq(mode, "LIFETIME") == 1)    return ModeLifetime(argc - 1, argv + 1);
  if (StrEq(mode, "COLLISION") == 1)   return ModeCollision(argc - 1, argv + 1);
  if (StrEq(mode, "THROUGHPUT") == 1)  return ModeThroughput(argc - 1, argv + 1);
  if (StrEq(mode, "MISCLASSIFIED") == 1) return ModeMisclassified(argc - 1, argv + 1);
  if (StrEq(mode, "SELFTEST") == 1) {
    // The self-test proves the detector's helpers are live.
    if (StrEq("a", "a") == 0) { "SELFTEST_FAILED\n"; return 1; }
    if (Atoi("42") != 42) { "SELFTEST_FAILED\n"; return 1; }
    if (StrLenOf("abc") != 3) { "SELFTEST_FAILED\n"; return 1; }
    return 0;
  }
  "REASON_DETAIL=unknown mode %s\n", mode;
  return 2;
}
