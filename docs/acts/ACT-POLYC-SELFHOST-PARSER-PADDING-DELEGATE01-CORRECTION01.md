# ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01
ACT-Phase: RED

**Title:** Close DELEGATE01 binding-predicate defects without undoing the production migration

**Repository:** PolyC
**Branch:** `main`
**Class:** SELFHOST / PRODUCTION-AUTHORITY-MIGRATION / QUALIFICATION-CORRECTION
**Priority:** P0

---

# 0. Mission (frozen)

`ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01` terminated with a binding
reviewer verdict:

```text
EFFECTIVE_VERDICT = HALT_MULTIPLE_BINDING_PREDICATES
```

The production migration itself is real engineering work and MUST be
preserved intact:

```text
PARSER_PADDING_COMPONENT_QUALIFICATION        = TRUE_GREEN
PARSER_PADDING_PRODUCTION_MIGRATION           = ENGINEERING_TRUE_GREEN
PARSER_PADDING_PRODUCTION_AUTHORITY           = POLYC
N01_PRODUCTION_CAUSALITY                      = TRUE_GREEN
LEGACY_RUNTIME_AUTHORITY                      = RETIRED
```

Three binding-predicate failures block promotion to `PASS_TRUE_GREEN`:

1. **P0-1 / AC13 FAIL** -- C1 froze `D-C = HCC_USE_SELFHOST_COMPONENTS`
   with `NO_NEW_MACRO=YES` and the explicit halt trigger
   `HALT_DELEGATION_DESIGN_AMBIGUOUS` for a new macro. C2 introduced
   the dedicated `HCC_USE_SELFHOST_PARSER_PADDING` flag. The
   engineering rationale is sound (the generic flag would activate
   all lexer self-host components), but the C1 design was violated.
   AC13 is mechanically FAIL.

2. **P0-2 / AC20 + AC32 + AC33 NOT_PROVEN** -- The C3
   generation-provenance TSV has placeholder text for G2 and G3
   parser-binary SHAs (`(distinct from G1 because...)`). The
   production-semantic-verify.txt shows build/run transcripts only
   for G0 and G1. G2/G3 independent production execution was
   asserted in prose, not mechanically recorded.

3. **P0-3 / external terminality FAIL** -- FACTORY_V2_RANGE_CHECK
   reports FAIL because the C0..C3 commits have blank-line-separated
   trailers and only `ACT-Verdict:` is parseable on the parent walk.

CORRECTION01 prospectively authorizes what was already implemented
and produces honest G2/G3 evidence and clean closure geometry.

---

# 1. Terminal objective

Successful CORRECTION01 closure requires:

```text
DEDICATED_MACRO_SEAM_AUTHORIZATION   = YES
AC13_REGRADE_UNDER_AUTHORIZED_DESIGN = PASS
G2_PARSER_BINARY_SHA256_FROZEN       = YES
G3_PARSER_BINARY_SHA256_FROZEN       = YES
G0_G1_G2_G3_INDEPENDENT_RUNS         = 4
G2_PRODUCTION_OUTPUT_SHA256          = FROZEN
G3_PRODUCTION_OUTPUT_SHA256          = FROZEN
C0_TRAILER_BLOCK_CONTIGUOUS          = YES
C1_TRAILER_BLOCK_CONTIGUOUS          = YES
C2_TRAILER_BLOCK_CONTIGUOUS          = YES
C3_TRAILER_BLOCK_CONTIGUOUS          = YES
C4_TRAILER_BLOCK_CONTIGUOUS          = YES
FACTORY_V2_RANGE_CHECK               = PASS
APPEND_ONLY_HISTORY_PRESERVED         = YES
PRODUCTION_MIGRATION_DELTA           = 0
PRODUCTION_AUTHORITY_AT_CLOSE        = POLYC
LEGACY_RUNTIME_AUTHORITY             = RETIRED
CORRECTION01_VERDICT                 = PASS_TRUE_GREEN
```

The CORRECTION01 ACT SHALL NOT:

