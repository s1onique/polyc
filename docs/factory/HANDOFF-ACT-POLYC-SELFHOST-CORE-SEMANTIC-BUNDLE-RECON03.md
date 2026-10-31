# HANDOFF — ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03

Factory-Version: 2
Lifecycle: terminal handoff (descriptive only; the closure verdict is the
`ACT-Verdict` trailer of the CLOSE commit)
Class: SELFHOST / CORE_SEMANTIC / BUNDLE_RECONNAISSANCE / CAUSAL_SELECTION
Binding predecessor: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01,
PASS / PASS_EVIDENCE_SUPPLEMENTED
Earlier predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02,
HALT_PREDECESSOR_PROOF_INCOMPLETE (carried forward unchanged; not
superseded)

VERDICT
------

PASS

  This document is DESCRIPTIVE ONLY. The authoritative verdict for this
  ACT lives in the `ACT-Verdict` trailer of its CLOSE commit, per
  `docs/factory/GIT-METADATA.md` section 1.

  The disposition is `PASS_SELECTED_CORE_BUNDLE`: exactly one coherent
  multi-site bundle of core compiler semantics has been selected, and
  every member of it has been qualified by its own physically separate
  C-source mutation of a real, whole production compiler.

## 1. What this ACT did, in one paragraph

RECON02 halted before its C1 because it could not certify the
predecessor's causal evidence. This ACT binds that evidence first — it
re-derives, by digest identity over the committed blob, that the
historical `M-POLYC-RO` record physically mutated the **pointer** site
and not the **range** site, and it accepts the correction's own
separately executed range-site experiment — and only then performs a
fresh production-linked core census, a frozen sixteen-clause eligibility
contract, a deterministic rank, an independent recomputation, and the
physical causal qualification of the selected bundle. The selected
bundle is `CAND-CMP-CC-A64`: the AArch64 comparison-condition-code
family, three sites, one named invariant, one bounded scalar ABI.

## 2. The two predecessor questions, kept separate

```text
AT_IMPLEMENT01_CLOSE_STRUCTURAL_AUTHORITIES = 13
AT_IMPLEMENT01_CLOSE_CAUSALLY_BACKED        = 12
HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT        = AbiCoreIsValidPointerOperator
HISTORICAL_RO_CAUSAL                        = UNPROVEN_AS_RECORDED
CORRECTION_RO_EXECUTION_ID                  = EXEC-RO-CORR01-MUTANT
CORRECTION_RO_CAUSAL                        = PROVEN (a separate execution)
CURRENT_STRUCTURAL_AUTHORITIES              = 13
CURRENT_CAUSALLY_BACKED_INCLUDING_CORRECTION = 13
```

The correction does not rewrite a single historical byte. It ADDS an
experiment. Both facts are true at once and are reported as two
counts.

The RECON02 technical verdict `HALT_PREDECESSOR_PROOF_INCOMPLETE` and
its forward-only cardinality correction `PASS` are carried forward
unchanged. Nothing in this ACT reopens them.

## 3. The census, and what it excluded

The census was derived from a NEW build in a disposable detached
worktree at the exact C0 commit, over the build's own **38-TU link
line** — not over a source scan alone, and not over the CENSUS01
inventory.

```text
scoped core TUs                 15
top-level function definitions  872
production-reachable C sites     11
dormant C predicates excluded   7
coherent candidate bundles      6
eligible bundles                4
```

The seven exclusions are a MEASUREMENT, not an assumption: each is
defined in a production object yet imported by none and called by
none, so it makes no decision that can reach the emitted assembly, the
emitted object or a compiled program's behaviour, and it can carry no
discriminating witness. They are `irIsStruct`, `irIsPtr`,
`irTypeIsScalar`, `irGetIntSize`, `irAreCompatibleCmpTypes`,
`irIsStore` and `irIsLoad`.

The CFG subsystem was checked and is LIVE (the `-cfg` path emits a
graph), so it is not dead-stripped.

## 4. The rank, and the independent recomputation

```text
R0 bootstrap dependency   1 for every candidate
   (the M2 producer is ABSENT: no PolyC-authored compiler source set
   exists, so R0=2 is unavailable to EVERY candidate and no candidate
   is labelled R0=2 for being inside the 19-subsystem SCC)
R1 semantic impact diversity   1 observed channel for the selected bundle
R2 independently testable sites 3
R3 ABI and invariant coherence  2
R4 graph reduction potential     3 (POTENTIAL_ONLY; NO cut is proven)
R5 implementation risk           0 (no host state writes, no recovery
                                  crossing, no pointer dereference)
R6 candidate identity            the tie-break
```

