# Selected Proof Contract — successor migration ACT

ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT_PHASE=C2-RANK-SELECT
EVIDENCE_KIND=selected-proof-contract

This document FREEZES the proof obligations for the successor ACT that
migrates CAND-001 `parseValidPostControlFlowToken` to a production
authoritative PolyC component.

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE02
NEXT_ACT_DESCRIPTIVE_TITLE=ACT-POLYC-SELFHOST-PARSER-CONTROL-FLOW-TOKEN01
TARGET_SYMBOL=BootstrapValidPostControlFlowToken
TARGET_LEGACY_SYMBOL=parseValidPostControlFlowToken
TARGET_LEGACY_SOURCE=src/parser.c:832..864
```

---

## 1. The sixteen frozen proof dimensions

| # | Proof dimension | Requirement | Frozen acceptance predicate |
|---|---|---|---|
| 1 | **Legacy reference** | Execute the ACTUAL C implementation, not a handwritten substitute. | The reference side of the differential calls `src/parser.c::parseValidPostControlFlowToken` (or a build of `src/parser.c` that contains it) directly. A re-implementation of the decision table in the harness is FORBIDDEN. |
| 2 | **Direct differential** | Compare C authority against the PolyC implementation. | For all 42 fixtures of `c2-selected-fixture-model.tsv`, the C result and the PolyC result are equal. Mismatches reported per fixture, not just as a count. |
| 3 | **Fixture coverage** | Normal, boundary, negative and malformed inputs. | The fixture matrix is present, complete (42 rows), and includes: NULL/EOF; the accepted and rejected punctuation and keyword classes; unknown token kinds; unknown and negative numeric payloads; and structurally valid but semantically rejected kind/value combinations. |
| 4 | **Component fixed point** | Four generations and all six pairwise comparisons. | Objects G0..G3 are produced by four successive generations. All 6 pairwise comparisons (G0-G1, G0-G2, G0-G3, G1-G2, G1-G3, G2-G3) are equal for the component's observable behaviour. |
| 5 | **Generation provenance** | Actual compiler, input, object and output identities. | Each generation records the producing compiler's identity, the component source's identity, the produced object's identity, and the observed output identity. All four are real SHA-256 values bound to real artifacts, not labels. |
| 6 | **Generation-copy control** | Forged provenance rejected even for byte-equal objects. | A forged provenance record for a byte-equal object is REJECTED by the verifier. A control exists that proves the verifier rejects forgery, not merely that it accepts good records. |
| 7 | **Production delegation** | The real compiler consumes the PolyC result. | The production binary contains the PolyC symbol AND the production call path reaches it. The legacy C decision body is NOT compiled into the production binary (it lives only in the non-production branch, exactly as the padding migration did). |
| 8 | **Production causal mutation** | A mutated component produces observable divergence. | The M1..M6 mutation classes are exercised. At least M1 is demonstrated at the PRODUCTION level: the mutated production binary rejects a control-flow body beginning with an identifier and emits the existing "while parsing if body" diagnostic, while the pristine production binary compiles the same input. |
| 9 | **Legacy authority retirement** | No independent C semantic calculation on the enabled production path. | On the enabled production path, the decision is computed ONCE, by the PolyC component. There is no second, independent C computation of the same decision in the production binary. The stage0 legacy oracle may exist as a deliberate control, exactly as `ParserLegacyCalcPaddingOracle` does today (`src/parser.c:476`). |
| 10 | **Parser conservation** | Current canonical parser tests actually EXECUTED. | The live canonical parser test target is run (inspect the Makefile for the live target name; do NOT rely on a historical command name), and its actual output and return code are recorded. |
| 11 | **Lexer conservation** | Current canonical lexer tests actually EXECUTED. | Same requirement for the lexer test target. |
| 12 | **LEXER07** | Compare to the prospective SHA-bound baseline. | The LEXER07 corpus is rerun and compared to the baseline identity recorded in `docs/factory/LEXER07-BASELINE-AUTHORITY.tsv`. Known baseline failures are reported separately from NEW failures. A failed full corpus MUST NOT be relabelled `STATUS=PASS` merely because the failure set is known. |
| 13 | **F14** | Closed artifacts unchanged. | `git diff --name-only <ENTRY>..HEAD -- evidence/` shows zero changes to any closed ACT's evidence directory, and zero changes to any closed HANDOFF. |
| 14 | **F-POLYC-TOOLS** | New substantive tooling is PolyC. | Any new substantive tool the successor adds is written in PolyC. Shell is permitted only as ≤50-LOC bootstrap glue. |
| 15 | **F-NO-PYTHON** | No new Python source or invocation. | Zero new tracked Python sources, zero Python shebangs, zero Python invocations. |
| 16 | **Factory gates** | Unmodified required gates execute. | The unmodified `gate-fast` and `gate-push` scripts, `factory-v2-test.sh` and `factory-append-only-test.sh` execute and their exact results are recorded. A gate that fails is reported as failed, not waived. |

---

## 2. Fixed-point semantics — what equality does and does not prove

```text
Fixed-point equality demonstrates REPRODUCIBILITY, not semantic
correctness.
```

The 4-generation / 6-pairwise requirement (dimension 4) proves that the
component's behaviour is a stable function of its input across
successive self-hosted compilations. It does **not** prove that the
behaviour is the RIGHT behaviour.

Semantic correctness is established by dimension 2 (the direct
differential against the actual C function) and dimension 8 (the
production causal mutation). A successor that ran only the fixed point
and reported "PASS" would be reporting an all-green-by-construction
claim, which the ACT forbids.

---

## 3. Stage0 → stage1 semantics for this migration

The successor's stage model is frozen as follows. This is an
**intentional stage0→stage1 migration**, and the ACT requires the
successor to freeze which stage is the control and which stages must
match exactly.

```text
stage0 = the LEGACY CONTROL build
         The production compiler built WITHOUT the new PolyC component.
         It computes the decision in C.  It is the differential's
         reference and the control for the production causal mutation.

