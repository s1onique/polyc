#ifndef LLVM_BACKEND_H__
#define LLVM_BACKEND_H__

/* ACT-POLYC-LLVM-SPIKE01-RESUME01: minimal LLVM 22 C-API emitter.
 *
 * The public surface is intentionally narrow. The PolyC compiler
 * never sees LLVM types - it asks this module to lower a PolyC
 * module (already lowered into the backend-neutral IR) into
 * verifier-clean textual LLVM IR, and writes the result either to
 * a FILE * or to a path.
 *
 * No native assembly, no object emission, no ORC, no JIT, no LLVM
 * optimization pipeline. No aggregate / pointer / float support.
 * No PHI nodes. No target machine. No data layout.
 *
 * The lowerer's contract:
 *
 *   input: a Cctrl * with cc->ast_list populated by the parser
 *   walks: irLowerFunction on every AST_FUNC, exactly like
 *          --dump-ir / irDumpWithFakePool
 *   emits: a single LLVMModuleRef containing every supported
 *          function, with verification + serialization
 *
 * Returns:
 *   0  on success (verified + serialized)
 *  >0  on explicit failure (with a diagnostic written to stderr)
 *
 * The backend writes to out_fp if non-NULL, otherwise to out_path
 * if non-NULL, otherwise to stdout. Exactly one must be set.
 */

#include <stdio.h>
#include "ir-types.h"

int llvmEmitProgram(IrProgram *prog,
                    Cctrl *cc,
                    FILE *out_fp,
                    const char *out_path);

/* Diagnostic codes. Surfaced via the compiler's existing stderr
 * style. Mirrored here so scripts can grep for them. */
#define LLVM_BACKEND_UNSUPPORTED_IR    "LLVM_BACKEND_UNSUPPORTED_IR"
#define LLVM_BACKEND_UNSUPPORTED_TYPE  "LLVM_BACKEND_UNSUPPORTED_TYPE"
/* ACT-POLYC-LLVM-CORE03: defensive invariant guard fired.
 * The dispatch observed a value shape that the canonical
 * lowerer is not supposed to produce (e.g. a non-i1 cond at
 * the IR_BR arm). The dispatch continues with the existing
 * fallback (trunc + condbr), but the diagnostic makes the
 * violation visible. The supported subset must keep this
 * counter at zero; the harness asserts it. */
#define LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED \
    "LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED"
#define LLVM_BACKEND_VERIFY_FAILED     "LLVM_BACKEND_VERIFY_FAILED"
#define LLVM_BACKEND_INTERNAL          "LLVM_BACKEND_INTERNAL"
/* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
 * scalar SSA lowering rejects local shapes that would require
 * a stack slot, PHI, or address-taken semantics. Surfaced as an
 * explicit diagnostic rather than silently falling back to
 * LLVMBuildAlloca / LLVMBuildStore / LLVMBuildLoad2. */
#define LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL \
    "LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL"
#define LLVM_BACKEND_INTERNAL_UNBOUND_VALUE \
    "LLVM_BACKEND_INTERNAL_UNBOUND_VALUE"

/* ACT-POLYC-LLVM-CORE01:
 * Named class-specific rejection diagnostics. The CORE contract
 * requires that every REJECTED opcode be identified by a named
 * token, not the generic LLVM_BACKEND_UNSUPPORTED_IR fallback.
 * The generic token remains as a safety net for opcodes not yet
 * assigned a class.
 *
 * One token per REJECTED opcode class. Each token MUST appear on
 * stderr when the corresponding opcode class is encountered. */
