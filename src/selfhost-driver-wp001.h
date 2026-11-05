/* src/selfhost-driver-wp001.h
 *
 * ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
 *
 * THE C-FACING DECLARATION OF THE POLYC-AUTHORED DRIVER.
 *
 * This header declares the seam and nothing else. It contains NO
 * option table, NO flag test, NO arity rule and NO action policy: every
 * one of those decisions lives in the compiled PolyC subject
 * tools/bootstrap/selfhost-driver-wp001.HC.
 *
 * The PolyC subject exports (the machine symbol carries a leading
 * underscore on Mach-O; the C identifier does not):
 *
 *   WpDriverClassifyOption(argc_index)   the option-name match decision
 *   WpDriverValueArgIndex(argc_index)     the value index, domain-checked
 *   WpDriverValueOffset(argc_index, opt)  where the value starts
 *   WpDriverOptionField(opt)              which CliArgs field to set
 *   WpDriverOptionAction(opt)             which action the option selects
 *   WpDriverSelectAction()                the whole-argv action decision
 *   WpDriverMapStatus(action)             the status mapping
 *   WpDriverDecide()                      the single entry point
 *   WpDriverSelectedAction()              the selected action code
 *   WpDriverSelectedEmission()            the selected ARTIFACT CLASS
 *
 * The host side (implemented in src/selfhost-driver-wp001.c) provides
 * three mechanical byte accessors and NOTHING else:
 *
 *   WpDriverHostArgc()
 *   WpDriverHostArgLen(idx)
 *   WpDriverHostArgByte(idx)
 */

#ifndef SELFHOST_DRIVER_WP001_H
#define SELFHOST_DRIVER_WP001_H

#include <stdint.h>

/* The PolyC subject's exports. The C declaration drops the leading
 * underscore that Mach-O adds; the two spellings are the SAME symbol. */
extern long long WpDriverClassifyOption(long long arg_index);
extern long long WpDriverClassifyArgument(long long arg_index);
extern long long WpDriverUnknownArgCount(void);
extern long long WpDriverArityViolationCount(void);
extern long long WpDriverValueArgIndex(long long arg_index);
extern long long WpDriverValueOffset(long long arg_index, long long opt_index);
extern long long WpDriverOptionField(long long opt_index);
extern long long WpDriverOptionAction(long long opt_index);
extern long long WpDriverSelectAction(void);
extern long long WpDriverMapStatus(long long action);
extern long long WpDriverDecide(void);
extern long long WpDriverSelectedAction(void);
extern long long WpDriverSelectedEmission(void);

/* ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.
 *
 * THE DRIVER PLAN.
 *
 * The plan is the WHOLE-CLI route decision, as an ORDERED list of
 * steps. It is the compiled PolyC driver's decision, and the C host
 * consumes it mechanically: the host executes the plan's step and
 * never decides whether the step applies.
 *
 *   WpDriverPlanActionCount()  the number of steps in the plan
 *   WpDriverPlanActionAt(i)    the step code at index i
 *   WpDriverPlanArgAt(i)       the argument index that caused step i
 *   WpDriverSelectedRoute()    the selected route, as a single code
 *   WpDriverPlanStatus()       the status for the whole argv
 *
 * The plan is rebuilt on demand, so a caller always reads the CURRENT
 * argv's plan. The plan is deterministic: identical argv yields an
 * identical plan.
 *
 * The plan's step codes are DISJOINT from the action domain and from
 * the status domain, so an out-of-domain step can never be confused
 * with a valid one. */
extern long long WpDriverPlanActionCount(void);
extern long long WpDriverPlanActionAt(long long index);
extern long long WpDriverPlanArgAt(long long index);
extern long long WpDriverSelectedRoute(void);
extern long long WpDriverPlanStatus(void);

/* The plan's step codes, mirrored from the PolyC subject.
 *
 * The values are SOURCE VALUES of the driver's step encoding. They
 * are DISJOINT from both the action domain and the status domain. */
