# HANDOFF — ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01

**ACT:** `ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01`
**Class:** SELFHOST / WHOLE-COMPILER / AUTHORITY-INVENTORY / DEPENDENCY-GRAPH / BOOTSTRAP-ROADMAP
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE09` (five-commit CLOSE/PASS, re-verified)
**Entry:** `a7f5648077b27b9af2f29f034eb27b4aba6941f8` (`ce428215cf8e8ec6376782aad7c7182ca188deb7`)

VERDICT

PASS

---

Closure verdict authority is the `ACT-Verdict` trailer of the CLOSE commit.
This HANDOFF is a summary. The post-CLOSE terminality receipt is produced
outside the repository after that commit and is not claimed here.

## 1. The outcome in one paragraph

The first whole-compiler semantic-authority census of the real production
compiler exists, with a typed dependency graph, a computed mandatory SCC
structure, three evidence-derived migration bundles, a bootstrap-readiness
map and a reproducible ACT forecast. The census is not parser-only: it
covers the 46 C translation units and 9 PolyC subject objects that the
linked `./hcc` actually contains, and it separates decision sites from
functions, objects and adapters. The central structural finding is that
19 of 20 compiler subsystems form **one** mandatory migration component,
so the shared type/state ABI — not another parser slice — is the critical
path. The forecast's low bound already exceeds one hundred ACTs.

## 2. Measured census

```text
PRODUCTION_CONFIGURATIONS        1 qualified (CFG-PROD-HCC-JIT-ON)
LINKED_C_TRANSLATION_UNITS       46   (+1 compiled, not extracted)
POLYC_SUBJECT_OBJECTS            9    (+5 dormant lexer components)
LINK_INPUT_ROWS                  68   (55 linked + exclusions with proof)
SOURCE_FUNCTIONS                 2156
FUNCTIONS_WITH_OBJECT_SYMBOL     1598
FUNCTIONS_SOURCE_ONLY_OR_INLINED 558
SEMANTIC_AUTHORITY_SITES         2233 (decision-site rows)
C_AUTHORITY                      2218
C_MECHANICAL_ADAPTER             6
POLYC_AUTHORITY                  9    (the nine parser decisions)
EXTERNAL_DEPENDENCY              2    (libm, libSystem)
UNKNOWN_AUTHORITY                3    (callback dispatch, format dispatch,
                                       recovery jump) + 4 header-inline symbols
NOT_IN_TARGET                    2    (dis_x86_64 member, LLVM backend)
C_DECISION_SITES                 2224 = 311 switch + 1913 coarse/straight
IF_SITES_NOT_SEPARATELY_ENUMERATED 1427 (declared, not dropped)
```

Every row binds a Git blob, a byte range and a range SHA-256; the verifier
re-derives the ranges and rejects a hash from another phase.

## 3. Graph and bundles

```text
MANDATORY_EDGES       238 typed (95 TYPE_REPRESENTATION, 14 CALLBACK,
                      14 MUTABLE_STATE, 12 RECOVERY, 103 CALLS availability)
SCCs (Tarjan)         34 over 52 nodes
LARGEST_SCC           19 subsystems: SCANNER_SUPPORT LEXER ASM_PARSER JSON
                      MEMORY ASSEMBLER JIT COMPILE_DRIVER CFG TRANSPILER
                      REPL LSP CODEGEN PARSER AST IR CONTAINERS DRIVER
                      CONTROL_SYMBOLS
CONDENSED_DAG_EDGES   2
INDEPENDENT_SCC       Kosaraju 34 SCCs, identical partition
MIGRATION_BUNDLES     3 (B-1 core 2136 sites, B-2 88, B-3 the already
                      migrated PolyC component group)
```

`CALLS` edges are deliberately excluded from the SCC: a PolyC caller may
keep calling a C callee, so a call is availability, not migration order.
The mandatory edges are the ones that carry type layout, mutable globals,
container callbacks and recovery state — and they close the core.

## 4. Forecast

```text
M1  154 / 348 / 948
M2  159 / 355 / 961
M3  161 / 358 / 967
M4  201 / 447 / 1208
M2_BELOW_100_ACTS = NOT_SUPPORTED
```

Five perturbations (capacity 6..20 sites/ACT, corrections 25..65%, risk
1.0..1.5) all keep M2 above 100 — the optimistic extreme is 162. The
numbers are derived from the bundle roster and the assumption table in
`c2/forecast-assumptions.tsv`; they are not measured effort, and the
HANDOFF says so rather than presenting them as fact.

Honest caveat: B-3 is the already-migrated PolyC component group and its
5-ACT nominal cost is included in M1, so M1 is if anything slightly
conservative in the *wrong* direction.

## 5. Bootstrap readiness

```text
M0  ACHIEVED and re-measured (nine PolyC parser decision sites)
M1  NOT ACHIEVED (2218 C decision sites remain)
M2  NOT ACHIEVED (no PolyC-authored compiler source set exists)
M3  NOT ACHIEVED
M4  OPTIONAL, NOT STARTED
SELFHOST_M2_ACHIEVED = NO
```

Four blockers are recorded, not repaired:

```text
BB-01   static initialised file-scope scalar / Main(argc,argv) collision
BB-02   pointer-valued ternary and Bool/I64 inference (16 GB OOM lead)
BB-03   shared /tmp/holyc-asm.s assembly temporary race
BB-04   no PolyC-authored compiler source set; the nine subjects are
        produced by the gcc-built stage0 compiler