```text
1  CAND-CMP-CC-A64    (the selected bundle)
2  CAND-CMP-CC-X86
3  CAND-TYPE-CLASS
4  CAND-TYPE-MAP
5  CAND-TYPE-FULL    excluded: E06
6  CAND-CMP-CC-BOTH  excluded: E16
```

The second implementation is a SEPARATE source and a SEPARATE
computation route: its own per-roster data model, its own line scanner,
its own failure bit mask instead of a clause list, and its own
selection sort instead of the primary's insertion sort. It NEVER reads
the primary checker's eligible column; it re-derives every eligibility
decision from the C1 source facts.

```text
ELIGIBILITY_INDEPENDENT_MISMATCHES = 0
RANK_INDEPENDENT_MISMATCHES       = 0
MISSING_IDS = 0   DUPLICATE_IDS = 0
```

The forged-`eligible=YES` control shows why the second implementation
is not redundant: the forgery DOES reach the primary ranker, which is
the documented behaviour of a mechanical join, and the independent
recomputation rejects it and keeps the candidate excluded on its own
E16 clause.

## 5. The causal qualification, in numbers

Three PHYSICALLY SEPARATE experiments, one per member, each in its own
disposable detached worktree, each with its own physical execution id.
No execution is counted twice.

| Site | Mutation | Emitted assembly | Program output |
|------|----------|------------------|----------------|
| SITE-A64-CC-FOR | `aarch64CcFor`'s signed `IR_CMP_LT` suffix `lt` → `ge` | `cset x0, lt` → `cset x0, ge` | LT_OK → **LT_BAD** |
| SITE-A64-CC-INV | `aarch64CcInvFor`'s signed `IR_CMP_LT` suffix `ge` → `lt` | `b.ge` → `b.lt` | LT_OK → **LT_BAD** |
| SITE-A64-CSET | `aarch64EmitCSet`'s materialisation → a fixed suffix | `cset x0, lt`/`cset x0, gt` → `cset x0, ne`/`cset x0, ne` | GT_OK → **GT_BAD** |

Each mutation changed **one line** of one function and was confined to
that function's byte range; the other two functions stayed
byte-identical. Each whole production compiler was rebuilt from
scratch with `BUILD_RC=0`.

The isolation anti-controls are honest about ONE GENUINE COUPLING:
`aarch64EmitCSet` calls `aarch64CcFor`, so a mutation of the FOR site
also moves the CSET site's emitted suffix. The FOR site's isolation
control is therefore W-A64-CC-INV, which does NOT move. This is
recorded, not concealed.

Every source restoration was byte-identical to the pristine digest
(`98ee2460916bd361d1c8b44e1f9d9e28e884e4ef1daf173c06e803a05e09130d`)
and every witness returned to its pristine observation. The linked
executables' digests are NOT byte-reproducible across worktrees,
because the compiler embeds its own build path; that is an explained
embedded-provenance difference, not a semantic one, and the SOURCE
restoration and the OBSERVED SEMANTICS are both exact.

## 6. The successor contract

One contract, frozen and source-hashed:
`evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/c2/selected-bundle-contract.md`
(SHA-256 `77e2a0d5168f02b9f8b550319e60ea32dc6a9f59064a4f54fd2b209ae735f681`,
published separately in `c2/selected-bundle-contract.sha256`).
The digest is published separately because a file cannot contain its
own digest: inserting it would change it.

Its ABI is `ABI-A64-CMP-CC-1`, three exports, a bounded scalar
projection, and a **NULL-pointer** failure signal — deliberately NOT a
negative numeric status, because `IR_CMP_EQ` is the zero of
`IrCmpKind` and a legitimate live value.

```text
required G0/G1/G2/G3 producers       the four-stage chain, byte-identity
required differential comparisons    12, required of the SUCCESSOR
fixture partitions                   VALID, INVALID, BOUNDARY, FALLBACK,
                                     ZERO-DISCRIMINANT
per-site post-migration checks       a PolyC mutation reproducing the
                                     recorded transition, plus a legacy
                                     C-dormancy anti-control
permitted production paths           tools/bootstrap/<component>.HC,
                                     src/aarch64.c, src/CMakeLists.txt,
                                     Makefile
graph impact                         POTENTIAL_ONLY (3 edges), NO cut
```

**The contract does not authorize implementation.**

## 7. Conservation and gates

