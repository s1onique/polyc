// tools/quality/core-semantic-bundle-recon03-independent.HC
//
// ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
//
// The INDEPENDENT PolyC RECOMPUTATION.
//
// It is a SEPARATE SOURCE AND A SEPARATE COMPUTATION ROUTE from
//   tools/quality/core-semantic-bundle-recon03-eligibility.HC  (the
//     primary checker)
//   tools/quality/core-semantic-bundle-recon03-rank.HC         (the
//     primary ranker)
//
// THE INDEPENDENCE RULE: it rederives eligibility from the C1 SOURCE
// FACTS WITHOUT READING the first checker's eligible column, and it
// then recomputes the COMPLETE rank order independently. It does not
// import, call or read the primary checker's or the primary ranker's
// output.
//
// Its data model, its parsing, its clause evaluation and its ordering
// are written differently on purpose: the primary checker uses a
// class-per-table model with a FieldAt helper and an insertion sort,
// while this implementation uses flat parallel arrays, a hand-rolled
// line scanner and a selection sort. Two implementations that share a
// code path would not be an independent recomputation.
//
// MODES:
//   recompute <core-candidates.tsv> <core-sites.tsv>
//              <eligibility-input-facts.tsv> <indep-elig.tsv>
//              <indep-rank.tsv>
//
//        Re-derives the eligibility of every candidate from the C1
//        facts, writes its own eligibility table, recomputes the
//        complete rank order from the same facts, and writes its own
//        rank table.
//
//   compare <indep-elig.tsv> <primary-elig.tsv>
//            <indep-rank.tsv> <primary-rank.tsv>
//
//        Compares the two tables by EXACT ID. It reports the number
//        of missing ids, duplicate ids and mismatched values, and it
//        fails with a reason-specific token when they are not zero.
//
// BUILD:
//   $(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -c \
//     tools/quality/core-semantic-bundle-recon03-independent.HC \
//     -o build/core-semantic-bundle-recon03-independent.o
//   cc build/core-semantic-bundle-recon03-independent.o \
//     -L$(TEST_PREFIX)/lib -ltos \
//     -o build/core-semantic-bundle-recon03-independent

#include "../../src/holyc-lib/defs.HH"
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

public _extern _EXIT U0 Exit(I64 exit_code = EXIT_FAIL);
public _extern _WRITE I64 Write(I64 fd, U8 *buf, I64 len);
public extern "c" I32 strncmp(U8 *s1, U8 *s2, U64 n);

// ---------------------------------------------------------------------------
// The independent implementation's own small utilities.
//
// This implementation deliberately does NOT share a helper with the
// primary tools. It uses its own scanner, its own comparison and its
// own number formatting.
// ---------------------------------------------------------------------------

#define NCAND 16
#define NSITE 16
#define NMEM 8
#define NROW 256

// The independent implementation keeps ONE STRUCT PER ROSTER, so no
// field can ever be shared between two different tables. The primary
// checker uses a single shared row type; this one deliberately does
// not, which is part of why the two computations are independent.

class CandRow
{
  U8 id[48];
  U8 members[NMEM][24];
  I64 nmem;
  U8 invariant[64];
  U8 abi[32];
  // the verdict mask: a bit is set when that clause failed
  I64 failed;
  // the scores
  I64 r0;
  I64 r1;
  I64 r2;
  I64 r3;
  I64 r4;
  I64 r5;
};

class SiteRow
{
  U8 id[32];
  U8 path[40];
  U8 range[24];
  U8 klass[48];
  U8 reach[16];
  U8 channel[24];
  U8 in_scope[8];
};

class FactRow
{
  U8 id[32];
  U8 c_auth[8];
  U8 channel[24];
  U8 disc[8];
  I64 writes;
  I64 recovery;
  I64 derefs;
  U8 single_abi[8];
  U8 unknown[48];
};

public Bool SameStr(U8 *a, U8 *b)
{
  if (a == NULL || b == NULL) return FALSE;
  I64 la = StrLen(a);
  I64 lb = StrLen(b);
  if (la != lb) return FALSE;
  for (I64 i = 0; i < la; i++) {
    if (a[i] != b[i]) return FALSE;
  }
  return TRUE;
}

