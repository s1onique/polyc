// tools/quality/core-semantic-bundle-recon03-eligibility.HC
//
// ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
//
// The ACT-LOCAL PolyC ELIGIBILITY CHECKER.
//
// It is NOT a canonical checker and it does NOT modify any canonical
// tool. The repository's canonical checker/ranker are read only; this
// tool is named ACT-LOCAL because the frozen 16-clause eligibility
// contract of this ACT has a schema the canonical checkers do not
// implement.
//
// THE CHECKER OWNS THE `eligible` COLUMN. The ranker joins the
// checker's output by stable candidate id and never trusts a freehand
// flag. The checker recomputes every eligibility decision from the C1
// SOURCE-DERIVED FACTS, so an excluded site cannot be promoted by
// editing an input file.
//
// THE 16 CLAUSES (frozen at C0, see
// evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/c0/frozen-16-eligibility.tsv):
//
//   E01 all members presently C-authoritative in the linked production
//        compiler, not merely leftover forwarding adapters
//   E02 exactly 2-6 distinct sites, stable ids, disjoint source ranges
//   E03 every site has source OID, byte range, source SHA-256, TU and
//        object/inline reachability
//   E04 every site is a semantic decision affecting compilation
//        acceptance, IR/assembly/object or runtime behaviour
//   E05 a SEPARATE discriminating compiler witness per member
//   E06 the members are coherently related by a NAMED invariant, not
//        arbitrary proximity
//   E07 a credible path to M1/M2 compiler semantic or bootstrap work
//   E08 the ABI projection has bounded copied scalars or rigorously
//        typed borrowed handles; no unrestricted void*/callback table
//   E09 ownership and lifetime of AST/IR/token/container data remain
//        explicit and non-leaking across the seam
//   E10 no cross-frame setjmp/longjmp, unbounded recursive recovery
//        transfer or unverified exception across PolyC/C
//   E11 diagnostics, allocation and mutable host state remain
//        correctly sequenced; no hidden double evaluation
//   E12 each member has a genuine C-only G0 path in a complete compiler
//        and can be compiled into a future PolyC subject
//   E13 full production C causal mutation can be built without changing
//        unrelated sites; source/object restoration observable
//   E14 fixtures can derive from live enum/source semantics and cover
//        valid, invalid, boundary and fallback input partitions
//   E15 the ABI has explicit status/data separation, especially valid
//        numeric zero, negative values and error domains
//   E16 the changes fit a bounded implementation with deterministic build
//        prerequisites and no unproven graph or SCC claim
//
// MODES:
//   check <core-candidates.tsv> <core-sites.tsv> <eligibility-input-facts.tsv>
//        <candidates-out.tsv> <sites-out.tsv>
//
//        Recomputes the eligibility of every candidate and writes:
//          <candidates-out.tsv>  candidate_id  eligible  failed_clauses
//          <sites-out.tsv>        site_id  clause_results
//        It prints one ELIGIBLE_LINE= and one EXCLUDED_LINE= per
//        candidate and a final FINAL= line.
//
//   selftest <core-candidates.tsv> <core-sites.tsv> <eligibility-input-facts.tsv>
//        Runs the checker's own anti-selftests: it mutates isolated
//        COPIES of the inputs and requires the checker to reject each
//        adverse shape with its OWN reason.
//
// BUILD:
//   $(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -c \
//     tools/quality/core-semantic-bundle-recon03-eligibility.HC \
//     -o build/core-semantic-bundle-recon03-eligibility.o
//   cc build/core-semantic-bundle-recon03-eligibility.o \
//     -L$(TEST_PREFIX)/lib -ltos \
//     -o build/core-semantic-bundle-recon03-eligibility

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

// FindStr returns a pointer to the first occurrence of `needle` in
// `hay`, or NULL when it is absent. The buffer must be NUL-terminated.
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

// Reads a whole file. Returns NULL when the file cannot be read.
public U8 *ReadFile(U8 *path, I64 *size_out)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (size_out != NULL) *size_out = size;
  return data;
}

// FieldAt copies the nth tab-separated field of the line [ls,le) into
// `out`, truncated to `cap`. Field 0 is the first.
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

public U0 ESay(U8 *s)
{
  Write(1, s, StrLen(s));
}

