#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char **argv) {
  if (argc < 3) return 2;
  long n = atol(argv[2]);
  char buf[4096];
  memset(buf, 'X', sizeof(buf));
  long remaining = n;
  while (remaining > 0) {
    ssize_t c = remaining > (long)sizeof(buf) ? (ssize_t)sizeof(buf) : (ssize_t)remaining;
    ssize_t w1 = write(1, buf, c);
    ssize_t w2 = write(2, buf, c);
    if (w1 < 0 || w2 < 0) break;
    remaining -= w1;
  }
  return 0;
}
