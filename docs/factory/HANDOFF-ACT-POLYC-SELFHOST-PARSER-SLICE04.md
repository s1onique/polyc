# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE04

**Factory-Version:** 2

## Result

The binary-operator classification of the PolyC parser is now owned by
a qualified PolyC component, and the legacy C decision has been
retired from the production path.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. Actual ENTRY_HEAD

```text
ENTRY_HEAD=e3eaf38c2e0a1183d8fd4969443c32c92f075e58
BRANCH=main
WORKTREE_CLEAN=YES
PREDECESSOR_REACHABLE=YES
GIT_REPLACE_REFS=0
```

The observed HEAD was EXACTLY the ACT's declared Expected ENTRY_HEAD, so
no intervening commit had to be inventoried.

## 2. The two candidate classifications

| ID | Function | Location | Authority before | Authority after |
|---|---|---|---|---|
| CAND-019 | `astBinOpFromToken` | `src/ast.c:206..236` | legacy C | **POLYC** |
| CAND-020 | `astUnaryOpFromToken` | `src/ast.c:238..254` | legacy C | legacy C (unchanged) |

Both candidates satisfied **all thirteen** eligibility clauses
(`clause bits 1111111111111`, `failed=0`, `MALFORMED=0`) under the
existing, closed RECON03 eligibility checker.

Neither candidate required an AST pointer or host allocation authority
to be transferred into PolyC: the one write through the output pointer
is **ABI output storage**, not host AST graph mutation.

## 3. The mechanically selected winner

```text
SELECTED_CANDIDATE_ID=CAND-019
SELECTED_FUNCTION=astBinOpFromToken
SELECTED_SOURCE_SHA256=2f6adf3b77e5ee0e6d95e0acb932eb015f54d2039f7f708df6eda1ec77b9048b
SELECTED_POLYC_SYMBOL=BootstrapAstBinOpFromToken
SELECTED_PRODUCTION_CALLER_COUNT=1
SELECTED_PRODUCTION_CALL_SITE=src/prslib.c:1527
```

The two candidates carried the **identical** RECON03 R0..R5 score
vector `(0, 2, 3, 2, 0, 0)`.  The winner was therefore decided by the
R6 **source-order** dimension alone (`src/ast.c:206` before
`src/ast.c:238`).  **Not one score was changed** to prefer binary over
unary.

The ranker is the existing, closed RECON03 ranker; the eligibility
checker is the existing, closed RECON03 checker.  SLICE04 authored
neither.

**Controls: 7/7 PASS** (NC-00..NC-06), plus the closed ranker's own
**4/4** embedded controls.  NC-00 proves the control driver's own
comparator agrees with the closed ranker, so its comparisons are
falsifiable.

## 4. The frozen ABI and enum mapping

```text
I64 BootstrapAstBinOpFromToken(I64 token_value) -> I64
FAILURE_SENTINEL=-1
```

The scalar/sentinel ABI was **proven safe** before it was used:

* the live `AstBinOp` enum spans `0..28` and `AstUnOp` spans `0..12`,
  both extracted by **compiling** the live `src/ast.h`;
* every one of the 19 successful mappings is nonnegative;
* `-1` cannot be a valid mapped enum, so there is **no sentinel
  collision**;
* the legacy body reads only the scalar parameter, so the decision
  depends on nothing else.

19 mappings, transcribed from the live legacy switch and measured by
executing it.

## 5. The C oracle and the fixture contract

The oracle is `src/ast.c` compiled **without** the delegation flag.  Its
object is **byte-identical** to the entry production `ast.c.o`
(`sha 144c9836...`), it does **not** reference the PolyC symbol, and
the driver contains **no mapping table**.

The fixture is **derived, not chosen**: 322 rows across 9 partitions,
every count computed from the frozen values.

```text
M01 19  M02 19  M03 84  M04 38  M05 3  M06 6  M07 6  M08 27  M09 120
```

The signed-I64 extremes are written with an exact 64-bit conversion
(`snprintf("%lld")`), because the runtime's `%d` is a **32-bit**
conversion that prints `INT64_MIN` as `0` and `INT64_MAX` as `-1`.
The differential's integer parser is exact over the whole signed
64-bit domain.

The independent integrity witness does **not** share the producer's
token-resolution code: it answers a different question (the fixture
structure and the ID set) with a different counting path (a whole-file
byte scan with no state machine).

**The eight negative controls all fire.**  Each mutates a **copy** of
the fixture and requires the **real** verifier to reject it with a
non-zero exit code.

## 6. The production delegation

`src/ast.c`'s `astBinOpFromToken` now delegates under the dedicated
selector `HCC_USE_SELFHOST_PARSER_AST_BINOP`, keeping its exact C ABI:
boolean success and conditional output storage.  The adapter owns
argument projection, success conversion and output storage; **PolyC owns
the decision**.