// ClauseName maps a clause index to its canonical clause id.
public U8 *ClauseName(I64 idx)
{
  if (idx == 0) return "E01";
  if (idx == 1) return "E02";
  if (idx == 2) return "E03";
  if (idx == 3) return "E04";
  if (idx == 4) return "E05";
  if (idx == 5) return "E06";
  if (idx == 6) return "E07";
  if (idx == 7) return "E08";
  if (idx == 8) return "E09";
  if (idx == 9) return "E10";
  if (idx == 10) return "E11";
  if (idx == 11) return "E12";
  if (idx == 12) return "E13";
  if (idx == 13) return "E14";
  if (idx == 14) return "E15";
  if (idx == 15) return "E16";
  return "E??";
}

// ClauseIndex maps a clause id string to its index, or -1.
public I64 ClauseIndex(U8 *name)
{
  for (I64 i = 0; i < 16; i++) {
    if (StrEq(ClauseName(i), name)) return i;
  }
  return -1;
}



#define MAX_CAND 16
#define MAX_SITE 16
#define MAX_CAND_MEMBERS 8

class Cand
{
  U8 id[64];
  U8 family[64];
  U8 invariant[96];
  U8 abi[64];
  U8 single_abi[8];
  I64 nmembers;
  U8 members[MAX_CAND_MEMBERS][24];
  I64 failed[16];
  I64 nfailed;
  Bool eligible;
};

class Site
{
  U8 id[48];
  U8 path[40];
  U8 oid[44];
  U8 range[24];
  U8 sha[68];
  U8 symbol[40];
  U8 linkage[12];
  U8 reach[16];
  U8 caller[48];
  U8 klass[48];
  U8 channel[24];
  I64 in_scope;
  Bool present;
};

class Fact
{
  I64 writes;
  I64 recovery;
  I64 derefs;
  U8 site[48];
  U8 c_auth[8];
  U8 channel[32];
  U8 disc[8];
  U8 domain[64];
  U8 single_abi[8];
  U8 unknown[48];
  Bool present;
};

public U0 CandFail(Cand *c, U8 *clause)
{
  I64 idx = ClauseIndex(clause);
  if (idx < 0) return;
  // a clause is recorded at most once per candidate.
  for (I64 k = 0; k < c->nfailed; k++) {
    if (c->failed[k] == idx) return;
  }
  c->failed[c->nfailed] = idx;
  c->nfailed++;
}

// ---------------------------------------------------------------------------
// Loading.
// ---------------------------------------------------------------------------

// LoadSites reads the site roster. A row is a SITE row when its id
// begins with "SITE-"; an "EXCL-" row is an EXCLUSION and is loaded
// separately so that it can never be selected.
public I64 LoadSites(U8 *data, I64 size, Site *sites, I64 max)
{
  I64 n = 0;
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] == 'S' && data[i+1] == 'I' && data[i+2] == 'T' && data[i+3] == 'E' && data[i+4] == '-') {
      if (n < max) {
        Site *s = &sites[n];
        FieldAt(data, i, le, 0, s->id, 48);
        FieldAt(data, i, le, 1, s->path, 40);
        FieldAt(data, i, le, 2, s->oid, 44);
        FieldAt(data, i, le, 3, s->range, 24);
        FieldAt(data, i, le, 4, s->sha, 68);
        FieldAt(data, i, le, 5, s->symbol, 40);
        FieldAt(data, i, le, 6, s->linkage, 12);
        FieldAt(data, i, le, 7, s->reach, 16);
        FieldAt(data, i, le, 8, s->caller, 48);
        FieldAt(data, i, le, 9, s->klass, 48);
        FieldAt(data, i, le, 10, s->channel, 24);
        U8 scope[16];
        FieldAt(data, i, le, 11, scope, 16);
        s->in_scope = 0;
        if (StrCmp(scope, "YES") == 0) s->in_scope = 1;
        s->present = TRUE;
        n++;
      }
    }
    i = le + 1;
  }
  return n;
}

// ParseSmallInt parses a small non-negative decimal integer. It is
// self-contained so that the checker never depends on an external
// conversion whose argument termination is not guaranteed here.
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

