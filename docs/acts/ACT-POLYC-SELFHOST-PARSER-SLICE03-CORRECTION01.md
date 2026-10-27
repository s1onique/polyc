# ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT

**Title:** Restore the qualification authority of SLICE03 without undoing
or modifying the production migration

**Repository:** `s1onique/polyc`
**Branch:** `main`

**Class:** SELFHOST / PARSER / QUALIFICATION-CORRECTION

**Priority:** P0

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE03`
(closed with `ACT-Verdict: PASS` on its CLOSE commit; its evidence tree
and HANDOFF are closed evidence under F14 and are NOT modified here)

**Entry reference:** `3dd44a6b66746394ae9852cb57e951c2389abf5f`

---

## 0. Mission

Restore the qualification authority of SLICE03 without undoing or
modifying the production migration.

**Preserve:**

- `BootstrapOperatorPrecedence` remains production authority.
- The legacy precedence algorithm remains retired from the production path.
- The existing two parser components remain production authorities.
- All previously closed ACT, HANDOFF, and evidence surfaces remain
  immutable.

**Repair:** fixture semantic coverage, independent qualification, G0
provenance, and successor-facing governance.

---

## 1. Binding historical findings

The following are **confirmed historical defects** of the predecessor's
QUALIFICATION SURFACE.  They are **not** newly discovered production
compiler regressions.  The production migration performed by SLICE03 is
sound and is **not** undone by this ACT.

| ID | Finding |
|---|---|
| D1 | P16 fixture generator silently omitted signed-I64 extremes |
| D2 | Original SLICE03 added five files outside its authorized tracked-mutation list |
| D3 | G0 recorded the wrong producing-compiler SHA |
| D4 | C1 evidence contains a stale fixture-count observation of 99 |
| D5 | Historical ACT range contains six commits, including `b707529`, rather than the specified five |
| D6 | The literal P16 enumeration cannot fit within the frozen 40-row partition |
| D7 | P16's nominal `expected_output=-1` does not describe its mixed expected values |

The predecessor's original PASS trailer and evidence must remain
unchanged.

### 1.1 The D1 mechanism (measured, not assumed)

The predecessor's P16 "I64 domain extreme" rows were emitted with the
tool's own `app_i` helper, which formats with `snprintf(..., "%d\n", v)`.
`%d` is a **32-bit** conversion, so every signed-I64 extreme was
TRUNCATED ON OUTPUT:

```text
INT64_MIN     (-9223372036854775808) -> printed as  0
INT64_MIN+1   (-9223372036854775807) -> printed as  1
INT64_MAX     ( 9223372036854775807) -> printed as -1
INT64_MAX-1   ( 9223372036854775806) -> printed as -2
```

The predecessor fixture's `F069..F072` rows carry exactly `0`, `1`,
`-1`, `-2`.  The values were computed correctly in the tool and were
destroyed by the formatter.  The PolyC `I64` arithmetic and the
`I64_MAX` / `I64_MIN` **hex** constants are NOT defective: they were
measured to carry the full 64-bit value through a C-side `%lld`
printer.

---

## 2. Authorized mutations

Permit only:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01.md

docs/factory/act-handoff-map.tsv

docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/**

tools/quality/parser-slice03-corr01-*.HC

Makefile
```

The five previously added, load-bearing files
(`src/cmake/VerifyOperatorPrecedenceObject.cmake`,
`src/cmake/WriteOperatorPrecedenceObjectStamp.cmake`,
`tools/quality/slice03-gen/g0-legacy-reference.c`,
`tools/quality/slice03-gen/generation-pairs.c`,
`tools/quality/slice03-is-terminal-stub.c`) may be used **prospectively**
under this ACT.  They are NOT deleted and are NOT retrospectively
declared compliant with SLICE03's original scope.

**Forbidden mutations:**

```text
existing closed evidence/**
existing closed HANDOFFs
existing closed ACT documents

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/**
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/**
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE03.md

src/prslib.c
src/parser.c
src/lexer.c
src/CMakeLists.txt

tools/bootstrap/selfhost-parser-operator-precedence.HC
tools/bootstrap/selfhost-parser-control-flow-token.HC
tools/bootstrap/selfhost-parser-padding.HC

tools/quality/parser-slice03-contract-requalify.HC
tools/quality/parser-slice03-differential.HC
tools/quality/parser-slice03-fixture-integrity.HC

existing Factory validators

## 3. C0 — AUTH / RED

Verify the live entry identity, clean worktree, predecessor
reachability, and frozen source hashes.

Reproduce all seven defects mechanically.

Independently enumerate the P16 required values using the 39 live
precedence-table entries.

For distinct-value coverage, require:

- Every operator value minus one.
- Every operator value plus one.
- `INT64_MIN`.
- `INT64_MIN+1`.
- `INT64_MAX-1`.
- `INT64_MAX`.
- `0`, `-1`, and `1`.

Freeze the canonical ordered set and its SHA-256.

Expected derivation from the supplied source snapshot:

```text
58 distinct operator-neighbor values
 4 signed-I64 extremes
 3 additional base values
