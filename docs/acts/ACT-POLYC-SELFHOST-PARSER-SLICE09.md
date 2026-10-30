# ACT-POLYC-SELFHOST-PARSER-SLICE09

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-DISPATCH / PRODUCTION-AUTHORITY-TRANSFER
**Priority:** P0
**Repository:** `s1onique/polyc` -- the user's canonical local checkout;
remote accessibility is not assumed.
**Branch:** existing `main`; no ceremonial ACT branch is created.
**Expected ENTRY_HEAD:** `ba9cb884cebd2eabe17b53d6125849e180758b01`
**Expected ENTRY_TREE:** `8d3974e4156c2058c0627e49356360d9807b267c`
**Binding predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08`,
reported CLOSE / PASS_SELECTED.
**Selected candidate:** `SUB-004` -- the statement-constructor dispatch.
**Prospective successor:** NONE.  No SLICE10 selection or implementation
is authorized.

---

## 0. Mission

Move the production decision of which keyword-specific statement
parser/constructor to invoke out of `src/parser.c` and into ONE pure,
compiled PolyC component, while keeping the actual invocation of the
constructor and ALL mutable parser state on the C side.

The old keyword-to-constructor decision remains available SOLELY in an
explicitly selector-OFF C-only oracle/fallback.  Under the production ON
build it is compiled out of the active decision path.

### Required final result

```text
PRODUCTION_STATEMENT_DISPATCH_AUTHORITY           = POLYC
LEGACY_C_KEYWORD_DISPATCH_AUTHORITY_RETIRED       = YES
POLYC_PARSER_AUTHORITIES                          = 9 (8 predecessors preserved)
```

This does NOT claim whole-parser or whole-compiler self-hosting.

### The frozen target

```text
CANDIDATE   = SUB-004
DECISION    = STATEMENT_DISPATCH
SOURCE      = src/parser.c:1864..1877
SHA256      = cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0
FUNCTION    = parseStatement
ABI         = I64 BootstrapStatementDispatch(I64 token_type, I64 keyword_id) -> I64 statement_selector
SUBJECT     = tools/bootstrap/selfhost-parser-statement-dispatch.HC
SELECTOR    = HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH  (default OFF; production ON)
ORACLE      = ParserLegacyStatementDispatchOracle
```

### Binding hierarchy

```text
Actual Git objects and executed observations
  > frozen RECON08 c2/selected-* contracts
  > this ACT
  > HANDOFF/digest narrative
```

RECON08's range digest omitted the raw bodies of its selected contracts.
The executor opened and validated those committed bytes at C0; their
content hashes are frozen in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/c0/predecessor-close-and-selected-contract-hashes.tsv`.

### Explicit non-goals

Do NOT migrate all of `parseStatement`, `parseExpr`,
`parseCompoundStatementInternal`, AST ownership, allocations, symbol
table lookup, token cursor, diagnostics, scope mapping, callback tables
or recovery.  Do NOT touch `SUB-005`, any scalar candidate, other
dispatch sites, the runtime ABI, code generation, LLVM/JIT, or the
historical RECON06 / SLICE08 evidence.  Do NOT turn an engineering
migration ACT into a new candidate-selection ACT.

---

## 1. C0 -- entry qualification and binding source contracts

Executed and recorded in `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/c0/`.

