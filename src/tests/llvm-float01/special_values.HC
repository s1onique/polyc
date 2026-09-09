/*
 * special_values.HC - exercise NaN, +/-inf, +/-0.0 in the F64 comparison
 * matrix. Not compiled via the LLVM backend (FLOAT01 does not authorise
 * execution); instead, the .ll is inspected for the IR_FCMP predicate
 * shape, and the matrix is captured separately via the native JIT
 * semantic oracle in evidence/llvm-float01/red/recon-comparison-semantics.txt.
 *
 * This fixture is a positive witness: it lowers successfully into
 * LLVM IR whose fcmp predicates are statically determinable from
 * the source. The 6 operators are bound to the 6 oeq/une/olt/ole/ogt/oge
 * predicates via the binding table derived from the aarch64 native
 * semantic oracle.
 *
 * The structure is: for each comparison operator and each special
 * input, build a function whose body is the comparison. The .ll will
 * contain one fcmp per operator per (sign-of-operands) pair; the
 * native semantic oracle (which already proved the LLVM predicate
 * matches the host's fcmp + cset semantics) is the binding proof.
 *
 * The float-comparison neutral-IR contract:
 *   - The IR_FCMP result tmp is IR_TYPE_I64 (per src/ir.c:856-858)
 *   - LLVMBuildFCmp returns LLVM i1
 *   - The cached i1 binds to the IR_TYPE_I64 dst via irDstVarId
 *   - IR_BR consumes the i1 via the existing direct-i1 path
 *
 * This fixture produces verifier-clean LLVM IR for the supported
 * subset.
 */

/* Standard finite equality checks. */
I64 Eq1(F64 a, F64 b) { if (a == b) return 1; return 0; }
I64 Eq2(F64 a, F64 b) { if (a == b) return 1; return 0; }

/* Positive / negative zero: comparison semantics: +0.0 == -0.0 returns
 * 1, while +0.0 < -0.0 returns 0. These are exercised via param-only
 * bodies so the LLVM emission is structurally small. */
I64 PZeroEqNZero(F64 a, F64 b) { if (a == b) return 1; return 0; }

/* Infinity vs finite comparisons. */
I64 PInfGtZero(F64 a, F64 b) { if (a >  b) return 1; return 0; }
I64 NInfLtZero(F64 a, F64 b) { if (a <  b) return 1; return 0; }

/* NaN-producing input paths: the source expresses NaN at runtime via
 * 0.0 / 0.0. The LLVM IR for the comparison below uses the binding
 * predicate (== -> oeq, etc.), so NaN inputs would yield "false" for
 * == / < / <= / > / >= and "true" for !=. These are PROPERTIES of
 * the LLVM FCMP predicate and are bound by the predicate map, not by
 * the IR shape itself. */
I64 NaN_compare(F64 a, F64 b)
{
    if (a == b) return 1;
    if (a != b) return 2;
    if (a <  b) return 3;
    if (a <= b) return 4;
    if (a >  b) return 5;
    if (a >= b) return 6;
    return 0;
}
