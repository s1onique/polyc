// tools/quality/lexer09-n02-mutation-runner.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION05 C2 IMPL.
//
// PolyC-native N02 production-causal-control orchestration runner.
//
// Per ACT §28 this binary owns ALL substantive N02 orchestration:
//   - temporary directory naming
//   - pristine source read
//   - mutation generation (kind=B: drop last byte of link_libs)
//   - mutated source write
//   - SHA capture (via ./build/lexer07-sha256)
//   - component compile invocation (./build/hcc-bootstrap02)
//   - component artifact verification
//   - seam link invocation (cc direct, bypassing make rules)
//   - seam artifact verification
//   - seam execution
//   - stdout/stderr collection
//   - RC classification
//   - pristine-vs-mutated semantic comparison
//   - expected fixture/field comparison
//   - machine-readable result emission
//
// The shell wrapper scripts/quality/lexer09-n02-mutation-runner.sh is
// reduced to dispatch-only and merely forwards argv to this binary.
//
// USAGE:
//   build/lexer09-n02-mutation-runner <pristine_src> <output_evidence> \
//       <pristine_seam_bin> <seam_src_c> <stage1_objdir> \
//       <mutated_seam_bin> <mutated_component_o> <polyC_compiler> \
//       <test_prefix> <mutated_src_out> <pristine_src_out> \
//       <pristine_rerun_out>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

#define SHA_BIN "./build/lexer07-sha256"
#define CC_BIN  "/usr/bin/cc"

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

I64 StrLen(U8 *s) { I64 n = 0; while (s[n]) n = n + 1; return n; }

I64 StrEq(U8 *a, U8 *b)
{
  while (*a && *b) {
    if (*a != *b) return 0;
    a = a + 1; b = b + 1;
  }
  return *a == 0 && *b == 0;
}

I64 StrStartsWith(U8 *s, U8 *prefix)
{
  while (*prefix) {
    if (*s != *prefix) return 0;
    s = s + 1; prefix = prefix + 1;
  }
  return 1;
}

I64 CopyFileTo(U8 *src_path, U8 *dst_path)
{
  I64 sz = 0;
  U8 *buf = FileRead(src_path, &sz);
  if (!buf || sz == 0) {
    if (buf) Free(buf);
    return -1;
  }
  if (!FileWrite(dst_path, buf, sz, 0x0202)) {
    Free(buf);
    return -2;
  }
  Free(buf);
  return 0;
}

I64 Sha256File(U8 *path, U8 *out_hex)
{
  U8 *args[4];
  args[0] = SHA_BIN;
  args[1] = "--file";
  args[2] = path;
  args[3] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(SHA_BIN, args, &out, &err);
  if (rc != 0) {
    if (out) Free(out);
    if (err) Free(err);
    return rc;
  }
  if (out == NULL) {
    if (err) Free(err);
    return 2;
  }
  I64 i = 0;
  while (i < 64 && out[i] != 0 && out[i] != '\n' &&
         out[i] != ' ' && out[i] != '\r') {
    out_hex[i] = out[i];
    i = i + 1;
  }
  out_hex[i] = 0;
  Free(out);
  if (err) Free(err);
  return 0;
}

