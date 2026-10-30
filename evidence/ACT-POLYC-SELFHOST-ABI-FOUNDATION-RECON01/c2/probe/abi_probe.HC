// evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_probe.HC
//
// ABI v1: the COMPILED PolyC side. It is compiled by the real ./hcc
// producer, never handwritten as a C object.
//
// The probe sees only opaque I64 handles and negative status codes.
// It never includes a C header, never casts a token to a pointer, and
// never computes a field offset.
//
// Status convention: host functions return 0/positive on success and
// a negative status code on failure; the probe propagates negatives
// unchanged and never converts an error into success.

extern "c" I64 AbiAstKind(I64 ast);
extern "c" I64 AbiAstBinOp(I64 ast);
extern "c" I64 AbiAstChildKind(I64 ast, I64 which);
extern "c" I64 AbiAstChildI64(I64 ast, I64 which);
extern "c" I64 AbiListLen(I64 list);
extern "c" I64 AbiListAt(I64 list, I64 index);
extern "c" I64 AbiListPush(I64 list, I64 value);
extern "c" I64 AbiListSet(I64 list, I64 index, I64 value);

// The following are the frozen Python-free ABI constants mirrored from
// src/ast.h. They are SOURCE VALUES, not a layout assumption: the host
// returns the enum value; the probe only compares it.
#define ABI_AST_BINOP    296
#define ABI_AST_LITERAL  266
#define ABI_BIN_OP_ADD     3

// Status codes mirrored from abi_host.h (the host validates them).
#define ABI_ATOMICITY_OR_RANGE_FAILURE 10
#define ABI_HOST_ERROR                 14

// ---------------------------------------------------------------------
// AST read: classify a real C-owned AST through host accessors.
//
// Observable decision:
//   * ADD of two I64 literals -> left * 1000 + right
//   * BINOP of another shape  -> 200
//   * any other node kind     -> 100
//   * host status             -> the exact negative status
// ---------------------------------------------------------------------
I64 AbiProbeAstClassify(I64 ast) {
  I64 kind = AbiAstKind(ast);
  if (kind < 0) return kind;
  if (kind != ABI_AST_BINOP) return 100;

  I64 op = AbiAstBinOp(ast);
  if (op < 0) return op;
  if (op != ABI_BIN_OP_ADD) return 300 + op;

  I64 lk = AbiAstChildKind(ast, 0);
  if (lk < 0) return lk;
  I64 rk = AbiAstChildKind(ast, 1);
  if (rk < 0) return rk;

  I64 lv = AbiAstChildI64(ast, 0);
  if (lv < 0) return lv;
  I64 rv = AbiAstChildI64(ast, 1);
  if (rv < 0) return rv;

  if (lk == ABI_AST_LITERAL && rk == ABI_AST_LITERAL) {
    return lv * 1000 + rv;
  }
  return 200;
}

// ---------------------------------------------------------------------
// Container mutation: PolyC chooses, host applies.
//
// Append is allowed only while len < limit. The host re-validates the
// capability, the token and its own allocation state before mutating.
// ---------------------------------------------------------------------
I64 AbiProbeListAppend(I64 list, I64 value, I64 limit) {
  I64 len = AbiListLen(list);
  if (len < 0) return len;
  if (limit < 0) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
  if (len >= limit) return -ABI_ATOMICITY_OR_RANGE_FAILURE;

  I64 rc = AbiListPush(list, value);
  if (rc < 0) return rc;

  I64 after = AbiListLen(list);
  if (after != len + 1) return -ABI_HOST_ERROR;

  I64 got = AbiListAt(list, len);
  if (got < 0) return got;
  if (got != value) return -ABI_HOST_ERROR;

  return after;
}

// Range is checked by BOTH sides before any write: failure is atomic.
I64 AbiProbeListReplace(I64 list, I64 index, I64 value) {
  I64 len = AbiListLen(list);
  if (len < 0) return len;
  if (index < 0) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
  if (index >= len) return -ABI_ATOMICITY_OR_RANGE_FAILURE;

  I64 rc = AbiListSet(list, index, value);
  if (rc < 0) return rc;

  I64 got = AbiListAt(list, index);
  if (got < 0) return got;
  if (got != value) return -ABI_HOST_ERROR;
  return got;
}
