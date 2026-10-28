# ACT-POLYC-SELFHOST-PARSER-SLICE07

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-BOUNDARY / PRODUCTION-AUTHORITY-TRANSFER
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main` (no ACT branch is created as ceremony)
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05`
(closed with `ACT-Verdict: PASS`; its evidence tree, HANDOFF and ACT
document are closed evidence under F14 and are NOT modified here)
**Expected ENTRY_HEAD:** `1a3d2d520306f02ca08adb29c62688748e33eab8`
**Expected ENTRY_TREE:** `c33d98783ca73dee676cf2effb8ccb661068b6e2`
**Target:** `SUB-003` -- the compound-block statement append/skip routing
**Successor:** none preselected

---

## 0. Mission

Migrate exactly ONE legacy-C semantic decision -- the one that
determines whether a parsed statement becomes an element of a compound
block's statement list -- from production-authoritative C into
production-authoritative, compiled PolyC.

The predecessor has already migrated SIX parser authorities:

```text
BootstrapCalcPadding                   -> POLYC production authority
BootstrapValidPostControlFlowToken     -> POLYC production authority
BootstrapOperatorPrecedence             -> POLYC production authority
BootstrapAstBinOpFromToken              -> POLYC production authority
BootstrapAstUnaryOpFromToken            -> POLYC production authority
BootstrapSwitchArmTerminates            -> POLYC production authority
```

SLICE07 must migrate exactly ONE more:

```text
the compound-block statement append/skip routing
  -> BootstrapCompoundBlockAppendsStatement
  -> POLYC production authority
```

This ACT does NOT claim whole-parser self-hosting.  It does NOT
implement `parseStatement`, `parseExpr`, `parseCompoundStatement` or
`parseCompoundStatementInternal`, and it does NOT transfer any AST
node, list, allocation, recovery, diagnostic, callback, symbol-table
or token-stream ownership.

### Required final result

```text
COMPOUND_BLOCK_APPEND_AUTHORITY = POLYC
LEGACY_COMPOUND_BLOCK_C_AUTHORITY = RETIRED
SEVENTH_POLYC_PARSER_AUTHORITY = ESTABLISHED
```

### The frozen target

```text
SELECTED_CANDIDATE=SUB-003
SELECTED_CANDIDATE_CLASS=STRUCTURAL_BOUNDARY
SELECTED_ENCLOSING_FUNCTION=parseCompoundStatementInternal
SELECTED_SOURCE_RANGE=src/parser.c:2049..2049
SELECTED_SOURCE_SHA256=378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8
SELECTED_ABI=I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind) -> I64
SELECTED_BOUNDARY_CLASS=SCALAR_TO_SCALAR
```

### The frozen semantic rule

```text
0 exactly for (stmt_kind == AST_DECL && declvar_kind == AST_GVAR)
1 otherwise
```

with `AST_DECL = 263` and `AST_GVAR = 256` re-derived from the LIVE
`src/ast.h` at C0 (not treated as evergreen constants).

---

## 1. The binding predecessor contract

The binding contract is the committed RECON05 `c2/selected-*` set,
read and frozen at C0.  The exact SHA-256 digests of the twenty
read files are in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/selected-contract-hashes.tsv`.

The frozen files are:

```text
c2/selected-id-and-source.tsv
c2/selected-abi.md
c2/selected-production-seam.md
c2/selected-state-and-ownership.tsv
c2/selected-legacy-oracle.md
c2/selected-fixture-contract.tsv
c2/selected-red-contract.md
c2/selected-causal-contract.md
c2/selected-negative-controls.md
c2/selected-provenance-contract.md
c2/selected-conservation-contract.md
c2/selected-out-of-scope.md
```

None of them is edited, renamed or re-interpreted by this ACT.

### 1.1 The conditional activation

RECON05's `c2/successor-authorization.md` records
`PROPOSED_NEXT_ACT_STATUS=INACTIVE_UNTIL_TERMINALITY`.  The four
conditions are verified at C0 in
`c0/successor-activation.txt`; all four hold, and the RECON05
`c4/terminality.txt` external receipt records
`PROPOSED_NEXT_ACT_STATUS=ACTIVE`.

### 1.2 The AC42 predecessor qualification

The predecessor's executed SUB-003 causal experiment REBUILT the
compiler successfully and then observed the MUTANT compiler FAILING TO
COMPILE a witness that the pristine compiler accepted and ran.

The precise witnessed output channel, classified at C0 from the actual
committed `c2/selected-causal-contract.md` and
`c3/causal-mutation-and-restoration.txt`, is:

```text
CHANNEL=COMPILER_ACCEPTANCE_AND_DIAGNOSTIC