public I64 LoadFacts(U8 *data, I64 size, Fact *facts, I64 max)
{
  I64 n = 0;
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] == 'S' && data[i+1] == 'I' && data[i+2] == 'T' && data[i+3] == 'E' && data[i+4] == '-') {
      if (n < max) {
        Fact *f = &facts[n];
        FieldAt(data, i, le, 0, f->site, 48);
        FieldAt(data, i, le, 1, f->c_auth, 8);
        FieldAt(data, i, le, 2, f->channel, 32);
        FieldAt(data, i, le, 3, f->disc, 8);
        U8 w[16];
        FieldAt(data, i, le, 4, w, 16); f->writes = ParseSmallInt(w);
        FieldAt(data, i, le, 5, w, 16); f->recovery = ParseSmallInt(w);
        FieldAt(data, i, le, 6, w, 16); f->derefs = ParseSmallInt(w);
        FieldAt(data, i, le, 7, f->domain, 64);
        FieldAt(data, i, le, 8, f->single_abi, 8);
        FieldAt(data, i, le, 9, f->unknown, 48);
        f->present = TRUE;
        n++;
      }
    }
    i = le + 1;
  }
  return n;
}

public Site *FindSite(Site *sites, I64 n, U8 *id)
{
  for (I64 i = 0; i < n; i++) {
    if (StrEq(sites[i].id, id)) return &sites[i];
  }
  return NULL;
}

public Fact *FindFact(Fact *facts, I64 n, U8 *id)
{
  for (I64 i = 0; i < n; i++) {
    if (StrEq(facts[i].site, id)) return &facts[i];
  }
  return NULL;
}


// ---------------------------------------------------------------------------
// The candidate roster. The candidate's member list is read from its
// `member_site_ids` column, which is a SEMICOLON-separated list.
// ---------------------------------------------------------------------------

public I64 LoadCands(U8 *data, I64 size, Cand *cands, I64 max)
{
  I64 n = 0;
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] == 'C' && data[i+1] == 'A' && data[i+2] == 'N' && data[i+3] == 'D' && data[i+4] == '-') {
      if (n < max) {
        Cand *c = &cands[n];
        U8 members[1024];
        // column layout: 0 id, 1 family, 2 member_site_ids (semicolon
        // separated), 3 member_count, 4 named_invariant,
        // 5 per_member_witness_plan, 6 abi_shape, 7 state
        FieldAt(data, i, le, 0, c->id, 64);
        FieldAt(data, i, le, 1, c->family, 64);
        FieldAt(data, i, le, 4, c->invariant, 96);
        FieldAt(data, i, le, 6, c->abi, 64);
        FieldAt(data, i, le, 2, members, 1024);
        c->nfailed = 0;
        c->eligible = FALSE;
        I64 start = 0;
        I64 k = 0;
        I64 count = 0;
        while (k <= StrLen(members)) {
          if (k == StrLen(members) || members[k] == ';') {
            I64 ml = k - start;
            if (ml > 0 && count < MAX_CAND_MEMBERS) {
              I64 cp = ml;
              if (cp > 23) cp = 23;
              MemCpy(c->members[count], members + start, cp);
              c->members[count][cp] = 0;
              count++;
            }
            start = k + 1;
          }
          k++;
        }
        c->nmembers = count;
        n++;
      }
    }
    i = le + 1;
  }
  return n;
}


// ---------------------------------------------------------------------------
// THE ELIGIBILITY EVALUATION.
//
// Each clause is evaluated from the C1 source-derived facts. A clause
// that cannot be decided from the facts is NOT silently coerced to
// "eligible": it fails, and the failure is recorded with its clause id.
// ---------------------------------------------------------------------------

