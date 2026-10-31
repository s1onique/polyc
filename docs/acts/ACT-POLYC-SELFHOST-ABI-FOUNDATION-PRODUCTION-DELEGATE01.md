# ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT — to be executed, not a completion report
**Class:** SELFHOST / ABI_FOUNDATION_PRODUCTION_DELEGATE / PRODUCTION_AUTHORITY_TRANSFER / SOURCE_REPRESENTATIVE_EDGE_CUT
**Priority:** P0
**Repository:** canonical local PolyC checkout (`s1onique/polyc`); remote availability is not presumed
**Branch:** existing `main`, without a per-ACT branch
**Expected ENTRY_HEAD:** `1d9f0e0646e603861d761c9af6343396fb738b88`
**Expected ENTRY_TREE:** `74a58c0cb9dccc0bd8d658263564a817cbac60af`
**Binding predecessor:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01` — CLOSE/PASS, `PASS_SHADOW_LAYOUT_EDGE_CUT_PROVEN`
**Frozen selected edge:** `E-TYP-0136`, `SYS-COMPILE_DRIVER` → `SYS-AST`, `TYPE_REPRESENTATION`
**Selected source consumer:** `src/compile.c`, `compilePrintAst`, invoked by `src/main.c` for `hcc -ast`
**Selected PolyC authority:** `AbiCpaShouldPrintAst(I64 ast_handle) -> I64 decision_or_status`
**Current active parser authorities:** 9
**Authorized additional production decision authority:** exactly 1, non-parser
**Authorized production graph cut:** at most `E-TYP-0136`
**Behavioral semantic delta:** 0; ownership-authority delta: C → PolyC for exactly one decision
**Successor:** NONE; `SLICE10_AUTHORIZED=NO`; `SELFHOST_M2_ACHIEVED=NO`.

---

## 0. Mission, boundary and non-negotiable truths

Promote the experimentally verified IMPLEMENT01 shadow-only ABI bridge into
the real production compiler. The compiled PolyC component shall own the full
top-level AST visibility predicate used by `compilePrintAst`; C shall retain
AST storage/layout, handles, iteration, `astToString`, printing, diagnostics
and all recovery. The normal production configuration shall no longer
compile the predicate as an active C decision or require `src/compile.c` to
include the concrete AST representation. The selector-disabled C build shall
remain a real, independent fallback/oracle, not a fabricated fixture.

### 0.1 The exact success claim

| Claim | Required evidence |
|-------|-------------------|
| `PRODUCTION_POLYC_CPA_AUTHORITY=YES` | In the effective production build, the actual `_compilePrintAst` delegates the entire visibility decision to the genuinely hcc-compiled `_AbiCpaShouldPrintAst`; C's legacy decision is compiled out. |
| `PRODUCTION_EDGE_CUT=E-TYP-0136` | The production ON effective `src/compile.c` translation unit has zero `src/ast.h` inclusion frames and zero direct `Ast` member reads; the production C object no longer contains the legacy AST-kind classification mask/decision. |
| `C_OFF_ORACLE=LIVE` | A real C-only selector-OFF compiler builds, has no import/reference to the new subject, retains the original C predicate, and matches the frozen reference behavior. |
| `PRODUCTION_POLYC_AUTHORITIES_TOTAL=10` | 9 unchanged parser decision objects plus 1 independently counted CPA production decision; the new subject is defined, imported, linked, reached and causally load-bearing. |
| `PRODUCTION_GRAPH_MANDATORY_EDGES=134` | Recomputed from the frozen 135-edge typed ledger, removing only `E-TYP-0136` if every source/object/preprocessor witness is fully retired. SCC must be computed, not inferred. |
| `SELFHOST_M2_ACHIEVED=NO` | This is an important ABI precedent, not whole-compiler self-hosting. |

The nine parser authorities are counted **separately** from the new
non-parser authority. The report will never say "ten parser authorities".
A source symbol, a test object or a shadow object does not by itself count
as a production authority. An intact SCC is not a failure, and a modified
graph file is never proof of a cut.

### 0.2 Explicit exclusions

This ACT does **not** migrate another compiler operation, add AST ownership
to PolyC, expose raw AST layout or pointers to PolyC, migrate
List/Map/AoStr/Cctrl/Arena, fix general signed `AbiListAt`, repair the
unrelated initialized-static/`argc` bug, the pointer-ternary compiler OOM,
the shared `/tmp/holyc-asm.s` race, historical census forecasting,
`E-MUT-0137`, `F-POLYC-TOOLS`, or historical lexer failures and stage0
defects unrelated to this authorized producer. No SLICE10, no
PARSER-SURFACE-RECON09, no other bundle.

A bootstrap-produced PolyC object, called from real production, is
essential. A pure C translation, an inlined C predicate, a hand-written
object masquerading as PolyC, or an `-ast`-only fixture binary fails the
contract.

---

## 1. C0 entry and historical binding

Before any tracked change this ACT read `AGENTS.md`,
`docs/factory/DOCTRINE.md`, `docs/factory/ACT-TEMPLATE.md`, the Factory-v2
trailer/range/closure/append-only/F14 checkers, the gate entry points, the
IMPLEMENT01 ACT/HANDOFF and its `c0..c4` evidence (including
`c1/selected-consumer-edge.md`, `c1/selected-source-provenance.tsv`,
`c1/shadow-build-plan.md`, `c1/ownership-recovery-contract.md`,
`c1/abi-v1-compatibility-and-v11-delta.md`,
`c1/token-saturation-and-signed-results-plan.md`, `c2/shadow-patch.diff`,
`c2/shadow-source-and-object-manifest.tsv`, `c2/producer-and-linkage.tsv`,
`c2/layout-edge-before-after.tsv`, `c2/g0-vs-g1-differential.tsv`, both
mutation/restoration transcripts and `c2/graph-production-shadow.tsv`),
RECON01's immutable `c2/abi-contract-v1.md`, and CENSUS01's frozen typed
graph and nine subject contracts.

Verified at C0 (`evidence/.../c0/entry-identity.txt`):

```text
HEAD=1d9f0e0646e603861d761c9af6343396fb738b88
HEAD^{tree}=74a58c0cb9dccc0bd8d658263564a817cbac60af
branch=main; clean index and tracked working tree; git replace refs=0
predecessor CLOSE/PASS trailers present; range=5 valid commits; post-CLOSE commits=0
predecessor frozen artifact hashes unchanged (git diff HEAD -- <predecessor> = 0 lines)
src/compile.c sha256 = 07fb25024ff058b2c0dbbeaa33cd7af827650e796e7dd7e7a3176cb88101c39b
    == the predecessor's frozen SELECTED_SOURCE_SHA256
