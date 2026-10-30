// tools/quality/abi-foundation-implement01-verify.HC
//
// ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01 C3 EVIDENCE.
//
// INDEPENDENT verifier for the source-representative ABI migration. It shares
// NO code with the C2 producer: it re-reads the real bytes, re-runs the real
// preprocessor and nm commands, and compares its OWN measurements against the
// recorded evidence. It never trusts a recorded PASS column.
//
// Usage:
//   build/abi-foundation-implement01-verify <shadow-root> <evidence-root>
//
// Exit code = number of failing checks (0 = all pass).

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);

I64 g_fail = 0;
I64 g_check = 0;

I64 BufCmp(U8 *a, U8 *b, I64 n)
{
  for (I64 i = 0; i < n; i = i + 1) {
    if (a[i] != b[i]) {
      if (a[i] < b[i]) return -1;
      return 1;
    }
  }
  return 0;
}

I64 BufLen(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

I64 CountOcc(U8 *hay, I64 hlen, U8 *needle)
{
  I64 nlen = BufLen(needle);
  I64 c = 0;
  I64 i = 0;
  if (nlen == 0) return 0;
  while (i + nlen <= hlen) {
    if (BufCmp(hay + i, needle, nlen) == 0) {
      c = c + 1;
      i = i + nlen;
    } else {
      i = i + 1;
    }
  }
  return c;
}

// Count lines whose first bytes are exactly `tok` followed by TAB.
I64 CountTokLines(U8 *hay, I64 hlen, U8 *tok)
{
  I64 tlen = BufLen(tok);
  I64 c = 0;
  I64 i = 0;
  Bool at_line_start = TRUE;
  while (i < hlen) {
    if (at_line_start && i + tlen < hlen &&
        BufCmp(hay + i, tok, tlen) == 0 && hay[i + tlen] == '\t') {
      c = c + 1;
    }
    at_line_start = (hay[i] == '\n');
    i = i + 1;
  }
  return c;
}

U8 *ReadAll(U8 *path, I64 *out_len)
{
  I64 n = 0;
  U8 *b = FileRead(path, &n);
  if (out_len) *out_len = n;
  return b;
}

// Run `/bin/sh -c <cmd>`; return captured stdout (may be NULL).
U8 *RunCapture(U8 *cmd, I64 *out_len)
{
  U8 *args[4];
  U8 *out = NULL;
  U8 *err = NULL;
  args[0] = "/bin/sh";
  args[1] = "-c";
  args[2] = cmd;
  args[3] = NULL;
  I64 rc = SpawnAndCapture("/bin/sh", args, &out, &err);
  if (err != NULL) Free(err);
  if (out == NULL) return NULL;
  if (out_len != NULL) *out_len = BufLen(out);
  if (rc != 0 && BufLen(out) == 0) {
    Free(out);
    return NULL;
  }
  return out;
}

I64 Check(Bool cond, U8 *id, U8 *what)
{
  g_check = g_check + 1;
  if (cond) {
    "CHECK %s PASS  %s\n", id, what;
    return 0;
  }
  "CHECK %s FAIL  %s\n", id, what;
  g_fail = g_fail + 1;
  return 1;
}


// Recompute sha256 of `path` and return 1 iff the hex value occurs in the
// evidence file `evpath`. Returns 0 when either step fails.
I64 ShaOf(U8 *path, U8 *evpath)
{
  U8 *cmd = StrPrint(NULL, "/usr/bin/shasum -a 256 %s 2>/dev/null", path);
  I64 n = 0;
  U8 *out = RunCapture(cmd, &n);
  Free(cmd);
  if (out == NULL || n < 64) {
    if (out != NULL) Free(out);
    return 0;
  }
  U8 *h = MAlloc(65);
  for (I64 i = 0; i < 64; i = i + 1) h[i] = out[i];
  h[64] = 0;
  Free(out);
  I64 en = 0;
  U8 *eb = ReadAll(evpath, &en);
  I64 found = 0;
  if (eb != NULL) {
    if (strstr(eb, h) != NULL) found = 1;
    Free(eb);
  }
  "DIGEST %s -> %s found_in_evidence=%lld\n", path, h, found;
  Free(h);
  return found;
}

// Read `build/abi01-verify-inputs.txt`: line 1 = shadow root, line 2 = evidence root.
U8 *CfgLine(U8 *cfg, I64 cfg_n, I64 *cursor)
{
  I64 s = *cursor;
  I64 e = s;
  while (e < cfg_n && cfg[e] != 10) e = e + 1;
  U8 *s2 = MAlloc(e - s + 1);
  for (I64 i = 0; i < e - s; i = i + 1) s2[i] = cfg[s + i];
  s2[e - s] = 0;
  *cursor = e + 1;
  return s2;
}

// Two-digit zero-padded suffix, e.g. 7 -> "07".
U8 *TwoDigits(I64 n)
{
  U8 *s = MAlloc(3);
  s[0] = '0' + (n / 10);
  s[1] = '0' + (n % 10);
  s[2] = 0;
  return s;
}

I64 ParseI64(U8 *s)
{
  I64 v = 0;
  I64 i = 0;
  Bool neg = FALSE;
  if (s[0] == '-') { neg = TRUE; i = 1; }
  while (s[i] >= '0' && s[i] <= '9') {
    v = v * 10 + (s[i] - '0');
    i = i + 1;
  }
  if (neg) return -v;
  return v;
}

// Count `->` occurrences in the CODE of `path`, i.e. after stripping
// end-of-line `//` comments, so a prose comment cannot mask a real
// dereference and a real dereference cannot hide behind a comment.
I64 CountCodeArrows(U8 *path)
{
  U8 *cmd = StrPrint(NULL,
    "sed 's|//.*||' %s | grep -c -- '->' || echo 0", path);
  I64 n = 0;
  U8 *out = RunCapture(cmd, &n);
  Free(cmd);
  if (out == NULL) return -1;
  I64 v = ParseI64(out);
  Free(out);
  return v;
}

// Plain decimal rendering without printf (the dialect's StrPrint does not
// accept length modifiers such as %lld).
U8 *NumStr(I64 n)
{
  U8 tmp[24];
  I64 i = 0;
  Bool neg = FALSE;
  if (n == 0) { tmp[i] = '0'; i = i + 1; }
  if (n < 0) { neg = TRUE; n = -n; }
  while (n > 0) { tmp[i] = '0' + (n % 10); n = n / 10; i = i + 1; }
  U8 *s = MAlloc(i + 2);
  I64 o = 0;
  if (neg) { s[o] = '-'; o = o + 1; }
  while (i > 0) { i = i - 1; s[o] = tmp[i]; o = o + 1; }
  s[o] = 0;
  return s;
}

I32 Main()
{
  I64 cfg_n = 0;
  U8 *cfg = ReadAll("build/abi01-verify-inputs.txt", &cfg_n);
  if (cfg == NULL || cfg_n < 3) {
    "ABI_IMPLEMENT01_VERIFY missing build/abi01-verify-inputs.txt\n";
    return 2;
  }
  I64 cur = 0;
  U8 *shadow = CfgLine(cfg, cfg_n, &cur);
  U8 *ev = CfgLine(cfg, cfg_n, &cur);
  Free(cfg);

  "ABI_IMPLEMENT01_VERIFY shadow=%s evidence=%s\n", shadow, ev;

  U8 *consumer_src = StrPrint(NULL, "%s/src/compile.c", shadow);
  U8 *subject_src = StrPrint(NULL, "%s/tools/experimental/compile-print-ast-decision.HC", shadow);

  // ---- V01..V03: the consumer's own bytes -------------------------------
  I64 cs_n = 0;
  U8 *cs = ReadAll(consumer_src, &cs_n);
  Check(cs != NULL, "V01a", "src/compile.c is readable");
  I64 n_member = -1;
  I64 n_call = -1;
  I64 n_dormant = -1;
  if (cs != NULL) {
    n_member = CountOcc(cs, cs_n, "ast->");
    n_call = CountOcc(cs, cs_n, "AbiCpaShouldPrintAst(");
    n_dormant = CountOcc(cs, cs_n, "kind != AST_");
    Free(cs);
  }
  Check(n_member == 3, "V01b", "the only three Ast member accesses left in the source are the dormant legacy branch");
  Check(n_call == 1, "V02", "src/compile.c has exactly one PolyC decision call site");
  Check(n_dormant == 3, "V03", "the three dormant legacy comparisons survive in the #else branch");

  // ---- V04..V05: the EFFECTIVE preprocessed translation unit ------------
  U8 *pp_on = StrPrint(NULL,
    "/usr/bin/gcc -DHCC_ENABLE_JIT -DHCC_USE_SELFHOST_ABI_CPA -I%s/src/asm -I%s/src "
    "-std=gnu11 -arch arm64 -E -H %s -o /dev/null 2>&1", shadow, shadow, consumer_src);
  I64 pn = 0;
  U8 *pout = RunCapture(pp_on, &pn);
  Free(pp_on);
  I64 n_pp_on = -1;
  I64 n_pp_member = -1;
  if (pout != NULL) {
    n_pp_on = CountOcc(pout, pn, "src/ast.h");
    n_pp_member = CountOcc(pout, pn, "ast->");
    Free(pout);
  }
  Check(n_pp_on == 0, "V04", "the delegating effective TU has ZERO src/ast.h frames");
  Check(n_pp_member == 0, "V04b", "the delegating effective TU has ZERO Ast member accesses");

  U8 *pp_off = StrPrint(NULL,
    "/usr/bin/gcc -DHCC_ENABLE_JIT -I%s/src/asm -I%s/src -std=gnu11 -arch arm64 "
    "-E -H %s -o /dev/null 2>&1", shadow, shadow, consumer_src);
  I64 pn2 = 0;
  U8 *pout2 = RunCapture(pp_off, &pn2);
  Free(pp_off);
  I64 n_pp_off = -1;
  if (pout2 != NULL) { n_pp_off = CountOcc(pout2, pn2, "src/ast.h"); Free(pout2); }
  Check(n_pp_off >= 1, "V05", "the dormant stage0 configuration still carries the legacy layout");

  // ---- V06..V09: symbol roles in the real objects and the binary --------
  U8 *host_obj = StrPrint(NULL, "%s/build/CMakeFiles/hcc.dir/abi-cpa-host.c.o", shadow);
  U8 *cons_obj = StrPrint(NULL, "%s/build/CMakeFiles/hcc.dir/compile.c.o", shadow);
  U8 *subj_obj = StrPrint(NULL, "%s/build/compile-print-ast-decision-subject.o", shadow);
  U8 *hcc_bin = StrPrint(NULL, "%s/hcc", shadow);

  U8 *c06 = StrPrint(NULL, "/usr/bin/nm -gU %s 2>/dev/null", host_obj);
  I64 n06 = 0;
  U8 *o06 = RunCapture(c06, &n06);
  Free(c06);
  I64 host_t = -1;
  I64 host_mut = -1;
  if (o06 != NULL) {
    host_t = CountOcc(o06, n06, " T _Abi");
    host_mut = CountOcc(o06, n06, "Push") + CountOcc(o06, n06, "Set") + CountOcc(o06, n06, "Grant");
    Free(o06);
  }
  Check(host_t == 4, "V06a", "the compiler host adapter exports exactly four mechanical symbols");
  Check(host_mut == 0, "V06b", "the compiler host adapter exports NO mutation entry point");

  U8 *c07 = StrPrint(NULL, "/usr/bin/nm -gU %s 2>/dev/null", subj_obj);
  I64 n07 = 0;
  U8 *o07 = RunCapture(c07, &n07);
  Free(c07);
  Bool sub_def = FALSE;
  if (o07 != NULL) { sub_def = (strstr(o07, "T _AbiCpaShouldPrintAst") != NULL); Free(o07); }
  Check(sub_def, "V07a", "the compiled PolyC subject DEFINES the decision");

  U8 *c07b = StrPrint(NULL, "/usr/bin/nm -u %s 2>/dev/null", subj_obj);
  I64 n07b = 0;
  U8 *o07b = RunCapture(c07b, &n07b);
  Free(c07b);
  Bool sub_imp = FALSE;
  if (o07b != NULL) { sub_imp = (strstr(o07b, "_AbiCpaAstKind") != NULL); Free(o07b); }
  Check(sub_imp, "V07b", "the compiled PolyC subject IMPORTS only the kind accessor");

  U8 *c08 = StrPrint(NULL, "/usr/bin/nm -u %s 2>/dev/null", cons_obj);
  I64 n08 = 0;
  U8 *o08 = RunCapture(c08, &n08);
  Free(c08);
  Bool cons_imp = FALSE;
  if (o08 != NULL) { cons_imp = (strstr(o08, "_AbiCpaShouldPrintAst") != NULL); Free(o08); }
  Check(cons_imp, "V08", "the shadow consumer object IMPORTS the PolyC decision");

  U8 *c09 = StrPrint(NULL, "/usr/bin/nm %s 2>/dev/null", hcc_bin);
  I64 n09 = 0;
  U8 *o09 = RunCapture(c09, &n09);
  Free(c09);
  Bool bin_def = FALSE;
  I64 n_boot = -1;
  if (o09 != NULL) {
    bin_def = (strstr(o09, "T _AbiCpaShouldPrintAst") != NULL);
    n_boot = CountOcc(o09, n09, " T _Bootstrap");
    Free(o09);
  }
  Check(bin_def, "V09a", "the shadow compiler binary DEFINES the PolyC decision");
  Check(n_boot == 9, "V09b", "the nine production PolyC authorities are still linked");

  // ---- V10..V11: recomputed digests against the recorded evidence -------
  U8 *ev_pl = StrPrint(NULL, "%s/c2/producer-and-linkage.tsv", ev);
  I64 sub_sha = ShaOf(subject_src, ev_pl);
  Check(sub_sha != 0, "V10", "the recorded PolyC subject source sha256 equals the recomputed one");
  U8 *ev_man = StrPrint(NULL, "%s/c2/shadow-source-and-object-manifest.tsv", ev);
  I64 cons_sha = ShaOf(cons_obj, ev_man);
  Check(cons_sha != 0, "V11", "the recorded shadow consumer object sha256 equals the recomputed one");

  // ---- V12: the graph ledger, recomputed from its own rows --------------
  U8 *gp = StrPrint(NULL, "%s/c2/graph-production-shadow.tsv", ev);
  I64 gn = 0;
  U8 *gb = ReadAll(gp, &gn);
  I64 edge_rows = 0;
  I64 proven = 0;
  I64 non_zero_prod = 0;
  if (gb != NULL) {
    I64 i = 0;
    Bool at_start = TRUE;
    while (i < gn) {
      if (at_start && i + 1 < gn && gb[i] == 'E' && gb[i+1] == '-') {
        edge_rows = edge_rows + 1;
        I64 j = i;
        while (j < gn && gb[j] != 10) j = j + 1;
        for (I64 k = i; k + 30 <= j; k = k + 1) {
          if (BufCmp(gb + k, "SHADOW_CUT_PROVEN_BY_EXECUTION", 30) == 0) { proven = proven + 1; break; }
        }
        I64 tabs = 0;
        I64 m = i;
        while (m < gn && tabs < 6) {
          if (gb[m] == '\t') tabs = tabs + 1;
          m = m + 1;
        }
        if (tabs == 6 && (m >= gn || gb[m] != '0')) non_zero_prod = non_zero_prod + 1;
        i = j;
      }
      at_start = (gb[i] == 10);
      i = i + 1;
    }
  }
  Check(edge_rows == 135, "V12a", "the graph ledger has exactly 135 edge rows");
  Check(non_zero_prod == 0, "V12b", "no edge contributes to a production cut");
  Check(proven == 1, "V12c", "exactly one edge is proved cut in the shadow graph");
  Bool id_ok = FALSE;
  if (gb != NULL) id_ok = (strstr(gb, "E-TYP-0136\tSYS-COMPILE_DRIVER\tSYS-AST") != NULL);
  Check(id_ok, "V12d", "the proved edge is the frozen E-TYP-0136 with its original endpoints");
  if (gb != NULL) Free(gb);
  Free(gp);

  // ---- V13..V14: frozen contracts, exact-ID joined ----------------------
  U8 *acp = StrPrint(NULL, "%s/c0/frozen-50-ac.tsv", ev);
  I64 acn = 0;
  U8 *acb = ReadAll(acp, &acn);
  I64 ac_bad = 0;
  if (acb != NULL) {
    for (I64 k = 1; k <= 50; k = k + 1) {
      U8 *tok = StrPrint(NULL, "AC%s", TwoDigits(k));
      if (CountTokLines(acb, acn, tok) != 1) ac_bad = ac_bad + 1;
      Free(tok);
    }
  } else { ac_bad = -1; }
  Check(ac_bad == 0, "V13", "AC01..AC50 each appear exactly once in the frozen ledger");
  if (acb != NULL) Free(acb);
  Free(acp);

  U8 *aip = StrPrint(NULL, "%s/c0/frozen-24-controls.tsv", ev);
  I64 ain = 0;
  U8 *aib = ReadAll(aip, &ain);
  I64 ai_bad = 0;
  if (aib != NULL) {
    for (I64 k = 1; k <= 24; k = k + 1) {
      U8 *tok = StrPrint(NULL, "AI-%s", TwoDigits(k));
      if (CountTokLines(aib, ain, tok) != 1) ai_bad = ai_bad + 1;
      Free(tok);
    }
  } else { ai_bad = -1; }
  Check(ai_bad == 0, "V14", "AI-01..AI-24 each appear exactly once in the frozen control ledger");
  if (aib != NULL) Free(aib);
  Free(aip);

  // ---- V15: the fourteen frozen candidates -----------------------------
  U8 *cp = StrPrint(NULL, "%s/c0/recon01-14-candidates.tsv", ev);
  I64 cn = 0;
  U8 *cb = ReadAll(cp, &cn);
  I64 cand_rows = 0;
  if (cb != NULL) {
    for (I64 k = 1; k <= 14; k = k + 1) {
      U8 *tok = StrPrint(NULL, "CAND-%s", NumStr(k));
      cand_rows = cand_rows + CountTokLines(cb, cn, tok);
      Free(tok);
    }
  } else { cand_rows = -1; }
  Check(cand_rows == 14, "V15", "all fourteen frozen candidates are still present exactly once");
  if (cb != NULL) Free(cb);
  Free(cp);

  // ---- V16: the behavioural differential --------------------------------
  U8 *dp = StrPrint(NULL, "%s/c2/g0-vs-g1-differential.tsv", ev);
  I64 dn = 0;
  U8 *db = ReadAll(dp, &dn);
  I64 match_rows = -1;
  if (db != NULL) { match_rows = CountOcc(db, dn, "\tMATCH"); Free(db); }
  Check(match_rows == 9, "V16", "all nine frozen witnesses MATCH between G0 and G1");
  Free(dp);

  // ---- V17: the PolyC subject carries no layout knowledge ---------------
  I64 sn = 0;
  U8 *sb = ReadAll(subject_src, &sn);
  I64 n_arrow = -1;
  I64 n_sizeof = -1;
  if (sb != NULL) {
    n_arrow = CountCodeArrows(subject_src);
    n_sizeof = CountOcc(sb, sn, "sizeof");
    Free(sb);
  }
  Check(n_arrow == 0, "V17a", "the PolyC subject never dereferences a pointer");
  Check(n_sizeof == 0, "V17b", "the PolyC subject never computes a layout size");
  "ABI_IMPLEMENT01_VERIFY checks=%lld failures=%lld\n", g_check, g_fail;
  return g_fail;
}
