# Scope and self-hosting milestones (frozen at C0)

**ACT_ID:** `ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01`
**Phase:** C0-RED. This file is the frozen definition of what this ACT
measures. It is not a claim about what has been achieved.

## 1. Programme boundary — derived, not assumed

The boundary is derived from **executable targets and actual link
inputs**, in this order:

1. the real build recipes (`Makefile` targets `production-hcc`,
   `hcc-bootstrap02/03/04`, `bootstrap-stage0`, `test-prefix-install`,
   `unit-test`, and the CMake targets in `src/CMakeLists.txt` and
   `src/asm/CMakeLists.txt`);
2. the link command actually recorded by the configured build
   (`build/CMakeFiles/hcc.dir/link.txt`) and the archive contents
   (`ar t build/asm/libtasm.a`);
3. the symbol table of the linked executable (`nm ./hcc`) joined to the
   symbol table of each candidate object, so that a source file is only
   in the boundary when at least one of its defined symbols is present
   in the linked image;
4. the compile database (`build/compile_commands.json`,
   `CMAKE_EXPORT_COMPILE_COMMANDS=on`) only as a cross-check, never as
   the sole authority, because it does not describe archive member
   inclusion or custom PolyC generation edges.

A directory name is not evidence of linkage. A symbol's existence in an
object is not evidence of production authority.

## 2. Authority classes (frozen vocabulary)

| Class | Meaning | Minimum evidence |
|---|---|---|
| `C_AUTHORITY` | Active C implementation chooses compiler-observable semantics | source range + active configuration + object/call path + witness |
| `POLYC_AUTHORITY` | Active compiled PolyC object chooses the semantics | ON selector + genuine PolyC-produced object + import + link + retired C decision |
| `C_MECHANICAL_ADAPTER` | C projects data, calls an already authoritative PolyC operation, or performs bounded mechanical work; it does not own the decision | call/branch proof **and** a separate identified semantic owner |
| `EXTERNAL_DEPENDENCY` | Library/runtime/platform service outside the semantic self-hosting boundary | reason, provider, link/ABI contract, bootstrap impact |
| `UNKNOWN_AUTHORITY` | Reachable decision whose owner cannot currently be established | named reason and exact evidence gap |
| `NOT_IN_TARGET` | Buildable code demonstrably outside the selected target/configuration | actual target and exclusion proof (e.g. archive member not extracted) |

`C_AUTHORITY` and `POLYC_AUTHORITY` are **decision-site** counts.
`FUNCTION_COUNT`, `TRANSLATION_UNIT_COUNT` and `AUTHORITY_COUNT` are
disjoint metrics. Nine PolyC parser decision sites are not "nine of
1244 functions migrated", and no completion percentage mixes them (see
C0 RED-2).

## 3. Granularity used by this census (declared, mechanically decidable)

Because the ACT forbids silently calling unknown logic "mechanical",
the census uses one decision-site detector with three documented
granularities, all derived from source and object facts:

* `SWITCH_SITE` — one row per `switch` statement in a linked C
  function. A switch over a semantic discriminator is a compiler
  decision; counted as `C_AUTHORITY` with `confidence=HIGH`.
* `POLYC_DELEGATION_SITE` — one row per call to a linked, selector-ON
  `Bootstrap*` symbol. Counted as `POLYC_AUTHORITY`, with the caller
  recorded as its adapter.
* `FUNCTION_COARSE` — one row per linked C function that has
  conditional control flow but no `switch` and no PolyC delegation.
  Counted as `C_AUTHORITY` with `confidence=MEDIUM` and
  `granularity=FUNCTION_COARSE`: a conditional that selects behaviour
  is a semantic decision, while its internal structure is not
  decomposed further by this ACT.

Functions with **no** conditional control flow and no delegation are
`C_MECHANICAL_ADAPTER` only when a semantic owner is identified; the
straight-line construction/projection work they perform cannot itself
choose between observable outcomes. Object functions that cannot be
bound to a source definition (generated code, macro-expanded bodies,
assembly stubs) are `UNKNOWN_AUTHORITY` with a named evidence gap.

## 4. Self-hosting milestones

* **M0 — Hybrid production compiler.** The current state, re-measured:
  nine PolyC-owned parser decisions inside a C compiler. No
  whole-parser or whole-compiler claim is made.
* **M1 — Semantics implementation boundary.** All in-scope compiler
  semantic decisions are PolyC-authored; bounded C/platform glue may
  remain only where it is proved not to own a decision.
* **M2 — First genuine self-hosted compiler generation.** A compiler
  produced by an earlier qualified compiler actually compiles the
  in-scope PolyC-authored compiler sources into a working
  next-generation compiler, with source, producer identity and runtime
  dependency closure demonstrated. Linking PolyC helper objects into a
  C compiler does **not** qualify.
* **M3 — Reproducible convergence.** Qualified successive generations
  agree under predeclared semantic (and, where applicable, normalized
  artifact) comparison, with distinct producer executable identities
  and demonstrated input closure. Hash-identical output alone never
  proves independent producer execution.
* **M4 — Optional broader goal.** Retire additional legacy C
  implementation and discharge expanded proof/portability work. M4 is
  not silently made a prerequisite of M2.

GCC's three-stage bootstrap and Rust's stage0–stage3 vocabulary are
methodological analogies only. The PolyC stage vocabulary is
reconstructed from the actual commands and recorded in
`c1/build-configs.tsv` and `c1/compiler-generation-chain.tsv`.

## 5. Non-goals (binding for this ACT)

No production compiler change, no new parser slice, no replacement of C
by PolyC, no ABI change, no new runtime, no AST rewrite, no edit to any
canonical checker/ranker, no formal-proof expansion, no tool-policy
remediation, no release action, no authorization of a successor ACT,
and no claim that a self-hosted compiler exists unless one is actually
built and exercised.
