# HANDOFF -- ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01

**ACT:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01`
**Class:** SELFHOST / ABI_FOUNDATION_IMPLEMENT / SOURCE_REPRESENTATIVE_CONSUMER / GRAPH_CUT_PROOF
**Predecessor:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01` (five-commit CLOSE/PASS, re-verified)
**Entry:** `315ff492c077a673c3d78ec536b2a31209a32270` (`99fbc47c714f37c83e0b8d3ec222b9f48724e527`)

VERDICT

PASS

---

Closure verdict authority is the `ACT-Verdict` trailer of the CLOSE commit.
This HANDOFF is a summary. The post-CLOSE terminality receipt is produced
outside the repository after that commit and is not claimed here.

## 1. The outcome in one paragraph

The first genuine source-representative ABI bridge exists. In an isolated,
disposable, detached worktree at the entry commit, a **complete** shadow
compiler was built from a fresh stage0, the nine unmodified parser subjects,
one new experimental PolyC subject and a nine-file patch. In that compiler the
real consumer `src/compile.c` no longer reads `Ast.kind` at all: the node
visibility decision of the `-ast` dump is made by a component compiled from
PolyC source, `AbiCpaShouldPrintAst`, through one checked opaque handle whose
only dereference happens in a mechanical C host adapter. The effective
preprocessed translation unit of `src/compile.c` in the delegating build
contains **zero** `src/ast.h` frames and **zero** Ast member accesses, while the
other thirteen candidate translation units each still contain the layout, so the
cut is neither hidden nor over-claimed. G0 (pristine) and G1 (shadow) agree byte
for byte on all nine frozen witnesses and on the entire 376-assertion parser
suite (identical assertion-sequence MD5). Both causal channels were executed and
both restorations are byte-identical. **Zero production edges are cut and no
production source changed.**

## 2. The frozen selection

```text
SELECTED_EDGE_ID        E-TYP-0136
SELECTED_EDGE_SRC/DST   SYS-COMPILE_DRIVER -> SYS-AST   (TYPE_REPRESENTATION)
SELECTED_CONSUMER_TU    src/compile.c
SELECTED_TU_BLOB_SHA1   ba5468da287c9a1f04e8de8eac0231b792b75591
SELECTED_SOURCE_SHA256  07fb25024ff058b2c0dbbeaa33cd7af827650e796e7dd7e7a3176cb88101c39b
SELECTED_OPERATION      the compilePrintAst node-visibility decision
                        ("print this top-level Ast, or suppress it by kind?")
SELECTED_CALLER         src/main.c:541, reached by `hcc -ast <file>`
```

Two of the three original kind comparisons are live (`AST_EXTERN_FUNC`,
`AST_ASM_FUNC_BIND`); the `AST_FUN_PROTO` comparison is dead at this call site
because `src/parser.c:3470` already filters that kind before `listAppend`. All
three are migrated so the decision stays correct if the parser changes. That
correction is recorded in `c1/selected-consumer-edge.md` together with the wrong
first guess it replaced.

## 3. How the edge was retired, and at what granularity

```text
E-TYP-0136 effective src/ast.h frames in src/compile.c   before 1 -> after 0
src/compile.c Ast member accesses (live build)           before 3 -> after 0
consumer object: Ast.kind load + 0x2401 kind mask        BEFORE  ->  ABSENT
consumer object: PolyC calls                             0 -> 3
subsystem pair COMPILE_DRIVER -> AST                      still carries E-MUT-0137
```

The retired relation is exactly what `E-TYP-0136` asserts -- "`src/compile.c`
requires the `Ast` layout" -- and that relation is gone from the built consumer.
The separate `E-MUT-0137` edge (mutable Ast globals) is **not** claimed as cut and
is **not** affected: a C1 audit found that its recorded witness names five
extern globals that `src/compile.c` never references, which is recorded as
residue rather than silently corrected.

## 4. ABI status

ABI v1 is reused unchanged except for a strict, additive v1.1 delta of two
items: fail-closed generation retirement (the 16-bit counter is never allowed to
wrap; the slot is retired and `-17 SLOT_RETIRED` is returned) and two new
negative statuses. No v1 signature, status value or handle field changed, and
RECON01's historical contract text is untouched.

