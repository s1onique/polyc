# HANDOFF — ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02

Factory-Version: 2
Lifecycle: terminal handoff (descriptive only; the closure verdict is the
`ACT-Verdict` trailer of the CLOSE commit)
Class: SELFHOST / CORE_SEMANTIC / BUNDLE_SELECTION / SOURCE_AND_OBJECT_RECONNAISSANCE
Binding predecessor: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01

VERDICT
------

HALT_PREDECESSOR_PROOF_INCOMPLETE

  HALT_CLASS = GOVERNANCE
  BLOCKS_NEXT = NO

This ACT did **not** select a successor bundle. It halted at its own C0
predecessor-proof gate, because the independent audit of the predecessor's
`M-POLYC-RO` experiment could not be certified.

The defect is in the predecessor's **recorded evidence**, not in the
production compiler. The production compiler is mechanically green and its
range-operator semantics are correct; the range site is genuinely live and
load-bearing. What is not established is the predecessor's claim that it
had executed a causal experiment for that site.

## 1. The exact failing predicate

ACT §1.2 requires:

> Produce PREDECESSOR_RO_PROOF=VERIFIED_INDEPENDENT or
> UNPROVEN_AS_RECORDED with explicit reason, source and execution IDs.
> If unproven, stop with HALT_PREDECESSOR_PROOF_INCOMPLETE.

The audit produced `PREDECESSOR_RO_PROOF = UNPROVEN_AS_RECORDED`.

ACT §8 (C0) requires:

> If predecessor proof fails, terminal HALT without selecting a successor.

## 2. What was measured

The three predecessor core-operator mutations were recomputed in
disposable detached worktrees at the frozen entry identity
`c05a028276ac3eff3976c113c16b220c7de1331a`, each with a full production
compiler rebuild.

| Predecessor record | Recorded digest | Recomputed mutation | Recomputed digest | Match |
|---|---|---|---|---|
| pristine subject object | `b9a76fe8…4de756` | pristine | `b9a76fe8…4de756` | YES |
| M-POLYC-CA mutant source | `cea1ca06…cfdae1` | CA mutation | `cea1ca06…cfdae1` | YES |
| M-POLYC-PO mutant source | `f61d7ea0…78a4b4` | PO mutation | `f61d7ea0…78a4b4` | YES |
| M-POLYC-PO mutant object | `af566dfb…854b58a` | PO mutation | `af566dfb…854b58a` | YES |
| **M-POLYC-RO mutant source** | **`f0599f79…b916615`** | **PO-LT mutation** (AST_BIN_OP_LT removed from `AbiCoreIsValidPointerOperator`) | **`f0599f79…b916615`** | **YES** |
| **M-POLYC-RO mutant object** | **`2d6a1394…d58c1f8`** | **PO-LT mutation** | **`2d6a1394…d58c1f8`** | **YES** |
| (no predecessor record) | — | RO mutation (AST_BIN_OP_LT removed from `AbiCoreIsRangeOperator`) | `dc068867…f88b3d1` / `c73e734d…ca77eff` | NOT RECORDED |

Four of the five recomputed source digests are **bit-identical** to the
predecessor's records, so the one mismatch is not a build-environment
artifact. The predecessor's `mutation-diffs/M-POLYC-RO.diff` is a
transcription of the *intended* mutation, not the mutation that was
compiled and whose digest was recorded.

**Consequence:** the predecessor's `M-POLYC-RO` physically mutated
`AbiCoreIsValidPointerOperator` (SITE-VALID-POINTER-OP). It never touched
`AbiCoreIsRangeOperator` (SITE-RANGE-OPERATOR). SITE-RANGE-OPERATOR
therefore has **no executed causal experiment** in the predecessor.

The predecessor's recorded `site-isolation.tsv` row for `M-POLYC-RO`
(claiming the pointer `<` witness went `0 -> COMPILE_FAILED`) is false as
written: no range-site mutation changes that witness, and the only
mutation that does is a pointer-site mutation.

## 3. The range site is nevertheless genuinely live

This is a **missing-evidence** defect, not a dead site. A discriminating
chained-range witness separates the two sites cleanly:

