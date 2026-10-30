# ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / ABI_FOUNDATION_IMPLEMENT / SOURCE_REPRESENTATIVE_CONSUMER / GRAPH_CUT_PROOF
**Priority:** P0
**Repository:** canonical local PolyC checkout (`s1onique/polyc`); remote availability is not presumed
**Branch:** existing `main`, without a per-ACT branch
**Expected ENTRY_HEAD:** `315ff492c077a673c3d78ec536b2a31209a32270`
**Expected ENTRY_TREE:** `99fbc47c714f37c83e0b8d3ec222b9f48724e527`
**Binding predecessor:** `ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01` — CLOSE/PASS, `PASS_ABI_FEASIBLE_AND_GRAPH_MEASURED`
**Existing active PolyC parser/decision authorities:** 9
**New production authorities authorized:** 0
**Tracked production semantic delta:** 0
**Next target:** NONE; no SLICE10 and no further production migration is authorized by this ACT.

---

## 0. Purpose, outcome and hard boundary

Replace at least one actual layout-dependency edge in a source-representative
compiler consumer with a checked PolyC/C opaque-handle interface, build and run
the modified compiler in an isolated detached worktree, and independently prove
equivalent compiler behaviour plus real producer/object provenance.

RECON01's fixture-only ABI proof is **not** repeated as the deliverable. Its real
`Ast`/`List` probe established that the dialect can use checked host-issued
tokens; it did not establish that any production compiler consumer stopped using
C structure layout. The consumer selected here must originate from the
compiler's linked source graph, must retain its original identity and real
callers, and must be exercised inside an isolated full-compiler build.

### 0.1 Two distinct statements of success

| id | statement | status under this ACT |
|----|-----------|----------------------|
| 1 | `SHADOW_CUT_PROVEN_BY_EXECUTION` — a source-representative consumer compiled in an isolated, full-compiler build no longer directly depends on the selected original C layout edge; a C host owns the object and performs bounded mechanical access; a genuine hcc-compiled PolyC component owns the selected semantic operation. | pursuable |
| 2 | `PRODUCTION_CUT_PROVEN_BY_EXECUTION` | **zero by construction**. `src/**`, the production selector/build configuration and every existing compiler authority are immutable. The production graph stays 52 nodes / 135 mandatory edges / 34 SCCs (largest 19) unless the entry evidence disproves those baselines, in which case this ACT HALTs and reconciles. |

The word *retired* applies to the selected layout dependency **in the shadow
consumer object only**. It must never be used to claim the original production
translation unit has been migrated.

### 0.2 Valid PASS versus HALT

`PASS_SHADOW_LAYOUT_EDGE_CUT_PROVEN` requires at least one original candidate edge
retired in a full, runnable shadow compiler; all required behavioural, ABI,
ownership and causal proofs; exact controls; and external terminality. SCC
shrinkage is *not* required. A fixture-only success, a changed diagnostic alone
without equivalence, a manually deleted edge, or an uncompiled proposed interface
is **not** PASS.

## 1. Entry gate (C0)

Read, in order: `AGENTS.md`; `docs/factory/DOCTRINE.md`; `docs/factory/ACT-TEMPLATE.md`;
the actual commit-trailer checker (`scripts/quality/factory-v2-commit-msg-check.sh`);
the range/closure and append-only tools; the full RECON01 ACT, HANDOFF and
`c0..c4` evidence; the original CENSUS01 graph tables. Then verify
`git rev-parse HEAD`, `HEAD^{tree}`, `main`, a clean index/worktree, zero replace
refs, no post-CLOSE commits and no ACT-created worktrees.

No reset, rebase, amend, replay, force-push or auto-branch may be used to
manufacture entry matching.

## 2. Permitted tracked scope

Only these tracked paths may change:

```text
docs/acts/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01.md
docs/factory/act-handoff-map.tsv                  # one additive map row
docs/ROADMAP.md                                   # one bounded additive section
evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/**
tools/quality/abi-foundation-implement01-*.HC     # new substantial PolyC verifiers
Makefile                                          # optional isolated, additive targets only
```

Experimental changes to the selected `src/**` consumer, a temporary ABI host
adapter, the PolyC subject, local CMake glue and test fixtures are permitted
**only** inside detached disposable worktrees or external build directories.
The exact patch, object/source hashes and commands are preserved as evidence.
The shadow changes are never cherry-picked to `main` during this ACT.

No production source/selector, `src/CMakeLists.txt`, runtime header, closed
ACT/evidence, canonical Factory tool, other existing quality tool, `.githooks`,
external dependency, or Python source may be changed in tracked main.

If real compiler linking requires widening tracked production paths, this ACT
HALTs and proposes a separate production-authorized successor.

## 3. Phase plan (five linear commits)

