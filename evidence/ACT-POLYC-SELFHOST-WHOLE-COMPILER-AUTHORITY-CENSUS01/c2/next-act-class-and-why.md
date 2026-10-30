# Next ACT class and why (C2 recommendation, not authorization)

**ACT:** `ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01` — C2
**Evidence:** `c2/scc-members.tsv`, `c2/condensed-migration-dag.tsv`,
`c2/topological-order.tsv`, `c2/migration-bundles.tsv`,
`c2/forecast.tsv`.

## 1. What the graph actually says

`graph-edges.tsv` carries 238 typed edges: 103 `CALLS` (availability
only, **not** mandatory), 95 `TYPE_REPRESENTATION`, 14 `CALLBACK`,
14 `MUTABLE_STATE` and 12 `RECOVERY`. Running Tarjan **only** over the
mandatory edges (the CALLS edges are deliberately excluded, because a
PolyC caller may keep calling a C callee) yields:

```text
MANDATORY_EDGES = 238 (all typed)     NODES = 52     SCCS = 34
largest SCC     = SCC-2 with 19 members
```

The 19 members of SCC-2 are:

```text
SCANNER_SUPPORT LEXER ASM_PARSER JSON MEMORY ASSEMBLER JIT COMPILE_DRIVER
CFG TRANSPILER REPL LSP CODEGEN PARSER AST IR CONTAINERS DRIVER CONTROL_SYMBOLS
```

Only `SYS-SUPPORT_HEADERS` (header-only, zero authority rows) and the
build-target / external / unknown nodes fall outside it. The condensed
DAG has exactly two edges, both into `SCC-1`.

**This is not an artefact of the edge typing.** It is what the shared
type and state surface looks like: `aostr.h` is included by 29
translation units, `ast.h` by 22 (and declares mutable globals),
`list.h` by 21, `containers.h` by 17, `cctrl.h` by 16, `lexer.h` by 15.
Any subsystem that is PolyC-authored must see those layouts; any
subsystem that owns `Cctrl`, `Ast`, `AoStr` or the container vtables
owns state that the others mutate.

## 2. Consequence for bundle strategy

Three bundles are derivable, and one of them is enormous:

```text
B-1  SCC-2  19 members  2136 C decision sites  HIGH  act_low/base/high = 137/325/888
B-2  SCC-3   1 member     88 C decision sites  LOW   act_low/base/high =  10/15/44
B-3  SCC-4   1 member      9 C decision sites  LOW   act_low/base/high =   5/5/11
```

A "small coherent bundle" strategy therefore has exactly one honest
meaning here: **the shared type/state core must be transferred first**,
behind an ABI that does not hide AST ownership, mutable symbol state,
callbacks or recovery. Everything else is downstream of it.

## 3. Recommendation

```text
NEXT_ACT_CLASS = ABI_FOUNDATION
NEXT_TARGET    = NONE
```

Why not `PARSER_RECON`: the parser is already inside SCC-2 and cannot be
split off from `Ast`/`Cctrl`/`Arena` ownership by another parser-local
slice. Another parser slice would migrate a decision site while leaving
the ownership boundary that makes the bundle expensively entangled.

Why not `BUNDLE_QUALIFICATION` for B-1 directly: B-1 has 2136 decision
sites and 19 subsystems. Qualifying it as a single bundle would be a
programme, not an ACT. The prerequisite is the **ABI and ownership
foundation** that lets B-1 be split into verifiable sub-bundles without
hiding state.

Why not `BOOTSTRAP_BLOCKER` first: BB-01..BB-04 are real and must be
scheduled, but they are not on the *migration* critical path until a
PolyC-authored compiler source set exists; the ABI foundation is.

A concrete ABI_FOUNDATION ACT should therefore:

1. define the bounded handle/ownership contract for `AoStr`, `List`,
   `Map`, `Ast`, `Cctrl` and `Arena` that a PolyC component may hold
   without owning the C layout;
2. prove, with a real producer and a real object, that the contract is
   expressible in the current PolyC dialect or record the exact dialect
   remedy needed (BB-02);
3. leave `SELFHOST_M2_ACHIEVED` untouched and authorize no migration.

This recommendation is **not** an authorization. A concrete ACT still
requires its own bounded contract under `docs/factory/ACT-TEMPLATE.md`.
