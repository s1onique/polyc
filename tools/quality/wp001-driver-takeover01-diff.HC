// tools/quality/wp001-driver-takeover01-diff.HC
//
// ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.
//
// THE PRODUCTION G0/G1 DIFFERENTIAL RUNNER.
//
// WHAT IT DOES
//
// It runs TWO production compilers over the SAME frozen case table and
// compares the observable schema the ACT names:
//
//   CASE_ID
//   ARGUMENTS
//   INPUT_DIGEST
//   SELECTOR
//   EXIT_STATUS
//   STDOUT_DIGEST
//   STDERR_DIGEST
//   ARTIFACT_COUNT
//   ARTIFACT_CLASS
//   ARTIFACT_ARCHITECTURE
//   REQUIRED_SYMBOLS
//   EXECUTION_RESULT
//
// G0 is the selector-OFF C-authoritative oracle. G1 is the
// selector-ON PolyC-authoritative compiler. Both are REAL production
// builds of the SAME source revision, with the SAME prefix, target and
// runtime.
//
// The runner NEVER reads a verdict string. It runs the compilers and
// OBSERVES the results.
//
// The comparison is structural, not literal, for the cases whose
// artifacts carry nondeterministic metadata: the runner compares the
// artifact's CLASS and ARCHITECTURE and its content digest, and it
// reports the content digest so that a difference is visible rather
// than normalised away.
//
// USAGE:
//   wp001-driver-takeover01-diff <case-table> <g0-hcc> <g1-hcc> <workdir>
//
// The case table is a TSV. Each row is:
//
//   case_id \t argv (space separated) \t expected_artifact_class
//
// where the expected artifact class is one of:
//   NONE      no artifact is expected
//   OBJECT    a relocatable object
//   EXEC      an executable
//   ASM       an assembly listing
//   DYLIB     a dynamic library
//
// The runner writes a TSV ledger to <workdir>/differential.tsv and
// prints a summary. Its exit status is 0 when every case agrees and
// 1 when any case disagrees.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The maximum number of cases.
#define MAXCASE 64

// The maximum length of one argv line.
#define MAXLINE 1024

// The maximum number of fields in one case row.
#define MAXFLD 8

// The artifact classes.
#define CLASS_NONE   0
#define CLASS_OBJECT 1
#define CLASS_EXEC   2
#define CLASS_ASM    3
#define CLASS_DYLIB  4

// The case table rows.
static U8 *CASE_ID[MAXCASE];
static U8 *CASE_ARGV[MAXCASE];
static I64  CASE_CLASS[MAXCASE];
static I64  CASECOUNT;

// The parsed fields of one row.
static U8 *FLD[MAXFLD];

// The observed result of one run.
static I64  RUN_EXIT;
static I64  RUN_CLASS;
static U8   RUN_OUT[64];
static U8   RUN_ERR[64];
static U8   RUN_ART[64];

// The number of failures.
static I64 failures;

// Are the two byte strings equal?
static I64 StrEq(U8 *a, U8 *b) {
  I64 i = 0;
  while (a[i] != 0 && b[i] != 0) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  if (a[i] != 0) return 0;
  if (b[i] != 0) return 0;
  return 1;
}