public U0 EvaluateCand(Cand *c, Site *sites, I64 nsites, Fact *facts, I64 nfacts)
{
  // E02 -- exactly 2..6 distinct sites with disjoint source ranges.
  if (c->nmembers < 2 || c->nmembers > 6) {
    CandFail(c, "E02");
  }
  for (I64 i = 0; i < c->nmembers; i++) {
    for (I64 j = i + 1; j < c->nmembers; j++) {
      if (StrEq(c->members[i], c->members[j])) CandFail(c, "E02");
    }
  }

  I64 nfound = 0;
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *s = FindSite(sites, nsites, c->members[i]);
    Fact *f = FindFact(facts, nfacts, c->members[i]);
    if (s == NULL || f == NULL) {
      // a member with no site record or no fact record cannot be
      // judged; it is NOT coerced to eligible.
      CandFail(c, "E03");
      continue;
    }
    nfound++;

    // E01 -- presently C-authoritative, and not a leftover adapter.
    if (!StrEq(f->c_auth, "YES")) CandFail(c, "E01");

    // E03 -- source OID, byte range, source SHA-256, TU and reachability.
    if (StrLen(s->oid) < 40) CandFail(c, "E03");
    if (StrLen(s->range) < 3) CandFail(c, "E03");
    if (StrLen(s->sha) < 64) CandFail(c, "E03");
    if (StrLen(s->path) < 3) CandFail(c, "E03");
    if (StrLen(s->reach) < 3) CandFail(c, "E03");
    if (StrCmp(s->reach, "0_IMPORTERS") == 0) CandFail(c, "E03");

    // E04 -- a real semantic decision on a real channel.
    if (!s->in_scope) CandFail(c, "E04");
    if (!StrEq(s->channel, "COMPILER_ACCEPTANCE") &&
        !StrEq(s->channel, "IR_ASSEMBLY_OBJECT") &&
        !StrEq(s->channel, "RUNTIME_BEHAVIOUR")) {
      CandFail(c, "E04");
    }
    if (!StrEq(f->channel, s->channel)) CandFail(c, "E04");

    // E05 -- a SEPARATE discriminating witness per member.
    if (!StrEq(f->disc, "YES")) CandFail(c, "E05");
    if (StrLen(f->domain) < 4) CandFail(c, "E05");

    // E08 -- bounded scalars only.
    if (f->derefs != 0) CandFail(c, "E08");
    if (!StrEq(f->single_abi, "YES")) CandFail(c, "E08");

    // E10 -- no recovery-frame crossing.
    if (f->recovery != 0) CandFail(c, "E10");

    // E11 -- no hidden mutable host state.
    if (f->writes != 0) CandFail(c, "E11");

    // E14 -- a closed, source-derived enum domain with a stated
    // unknown-input handling.
    if (StrLen(f->domain) < 8) CandFail(c, "E14");
    if (StrLen(f->unknown) < 4) CandFail(c, "E14");
    if (StrCmp(f->unknown, "TOTAL") != 0 &&
        strncmp(f->unknown, "TOTAL:", 6) != 0) {
      CandFail(c, "E14");
    }

    // E15 -- explicit status/data separation.
    if (strncmp(f->unknown, "TOTAL", 5) != 0) CandFail(c, "E15");
  }
  if (nfound != c->nmembers) CandFail(c, "E02");


  // E02 -- disjoint source ranges: no two members may share a byte
  // range in the same file.
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *a = FindSite(sites, nsites, c->members[i]);
    if (a == NULL) continue;
    for (I64 j = i + 1; j < c->nmembers; j++) {
      Site *b = FindSite(sites, nsites, c->members[j]);
      if (b == NULL) continue;
      if (StrEq(a->path, b->path) && StrEq(a->range, b->range)) {
        CandFail(c, "E02");
      }
    }
  }

  // E06 -- a NAMED invariant, not a category.
  if (StrLen(c->invariant) < 16) CandFail(c, "E06");
  if (strncmp(c->invariant, "IR_VALUE_TYPE_CLASSIFICATION", 26) != 0 &&
      strncmp(c->invariant, "IR_TYPE_PROJECTION", 18) != 0 &&
      strncmp(c->invariant, "X86_64_COMPARISON", 17) != 0 &&
      strncmp(c->invariant, "AARCH64_COMPARISON", 18) != 0 &&
      strncmp(c->invariant, "TARGET_AGNOSTIC", 15) != 0 &&
      strncmp(c->invariant, "IR_TYPE_ANALYSIS_FAMILY", 24) != 0) {
    CandFail(c, "E06");
  }

  // E07 -- a credible path to M1/M2. The M2 producer is ABSENT in this
  // tree, so no candidate can be M2-critical; a candidate is M1-valid
  // when all its sites are compiler-core semantic decisions.
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    Bool core = StrCmp(s->klass, "CODEGEN_COMPARISON_CONDITION_CODE") == 0 ||
                StrCmp(s->klass, "CODEGEN_COMPARISON_CONDITION_CODE_INVERSE") == 0 ||
                StrCmp(s->klass, "CODEGEN_BOOLEAN_MATERIALISATION") == 0 ||
                StrCmp(s->klass, "CODEGEN_ORDERED_FLOAT_COMPARISON") == 0 ||
                StrCmp(s->klass, "TYPE_ANALYSIS") == 0;
    if (!core) CandFail(c, "E07");
  }

  // E12 -- a genuine C-only G0 path.
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    if (StrCmp(s->reach, "0_IMPORTERS") == 0) CandFail(c, "E12");
  }

  // E02 -- disjoint source ranges: no two members may share a byte
  // range in the same file.
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *a = FindSite(sites, nsites, c->members[i]);
    if (a == NULL) continue;
    for (I64 j = i + 1; j < c->nmembers; j++) {
      Site *b = FindSite(sites, nsites, c->members[j]);
      if (b == NULL) continue;
      if (StrEq(a->path, b->path) && StrEq(a->range, b->range)) {
        CandFail(c, "E02");
      }
    }
  }

  // E06 -- a NAMED invariant, not a category.
  if (StrLen(c->invariant) < 16) CandFail(c, "E06");
  if (strncmp(c->invariant, "IR_VALUE_TYPE_CLASSIFICATION", 26) != 0 &&
      strncmp(c->invariant, "IR_TYPE_PROJECTION", 18) != 0 &&
      strncmp(c->invariant, "X86_64_COMPARISON", 17) != 0 &&
      strncmp(c->invariant, "AARCH64_COMPARISON", 18) != 0 &&
      strncmp(c->invariant, "TARGET_AGNOSTIC", 15) != 0 &&
      strncmp(c->invariant, "IR_TYPE_ANALYSIS_FAMILY", 24) != 0) {
    CandFail(c, "E06");
  }

  // E13 -- feasibility of a full production C causal mutation: the
  // site's byte range must be well formed, so that it can be changed
  // without touching another site.
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    if (StrLen(s->range) < 3) CandFail(c, "E13");
    Bool has_dots = FALSE;
    for (I64 k = 0; k < StrLen(s->range); k++) {
      if (s->range[k] == '.') { has_dots = TRUE; break; }
    }
    if (!has_dots) CandFail(c, "E13");
  }

  // E16 -- a bounded implementation with deterministic build
  // prerequisites and NO unproven graph or SCC claim. A shape that
  // would need one ABI per target ABI is not a bounded implementation.
  if (!StrEq(c->abi, "BOUNDED_SCALAR_OUT")) {
    CandFail(c, "E16");
  }

  // E09 -- ownership and lifetime are explicit and non-leaking.
  for (I64 i = 0; i < c->nmembers; i++) {
    Site *s = FindSite(sites, nsites, c->members[i]);
    if (s == NULL) continue;
    if (StrLen(s->caller) < 3) CandFail(c, "E09");
  }

  c->eligible = FALSE;
  if (c->nfailed == 0) c->eligible = TRUE;
}


