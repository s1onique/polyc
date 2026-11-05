/* tools/quality/fixtures/driver-required-route-correction03-zerofill-fixture.c
 *
 * ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
 * R5-03.
 *
 * THE GENUINE arm64 MIXED-ZERO-FILL FIXTURE.
 *
 * THE ORIGINAL COUNTEREXAMPLE. A genuine, platform-compiled arm64 object
 * containing virtual zero-fill sections was rejected with
 * `MACHO_SECTION_EXTENT_INVALID`. The macOS linker accepts that same
 * object, and the resulting executable returns 7.
 *
 * The object carries THREE kinds of section:
 *
 *   __text           file-backed    the ordinary code
 *   __thread_bss     S_THREAD_LOCAL_ZEROFILL (0x12)  a LARGE virtual
 *                    section: 256 KiB of zero-fill
 *   __thread_vars    S_THREAD_LOCAL_VARIABLES (0x13) a virtual section
 *
 * The large zero-fill section is the point of the fixture. The
 * PRE-REPAIR validator recorded EVERY section's extent and compared them
 * as FILE ranges, so the zero-fill section's VIRTUAL size was compared
 * against the file-backed `__text` section's FILE offset, and the two
 * "overlapped". The macOS linker does not make that comparison: a
 * zero-fill section occupies no file bytes at all.
 *
 * WHY THE ZERO-FILL SECTION IS A THREAD-LOCAL ONE. The arm64 target's
 * assembler emits a PLAIN `__bss` only when the compiler cannot prove
 * the section is unreferenced; an unreferenced plain `bss` array is
 * simply DROPPED, and an explicitly named one is emitted as an ordinary
 * file-backed `S_REGULAR` section with a file offset. A thread-local
 * zero-fill section is EMITTED RELIABLY, carries `S_THREAD_LOCAL_
 * ZEROFILL` (0x12), has a FILE OFFSET OF ZERO, and has a VIRTUAL size
 * that is the array's size. It is therefore the arm64 shape that
 * exercises the defect: a virtual section whose size exceeds the whole
 * file.
 *
 * The fixture is compiled by the PLATFORM'S OWN compiler for the arm64
 * target, and it is the REFERENCE for the R5-03 classification.
 */

/* A LARGE virtual zero-fill section: 256 KiB. */
__thread int tls_bss[65536] __attribute__((used));

/* An ordinary file-backed datum. */
int marker = 7;

int get_tls_bss(void) { return tls_bss[3]; }
int get_marker(void) { return marker; }
