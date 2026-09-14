# ACT-POLYC-SELFHOST-LEXER02-CORRECTION03

**Title:** Repair F-POLYC-TOOLS governance defect in CORRECTION02
closure (`adc977e`)

**Class:** CORRECTION (FACTORY-GOVERNANCE)

**ACT-Supersedes:** ACT-POLYC-SELFHOST-LEXER02-CORRECTION02 (for the
F-POLYC-TOOLS defect listed below)

**Predecessor (binding):**
ACT-POLYC-SELFHOST-LEXER02-CORRECTION02 CLOSED `adc977e`

**Trigger (post-CORRECTION02 reviewer audit):**

P0 — F-POLYC-TOOLS violation. CORRECTION02 introduced two new
substantive shell tools that implement TSV parsing, fixture
classification, file enumeration, multi-step orchestration,
sha256 byte-equality, classification policy, and provenance
binding:

  - `scripts/quality/lexer07-fixture-inventory.sh` (165 LOC)
  - `scripts/quality/lexer07-broad-corpus-4-stage.sh` (221 LOC)

The repository doctrine (F-POLYC-TOOLS) records that all newly
introduced tool implementations SHALL be PolyC; new shell is
allowed only as ≤50-LOC bootstrap/tiny-dispatch glue, and may
not implement TSV parsing, test matrices, filesystem
traversal, provenance calculation, policy classification, or
multi-step orchestration.

P1 — Historical stage0 wording. CORRECTION02's broad corpus
summary used the wording "175/175 BYTE_IDENTICAL_4" but nine
of those 175 are baseline-against-historical stage0 outputs
from `build/b02-corpus-A` (pre-existing `./hcc` ARM64 inline
asm regression), not freshly-produced current-stage0 outputs.
The mechanically exact wording should distinguish
`CURRENT_4_STAGE_BYTE_IDENTICAL` (166/166) from
`HISTORICAL_S0_BASELINED_4_WAY_EQ` (9/9) from
`TOTAL_EQUIVALENCE_COVERAGE` (175/175).

## Scope (bounded governance correction)

  - Two new substantive shell tools → port to PolyC
    (tools/quality/lexer07-fixture-inventory.HC,
    tools/quality/lexer07-broad-corpus-4-stage.HC); replace
    each shell with ≤50-LOC dispatch glue.
  - Existing CORRECTION02 evidence files (already PASS) are
    preserved verbatim; only the proof machinery changes.
  - No new dependency, no production source mutation, no
    ABI change, no language semantics change.

## Predicates

  - Both new shell tools ≤50 LOC (measured with `wc -l`).
  - Both new substantive implementations are .HC files
    (PolyC) and compile via `./hcc --install-dir=./build/test-prefix`.
  - Both binaries land in build/ and are invokable via the
    new shell wrappers and Makefile targets.
  - Makefile targets lexer07-fixture-inventory,
    lexer07-broad-corpus-4-stage continue to emit the
    CORRECTION02 PASS evidence.
  - shell-loc-gate explicitly runs and PASSes for the new
    shell scripts.
  - Lexer02 engineering result remains PASS (the underlying
    `scalar_literal_scanner` implementation is unchanged).

## Closure plan

  C1 RED:           mechanically enumerate both defects +
                    prove the new shell tools violate the
                    F-POLYC-TOOLS limit.
  C2 IMPL:          port both shell tools to PolyC;
                    replace shell with ≤50-LOC dispatch glue;
                    add Makefile build rules.
  C3 EVIDENCE:      re-run the CORRECTION02 evidence through
                    the PolyC-built binaries; prove equivalence;
                    run shell-loc-gate explicitly.
  C4 CLOSE:         update ROADMAP; write HANDOFF-...-CORRECTION03.md.

## Authorization

  F1 (identity before mutation): recorded at session start.
  F2 (recon): inspected F-POLYC-TOOLS doctrine,
              legacy registry, shell-loc-gate, Makefile.
  F3 (RED before production): C1 will mechanically demonstrate
      the violation before C2 ports the tools.
  F4 (failures are evidence): hcc parser bugs at large file
      sizes are NOT a halt — they are a constraint on the
      implementation strategy (smaller per-file scope).
  F5 (no test weakening): no test weakening; the FIX is to
      add PolyC ports, not to relax the gate.
  F6 (no silent fallback): the stage0 historical fallback in
      the broad corpus is preserved with explicit provenance
      binding (compiler_identity=stage0-historical).
  F7 (scope): bounded to the two specific tools.
  F13 (evidence over prose): every gate emits explicit
       PASS/FAIL counts.
  F15 (never self-authorize scope expansion): if porting
       requires ABI changes, halt with HALT_SCOPE_EXPANSION_REQUIRED.
