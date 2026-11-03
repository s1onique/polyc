// tools/quality/driver-required-route-correction03-abi-probe.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03.
//
// The compiled PolyC selected-emission ABI probe. It reads the emission
// selected for exact argv shapes and compares the returned value with the
// C-oracle-derived precedence expectation.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 WpDriverHostArgc();
extern "c" I64 WpDriverHostArgLen(I64 idx);
extern "c" U8 *WpDriverHostArgByte(I64 idx);
extern "c" U0 WpDriverHostSetArgv(I32 argc, U8 **argv);
extern "c" I64 WpDriverSelectedEmission();

#define WP_EMIT_UNKNOWN        0
#define WP_EMIT_COMPILE_OBJECT 1
#define WP_EMIT_EXECUTE        2
#define WP_EMIT_ASSEMBLY       3
#define WP_EMIT_DYLIB          4

// The DOMAIN COVERAGE.
//
// The eight mandatory precedence cases cover the OBJECT and the ASSEMBLY
// domain. The remaining two SUPPORTED domain values -- the DYNAMIC LIBRARY
// domain and the EXECUTABLE (default) domain -- are covered here, so that
// EVERY supported selected-emission value has OBSERVED dispatch behavior
// and no supported value rests on a DECLARED status alone.
//
// The FAIL-CLOSED cases cover the INVALID values: an argv whose arity is
// violated, and an argv with no source file, must select the UNKNOWN
// emission rather than falling back to a supported one.
#define NCASE 16
#define NARGS 6

static U8 *CASE_ID[NCASE];
static I64 CASE_NARG[NCASE];
static U8 *CASE_ARGV[NCASE * NARGS];
static I64 CASE_EXPECT[NCASE];
static I64 failures;

static U0 SetArg(I64 c, I64 i, U8 *v) {
  CASE_ARGV[c * NARGS + i] = v;
}