```

A derived SHA-256 manifest of all 61 predecessor evidence files was taken
(`c0/predecessor-terminal-and-freeze.tsv`) — a manifest of the actual
bytes, not a digest of rendered prose.

**Shadow patch identity.** The predecessor's `c2/shadow-patch.diff` is
base64-encoded. It was decoded with
`sed -n '/^%%PATCH-BASE64%%$/,$p' ... | tail -n +2 | base64 -d` and the
decoded bytes hash to `17072ce6f475154ca6052f86dbc893e1b7b7ba46de74d73883ef54954ac5f741`
— the exact digest the predecessor recorded. It contains **9** changed
paths, all listed in `c1/shadow-to-production-patch-reconciliation.tsv`.

**Patch applicability was TESTED, not assumed.** Against a disposable
detached worktree at `ENTRY_HEAD`:

```text
git apply --check shadow.patch                    -> FAIL (Makefile third hunk only)
git apply --check --exclude=Makefile shadow.patch -> PASS (8 of 9 paths)
git apply --check <Makefile hunks 1 and 2>         -> PASS
```

The failing hunk is the trailing append anchored at the end of the
Makefile; the IMPLEMENT01 ACT appended its own block after that anchor.
The two **semantically load-bearing** Makefile hunks — the `CPA_SRC`/`CPA_OBJ`
variable declarations and the `PRODUCTION_HCC_INPUTS += $(CPA_OBJ)`
dependency — apply cleanly. This is recorded rather than hidden, and the
production Makefile rules are written from the frozen recipe *content*; the
effective dependency graph is proven by `make -n` and by the C3 causal
mutation, never by the patch applying mechanically.

---

## 2. Permitted tracked changes

Only the minimum required under:

```text
src/compile.c
src/cctrl.h
src/parser.h
src/ir-types.c                       # ONLY the missing direct ast.h inclusion, if truly required
src/abi-cpa-host.c                   # new, or established equivalent from the frozen shadow patch
src/abi-cpa-host.h                   # new, or established equivalent
src/CMakeLists.txt                   # selector, host TU, subject object and strict link verification
Makefile                             # subject producer, effective prerequisites, ABI-specific gates
tools/bootstrap/selfhost-abi-compile-print-ast.HC    # actual production PolyC component
tools/quality/abi-foundation-production-delegate01-*.HC  # new, independently auditable verifiers
docs/acts/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01.md
docs/factory/act-handoff-map.tsv     # exactly one additive row
docs/ROADMAP.md                      # one bounded additive section
evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/**
```

The frozen experimental PolyC decision is reused **verbatim** at its new
production-authorized path unless a mechanical bootstrap-specific
compatibility change is indispensable and separately proven. There is no
blanket header refactor. The only justified header changes are those
demonstrated by the IMPLEMENT01 shadow's transitive-include cut; every
translation unit that needs an explicit `ast.h` afterwards is validated.
`src/ir-types.c` is adjusted only for the **measured** breakage from
removing the transitive header import.

**The measured breakage is exactly one TU.** In a disposable probe tree
where `src/cctrl.h` and `src/parser.h` stop importing `ast.h`, 15 of the 16
`cctrl.h`/`parser.h`-consuming translation units still compile. Exactly one
breaks: `src/ir-types.c`, with 20 errors covering 12 `AST_TYPE_*`
constants and `struct AstType`. This is the only reason `src/ir-types.c`
is touched.

`src/ast.h`, the AST/allocator implementation, parser semantics, the nine
existing PolyC sources and their selectors, historical ACT files/evidence,
canonical Factory checkers, dependencies, Python and unrelated tests are
**not** changed. ACT-owned witnesses live under this ACT's evidence
namespace; existing tests remain untouched. Any additional required source
path or unfrozen semantic migration is a HALT, not an implicit widening.

---

## 3. Frozen ABI and operational contract

### 3.1 Symbol and behavior

```c
I64 AbiCpaIssueAst(void *ast);            /* mechanical C: returns an opaque handle */
I64 AbiCpaAstKind(I64 ast_handle);        /* C accessor: kind or negative status */
I64 AbiCpaShouldPrintAst(I64 ast_handle); /* compiled PolyC: 0 / 1 / negative status */
void AbiCpaRetireAst(I64 ast_handle);     /* mechanical C: invalidates the borrow */
I64 AbiAbiVersion(void);                  /* ABI version check */
```

The semantic rule is exactly the predecessor predicate: suppress
`AST_FUN_PROTO`, `AST_EXTERN_FUNC`, `AST_ASM_FUNC_BIND`; print the other
top-level AST kinds. The enum numeric values are derived from the live
frozen `src/ast.h` bytes: `AST_ASM_FUNC_BIND=276` (`src/ast.h:120`),
`AST_FUN_PROTO=286` (`src/ast.h:130`), `AST_EXTERN_FUNC=289`
(`src/ast.h:133`). The `0x2401` mask in the prior compiled C object is a
**compiler artifact** of the legacy comparison chain, not an ABI constant,
and is not reused. The new compiler may optimize differently.

The C owner controls iteration over `cc->ast_list`, AST lifetime,
`astToString`, printing and diagnostics. It issues a bounded AST borrow per
node, invokes PolyC, checks the decision/status, retires the token on all
paths (including errors), and never exposes pointer offsets or a raw `Ast*`
to PolyC. The host accessor can read `ast->kind`, but must not decide
visibility. Code-level and object-level evidence distinguish mechanical
host read from semantic C decision.

### 3.2 ABI safety gates

The frozen v1 layout and the bounded v1.1 safety delta are reused. There
is no silent incompatible extension.

* The opaque 64-bit token is host-validated for magic, domain, generation,
  kind, index and arena epoch. Valid tokens have the sign bit set
  (`0xC0DE` in bits 48..63), so a handle must **never** be tested with
  `handle < 0` or `handle >= 0`. Validity is established by the host
  lookup path.
* Generation exhaustion fails closed: the slot is retired, never wrapped
  into an alias; the exact recorded `-17` status is used. Capacity `-15`,
  domain `-6` and the reserved statuses are distinguished by the committed
  ABI definitions, not guessed from a digest.
* For this selected scalar operation only, legitimate kind `256..299`,
  visibility `0/1` and the negative statuses are disjoint. The unresolved
  signed-`AbiListAt` case stays outside scope.
* The production CPA host exposes **no** mutation capability. Every
  unsupported attempt fails without memory mutation. C owns AST
  allocation/free and arena lifecycle. Borrow invalidation on teardown is
  mandatory.
* No nonlocal `setjmp`/`longjmp` across an active PolyC frame, no stored
  callback, no captured pointer across a borrow, and no crash is treated as
  a negative-control success.
* The proven target is Apple ARM64 C ABI / Mach-O, with I64-sized scalar
  parameters, measured symbol decoration and sign extension. No
  cross-target portability is claimed.
* Saturation and repeated issuance/retirement across sufficiently many AST
  nodes must not silently reuse an old live identity. If the slot table
  exhausts during a realistic `-ast`, the host either fails closed with an
  explicit bounded error or implements a separately evidenced safe use
  pattern that respects the frozen ABI. There is no uncontrolled silent
  skip/print on error.

### 3.3 Selector modes (compile-time, not runtime illusion)

| Configuration | Behavior |
|---------------|----------|
| Stage0 / bootstrap host compiler | `OFF`, independent of the new PolyC subject. |
| G0 C-only production oracle | `OFF`; retains the original C decision and its `ast.h` needs. |
| Normal production `./hcc` | `ON`; the compiled PolyC decision is authoritative and the C predicate is compiled out. |
| Adverse producer/selector configurations | Fail closed; never silently substitute C or omit the subject. |

The selector must not be enabled accidentally for other targets or test
tools. The macros and source prerequisites are defined **before** the
Makefile rules consume them, and the effective dependency graph is proven
rather than inferred from `+=` text. Stage0 object provenance, production
ON flags and the host install prefix are independently observable.

---

## 4. Factory-v2 lifecycle: five forward commits
## 5. Exact frozen adverse-control contract: PD-01..PD-24

Each ID is frozen in `c0/frozen-24-controls.tsv` before C1/C2. Each row
carries `control_id`, subject, mutation, `expected_detector_class`,
pristine observation, adverse observation, restored observation,
`execution_id`, source/object hashes and `evidence_path`.

| ID | Adverse condition | Required detector class |
|----|------------------|--------------------------|
| PD-01 | Tamper predecessor frozen path digest | `PREDECESSOR_F14_HASH_MISMATCH` |
| PD-02 | Start from wrong HEAD/tree or replace ref | `ENTRY_IDENTITY_MISMATCH` |
| PD-03 | Substitute a different edge for `E-TYP-0136` | `EDGE_ID_BINDING_MISMATCH` |
| PD-04 | Migrate another AST consumer or other semantic decision | `UNAUTHORIZED_PRODUCTION_SCOPE` |
| PD-05 | Count experimental shadow subject as second production authority | `SHADOW_PRODUCTION_AUTHORITY_CONFLATION` |
| PD-06 | Claim ten parser authorities rather than nine + one CPA | `AUTHORITY_CLASSIFICATION_MISMATCH` |
| PD-07 | Use hand-written C/object instead of hcc-compiled PolyC subject | `SUBJECT_PRODUCER_MISMATCH` |
| PD-08 | Use identical producer executable for G1/G2/G3 despite claiming independence | `COMPILER_GENERATION_PROVENANCE_FAILURE` |
| PD-09 | Place production subject Makefile dependency after consuming rule / stale prebuilt object | `INEFFECTIVE_BUILD_PREREQUISITE` |
| PD-10 | Include symbol in binary but do not execute call from `-ast` | `DORMANT_DELEGATION` |
| PD-11 | Keep active C three-kind print/skip predicate in the ON branch | `LEGACY_C_DECISION_STILL_ACTIVE` |
| PD-12 | Remove literal `ast.h` while restoring it transitively | `TRANSITIVE_AST_LAYOUT_REMAINS` |
| PD-13 | Use direct `Ast` field/offset in production `compile.c` despite claimed cut | `PRODUCTION_LAYOUT_DEPENDENCY_REMAINS` |
| PD-14 | Forge `E-TYP-0136` removal without source/object proof | `UNPROVEN_GRAPH_EDGE_CUT` |
| PD-15 | Drop unrelated typed edge or misreport SCC | `GRAPH_OR_SCC_SET_MISMATCH` |
| PD-16 | Treat valid negative opaque handle as error based on sign | `TOKEN_SIGN_MISCLASSIFICATION` |
| PD-17 | Reuse stale/wrong-kind/domain/expired handle | `HANDLE_LIFETIME_OR_KIND_FAILURE` |
| PD-18 | Wrap generation counter to a previously valid token | `GENERATION_WRAP_ALIAS` |
| PD-19 | Exhaust slot/domain without fail-closed response or leak a live token | `HANDLE_EXHAUSTION_OR_LEAK` |
| PD-20 | Disguise negative signed payload as valid result (or silently widen CPA to List) | `STATUS_PAYLOAD_AMBIGUITY` |
| PD-21 | Trigger nonlocal recovery across a live PolyC frame | `CROSS_FRAME_RECOVERY_UNSAFE` |
| PD-22 | Mutate PolyC source but re-link old object, and still report causality | `POLYC_MUTATION_NONCAUSAL_OR_STALE` |
| PD-23 | Mutate host accessor but still report pristine oracle without difference | `HOST_MUTATION_NONCAUSAL` |
| PD-24 | C-OFF mutant has no effect or ON mutant affects active production behavior | `C_FALLBACK_OR_DORMANCY_VIOLATION` |

Controls may execute in safely isolated copies; crashes, timeouts and
unrelated build failures do not count as detector-sensitive successes. The
verifier carries a specific false-PASS selftest: a deliberately missing
control row, an altered ID, a fake PASS column and a subject substitution
must each be rejected. The control roster is an exact-ID set, not a
number-only count.

---

## 6. Fifty mandatory acceptance criteria

`AC01..AC50` are frozen at C0 in `c0/frozen-50-ac.tsv`. Each terminal PASS
requires an evidence path, a raw command/result or object proof, and
independent recomputation where specified. `AC50` is `DEFERRED` at C3 and
is decided only by the external post-CLOSE receipt.

## 7. Conservation and provenance baseline

The expected historical reference, freshly measured at C0 and re-measured at
C3:

```text
PARSER                   376/376 over 90 files
PARSER_ASSERTION_MD5     b6f117eb1386ca80f81bc06226e2a741
LEXER07_DIRECT           89/89
LEXER08_DIRECT           45/45
LEXER09_DIRECT           23/23
LEXER07_BROAD            FAIL_KNOWN_BASELINE, 15 failure identities
LEXER07_IDENTITY_MD5     7ee761440de83552e751e3c3976c1683
CROSS_TARGET             FAIL_ENVIRONMENT_PREFIX, 67
F_NO_PYTHON              FAIL_KNOWN_BASELINE, 12, zero new
F_POLYC_TOOLS            UNAVAILABLE (authoritative checker absent)
GATE_FAST                PASS
GATE_PUSH                PASS, all seven repository checks
APPEND_ONLY              11/11 PASS
PRODUCTION_PARSER_AUTHORITIES 9, unchanged
PRODUCTION_CPA_AUTHORITIES   1 newly transferred, if and only if proven
M2_SELFHOST              NOT_ACHIEVED
```

A new failure identity is an immediate HALT pending diagnosis. Known FAIL
conditions are never called PASS.

---

## 8. Evidence layout

```text
evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/
  c0/  entry-identity.txt predecessor-terminal-and-freeze.tsv
       selected-shadow-source-and-patch-hashes.tsv production-nine-authorities.tsv
       original-graph-135.tsv frozen-50-ac.tsv frozen-24-controls.tsv
       five-reds.tsv baselines-raw.txt baselines.txt
       red-1-object-and-preprocessed.txt red-2-and-red-3.txt red-4-and-red-5.txt
  c1/  selected-operation-and-enums.tsv original-layout-and-header-chain.tsv
       shadow-to-production-patch-reconciliation.tsv selector-stage0-off-on-build-graph.md
       abi-v11-production-ownership.md g0-oracle-object-and-witnesses.tsv
       frozen-witness-corpus.tsv object-producer-and-target-plan.md cases/
  c2/  production-source-and-object-manifest.tsv c-off-oracle-proof.tsv
       c-on-polyc-authority-proof.tsv effective-make-and-cmake-prerequisites.txt
       abi-handle-and-lifetime-raw.txt g0-g1-differential.tsv
       graph-production-c-off-on.tsv production-edge-cut-proof.tsv phase-build-transcripts.txt
  c3/  four-generations-and-12-ordered-differentials.tsv polyc-mutation-restoration.txt
       host-mutation-restoration.txt legacy-c-dormancy-anti-control.txt
       independent-source-object-recompute.tsv independent-graph-and-scc-recompute.tsv
       negative-controls-raw.tsv frozen-control-execution-join.tsv
       mandatory-50-ac-status.tsv baselines-raw.txt baselines.txt
       gate-fast.txt gate-push.txt source-history-and-f14-conservation.txt
       factory-range-append-only-patch-hygiene.txt
  c4/  terminality-plan.txt
