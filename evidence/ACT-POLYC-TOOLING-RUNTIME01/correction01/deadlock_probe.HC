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

// =====================================================================
// SUPERSEDED NOTICE — added by ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02
// =====================================================================
//
// This file has a U8 *args[3] declared but assigned 4 elements
// (args[0..3] = path, mode, nbytes, NULL), which is an out-of-bounds
// write. Per the reviewer, this is a latent memory-corruption witness
// that should not be committed as authoritative evidence.
//
// The authoritative fixture for the CORRECTION01 deadlock-stress
// reproducer is the C-side pair:
//
//   evidence/ACT-POLYC-TOOLING-RUNTIME01/correction01/deadlock_probe.c
//   evidence/ACT-POLYC-TOOLING-RUNTIME01/correction01/dl_check.HC
//
// THIS FILE IS NOT USED FOR AUTHORITATIVE TESTING.
// =====================================================================
