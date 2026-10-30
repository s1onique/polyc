// evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/red-probe/abi_red_probe.HC
//
// C0 RED probe: the COMPILED PolyC side. Compiled by the real ./hcc producer;
// never handwritten as a C object.
//
// The probe sees only opaque I64 handles and negative status codes. It never
// includes a C header, never casts a token to a pointer and never computes a
// field offset.
//
// Status convention: host functions return 0/positive on success and a
// negative status on failure; the probe propagates negatives unchanged.

extern "c" I64 AbiAstKind(I64 ast);
extern "c" I64 AbiListLen(I64 list);
extern "c" I64 AbiListAt(I64 list, I64 index);
extern "c" I64 AbiListPush(I64 list, I64 value);
extern "c" I64 AbiListSet(I64 list, I64 index, I64 value);

// AstKind values mirrored from src/ast.h. These are SOURCE VALUES of the
// kind encoding, not a layout assumption: the host returns the enum value and
// the probe only compares it.
#define ABI_AST_ASM_FUNC_BIND 276
#define ABI_AST_FUN_PROTO     286
#define ABI_AST_EXTERN_FUNC   289

#define ABI_ATOMICITY_OR_RANGE_FAILURE 10
#define ABI_HOST_ERROR                 14

// ---------------------------------------------------------------------
// The bounded semantic operation under test (C0 RED form).
//
// "Should this top-level AST node be printed by the AST dump?" — the real
// predicate that src/compile.c:31-33 evaluates inline today.
// ---------------------------------------------------------------------
I64 AbiRedShouldPrint(I64 ast) {
  I64 kind = AbiAstKind(ast);
  if (kind < 0) return kind;
  if (kind == ABI_AST_FUN_PROTO)    return 0;
  if (kind == ABI_AST_EXTERN_FUNC)  return 0;
  if (kind == ABI_AST_ASM_FUNC_BIND) return 0;
  return 1;
}

// ---------------------------------------------------------------------
// Container mutation: PolyC chooses, host applies. Append is allowed only
// while len < limit; range is checked on both sides, so failure is atomic.
// ---------------------------------------------------------------------
I64 AbiRedListAppendBounded(I64 list, I64 value, I64 limit) {
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
