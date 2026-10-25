# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01
ACT-Phase: RED

**Title:** Repair PolyC's bootstrap dependency graph so a clean Git checkout builds the default production compiler without relying on untracked or gitignored binary artifacts

**Repository:** PolyC
**Branch:** `main`
**Class:** PRODUCTION / BOOTSTRAP / BUILD-SYSTEM-REPAIR
**Priority:** P0
**Execution mode:** EXECUTE — C0 through C4
**Authorized entry:** `fda4a62add5c2f268d1904f9243731727ae5d00b`
**Primary qualification host:** macOS ARM64
**Verdict target:** `PASS_TRUE_GREEN`

---

# 0. Mission (frozen)

Repair PolyC's bootstrap dependency graph so that the canonical user
command succeeds from a clean Git checkout:

```bash
make clean
make
```

The production compiler MUST continue to use:

```text
src/parser.c::CalcPadding
  -> BootstrapCalcPadding
  -> PolyC-generated object
```

The legacy implementation MUST remain available only as an explicit
stage0 / differential control.

The complete native sequence MUST be:

```text
HOST C COMPILER
      |
      v
STAGE0 LEGACY hcc
  HCC_USE_SELFHOST_PARSER_PADDING=OFF
      |
      v
BOOTSTRAP HEADER PREFIX
      |
      v
BOOTSTRAP PARSER-PADDING OBJECT
  compiled from selfhost-parser-padding.HC
      |
      v
PRODUCTION hcc
  HCC_USE_SELFHOST_PARSER_PADDING=ON
      |
      v
BOOTSTRAP02 / 03 / 04 (where required)
      |
      v
CANONICAL RUNTIME INSTALL
      |
      v
AOT / JIT / LSP / LLVM / PUSH GATES
```

**Central invariant:** the build MUST be acyclic, explicit, reproducible
and fail-closed.

---

# 1. Root cause (frozen at C0)

The historical input report identifies two build blockers:

```text
B1 = parser-padding-subject.o missing from fresh tree
B2 = hcc-bootstrap04 required before compiler-only CMake configure
```

plus release/runtime coupling:

```text
B3 = CMake runtime output defaults to repository root
B4 = cross-build must use target-architecture padding object
B5 = runtime install depends on a provenance-strict bootstrap04
B6 = Linux runtime port has separate existing limitations
```

These are RECON TARGETS, not unquestionable assumptions. C1 captures
actual behaviour at the entry tree and corrects the model if any
observation differs.

---

# 2. Binding predecessors

The current production migration is preserved from:

`ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01`

Its latest engineering qualification is:

`ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01`

at `fda4a62`.

These engineering invariants MUST be preserved:

```text
BOOTSTRAP_CALC_PADDING_SOURCE_DELTA=0
CALC_PADDING_PRODUCTION_DELEGATION=POLYC
HCC_USE_SELFHOST_PARSER_PADDING_DEFAULT=ON
LEGACY_RUNTIME_AUTHORITY=RETIRED
N01_PRODUCTION_CAUSALITY=PRESERVED
```

CORRECTION01's historical Factory-v2 range-check FAIL remains a
separate governance defect. This ACT does NOT repair or reclassify it.

---

# 3. Scope

## 3.1 IN SCOPE

Production build integration:

- `Makefile`
- `src/CMakeLists.txt`
- `.github/workflows/release.yml`, only where needed for correct
  bootstrap ordering or architecture-specific object production
- narrowly necessary Make/CMake build-graph definitions

Verification:

- new PolyC-native build qualification tests, if required
- existing canonical parser-padding and compiler tests
- isolated clean-checkout / build controls
- new ACT, evidence and HANDOFF artifacts

## 3.2 OUT OF SCOPE

No changes to:

- `src/parser.c::CalcPadding`
- `tools/bootstrap/selfhost-parser-padding.HC`
- parser-padding algebraic algorithm
- LEXER self-host implementations
- compiler parser or code generator semantics
- Factory-v2 range-check implementation
- `scripts/quality/gate-push.sh`
- `.githooks/pre-push`
- `scripts/quality/gate-fast.sh`
- old ACTs, closed evidence or HANDOFFs

Do NOT change Factory policy to obtain a PASS.

Do NOT add Python or substantive shell tooling.

All new substantive verifier logic MUST be written in PolyC. Shell is
permitted only as bounded bootstrap/dispatch glue under F-POLYC-TOOLS.

---

# 4. Entry gate (frozen)

