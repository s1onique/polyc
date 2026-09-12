/*
 * ACT-POLYC-AOT-PIC-EXTERNAL-REFS01 C1 / §3.1 external producer.
 *
 * Ordinary C dylib with a single non-PolyC-runtime function. Built as
 * libpolyc-extref.dylib; no libtos linkage, no PolyC headers.
 *
 * The consumer PolyC source references PolycExtAdd1 by name; the link
 * failure reproduces the production "invalid use of ADRP" defect when
 * the consumer's AOT codegen materialises the function address via
 * adrp/add instead of a Mach-O-valid external-reference strategy.
 */
#include <stdint.h>

int64_t PolycExtAdd1(int64_t x) {
    return x + 1;
}