* Rewrite any closed DELEGATE01 evidence file.
* Touch `src/parser.c`, `src/CMakeLists.txt`, or any other production
  source. The migration is real and stays.
* Use amend, rebase, reset, or force push.

---

# 2. Historical truth -- immutable

The following DELEGATE01 facts are preserved verbatim:

```text
DELEGATE01_COMMIT_COUNT                    = 5
DELEGATE01_FINAL_HEAD                      = 35dc0b00d177b51b308d18658fad584ca3357ad6
DELEGATE01_HISTORY_IMMUTABLE               = YES
DELEGATE01_REVIEWED_VERDICT                = HALT_MULTIPLE_BINDING_PREDICATES

DELEGATE01_PRODUCTION_AUTHORITY_AT_ENTRY   = LEGACY_C
DELEGATE01_PRODUCTION_AUTHORITY_AT_CLOSE   = POLYC
DELEGATE01_N01_PRODUCTION_CAUSALITY        = TRUE_GREEN
DELEGATE01_LEGACY_RUNTIME_AUTHORITY        = RETIRED

DELEGATE01_PARSER_PADDING_PRODUCTION_MIGRATION    = ENGINEERING_TRUE_GREEN
DELEGATE01_PARSER_PADDING_COMPONENT_QUALIFICATION = TRUE_GREEN
```

The C0..C4 evidence directories are CLOSED per F14 and SHALL NOT be
modified.

---

# 3. Authorized production source (frozen)

```text
HCC_USE_SELFHOST_PARSER_PADDING = YES  (default ON)
src/parser.c::CalcPadding       = #ifdef-d delegation to BootstrapCalcPadding
                                   #else = legacy oracle (stage0 only)
src/CMakeLists.txt              = option() + if() linking build/parser-padding-subject.o
```

This CORRECTION01 prospectively authorizes the dedicated
`HCC_USE_SELFHOST_PARSER_PADDING` seam and freezes it as the binding
production authority design.

---

# 4. Authorized scope (frozen)

CORRECTION01 is bounded to:

* Documentation of the binding reviewer verdict and its rationale
  (prospective C0-C2 evidence files in
  `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/`).
* G2 and G3 production binary SHA-256 freeze plus full independent
  build/run transcripts recorded under C1/C3 evidence.
* Repair of the C0..C4 trailer blocks via a true `git commit --trailer`
  or `git interpret-trailers --if-exists=replace` workflow, executed
  as a single prospective commit on top of the closed DELEGATE01
  HEAD -- no amend, no reset, no force push.
* Re-execution of the external terminality gate against the new HEAD.

Production source code, production binaries, and PolyC subject source
are explicitly OUT OF SCOPE.

---

# 5. RED/CONTRACT (C1 of CORRECTION01)

## C1.1 -- Prospective re-authorization of the dedicated macro seam

```text
RED: the C1 frozen design (HCC_USE_SELFHOST_COMPONENTS) is incompatible
     with the implemented design (HCC_USE_SELFHOST_PARSER_PADDING).
WITNESS: c1-delegation-design-correction01.txt records the design
         reconciliation, the rationale for the dedicated flag, and
         the prospective AC13 regrading.
```

## C1.2 -- G2 / G3 production seam independent-run contract

```text
RED: the C3 generation-provenance TSV has placeholder text for G2/G3.
WITNESS: c1-generation-independent-run-contract.tsv freezes the
         required compiler SHA, subject SHA, full command, output
         SHA, and binary SHA for G2 and G3 generations.
```

## C1.3 -- Closure geometry contract

```text
RED: the C0..C4 trailer blocks have blank-line-separated trailers.
WITNESS: c1-closure-geometry-contract.txt freezes the trailer
         format that will be applied prospectively (contiguous
         trailer block, native `git commit --trailer ...`).
```

---

# 6. IMPL (C2 of CORRECTION01)

## C2.1 -- Prospective re-authorization

