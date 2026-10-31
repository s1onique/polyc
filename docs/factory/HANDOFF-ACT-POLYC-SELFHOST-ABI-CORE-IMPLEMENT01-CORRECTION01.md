# HANDOFF — ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01

Factory-Version: 2
Lifecycle: terminal handoff (descriptive only; the closure verdict is the
`ACT-Verdict` trailer of the CLOSE commit)
Class: SELFHOST / ABI_CORE / APPEND_ONLY_EVIDENCE_CORRECTION / CAUSAL_ATTRIBUTION
Binding historical defect: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01, misattributed M-POLYC-RO physical mutation
Discovering ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02, HALT_PREDECESSOR_PROOF_INCOMPLETE, GOVERNANCE / BLOCKS_NEXT=NO

VERDICT
------

PASS

  This document is DESCRIPTIVE ONLY. The authoritative verdict for this
  ACT lives in the `ACT-Verdict` trailer of its CLOSE commit, per
  `docs/factory/GIT-METADATA.md` section 1.

  The disposition is `PASS_EVIDENCE_SUPPLEMENTED`: the missing causal
  evidence for SITE-RANGE-OPERATOR is supplied by this correction's
  own executed experiment, without rewriting a single historical byte.

## 1. What this correction did, in one paragraph

The thirteenth structurally active PolyC decision authority,
`AUTH-13 / SITE-RANGE-OPERATOR / _AbiCoreIsRangeOperator`, had **no
causal experiment of its own**. The predecessor's `M-POLYC-RO` record
claimed one, but its recorded source and object digests are
bit-identically the digests of a **pointer-site** mutation: removing
`AST_BIN_OP_LT` from `AbiCoreIsValidPointerOperator`, not from
`AbiCoreIsRangeOperator`. This ACT executed a **new, independently
attributable** physical experiment on the range site and recorded it
under its own execution id, `EXEC-RO-CORR01-MUTANT`, with its own
source digest, its own object digest, its own linked compiler and its
own discriminating compiled-program witness. It did **not** rewrite,
rename, replace, annotate or invalidate a single historical byte.

## 2. The two questions, kept separate

```text
IMPLEMENT01_HISTORICAL_M_POLYC_RO_EXECUTED_ON_RO   = NO
IMPLEMENT01_HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT  = AbiCoreIsValidPointerOperator
HISTORICAL_RO_CAUSAL                               = UNPROVEN_AS_RECORDED (unchanged)
RECON02_HISTORICAL_HALT                           = HALT_PREDECESSOR_PROOF_INCOMPLETE (unchanged)
RECON02_CORRECTION_VERDICT                        = PASS (unchanged)
CORRECTION_RO_ACTUAL_SUBJECT                      = AbiCoreIsRangeOperator
CORRECTION_RO_EXECUTION_ID                         = EXEC-RO-CORR01-MUTANT
CORRECTION_RO_CAUSAL                               = PROVEN
```

The historical defect **remains true**. What changes is that the
missing evidence is now supplied by a later, separate execution.

## 3. The new experiment, in numbers

```text
WITNESS_RO_PRISTINE_EXIT   = 0
WITNESS_RO_MUTANT_EXIT     = 1
WITNESS_RO_RESTORED_EXIT   = 0
PO_ANTI_CONTROL_RO_WITNESS_EXIT = 0
WITNESS_PO_LT_EXIT_UNDER_THE_RO_MUTATION = 0   (UNCHANGED)
WITNESS_CA_EXIT_UNDER_THE_RO_MUTATION  = 30  (UNCHANGED)
HISTORICAL_NONDISCRIM_EXIT             = 1   (UNCHANGED -- it cannot discriminate)
CORRECTION_RO_SOURCE_SHA256 = 5bfe5b6048374a9e12c48aa13b3e66beb764d7b14b97813c761c486926161da9
CORRECTION_RO_OBJECT_SHA256 = c73e734dc6b735bd738fd2e3f5735f10b577d5048730d586d2892b153ca77eff
```