---

## 2. The hard semantic invariant

The two-argument ABI does NOT make both host reads unconditional.

C evaluates both call arguments BEFORE invoking a function, so a naive

```c
BootstrapCompoundBlockAppendsStatement(stmt->kind, stmt->declvar->kind);
```

would introduce an invalid host-state read on every non-declaration
statement.  The C side MUST retain exactly ONE projection guard:

```c
I64 projected_stmt_kind = stmt->kind;
I64 projected_declvar_kind = 0;
if (projected_stmt_kind == AST_DECL) {
    projected_declvar_kind = stmt->declvar->kind;
}
I64 append = BootstrapCompoundBlockAppendsStatement(
    projected_stmt_kind, projected_declvar_kind);
```

The C guard authorizes a FIELD READ.  It does not authorize the
append/skip result.  The PolyC function alone computes the decision
from the two scalars, and the C side acts on its return exactly once.

The C projection MAY compare `stmt_kind` against `AST_DECL` to protect
the dereference.  It MUST NOT contain a second comparison against
`AST_GVAR`, a C-computed append/skip boolean, a post-call policy
override, or any arrangement in which the PolyC symbol is linked but
never actually called.

No nullable-pointer handling and no error sentinel may be introduced:
the original source's exceptional behaviour for malformed declarations
is unchanged.

### 2.1 The measured short-circuit, at C0

The live production object already shows the short-circuit structure
that must be preserved (`c0/red-reproduction.txt`):

```text
3a20: b9400008     ldr  w8, [x0]        ; stmt->kind
3a24: 71041d1f     cmp  w8, #263        ; == AST_DECL
3a28: 540000a1     b.ne 0x3a3c         ; SHORT-CIRCUIT: skip the declvar load
3a2c: f9401828     ldr  x8, [x1, #48]   ; stmt->declvar
3a30: b9400108     ldr  w8, [x8]        ; stmt->declvar->kind
3a34: 7104011f     cmp  w8, #256        ; == AST_GVAR
3a38: 54ffed20     b.eq 0x37dc         ; -> SKIP (continue)
```

---

## 3. The authorized scope

Changed files, and ONLY these:

```text
src/parser.c                    bounded SUB-003 projection/delegation only
src/CMakeLists.txt              selector, subject build, link and provenance gating
Makefile                        corresponding existing build/gate wiring
tools/bootstrap/selfhost-parser-slice07.HC     the one new PolyC component
tools/quality/parser-slice07-*.HC                bounded new PolyC verifiers
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE07.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE07.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/**
```

Any production file beyond that list requires a HALT and separate
authorization.  Test-only witnesses live in the new ACT evidence or
in bounded new PolyC quality programs, NOT as edits to the canonical
90-file suite.

Forbidden: a broad refactor, a dependency change, Python, a new
substantial Bash or shell-based oracle, any edit to a closed
predecessor file, branch switching as ceremony, reset/rebase/amend/
force-push, and any production commit pushed before its own gates pass.

Temporary adverse production edits occur in DETACHED DISPOSABLE
WORKTREES and are never merged.

---

---

## 5. The mandatory acceptance contract

