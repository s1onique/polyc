// tools/quality/parser-padding-generation-provenance-verify.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
//
// PolyC-native generation-provenance verifier (AC29 repair).
//
// Reads a provenance TSV (header + one row per generation) and for
// each generation row, recomputes the actual build identity from
// disk and compares it to the row's expected fields:
//
//   compiler_sha256        vs sha256(actual compiler_path)
//   source_sha256          vs sha256(actual source_path)
//   command_sha256         vs sha256(normalized command_line)
//   object_sha256          vs sha256(actual object_path)
//   fresh_build_record_sha vs sha256(actual fresh_build_record)
//
// If ANY required field mismatches, emit REJECT and exit nonzero.
// Otherwise emit PASS and exit 0.
//
// Schema columns (tab-separated):
//   generation, compiler_path, compiler_sha256, source_path,
//   source_sha256, command_line, command_sha256, object_path,
//   object_sha256, object_size, fresh_build_record,
//   fresh_build_record_sha256, mtime

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

#define SHA256_BIN "./build/lexer07-sha256"
#define LINE_CAP   1024

U0 EmitField(U8 *label, U8 *expected, U8 *actual, I64 match)
{
  if (match) {
    "PROVENANCE_FIELD_MATCH label=%s expected=%s actual=%s\n",
      label, expected, actual;
  } else {
    "PROVENANCE_FIELD_MISMATCH label=%s expected=%s actual=%s\n",
      label, expected, actual;
  }
}

Bool GetFileSHA256(U8 *path, U8 *out_hex64)
{
  U8 *args[4];
  args[0] = SHA256_BIN;
  args[1] = "--file";
  args[2] = path;
  args[3] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(SHA256_BIN, args, &out, &err);
  if (rc != 0) {
    if (out) Free(out);
    if (err) Free(err);
    return FALSE;
  }
  if (out == NULL) {
    if (err) Free(err);
    return FALSE;
  }
  I64 i = 0;
  while (i < 64 && out[i] != 0 && out[i] != '\n' &&
         out[i] != ' ' && out[i] != '\r') {
    out_hex64[i] = out[i];
    i = i + 1;
  }
  out_hex64[i] = 0;
  if (out) Free(out);
  if (err) Free(err);
  return (i == 64);
}