| File | Content |
|---|---|
| `entry-identity.txt` | exact HEAD/TREE/branch/clean index/zero replace refs |
| `predecessor-close-and-selected-contract-hashes.tsv` | the five-commit RECON08 range and the seven frozen selected-contract hashes |
| `historical-f14-path-freeze.tsv` | 575 frozen predecessor paths, verified by two independent methods |
| `selected-contract-bindings.tsv` | the SUB-004 source identity, the complete keyword mapping, the selector encoding, the ABI, the projection, the fixture, the causal controls |
| `frozen-50-ac-contract.tsv` | AC01..AC50, frozen before implementation |
| `frozen-18-owned-controls.tsv` | S9-FC-01..S9-XC-02, frozen before implementation |
| `frozen-inherited-controls.tsv` | the 24 inherited R8-* controls plus the four surviving SUB-004 controls, with their SLICE09 classification |
| `baseline-parser-lexer-policy.txt` | the parser/lexer/cross-target baseline and the eleven known debts |
| `baseline-gates-and-policies.txt` | F-NO-PYTHON, F-POLYC-TOOLS, gate-fast, gate-push, the range checker, the append-only suite |
| `eight-authority-object-proof.tsv` | the eight predecessor authorities at the object/link level |
| `five-red-reproduction.txt` | the five executed REDs, plus one extra, with two detector gaps recorded |

### The subject-file binding

This ACT's section 2.1 lists `tools/bootstrap/selfhost-parser-slice09.HC`
as the permitted path and says: "Filename of subject must agree with
committed selected contract or bind exact permitted equivalent at C0."

The committed selected contract names
`tools/bootstrap/selfhost-parser-statement-dispatch.HC`.  The frozen
contract is the higher authority in this ACT's own binding hierarchy,
so the FROZEN name is bound as the exact permitted equivalent at C0.
The binding is recorded in `c0/selected-contract-bindings.tsv`.

### The selector encoding

The frozen contract fixes the ABI (two `I64` in, one `I64` out, total,
no failure sentinel) and the SEMANTICS (which keyword selects which
constructor; a non-dispatch keyword selects the not-a-keyword-statement
selector).  It does NOT assign numeric codes.  This ACT DERIVES a dense
encoding from the SOURCE ORDER of the `case` labels and FREEZES it at
C0, without changing the frozen semantic contract:

```text
STMT_NOT_A_KEYWORD_STATEMENT = 0
STMT_IF = 1 .. STMT_GOTO = 15      (in source order of the `case` labels)
```

### The dispatch extent

The frozen range `1864..1877` ends at the `KW_CONTINUE` arm.  The same
`switch` statement continues with `KW_ASM` (1878), `KW_STATIC` (1893),
`KW_GOTO` (1955) and a `default:` arm (1967).  All of them are INSIDE
the same `if (tok->tk_type == TK_KEYWORD)` guard and are part of the
same decision, so the mechanical C routing table must reproduce the
ENTIRE legacy decision or the migration would change behaviour.  They
are therefore included, with their real routes.

---

## 2. Scope

### Permitted tracked paths

```text
src/parser.c                                  # only the SUB-004 seam and the adjacent C-only oracle
src/CMakeLists.txt                            # subject option/build/link wiring only
Makefile                                      # subject producer, exact prerequisite and gate hooks only
tools/bootstrap/selfhost-parser-statement-dispatch.HC   # the one selected pure PolyC component
tools/quality/parser-slice09-*.HC             # bounded substantive PolyC verification tools
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE09.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE09.md
docs/factory/act-handoff-map.tsv              # exactly one additive mapping
docs/ROADMAP.md                               # bounded additive outcome
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/**
```

`tools/quality/parser-slice09-reloc-scope.sh` is a bootstrap-glue
wrapper (16 LOC, well under the 50-LOC shell limit) that joins a
sorted symbol table's function range with a relocation table by
address.  It implements NO domain rule; the detection decisions are
made by the PolyC quality tools.

No changes outside the above without stopping for separate
authorization.  In particular NO changes to other `src/**`, existing
`tools/bootstrap/**` components, existing quality tools, tests, the
canonical eligibility/ranking tools, the gates, `.githooks`, the
runtime headers/ABI, dependencies, or any closed ACT/HANDOFF/evidence.

No Python.  No new third-party dependency.  No broad Bash orchestration.
No unrelated formatting.  No new ACT branch as ceremony.  No amends,
resets, rebases, force pushes or edits to immutable history.

---

## 3. Phases