#define WP_DRIVER_STEP_INVALID        0
#define WP_DRIVER_STEP_ASSEMBLE       1
#define WP_DRIVER_STEP_REPL           2
#define WP_DRIVER_STEP_PRINT_TOKENS   3
#define WP_DRIVER_STEP_TRANSPILE      4
#define WP_DRIVER_STEP_PRINT_AST      5
#define WP_DRIVER_STEP_DUMP_IR        6
#define WP_DRIVER_STEP_DUMP_IR_POOLED 7
#define WP_DRIVER_STEP_CFG            8
#define WP_DRIVER_STEP_EMIT_LLVM      9
#define WP_DRIVER_STEP_JIT           10
#define WP_DRIVER_STEP_COMPILE       11

/* The step domain's member count. The bound exists so the C side can
 * REJECT a step the driver did not select. Without it, an
 * out-of-domain step matches none of the dispatch cases and the
 * compiler would fall through to the default route -- a FAIL-OPEN in
 * which the PolyC authority is silently absent and the legacy C
 * policy runs anyway. */
#define WP_DRIVER_STEP_COUNT 12

/* The argument classification, mirrored from the PolyC subject so the
 * C side can route an argument without re-deciding what it is. The
 * values are SOURCE VALUES of the driver's classification encoding. */
#define WP_DRIVER_ARG_OPTION  1
#define WP_DRIVER_ARG_SOURCE  2
#define WP_DRIVER_ARG_OBJECT  3
#define WP_DRIVER_ARG_UNKNOWN 4

/* The status domain, mirrored from the PolyC subject so the C side can
 * name the statuses without inventing a parallel policy. The values
 * are SOURCE VALUES of the driver's status encoding, not a layout
 * assumption. */
#define WP_DRIVER_STATUS_OK       0
#define WP_DRIVER_STATUS_USAGE    1
#define WP_DRIVER_STATUS_COMPILE  2
#define WP_DRIVER_STATUS_ARITY    3
#define WP_DRIVER_STATUS_NO_INPUT 4
#define WP_DRIVER_STATUS_ENGINE   5

/* ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.
 *
 * The `-o-` output target REQUIRES `-S`. This condition was decided by
 * the C side, because the status domain could not express it, and a C
 * policy that fired without consulting the PolyC-selected status could
 * PREEMPT that status.
 *
 * The status domain expresses it now. The value is the SAME SOURCE
 * VALUE as the PolyC subject's WP_STATUS_TO_STDOUT, and it is the
 * LARGEST member, so it is DISJOINT from every other status.
 */
#define WP_DRIVER_STATUS_TO_STDOUT 6

/* ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02, C3.
 *
 * The EXCLUSIVE UPPER BOUND of the status domain. The domain is
 * { 0 .. WP_DRIVER_STATUS_COUNT-1 } and the count is the number of
 * distinct status members, so the bound and the member count cannot
 * drift apart.
 *
 * The bound exists so that the C side can REJECT a status the driver
 * did not select. Without it, the status dispatch is a set of positive
 * equality tests: a status OUTSIDE the domain matches none of them,
 * and the compiler PROCEEDS as if the driver had selected OK. That is
 * a FAIL-OPEN -- the authority is silently absent and the requested
 * work is performed anyway.
 *
 * AC36 requires an invalid status to FAIL CLOSED: no artifact, no
 * fallback. The bound is what makes that check expressible.
 */
#define WP_DRIVER_STATUS_COUNT 8

/* ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.
 *
 * The emit-LLVM MUTUAL-EXCLUSION status.
 *
 * The live compiler decided that `--emit-llvm` may not be composed
 * with -jit/-repl/-run/-S/-c/-lib/-transpile/-lsp, and it reported
 * that condition with its own diagnostic and its own exit status.
 * The condition is a decision about the argv, so it is the DRIVER's
 * decision now, and the C host renders the diagnostic the driver
 * selected.
 *
 * This member is the LARGEST value, so it is DISJOINT from every
 * pre-existing status and cannot be confused with a valid one. */