The witness is `W-CORR-RO-DISCRIM`, the chained-range expression
`5 < 1 < 3`. The range lowering reads it as `(5 < 1) && (1 < 3)` =
FALSE = 0; without the range lowering it is left-associated, `(5 < 1)
< 3` = TRUE = 1. The historical witness `1 < 2 < 3` reads TRUE under
**both** lowerings and therefore cannot separate them; it is retained
as `W-HISTORICAL-NONDISCRIM` and explicitly labelled insufficient.

The **emitted assembly** is an independent witness of the lowering
change and not a restatement of the exit status: the pristine
emission contains the range-lowering short-circuit block (the
`.LIRBRP0_E0` branch, the `cset x0, lt` comparison and a second
compare-and-branch) and the mutant emission contains **none** of it.
The structural shape falls from 5 branches / 3 compares / 7 labels to
2 / 1 / 4, and returns exactly on restoration.

## 4. Site isolation, proven by execution

| Site | Execution id | Source digest | Object digest | Witness | Transition |
|---|---|---|---|---|---|
| SITE-COMPOUND-ASSIGN | M-POLYC-CA | `cea1ca06...` | `035ce7e1...` | W-CA | 30 → 246 → 30 |
| SITE-VALID-POINTER-OP | EXEC-PO-CORR01-ANTI | `f0599f79...` | `2d6a1394...` | W-CORR-PO-LT | 0 → COMPILE_FAILED |
| SITE-RANGE-OPERATOR | EXEC-RO-CORR01-MUTANT | `5bfe5b60...` | `c73e734d...` | W-CORR-RO-DISCRIM | 0 → 1 → 0 |

Four distinct execution ids, four distinct source digests, four
distinct object digests. No physical experiment is counted for more
than one site.


## 5. The corroboration, and what it is not

The **PO anti-control** is a second, distinct physical mutation in
its own worktree and its own full rebuild. Its applied source digest
and its subject object digest are **bit-identical** to the historical
`M-POLYC-RO` recorded digests:

```text
historical M-POLYC-RO source digest = f0599f79900cf406415283a9742c2b3d794c03f107e7a959ce021db91b916615
EXEC-PO-CORR01-ANTI source digest   = f0599f79900cf406415283a9742c2b3d794c03f107e7a959ce021db91b916615
historical M-POLYC-RO object digest = 2d6a1394dffa8b513af092971338692e113cbf893c4d52a0b554afda9d58c1f8
EXEC-PO-CORR01-ANTI object digest   = 2d6a1394dffa8b513af092971338692e113cbf893c4d52a0b554afda9d58c1f8
```

This is an **independent reproduction of the historical defect from
the opposite direction**, and it is corroboration — never a substitute
for the RO experiment. The RO experiment stands on its own measured
transition and its own assembly change.

Symmetrically, the RO mutant's subject object digest
`c73e734dc6b735bd738fd2e3f5735f10b577d5048730d586d2892b153ca77eff`
coincides with the digest the correction's own reference table records
for RECON02's independent exploratory RO mutant. That is a
cross-check; the proof is this execution's own measured 0 → 1 → 0
transition.

## 6. The authority accounting, as two distinct counts

```text
PRODUCTION_AUTHORITIES_STRUCTURAL            = 13
HISTORICAL_AUTHORITIES_WITH_CAUSAL_PROOF      = 12   (at the IMPLEMENT01 close)
CORRECTION_INCLUSIVE_AUTHORITIES_WITH_CAUSAL_PROOF = 13 (after this correction)
NEW_PRODUCTION_AUTHORITIES                    = 0
PRODUCTION_SEMANTIC_DELTA                     = 0
NEW_PROVEN_GRAPH_CUTS                         = 0
PRODUCTION_GRAPH = 52_NODES_134_EDGES_34_SCC_LARGEST_19
```

**It is not true** that thirteen of thirteen authorities had causal
backing at the IMPLEMENT01 close; AUTH-13 did not. **It is true** that
after this correction's own executed experiment, thirteen of thirteen
do. The two statements are different and only the second one is made
here. The structural count of 13 is independently recomputed at C3:
each of the 13 symbols is defined exactly once in the freshly built
production compiler and imported by exactly one caller object.

## 7. Conservation and gates