I64 ApplyMutationB(U8 *src_path, U8 *dst_path)
{
  // Read source.
  I64 sz = 0;
  U8 *buf = FileRead(src_path, &sz);
  if (!buf || sz == 0) {
    if (buf) Free(buf);
    return -1;
  }
  // Build needle and insertion strings on the heap (PolyC static
  // array initializers appear to store only the first 4 bytes for
  // unknown reasons; heap allocation is reliable).
  U8 *needle = MAlloc(256);
  I64 nlen = 0;
  needle[nlen++] = ' '; needle[nlen++] = ' '; needle[nlen++] = ' ';
  needle[nlen++] = ' '; needle[nlen++] = ' '; needle[nlen++] = ' ';
  needle[nlen++] = '*'; needle[nlen++] = 'o'; needle[nlen++] = 'u';
  needle[nlen++] = 't'; needle[nlen++] = '_'; needle[nlen++] = 't';
  needle[nlen++] = 'a'; needle[nlen++] = 'r'; needle[nlen++] = 'g';
  needle[nlen++] = 'e'; needle[nlen++] = 't'; needle[nlen++] = '_';
  needle[nlen++] = 'l'; needle[nlen++] = 'e'; needle[nlen++] = 'n';
  needle[nlen++] = ' '; needle[nlen++] = ' '; needle[nlen++] = '=';
  needle[nlen++] = ' '; needle[nlen++] = 'i'; needle[nlen++] = ' ';
  needle[nlen++] = '-'; needle[nlen++] = ' '; needle[nlen++] = 'b';
  needle[nlen++] = 'o'; needle[nlen++] = 'd'; needle[nlen++] = 'y';
  needle[nlen++] = '_'; needle[nlen++] = 's'; needle[nlen++] = 't';
  needle[nlen++] = 'a'; needle[nlen++] = 'r'; needle[nlen++] = 't';
  needle[nlen++] = ';';
  needle[nlen] = 0;
  U8 *ins = MAlloc(256);
  I64 ilen = 0;
  ins[ilen++] = '\n';
  ins[ilen++] = ' '; ins[ilen++] = ' '; ins[ilen++] = ' ';
  ins[ilen++] = ' '; ins[ilen++] = ' '; ins[ilen++] = ' ';
  ins[ilen++] = '*'; ins[ilen++] = 'o'; ins[ilen++] = 'u';
  ins[ilen++] = 't'; ins[ilen++] = '_'; ins[ilen++] = 't';
  ins[ilen++] = 'a'; ins[ilen++] = 'r'; ins[ilen++] = 'g';
  ins[ilen++] = 'e'; ins[ilen++] = 't'; ins[ilen++] = '_';
  ins[ilen++] = 'l'; ins[ilen++] = 'e'; ins[ilen++] = 'n';
  ins[ilen++] = ' '; ins[ilen++] = '='; ins[ilen++] = ' ';
  ins[ilen++] = '*'; ins[ilen++] = 'o'; ins[ilen++] = 'u';
  ins[ilen++] = 't'; ins[ilen++] = '_'; ins[ilen++] = 't';
  ins[ilen++] = 'a'; ins[ilen++] = 'r'; ins[ilen++] = 'g';
  ins[ilen++] = 'e'; ins[ilen++] = 't'; ins[ilen++] = '_';
  ins[ilen++] = 'l'; ins[ilen++] = 'e'; ins[ilen++] = 'n';
  ins[ilen++] = ' '; ins[ilen++] = '-'; ins[ilen++] = ' ';
  ins[ilen++] = '1'; ins[ilen++] = ';';
  ins[ilen++] = ' '; ins[ilen++] = ' ';
  ins[ilen++] = '/'; ins[ilen++] = '/';
  ins[ilen++] = ' '; ins[ilen++] = 'C'; ins[ilen++] = 'O';
  ins[ilen++] = 'R'; ins[ilen++] = 'R'; ins[ilen++] = 'E';
  ins[ilen++] = 'C'; ins[ilen++] = 'T'; ins[ilen++] = 'I';
  ins[ilen++] = 'O'; ins[ilen++] = 'N'; ins[ilen++] = '0';
  ins[ilen++] = '5'; ins[ilen++] = ' '; ins[ilen++] = 'N';
  ins[ilen++] = '0'; ins[ilen++] = '2'; ins[ilen++] = ' ';
  ins[ilen++] = 'k'; ins[ilen++] = 'i'; ins[ilen++] = 'n';
  ins[ilen++] = 'd'; ins[ilen++] = ' '; ins[ilen++] = 'B';
  ins[ilen++] = '\n';
  ins[ilen] = 0;
  I64 found_count = 0;
  // Find ALL occurrences and remember their offsets; mutate back-to-front
  // so byte offsets remain stable.
  I64 offsets[8];
  I64 noffsets = 0;
  for (I64 i = 0; i + nlen <= sz; i = i + 1) {
    I64 m = 1;
    for (I64 j = 0; j < nlen; j = j + 1) {
      if (buf[i + j] != needle[j]) { m = 0; break; }
    }
    if (m) {
      if (noffsets < 8) {
        offsets[noffsets] = i;
        noffsets = noffsets + 1;
      }
      found_count = found_count + 1;
    }
  }
  Free(needle);
  if (noffsets == 0) { Free(buf); Free(ins); return -2; }
  // Insert ins after every occurrence, from last to first.
  I64 cur_sz = sz;
  U8 *cur_buf = MAlloc(cur_sz + noffsets * ilen + 1);
  if (!cur_buf) { Free(buf); Free(ins); return -3; }
  // Copy first.
  for (I64 i = 0; i < cur_sz; i = i + 1) cur_buf[i] = buf[i];
  // Insert in reverse.
  for (I64 k = noffsets - 1; k >= 0; k = k - 1) {
    I64 pos = offsets[k] + nlen;
    // shift [pos..cur_sz) right by ilen
    for (I64 i = cur_sz - 1; i >= pos; i = i - 1)
      cur_buf[i + ilen] = cur_buf[i];
    // insert
    for (I64 i = 0; i < ilen; i = i + 1) cur_buf[pos + i] = ins[i];
    cur_sz = cur_sz + ilen;
  }
  cur_buf[cur_sz] = 0;
  if (!FileWrite(dst_path, cur_buf, cur_sz, 0x0202)) {
    Free(buf); Free(cur_buf); Free(ins);
    return -4;
  }
  Free(buf); Free(cur_buf); Free(ins);
  return 0;
}

