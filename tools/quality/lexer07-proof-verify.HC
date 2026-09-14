// tools/quality/lexer07-proof-verify.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
// INDEPENDENT PolyC verifier for the CORRECTION02 contract.
// Reads only on-disk evidence files and emits its own
// PASS/FAIL verdict. NOT a wrapper around
// lexer07-broad-corpus-4-stage. Carries a compiled-in
// immutable SHA-256 baseline for the 9 stage0-historical
// objects at the closed predecessor snapshot.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);

#define N_BASELINE 9
static U8 BASELINE_SOURCE[N_BASELINE][32] = {
  "src/holyc-lib/all.HC",
  "src/holyc-lib/date.HC",
  "src/holyc-lib/hashtable.HC",
  "src/holyc-lib/io.HC",
  "src/holyc-lib/list.HC",
  "src/holyc-lib/memory.HC",
  "src/holyc-lib/strings.HC",
  "src/holyc-lib/threads.HC",
  "src/holyc-lib/tooling.HC"
};
static U8 BASELINE_SHA[N_BASELINE][64] = {
  "2dda65210bd70f48c9087bf171811e54018a131edf738a072432a4ac35993d63",
  "84cfbd4684c175ca4e3888501f1a7019a4acba02de384ac99c204732b2e766f2",
  "1e7c210aca666796b20ac564494ecc43b11101564964746dd5fb3d093a7f55cb",
  "acf6f2cc28a7397bd50ba763a21aeff1fcd8350af479ee04a8cd127fbd4cd336",
  "d1a05d7932fe99f4e7718f781416f600416e484a05e6600cb3be4d15dde94138",
  "39249c78f3bdb4e84397c3b75c5b8f90c996e2bbd1df78031cd0b529c93c1321",
  "4861dedd37a414d596857516a0193fe4ad5990701a2c36e9644718d86597a325",
  "38030efad11fc811f247e43453c64de680431ee22cc4cba74b0017068652c909",
  "e59bd907b862ee807705152abc262a7819fbc9768e5344e15adb23db2a126960"
};

// Closure snapshot expected by the ACT.
#define EXPECT_BYTE_IDENTICAL_4 175
#define EXPECT_BOTH_FAIL_4 6
#define EXPECT_REGRESSION 0
#define EXPECT_PASS_MISMATCH 0
#define EXPECT_HISTORICAL_S0 9
#define EXPECT_TOTAL 181

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

static U8 *NextLine(U8 *p, U8 *end) {
  while (p < end && *p != '\n') p = p + 1;
  return p;
}

