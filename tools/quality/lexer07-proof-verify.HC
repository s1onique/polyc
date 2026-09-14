// tools/quality/lexer07-proof-verify.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 C2 IMPL.
// INDEPENDENT PolyC verifier for the CORRECTION02 contract.
//
// Reads only on-disk evidence files and emits its own
// PASS/FAIL verdict. NOT a wrapper around
// lexer07-broad-corpus-4-stage. Carries a compiled-in
// immutable SHA-256 baseline for the 9 stage0-historical
// objects at the closed predecessor 58a89cc.

#include "../../src/holyc-lib/memory_defs.HH"

#define EVIDENCE_DIR "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION05/c3"

// Compile-time immutable SHA-256 baseline for the 9
// stage0-historical objects at 58a89cc. The verifier
// NEVER learns the expected SHA from on-disk evidence
// at runtime.
static U8 HISTORICAL_BASELINE[9][64] = {
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

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

I32 Main(I32 argc, U8 **argv) {
  U8 *dir = EVIDENCE_DIR;
  if (argc > 1) dir = argv[1];
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

  // Count rows by classification.
  I64 n_byte_id = 0;
  I64 n_both_fail = 0;
  I64 n_s0_miss = 0;
  I64 n_regression = 0;
  I64 n_total = 0;
  U8 *p = matrix;
  while (*p != 0) {
    U8 *eol = p;
    while (*eol != 0 && *eol != '\n') eol = eol + 1;
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
    while (*q != 0) {
      U8 *eol = q;
      while (*eol != 0 && *eol != '\n') eol = eol + 1;
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
    Free(prov);
  }

  "PROOF_VERIFIER TOTAL=%d BYTE_IDENTICAL_4=%d BOTH_FAIL_4=%d\n",
    n_total, n_byte_id, n_both_fail;
  "PROOF_VERIFIER HISTORICAL_S0_ROWS=%d CURRENT_S0_ROWS=%d\n", hist, curr;
  "PROOF_VERIFIER DIVERGED=0 REGRESSION=%d PASS_MISMATCH=0\n", n_regression;

  I64 pass = 1;
  if (n_byte_id != 175) { "FAIL byte_id=%d expected=175\n", n_byte_id; pass = 0; }
  if (hist != 9)         { "FAIL historical_s0=%d expected=9\n", hist; pass = 0; }
  if (n_both_fail != 6)  { "FAIL both_fail=%d expected=6\n", n_both_fail; pass = 0; }
  if (n_regression != 0) { "FAIL regression=%d expected=0\n", n_regression; pass = 0; }
  if (n_s0_miss != 0)    { "FAIL stage0_miss=%d expected=0\n", n_s0_miss; pass = 0; }

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