```

All evidence is source/commit/object-addressable. New substantive verifiers
are PolyC, with POSIX/AWK as independent verification rather than as fake
PolyC substitutes.

---

## 9. HALT reasons

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_PROVENANCE_OR_PATCH_MISMATCH
HALT_UNAUTHORIZED_PATH_OR_SEMANTIC_SCOPE
HALT_NO_GENUINE_C_OFF_ORACLE
HALT_STAGE0_BOOTSTRAP_DEPENDENCY
HALT_SUBJECT_PRODUCER_OR_LINKAGE
HALT_INEFFECTIVE_PREREQUISITE_OR_STALE_OBJECT
HALT_LEGACY_C_DECISION_STILL_ACTIVE
HALT_PRODUCTION_AST_LAYOUT_DEPENDENCY_REMAINS
HALT_ABI_TOKEN_OR_LIFETIME_UNSAFE
HALT_STATUS_PAYLOAD_AMBIGUITY
HALT_CROSS_FRAME_RECOVERY
HALT_UNPROVEN_PRODUCTION_GRAPH_CUT
HALT_MULTIGENERATION_PROVENANCE
HALT_DIFFERENTIAL_OR_NEW_FAILURE_IDENTITY
HALT_ADVERSE_CONTROL_NOT_SENSITIVE
HALT_GATE_OR_FACTORY
HALT_TERMINALITY
```

