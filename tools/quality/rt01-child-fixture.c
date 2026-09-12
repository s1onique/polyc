// tools/quality/rt01-child-fixture.c
//
// ACT-POLYC-TOOLING-RUNTIME01 C3 EVIDENCE — bounded
// child fixture used as a deterministic test oracle.
//
// Behavior (driven by argv[1]):
//   "stdout"  -> prints "polyc-rt01-out\n" to stdout,
//                exits 0.
//   "stderr"  -> prints "polyc-rt01-err\n" to stderr,
//                exits 0.
//   "rc=N"    -> exits with N (decimal), no output.
//   "echo"    -> prints argv[2] verbatim to stdout,
//                exits 0.
//   default   -> prints help message to stderr, exits 2.
//
// This file contains NO test policy. It is a deterministic
// process-execution oracle only.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "rt01-child: missing mode\n");
    return 2;
  }
  if (strcmp(argv[1], "stdout") == 0) {
    printf("polyc-rt01-out\n");
    return 0;
  }
  if (strcmp(argv[1], "stderr") == 0) {
    fprintf(stderr, "polyc-rt01-err\n");
    return 0;
  }
  if (strncmp(argv[1], "rc=", 3) == 0) {
    return atoi(argv[1] + 3);
  }
  if (strcmp(argv[1], "echo") == 0) {
    if (argc < 3) {
      fprintf(stderr, "rt01-child: echo needs arg\n");
      return 2;
    }
    printf("%s\n", argv[2]);
    return 0;
  }
  fprintf(stderr, "rt01-child: unknown mode '%s'\n", argv[1]);
  return 2;
}