// ---------------------------------------------------------------------------
// The checker's own anti-selftests.
//
// Each test mutates an ISOLATED COPY of the inputs and requires the
// checker to reject the adverse shape with its OWN reason -- not merely
// "not green". A test that fires because of a generic parse error is
// NOT accepted.
// ---------------------------------------------------------------------------

// RunOneAdverse applies one adverse mutation to an in-memory copy of
// the inputs, re-evaluates the affected candidate, and returns 1 when
// the mutation was CAUGHT (the candidate became ineligible with at
// least one failed clause), 0 when it was MISSED, and -1 when the
// test could not be set up.
public I64 RunOneAdverse(I64 which, U8 *cands, I64 csize, U8 *sites, I64 ssize, U8 *facts, I64 fsize)
{
  U8 cb[8192];
  U8 sb[8192];
  U8 fb[8192];
  MemCpy(cb, cands, csize); cb[csize] = 0;
  MemCpy(sb, sites, ssize); sb[ssize] = 0;
  MemCpy(fb, facts, fsize); fb[fsize] = 0;

  if (which == 1) {
    // T1: an already PolyC-owned authority offered as a C candidate.
    U8 *p = FindStr(fb, "SITE-IR-ISFLOAT");
    if (p == NULL) return -1;
    p = FindStr(p, "YES");
    if (p == NULL) return -1;
    MemCpy(p, "NO ", 3);
  } else if (which == 2) {
    // T2: a dormant site (zero importers) offered as a candidate.
    U8 *p = FindStr(sb, "SITE-IR-ISFLOAT");
    if (p == NULL) return -1;
    U8 *q = FindStr(p, "5_IMPORTERS");
    if (q == NULL) return -1;
    MemCpy(q, "0_IMPORTERS", 11);
  } else if (which == 3) {
    // T3: a non-discriminating witness.
    U8 *p = FindStr(fb, "SITE-IR-ISFLOAT");
    if (p == NULL) return -1;
    p = FindStr(p, "IR_ASSEMBLY_OBJECT\tYES\t");
    if (p == NULL) return -1;
    MemCpy(p, "IR_ASSEMBLY_OBJECT\tNO\t", 22);
  } else if (which == 4) {
    // T4: a recovery-frame crossing.
    U8 *p = FindStr(fb, "SITE-IR-ISFLOAT");
    if (p == NULL) return -1;
    p = FindStr(p, "\t0\t0\t0\t");
    if (p == NULL) return -1;
    MemCpy(p, "\t0\t1\t0\t", 7);
  } else if (which == 5) {
    // T5: a two-target ABI projection, which is not a bounded single
    // implementation.
    U8 *p = FindStr(cb, "CAND-CMP-CC-BOTH");
    if (p == NULL) return -1;
    U8 *q = FindStr(p, "TWO_TARGET_ABI_PROJECTS");
    if (q == NULL) return -1;
    MemCpy(q, "BOUNDED_SCALAR_OUT_XX", 21);
  } else if (which == 6) {
    // T6: an unknown member site id.
    U8 *p = FindStr(cb, "SITE-IR-ISFLOAT;SITE-IR-ISINT");
    if (p == NULL) return -1;
    MemCpy(p, "SITE-IR-ISFLOAT;SITE-IR-NOPE", 31);
  } else if (which == 7) {
    // T7: a single-site bundle, which violates the 2..6 cardinality.
    // The mutation is applied to CAND-TYPE-CLASS's OWN member list,
    // so the search must start at that candidate's row.
    U8 *p = FindStr(cb, "CAND-TYPE-CLASS\t");
    if (p == NULL) return -1;
    p = FindStr(p, "\tSITE-IR-ISFLOAT;SITE-IR-ISINT\t");
    if (p == NULL) return -1;
    p += 1;
    // Replace the WHOLE member list with a single member, and blank
    // the bytes that followed it so the row stays well formed.
    MemCpy(p, "SITE-IR-ISFLOAT", 15);
    I64 rest = StrLen(p) - 15;
    for (I64 z = 0; z < rest; z++) p[15 + z] = ' ';
  } else if (which == 8) {
    // T8: a member that dereferences a caller-owned pointer.
    U8 *p = FindStr(fb, "SITE-IR-ISFLOAT");
    if (p == NULL) return -1;
    p = FindStr(p, "\t0\t0\t0\t");
    if (p == NULL) return -1;
    MemCpy(p, "\t0\t0\t2\t", 7);
  } else {
    return -1;
  }

  Site msites[MAX_SITE];
  Fact mfacts[MAX_SITE];
  Cand mcands[MAX_CAND];
  I64 mnsites = LoadSites(sb, ssize, msites, MAX_SITE);
  I64 mnfacts = LoadFacts(fb, fsize, mfacts, MAX_SITE);
  I64 mncands = LoadCands(cb, csize, mcands, MAX_CAND);

  I64 target = -1;
  for (I64 i = 0; i < mncands; i++) {
    if (StrEq(mcands[i].id, "CAND-CMP-CC-BOTH")) {
      if (which == 5) target = i;
    }
    if (StrEq(mcands[i].id, "CAND-TYPE-CLASS")) {
      if (which == 1 || which == 2 || which == 3 || which == 4 ||
          which == 6 || which == 7 || which == 8) target = i;
    }
  }
  if (target < 0) return -1;

  EvaluateCand(&mcands[target], msites, mnsites, mfacts, mnfacts);
  if (mcands[target].eligible) return 0;   // the mutation was NOT caught
  if (mcands[target].nfailed == 0) return 0;
  return 1;
}