A HALT reports the completed phases, the exact observed evidence, the
unresolved AC/control IDs, the preserved work and the precise next bounded
correction. There is no false PASS.

---

## 10. Exit and successor handoff

A PASS may report one newly authoritative production PolyC decision and one
production type-layout edge cut, with the nine parser decision authorities
conserved. It may not report a smaller 19-subsystem SCC without measured
graph evidence, and it may not claim any reduction in time-to-self-hosting
absent a validated forecast. A subsequent ACT should use the now-proven
production ABI recipe to qualify a core compiler semantic consumer — not
automatically another diagnostic predicate.

```text
NEXT_TARGET=NONE · SLICE10_AUTHORIZED=NO · SELFHOST_M2_ACHIEVED=NO.
```

At C3 the only acceptable pre-CLOSE ledger is **49 PASS / 0 FAIL / 0
UNPROVEN / AC50 DEFERRED**. Any unreconciled required proof is a HALT; no
status field substitutes for its raw witness.

---


| Commit | Phase | Required focus |
|--------|-------|----------------|
| C0 | RED | Exact entry, predecessor freeze, baseline, five live REDs, frozen 50 ACs / 24 adverse controls. |
| C1 | EVIDENCE | Measured C-only oracle, ABI/selector/header-cut constraints, source-bound corpus, build/provenance plan. |
| C2 | IMPL | Bounded production migration of the proven recipe, actual object/producer/linkage and the first production cut. |
| C3 | EVIDENCE | Independent replay, multi-generation equivalence, causal controls, conservation, negative tests and gates. |
| C4 | CLOSE | HANDOFF, ROADMAP, handoff map and one terminal CLOSE with only a terminality plan in the tree. |

---