Exactly fifty predicates, `AC01`..`AC50`, frozen verbatim at C0 in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/mandatory-ac-contract.tsv`.

At C3, `AC01`..`AC49` may be PASS and `AC50` alone is
`DEFERRED_TO_CLOSE`.  There is no 50/50 PASS before the external C4
terminality check succeeds.

---

## 6. The HALT taxonomy

```text
HALT_ENTRY_IDENTITY
HALT_SUCCESSOR_NOT_ACTIVE
HALT_PREDECESSOR_CONTRACT_MISMATCH
HALT_PREDECESSOR_CAUSAL_CONTRACT_CONFLICT
HALT_CLOSED_ARTIFACT_MUTATED
HALT_SELECTED_SOURCE_MISMATCH
HALT_SEMANTIC_PROJECTION_UNBOUNDED
HALT_EAGER_HOST_DEREFERENCE
HALT_G0_OBJECT_ORACLE_NOT_INDEPENDENT
HALT_FIXTURE_INCOMPLETE
HALT_FROZEN_CONTROL_UNSATISFIED
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_PRODUCTION_AUTHORITY_NOT_POLYC
HALT_PRODUCTION_LEGACY_C_STILL_ACTIVE
HALT_SELECTOR_OR_LINKAGE_FALSE_GREEN
HALT_STAGE_PROVENANCE_NOT_INDEPENDENT
HALT_G0_G3_DIFFERENTIAL
HALT_POLYC_MUTANT_BUILD
HALT_POLYC_CAUSAL_WITNESS
HALT_RESTORATION_NOT_IDENTICAL
HALT_NEW_PARSER_OR_LEXER_FAILURE
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_INVARIANT
HALT_MANDATORY_AC
HALT_TERMINALITY
```

On a HALT: preserve the measured observations, report the exact stage
and the unsatisfied predicate or control ID, leave the closed
predecessors untouched, do NOT choose a second candidate, and request a
separate bounded correction ACT only if an actual proof or
implementation defect warrants it.  An acceptance predicate is NEVER
changed to manufacture a PASS.

---

## 7. The evidence tree

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/
  c0/  entry-identity.txt  predecessor-freeze.tsv  successor-activation.txt
       selected-contract-hashes.tsv  baseline-parser.txt  baseline-lexer.txt
       baseline-lexer07.txt  baseline-cross-target.txt  baseline-gates.txt
       tool-policy.txt  production-authorities.tsv  red-reproduction.txt
       mandatory-ac-contract.tsv  negative-control-contract.tsv
  c1/  legacy-source-and-abi.txt  g0-production-object.txt
       live-ast-enums.tsv  fixture.tsv  fixture-independent-verification.txt
       conditional-projection-evidence.txt  negative-control-red.txt
       stage-provenance-plan.tsv
  c2/  production-source-delta.txt  subject-source-and-symbol.txt
       selector-and-build-rules.txt  production-object-disassembly.txt
       producer-identity.txt  real-linkage.txt  fixture-early-green.txt
       anti-false-green.txt
  c3/  generation-provenance.tsv  g0-g3-full-differential.tsv
       object-and-linkage-audit.txt  fixture-independent-recompute.txt
       inherited-controls-join.tsv  new-controls-join.tsv
       causal-polyc-mutation-restoration.txt  parser-conservation.txt
       lexer-conservation.txt  lexer07-delta.txt  cross-target-delta.txt
       tool-policy.txt  gate-fast.txt  gate-push.txt  factory-invariants.txt
       immutable-predecessor-check.txt  mandatory-ac-status.tsv
  c4/  terminality.txt
```

---

## 8. The final execution directive

Execute C0-C4 as a single bounded implementation ACT, provided the
current real repository verifies the expected entry and the
predecessor's conditional successor authorization is active.  Carry
forward RECON05's immutable selected contract, not its alternative
ranked candidates.  Prioritize the real production migration and
independently executed semantics over documentation polishing.

The required terminal meaning of PASS:

> SUB-003 has ceased to be production-authoritative C; the compiled
> PolyC function now decides whether a statement is appended to a
> compound block; the C host retains safe short-circuit field
> projection and all AST ownership; G0-G3 agree under independent real
> compilers; a real PolyC-source mutant changes compiled production
> compiler behaviour and restores; the six preceding parser authorities
> remain active; conservation and Factory-v2 gates pass with the
> historical failures reported accurately; and the ACT has exactly one
> valid immutable CLOSE.

No other target and no successor selection are authorized here.


## 4. The commit lifecycle

Five forward-only commits on the existing checkout:

```text
C0  RED       exact entry, predecessor hash freeze, baseline, frozen
              acceptance and RED control contracts
C1  EVIDENCE  real object-level legacy oracle, current enums, fixture,
              conditional projection, test and negative-control
              preparations
C2  IMPL      one compiled PolyC component, one production delegation
              and bounded build integration
C3  EVIDENCE  G0-G3 differential, independent provenance, causal PolyC
              mutation, controls, conservation, gates
C4  CLOSE     one HANDOFF, map/roadmap updates, exact close trailers,
              external post-CLOSE terminality
```

Every commit carries the exact ACT ID and the correct Factory-v2 phase
trailer, validated with the repository's own trailer checker BEFORE the
commit is created.  The C0-C3 range is validated before C4.

```

It is NOT an AST/IR output change and NOT a compiled-program runtime
output change, because no mutant executable was produced for the
witness.

The frozen successor contract (`selected-red-contract.md` RED-05)
requires exactly that channel for the mutated direction, so there is
no conflict and `HALT_PREDECESSOR_CAUSAL_CONTRACT_CONFLICT` is NOT
triggered.  Where the C3 mutant rejects compilation, this ACT reports
`COMPILER_ACCEPTANCE_CHANGED` honestly and does NOT claim a runtime
output change.
