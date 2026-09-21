# ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
ACT-Phase: RED

**Title:** Transfer production `CalcPadding` authority from legacy C to
qualified PolyC `BootstrapCalcPadding`

**Class:** SELFHOST / PRODUCTION-AUTHORITY-MIGRATION

**Repository:** PolyC

**Branch:** `main`

**Entry HEAD:** `9c6cda6c2a5daa8a52c58baaf66f0f61bf160800`

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION04`

**Predecessor committed verdict:** `PASS_FORWARD_BASELINE_GOVERNANCE_REQUALIFIED`
(effective, promoted by external terminality gate)

**Target surface:** parser padding

**Legacy authority:** `src/parser.c::CalcPadding`

**Qualified PolyC subject:** `tools/bootstrap/selfhost-parser-padding.HC::BootstrapCalcPadding`

**Transition:**

```text
LEGACY_C
   ↓
POLYC_PRODUCTION_AUTHORITY
```

**Baseline authority:** `docs/factory/LEXER07-BASELINE-AUTHORITY.tsv`

**Mission:** real compiler-semantic migration.

---

## 1. Executive mission

Transfer production parser-padding semantics from the legacy C
implementation `CalcPadding(offset, size)` to the already-qualified
PolyC implementation `BootstrapCalcPadding(offset, size)` without
changing padding semantics.

At successful close:

```text
PARSER_PADDING_PRODUCTION_AUTHORITY = POLYC
LEGACY_CALC_PADDING_AUTHORITY        = RETIRED
BootstrapCalcPadding                 = LOAD_BEARING_IN_PRODUCTION
```

The ACT must prove that the production compiler actually consumes the
PolyC result. A source reference or linked symbol is not sufficient. A
causal production mutation must alter observable parser/layout behavior.

---

## 2. Why this ACT is now authorized

Prior work established:

```text
BootstrapCalcPadding implementation         = GREEN
independent algebraic verification          = GREEN
bounded differential                         = GREEN
mutation controls                            = GREEN
4-generation component fixed point          = GREEN
generation provenance                       = GREEN
legacy oracle authority                     = GREEN
forward LEXER07 baseline                     = SHA-BOUND
parser-padding production authority          = LEGACY_C
```

The remaining missing step is not another component proof.
It is: production delegation.

---

## 3. Core invariant

The migration must preserve the legacy semantic function:

```text
padding(offset, size) =
    0                         if size == 0
    0                         if offset % size == 0
    size - (offset % size)    otherwise
```

```text
CALC_PADDING_SEMANTIC_DELTA = 0
```

---

## 4. Production-authority definition

`POLYC_PRODUCTION_AUTHORITY=YES` requires ALL of:

1. production parser/layout code obtains padding from `BootstrapCalcPadding`;
2. the legacy C `CalcPadding` algorithm is not independently used on the
   migrated production path;
3. changing `BootstrapCalcPadding` in a temporary causal-control build
   changes production-observable behavior;
4. restoring the pristine subject restores production behavior;
5. stage1+ compiler generations exercise the PolyC authority;
6. no silent C fallback exists on the migrated path.

Merely calling PolyC as a shadow verifier does not qualify.

---

## 5. Non-goals

This ACT MUST NOT change `BootstrapCalcPadding` semantics; redesign
class/union layout; migrate `CalcClassSize`, `CalcUnionSize`,
`parseCompoundStatementInternal`; alter parser recovery, lexer semantics,
or the LEXER07 baseline; repair historical Factory ACTs; introduce
Python; or implement unrelated parser primitives.

---

## 6. Production scope

Expected semantic source changes: `src/parser.c`. Plus minimum
bridge/header/build plumbing required to make `BootstrapCalcPadding`
callable from the production parser.

Potential support surfaces (only if mechanically required):
`src/parser_bridge.h` (may be created or existing reused), `Makefile`,
`src/CMakeLists.txt`, existing parser bootstrap integration surface.

C1 discovers the actual current pattern before C2 chooses exact files.
No speculative bridge file may be created if an existing ABI mechanism
already handles this call.

---

## 7. Qualified subject freeze

At C0 the SHA-256 of:

* `tools/bootstrap/selfhost-parser-padding.HC` (subject)
* `tools/quality/parser-padding-algebraic-invariants.HC`
* `tools/quality/parser-padding-generation-provenance-verify.HC`
* `tools/quality/parser-padding-oracle-impl.c`

MUST remain byte-identical throughout this ACT.

Required at C3: `BOOTSTRAP_CALC_PADDING_SOURCE_DELTA = 0`.

If C2 appears to require changing the subject:

```text
HALT_SUBJECT_NOT_QUALIFIED_FOR_DELEGATION
```

---

## 8-9. Entry gate / authority check

See `evidence/.../c0/c0-entry-identity.txt`,
`c0-predecessor-binding.txt`, `c0-production-authority.txt`.

---

## 10-11. C0 artifacts and commit

See `evidence/.../c0/`. Commit trailer:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01 C0: AUTH
```

No implementation work in C0.

---

## 12-30. C1 RED and delegation recon

C1 enumerates every CalcPadding call/reference, records the legacy
function shape, classifies every call site, and freezes RED witnesses:

* RED-1 — PolyC is not production-authoritative at entry
* RED-2 — production causal mutation absent before migration
* RED-3 — delegation absent

C1 also freezes:

* `c1-production-fixture-contract.tsv`
* `c1-production-output-schema.txt`
* `c1-generation-contract.tsv`
* `c1-negative-control-contract.txt`

C1 commit trailer:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01 C1: RED/CONTRACT
```

---

## 31-39. C2 IMPL — production delegation

C2 performs the actual authority transfer. Allowed semantic operation:

```text
production padding calculation
    legacy CalcPadding body
→
    BootstrapCalcPadding
