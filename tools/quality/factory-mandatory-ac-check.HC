// tools/quality/factory-mandatory-ac-check.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
//
// Mechanical mandatory-AC closure verifier.
//
// Reads a deterministic TSV with the schema:
//   ac_id  <TAB>  mandatory  <TAB>  status  <TAB>  evidence_path
//
// Permitted status values:
//   PASS / FAIL / PARTIAL / DEFERRED / UNKNOWN
//
// Required close predicate:
//   - mandatory=1 rows with status!=PASS => HALT_MANDATORY_AC_NOT_GREEN
//   - duplicate ac_id => HALT_MANDATORY_AC_NOT_GREEN
//   - evidence_path empty for mandatory=PASS rows => HALT_MANDATORY_AC_NOT_GREEN
//   - mandatory=0 rows are NOT counted toward the closure predicate
//
// On success, emits a single STATUS=PASS line and rc=0.
// On failure, emits STATUS=FAIL plus per-counter lines and
// rc=1.
//
// Usage:
//   build/factory-mandatory-ac-check <status_tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "MANDATORY_AC_CHECK usage: %s <status_tsv>\n", argv[0];
    return 1;
  }
  U8 *path = argv[1];
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) {
    "MANDATORY_AC_CHECK=ERROR reason=cannot-read path=%s\n", path;
    return 2;
  }

  // Initialize accumulators.
  I64 total = 0;
  I64 mandatory_total = 0;
  I64 mandatory_pass = 0;
  I64 mandatory_fail = 0;
  I64 mandatory_partial = 0;
  I64 mandatory_deferred = 0;
  I64 mandatory_unknown = 0;
  I64 mandatory_missing_evidence = 0;
  I64 duplicate = 0;

  // Track last 64 ac_ids for duplicate detection (small bounded
  // history; bounded by row count below).
  U8 seen_ids[4096][64];
  I64 seen_n = 0;

  U8 *p = buf;
  U8 *end = buf + sz;
  I64 lineno = 0;
  while (p < end) {
    U8 *eol = p;
    while (eol < end && *eol != '\n') eol = eol + 1;
    I64 llen = eol - p;
    if (llen > 0 && *p != '#') {
      // Parse: ac_id <TAB> mandatory <TAB> status <TAB> evidence_path
      U8 *line = MAlloc(llen + 1);
      MemCpy(line, p, llen);
      line[llen] = 0;
      // Token 1: ac_id
      U8 *q = line;
      U8 *t1 = q;
      while (*q != 0 && *q != '\t') q = q + 1;
      if (*q == '\t') { *q = 0; q = q + 1; }
      U8 *ac_id = t1;
      // Token 2: mandatory
      U8 *t2 = q;
      while (*q != 0 && *q != '\t') q = q + 1;
      if (*q == '\t') { *q = 0; q = q + 1; }
      U8 *mand = t2;
      // Token 3: status
      U8 *t3 = q;
      while (*q != 0 && *q != '\t') q = q + 1;
      if (*q == '\t') { *q = 0; q = q + 1; }
      U8 *status = t3;
      // Token 4: evidence_path (rest)
      U8 *ev = q;
      while (*ev != 0 && *ev != '\r' && *ev != '\n') ev = ev + 1;
      *ev = 0;
      // `ev` now points at the terminator (\0). The path
      // itself is the substring at `q`. Detect empty path
      // by checking `q[0] == 0`.

      if (StrEq(ac_id, "ac_id") == 0) {
        lineno = lineno + 1;
        total = total + 1;
        // Skip header row.
        if (lineno == 1 && StrEq(ac_id, "ac_id") == 0) {
          // already not header
        }
        I64 is_mandatory = 0;
        if (StrEq(mand, "1") || StrEq(mand, "true") || StrEq(mand, "TRUE") ||
            StrEq(mand, "yes") || StrEq(mand, "YES"))
          is_mandatory = 1;

        // Duplicate detection.
        I64 dup = 0;
        for (I64 k = 0; k < seen_n; k = k + 1) {
          if (StrEq(seen_ids[k], ac_id)) { dup = 1; break; }
        }
        if (dup) {
          duplicate = duplicate + 1;
        } else if (seen_n < 4096) {
          I64 j = 0;
          while (ac_id[j] != 0 && j < 63) { seen_ids[seen_n][j] = ac_id[j]; j = j + 1; }
          seen_ids[seen_n][j] = 0;
          seen_n = seen_n + 1;
        }

        if (is_mandatory) {
          mandatory_total = mandatory_total + 1;
          if (StrEq(status, "PASS")) {
            mandatory_pass = mandatory_pass + 1;
            if (q[0] == 0) {
              mandatory_missing_evidence = mandatory_missing_evidence + 1;
            }
          }
          else if (StrEq(status, "FAIL"))   mandatory_fail = mandatory_fail + 1;
          else if (StrEq(status, "PARTIAL")) mandatory_partial = mandatory_partial + 1;
          else if (StrEq(status, "DEFERRED")) mandatory_deferred = mandatory_deferred + 1;
          else                              mandatory_unknown = mandatory_unknown + 1;
        }
      }
      Free(line);
    }
    if (eol < end) p = eol + 1;
    else p = eol;
  }
  Free(buf);

  I64 mandatory_nonpass = mandatory_fail + mandatory_partial +
                          mandatory_deferred + mandatory_unknown +
                          mandatory_missing_evidence;
  "MANDATORY_AC_TOTAL=%d\n", total;
  "MANDATORY_AC_MANDATORY_TOTAL=%d\n", mandatory_total;
  "MANDATORY_AC_PASS=%d\n", mandatory_pass;
  "MANDATORY_AC_FAIL=%d\n", mandatory_fail;
  "MANDATORY_AC_PARTIAL=%d\n", mandatory_partial;
  "MANDATORY_AC_DEFERRED=%d\n", mandatory_deferred;
  "MANDATORY_AC_UNKNOWN=%d\n", mandatory_unknown;
  "MANDATORY_AC_MISSING_EVIDENCE=%d\n", mandatory_missing_evidence;
  "MANDATORY_AC_DUPLICATE=%d\n", duplicate;
  "MANDATORY_AC_NONPASS=%d\n", mandatory_nonpass;

  if (mandatory_total == 0) {
    "MANDATORY_AC_CHECK=ERROR reason=no-mandatory-acs\n";
    return 3;
  }
  if (duplicate != 0) {
    "MANDATORY_AC_CHECK=ERROR reason=duplicate-acs count=%d\n", duplicate;
    return 4;
  }
  if (mandatory_nonpass != 0) {
    "MANDATORY_AC_CHECK=ERROR reason=mandatory-nonpass count=%d\n",
      mandatory_nonpass;
    "CLOSURE_AC_STATUS=FAIL\n";
    return 1;
  }
  if (mandatory_pass != mandatory_total) {
    "MANDATORY_AC_CHECK=ERROR reason=pass-mismatch pass=%d total=%d\n",
      mandatory_pass, mandatory_total;
    "CLOSURE_AC_STATUS=FAIL\n";
    return 5;
  }

  "CLOSURE_AC_STATUS=PASS\n";
  return 0;
}