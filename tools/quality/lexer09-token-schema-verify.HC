// tools/quality/lexer09-token-schema-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION05 C2 IMPL.
// Token schema verifier per ACT §18-§20.

#define MAX_TOKENS 200
#define MAX_KEY_LEN 80
#define MAX_TYPE_LEN 20
#define MAX_PROD_LEN 60
#define MAX_CONS_LEN 60
#define MAX_LIST 1024

I64 EndsWithTsv(U8 *s)
{
  I64 n = 0;
  while (s[n]) n = n + 1;
  if (n < 4) return 0;
  if (s[n-1] != 'v') return 0;
  if (s[n-2] != 's') return 0;
  if (s[n-3] != 't') return 0;
  if (s[n-4] != '.') return 0;
  return 1;
}

I64 StrLen(U8 *s) { I64 n = 0; while (s[n]) n = n + 1; return n; }

I64 StrEq(U8 *a, U8 *b)
{
  while (*a && *b) {
    if (*a != *b) return 0;
    a = a + 1; b = b + 1;
  }
  return *a == 0 && *b == 0;
}

U0 AppendList(U8 *list, U8 *item)
{
  I64 il = StrLen(item);
  I64 cur = StrLen(list);
  if (cur + il + 2 >= MAX_LIST) return;
  for (I64 k = 0; k < il; k = k + 1) list[cur + k] = item[k];
  list[cur + il] = ' ';
  list[cur + il + 1] = 0;
}

I64 ReadTokens(U8 *path,
               U8 keys[MAX_TOKENS][MAX_KEY_LEN],
               U8 types[MAX_TOKENS][MAX_TYPE_LEN],
               U8 prods[MAX_TOKENS][MAX_PROD_LEN],
               U8 cons[MAX_TOKENS][MAX_CONS_LEN])
{
  I64 sz = 0;
  U8 *raw = FileRead(path, &sz);
  if (!raw || sz == 0) {
    if (raw) Free(raw);
    return -1;
  }
  I64 n = 0;
  I64 i = 0;
  while (i < sz && raw[i] != '\n') i = i + 1;
  if (i < sz) i = i + 1;
  while (i < sz && n < MAX_TOKENS) {
    I64 ll = 0;
    while (i + ll < sz && raw[i + ll] != '\n') ll = ll + 1;
    if (ll == 0) { i = i + 1; continue; }
    U8 *line = MAlloc(ll + 1);
    for (I64 k = 0; k < ll; k = k + 1) line[k] = raw[i + k];
    line[ll] = 0;
    U8 *fields[7];
    I64 flens[7];
    for (I64 q = 0; q < 7; q = q + 1) { fields[q] = NULL; flens[q] = 0; }
    I64 p = 0;
    I64 nf = 0;
    while (p < ll && nf < 7) {
      fields[nf] = line + p;
      I64 q = p;
      while (q < ll && line[q] != '\t') q = q + 1;
      flens[nf] = q - p;
      if (q < ll) line[q] = 0;
      nf = nf + 1;
      p = q + 1;
    }
    if (nf >= 4) {
      I64 kl = flens[0]; if (kl >= MAX_KEY_LEN) kl = MAX_KEY_LEN - 1;
      for (I64 k = 0; k < kl; k = k + 1) keys[n][k] = fields[0][k];
      keys[n][kl] = 0;
      I64 tl = flens[1]; if (tl >= MAX_TYPE_LEN) tl = MAX_TYPE_LEN - 1;
      for (I64 k = 0; k < tl; k = k + 1) types[n][k] = fields[1][k];
      types[n][tl] = 0;
      I64 pl = flens[2]; if (pl >= MAX_PROD_LEN) pl = MAX_PROD_LEN - 1;
      for (I64 k = 0; k < pl; k = k + 1) prods[n][k] = fields[2][k];
      prods[n][pl] = 0;
      I64 cl = flens[3]; if (cl >= MAX_CONS_LEN) cl = MAX_CONS_LEN - 1;
      for (I64 k = 0; k < cl; k = k + 1) cons[n][k] = fields[3][k];
      cons[n][cl] = 0;
      n = n + 1;
    }
    Free(line);
    i = i + ll + 1;
  }
  Free(raw);
  return n;
}

