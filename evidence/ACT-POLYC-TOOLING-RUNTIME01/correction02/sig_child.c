#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void flood(int fd, long nbytes) {
  char buf[4096];
  memset(buf, 'X', sizeof(buf));
  long remaining = nbytes;
  while (remaining > 0) {
    ssize_t chunk = remaining > (long)sizeof(buf)
                      ? (ssize_t)sizeof(buf)
                      : (ssize_t)remaining;
    ssize_t w = write(fd, buf, (size_t)chunk);
    if (w < 0) break;
    remaining -= w;
  }
}

int main(int argc, char **argv) {
  if (argc < 2) { fprintf(stderr, "missing mode\n"); return 2; }
  if (strncmp(argv[1], "stderr-flood-", 13) == 0) {
    long n = atol(argv[1] + 13);
    if (argc >= 3) n = atol(argv[2]);
    flood(2, n); return 0;
  }
  if (strncmp(argv[1], "stdout-flood-", 13) == 0) {
    long n = atol(argv[1] + 13);
    if (argc >= 3) n = atol(argv[2]);
    flood(1, n); return 0;
  }
  if (strncmp(argv[1], "rc=", 3) == 0) return atoi(argv[1] + 3);
  if (strcmp(argv[1], "sigterm") == 0) {
    // Sleep; default SIGTERM handler kills us. Test then sees
    // a signal-killed exit (rc = 128 + SIGTERM = 143).
    while (1) pause();
  }
  if (strcmp(argv[1], "sigabrt") == 0) { raise(SIGABRT); return 0; }
  fprintf(stderr, "unknown mode '%s'\n", argv[1]); return 2;
}
