// only-externs.HC
// Every top-level node in this file is on the SUPPRESSION branch of the
// -ast dump: AST_EXTERN_FUNC, produced by the `extern "c"` declaration
// form (src/parser.c parseExternFunctionProto).
//
// The dump must therefore be exactly the header line "AST: " and nothing
// else: no node body is printed at all.
//
// ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01 witness.
extern "c" I64 printf(I64 fmt, ...);
extern "c" I64 puts(I64 s);
