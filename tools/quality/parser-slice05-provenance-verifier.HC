// tools/quality/parser-slice05-provenance-verifier.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C1.
//
// THE GENERATION-SCOPED PROVENANCE WITNESS VERIFIER.
//
// WHY A NEW VERIFIER
// ==================
//
// The SLICE04 verifier is closed evidence under F14 and MUST NOT be
// modified.  It also cannot express the two controls this ACT requires:
//
//   D-PROV-01  a COMPLETE four-generation witness whose G3 slot carries
//              the G1 payload.  The SLICE04 verifier has no
//              per-generation BINDING field, so it cannot tell that
//              apart from a legitimate G3 row.
//   D-PROV-02  a COMPLETE four-generation witness whose G3 execution
//              receipt has been removed.  The SLICE04 verifier's
//              receipt reason is GENERIC and names whichever
//              generation happens to fail first.
//
// This verifier therefore adds:
//
//   1. a per-generation BINDING field (GENERATION_BINDING), compared
//      against the EXPECTED binding for that generation.  This is what
//      makes a G1 payload in the G3 slot detectable;
//   2. GENERATION-SCOPED rejection reasons, so a G3 defect is reported
//      as a G3 defect and not as a generic failure;
//   3. NO SHORT-CIRCUIT.  Every check is evaluated for every generation
//      and EVERY diagnostic is reported, so a control that breaks
//      several things at once cannot be satisfied by the first
//      unrelated failure.
//
// THE NO-SHORT-CIRCUIT RULE IS THE POINT
// ======================================
//
// Both SLICE04 defects had the SAME root cause: the control mutation
// also broke the witness's STRUCTURE, so the structural detector fired
// first and the intended per-generation detector was never exercised.
// A verifier that reports only the first failure cannot avoid that
// class of defect by construction.  This one reports everything.
//
// THE SHA-256 ADAPTER
// ===================
//
// The PolyC runtime has no SHA-256 primitive.  The hashing is done by
// the host's `shasum`, which is an INDISPENSABLE EXTERNAL TOOLCHAIN
// ADAPTER: it is a toolchain facility, not a verification decision.
// Every VERIFICATION DECISION -- which generation is present, whether
// the binding matches, whether the receipt matches the nonce, whether
// the recorded identity equals the live one, whether the nonces are
// distinct -- is made HERE, in PolyC.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  The only non-PolyC
// part is the `shasum` invocation.
//
// USAGE:
//   build/parser-slice05-provenance-verifier <witness-file>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/system.HC"

#define MAX_GENS 8
#define LINE_CAP 1024

static U8 *G_NAME[MAX_GENS];
static U8 *G_BINDING[MAX_GENS];
static U8 *G_NONCE[MAX_GENS];
static U8 *G_PROBE_OUT[MAX_GENS];
static U8 *G_CC_PATH[MAX_GENS];
static U8 *G_CC_SHA[MAX_GENS];
static U8 *G_OBJ_PATH[MAX_GENS];
static U8 *G_OBJ_SHA[MAX_GENS];
static U8 *G_SRC_PATH[MAX_GENS];
static U8 *G_SRC_SHA[MAX_GENS];
static U8 *G_RECEIPT_ID[MAX_GENS];
static U8 *G_RUN_BINDING[MAX_GENS];
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

