# HANDOFF — ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01

VERDICT
------

PASS

  This document is DESCRIPTIVE ONLY. The authoritative verdict for this
  ACT lives in the `ACT-Verdict` trailer of its CLOSE commit, per
  `docs/factory/GIT-METADATA.md` section 1.

  The disposition is PASS_TWO_A64_CONDITION_AUTHORITIES_WITH_CSET_ADAPTER.

```text
DISPOSITION  = PASS_TWO_A64_CONDITION_AUTHORITIES_WITH_CSET_ADAPTER
BUNDLE_MODE  = TWO_PLUS_ADAPTER
ABI          = ABI-A64-CMP-CC-2 (the corrected, correction-owned ABI)
FUTURE       = 13 -> 15 production PolyC authorities
ENTRY_HEAD   = 23546c7ca224d93bc1b765d92dfad9edbf78229c
ENTRY_TREE   = 0d5ca569ae3a34dab6043607f92380dcc69791b3
BRANCH       = main
NEXT_ACT     = NONE PROPOSED BY THIS ACT
NEXT_TARGET_AUTHORIZED = NO
SELFHOST_M2_ACHIEVED   = NO
SLICE10_AUTHORIZED     = NO
PUSH_PERFORMED         = NO
```

## What this ACT did

The corrected contract
`ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01`
authorised an implementation with a target of **13 → 15** production
PolyC authorities, a new ABI version `ABI-A64-CMP-CC-2`, and exactly
**two** migrated AArch64 condition-code decisions with the CSET site
retained as a C-owned mechanical adapter.

This ACT implemented that contract. It transferred the `aarch64CcFor`
and `aarch64CcInvFor` decisions into a genuinely compiled PolyC
component, `tools/bootstrap/selfhost-a64-cmp-cc-v2.HC`, which exports
**exactly two** public semantic functions and **no third export of any
signature**. The `aarch64EmitCSet` site was **not** migrated: its
whole 152-byte definition carries zero switches, zero cases and zero
`IR_CMP` references, so it owns no condition selection of its own.

## The measurement, not the assertion

Every claim in this handoff is a measurement over the real tree.

### The legacy C tables are gone from the production object

The same `src/aarch64.c` was compiled twice, once with the dedicated
selector `HCC_USE_SELFHOST_A64_CMP_CC` **off** and once **on**:

| Object | Legacy suffix literals | Imports an A64 export |
|---|---|---|
| selector-ON (production) | **0 of 12** | yes, exactly the two |
| selector-OFF (G0 oracle) | **12 of 12** | **neither** |

The fixed `cset    x0, %s` format string is present in **both**
objects, so the CSET emitter survives as a C-owned mechanical adapter.

### The four semantic streams agree byte-for-byte

All four streams were emitted fresh by **one** compiled PolyC
mechanism, `tools/quality/a64-cmp-cc-implement02-corrected01-semantic-stream.HC`,
which *calls* each stream's decision function. The G0 legacy C oracle
was built from the selector-OFF arms of the real `src/aarch64.c`,
extracted verbatim, with the real `IrCmpKind` discriminants.

```text
ALL FOUR STREAMS = 8bbd55a6faa483da2f00f62706a7caecbaa4811b87710975073d2a6830c27f17
FIXTURE ROWS     = 220
MISMATCHES       = 0
```

The three PolyC producers have **distinct** digests
(`fe16a5f7…`, `c0bc92c9…`, `79939fa5…`) and a **byte-identical**
subject (`c321be33…`). The C oracle's *different* digest is reported,
not claimed away.

### The two rosters are distinct and both discharged

* **PAIR** — all twelve ordered all-direction comparisons, each over
  all 220 rows including the failed-domain rows. 12/12 PASS.
* **FROZEN** — twelve heterogeneous obligations, each by its own
  witness. 12/12 PASS.

They have disjoint member ids. A count of twelve in one never
discharges the other.

### The causality is real and the site isolation is real

| Experiment | Pristine | Adverse | Restored |
|---|---|---|---|
| PolyC-source FOR mutation | `cset x0, lt`, exit 2 | `cset x0, ge`, exit 0 | byte-identical |
| PolyC-source INV mutation | `b.ge`, exit 1 | `b.lt`, exit 0 | byte-identical |
| C-only FOR mutation (OFF arm) | live | changed | byte-identical |
| C-only FOR mutation (ON arm) | dormant | **unchanged** | byte-identical |

### The authority census reaches fifteen

Each of the fifteen is defined as a global text symbol in a subject
object the production link line actually consumes, is present in the
linked `./hcc`, and is imported by **exactly one** production C object.

```text
STRUCTURALLY_ACTIVE               = 15
CAUSALLY_BACKED_AT_IMPLEMENT01_CLOSE = 12
CAUSALLY_BACKED_CORRECTION_INCLUSIVE = 13
CAUSALLY_BACKED_AT_THIS_ACT_CLOSE = 15
AUTHORITIES_ADDED_BY_THIS_ACT    = 2
AUTHORITIES_LOST_BY_THIS_ACT     = 0
```

The three causal counts are **never** collapsed, and the historical
12-of-13 is **not** retroactively rewritten.

### The graph is recomputed, not transcribed

```text
GRAPH_NODES = 52   MANDATORY_EDGES = 135   SCCs = 34   LARGEST = 19
NEW_PROVEN_GRAPH_CUTS = 0
```


## The conservation