#define LLVM_BACKEND_UNSUPPORTED_INT_DIVISION  "LLVM_BACKEND_UNSUPPORTED_INT_DIVISION"
#define LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER "LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER"
#define LLVM_BACKEND_UNSUPPORTED_INT_NEGATION   "LLVM_BACKEND_UNSUPPORTED_INT_NEGATION"
#define LLVM_BACKEND_UNSUPPORTED_INT_BITWISE    "LLVM_BACKEND_UNSUPPORTED_INT_BITWISE"
#define LLVM_BACKEND_UNSUPPORTED_INT_SHIFT      "LLVM_BACKEND_UNSUPPORTED_INT_SHIFT"
#define LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH    "LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH"
#define LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP      "LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP"
#define LLVM_BACKEND_UNSUPPORTED_CONVERSION     "LLVM_BACKEND_UNSUPPORTED_CONVERSION"
#define LLVM_BACKEND_UNSUPPORTED_BITCAST        "LLVM_BACKEND_UNSUPPORTED_BITCAST"
#define LLVM_BACKEND_UNSUPPORTED_PHI            "LLVM_BACKEND_UNSUPPORTED_PHI"
/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4: when the bounded
 * IR_PHI dispatch arm rejects a shape whose incoming-edge
 * type binding is not satisfiable (i.e. the incoming
 * LLVMValueRef is neither i8 (constant/argument case) nor
 * i1 with an authorised IR_ICMP producer, nor is the
 * producer record present). Distinct from
 * LLVM_BACKEND_UNSUPPORTED_PHI, which is reserved for the
 * legacy "PHI unsupported at all" stance and is not used
 * by the SHAPE_DEPENDENT arm. */
#define LLVM_BACKEND_UNSUPPORTED_PHI_TYPE_CONTRACT \
    "LLVM_BACKEND_UNSUPPORTED_PHI_TYPE_CONTRACT"
/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4: when the bounded
 * IR_PHI dispatch arm detects that the static shape is
 * authorised but the runtime materialisation preconditions
 * (PI-1: predecessor block exists; PI-2: predecessor block
 * has a terminator; PI-3: incoming value already lowered
 * into predecessor) are not satisfied. Distinct from
 * LLVM_BACKEND_UNSUPPORTED_PHI_TYPE_CONTRACT, which fires
 * in Phase A static admission. */
#define LLVM_BACKEND_UNSUPPORTED_PHI_EDGE_MATERIALIZATION \
    "LLVM_BACKEND_UNSUPPORTED_PHI_EDGE_MATERIALIZATION"
#define LLVM_BACKEND_UNSUPPORTED_SWITCH         "LLVM_BACKEND_UNSUPPORTED_SWITCH"
#define LLVM_BACKEND_UNSUPPORTED_SELECT         "LLVM_BACKEND_UNSUPPORTED_SELECT"
#define LLVM_BACKEND_UNSUPPORTED_VARARGS        "LLVM_BACKEND_UNSUPPORTED_VARARGS"
#define LLVM_BACKEND_UNSUPPORTED_ASM            "LLVM_BACKEND_UNSUPPORTED_ASM"
#define LLVM_BACKEND_UNSUPPORTED_MEMORY         "LLVM_BACKEND_UNSUPPORTED_MEMORY"
#define LLVM_BACKEND_UNSUPPORTED_POINTER        "LLVM_BACKEND_UNSUPPORTED_POINTER"
#define LLVM_BACKEND_UNSUPPORTED_AGGREGATE      "LLVM_BACKEND_UNSUPPORTED_AGGREGATE"
/* ACT-POLYC-LLVM-GEP01: named diagnostic for an
 * IR_IADD whose operand shape does not match the
 * frozen B0 byte-indexing GEP subset. Fires only as a
 * safety net — the canonical IR for byte indexing always
 * lands on the recognised shape, and non-byte element
 * indexing is rejected by the existing IR_LOAD_DEREF /
 * IR_STORE_DEREF disp/idx/scale guards. */
#define LLVM_BACKEND_UNSUPPORTED_GEP_SHAPE      "LLVM_BACKEND_UNSUPPORTED_GEP_SHAPE"
#define LLVM_BACKEND_UNSUPPORTED_GLOBAL         "LLVM_BACKEND_UNSUPPORTED_GLOBAL"
#define LLVM_BACKEND_UNSUPPORTED_EXTERNAL       "LLVM_BACKEND_UNSUPPORTED_EXTERNAL"
/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: a mutable local
 * meets every §2 discriminator rule except one (e.g. has a
 * definition opcode outside {IR_STORE, IR_IADD, IR_ISUB}, is
 * address-taken, or has a read with no reaching definition). The
 * backend must reject such a local with this named diagnostic
 * rather than silently widening Option W's scope. */
#define LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE \
    "LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE"

#endif
