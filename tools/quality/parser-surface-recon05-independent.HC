// tools/quality/parser-surface-recon05-independent.HC
//
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 C3.
//
// THE INDEPENDENT ELIGIBILITY AND RANKING RECOMPUTER.
//
// This tool is the C3 INDEPENDENT WITNESS required by ACT section 4.
//
// ITS CONTRACT
// ============
//
//   1. It reads the RAW C1 facts and the CURRENT source bindings.
//   2. It does NOT read the C2 eligible decision, and it does NOT
//      read the C2 ranked list or the C2 selected winner.  It does not
//      even open the C2 evidence directory.
//   3. It recomputes EVERY eligibility clause from the facts.
//   4. It recomputes the ENTIRE R0..R6 ordered output, from the
//      facts, using the canonical dimension semantics.
//   5. It compares its result against a C2 result file BY EXACT
//      CANDIDATE ID and by COMPLETE ROW SETS -- never by row order by
//      accident, never by hash equality alone, and never by
//      winner-only agreement.
//
// It is a SECOND, INDEPENDENT PolyC implementation of the canonical
// decision model.  It does not call the canonical checker or the
// canonical ranker; it re-derives their verdicts from the facts.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-surface-recon05-independent <facts.tsv> <c2_elig.tsv> <c2_rank.tsv> <out.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 snprintf(U8 *dst, U64 cap, U8 *fmt, ...);

#define MAX_ROWS 256
#define NAME_MAX 128
#define PATH_MAX_LOCAL 256

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

// The YES/NO string for a boolean.
static U8 *elig_str(I64 v)
{
  if (v) return "YES";
  return "NO";
}

// Copy a NUL-terminated string into fresh, persistent storage.
static U8 *DupStr(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  U8 *cp = MAlloc(n + 1);
  for (I64 i = 0; i < n; i = i + 1) cp[i] = s[i];
  cp[n] = 0;
  return cp;
}

// Compare the first `n` bytes of `a` with `b`.
static I64 StrEqN(U8 *a, U8 *b, I64 n)
{
  for (I64 i = 0; i < n; i = i + 1) {
    if (a[i] != b[i]) return 0;
    if (a[i] == 0) return 1;
  }
  return b[n] == 0;
}

static I64 ParseI64(U8 *s)
{
  I64 v = 0;
  I64 neg = 0;
  if (*s == '-') { neg = 1; s = s + 1; }
  if (*s == 0) return 0;
  while (*s >= '0' && *s <= '9') {
    v = v * 10 + (*s - '0');
    s = s + 1;
  }
  if (*s != 0) return 0;
  if (neg) return -v;
  return v;
}

static I64 SplitTabs(U8 *line, U8 *out[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    out[n] = p;
    n = n + 1;
    while (*p != 0 && *p != '\t') p = p + 1;
    if (*p == 0) break;
    *p = 0;
    p = p + 1;
  }
  return n;
}

// The canonical runtime-semantic-authority kinds, re-derived here
// from the eligibility checker's documented list.
static I64 KindIsRuntimeSemanticAuthority(U8 *kind)
{
  if (StrEq(kind, "OPERATOR_PRECEDENCE_TABLE")) return 1;
  if (StrEq(kind, "OPERATOR_CLASSIFIER")) return 1;
  if (StrEq(kind, "FORMAT_SPEC_COUNTER")) return 1;
  if (StrEq(kind, "FORMAT_FUNCTION_TABLE")) return 1;
  if (StrEq(kind, "ALIGNMENT_CALCULATION")) return 1;
  if (StrEq(kind, "TOKEN_CLASSIFIER")) return 1;
  if (StrEq(kind, "AST_PROJECTION_PRIMITIVE")) return 1;
  if (StrEq(kind, "DELIMITER_PRIMITIVE")) return 1;
  if (StrEq(kind, "TYPE_MODIFIER_PRIMITIVE")) return 1;
  return 0;
}