static U0 InitCases() {
  CASE_ID[0] = "OBJECT_THEN_ASSEMBLY";
  SetArg(0,0,"hcc"); SetArg(0,1,"-c"); SetArg(0,2,"-S"); SetArg(0,3,"input.HC");
  CASE_NARG[0] = 4; CASE_EXPECT[0] = WP_EMIT_COMPILE_OBJECT;

  CASE_ID[1] = "ASSEMBLY_THEN_OBJECT";
  SetArg(1,0,"hcc"); SetArg(1,1,"-S"); SetArg(1,2,"-c"); SetArg(1,3,"input.HC");
  CASE_NARG[1] = 4; CASE_EXPECT[1] = WP_EMIT_COMPILE_OBJECT;

  CASE_ID[2] = "OBJECT_ASSEMBLY_OBJECT";
  SetArg(2,0,"hcc"); SetArg(2,1,"-c"); SetArg(2,2,"-S"); SetArg(2,3,"-c");
  SetArg(2,4,"input.HC");
  CASE_NARG[2] = 5; CASE_EXPECT[2] = WP_EMIT_COMPILE_OBJECT;

  CASE_ID[3] = "ASSEMBLY_OBJECT_ASSEMBLY";
  SetArg(3,0,"hcc"); SetArg(3,1,"-S"); SetArg(3,2,"-c"); SetArg(3,3,"-S");
  SetArg(3,4,"input.HC");
  CASE_NARG[3] = 5; CASE_EXPECT[3] = WP_EMIT_COMPILE_OBJECT;

  CASE_ID[4] = "OBJECT_DUPLICATE";
  SetArg(4,0,"hcc"); SetArg(4,1,"-c"); SetArg(4,2,"-c"); SetArg(4,3,"input.HC");
  CASE_NARG[4] = 4; CASE_EXPECT[4] = WP_EMIT_COMPILE_OBJECT;

  CASE_ID[5] = "ASSEMBLY_DUPLICATE";
  SetArg(5,0,"hcc"); SetArg(5,1,"-S"); SetArg(5,2,"-S"); SetArg(5,3,"input.HC");
  CASE_NARG[5] = 4; CASE_EXPECT[5] = WP_EMIT_ASSEMBLY;

  CASE_ID[6] = "OBJECT_WITH_DYLIB";
  SetArg(6,0,"hcc"); SetArg(6,1,"-lib"); SetArg(6,2,"name");
  SetArg(6,3,"-c"); SetArg(6,4,"input.HC");
  CASE_NARG[6] = 5; CASE_EXPECT[6] = WP_EMIT_COMPILE_OBJECT;

  CASE_ID[7] = "ASSEMBLY_WITH_DYLIB";
  SetArg(7,0,"hcc"); SetArg(7,1,"-lib"); SetArg(7,2,"name");
  SetArg(7,3,"-S"); SetArg(7,4,"input.HC");
  CASE_NARG[7] = 5; CASE_EXPECT[7] = WP_EMIT_ASSEMBLY;

  // -----------------------------------------------------------------------
  // THE REMAINING SUPPORTED DOMAINS.
  // -----------------------------------------------------------------------

  // The DYNAMIC LIBRARY domain: `-lib <name>` with a source file and no
  // object request and no assembly request selects the dylib.
  CASE_ID[8] = "DYLIB_ONLY";
  SetArg(8,0,"hcc"); SetArg(8,1,"-lib"); SetArg(8,2,"name");
  SetArg(8,3,"input.HC");
  CASE_NARG[8] = 4; CASE_EXPECT[8] = WP_EMIT_DYLIB;

  // The DYNAMIC LIBRARY domain again, with the `-lib` request AFTER the
  // source file, so that the whole-argv precedence cannot depend on the
  // position of the request.
  CASE_ID[9] = "DYLIB_AFTER_SOURCE";
  SetArg(9,0,"hcc"); SetArg(9,1,"input.HC"); SetArg(9,2,"-lib");
  SetArg(9,3,"name");
  CASE_NARG[9] = 4; CASE_EXPECT[9] = WP_EMIT_DYLIB;

  // The EXECUTABLE (default) domain: a source file and no emission option
  // at all selects the executable.
  CASE_ID[10] = "EXECUTABLE_DEFAULT";
  SetArg(10,0,"hcc"); SetArg(10,1,"input.HC");
  CASE_NARG[10] = 2; CASE_EXPECT[10] = WP_EMIT_EXECUTE;

  // The EXECUTABLE (default) domain with an output file: the output file
  // is not an emission request, so the argv still selects the executable.
  CASE_ID[11] = "EXECUTABLE_DEFAULT_WITH_OUTPUT";
  SetArg(11,0,"hcc"); SetArg(11,1,"input.HC"); SetArg(11,2,"-o");
  SetArg(11,3,"out");
  CASE_NARG[11] = 4; CASE_EXPECT[11] = WP_EMIT_EXECUTE;

  // The DYNAMIC LIBRARY domain outranks the EXECUTABLE domain: a `-lib`
  // request together with a source file selects the dylib, not the
  // executable.
  CASE_ID[12] = "DYLIB_OUTRANKS_EXECUTABLE";
  SetArg(12,0,"hcc"); SetArg(12,1,"-lib"); SetArg(12,2,"name");
  SetArg(12,3,"input.HC");
  SetArg(12,4,"-o"); SetArg(12,5,"out");
  CASE_NARG[12] = 6; CASE_EXPECT[12] = WP_EMIT_DYLIB;

  // The OBJECT domain outranks the DYNAMIC LIBRARY domain: a `-c`
  // request together with a `-lib` request selects the object.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
  // ROUND 2, P2-4 -- THE SIXTEENTH ROW IS NOW A DISTINCT ARGV SHAPE.
  //
  // The previous revision's case 13 was "hcc -lib name -c input.HC", which
  // is BYTE IDENTICAL to its case 6. The roster therefore carried SIXTEEN
  // ROWS but only FIFTEEN UNIQUE argv shapes, and the roster's own count
  // overstated the coverage.
  //
  // The case is now a DISTINCT shape that tests the SAME precedence rule
  // with the `-c` request AFTER the source file, so the rule cannot be
  // satisfied by a whole-argv scan that happens to stop at the first
  // source file.
  CASE_ID[13] = "OBJECT_OUTRANKS_DYLIB_AFTER_SOURCE";
  SetArg(13,0,"hcc"); SetArg(13,1,"-lib"); SetArg(13,2,"name");
  SetArg(13,3,"input.HC"); SetArg(13,4,"-c");
  CASE_NARG[13] = 5; CASE_EXPECT[13] = WP_EMIT_COMPILE_OBJECT;

  // -----------------------------------------------------------------------
  // THE INVALID / FAIL-CLOSED CASES.
  // -----------------------------------------------------------------------

  // An option whose value is MISSING is an arity violation. The emission
  // decision is NOT made on a malformed argv, so the emission is UNKNOWN
  // and the caller fails closed.
  CASE_ID[14] = "ARITY_VIOLATION_IS_UNKNOWN";
  SetArg(14,0,"hcc"); SetArg(14,1,"-lib");
  CASE_NARG[14] = 2; CASE_EXPECT[14] = WP_EMIT_UNKNOWN;

  // An argv with NO source file and NO emission request selects NO
  // emission at all. It is the ABSENT case and it is distinct from the
  // EXECUTABLE case.
  CASE_ID[15] = "NO_SOURCE_IS_UNKNOWN";
  SetArg(15,0,"hcc"); SetArg(15,1,"--install-dir");
  SetArg(15,2,"/tmp/prefix");
  CASE_NARG[15] = 3; CASE_EXPECT[15] = WP_EMIT_UNKNOWN;
}