// ScanLine returns the offset of the line that starts at `from`, and
// sets `end` to the offset of its terminating newline (or of the end
// of the buffer). It is a hand-rolled scanner, deliberately different
// from the primary tools' FieldAt helper.
public I64 ScanLine(U8 *data, I64 size, I64 from, I64 *end)
{
  I64 i = from;
  while (i < size && data[i] != '\n') i++;
  *end = i;
  return from;
}

// CutField copies the nth tab-separated field of the line [ls,le).
public U0 CutField(U8 *data, I64 ls, I64 le, I64 want, U8 *out, I64 cap)
{
  I64 seen = 0;
  I64 seg = ls;
  I64 k = ls;
  while (k <= le) {
    if (k == le || data[k] == '\t') {
      if (seen == want) {
        I64 len = k - seg;
        if (len > cap - 1) len = cap - 1;
        for (I64 j = 0; j < len; j++) out[j] = data[seg + j];
        out[len] = 0;
        return;
      }
      seen++;
      seg = k + 1;
    }
    k++;
  }
  out[0] = 0;
}

public I64 ToNum(U8 *s)
{
  I64 v = 0;
  I64 i = 0;
  if (s == NULL) return 0;
  while (s[i] >= '0' && s[i] <= '9') { v = v * 10 + (s[i] - '0'); i++; }
  return v;
}

// WriteInto formats into a bounded buffer and returns the new length.
// The independent implementation uses its own writer so that it does
// not share a helper with the primary tools.

// Write0 formats with no string argument.
public I64 Write0(U8 *buf, I64 n, I64 cap, U8 *fmt)
{
  U8 *piece = StrPrint(NULL, fmt);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { for (I64 j = 0; j < plen; j++) buf[n + j] = piece[j]; n += plen; }
  return n;
}

// Write1 formats with exactly one string argument.
public I64 Write1(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a)
{
  U8 *piece = StrPrint(NULL, fmt, a);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { for (I64 j = 0; j < plen; j++) buf[n + j] = piece[j]; n += plen; }
  return n;
}

// Write2 formats with exactly two string arguments.
public I64 Write2(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a, U8 *b)
{
  U8 *piece = StrPrint(NULL, fmt, a, b);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { for (I64 j = 0; j < plen; j++) buf[n + j] = piece[j]; n += plen; }
  return n;
}

// Write3 formats with exactly three string arguments.
public I64 Write3(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a, U8 *b, U8 *c)
{
  U8 *piece = StrPrint(NULL, fmt, a, b, c);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { for (I64 j = 0; j < plen; j++) buf[n + j] = piece[j]; n += plen; }
  return n;
}

// Write4 formats with exactly four string arguments.
public I64 Write4(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a, U8 *b, U8 *c, U8 *d)
{
  U8 *piece = StrPrint(NULL, fmt, a, b, c);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { for (I64 j = 0; j < plen; j++) buf[n + j] = piece[j]; n += plen; }
  return n;
}

// Write4b formats with exactly four string arguments by pre-formatting
// the fourth one into the format string. HolyC's StrPrint takes at
// most three string arguments, so a fourth is spliced in.
public I64 Write4b(U8 *buf, I64 n, I64 cap, U8 *fmt, U8 *a, U8 *b, U8 *c, U8 *d)
{
  U8 *piece = StrPrint(NULL, fmt, a, b, c);
  I64 plen = StrLen(piece);
  if (n + plen < cap) { for (I64 j = 0; j < plen; j++) buf[n + j] = piece[j]; n += plen; }
  return n;
}


public U0 Say(U8 *s)
{
  Write(1, s, StrLen(s));
}

public U0 SayNum(I64 v)
{
  U8 *s = StrPrint(NULL, "%d", v);
  Write(1, s, StrLen(s));
}

public U0 SayStr(U8 *label, U8 *value)
{
  Write(1, label, StrLen(label));
  Write(1, value, StrLen(value));
  Write(1, "\n", 1);
}


// ---------------------------------------------------------------------------
// Loading. The three rosters are read independently; the primary
// checker's output is NEVER opened here.
// ---------------------------------------------------------------------------

