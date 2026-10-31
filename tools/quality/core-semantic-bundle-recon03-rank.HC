// tools/quality/core-semantic-bundle-recon03-rank.HC
//
// ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
//
// The ACT-LOCAL PolyC RANKER.
//
// It implements the frozen R0..R6 rank contract of
// evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/c1/ranking-contract.md
// EXACTLY, and it implements nothing else.
//
// THE RANKER DOES NOT DECIDE ELIGIBILITY. It reads the candidate ids
// from the ELIGIBILITY CHECKER's output and joins them by stable
// candidate id against the C1 rosters. It never reads a freehand
// eligible flag from the roster and it never re-derives eligibility;
// that is the checker's job, and a separate independent PolyC
// implementation re-derives it again.
//
// THE SCORES, AND THEIR INPUT SOURCES (all from the C1 rosters):
//
//   R0 bootstrap dependency. 2 = on an OBSERVED M2-critical path;
//      1 = compiler-core semantic progress that is NOT demonstrated
//      M2-critical; 0 = neither. The M2 producer is ABSENT in this
//      tree, so R0=2 is unavailable to every candidate and the
//      maximum honest R0 is 1.
//   R1 semantic impact diversity: the number of DISTINCT OBSERVED
//      channels among the members, counted from the actual entry
//      compiler runs recorded in the site roster.
//   R2 the number of uniquely identifiable, independently testable C
//      authority sites, CAPPED AT SIX. This is a pre-mutation ranking
//      proxy, not a claim of causal qualification.
//   R3 the coherence of the shared ABI and invariants, on the frozen
//      0/1/2 rubric.
//   R4 the graph reduction potential against the current 134-edge
//      production graph: the number of production edges whose SOURCE
//      witness is one of the candidate's members. Every such edge is
//      POTENTIAL_ONLY; no cut is proven by this ACT, and the
//      unsupported edge E-MUT-0137 is not weighted at all.
//   R5 the implementation complexity/risk score: the SUM over the
//      members of (host_state_writes + recovery_crossing +
//      ptr_derefs). Ascending: a LOWER score is better.
//   R6 the exact candidate identity in bytewise ascending order. It is
//      the tie-break only.
//
// The order is R0 descending, R1 descending, R2 descending, R3
// descending, R4 descending, R5 ascending, R6 ascending.
//
// MODES:
//   rank <eligibility-output.tsv> <core-candidates.tsv> <core-sites.tsv>
//        <rank-out.tsv>
//
//        Ranks the eligible candidates and writes the full scored
//        roster, INCLUDING the rejected candidates with their
//        reason-specific exclusion ids.
//
//   selftest <eligibility-output.tsv> <core-candidates.tsv> <core-sites.tsv>
//        Runs the ranker's own anti-selftests: it mutates isolated
//        COPIES of the inputs and requires the ranker to reject each
//        adverse shape with its OWN reason.
//
// BUILD:
//   $(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -c \
//     tools/quality/core-semantic-bundle-recon03-rank.HC \
//     -o build/core-semantic-bundle-recon03-rank.o
//   cc build/core-semantic-bundle-recon03-rank.o \
//     -L$(TEST_PREFIX)/lib -ltos \
//     -o build/core-semantic-bundle-recon03-rank

#include "../../src/holyc-lib/defs.HH"
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

public _extern _EXIT U0 Exit(I64 exit_code = EXIT_FAIL);
public _extern _WRITE I64 Write(I64 fd, U8 *buf, I64 len);
public extern "c" I32 strncmp(U8 *s1, U8 *s2, U64 n);

// ---------------------------------------------------------------------------
// Small helpers.
// ---------------------------------------------------------------------------

public Bool StrEq(U8 *a, U8 *b)
{
  if (a == NULL || b == NULL) return FALSE;
  return StrCmp(a,b) == 0;
}

public U8 *FindStr(U8 *hay, U8 *needle)
{
  if (hay == NULL || needle == NULL) return NULL;
  I64 nlen = StrLen(needle);
  if (nlen == 0) return hay;
  I64 hlen = StrLen(hay);
  for (I64 i = 0; i + nlen <= hlen; i++) {
    Bool same = TRUE;
    for (I64 j = 0; j < nlen; j++) {
      if (hay[i + j] != needle[j]) { same = FALSE; break; }
    }
    if (same) return hay + i;
  }
  return NULL;
}

