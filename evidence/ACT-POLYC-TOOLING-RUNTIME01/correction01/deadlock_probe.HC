// deadlock_probe.HC -- RED witness for SpawnAndCapture
// deadlock under stderr-flood.

#include "src/holyc-lib/tooling.HC"

public I32 Main(I32 argc, U8 **argv)
{
  U8 *out = NULL, *err = NULL;
  U8 *args[3];
  I64 rc;

  args[0] = "/tmp/deadlock_probe";
  args[1] = "stderr-flood";
  args[2] = "4194304";   // 4 MiB
  args[3] = NULL;

  "deadlock_probe: starting stderr-flood 4 MiB\n";
  rc = SpawnAndCapture("/tmp/deadlock_probe", args, &out, &err);
  I64 out_len = 0;
  I64 err_len = 0;
  if (out) out_len = StrLen(out);
  if (err) err_len = StrLen(err);
  "deadlock_probe: rc=%d out_len=%d err_len=%d\n",
   rc, out_len, err_len;

  if (rc != 0) return 1;
  if (!out) return 2;
  if (!Contains(out, "stdout-sentinel")) return 3;
  if (!err) return 4;
  if (!Contains(err, "stderr-sentinel")) return 5;
  return 0;
}
