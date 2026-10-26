// evidence/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01/probes/filewrite-signature-probe.HC
//
// RED probe for ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01, Defect A.
//
// This probe links against the CANONICAL installed libtos and includes
// ONLY the declaration-only header src/holyc-lib/io_defs.HH -- the same
// library-ownership boundary the GEP01 harness uses.
//
// It demonstrates that the FileWrite CALL SITE compiled against
// io_defs.HH's declaration fails, because the 4th parameter is typed
// `Bool append=FALSE` in the header but `I64 flags=O_CREAT|O_RDWR` in the
// library definition (src/holyc-lib/io.HC) and the canonical public
// header (src/holyc-lib/tos.HH).
//
// A defaulted 4th argument therefore becomes the boolean FALSE == 0, the
// library issues open(path, 0, 420) WITHOUT O_CREAT, and the write fails.
//
// After the repair the header declares `I64 flags=O_CREAT|O_RDWR`, the
// default becomes 0x202, and the defaulted call succeeds.

#include "../../../src/holyc-lib/memory_defs.HH"
#include "../../../src/holyc-lib/tooling_defs.HH"
#include "../../../src/holyc-lib/io_defs.HH"

extern "c" I32 open(U8 *__name, I32 flags, ...);
extern "c" I64 write(I32 __fd, U0 *__buf, U64 __nbyte);
extern "c" I32 close(I32 fd);

public I32 main(I32 argc, U8 **argv)
{
  U8 *dir = argv[1];
  U8 *p_default = StrPrint(NULL, "%s/fw-default.txt", dir);
  U8 *p_explicit = StrPrint(NULL, "%s/fw-explicit.txt", dir);
  U8 *p_num = StrPrint(NULL, "%s/fw-num.txt", dir);
  U8 *p_trunc = StrPrint(NULL, "%s/fw-trunc.txt", dir);
  U8 *p_direct = StrPrint(NULL, "%s/fw-direct.txt", dir);

  "=== ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01 :: Defect A probe ===\n";
  "io_defs.HH FileWrite 4th parameter default is used by the harness.\n\n";

  // (1) Defaulted 4th argument -- the harness's actual call shape.
  Bool a = FileWrite(p_default, "hello", 5);
  "FileWrite(default)                    = %d\n", a;

  // (2) Explicit flags, same value the correct default expands to.
  Bool b = FileWrite(p_explicit, "hello", 5, O_CREAT|O_RDWR);
  "FileWrite(explicit O_CREAT|O_RDWR)    = %d\n", b;

  // (3) Explicit numeric flags.
  Bool c = FileWrite(p_num, "hello", 5, 0x202);
  "FileWrite(explicit 0x202)             = %d\n", c;

  // (4) Explicit flags with truncation.
  Bool d = FileWrite(p_trunc, "hello", 5, O_CREAT|O_RDWR|O_TRUNC);
  "FileWrite(explicit ...|O_TRUNC)       = %d\n", d;

  // (5) The raw POSIX call the library makes, bypassing the signature.
  I32 fd = open(p_direct, O_CREAT|O_RDWR, 420);
  I64 n = -1;
  if (fd >= 0) { n = write(fd, "hello", 5); close(fd); }
  "direct open(O_CREAT|O_RDWR, 420)      = fd %d, wrote %d bytes\n", fd, n;

  "\n=== INTERPRETATION ===\n";
  "If FileWrite(default) == 0 while the explicit-flag calls == 1, the\n";
  "call site is being lowered against a 4th parameter that is NOT the\n";
  "library's I64 flags parameter. The defaulted value arrives as the\n";
  "boolean FALSE (0), so open() is issued without O_CREAT and fails.\n";
  return 0;
}