```bash
set -eu

ACT=ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01
ENTRY=fda4a62add5c2f268d1904f9243731727ae5d00b

test "$(git branch --show-current)" = main
test "$(git rev-parse HEAD)" = "$ENTRY"
test -z "$(git status --porcelain)"

git diff --check
git merge-base --is-ancestor "$ENTRY" HEAD
```

If HEAD advanced, inspect the new commits and revalidate authorization
before making changes. Do NOT reset or rewrite history.

Measured entry identity, active toolchain, relevant environment
variables, source hashes and Git metadata are recorded under
`evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01/c0/`.

Availability of `cmake`, `make`, `cc`, `nm`, `ar`, `shasum` and LLVM 22
is recorded WITH ACTUAL VERSIONS. Toolchain identities are NEVER
invented.

---

# 5. Phase plan

| Phase | Trailer | Purpose |
|-------|---------|---------|
| C0 | `ACT-Phase: RED` | Authorization + entry identity + frozen subjects |
| C1 | `ACT-Phase: EVIDENCE` | RED reproduction, dependency graph, frozen design |
| C2 | `ACT-Phase: IMPL` | Production Makefile/CMake/release repair |
| C3 | `ACT-Phase: EVIDENCE` | Positive + negative controls, gates, conservation |
| C4 | `ACT-Phase: CLOSE` | HANDOFF, manifest registration, closure verdict |

## 5.1 C0 — AUTH

Create `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01/c0/`:

```text
entry-identity.txt
production-source-freeze.tsv
preexisting-gate-state.txt
build-graph-contract.txt
scope.txt
```

At C0, measure the byte identities of the frozen parser-padding
subjects and preserve those values for later comparison.

NO production changes in C0.

## 5.2 C1 — RED / RECON

- RED-1: clean build fails (isolated clean checkout at frozen ENTRY).
  Required: `RED_CLEAN_BUILD_REPRODUCED=YES`,
  `ENTRY_CLEAN_BUILD_RC_NONZERO=YES`.
- RED-2: recursive dependency analysis of
  `Makefile::all`, `Makefile::parser-padding-component`,
  `Makefile::test-prefix-install`,
  `src/CMakeLists.txt::HCC_USE_SELFHOST_PARSER_PADDING`,
  `src/CMakeLists.txt::HCC_BOOTSTRAP`.
  Required witnesses: `LEGACY_STAGE0_AVAILABLE_FROM_CLEAN_TREE=NO`,
  `PADDING_OBJECT_REQUIRES_EXISTING_HCC=YES`,
  `PRODUCTION_HCC_REQUIRES_PADDING_OBJECT=YES`,
  `BOOTSTRAP_GRAPH_CYCLE_DETECTED=YES`.
- RED-3: compiler-only configuration blocked by bootstrap04.
  Required: `COMPILER_ONLY_CONFIG_REQUIRES_BOOTSTRAP04=YES`.
- RED-4: unmodified `gate-push` failure against ENTRY.
  Required: `ENTRY_GATE_PUSH=FAIL`, `FIRST_FAILURE=<actual>`,
  `BYPASS_USED=NO`.
- RED-5: release matrix inspection with a SEPARATE disposition per
  platform.

Then FREEZE one concrete, acyclic design (D1..D6) before C2.

## 5.3 C2 — PRODUCTION IMPLEMENTATION

Implement the frozen acyclic build graph. The canonical production build
MUST automatically:

1. Build legacy stage0.
2. Prepare minimal bootstrap inputs.
3. Compile the PolyC padding object.
4. Verify the object symbol and architecture.
5. Configure production CMake with delegation ON.
6. Link production `hcc`.
7. Verify that `BootstrapCalcPadding` is linked.

NO manual prerequisite command may be required for `make all`.
NO ignored binary may be assumed present.
Use file-based dependencies and correct ordering rather than a
permanently phony rebuild pipeline.
Recompiling unchanged inputs MUST NOT unnecessarily recreate every stage.

CMake repair is bounded to the authorized build seams. The strict
runtime producer check MAY move from global configure time to the point
where that producer is actually required. It MUST NOT disappear.

The following silent fallbacks are FORBIDDEN:

```text
missing object            -> disable parser delegation
missing object            -> compile legacy CalcPadding instead
failed compiler           -> accept cached object
missing bootstrap         -> use random system hcc
wrong SHA                 -> recompute expected SHA from substituted producer
failed object compilation -> continue linking
```

## 5.4 C3 — VERIFY

Positive controls P01..P07 and negative controls N01..N05 as specified
in the ACT body, plus release matrix validation, F14 conservation and
Factory quality gates.