| Baseline | Result |
|---|---|
| Parser | 376/376 assertions over 90 blocks, sequence MD5 `b6f117eb1386ca80f81bc06226e2a741` |
| Direct lexers | 89/89, 45/45, 23/23 |
| `gate-fast` | PASS (5 checks) |
| `gate-push` | PASS (7 of 7 checks) |
| Append-only | PASS (11/11) |
| Closure status | PASS (59/59) |
| F14 strict | **522 of 523** byte-identical |
| `F-NO-PYTHON` | **FAIL** at the **same** 12 paths, zero new violations |
| `F-POLYC-TOOLS` | **UNAVAILABLE** — the canonical checker does not exist |
| Cross-target | **NOT_REMEASURED**, historical `FAIL_ENVIRONMENT_PREFIX` identity preserved |
| Negative controls | 24/24 fired with their own named reason, all restored |
| Verifier anti-selftests | 14/14 |
| Comparator anti-tests | 9/9 adverse inputs rejected, pristine accepted |

**The one F14 delta is fully accounted for.** The predecessor's
523-path freeze records `docs/factory/act-handoff-map.tsv` at its C3
digest; the predecessor's *own* C4 added exactly one handoff-map row
to that file — one insertion, zero deletions, introduced by the entry
commit `23546c7c`. This ACT never touched that path.

## The scope

Exactly four production paths changed, all inside the authorised list:

```text
Makefile                                  |  80 +++++++++-
src/CMakeLists.txt                        | 101 +++++++++++++
src/aarch64.c                             |  89 ++++++++++-
tools/bootstrap/selfhost-a64-cmp-cc-v2.HC | 238 ++++++++++++++++++++++++++++++
4 files changed, 505 insertions(+), 3 deletions(-)
```

No test file, no script and no canonical gate was modified. No
historical ACT, HANDOFF or evidence file was touched.

## What was found and fixed during the work

Two verifier defects were found and fixed **in this ACT's own tools**,
and both are recorded rather than quietly patched away:

1. The `export-count` detector used a **raw substring search**, so it
   **rejected the very subject source it was meant to accept** — that
   source *states* the prohibition in a prose comment. It now uses the
   same declaration-aware, prose-tolerant test as the `third-export`
   detector. The real source is accepted; a source that really
   *declares* the third export is still rejected.

2. The `legacy-live` detector used `strings` with its default minimum
   length of 4, which filters out **every** two-character AArch64
   condition suffix. It now uses `strings -a -n 2`.

Four **compiler** defects were also discovered and reproduced; they
are outside this ACT's authorised scope and are recorded as classified
residue (RES-01 … RES-04), not silently fixed:

* a global variable **with an initialiser** makes the compiler emit the
  entry point with `argc=0`, so a PolyC program cannot read its own
  arguments;
* a duplicate `extern "c"` declaration of a library function whose
  return type differs from the header's produces a **broken call** that
  segfaults with no diagnostic;
* three-dimensional arrays are not supported;
* the ternary operator `?:` is not supported.

## The deviations, stated plainly

**DEVIATION-01 — the commit-phase shape.** The ACT's section 6 states
the expected range as `C0 RED → C1 EVIDENCE → C2 IMPL → C3 EVIDENCE →
C4 CLOSE` (five commits). The **actual** committed range is `RED,
IMPL, EVIDENCE, CLOSE`: the C1 EVIDENCE phase's evidence files were
committed together with the C3 EVIDENCE phase's files in the C3 commit,
so the C1 phase has no commit of its own.

This was **not repaired**, because the repository's authoritative
history is append-only and inserting a C1 commit *before* the C2 IMPL
commit would require rewriting published history, which the
append-only invariant and the pre-push hook forbid.

It is **not a HALT**, because the canonical Factory-v2 range checker —
which the ACT names as its authority — has **no numeric commit-count
rule**. It enforces only that the range be contiguous, that every
commit carry the ACT id with a valid phase, that FIRST be RED, that
exactly one CLOSE exist and be last, and that no commit after CLOSE
carry the id. The ACT's committed range satisfies every one of those
rules, and each commit's `ACT-Phase` trailer honestly classifies what
that commit actually contains: the C3 commit contains evidence and is
classified `EVIDENCE`.

The external terminality receipt must record the **actual** phase
sequence and the **actual** commit count. It must not report five
commits, because five commits were not made.

## The terminality

`AC50` is **DEFERRED by construction**. The external, read-only
terminality receipt is created **after** the CLOSE commit, **outside**
the Git tree, bound to the exact terminal HEAD and TREE, and it is
never backdated. The plan for it is tracked at
`evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01/c4/terminality-plan.txt`,
and it is explicitly marked **PLAN**, not a receipt.

The committed acceptance ledger closes at **AC01…AC49 PASS** and
**AC50 DEFERRED**. No tracked post-CLOSE receipt and no ordinary
compensating commit are made.

```text
AC_PASS = 49   AC_FAIL = 0   AC_UNPROVEN = 0   AC_NOT_RUN = 0
AC_DEFERRED = 1 (AC50)
```

## Where to look

```text
evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01/
  c0/  entry identity, frozen predecessor, frozen rosters, the five REDs
  c1/  the C oracle, the fixture contract, the producers, the build contract
  c2/  the subject build, the selector objects, the link and relocations
  c3/  the four streams, both rosters, the causality, the 24 controls,
       the verifier anti-selftests, the authority census, the graph,
       the acceptance ledger, the gates
  c4/  the terminality plan (PLAN, not a receipt)
```