I64 ReadWitnessKeys(U8 *path, U8 keys[MAX_TOKENS][MAX_KEY_LEN])
{
  I64 sz = 0;
  U8 *raw = FileRead(path, &sz);
  if (!raw || sz == 0) {
    if (raw) Free(raw);
    return 0;
  }
  I64 n = 0;
  I64 i = 0;
  while (i < sz && raw[i] != '\n') i = i + 1;
  if (i < sz) i = i + 1;
  while (i < sz && n < MAX_TOKENS) {
    I64 ll = 0;
    while (i + ll < sz && raw[i + ll] != '\n') ll = ll + 1;
    if (ll == 0) { i = i + 1; continue; }
    U8 *line = MAlloc(ll + 1);
    for (I64 k = 0; k < ll; k = k + 1) line[k] = raw[i + k];
    line[ll] = 0;
    U8 *fields[8];
    I64 flens[8];
    for (I64 q = 0; q < 8; q = q + 1) { fields[q] = NULL; flens[q] = 0; }
    I64 p = 0;
    I64 nf = 0;
    while (p < ll && nf < 8) {
      fields[nf] = line + p;
      I64 q = p;
      while (q < ll && line[q] != '\t') q = q + 1;
      flens[nf] = q - p;
      if (q < ll) line[q] = 0;
      nf = nf + 1;
      p = q + 1;
    }
    if (nf >= 5) {
      I64 kl = flens[4]; if (kl >= MAX_KEY_LEN) kl = MAX_KEY_LEN - 1;
      for (I64 k = 0; k < kl; k = k + 1) keys[n][k] = fields[4][k];
      keys[n][kl] = 0;
      n = n + 1;
    }
    Free(line);
    i = i + ll + 1;
  }
  Free(raw);
  return n;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc != 4) {
    "USAGE: lexer09-token-schema-verify <token_schema.tsv> "
      "<witness_contract.tsv> <mandatory_ac.tsv>\n";
    return 2;
  }
  if (!EndsWithTsv(argv[1]) || !EndsWithTsv(argv[2]) ||
      !EndsWithTsv(argv[3])) {
    "TOKEN_SCHEMA_VERIFY_RC=1\n";
    "TOKEN_SCHEMA_VERIFY_REASON=non-tsv-input\n";
    return 1;
  }
  U8 keys[MAX_TOKENS][MAX_KEY_LEN];
  U8 types[MAX_TOKENS][MAX_TYPE_LEN];
  U8 prods[MAX_TOKENS][MAX_PROD_LEN];
  U8 cons[MAX_TOKENS][MAX_CONS_LEN];
  I64 ntok = ReadTokens(argv[1], keys, types, prods, cons);
  if (ntok < 0) {
    "TOKEN_SCHEMA_VERIFY_RC=1\n";
    "TOKEN_SCHEMA_VERIFY_REASON=schema-read-failed\n";
    return 1;
  }
  I64 ndup = 0;
  U8 dup_list[MAX_LIST];
  dup_list[0] = 0;
  for (I64 i = 0; i < ntok; i = i + 1) {
    for (I64 j = i + 1; j < ntok; j = j + 1) {
      if (StrEq(keys[i], keys[j])) {
        ndup = ndup + 1;
        AppendList(dup_list, keys[i]);
      }
    }
  }
  U8 witness_keys[MAX_TOKENS][MAX_KEY_LEN];
  I64 nw = ReadWitnessKeys(argv[2], witness_keys);
  I64 nmiss = 0;
  U8 miss_list[MAX_LIST];
  miss_list[0] = 0;
  for (I64 i = 0; i < nw; i = i + 1) {
    I64 found = 0;
    for (I64 j = 0; j < ntok; j = j + 1) {
      if (StrEq(witness_keys[i], keys[j])) { found = 1; break; }
    }
    if (!found) {
      nmiss = nmiss + 1;
      AppendList(miss_list, witness_keys[i]);
    }
  }
  I64 ndrift = 0;
  U8 drift_list[MAX_LIST];
  drift_list[0] = 0;
  for (I64 i = 0; i < ntok; i = i + 1) {
    for (I64 j = i + 1; j < ntok; j = j + 1) {
      if (StrEq(keys[i], keys[j])) {
        if (!StrEq(prods[i], prods[j]) || !StrEq(cons[i], cons[j])) {
          ndrift = ndrift + 1;
          AppendList(drift_list, keys[i]);
        }
      }
    }
  }
  "TOKEN_SCHEMA_DUPLICATES=%d\n", ndup;
  if (dup_list[0]) "TOKEN_SCHEMA_DUPLICATE_KEYS=%s\n", dup_list;
  "WITNESS_KEYS_WITHOUT_SCHEMA=%d\n", nmiss;
  if (miss_list[0]) "WITNESS_KEYS_WITHOUT_SCHEMA_LIST=%s\n", miss_list;
  "TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT=%d\n", ndrift;
  if (drift_list[0]) "TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT_LIST=%s\n", drift_list;
  "TOKEN_SCHEMA_TOTAL_ENTRIES=%d\n", ntok;
  I64 verify_rc;
  if (ndup == 0 && nmiss == 0 && ndrift == 0) verify_rc = 0;
  else verify_rc = 2;
  "TOKEN_SCHEMA_VERIFY_RC=%d\n", verify_rc;
  if (ndup == 0 && nmiss == 0 && ndrift == 0) return 0;
  return 2;
}