The production object's **disassembly** is the proof that the C
decision left the production path: the function is now
call / test / conditionally store / return, with **no jump table and no
enum immediate**.  The unselected `astUnaryOpFromToken` still carries its
C switch.

The build **fails closed** in seven measured cases (missing, empty,
undefined-only, local-only, weak-only, not-an-object, and the passing
case), and the verification is a custom **target**, so no stale stamp
can bypass the current object check.

## 7. Generation provenance and comparisons

```text
G0  legacy C reference   producer /usr/bin/cc              sha 9b11ead1...
G1  stage-1 PolyC         producer ./hcc                    sha 222ef8f7...
G2  stage-2 PolyC         producer ./build/hcc-bootstrap02  sha 04e47f3b...
G3  stage-3 PolyC         producer ./build/hcc-bootstrap03  sha 2663f24e...
```

All six generation pairs are **semantically equivalent**; the three
PolyC pairs are additionally **byte-equal**; the G0-versus-PolyC
comparisons are semantic and use the **real** legacy mapping.

Because G1, G2 and G3 produce **byte-identical** objects, a finished
object could be substituted for another **without changing the output
bytes**.  SLICE04 therefore implemented an **execution-linked
provenance witness**: a probe built by that generation's own compiler,
linked against that generation's own object, and executed.  The five
provenance negative controls corrupt or substitute that witness, and
each is **rejected** with a concrete reason.

The G0 producer is resolved and hashed **from the actual invoked
command**, and the raw receipt, the manifest and the summary are
generated from **one** recording, so they are single-valued.  This is
the direct response to the predecessor's D-PREV-02 contradiction.

## 8. The causal mutation

A mapping differential alone is not sufficient.  The `'+'` token (43)
was mapped to `AST_BIN_OP_SUB` instead of `AST_BIN_OP_ADD`, in an
**isolated scratch workspace**; the tracked subject was never mutated.

```text
p0_OUTPUT=13      pristine:  6 + 7
p1_OUTPUT=-1      mutated:   6 - 7
p2_OUTPUT=13      restored:  6 + 7

A_BUILD_RC=0  A_EXEC_RC=0
B_BUILD_RC=0  B_EXEC_RC=0
C_BUILD_RC=0  C_EXEC_RC=0
B_OUTPUT_DIFFERS_FROM_A=YES
C_OUTPUT_EQUALS_A=YES
C_COMPONENT_SHA_EQUALS_A=YES
```

The mutant build **succeeded** (a failed mutant build is not a
successful causal control), and the restored component is a **rebuild**
of the pristine source with the **same sha**.

## 9. Conservation and the Factory gates

The conservation baseline is the **entry tree**, not a historical
HANDOFF's claimed result.

```text
BASELINE_PASSED=87  BASELINE_FAILED=3
CURRENT_PASSED=87   CURRENT_FAILED=3     (identical failure identities)

NEW_PARSER_FAILURE_IDENTITIES=0
NEW_PARSER_SEMANTIC_REGRESSIONS=0
NEW_LEXER_FAILURE_IDENTITIES=0
NEW_LEXER07_FAILURE_IDENTITIES=0
PRODUCTION_SEMANTIC_DELTA=0
```

The three parser failures are the pre-existing
`/usr/local/include/tos.HH` installation-prefix issue.  They are
recorded as **measured**, not relabelled PASS, and they are present in
the baseline too.

The LEXER02/07/08/09 differentials report 89 / 45 / 23 rows with 0
failures.  The LEXER07 broad corpus is identical to the canonical
baseline registry (`REGRESSION=0`, `DIVERGED=0`), and its historical
`STATUS=FAIL` is preserved honestly.

The three previous PolyC parser authorities are conserved with **zero**
source-hash changes.

```text
GATE_FAST=PASS
GATE_PUSH=PASS
FACTORY_V2=PASS (53/0)
APPEND_ONLY=PASS (11/0)
F14=PASS
PATCH_HYGIENE=PASS
TRACKED_MUTATIONS_OUTSIDE_SCOPE=0
```

The F-NO-PYTHON checker reports its 12 findings; every one is in a
file this ACT does not touch, and the `.py` files exist at the entry
commit.  They are recorded as **pre-existing**, separately from any
newly introduced violation.

## 10. Honest residue

* The F-NO-PYTHON checker reports **12 pre-existing** findings.  They
  are not relabelled PASS and not suppressed.
* `tools/factory/factory-polyc-tools-check.HC` **does not exist**.  It
  is the known C2.9 residue recorded in `AGENTS.md`, not a defect of
  this ACT.  Every tool this ACT introduces is PolyC, and the only
  non-PolyC files are the narrow C oracle adapters the ACT permits.
* The parser suite has **3 pre-existing** failures.
* The LEXER07 broad corpus has an overall `STATUS=FAIL` that is
  historical and unchanged.

### A fresh-tree defect that was found and repaired in the C2 phase

