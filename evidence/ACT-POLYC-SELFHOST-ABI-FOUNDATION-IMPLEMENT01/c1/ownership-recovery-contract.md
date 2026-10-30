# C1 — ownership, lifetime, mutation, callback and recovery contract

Derived from the ORIGINAL code of the selected consumer, not from RECON01's
summary. Every claim below cites a real source location.

## 1. Who owns what

| object | owner before | owner after the shadow change |
|--------|--------------|-------------------------------|
| `Cctrl` (`cc`) | `main.c` stack / `ccMacroProcessor` | unchanged; C |
| `cc->ast_list` (`List`) | `Cctrl` (created at `src/cctrl.c:263`) | unchanged; C |
| every `Ast` in `cc->ast_list` | the static Ast arena (`src/ast.c` `astMemoryInit` / `astMemoryRelease`) | unchanged; C |
| the printed string (`astToString`) | `src/ast.c` (borrowed `AoStr`) | unchanged; C |
| the handle table | does not exist today | the shadow C host only |

PolyC owns nothing. It receives one opaque `I64` handle per node and returns one
`I64`. It never allocates, never retains, never frees, never computes an offset
and never dereferences a token.

## 2. Lifetime and borrowing (measured, not assumed)

```text
Ast nodes are arena-allocated (astMemoryInit) and die en masse at
astMemoryRelease (src/ast.c).  compilePrintAst runs entirely inside one
parse->print window: main.c calls compileToAst() then compilePrintAst()
then goto success, and memoryRelease() happens later in the same function.
So the borrow window of every handle is a strict subset of the arena epoch.
```

The shadow host therefore stamps every AST slot with the arena epoch and
compares it **before** dereferencing. `c0/red-probe-raw.txt` records the
executed witness: after the real `astMemoryRelease()` the same token returns
`-8 EXPIRED_BORROW_OR_ARENA` and the process stays alive.

## 3. Aliasing

`compilePrintAst` copies `(Ast *)it->value` into a local `ast`. There is no
second alias, no escalation, no write. The shadow version keeps exactly the
same single local; the handle is issued immediately before the call and
released immediately after, so the host slot table never holds more than one
live AST at a time.

## 4. Mutation capability

**The selected operation is a pure read.** There is no `AST`-side mutation in
`compilePrintAst`, so the shadow ABI exposes **no** AST mutation entry point at
all. The `List` mutation surface (`AbiListPush` / `AbiListSet` with an explicit
capability grant) exists in the shared host implementation and is exercised by
the C0 probe controls, but the shadow consumer never calls it and never grants
capability. Nothing in the shadow compiler can write through a handle.

`list.h`'s `List.value` is read as `void *` and cast to `Ast *`; that is an
opaque pointer cast inside C. It stays in C.

## 5. Callbacks

`compilePrintAst` makes no callback into user code: `astToString` is a normal
function in the same linked binary and `printf` is libc. The shadow ABI has no
callback surface. `AbiRetainCallback` exists in the shared host only to reject
the operation (`-11 CALLBACK_LIFETIME_OR_REENTRANCY`), which `c0` executes.

## 6. Recovery

`src/compile.c` contains no `setjmp`, no `longjmp` and no error path in
`compilePrintAst`; it cannot fail. The host's own failure modes are translated
into negative status codes **at the boundary**, and PolyC propagates them
unchanged. There is no `jmp_buf` across a PolyC frame anywhere in the shadow
binary — `c0/red-probe-raw.txt` records `PRESENT=NO` for `setjmp`/`longjmp`
symbols in the probe binary, and C2 repeats the check on the shadow compiler.

`Cctrl` recovery stays `NO_HANDLE_YET`/`BLOCKED`: `src/cctrl.c` performs a
`longjmp` through the C stack, which has no defined contract across a PolyC
frame.

## 7. Failure atomicity

The only "write" the shadow consumer performs is `printf`. The decision is
computed **before** anything is printed, and the host accessor cannot mutate.
Therefore a failed accessor call means the dump line is not printed at all —
there is no partial write to roll back. The C0 probe additionally proves the
`List` path's atomicity for completeness (`c0/red-probe-raw.txt`).

## 8. Explicitly blocked surfaces (frozen)

```text
Cctrl recovery                BLOCKED   (longjmp through C stack)
Map / Vec with callbacks      NO_HANDLE_YET
AoStr pool borrow             NO_HANDLE_YET
Arena allocation transfer     NO_HANDLE_YET
AST mutation                  NOT EXPOSED BY THIS ACT
List mutation                 EXPOSED BUT NEVER USED BY THE SHADOW CONSUMER
```
