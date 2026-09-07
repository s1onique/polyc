#ifndef IR_H__
#define IR_H__

#include "cctrl.h"
#include "ir-types.h"
#include "ir-regalloc.h"

void irMemoryInit(void);
void irMemoryRelease(void);
void irMemoryStats(void);
void irDump(Cctrl *cc);
/* ACT-POLYC-IR-BOUNDARY01 RED witness dump entrypoint. */
void irDumpWithFakePool(Cctrl *cc);
IrValue *irExpr(IrCtx *ctx, Ast *ast);
IrCtx *irLowerProgram(Cctrl *cc);
IrFunction *irLowerFunction(IrCtx *ctx, Ast *ast_func);

void irFunctionPrepForCodeGen(IrCgCtx *ctx, IrFunction *fn, Ast *ast_fn);

/* ACT-POLYC-IR-BOUNDARY01: native-only ABI assignment post-pass.
 * Stamps `loc.kind = IR_LOC_REG` on IR_VAL_PARAM arrive values
 * based on the active `IrRegPool`. Called from the native codegen
 * paths between `irLowerFunction` and `irBasicFunctionOptimisations`.
 * A neutral consumer MUST NOT call this. */
void irAssignAbiParamLocations(IrFunction *fn, Ast *ast_func, IrRegPool *pool);

#endif