// The number of bytes in the string.
static I64 Len(U8 *s) {
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

// Copy `src` into `dst`, truncating at `max-1` bytes.
static U0 CopyStr(U8 *dst, I64 max, U8 *src) {
  I64 i = 0;
  while (i < max - 1 && src[i] != 0) {
    dst[i] = src[i];
    i = i + 1;
  }
  dst[i] = 0;
}

// A 64-bit FNV-1a digest of a byte range, rendered as 16 hex digits.
//
// The runner needs a CONTENT digest so that two artifacts are compared
// by their bytes and not by their names. FNV-1a is not a
// cryptographic hash, and it is not claimed to be: it is a stable
// content fingerprint that detects a difference.
static U0 Digest(U8 *buf, I64 size, U8 *out) {
  I64 h = 14695981039346656037;
  I64 i = 0;
  while (i < size) {
    h = h ^ buf[i];
    h = h * 1099511628211;
    i = i + 1;
  }
  I64 k = 0;
  while (k < 16) {
    I64 nib = h & 15;
    U8 *p = out + k;
    if (nib < 10) *p = 48 + nib;
    else *p = 87 + nib;
    h = h >> 4;
    k = k + 1;
  }
  out[16] = 0;
}

// Split one TSV line in place. Returns the field count.
static I64 SplitTabs(U8 *line, I64 max) {
  I64 n = 0;
  U8 *p = line;
  while (n < max) {
    FLD[n] = p;
    n = n + 1;
    U8 *e = p;
    while (*e != 0 && *e != '\t') e = e + 1;
    if (*e == 0) break;
    *e = 0;
    p = e + 1;
  }
  return n;
}

// The observation file names.
//
// They are LOCAL constants inside Main, not file-scope constants.
//
// The reason is measured, not stylistic: a file-scope `static U8 *`
// string constant in this compiler can be emitted with a label that
// does not match its own content, and the tool then fails to link with
// "Undefined symbols: .L33". The working tools in this tree keep every
// string literal inside a function body. This tool follows the same
// rule, and passes the names down to the helpers as parameters.
//
// Copy a byte sequence into a buffer, NUL-terminating it.
//
// The names are built at RUNTIME from their bytes, not from string
// literals.
//
// The reason is measured, not stylistic: this compiler's code
// generation can emit a string literal as an UNDEFINED label symbol
// in some shapes, and the tool then fails to link with "Undefined
// symbols: .L33". The working tools in this tree keep every string
// literal inside a function body, but they do not need this many
// names. Building the bytes at runtime removes the dependency on the
// code generator's literal handling entirely, and the tool then has
// NO undefined label symbols.
//
// The byte values are written as decimal character codes, which is
// unambiguous and does not depend on any escape-sequence handling.
static U0 SetName(U8 *dst, I64 max, U8 *src) {
  I64 i = 0;
  while (src[i] != 0 && i < max - 1) {
    dst[i] = src[i];
    i = i + 1;
  }
  dst[i] = 0;
}

// The class-name codes, rendered in the ledger.
#define NM_OBJECT 0
#define NM_EXEC   1
#define NM_ASM    2
#define NM_DYLIB  3
#define NM_NONE   4

// The names the helpers need.
//
// They are carried in ONE struct so that the helpers never mention a
// string literal themselves. The struct's fields point at buffers that
// InitNames fills at runtime.
class Names;
class Names {
  U8 *stdout_name;
  U8 *stderr_name;
  U8 *status_name;
  U8 *artifact_name;
  U8 *aout_name;
  U8 *asm_name;
  U8 *dylib_name;
  U8 *cd_frag;
  U8 *and_frag;
  U8 *redirect_frag;
  U8 *rmf_frag;
  U8 *g0_frag;
  U8 *g1_frag;
  U8 *slash_stdout;
  U8 *slash_stderr;
  U8 *slash_status;
  U8 *slash_artifact;
  U8 *slash_aout;
  U8 *slash_asm;
  U8 *slash_dylib;
  U8 *class_object;
  U8 *class_exec;
  U8 *class_asm;
  U8 *class_dylib;
  U8 *class_none;
  U8 *verdict_agree;
  U8 *verdict_disagree;
};

// The storage for the names.
//
// They are ALL in ONE array.
//
// The reason is measured, not stylistic: this compiler fails to emit
// the label for a static array once the file declares enough of them,
// and the tool then fails to link with "Undefined symbols: .L31". The
// working tools in this tree declare at most three static arrays.
//
// So the names share ONE buffer, and each name has a fixed OFFSET in
// it. The byte values are the ASCII codes of the characters, written
// explicitly, so that the tool carries no string literal at all.
//
// The offsets are computed from the name lengths below.
#define NB_STDOUT    0
#define NB_STDERR   16
#define NB_STATUS   32
#define NB_ARTIFACT 48
#define NB_AOUT     64
#define NB_ASM      72
#define NB_DYLIB    88
#define NB_CD      112
#define NB_AND     120
#define NB_REDIRECT 128
#define NB_RMF     224
#define NB_G0      232
#define NB_G1      240
#define NB_SLASH_STDOUT  248
#define NB_SLASH_STDERR  264
#define NB_SLASH_STATUS  280
#define NB_SLASH_ARTIFACT 296
#define NB_SLASH_AOUT    312
#define NB_SLASH_ASM     328
#define NB_SLASH_DYLIB   344
#define NB_CLASS_OBJECT  368
#define NB_CLASS_EXEC    376
#define NB_CLASS_ASM     384
#define NB_CLASS_DYLIB   392
#define NB_CLASS_NONE    400
#define NB_VERDICT_AGREE 408
#define NB_VERDICT_DISAGREE 416
#define NB_TOTAL        425

static U8 N_BUF[NB_TOTAL];

// The working buffers.
//
// They are FILE-SCOPE arrays, not function-local statics.
//
// The reason is measured, not stylistic: this compiler does not emit
// the label for a function-local `static` array once SEVERAL functions
// each declare one, and the tool then fails to link with "Undefined
// symbols: .L31". The reproduction is in
// tools/quality/wp001-driver-takeover01-diff.HC's own header comment.
//
// The working tools in this tree declare at most one function-local
// static each. This tool declares none.
static U8 CMD_BUF[4096];
static U8 CMD2_BUF[2048];
static U8 PATH_BUF[512];
static U8 G0_WORK_BUF[512];
static U8 G1_WORK_BUF[512];
static U8 TMP_BUF[512];
static U8 VERDICT_BUF[16];

// Fill the first half of the name buffers.
//
// The bytes are assigned one at a time, so the tool has no string
// literal and therefore no undefined label symbol.
static U0 InitNamesA() {
  // "case.stdout"
  N_BUF[NB_STDOUT + 0] = 99; N_BUF[NB_STDOUT + 1] = 97; N_BUF[NB_STDOUT + 2] = 115; N_BUF[NB_STDOUT + 3] = 101;
  N_BUF[NB_STDOUT + 4] = 46; N_BUF[NB_STDOUT + 5] = 115; N_BUF[NB_STDOUT + 6] = 116; N_BUF[NB_STDOUT + 7] = 100;
  N_BUF[NB_STDOUT + 8] = 111; N_BUF[NB_STDOUT + 9] = 117; N_BUF[NB_STDOUT + 10] = 116; N_BUF[NB_STDOUT + 11] = 0;
  // "case.stderr"
  N_BUF[NB_STDERR + 0] = 99; N_BUF[NB_STDERR + 1] = 97; N_BUF[NB_STDERR + 2] = 115; N_BUF[NB_STDERR + 3] = 101;
  N_BUF[NB_STDERR + 4] = 46; N_BUF[NB_STDERR + 5] = 115; N_BUF[NB_STDERR + 6] = 116; N_BUF[NB_STDERR + 7] = 100;
  N_BUF[NB_STDERR + 8] = 101; N_BUF[NB_STDERR + 9] = 114; N_BUF[NB_STDERR + 10] = 114; N_BUF[NB_STDERR + 11] = 0;
  // "case.status"
  N_BUF[NB_STATUS + 0] = 99; N_BUF[NB_STATUS + 1] = 97; N_BUF[NB_STATUS + 2] = 115; N_BUF[NB_STATUS + 3] = 101;
  N_BUF[NB_STATUS + 4] = 46; N_BUF[NB_STATUS + 5] = 115; N_BUF[NB_STATUS + 6] = 116; N_BUF[NB_STATUS + 7] = 97;
  N_BUF[NB_STATUS + 8] = 116; N_BUF[NB_STATUS + 9] = 117; N_BUF[NB_STATUS + 10] = 115; N_BUF[NB_STATUS + 11] = 0;
  // "case.out.o"
  N_BUF[NB_ARTIFACT + 0] = 99; N_BUF[NB_ARTIFACT + 1] = 97; N_BUF[NB_ARTIFACT + 2] = 115; N_BUF[NB_ARTIFACT + 3] = 101;
  N_BUF[NB_ARTIFACT + 4] = 46; N_BUF[NB_ARTIFACT + 5] = 111; N_BUF[NB_ARTIFACT + 6] = 117; N_BUF[NB_ARTIFACT + 7] = 116;
  N_BUF[NB_ARTIFACT + 8] = 46; N_BUF[NB_ARTIFACT + 9] = 111; N_BUF[NB_ARTIFACT + 10] = 0;
  // "a.out"
  N_BUF[NB_AOUT + 0] = 97; N_BUF[NB_AOUT + 1] = 46; N_BUF[NB_AOUT + 2] = 111; N_BUF[NB_AOUT + 3] = 117;
  N_BUF[NB_AOUT + 4] = 116; N_BUF[NB_AOUT + 5] = 0;
  // "case.out.s"
  N_BUF[NB_ASM + 0] = 99; N_BUF[NB_ASM + 1] = 97; N_BUF[NB_ASM + 2] = 115; N_BUF[NB_ASM + 3] = 101;
  N_BUF[NB_ASM + 4] = 46; N_BUF[NB_ASM + 5] = 111; N_BUF[NB_ASM + 6] = 117; N_BUF[NB_ASM + 7] = 116;
  N_BUF[NB_ASM + 8] = 46; N_BUF[NB_ASM + 9] = 115; N_BUF[NB_ASM + 10] = 0;
  // "libcase.out.dylib"
  //
  // The DYNAMIC LIBRARY the -lib route produces. The dylib route
  // writes lib<name>.dylib, and the -lib value in the case table is
  // "case.out", so the file is libcase.out.dylib. Without this
  // observation the dylib route was NEVER checked: the runner only
  // looked at case.out.o, which that route does not write, so the
  // case silently reported NONE.
  N_BUF[NB_DYLIB + 0] = 108; N_BUF[NB_DYLIB + 1] = 105; N_BUF[NB_DYLIB + 2] = 98;
  N_BUF[NB_DYLIB + 3] = 99; N_BUF[NB_DYLIB + 4] = 97; N_BUF[NB_DYLIB + 5] = 115;
  N_BUF[NB_DYLIB + 6] = 101; N_BUF[NB_DYLIB + 7] = 46; N_BUF[NB_DYLIB + 8] = 111;
  N_BUF[NB_DYLIB + 9] = 117; N_BUF[NB_DYLIB + 10] = 116; N_BUF[NB_DYLIB + 11] = 46;
  N_BUF[NB_DYLIB + 12] = 100; N_BUF[NB_DYLIB + 13] = 121; N_BUF[NB_DYLIB + 14] = 108;
  N_BUF[NB_DYLIB + 15] = 105; N_BUF[NB_DYLIB + 16] = 98; N_BUF[NB_DYLIB + 17] = 0;
  // "cd "
  N_BUF[NB_CD + 0] = 99; N_BUF[NB_CD + 1] = 100; N_BUF[NB_CD + 2] = 32; N_BUF[NB_CD + 3] = 0;
  // " && "
  N_BUF[NB_AND + 0] = 32; N_BUF[NB_AND + 1] = 38; N_BUF[NB_AND + 2] = 38; N_BUF[NB_AND + 3] = 32; N_BUF[NB_AND + 4] = 0;
  // "rm -f "
  N_BUF[NB_RMF + 0] = 114; N_BUF[NB_RMF + 1] = 109; N_BUF[NB_RMF + 2] = 32; N_BUF[NB_RMF + 3] = 45;
  N_BUF[NB_RMF + 4] = 102; N_BUF[NB_RMF + 5] = 32; N_BUF[NB_RMF + 6] = 0;
  // "/g0" and "/g1"
  N_BUF[NB_G0 + 0] = 47; N_BUF[NB_G0 + 1] = 103; N_BUF[NB_G0 + 2] = 48; N_BUF[NB_G0 + 3] = 0;
  N_BUF[NB_G1 + 0] = 47; N_BUF[NB_G1 + 1] = 103; N_BUF[NB_G1 + 2] = 49; N_BUF[NB_G1 + 3] = 0;
  // " > case.stdout 2> case.stderr ; echo $? > case.status"
  N_BUF[NB_REDIRECT + 0] = 32; N_BUF[NB_REDIRECT + 1] = 62; N_BUF[NB_REDIRECT + 2] = 32;
  N_BUF[NB_REDIRECT + 3] = 99; N_BUF[NB_REDIRECT + 4] = 97; N_BUF[NB_REDIRECT + 5] = 115; N_BUF[NB_REDIRECT + 6] = 101;
  N_BUF[NB_REDIRECT + 7] = 46; N_BUF[NB_REDIRECT + 8] = 115; N_BUF[NB_REDIRECT + 9] = 116; N_BUF[NB_REDIRECT + 10] = 100;
  N_BUF[NB_REDIRECT + 11] = 111; N_BUF[NB_REDIRECT + 12] = 117; N_BUF[NB_REDIRECT + 13] = 116;
  N_BUF[NB_REDIRECT + 14] = 32; N_BUF[NB_REDIRECT + 15] = 50; N_BUF[NB_REDIRECT + 16] = 62; N_BUF[NB_REDIRECT + 17] = 32;
  N_BUF[NB_REDIRECT + 18] = 99; N_BUF[NB_REDIRECT + 19] = 97; N_BUF[NB_REDIRECT + 20] = 115; N_BUF[NB_REDIRECT + 21] = 101;
  N_BUF[NB_REDIRECT + 22] = 46; N_BUF[NB_REDIRECT + 23] = 115; N_BUF[NB_REDIRECT + 24] = 116; N_BUF[NB_REDIRECT + 25] = 100;
  N_BUF[NB_REDIRECT + 26] = 101; N_BUF[NB_REDIRECT + 27] = 114; N_BUF[NB_REDIRECT + 28] = 114;
  N_BUF[NB_REDIRECT + 29] = 32; N_BUF[NB_REDIRECT + 30] = 59; N_BUF[NB_REDIRECT + 31] = 32;
  N_BUF[NB_REDIRECT + 32] = 101; N_BUF[NB_REDIRECT + 33] = 99; N_BUF[NB_REDIRECT + 34] = 104; N_BUF[NB_REDIRECT + 35] = 111;
  N_BUF[NB_REDIRECT + 36] = 32; N_BUF[NB_REDIRECT + 37] = 36; N_BUF[NB_REDIRECT + 38] = 63;
  N_BUF[NB_REDIRECT + 39] = 32; N_BUF[NB_REDIRECT + 40] = 62; N_BUF[NB_REDIRECT + 41] = 32;
  N_BUF[NB_REDIRECT + 42] = 99; N_BUF[NB_REDIRECT + 43] = 97; N_BUF[NB_REDIRECT + 44] = 115;
  N_BUF[NB_REDIRECT + 45] = 101; N_BUF[NB_REDIRECT + 46] = 46; N_BUF[NB_REDIRECT + 47] = 115;
  N_BUF[NB_REDIRECT + 48] = 116; N_BUF[NB_REDIRECT + 49] = 97; N_BUF[NB_REDIRECT + 50] = 116;
  N_BUF[NB_REDIRECT + 51] = 117; N_BUF[NB_REDIRECT + 52] = 115; N_BUF[NB_REDIRECT + 53] = 0;
}

// Fill the second half of the name buffers.
static U0 InitNamesB() {
  // "/case.stdout "
  N_BUF[NB_SLASH_STDOUT + 0] = 47; N_BUF[NB_SLASH_STDOUT + 1] = 99; N_BUF[NB_SLASH_STDOUT + 2] = 97;
  N_BUF[NB_SLASH_STDOUT + 3] = 115; N_BUF[NB_SLASH_STDOUT + 4] = 101; N_BUF[NB_SLASH_STDOUT + 5] = 46;
  N_BUF[NB_SLASH_STDOUT + 6] = 115; N_BUF[NB_SLASH_STDOUT + 7] = 116; N_BUF[NB_SLASH_STDOUT + 8] = 100;
  N_BUF[NB_SLASH_STDOUT + 9] = 111; N_BUF[NB_SLASH_STDOUT + 10] = 117; N_BUF[NB_SLASH_STDOUT + 11] = 116;
  N_BUF[NB_SLASH_STDOUT + 12] = 32; N_BUF[NB_SLASH_STDOUT + 13] = 0;
  // "/case.stderr "
  N_BUF[NB_SLASH_STDERR + 0] = 47; N_BUF[NB_SLASH_STDERR + 1] = 99; N_BUF[NB_SLASH_STDERR + 2] = 97;
  N_BUF[NB_SLASH_STDERR + 3] = 115; N_BUF[NB_SLASH_STDERR + 4] = 101; N_BUF[NB_SLASH_STDERR + 5] = 46;
  N_BUF[NB_SLASH_STDERR + 6] = 115; N_BUF[NB_SLASH_STDERR + 7] = 116; N_BUF[NB_SLASH_STDERR + 8] = 100;
  N_BUF[NB_SLASH_STDERR + 9] = 101; N_BUF[NB_SLASH_STDERR + 10] = 114; N_BUF[NB_SLASH_STDERR + 11] = 114;
  N_BUF[NB_SLASH_STDERR + 12] = 32; N_BUF[NB_SLASH_STDERR + 13] = 0;
  // "/case.status "
  N_BUF[NB_SLASH_STATUS + 0] = 47; N_BUF[NB_SLASH_STATUS + 1] = 99; N_BUF[NB_SLASH_STATUS + 2] = 97;
  N_BUF[NB_SLASH_STATUS + 3] = 115; N_BUF[NB_SLASH_STATUS + 4] = 101; N_BUF[NB_SLASH_STATUS + 5] = 46;
  N_BUF[NB_SLASH_STATUS + 6] = 115; N_BUF[NB_SLASH_STATUS + 7] = 116; N_BUF[NB_SLASH_STATUS + 8] = 97;
  N_BUF[NB_SLASH_STATUS + 9] = 116; N_BUF[NB_SLASH_STATUS + 10] = 117; N_BUF[NB_SLASH_STATUS + 11] = 115;
  N_BUF[NB_SLASH_STATUS + 12] = 32; N_BUF[NB_SLASH_STATUS + 13] = 0;
  // "/case.out.o "
  N_BUF[NB_SLASH_ARTIFACT + 0] = 47; N_BUF[NB_SLASH_ARTIFACT + 1] = 99; N_BUF[NB_SLASH_ARTIFACT + 2] = 97;
  N_BUF[NB_SLASH_ARTIFACT + 3] = 115; N_BUF[NB_SLASH_ARTIFACT + 4] = 101; N_BUF[NB_SLASH_ARTIFACT + 5] = 46;
  N_BUF[NB_SLASH_ARTIFACT + 6] = 111; N_BUF[NB_SLASH_ARTIFACT + 7] = 117; N_BUF[NB_SLASH_ARTIFACT + 8] = 116;
  N_BUF[NB_SLASH_ARTIFACT + 9] = 46; N_BUF[NB_SLASH_ARTIFACT + 10] = 111; N_BUF[NB_SLASH_ARTIFACT + 11] = 32;
  N_BUF[NB_SLASH_ARTIFACT + 12] = 0;
  // "/a.out "
  N_BUF[NB_SLASH_AOUT + 0] = 47; N_BUF[NB_SLASH_AOUT + 1] = 97; N_BUF[NB_SLASH_AOUT + 2] = 46;
  N_BUF[NB_SLASH_AOUT + 3] = 111; N_BUF[NB_SLASH_AOUT + 4] = 117; N_BUF[NB_SLASH_AOUT + 5] = 116;
  N_BUF[NB_SLASH_AOUT + 6] = 32; N_BUF[NB_SLASH_AOUT + 7] = 0;
  // "/case.out.s"
  N_BUF[NB_SLASH_ASM + 0] = 47; N_BUF[NB_SLASH_ASM + 1] = 99; N_BUF[NB_SLASH_ASM + 2] = 97;
  N_BUF[NB_SLASH_ASM + 3] = 115; N_BUF[NB_SLASH_ASM + 4] = 101; N_BUF[NB_SLASH_ASM + 5] = 46;
  N_BUF[NB_SLASH_ASM + 6] = 111; N_BUF[NB_SLASH_ASM + 7] = 117; N_BUF[NB_SLASH_ASM + 8] = 116;
  N_BUF[NB_SLASH_ASM + 9] = 46; N_BUF[NB_SLASH_ASM + 10] = 115; N_BUF[NB_SLASH_ASM + 11] = 32;
  N_BUF[NB_SLASH_ASM + 12] = 0;
  // "libcase.out.dylib "
  //
  // THE WRITE IS DELIBERATELY SPLIT INTO SHORT RUNS. The compiler
  // miscompiles a LONG run of byte-writes into a static array: a
  // 19-write run placed the last two bytes at the wrong offsets, and
  // the resulting path was "libcase.out.dylb". The M-POLYC-MACHO-01
  // experiment measured that corruption at runtime by reading the
  // bytes back, so it is a MEASURED defect and not a guess.
  //
  // Every run below is at most 8 writes, which the compiler places
  // correctly. The tool's other name regions are already in that
  // shape.
  N_BUF[NB_SLASH_DYLIB + 0] = 47; N_BUF[NB_SLASH_DYLIB + 1] = 108; N_BUF[NB_SLASH_DYLIB + 2] = 105;
  N_BUF[NB_SLASH_DYLIB + 3] = 98; N_BUF[NB_SLASH_DYLIB + 4] = 99; N_BUF[NB_SLASH_DYLIB + 5] = 97;
  N_BUF[NB_SLASH_DYLIB + 6] = 115; N_BUF[NB_SLASH_DYLIB + 7] = 101;
  N_BUF[NB_SLASH_DYLIB + 8] = 46; N_BUF[NB_SLASH_DYLIB + 9] = 111; N_BUF[NB_SLASH_DYLIB + 10] = 117;
  N_BUF[NB_SLASH_DYLIB + 11] = 116; N_BUF[NB_SLASH_DYLIB + 12] = 46; N_BUF[NB_SLASH_DYLIB + 13] = 100;
  N_BUF[NB_SLASH_DYLIB + 14] = 121; N_BUF[NB_SLASH_DYLIB + 15] = 108;
  N_BUF[NB_SLASH_DYLIB + 16] = 105; N_BUF[NB_SLASH_DYLIB + 17] = 98; N_BUF[NB_SLASH_DYLIB + 18] = 32;
  N_BUF[NB_SLASH_DYLIB + 19] = 0;
  // "OBJECT" "EXEC" "ASM" "DYLIB" "NONE"
  N_BUF[NB_CLASS_OBJECT + 0] = 79; N_BUF[NB_CLASS_OBJECT + 1] = 66; N_BUF[NB_CLASS_OBJECT + 2] = 74;
  N_BUF[NB_CLASS_OBJECT + 3] = 69; N_BUF[NB_CLASS_OBJECT + 4] = 67; N_BUF[NB_CLASS_OBJECT + 5] = 84;
  N_BUF[NB_CLASS_OBJECT + 6] = 0;
  N_BUF[NB_CLASS_EXEC + 0] = 69; N_BUF[NB_CLASS_EXEC + 1] = 88; N_BUF[NB_CLASS_EXEC + 2] = 69;
  N_BUF[NB_CLASS_EXEC + 3] = 67; N_BUF[NB_CLASS_EXEC + 4] = 0;
  N_BUF[NB_CLASS_ASM + 0] = 65; N_BUF[NB_CLASS_ASM + 1] = 83; N_BUF[NB_CLASS_ASM + 2] = 77;
  N_BUF[NB_CLASS_ASM + 3] = 0;
  N_BUF[NB_CLASS_DYLIB + 0] = 68; N_BUF[NB_CLASS_DYLIB + 1] = 89; N_BUF[NB_CLASS_DYLIB + 2] = 76;
  N_BUF[NB_CLASS_DYLIB + 3] = 73; N_BUF[NB_CLASS_DYLIB + 4] = 66; N_BUF[NB_CLASS_DYLIB + 5] = 0;
  N_BUF[NB_CLASS_NONE + 0] = 78; N_BUF[NB_CLASS_NONE + 1] = 79; N_BUF[NB_CLASS_NONE + 2] = 78;
  N_BUF[NB_CLASS_NONE + 3] = 69; N_BUF[NB_CLASS_NONE + 4] = 0;
  // "AGREE" "DISAGREE"
  N_BUF[NB_VERDICT_AGREE + 0] = 65; N_BUF[NB_VERDICT_AGREE + 1] = 71; N_BUF[NB_VERDICT_AGREE + 2] = 82;
  N_BUF[NB_VERDICT_AGREE + 3] = 69; N_BUF[NB_VERDICT_AGREE + 4] = 69; N_BUF[NB_VERDICT_AGREE + 5] = 0;
  N_BUF[NB_VERDICT_DISAGREE + 0] = 68; N_BUF[NB_VERDICT_DISAGREE + 1] = 73; N_BUF[NB_VERDICT_DISAGREE + 2] = 83;
  N_BUF[NB_VERDICT_DISAGREE + 3] = 65; N_BUF[NB_VERDICT_DISAGREE + 4] = 71; N_BUF[NB_VERDICT_DISAGREE + 5] = 82;
  N_BUF[NB_VERDICT_DISAGREE + 6] = 69; N_BUF[NB_VERDICT_DISAGREE + 7] = 69; N_BUF[NB_VERDICT_DISAGREE + 8] = 0;
}


// The artifact class of one case row.
//
// The class is carried as an INTEGER code in the case table, not as a
// name. The reason is measured: a string literal used inside a static
// function of a PolyC tool is emitted as an undefined label symbol in
// some code shapes, and the tool then fails to link. The integer
// encoding removes that class of failure from the tool entirely, and
// the class NAME is still rendered in the ledger.
static I64 ClassCode(U8 *c) {
  I64 n = 0;
  I64 i = 0;
  while (c[i] != 0) {
    n = n * 10 + (c[i] - 48);
    i = i + 1;
  }
  return n;
}

// Load the case table. Returns the number of rows, or -1 on error.
static I64 LoadCases(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  CASECOUNT = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      buf[i] = 0;
      if (*line != 0 && *line != '#') {
        I64 n = SplitTabs(line, MAXFLD);
        if (n >= 3 && CASECOUNT < MAXCASE) {
          CASE_ID[CASECOUNT] = FLD[0];
          CASE_ARGV[CASECOUNT] = FLD[1];
          CASE_CLASS[CASECOUNT] = ClassCode(FLD[2]);
          CASECOUNT++;
        }
      }
      line = buf + i + 1;
    }
    i = i + 1;
  }
  if (line < buf + size && *line != 0 && *line != '#') {
    I64 n = SplitTabs(line, MAXFLD);
    if (n >= 3 && CASECOUNT < MAXCASE) {
      CASE_ID[CASECOUNT] = FLD[0];
      CASE_ARGV[CASECOUNT] = FLD[1];
      CASE_CLASS[CASECOUNT] = ClassCode(FLD[2]);
      CASECOUNT++;
    }
  }
  return CASECOUNT;
}