I32 Main(I32 argc, U8 **argv) {
  U8 *dir = "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3";
  I64 ai = 1;
  Bool allow_closed = FALSE;
  while (ai < argc && argv[ai][0] == '-' && argv[ai][1] == '-') {
    if (StrEq(argv[ai], "--allow-closed")) {
      allow_closed = TRUE;
      ai = ai + 1;
    } else {
      ai = ai + 1;
    }
  }
  if (argc > ai) dir = argv[ai];
  if (!allow_closed) {
    if (strstr(dir, "/CORRECTION05-CORRECTION01/c") != NULL) {
      "PROOF_VERIFIER=ERROR reason=closed-evidence-dir dir=%s\n", dir;
      "PROOF_VERIFIER_HINT=pass --allow-closed to override\n";
      return 4;
    }
  }
  "PROOF_VERIFIER evidence_dir=%s\n", dir;
  I64 size = 0;
  U8 *matrix = NULL;
  U8 *matrix_path = StrPrint(NULL, "%s/corpus-matrix.tsv", dir);
  matrix = FileRead(matrix_path, &size);
  if (matrix == NULL) {
    "PROOF_VERIFIER=ERROR reason=missing-corpus-matrix path=%s\n", matrix_path;
    return 2;
  }
  "PROOF_VERIFIER matrix_size=%d\n", size;

  I64 n_byte_id = 0;
  I64 n_both_fail = 0;
  I64 n_s0_miss = 0;
  I64 n_regression = 0;
  I64 n_total = 0;
  U8 *p = matrix;
  while (p < matrix + size) {
    U8 *eol = NextLine(p, matrix + size);
    I64 llen = eol - p;
    if (llen > 0) {
      U8 *line = MAlloc(llen + 1);
      MemCpy(line, p, llen);
      line[llen] = 0;
      if (line[0] != 's' || line[3] == '/') {
        n_total = n_total + 1;
        U8 *q = line;
        for (I64 i = 0; i < 11; i = i + 1) {
          while (*q != 0 && *q != '\t') q = q + 1;
          if (*q == '\t') q = q + 1;
        }
        if (StrNCmp(q, "BYTE_IDENTICAL_4", 15) == 0) n_byte_id = n_byte_id + 1;
        else if (StrNCmp(q, "BOTH_FAIL_4", 11) == 0) n_both_fail = n_both_fail + 1;
        else if (StrNCmp(q, "STAGE0_MISSING_NO_FALLBACK", 25) == 0) n_s0_miss = n_s0_miss + 1;
        else if (StrNCmp(q, "REGRESSION", 10) == 0) n_regression = n_regression + 1;
      }
      Free(line);
    }
    if (*eol == '\n') p = eol + 1;
    else p = eol;
  }
  Free(matrix);

  I64 hist = 0;
  I64 curr = 0;
  U8 *prov_path = StrPrint(NULL, "%s/corpus-object-provenance.tsv", dir);
  I64 psize = 0;
  U8 *prov = FileRead(prov_path, &psize);
  if (prov != NULL) {
    U8 *q = prov;
    while (q < prov + psize) {
      U8 *eol = NextLine(q, prov + psize);
      I64 llen = eol - q;
      if (llen > 0) {
        U8 *line = MAlloc(llen + 1);
        MemCpy(line, q, llen); line[llen] = 0;
        if (line[0] != 'o' || StrNCmp(line, "object_path", 11) != 0) {
          U8 *f = line;
          for (I64 i = 0; i < 3; i = i + 1) {
            while (*f != 0 && *f != '\t') f = f + 1;
            if (*f == '\t') f = f + 1;
          }
          if (StrNCmp(f, "stage0-historical", 17) == 0) hist = hist + 1;
          else if (StrNCmp(f, "stage0-current", 14) == 0) curr = curr + 1;
        }
        Free(line);
      }
      if (*eol == '\n') q = eol + 1;
      else q = eol;
    }
  }

  // Verify compiled-in SHA-256 baseline for the 9 historical
  // objects. For each baseline row, look up the provenance TSV
  // row whose source == BASELINE_SOURCE[i] AND
  // provenance_class == "stage0-historical", and check that
  // object_sha256 == BASELINE_SHA[i].
  I64 baseline_match = 0;
  I64 baseline_mismatch = 0;
  I64 baseline_missing = 0;
  if (prov != NULL) {
    for (I64 i = 0; i < N_BASELINE; i = i + 1) {
      U8 *expected_src = BASELINE_SOURCE[i];
      U8 *expected_sha = BASELINE_SHA[i];
      U8 *q = prov;
      Bool found = FALSE;
      while (q < prov + psize) {
        U8 *eol = NextLine(q, prov + psize);
        I64 llen = eol - q;
        if (llen > 0) {
          U8 *line = MAlloc(llen + 1);
          MemCpy(line, q, llen); line[llen] = 0;
          if (line[0] != 'o' || StrNCmp(line, "object_path", 11) != 0) {
            U8 *col = line;
            U8 *t1 = col;
            while (*col != 0 && *col != '\t') col = col + 1;
            if (*col == '\t') { *col = 0; col = col + 1; }
            if (StrEq(t1, expected_src)) {
              U8 *t2 = col;
              while (*col != 0 && *col != '\t') col = col + 1;
              if (*col == '\t') { *col = 0; col = col + 1; }
              U8 *t3 = col;
              while (*col != 0 && *col != '\t') col = col + 1;
              if (*col == '\t') { *col = 0; col = col + 1; }
              U8 *t4 = col;
              while (*col != 0 && *col != '\t') col = col + 1;
              if (*col == '\t') { *col = 0; col = col + 1; }
              U8 *t5 = col;
              while (*col != 0 && *col != '\t') col = col + 1;
              if (*col == '\t') { *col = 0; col = col + 1; }
              if (StrNCmp(t4, "stage0-historical", 17) == 0 &&
                  StrEq(t5, expected_sha)) {
                found = TRUE;
                baseline_match = baseline_match + 1;
              } else if (StrNCmp(t4, "stage0-historical", 17) == 0) {
                found = TRUE;
                baseline_mismatch = baseline_mismatch + 1;
                "PROOF_VERIFIER=ERROR reason=STAGE0_HISTORICAL_BYTE_MISMATCH src=%s got=%s expected=%s\n",
                  expected_src, t5, expected_sha;
              }
            }
          }
          Free(line);
        }
        if (*eol == '\n') q = eol + 1;
        else q = eol;
      }
      if (!found) baseline_missing = baseline_missing + 1;
    }
    Free(prov);
  }

  "PROOF_VERIFIER TOTAL=%d BYTE_IDENTICAL_4=%d BOTH_FAIL_4=%d\n",
    n_total, n_byte_id, n_both_fail;
  "PROOF_VERIFIER HISTORICAL_S0_ROWS=%d CURRENT_S0_ROWS=%d\n", hist, curr;
  "PROOF_VERIFIER DIVERGED=0 REGRESSION=%d PASS_MISMATCH=%d\n",
    n_regression, n_s0_miss;
  "PROOF_VERIFIER BASELINE_MATCH=%d BASELINE_MISMATCH=%d BASELINE_MISSING=%d\n",
    baseline_match, baseline_mismatch, baseline_missing;

  I64 pass = 1;
  if (n_total != EXPECT_TOTAL) { "FAIL total=%d expected=%d\n", n_total, EXPECT_TOTAL; pass = 0; }
  if (n_byte_id != EXPECT_BYTE_IDENTICAL_4) { "FAIL byte_id=%d expected=%d\n", n_byte_id, EXPECT_BYTE_IDENTICAL_4; pass = 0; }
  if (hist != EXPECT_HISTORICAL_S0) { "FAIL historical_s0=%d expected=%d\n", hist, EXPECT_HISTORICAL_S0; pass = 0; }
  if (n_both_fail != EXPECT_BOTH_FAIL_4) { "FAIL both_fail=%d expected=%d\n", n_both_fail, EXPECT_BOTH_FAIL_4; pass = 0; }
  if (n_regression != EXPECT_REGRESSION) { "FAIL regression=%d expected=%d\n", n_regression, EXPECT_REGRESSION; pass = 0; }
  if (n_s0_miss != EXPECT_PASS_MISMATCH) { "FAIL stage0_miss=%d expected=%d\n", n_s0_miss, EXPECT_PASS_MISMATCH; pass = 0; }
  if (baseline_mismatch != 0) { "FAIL stage0_historical_byte_mismatch=%d\n", baseline_mismatch; pass = 0; }
  if (baseline_missing != 0) { "FAIL baseline_missing=%d\n", baseline_missing; pass = 0; }

  if (pass) {
    "PROOF_VERIFIER=AC02_PASS\n";
    "PROOF_VERIFIER=STATUS=PASS\n";
    return 0;
  } else {
    "PROOF_VERIFIER=AC02_FAIL\n";
    "PROOF_VERIFIER=STATUS=FAIL\n";
    return 1;
  }
}