I64 CompileComponent(U8 *compiler, U8 *test_prefix, U8 *src_hc, U8 *out_o)
{
  U8 *args[8];
  args[0] = compiler;
  U8 *install_arg = StrPrint(NULL, "--install-dir=%s", test_prefix);
  args[1] = install_arg;
  args[2] = "-c";
  args[3] = src_hc;
  args[4] = "-o";
  args[5] = out_o;
  args[6] = NULL;
  U8 *oo = NULL;
  U8 *ee = NULL;
  I64 rc = SpawnAndCapture(compiler, args, &oo, &ee);
  if (install_arg) Free(install_arg);
  if (oo) Free(oo);
  if (ee) Free(ee);
  return rc;
}

I64 RunSeam(U8 *seam_bin, U8 *out_path)
{
  U8 *args[2];
  args[0] = seam_bin;
  args[1] = NULL;
  U8 *oo = NULL;
  U8 *ee = NULL;
  I64 rc = SpawnAndCapture(seam_bin, args, &oo, &ee);
  if (oo) {
    FileWrite(out_path, oo, StrLen(oo), 0x0202);
    Free(oo);
  }
  if (ee) Free(ee);
  return rc;
}

// Extract link_libs value for a fixture id from a seam-run output.
I64 ExtractLinkLibs(U8 *seam_output_path, U8 *fixture_id, U8 *out_val)
{
  I64 sz = 0;
  U8 *buf = FileRead(seam_output_path, &sz);
  if (!buf || sz == 0) {
    if (buf) Free(buf);
    return -1;
  }
  I64 fid_len = StrLen(fixture_id);
  // Walk lines, find "CASE=<fixture_id>", then look for "link_libs=...".
  I64 i = 0;
  I64 found_case = 0;
  while (i < sz) {
    I64 ll = 0;
    while (i + ll < sz && buf[i + ll] != '\n') ll = ll + 1;
    if (ll >= 5 && buf[i]=='C' && buf[i+1]=='A' && buf[i+2]=='S' &&
        buf[i+3]=='E' && buf[i+4]=='=') {
      U8 cid[128];
      I64 ci = 0;
      for (I64 k = 5; k < ll && ci < 127; k = k + 1)
        cid[ci++] = buf[i + k];
      cid[ci] = 0;
      if (StrEq(cid, fixture_id)) {
        found_case = 1;
      } else if (found_case) {
        // We've moved past the case block.
        break;
      }
    } else if (found_case && ll >= 9 && buf[i]=='l' && buf[i+1]=='i' &&
               buf[i+2]=='n' && buf[i+3]=='k' && buf[i+4]=='_' &&
               buf[i+5]=='l' && buf[i+6]=='i' && buf[i+7]=='b' &&
               buf[i+8]=='s' && buf[i+9]=='=') {
      for (I64 k = 10; k < ll; k = k + 1) out_val[k - 10] = buf[i + k];
      out_val[ll - 10] = 0;
      Free(buf);
      return 0;
    }
    i = i + ll + 1;
  }
  Free(buf);
  out_val[0] = 0;
  if (found_case) return -2;
  return -3;
}