| commit | phase | scope |
|--------|-------|-------|
| C0 | `RED` | entry, provenance freeze, frozen 50-AC and 24-control contracts, selection policy, five measured REDs |
| C1 | `EVIDENCE` | one frozen real compiler consumer/edge/ABI/G0/corpus/shadow-build plan |
| C2 | `IMPL` | isolated source-representative G1 compiler plus the executable edge-cut proof |
| C3 | `EVIDENCE` | independent recomputation, 24 executed controls, conservation, gates |
| C4 | `CLOSE` | one append-only HANDOFF, roadmap row, map row, terminality plan |

### 3.1 C0 — RED: entry, reproducible failure, frozen obligations

Produce actual measured RED observations:

1. at least one admissible candidate consumer has a **direct** AST/List C layout
dependence (definitive selection is frozen only at C1): preprocessed dependency
chain, exact layout field/offset use, code/object reference and source SHA;
mere header inclusion does not prove semantic use;
2. the nine PolyC authorities are independently load-bearing and no production
ABI-v1 consumer has already retired the proposed candidate edge;
3. ABI v1 can read real AST/List in an isolated probe, but no candidate original
edge is `CUT_PROVEN_BY_EXECUTION`;
4. a bounded wrong-kind/stale token and an invalid mutation fail by **exact host
status**, not by crash;
5. distinct host/PolyC consumer provenance and a previously unknown actual
compiler-use witness are recorded, with a real negative experiment showing the
oracle detects a wrong semantic choice.

`AC01..AC50` and `AI-01..AI-24` are frozen here and may not be executed as PASS
without the recorded runs.

### 3.2 C1 — EVIDENCE: selection and shadow-build contract

Derive the 14 original candidate cuts from committed predecessor bytes, join each
to the original 135-edge ledger by ID and destination, keep every disqualified
candidate and its reason. Choose one eligible source-representative consumer and
one bounded semantic operation under the frozen scoring rules. Freeze an
independent G0 pristine compiler plus a source-derived behavioural corpus; freeze
the ABI version, signatures, status/value encoding, target triple, owner and
borrow scope; prove the host adapter is mechanical and the shadow build plan is a
complete compiler.

Frozen ABI safety gates (not optional documentation): generation wrap, capacity
and domain exhaustion, signed data versus error status, the exact Apple ARM64 C
ABI, and recovery. No `setjmp`/`longjmp` across a live PolyC frame. No process
crash may be counted as a safety detector.

### 3.3 C2 — IMPL: replace the real consumer operation and execute it

In a disposable detached worktree at the original entry commit: rebuild G0 from a
fresh isolated prefix; implement the chosen operation in PolyC using genuine
host-owned state through checked accessors; replace the selected C decision use
in the actual selected TU with a bounded call plus mechanical host dispatch;
remove the direct field/layout usage **and** the effective preprocessor-level
include dependency; compile the PolyC subject with a digest-bound real hcc
producer; link the complete shadow compiler; prove the C legacy decision is not
active in the new path; run the frozen corpus on G0 and G1; demonstrate two
distinct causal channels (PolyC-source mutation, host-accessor mutation) and a
byte-identical restoration; re-run shadow smoke and representative functional
tests.

Failure classification: `HALT_NOT_SOURCE_REPRESENTATIVE` for a component-only or
fixture-only demonstration, `HALT_DORMANT_DELEGATION` for a binary that
references the PolyC symbol but never executes the selected function.

### 3.4 C2 graph accounting (three distinct ledgers)

* `PRODUCTION_GRAPH` — original 52 nodes / 135 mandatory edges, no production
  change, all 14 prior candidates still unproven, `PRODUCTION_CUT_COUNT=0`.
* `SHADOW_GRAPH` — the same source IDs and typed edges with the selected edge
  removed **only** where the shadow source/object/preprocessor evidence proves
  the consumer no longer requires that relation. All other edges remain.
* `HYPOTHETICAL_GRAPH` — interfaces merely proposed; always
  `CUT_CANDIDATE_NOT_PROVEN`; it may not affect either proved result.

SCCs are recomputed from the original individual edges. If the original edge is
an aggregate subsystem relation still supported by another consumer or another
direct use, the row is reported as `PARTIAL_CONSUMER_DECOUPLING_ONLY`, not a
proved cut.

### 3.5 C3 — EVIDENCE: independent verification and controls

Independent recomputation uses a different implementation from the C2 producer: a
new PolyC verifier plus separate POSIX/AWK and Tarjan/Kosaraju graph algorithms,
reading raw bytes and commands rather than C2's verdict column. The verifier must
reject modified source range hashes, an unlinked or wrongly produced subject, an
unexecuted function, and a manually dropped graph edge. All 24 controls
(`AI-01..AI-24`) are executed with their exact detector classes.

