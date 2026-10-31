# HANDOFF — ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01

Factory-Version: 2
Lifecycle: terminal handoff (descriptive only; the closure verdict is the
`ACT-Verdict` trailer of the CLOSE commit)
Class: SELFHOST / CORE_SEMANTIC / FACTORY_V2 / CLOSURE_CARDINALITY_CORRECTION
Binding predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02

VERDICT
------

PASS

  This document is DESCRIPTIVE ONLY. The authoritative verdict for this
  ACT lives in the `ACT-Verdict` trailer of its CLOSE commit, per
  `docs/factory/GIT-METADATA.md` section 1.

  The predecessor's verdict is carried forward unchanged:

```text
ACT-Supersedes: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
ACT-Corrected-Verdict: HALT_PREDECESSOR_PROOF_INCOMPLETE
```

## 1. What was defective

The predecessor ACT committed its C4 CLOSE correctly as `2f1db0e3`, then
made a further commit `8e078b7f` carrying the same ACT trailer. That
commit was unnecessary — its stated purpose was to restate the F14
path-freeze re-verification against the terminal CLOSE commit, but the
committed C3 form of that file already records the measured substance
(5790 frozen paths, 0 mismatches, F14 PASS), and the terminal verification
belongs in the external read-only receipt, which is outside the
repository.

The result is a closure-cardinality defect: the predecessor's ACT id has
**two** CLOSE commits where the Cardinality-1 closure-identity invariant
requires exactly one. The repository's own tools report it:

```text
EXPECTED 1 CLOSE COMMIT FOR ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02, GOT 2
STATUS=FAIL
REASON=expected exactly 1 CLOSE commit in range, found 2
```

A follow-up ordinary commit `4c22f973` restored the C3 form of the file
and made the terminal tree equal the intended CLOSE tree
(`6867b460a6057bf6aaa5dab76d6a777b9f10f141`), but it could not remove
the duplicate CLOSE: every commit after
`baf5dbd77cf89330699685dffd932c54031c815c` is immutable under the
append-only invariant.

## 2. What was repaired

The closure identity is repaired **forward-only**, with the repository's
own mechanism:

- this ACT's CLOSE carries `ACT-Supersedes: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02`;
- it carries `ACT-Corrected-Verdict: HALT_PREDECESSOR_PROOF_INCOMPLETE`;
- it is the **single** CLOSE commit for
  `ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01`, and it
  is the last commit of its own range;
- the predecessor's intended terminal CLOSE `2f1db0e3` is named
  explicitly as the terminal closure of the predecessor's phase range;
- the predecessor's committed bytes are untouched (F14).

The direct precedent is `ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01`,
whose recorded defect D5 is "the historical range has six commits, not
the specified five" and which was repaired forward-only in exactly this
way. The multi-CLOSE state also has direct precedent in this repository:
`ACT-POLYC-LLVM-FLOAT01-CORRECTION01` carries eight CLOSE commits under
the repository's own RE-CLOSE convention.

## 3. What was NOT changed

The predecessor's **technical** result is not revised, weakened or
reinterpreted.

| Item | Value |
|---|---|
| PREDECESSOR_RO_PROOF | UNPROVEN_AS_RECORDED |
| PREDECESSOR_VERDICT | HALT_PREDECESSOR_PROOF_INCOMPLETE (unchanged) |
| HALT_CLASS / BLOCKS_NEXT | GOVERNANCE / NO (unchanged) |
| PRODUCTION_POLYC_AUTHORITIES | 13 structurally active, 12 with causal evidence (unchanged) |
| SITE-RANGE-OPERATOR | still has NO executed causal experiment (unchanged) |
| SELECTED_BUNDLE_ID | NONE (unchanged) |
| NEW_PRODUCTION_AUTHORITIES | 0 |
| PRODUCTION_SEMANTIC_DELTA | 0 |
| NEW_PROVEN_GRAPH_CUTS | 0 |
| GRAPH | 52 nodes / 134 active mandatory edges / 1 proven cut (E-TYP-0136) |

No production source, test, dependency, prior ACT document, prior HANDOFF
or prior evidence file was modified.

## 4. Conservation

| Baseline | Value |
|---|---|
| PARSER_ASSERTIONS | 376/376 over 90 files, MD5 `b6f117eb1386ca80f81bc06226e2a741` |
| LEXER07/08/09 DIRECT | 89/89, 45/45, 23/23 |
| LEXER07_BROAD | FAIL_KNOWN_BASELINE, 15 failure identities, MD5 `7ee761440de83552e751e3c3976c1683` |
| CROSS_TARGET_PREFIX | FAIL_ENVIRONMENT_PREFIX, 67 |
| F_NO_PYTHON | FAIL_KNOWN_BASELINE, 12 historical, 0 new |
| F_POLYC_TOOLS | UNAVAILABLE |
| GATE_FAST | PASS |
| GATE_PUSH | PASS |
| APPEND_ONLY | 11/11 PASS |
| F14 | PASS, 0 mismatches |

## 5. What this ACT does NOT establish

- It does NOT repair the predecessor's **range-site** proof defect. That
  defect is technical, not bookkeeping, and is unchanged.
- It does NOT select a successor bundle.
- It does NOT create a 14th authority, retire a graph edge, or claim
  M1/M2: `SELFHOST_M2_ACHIEVED = NO`, `SLICE10_AUTHORIZED = NO`.

## 6. Proposed next authorized step (proposed, NOT authorized)

`ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01` — the bounded
append-only correction that executes a **real** range-site mutation
(remove `AST_BIN_OP_LT` from `AbiCoreIsRangeOperator`), rebuilds the full
production compiler, records a **discriminating** compiled-program witness
(such as `5 < 1 < 3`, not the non-discriminating `1 < 2 < 3`), and
corrects the site-isolation table without touching the predecessor's
committed bytes.

This correction ACT does **not** authorize it, and does **not** authorize
the bundle selection that follows it.

No publication or push as part of this ACT.

## 7. Evidence index

```text
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01/
  c0/ entry-identity.txt predessor-range.tsv cardinality-defect.txt
      frozen-acceptance.tsv
  c1/ closure-identity-analysis.tsv technical-verdict-carry-forward.tsv
  c2/ (no production artefacts; this ACT changes no production code)
  c3/ cardinality-and-range.txt conservation.txt gates-and-factory.txt
      scope-and-patch-hygiene.txt acceptance-ledger.tsv
  c4/ terminal-closure-identity.tsv terminality-plan.txt
```
