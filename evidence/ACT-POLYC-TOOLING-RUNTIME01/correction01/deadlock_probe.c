// deadlock_probe.c -- stress fixture for SpawnAndCapture.
//
// Mode "stderr-flood": emits a configurable amount of
// data to stderr (default 4 MiB), keeps stdout open,
// then prints a sentinel line on stdout and exits 0.
//
// Mode "stdout-flood": symmetric case.
//
// Mode "interleave":  alternates stderr/stdout chunks.
//
// Used to mechanically prove that the drain-stdout-
// then-drain-stderr pattern does not deadlock.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CHUNK 8192

static void emit(FILE *f, long nbytes) {
  char buf[CHUNK];
  memset(buf, 'X', sizeof(buf));
  while (nbytes > 0) {
    long take = nbytes < (long)sizeof(buf) ? nbytes : (long)sizeof(buf);
    fwrite(buf, 1, (size_t)take, f);
    nbytes -= take;
  }
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "deadlock_probe: missing mode\n");
    return 2;
  }
  long nbytes = 4L * 1024L * 1024L;   // 4 MiB default
  if (argc >= 3) {
    long v = atol(argv[2]);
    if (v > 0) nbytes = v;
  }

  if (strcmp(argv[1], "stderr-flood") == 0) {
    // stdout open + quiet
    fprintf(stdout, "stdout-sentinel\n");
    fflush(stdout);
    // flood stderr
    emit(stderr, nbytes);
    fprintf(stderr, "stderr-sentinel\n");
    fflush(stderr);
    return 0;
  }
  if (strcmp(argv[1], "stdout-flood") == 0) {
    // flood stdout
    emit(stdout, nbytes);
    fprintf(stdout, "stdout-sentinel\n");
    fflush(stdout);
    // stderr open + quiet
    fprintf(stderr, "stderr-sentinel\n");
    fflush(stderr);
    return 0;
  }
  if (strcmp(argv[1], "interleave") == 0) {
    long chunks = nbytes / CHUNK;
    for (long i = 0; i < chunks; ++i) {
      fprintf(stdout, "S%ld\n", i);
      fprintf(stderr, "E%ld\n", i);
    }
    fprintf(stdout, "stdout-sentinel\n");
    fprintf(stderr, "stderr-sentinel\n");
    fflush(stdout);
    fflush(stderr);
    return 0;
  }

  fprintf(stderr, "deadlock_probe: unknown mode '%s'\n", argv[1]);
  return 2;
}