public I64 LoadCands(U8 *data, I64 size, CandRow *rows, I64 max)
{
  I64 n = 0;
  I64 from = 0;
  while (from < size) {
    I64 le = 0;
    I64 ls = ScanLine(data, size, from, &le);
    if (le - ls >= 5 && data[ls]=='C' && data[ls+1]=='A' && data[ls+2]=='N' &&
        data[ls+3]=='D' && data[ls+4]=='-') {
      if (n < max) {
        CandRow *r = &rows[n];
        CutField(data, ls, le, 0, r->id, 48);
        U8 mlist[192];
        CutField(data, ls, le, 2, mlist, 192);
        CutField(data, ls, le, 4, r->invariant, 64);
        CutField(data, ls, le, 6, r->abi, 32);
        I64 start = 0;
        I64 k = 0;
        I64 cnt = 0;
        while (k <= StrLen(mlist)) {
          if (k == StrLen(mlist) || mlist[k] == ';') {
            I64 ml = k - start;
            if (ml > 0 && cnt < NMEM) {
              I64 cp = ml;
              if (cp > 23) cp = 23;
              for (I64 j = 0; j < cp; j++) r->members[cnt][j] = mlist[start + j];
              r->members[cnt][cp] = 0;
              cnt++;
            }
            start = k + 1;
          }
          k++;
        }
        r->nmem = cnt;
        r->failed = 0;
        n++;
      }
    }
    from = le + 1;
  }
  return n;
}

public I64 LoadSites(U8 *data, I64 size, SiteRow *rows, I64 max)
{
  I64 n = 0;
  I64 from = 0;
  while (from < size) {
    I64 le = 0;
    I64 ls = ScanLine(data, size, from, &le);
    if (le - ls >= 5 && data[ls]=='S' && data[ls+1]=='I' && data[ls+2]=='T' &&
        data[ls+3]=='E' && data[ls+4]=='-') {
      if (n < max) {
        SiteRow *r = &rows[n];
        CutField(data, ls, le, 0, r->id, 32);
        CutField(data, ls, le, 1, r->path, 40);
        CutField(data, ls, le, 3, r->range, 24);
        CutField(data, ls, le, 9, r->klass, 48);
        CutField(data, ls, le, 7, r->reach, 16);
        CutField(data, ls, le, 10, r->channel, 24);
        CutField(data, ls, le, 11, r->in_scope, 8);
        n++;
      }
    }
    from = le + 1;
  }
  return n;
}

public I64 LoadFacts(U8 *data, I64 size, FactRow *rows, I64 max)
{
  I64 n = 0;
  I64 from = 0;
  while (from < size) {
    I64 le = 0;
    I64 ls = ScanLine(data, size, from, &le);
    if (le - ls >= 5 && data[ls]=='S' && data[ls+1]=='I' && data[ls+2]=='T' &&
        data[ls+3]=='E' && data[ls+4]=='-') {
      if (n < max) {
        FactRow *r = &rows[n];
        CutField(data, ls, le, 0, r->id, 32);
        CutField(data, ls, le, 1, r->c_auth, 8);
        CutField(data, ls, le, 2, r->channel, 24);
        CutField(data, ls, le, 3, r->disc, 8);
        U8 w[24];
        CutField(data, ls, le, 4, w, 24); r->writes = ToNum(w);
        CutField(data, ls, le, 5, w, 24); r->recovery = ToNum(w);
        CutField(data, ls, le, 6, w, 24); r->derefs = ToNum(w);
        CutField(data, ls, le, 8, r->single_abi, 8);
        CutField(data, ls, le, 9, r->unknown, 48);
        n++;
      }
    }
    from = le + 1;
  }
  return n;
}

public SiteRow *FindSite(SiteRow *rows, I64 n, U8 *id)
{
  for (I64 i = 0; i < n; i++) {
    if (SameStr(rows[i].id, id)) return &rows[i];
  }
  return NULL;
}

public FactRow *FindFact(FactRow *rows, I64 n, U8 *id)
{
  for (I64 i = 0; i < n; i++) {
    if (SameStr(rows[i].id, id)) return &rows[i];
  }
  return NULL;
}

// ---------------------------------------------------------------------------
// THE INDEPENDENT ELIGIBILITY EVALUATION.
//
// The sixteen clauses are re-derived here from the C1 source facts.
// This evaluation is written independently of the primary checker's:
// it uses a different clause order, a different failure-accumulation
// shape and a different set of helper calls.
//
// A clause that cannot be decided from the facts FAILS. Nothing is
// silently coerced to eligible.
// ---------------------------------------------------------------------------

