// tools/quality/driver-required-route-correction03-compare.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03.
//
// Compare the artifacts produced by the selector-OFF C oracle and the
// selector-ON PolyC compiler for one argv shape. The artifact class is
// derived from the file bytes, never from the filename or compiler exit.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MACHO64_MAGIC 0xFEEDFACF
#define ELF64_MAGIC   0x7F454C46

static I64 failures;

static I64 WordAt(U8 *buf, I64 size, I64 off) {
  if (size < off + 4) return -1;
  I64 v = 0;
  I64 i = off + 3;
  while (i >= off) { v = v * 256 + buf[i]; i = i - 1; }
  return v;
}

static U8 *ClassName(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return "ABSENT";
  I64 magic = WordAt(buf, size, 0);
  if (magic == MACHO64_MAGIC) {
    I64 type = WordAt(buf, size, 12);
    if (type == 1) return "MACHO_OBJECT";
    if (type == 2) return "MACHO_EXECUTABLE";
    if (type == 6) return "MACHO_DYLIB";
    return "MACHO_OTHER";
  }
  if (magic == ELF64_MAGIC) return "ELF";
  return "OTHER";
}

static I64 BytesEqual(U8 *a, U8 *b) {
  I64 asize = 0;
  I64 bsize = 0;
  U8 *abuf = FileRead(a, &asize);
  U8 *bbuf = FileRead(b, &bsize);
  if (abuf == NULL || bbuf == NULL) return 0;
  if (asize != bsize) return 0;
  I64 i = 0;
  while (i < asize) {
    if (abuf[i] != bbuf[i]) return 0;
    i = i + 1;
  }
  return 1;
}

static I64 StringsEqual(U8 *a, U8 *b) {
  I64 i = 0;
  while (a[i] != 0 && b[i] != 0) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  if (a[i] == 0 && b[i] == 0) return 1;
  return 0;
}

static U0 Check(I64 ok, U8 *case_id, U8 *what) {
  if (ok == 1) {
    "%s\t%s\tPASS\n", case_id, what;
  } else {
    "%s\t%s\tFAIL\n", case_id, what;
    failures = failures + 1;
  }
}

I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  if (argc < 4) {
    "REASON_DETAIL=usage: <case-id> <oracle-artifact> <polyc-artifact>\n";
    return 2;
  }
  U8 *case_id = argv[1];
  U8 *oracle = argv[2];
  U8 *polyc = argv[3];
  U8 *oracle_class = ClassName(oracle);
  U8 *polyc_class = ClassName(polyc);
  "ARTIFACT_CLASS\t%s\t%s\t%s\n", case_id, oracle_class, polyc_class;
  Check(oracle_class[0] != 'A' || oracle_class[1] != 'B', case_id,
        "the oracle produced an artifact");
  Check(polyc_class[0] != 'A' || polyc_class[1] != 'B', case_id,
        "the PolyC compiler produced an artifact");
  Check(StringsEqual(oracle_class, polyc_class) == 1, case_id,
        "the artifact classes agree");
  Check(BytesEqual(oracle, polyc) == 1, case_id,
        "the actual artifact bytes agree");
  // stderr is recorded by the harness. The selector-OFF legacy object
  // command emits an existing assembler warning for unused link flags;
  // that pre-existing difference is P1 residue, not a PolyC diagnostic.
  "CORRECTION03_COMPARE_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