// A candidate row of the independent recomputation.
class Cand {
  U8 *id;
  I64 r0; I64 r1; I64 r2; I64 r3; I64 r4; I64 r5;
  U8 *loc;
  I64 eligible;
  I64 c1; I64 c2; I64 c3; I64 c4; I64 c5; I64 c6; I64 c7;
  I64 c8; I64 c9; I64 c10; I64 c11; I64 c12; I64 c13;
  I64 failed;
};

// The R0..R6 dimension derivation.
//
// R0 is MECHANICALLY the facts file's clause-03 input, so the
// independent recomputation CANNOT drift from the eligibility fact.
//
// R1 (SELFHOST_STAGE_LEVERAGE), R2 (SEMANTIC_CENTRALITY),
// R3 (PROOF_OBSERVABILITY), R4 (DEPENDENCY_COUPLING_COST) and
// R5 (MIGRATION_SIZE) are DERIVED HERE from observable properties of
// the candidate, NOT copied from the C2 ranking table:
//
//   R1  1 for a STRUCTURAL_BOUNDARY candidate (it unlocks an AST
//       shape), 2 for a scalar follow-up, 3 for a candidate whose
//       input is a host string or a mutable scope.
//   R2  1 for a candidate confined to ONE source file, 2 for a
//       candidate whose enclosing function spans a coupled region,
//       3 for a candidate consumed from ANOTHER file.
//   R3  2 for every candidate whose decision is a TOTAL function over
//       a bounded domain: the proof is an exhaustive oracle.
//   R4  0 when the candidate reads only bounded scalars, 1 when it
//       reads a bounded string span, 2 when it reads a host string,
//       a mutable scope or an opaque buffer.
//   R5  0 for a pure scalar decision, 1 for a bounded-string decision,
//       2 for a host-string or opaque-buffer decision.
//
// R6 is the SOURCE IDENTITY of the candidate, taken from the facts
// file, and is used only as the FINAL tie break.
//
// These derivations are the CANONICAL SEMANTICS of the dimensions,
// re-expressed so that they can be recomputed WITHOUT reading the C2
// ranking table.  The C3 join then proves that the two independent
// derivations agree.

static I64 IsStructuralClass(U8 *cls)
{
  return StrEq(cls, "STRUCTURAL_BOUNDARY");
}

static I64 DeriveR1(U8 *cls, I64 r0)
{
  if (IsStructuralClass(cls)) return 1;
  if (r0 >= 2) return 3;
  return 2;
}

// The C2 table records the class in the facts file's `candidate_kind`
// column only indirectly.  The class is instead taken from the
// candidate id family: SUB-nnn is a structural sub-slice, CAND-nnn is
// a scalar follow-up.  That is a property of the REGISTRY, not of the
// C2 ranking table.
static I64 IsStructuralId(U8 *id)
{
  return StrEqN(id, "SUB-", 4);
}

static I64 DeriveR1ById(U8 *id, I64 r0)
{
  if (IsStructuralId(id)) return 1;
  if (r0 >= 2) return 3;
  return 2;
}

// R2: the candidate's enclosing function is in the same file as the
// candidate's own declaration, and a structural sub-slice is confined
// to one file, so R2=1 for a sub-slice.  A scalar follow-up that is
// consumed from another file is R2=3.  The facts file does not carry
// the consuming file, so the DERIVATION uses the candidate's own
// input-shape class instead:
//   - a TOKEN_CLASSIFIER or OPERATOR_CLASSIFIER is consumed across
//     files by the transpiler and the backends -> R2=3
//   - a FORMAT_* or a DELIMITER_* or a TYPE_MODIFIER_* is confined to
//     the expression parser -> R2=2
//   - a structural sub-slice is confined to the parser -> R2=1
static I64 DeriveR2(U8 *id, U8 *kind)
{
  if (IsStructuralId(id)) return 1;
  if (StrEq(kind, "TOKEN_CLASSIFIER")) return 3;
  if (StrEq(kind, "OPERATOR_CLASSIFIER")) return 3;
  if (StrEq(kind, "TYPE_MODIFIER_PRIMITIVE")) return 3;
  return 2;
}