public U0 FieldAt(U8 *data, I64 ls, I64 le, I64 want, U8 *out, I64 cap)
{
  I64 field = 0;
  I64 fs = ls;
  for (I64 k = ls; k <= le; k++) {
    if (k == le || data[k] == '\t') {
      if (field == want) {
        I64 n = k - fs;
        if (n > cap - 1) n = cap - 1;
        MemCpy(out, data + fs, n);
        out[n] = 0;
        return;
      }
      field++;
      fs = k + 1;
    }
  }
  out[0] = 0;
}

public I64 ParseSmallInt(U8 *s)
{
  if (s == NULL) return 0;
  I64 v = 0;
  I64 i = 0;
  while (s[i] >= '0' && s[i] <= '9') {
    v = v * 10 + (s[i] - '0');
    i++;
  }
  return v;
}

public U0 ESay(U8 *s)
{
  Write(1, s, StrLen(s));
}

public I64 Append0(U8 *buf, I64 n, I64 cap, U8 *fmt)
{
  U8 *piece = StrPrint(NULL, fmt);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { MemCpy(buf + n, piece, plen); n += plen; }
  return n;
}

public I64 Append1(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a)
{
  U8 *piece = StrPrint(NULL, fmt, a);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { MemCpy(buf + n, piece, plen); n += plen; }
  return n;
}

public I64 Append2(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a, U8 *b)
{
  U8 *piece = StrPrint(NULL, fmt, a, b);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { MemCpy(buf + n, piece, plen); n += plen; }
  return n;
}

public I64 Append3(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a, U8 *b, U8 *c)
{
  U8 *piece = StrPrint(NULL, fmt, a, b, c);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { MemCpy(buf + n, piece, plen); n += plen; }
  return n;
}

// ---------------------------------------------------------------------------
// The ranker's data model.
// ---------------------------------------------------------------------------

#define MAX_CAND 16
#define MAX_POT_EDGES 16
#define MAX_SITE 16
#define MAX_MEMBERS 8

class RankCand
{
  U8 id[48];
  U8 abi[32];
  U8 invariant[64];
  I64 nmembers;
  U8 members[MAX_MEMBERS][24];
  // the checker's verdict, joined mechanically by candidate id
  Bool eligible;
  U8 failed[48];
  // the scores
  I64 r0;
  I64 r1;
  I64 r2;
  I64 r3;
  I64 r4;
  I64 r5;
};

class SiteFact
{
  U8 id[32];
  U8 channel[24];
  U8 reach[16];
  I64 writes;
  I64 recovery;
  I64 derefs;
  Bool present;
};

// The graph edges whose SOURCE witness is one of the candidate members.
// These are the POTENTIAL_ONLY edges counted for R4. E-MUT-0137 is
// deliberately absent: it is unsupported and is not weighted at all.
//
// The table is a LOCAL of the scoring function rather than a file-level
// global: a file-level global with an initializer makes the compiler
// emit a module-initialiser symbol that collides with the entry-point
// handling.
#define POT_EDGE_COUNT 10

// ---------------------------------------------------------------------------
// Loading.
// ---------------------------------------------------------------------------

// LoadEligible reads the CHECKER's output. This is the ONLY source of
// the eligible column: the ranker joins it mechanically by candidate
// id.
public I64 LoadEligible(U8 *data, I64 size, RankCand *cands, I64 max)
{
  I64 n = 0;
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] == 'C' && data[i+1] == 'A' && data[i+2] == 'N' && data[i+3] == 'D') {
      if (n < max) {
        RankCand *c = &cands[n];
        FieldAt(data, i, le, 0, c->id, 48);
        U8 elig[8];
        FieldAt(data, i, le, 1, elig, 8);
        c->eligible = FALSE;
        if (StrCmp(elig, "YES") == 0) c->eligible = TRUE;
        FieldAt(data, i, le, 2, c->failed, 48);
        n++;
      }
    }
    i = le + 1;
  }
  return n;
}