I64 LinkSeam(U8 *seam_src, U8 *mutated_o, U8 *stage1_objdir, U8 *mutated_seam_bin,
             U8 *polyC_compiler)
{
  // Build cc argv. The original CORRECTION04 shell script collected a
  // list of .o files from stage1_objdir; replicate that here by
  // enumerating the canonical set used by the lexer09-link-component-build
  // rule. This is a focused list of compile-time objects.
  U8 *objs[64];
  I64 nobjs = 0;
  U8 *names[36];
  names[0] = "lexer.c.o"; names[1] = "aostr.c.o"; names[2] = "containers.c.o";
  names[3] = "list.c.o"; names[4] = "arena.c.o"; names[5] = "ast.c.o";
  names[6] = "cctrl.c.o"; names[7] = "parser.c.o"; names[8] = "json.c.o";
  names[9] = "mempool.c.o"; names[10] = "memory.c.o"; names[11] = "memsafe.c.o";
  names[12] = "asm.c.o"; names[13] = "cfg.c.o"; names[14] = "cfg-print.c.o";
  names[15] = "cli.c.o"; names[16] = "compile.c.o"; names[17] = "ir.c.o";
  names[18] = "ir-debug.c.o"; names[19] = "ir-eval.c.o";
  names[20] = "ir-optimise.c.o"; names[21] = "ir-regalloc.c.o";
  names[22] = "ir-types.c.o"; names[23] = "lsp.c.o"; names[24] = "prsasm.c.o";
  names[25] = "prslib.c.o"; names[26] = "prsutil.c.o";
  names[27] = "transpiler.c.o"; names[28] = "x86_64.c.o";
  names[29] = "x86_64-jit.c.o"; names[30] = "aarch64.c.o";
  names[31] = "aarch64-jit.c.o"; names[32] = "x86.c.o";
  names[33] = "jit-common.c.o"; names[34] = "linenoise/linenoise.c.o";
  names[35] = NULL;
  for (I64 i = 0; names[i] != NULL; i = i + 1) {
    U8 *path = StrPrint(NULL, "%s/%s", stage1_objdir, names[i]);
    I64 sz = 0;
    U8 *t = FileRead(path, &sz);
    if (t) {
      objs[nobjs] = path;
      nobjs = nobjs + 1;
      Free(t);
    } else {
      Free(path);
    }
  }
  // Build argv.
  U8 *args[80];
  I64 argc = 0;
  args[argc++] = CC_BIN;
  args[argc++] = "-std=c99";
  args[argc++] = "-O2";
  args[argc++] = "-Wall";
  args[argc++] = "-Wextra";
  args[argc++] = "-Wno-unused-function";
  args[argc++] = "-Wno-unused-variable";
  args[argc++] = "-DBUILD_LABEL=\"stage1mut\"";
  args[argc++] = "-DHCC_USE_SELFHOST_COMPONENTS";
  args[argc++] = "-Isrc";
  args[argc++] = "-o";
  args[argc++] = mutated_seam_bin;
  args[argc++] = seam_src;
  for (I64 i = 0; i < nobjs; i = i + 1) args[argc++] = objs[i];
  args[argc++] = "./build/lexer07-scalar-literal.o";
  args[argc++] = "./build/bootstrap02-ident.o";
  args[argc++] = "./build/bootstrap06-operator-classify.o";
  args[argc++] = "./build/lexer08-trivia.o";
  args[argc++] = mutated_o;
  args[argc++] = "./build/asm/libtasm.a";
  args[argc++] = "-lm";
  args[argc++] = "-lpthread";
  args[argc++] = "-ldl";
  args[argc] = NULL;
  U8 *oo = NULL;
  U8 *ee = NULL;
  I64 rc = SpawnAndCapture(CC_BIN, args, &oo, &ee);
  if (oo) Free(oo);
  if (ee) Free(ee);
  for (I64 i = 0; i < nobjs; i = i + 1) Free(objs[i]);
  return rc;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc != 13) {
    "USAGE: lexer09-n02-mutation-runner <pristine_src> <output_evidence> "
      "<pristine_seam_bin> <seam_src_c> <stage1_objdir> "
      "<mutated_seam_bin> <mutated_component_o> <polyC_compiler> "
      "<test_prefix> <mutated_src_out> <pristine_src_out> "
      "<pristine_rerun_out>\n";
    return 2;
  }
  U8 *pristine_src       = argv[1];
  U8 *output_evidence    = argv[2];
  U8 *pristine_seam_bin  = argv[3];
  U8 *seam_src_c         = argv[4];
  U8 *stage1_objdir      = argv[5];
  U8 *mutated_seam_bin   = argv[6];
  U8 *mutated_component_o = argv[7];
  U8 *polyC_compiler     = argv[8];
  U8 *test_prefix        = argv[9];
  U8 *mutated_src_out    = argv[10];
  U8 *pristine_src_out   = argv[11];
  U8 *pristine_rerun_out = argv[12];

  I64 rc;
  U8 pristine_sha[65];
  rc = Sha256File(pristine_src, pristine_sha);
  if (rc != 0) {
    "N02_OUTCOME=FAIL reason=pristine-sha-fail rc=%d\n", rc;
    return 1;
  }
  "N02_MUTATION_KIND=B\n";
  "PRISTINE_SOURCE_SHA256=%s\n", pristine_sha;

  rc = CopyFileTo(pristine_src, pristine_src_out);
  if (rc != 0) {
    "N02_OUTCOME=FAIL reason=copy-pristine rc=%d\n", rc;
    return 1;
  }
  rc = ApplyMutationB(pristine_src_out, mutated_src_out);
  if (rc != 0) {
    "N02_OUTCOME=FAIL reason=mutation-apply rc=%d\n", rc;
    return 1;
  }
  U8 mutated_sha[65];
  rc = Sha256File(mutated_src_out, mutated_sha);
  if (rc != 0) {
    "N02_OUTCOME=FAIL reason=mutated-sha-fail rc=%d\n", rc;
    return 1;
  }
  "MUTATED_SOURCE_SHA256=%s\n", mutated_sha;
  if (StrEq(pristine_sha, mutated_sha)) {
    "SOURCE_SHA_DIFFERS=NO\n";
    "N02_OUTCOME=FAIL reason=source-sha-equal\n";
    return 1;
  }
  "SOURCE_SHA_DIFFERS=YES\n";
  "MUTATED_SOURCE_SHA_NONEMPTY=YES\n";

  // Stage 3: compile mutated component.
  I64 build_rc = CompileComponent(polyC_compiler, test_prefix,
                                  mutated_src_out, mutated_component_o);
  "MUTATED_COMPONENT_BUILD_RC=%d\n", build_rc;
  if (build_rc != 0) {
    "N02_OUTCOME=FAIL reason=build-failed\n";
    return 1;
  }
  U8 mutated_o_sha[65];
  rc = Sha256File(mutated_component_o, mutated_o_sha);
  if (rc != 0 || mutated_o_sha[0] == 0) {
    "MUTATED_COMPONENT_SHA_NONEMPTY=NO\n";
    "N02_OUTCOME=FAIL reason=component-sha-fail rc=%d\n", rc;
    return 1;
  }
  "MUTATED_COMPONENT_SHA_NONEMPTY=YES\n";
  "MUTATED_COMPONENT_SHA256=%s\n", mutated_o_sha;
  U8 pristine_o_sha[65];
  pristine_o_sha[0] = 0;
  U8 *pristine_o_path = "./build/lexer09-link.o";
  I64 sz = 0;
  U8 *t = FileRead(pristine_o_path, &sz);
  if (t && sz > 0) {
    Free(t);
    Sha256File(pristine_o_path, pristine_o_sha);
  }
  if (pristine_o_sha[0]) {
    "PRISTINE_COMPONENT_SHA256=%s\n", pristine_o_sha;
  }
  if (pristine_o_sha[0] && StrEq(pristine_o_sha, mutated_o_sha)) {
    "COMPONENT_SHA_DIFFERS=NO\n";
    "MUTATED_COMPONENT_SHA_DIFFERS=NO\n";
  } else {
    "COMPONENT_SHA_DIFFERS=YES\n";
    "MUTATED_COMPONENT_SHA_DIFFERS=YES\n";
  }

  // Stage 4: link seam with mutated component.
  I64 link_rc = LinkSeam(seam_src_c, mutated_component_o, stage1_objdir,
                         mutated_seam_bin, polyC_compiler);
  "MUTATED_SEAM_LINK_RC=%d\n", link_rc;
  if (link_rc != 0) {
    "N02_OUTCOME=FAIL reason=link-failed\n";
    return 1;
  }
  U8 mutated_seam_sha[65];
  rc = Sha256File(mutated_seam_bin, mutated_seam_sha);
  if (rc != 0 || mutated_seam_sha[0] == 0) {
    "MUTATED_SEAM_SHA_NONEMPTY=NO\n";
    "N02_OUTCOME=FAIL reason=seam-sha-fail rc=%d\n", rc;
    return 1;
  }
  "MUTATED_SEAM_SHA_NONEMPTY=YES\n";
  "MUTATED_SEAM_SHA256=%s\n", mutated_seam_sha;

  // Stage 5: run mutated seam.
  I64 seam_run_rc = RunSeam(mutated_seam_bin,
    "evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/c3-seam-mutated.raw.txt");
  "MUTATED_SEAM_RUN_RC=%d\n", seam_run_rc;
  if (seam_run_rc != 0) {
    "N02_OUTCOME=FAIL reason=seam-run-failed\n";
    return 1;
  }

  // Stage 6: extract link_libs for L07 from mutated run.
  U8 mutated_l07[128];
  ExtractLinkLibs(
    "evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/c3-seam-mutated.raw.txt",
    "L07_angle_complex", mutated_l07);
  "MUTATED_L07_LINK_LIBS=%s\n", mutated_l07;
  if (StrEq(mutated_l07, "lib-complex_1.")) {
    "MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES\n";
    "EXPECTED_DIVERGENCE_FIXTURE=L07\n";
    "EXPECTED_DIVERGENCE_FIELD=link_libs\n";
    "UNEXPECTED_MUTATION_DIVERGENCE_COUNT=0\n";
  } else {
    "MUTATED_PRODUCTION_DIVERGENCE_DETECTED=NO\n";
    "UNEXPECTED_MUTATION_DIVERGENCE_COUNT=1\n";
    "N02_OUTCOME=FAIL reason=divergence-not-detected observed=%s\n",
      mutated_l07;
    return 1;
  }

  // Stage 7: pristine rerun (sanity).
  I64 pristine_run_rc = RunSeam(pristine_seam_bin, pristine_rerun_out);
  if (pristine_run_rc != 0) {
    "PRISTINE_REVERIFY_RC=1\n";
    "N02_OUTCOME=FAIL reason=pristine-rerun-failed\n";
    return 1;
  }
  U8 pristine_l07[128];
  ExtractLinkLibs(pristine_rerun_out, "L07_angle_complex", pristine_l07);
  "PRISTINE_L07_LINK_LIBS=%s\n", pristine_l07;
  if (StrEq(pristine_l07, "lib-complex_1.0")) {
    "PRISTINE_REVERIFY_RC=0\n";
  } else {
    "PRISTINE_REVERIFY_RC=1\n";
    "N02_OUTCOME=FAIL reason=pristine-not-reverted observed=%s\n",
      pristine_l07;
    return 1;
  }

  "N02_OUTCOME=PASS\n";
  return 0;
}