```text
C0  RED       entry qualification, frozen contracts, baselines, five REDs
C1  EVIDENCE  genuine C oracle, full dispatch coverage, build plan
C2  IMPL      one PolyC authority and one C mechanical routing seam
C3  EVIDENCE  independent stage proof, causality and conservation
C4  CLOSE     HANDOFF, manifest, additive ROADMAP, external terminality
```

Exactly five forward commits, in that order, with the canonical
Factory-v2 trailers.

---

## 4. Acceptance criteria

The fifty criteria AC01..AC50 are frozen verbatim at C0 in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/c0/frozen-50-ac-contract.tsv`
and are joined by exact ID at C3 and C4.

AC50 is DEFERRED until the external read-only post-CLOSE terminality
probe has genuinely run.

---

## 5. Negative controls

Eighteen SLICE09-owned controls S9-*, frozen verbatim at C0 in
`c0/frozen-18-owned-controls.tsv`, plus the 24 inherited RECON08
controls in `c0/frozen-inherited-controls.tsv` with their SLICE09
classification.

The inherited R8-* controls are HISTORICAL_RECON08_PROOF_TO_VERIFY
except `R8-CC-01`, which is PROHIBITED_SUBSTITUTION for the post-PolyC
mutation.  The RECON08 pre-migration C mutant CANNOT discharge
`RECON08-SUB-004-POST-POLYC-MUTANT`.

---

## 6. HALT reasons

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_NOT_VERIFIED
HALT_FROZEN_HISTORY_INCONSISTENT
HALT_SELECTED_CONTRACT_MISSING_OR_CONTRADICTORY
HALT_SOURCE_RANGE_OR_SEMANTIC_ANCHOR_MISMATCH
HALT_OLD_C_DISPATCH_ORACLE_NOT_GENUINE
HALT_DISPATCH_FIXTURE_OR_ENUM_UNBOUND
HALT_PROJECTION_OR_OWNERSHIP_UNBOUNDED
HALT_SELECTOR_ENCODING_UNSPECIFIED
HALT_BUILD_GRAPH_OR_SUBJECT_PROVIDER
HALT_DUPLICATE_C_PRODUCTION_AUTHORITY
HALT_PRODUCTION_OBJECT_NOT_LOAD_BEARING
HALT_G0_G1_G2_G3_PROVENANCE
HALT_GENERATION_DIFFERENTIAL_MISMATCH
HALT_POST_POLYC_MUTATION_WRONG_SUBJECT
HALT_MUTANT_PRODUCTION_BUILD_FAILED
HALT_CAUSAL_WITNESS_UNPROVEN
HALT_MUTATION_RESTORATION_FAILED
HALT_CONTROL_ID_OR_EXECUTION_GAP
HALT_NEW_PARSER_OR_LEXER_FAILURE_IDENTITY
HALT_EIGHT_AUTHORITY_REGRESSION
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_V2_F14_APPEND_ONLY
HALT_MANDATORY_AC_UNPROVEN
HALT_TERMINALITY
```

Known separate debts, NOT to be repaired here: the 15 historical
LEXER07 failure IDs, the 67 cross-target prefix cases, the 12
F-NO-PYTHON violations, the unavailable F-POLYC-TOOLS checker, the
SLICE06 stale CMake producer, the shared assembly temporary-file race,
the initialized static global / `Main(argc)` storage collision, the
pointer-valued ternary OOM lead, the canonical checker's source-hash
omission, the canonical ranker trusting its eligibility column, and the
historical SLICE08 self-referential control rows.

---

## 7. Authorization statement

This document authorizes only the bounded `SUB-004` implementation and
its independently verified Factory-v2 lifecycle, conditioned on exact
entry and frozen successor contract validation.  It does NOT authorize
the migration of any other semantic authority, the rewriting of a
historical CLOSE or HALT, any change to core compiler architecture, or
the selection of SLICE10.

On an evidence gap: HALT honestly.  On PASS: produce an active ninth
PolyC parser decision site, not a claim of entire compiler self-hosting.