stage1 = the PolyC production build.
         The production compiler built WITH the new PolyC component
         linked and the production call path routed through it.

stage2, stage3 = further self-hosted generations of the production
         compiler (or of the component, per the successor's design).
```

**Required equality assertions (frozen):**

```text
ASSERTION_1  stage0 and stage1 MUST produce IDENTICAL observable
              behaviour on the entire fixture matrix.
              This is an EQUALITY assertion.  It is NOT a "migration
              delta" assertion.  A migration is not supposed to change
              behaviour, so any stage0/stage1 difference is a DEFECT,
              not an expected delta.

ASSERTION_2  stage1, stage2 and stage3 MUST produce identical observable
              behaviour to each other and to stage0.

ASSERTION_3  The legacy C decision body MUST NOT be present in the
              stage1/stage2/stage3 production binaries on the enabled
              path.  The stage0 binary MAY contain it -- it is the
              deliberate control.

ASSERTION_4  The production causal mutation MUST produce a stage1'
              (mutated) build whose observable behaviour DIFFERS from
              stage1 on the affected fixtures, and MUST differ at the
              PRODUCTION level (the "while parsing if body" diagnostic),
              not only inside the differential harness.
```

**No silent substitution.** The successor MUST NOT weaken an equality
assertion into a "delta within tolerance" assertion. If the successor
genuinely needs a behaviour change, that is a different ACT with
explicit semantic authorization, not a footnote in this one.

---

## 4. What the successor must NOT do

The successor inherits the forbidden list of this ACT:

```text
- implement parseStatement / parseDecl* / parseExpr* / parseToplevel*
  wholesale
- migrate parseCompoundStatementInternal (R0=5, recovery-coupled)
- migrate CalcClassSize (R0=4, host-graph writer) as part of this ACT
- change Ast / Cctrl / Lexeme / Map / List layouts
- change parser recovery behaviour
- move diagnostic ownership or cctrlRaiseException into PolyC
- modify canonical test oracles
- change Factory validators or hooks
- add Python
- add a substantive shell or C tool
```

Plus, specific to this component:

```text
- change the ABI shape frozen in c2-selected-abi-contract.md
- accept a Lexeme* (or any host pointer) across the PolyC boundary
- bind the token/keyword constants to anything other than the numeric
  values defined in the live src/lexer.h (see the aliasing note on
  TK_SUPERSCRIPT/TK_STR = 0x301)
- treat the component as production-authoritative while the legacy C
  decision body is still compiled into the enabled production binary
```

---

## 5. Successor objective

```text
The successor ACT must leave the repository in a state where:

  PARSER_CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY = POLYC
  LEGACY_C_CONTROL_FLOW_TOKEN_AUTHORITY = RETIRED (on the enabled path)
  and the production binary's observable behaviour is unchanged from the
  legacy control for every input.
```
