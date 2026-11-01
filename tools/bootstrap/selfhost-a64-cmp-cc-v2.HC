// tools/bootstrap/selfhost-a64-cmp-cc-v2.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01 C2 IMPL.
//
// THE PRODUCTION AARCH64 CONDITION-CODE DECISION COMPONENT.
//
// This component owns TWO of the three selected AArch64 comparison
// condition-code decisions of BUNDLE CAND-CMP-CC-A64:
//
//   SITE-A64-CC-FOR  src/aarch64.c  aarch64CcFor
//   SITE-A64-CC-INV  src/aarch64.c  aarch64CcInvFor
//
// The third selected site, SITE-A64-CSET (aarch64EmitCSet), is a
// C-OWNED MECHANICAL ADAPTER and stays in C. It owns no condition
// selection of its own: its whole definition is one call to
// aarch64CcFor plus a fixed format string. It is NOT migrated here and
// it does NOT receive an export.
//
// THE ABI (ABI-A64-CMP-CC-2)
// ========================
//
//   U8 *AbiA64CcForV2(I64 comparison_kind, I64 is_float);
//   U8 *AbiA64CcInvForV2(I64 comparison_kind, I64 is_float);
//
// There is EXACTLY TWO exports. There is NO AbiA64CmpCcEmitCSet export
// of any signature. The historical inert v1 third export is FORBIDDEN
// and is not implemented.
//
// The exact contract is frozen in
// evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01/
// c0/abi-a64-cmp-cc-2.txt.
//
// RESULT AND STATUS SEPARATION
// ============================
//
// The result is a BORROWED, IMMUTABLE, NUL-terminated string literal
// owned by this component's static data. It is never allocated, never
// freed and never written by the host.
//
// An unsupported (kind,is_float) returns 0, that is, NULL. NULL is a
// POINTER status, never a numeric status, so it can NEVER collide with
// the IR_CMP_EQ == 0 discriminant. The host translates NULL into its
// own fail-closed termination.
//
// THE CONSTANTS ARE SOURCE VALUES, NOT LAYOUT ASSUMPTIONS
// ======================================================
//
// This component cannot include the C headers, so the IrCmpKind
// enumerator values are written as their NUMERIC values. Every one of
// them was resolved from the LIVE src/ir-types.h by the independent
// deriver and is recorded in
// evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01/
// c0/source-ranges-and-abi.tsv.
//
//   IR_CMP_INVALID = -1
//   IR_CMP_EQ      =  0
//   IR_CMP_NE      =  1
//   IR_CMP_LT      =  2
//   IR_CMP_LE      =  3
//   IR_CMP_GT      =  4
//   IR_CMP_GE      =  5
//   IR_CMP_ULT     =  6
//   IR_CMP_ULE     =  7
//   IR_CMP_UGT     =  8
//   IR_CMP_UGE     =  9
//   IR_CMP_OEQ     = 10   (unsupported on both paths)
//   IR_CMP_ONE     = 11   (unsupported on both paths)
//   IR_CMP_OLT     = 12   (unsupported on both paths)
//   IR_CMP_OLE     = 13   (unsupported on both paths)
//   IR_CMP_OGT     = 14   (unsupported on both paths)
//   IR_CMP_OGE     = 15   (unsupported on both paths)
//   IR_CMP_UNO     = 16   (unsupported on both paths)
//   IR_CMP_ORD     = 17   (unsupported on both paths)
//
// THE SUFFIXES ARE A VERBATIM TRANSCRIPTION
// =========================================
//
// The float table and the integer table below are transcribed from the
// live src/aarch64.c definitions of aarch64CcFor and aarch64CcInvFor
// at the source blob 6a53ac8f2e320aa8b0f7fc23ea9bd90be0334229. The
// legacy C tables terminated an unsupported case through loggerPanic;
// here the same case returns NULL and the host reproduces the same
// fail-closed termination.
//
// PURITY CONSTRAINTS
// =================
//
//   - no host AST, no host IR, no host context and no host layout;
//   - no allocation, no side effects, no global mutable state;
//   - no callbacks and no recovery;
//   - the only inputs are two copied integer scalars.
//
// LANGUAGE CONSTRAINTS
// ===================
//
// The control flow uses EXPLICIT if branches and explicit returns. It
// deliberately avoids a pointer-valued conditional expression, because
// that form is not reliably compiled by this compiler and previously
// caused verifier hangs and out-of-memory failures.

// IrCmpKind numeric values, derived from the live src/ir-types.h.
#define A64_CMP_INVALID (-1)
#define A64_CMP_EQ      0
#define A64_CMP_NE      1
#define A64_CMP_LT      2
#define A64_CMP_LE      3
#define A64_CMP_GT      4
#define A64_CMP_GE      5
#define A64_CMP_ULT     6
#define A64_CMP_ULE     7
#define A64_CMP_UGT     8
#define A64_CMP_UGE     9

