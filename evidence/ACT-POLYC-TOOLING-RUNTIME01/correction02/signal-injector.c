#define _GNU_SOURCE
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <pthread.h>
#include <errno.h>

extern int SpawnAndCapture(const char *program, char *const args[],
                           char **out, char **err);

static void noop(int sig) { (void)sig; }

// Worker thread: continuously sends SIGALRM to the main thread until
// the "stop" flag is set. This guarantees SIGALRM hits the parent
// many times WHILE it is in the SpawnAndCapture drain loop.
static volatile int g_stop = 0;
static pthread_t g_self;
static void *spammer(void *arg) {
  (void)arg;
  while (!g_stop) {
    pthread_kill(g_self, SIGALRM);
    usleep(1000);  // 100us between sends
  }
  return NULL;
}

int main(int argc, char **argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: signal-injector PROG ARGV0... [ARGV1...]\n");
    return 2;
  }
  // Block SIGALRM in all threads BEFORE creating the spammer,
  // so the spawn/fork/setup is not interrupted.
  sigset_t block_set;
  sigemptyset(&block_set);
  sigaddset(&block_set, SIGALRM);
  pthread_sigmask(SIG_BLOCK, &block_set, NULL);

  struct sigaction sa = {0};
  sa.sa_handler = noop;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGALRM, &sa, NULL);

  // args[0] = program path
  int n_user = argc - 2;
  int nargs = n_user + 1;
  char **args = calloc(nargs + 1, sizeof(char *));
  args[0] = (char *)argv[1];
  for (int i = 0; i < n_user; i++) args[1 + i] = argv[2 + i];
  args[nargs] = NULL;

  char *out = NULL, *err = NULL;

  // Start spammer thread
  g_self = pthread_self();
  pthread_t tid;
  pthread_create(&tid, NULL, spammer, NULL);

  // Unblock SIGALRM in main thread only — now SIGALRM will hit during
  // the drain loop. The spammer thread has SIGALRM blocked.
  pthread_sigmask(SIG_UNBLOCK, &block_set, NULL);

  int rc = SpawnAndCapture(argv[1], args, &out, &err);

  // Stop spammer, re-block so teardown is clean
  g_stop = 1;
  pthread_sigmask(SIG_BLOCK, &block_set, NULL);
  pthread_join(tid, NULL);

  size_t out_len = out ? strlen(out) : 0;
  size_t err_len = err ? strlen(err) : 0;
  printf("rc=%d out=%zu err=%zu\n", rc, out_len, err_len);
  free(out); free(err); free(args);
  return 0;
}
