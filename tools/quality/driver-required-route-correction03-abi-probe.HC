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

#define NCASE 8
#define NARGS 5

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
}

I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  InitCases();
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