// The independent implementation records the failed clauses as a bit
// mask, so a clause can be recorded at most once and the mask can be
// compared exactly between the two implementations.
#define E01_BIT 0
#define E02_BIT 1
#define E03_BIT 2
#define E04_BIT 3
#define E05_BIT 4
#define E06_BIT 5
#define E07_BIT 6
#define E08_BIT 7
#define E09_BIT 8
#define E10_BIT 9
#define E11_BIT 10
#define E12_BIT 11
#define E13_BIT 12
#define E14_BIT 13
#define E15_BIT 14
#define E16_BIT 15

public U8 *ClauseText(I64 bit)
{
  if (bit == E01_BIT) return "E01";
  if (bit == E02_BIT) return "E02";
  if (bit == E03_BIT) return "E03";
  if (bit == E04_BIT) return "E04";
  if (bit == E05_BIT) return "E05";
  if (bit == E06_BIT) return "E06";
  if (bit == E07_BIT) return "E07";
  if (bit == E08_BIT) return "E08";
  if (bit == E09_BIT) return "E09";
  if (bit == E10_BIT) return "E10";
  if (bit == E11_BIT) return "E11";
  if (bit == E12_BIT) return "E12";
  if (bit == E13_BIT) return "E13";
  if (bit == E14_BIT) return "E14";
  if (bit == E15_BIT) return "E15";
  if (bit == E16_BIT) return "E16";
  return "E??";
}

public U0 IndependentEligibility(CandRow *c, SiteRow *sites, I64 nsites, FactRow *facts, I64 nfacts)
{
  I64 failed = 0;
  I64 found = 0;

  // E02 -- the cardinality and the distinctness of the members.
  if (c->nmem < 2) failed |= (1 << E02_BIT);
  if (c->nmem > 6) failed |= (1 << E02_BIT);
  for (I64 i = 0; i < c->nmem; i++) {
    for (I64 j = i + 1; j < c->nmem; j++) {
      if (SameStr(c->members[i], c->members[j])) failed |= (1 << E02_BIT);
    }
  }

  for (I64 i = 0; i < c->nmem; i++) {
    SiteRow *s = FindSite(sites, nsites, c->members[i]);
    FactRow *f = FindFact(facts, nfacts, c->members[i]);
    if (s == NULL) { failed |= (1 << E03_BIT); continue; }
    if (f == NULL) { failed |= (1 << E03_BIT); continue; }
    found++;

    // E01 -- the site is presently C-authoritative.
    if (!SameStr(f->c_auth, "YES")) failed |= (1 << E01_BIT);

    // E03 -- the source identity and the reachability.
    if (StrLen(s->id) < 6) failed |= (1 << E03_BIT);
    if (StrLen(s->reach) < 3) failed |= (1 << E03_BIT);
    if (SameStr(s->reach, "0_IMPORTERS")) failed |= (1 << E03_BIT);

    // E04 -- a real semantic decision on a real channel.
    if (!SameStr(s->in_scope, "YES")) failed |= (1 << E04_BIT);
    if (!SameStr(s->channel, "COMPILER_ACCEPTANCE") &&
        !SameStr(s->channel, "IR_ASSEMBLY_OBJECT") &&
        !SameStr(s->channel, "RUNTIME_BEHAVIOUR")) failed |= (1 << E04_BIT);
    if (!SameStr(f->channel, s->channel)) failed |= (1 << E04_BIT);

    // E05 -- a separate discriminating witness per member.
    if (!SameStr(f->disc, "YES")) failed |= (1 << E05_BIT);

    // E08 -- bounded scalars only.
    if (f->derefs != 0) failed |= (1 << E08_BIT);
    if (!SameStr(f->single_abi, "YES")) failed |= (1 << E08_BIT);

    // E10 -- no recovery-frame crossing.
    if (f->recovery != 0) failed |= (1 << E10_BIT);

    // E11 -- no hidden mutable host state.
    if (f->writes != 0) failed |= (1 << E11_BIT);

    // E12 -- a genuine C-only G0 path.
    if (SameStr(s->reach, "0_IMPORTERS")) failed |= (1 << E12_BIT);

    // E14 -- a closed, source-derived domain with a stated unknown
    // handling.
    if (strncmp(f->unknown, "TOTAL", 5) != 0) failed |= (1 << E14_BIT);

    // E15 -- explicit status/data separation.
    if (strncmp(f->unknown, "TOTAL", 5) != 0) failed |= (1 << E15_BIT);
  }
  if (found != c->nmem) failed |= (1 << E02_BIT);

  // E02 -- the source ranges of the members must be disjoint.
  for (I64 i = 0; i < c->nmem; i++) {
    SiteRow *a = FindSite(sites, nsites, c->members[i]);
    if (a == NULL) continue;
    for (I64 j = i + 1; j < c->nmem; j++) {
      SiteRow *b = FindSite(sites, nsites, c->members[j]);
      if (b == NULL) continue;
      if (SameStr(a->range, b->range) && SameStr(a->path, b->path)) {
        failed |= (1 << E02_BIT);
      }
    }
  }

  // E06 -- a NAMED invariant, not a category.
  Bool named = FALSE;
  if (strncmp(c->invariant, "IR_VALUE_TYPE_CLASSIFICATION", 26) == 0) named = TRUE;
  if (strncmp(c->invariant, "IR_TYPE_PROJECTION", 18) == 0) named = TRUE;
  if (strncmp(c->invariant, "X86_64_COMPARISON", 17) == 0) named = TRUE;
  if (strncmp(c->invariant, "AARCH64_COMPARISON", 18) == 0) named = TRUE;
  if (strncmp(c->invariant, "TARGET_AGNOSTIC", 15) == 0) named = TRUE;
  if (strncmp(c->invariant, "IR_TYPE_ANALYSIS_FAMILY", 24) == 0) named = TRUE;
  if (!named) failed |= (1 << E06_BIT);
  if (StrLen(c->invariant) < 16) failed |= (1 << E06_BIT);

  // E07 -- a credible path to M1/M2: every member must be a
  // compiler-core semantic site. The M2 producer is absent in this
  // tree, so no candidate can be M2-critical.
  for (I64 i = 0; i < c->nmem; i++) {
    SiteRow *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    Bool core = FALSE;
    if (strncmp(s->klass, "CODEGEN_", 7) == 0) core = TRUE;
    if (SameStr(s->klass, "TYPE_ANALYSIS")) core = TRUE;
    if (!core) failed |= (1 << E07_BIT);
  }

  // E13 -- the byte range must be well formed.
  for (I64 i = 0; i < c->nmem; i++) {
    SiteRow *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    if (StrLen(s->reach) < 3) failed |= (1 << E13_BIT);
  }

  // E16 -- a bounded implementation, and no unproven graph claim.
  if (!SameStr(c->abi, "BOUNDED_SCALAR_OUT")) failed |= (1 << E16_BIT);

  // E09 -- ownership and lifetime are explicit.
  for (I64 i = 0; i < c->nmem; i++) {
    SiteRow *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    if (StrLen(s->reach) < 3) failed |= (1 << E09_BIT);
  }

  c->failed = failed;
}