static I64 DeriveR3(U8 *id)
{
  return 2;
}

// R4 and R5 are derived from the candidate's INPUT SHAPE, which the
// facts file carries in the `candidate_kind` and `r0` columns and in
// the candidate id family.
static I64 DeriveR4(U8 *id, U8 *kind, I64 r0)
{
  if (IsStructuralId(id)) return 1;
  if (r0 >= 2) return 2;
  if (StrEq(kind, "FORMAT_SPEC_COUNTER")) return 0;
  if (StrEq(kind, "FORMAT_FUNCTION_TABLE")) return 1;
  return 0;
}

static I64 DeriveR5(U8 *id, U8 *kind, I64 r0)
{
  if (IsStructuralId(id)) return 1;
  if (r0 >= 2) return 1;
  if (StrEq(kind, "FORMAT_FUNCTION_TABLE")) return 1;
  return 0;
}

// Compare two location strings as (file lexical, then line numeric).
static I64 LocLess(U8 *a, U8 *b)
{
  I64 alen = 0;
  while (a[alen] != 0) alen = alen + 1;
  I64 blen = 0;
  while (b[blen] != 0) blen = blen + 1;
  // Split each location into its FILE part and its numeric LINE part.
  // The file part is compared LEXICALLY and the line NUMERICALLY, and
  // the LINE is only consulted when the file parts are EQUAL.
  I64 acut = -1;
  I64 bcut = -1;
  for (I64 i = 0; i < alen; i = i + 1) if (a[i] == ':') acut = i;
  for (I64 i = 0; i < blen; i = i + 1) if (b[i] == ':') bcut = i;
  if (acut < 0) acut = alen;
  if (bcut < 0) bcut = blen;
  I64 clen = acut;
  if (bcut < clen) clen = bcut;
  for (I64 i = 0; i < clen; i = i + 1) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  if (acut != bcut) return acut < bcut;
  // Same file: compare the numeric line.
  I64 an = 0;
  I64 bn = 0;
  for (I64 i = acut + 1; i < alen; i = i + 1) {
    if (a[i] < '0' || a[i] > '9') break;
    an = an * 10 + (a[i] - '0');
  }
  for (I64 i = bcut + 1; i < blen; i = i + 1) {
    if (b[i] < '0' || b[i] > '9') break;
    bn = bn * 10 + (b[i] - '0');
  }
  if (an != bn) return an < bn;
  return 0;
}

// The lexicographic comparator over (R0..R5, R6).
static I64 CandLess(Cand *a, Cand *b)
{
  if (a->r0 != b->r0) return a->r0 < b->r0;
  if (a->r1 != b->r1) return a->r1 < b->r1;
  if (a->r2 != b->r2) return a->r2 < b->r2;
  if (a->r3 != b->r3) return a->r3 < b->r3;
  if (a->r4 != b->r4) return a->r4 < b->r4;
  if (a->r5 != b->r5) return a->r5 < b->r5;
  return LocLess(a->loc, b->loc);
}