--
65 distinct P16 values
```

If live source produces a different set, investigate before freezing the
contract.

---

## 4. C1 — CONTRACT REQUALIFICATION

Construct a new, correction-owned fixture contract.

Preserve all 19 partitions and their required coverage.  Do not preserve
the incorrect 98-row total merely for historical compatibility.

If other partition counts remain unchanged, expect **123** fixture rows:
**65** P16 rows plus **58** rows from other partitions.

Require semantic membership checks, not just fixture-ID and row-count
checks.

For every row, verify:

- Correct ID and partition membership.
- Exact signed 64-bit input.
- Expected precedence computed from the real legacy table.
- Valid input representation without overflow or truncation.
- Source identity and fixture SHA binding.

P16 expected values are derived individually; they are NOT universally
`-1`.

Require negative controls detecting:

1. a missing extreme,
2. a duplicated row replacing a required value,
3. an unknown row,
4. an overflowed input,
5. a fixture with correct row count but incorrect coverage.

---

## 5. C2 — IMPLEMENT QUALIFICATION REPAIR

Implement the corrected fixture generator and independent semantic
coverage verifier as **new** PolyC tools.

Do not modify the closed original generator.

Do not scan numeric fragments out of symbolic identifiers.  Symbolic
boundary constants MUST be resolved explicitly or rejected.

The producer MUST fail rather than emit a superficially complete fixture
when mandatory semantic values are missing.

Reuse the real legacy-C oracle and the existing PolyC subject WITHOUT

## 6. C3 — VERIFY

Execute the complete corrected fixture differential against the real
legacy-C oracle and the PolyC component.

Require every corrected row to agree with both its expected result and
the actual oracle output.

Independently verify the fixture's exact semantic value set.  The
verifier MUST NOT share the producer's symbolic-token parsing logic.

Rebuild G0 and capture the ACTUAL C compiler identity:

- Invocation and resolved compiler executable.
- Compiler executable SHA-256.
- Version.
- Source SHA-256.
- Exact compilation command.
- Resulting object SHA-256.

Reproduce G1–G3 provenance and the required semantic comparisons.
Re-run copy-forgery negative controls.

Run production authority checks, parser/lexer conservation, `gate-fast`,
`gate-push`, Factory-v2, append-only, F14 conservation, and patch
hygiene.

Record the historical six-commit SLICE03 range exactly, including the
`b707529` stage-0 build change.  Do not rewrite it or claim that it
satisfied a five-commit contract.

Verify zero tracked production-source changes relative to correction
entry.

---

## 7. Mandatory acceptance

All predicates are binding:

```text
PARSER_PRECEDENCE_PRODUCTION_AUTHORITY = POLYC
PRODUCTION_SUBJECT_SHA_DELTA          = 0
PRODUCTION_SEMANTIC_DELTA             = 0

P16_REQUIRED_VALUES_COMPLETE         = YES
P16_SIGNED_EXTREMES_PRESENT          = 4/4
P16_ALL_OPERATOR_NEIGHBORS_PRESENT   = YES
P16_FALSE_SYMBOLIC_NUMERICS          = 0
FIXTURE_COVERAGE_VERIFIER            = PASS
FIXTURE_NEGATIVE_CONTROLS            = PASS

REAL_C_ORACLE_DIFFERENTIAL           = PASS
DIFFERENTIAL_MISMATCHES              = 0
G0_COMPILER_IDENTITY                 = CORRECT
G0_G3_PROVENANCE                     = PASS

PREDECESSOR_F14_DELTA                = 0
HISTORICAL_SCOPE_VIOLATION           = ACKNOWLEDGED
HISTORICAL_SIX_COMMIT_RANGE          = ACKNOWLEDGED
RETROACTIVE_REPAIR_CLAIM             = FALSE

NEW_PARSER_FAILURE_IDENTITIES        = 0
NEW_LEXER_FAILURE_IDENTITIES         = 0
GATE_FAST                             = PASS
GATE_PUSH                             = PASS
FACTORY_V2                            = PASS
APPEND_ONLY                           = PASS
PATCH_HYGIENE_ERRORS                  = 0
```

Any mandatory predicate that cannot be proven is a HALT, not a PASS with
a prose exception.

---

## 8. C4 — CLOSE

Use a fresh, forward-only Factory-v2 correction range.

Required order:

```text
1. C0 RED      (historical defects and entry identity)
2. C1 EVIDENCE (independently requalified fixture contract)
3. C2 IMPL     (correction-owned qualification tools)
4. C3 EVIDENCE (differential, provenance, conservation and acceptance)
5. C4 CLOSE    (HANDOFF and final verdict)
```

Use contiguous, validator-compatible commit trailers.  Any correction
supersession metadata belongs on CLOSE and MUST satisfy the live Factory
validator.

No amend, reset, rebase, or force push.

The C4 commit is the final commit of the correction range.  Any
post-CLOSE terminality check MUST be read-only with results kept
outside tracked closed evidence.

---

## 9. Halt conditions

Halt on any unproven boundary value, fixture count or membership
contradiction, unverified G0 compiler identity, mutation of a closed
surface, production semantic regression, unauthorized tracked mutation,
or mandatory gate failure.

Preserve successful observations when halting.  Do not undo an
already-qualified production migration merely because a qualification
predicate fails.

---

## 10. Successor

After successful independent correction review:

```text
ACT-POLYC-SELFHOST-PARSER-SLICE04
```

Candidate shortlist: `CAND-019 astBinOpFromToken` and
`CAND-020 astUnaryOpFromToken`.

Select exactly one through the successor's binding eligibility and
ranking contract.  Do not preselect a winner by prose alone.

changes.  Where an existing closed differential cannot accept the
corrected fixture, provide a NEW correction-owned comparison tool
rather than weakening or editing its frozen contract.

---

pre-push hooks
```

No Python implementation.  No new oversized shell tools.

**F14 is binding.**  The predecessor's evidence tree and HANDOFF are
closed evidence.  The historical defects D1..D7 are RECORDED in this
ACT's own evidence; they are NOT repaired by editing SLICE03.

---
