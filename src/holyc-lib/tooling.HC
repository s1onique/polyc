// src/holyc-lib/tooling.HC
//
// ACT-POLYC-TOOLING-RUNTIME01 C2 IMPL.
//
// Tooling-runtime primitives for a PolyC-native test
// harness. Direct-argv process execution; race-safe
// temp files; multi-byte substring search; verdict
// aggregation.
//
// Contract: evidence/ACT-POLYC-TOOLING-RUNTIME01
//            api-shape-freeze.txt (under c1/)
//
// NO shell parsing. NO /bin/sh -c. NO system().
//   System / Sh / Shlurp remain in system.HC for
//   legacy callers but are FORBIDDEN in any new code
//   path that needs deterministic subprocess semantics.

#include "./defs.HH"
#include "./memory.HC"

// ------------------------------------------------------------
// POSIX mechanism (libc) — bounded to ACT §5 hosts
// ------------------------------------------------------------

// These prototypes are pure C and resolve through libc
// on macOS and Linux. Both are POSIX 2008+. We do NOT
// depend on a libc that lacks them.

extern "c" I32 fork();
extern "c" I32 pipe(I32 *fds);
extern "c" I32 dup2(I32 oldfd, I32 newfd);
extern "c" I32 close(I32 fd);
extern "c" I32 execv(U8 *path, U8 **argv);
extern "c" I32 waitpid(I32 pid, I32 *status, I32 options);
extern "c" I32 mkstemp(U8 *template);
extern "c" U0 _exit(I32 status);

extern "c" U8 *strstr(U8 *haystack, U8 *needle);

extern "c" I32 getpid();
extern "c" I32 poll(U0 *fds, U64 nfds, I32 timeout);

// Constants for waitpid decoding (POSIX).
#define WIFEXITED_FLAG   0x00   // status low byte is exit code
#define W_EXITCODE_MASK  0xFF00 // bits 8..15 hold exit code
#define W_EXITCODE_SHIFT 8
#define W_TERMSIG_MASK   0x7F   // bits 0..6 hold signal number

// ------------------------------------------------------------
// P-CONTAINS: substring search (libc strstr wrapper)
// ------------------------------------------------------------

public Bool Contains(U8 *haystack, U8 *needle)
{
  if (!haystack || !needle) return FALSE;
  if (needle[0] == 0) return TRUE;  // empty needle is "always present"
  if (strstr(haystack, needle) != NULL)
    return TRUE;
  return FALSE;
}

// ------------------------------------------------------------
// P-WAITDEC: waitpid status -> PolyC exit code
// ------------------------------------------------------------

public I64 WaitDecode(I32 status)
{
  // On POSIX the termination status is laid out as:
  //   bits 0..6   : signal number (if WIFSIGNALED)
  //   bits 7      : core dump flag
  //   bits 8..15  : exit code    (if WIFEXITED)
  //
  // WIFEXITED == (status & 0x7f) == 0
  if ((status & 0x7f) == 0) {
    // Normal exit. Extract the exit code from bits 8..15.
    return (status >> 8) & 0xff;
  }
  // Abnormal termination: signal number.
  return 128 + (status & 0x7f);
}

// ------------------------------------------------------------
// P-TMP: race-safe temporary file
// ------------------------------------------------------------
//
// Returns an open fd and writes the resolved path into
// *out_path (caller owns *out_path; Free() it).
// Uses mkstemp() when the template suffix is suitable.
// Falls back to a unique-name strategy with
// O_CREAT|O_EXCL if mkstemp() fails.

#define POLYC_TMP_FALLBACK_TRIES 16

public I32 TmpFile(U8 *dir, U8 *prefix, U8 **out_path)
{
  U8 *tpl;
  I32 fd;

  if (!dir || !prefix || !out_path) return -1;
  *out_path = NULL;

  // mkstemp() requires the last 6 chars of the template
  // to be "XXXXXX".
  tpl = StrPrint(NULL, "%s/%sXXXXXX", dir, prefix);
  fd = mkstemp(tpl);
  if (fd >= 0) {
    *out_path = tpl;
    return fd;
  }
  // mkstemp() failed; fall back to a unique-name loop.
  Free(tpl);

  for (I32 i = 0; i < POLYC_TMP_FALLBACK_TRIES; ++i) {
    tpl = StrPrint(NULL, "%s/%s%d%d", dir, prefix, getpid(), i);
    // O_RDWR | O_CREAT | O_EXCL -- exclusive create.
    fd = open(tpl, O_RDWR | O_CREAT | O_EXCL, 384); // 0600
    if (fd >= 0) {
      *out_path = tpl;
      return fd;
    }
    Free(tpl);
  }
  return -1;
}

// ------------------------------------------------------------
// P-SPAWN: SpawnAndCapture
// ------------------------------------------------------------
//
// Direct-argv subprocess execution with separate stdout
// and stderr capture. No shell.
//
// Returns:
//   - exit code (0..255) on normal exit
//   - 127 on missing/exec-failed child
//     (Note: an executed child that legitimately
//      exits 127 cannot be distinguished from an
//      execv failure under the current contract.
//      See c4/residue.txt for the P2 follow-up.)
//   - 128 + signum on abnormal termination
//   - -1 on parent-side fork failure
//
// On success, *out and *err point to malloc'd,
// NUL-terminated buffers (caller must Free).
// Either or both may be NULL on spawn failure.
//
// IMPORTANT: stdout and stderr are drained CONCURRENTLY
// via poll(). The original implementation drained stdout
// fully before draining stderr, which deadlocks whenever
// stderr fills the pipe buffer while stdout remains
// open (POSIX pipe capacity is bounded; pipe(7) warns
// that applications must not rely on it). CORRECTION01.

