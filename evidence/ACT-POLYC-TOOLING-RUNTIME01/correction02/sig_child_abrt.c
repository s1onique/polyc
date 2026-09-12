#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char **argv) {
  if (argc < 2) return 2;
  if (strcmp(argv[1], "sigabrt") == 0) { raise(SIGABRT); return 0; }
  return 2;
}