`AC01..AC49` must form an exact-ID ledger with 49 PASS, 0 FAIL, 0 UNPROVEN to
pursue PASS. `AC50` stays `DEFERRED` until an external read-only post-CLOSE
receipt exists.

### 3.6 C4 — CLOSE: append-only handoff and terminality

One HANDOFF, one `act-handoff-map.tsv` row, one bounded `docs/ROADMAP.md`
section and `c4/terminality-plan.txt` — a plan only, never a fabricated receipt.
Exactly one terminal Factory-v2 CLOSE commit with `ACT:`,
`ACT-Phase: CLOSE` and `ACT-Verdict:` trailers, prechecked by the real validator.
No amend, rebase or replay. After CLOSE: external read-only HEAD/TREE, range,
clean worktree/index, replace refs, F14, append-only, closure, gate-push,
predecessor freeze and AC50; the receipt is stored **outside** the repository.

## 4. Frozen adverse control contract

Exactly 24 IDs (`AI-01..AI-24`), with the detector classes frozen in
`evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/frozen-24-controls.tsv`.
A crash, timeout, unexpected build failure or generic nonzero exit is not a
detector match unless it is the control's explicit expected target. No control
may be papered over as unexecutable.

## 5. Mandatory acceptance contract

Exactly 50 IDs (`AC01..AC50`), frozen in
`evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/frozen-50-ac.tsv`.
Each PASS must reference raw evidence, exact command/object/source identity, and
independent verification where applicable.

## 6. HALT taxonomy

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_EDGE_INTEGRITY
HALT_NO_SAFE_SOURCE_REPRESENTATIVE_CONSUMER
HALT_ABI_TOKEN_EXHAUSTION
HALT_SIGNED_RESULT_AMBIGUITY
HALT_OWNERSHIP_OR_RECOVERY_UNSAFE
HALT_SHADOW_LINKAGE
HALT_DORMANT_DELEGATION
HALT_NOT_SOURCE_REPRESENTATIVE
HALT_EDGE_NOT_FULLY_RETIRED
HALT_SEMANTIC_DIFFERENTIAL
HALT_CONTROL_NOT_SENSITIVE
HALT_UNPROVEN_GRAPH_CUT
HALT_NEW_REGRESSION
HALT_GATE
HALT_FACTORY
HALT_TERMINALITY
```

A truthful HALT records the completed phase(s), the exact observed AC/control
counts, the raw failure identities and the preserved work. A PASS is never
fabricated and a successful terminal CLOSE is never appended after a terminal
failure.

## 7. Evidence tree

```text
c0/ entry-identity.txt predecessor-freeze.tsv production-nine-authorities.tsv
    original-135-edges.tsv recon01-14-candidates.tsv selection-policy.md
    frozen-50-ac.tsv frozen-24-controls.tsv five-reds.tsv baselines-raw.txt
    baselines.txt red-1-preprocessed-chain.txt red-1-object.txt red-probe/
    red-probe-raw.txt
c1/ candidate-eligibility-and-ranking.tsv selected-consumer-edge.md
    selected-source-provenance.tsv consumer-fields-includes-callers.tsv
    ownership-recovery-contract.md abi-v1-compatibility-and-v11-delta.md
    token-saturation-and-signed-results-plan.md frozen-g0-and-witnesses.tsv
    shadow-build-plan.md
c2/ shadow-patch.diff shadow-source-and-object-manifest.tsv
    producer-and-linkage.tsv abi-handle-safety-raw.txt
    g0-vs-g1-differential.tsv polyc-mutant-restoration.txt
    host-mutant-restoration.txt layout-edge-before-after.tsv
    graph-production-shadow.tsv graph-scc-recompute.tsv shadow-build-raw.txt
c3/ independent-object-and-source-recompute.tsv independent-abi-witness.tsv
    independent-graph-and-scc-recompute.tsv negative-controls-raw.tsv
    frozen-control-execution-join.tsv mandatory-50-ac-status.tsv
    source-and-history-conservation.txt baselines-raw.txt baselines.txt
    gate-fast.txt gate-push.txt factory-v2-f14-append-only.txt
c4/ terminality-plan.txt
```

`shadow-patch.diff` is an evidence artifact, not an authorization to apply that
patch on `main`. Reproduction uses permitted PolyC tooling plus POSIX shell/awk;
no Python and no self-reporting always-green verifier.

## 8. Factory gate separation

C3 may run the applicable pre-CLOSE checks. Factory range/closure/AC50
terminality only become final after C4. The C4 commit contains a terminality
*plan*, not observations it could not yet contain. After C4 a true external
read-only receipt is recorded outside the repository, not as a sixth commit.

## 9. Next authority

`NEXT_TARGET = NONE`. `SLICE10_AUTHORIZED = NO`. `SELFHOST_M2_ACHIEVED = NO`.
This ACT does not perform a production migration; a later ACT may seek separate
authorization for one against this frozen recipe.