// ---------------------------------------------------------------------------
// SITE-A64-CC-FOR
//
// The TRUE-side condition-code suffix.
//
// The float table, transcribed from the live aarch64CcFor:
//
//     if (is_float) {
//         case IR_CMP_EQ:  return "eq";
//         case IR_CMP_NE:  return "ne";
//         case IR_CMP_LT:  return "mi";
//         case IR_CMP_LE:  return "ls";
//         case IR_CMP_GT:  return "gt";
//         case IR_CMP_GE:  return "ge";
//         default: loggerPanic(...);
//     }
//
// The integer table, transcribed from the live aarch64CcFor:
//
//     case IR_CMP_EQ:  return "eq";
//     case IR_CMP_NE:  return "ne";
//     case IR_CMP_LT:  return "lt";
//     case IR_CMP_LE:  return "le";
//     case IR_CMP_GT:  return "gt";
//     case IR_CMP_GE:  return "ge";
//     case IR_CMP_ULT: return "lo";
//     case IR_CMP_ULE: return "ls";
//     case IR_CMP_UGT: return "hi";
//     case IR_CMP_UGE: return "hs";
//     default: loggerPanic(...);
// ---------------------------------------------------------------------------
U8 *AbiA64CcForV2(I64 comparison_kind, I64 is_float)
{
  if (is_float == 1) {
    if (comparison_kind == A64_CMP_EQ) return "eq";
    if (comparison_kind == A64_CMP_NE) return "ne";
    if (comparison_kind == A64_CMP_LT) return "mi";
    if (comparison_kind == A64_CMP_LE) return "ls";
    if (comparison_kind == A64_CMP_GT) return "gt";
    if (comparison_kind == A64_CMP_GE) return "ge";
    // The unsigned kinds and the ordered/unordered kinds are NOT
    // supported on the float path. Fail closed.
    return 0;
  }
  if (is_float == 0) {
    if (comparison_kind == A64_CMP_EQ)  return "eq";
    if (comparison_kind == A64_CMP_NE)  return "ne";
    if (comparison_kind == A64_CMP_LT)  return "lt";
    if (comparison_kind == A64_CMP_LE)  return "le";
    if (comparison_kind == A64_CMP_GT)  return "gt";
    if (comparison_kind == A64_CMP_GE)  return "ge";
    if (comparison_kind == A64_CMP_ULT) return "lo";
    if (comparison_kind == A64_CMP_ULE) return "ls";
    if (comparison_kind == A64_CMP_UGT) return "hi";
    if (comparison_kind == A64_CMP_UGE) return "hs";
    // IR_CMP_INVALID (-1), the ordered/unordered kinds (10..17) and
    // every other value fail closed.
    return 0;
  }
  // An is_float value other than 0 or 1 is out of domain. Fail closed.
  return 0;
}

// ---------------------------------------------------------------------------
// SITE-A64-CC-INV
//
// The FALSE-side (inverse) condition-code suffix.
//
// The float table, transcribed from the live aarch64CcInvFor:
//
//     if (is_float) {
//         case IR_CMP_EQ:  return "ne";
//         case IR_CMP_NE:  return "eq";
//         case IR_CMP_LT:  return "pl";
//         case IR_CMP_LE:  return "hi";
//         case IR_CMP_GT:  return "le";
//         case IR_CMP_GE:  return "lt";
//         default: loggerPanic(...);
//     }
//
// The integer table, transcribed from the live aarch64CcInvFor:
//
//     case IR_CMP_EQ:  return "ne";
//     case IR_CMP_NE:  return "eq";
//     case IR_CMP_LT:  return "ge";
//     case IR_CMP_LE:  return "gt";
//     case IR_CMP_GT:  return "le";
//     case IR_CMP_GE:  return "lt";
//     case IR_CMP_ULT: return "hs";
//     case IR_CMP_ULE: return "hi";
//     case IR_CMP_UGT: return "ls";
//     case IR_CMP_UGE: return "lo";
//     default: loggerPanic(...);
// ---------------------------------------------------------------------------
U8 *AbiA64CcInvForV2(I64 comparison_kind, I64 is_float)
{
  if (is_float == 1) {
    if (comparison_kind == A64_CMP_EQ) return "ne";
    if (comparison_kind == A64_CMP_NE) return "eq";
    if (comparison_kind == A64_CMP_LT) return "pl";
    if (comparison_kind == A64_CMP_LE) return "hi";
    if (comparison_kind == A64_CMP_GT) return "le";
    if (comparison_kind == A64_CMP_GE) return "lt";
    // The unsigned kinds and the ordered/unordered kinds are NOT
    // supported on the float path. Fail closed.
    return 0;
  }
  if (is_float == 0) {
    if (comparison_kind == A64_CMP_EQ)  return "ne";
    if (comparison_kind == A64_CMP_NE)  return "eq";
    if (comparison_kind == A64_CMP_LT)  return "ge";
    if (comparison_kind == A64_CMP_LE)  return "gt";
    if (comparison_kind == A64_CMP_GT)  return "le";
    if (comparison_kind == A64_CMP_GE)  return "lt";
    if (comparison_kind == A64_CMP_ULT) return "hs";
    if (comparison_kind == A64_CMP_ULE) return "hi";
    if (comparison_kind == A64_CMP_UGT) return "ls";
    if (comparison_kind == A64_CMP_UGE) return "lo";
    // IR_CMP_INVALID (-1), the ordered/unordered kinds (10..17) and
    // every other value fail closed.
    return 0;
  }
  // An is_float value other than 0 or 1 is out of domain. Fail closed.
  return 0;
}