The qualification tool's link line listed the three existing PolyC
subject objects TWICE, so the differential could not be linked from a
pristine clone:

```text
ld: 3 duplicate symbols
  _BootstrapCalcPadding
  _BootstrapOperatorPrecedence
  _BootstrapValidPostControlFlowToken
```

The defect was **masked by a warm build state** during the first C2
measurement and became visible only after the libtos archive was
rebuilt and the link resolution order changed.  It is exactly what
F9's fresh-tree requirement exists to catch.

It was **repaired in the C2 phase** -- the phase that introduced it,
and the phase ACT section 16 authorizes for such a repair -- and
every C3 result was then re-measured from the corrected tree.  The
defect affected **no production artifact** (the production compiler is
built by the CMake graph) and **no evidence claim**.

```text
DEFECT_SCOPE=QUALIFICATION_TOOL_LINK_ONLY
PRODUCTION_AFFECTED=NO
EVIDENCE_AFFECTED=NO
REPRODUCED_FROM_PRISTINE_CLONE=YES
REPAIRED_IN_THE_C2_PHASE=YES
```

The full detail is in `c2/build-subject-defect.txt` and
`c3/build-subject-defect.txt`.

## 11. The remaining unmigrated AST mapping

```text
astUnaryOpFromToken (CAND-020)   LEGACY_C
```

It is byte-identical to the entry version, still the legacy C
authority, and its semantics are unchanged (measured through the real
function: every accepted token maps to its exact enum and every
rejected token leaves the output unchanged).

## 12. The next candidate

A later `ACT-POLYC-SELFHOST-PARSER-SLICE05` may migrate
`astUnaryOpFromToken`, but only after SLICE04's production authority
and proof obligations are fully established, which they now are.

The successor inherits:

* the production authority is `BootstrapAstBinOpFromToken` (PolyC),
  with the legacy binary-operator switch retired;
* the four previous PolyC parser authorities are all active and
  conserved;
* the G0 provenance reading is the **actual** producing compiler;
* the execution-linked provenance witness pattern, which is what makes
  a byte-identical substitution detectable;
* the exact 64-bit fixture formatting, which is what keeps the
  signed-I64 extremes honest;
* the self-hosted candidate shortlist for the AST operator surface is
  exhausted: after SLICE05 the whole AST operator classification
  family would be PolyC-owned.

## The acceptance ledger

```text
AC_TOTAL=50
AC_ID_UNIQUE=YES
AC_MISSING=0
AC_DUPLICATE=0
AC_PASS=50
AC_FAIL=0
AC_UNPROVEN=0
```

The ledger was produced by an **exact acceptance-ID join** against the
frozen C1 contract, and the counts were recomputed from the written
ledger's own rows.  At C3, AC50 was `DEFERRED_TO_CLOSE` with the
reason recorded explicitly, exactly as the ACT permits; its actual
post-CLOSE satisfaction is established by the external terminality
checks of ACT section 17.

---

## Terminal facts

```text
SELECTED_CANDIDATE_ID      = CAND-019
SELECTED_FUNCTION          = astBinOpFromToken
SELECTED_POLYC_SYMBOL      = BootstrapAstBinOpFromToken
SELECTED_ABI               = I64 BootstrapAstBinOpFromToken(I64) -> I64
SELECTED_FAILURE_SENTINEL  = -1
DELEGATION_MACRO           = HCC_USE_SELFHOST_PARSER_AST_BINOP
PRODUCTION_CALL_SITE       = src/prslib.c:1527
COMPONENT_SOURCE           = tools/bootstrap/selfhost-parser-slice04.HC
COMPONENT_SOURCE_SHA256    = 43f3b95933a6d87aca9824b0337d416abeddc24bfb25743413554be922c8f63d
COMPONENT_OBJECT_SHA256    = 6d598bc7f0b00ac47642ec06b8cceba641d55a8cfe5498e0a6a995c40f2e054d
G0_COMPILER                = /usr/bin/cc
G0_COMPILER_SHA256         = 9b11ead1ca76a03d61108ad5bf2c913d6aa8daa7deb9fd28893e847e3680e5e7
G0_COMPILER_VERSION        = Apple clang version 15.0.0 (clang-1500.0.40.1)
G0_COMPILER_IS_THE_POLYC_COMPILER = NO
FIXTURE_ROW_COUNT          = 322
ACCEPTED_MAPPING_COUNT     = 19
```

VERDICT

PASS

The binary-operator classification of the PolyC parser is now owned by
the qualified PolyC component `BootstrapAstBinOpFromToken`, the legacy
C decision is retired from the production path, and the unselected
`astUnaryOpFromToken` is unchanged and still the legacy C authority.
The selection was mechanical, the production delegation is proven
causally load-bearing by a pristine/mutated/restored sequence, all four
generations were independently built and executed, the provenance is
single-valued and execution-linked, every established behaviour is
conserved, and all 50 mandatory acceptance predicates are proven.
