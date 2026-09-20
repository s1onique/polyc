// tools/quality/lexer09-n02-witness-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL.
//
// N02 production-causal-control witness verifier. Reads the N02
// evidence file (c3-n02-production-causal-control.txt) and validates
// every required token per ACT §24 and §25.
//
// Required tokens (per ACT §24):
//   N02_MUTATION_KIND, PRISTINE_SOURCE_SHA256, MUTATED_SOURCE_SHA256,
//   SOURCE_SHA_DIFFERS, PRISTINE_COMPONENT_SHA256, MUTATED_COMPONENT_SHA256,
//   COMPONENT_SHA_DIFFERS, MUTATED_COMPONENT_BUILD_RC, MUTATED_SEAM_SHA256,
//   MUTATED_SEAM_LINK_RC, MUTATED_SEAM_RUN_RC,
//   MUTATED_PRODUCTION_DIVERGENCE_DETECTED, UNEXPECTED_MUTATION_DIVERGENCE_COUNT,
//   PRISTINE_REVERIFY_RC, N02_OUTCOME
//
// Emits:
//   N02_VERIFIER_RC=0 verdict=PASS
//   N02_VERIFIER_RC=1 verdict=FAIL
//
// Negative selftest (per ACT §25): if argv[2] is provided, treats it as
// a forged witness with the MUTATED_COMPONENT_SHA256 line blanked.
// The verifier must REJECT it.
//   N02_INCOMPLETE_WITNESS_REJECTED=YES|NO
//
// USAGE:
//   build/lexer09-n02-witness-verify <n02_evidence.txt> [optional_forged_evidence]

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

I64 LineLen(U8 *p, I64 sz)
{
  I64 i = 0;
  while (i < sz && p[i] != '\n') i = i + 1;
  return i;
}

I64 MemCmp(U8 *a, U8 *b, I64 n)
{
  for (I64 i = 0; i < n; i = i + 1) {
    if (a[i] != b[i]) {
      if (a[i] < b[i]) return -1;
      return 1;
    }
  }
  return 0;
}

I64 ExtractKv(U8 *buf, I64 sz, U8 *key, U8 *val_out, I64 val_cap)
{
  I64 key_len = 0;
  while (key[key_len]) key_len = key_len + 1;
  I64 i = 0;
  while (i < sz) {
    I64 ll = LineLen(buf + i, sz - i);
    if (ll >= key_len + 1 &&
        MemCmp(buf + i, key, key_len) == 0 &&
        buf[i + key_len] == '=') {
      I64 vstart = i + key_len + 1;
      I64 vlen = ll - (key_len + 1);
      if (vlen >= val_cap) vlen = val_cap - 1;
      for (I64 k = 0; k < vlen; k = k + 1) val_out[k] = buf[vstart + k];
      val_out[vlen] = 0;
      return 0;
    }
    i = i + ll + 1;
  }
  return -1;
}

I64 Streq(U8 *a, U8 *b)
{
  while (*a && *b) {
    if (*a != *b) return 0;
    a = a + 1; b = b + 1;
  }
  return *a == 0 && *b == 0;
}

I64 CountHex(U8 *s)
{
  I64 n = 0;
  while (*s) {
    U8 c = *s;
    Bool is_hex = (c >= '0' && c <= '9') ||
                  (c >= 'a' && c <= 'f') ||
                  (c >= 'A' && c <= 'F');
    if (is_hex) n = n + 1;
    s = s + 1;
  }
  return n;
}