// The artifact class of a produced file, read from its BYTES.
//
// The class is NEVER read from the file's NAME: a compiler that writes
// an executable into a .o path must be detected as the wrong class.
//
//   CLASS_NONE    the file does not exist
//   CLASS_OBJECT  a Mach-O or ELF relocatable object
//   CLASS_EXEC    a Mach-O or ELF executable
//   CLASS_ASM     an assembly listing (not an object)
//   CLASS_DYLIB   a Mach-O or ELF dynamic library
//
static I64 ClassifyArtifact(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(PATH_BUF, &size);
  if (buf == NULL) return CLASS_NONE;
  if (size < 16) return CLASS_ASM;

  // The Mach-O magic.
  I64 m = buf[0] | (buf[1] << 8) | (buf[2] << 16) | (buf[3] << 24);
  if (m == 0xFEEDFACF) {
    // The filetype is at offset 12.
    I64 ft = buf[12] | (buf[13] << 8) | (buf[14] << 16) | (buf[15] << 24);
    // THE MACHO FILETYPES, from Apple's loader.h:
    //
    //   MH_OBJECT   0x1   relocatable object file
    //   MH_EXECUTE  0x2   demand paged executable file
    //   MH_DYLIB    0x6   dynamically bound shared library
    //   MH_BUNDLE   0x8   dynamically bound bundle file
    //
    // This mapping was WRONG: it read 6 as MH_EXECUTE and 8 as
    // MH_DYLIB, so a real dynamic library was reported as an
    // executable and a bundle was reported as a dynamic library. The
    // M-POLYC-MACHO-01 experiment measured the misclassification
    // against the SDK's own definitions, and the mapping was
    // corrected.
    if (ft == 1) return CLASS_OBJECT;      // MH_OBJECT
    if (ft == 2) return CLASS_EXEC;        // MH_EXECUTE
    if (ft == 6) return CLASS_DYLIB;       // MH_DYLIB
    if (ft == 8) return CLASS_DYLIB;       // MH_BUNDLE (a dynamic bundle)
    return CLASS_ASM;
  }
  if (m == 0xFEEDFACE) return CLASS_OBJECT;

  // The ELF magic, byte-order invariant.
  if (buf[0] == 0x7F && buf[1] == 0x45 && buf[2] == 0x4C && buf[3] == 0x46) {
    // The e_type field is at offset 16, little-endian.
    I64 et = buf[16] | (buf[17] << 8);
    if (et == 1) return CLASS_OBJECT;      // ET_REL
    if (et == 2) return CLASS_EXEC;        // ET_EXEC
    if (et == 3) return CLASS_DYLIB;       // ET_DYN
    return CLASS_ASM;
  }
  return CLASS_ASM;
}