```text
TOKEN_GENERATION_WRAP   FAIL_CLOSED  (-17, no aliasing token; accelerated near-wrap
                                    through the real transition code)
TOKEN_CAPACITY_DOMAIN   FAIL_CLOSED  (-15 slot exhaustion, -6 domain mismatch)
SIGNED_STATUS_DATA      DISJOINT     (decision 0/1 vs statuses -17..-1; kind
                                    256..299 vs statuses)
APPLE ARM64             measured     (sizeof I64 = 8, u8 = 1, Mach-O `_` decoration,
                                    int->I64 sign extension agrees for 256..299)
RECOVERY                BLOCKED      no setjmp/longjmp surface; 2 symbols in G0,
                                    2 in G1, 0 in the probe
MUTATION CAPABILITY     ABSENT       the compiler adapter exports four mechanical
                                    symbols and no Push/Set/Grant at all
```

A measured trap is documented for every future consumer: because `0xC0DE` sits in
bits 48..63, **every valid handle is a negative I64**, so a handle must never be
tested with `< 0`. Only the *result* of `AbiCpaAstKind` is sign-tested, and that
range is provably disjoint from the status range.

## 5. The two compilers

```text
G0  pristine, unmodified, isolated worktree, fresh stage0 + the nine subjects
    hcc sha256 7f5579849d5f4565f95fae2804ec5c63c7cca48a914bec868b9aa0d4da12b261
    compile.c.o 303aa783e68a767f2ac2bab7cfad26d18bc7bf1d81f8f6d9256e84f9dc58f877
G1  shadow, complete, same producer chain plus one compiled PolyC subject
    hcc sha256 9a4e43bbf595bb15da7cb1b409b07e8bd7269e102383d24aaabe6efa87c36210
    compile.c.o 274601325afd65aef95ec15cb61384fd4563508ee80204e9cb3bde20693cc979
    abi-cpa-host.c.o 23a9940c7a53c4c1d61b54fb82daae1624163b8160e878738270eda06676353d
    PolyC subject   f5dfc1644b4f133a4bfa972e4988231b5eb3ed77ad52a7617093798c8a04d799
    produced by build/host-stage0/hcc
                0e4fe8ff3b6dda63c1e073573cf859cb209305382f7e2267fa073d031a8b2e1a
```

The PolyC subject is a real Mach-O arm64 object that **defines**
`_AbiCpaShouldPrintAst` and **imports only** `_AbiCpaAstKind`. The consumer object
imports it; the shadow binary defines it in the same text region as the nine
`_Bootstrap*` subjects; the link line contains all three new objects. A GNU Make
trap was found and fixed while doing this: a `PRODUCTION_HCC_INPUTS +=` placed
*after* the rule had no effect, so a rebuilt subject left the binary stale. It was
caught with `make -n` and digest comparison, not by a PASS column.

## 6. Equivalence

```text
nine frozen witnesses   9/9 identical stdout + identical stderr + identical exit
                        code + identical diagnostic text (two are malformed sources)
parser unit suite run   376/376 over 90 files
BY THE SHADOW COMPILER  assertion-sequence MD5 b6f117eb1386ca80f81bc06226e2a741
                        -- the historical identity, not merely a count
```

## 7. Both causal channels, executed

```text
(a) PolyC source mutation   remove the AST_EXTERN_FUNC clause, rebuild the
                            subject, relink: the real shadow compiler emits
                            ~500 previously suppressed <extern_function> nodes
                            per case (0 -> 499/502/507/499/505).
                            Subject digest changes; C objects do not.
(b) host accessor mutation  report kind 286 for every node, PolyC untouched:
                            the dump collapses to the single `AST: ` line.
                            PolyC digest unchanged; host digest changes.
Both restorations            source, object and binary digests return to byte
                            identity and behaviour returns to 9/9 MATCH.
```

## 8. Graph accounting -- three ledgers, one proved cut

```text
PRODUCTION_GRAPH   52 nodes, 135 mandatory edges, PRODUCTION_CUT_COUNT = 0
SHADOW_GRAPH       134 mandatory edges, SHADOW_CUT_PROVEN_BY_EXECUTION = 1
                   SHADOW_EDGE_IDS = E-TYP-0136
HYPOTHETICAL_GRAPH 0 edges proposed as cuts by this ACT
SCC (both graphs)  34 SCCs, largest 19, identical member set
                   (C2: transitive closure; C3: Kosaraju -- different algorithms,
                    same partition, recomputed from the original edge IDs)
```