I64 main(I64 argc, U8 **argv)
{
  if (argc < 2) {
    "USAGE: %s <n02_evidence.txt> [forged_evidence]\n", argv[0];
    return 2;
  }
  U8 *path = argv[1];
  I64 sz = 0;
  U8 *raw = FileRead(path, &sz);
  if (!raw || sz == 0) {
    "N02_VERIFIER_RC=2 reason=missing-evidence\n";
    if (raw) Free(raw);
    return 2;
  }

  I64 pass = 1;
  U8 val[512];

  if (ExtractKv(raw, sz, "N02_MUTATION_KIND", val, 512) != 0) {
    pass = 0;
  } else if (!Streq(val, "A") && !Streq(val, "B") && !Streq(val, "C")) {
    pass = 0;
  }

  if (pass && (ExtractKv(raw, sz, "PRISTINE_SOURCE_SHA256", val, 512) != 0 || CountHex(val) != 64)) pass = 0;
  if (pass && (ExtractKv(raw, sz, "MUTATED_SOURCE_SHA256", val, 512) != 0 || CountHex(val) != 64)) pass = 0;
  if (pass && (ExtractKv(raw, sz, "SOURCE_SHA_DIFFERS", val, 512) != 0 || !Streq(val, "YES"))) pass = 0;

  if (pass && (ExtractKv(raw, sz, "PRISTINE_COMPONENT_SHA256", val, 512) != 0 || CountHex(val) != 64)) pass = 0;
  if (pass && (ExtractKv(raw, sz, "MUTATED_COMPONENT_SHA256", val, 512) != 0 || CountHex(val) != 64)) pass = 0;
  if (pass && (ExtractKv(raw, sz, "COMPONENT_SHA_DIFFERS", val, 512) != 0 || !Streq(val, "YES"))) pass = 0;

  if (pass && (ExtractKv(raw, sz, "MUTATED_COMPONENT_BUILD_RC", val, 512) != 0 || !Streq(val, "0"))) pass = 0;
  if (pass && (ExtractKv(raw, sz, "MUTATED_SEAM_LINK_RC", val, 512) != 0 || !Streq(val, "0"))) pass = 0;
  if (pass && (ExtractKv(raw, sz, "MUTATED_SEAM_RUN_RC", val, 512) != 0 || !Streq(val, "0"))) pass = 0;

  if (pass && (ExtractKv(raw, sz, "MUTATED_SEAM_SHA256", val, 512) != 0 || CountHex(val) != 64)) pass = 0;

  if (pass && (ExtractKv(raw, sz, "MUTATED_PRODUCTION_DIVERGENCE_DETECTED", val, 512) != 0 || !Streq(val, "YES"))) pass = 0;
  if (pass && (ExtractKv(raw, sz, "UNEXPECTED_MUTATION_DIVERGENCE_COUNT", val, 512) != 0 || !Streq(val, "0"))) pass = 0;

  if (pass && (ExtractKv(raw, sz, "PRISTINE_REVERIFY_RC", val, 512) != 0 || !Streq(val, "0"))) pass = 0;
  if (pass && (ExtractKv(raw, sz, "N02_OUTCOME", val, 512) != 0 || !Streq(val, "PASS"))) pass = 0;

  Free(raw);

  if (argc >= 3) {
    U8 *forged_path = argv[2];
    I64 fsz = 0;
    U8 *fraw = FileRead(forged_path, &fsz);
    if (!fraw || fsz == 0) {
      "N02_INCOMPLETE_WITNESS_REJECTED=YES\n";
    } else {
      I64 found = 0;
      I64 i = 0;
      while (i < fsz) {
        I64 ll = LineLen(fraw + i, fsz - i);
        if (ll >= 27 &&
            MemCmp(fraw + i, "MUTATED_COMPONENT_SHA256=", 24) == 0) {
          for (I64 k = 0; k < ll; k = k + 1) fraw[i + k] = 'X';
          found = 1;
        }
        i = i + ll + 1;
      }
      if (!found) {
        "N02_INCOMPLETE_WITNESS_REJECTED=YES\n";
      } else {
        I64 selftest_pass = 1;
        if (ExtractKv(fraw, fsz, "MUTATED_COMPONENT_SHA256", val, 512) != 0) selftest_pass = 0;
        else if (CountHex(val) != 64) selftest_pass = 0;
        if (selftest_pass) {
          "N02_INCOMPLETE_WITNESS_REJECTED=NO\n";
        } else {
          "N02_INCOMPLETE_WITNESS_REJECTED=YES\n";
        }
      }
      Free(fraw);
    }
  }

  if (pass) {
    "N02_VERIFIER_RC=0 verdict=PASS\n";
    return 0;
  }
  "N02_VERIFIER_RC=1 verdict=FAIL\n";
  return 1;
}