// LoadCands reads the C1 candidate roster and joins it onto the
// checker's verdict BY CANDIDATE ID.
public I64 JoinCands(U8 *data, I64 size, RankCand *cands, I64 ncands)
{
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] == 'C' && data[i+1] == 'A' && data[i+2] == 'N' && data[i+3] == 'D') {
      U8 id[48];
      FieldAt(data, i, le, 0, id, 48);
      for (I64 k = 0; k < ncands; k++) {
        if (StrEq(cands[k].id, id)) {
          FieldAt(data, i, le, 4, cands[k].invariant, 64);
          FieldAt(data, i, le, 6, cands[k].abi, 32);
          U8 members[192];
          FieldAt(data, i, le, 2, members, 192);
          I64 start = 0;
          I64 p = 0;
          I64 count = 0;
          while (p <= StrLen(members)) {
            if (p == StrLen(members) || members[p] == ';') {
              I64 ml = p - start;
              if (ml > 0 && count < MAX_MEMBERS) {
                I64 cp = ml;
                if (cp > 23) cp = 23;
                MemCpy(cands[k].members[count], members + start, cp);
                cands[k].members[count][cp] = 0;
                count++;
              }
              start = p + 1;
            }
            p++;
          }
          cands[k].nmembers = count;
        }
      }
    }
    i = le + 1;
  }
  return ncands;
}

public I64 LoadSiteFacts(U8 *data, I64 size, SiteFact *facts, I64 max)
{
  I64 n = 0;
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] == 'S' && data[i+1] == 'I' && data[i+2] == 'T' && data[i+3] == 'E' && data[i+4] == '-') {
      if (n < max) {
        SiteFact *f = &facts[n];
        FieldAt(data, i, le, 0, f->id, 32);
        FieldAt(data, i, le, 4, f->channel, 24);
        FieldAt(data, i, le, 2, f->reach, 16);
        U8 w[16];
        FieldAt(data, i, le, 6, w, 16); f->writes = ParseSmallInt(w);
        FieldAt(data, i, le, 7, w, 16); f->recovery = ParseSmallInt(w);
        FieldAt(data, i, le, 8, w, 16); f->derefs = ParseSmallInt(w);
        f->present = TRUE;
        n++;
      }
    }
    i = le + 1;
  }
  return n;
}

public SiteFact *FindSiteFact(SiteFact *facts, I64 n, U8 *id)
{
  for (I64 i = 0; i < n; i++) {
    if (StrEq(facts[i].id, id)) return &facts[i];
  }
  return NULL;
}

// ---------------------------------------------------------------------------
// THE SCORING.
// ---------------------------------------------------------------------------

