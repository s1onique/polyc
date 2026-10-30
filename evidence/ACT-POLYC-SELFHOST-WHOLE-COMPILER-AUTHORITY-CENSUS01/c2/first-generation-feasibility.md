# First-generation feasibility (M2 / M3)

**ACT:** `ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01` — C2
**Basis:** `c1/*`, `c2/scc-members.tsv`, `c2/topological-order.tsv`,
`c1/compiler-generation-chain.tsv`, `c2/bootstrap-blockers.tsv`.

## 1. What must be PolyC-authored for each milestone

| Milestone | Source that must be PolyC-authored | What may remain C/platform |
|---|---|---|
| M1 | Every in-scope compiler **decision site** (the 2218 `C_AUTHORITY` sites, grouped into coherent bundles) | (a) the six delegation-only adapters, (b) straight-line data plumbing that implements no choice, (c) libm/libSystem, (d) header-only declarations, (e) the system assembler/linker |
| M2 | All of the above **plus** the compiler's own translation, so that a compiler built by an earlier compiler compiles the in-scope PolyC compiler sources into a working next-generation executable | The same platform set, and only that set. A C compiler that links PolyC helper objects does **not** qualify (control `WC-BS-02`). |
| M3 | M2 plus two distinct producer executables whose identity and input closure are demonstrated | Platform set; but hash-identical output alone never proves independent producers |

## 2. Is the required source set expressible in the current PolyC dialect?

Not yet, with evidence:

* **BB-02 (language inference).** The pointer-valued ternary and the
  `Bool`/`I64` inference gap are recorded language-feature defects. The
  compiler's own code uses those forms extensively, so they are a
  *dialect* blocker, not a style preference. Evidence: the reported
  16 GB OOM lead and C0 RED-3/RED-5.
* **BB-01 (storage collision).** The static initialised file-scope
  scalar and `Main(argc, argv)` storage collision is a correctness lead
  that directly affects a self-hosted compiler's globals.
* **BB-04 (producer).** All nine production PolyC subject objects are
  produced by `build/host-stage0/hcc`, which is built by **gcc**
  (`c1/compiler-generation-chain.tsv`, rows GC-01..GC-10). No
  PolyC-authored compiler source set exists anywhere in this tree
  (GC-14 declares `M2_PRODUCER_ABSENT`).
* **BB-03 (build concurrency).** The shared `/tmp/holyc-asm.s` temporary
  makes concurrent generation unreliable; every measurement in this ACT
  was serialized because of it.

## 3. Bounded read-only probe performed here

The probe re-ran the **stage0 recipe** into an isolated directory and
re-measured provenance:

```text
fresh stage0 binary      build/census01/stage0-fresh/hcc
sha256                   db9aefd39bf7875c35c52e123062ea786d4faa42340588929c3a929931ced388
selectors                all nine OFF
Bootstrap definitions    0
producer                 /usr/bin/gcc
```

This proves the *current* generation chain is C-rooted and that the
stage0 recipe is sound; it does **not** demonstrate M2, and it is not
claimed as one. The same probe also exposed that the pre-existing
`build/host-stage0/hcc` artifact defines `_BootstrapStatementDispatch`
although the recipe passes OFF — a stale-artifact provenance defect
recorded in `c1/build-configs.tsv` and never repaired here.

## 4. Exact M2 acceptance conditions proposed

An M2 ACT must demonstrate, with executed commands and stored digests:

1. a **source manifest** of the in-scope PolyC compiler sources
   (content-addressed blobs, no C translation units in the semantic set);
2. a **producer executable** that is itself a qualified compiler, with
   its own source manifest and digest;
3. a **resulting next-generation executable** produced by that producer
   from (1), with the link inputs and the runtime prefix recorded;
4. a **compiler operation exercised through that executable** on a real
   input, with the expected observable output;
5. an explicit statement of which C/platform objects remain linked, each
   proved not to own a decision site (the census's own `C_AUTHORITY`
   check is the instrument).

M3 additionally requires two distinct producer executables (identity
collision detector `WC-BS-01`) and a predeclared agreement rule.

## 5. Verdict

```text
M0 (hybrid)                 ACHIEVED AND RE-MEASURED (9 PolyC decision sites)
M1                          NOT ACHIEVED: 2218 C decision sites remain
M2                          NOT ACHIEVED: no PolyC-authored compiler source set
M3                          NOT ACHIEVED
M4                          OPTIONAL, NOT STARTED
SELFHOST_M2_ACHIEVED        NO
```
