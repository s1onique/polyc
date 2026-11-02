# THE ONE SUCCESSOR THIS ACT SELECTS

**ACT-POLYC-SELFHOST-DRIVER-MIGRATION01**

## Why this one, and why only this one

The ranking in `c2/work-package-ranking.tsv` is computed by reachability
over the real dependency edges. It is not an ordering by taste.

| package | subsystem | authority rows | downstream unblocked | base effort | qualification |
|---|---|---|---|---|---|
| **WP-001** | DRIVER | 32 | **19 of 20** | 3 | **QUALIFIED** |
| WP-002 | COMPILE_DRIVER | 77 | 17 | 5 | QUALIFIED_PENDING |
| WP-003 | LEXER | 63 | 13 | 7 | QUALIFIED |
| WP-004 | PARSER | 142 | 12 | 8 | QUALIFIED |
| WP-006 | CONTAINERS | 179 | 4 | 4 | QUALIFIED_PENDING |
| WP-017 | SHARED_INFRA | 0 | 3 | 4 | QUALIFIED_PENDING |
| WP-018 | BOOTSTRAP | 0 | 2 | 4 | QUALIFIED_PENDING |

WP-001 unblocks **nineteen of the twenty** packages in the model. It is
also the only R0 package that is `QUALIFIED` (a named witness, already
proof-ready) **and** has no predecessors. Every other R0 package either
waits on WP-001 or is still pending qualification.

The producer DAG (`c1/generation-producer-dag.tsv`) says the earliest
unsatisfied bootstrap gate is **P0**: no PolyC-authored compiler source
set exists. A compiler source set cannot begin with the lexer or the
parser; it begins with the thing that decides *what to compile*: the
driver.

## The bounded scope

WP-001 owns the argument handling and the compile entry point.

* `src/main.c` — 683 lines. The `main()` function, the mode dispatch
  (AOT compile / JIT / REPL / CFG-dump / LLVM), the output emission,
  and the `safeSystem`/`linkLibFlags`/`hccLibInit` helpers.
* `src/cli.c` — 574 lines. `cliArgsInit`, the option table, the
  `cliParse*` value parsers, and the `CliArgs` structure that the rest
  of the compiler reads.

Total: **1257 lines**, **32 authority rows** (10 from `src/main.c`,
22 from `src/cli.c`), and **no dependency on any other work package**.

## What the successor must NOT do

The successor is a MIGRATION of the driver, not a rewrite of the
programme. It is forbidden from:

* touching the lexer, the parser, the AST, the IR, the CFG, the
  assembler or the backends — those are WP-003, WP-004, WP-005,
  WP-007, WP-008, WP-009, WP-010 and WP-011;
* changing any language semantics, any CLI flag semantics, any exit
  code or any diagnostic text;
* changing the `CliArgs` layout, because 95 of the 135 mandatory graph
  edges are header-inclusion layout coupling and changing that layout
  would invalidate the graph this ACT has just re-derived;
* introducing the ternary operator, which this ACT MEASURED to be
  unsupported grammar (`RES-04`);
* touching `/tmp/holyc-asm.s`, the shared scratch path, which is
  `BB-03` and is not this ACT's to fix.

## The smallest runnable witness

`hcc --install-dir=X -c input.HC -o out.o` emits a compiler artifact.

That witness is the ACT's own acceptance criterion. It is not a
synthetic mock: it is the real production invocation, with the real
CLI, the real pipeline and the real output path.

The RED for the successor is therefore a genuine behavioural witness
showing that the driver is **not** PolyC-authored today, together with
the positive control that the PolyC-authored driver **does** produce
the same artifact.

## Why the driver and not the lexer

Three reasons, each measured:

1. **Leverage.** WP-001 unblocks 19 of 20 packages. The lexer unblocks
   13. The difference is six packages, which at the measured
   1-site-per-ACT rate is a large fraction of the whole programme.
2. **The P0 gate is about a COMPILER PRODUCING SOURCE SET, not about
   a compiler.** The bootstrap gate is not discharged by having a
   PolyC-authored lexer; it is discharged by having a PolyC-authored
   source set that, when compiled, yields a compiler. The driver is
   the entry point of that source set.
3. **Risk.** The lexer already has six dormant PolyC prototypes
   (`BootstrapScanTrivia` and friends) that are selector-OFF today, so
   the lexer package has precedent and can wait for its own turn. The
   driver has none, and starting it early is what makes the rest of
   the model reachable.

## The forecast consequence

The rebased model prices the full M2 scope at **1897 ACTs** at the
measured 1-site-per-ACT rate, against the archived 355 which rested on
an unvalidated 12-sites-per-ACT assumption. The first bounded step is
priced at **3 ACTs** (2 low / 3 base / 5 high) — `WP-001` alone.

The critical path through the whole model is **75 ACTs** with the
witness route:

```
WP-001 -> WP-002 -> WP-003 -> WP-004 -> WP-005 -> WP-007
       -> WP-008 -> WP-017 -> WP-018 -> WP-019 -> WP-020
```

That route is 11 of the 20 packages. The other nine are parallel work.
The successor opens the route.