I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  InitCases();

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
  // ROUND 2, P2-4 -- THE DISTINCT-ARGV-SHAPE SELF-CHECK.
  //
  // The roster's row count is NOT evidence of coverage. Two rows with the
  // SAME argv shape test the SAME decision, so the roster must require
  // that every pair of rows has a DISTINCT shape.
  //
  // The check is MECHANICAL: two rows collide when their argument
  // sequences are identical, argument for argument.
  I64 dup = 0;
  I64 a = 0;
  while (a < NCASE) {
    I64 b = a + 1;
    while (b < NCASE) {
      I64 same = 1;
      if (CASE_NARG[a] != CASE_NARG[b]) {
        same = 0;
      } else {
        I64 k = 0;
        while (k < CASE_NARG[a]) {
          if (StrCmp(CASE_ARGV[a * NARGS + k],
                     CASE_ARGV[b * NARGS + k]) != 0) {
            same = 0;
            break;
          }
          k = k + 1;
        }
      }
      if (same == 1) {
        "%s\tDUPLICATE_ARGV_SHAPE\t%s\tFAIL\n", CASE_ID[a], CASE_ID[b];
        dup = dup + 1;
        failures = failures + 1;
      }
      b = b + 1;
    }
    a = a + 1;
  }
  "CORRECTION03_ABI_PROBE_ROWS\t%d\n", NCASE;
  "CORRECTION03_ABI_PROBE_DUPLICATE_SHAPES\t%d\n", dup;

  I64 i = 0;
  while (i < NCASE) {
    U8 *av[NARGS];
    I64 j = 0;
    while (j < NARGS) { av[j] = CASE_ARGV[i * NARGS + j]; j = j + 1; }
    { I32 n = CASE_NARG[i]; WpDriverHostSetArgv(n, av); }
    I64 observed = WpDriverSelectedEmission();
    I64 expected = CASE_EXPECT[i];
    if (observed == expected) {
      "%s\t%d\t%d\tPASS\n", CASE_ID[i], observed, expected;
    } else {
      "%s\t%d\t%d\tFAIL\n", CASE_ID[i], observed, expected;
      failures = failures + 1;
    }
    i = i + 1;
  }
  "CORRECTION03_ABI_PROBE_CASES\t%d\n", NCASE;
  "CORRECTION03_ABI_PROBE_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