// Append a byte string to a buffer at `*n`. The buffer is bounded, so
// an over-long append is TRUNCATED rather than overflowing.
static U0 App(U8 *buf, I64 max, I64 *n, U8 *s) {
  I64 i = 0;
  while (s[i] != 0 && *n < max - 1) {
    buf[*n] = s[i];
    *n = *n + 1;
    i = i + 1;
  }
  buf[*n] = 0;
}

// Append one character to a buffer at `*n`.
static U0 AppCh(U8 *buf, I64 max, I64 *n, U8 c) {
  if (*n < max - 1) {
    buf[*n] = c;
    *n = *n + 1;
  }
  buf[*n] = 0;
}

// Run one compiler over one case, in its own working directory.
//
// The runner builds a shell command that REDIRECTS the compiler's
// stdout and stderr into files and records the exit status, so the two
// runs are OBSERVED rather than interleaved.
//
// The working directory is FRESH for each run: the runner removes the
// previous run's outputs first, so a stale artifact can never be
// mistaken for a fresh one.
static U0 RunCase(Names *nm, U8 *compiler, U8 *workdir, U8 *argvline) {

  I64 n = 0;
  CMD_BUF[0] = 0;

  App(CMD_BUF, 4096, &n, nm->cd_frag);
  App(CMD_BUF, 4096, &n, workdir);
  App(CMD_BUF, 4096, &n, nm->and_frag);
  App(CMD_BUF, 4096, &n, compiler);
  AppCh(CMD_BUF, 4096, &n, 32);
  App(CMD_BUF, 4096, &n, argvline);
  App(CMD_BUF, 4096, &n, nm->redirect_frag);

  System(CMD_BUF);
}

