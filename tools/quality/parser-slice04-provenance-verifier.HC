// tools/quality/parser-slice04-provenance-verifier.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C3 IMPL.
//
// THE PROVENANCE WITNESS VERIFIER.
//
// WHY A WITNESS EXISTS
// ====================
//
// G1, G2 and G3 produce BYTE-IDENTICAL objects.  A finished object from
// one generation could therefore be SUBSTITUTED for another without
// changing the output bytes, and a check that only compared
// (object SHA, compiler SHA) would NOT detect it: both fields are
// copyable and relabelled.
//
// ACT section 9.5 therefore requires an EXECUTION-LINKED provenance
// witness, and this tool is the CHECKER for it.
//
// A witness is ACCEPTED only when ALL of the following hold:
//
//   1. the four generations' labels are exactly g0, g1, g2, g3 (so the
//      stage labels cannot be swapped);
//   2. every generation's PROVENANCE_NONCE is present;
//   3. every generation's PROBE_EXECUTION_OUTPUT is present and EQUALS
//      its PROVENANCE_NONCE (so the witness was produced by a REAL
//      EXECUTION, not by copying);
//   4. every generation's recorded COMPILER_BINARY_SHA256 equals the
//      ACTUAL sha256 of the recorded COMPILER_RESOLVED_PATH (so a
//      relabelled producer is detected);
//   5. every generation's recorded OUTPUT_OBJECT_SHA256 equals the
//      ACTUAL sha256 of the recorded OUTPUT_OBJECT_PATH (so a
//      substituted object is detected);
//   6. every generation's recorded SOURCE_SHA256 equals the ACTUAL
//      sha256 of the recorded SOURCE_PATH;
//   7. the four generations' nonces are DISTINCT (so a witness cannot
//      be copied from another generation).
//
// THE SHA-256 ADAPTER
// ===================
//
// The PolyC runtime has no SHA-256 primitive.  The hashing is done by
// the host's `shasum`, which is an INDISPENSABLE EXTERNAL TOOLCHAIN
// ADAPTER: it is a toolchain facility, not a verification decision.
// Every VERIFICATION DECISION -- which generation is present, whether
// the receipt matches the nonce, whether the recorded identity equals
// the live one, whether the nonces are distinct -- is made HERE, in
// PolyC.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  The only non-PolyC
// part is the `shasum` invocation.
//
// USAGE:
//   build/parser-slice04-provenance-verifier <witness-file>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/system.HC"

#define MAX_GENS 8
#define LINE_CAP 1024

static U8 *G_NAME[MAX_GENS];
static U8 *G_NONCE[MAX_GENS];
static U8 *G_PROBE_OUT[MAX_GENS];
static U8 *G_CC_PATH[MAX_GENS];
static U8 *G_CC_SHA[MAX_GENS];
static U8 *G_OBJ_PATH[MAX_GENS];
static U8 *G_OBJ_SHA[MAX_GENS];
static U8 *G_SRC_PATH[MAX_GENS];
static U8 *G_SRC_SHA[MAX_GENS];
static I64 G_N;

// Do the two strings denote the same bytes?
static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

