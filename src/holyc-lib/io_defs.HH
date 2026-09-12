// src/holyc-lib/io_defs.HH
//
// ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01 C2 IMPL.
//
// Declaration-only header exposing the public surface of
// `io.HC` so that test harnesses can consume the API without
// dragging in the implementation source (which transitively
// `#include`s `memory.HC`).
//
// This header MUST NOT include `memory.HC` or any other
// libtos source. Definitions live in `src/holyc-lib/io.HC`
// and resolve at link time via `-ltos`.
//
// Tooling runtime's public io surface used by external
// harnesses:

public class Fstat;

extern "c" I32 open(U8 *__name, I32 flags, ...);
extern "c" I32 creat(U8 *__name, U16 __flags);
extern "c" I32 fcntl(I32 __fd, I32 __flags, ...);
extern "c" I32 close(I32 __fd);
extern "c" I64 read(I32 __fd, U0 *__buf, U64 __nbyte);
extern "c" I64 write(I32 __fd, U0 *__buf, U64 __nbyte);
extern "c" I64 lseek(I32 __fd, I64 __offset, I32 __whence);
extern "c" I32 chdir(U8 *path);
extern "c" I8 *getcwd(U8 *buf, U64 size);
extern "c" I8 *getenv(U8 *buf);
extern "c" I32 isatty(I32 fd);

// Open flags (mirror io.HC).
#define O_RDONLY  0x0000
#define O_WRONLY  0x0001
#define O_RDWR    0x0002
#define O_ACCMODE 0x0003
#define O_CREAT   0x0200
#define O_TRUNC   0x0400
#define O_EXCL    0x0800
#define O_NONBLOCK 0x004
#define O_APPEND   0x008

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

// Public API (mirror io.HC signatures verbatim).
public U8 *FileRead(U8 *path, I64 *_size);
public Bool FileWrite(U8 *filename, U8 *buf, I64 size,
                      Bool append=FALSE);
public I32 Cd(U8 *path);
public U8 *Pwd(U8 *buf, U64 buf_size);
public I32 Stat(Fstat *fst, U8 *pathname);
public I64 Dir(U8 *pathname);