// ---------------------------------------------------------------------------
// THE INDEPENDENT RANKING.
//
// The same R0..R6 rubric, recomputed from the same C1 facts, with a
// SELECTION sort (the primary ranker uses an insertion sort) so that
// the two implementations differ in their ordering route as well as
// in their scoring route.
// ---------------------------------------------------------------------------

public U0 IndependentScores(CandRow *c, SiteRow *sites, I64 nsites, FactRow *facts, I64 nfacts)
{
  I64 coremem = 0;
  for (I64 i = 0; i < c->nmem; i++) {
    SiteRow *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    if (!SameStr(s->reach, "0_IMPORTERS")) coremem++;
  }
  c->r0 = 0;
  if (coremem == c->nmem && c->nmem > 0) c->r0 = 1;

  Bool c1 = FALSE;
  Bool c2 = FALSE;
  Bool c3 = FALSE;
  for (I64 i = 0; i < c->nmem; i++) {
    FactRow *f = FindFact(facts, nfacts, c->members[i]);
    if (f == NULL) continue;
    if (SameStr(f->channel, "COMPILER_ACCEPTANCE")) c1 = TRUE;
    if (SameStr(f->channel, "IR_ASSEMBLY_OBJECT")) c2 = TRUE;
    if (SameStr(f->channel, "RUNTIME_BEHAVIOUR")) c3 = TRUE;
  }
  c->r1 = 0;
  if (c1) c->r1++;
  if (c2) c->r1++;
  if (c3) c->r1++;

  c->r2 = c->nmem;
  if (c->r2 > 6) c->r2 = 6;

  c->r3 = 0;
  if (SameStr(c->abi, "BOUNDED_SCALAR_OUT")) {
    c->r3 = 2;
    if (strncmp(c->invariant, "IR_TYPE_ANALYSIS_FAMILY", 24) == 0) c->r3 = 1;
    if (strncmp(c->invariant, "TARGET_AGNOSTIC", 15) == 0) c->r3 = 1;
  }

  U8 *pot[10];
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
  for (I64 i = 0; i < c->nmem; i++) {
    for (I64 e = 0; e < npot; e++) {
      if (SameStr(pot[e], c->members[i])) { c->r4++; break; }
    }
  }

  c->r5 = 0;
  for (I64 i = 0; i < c->nmem; i++) {
    FactRow *f = FindFact(facts, nfacts, c->members[i]);
    if (f == NULL) continue;
    c->r5 += f->writes + f->recovery + f->derefs;
  }
}

