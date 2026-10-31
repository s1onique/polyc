# HANDOFF -- ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01

**ACT:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01`
**Class:** SELFHOST / ABI_FOUNDATION_PRODUCTION_DELEGATE / PRODUCTION_AUTHORITY_TRANSFER / SOURCE_REPRESENTATIVE_EDGE_CUT
**Predecessor:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01` (five-commit CLOSE/PASS, re-verified)
**Entry:** `1d9f0e0646e603861d761c9af6343396fb738b88` (`74a58c0cb9dccc0bd8d658263564a817cbac60af`)

VERDICT

PASS

---

Closure verdict authority is the `ACT-Verdict` trailer of the CLOSE commit.
This HANDOFF is a summary. The post-CLOSE terminality receipt is produced
outside the repository after that commit and is not claimed here.

## 1. The outcome in one paragraph

The top-level AST visibility decision of the `-ast` dump is now owned by a
genuinely compiled PolyC component in the **production** compiler. The
decision that used to be an inline C predicate in `src/compile.c` now lives
in `tools/bootstrap/selfhost-abi-compile-print-ast.HC`, compiled by the same
digest-bound stage0 producer that builds the nine existing parser subjects.
The compiled object's digest,
`f5dfc1644b4f133a4bfa972e4988231b5eb3ed77ad52a7617093798c8a04d799`, is the
**same** digest the predecessor froze for the shadow subject, so the proven
component was reused verbatim rather than rewritten. In the production ON
build the effective preprocessed translation unit of `src/compile.c` has
**zero** `src/ast.h` frames and **zero** direct `Ast` member reads, and the
compiled object contains **zero** occurrences of the legacy `0x2401` kind
mask. C still owns the AST layout, the opaque handle table, the only
dereference of the node, iteration, `astToString`, printing and
diagnostics; the host contains **zero** `AST_` comparisons. The
selector-OFF build remains a **real, independent** C oracle: its binary has
no CPA symbol, its link line contains neither the host nor the subject, its
legacy predicate is active, and its `compile.c.o` is byte-identical to the
entry tree's. One production type-layout edge is retired, one non-parser
production decision authority is added, the nine parser authorities are
conserved, and the behavioural delta is zero.

## 2. The frozen selection

```text
SELECTED_EDGE_ID        E-TYP-0136
SELECTED_EDGE_SRC/DST   SYS-COMPILE_DRIVER -> SYS-AST   (TYPE_REPRESENTATION)
SELECTED_CONSUMER_TU    src/compile.c
SELECTED_SOURCE_SHA256  07fb25024ff058b2c0dbbeaa33cd7af827650e796e7dd7e7a3176cb88101c39b
                        (unchanged from the predecessor's frozen value)
SELECTED_OPERATION      the compilePrintAst node-visibility decision
                        ("print this top-level Ast, or suppress it by kind?")
SELECTED_CALLER         src/main.c:541, reached by `hcc -ast <file>`
POLYC_AUTHORITY         AbiCpaShouldPrintAst(I64) -> 0 | 1 | negative status
```

## 3. The production claim, with its evidence

| Claim | Value | Evidence |
|-------|-------|----------|
| `PRODUCTION_POLYC_CPA_AUTHORITY` | YES | `c2/c-on-polyc-authority-proof.tsv`: the ON `compile.c.o` imports `_AbiCpaShouldPrintAst` with a `BR26` relocation at offset `0x70`; the binary defines it; the call is reachable from `hcc -ast`. |
| `PRODUCTION_EDGE_CUT` | E-TYP-0136 | `c2/production-edge-cut-proof.tsv`: the effective ON TU has 0 `ast.h` frames and 0 direct `Ast` member reads; the ON object has 0 occurrences of the legacy mask. The OFF build still has 1 frame, 3 direct reads and the live mask. |
| `C_OFF_ORACLE` | LIVE | `c2/c-off-oracle-proof.tsv`: 0 CPA symbols, 0 CPA imports, neither the host nor the subject in the link line, the legacy predicate active, and `compile.c.o` byte-identical to the entry tree's. |
| `PRODUCTION_POLYC_AUTHORITIES_TOTAL` | 10 | `c3/independent-source-object-recompute.tsv`: 9 parser decision objects plus 1 non-parser CPA decision. The 13 raw symbols are explicitly distinguished from the 10 authorities. |
| `PRODUCTION_GRAPH_MANDATORY_EDGES` | 134 | `c3/independent-graph-and-scc-recompute.tsv`: the original 135-ID set minus exactly E-TYP-0136, recomputed by two independent algorithms. |
| `SELFHOST_M2_ACHIEVED` | NO | This is an ABI precedent, not whole-compiler self-hosting. |

## 4. The three causal channels

| Channel | Experiment | Result |
|---------|-----------|--------|
| PolyC is load-bearing | `PD-C3-M1`: mutate only the new production PolyC predicate | the subject digest changed `f5dfc164` -> `3ff2a2db`, the host object and the nine other subjects did **not** change, and a real `-ast` witness went from 7 lines to 1026. Restored byte-identically. |
| The host is load-bearing | `PD-C3-M2`: mutate only the C host accessor | the host digest changed `62c70a6a` -> `8566dd88`, the PolyC source and object did **not** change, and the same witness went from 7 lines to 1026. Restored byte-identically. |
| The legacy C decision is dormant | `PD-C3-M3`: mutate only the legacy C predicate in the selector-OFF branch | the C-OFF object and witness **changed**; the production-ON object stayed **byte-identical** (`78409b97`) and its witness did not move. |