// Does the two strings start with the given prefix?
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
// from a per-call output file.
static U8 *sha256_of(U8 *path)
{
  U8 *out = MAlloc(128);
  out[0] = 0;
  U8 *cmd = StrPrint(NULL, "shasum -a 256 %s > ./build/slice05-sha.out 2>/dev/null", path);
  system(cmd);
  I64 fsz = 0;
  U8 *txt = FileRead("./build/slice05-sha.out", &fsz);
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

// The EXPECTED binding for a generation.
//
// The binding records the generation's expected STAGE IDENTITY and RUN
// BINDING ID.  A payload that belongs to a DIFFERENT generation cannot
// carry the right binding, so a substituted payload is detected.
//
// The expected bindings are:
//   g0  STAGE0_LEGACY_C
//   g1  STAGE1_POLYC
//   g2  STAGE2_POLYC
//   g3  STAGE3_POLYC
static U8 *ExpectedBinding(I64 idx)
{
  if (idx == 0) return "STAGE0_LEGACY_C";
  if (idx == 1) return "STAGE1_POLYC";
  if (idx == 2) return "STAGE2_POLYC";
  if (idx == 3) return "STAGE3_POLYC";
  return "";
}

// The canonical label for a generation index.
static U8 *ExpectedLabel(I64 idx)
{
  if (idx == 0) return "g0";
  if (idx == 1) return "g1";
  if (idx == 2) return "g2";
  if (idx == 3) return "g3";
  return "";
}

// Load the witness.
//
// The witness is a flat KEY=VALUE file.  A `GENERATION=` line starts a
// new generation block; every other recognised key belongs to the
// CURRENT block.
//
// EVERY field is recorded, including the ones that may be MISSING: a
// missing field is recorded as NULL and reported by the verifier, not
// silently skipped.
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
      G_BINDING[cur] = NULL;
      G_NONCE[cur] = NULL;
      G_PROBE_OUT[cur] = NULL;
      G_CC_PATH[cur] = NULL;
      G_CC_SHA[cur] = NULL;
      G_OBJ_PATH[cur] = NULL;
      G_OBJ_SHA[cur] = NULL;
      G_SRC_PATH[cur] = NULL;
      G_SRC_SHA[cur] = NULL;
      G_RECEIPT_ID[cur] = NULL;
      G_RUN_BINDING[cur] = NULL;
      continue;
    }
    if (cur < 0) continue;
    v = field_value(line, "GENERATION_BINDING=");
    if (v != NULL) { G_BINDING[cur] = v; continue; }
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
    v = field_value(line, "EXECUTION_RECEIPT_ID=");
    if (v != NULL) { G_RECEIPT_ID[cur] = v; continue; }
    v = field_value(line, "RUN_BINDING_ID=");
    if (v != NULL) { G_RUN_BINDING[cur] = v; continue; }
  }
  G_N = n;
  return n;
}

// ---------------------------------------------------------------------------
// The verification.
//
// NO CHECK SHORT-CIRCUITS.  Every check is evaluated for every
// generation, and EVERY diagnostic is reported.  A control that breaks
// several things at once therefore cannot be "satisfied" by the first
// unrelated failure: the intended per-generation reason is always
// among the reported diagnostics.
//
// The generation-scoped reason tokens are:
//   <GEN>_BINDING_MISMATCH
//   <GEN>_EXECUTION_RECEIPT_MISSING
//   <GEN>_EXECUTION_RECEIPT_MISMATCH
//   <GEN>_COMPILER_IDENTITY_MISMATCH
//   <GEN>_OBJECT_IDENTITY_MISMATCH
//   <GEN>_SOURCE_IDENTITY_MISMATCH
//   <GEN>_MISSING_NONCE
//   <GEN>_MISSING_RECEIPT_ID
//   <GEN>_MISSING_RUN_BINDING_ID
//   <GEN>_STAGE_IDENTITY_MISMATCH
// where <GEN> is the UPPERCASE generation label (G0, G1, G2, G3).
// ---------------------------------------------------------------------------

