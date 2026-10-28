// tools/quality/parser-slice06-provenance-verifier.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C3.
//
// THE GENERATION-SCOPED PROVENANCE WITNESS VERIFIER.
//
// WHY A NEW VERIFIER
// ==================
//
// The SLICE04 and SLICE05 verifiers are closed evidence under F14 and
// MUST NOT be modified.  This verifier adds the SLICE06-specific
// checks:
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
//   build/parser-slice06-provenance-verifier <witness-file>

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
    a++;
    b++;
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

// Does the string start with the given prefix?
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
//
// The value is COPIED into a fresh allocation: the line buffer is
// freed after each record, so a pointer into it would dangle.
static U8 *field_value(U8 *line, U8 *key)
{
  I64 kl = str_len(key);
  if (!starts_with(line, key)) return NULL;
  U8 *v = line + kl;
  I64 vl = str_len(v);
  U8 *out = MAlloc(vl + 1);
  I64 i = 0;
  while (i < vl) { out[i] = v[i]; i = i + 1; }
  out[vl] = 0;
  return out;
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
// This is the INDISPENSABLE EXTERNAL TOOLCHAIN ADAPTER.
static U8 *sha256_of(U8 *path)
{
  U8 *out = MAlloc(128);
  out[0] = 0;
  U8 *cmd = StrPrint(NULL, "shasum -a 256 %s > ./build/slice06-sha.out 2>/dev/null", path);
  system(cmd);
  I64 fsz = 0;
  U8 *txt = FileRead("./build/slice06-sha.out", &fsz);
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

// Does the execution receipt carry exactly this nonce?
//
// The receipt has the form "nonce=<n>,probe_output=<n>".  The nonce is
// the text between "nonce=" and the next comma.
static I64 receipt_nonce_matches(U8 *receipt, U8 *nonce)
{
  if (!starts_with(receipt, "nonce=")) return 0;
  U8 *v = receipt + 6;
  I64 i = 0;
  while (v[i] != 0 && v[i] != 44) i = i + 1;
  I64 j = 0;
  while (j < i && nonce[j] != 0) j = j + 1;
  if (j != i) return 0;
  I64 k = 0;
  while (k < i) {
    if (v[k] != nonce[k]) return 0;
    k = k + 1;
  }
  return 1;
}

// The EXPECTED binding for a generation.
//
// The binding records the generation's expected STAGE IDENTITY.  A
// payload that belongs to a DIFFERENT generation cannot carry the
// right binding, so a substituted payload is detected.
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

  I64 pos = 0;
  I64 rec_start = 0;
  while (pos <= fsz) {
    if (pos == fsz || txt[pos] == 10) {
      I64 len = pos - rec_start;
      if (len > 0 && txt[pos - 1] == 13) len = len - 1;
      if (len > 0) {
        U8 *line = MAlloc(len + 1);
        I64 i = 0;
        while (i < len) { line[i] = txt[rec_start + i]; i = i + 1; }
        line[len] = 0;

        if (starts_with(line, "GENERATION=") == 1 && n < MAX_GENS) {
          G_NAME[n] = field_value(line, "GENERATION=");
          G_BINDING[n] = NULL;
          G_NONCE[n] = NULL;
          G_PROBE_OUT[n] = NULL;
          G_CC_PATH[n] = NULL;
          G_CC_SHA[n] = NULL;
          G_OBJ_PATH[n] = NULL;
          G_OBJ_SHA[n] = NULL;
          G_SRC_PATH[n] = NULL;
          G_SRC_SHA[n] = NULL;
          G_RECEIPT_ID[n] = NULL;
          G_RUN_BINDING[n] = NULL;
          n = n + 1;
        } else if (n > 0) {
          I64 slot = n - 1;
          if (starts_with(line, "GENERATION_BINDING=") == 1) G_BINDING[slot] = field_value(line, "GENERATION_BINDING=");
          else if (starts_with(line, "NONCE=") == 1) G_NONCE[slot] = field_value(line, "NONCE=");
          else if (starts_with(line, "PROBE_OUTPUT=") == 1) G_PROBE_OUT[slot] = field_value(line, "PROBE_OUTPUT=");
          else if (starts_with(line, "COMPILER_PATH=") == 1) G_CC_PATH[slot] = field_value(line, "COMPILER_PATH=");
          else if (starts_with(line, "COMPILER_SHA256=") == 1) G_CC_SHA[slot] = field_value(line, "COMPILER_SHA256=");
          else if (starts_with(line, "OBJECT_PATH=") == 1) G_OBJ_PATH[slot] = field_value(line, "OBJECT_PATH=");
          else if (starts_with(line, "OBJECT_SHA256=") == 1) G_OBJ_SHA[slot] = field_value(line, "OBJECT_SHA256=");
          else if (starts_with(line, "SOURCE_PATH=") == 1) G_SRC_PATH[slot] = field_value(line, "SOURCE_PATH=");
          else if (starts_with(line, "SOURCE_SHA256=") == 1) G_SRC_SHA[slot] = field_value(line, "SOURCE_SHA256=");
          else if (starts_with(line, "RECEIPT_ID=") == 1) G_RECEIPT_ID[slot] = field_value(line, "RECEIPT_ID=");
          else if (starts_with(line, "RUN_BINDING=") == 1) G_RUN_BINDING[slot] = field_value(line, "RUN_BINDING=");
        }
        Free(line);
      }
      rec_start = pos + 1;
    }
    pos = pos + 1;
  }
  Free(txt);
  return n;
}

// ---------------- The main -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "usage: parser-slice06-provenance-verifier <witness-file>\n";
    return 2;
  }
  U8 *path = argv[1];

  I64 n = LoadWitness(path);
  if (n < 0) {
    "SLICE06_PROV_STATUS=FAIL\n";
    "SLICE06_PROV_REASON=CANNOT_READ_WITNESS\n";
    return 1;
  }

  I64 missing_generations = 0;
  I64 binding_mismatches = 0;
  I64 missing_binding = 0;
  I64 missing_receipt = 0;
  I64 receipt_mismatches = 0;
  I64 missing_nonce = 0;
  I64 duplicate_nonces = 0;
  I64 missing_probe_output = 0;
  I64 compiler_identity_mismatches = 0;
  I64 object_identity_mismatches = 0;
  I64 source_identity_mismatches = 0;
  I64 missing_compiler = 0;
  I64 missing_object = 0;
  I64 missing_source = 0;
  I64 run_binding_mismatches = 0;

  // ---- the four generations are present --------------------------------
  for (I64 g = 0; g < 4; g = g + 1) {
    I64 found = 0;
    for (I64 i = 0; i < n; i = i + 1) {
      if (StrEq(G_NAME[i], ExpectedLabel(g)) == 1) found = 1;
    }
    if (found == 0) {
      missing_generations = missing_generations + 1;
      "SLICE06_PROV_MISSING_GENERATION=%s\n", ExpectedLabel(g);
    }
  }

  // ---- per-generation checks --------------------------------------------
  //
  // EVERY check is evaluated for EVERY generation and EVERY diagnostic
  // is reported.  There is NO short-circuit: a control that breaks
  // several things at once cannot be satisfied by the first unrelated
  // failure.
  for (I64 i = 0; i < n; i = i + 1) {
    // The generation's INDEX in the canonical order.
    I64 idx = -1;
    for (I64 g = 0; g < 4; g = g + 1) {
      if (StrEq(G_NAME[i], ExpectedLabel(g)) == 1) idx = g;
    }
    if (idx < 0) continue;

    // 1. The BINDING must match the expected binding for this
    //    generation.  A payload that belongs to a DIFFERENT generation
    //    cannot carry the right binding.
    if (G_BINDING[i] == NULL) {
      missing_binding = missing_binding + 1;
      "SLICE06_PROV_MISSING_BINDING=%s\n", G_NAME[i];
    } else if (StrEq(G_BINDING[i], ExpectedBinding(idx)) == 0) {
      binding_mismatches = binding_mismatches + 1;
      "SLICE06_PROV_BINDING_MISMATCH=%s\n", G_NAME[i];
    }

    // 2. The RUN BINDING must match too: it is the second, independent
    //    binding of the execution receipt to the generation.
    if (G_RUN_BINDING[i] == NULL) {
      missing_binding = missing_binding + 1;
      "SLICE06_PROV_MISSING_RUN_BINDING=%s\n", G_NAME[i];
    } else if (StrEq(G_RUN_BINDING[i], ExpectedBinding(idx)) == 0) {
      run_binding_mismatches = run_binding_mismatches + 1;
      "SLICE06_PROV_RUN_BINDING_MISMATCH=%s\n", G_NAME[i];
    }

    // 3. The EXECUTION RECEIPT must be present and must carry the
    //    generation's NONCE.
    if (G_RECEIPT_ID[i] == NULL) {
      missing_receipt = missing_receipt + 1;
      "SLICE06_PROV_MISSING_RECEIPT=%s\n", G_NAME[i];
    } else {
      if (G_NONCE[i] == NULL) {
        missing_nonce = missing_nonce + 1;
        "SLICE06_PROV_MISSING_NONCE=%s\n", G_NAME[i];
      } else if (starts_with(G_RECEIPT_ID[i], "nonce=") == 0
                 || receipt_nonce_matches(G_RECEIPT_ID[i], G_NONCE[i]) == 0) {
        receipt_mismatches = receipt_mismatches + 1;
        "SLICE06_PROV_RECEIPT_MISMATCH=%s\n", G_NAME[i];
      }
    }

    // 4. The PROBE OUTPUT must be present.
    if (G_PROBE_OUT[i] == NULL) {
      missing_probe_output = missing_probe_output + 1;
      "SLICE06_PROV_MISSING_PROBE_OUTPUT=%s\n", G_NAME[i];
    }

    // 5. The recorded COMPILER identity must equal the LIVE identity of
    //    the named compiler.
    if (G_CC_PATH[i] == NULL || G_CC_SHA[i] == NULL) {
      missing_compiler = missing_compiler + 1;
      "SLICE06_PROV_MISSING_COMPILER=%s\n", G_NAME[i];
    } else {
      U8 *live = sha256_of(G_CC_PATH[i]);
      if (StrEq(live, G_CC_SHA[i]) == 0) {
        compiler_identity_mismatches = compiler_identity_mismatches + 1;
        "SLICE06_PROV_COMPILER_IDENTITY_MISMATCH=%s\n", G_NAME[i];
      }
      Free(live);
    }

    // 6. The recorded OBJECT identity must equal the LIVE identity.
    if (G_OBJ_PATH[i] == NULL || G_OBJ_SHA[i] == NULL) {
      missing_object = missing_object + 1;
      "SLICE06_PROV_MISSING_OBJECT=%s\n", G_NAME[i];
    } else {
      U8 *live = sha256_of(G_OBJ_PATH[i]);
      if (StrEq(live, G_OBJ_SHA[i]) == 0) {
        object_identity_mismatches = object_identity_mismatches + 1;
        "SLICE06_PROV_OBJECT_IDENTITY_MISMATCH=%s\n", G_NAME[i];
      }
      Free(live);
    }

    // 7. The recorded SOURCE identity must equal the LIVE identity.
    if (G_SRC_PATH[i] == NULL || G_SRC_SHA[i] == NULL) {
      missing_source = missing_source + 1;
      "SLICE06_PROV_MISSING_SOURCE=%s\n", G_NAME[i];
    } else {
      U8 *live = sha256_of(G_SRC_PATH[i]);
      if (StrEq(live, G_SRC_SHA[i]) == 0) {
        source_identity_mismatches = source_identity_mismatches + 1;
        "SLICE06_PROV_SOURCE_IDENTITY_MISMATCH=%s\n", G_NAME[i];
      }
      Free(live);
    }
  }

  // ---- the nonces must be DISTINCT --------------------------------------
  //
  // Two generations that share a nonce cannot have been independently
  // executed: a receipt that was copied would carry the same nonce.
  for (I64 i = 0; i < n; i = i + 1) {
    if (G_NONCE[i] == NULL) continue;
    for (I64 j = i + 1; j < n; j = j + 1) {
      if (G_NONCE[j] == NULL) continue;
      if (StrEq(G_NONCE[i], G_NONCE[j]) == 1) {
        duplicate_nonces = duplicate_nonces + 1;
        "SLICE06_PROV_DUPLICATE_NONCE=%s,%s\n", G_NAME[i], G_NAME[j];
      }
    }
  }

  "SLICE06_PROV_GENERATIONS=%d\n", n;
  "SLICE06_PROV_MISSING_GENERATIONS=%d\n", missing_generations;
  "SLICE06_PROV_MISSING_BINDING=%d\n", missing_binding;
  "SLICE06_PROV_BINDING_MISMATCHES=%d\n", binding_mismatches;
  "SLICE06_PROV_RUN_BINDING_MISMATCHES=%d\n", run_binding_mismatches;
  "SLICE06_PROV_MISSING_RECEIPT=%d\n", missing_receipt;
  "SLICE06_PROV_RECEIPT_MISMATCHES=%d\n", receipt_mismatches;
  "SLICE06_PROV_MISSING_NONCE=%d\n", missing_nonce;
  "SLICE06_PROV_DUPLICATE_NONCES=%d\n", duplicate_nonces;
  "SLICE06_PROV_MISSING_PROBE_OUTPUT=%d\n", missing_probe_output;
  "SLICE06_PROV_MISSING_COMPILER=%d\n", missing_compiler;
  "SLICE06_PROV_COMPILER_IDENTITY_MISMATCHES=%d\n", compiler_identity_mismatches;
  "SLICE06_PROV_MISSING_OBJECT=%d\n", missing_object;
  "SLICE06_PROV_OBJECT_IDENTITY_MISMATCHES=%d\n", object_identity_mismatches;
  "SLICE06_PROV_MISSING_SOURCE=%d\n", missing_source;
  "SLICE06_PROV_SOURCE_IDENTITY_MISMATCHES=%d\n", source_identity_mismatches;

  // The acceptance predicate.
  if (n >= 4
      && missing_generations == 0
      && missing_binding == 0
      && binding_mismatches == 0
      && run_binding_mismatches == 0
      && missing_receipt == 0
      && receipt_mismatches == 0
      && missing_nonce == 0
      && duplicate_nonces == 0
      && missing_probe_output == 0
      && missing_compiler == 0
      && compiler_identity_mismatches == 0
      && missing_object == 0
      && object_identity_mismatches == 0
      && missing_source == 0
      && source_identity_mismatches == 0) {
    "SLICE06_PROV_STATUS=PASS\n";
    return 0;
  }
  "SLICE06_PROV_STATUS=FAIL\n";
  return 1;
}
