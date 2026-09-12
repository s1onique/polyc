// evidence/ACT-POLYC-TOOLING-RUNTIME01/c1/tooling-probe.HC
//
// ACT-POLYC-TOOLING-RUNTIME01 C1 RED — first tooling probe.
//
// Goal: mechanically express the intended consumer of the
// new runtime substrate using current PolyC syntax, so
// that the failure layer is unambiguous:
//
//     the symbol SpawnAndCapture() does not exist.
//
// The probe does NOT call System() or Sh() because both
// route through /bin/sh -c and are explicitly forbidden
// by ACT §4.
//
// The probe also does NOT call a missing mkstemp() or
// strstr() — those primitives are exercised in C2/C3.
//
// This file exists as evidence that the PolyC compiler
// successfully tokenizes and parses the intended API
// shape. At parse time, the unknown identifier surfaces
// a precise diagnostic; at link time it would surface
// an undefined-symbol error. Both layers are acceptable
// for ACT §11.

public I32 Main(I32 argc, U8 **argv)
{
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = 0;

  // ----- P1: deterministic successful child -----
  rc = SpawnAndCapture("/bin/printf", "hello", &out, &err);
  if (rc != 0) {
    "tooling-probe: P1 spawn failed rc=%d\n", rc;
    return 1;
  }
  if (!out || StrCmp(out, "hello") != 0) {
    "tooling-probe: P1 stdout mismatch\n";
    return 2;
  }
  if (err && err[0] != 0) {
    "tooling-probe: P1 unexpected stderr\n";
    return 3;
  }

  // ----- P2: missing executable -----
  rc = SpawnAndCapture("/does/not/exist/polyc-probe",
                       &out, &err);
  if (rc == 0) {
    "tooling-probe: P2 missing-executable returned 0\n";
    return 4;
  }

  "tooling-probe: C1 RED layer reached successfully\n";
  return 0;
}