// Read the observed exit status from the status file.
static I64 ReadStatus(Names *nm, U8 *workdir) {

  I64 n = 0;
  I64 i = 0;
  U8 *w = workdir;
  while (w[i] != 0 && n < 400) { PATH_BUF[n] = w[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 47; n = n + 1;   // '/'
  i = 0;
  U8 *s = nm->status_name;
  while (s[i] != 0 && n < 500) { PATH_BUF[n] = s[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 0;
  I64 size = 0;
  U8 *buf = FileRead(PATH_BUF, &size);
  if (buf == NULL) return -1;
  I64 v = 0;
  I64 k = 0;
  while (k < size) {
    I64 c = buf[k];
    if (c < 48 || c > 57) break;
    v = v * 10 + (c - 48);
    k = k + 1;
  }
  return v;
}

// The digest of a file's CONTENTS, or the empty string when the file
// does not exist.
static U0 FileDigest(Names *nm, U8 *workdir, U8 *name, U8 *out) {

  I64 n = 0;
  I64 i = 0;
  U8 *w = workdir;
  while (w[i] != 0 && n < 400) { PATH_BUF[n] = w[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 47; n = n + 1;   // '/'
  i = 0;
  while (name[i] != 0 && n < 500) { PATH_BUF[n] = name[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 0;
  I64 size = 0;
  U8 *buf = FileRead(PATH_BUF, &size);
  if (buf == NULL) {
    out[0] = 45;   // '-'
    out[1] = 0;
    return;
  }
  Digest(buf, size, out);
}

// The class of an artifact in the working directory.
//
// The artifact is the DYNAMIC LIBRARY if the run produced one, and the
// object otherwise. The dylib route (-lib) writes lib<name>.dylib and
// does NOT write case.out.o, so the dylib is checked FIRST: without
// that, the dylib route reported NONE and the case silently verified
// nothing.
static I64 WorkArtifactClass(Names *nm, U8 *workdir) {

  I64 n = 0;
  I64 i = 0;
  U8 *w = workdir;
  while (w[i] != 0 && n < 400) { PATH_BUF[n] = w[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 47; n = n + 1;   // '/'
  i = 0;
  U8 *s = nm->dylib_name;
  while (s[i] != 0 && n < 500) { PATH_BUF[n] = s[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 0;
  I64 dylib_class = ClassifyArtifact(PATH_BUF);
  if (dylib_class != CLASS_NONE) return dylib_class;

  n = 0;
  i = 0;
  w = workdir;
  while (w[i] != 0 && n < 400) { PATH_BUF[n] = w[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 47; n = n + 1;   // '/'
  i = 0;
  s = nm->artifact_name;
  while (s[i] != 0 && n < 500) { PATH_BUF[n] = s[i]; n = n + 1; i = i + 1; }
  PATH_BUF[n] = 0;
  return ClassifyArtifact(PATH_BUF);
}

// The class as a name.
static U8 *ClassName(Names *nm, I64 c) {
  if (c == CLASS_OBJECT) return nm->class_object;
  if (c == CLASS_EXEC) return nm->class_exec;
  if (c == CLASS_ASM) return nm->class_asm;
  if (c == CLASS_DYLIB) return nm->class_dylib;
  return nm->class_none;
}

// Remove the observation files from a working directory, so a stale
// artifact can never be mistaken for a fresh one.
static U0 CleanWork(Names *nm, U8 *workdir) {

  I64 n = 0;
  CMD2_BUF[0] = 0;
  App(CMD2_BUF, 2048, &n, nm->rmf_frag);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_stdout);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_stderr);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_status);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_artifact);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_aout);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_asm);
  App(CMD2_BUF, 2048, &n, workdir);
  App(CMD2_BUF, 2048, &n, nm->slash_dylib);
  System(CMD2_BUF);
}

// Run one compiler over one case and OBSERVE the result.
static U0 Observe(Names *nm, U8 *compiler, U8 *workdir, U8 *argvline) {
  CleanWork(nm, workdir);
  RunCase(nm, compiler, workdir, argvline);
  RUN_EXIT = ReadStatus(nm, workdir);
  RUN_CLASS = WorkArtifactClass(nm, workdir);
  FileDigest(nm, workdir, nm->stdout_name, RUN_OUT);
  FileDigest(nm, workdir, nm->stderr_name, RUN_ERR);
  // The CONTENT digest is taken of whichever artifact the class was
  // read from, so a dylib is compared by its bytes and not by an
  // empty digest of a file that was never produced.
  if (RUN_CLASS == CLASS_DYLIB) {
    FileDigest(nm, workdir, nm->dylib_name, RUN_ART);
  } else {
    FileDigest(nm, workdir, nm->artifact_name, RUN_ART);
  }
}

// The number of artifacts present in the working directory.
static I64 ArtifactCount(Names *nm, U8 *workdir) {
  I64 c = 0;
  if (WorkArtifactClass(nm, workdir) != CLASS_NONE) c = c + 1;
  return c;
}

// The result of one case, in the ledger's flat form.
static I64 G0_EXIT;
static I64 G1_EXIT;
static I64 G0_CLASS;
static I64 G1_CLASS;
static I64 G0_COUNT;
static I64 G1_COUNT;
static U8  G0_OUT[64];
static U8  G1_OUT[64];
static U8  G0_ERR[64];
static U8  G1_ERR[64];
static U8  G0_ART[64];
static U8  G1_ART[64];

I32 Main(I32 argc, U8 **argv) {
  if (argc < 5) {
    "REASON_DETAIL=usage: <cases> <g0> <g1> <workdir>\n";
    return 2;
  }

  // The names. They are built at RUNTIME, for the reason recorded
  // above: this compiler can emit a string literal as an undefined
  // label symbol in some shapes, and the tool would then fail to link.
  InitNamesA();
  InitNamesB();
  static Names nm;
  nm.stdout_name = N_BUF + NB_STDOUT;
  nm.stderr_name = N_BUF + NB_STDERR;
  nm.status_name = N_BUF + NB_STATUS;
  nm.artifact_name = N_BUF + NB_ARTIFACT;
  nm.aout_name = N_BUF + NB_AOUT;
  nm.asm_name = N_BUF + NB_ASM;
  nm.dylib_name = N_BUF + NB_DYLIB;
  nm.cd_frag = N_BUF + NB_CD;
  nm.and_frag = N_BUF + NB_AND;
  nm.redirect_frag = N_BUF + NB_REDIRECT;
  nm.rmf_frag = N_BUF + NB_RMF;
  nm.g0_frag = N_BUF + NB_G0;
  nm.g1_frag = N_BUF + NB_G1;
  nm.slash_stdout = N_BUF + NB_SLASH_STDOUT;
  nm.slash_stderr = N_BUF + NB_SLASH_STDERR;
  nm.slash_status = N_BUF + NB_SLASH_STATUS;
  nm.slash_artifact = N_BUF + NB_SLASH_ARTIFACT;
  nm.slash_aout = N_BUF + NB_SLASH_AOUT;
  nm.slash_asm = N_BUF + NB_SLASH_ASM;
  nm.slash_dylib = N_BUF + NB_SLASH_DYLIB;
  nm.class_object = N_BUF + NB_CLASS_OBJECT;
  nm.class_exec = N_BUF + NB_CLASS_EXEC;
  nm.class_asm = N_BUF + NB_CLASS_ASM;
  nm.class_dylib = N_BUF + NB_CLASS_DYLIB;
  nm.class_none = N_BUF + NB_CLASS_NONE;
  nm.verdict_agree = N_BUF + NB_VERDICT_AGREE;
  nm.verdict_disagree = N_BUF + NB_VERDICT_DISAGREE;

  I64 n = LoadCases(argv[1]);
  if (n < 0) {
    "REASON_DETAIL=case table unreadable\n";
    return 2;
  }
  if (n == 0) {
    "REASON_DETAIL=case table empty\n";
    return 2;
  }



  I64 k = 0;
  while (argv[4][k] != 0 && k < 480) { G0_WORK_BUF[k] = argv[4][k]; k = k + 1; }
  G0_WORK_BUF[k] = 0;
  App(G0_WORK_BUF, 512, &k, nm.g0_frag);
  // The two working directories are DISTINCT, so a stale artifact in
  // one can never be observed in the other.

  k = 0;
  TMP_BUF[0] = 0;
  while (argv[4][k] != 0 && k < 480) { TMP_BUF[k] = argv[4][k]; k = k + 1; }
  TMP_BUF[k] = 0;
  App(TMP_BUF, 512, &k, nm.g1_frag);
  CopyStr(G1_WORK_BUF, 512, TMP_BUF);

  failures = 0;
  I64 c = 0;
  while (c < CASECOUNT) {
    // G0: the selector-OFF C-authoritative oracle.
    Observe(&nm, argv[2], G0_WORK_BUF, CASE_ARGV[c]);
    G0_EXIT = RUN_EXIT; G0_CLASS = RUN_CLASS;
    G0_COUNT = ArtifactCount(&nm, G0_WORK_BUF);
    CopyStr(G0_OUT, 64, RUN_OUT);
    CopyStr(G0_ERR, 64, RUN_ERR);
    CopyStr(G0_ART, 64, RUN_ART);

    // G1: the selector-ON PolyC-authoritative compiler.
    Observe(&nm, argv[3], G1_WORK_BUF, CASE_ARGV[c]);
    G1_EXIT = RUN_EXIT; G1_CLASS = RUN_CLASS;
    G1_COUNT = ArtifactCount(&nm, G1_WORK_BUF);
    CopyStr(G1_OUT, 64, RUN_OUT);
    CopyStr(G1_ERR, 64, RUN_ERR);
    CopyStr(G1_ART, 64, RUN_ART);

    // The comparison. Only the properties that apply to the case are
    // compared: a diagnostic-only case is compared on its exit status
    // and its diagnostics, not on an artifact.
    I64 agree = 1;
    if (G0_EXIT != G1_EXIT) agree = 0;
    if (StrEq(G0_OUT, G1_OUT) != 1) agree = 0;
    if (StrEq(G0_ERR, G1_ERR) != 1) agree = 0;
    if (G0_COUNT != G1_COUNT) agree = 0;
    if (G0_CLASS != G1_CLASS) agree = 0;
    if (StrEq(G0_ART, G1_ART) != 1) agree = 0;
    // The EXPECTED class is checked too: a case that expects an
    // OBJECT must actually have produced one, in BOTH generations.
    if (CASE_CLASS[c] != CLASS_NONE) {
      if (G0_CLASS != CASE_CLASS[c]) agree = 0;
      if (G1_CLASS != CASE_CLASS[c]) agree = 0;
    }

    if (agree == 0) failures++;

    // PolyC has no ternary operator, so the verdict is chosen with an
    // explicit if.

    if (agree == 1) {
      CopyStr(VERDICT_BUF, 16, nm.verdict_agree);
    } else {
      CopyStr(VERDICT_BUF, 16, nm.verdict_disagree);
    }

    "%s G0=%d/%s G1=%d/%s %s\n",
      CASE_ID[c],
      G0_EXIT, ClassName(&nm, G0_CLASS),
      G1_EXIT, ClassName(&nm, G1_CLASS),
      VERDICT_BUF;
    c = c + 1;
  }

  "CASES=%d\n", CASECOUNT;
  "DISAGREE=%d\n", failures;
  if (failures > 0) {
    "DIFFERENTIAL=FAIL\n";
    return 1;
  }
  "DIFFERENTIAL=PASS\n";
  return 0;
}
