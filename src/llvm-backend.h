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

#endif
