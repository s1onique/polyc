/* src/holyc-lib/errno_shim.c
 *
 * ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02 — bounded
 *
 * Tiny C shim that exposes the libc errno accessor under a
 * HolyC-friendly name. The native symbol on macOS is __error
 * (leading double underscore) which the HolyC parser refuses
 * to accept as an identifier. On glibc the equivalent is
 * __errno_location. Linux portability is a separate ACT;
 * this file currently compiles only on macOS.
 *
 * The shim is compiled into libtos.a by adding it to the
 * install step in src/CMakeLists.txt (see the install(CODE
 * ...) block there).
 */
#include <errno.h>

int *Errno(void) {
#if defined(__APPLE__)
    return __error();
#elif defined(__linux__)
    return __errno_location();
#else
#error "Tooling runtime errno shim: unsupported platform"
#endif
}
