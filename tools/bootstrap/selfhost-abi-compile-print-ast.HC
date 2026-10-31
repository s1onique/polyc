// tools/bootstrap/selfhost-abi-compile-print-ast.HC
// ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01
//
// The production PolyC decision component for the top-level AST visibility
// predicate. The semantic decision that used to live inline in
// src/compile.c:31-33:
//
//     if (ast->kind != AST_FUN_PROTO &&
//         ast->kind != AST_EXTERN_FUNC &&
//         ast->kind != AST_ASM_FUNC_BIND)
//     { print astToString(ast); }
//
// now lives here, in a component compiled from PolyC source by the real
// hcc producer and linked into the production compiler.
//
// This file is the frozen IMPLEMENT01 shadow decision, moved VERBATIM to
// its production-authorized path. Only the provenance comment header
// differs; the code below is byte-identical to
// evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c2/shadow-patch.diff
// (tools/experimental/compile-print-ast-decision.HC).
//
// The component sees ONE opaque I64 handle and returns 0/1 or a negative
// status. It never includes a C header, never casts a token to a pointer
// and never computes a field offset.
//
// NOTE ON HANDLES: a valid handle has 0xC0DE in bits 48..63, so a token is a
// NEGATIVE I64 when read as a signed integer. Handles are opaque bit patterns:
// this component must never test a handle with `< 0`. Only the RESULT of
// AbiCpaAstKind is sign-tested, and that result is provably disjoint from the
// negative status range.

extern "c" I64 AbiCpaAstKind(I64 ast);

// AstKind values mirrored from src/ast.h. These are SOURCE VALUES of the kind
// encoding, not a layout assumption: the host returns the enum value and this
// component only compares it.
#define ABI_AST_ASM_FUNC_BIND 276
#define ABI_AST_FUN_PROTO     286
#define ABI_AST_EXTERN_FUNC   289

I64 AbiCpaShouldPrintAst(I64 ast) {
  I64 kind = AbiCpaAstKind(ast);
  if (kind < 0) return kind;

  if (kind == ABI_AST_FUN_PROTO)     return 0;
  if (kind == ABI_AST_EXTERN_FUNC)   return 0;
  if (kind == ABI_AST_ASM_FUNC_BIND) return 0;

  return 1;
}
