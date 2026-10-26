# Selected RED Model — CAND-001 `parseValidPostControlFlowToken`

ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT_PHASE=C2-RANK-SELECT
EVIDENCE_KIND=selected-red-model

The successor migration ACT must be able to exhibit a mechanically
reproducible RED proving that the semantic production authority of this
component is STILL in C.  This document freezes what that RED must
establish and how it is reproduced.

```text
RED_MODEL_COMPLETE=YES
RED_MODEL_REPRODUCIBLE=YES
PRODUCTION_AUTHORITY_LEGACY_C=YES
```

---

## RED-1 — Legacy authority exists

**Claim.** The production C source still implements the semantic
decision for `parseValidPostControlFlowToken`.

**Frozen witness.**

```sh
$ sed -n '832,864p' src/parser.c
int parseValidPostControlFlowToken(Lexeme *tok) {
    if (tok == NULL) return 0; /* EOF - caller raises */
    if (tok->tk_type == TK_IDENT) return 1;
    if (tok->tk_type == TK_STR) return 1;
    if (tok->tk_type == TK_PUNCT) {
        switch (tok->i64) {
            case TK_MINUS_MINUS:
            case TK_PLUS_PLUS:
            case '{':
            case ';':
            case '*':
                return 1;
        }
    }
    if (tok->tk_type == TK_KEYWORD) {
        switch (tok->i64) {
            case KW_DO:
            ...
                return 1;
        }
    }
    return 0;
}
```

**Live call sites (all 5 execute on ordinary production compiles).**

```sh
$ grep -n 'parseValidPostControlFlowToken' src/parser.c
832:int parseValidPostControlFlowToken(Lexeme *tok) {
950:    if (!parseValidPostControlFlowToken(peek)) {
961:        if (!parseValidPostControlFlowToken(epeek)) {
1254:    if (!parseValidPostControlFlowToken(peek)) {
1288:    if (!parseValidPostControlFlowToken(peek)) {
1321:    if (!parseValidPostControlFlowToken(peek)) {
```

**Reproduction.** The command above is deterministic and re-runnable at
any time. The five call sites are in `parseIfStatement` (if body and
else body), `parseForStatement`, `parseWhileStatement` and
`parseDoWhileStatement` — every ordinary control-flow construct in the
language reaches this function.

**Note on what this RED does NOT claim.** It does not claim the function
is unreachable, and it does not claim the compiler misbehaves. It claims
the *semantic decision* — which tokens may begin a statement after a
control-flow header — is computed by C code, in the production binary,
on every such construct.

---

## RED-2 — PolyC authority absent

**Claim.** The intended PolyC production delegate
`BootstrapValidPostControlFlowToken` does not exist and is not connected
to the selected production call path.

**Frozen witness.**

```sh
$ grep -rn 'BootstrapValidPostControlFlowToken' src/ tools/ 2>/dev/null
   (no output)
```

At the C2 boundary this symbol does not exist anywhere in the tree.

**Existing unrelated PolyC helpers do NOT satisfy this RED.** The
repository already contains five self-hosted PolyC components
(`docs/factory/SELF-HOST-COMPONENTS.tsv`):

```text
identifier_scanner         BootstrapScanIdent
operator_punctuation_recognizer  BootstrapClassifyOperator
scalar_literal_scanner     BootstrapScanScalarLiteral
trivia_scanner             BootstrapScanTrivia
link_directive_scanner     BootstrapLinkDirective
```

plus the already-migrated `BootstrapCalcPadding`. **None of them
implements the control-flow-token decision**, and none of them is
reachable from `parseValidPostControlFlowToken`. Their presence is
irrelevant to this RED: the RED is about THIS semantic decision.

**Reproduction.** `grep -rn 'BootstrapValidPostControlFlowToken'` over
`src/` and `tools/` returns nothing at the C2 boundary. The successor
repeats this before it implements anything; after implementation the
symbol exists, and the RED transitions from RED-2 to GREEN.

---

## RED-3 — Production delegation absent

**Claim.** A production build with the current configuration does not
execute the proposed new PolyC component.

**Frozen witness.**

```sh
$ nm build/hcc | grep -c '_BootstrapValidPostControlFlowToken'
0
```

The symbol is absent from the production binary.

**This is NOT satisfied by a shadow test or a dead linked object.** The
distinction the ACT draws is mechanical:

| Situation | Is it production delegation? |
|---|---|
| Symbol present in `build/hcc` but no production call site reaches it | **NO** — dead linked object |
| A separate test binary calls the PolyC component | **NO** — shadow test |
| The PolyC component is called only by a differential harness | **NO** — shadow test |
| `src/parser.c::parseValidPostControlFlowToken` (or its 5 call sites) routes its decision through the PolyC component in the production binary | **YES** |

The successor must demonstrate the LAST row. The precedent for this
distinction is the completed padding migration, whose qualification
recorded `PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC` together with the
proof that the legacy C body lives only in the `#else` branch that
production does not compile.

**Reproduction.** `nm build/hcc | grep -c '_BootstrapValidPostControlFlowToken'`
returns 0 at the C2 boundary.

---

## RED-4 — No qualified successor proof