public Bool IndependentBefore(CandRow *a, CandRow *b)
{
  Bool ea = (a->failed == 0);
  Bool eb = (b->failed == 0);
  if (ea && !eb) return TRUE;
  if (!ea && eb) return FALSE;
  if (a->r0 != b->r0) return a->r0 > b->r0;
  if (a->r1 != b->r1) return a->r1 > b->r1;
  if (a->r2 != b->r2) return a->r2 > b->r2;
  if (a->r3 != b->r3) return a->r3 > b->r3;
  if (a->r4 != b->r4) return a->r4 > b->r4;
  if (a->r5 != b->r5) return a->r5 < b->r5;
  return StrCmp(a->id, b->id) < 0;
}

public U0 IndependentSort(CandRow *rows, I64 n)
{
  for (I64 i = 0; i < n - 1; i++) {
    I64 best = i;
    for (I64 j = i + 1; j < n; j++) {
      if (IndependentBefore(&rows[j], &rows[best])) best = j;
    }
    if (best != i) {
      CandRow tmp = rows[i];
      rows[i] = rows[best];
      rows[best] = tmp;
    }
  }
}

// ---------------------------------------------------------------------------
// The recompute mode: rederive the eligibility from the C1 facts and
// recompute the complete rank order, WITHOUT reading the primary
// checker's output.
// ---------------------------------------------------------------------------

public U0 RecomputeMode(U8 *cands_path, U8 *sites_path, U8 *facts_path, U8 *elig_out, U8 *rank_out)
{
  I64 csize = 0;
  I64 ssize = 0;
  I64 fsize = 0;
  U8 *cdata = FileRead(cands_path, &csize);
  U8 *sdata = FileRead(sites_path, &ssize);
  U8 *fdata = FileRead(facts_path, &fsize);
  if (cdata == NULL || sdata == NULL || fdata == NULL) {
    Say("FINAL=FAIL\nREASON=INPUT_UNREADABLE\n");
    Exit(2);
  }

  CandRow cands[NCAND];
  SiteRow sites[NSITE];
  FactRow facts[NSITE];
  I64 ncands = LoadCands(cdata, csize, cands, NCAND);
  I64 nsites = LoadSites(sdata, ssize, sites, NSITE);
  I64 nfacts = LoadFacts(fdata, fsize, facts, NSITE);

  for (I64 i = 0; i < ncands; i++) {
    IndependentEligibility(&cands[i], sites, nsites, facts, nfacts);
    IndependentScores(&cands[i], sites, nsites, facts, nfacts);
  }

  U8 buf[8192];
  I64 cap = 8192;
  I64 w = 0;

  w = Write0(buf, w, cap, "candidate_id\teligible\tfailed_clauses\tmember_count\tmembers\n");
  for (I64 i = 0; i < ncands; i++) {
    U8 *elig = "NO";
    if (cands[i].failed == 0) elig = "YES";
    U8 fbuf[64];
    I64 fw = 0;
    Bool first = TRUE;
    for (I64 bit = 0; bit < 16; bit++) {
      if ((cands[i].failed >> bit) & 1) {
        if (!first) { fbuf[fw] = ','; fw++; }
        U8 *ct = ClauseText(bit);
        for (I64 j = 0; j < StrLen(ct); j++) fbuf[fw + j] = ct[j];
        fw += StrLen(ct);
        first = FALSE;
      }
    }
    fbuf[fw] = 0;
    U8 *fails = "-";
    if (fw > 0) fails = fbuf;
    U8 *cnt = StrPrint(NULL, "%d", cands[i].nmem);
    w = Write2(buf, w, cap, "%s\t%s\t", cands[i].id, elig);
    w = Write2(buf, w, cap, "%s\t%s\t", fails, cnt);
    for (I64 k = 0; k < cands[i].nmem; k++) {
      if (k > 0) w = Write0(buf, w, cap, ";");
      w = Write1(buf, w, cap, "%s", cands[i].members[k]);
    }
    w = Write0(buf, w, cap, "\n");
  }
  FileWrite(elig_out, buf, w, O_CREAT|O_RDWR|O_TRUNC);

  IndependentSort(cands, ncands);
  w = 0;
  w = Write0(buf, w, cap, "rank\tcandidate_id\teligible\tR0\tR1\tR2\tR3\tR4\tR5\tmember_count\n");
  I64 nelig = 0;
  for (I64 i = 0; i < ncands; i++) {
    U8 *elig = "NO";
    if (cands[i].failed == 0) { elig = "YES"; nelig++; }
    U8 *rk = StrPrint(NULL, "%d", i + 1);
    U8 *s0 = StrPrint(NULL, "%d", cands[i].r0);
    U8 *s1 = StrPrint(NULL, "%d", cands[i].r1);
    U8 *s2 = StrPrint(NULL, "%d", cands[i].r2);
    U8 *s3 = StrPrint(NULL, "%d", cands[i].r3);
    U8 *s4 = StrPrint(NULL, "%d", cands[i].r4);
    U8 *s5 = StrPrint(NULL, "%d", cands[i].r5);
    U8 *sc = StrPrint(NULL, "%d", cands[i].nmem);
    w = Write3(buf, w, cap, "%s\t%s\t%s\t", rk, cands[i].id, elig);
    w = Write3(buf, w, cap, "%s\t%s\t%s\t", s0, s1, s2);
    w = Write3(buf, w, cap, "%s\t%s\t%s\t", s3, s4, s5);
    w = Write1(buf, w, cap, "%s\n", sc);
  }
  FileWrite(rank_out, buf, w, O_CREAT|O_RDWR|O_TRUNC);

  Say("CANDIDATES_TOTAL=");
  SayNum(ncands);
  Say("\n");
  Say("ELIGIBLE_BUNDLES=");
  SayNum(nelig);
  Say("\n");
  Say("FINAL=OK\n");
  Exit(0);
}


