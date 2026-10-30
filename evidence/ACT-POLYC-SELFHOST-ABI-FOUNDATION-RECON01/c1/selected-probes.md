# Selected C2 probes (C1 decision, not a verdict)

## Selected AST read: `AbiProbeAstClassify`

`Ast` is host-owned and lives in the static Ast arena in `src/ast.c`
(`astMemoryRelease` invalidates every node at once). The selected probe reads
only host accessor results:

```text
AbiAstKind(ast)                 -> 256..299 or negative status
AbiAstBinOp(ast)                -> AstBinOp or negative status
AbiAstChildKind(ast, 0|1)       -> AstKind of left/right or negative status
AbiAstChildI64(ast, 0|1)        -> literal value or negative status
```

The PolyC component makes an externally visible decision: for an
`AST_BINOP`/`AST_BIN_OP_ADD` node whose children are both `AST_LITERAL`, it
returns `left*1000 + right`; for other shapes it returns a class code in the
hundreds. The C host independently computes the same classification with a
C-only oracle that does not use the handle layer, and compares.

Why this is not a toy: the AST is built with the real production constructors
`astMemoryInit`, `astI64Type`, `astBinaryOp` and the real `Ast`/`AstType`
structures. The handle layer stores a genuine `Ast *`; PolyC never sees it.

## Selected container mutation: `AbiProbeListAppend` / `AbiProbeListReplace`

`List` is a real ring (`src/list.c`). The host registers a `List *` created by
`listNew`/`listAppend`. PolyC reads `AbiListLen`, decides whether the append is
inside the caller-supplied bound, calls `AbiListPush`, then verifies the new
length and the value it reads back through `AbiListAt`. A `replace` probe
checks the range through `AbiListLen` first and asks for `AbiListSet`; the host
re-checks the range before mutating, so an out-of-range request returns
`ATOMICITY_OR_RANGE_FAILURE` with the list unchanged.

## Arena lifetime witness

The AST slots carry the host's Ast-arena epoch. `AbiAstKind` compares the slot
epoch with the current epoch **before** dereferencing. The host witness calls
`astMemoryRelease()` (the real teardown) and then asks for the kind of the old
token; the expected result is `EXPIRED_BORROW_OR_ARENA` and the process must
remain alive. The probe never claims that an arena-owned AST survives teardown.

## Recovery decision

`Cctrl` is not selected as an opaque handle in v1. `src/cctrl.c:965` performs a
`longjmp` through the C stack; a PolyC frame has no defined unwinding contract
for that. The C2 fixture therefore translates host failures into negative
status codes at the host boundary and never installs a `jmp_buf` across a
PolyC frame. `Cctrl` is `NO_HANDLE_YET`/`BLOCKED` for recovery, and the
callback-bearing `Map`/`Vec` types are `NO_HANDLE_YET` until a callback
lifetime contract exists.
