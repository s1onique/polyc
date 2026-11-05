/* tools/quality/fixtures/driver-required-route-correction03-tls-fixture.c
 *
 * ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-10.
 *
 * THE GENUINE arm64 THREAD-LOCAL FIXTURE.
 *
 * The source is C, because the production compiler does not spell a
 * thread-local variable. The fixture is compiled by the PLATFORM'S OWN
 * compiler for the arm64 target, and it is the REFERENCE for the R4-10
 * section classification.
 *
 * The object carries two thread-local sections:
 *
 *   __thread_data   type 0x11  S_THREAD_LOCAL_REGULAR        FILE-BACKED
 *   __thread_vars   type 0x13  S_THREAD_LOCAL_VARIABLES      FILE-BACKED
 *
 * Both types are FILE-BACKED. The PRE-REPAIR validator classified 0x11
 * correctly but classified 0x13, 0x14, 0x15 and 0x16 as VIRTUAL, and it
 * therefore never bounded their file extents. The corrected validator
 * classifies them as file-backed, and it MUST still ACCEPT this genuine
 * object -- which is what the control proves.
 */
__thread long tls_value = 42;

long get_tls(void) {
  return tls_value;
}
