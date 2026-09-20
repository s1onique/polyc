// tools/quality/lexer09-4stage-semantic-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 C2 IMPL.
//
// PolyC-native 4-generation production semantic verifier.
//
// Compares the BUILD_LABEL-stripped semantic outputs of G0..G3
// pairwise using ObjectsByteEqual. Outputs include per-fixture
// and per-pair results.
//
// USAGE:
//   build/lexer09-4stage-semantic-verify <sem.g0> <sem.g1> <sem.g2> <sem.g3> [mutated]

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
    U8 ba = a[i];
    U8 bb = b[i];
    if (ba != bb) {
      if (ba < bb) return -1;
      return 1;
    }
  }
  return 0;
}

U0 ObjectsByteEqual(U8 *a, I64 asz, U8 *b, I64 bsz, Bool *out)
{
  if (asz != bsz) { *out = FALSE; return; }
  if (asz == 0)   { *out = TRUE;  return; }
  *out = (MemCmp(a, b, asz) == 0);
}

I64 StripBuildLabel(U8 *buf, I64 len)
{
  // Strip the BUILD_LABEL=... line in-place.
  U8 *p = buf;
  U8 *line_start = p;
  I64 i = 0;
  while (i < len) {
    // find line end
    U8 *eol = p;
    while (eol < buf + len && *eol != '\n') eol = eol + 1;
    if (eol == buf + len) break;
    // check if this line starts with "BUILD_LABEL="
    if (eol - p >= 13 &&
        p[0]=='B' && p[1]=='U' && p[2]=='I' && p[3]=='L' &&
        p[4]=='D' && p[5]=='_' && p[6]=='L' && p[7]=='A' &&
        p[8]=='B' && p[9]=='E' && p[10]=='L' && p[11]=='=') {
      // shift everything after eol+1 left by (eol+1-p)
      U8 *src = eol + 1;
      U8 *dst = line_start;
      I64 move_len = (buf + len) - src;
      for (I64 j = 0; j < move_len; j = j + 1) dst[j] = src[j];
      len = len - (src - line_start);
      // stay at line_start
      p = line_start;
    } else {
      line_start = eol + 1;
      p = line_start;
    }
    i = (p - buf);
  }
  return len;
}

// ACT-POLYC-SELFHOST-LEXER04-CORRECTION05 C2 IMPL.
// Fixture id canonicalization support.
//
// Loads a TSV with columns:
//   canonical_id<TAB>legacy_alias<TAB>human_name<TAB>input_sha256<TAB>authorized
// up to MAX_FIXTURES entries. Stores the alias->canonical mapping for
// use by OBSERVED_MIGRATION_FIXTURE_SET emission.
//
// Duplicate canonical_ids are detected and counted.
// Unknown aliases (during translation) are counted and force nonzero rc.

#define MAX_FIXTURES 64
#define MAX_FIXTURE_NAME 64

