# HANDOFF — ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01

**ACT:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01`
**Class:** SELFHOST / ABI_FOUNDATION / OWNERSHIP / EXECUTABLE_RECON / GRAPH_CUT
**Predecessor:** `ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01` (five-commit CLOSE/PASS, re-verified)
**Entry:** `facadfc29bd5284568b6fc1d5c9f96c07e82a07c` (`d778bbe13d913134f76efcb643dd75491df31222`)

VERDICT

PASS

---

Closure verdict authority is the `ACT-Verdict` trailer of the CLOSE commit.
This HANDOFF is a summary. The post-CLOSE terminality receipt is produced
outside the repository after that commit and is not claimed here.

## 1. The outcome in one paragraph

The current PolyC dialect can express and link a bounded C host -> compiled
PolyC -> C host ABI with genuinely opaque 64-bit state handles and checked
status codes. A real `./hcc`-compiled PolyC object read a genuine
`Ast`/`AstType` tree through C accessors and matched an independent C-only
oracle; it also drove a real `List` append and in-place replace through the
host, refused a bounded append atomically, and propagated an injected host
error without changing state. Null, wrong-kind, stale, earlier-generation,
forged, wrong-domain, arena-expired and double-release handles are all
rejected with exact statuses. A causal PolyC-source mutation changed the
linked behaviour and rebuilding restored the object byte-identically.
The interface cuts **zero** mandatory graph edges today because no production
compiler subsystem was recompiled against it; 14 AST/container representation
edges are candidate cuts and the 19-subsystem SCC is unchanged.

## 2. ABI v1 in brief

```text
REPRESENTATION  checked index+generation token in one I64
TOKEN           magic[7:0] domain[15:8] generation[31:16]
                kind[39:32] index+1[47:40] reserved[63:48]
POLYC SEES      one opaque I64 per object; negative status codes
HOST VALIDATES  magic, reserved, index range, domain, token/slot kind,
                liveness, generation, and (AST) the Ast-arena epoch
OWNERSHIP       C host owns every object; PolyC holds OPAQUE_BORROW only
MUTATION        List is read-only until AbiListGrantMutation; otherwise
                MUTATION_WITHOUT_CAPABILITY and no change
RECOVERY        no setjmp/longjmp across PolyC frames; host failures become
                negative status codes at the boundary; Cctrl is NO_HANDLE_YET
ARENA           astMemoryRelease invalidates AST tokens; the accessor checks
                the epoch BEFORE dereference and returns EXPIRED_BORROW_OR_ARENA
```

`Map`, `AoStr`, `Cctrl` and allocation from `Arena` are deliberately not
exposed in v1. The full contract is `evidence/.../c2/abi-contract-v1.md`.

## 3. Measured probe evidence

```text
POLYC PRODUCER                 ./hcc sha256 9e50565b9235ae2939b2333580b45956c3589dddc972e9f4bf6b8cbd2563d90a
POLYC PROBE OBJECT             d414acdc6532021ba1ff69ed41e46fba38fca5853f9a948242917d496b92743a
POLYC SOURCE                   ca2f3e6f8f7baa47cbcd4cf6b1027b1bebc9c36f31d6b1a8b00639072e7873c1
REAL C LIBRARY OBJECTS         src/ast.c src/list.c src/aostr.c src/containers.c src/arena.c src/memory.c
AST READ                       17025 = 17*1000+25; C oracle 17025; MATCH
LIST MUTATION                  append 3->4 with value 40; replace index 1 with 99; observed
BOUNDED APPEND                 status -10 (atomic); count unchanged
CAUSAL MUTATION                x1000 -> x100: result 1725; restored object identical
HOST CONTROLS                  12/12 exact statuses
RECORD CONTROLS                12/12 exact detectors on isolated copies
```

The probe's PolyC object imports exactly the eight host accessors; the C host
defines all eight; relinking closes with no unresolved target and no duplicate
definition. Disassembly/`nm` evidence is in `c3/independent-abi-and-object-recompute.tsv`.

## 4. Graph counterfactual

```text
GRAPH_NODES                    52
MANDATORY_EDGES                135  (CALLS availability edges excluded)
SCC_BASE                       34, largest 19 subsystems
CUT_PROVEN_BY_EXECUTION        0
CUT_CANDIDATE_NOT_PROVEN       14   (13 into SYS-AST, 1 into SYS-CONTAINERS)
NOT_CUT                        121  (including 14 CALLBACK and 12 RECOVERY)
SCC_AFTER_PROVEN_CUTS          34, largest 19
SCC_UNCHANGED                  YES
```

`CUT_PROVEN_BY_EXECUTION` is zero because the definition requires a
source-representative compiler translation unit recompiled against the
interface with its direct C layout/state dependence removed. The fixture is
not a compiler subsystem. The 14 candidates are marked
`CUT_CANDIDATE_NOT_PROVEN`, not converted into a claim.

All 95 `TYPE_REPRESENTATION` mandatory rows are header-inclusion observations
(`#include "x.h"` at line 1), i.e. `OBSERVED_LAYOUT_COUPLING`. They prove the
current include closure, not that two implementations must migrate atomically.

## 5. Forecast and historical audit

```text
HISTORICAL_M2                 159/355/961, preserved as UNQUALIFIED baseline
REMAINING_C_SEMANTIC_SITES    2130 = 2218 C_AUTHORITY - 88 vendored line-editor rows
B-2 (vendored)                EXCLUDED from remaining work
B-3 (9 already-migrated)      EXCLUDED from remaining work
SCENARIO RANGE                148..614 ACTs (unvalidated site->ACT mapping)
NEW_M2_ESTIMATE               UNPROVEN (scenario only)
M2_BELOW_100                  NOT_SUPPORTED
```