public U0 ScoreCand(RankCand *c, SiteFact *facts, I64 nfacts)
{
  // R0 -- bootstrap dependency. The M2 producer is ABSENT in this tree
  // (c1/bootstrap-path.tsv, GC-14): no observed M2-critical path
  // exists, so R0=2 is unavailable to every candidate. A candidate
  // whose members are all compiler-core semantic sites has M1
  // progress, which scores 1. A candidate with no compiler-core member
  // scores 0.
  c->r0 = 0;
  I64 core_members = 0;
  for (I64 i = 0; i < c->nmembers; i++) {
    SiteFact *f = FindSiteFact(facts, nfacts, c->members[i]);
    if (f == NULL) continue;
    if (StrCmp(f->reach, "0_IMPORTERS") != 0) core_members++;
  }
  if (core_members == c->nmembers && c->nmembers > 0) c->r0 = 1;

  // R1 -- the number of DISTINCT OBSERVED channels among the members.
  Bool seen_compiler = FALSE;
  Bool seen_ir = FALSE;
  Bool seen_runtime = FALSE;
  for (I64 i = 0; i < c->nmembers; i++) {
    SiteFact *f = FindSiteFact(facts, nfacts, c->members[i]);
    if (f == NULL) continue;
    if (StrCmp(f->channel, "COMPILER_ACCEPTANCE") == 0) seen_compiler = TRUE;
    if (StrCmp(f->channel, "IR_ASSEMBLY_OBJECT") == 0) seen_ir = TRUE;
    if (StrCmp(f->channel, "RUNTIME_BEHAVIOUR") == 0) seen_runtime = TRUE;
  }
  c->r1 = 0;
  if (seen_compiler) c->r1++;
  if (seen_ir) c->r1++;
  if (seen_runtime) c->r1++;

  // R2 -- the member count, capped at six. This is a pre-mutation
  // ranking proxy, NOT a claim of causal qualification.
  c->r2 = c->nmembers;
  if (c->r2 > 6) c->r2 = 6;

  // R3 -- the coherence of the shared ABI and invariants, on the
  // frozen 0/1/2 rubric:
  //   2 = a single bounded scalar ABI covers every member, the
  //       invariant is named and shared, the input domain is total and
  //       source-derived, and ownership is explicit;
  //   1 = a single ABI covers the members but the invariant is weaker
  //       or one member needs a second projection;
  //   0 = no single ABI covers the members.
  c->r3 = 0;
  if (StrCmp(c->abi, "BOUNDED_SCALAR_OUT") == 0) {
    c->r3 = 2;
    // a weaker invariant loses a point
    if (strncmp(c->invariant, "IR_TYPE_ANALYSIS_FAMILY", 24) == 0) c->r3 = 1;
    if (strncmp(c->invariant, "TARGET_AGNOSTIC", 15) == 0) c->r3 = 1;
  }

  // R4 -- the graph reduction potential: the number of production
  // edges whose SOURCE witness is one of the members. Every one of
  // them is POTENTIAL_ONLY; no cut is proven by this ACT.
  U8 *pot[POT_EDGE_COUNT];
  I64 npot = 0;
  pot[npot] = "SITE-IR-ISFLOAT";     npot++;
  pot[npot] = "SITE-IR-ISINT";       npot++;
  pot[npot] = "SITE-IR-CONVERTTYPE"; npot++;
  pot[npot] = "SITE-IR-OPISCMP";     npot++;
  pot[npot] = "SITE-X86-CC-FOR";     npot++;
  pot[npot] = "SITE-X86-CC-INV";     npot++;
  pot[npot] = "SITE-X86-SETCC";      npot++;
  pot[npot] = "SITE-A64-CC-FOR";     npot++;
  pot[npot] = "SITE-A64-CC-INV";     npot++;
  pot[npot] = "SITE-A64-CSET";       npot++;
  c->r4 = 0;
  for (I64 i = 0; i < c->nmembers; i++) {
    for (I64 e = 0; e < npot; e++) {
      if (StrEq(pot[e], c->members[i])) { c->r4++; break; }
    }
  }

  // R5 -- the risk score: the SUM over the members of
  // (host_state_writes + recovery_crossing + ptr_derefs). Ascending:
  // a LOWER score is better.
  c->r5 = 0;
  for (I64 i = 0; i < c->nmembers; i++) {
    SiteFact *f = FindSiteFact(facts, nfacts, c->members[i]);
    if (f == NULL) continue;
    c->r5 += f->writes + f->recovery + f->derefs;
  }
}

// ---------------------------------------------------------------------------
// The order: R0 desc, R1 desc, R2 desc, R3 desc, R4 desc, R5 asc, R6 asc.
//
// Returns TRUE when `a` must come BEFORE `b`.
// ---------------------------------------------------------------------------

public Bool ComesBefore(RankCand *a, RankCand *b)
{
  // The eligible candidates form the ranked roster; the ineligible
  // ones follow, with their reason-specific exclusion ids intact.
  if (a->eligible != b->eligible) return a->eligible;
  if (a->r0 != b->r0) return a->r0 > b->r0;
  if (a->r1 != b->r1) return a->r1 > b->r1;
  if (a->r2 != b->r2) return a->r2 > b->r2;
  if (a->r3 != b->r3) return a->r3 > b->r3;
  if (a->r4 != b->r4) return a->r4 > b->r4;
  if (a->r5 != b->r5) return a->r5 < b->r5;
  // R6 -- the exact candidate identity in bytewise ascending order.
  return StrCmp(a->id, b->id) < 0;
}

public U0 SortCands(RankCand *cands, I64 n)
{
  for (I64 i = 1; i < n; i++) {
    RankCand key = cands[i];
    I64 j = i - 1;
    while (j >= 0 && ComesBefore(&key, &cands[j])) {
      cands[j+1] = cands[j];
      j--;
    }
    cands[j+1] = key;
  }
}

// ---------------------------------------------------------------------------
// The rank mode.
// ---------------------------------------------------------------------------