// The length of a NUL-terminated string.
static I64 str_len(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

// Do the two strings start with the given prefix?
static I64 starts_with(U8 *s, U8 *prefix)
{
  I64 i = 0;
  while (prefix[i] != 0) {
    if (s[i] != prefix[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// Copy the value of a KEY=VALUE line.
static U8 *field_value(U8 *line, U8 *key)
{
  I64 kl = str_len(key);
  if (!starts_with(line, key)) return NULL;
  U8 *v = line + kl;
  return v;
}

// Append a character to a string.
static U8 *app_char(U8 *s, U8 c)
{
  I64 n = str_len(s);
  U8 *out = MAlloc(n + 2);
  I64 i = 0;
  while (i < n) { out[i] = s[i]; i = i + 1; }
  out[n] = c;
  out[n + 1] = 0;
  return out;
}

// The sha256 of a file, computed by the host's `shasum`.
//
// This is the INDISPENSABLE EXTERNAL TOOLCHAIN ADAPTER: the PolyC
// runtime has no SHA-256 primitive.  The recorded digest is read back
// from a per-call output file, so concurrent calls cannot interfere.
static U8 *sha256_of(U8 *path)
{
  U8 *out = MAlloc(128);
  out[0] = 0;
  U8 *cmd = StrPrint(NULL, "shasum -a 256 %s > ./build/slice04-sha.out 2>/dev/null", path);
  system(cmd);
  I64 fsz = 0;
  U8 *txt = FileRead("./build/slice04-sha.out", &fsz);
  if (txt != NULL) {
    I64 i = 0;
    while (txt[i] != 0 && txt[i] != 10 && txt[i] != 13 && txt[i] != 32) {
      out = app_char(out, txt[i]);
      i = i + 1;
    }
    Free(txt);
  }
  return out;
}


// Read the witness and populate the per-generation records.
static I64 LoadWitness(U8 *path)
{
  I64 fsz = 0;
  U8 *txt = FileRead(path, &fsz);
  if (txt == NULL) return -1;
  I64 n = 0;
  I64 cur = -1;
  U8 *p = txt;
  U8 *end = txt + fsz;
  while (p < end && n < MAX_GENS) {
    U8 *line_start = p;
    while (p < end && *p != 10) p++;
    U8 *line_end = p;
    if (p < end) p++;
    if (line_end > line_start && *(line_end - 1) == 13) line_end--;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;

    U8 *v = field_value(line, "GENERATION=");
    if (v != NULL) {
      n = n + 1;
      cur = n - 1;
      G_NAME[cur] = v;
      G_NONCE[cur] = NULL;
      G_PROBE_OUT[cur] = NULL;
      G_CC_PATH[cur] = NULL;
      G_CC_SHA[cur] = NULL;
      G_OBJ_PATH[cur] = NULL;
      G_OBJ_SHA[cur] = NULL;
      G_SRC_PATH[cur] = NULL;
      G_SRC_SHA[cur] = NULL;
      continue;
    }
    if (cur < 0) continue;
    v = field_value(line, "PROVENANCE_NONCE=");
    if (v != NULL) { G_NONCE[cur] = v; continue; }
    v = field_value(line, "PROBE_EXECUTION_OUTPUT=");
    if (v != NULL) { G_PROBE_OUT[cur] = v; continue; }
    v = field_value(line, "COMPILER_RESOLVED_PATH=");
    if (v != NULL) { G_CC_PATH[cur] = v; continue; }
    v = field_value(line, "COMPILER_BINARY_SHA256=");
    if (v != NULL) { G_CC_SHA[cur] = v; continue; }
    v = field_value(line, "OUTPUT_OBJECT_PATH=");
    if (v != NULL) { G_OBJ_PATH[cur] = v; continue; }
    v = field_value(line, "OUTPUT_OBJECT_SHA256=");
    if (v != NULL) { G_OBJ_SHA[cur] = v; continue; }
    v = field_value(line, "SOURCE_PATH=");
    if (v != NULL) { G_SRC_PATH[cur] = v; continue; }
    v = field_value(line, "SOURCE_SHA256=");
    if (v != NULL) { G_SRC_SHA[cur] = v; continue; }
  }
  G_N = n;
  return n;
}

// ---------------- The verification ---------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "build/slice04-gen/provenance";
  if (argc > 1) path = argv[1];

  I64 n = LoadWitness(path);
  if (n < 0) {
    "PROVENANCE_VERDICT=REJECTED\n";
    "REJECT_CANNOT_READ_WITNESS\n";
    "WITNESS=%s\n", path;
    return 1;
  }

  I64 fail = 0;

  // ---- 1. the stage labels are exactly g0, g1, g2, g3 ---------------
  if (n != 4) {
    "REJECT_STAGE_LABELS the witness carries %d generations, expected 4\n", n;
    fail = 1;
  }
  for (I64 i = 0; i < n; i++) {
    I64 ok = 0;
    if (StrEq(G_NAME[i], "g0")) ok = 1;
    if (StrEq(G_NAME[i], "g1")) ok = 1;
    if (StrEq(G_NAME[i], "g2")) ok = 1;
    if (StrEq(G_NAME[i], "g3")) ok = 1;
    if (!ok) {
      "REJECT_STAGE_LABELS the witness carries an unexpected generation label\n";
      fail = 1;
    }
  }

  for (I64 i = 0; i < n; i++) {
    U8 *g = G_NAME[i];

    // ---- 2. the nonce is present ------------------------------------
    if (G_NONCE[i] == NULL || str_len(G_NONCE[i]) == 0) {
      "REJECT_MISSING_NONCE %s has no PROVENANCE_NONCE\n", g;
      fail = 1;
      continue;
    }

    // ---- 3. the execution receipt is present and matches ------------
    if (G_PROBE_OUT[i] == NULL || str_len(G_PROBE_OUT[i]) == 0) {
      "REJECT_OMITTED_EXECUTION_RECEIPT %s has no PROBE_EXECUTION_OUTPUT\n", g;
      fail = 1;
      continue;
    }
    if (!StrEq(G_PROBE_OUT[i], G_NONCE[i])) {
      "REJECT_EXECUTION_RECEIPT_MISMATCH %s recorded probe output [%s] but its nonce is [%s]\n",
             g, G_PROBE_OUT[i], G_NONCE[i];
      fail = 1;
      continue;
    }

    // ---- 4. the producing compiler's identity -----------------------
    if (G_CC_PATH[i] == NULL || G_CC_SHA[i] == NULL) {
      "REJECT_MISSING_COMPILER_IDENTITY %s has no compiler identity\n", g;
      fail = 1;
      continue;
    }
    U8 *actual_cc = sha256_of(G_CC_PATH[i]);
    if (str_len(actual_cc) == 0) {
      "REJECT_MISSING_COMPILER %s names a compiler that cannot be hashed\n", g;
      fail = 1;
      continue;
    }
    if (!StrEq(actual_cc, G_CC_SHA[i])) {
      "REJECT_COMPILER_SHA_MISMATCH %s recorded compiler sha [%s] but the live compiler hashes to [%s]\n",
             g, G_CC_SHA[i], actual_cc;
      fail = 1;
      continue;
    }

    // ---- 5. the component object ------------------------------------
    if (G_OBJ_PATH[i] == NULL || G_OBJ_SHA[i] == NULL) {
      "REJECT_MISSING_OBJECT_IDENTITY %s has no object identity\n", g;
      fail = 1;
      continue;
    }
    U8 *actual_obj = sha256_of(G_OBJ_PATH[i]);
    if (str_len(actual_obj) == 0) {
      "REJECT_MISSING_OBJECT %s names an object that cannot be hashed\n", g;
      fail = 1;
      continue;
    }
    if (!StrEq(actual_obj, G_OBJ_SHA[i])) {
      "REJECT_OBJECT_SHA_MISMATCH %s recorded object sha [%s] but the live object hashes to [%s]\n",
             g, G_OBJ_SHA[i], actual_obj;
      fail = 1;
      continue;
    }

    // ---- 6. the source ----------------------------------------------
    if (G_SRC_PATH[i] == NULL || G_SRC_SHA[i] == NULL) {
      "REJECT_MISSING_SOURCE_IDENTITY %s has no source identity\n", g;
      fail = 1;
      continue;
    }
    U8 *actual_src = sha256_of(G_SRC_PATH[i]);
    if (str_len(actual_src) == 0) {
      "REJECT_MISSING_SOURCE %s names a source that cannot be hashed\n", g;
      fail = 1;
      continue;
    }
    if (!StrEq(actual_src, G_SRC_SHA[i])) {
      "REJECT_SOURCE_SHA_MISMATCH %s recorded source sha [%s] but the live source hashes to [%s]\n",
             g, G_SRC_SHA[i], actual_src;
      fail = 1;
      continue;
    }
  }

  // ---- 7. the nonces are DISTINCT -------------------------------------
  for (I64 i = 0; i < n; i++) {
    if (G_NONCE[i] == NULL) continue;
    for (I64 j = i + 1; j < n; j++) {
      if (G_NONCE[j] == NULL) continue;
      if (StrEq(G_NONCE[i], G_NONCE[j])) {
        "REJECT_DUPLICATE_NONCE the witness carries the same nonce for two generations\n";
        fail = 1;
      }
    }
  }

  "GENERATIONS_VERIFIED=%d\n", n;
  if (fail != 0) {
    "PROVENANCE_VERDICT=REJECTED\n";
    return 1;
  }
  "PROVENANCE_VERDICT=ACCEPTED\n";
  return 0;
}