#define WP_DRIVER_STATUS_EMIT_LLVM_CONFLICT 7

/* The action domain, mirrored the same way. */

/* The EMISSION domain, mirrored the same way. It is DISJOINT from both
 * the action domain and the status domain: 0 is the absent/invalid
 * sentinel and every valid emission is >= 1. */
#define WP_DRIVER_EMIT_UNKNOWN        0
#define WP_DRIVER_EMIT_COMPILE_OBJECT 1
#define WP_DRIVER_EMIT_EXECUTE        2
#define WP_DRIVER_EMIT_ASSEMBLY       3
#define WP_DRIVER_EMIT_DYLIB          4

#define WP_DRIVER_ACTION_COMPILE_OBJECT 1
#define WP_DRIVER_ACTION_NONE           20

/* The field codes, mirrored the same way. The C bridge maps each code
 * to exactly one CliArgs member. */
#define WP_DRIVER_FIELD_NONE             0
#define WP_DRIVER_FIELD_PRINT_AST        1
#define WP_DRIVER_FIELD_PRINT_TOKENS     2
#define WP_DRIVER_FIELD_CFG_CREATE       3
#define WP_DRIVER_FIELD_CFG_PNG          4
#define WP_DRIVER_FIELD_CFG_SVG          5
#define WP_DRIVER_FIELD_ASSEMBLE_ONLY    6
#define WP_DRIVER_FIELD_WERROR           7
#define WP_DRIVER_FIELD_EMIT_DYLIB       8
#define WP_DRIVER_FIELD_EMIT_OBJECT      9
#define WP_DRIVER_FIELD_RUN             10
#define WP_DRIVER_FIELD_JIT             11
#define WP_DRIVER_FIELD_MEMSAFE         12
#define WP_DRIVER_FIELD_REPL            13
#define WP_DRIVER_FIELD_LSP             14
#define WP_DRIVER_FIELD_ASSEMBLE        15
#define WP_DRIVER_FIELD_TRANSPILE       16
#define WP_DRIVER_FIELD_TO_STDOUT       17
#define WP_DRIVER_FIELD_OUTPUT_FILENAME 18
#define WP_DRIVER_FIELD_CLIBS           19
#define WP_DRIVER_FIELD_DEFINES_LIST    20
#define WP_DRIVER_FIELD_TARGET          21
#define WP_DRIVER_FIELD_INSTALL_DIR     22
#define WP_DRIVER_FIELD_DUMP_IR         23
#define WP_DRIVER_FIELD_DUMP_IR_POOLED  24
#define WP_DRIVER_FIELD_EMIT_LLVM       25
#define WP_DRIVER_FIELD_CAP_TABLE       26
#define WP_DRIVER_FIELD_MEM_STATS       27
#define WP_DRIVER_FIELD_HELP            28
#define WP_DRIVER_FIELD_VERSION         29
#define WP_DRIVER_FIELD_TERRY           30
#define WP_DRIVER_FIELD_USE_LEGACY_X86  31
#define WP_DRIVER_FIELD_FPIC            32

/* The host-side byte accessors, implemented in
 * src/selfhost-driver-wp001.c. */
long long WpDriverHostArgc(void);
long long WpDriverHostArgLen(long long index);
unsigned char *WpDriverHostArgByte(long long index);

/* Install the argument vector the byte accessors read. It is called
 * once, from main(), before the first PolyC call. */
void WpDriverHostSetArgv(int argc, char **argv);

/* Copy the option's value out of the argument vector into a fresh heap
 * string. The PolyC driver says WHICH argument holds the value and at
 * what OFFSET the value starts; this function only moves bytes. It
 * returns NULL when the value is absent or the domain is violated. */
char *WpDriverHostCopyValue(long long value_arg_index,
                             long long value_offset);

#endif /* SELFHOST_DRIVER_WP001_H */