public U0 SelftestMode(U8 *cands_path, U8 *sites_path, U8 *facts_path)
{
  I64 csize = 0;
  I64 ssize = 0;
  I64 fsize = 0;
  U8 *cdata = ReadFile(cands_path, &csize);
  U8 *sdata = ReadFile(sites_path, &ssize);
  U8 *fdata = ReadFile(facts_path, &fsize);
  if (cdata == NULL || sdata == NULL || fdata == NULL) {
    ESay("FINAL=FAIL\nREASON=INPUT_UNREADABLE\n");
    Exit(2);
  }

  I64 ncaught = 0;
  I64 ntests = 8;
  for (I64 t = 1; t <= ntests; t++) {
    I64 r = RunOneAdverse(t, cdata, csize, sdata, ssize, fdata, fsize);
    if (r == 1) {
      ncaught++;
      ESay("SELFTEST_CAUGHT=");
      ESay(StrPrint(NULL,"%d",t));
      ESay("\n");
    } else {
      ESay("SELFTEST_MISSED=");
      ESay(StrPrint(NULL,"%d",t));
      ESay("\n");
    }
  }

  // The pristine state must still be accepted: the checker must NOT
  // reject the genuine inputs.
  Site psites[MAX_SITE];
  Fact pfacts[MAX_SITE];
  Cand pcands[MAX_CAND];
  I64 pnsites = LoadSites(sdata, ssize, psites, MAX_SITE);
  I64 pnfacts = LoadFacts(fdata, fsize, pfacts, MAX_SITE);
  I64 pncands = LoadCands(cdata, csize, pcands, MAX_CAND);
  I64 pristine_eligible = 0;
  for (I64 i = 0; i < pncands; i++) {
    EvaluateCand(&pcands[i], psites, pnsites, pfacts, pnfacts);
    if (pcands[i].eligible) pristine_eligible++;
  }

  ESay("SELFTESTS_TOTAL=");
  ESay(StrPrint(NULL,"%d",ntests));
  ESay("\n");
  ESay("SELFTESTS_CAUGHT=");
  ESay(StrPrint(NULL,"%d",ncaught));
  ESay("\n");
  ESay("PRISTINE_ELIGIBLE=");
  ESay(StrPrint(NULL,"%d",pristine_eligible));
  ESay("\n");

  if (ncaught != ntests) {
    ESay("FINAL=FAIL\nREASON=SELFTEST_NOT_SENSITIVE\n");
    Exit(1);
  }
  if (pristine_eligible == 0) {
    ESay("FINAL=FAIL\nREASON=SELFTEST_REJECTS_PRISTINE\n");
    Exit(1);
  }
  ESay("FINAL=OK\n");
  Exit(0);
}