```text
parser                          376/376 over 90 blocks, MD5
                                b6f117eb1386ca80f81bc06226e2a741
direct lexer07 / 08 / 09        89/89, 45/45, 23/23
broad LEXER07                    181 cases, 15 S0 failures, failure
                                identity MD5
                                7ee761440de83552e751e3c3976c1683
                                FAIL_KNOWN_BASELINE, not PASS
cross-target prefix              67, FAIL_ENVIRONMENT_PREFIX
F-NO-PYTHON                      12 historical violations, 0 new,
                                FAIL_KNOWN_BASELINE, not PASS
F-POLYC-TOOLS                    UNAVAILABLE (the checker is not landed)
production graph                 52 nodes, 134 edges, 34 SCCs, largest 19
proven cuts                      1 (E-TYP-0136); E-MUT-0137 still
                                UNSUPPORTED_WITNESS
PolyC authorities                13, conserved
production semantic delta        0
new production authorities       0
new proven graph cuts            0
F14 path freeze                  12367 paths re-hashed, 0 mismatches,
                                0 missing objects
negative controls                24/24 fired for their own named reason
verifier anti-selftests          18/18 caught with their own reasons
gate-fast                        PASS
gate-push                        PASS (build, install, gep01, aot, jit,
                                lsp, diff-check)
append-only                      11/11 PASS
acceptance criteria              49 PASS, 1 DEFERRED at C3
```

## 8. The scope

```text
ADDED    docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03.md
         docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03.md
         docs/factory/act-handoff-map.tsv   (ONE append row)
         docs/ROADMAP.md                    (bounded append)
         evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/**
         tools/quality/core-semantic-bundle-recon03-*.HC
UNCHANGED src/**, tools/bootstrap/**, tests/**, Makefile, src/CMakeLists.txt,
         scripts/quality/**, the canonical gates, AGENTS.md,
         docs/factory/DOCTRINE.md, docs/factory/GIT-METADATA.md,
         and every closed ACT's evidence
PUSH     none
```

## 9. The residual debts, NOT repaired here

- The `/tmp/holyc-asm.s` shared-scratch race is OPEN. Every compiler
  invocation in this ACT was serialised; the defect itself is not
  repaired.
- The parallel `make -j` object race is OPEN. Every build used
  `make -j1`.
- The unit-test fail-open prefix is OPEN. The measured run is a real
  376/376 against a populated prefix.
- F-POLYC-TOOLS has no landed authoritative checker.
- The ARM64 indexed-byte-load defect is OPEN and is not on this
  bundle's path.
- The cross-target 67-case prefix condition is a missing-prefix
  condition, not a semantic failure; its count was NOT remeasured and
  no number was fabricated.
- The historical `M-POLYC-RO` misattribution is a CLOSED historical
  record and is not re-opened by this bundle.

## 10. The next proposed (NOT authorized) ACT

`ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02`, implementing
`CAND-CMP-CC-A64` against the frozen contract
`ABI-A64-CMP-CC-1`.

It must re-verify this ACT's contract and must NOT assume a particular
file, operator, ABI or production graph cut that was not measured here.
No SLICE10 authorization. No first self-hosting and no M2 claim: the M2
producer is absent, and this bundle does not create one.

## 11. The evidence

```text
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/
  c0/  the entry identity, the post-CLOSE ancestry and commit scope,
        the correction-inclusive predecessor proof, the F14 freeze,
        the existing-authority census, the parser and non-green
        baselines, the frozen 50 ACs, the frozen 24 NCs, the frozen 16
        eligibility predicates and the five RED observations
  c1/  the linked TU and symbol census, the core sites, the core
        authorities, the core dependencies, the core candidates, the
        candidate exclusions, the source enum and ABI facts, the
        bootstrap path, the ownership and recovery witnesses, the
        eligibility input facts and the frozen ranking contract
  c2/  the eligibility output, the site facts, the independent
        eligibility and the independent rank, the rank selection proof,
        the ranked candidates, the selected bundle members, the three
        causal experiments' four files each, the selected causal join,
        the ABI and bootstrap successor contract and the ONE
        source-hashed selected bundle contract
  c3/  the independent source and object audit, the 24 negative
        controls, the 18 verifier anti-selftests, the 50-AC ledger,
        the parser and lexer conservation, the historical non-green
        conservation, the graph and authority conservation, the gates
        and the scope and F14 re-check
  c4/  the terminality PLAN (not a receipt)
```

The external read-only receipt is created **after** the CLOSE commit,
**outside** the repository, and is never backdated into the C3 or CLOSE
commits. AC50 is DEFERRED until it exists.
