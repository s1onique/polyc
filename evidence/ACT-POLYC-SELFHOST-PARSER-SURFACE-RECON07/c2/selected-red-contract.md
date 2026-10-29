# SELECTED RED CONTRACT (for the successor ACT)

The successor MUST execute these REDs BEFORE it changes any production
source. Each MUST be an ACTUAL EXECUTION against a real seam, with a
real rejection output. A planned RED is not a RED.

| ID | The RED | The detector |
|---|---|---|
| SL-RED-1 | An unmapped function in the successor's own census | Missing exact source/function ID |
| SL-RED-2 | An unbound candidate hash in the successor's identity table | Exact source hash mismatch |
| SL-RED-3 | A forged eligibility decision in the successor's facts | The canonical checker recomputes the clause from the fact and the source-bound DEPENDS detector re-derives the dependence |
| SL-RED-4 | A forged full ranking | The independent recomputer rejects the forged order |
| SL-RED-5 | A PolyC mutant with no provenance/witness link | The mutant's production parser object is byte-identical to the pristine one and the witness output is unchanged, so there is NO causal link |

## THE RED-5 REQUIREMENT IN DETAIL

This ACT measured the failure mode concretely. The CORRECTION01
evidence records a C-ON build whose parser object was byte-identical
to the pristine one while the C source carried a mutation:

```text
PRISTINE_C_ON_PARSER_OBJECT_SHA256=253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246
MUTANT_C_ON_PARSER_OBJECT_SHA256=253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246
C_ON_PARSER_OBJECT_UNCHANGED_BY_THE_C_MUTATION=YES
```

A successor that mutates the PolyC component and observes NO change
in the production object has produced a **dormant** mutation, not a
causal proof. It MUST be classified `NO_CAUSAL_LINK` and MUST NOT be
counted as a discharge of the POST-POLYC-MUTANT control.

## THE RED-3 AND RED-4 REQUIREMENTS IN DETAIL

This ACT measured the failure modes concretely:

* The canonical eligibility checker CANNOT detect a forged fact row:
  it is a pure function of its input. The defence is the
  source-bound `MODE=DEPENDS` verification plus the independent
  re-derivation.
* The canonical ranker DOES trust its `eligible` column: given a
  forged `eligible=YES` for an already-self-hosted candidate, it
  SELECTS it. The defence is that the `eligible` column is the
  checker's OUTPUT and the independent recomputer re-derives it from
  the raw facts.

The successor MUST reproduce both findings, not merely cite them.