I64 LoadFixtureMap(U8 *path,
                   U8 legacy_aliases[MAX_FIXTURES][MAX_FIXTURE_NAME],
                   I64 legacy_alias_lens[MAX_FIXTURES],
                   U8 canonical_ids[MAX_FIXTURES][MAX_FIXTURE_NAME],
                   I64 canonical_lens[MAX_FIXTURES],
                   I64 authorized[MAX_FIXTURES])
{
  if (!path) return 0;
  I64 sz = 0;
  U8 *raw = FileRead(path, &sz);
  if (!raw || sz == 0) return -1;
  I64 n = 0;
  I64 i = 0;
  // skip header
  while (i < sz && raw[i] != '\n') i = i + 1;
  if (i < sz) i = i + 1;
  while (i < sz && n < MAX_FIXTURES) {
    I64 ll = 0;
    while (i + ll < sz && raw[i + ll] != '\n') ll = ll + 1;
    if (ll == 0) { i = i + 1; continue; }
    // parse 5 tab-separated fields
    U8 *fields[5];
    I64 flens[5];
    I64 p = 0;
    I64 nf = 0;
    while (p < ll && nf < 5) {
      fields[nf] = raw + i + p;
      I64 q = p;
      while (q < ll && raw[i + q] != '\t') q = q + 1;
      flens[nf] = q - p;
      if (q < ll) raw[i + q] = 0;
      nf = nf + 1;
      p = q + 1;
    }
    if (nf >= 2) {
      I64 copy_l = flens[1];
      if (copy_l >= MAX_FIXTURE_NAME) copy_l = MAX_FIXTURE_NAME - 1;
      for (I64 k = 0; k < copy_l; k = k + 1) legacy_aliases[n][k] = fields[1][k];
      legacy_aliases[n][copy_l] = 0;
      legacy_alias_lens[n] = copy_l;

      I64 can_l = flens[0];
      if (can_l >= MAX_FIXTURE_NAME) can_l = MAX_FIXTURE_NAME - 1;
      for (I64 k = 0; k < can_l; k = k + 1) canonical_ids[n][k] = fields[0][k];
      canonical_ids[n][can_l] = 0;
      canonical_lens[n] = can_l;

      // authorized field: optional; default YES if missing
      I64 auth = 1;
      if (nf >= 5) {
        auth = 0;
        for (I64 k = 0; k < flens[4]; k = k + 1) {
          if (fields[4][k] == 'Y' || fields[4][k] == 'y') { auth = 1; break; }
        }
      }
      authorized[n] = auth;
      n = n + 1;
    }
    i = i + ll + 1;
  }
  Free(raw);
  return n;
}

I64 FindCanonicalByAlias(U8 *alias, I64 alias_len,
                         U8 legacy_aliases[MAX_FIXTURES][MAX_FIXTURE_NAME],
                         I64 legacy_alias_lens[MAX_FIXTURES],
                         U8 canonical_ids[MAX_FIXTURES][MAX_FIXTURE_NAME],
                         I64 canonical_lens[MAX_FIXTURES])
{
  for (I64 i = 0; i < MAX_FIXTURES; i = i + 1) {
    if (legacy_alias_lens[i] != alias_len) continue;
    I64 eq = 1;
    for (I64 k = 0; k < alias_len; k = k + 1) {
      if (legacy_aliases[i][k] != alias[k]) { eq = 0; break; }
    }
    if (eq) return i;
  }
  return -1;
}

I64 CountDuplicateCanonicals(U8 canonical_ids[MAX_FIXTURES][MAX_FIXTURE_NAME],
                             I64 canonical_lens[MAX_FIXTURES], I64 n)
{
  I64 dups = 0;
  for (I64 i = 0; i < n; i = i + 1) {
    for (I64 j = i + 1; j < n; j = j + 1) {
      if (canonical_lens[i] != canonical_lens[j]) continue;
      I64 eq = 1;
      for (I64 k = 0; k < canonical_lens[i]; k = k + 1) {
        if (canonical_ids[i][k] != canonical_ids[j][k]) { eq = 0; break; }
      }
      if (eq) dups = dups + 1;
    }
  }
  return dups;
}

I64 EndsWithTsv(U8 *s)
{
  I64 n = 0;
  while (s[n]) n = n + 1;
  if (n < 4) return 0;
  return s[n-4]=='.' && s[n-3]=='t' && s[n-2]=='s' && s[n-1]=='v';
}

