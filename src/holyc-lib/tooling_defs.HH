// src/holyc-lib/tooling_defs.HH
//
// ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01 C2 IMPL.
//
// Declaration-only header exposing the public surface of
// `tooling.HC` so that test harnesses can consume the API
// without dragging in the implementation source. This
// restores the library-ownership boundary that the harness
// was previously violating by `#include`-ing
// `../../src/holyc-lib/tooling.HC` (which transitively
// `#include`s `memory.HC` and pulls libtos implementation
// definitions into the harness object).
//
// This header MUST NOT include `memory.HC` or any other
// libtos source. It contains only:
//   - extern "c" prototypes (POSIX / C shims)
//   - class forward-decls and member declarations
//   - #define constants used by the public API
//   - public function prototypes (matching the bodies in
//     tooling.HC verbatim)
//
// All definitions live in `src/holyc-lib/tooling.HC` (and
// the libtos archive / dylib built from it). Linking
// against `-ltos` resolves the symbols.
//
// Note: `defs.HH` (basic-type and constant `#define`s) is
// included because the public-API signatures reference
// types like `I32`, `I64`, `U8`, etc. that are defined in
// the compiler's built-ins and aliased here. defs.HH is
// pure `#define`s; it does NOT pull in any implementation.

// ------------------------------------------------------------
// Type forward-decls (Fstat is in tos.HH; io_defs.HH provides
// it via the Stat/FileExists surface; tooling.HC only uses
// Fstat through io.HC's Stat, so tooling_defs.HH does not
// need to redeclare it).
// ------------------------------------------------------------

// ------------------------------------------------------------
// POSIX mechanism (libc) — bounded to ACT §5 hosts
// ------------------------------------------------------------

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

extern "c" I32 open(U8 *__name, I32 flags, ...);
extern "c" I64 read(I32 __fd, U0 *__buf, U64 __nbyte);

// CORRECTION02/CORRECTION03: errno accessor via a tiny C shim
// (see errno_shim.c). See tooling.HC for the full rationale.
extern "c" I32 *Errno();

// ------------------------------------------------------------
// Constants for waitpid decoding (POSIX).
// ------------------------------------------------------------

#define WIFEXITED_FLAG   0x00
#define W_EXITCODE_MASK  0xFF00
#define W_EXITCODE_SHIFT 8
#define W_TERMSIG_MASK   0x7F

// ------------------------------------------------------------
// Poll types and constants (mirror tooling.HC).
// ------------------------------------------------------------

class PollFd
{
  I32 fd;
  I16 events;
  I16 revents;
};

#define POLL_POLLIN   0x0001
#define POLL_POLLHUP  0x0010
#define POLL_POLLERR  0x0008
#define POLL_POLLNVAL 0x0020
#define POLL_CHUNK    4096

// Open flags (mirror io.HC; needed by TmpFile's fallback path).
#define O_RDONLY  0x0000
#define O_RDWR    0x0002
#define O_CREAT   0x0200
#define O_EXCL    0x0800

// ------------------------------------------------------------
// TmpFile fallback tries (mirror tooling.HC).
// ------------------------------------------------------------

#define POLYC_TMP_FALLBACK_TRIES 16

// ------------------------------------------------------------
// Public API (mirror tooling.HC signatures verbatim).
// ------------------------------------------------------------

public I32 PollIntr(U0 *fds, U64 nfds, I32 timeout);
public I32 ReadIntr(I32 fd, U0 *buf, U64 n);
public I32 WaitPidIntr(I32 pid, I32 *status, I32 options);
public Bool Contains(U8 *haystack, U8 *needle);
public I64 WaitDecode(I32 status);
public I32 TmpFile(U8 *dir, U8 *prefix, U8 **out_path);
public I64 SpawnAndCapture(U8 *program, U8 **args,
                           U8 **out, U8 **err);
public Bool FileExists(U8 *path);