Bool GetStringSHA256(U8 *str, U8 *out_hex64)
{
  // Compute sha256(str) by piping str through the PolyC sha256 tool's
  // string-arg mode. The PolyC lexer07-sha256 accepts a positional
  // argv[1] and prints hex.
  U8 *args[3];
  args[0] = SHA256_BIN;
  args[1] = str;
  args[2] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(SHA256_BIN, args, &out, &err);
  if (rc != 0) {
    if (out) Free(out);
    if (err) Free(err);
    return FALSE;
  }
  if (out == NULL) {
    if (err) Free(err);
    return FALSE;
  }
  I64 i = 0;
  while (i < 64 && out[i] != 0 && out[i] != '\n' &&
         out[i] != ' ' && out[i] != '\r') {
    out_hex64[i] = out[i];
    i = i + 1;
  }
  out_hex64[i] = 0;
  if (out) Free(out);
  if (err) Free(err);
  return (i == 64);
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 2) {
    "PROVENANCE_VERIFY_USAGE: %s <provenance.tsv>\n", argv[0];
    return 2;
  }

  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == NULL) {
    "PROVENANCE_VERIFY_RC=2 reason=missing-tsv path=%s\n", argv[1];
    return 2;
  }

  I64 line_no = 0;
  I64 rows_checked = 0;
  I64 rows_failed = 0;
  I64 i = 0;

  while (i < fsz) {
    while (i < fsz && (ftxt[i] == '\n' || ftxt[i] == '\r')) i = i + 1;
    if (i >= fsz) break;

    U8 line[LINE_CAP];
    I64 j = 0;
    while (i < fsz && ftxt[i] != '\n' && ftxt[i] != '\r' && j < LINE_CAP - 1) {
      line[j] = ftxt[i];
      j = j + 1;
      i = i + 1;
    }
    line[j] = 0;
    line_no = line_no + 1;
    if (line_no == 1) continue;
    if (j == 0) continue;

    rows_checked = rows_checked + 1;
    "PROVENANCE_ROW_BEGIN line=%d\n", line_no;

    U8 *fields[13];
    I64 fld = 0;
    U8 *p = line;
    fields[0] = p;
    fld = 1;
    while (*p && fld < 13) {
      if (*p == '\t') {
        *p = 0;
        p = p + 1;
        fields[fld] = p;
        fld = fld + 1;
      } else {
        p = p + 1;
      }
    }
    if (fld != 13) {
      "PROVENANCE_ROW_FAIL line=%d reason=field-count\n", line_no;
      rows_failed = rows_failed + 1;
      "PROVENANCE_ROW_END\n";
      continue;
    }

    U8 *gen          = fields[0];
    U8 *compiler_path= fields[1];
    U8 *compiler_sha = fields[2];
    U8 *source_path  = fields[3];
    U8 *source_sha   = fields[4];
    U8 *cmd_line     = fields[5];
    U8 *cmd_sha      = fields[6];
    U8 *object_path  = fields[7];
    U8 *object_sha   = fields[8];
    U8 *object_size  = fields[9];
    U8 *fresh_path   = fields[10];
    U8 *fresh_sha    = fields[11];

    // Generation label whitelist. The fixpoint theorem assumes exactly
    // four generation labels: G0, G1, G2, G3 (bound to the four
    // canonical compilers). A row whose generation label is NOT in
    // this set is rejected (this is the minimum check that catches a
    // generation-copy forgery whose label was rewritten to indicate
    // its provenance).
    I64 ok = 1;
    I64 gen_ok = (StrCmp(gen, "G0") == 0) ||
                 (StrCmp(gen, "G1") == 0) ||
                 (StrCmp(gen, "G2") == 0) ||
                 (StrCmp(gen, "G3") == 0);
    if (!gen_ok) {
      "PROVENANCE_FIELD_MISMATCH label=generation expected=G0|G1|G2|G3 actual=%s\n",
        gen;
      ok = 0;
    }

    U8 actual_compiler_sha[65];
    U8 actual_source_sha[65];
    U8 actual_object_sha[65];
    U8 actual_fresh_sha[65];
    U8 actual_cmd_sha[65];

    if (!GetFileSHA256(compiler_path, actual_compiler_sha)) {
      "PROVENANCE_FIELD_ERROR label=compiler_sha reason=sha256-error path=%s\n", compiler_path;
      ok = 0;
    }
    if (!GetFileSHA256(source_path, actual_source_sha)) {
      "PROVENANCE_FIELD_ERROR label=source_sha reason=sha256-error path=%s\n", source_path;
      ok = 0;
    }
    if (!GetFileSHA256(object_path, actual_object_sha)) {
      "PROVENANCE_FIELD_ERROR label=object_sha reason=sha256-error path=%s\n", object_path;
      ok = 0;
    }
    if (!GetFileSHA256(fresh_path, actual_fresh_sha)) {
      "PROVENANCE_FIELD_ERROR label=fresh_sha reason=sha256-error path=%s\n", fresh_path;
      ok = 0;
    }
    if (!GetStringSHA256(cmd_line, actual_cmd_sha)) {
      "PROVENANCE_FIELD_ERROR label=command_sha reason=sha256-error cmd=%s\n", cmd_line;
      ok = 0;
    }

    EmitField("compiler_sha", compiler_sha, actual_compiler_sha,
              StrCmp(compiler_sha, actual_compiler_sha) == 0);
    EmitField("source_sha",   source_sha,   actual_source_sha,
              StrCmp(source_sha,   actual_source_sha)   == 0);
    EmitField("object_sha",   object_sha,   actual_object_sha,
              StrCmp(object_sha,   actual_object_sha)   == 0);
    EmitField("fresh_sha",    fresh_sha,    actual_fresh_sha,
              StrCmp(fresh_sha,    actual_fresh_sha)    == 0);
    EmitField("command_sha",  cmd_sha,      actual_cmd_sha,
              StrCmp(cmd_sha,      actual_cmd_sha)      == 0);

    if (StrCmp(compiler_sha, actual_compiler_sha) != 0) ok = 0;
    if (StrCmp(source_sha,   actual_source_sha)   != 0) ok = 0;
    if (StrCmp(object_sha,   actual_object_sha)   != 0) ok = 0;
    if (StrCmp(fresh_sha,    actual_fresh_sha)    != 0) ok = 0;
    if (StrCmp(cmd_sha,      actual_cmd_sha)      != 0) ok = 0;

    "PROVENANCE_OBJECT_SIZE recorded=%s\n",
      object_size;

    if (ok) {
      "PROVENANCE_ROW_PASS line=%d generation=%s\n", line_no, gen;
    } else {
      "PROVENANCE_ROW_FAIL line=%d generation=%s\n", line_no, gen;
      rows_failed = rows_failed + 1;
    }
    "PROVENANCE_ROW_END\n";
  }

  Free(ftxt);

  "PROVENANCE_VERIFY_ROWS_CHECKED=%d\n", rows_checked;
  "PROVENANCE_VERIFY_ROWS_FAILED=%d\n", rows_failed;
  if (rows_failed == 0) {
    "PROVENANCE_VERIFY_STATUS=PASS\n";
    return 0;
  }
  "PROVENANCE_VERIFY_STATUS=FAIL\n";
  return 1;
}