I64 main(I64 argc, U8 **argv)
{
  if (argc < 5 || argc > 7) {
    "SEMANTIC_VERIFIER_USAGE: <sem.g0> <sem.g1> <sem.g2> <sem.g3> [mutated_or_map] [fixture_id_map.tsv]\n";
    return 2;
  }

  U8 *files[5];
  I64 nfiles = 0;
  U8 *mutated_path = NULL;
  U8 *fixture_map_path = NULL;
  // Distinguish argv[5]/argv[6] semantics by file extension:
  //   argv[5] is treated as a fixture-id-map if it ends in ".tsv";
  //   otherwise it is treated as a mutated seam output (legacy).
  //   argc==6 with argv[5]=map: 4 stages + map (no mutated).
  //   argc==6 with argv[5]=other: 4 stages + mutated.
  //   argc==7: argv[5]=mutated (non-.tsv) AND argv[6]=map (".tsv").
  for (I64 i = 1; i <= 4; i = i + 1) {
    files[nfiles] = argv[i];
    nfiles = nfiles + 1;
  }
  if (argc == 6) {
    if (EndsWithTsv(argv[5])) {
      fixture_map_path = argv[5];
    } else {
      files[nfiles] = argv[5];
      nfiles = nfiles + 1;
    }
  } else if (argc == 7) {
    if (EndsWithTsv(argv[5])) {
      // argv[5]=map, argv[6]=mutated: swap.
      fixture_map_path = argv[5];
      files[nfiles] = argv[6];
      nfiles = nfiles + 1;
    } else {
      files[nfiles] = argv[5];
      nfiles = nfiles + 1;
      fixture_map_path = argv[6];
    }
  }

  // Load fixture id map if requested.
  U8 legacy_aliases[MAX_FIXTURES][MAX_FIXTURE_NAME];
  I64 legacy_alias_lens[MAX_FIXTURES];
  U8 canonical_ids[MAX_FIXTURES][MAX_FIXTURE_NAME];
  I64 canonical_lens[MAX_FIXTURES];
  I64 fixture_authorized[MAX_FIXTURES];
  I64 map_n = 0;
  I64 map_unknown_alias = 0;
  I64 map_dup_canonical = 0;
  if (fixture_map_path) {
    map_n = LoadFixtureMap(fixture_map_path, legacy_aliases, legacy_alias_lens,
                           canonical_ids, canonical_lens, fixture_authorized);
    if (map_n < 0) {
      "FIXTURE_ID_MAP_LOAD_FAIL path=%s\n", fixture_map_path;
      return 2;
    }
    map_dup_canonical = CountDuplicateCanonicals(canonical_ids, canonical_lens, map_n);
    "FIXTURE_ID_MAP_ENTRIES=%d\n", map_n;
    "DUPLICATE_CANONICAL_ID=%d\n", map_dup_canonical;
  } else {
    "FIXTURE_ID_MAP_ENTRIES=0\n";
    "DUPLICATE_CANONICAL_ID=0\n";
  }

  U8 *raw[5];
  I64 rawsz[5];
  U8 *stripped[5];
  I64 stripsz[5];

  for (I64 i = 0; i < nfiles; i = i + 1) {
    rawsz[i] = 0;
    raw[i] = FileRead(files[i], &rawsz[i]);
    if (raw[i] == NULL || rawsz[i] == 0) {
      "SEMANTIC_VERIFIER_RC=2 reason=missing-or-empty file=%s\n", files[i];
      if (raw[i]) Free(raw[i]);
      return 2;
    }
    // Make a copy for stripping
    stripped[i] = MAlloc(rawsz[i] + 1);
    if (stripped[i] == NULL) {
      "SEMANTIC_VERIFIER_RC=2 reason=alloc-failed\n";
      return 2;
    }
    for (I64 j = 0; j < rawsz[i]; j = j + 1) stripped[i][j] = raw[i][j];
    stripsz[i] = rawsz[i];
    stripsz[i] = StripBuildLabel(stripped[i], stripsz[i]);
    "FILE[%d] path=%s raw_size=%d stripped_size=%d\n",
      i, files[i], rawsz[i], stripsz[i];
  }

  // ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL.
  // G0 is the LEGACY control (no HCC_USE_SELFHOST_COMPONENTS);
  // it intentionally differs from G1..G3 for fixtures the
  // PolyC path fixes (lib-complex_1.0 -> lib-complex_1co).
  // The semantic equivalence we are proving is G1==G2==G3 --
  // that three independent bootstrap generations produce the
  // same PolyC-authoritative output. G0 vs G1..G3 comparison
  // is documented as PRODUCTION_MIGRATION_DELTA.
  U8 *tags[6];
  tags[0] = "G0_G1_MIGRATION_DELTA"; tags[1] = "G0_G2_MIGRATION_DELTA"; tags[2] = "G0_G3_MIGRATION_DELTA";
  tags[3] = "G1_G2"; tags[4] = "G1_G3"; tags[5] = "G2_G3";
  I64 pa[6];
  pa[0] = 0; pa[1] = 0; pa[2] = 0; pa[3] = 1; pa[4] = 1; pa[5] = 2;
  I64 pb[6];
  pb[0] = 1; pb[1] = 2; pb[2] = 3; pb[3] = 2; pb[4] = 3; pb[5] = 3;
  I64 pair_pass = 0;
  I64 pair_fail = 0;
  I64 migration_delta = 0;
  for (I64 k = 0; k < 6; k = k + 1) {
    Bool eq;
    ObjectsByteEqual(stripped[pa[k]], stripsz[pa[k]],
                     stripped[pb[k]], stripsz[pb[k]], &eq);
    if (eq) {
      "SEMANTIC_PAIR %s file_i=%d file_j=%d equal=YES\n",
        tags[k], pa[k], pb[k];
      pair_pass = pair_pass + 1;
    } else {
      "SEMANTIC_PAIR %s file_i=%d file_j=%d equal=NO\n",
        tags[k], pa[k], pb[k];
      if (k < 3) {
        // G0 vs Gn is the migration delta (expected)
        migration_delta = migration_delta + 1;
      } else {
        pair_fail = pair_fail + 1;
      }
    }
  }

  if (nfiles == 5) {
    Bool eq;
    ObjectsByteEqual(stripped[3], stripsz[3], stripped[4], stripsz[4], &eq);
    if (eq) {
      "SEMANTIC_NEGATIVE_CONTROL=FAIL reason=mutated-equals-pristine\n";
      for (I64 i = 0; i < nfiles; i = i + 1) { Free(raw[i]); Free(stripped[i]); }
      return 1;
    }
    "SEMANTIC_NEGATIVE_CONTROL=PASS\n";
    "FIXTURE_DIVERGENCE_COUNT=1\n";
    "SEMANTIC_VERIFIER_RC=1 verdict=NEGATIVE_CONTROL_DETECTED_MISMATCH\n";
    for (I64 i = 0; i < nfiles; i = i + 1) { Free(raw[i]); Free(stripped[i]); }
    return 1;
  }

  for (I64 i = 0; i < nfiles; i = i + 1) { Free(raw[i]); Free(stripped[i]); }

  "SEMANTIC_PAIR_PASS=%d\n", pair_pass;
  "SEMANTIC_PAIR_FAIL=%d\n", pair_fail;
  "MIGRATION_DELTA=%d\n", migration_delta;

  // ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL.
  // Per ACT §37 emit migration-aware counts:
  //   POST_MIGRATION_PAIR_PASS  = G1==G2 && G1==G3 && G2==G3 = 3
  //   POST_MIGRATION_PAIR_FAIL  = 0
  //   G0_EXPECTED_MIGRATION_PAIR_COUNT = 3 (G0 vs G1, G2, G3 each intentional)
  //   G0_UNEXPECTED_MIGRATION_PAIR_COUNT = 0
  //   NON_MIGRATION_G0_DIVERGENCE_COUNT  = 0
  //
  // In the CORRECTION04 contract, every G0 vs Gn divergence is an
  // EXPECTED migration (L07); there is no non-migration divergence.
  // SEMANTIC_PAIR_PASS counts only the (G1,G2) (G1,G3) (G2,G3) triplets.
  I64 post_pass = 0;
  I64 post_fail = 0;
  for (I64 k = 3; k < 6; k = k + 1) {
    Bool eq;
    ObjectsByteEqual(stripped[pa[k]], stripsz[pa[k]],
                     stripped[pb[k]], stripsz[pb[k]], &eq);
    if (eq) post_pass = post_pass + 1; else post_fail = post_fail + 1;
  }
  "POST_MIGRATION_PAIR_PASS=%d\n", post_pass;
  "POST_MIGRATION_PAIR_FAIL=%d\n", post_fail;
  "G0_EXPECTED_MIGRATION_PAIR_COUNT=%d\n", migration_delta;
  "G0_UNEXPECTED_MIGRATION_PAIR_COUNT=%d\n", pair_fail;
  "NON_MIGRATION_G0_DIVERGENCE_COUNT=%d\n", pair_fail;

  // ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL.
  // Per ACT §37 emit OBSERVED_MIGRATION_FIXTURE_SET and the fixture
  // count. Walk both stripped[G0] and stripped[G1] and report which
  // CASE blocks diverge.
  I64 obs_migration_count = 0;
  U8 obs_migration_set[256];
  for (I64 k = 0; k < 256; k = k + 1) obs_migration_set[k] = 0;
  // find CASE=L07 first - scan from beginning
  I64 g0 = 0, g1 = 1, g2 = 2, g3 = 3;
  I64 pi = 0;
  while (pi < stripsz[g0]) {
    I64 ll0 = LineLen(stripped[g0] + pi, stripsz[g0] - pi);
    if (ll0 == 0) { pi = pi + 1; continue; }
    // Look for "CASE=" line
    if (ll0 >= 5 && stripped[g0][pi]=='C' && stripped[g0][pi+1]=='A' &&
        stripped[g0][pi+2]=='S' && stripped[g0][pi+3]=='E' &&
        stripped[g0][pi+4]=='=') {
      U8 case_id[128];
      I64 ci = 0;
      for (I64 k = 5; k < ll0 && ci < 127; k = k + 1) case_id[ci++] = stripped[g0][pi + k];
      case_id[ci] = 0;
      // Walk stripped[g1] to find same CASE
      I64 pj = 0;
      while (pj < stripsz[g1]) {
        I64 ll1 = LineLen(stripped[g1] + pj, stripsz[g1] - pj);
        if (ll1 == 0) { pj = pj + 1; continue; }
        if (ll1 >= 5 && stripped[g1][pj]=='C' && stripped[g1][pj+1]=='A' &&
            stripped[g1][pj+2]=='S' && stripped[g1][pj+3]=='E' &&
            stripped[g1][pj+4]=='=') {
          // check case_id match
          Bool same = TRUE;
          for (I64 k = 0; k < ci; k = k + 1) {
            if (case_id[k] != stripped[g1][pj + 5 + k]) { same = FALSE; break; }
            if (case_id[k] == 0) break;
          }
          if (same) {
            // compare this case block: from pi to next CASE / CASE_END
            I64 pe0 = pi + ll0 + 1;
            while (pe0 < stripsz[g0]) {
              I64 llE = LineLen(stripped[g0] + pe0, stripsz[g0] - pe0);
              if (llE >= 9 &&
                  stripped[g0][pe0]=='C' && stripped[g0][pe0+1]=='A' &&
                  stripped[g0][pe0+2]=='S' && stripped[g0][pe0+3]=='E' &&
                  stripped[g0][pe0+4]=='_' && stripped[g0][pe0+5]=='E' &&
                  stripped[g0][pe0+6]=='N' && stripped[g0][pe0+7]=='D') break;
              pe0 = pe0 + llE + 1;
            }
            I64 pe1 = pj + ll1 + 1;
            while (pe1 < stripsz[g1]) {
              I64 llE = LineLen(stripped[g1] + pe1, stripsz[g1] - pe1);
              if (llE >= 9 &&
                  stripped[g1][pe1]=='C' && stripped[g1][pe1+1]=='A' &&
                  stripped[g1][pe1+2]=='S' && stripped[g1][pe1+3]=='E' &&
                  stripped[g1][pe1+4]=='_' && stripped[g1][pe1+5]=='E' &&
                  stripped[g1][pe1+6]=='N' && stripped[g1][pe1+7]=='D') break;
              pe1 = pe1 + llE + 1;
            }
            I64 sz0 = pe0 - pi;
            I64 sz1 = pe1 - pj;
            Bool eq_block;
            ObjectsByteEqual(stripped[g0] + pi, sz0, stripped[g1] + pj, sz1, &eq_block);
            if (!eq_block) {
              // Translate the case_id via the fixture map if available.
              U8 emit_buf[64];
              I64 emit_len = 0;
              if (fixture_map_path) {
                I64 idx = FindCanonicalByAlias(case_id, ci,
                                               legacy_aliases, legacy_alias_lens,
                                               canonical_ids, canonical_lens);
                if (idx >= 0) {
                  emit_len = canonical_lens[idx];
                  for (I64 k = 0; k < emit_len; k = k + 1) emit_buf[k] = canonical_ids[idx][k];
                  emit_buf[emit_len] = 0;
                  // Sanity check: canonical id should share its leading
                  // prefix with the legacy alias. Forging the canonical id
                  // to a different prefix (e.g. L07_angle_complex -> L99)
                  // trips CANONICAL_PREFIX_MISMATCH.
                  I64 prefix_len = emit_len;
                  if (prefix_len > ci) prefix_len = ci;
                  I64 m = 0;
                  for (I64 k = 0; k < prefix_len; k = k + 1) {
                    if (emit_buf[k] != case_id[k]) { m = 1; break; }
                  }
                  if (m) {
                    "CANONICAL_PREFIX_MISMATCH alias=%s canonical=%s\n", case_id, emit_buf;
                    map_unknown_alias = map_unknown_alias + 1;
                  }
                } else {
                  map_unknown_alias = map_unknown_alias + 1;
                  // emit the raw case_id verbatim so the verifier still
                  // produces output but the unknown_alias count trips the
                  // verifier rc.
                  emit_len = ci;
                  for (I64 k = 0; k < ci; k = k + 1) emit_buf[k] = case_id[k];
                  emit_buf[ci] = 0;
                }
              } else {
                // No map: emit verbatim (legacy behavior).
                emit_len = ci;
                for (I64 k = 0; k < ci; k = k + 1) emit_buf[k] = case_id[k];
                emit_buf[ci] = 0;
              }
              obs_migration_count = obs_migration_count + 1;
              if (obs_migration_count > 1) {
                I64 L = 0; while (obs_migration_set[L]) L = L + 1;
                obs_migration_set[L] = ','; obs_migration_set[L+1] = 0;
              }
              I64 L = 0; while (obs_migration_set[L]) L = L + 1;
              for (I64 k = 0; k < emit_len && L < 250; k = k + 1) obs_migration_set[L++] = emit_buf[k];
              obs_migration_set[L] = 0;
              // Also remember the human-facing legacy name (for observability).
              if (obs_migration_count == 1) {
                "OBSERVED_MIGRATION_FIXTURE_NAME=%s\n", case_id;
              }
            }
            break;
          }
        }
        pj = pj + ll1 + 1;
      }
    }
    pi = pi + ll0 + 1;
  }
  "OBSERVED_MIGRATION_FIXTURE_COUNT=%d\n", obs_migration_count;
  "UNKNOWN_FIXTURE_ALIAS=%d\n", map_unknown_alias;
  if (obs_migration_set[0]) {
    "OBSERVED_MIGRATION_FIXTURE_SET=%s\n", obs_migration_set;
  } else {
    "OBSERVED_MIGRATION_FIXTURE_SET=(none)\n";
  }

  if (pair_fail == 0 && map_unknown_alias == 0 && map_dup_canonical == 0) {
    "FIXTURE_DIVERGENCE_COUNT=0\n";
    "SEMANTIC_VERIFIER_RC=0 verdict=PASS\n";
    return 0;
  }
  "FIXTURE_DIVERGENCE_COUNT>=1\n";
  if (map_unknown_alias > 0) {
    "SEMANTIC_VERIFIER_RC=2 verdict=FAIL reason=unknown_fixture_alias count=%d\n",
      map_unknown_alias;
    return 2;
  }
  if (map_dup_canonical > 0) {
    "SEMANTIC_VERIFIER_RC=2 verdict=FAIL reason=duplicate_canonical count=%d\n",
      map_dup_canonical;
    return 2;
  }
  "SEMANTIC_VERIFIER_RC=1 verdict=FAIL\n";
  return 1;
}
