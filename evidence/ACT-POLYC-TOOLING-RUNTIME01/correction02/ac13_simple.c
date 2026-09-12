#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern int SpawnAndCapture(const char *program, char *const args[],
                           char **out, char **err);

int main(int argc, char **argv) {
  if (argc < 2) return 2;
  int n_user = argc - 2;
  int nargs = n_user + 1;
  char **args = calloc(nargs + 1, sizeof(char *));
  args[0] = (char *)argv[1];
  for (int i = 0; i < n_user; i++) args[1 + i] = argv[2 + i];
  args[nargs] = NULL;
  char *out = NULL, *err = NULL;
  int rc = SpawnAndCapture(argv[1], args, &out, &err);
  size_t ol = out ? strlen(out) : 0;
  size_t el = err ? strlen(err) : 0;
  printf("rc=%d out=%zu err=%zu\n", rc, ol, el);
  free(out); free(err); free(args);
  return 0;
}