```

Nothing else.

**Implementation rule (ACT §32):** after C2, the default
selfhost/current production path MUST call the qualified PolyC
function. The stage0 evidence path may retain legacy semantics behind
an explicit qualification seam. No automatic fallback.

**No silent fallback (ACT §33).** Forbidden patterns include
"if BootstrapCalcPadding fails use legacy", "if symbol missing use C",
"dual calculate and choose legacy result", "shadow calculate without
consuming PolyC result".

**Legacy function disposition (ACT §34):** choose one of:
* D-A — delegating compatibility wrapper
* D-B — direct-call replacement
* D-C — existing stage-selection seam (`HCC_USE_SELFHOST_COMPONENTS`)

**ABI rule (ACT §35):** the production ABI uses the already-qualified
scalar contract `I64 offset, I64 size -> I64 padding`. No new state
crosses the ABI.

**Build integration (ACT §36):** add only the minimum linker/build
dependency necessary so every relevant production generation resolves
`BootstrapCalcPadding`.

**Local GREEN (ACT §37):** before committing C2, run direct
parser-padding differential, independent algebraic verifier, existing
parser-padding mutation verifier, component fixed-point verifier,
parser layout tests. Required: `C2_LOCAL_REGRESSION_COUNT=0`.

**Subject freeze check (ACT §38):** before C2 commit,
`BootstrapCalcPadding` source SHA MUST equal C0 SHA.

C2 commit trailer:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01 C2: IMPL
```

---

## 40-70. C3 VERIFY — evidence only

C3 establishes:

* semantics preserved (direct differential, algebraic invariants,
  component fixed-point)
* PolyC is load-bearing (N01 production-causal mutation)
* legacy authority retired (`LEGACY_SEMANTIC_AUTHORITY_COUNT=0`)
* all generations independently exercise the path
* no baseline regression introduced (LEXER01..LEXER04, LEXER07,
  parser layout, parser general)
* F-POLYC-TOOLS, F-NO-PYTHON, F14, patch hygiene, gate-fast,
  append-only

C3 commit trailer:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01 C3: VERIFY
```

No implementation mutation after C3 commit.
No implementation mutation after C3 commit.

---

## 71-77. C4 CLOSE

C4 commits only closure artifacts (HANDOFF, C4 evidence,
`docs/factory/act-handoff-map.tsv`, ROADMAP append if required). No
production source. No C3 evidence rewrite.

C4 commit trailer + committed verdict:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01 C4: CLOSE
PASS_PENDING_EXTERNAL_TERMINALITY
```

External terminality observation (§74) promotes to effective verdict
`PASS_TRUE_GREEN` or `HALT_EXTERNAL_TERMINALITY_GATE`.

---

## 78. Successor recon

After successful external closure:

```text
NEXT = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

Mission: re-inventory parser semantic authority, re-rank smaller
low-coupling slices, measure leverage change after CalcPadding
migration. Do not automatically return to
`parseCompoundStatementInternal`.

---

## 79. Board effect

Before:

```text
LEXER selfhosting                    = mature through LEXER04
PARSER.COMPOUND                     = deferred / dependency explosion
BootstrapCalcPadding component      = qualified
CalcPadding production authority    = LEGACY_C
PADDING-DELEGATE01                  = active
```

After successful external closure:

```text
BootstrapCalcPadding component      = TRUE_GREEN
CalcPadding production authority    = POLYC
PARSER_PADDING_SELFHOST_COMPLETE    = YES

FIRST_PARSER_PRODUCTION_SLICE       = MIGRATED

NEXT                                = PARSER-SLICE-RECON02
```

---

## 80. Halt taxonomy

Valid halts include:

```text
HALT_PREDECESSOR_NOT_TERMINAL
HALT_SUBJECT_NOT_QUALIFIED_FOR_DELEGATION
HALT_RED_NOT_REPRODUCED
HALT_DELEGATION_DESIGN_AMBIGUOUS
HALT_UNCLASSIFIED_CALL_SITE
HALT_PRODUCTION_SEMANTIC_REGRESSION
HALT_POLYC_NOT_LOAD_BEARING
HALT_N01_BUILD_FAILED
HALT_N01_LINK_FAILED
HALT_N01_RUN_FAILED
HALT_N01_NO_SEMANTIC_DIVERGENCE
HALT_N01_WITNESS_INCOMPLETE
HALT_GENERATION_NOT_INDEPENDENT
HALT_GENERATION_COPY_NOT_DETECTED
HALT_PARSER_LAYOUT_REGRESSION
HALT_PARSER_REGRESSION
HALT_LEXER_CONSERVATION
HALT_LEXER07_FORWARD_BASELINE_REGRESSION
HALT_COMPONENT_FIXEDPOINT_REGRESSION
HALT_F_POLYC_TOOLS
HALT_F_NO_PYTHON
HALT_F14
HALT_PATCH_HYGIENE
HALT_FACTORY_GATE
HALT_C2_DEFECT_FOUND_DURING_C3
HALT_MANDATORY_AC_NOT_GREEN
HALT_EXTERNAL_TERMINALITY_GATE
```

A HALT is preferable to weakening a frozen predicate.

---

## 81. Required final external result

See `evidence/.../c3/c3-required-result.txt` for the complete token list
required before C4.

---

## 82. Final instruction

This is not another qualification ACT. The PolyC padding function is
already qualified. Make production use it. Keep the change atomic.
Prove it is load-bearing. Prove it behaves identically to the legacy
implementation. Prove all independently built generations exercise it.
Retire the legacy semantic authority. Then stop. Do not fix unrelated
parser surfaces. Do not revisit baseline governance. Do not add a sixth
commit to polish the close.

After successful closure, recon the parser again and select the next
actual self-hosting slice mechanically.