* Re-authorize the dedicated `HCC_USE_SELFHOST_PARSER_PADDING` flag
  (already in `src/CMakeLists.txt`).
* Re-freeze AC13 under the new design.
* Document the design rationale in
  `evidence/.../CORRECTION01/c2/c2-design-reconciliation.txt`.

## C2.2 -- G2 / G3 independent production execution

* Build `hcc-bootstrap02` (G2) and `hcc-bootstrap03` (G3) via the
  existing bootstrap chain.
* Record for each:
    * compiler SHA-256
    * parser-padding subject object SHA-256
    * resulting production binary SHA-256
    * full build command transcript
    * run command transcript
    * FIXTURE_ALIGNOF / FIXTURE_U0_TAIL / FIXTURE_INHERITANCE
      output SHA-256

## C2.3 -- Closure geometry repair (single prospective commit)

* On top of DELEGATE01 HEAD = `35dc0b0`, execute a true commit
  (`git commit --amend` is FORBIDDEN; `git reset` is FORBIDDEN;
  `git rebase` is FORBIDDEN; force push is FORBIDDEN).
* The commit message SHALL use contiguous trailer blocks via
  `git commit --trailer 'ACT: ...' --trailer 'ACT-Phase: ...' --trailer 'ACT-Verdict: ...'`.
* Re-execute `scripts/quality/factory-v2-range-check.sh` and
  record `STATUS=PASS`.

---

# 7. VERIFY (C3 of CORRECTION01)

C3 verifies:

* AC13 = PASS under authorized design.
* AC20 = PASS (G0/G1/G2/G3 independently executed).
* AC32 = PASS (4 generation provenance rows).
* AC33 = PASS (no generation provenance fail).
* FACTORY_V2_RANGE_CHECK = PASS.
* Append-only history preserved.
* No production source touched.
* All C0..C4 trailer blocks contiguous and parseable.

---

# 8. CLOSE (C4 of CORRECTION01)

C4 closes the ACT, writes the HANDOFF, appends to `act-handoff-map.tsv`.

---

# 9. Acceptance criteria

```text
AC01  ENTRY_HEAD matches CORRECTION01 C0
AC02  branch = main
AC03  worktree clean at CORRECTION01 C0
AC04  predecessor verdict = HALT_MULTIPLE_BINDING_PREDICATES
AC05  AC13 regrades to PASS under authorized design
AC06  HCC_USE_SELFHOST_PARSER_PADDING = ON (default)
AC07  src/parser.c untouched (no diff)
AC08  src/CMakeLists.txt untouched (no diff)
AC09  G2 production binary SHA-256 frozen
AC10  G3 production binary SHA-256 frozen
AC11  G2 production output SHA-256 frozen
AC12  G3 production output SHA-256 frozen
AC13  G2/G3 build/run command transcripts recorded
AC14  C0..C4 trailer blocks contiguous
AC15  factory-v2-range-check = PASS
AC16  gate-fast = PASS
AC17  patch hygiene errors = 0
AC18  F14 closed-evidence surfaces untouched
AC19  F-POLYC-TOOLS = PASS
AC20  F-NO-PYTHON = PASS
AC21  HANDOFF PASS_TRUE_GREEN with all required sections
AC22  commit topology honors C0-before-C1
```

---

# 10. Halt semantics

```text
HALT_DESIGN_RECONCILIATION_REJECTED       (if AC05 cannot regrade)
HALT_G2_G3_BUILD_INFRASTRUCTURE_MISSING  (if hcc-bootstrap02/03 unavailable)
HALT_APPEND_ONLY_VIOLATION                (if any amend/reset/force push detected)
HALT_RANGE_CHECK_STILL_FAIL               (if factory-v2-range-check still FAIL)
HALT_PRODUCTION_SOURCE_DRIFT              (if any production source diff)
```

---

# 11. Recommended next ACT after CORRECTION01 PASS

```text
NEXT = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

The parser-padding slice is the first PolyC production-authority
component; the slice-recon ACT can now begin with confidence.