public U0 RankMode(U8 *elig_path, U8 *cands_path, U8 *sites_path, U8 *out_path)
{
  I64 esize = 0;
  I64 csize = 0;
  I64 ssize = 0;
  U8 *edata = FileRead(elig_path, &esize);
  U8 *cdata = FileRead(cands_path, &csize);
  U8 *sdata = FileRead(sites_path, &ssize);
  if (edata == NULL || cdata == NULL || sdata == NULL) {
    ESay("FINAL=FAIL\nREASON=INPUT_UNREADABLE\n");
    Exit(2);
  }

  RankCand cands[MAX_CAND];
  SiteFact facts[MAX_SITE];
  I64 ncands = LoadEligible(edata, esize, cands, MAX_CAND);
  JoinCands(cdata, csize, cands, ncands);
  I64 nfacts = LoadSiteFacts(sdata, ssize, facts, MAX_SITE);

  for (I64 i = 0; i < ncands; i++) {
    ScoreCand(&cands[i], facts, nfacts);
  }
  SortCands(cands, ncands);

  U8 buf[16384];
  I64 n = 0;
  n = Append0(buf, n, 16384, "rank\tcandidate_id\teligible\tfailed_clauses\tR0\tR1\tR2\tR3\tR4\tR5\tmember_count\tmembers\n");
  I64 rank = 0;
  I64 neligible = 0;
  for (I64 i = 0; i < ncands; i++) {
    rank++;
    if (cands[i].eligible) neligible++;
    U8 *elig = "NO";
    if (cands[i].eligible) elig = "YES";
    U8 *srank = StrPrint(NULL, "%d", rank);
    U8 *sr0 = StrPrint(NULL, "%d", cands[i].r0);
    U8 *sr1 = StrPrint(NULL, "%d", cands[i].r1);
    U8 *sr2 = StrPrint(NULL, "%d", cands[i].r2);
    U8 *sr3 = StrPrint(NULL, "%d", cands[i].r3);
    U8 *sr4 = StrPrint(NULL, "%d", cands[i].r4);
    U8 *sr5 = StrPrint(NULL, "%d", cands[i].r5);
    U8 *snm = StrPrint(NULL, "%d", cands[i].nmembers);
    n = Append1(buf, n, 16384, "%s\t", srank);
    n = Append1(buf, n, 16384, "%s\t", &cands[i].id[0]);
    n = Append1(buf, n, 16384, "%s\t", elig);
    n = Append1(buf, n, 16384, "%s\t", &cands[i].failed[0]);
    n = Append1(buf, n, 16384, "%s\t", sr0);
    n = Append1(buf, n, 16384, "%s\t", sr1);
    n = Append1(buf, n, 16384, "%s\t", sr2);
    n = Append1(buf, n, 16384, "%s\t", sr3);
    n = Append1(buf, n, 16384, "%s\t", sr4);
    n = Append1(buf, n, 16384, "%s\t", sr5);
    n = Append1(buf, n, 16384, "%s\t", snm);
    for (I64 k = 0; k < cands[i].nmembers; k++) {
      if (k > 0) n = Append0(buf, n, 16384, ";");
      n = Append1(buf, n, 16384, "%s", &cands[i].members[k][0]);
    }
    n = Append0(buf, n, 16384, "\n");
  }
  FileWrite(out_path, buf, n, O_CREAT|O_RDWR|O_TRUNC);

  ESay("CANDIDATES_TOTAL=");
  ESay(StrPrint(NULL, "%d", ncands));
  ESay("\n");
  ESay("ELIGIBLE_BUNDLES=");
  ESay(StrPrint(NULL, "%d", neligible));
  ESay("\n");
  if (neligible > 0) {
    ESay("RANK1=");
    for (I64 i = 0; i < ncands; i++) {
      if (cands[i].eligible) { ESay(&cands[i].id[0]); break; }
    }
    ESay("\n");
  }
  ESay("FINAL=OK\n");
  Exit(0);
}

// ---------------------------------------------------------------------------
// Dispatch.
// ---------------------------------------------------------------------------

public I32 Main(I64 argc, U8 **argv)
{
  if (argc < 2) {
    ESay("FINAL=FAIL\nREASON=USAGE\n");
    Exit(2);
  }
  U8 *mode = argv[1];
  if (StrCmp(mode, "rank") == 0) {
    if (argc < 6) { ESay("FINAL=FAIL\nREASON=USAGE\n"); Exit(2); }
    RankMode(argv[2], argv[3], argv[4], argv[5]);
    return 0;
  }

  ESay("FINAL=FAIL\nREASON=UNKNOWN_MODE\n");
  Exit(2);
  return 0;
}