```

A bounded read-only probe re-ran the stage0 recipe into an isolated
directory: binary `db9aefd3…`, all nine selectors OFF, zero Bootstrap
definitions, producer `/usr/bin/gcc`. It proves the recipe is sound and
the chain is C-rooted; it does not claim M2.

## 6. Artifact findings recorded rather than repaired

* The pre-existing `build/host-stage0/hcc` (`4264610a…`) **defines**
  `_BootstrapStatementDispatch` although the Makefile stage0 recipe
  passes `OFF`. The fresh replay of the same recipe yields the all-OFF
  control, so the recipe is correct and the artifact is stale.
* `hcc-bootstrap02/03/04` binaries disagree with their CMake caches
  (they contain the five lexer components and none of the nine parser
  components while the cache records parser selectors ON). No semantic
  claim is drawn from them.
* Six selector-OFF lexer delegations are `DORMANT_SELECTOR_OFF` with
  zero object imports and zero linked definitions; they are never
  counted as authority.
* The C0 emission of the predecessor freeze table wrote an empty path
  column (the `git ls-files -s` parse split on spaces before the TAB).
  It was regenerated at C3 with the same blob/sha256 columns and a
  correct path column **before** CLOSE; the conservation proof is the
  measured `CHANGED_PREDECESSOR_PATHS_SINCE_C0=0` over 5389 paths.

## 7. Conservation and gates

```text
PARSER_ASSERTIONS              376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5  b6f117eb1386ca80f81bc06226e2a741
LEXER_DIRECT                   89/89, 45/45, 23/23 PASS
LEXER07_BROAD                  FAIL_KNOWN_BASELINE, 15 IDs,
                               MD5 7ee761440de83552e751e3c3976c1683,
                               REGRESSION=0, DIVERGED=0
CROSS_TARGET                   FAIL_ENVIRONMENT_PREFIX, 67 cases
F_NO_PYTHON                    FAIL, exactly 12 historical paths, 0 new
F_POLYC_TOOLS                  UNAVAILABLE (checker not landed)
GATE_FAST                      PASS on the C3 tree
GATE_PUSH                      PASS (build, install, gep01, aot, jit, lsp,
                               diff-check) at subject 838b212
APPEND_ONLY                    11/11 PASS
CLOSURE_STATUS                 PASS (47 pairs)
F14_FREEZE                     5389 paths, 0 changed since C0
REPLACE_REFS                   0
PRODUCTION_SEMANTIC_DELTA      0
```

## 8. Controls and acceptance

```text
NEGATIVE_CONTROLS_TOTAL              24
NEGATIVE_CONTROLS_EXECUTED           24
NEGATIVE_CONTROLS_UNPROVEN           0
NEGATIVE_CONTROLS_PHYSICAL_EXECUTIONS 24 (one process per control, on an
                                     injected copy of the census)
MANDATORY_AC_TOTAL                   50
MANDATORY_AC_PASS                    49
MANDATORY_AC_FAIL                    0
MANDATORY_AC_UNPROVEN                0
MANDATORY_AC_DEFERRED                1  (AC50, post-CLOSE terminality)
```

## 9. Next ACT class (recommendation, not authorization)

```text
NEXT_ACT_CLASS = ABI_FOUNDATION
NEXT_TARGET    = NONE
SLICE10_AUTHORIZED = NO
```

Because the mandatory graph is one 19-subsystem component, the first
bounded prerequisite is a handle/ownership ABI for `AoStr`, `List`, `Map`,
`Ast`, `Cctrl` and `Arena` that a PolyC component can hold without owning
the C layout — and a demonstration that the contract is expressible in the
current PolyC dialect. Another parser slice would migrate a decision while
leaving the ownership boundary that makes the bundle expensive.

## 10. Scope

```text
docs/acts/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01.md
docs/factory/act-handoff-map.tsv            (one additive row)
docs/ROADMAP.md                             (bounded additive section)
evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/**
tools/quality/whole-compiler-census01-verify.HC
tools/quality/whole-compiler-census01-independent.HC
Makefile                                    (additive census01 targets)
```

No tracked `src/**`, `tools/bootstrap/**`, runtime header, existing
tool/test, canonical checker/ranker, gate script, CMake config or closed
ACT/HANDOFF/evidence was modified. `.factory/epic-board.md` does not exist
in this checkout; no board file was created.

## 11. Evidence

`evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c0..c4/`.
C3 holds the independent joins, the Kosaraju partition comparison, the
independent forecast recompute, the sensitivity table, the 24 control
executions and their frozen join, the conservation files, the gate logs
and the exact-ID 50-AC ledger. The whole pipeline is reproducible with
`make census01-all`.