```text
parser                       376/376 over 90 test blocks, MD5 b6f117eb1386ca80f81bc06226e2a741
lexer direct                 89/89, 45/45, 23/23
lexer broad (LEXER07)        181 cases, 15 historical S0 failures, MD5 7ee761440de83552e751e3c3976c1683
                             regression 0, diverged 0
F-NO-PYTHON                  12 historical violations, 0 new
F-POLYC-TOOLS                UNAVAILABLE (the checker is not landed; not claimed as PASS)

## 8. The scope

No `src/**` byte changed. No `tools/bootstrap/**` byte changed. No
existing test, Makefile, CMake file, canonical verifier or gate
changed. No prior ACT document, HANDOFF or closed evidence byte
changed. The F14 per-path re-verification over all 6434 frozen paths
found **0** mismatches and **0** missing paths. Every mutation lived
in a disposable detached worktree, and all four ACT-owned worktrees
were removed afterwards; the pre-existing worktrees were left alone.

The substantive PolyC verifier
`tools/quality/abi-core-implement01-correction01-verify.HC` is new and
is PolyC-authored; its own compiled object and its own execution are
verified, and its SHA-256 implementation was first validated against
the NIST `"abc"` vector and against `shasum -a 256` on the real subject
file, so a verifier that hashed wrongly could not certify a wrong
digest.

## 9. The residual debts, NOT repaired here

```text
DEBT_01  the unit-test fail-open prefix                        NOT REPAIRED HERE
DEBT_02  the shared /tmp/holyc-asm.s assembly temporary race   NOT REPAIRED HERE
DEBT_03  the 67 cross-target missing-prefix cases              NOT REPAIRED HERE
DEBT_04  the 12 F-NO-PYTHON violations                         NOT REPAIRED HERE
DEBT_05  the F-POLYC-TOOLS checker is not landed               NOT REPAIRED HERE
DEBT_06  a parallel make -j races two rules onto one object    NOT REPAIRED HERE
DEBT_07  an arm64 scaled-index byte load emits invalid asm     NOT REPAIRED HERE
```

DEBT_06 and DEBT_07 were observed during this execution and are
recorded as residue. Every build in this ACT was serial, and the
verifier reads bytes through a moving pointer for the same reason.
Neither debt is repaired here, and neither is silently absorbed.

## 10. The next proposed (NOT authorized) ACT

`ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03` — a **fresh**
selection ACT. It must perform a fresh source/object census, because
RECON02 halted before its C1 and therefore no selected bundle was ever
inherited. There is no inherited bundle to carry forward.

No push or publication was performed under this ACT. The local
append-only chain and its existing `origin/main` lag are preserved. A
future fast-forward publication requires separate operator
authorization and ancestry verification.

## 11. The evidence

```text
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/
  c0/  entry identity, the F14 freeze, the historical RO
       reconstruction, the baselines, the authority census, the frozen
       28-AC and 12-NC contracts, the RED detector's
       pristine/adverse/restored proof
  c1/  the source function identity, the enum domain, the intended
       mutation, the ABI ownership, the witness contract, the genuine
       selector-ON/OFF builds, the producer and link provenance, the
       experiment plan and the rollback
  c2/  the pristine, RO-mutant, PO-anti and restored executions: the
       applied mutation, the object and link provenance, the witness
       matrix, the corrected site isolation, the restoration identity
       and the source/object/witness/execution join
  c3/  the independent re-derivation, the twelve negative controls,
       the verifier anti-selftests, the authority conservation, the
       graph and F14 re-check, the conservation baselines, the gates
       and the AC01-AC27 ledger
  c4/  the terminality PLAN (not a receipt)
```

The external read-only receipt is created **after** the CLOSE commit,
**outside** the repository, and is never backdated into the C3 or
CLOSE commits.

gate-fast                    PASS
gate-push                    PASS
append-only                  11/11 PASS
F14 path freeze              6434 paths frozen and re-hashed, 0 mismatches, 0 missing
negative controls            12/12 fired for their own named reason
verifier anti-selftests      13 run: 3 silent on the genuine state, 10 fired
acceptance criteria          27 PASS, 1 DEFERRED at C3
```

The cross-target 67-case prefix condition and the F-POLYC-TOOLS
unavailability are recorded with their provenance, not with a
fabricated re-measurement.