The third row is the strongest single result in this ACT: the legacy C
decision is a live, load-bearing fallback in the C-OFF build and is
completely absent from the production build.

## 5. Equivalence

* The frozen nine-witness corpus agrees byte for byte across G0 (the
  unmodified entry tree), the selector-OFF oracle and the production ON
  compiler: identical stdout, identical stderr, identical exit status, on
  every row, including two malformed sources whose distinct diagnostic
  identities are compared rather than an exit code.
* All four compiler generations — G0 selector-OFF, G1 stage0-produced
  subject, G2 production-produced subject, G3 bootstrap-generation-produced
  subject — agree on every witness, so all **twelve** ordered generation
  pairs agree. The three producers are three **distinct** executables with
  three distinct digests; the same binary is never counted three times.
* The production ON compiler runs the parser suite at **376/376 over 90
  files** with the historical assertion-sequence MD5
  `b6f117eb1386ca80f81bc06226e2a741`.

## 6. The graph

```text
ACTIVE_PRODUCTION_GRAPH_NODES           = 52
ACTIVE_PRODUCTION_GRAPH_MANDATORY_EDGES = 134   (135 minus the ONE proven cut)
PRODUCTION_PROVEN_CUT_IDS               = {E-TYP-0136}
PRODUCTION_PROVEN_CUT_COUNT             = 1
C_OFF_ORACLE_GRAPH_EDGES               = 135   (configuration-scoped)
HISTORICAL_SHADOW_CUT                  = 1     (not an additional production cut)
SCC_PRODUCTION_BASE                    = 34 SCCs, largest 19
SCC_PRODUCTION_AFTER_CUT               = 34 SCCs, largest 19
SCC_PARTITION_CHANGED_BY_THE_CUT      = NO
E-MUT-0137                             = NOT_CUT / WITNESS_QUALITY_DISPUTED
```

The SCC partition is recomputed from the **original individual edge IDs**
by two different algorithms — Kosaraju and a transitive-closure partition
— both of which reproduce the predecessor's frozen baseline of 34 SCCs with
a largest component of 19. No count was subtracted to obtain them.

## 7. Two findings that changed the work

**A baseline-methodology defect, found and corrected.** The C0 parser
baseline had been measured through a *stale* `src/tests/test-runner` binary.
The host-mode runner invokes the compiler **without** `--install-dir`, so
it needs the compile-time install prefix, and `/usr/local/include` does not
exist on this host. The **unmodified** G0 tree reproduces exactly the same
67 failures as the migrated tree, with identical failure identities, so
this ACT introduced no new failure; the 376/376 figure was an artifact of
the stale binary. Every measurement from C2 onward uses the hermetic
prefix method that `gate-push` itself uses, under which G0 reproduces
376/376 with the historical MD5. `src/tests/` is untouched.

**A real generation-counter defect in the host, found by a control and
fixed.** The first host implementation retired the slot when the 16-bit
generation counter would overflow. That *abandoned* the slot instead of
failing the caller, so the `-17 ABI_SLOT_RETIRED` fail-closed path was
unreachable and the counter wrapped silently. The `PD-18` control now
drives 40 000 issue/retire cycles and observes exactly `-17` at the
overflow, with **zero** aliases across every issued handle. The fix is in
`src/abi-cpa-host.c`; it does not change the consumer object.

## 8. Scope

```text
CHANGED  src/compile.c        the ON branch delegates the decision; the OFF
                              branch keeps the legacy C predicate
CHANGED  src/cctrl.h          ast.h -> forward declarations of Ast/AstType
CHANGED  src/parser.h         ast.h -> forward declaration of Ast
CHANGED  src/ir-types.c       the MEASURED breakage repair: this TU reads
                              AstType members and now states the dependency
                              it used to inherit from cctrl.h
NEW      src/abi-cpa-host.c   the C host
NEW      src/abi-cpa-host.h   the ABI header
CHANGED  src/CMakeLists.txt   the dedicated selector, the ON-only host TU and
                              the fail-closed subject contract
CHANGED  Makefile            the subject producer rule, the effective
                              prerequisite and the selector at every
                              configure site
NEW      tools/bootstrap/selfhost-abi-compile-print-ast.HC
                              the new production PolyC decision component
```

Nothing else under `src/` or `tools/bootstrap/` changed. `src/ast.h`, the
AST/allocator implementation, the parser, the lexer, the nine existing PolyC
sources and their selectors, the test harness, the canonical Factory
checkers, the dependencies and every historical ACT file are untouched. The
predecessor, RECON01 and CENSUS01 evidence namespaces have an empty diff.

## 9. Acceptance and controls

```text
AC ledger       49 PASS / 0 FAIL / 0 UNPROVEN / 1 DEFERRED (AC50)
Controls        24 of 24 SENSITIVE
                each with a pristine pass, a reason-specific firing and a
                restored pass, its own execution ID, and its detector class
                matching the frozen contract
Verifier selftest  the pristine ledger is ACCEPTED; a deleted row, an
                altered ID, a fake PASS column and a substituted subject
                are each REJECTED with a specific reason
```

## 10. The successor

```text
NEXT_TARGET=NONE · SLICE10_AUTHORIZED=NO · SELFHOST_M2_ACHIEVED=NO
```

A subsequent ACT may use the now-proven production ABI recipe to qualify a
**core compiler semantic consumer** — not automatically another diagnostic
predicate. This ACT deliberately does not select that target.