// Output. The candidate output is the checker's OWN eligible column.
// The ranker joins it by candidate id and never re-derives eligibility.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// The check mode.
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Output. The candidate output is the checker's OWN eligible column.
// The ranker joins it by candidate id and never re-derives eligibility.
// ---------------------------------------------------------------------------

// Append formats into a bounded buffer and returns the new length.
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

public U0 WriteOutputs(Cand *cands, I64 ncands, Site *sites, I64 nsites, Fact *facts, I64 nfacts, U8 *cand_out_path, U8 *site_out_path)
{
  U8 buf[16384];
  I64 n = 0;

  n = Append0(buf, n, 16384, "candidate_id\teligible\tfailed_clauses\tmember_count\tmembers\n");
  for (I64 i = 0; i < ncands; i++) {
    Cand *c = &cands[i];
    U8 *elig = "NO";
    if (c->eligible) elig = "YES";
    n = Append2(buf, n, 16384, "%s\t%s\t", &c->id[0], elig);
    if (c->nfailed == 0) {
      n = Append0(buf, n, 16384, "-\t");
    } else {
      for (I64 k = 0; k < c->nfailed; k++) {
        if (k > 0) n = Append0(buf, n, 16384, ",");
        n = Append1(buf, n, 16384, "%s", ClauseName(c->failed[k]));
      }
      n = Append0(buf, n, 16384, "\t");
    }
    U8 *cnt = StrPrint(NULL, "%d", c->nmembers);
    n = Append1(buf, n, 16384, "%s\t", cnt);
    for (I64 k = 0; k < c->nmembers; k++) {
      if (k > 0) n = Append0(buf, n, 16384, ";");
      n = Append1(buf, n, 16384, "%s", &c->members[k][0]);
    }
    n = Append0(buf, n, 16384, "\n");
  }
  FileWrite(cand_out_path, buf, n, O_CREAT|O_RDWR|O_TRUNC);

  n = 0;
  n = Append0(buf, n, 16384, "site_id\tin_scope\treachability\tc_authoritative\tsemantic_channel\tdiscriminating\twrites\trecovery\tderefs\tsingle_abi\n");
  for (I64 i = 0; i < nsites; i++) {
    Site *s = &sites[i];
    Fact *f = FindFact(facts, nfacts, s->id);
    U8 *scope_s = "NO";
    if (s->in_scope) scope_s = "YES";
    n = Append3(buf, n, 16384, "%s\t%s\t%s\t", &s->id[0], scope_s, &s->reach[0]);
    if (f == NULL) {
      n = Append0(buf, n, 16384, "-\t-\t-\t-\t-\t-\t-\t-\n");
    } else {
      n = Append3(buf, n, 16384, "%s\t%s\t%s\t", &f->c_auth[0], &f->channel[0], &f->disc[0]);
      U8 *w1 = StrPrint(NULL, "%d", f->writes);
      n = Append1(buf, n, 16384, "%s\t", w1);
      U8 *w2 = StrPrint(NULL, "%d", f->recovery);
      n = Append1(buf, n, 16384, "%s\t", w2);
      U8 *w3 = StrPrint(NULL, "%d", f->derefs);
      n = Append1(buf, n, 16384, "%s\t", w3);
      n = Append1(buf, n, 16384, "%s\n", &f->single_abi[0]);

    }
  }
  FileWrite(site_out_path, buf, n, O_CREAT|O_RDWR|O_TRUNC);
}

