// tools/quality/lexer09-ac-witness-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL.
//
// Generic predicate-witness verifier. Implements the third binding
// layer per ACT §28 / §30.
//
// Witness contract schema (tab-separated, header + rows):
//   ac_id<TAB>witness_id<TAB>evidence_path<TAB>witness_kind<TAB>
//   key<TAB>operator<TAB>expected_value<TAB>mandatory
//
// Supported witness_kind: KV, FILE_EXISTS, NONEMPTY, INTEGER
// Supported operator:     EQ, NE, MATCH_HEX64
//
// Output (tab-separated, header + rows):
//   ac_id<TAB>witness_id<TAB>observed_value<TAB>operator<TAB>expected_value<TAB>result
//
// Summary tokens emitted on stdout:
//   WITNESS_TOTAL=N
//   WITNESS_PASS=K
//   WITNESS_FAIL=F
//   WITNESS_MISSING=M
//   WITNESS_RC=0 verdict=PASS
//   WITNESS_RC=1 verdict=FAIL
//
// USAGE:
//   build/lexer09-ac-witness-verify <witness_contract.tsv> <out_results.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

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

I64 LineLen(U8 *p, I64 sz)
{
  I64 i = 0;
  while (i < sz && p[i] != '\n') i = i + 1;
  return i;
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

I64 IsHex64(U8 *s)
{
  if (CountHex(s) != 64) return 0;
  return 1;
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

U0 AppendBuf(U8 **buf, I64 *len, I64 *cap, U8 *src, I64 n)
{
  while (*len + n + 1 > *cap) {
    I64 new_cap = *cap * 2;
    if (new_cap < *len + n + 1) new_cap = *len + n + 1;
    U8 *nb = MAlloc(new_cap);
    if (!nb) return;
    for (I64 k = 0; k < *len; k = k + 1) nb[k] = (*buf)[k];
    Free(*buf);
    *buf = nb;
    *cap = new_cap;
  }
  for (I64 k = 0; k < n; k = k + 1) {
    (*buf)[*len + k] = src[k];
  }
  *len = *len + n;
  (*buf)[*len] = 0;
}

U0 AppendStr(U8 **buf, I64 *len, I64 *cap, U8 *s)
{
  I64 n = 0;
  while (s[n]) n = n + 1;
  AppendBuf(buf, len, cap, s, n);
}

U0 AppendCh(U8 **buf, I64 *len, I64 *cap, U8 c)
{
  AppendBuf(buf, len, cap, &c, 1);
}

I64 CountRows(U8 *buf, I64 sz)
{
  I64 n = 0;
  for (I64 i = 0; i < sz; i = i + 1) if (buf[i] == '\n') n = n + 1;
  return n;
}
I64 main(I64 argc, U8 **argv)
{
  if (argc != 3) {
    "USAGE: %s <witness_contract.tsv> <out_results.tsv>\n", argv[0];
    return 2;
  }

  I64 contract_sz = 0;
  U8 *contract_raw = FileRead(argv[1], &contract_sz);
  if (!contract_raw || contract_sz == 0) {
    "WITNESS_RC=2 reason=missing-contract\n";
    if (contract_raw) Free(contract_raw);
    return 2;
  }

  I64 cap = 8192 + CountRows(contract_raw, contract_sz) * 128;
  U8 *out_buf = MAlloc(cap);
  if (!out_buf) {
    "WITNESS_RC=2 reason=oom\n";
    Free(contract_raw);
    return 2;
  }
  I64 out_len = 0;

  // Header
  AppendStr(&out_buf, &out_len, &cap, "ac_id\twitness_id\tobserved_value\toperator\texpected_value\tresult\n");

  I64 witness_total = 0;
  I64 witness_pass = 0;
  I64 witness_fail = 0;
  I64 witness_missing = 0;

  // Skip header line
  I64 i = 0;
  while (i < contract_sz && contract_raw[i] != '\n') i = i + 1;
  if (i < contract_sz) i = i + 1;

  while (i < contract_sz) {
    I64 ll = LineLen(contract_raw + i, contract_sz - i);
    if (ll == 0) { i = i + 1; continue; }

    U8 *fields[8];
    I64 flens[8];
    I64 nf = 0;
    I64 p = 0;
    while (p < ll && nf < 8) {
      fields[nf] = contract_raw + i + p;
      I64 q = p;
      while (q < ll && contract_raw[i + q] != '\t') q = q + 1;
      flens[nf] = q - p;
      if (q < ll) {
        contract_raw[i + q] = 0;
      } else {
        if (i + q < contract_sz) contract_raw[i + q] = 0;
      }
      nf = nf + 1;
      p = q + 1;
    }
    if (nf < 7) { i = i + ll + 1; continue; }

    U8 *ac_id = fields[0];
    U8 *w_id  = fields[1];
    U8 *evp   = fields[2];
    U8 *kind  = fields[3];
    U8 *key   = fields[4];
    U8 *op    = fields[5];
    U8 *exp   = fields[6];

    for (I64 k = 0; k < nf; k = k + 1) {
      I64 L = flens[k];
      while (L > 0 && (fields[k][L-1] == '\r' || fields[k][L-1] == ' ' || fields[k][L-1] == '\t')) {
        fields[k][L-1] = 0;
        L = L - 1;
      }
    }

    U8 observed[1024];
    for (I64 k = 0; k < 1024; k = k + 1) observed[k] = 0;

    I64 is_missing = 0;

    I64 ev_sz = 0;
    U8 *ev_raw = FileRead(evp, &ev_sz);
    if (!ev_raw || ev_sz == 0) {
      is_missing = 1;
    } else {
      if (Streq(kind, "KV") || Streq(kind, "INTEGER")) {
        if (ExtractKv(ev_raw, ev_sz, key, observed, 1024) != 0) {
          is_missing = 1;
        }
      } else if (Streq(kind, "FILE_EXISTS")) {
        observed[0] = 'Y'; observed[1] = 'E'; observed[2] = 'S'; observed[3] = 0;
      } else if (Streq(kind, "NONEMPTY")) {
        observed[0] = 'Y'; observed[1] = 'E'; observed[2] = 'S'; observed[3] = 0;
      } else {
        is_missing = 1;
      }
      Free(ev_raw);
    }

    // Build result column
    U8 result_buf[16];
    I64 pass = 0;
    if (is_missing) {
      result_buf[0] = 'M'; result_buf[1] = 'I'; result_buf[2] = 'S';
      result_buf[3] = 'S'; result_buf[4] = 'I'; result_buf[5] = 'N';
      result_buf[6] = 'G'; result_buf[7] = 0;
    } else {
      if (Streq(op, "EQ")) {
        pass = Streq(observed, exp);
      } else if (Streq(op, "NE")) {
        pass = !Streq(observed, exp);
      } else if (Streq(op, "MATCH_HEX64")) {
        pass = IsHex64(observed);
      } else {
        pass = 0;
      }
      if (pass) {
        result_buf[0] = 'P'; result_buf[1] = 'A'; result_buf[2] = 'S';
        result_buf[3] = 'S'; result_buf[4] = 0;
      } else {
        result_buf[0] = 'F'; result_buf[1] = 'A'; result_buf[2] = 'I';
        result_buf[3] = 'L'; result_buf[4] = 0;
      }
    }

    // Append row: ac_id\tw_id\tobserved\top\texp\tresult\n
    AppendStr(&out_buf, &out_len, &cap, ac_id);
    AppendCh(&out_buf, &out_len, &cap, '\t');
    AppendStr(&out_buf, &out_len, &cap, w_id);
    AppendCh(&out_buf, &out_len, &cap, '\t');
    if (is_missing) {
      AppendStr(&out_buf, &out_len, &cap, "<MISSING>");
    } else {
      AppendStr(&out_buf, &out_len, &cap, observed);
    }
    AppendCh(&out_buf, &out_len, &cap, '\t');
    AppendStr(&out_buf, &out_len, &cap, op);
    AppendCh(&out_buf, &out_len, &cap, '\t');
    AppendStr(&out_buf, &out_len, &cap, exp);
    AppendCh(&out_buf, &out_len, &cap, '\t');
    AppendStr(&out_buf, &out_len, &cap, result_buf);
    AppendCh(&out_buf, &out_len, &cap, '\n');

    witness_total = witness_total + 1;
    if (is_missing) {
      witness_missing = witness_missing + 1;
    } else if (pass) {
      witness_pass = witness_pass + 1;
    } else {
      witness_fail = witness_fail + 1;
    }

    i = i + ll + 1;
  }

  if (!FileWrite(argv[2], out_buf, out_len, O_CREAT | O_RDWR | O_TRUNC)) {
    "WITNESS_RC=2 reason=cannot-write-output\n";
    Free(out_buf);
    Free(contract_raw);
    return 2;
  }
  Free(out_buf);
  Free(contract_raw);

  "WITNESS_TOTAL=%d\n", witness_total;
  "WITNESS_PASS=%d\n", witness_pass;
  "WITNESS_FAIL=%d\n", witness_fail;
  "WITNESS_MISSING=%d\n", witness_missing;

  if (witness_fail == 0 && witness_missing == 0) {
    "WITNESS_RC=0 verdict=PASS\n";
    return 0;
  }
  "WITNESS_RC=1 verdict=FAIL\n";
  return 1;
}