| Witness | pristine (selector ON) | selector OFF (stage0 C) | RO mutation | PO mutation |
|---|---|---|---|---|
| `5 < 1 < 3` (discriminating) | EXIT=0 | EXIT=0 | **EXIT=1** | EXIT=0 |
| `1 < 2 < 3` (the predecessor's witness) | EXIT=1 | EXIT=1 | EXIT=1 | EXIT=1 |

The predecessor's own witness (`1 < 2 < 3`) is **not discriminating**:
`(1<2) && (2<3)` and the default left-associative `(1<2) < 3` agree for
that input. A witness such as `5 < 1 < 3` does discriminate:
`(5<1) && (1<3)` is false, while `(5<1) < 3` is `0 < 3`, i.e. true.

The emitted assembly differs as well: the pristine compiler lowers the
chained range to the short-circuit AND form with a separate `.LIRBRP0_E0`
branch block, while the range mutant emits the plain left-associative
comparison.

## 4. The 13-authority baseline

| Claim | Status |
|---|---|
| 13 decision sites are structurally reachable and active in a freshly built production compiler (each defined exactly once, imported by exactly one caller object) | **PROVEN** |
| 13 decision sites each have their own executed causal experiment | **NOT PROVEN** (12 of 13) |

## 5. Conservation

| Baseline | Value |
|---|---|
| PARSER_ASSERTIONS | 376/376 over 90 files, MD5 `b6f117eb1386ca80f81bc06226e2a741` |
| LEXER07_DIRECT | 89/89 |
| LEXER08_DIRECT | 45/45 |
| LEXER09_DIRECT | 23/23 |
| LEXER07_BROAD | FAIL_KNOWN_BASELINE, 15 failure identities, MD5 `7ee761440de83552e751e3c3976c1683` |
| CROSS_TARGET_PREFIX | FAIL_ENVIRONMENT_PREFIX, 67 |
| F_NO_PYTHON | FAIL_KNOWN_BASELINE, 12 historical, 0 new |
| F_POLYC_TOOLS | UNAVAILABLE |
| PRODUCTION POLYC AUTHORITIES | 13 structurally active, 12 with causal evidence |
| GRAPH | 52 nodes / 134 active mandatory edges / 1 proven cut (E-TYP-0136) |
| GATE_FAST | PASS |
| GATE_PUSH | PASS |
| APPEND_ONLY | 11/11 PASS |
| F14 | 5790/5790 frozen paths unchanged |
| REDS | 5/5 executed with sensitive detectors |
| ADVERSE CONTROLS | 8/24 executed and reason-specifically sensitive; 16 NOT_RUN (no subject) |
| ACCEPTANCE CRITERIA | 20 PASS / 3 FAIL / 26 NOT_RUN / 1 DEFERRED; **not** 50/50 |

The known non-green baselines are recorded honestly and are not relabelled
PASS.

## 6. What this ACT does NOT establish

- It does NOT select a successor bundle. `SELECTED_BUNDLE_ID = NONE`.
- It does NOT create a 14th authority. `NEW_PRODUCTION_AUTHORITIES = 0`.
- It does NOT retire a graph edge. `NEW_PROVEN_GRAPH_CUTS = 0`.
- It does NOT demonstrate M1 or M2: `SELFHOST_M2_ACHIEVED = NO`.
- It does NOT repair the predecessor's evidence. F14 forbids it, and the
  ACT forbids writing the correction experiment here.
- It does NOT change any production source: `PRODUCTION_SEMANTIC_DELTA = 0`.
- `SLICE10_AUTHORIZED = NO`, `NEXT_TARGET = NONE`.

## 7. The bounded correction that must precede a 13-authority claim

A separately authorized append-only correction ACT must:

1. execute a **real** range-site mutation (remove `AST_BIN_OP_LT` from
   `AbiCoreIsRangeOperator`) in a disposable detached worktree and rebuild
   the **full** production compiler;
2. record a **discriminating** compiled-program witness (not `1 < 2 < 3`);
3. record the digest of the mutation **actually applied** and verify it
   against the compiled object, so a recorded diff can never again
   disagree with the compiled artefact;
4. record the corrected site-isolation table, in which the RO row names
   the RO site with its own source/object digest and its own execution id;
5. leave the predecessor's committed evidence untouched (F14); the
   correction lives in a new `<original-id>-CORRECTION01/` directory.

## 8. Proposed next authorized step (proposed, NOT authorized)

`ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01` — the bounded
append-only evidence correction described in §7.

A **separate** successor `ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03`
may be opened for the bundle selection itself, provided it does **not**
treat the range site's causal backing as established: the production range
semantics are mechanically green and independently re-proved by this ACT,
so the selection work is not blocked, but the 13-authority *causal*
baseline may only be claimed after the correction.

No default SLICE10 selection. No publication or push as part of this ACT.

## 9. Evidence index

```text
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/
  c0/ entry-identity.txt predecessor-terminal.tsv predecessor-freeze.tsv
      predecessor-ro-attribution.tsv predecessor-ro-attribution-witness.tsv
      predecessor-g0-proof.tsv enum-zero.tsv authority-conservation.tsv
      graph-baseline.tsv parser-conservation.txt non-green-conservation.txt
      five-reds.tsv frozen-50-ac.tsv frozen-24-nc.tsv
      baseline-raw/manifest.txt probes/red-detectors.{sh,out}
  c1/ (not created: the ACT halted at its C0 gate)
  c2/ (not created: the ACT halted at its C0 gate)
  c3/ independent-census.tsv independent-graph.tsv control-execution.tsv
      control-join.tsv control-verifier-selftest.tsv
      authority-conservation.tsv graph-after.tsv parser-conservation.txt
      non-green-conservation.txt gates-and-factory.txt
      ac01-ac49-ledger.tsv predecessor-freeze-recheck.tsv
      probes/nc-detectors.{sh,out} probes/control-verifier-selftest.{sh,out}
  c4/ terminality-plan.txt
```
