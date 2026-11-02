/* src/selfhost-driver-wp001.c
 *
 * ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
 *
 * THE MECHANICAL HOST BRIDGE FOR THE POLYC-AUTHORED DRIVER.
 *
 * WHAT THIS FILE IS: a mechanical shim. It provides the three byte
 * accessors the PolyC driver reads, and it mechanically fills the
 * existing CliArgs structure from the decision the PolyC driver made.
 *
 * WHAT THIS FILE IS NOT: it is not a second CLI policy. It contains
 * NO option table, NO option name, NO flag test, NO arity rule and NO
 * action selection. Every one of those decisions is made by the
 * compiled PolyC subject and read back through the seam.
 *
 * The field-code switch below maps a PolyC-chosen FIELD CODE onto one
 * CliArgs member. It is a mechanical assignment table, not a decision:
 * the CODE is chosen by PolyC, not here.
 */

#include <stddef.h>
#include <string.h>

#include "selfhost-driver-wp001.h"

/* ---------------------------------------------------------------------------
 * THE ARGUMENT STATE
 *
 * Set once, from main(), before the first PolyC call, and never mutated
 * afterwards. The borrowed byte pointers therefore stay valid for the
 * whole decision, and there is no global mutable argv decoder that
 * could reuse stale state.
 * ------------------------------------------------------------------------ */

static char **g_wp_argv = NULL;
static int g_wp_argc = 0;

void WpDriverHostSetArgv(int argc, char **argv) {
    g_wp_argc = argc;
    g_wp_argv = argv;
}

long long WpDriverHostArgc(void) {
    return (long long)g_wp_argc;
}

long long WpDriverHostArgLen(long long index) {
    if (index < 0 || index >= (long long)g_wp_argc) return 0;
    return (long long)strlen(g_wp_argv[index]);
}

unsigned char *WpDriverHostArgByte(long long index) {
    if (index < 0 || index >= (long long)g_wp_argc) return NULL;
    return (unsigned char *)g_wp_argv[index];
}

/* ---------------------------------------------------------------------------
 * THE VALUE COPIER
 *
 * Copies the option's value out of the argument vector into a fresh
 * heap string. The PolyC driver says WHICH argument holds the value
 * and at what OFFSET the value starts; this function only moves bytes.
 *
 * Returns NULL when the value is absent or the domain is violated.
 * ------------------------------------------------------------------------ */

char *WpDriverHostCopyValue(long long value_arg_index,
                             long long value_offset) {
    if (value_arg_index < 0) return NULL;
    if (value_arg_index >= (long long)g_wp_argc) return NULL;
    const char *base = g_wp_argv[value_arg_index];
    if (base == NULL) return NULL;
    size_t len = strlen(base);
    if (value_offset < 0) return NULL;
    if ((size_t)value_offset > len) return NULL;
    return strdup(base + value_offset);
}