**Claim.** The proposed successor does not yet have complete
direct-differential, independent-generation, provenance, and
production-causal qualification.

**Frozen witness — the specific MISSING evidence, not an absent
filename.** At the C2 boundary none of the following exists:

| Proof dimension | What is missing at the C2 boundary |
|---|---|
| Direct differential | No harness compares the actual C `parseValidPostControlFlowToken` against any PolyC implementation over the 42-row fixture matrix (`c2-selected-fixture-model.tsv`). |
| Independent generation | No stage0/stage1/stage2/stage3 object generations of a control-flow-token component exist. The component source does not exist. |
| Generation provenance | No provenance records bind compiler identity, input identity, object identity and output identity for any generation. |
| Production delegation | See RED-3. |
| Production causal mutation | No mutation campaign exists that changes a bounded decision and shows observable divergence in the production binary. |
| Legacy authority retirement | The production binary still computes the decision in C. |

**Reproduction.** Each row is checkable by a concrete command (the
`grep`/`nm` commands above; and the absence of any
`selfhost-parser-control-flow-token*` artifact under `tools/bootstrap/`
and `build/`). This is a statement of missing evidence, not of a missing
filename alone.

---

## RED-5 — Observable causal sensitivity

**Claim.** A feasible mutation exists that changes a bounded candidate
decision WITHOUT causing an unrelated compile or link failure, and
without changing the component's ABI.

**Frozen mutation plan.** The mutation is applied to the PolyC subject's
decision logic, inside the component body, NOT to the ABI, NOT to the
build graph, and NOT to any production file.

| Class | Mutation | Affected fixtures | Expected observable |
|---|---|---|---|
| **M1** | Drop the `TK_IDENT` acceptance (return 0 for `TK_IDENT`) | F002, F003, F004 | the differential reports a mismatch on 3 fixtures |
| **M2** | Drop the `TK_STR` acceptance | F005, F006 | mismatch on 2 fixtures |
| **M3** | Drop one accepted punctuation case (`'*'`) | F011 | mismatch on 1 fixture |
| **M4** | Drop one accepted keyword case (e.g. `KW_ASM`) | F029 | mismatch on 1 fixture |
| **M5** | Accept `TK_PUNCT` with ANY payload (drop the payload switch) | F012..F017 | mismatch on 6 fixtures |
| **M6** | Treat `token_present == 0` as accepted | F001 | mismatch on 1 fixture |

**M1 is the primary causal class.** It is load-bearing because it
changes the decision on the *most common* production input (an
identifier starting a control-flow body) while leaving the component
type-correct, linkable, and ABI-compatible. It therefore cannot be
masked by a compile error or a link error.

**Required successor sequence (all steps, in order):**

```text
build pristine subject
build mutated subject
link both successfully
run both on identical fixtures
observe a semantic difference
restore pristine subject
reverify pristine behavior
```

**Production-level observability path.** The mutation must ALSO be
observable at the PRODUCTION level, not only in the differential. The
production-level observable is the compiler's diagnostic: with M1
mutated, a control-flow body beginning with an identifier
(`if (x) y = 1;`) is REJECTED by the production binary, and the
production compiler emits the existing diagnostic

```text
Unexpected Identifier `y` while parsing if body
```

(`src/parser.c:951-952`). With the pristine subject, the same input
compiles successfully. The successor MUST capture both outputs.

**Why this mutation is feasible (frozen rationale).** The decision
function is a pure 3-scalar-in / 1-scalar-out function with no
allocation, no side effects and no error path. Any of the six mutation
classes is a one-line edit inside the component body. The component has
no dependency on the Cctrl, no recovery coupling, and no callback
authority, so no mutation can accidentally trip a longjmp or a
diagnostic path inside the component itself.

**At reconnaissance time (C2), the mutation location, the affected
fixtures and the observability path are FROZEN. The PolyC subject is
NOT implemented here.**

---

## RED model summary

```text
RED_1_LEGACY_AUTHORITY_EXISTS=YES
  witness: src/parser.c:832..864 plus 5 live call sites (:950, :961,
  :1254, :1288, :1321)

RED_2_POLYC_AUTHORITY_ABSENT=YES
  witness: grep -rn 'BootstrapValidPostControlFlowToken' src/ tools/
  returns nothing.  The 6 existing PolyC components do not implement this
  decision.

RED_3_PRODUCTION_DELEGATION_ABSENT=YES
  witness: nm build/hcc | grep -c '_BootstrapValidPostControlFlowToken'
  returns 0.  Not a shadow test, not a dead linked object -- the symbol
  does not exist at all.

RED_4_NO_QUALIFIED_SUCCESSOR_PROOF=YES
  witness: the five specific missing proof dimensions are enumerated
  above, each checkable by a concrete command.

RED_5_OBSERVABLE_CAUSAL_SENSITIVITY=YES
  witness: six frozen mutation classes; M1 is the primary class; the
  production-level observable is the existing "while parsing if body"
  diagnostic.

RED_MODEL_COMPLETE=YES
RED_MODEL_REPRODUCIBLE=YES
PRODUCTION_AUTHORITY_LEGACY_C=YES
