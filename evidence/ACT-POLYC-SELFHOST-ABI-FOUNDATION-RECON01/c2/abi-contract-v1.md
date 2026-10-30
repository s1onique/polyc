# ABI contract v1 — opaque checked state handles

Status: version 1, non-production, proven by the `c2/probe` executable.
Target: arm64-apple-darwin. Compiler: `./hcc` sha256
`9e50565b9235ae2939b2333580b45956c3589dddc972e9f4bf6b8cbd2563d90a`.

## 1. Representation

A handle is one opaque 64-bit value. It is **not** a pointer and it is never
dereferenced by PolyC. Layout (host-private, validated before use):

```text
bits  0..7   magic 0x5A
bits  8..15  ownership domain id (1..255)
bits 16..31  generation (u16)
bits 32..39  kind (1 = AST, 2 = LIST)
bits 40..47  slot index + 1 (1..64)
bits 48..63  reserved 0xC0DE
```

The host checks magic, reserved, index range, domain, token kind, slot kind,
liveness, generation and (for AST) the arena epoch **before** touching the
object. A forged integer fails `HANDLE_NOT_ISSUED`; a released token fails
`STALE_OR_RELEASED_HANDLE`; a live slot presented with an earlier generation
fails `HANDLE_GENERATION_MISMATCH`; a token from another domain fails
`HANDLE_DOMAIN_MISMATCH`.

## 2. Ownership

The C host owns every `Ast`, `List`, `AoStr`, `Map`, `Cctrl` and `Arena`
object. PolyC receives `OPAQUE_BORROW` handles only:

* it may not retain a handle beyond the host scope that issued it;
* it may not allocate, free or release storage except through `AbiRelease`
  (which only invalidates the host's slot; the host remains the storage owner);
* it may not convert a handle to a pointer, compute an offset or read a field;
* AST handles die when `astMemoryRelease()` clears the static Ast arena.

`Map`, `AoStr`, `Cctrl` and allocation from `Arena` are deliberately not
exposed in v1 (`NO_HANDLE_YET`): `Map`/`Vec` carry caller-supplied function
pointers, `AoStr`'s pool recycling has no proven borrow contract, and `Cctrl`
recovery is a `longjmp` through the C stack.

## 3. Mutation capability

A borrowed `List` is read-only by default. The host must call
`AbiListGrantMutation` before `AbiListPush`/`AbiListSet`; otherwise the result
is `MUTATION_WITHOUT_CAPABILITY` and the list is unchanged. This makes the
borrow/mutation distinction observable rather than a comment.

## 4. Recovery

`longjmp` across a live PolyC frame is forbidden. The host translates its own
failures into negative status codes at the boundary and PolyC propagates them.
The executable contains no `setjmp`/`longjmp`. `Cctrl` recovery is therefore
`BLOCKED` in v1, not silently emulated. A trap or signal is never used as a
detector.

## 5. Failure atomicity

Range and capability are checked before any write. The negative controls
`AB-ST-01` and `AB-ST-02` assert both the status and `STATE_UNCHANGED=1`. An
injected host allocation error (`AB-ST-05`) returns `HOST_ERROR` with the list
length unchanged; PolyC returns that exact negative code.

## 6. Calling convention and widths

All functions are SysV arm64 C ABI, return `I64` (64 bits) and take `I64`
parameters (64 bits). `Bool` is 1 byte and is never used across the boundary.
The PolyC object's undefined symbols are exactly the eight host accessors and
the C host defines all eight; the link closes with no unresolved target and no
duplicate definition (see `probe-build-and-selftests.txt`).

## 7. What v1 does not claim

No production subsystem was recompiled against this interface, so no mandatory
graph edge is claimed as cut. The 14 candidate edges are
`CUT_CANDIDATE_NOT_PROVEN`. The SCC partition is unchanged.
