// tools/quality/driver-required-route-correction01-test.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01.
//
// THE CANONICAL DRIVER ROUTE REGRESSION TEST.
//
// It classifies the ARTIFACTS that the production compiler produced on
// the two frozen routes, and it checks that they are of DIFFERENT and
// CORRECT classes:
//
//   the -c route      MUST have produced an OBJECT
//   the non -c route  MUST have produced an EXECUTABLE
//
// The class is read from the BYTES of the produced file -- NOT from
// its NAME and NOT from the compiler's exit status. A compiler that
// writes an executable into a .o path FAILS this test.
//
// It also checks that the NEGATIVE argument case produced NO artifact.
//
// The test is a COMPILED POLYC program: it is built by the real
// production compiler and executed against the real production binary's
// output.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 8192
#define NCOL 24

// The Mach-O 64-bit magic, as it appears in the file's first four bytes
// read little-endian.
#define MACHO64_MAGIC 0xFEEDFACF
// The ELF 64-bit magic. The ELF magic is byte-order invariant, so the
// same little-endian reader recognises it unchanged.
#define ELF64_MAGIC   0x7F454C46

// NOTE: NO FILE-SCOPE INITIALISER HERE.
//
// A file-scope initialiser makes the production compiler build a
// synthetic `_main` driver that calls the user `Main` with argc=0 and
// argv=NULL (src/asm.c::asmNormaliseFunctionName /
// asmBuildInitialiserMain). This tool NEEDS the real argc/argv, so it
// declares its accumulator WITHOUT an initialiser and seeds it on
// entry. This is a documented tool constraint, not a workaround for
// an untested behaviour; the same constraint and the same workaround
// are already recorded as RES-01 by
// ACT-POLYC-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01.
static I64 failures;

// The LITTLE-ENDIAN 32-bit value at a byte offset, or -1 when the file
// is too short.
//
// Mach-O on the supported Apple targets is LITTLE-ENDIAN, so the magic
// and the filetype field are read least-significant byte first. The
// ELF magic is byte-order invariant, so the same reader serves both.
static I64 WordAt(U8 *buf, I64 size, I64 off) {
  if (size < off + 4) return -1;
  I64 v = 0;
  I64 i = off + 3;
  while (i >= off) { v = v * 256 + buf[i]; i = i - 1; }
  return v;
}

// Is the file a Mach-O OBJECT? A Mach-O object has filetype 1
// (MH_OBJECT) at offset 12; an executable has filetype 2 (MH_EXECUTE).
static I64 IsMachOObject(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  if (WordAt(buf, size, 0) != MACHO64_MAGIC) return 0;
  if (WordAt(buf, size, 12) != 1) return 0;
  return 1;
}

// Is the file an EXECUTABLE?
static I64 IsExecutable(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  I64 magic = WordAt(buf, size, 0);
  if (magic == MACHO64_MAGIC) {
    if (WordAt(buf, size, 12) == 2) return 1;
    return 0;
  }
  if (magic == ELF64_MAGIC) return 1;
  return 0;
}

// Does the file EXIST at all?
//
// This deliberately does NOT require a non-zero size. An EMPTY file is
// still a file, and a negative case that produced an empty file has
// produced an artifact. The existence question is therefore asked
// separately from the content questions, so that a zero-byte artifact
// cannot be mistaken for an absent one.
static I64 FilePresent(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  return 1;
}

static U0 Check(I64 ok, U8 *case_id, U8 *what) {
  if (ok == 1) {
    "%s\t%s\tPASS\n", case_id, what;
  } else {
    "%s\t%s\tFAIL\n", case_id, what;
    failures = failures + 1;
  }
}

// ---------------------------------------------------------------------------
// THE TOOL SELF-TEST
// ---------------------------------------------------------------------------
//
// The classification logic is verified against SYNTHETIC byte patterns
// whose class is known by construction. This proves the reader is
// sensitive BEFORE it is asked to judge a real artifact: a reader that
// always answered "not an object" would fail here, and a reader that
// always answered "object" would fail here too.
//
// The patterns are written to files by the caller and classified by
// path, so the self-test exercises the SAME code path as the real
// assertions.
// ---------------------------------------------------------------------------
static I32 ModeSelfTest(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: SELFTEST <object-pattern> <executable-pattern> <not-macho>\n"; return 2; }
  U8 *objpat = argv[1];
  U8 *exepat = argv[2];
  U8 *other = argv[3];
  failures = 0;
  Check(IsMachOObject(objpat) == 1, "SELFTEST", "a synthetic MH_OBJECT is classified as an object");
  Check(IsExecutable(objpat) == 0, "SELFTEST", "a synthetic MH_OBJECT is NOT classified as an executable");
  Check(IsExecutable(exepat) == 1, "SELFTEST", "a synthetic MH_EXECUTE is classified as an executable");
  Check(IsMachOObject(exepat) == 0, "SELFTEST", "a synthetic MH_EXECUTE is NOT classified as an object");
  Check(IsMachOObject(other) == 0, "SELFTEST", "a non-Mach-O file is NOT classified as an object");
  Check(IsExecutable(other) == 0, "SELFTEST", "a non-Mach-O file is NOT classified as an executable");
  "DRIVER_ROUTE_TEST_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}

// ---------------------------------------------------------------------------
// THE DISPATCHER
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  if (argc < 2) {
    "REASON_DETAIL=usage: <mode> <args...>\n";
    return 2;
  }
  if (argv[1][0] == 'S' && argv[1][1] == 'E' && argv[1][2] == 'L' &&
      argv[1][3] == 'F' && argv[1][4] == 'T' && argv[1][5] == 'E' &&
      argv[1][6] == 'S' && argv[1][7] == 'T' && argv[1][8] == 0) {
    return ModeSelfTest(argc - 1, argv + 1);
  }
  if (argc < 4) {
    "REASON_DETAIL=usage: <object-artifact> <executable-artifact> <absent-artifact>\n";
    return 2;
  }
  U8 *objpath = argv[1];
  U8 *exepath = argv[2];
  U8 *nopath = argv[3];

  Check(FilePresent(objpath) == 1, "ROUTE_OBJECT", "the required route produced an artifact");
  Check(IsMachOObject(objpath) == 1, "ROUTE_OBJECT", "the required route produced a real Mach-O OBJECT");
  Check(IsExecutable(objpath) == 0, "ROUTE_OBJECT", "the required route did NOT produce an executable");

  Check(FilePresent(exepath) == 1, "ROUTE_ALTERNATE", "the alternate route produced an artifact");
  Check(IsExecutable(exepath) == 1, "ROUTE_ALTERNATE", "the alternate route produced an EXECUTABLE");
  Check(IsMachOObject(exepath) == 0, "ROUTE_ALTERNATE", "the alternate route did NOT produce an object");

  Check(FilePresent(nopath) == 0, "NEG_UNKNOWN_OPTION", "the failing case produced no artifact");

  "DRIVER_ROUTE_TEST_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