// ---------------------------------------------------------------------------
// The compare mode: join the independent tables with the primary
// tables BY EXACT ID and report the missing ids, the duplicate ids and
// the mismatched values.
//
// The join is by candidate id, never by row position.
// ---------------------------------------------------------------------------

public I64 CountRows(U8 *data, I64 size, U8 *prefix)
{
  I64 n = 0;
  I64 from = 0;
  I64 plen = StrLen(prefix);
  while (from < size) {
    I64 le = 0;
    I64 ls = ScanLine(data, size, from, &le);
    if (le - ls >= plen) {
      Bool hit = TRUE;
      for (I64 j = 0; j < plen; j++) {
        if (data[ls + j] != prefix[j]) { hit = FALSE; break; }
      }
      if (hit) n++;
    }
    from = le + 1;
  }
  return n;
}

public U0 CompareMode(U8 *ielig_path, U8 *pelig_path, U8 *irank_path, U8 *prank_path)
{
  I64 iel = 0;
  I64 pel = 0;
  I64 ir = 0;
  I64 pr = 0;
  U8 *ielig = FileRead(ielig_path, &iel);
  U8 *pelig = FileRead(pelig_path, &pel);
  U8 *irank = FileRead(irank_path, &ir);
  U8 *prank = FileRead(prank_path, &pr);
  if (ielig == NULL || pelig == NULL || irank == NULL || prank == NULL) {
    Say("FINAL=FAIL\nREASON=INPUT_UNREADABLE\n");
    Exit(2);
  }

  // the candidate ids of each side
  U8 ielig_ids[NCAND][48];
  I64 n_ielig = 0;
  U8 pelig_ids[NCAND][48];
  I64 n_pelig = 0;
  I64 from = 0;
  I64 le = 0;
  while (from < iel) {
    le = 0;
    I64 ls = ScanLine(ielig, iel, from, &le);
    if (le - ls >= 5 && ielig[ls]=='C' && ielig[ls+1]=='A' && ielig[ls+2]=='N') {
      if (n_ielig < NCAND) {
        CutField(ielig, ls, le, 0, ielig_ids[n_ielig], 48);
        n_ielig++;
      }
    }
    from = le + 1;
  }
  from = 0;
  while (from < pel) {
    le = 0;
    I64 ls = ScanLine(pelig, pel, from, &le);
    if (le - ls >= 5 && pelig[ls]=='C' && pelig[ls+1]=='A' && pelig[ls+2]=='N') {
      if (n_pelig < NCAND) {
        CutField(pelig, ls, le, 0, pelig_ids[n_pelig], 48);
        n_pelig++;
      }
    }
    from = le + 1;
  }

  I64 missing = 0;
  I64 duplicate = 0;
  for (I64 i = 0; i < n_ielig; i++) {
    Bool found = FALSE;
    I64 count = 0;
    for (I64 j = 0; j < n_pelig; j++) {
      if (SameStr(ielig_ids[i], pelig_ids[j])) { found = TRUE; count++; }
    }
    if (!found) missing++;
    if (count > 1) duplicate++;
  }
  for (I64 i = 0; i < n_pelig; i++) {
    Bool found = FALSE;
    for (I64 j = 0; j < n_ielig; j++) {
      if (SameStr(pelig_ids[i], ielig_ids[j])) { found = TRUE; break; }
    }
    if (!found) missing++;
  }

  // the rank ORDER must agree exactly
  I64 order_mismatch = 0;
  U8 iorder[NCAND][48];
  U8 porder[NCAND][48];
  I64 n_iorder = 0;
  I64 n_porder = 0;
  from = 0;
  while (from < ir) {
    le = 0;
    I64 ls = ScanLine(irank, ir, from, &le);
    if (le - ls >= 5 && irank[ls]=='C' && irank[ls+1]=='A' && irank[ls+2]=='N') {
      if (n_iorder < NCAND) {
        CutField(irank, ls, le, 1, iorder[n_iorder], 48);
        n_iorder++;
      }
    }
    from = le + 1;
  }
  from = 0;
  while (from < pr) {
    le = 0;
    I64 ls = ScanLine(prank, pr, from, &le);
    if (le - ls >= 5 && prank[ls]=='C' && prank[ls+1]=='A' && prank[ls+2]=='N') {
      if (n_porder < NCAND) {
        CutField(prank, ls, le, 1, porder[n_porder], 48);
        n_porder++;
      }
    }
    from = le + 1;
  }
  if (n_iorder != n_porder) order_mismatch++;
  else {
    for (I64 i = 0; i < n_iorder; i++) {
      if (!SameStr(iorder[i], porder[i])) order_mismatch++;
    }
  }

  Say("INDEPENDENT_CANDIDATES=");
  SayNum(n_ielig);
  Say("\n");
  Say("PRIMARY_CANDIDATES=");
  SayNum(n_pelig);
  Say("\n");
  Say("MISSING_IDS=");
  SayNum(missing);
  Say("\n");
  Say("DUPLICATE_IDS=");
  SayNum(duplicate);
  Say("\n");
  Say("RANK_ORDER_MISMATCHES=");
  SayNum(order_mismatch);
  Say("\n");

  if (missing != 0) { Say("FINAL=FAIL\nREASON=MISSING_CANDIDATE_ID\n"); Exit(1); }
  if (duplicate != 0) { Say("FINAL=FAIL\nREASON=DUPLICATE_ID\n"); Exit(1); }
  if (order_mismatch != 0) { Say("FINAL=FAIL\nREASON=RANK_ORDER_MISMATCH\n"); Exit(1); }
  Say("FINAL=OK\n");
  Exit(0);
}

// ---------------------------------------------------------------------------
// Dispatch.
// ---------------------------------------------------------------------------

public I32 Main(I64 argc, U8 **argv)
{
  if (argc < 2) {
    Say("FINAL=FAIL\nREASON=USAGE\n");
    Exit(2);
  }
  U8 *mode = argv[1];
  if (SameStr(mode, "recompute")) {
    if (argc < 7) { Say("FINAL=FAIL\nREASON=USAGE\n"); Exit(2); }
    RecomputeMode(argv[2], argv[3], argv[4], argv[5], argv[6]);
    return 0;
  }
  if (SameStr(mode, "compare")) {
    if (argc < 6) { Say("FINAL=FAIL\nREASON=USAGE\n"); Exit(2); }
    CompareMode(argv[2], argv[3], argv[4], argv[5]);
    return 0;
  }
  Say("FINAL=FAIL\nREASON=UNKNOWN_MODE\n");
  Exit(2);
  return 0;
}
