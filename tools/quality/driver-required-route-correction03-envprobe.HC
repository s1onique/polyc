// tools/quality/driver-required-route-correction03-envprobe.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// THE ENVIRONMENT PROBE.
//
// It prints the value of the environment variable named by its FIRST
// argument, on its standard output, and exits 0.
//
// It exists so that the harness can PROVE that the environment it records
// is the environment the spawned child actually observed. The harness
// applies a binding, spawns this probe, and requires the probe's output to
// carry the expected value.
//
// Without this probe, a WRONG environment application is INVISIBLE: the
// setenv call succeeds, the capture records the binding the harness
// BELIEVED it applied, and every self-consistent check passes. That is
// exactly what happened before this probe existed.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "ENVPROBE_USAGE=envprobe <variable-name>\n";
    return 2;
  }
  U8 *name = argv[1];
  U8 *value = getenv(name);
  if (value == NULL) {
    "ENVPROBE_VALUE=ABSENT\n";
    "ENVPROBE_NAME=%s\n", name;
    return 0;
  }
  "ENVPROBE_VALUE=%s\n", value;
  "ENVPROBE_NAME=%s\n", name;
  return 0;
}
