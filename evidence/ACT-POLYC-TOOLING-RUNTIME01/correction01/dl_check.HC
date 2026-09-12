#include "src/holyc-lib/tooling.HC"

public I32 Main(I32 argc, U8 **argv)
{
  U8 *modes[4];
  modes[0] = "stderr-flood";
  modes[1] = "stdout-flood";
  modes[2] = "interleave";
  modes[3] = NULL;
  for (I32 k = 0; modes[k]; k++) {
    U8 *out = NULL;
    U8 *err = NULL;
    U8 *args[4];
    args[0] = "/tmp/deadlock_probe";
    args[1] = modes[k];
    args[2] = "4194304";
    args[3] = NULL;
    I64 rc = SpawnAndCapture("/tmp/deadlock_probe", args, &out, &err);
    "mode=%s rc=%d out=%d err=%d\n", modes[k], rc, StrLen(out), StrLen(err);
    if (Contains(out, "stdout-sentinel")) "  OUT_SENT\n";
    else "  OUT_MISS\n";
    if (Contains(err, "stderr-sentinel")) "  ERR_SENT\n";
    else "  ERR_MISS\n";
  }
  return 0;
}