CENSUS01 integrity audit, recorded without rewriting history:

* `tools/quality/tl-tmp.HC` and `tools/quality/tn-tmp.HC` are tracked and were
  added by CENSUS01 C3, outside its permitted
  `tools/quality/whole-compiler-census01-*.HC` glob. **Historical scope debt,
  nonblocking**; neither is referenced by any evidence file or production
  target. A bounded correction ACT should relocate or retire them. This ACT
  did not delete or rename them.
* B-1's 2136 decision sites include the six `C_MECHANICAL_ADAPTER` rows; B-2 is
  the 88-row vendored line editor; B-3 costs 5 ACTs for nine already-migrated
  PolyC authorities. The three bundles sum to all 2233 authority rows.
* `ONE_DECISION_PER_ACT` is a malformed five-field row in a six-column table.
* `critical_path_length` equals `total_effort_sum` in all four milestone rows;
  that equality is not derived from the DAG.

A **CENSUS01-CORRECTION** ACT is the correct home for these, not a rewrite.

## 6. Conservation and gates

```text
PARSER_ASSERTIONS             376/376 over 90 files
PARSER_SEQUENCE_MD5           b6f117eb1386ca80f81bc06226e2a741
LEXER07/08/09 DIRECT          89/89, 45/45, 23/23 PASS
LEXER07 BROAD                 FAIL_KNOWN_BASELINE, 15 IDs,
                              MD5 7ee761440de83552e751e3c3976c1683,
                              REGRESSION=0, DIVERGED=0
CROSS_TARGET                  FAIL_ENVIRONMENT_PREFIX, 67 cases
F_NO_PYTHON                   FAIL, exactly 12 historical paths
F_POLYC_TOOLS                 UNAVAILABLE (checker not landed)
GATE_FAST                     PASS on the C3 staged tree
GATE_PUSH                     PASS at subject 0c5c581 (build, install, gep01,
                              aot, jit, lsp, diff-check)
APPEND_ONLY                   11/11 PASS
F14_PREDECESSOR_CHANGES       1 authorized (Makefile additive targets), 0 production
REPLACE_REFS                  0
PRODUCTION_SEMANTIC_DELTA     0
NINE_POLYC_AUTHORITIES        9 CONSERVED
```

## 7. Controls and acceptance

```text
NEGATIVE_CONTROLS_TOTAL        24
NEGATIVE_CONTROLS_EXECUTED     24
NEGATIVE_CONTROLS_PASS         24
MANDATORY_AC_TOTAL             50
MANDATORY_AC_PASS              49
MANDATORY_AC_DEFERRED          1 (AC50 post-CLOSE terminality)
MANDATORY_AC_FAIL              0
MANDATORY_AC_UNPROVEN          0
```


## 8. Bootstrap blockers (unchanged)

```text
BB-01  static initialised file-scope scalar / Main(argc,argv) collision
BB-02  pointer-valued ternary and Bool/I64 inference (the 16 GB OOM lead;
       this ACT independently confirmed that a ternary in tool source breaks
       the producer, and avoided it)
BB-03  shared /tmp/holyc-asm.s assembly temporary race
BB-04  no PolyC-authored compiler source set; the nine subjects are produced
       by the gcc-built stage0 compiler
```

M0 remains ACHIEVED (nine parser decision sites). M1/M2/M3 remain NOT
ACHIEVED. `SELFHOST_M2_ACHIEVED = NO`.

## 9. Next ACT class (recommendation, not authorization)

```text
NEXT_ACT_CLASS = ABI_FOUNDATION_IMPLEMENT
NEXT_TARGET    = NONE
SLICE10_AUTHORIZED = NO
```

The next bounded step is to take one source-representative compiler consumer —
most plausibly an AST reader that today includes `ast.h` only to inspect node
kinds and children — and recompile it against ABI v1, with the C host still
accountable for the object. That is the only route that can move a row from
`CUT_CANDIDATE_NOT_PROVEN` to `CUT_PROVEN_BY_EXECUTION`. Alternatives:
`DIALECT_FFI_CORRECTION` (the measured dialect limits) or
`BUNDLE_QUALIFICATION` (validate the site->ACT mapping before trusting any
forecast).

## 10. Scope

```text
docs/acts/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01.md
docs/factory/act-handoff-map.tsv            (one additive row)
docs/ROADMAP.md                             (bounded additive section)
evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/**
tools/quality/abi-foundation-recon01-graph.HC
tools/quality/abi-foundation-recon01-verify.HC
Makefile                                    (isolated additive targets)
```

No tracked `src/**`, `tools/bootstrap/**`, runtime header, existing tool/test,
canonical checker/ranker, gate script, CMake config, `.githooks` or closed
ACT/HANDOFF/evidence was modified. The probe C sources live only under this
ACT's evidence namespace and are built only as detached, off-production
fixtures.

## 11. Evidence

`evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0..c4/`.
C0 holds entry, freeze, authorities, baselines, REDs, the frozen 50/24
contracts and the CENSUS01 audit. C1 holds the six-family inventory, layout
and lifetime, representations, ownership state machine, callback/recovery
analysis and all 135 edge witnesses. C2 holds the ABI contract, signatures,
real object linkage, AST/container proofs, causal mutation, arena/recovery,
the cut ledger, the before/after SCC and the forecast scenario. C3 holds the
independent recomputations, all 24 control executions, the exact-ID joins,
the conserved baselines, the gate logs, the Factory-v2/F14/append-only proof
and the 49/50 AC ledger. The pipeline is reproducible with
`make abi-foundation-recon01-selftest abi-foundation-recon01-graph
abi-foundation-recon01-verify`.