// The UPPERCASE form of a generation label.
static U8 *UpperLabel(U8 *label)
{
  U8 *out = MAlloc(str_len(label) + 1);
  I64 i = 0;
  while (label[i] != 0) {
    U8 c = label[i];
    if (c >= 97 && c <= 122) c = c - 32;
    out[i] = c;
    i = i + 1;
  }
  out[i] = 0;
  return out;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "build/slice05-gen/provenance";
  if (argc > 1) path = argv[1];

  I64 n = LoadWitness(path);
  if (n < 0) {
    "PROVENANCE_VERDICT=REJECTED\n";
    "REJECT_CANNOT_READ_WITNESS\n";
    "WITNESS=%s\n", path;
    return 1;
  }

  I64 fail = 0;

  // ---- 1. the generation set ------------------------------------------
  //
  // The witness MUST carry exactly the four expected generation labels.
  // This is a STRUCTURAL check, reported separately from the
  // per-generation checks so that a structural defect can never be
  // mistaken for a per-generation one.
  I64 label_ok = 0;
  if (n != 4) {
    "REJECT_STAGE_LABELS the witness carries %d generations, expected 4\n", n;
    fail = 1;
  } else {
    for (I64 i = 0; i < 4; i++) {
      if (StrEq(G_NAME[i], ExpectedLabel(i)) == 1) label_ok = label_ok + 1;
    }
    if (label_ok != 4) {
      "REJECT_STAGE_LABELS the witness does not carry the labels g0,g1,g2,g3 in order\n";
      fail = 1;
    }
  }
  "GENERATIONS_PRESENT=%d\n", n;
  "GENERATION_ROWS=%d\n", n;
  "STAGE_LABELS_MATCH=%d\n", label_ok;

  // ---- 2. the per-generation checks ------------------------------------
  //
  // Every check runs for EVERY generation.  Nothing short-circuits.
  I64 receipts_present = 0;
  for (I64 i = 0; i < n; i++) {
    U8 *g = G_NAME[i];
    U8 *up = UpperLabel(g);

    // ---- 2a. the BINDING -----------------------------------------------
    //
    // THIS IS THE FIELD THAT MAKES A SUBSTITUTED PAYLOAD DETECTABLE.
    // A payload that belongs to a different generation carries that
    // generation's binding, not this one's.
    U8 *exp_binding = ExpectedBinding(i);
    if (G_BINDING[i] == NULL || str_len(G_BINDING[i]) == 0) {
      "%s_BINDING_MISSING %s has no GENERATION_BINDING\n", up, g;
      fail = 1;
    } else if (StrEq(G_BINDING[i], exp_binding) == 0) {
      "%s_BINDING_MISMATCH %s recorded binding [%s] but the expected binding is [%s]\n",
             up, g, G_BINDING[i], exp_binding;
      fail = 1;
    }

    // ---- 2b. the nonce --------------------------------------------------
    if (G_NONCE[i] == NULL || str_len(G_NONCE[i]) == 0) {
      "%s_MISSING_NONCE %s has no PROVENANCE_NONCE\n", up, g;
      fail = 1;
    }

    // ---- 2c. the execution receipt -------------------------------------
    //
    // A MISSING receipt is reported with the GENERATION-SCOPED reason
    // "<GEN>_EXECUTION_RECEIPT_MISSING", NOT with a generic reason that
    // names whichever generation happened to fail first.
    if (G_PROBE_OUT[i] == NULL || str_len(G_PROBE_OUT[i]) == 0) {
      "%s_EXECUTION_RECEIPT_MISSING %s has no PROBE_EXECUTION_OUTPUT\n", up, g;
      fail = 1;
    } else {
      receipts_present = receipts_present + 1;
      if (G_NONCE[i] == NULL || str_len(G_NONCE[i]) == 0) {
        // The nonce is already reported as missing; do not also report a
        // mismatch that is only a consequence of it.
      } else if (StrEq(G_PROBE_OUT[i], G_NONCE[i]) == 0) {
        "%s_EXECUTION_RECEIPT_MISMATCH %s recorded probe output [%s] but its nonce is [%s]\n",
               up, g, G_PROBE_OUT[i], G_NONCE[i];
        fail = 1;
      }
    }

    // ---- 2d. the receipt and run-binding identifiers --------------------
    if (G_RECEIPT_ID[i] == NULL || str_len(G_RECEIPT_ID[i]) == 0) {
      "%s_MISSING_RECEIPT_ID %s has no EXECUTION_RECEIPT_ID\n", up, g;
      fail = 1;
    }
    if (G_RUN_BINDING[i] == NULL || str_len(G_RUN_BINDING[i]) == 0) {
      "%s_MISSING_RUN_BINDING_ID %s has no RUN_BINDING_ID\n", up, g;
      fail = 1;
    }

    // ---- 2e. the producing compiler's identity -------------------------
    if (G_CC_PATH[i] == NULL || G_CC_SHA[i] == NULL) {
      "%s_MISSING_COMPILER_IDENTITY %s has no compiler identity\n", up, g;
      fail = 1;
    } else {
      U8 *actual_cc = sha256_of(G_CC_PATH[i]);
      if (str_len(actual_cc) == 0) {
        "%s_COMPILER_IDENTITY_UNREADABLE %s names a compiler that cannot be hashed\n",
               up, g;
        fail = 1;
      } else if (StrEq(actual_cc, G_CC_SHA[i]) == 0) {
        "%s_COMPILER_IDENTITY_MISMATCH %s recorded compiler sha [%s] but the live compiler hashes to [%s]\n",
               up, g, G_CC_SHA[i], actual_cc;
        fail = 1;
      }
    }

    // ---- 2f. the component object ---------------------------------------
    if (G_OBJ_PATH[i] == NULL || G_OBJ_SHA[i] == NULL) {
      "%s_MISSING_OBJECT_IDENTITY %s has no object identity\n", up, g;
      fail = 1;
    } else {
      U8 *actual_obj = sha256_of(G_OBJ_PATH[i]);
      if (str_len(actual_obj) == 0) {
        "%s_OBJECT_IDENTITY_UNREADABLE %s names an object that cannot be hashed\n",
               up, g;
        fail = 1;
      } else if (StrEq(actual_obj, G_OBJ_SHA[i]) == 0) {
        "%s_OBJECT_IDENTITY_MISMATCH %s recorded object sha [%s] but the live object hashes to [%s]\n",
               up, g, G_OBJ_SHA[i], actual_obj;
        fail = 1;
      }
    }

    // ---- 2g. the source -------------------------------------------------
    if (G_SRC_PATH[i] == NULL || G_SRC_SHA[i] == NULL) {
      "%s_MISSING_SOURCE_IDENTITY %s has no source identity\n", up, g;
      fail = 1;
    } else {
      U8 *actual_src = sha256_of(G_SRC_PATH[i]);
      if (str_len(actual_src) == 0) {
        "%s_SOURCE_IDENTITY_UNREADABLE %s names a source that cannot be hashed\n",
               up, g;
        fail = 1;
      } else if (StrEq(actual_src, G_SRC_SHA[i]) == 0) {
        "%s_SOURCE_IDENTITY_MISMATCH %s recorded source sha [%s] but the live source hashes to [%s]\n",
               up, g, G_SRC_SHA[i], actual_src;
        fail = 1;
      }
    }

    // ---- 2h. the stage identity -----------------------------------------
    //
    // The RUN_BINDING_ID must agree with the generation's expected stage
    // identity.  This is what detects a STAGE SWAP (NC-P05): the G1 and
    // G3 stage identities interchanged.
    if (G_RUN_BINDING[i] != NULL && str_len(G_RUN_BINDING[i]) > 0) {
      if (StrEq(G_RUN_BINDING[i], exp_binding) == 0) {
        "%s_STAGE_IDENTITY_MISMATCH %s recorded run binding [%s] but the expected stage identity is [%s]\n",
               up, g, G_RUN_BINDING[i], exp_binding;
        fail = 1;
      }
    }
  }

  "ALL_REQUIRED_RECEIPTS_PRESENT=%d\n", receipts_present;

  // ---- 3. the nonces are DISTINCT --------------------------------------
  //
  // A witness cannot be copied from another generation.
  I64 dup_nonce = 0;
  for (I64 i = 0; i < n; i++) {
    if (G_NONCE[i] == NULL) continue;
    for (I64 j = i + 1; j < n; j++) {
      if (G_NONCE[j] == NULL) continue;
      if (StrEq(G_NONCE[i], G_NONCE[j]) == 1) {
        "REJECT_DUPLICATE_NONCE the witness carries the same nonce for two generations\n";
        dup_nonce = dup_nonce + 1;
        fail = 1;
      }
    }
  }
  "DUPLICATE_NONCE_COUNT=%d\n", dup_nonce;

  "GENERATIONS_VERIFIED=%d\n", n;
  if (fail != 0) {
    "PROVENANCE_VERDICT=REJECTED\n";
    return 1;
  }
  "PROVENANCE_VERDICT=ACCEPTED\n";
  return 0;
}