No SCC shrinkage is claimed or expected: `SYS-COMPILE_DRIVER` still reaches
`SYS-AST` through the separate `E-MUT-0137` edge and through other subsystems.

## 9. Controls and acceptance

```text
NEGATIVE_CONTROLS  24/24 executed; 24 PASS; 0 missing; 0 extra; 0 duplicate;
                   0 detector-class mismatch against the frozen contract
MANDATORY_AC       49 PASS + AC50 DEFERRED (external post-CLOSE receipt)
```

## 10. Conservation

```text
PARSER_ASSERTIONS        376/376 over 90 files, MD5 b6f117eb1386ca80f81bc06226e2a741
LEXER07/08/09 DIRECT     89/89, 45/45, 23/23
LEXER07 BROAD            TOTAL=181, FAIL_S0=15, identity MD5 7ee761440de83552e751e3c3976c1683
CROSS_TARGET             67, FAIL_ENVIRONMENT_PREFIX (unchanged)
F_NO_PYTHON              12 (exactly historical; zero new) -- FAIL, not PASS
F_POLYC_TOOLS            UNAVAILABLE (checker still not landed)
Production src/**        0 changed files
Nine PolyC authorities  9 defined in ./hcc; 0 production ABI symbols
GATE_FAST                PASS
GATE_PUSH                PASS (run at the C3 commit; recorded under c4/)
APPEND_ONLY              11/11 PASS
FACTORY_V2 / F14         PASS; predecessor files changed = 0
```

## 11. Self-hosting status -- unchanged

```text
PRODUCTION_POLYC_AUTHORITIES      9
NEW_PRODUCTION_AUTHORITIES        0
PRODUCTION_SEMANTIC_DELTA         0
M0_SELFHOST                       ACHIEVED (nine PolyC parser decision sites)
M1 / M2 / M3                      NOT ACHIEVED
SLICE10_AUTHORIZED                NO
NEXT_TARGET                       NONE
```

The experimental PolyC subject is **not** a tenth production authority. It exists
only inside a deleted worktree, it is not linked into `./hcc`, and the verifier
checks that the production binary defines zero `_Abi*` symbols.

## 12. Residue

```text
P1  E-MUT-0137's recorded witness is inaccurate: it names five Ast extern
    globals as "consumed by src/compile.c" and that file references none of
    them. The edge stays NOT_CUT and is untouched by this ACT. A future
    CENSUS-style correction should re-derive it.
P1  The dormant legacy branch of compilePrintAst keeps `#include "ast.h"`
    behind `#ifndef HCC_USE_SELFHOST_ABI_CPA`, exactly like the nine parser
    authorities. A production migration must decide whether that branch is
    deleted or kept as the stage0 oracle.
P1  `make unit-test` needs an INSTALL_PREFIX that exists; with the default
    `/usr/local` every case reports "Failed to compile". The authoritative
    checkout is configured with a real prefix. Recorded, not repaired.
P2  The PolyC dialect still rejects ternaries, `%lld`/`%02lld` in StrPrint and
    `(I32)` prefix casts; the new verifier works around all three. These are
    compiler ergonomics defects, not ABI blockers.
P2  A `PRODUCTION_HCC_INPUTS +=` placed after the rule silently does nothing.
P2  Signed list payloads remain ambiguous in v1 (`AbiListAt` can legitimately
    return a negative value); this ACT avoids them and the split is left to a
    later ABI version.
P2  F-POLYC-TOOLS enforcement is still not wired into gate-fast.
```

## 13. What a successor may and may not infer

This ACT proves a **shadow** cut. It does not prove a production cut, it does not
reduce the production SCC, and it does not authorize a migration. A successor
ACT of class `ABI_FOUNDATION_PRODUCTION_DELEGATE` may seek separate
authorization to apply the same recipe to tracked `src/**`, using the frozen
recipe in `c1/shadow-build-plan.md`, the header-cut technique in
`c1/feasibility-header-cut.txt` and the verifier in
`tools/quality/abi-foundation-implement01-verify.HC` as its starting gate.

```text
RECOMMENDED_NEXT_ACT_CLASS  ABI_FOUNDATION_PRODUCTION_DELEGATE (separate authorization)
NEXT_TARGET                 NONE
SLICE10_AUTHORIZED          NO
SELFHOST_M2_ACHIEVED        NO
```