## 5.5 C4 — CLOSE

Closure preconditions, HANDOFF, manifest registration, CLOSE commit with
`ACT-Verdict` trailer, then external terminality observation.

---

# 6. Acceptance criteria (mandatory ledger)

All criteria MUST be resolved by OBSERVED evidence. No substituted
predicates. AC47 and AC48 are evaluated AFTER C4 exists and MUST NOT be
marked PASS in C3.

See `evidence/.../c3/mandatory-ac-status.tsv` for the per-AC witness map.

---

# 7. HALT taxonomy

```text
HALT_ENTRY_IDENTITY_MISMATCH
HALT_RED_NOT_REPRODUCED
HALT_SCOPE_EXPANSION_REQUIRED
HALT_STAGE0_BUILD_FAILED
HALT_BOOTSTRAP_GRAPH_STILL_CYCLIC
HALT_BOOTSTRAP_INPUTS_INSUFFICIENT
HALT_PADDING_OBJECT_BUILD_FAILED
HALT_STALE_OBJECT_ACCEPTED
HALT_WRONG_ARCH_OBJECT_ACCEPTED
HALT_PROVENANCE_CONTRACT_VIOLATED
HALT_RUNTIME_INSTALL_FAILED
HALT_PLATFORM_PORT_REQUIRED
HALT_PRODUCTION_SEMANTIC_REGRESSION
HALT_GATE_PUSH_NOT_GREEN
HALT_RELEASE_CROSS_BUILD_FAILED
HALT_CLOSED_EVIDENCE_MUTATION
HALT_MANDATORY_AC_NOT_GREEN
HALT_EXTERNAL_TERMINALITY_FAILED
```

A HALT MUST include the exact failing command, return code,
expected/actual predicate, and evidence path.

Complexity or session length is NOT a HALT condition.

---

# 8. Mutation controls

- Append-only history from `baf5dbd77cf89330699685dffd932c54031c815c`.
  Forbidden: `amend`, `rebase`, `filter-branch`, `filter-repo`,
  `git replace`, `reset + recommit`, `squash merge`, force push.
- Closed predecessor evidence and HANDOFFs are IMMUTABLE (F14).
- No SHA-of-self claims in any committed artifact (F-GIT-IDENTITY).
- No Python (F-NO-PYTHON). New substantive verifier logic in PolyC
  (F-POLYC-TOOLS).
- No weakening of an existing gate or test to obtain PASS (F5).

---

# 9. Next ACT

On successful closure:

```text
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

---

# 10. Closure record (written at C4)

The closure precondition of section 40 is evaluated against the
measured evidence in `evidence/.../c3/`. Every engineering predicate is
met, EXCEPT `GATE_PUSH_UNMODIFIED=PASS`.

```text
COLD_BUILD=PASS
PRODUCTION_PADDING_AUTHORITY=POLYC
BOOTSTRAP_GRAPH_ACYCLIC=YES
STALE_OBJECT_REUSE=NO
WRONG_ARCH_REJECTED=YES
WRONG_BOOTSTRAP_REJECTED=YES
PARSER_PADDING_CONSERVATION=PASS
LEXER_CONSERVATION=PASS
GATE_PUSH_UNMODIFIED=FAIL     (PRE-EXISTING GEP01 defect)
GATE_PUSH_BYPASS_USED=NO
F14=PASS
PATCH_HYGIENE_ERRORS=0
```

The gate failure is the pre-existing LLVM GEP01 cap-verifier defect.
Its failing rows are BYTE-IDENTICAL to the baseline recorded before this
ACT, and it is recorded as pre-existing in the Factory's own ROADMAP.

Section 33 governs this case: "If gate-push fails for a separate
pre-existing defect, classify that defect with its own evidence. Do not
claim full gate qualification." The defect IS classified, with its own
evidence (`c3/gate-push-unmodified.txt`), and full gate qualification is
NOT claimed.

The verdict is therefore `HALT_GATE_PUSH_NOT_GREEN` with
`HALT_CLASS=GOVERNANCE` and `BLOCKS_NEXT=NO`. A PASS verdict is not
available: the mechanical classifier REJECTS `HALT_CLASS` on a PASS
verdict, and the gate is not green. The verdict was validated against
`tools/factory/factory-halt-classification.HC`, which reports
`STATUS=PASS` for exactly this trailer set.

The HANDOFF is at
`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01.md`
and the pair is registered in `docs/factory/act-handoff-map.tsv`.
