// tools/quality/parser-slice-recon03-eligibility.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 C2 IMPL.
//
// MECHANICAL 13-CLAUSE ELIGIBILITY CHECKER for the parser-slice
// reconnaissance candidates.
//
// The checker computes `eligible` from the FACT fields in the input
// table.  There is NO `eligible` column in the input schema: an
// eligibility flag can therefore NOT be hand-authored or
// hand-overridden.  A candidate is eligible only when ALL THIRTEEN
// clauses hold.
//
// The thirteen clauses (ACT §8.1):
//
//   01 semantic_authority == YES
//   02 already_selfhosted == NO
//   03 r0 <= 2
//   04 owns_setjmp == NO
//   05 writes_current_recovery == NO
//   06 requires_nonlocal_recovery == NO
//   07 host_graph_writes == 0
//   08 pointer_identity_operations == 0
//   09 parser_callback_count == 0
//   10 semantic_callback_count == 0
//   11 deterministic_projection == YES
//   12 production_delegation_feasible == YES
//   13 candidate_kind is runtime semantic authority
//
// INPUT SCHEMA (tab-separated, one candidate per data line; `#` starts a
// comment line; blank lines are ignored):
//
//   01 candidate_id
//   02 function_name
//   03 source_file
//   04 source_start
//   05 source_end
//   06 candidate_kind
//   07 semantic_authority        YES|NO
//   08 already_selfhosted        YES|NO
//   09 r0                        0..5
//   10 owns_setjmp               YES|NO
//   11 writes_current_recovery   YES|NO
//   12 requires_nonlocal_recovery YES|NO
//   13 host_graph_writes         integer
//   14 pointer_identity_operations integer
//   15 parser_callback_count     integer
//   16 semantic_callback_count   integer
//   17 deterministic_projection  YES|NO
//   18 production_delegation_feasible YES|NO
//   19 production_reachable      YES|NO
//   20 exclusion_reason          free text (may be empty)
//
// The `candidate_kind` values that satisfy clause 13 are:
//
//   OPERATOR_PRECEDENCE_TABLE
//   OPERATOR_CLASSIFIER
//   FORMAT_SPEC_COUNTER
//   FORMAT_FUNCTION_TABLE
//   ALIGNMENT_CALCULATION
//   TOKEN_CLASSIFIER
//   AST_PROJECTION_PRIMITIVE
//   DELIMITER_PRIMITIVE
//   TYPE_MODIFIER_PRIMITIVE
//
// These are the RUNTIME SEMANTIC AUTHORITY kinds: each one carries a
// decision that changes the compiler's observable output.  Kinds such as
// STATIC_HELPER, ORCHESTRATOR, DIAGNOSTIC_HELPER and DEAD_OR_NONRUNTIME
// are NOT runtime semantic authority and are excluded by clause 13.
//
// OUTPUT: one line per candidate, tab-separated:
//
//   candidate_id  eligible(YES|NO)  clause01..clause13 (each 1|0)  failed
//
// A candidate is ELIGIBLE only if every clause bit is 1 and the
// production_reachable fact is also YES (clause 12's delegation
// feasibility is only meaningful for a reachable candidate).

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define N_FIELDS 20
#define N_CLAUSES 13

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

static I64 IsYes(U8 *s) { return StrEq(s, "YES"); }

// Parse a leading signed decimal integer.  Returns 0 when the field is
// not an integer at all.
static I64 ParseInt(U8 *s)
{
  I64 v = 0;
  I64 neg = 0;
  U8 *p = s;
  if (*p == '-') { neg = 1; p++; }
  if (*p == 0) return 0;
  while (*p >= '0' && *p <= '9') {
    v = v * 10 + (*p - '0');
    p++;
  }
  if (*p != 0) return 0;
  if (neg) return -v;
  return v;
}

// Split one tab-separated line into at most N_FIELDS pointers.
// Returns the number of fields actually present.