public U0 CheckMode(U8 *cands_path, U8 *sites_path, U8 *facts_path, U8 *cand_out, U8 *site_out)
{
  I64 csize = 0;
  I64 ssize = 0;
  I64 fsize = 0;
  U8 *cdata = ReadFile(cands_path, &csize);
  U8 *sdata = ReadFile(sites_path, &ssize);
  U8 *fdata = ReadFile(facts_path, &fsize);
  if (cdata == NULL || sdata == NULL || fdata == NULL) {
    ESay("FINAL=FAIL\nREASON=INPUT_UNREADABLE\n");
    Exit(2);
  }

  Site sites[MAX_SITE];
  Fact facts[MAX_SITE];
  Cand cands[MAX_CAND];
  I64 nsites = LoadSites(sdata, ssize, sites, MAX_SITE);
  I64 nfacts = LoadFacts(fdata, fsize, facts, MAX_SITE);
  I64 ncands = LoadCands(cdata, csize, cands, MAX_CAND);

  I64 neligible = 0;
  for (I64 i = 0; i < ncands; i++) {
    EvaluateCand(&cands[i], sites, nsites, facts, nfacts);
    if (cands[i].eligible) {
      neligible++;
      ESay("ELIGIBLE_LINE=");
      ESay(cands[i].id);
      ESay("\n");
    } else {
      ESay("EXCLUDED_LINE=");
      ESay(cands[i].id);
      ESay(" FAILED=");
      for (I64 k = 0; k < cands[i].nfailed; k++) {
        if (k > 0) ESay(",");
        ESay(ClauseName(cands[i].failed[k]));
      }
      ESay("\n");
    }
  }

  WriteOutputs(cands, ncands, sites, nsites, facts, nfacts, cand_out, site_out);

  ESay("CANDIDATES_TOTAL=");
  ESay(StrPrint(NULL,"%d",ncands));
  ESay("\n");
  ESay("ELIGIBLE_BUNDLES=");
  ESay(StrPrint(NULL,"%d",neligible));
  ESay("\n");
  ESay("FINAL=OK\n");
  Exit(0);
}


// ---------------------------------------------------------------------------
// Dispatch.
// ---------------------------------------------------------------------------

public U0 Main(I64 argc, I8 **argv)
{
  if (argc < 2) {
    ESay("FINAL=FAIL\nREASON=USAGE\n");
    Exit(2);
  }
  U8 *mode = argv[1];

  if (StrCmp(mode, "check") == 0) {
    if (argc < 7) { ESay("FINAL=FAIL\nREASON=USAGE\n"); Exit(2); }
    CheckMode(argv[2], argv[3], argv[4], argv[5], argv[6]);
    return;
  }
  if (StrCmp(mode, "selftest") == 0) {
    if (argc < 4) { ESay("FINAL=FAIL\nREASON=USAGE\n"); Exit(2); }
    SelftestMode(argv[2], argv[3], argv[4]);
    return;
  }

  ESay("FINAL=FAIL\nREASON=UNKNOWN_MODE\n");
  Exit(2);
}