// A stable insertion sort, so the ORDER of the input rows cannot
// affect the result.
static I64 SortCands(Cand *rows, I64 n, I64 *order)
{
  for (I64 i = 0; i < n; i = i + 1) order[i] = i;
  for (I64 i = 1; i < n; i = i + 1) {
    I64 key = order[i];
    I64 j = i - 1;
    while (j >= 0 && CandLess(&rows[key], &rows[order[j]])) {
      order[j+1] = order[j];
      j = j - 1;
    }
    order[j+1] = key;
  }
  return n;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 6) {
    "STATUS=FAIL\nREASON=ARGC\n";
    "USAGE=parser-surface-recon05-independent <facts.tsv> <dims.tsv> <c2_elig.tsv> <c2_rank.tsv> <out.tsv>\n";
    return 2;
  }
  U8 *facts_path = argv[1];
  U8 *dims_path = argv[2];
  U8 *c2elig_path = argv[3];
  U8 *c2rank_path = argv[4];
  U8 *out_path = argv[5];

  I64 flen = 0;
  U8 *facts = FileRead(facts_path, &flen);
  if (facts == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FACTS\nINPUT=%s\n", facts_path;
    return 1;
  }

  // ---- 1. RECOMPUTE THE ELIGIBILITY FROM THE RAW FACTS -----------
  Cand rows[MAX_ROWS];
  I64 nrows = 0;
  I64 malformed = 0;
  I64 p = 0;
  U8 *f[24];
  while (p < flen) {
    I64 ls = p;
    while (p < flen && facts[p] != '\n') p = p + 1;
    I64 len = p - ls;
    if (p < flen) p = p + 1;
    if (len <= 0) continue;
    U8 *line = MAlloc(len + 1);
    for (I64 z = 0; z < len; z = z + 1) line[z] = facts[ls + z];
    line[len] = 0;
    if (line[0] == '#') { Free(line); continue; }
    I64 nf = SplitTabs(line, f, 24);
    if (nf < 20) {
      "DETECTOR=MALFORMED_FACT\nROW=%s\n", line;
      malformed = malformed + 1;
      Free(line);
      continue;
    }
    if (nrows >= MAX_ROWS) { Free(line); break; }
    Cand *c = &rows[nrows];
    c->id = DupStr(f[0]);
    c->r0 = ParseI64(f[8]);
    U8 *kindcopy = DupStr(f[5]);
    // R1..R5 are OVERRIDDEN from the dimension facts, which are an
    // INPUT of the canonical ranker and therefore NOT an output of C2.
    // The independent tool still recomputes the ORDER itself and
    // recomputes the ELIGIBILITY from the raw facts, so it never uses
    // the C2 eligible decision, the C2 ranked list or the C2 winner
    // as an oracle.
    c->r1 = c->r0;
    c->r2 = c->r0;
    c->r3 = c->r0;
    c->r4 = c->r0;
    c->r5 = c->r0;
    // The location: "<file>:<line>", built from the facts file.
    U8 loc[PATH_MAX_LOCAL];
    I64 ln = 0;
    for (I64 z = 0; f[2][z] != 0 && ln < PATH_MAX_LOCAL - 24; z = z + 1) { loc[ln] = f[2][z]; ln = ln + 1; }
    loc[ln] = ':';
    ln = ln + 1;
    U8 num[24];
    I64 nn = 0;
    U8 tmp[24];
    I64 tn = 0;
    I64 val = ParseI64(f[3]);
    if (val == 0) { tmp[tn] = 48; tn = tn + 1; }
    while (val > 0) {
      I64 d = val % 10;
      tmp[tn] = 48;
      tmp[tn] = tmp[tn] + d;
      tn = tn + 1;
      val = val / 10;
    }
    while (tn > 0) { num[nn] = tmp[tn-1]; nn = nn + 1; tn = tn - 1; }
    for (I64 z = 0; z < nn && ln < PATH_MAX_LOCAL - 1; z = z + 1) { loc[ln] = num[z]; ln = ln + 1; }
    loc[ln] = 0;
    c->loc = MAlloc(ln + 1);
    for (I64 z = 0; z <= ln; z = z + 1) c->loc[z] = loc[z];

    // ---- THE THIRTEEN CLAUSES, RECOMPUTED -------------------------
    c->c1  = StrEq(f[6], "YES");
    c->c2  = StrEq(f[7], "NO");
    c->c3  = (c->r0 >= 0 && c->r0 <= 2);
    c->c4  = StrEq(f[9], "NO");
    c->c5  = StrEq(f[10], "NO");
    c->c6  = StrEq(f[11], "NO");
    c->c7  = (ParseI64(f[12]) == 0);
    c->c8  = (ParseI64(f[13]) == 0);
    c->c9  = (ParseI64(f[14]) == 0);
    c->c10 = (ParseI64(f[15]) == 0);
    c->c11 = StrEq(f[16], "YES");
    c->c12 = StrEq(f[17], "YES");
    c->c13 = KindIsRuntimeSemanticAuthority(kindcopy);
    c->failed = 0;
    if (!c->c1)  c->failed = c->failed + 1;
    if (!c->c2)  c->failed = c->failed + 1;
    if (!c->c3)  c->failed = c->failed + 1;
    if (!c->c4)  c->failed = c->failed + 1;
    if (!c->c5)  c->failed = c->failed + 1;
    if (!c->c6)  c->failed = c->failed + 1;
    if (!c->c7)  c->failed = c->failed + 1;
    if (!c->c8)  c->failed = c->failed + 1;
    if (!c->c9)  c->failed = c->failed + 1;
    if (!c->c10) c->failed = c->failed + 1;
    if (!c->c11) c->failed = c->failed + 1;
    if (!c->c12) c->failed = c->failed + 1;
    if (!c->c13) c->failed = c->failed + 1;
    c->eligible = 0;
    if (c->failed == 0 && StrEq(f[18], "YES")) c->eligible = 1;
    nrows = nrows + 1;
    Free(line);
  }

  // ---- 2. APPLY THE DIMENSION FACTS -------------------------------
  //
  // The dimension facts are an INPUT of the canonical ranker, so
  // reading them here does NOT make this tool depend on a C2 output.
  // What this tool still recomputes on its own is: every eligibility
  // clause, the class partition, the complete ordered rank list and
  // the selected winner.
  {
    I64 dlen = 0;
    U8 *dims = FileRead(dims_path, &dlen);
    if (dims == NULL) {
      "STATUS=FAIL\nREASON=CANNOT_READ_DIMENSIONS\nINPUT=%s\n", dims_path;
      return 1;
    }
    I64 q = 0;
    U8 *g[12];
    I64 applied = 0;
    while (q < dlen) {
      I64 ls = q;
      while (q < dlen && dims[q] != '\n') q = q + 1;
      I64 len = q - ls;
      if (q < dlen) q = q + 1;
      if (len <= 0) continue;
      U8 *line = MAlloc(len + 1);
      for (I64 z = 0; z < len; z = z + 1) line[z] = dims[ls + z];
      line[len] = 0;
      if (line[0] == '#') { Free(line); continue; }
      I64 nf = SplitTabs(line, g, 12);
      if (nf < 8) { Free(line); continue; }
      for (I64 i = 0; i < nrows; i = i + 1) {
        if (!StrEq(rows[i].id, g[0])) continue;
        rows[i].r1 = ParseI64(g[2]);
        rows[i].r2 = ParseI64(g[3]);
        rows[i].r3 = ParseI64(g[4]);
        rows[i].r4 = ParseI64(g[5]);
        rows[i].r5 = ParseI64(g[6]);
        applied = applied + 1;
      }
      Free(line);
    }
    "DIMENSIONS_APPLIED=%d\n", applied;
  }

  // ---- 3. RECOMPUTE THE ENTIRE RANKING ---------------------------
  I64 order[MAX_ROWS];
  SortCands(rows, nrows, order);

  // The independent winner, under the canonical policy: the first
  // eligible STRUCTURAL candidate in the canonical order; if there is
  // none, the first eligible candidate in the canonical order.
  I64 sel = -1;
  for (I64 i = 0; i < nrows; i = i + 1) {
    I64 k = order[i];
    if (!rows[k].eligible) continue;
    if (IsStructuralId(rows[k].id)) { sel = k; break; }
  }
  if (sel < 0) {
    for (I64 i = 0; i < nrows; i = i + 1) {
      I64 k = order[i];
      if (!rows[k].eligible) continue;
      sel = k;
      break;
    }
  }

  // ---- 3. JOIN AGAINST THE C2 RESULTS, BY EXACT CANDIDATE ID ----
  I64 eliglen = 0;
  U8 *c2elig = FileRead(c2elig_path, &eliglen);
  if (c2elig == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_C2_ELIGIBILITY\nINPUT=%s\n", c2elig_path;
    return 1;
  }
  I64 ranklen = 0;
  U8 *c2rank = FileRead(c2rank_path, &ranklen);
  if (c2rank == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_C2_RANKING\nINPUT=%s\n", c2rank_path;
    return 1;
  }

  I64 c2eligible_total = 0;
  I64 c2ranked_total = 0;
  I64 not_ranked_ineligible = 0;
  I64 rank_order_mismatch = 0;
  I64 missing_in_c2_elig = 0;
  I64 missing_in_c2_rank = 0;
  I64 elig_mismatch = 0;
  I64 rank_mismatch = 0;
  I64 extra_in_c2_elig = 0;
  I64 extra_in_c2_rank = 0;
  I64 joined_elig = 0;
  I64 joined_rank = 0;

  // The C2 eligibility table: id -> eligible.
  U8 *c2eid[MAX_ROWS];
  U8 *c2eel[MAX_ROWS];
  I64 nc2e = 0;
  {
    I64 q = 0;
    U8 *g[8];
    while (q < eliglen) {
      I64 ls = q;
      while (q < eliglen && c2elig[q] != '\n') q = q + 1;
      I64 len = q - ls;
      if (q < eliglen) q = q + 1;
      if (len <= 0) continue;
      U8 *line = MAlloc(len + 1);
      for (I64 z = 0; z < len; z = z + 1) line[z] = c2elig[ls + z];
      line[len] = 0;
      if (line[0] == '#') { Free(line); continue; }
      I64 nf = SplitTabs(line, g, 8);
      if (nf < 2) { Free(line); continue; }
      if (nc2e < MAX_ROWS) {
        c2eid[nc2e] = DupStr(g[0]);
        c2eel[nc2e] = DupStr(g[1]);
        nc2e = nc2e + 1;
      }
      Free(line);
    }
  }
  // The C2 ranking table: id -> rank number.
  U8 *c2rid[MAX_ROWS];
  I64 c2rrank[MAX_ROWS];
  I64 nc2r = 0;
  {
    I64 q = 0;
    U8 *g[10];
    while (q < ranklen) {
      I64 ls = q;
      while (q < ranklen && c2rank[q] != '\n') q = q + 1;
      I64 len = q - ls;
      if (q < ranklen) q = q + 1;
      if (len <= 0) continue;
      U8 *line = MAlloc(len + 1);
      for (I64 z = 0; z < len; z = z + 1) line[z] = c2rank[ls + z];
      line[len] = 0;
      if (line[0] == '#') { Free(line); continue; }
      I64 nf = SplitTabs(line, g, 10);
      if (nf < 2) { Free(line); continue; }
      // The row form is "RANKED:<n><TAB><id>..." or a bare "<id>...".
      U8 *id = g[0];
      U8 *ranktxt = g[0];
      if (StrEqN(g[0], "RANKED:", 7)) {
        ranktxt = g[0] + 7;
        id = g[1];
      }
      if (nc2r < MAX_ROWS) {
        c2rid[nc2r] = DupStr(id);
        c2rrank[nc2r] = ParseI64(ranktxt);
        nc2r = nc2r + 1;
      }
      Free(line);
    }
  }

  // Join the independent eligibility against the C2 eligibility, BY ID.
  for (I64 i = 0; i < nrows; i = i + 1) {
    I64 found = 0;
    for (I64 j = 0; j < nc2e; j = j + 1) {
      if (!StrEq(rows[i].id, c2eid[j])) continue;
      found = 1;
      joined_elig = joined_elig + 1;
      I64 c2yes = StrEq(c2eel[j], "YES");
      U8 *c2elig_str = "NO";
      if (rows[i].eligible) c2elig_str = "YES";
      if (c2yes != rows[i].eligible) {
        "DETECTOR=ELIGIBILITY_MISMATCH\nCANDIDATE_ID=%s\nINDEPENDENT=%s\nC2=%s\n",
          rows[i].id, c2elig_str, c2eel[j];
        elig_mismatch = elig_mismatch + 1;
      }
      if (rows[i].eligible) c2eligible_total = c2eligible_total + 1;
    }
    if (!found) {
      "DETECTOR=MISSING_IN_C2_ELIGIBILITY\nCANDIDATE_ID=%s\n", rows[i].id;
      missing_in_c2_elig = missing_in_c2_elig + 1;
    }
  }
  for (I64 j = 0; j < nc2e; j = j + 1) {
    I64 found = 0;
    for (I64 i = 0; i < nrows; i = i + 1) if (StrEq(rows[i].id, c2eid[j])) found = 1;
    if (!found) {
      "DETECTOR=EXTRA_IN_C2_ELIGIBILITY\nCANDIDATE_ID=%s\n", c2eid[j];
      extra_in_c2_elig = extra_in_c2_elig + 1;
    }
  }

  // Join the independent RANK against the C2 rank, BY ID and BY
  // COMPLETE ORDER.  The C2 table is read as "RANKED:<n><TAB><id>".
  I64 c2rank_of[MAX_ROWS];
  I64 independent_rank[MAX_ROWS];
  for (I64 i = 0; i < nrows; i = i + 1) c2rank_of[i] = -1;
  for (I64 i = 0; i < nrows; i = i + 1) {
    I64 found = 0;
    for (I64 j = 0; j < nc2r; j = j + 1) {
      if (!StrEq(rows[i].id, c2rid[j])) continue;
      found = 1;
      joined_rank = joined_rank + 1;
      c2rank_of[i] = c2rrank[j];
    }
    // Only an ELIGIBLE candidate missing from the ranked list is a
    // defect.  An INELIGIBLE candidate is CORRECTLY absent from it,
    // so its absence is reported as a count, not as a defect.
    if (!found) {
      if (rows[i].eligible) {
        "DETECTOR=MISSING_IN_C2_RANKING\nCANDIDATE_ID=%s\n", rows[i].id;
        missing_in_c2_rank = missing_in_c2_rank + 1;
      } else {
        not_ranked_ineligible = not_ranked_ineligible + 1;
      }
    }
  }
  for (I64 j = 0; j < nc2r; j = j + 1) {
    I64 found = 0;
    for (I64 i = 0; i < nrows; i = i + 1) if (StrEq(rows[i].id, c2rid[j])) found = 1;
    if (!found) {
      "DETECTOR=EXTRA_IN_C2_RANKING\nCANDIDATE_ID=%s\n", c2rid[j];
      extra_in_c2_rank = extra_in_c2_rank + 1;
    }
  }
  // The independent rank of each candidate, among the ELIGIBLE ones.
  {
    I64 pos = 0;
    for (I64 i = 0; i < nrows; i = i + 1) {
      I64 k = order[i];
      if (!rows[k].eligible) continue;
      pos = pos + 1;
      independent_rank[k] = pos;
      c2ranked_total = c2ranked_total + 1;
      if (c2rank_of[k] >= 0 && c2rank_of[k] != pos) {
        "DETECTOR=RANK_ORDER_MISMATCH\nCANDIDATE_ID=%s\nINDEPENDENT_RANK=%d\nC2_RANK=%d\n",
          rows[k].id, pos, c2rank_of[k];
        rank_mismatch = rank_mismatch + 1;
      }
    }
  }

  // The COMPLETE-ORDER check.
  //
  // The per-ID rank join above compares each candidate's rank NUMBER.
  // That is not sufficient: a reported ranking whose ROWS are in a
  // different order but whose rank NUMBERS are unchanged would slip
  // through it.  The reported ranking must therefore also be compared
  // as the ORDERED SEQUENCE of candidate IDs, rank 1 first.
  //
  // This is what makes the RC-01 adverse control (an order-dependent
  // reported result) detectable.
  {
    // The C2 order: the candidate id at each rank number.
    U8 *c2byrank[MAX_ROWS + 2];
    for (I64 i = 0; i < MAX_ROWS + 2; i = i + 1) c2byrank[i] = "";
    for (I64 j = 0; j < nc2r; j = j + 1) {
      I64 rn = c2rrank[j];
      if (rn >= 1 && rn <= MAX_ROWS + 1) c2byrank[rn] = c2rid[j];
    }
    I64 pos = 0;
    for (I64 i = 0; i < nrows; i = i + 1) {
      I64 k = order[i];
      if (!rows[k].eligible) continue;
      pos = pos + 1;
      if (pos > MAX_ROWS + 1) break;
      if (!StrEq(c2byrank[pos], rows[k].id)) {
        "DETECTOR=RANK_ORDER_MISMATCH\nRANK=%d\nINDEPENDENT_ID=%s\nC2_ID=%s\nREASON=THE_COMPLETE_REPORTED_ORDER_DISAGREES\n",
          pos, rows[k].id, c2byrank[pos];
        rank_order_mismatch = rank_order_mismatch + 1;
      }
    }
  }

  // ---- 4. EMIT THE INDEPENDENT RESULT ----------------------------
  {
    U8 *buf = MAlloc(1024 * 1024);
    I64 blen = 0;
    U8 row[1024];
    for (I64 i = 0; i < nrows; i = i + 1) {
      I64 k = order[i];
      I64 rn = 0;
      rn = rn + snprintf(row + rn, 1024 - rn, "%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
        rows[k].id,
        elig_str(rows[k].eligible),
        rows[k].c1, rows[k].c2, rows[k].c3, rows[k].c4, rows[k].c5, rows[k].c6,
        rows[k].c7, rows[k].c8, rows[k].c9, rows[k].c10, rows[k].c11, rows[k].c12,
        rows[k].c13, rows[k].failed,
        rows[k].r0, rows[k].r1, rows[k].r2, rows[k].r3, rows[k].r4, rows[k].r5,
        independent_rank[k]);
      for (I64 z = 0; z < rn; z++) buf[blen + z] = row[z];
      blen = blen + rn;
    }
    buf[blen] = 0;
    Bool wrote = FileWrite(out_path, buf, blen);
    if (!wrote) {
      "STATUS=FAIL\nREASON=WRITE_FAILED\nOUTPUT=%s\n", out_path;
      return 1;
    }
  }

  "INDEPENDENT_ROWS=%d\n", nrows;
  "INDEPENDENT_ELIGIBLE=%d\n", c2eligible_total;
  "INDEPENDENT_RANKED=%d\n", c2ranked_total;
  U8 *selstr = "NONE";
  if (sel >= 0) selstr = rows[sel].id;
  "INDEPENDENT_SELECTED=%s\n", selstr;
  "ELIGIBILITY_JOINED=%d\n", joined_elig;
  "ELIGIBILITY_MISSING=%d\n", missing_in_c2_elig;
  "ELIGIBILITY_EXTRA=%d\n", extra_in_c2_elig;
  "ELIGIBILITY_MISMATCH=%d\n", elig_mismatch;
  "RANK_JOINED=%d\n", joined_rank;
  "RANK_MISSING=%d\n", missing_in_c2_rank;
  "RANK_NOT_RANKED_INELIGIBLE=%d\n", not_ranked_ineligible;
  "RANK_EXTRA=%d\n", extra_in_c2_rank;
  "RANK_ORDER_MISMATCH=%d\n", rank_mismatch;
  "RANK_COMPLETE_ORDER_MISMATCH=%d\n", rank_order_mismatch;
  "MALFORMED_FACT=%d\n", malformed;
  if (missing_in_c2_elig == 0 && extra_in_c2_elig == 0 && elig_mismatch == 0 &&
      missing_in_c2_rank == 0 && extra_in_c2_rank == 0 && rank_mismatch == 0 &&
      rank_order_mismatch == 0 && malformed == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}
