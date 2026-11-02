# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01
# ACT_PHASE=C1-EVIDENCE
# EVIDENCE_KIND=compiler-producing-precursor-vs-m2
#
# THE M2-PRECURSOR AND M2 ARE DIFFERENT MILESTONES, AND THE
# DIFFERENCE IS EXACTLY THE PRODUCER SHAPE.
#
## The distinction that matters

A **PolyC-authored compiler source set** is a set of `.HC` sources that,
when compiled by a qualified producer, yield an artifact that IS a
compiler: it reads a source file, lexes it, parses it, lowers a
semantically meaningful construct, and emits a real compiler output.

The current tree has **twelve** PolyC sources under `tools/bootstrap/`.
Every one of them is a **pure decision function with a frozen ABI**:
`BootstrapCalcPadding`, `BootstrapValidPostControlFlowToken`,
`BootstrapOperatorPrecedence`, `BootstrapAstBinOpFromToken`,
`BootstrapAstUnaryOpFromToken`, `BootstrapSwitchArmTerminates`,
`BootstrapCompoundBlockAppendsStatement`, `BootstrapDefaultArmTerminates`,
`BootstrapStatementDispatch`, `AbiCpaShouldPrintAst`, the three
`_AbiCore*` operators, and the two `_AbiA64Cc*V2` condition selectors.

Measured: **12 sources, 1,612 LOC, zero drivers, zero compilers.** Their
compiled output is a set of `.o` files that the linker binds into the
**C** compiler. They are library objects, not a compiler.

## The measured producer chain

| stage | producer | compiles | classification |
|---|---|---|---|
| GC-01 | `/usr/bin/gcc` | 46 C translation units | `C_ROOTED` |
| GC-02 | `build/host-stage0/hcc` (C-rooted) | 12 PolyC helper subjects | `HYBRID` |
| GC-03 | linker | 28 C objects + 12 PolyC subjects | `HYBRID` |
| GC-04 | — | a PolyC-authored compiler source set | **ABSENT** |
| GC-05 | — | a second independent producer | **ABSENT** |

GC-02 and GC-03 are the decisive rows. The stage0 compiler compiles
**PolyC source**, but the source it compiles is **helper subjects**, not
a compiler. The output is a library that a C compiler links in. That is
exactly the shape the ACT calls "a C-built host-stage0/hcc compiling `.HC`
subject objects", which is **not** M2.

## The two boundaries

### Boundary A — M2-PRECURSOR

The smallest compiler-producing vertical slice. Measured membership:
**10 translation units, 14,346 LOC** — `main.c`, `cli.c`, `compile.c`,
`lexer.c`, `parser.c`, `ast.c`, `aostr.c`, `containers.c`, `list.c`,
`cctrl.c`, plus the permitted mechanical glue (`memory.c`, `mempool.c`,
`arena.c`, `linenoise.c`, 2,991 LOC).

Boundary A is a **precursor**, not M2. It becomes M2 only when the
producer of that source set is itself a qualified earlier compiler AND
the complete in-scope source set is covered.

### Boundary B — M2 full in-scope semantic source set

**24 semantic C translation units, 36,677 LOC**, each of which must
eventually be PolyC-authored or proved mechanical/platform-only. Every
one of them currently has **no PolyC source**: the measured
`OPEN_MISSING_POLYC_SOURCES` count is **24**, and the measured count of
PolyC sources that constitute a *compiler* source set is **0**.

## Why no narrower slice exists

A compiler must produce a compiler output. The narrowest real compiler
output in this tree is the **assembly text** emitted by `src/asm.c`
(3,047 LOC across `asm.c` and `prsasm.c`). Any slice that stops before
emission is a library, not a compiler.

Could the slice stop at the assembly text and use the **C** codegen?
No: the codegen is where the semantic decisions live. Delegating
emission to C while keeping the front end in PolyC produces a **front
end**, not a compiler, and it leaves the codegen's semantics in C —
which is exactly the M1/M2 boundary the ACT draws.

## The measured blockers that apply to the selected slice

Of the eight recorded blockers, **only BB-04** (no PolyC-authored
compiler source set) blocks the precursor, M2 and M3. BB-02 and RES-04
(the ternary operator) are **UNSUPPORTED GRAMMAR** — this ACT measured
it by compiling its own PolyC tool and watching the parser reject five
ternary expressions — and the selected source closure uses no ternary.
BB-01, RES-01, RES-02 and RES-03 are **historical-only** and were not
re-measured here. BB-03 (the shared `/tmp/holyc-asm.s`) was **avoided by
serialisation, not fixed**.

## The honest conclusion

The M2-PRECURSOR is **derivable** from the real source: the boundary is
10 named translation units with named responsibilities, and the driver
is the first one. But **no PolyC-authored compiler source set exists
today**, so the earliest unsatisfied bootstrap gate is **P0**, and the
programme's first real work is to create that source set.

That is a bounded, executable next step — which is why this ACT can
select a successor without inventing anything.
