// tools/quality/driver-required-route-correction01-abi-probe.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01 C1 EVIDENCE.
//
// THE SELECTED-ACTION ABI PROBE.
//
// It reads the emission action that the compiled PolyC driver selects
// for a SET OF ARGV SHAPES, and prints one row per shape:
//
//   <case-id> <emission-code> <expected-code> <verdict>
//
// The verdict is PASS when the observed code equals the expected code
// and FAIL otherwise. The probe NEVER reads a status field: it calls
// the driver export and compares the RETURNED VALUE.
//
// It is compiled by the real production compiler and linked against the
// real driver subject and the real host bridge, so the seam it probes
// is the seam the production compiler uses.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// THE HOST SEAM (implemented in src/selfhost-driver-wp001.c).
extern "c" I64 WpDriverHostArgc();
extern "c" I64 WpDriverHostArgLen(I64 idx);
extern "c" U8 *WpDriverHostArgByte(I64 idx);
extern "c" U0 WpDriverHostSetArgv(I32 argc, U8 **argv);

// THE SUBJECT UNDER TEST: the driver's emission decision.
extern "c" I64 WpDriverSelectedEmission();

// THE EMISSION DOMAIN (mirrored from src/selfhost-driver-wp001.h).
#define WP_EMIT_UNKNOWN        0
#define WP_EMIT_COMPILE_OBJECT 1
#define WP_EMIT_EXECUTE        2
#define WP_EMIT_ASSEMBLY       3
#define WP_EMIT_DYLIB          4

// ---------------------------------------------------------------------------
// THE PROBE CASES
//
// Each case is: an id, the argv shape, and the expected emission code.
// The expected codes are DERIVED FROM THE ARGV SHAPE, not from the
// observed output: they are written here, BEFORE the implementation.
//
// Every argv shape below is a COMPLETE, well-formed argv. In
// particular an option that takes a value ALWAYS has its value, so
// the case exercises the EMISSION decision and not the arity decision.
// The one deliberate exception is CASE 7, which is the arity case.
//
// The order of the argv is: the program name, then the options, then
// the source file, then the output option and its value.
// ---------------------------------------------------------------------------

#define NCASE 9
#define NARGS 7

static U8 *CASE_ID[NCASE];
static I64 CASE_NARG[NCASE];
static U8 *CASE_ARGV[NCASE * NARGS];
static I64 CASE_EXPECT[NCASE];

static U0 SetArg(I64 c, I64 i, U8 *v) {
  CASE_ARGV[c * NARGS + i] = v;
}

static U0 InitCases() {
  // 0: the REQUIRED route. The expected class is an OBJECT.
  CASE_ID[0] = "REQUIRED_ROUTE_OBJECT";
  SetArg(0,0,"hcc"); SetArg(0,1,"--install-dir=/p"); SetArg(0,2,"-c");
  SetArg(0,3,"input.HC"); SetArg(0,4,"-o"); SetArg(0,5,"out.o");
  CASE_NARG[0] = 6; CASE_EXPECT[0] = WP_EMIT_COMPILE_OBJECT;

  // 1: the -obj alias of the object route.
  CASE_ID[1] = "OBJECT_ALIAS_OBJ";
  SetArg(1,0,"hcc"); SetArg(1,1,"--install-dir=/p"); SetArg(1,2,"-obj");
  SetArg(1,3,"input.HC"); SetArg(1,4,"-o"); SetArg(1,5,"out.o");
  CASE_NARG[1] = 6; CASE_EXPECT[1] = WP_EMIT_COMPILE_OBJECT;

  // 2: the ALTERNATE route. The expected class is an EXECUTABLE.
  CASE_ID[2] = "ALTERNATE_ROUTE_EXECUTABLE";
  SetArg(2,0,"hcc"); SetArg(2,1,"--install-dir=/p"); SetArg(2,2,"input.HC");
  SetArg(2,3,"-o"); SetArg(2,4,"out");
  CASE_NARG[2] = 5; CASE_EXPECT[2] = WP_EMIT_EXECUTE;

  // 3: the assembly route.
  CASE_ID[3] = "ASSEMBLY_ROUTE";
  SetArg(3,0,"hcc"); SetArg(3,1,"--install-dir=/p"); SetArg(3,2,"-S");
  SetArg(3,3,"input.HC"); SetArg(3,4,"-o"); SetArg(3,5,"out.s");
  CASE_NARG[3] = 6; CASE_EXPECT[3] = WP_EMIT_ASSEMBLY;

  // 4: the dylib route.
  CASE_ID[4] = "DYLIB_ROUTE";
  SetArg(4,0,"hcc"); SetArg(4,1,"--install-dir=/p"); SetArg(4,2,"-lib");
  SetArg(4,3,"input.HC"); SetArg(4,4,"-o"); SetArg(4,5,"out.dylib");
  CASE_NARG[4] = 6; CASE_EXPECT[4] = WP_EMIT_DYLIB;

  // 5: an UNKNOWN option selects no emission; the default is EXECUTE.
  CASE_ID[5] = "UNKNOWN_OPTION_DEFAULT";
  SetArg(5,0,"hcc"); SetArg(5,1,"--install-dir=/p"); SetArg(5,2,"-bogus");
  SetArg(5,3,"input.HC"); SetArg(5,4,"-o"); SetArg(5,5,"out");
  CASE_NARG[5] = 6; CASE_EXPECT[5] = WP_EMIT_EXECUTE;

  // 6: the ABSENT request. A program name and nothing else -> UNKNOWN.
  CASE_ID[6] = "ABSENT_REQUEST";
  SetArg(6,0,"hcc");
  CASE_NARG[6] = 1; CASE_EXPECT[6] = WP_EMIT_UNKNOWN;

  // 7: the ERROR case. An option whose value is MISSING is an arity
  //    failure, and no emission is decided on a malformed argv.
  CASE_ID[7] = "ERROR_ARITY_MISSING_VALUE";
  SetArg(7,0,"hcc"); SetArg(7,1,"--install-dir=/p"); SetArg(7,2,"-c");
  SetArg(7,3,"input.HC"); SetArg(7,4,"-o");
  CASE_NARG[7] = 5; CASE_EXPECT[7] = WP_EMIT_UNKNOWN;

  // 8: the SAME object route as case 0, repeated. The decision MUST be
  //    STABLE: it is a pure function of the argv.
  CASE_ID[8] = "REQUIRED_ROUTE_OBJECT_REPEAT";
  SetArg(8,0,"hcc"); SetArg(8,1,"--install-dir=/p"); SetArg(8,2,"-c");
  SetArg(8,3,"input.HC"); SetArg(8,4,"-o"); SetArg(8,5,"out.o");
  CASE_NARG[8] = 6; CASE_EXPECT[8] = WP_EMIT_COMPILE_OBJECT;
}

I32 Main(I32 argc, U8 **argv) {
  InitCases();
  I64 failures = 0;
  I64 i = 0;
  while (i < NCASE) {
    U8 *av[NARGS];
    I64 j = 0;
    while (j < NARGS) { av[j] = CASE_ARGV[i * NARGS + j]; j = j + 1; }
    // The host state is installed per case and never mutated afterwards,
    // so the argv lifetime is bounded by this iteration.
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
  "ABI_PROBE_CASES\t%d\n", NCASE;
  "ABI_PROBE_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