// Split one tab-separated line into at most N_FIELDS pointers.
// Returns the number of fields actually present.
static I64 SplitTabs(U8 *line, U8 *out[])
{
  I64 n = 0;
  U8 *p = line;
  while (n < N_FIELDS) {
    out[n] = p;
    n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0;
    p++;
  }
  return n;
}

// Clause 13: is this candidate kind a runtime semantic authority?

// Clause 13: is this candidate kind a runtime semantic authority?
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

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c1/candidate-eligibility-facts.tsv";
  I64 ai = 1;
  if (argc > ai) path = argv[ai];

  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_INPUT\n";
    "INPUT=%s\n", path;
    return 1;
  }

  I64 total = 0;
  I64 eligible = 0;
  I64 malformed = 0;

  U8 *p = buf;
  U8 *end = buf + fsize;

  while (p < end) {
    // Extract one line.
    U8 *line_start = p;
    while (p < end && *p != '\n') p++;
    U8 *line_end = p;
    if (p < end) p++;
    // Strip a trailing CR.
    if (line_end > line_start && *(line_end - 1) == '\r') line_end--;
    *line_end = 0;

    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;

    U8 *f[N_FIELDS];
    I64 nf = SplitTabs(line, f);
    if (nf < N_FIELDS) {
      malformed++;
      continue;
    }

    total++;

    I64 c[N_CLAUSES + 1];

    // 01 semantic_authority
    c[1] = IsYes(f[6]);
    // 02 already_selfhosted == NO
    c[2] = 0;
    if (StrEq(f[7], "NO")) c[2] = 1;
    // 03 r0 <= 2
    I64 r0 = ParseInt(f[8]);
    c[3] = 0;
    if (r0 >= 0 && r0 <= 2) c[3] = 1;
    // 04 owns_setjmp == NO
    c[4] = 0;
    if (StrEq(f[9], "NO")) c[4] = 1;
    // 05 writes_current_recovery == NO
    c[5] = 0;
    if (StrEq(f[10], "NO")) c[5] = 1;
    // 06 requires_nonlocal_recovery == NO
    c[6] = 0;
    if (StrEq(f[11], "NO")) c[6] = 1;
    // 07 host_graph_writes == 0
    c[7] = 0;
    if (ParseInt(f[12]) == 0) c[7] = 1;
    // 08 pointer_identity_operations == 0
    c[8] = 0;
    if (ParseInt(f[13]) == 0) c[8] = 1;
    // 09 parser_callback_count == 0
    c[9] = 0;
    if (ParseInt(f[14]) == 0) c[9] = 1;
    // 10 semantic_callback_count == 0
    c[10] = 0;
    if (ParseInt(f[15]) == 0) c[10] = 1;
    // 11 deterministic_projection == YES
    c[11] = IsYes(f[16]);
    // 12 production_delegation_feasible == YES
    c[12] = IsYes(f[17]);
    // 13 candidate_kind is runtime semantic authority
    c[13] = KindIsRuntimeSemanticAuthority(f[5]);

    I64 ok = 1;
    I64 failed = 0;
    for (I64 k = 1; k <= N_CLAUSES; k++) {
      if (!c[k]) { ok = 0; failed++; }
    }

    // A candidate that is not production-reachable can never be
    // delegated: the delegation-feasibility clause is vacuous for it.
    if (!IsYes(f[18])) ok = 0;

    if (ok) eligible++;

    U8 *elig_str = "NO";
    if (ok) elig_str = "YES";

    "%s\t%s\t", f[0], elig_str;
    for (I64 k = 1; k <= N_CLAUSES; k++) {
      "%d", c[k];
    }
    "\t%d\n", failed;
  }

  Free(buf);

  "TOTAL=%d\n", total;
  "ELIGIBLE=%d\n", eligible;
  "MALFORMED=%d\n", malformed;
  if (malformed == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}