class PollFd
{ /* struct pollfd */
  I32 fd;
  I16 events;
  I16 revents;
};

#define POLL_POLLIN  0x0001
#define POLL_POLLHUP 0x0010
#define POLL_POLLERR 0x0008
#define POLL_POLLNVAL 0x0020
#define POLL_CHUNK   4096

public I64 SpawnAndCapture(U8 *program, U8 **args,
                           U8 **out, U8 **err)
{
  I32 out_fd[2], err_fd[2];
  I32 pid;
  I32 status = 0;
  I64 rc = -1;
  U8 *out_buf = NULL;
  U8 *err_buf = NULL;
  I64 out_len = 0, err_len = 0;
  U8 chunk[POLL_CHUNK];
  I64 n;

  if (out) *out = NULL;
  if (err) *err = NULL;

  if (!program || !args) return -1;
  if (pipe(out_fd) != 0) return -1;
  if (pipe(err_fd) != 0) {
    close(out_fd[0]); close(out_fd[1]);
    return -1;
  }

  pid = fork();
  if (pid < 0) {
    close(out_fd[0]); close(out_fd[1]);
    close(err_fd[0]); close(err_fd[1]);
    return -1;
  }

  if (pid == 0) {
    // ----- child -----
    dup2(out_fd[1], 1);     // stdout -> pipe
    dup2(err_fd[1], 2);     // stderr -> pipe
    close(out_fd[0]);
    close(out_fd[1]);
    close(err_fd[0]);
    close(err_fd[1]);
    execv(program, args);
    // execv failed; signal to parent via 127.
    _exit(127);
  }

  // ----- parent -----
  // Close the write ends; we only read.
  close(out_fd[1]);
  close(err_fd[1]);

  // Concurrent drain via poll(2).
  //
  // POLLHUP may fire WHILE the kernel still has buffered
  // bytes in the pipe (writer closed, but we have not
  // consumed the buffer yet). Closing on POLLHUP without
  // draining loses those bytes. Correct policy: on any
  // event (POLLIN / POLLHUP / POLLERR), attempt a read;
  // only close when read returns 0 (true EOF).
  PollFd pfds[2];
  pfds[0].fd = out_fd[0];
  pfds[0].events = POLL_POLLIN;
  pfds[0].revents = 0;
  pfds[1].fd = err_fd[0];
  pfds[1].events = POLL_POLLIN;
  pfds[1].revents = 0;
  Bool out_open = TRUE, err_open = TRUE;

  while (out_open || err_open) {
    I32 nfd = poll(pfds, 2, -1);
    if (nfd < 0) break;

    // stdout
    if (out_open) {
      I16 r = pfds[0].revents;
      if (r & (POLL_POLLIN | POLL_POLLHUP | POLL_POLLERR)) {
        n = read(out_fd[0], chunk, POLL_CHUNK);
        if (n > 0) {
          out_buf = ReAlloc(out_buf, out_len + n + 1);
          MemCpy(out_buf + out_len, chunk, n);
          out_len += n;
        } else {
          // n == 0 (EOF) or n < 0 (error); in both cases
          // the writer is gone — close this fd.
          out_open = FALSE;
          close(out_fd[0]);
          pfds[0].fd = -1;
        }
      }
    }
    // stderr
    if (err_open) {
      I16 r = pfds[1].revents;
      if (r & (POLL_POLLIN | POLL_POLLHUP | POLL_POLLERR)) {
        n = read(err_fd[0], chunk, POLL_CHUNK);
        if (n > 0) {
          err_buf = ReAlloc(err_buf, err_len + n + 1);
          MemCpy(err_buf + err_len, chunk, n);
          err_len += n;
        } else {
          err_open = FALSE;
          close(err_fd[0]);
          pfds[1].fd = -1;
        }
      }
    }
  }
  // Defensive close (in case we exited via nfd<0).
  if (out_open) close(out_fd[0]);
  if (err_open) close(err_fd[0]);

  if (out_buf) out_buf[out_len] = 0;
  else { out_buf = MAlloc(1); out_buf[0] = 0; }
  if (err_buf) err_buf[err_len] = 0;
  else { err_buf = MAlloc(1); err_buf[0] = 0; }

  // Wait for child.
  if (waitpid(pid, &status, 0) < 0) {
    if (out) *out = out_buf;
    if (err) *err = err_buf;
    return -1;
  }

  if (out) *out = out_buf;
  if (err) *err = err_buf;
  return WaitDecode(status);
}

// ------------------------------------------------------------
// FileExists: thin stat() wrapper
// ------------------------------------------------------------

public Bool FileExists(U8 *path)
{
  Fstat fst;
  if (!path) return FALSE;
  return Stat(&fst, path) == 0;
}

