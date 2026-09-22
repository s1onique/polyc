# ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT (post-reviewer-revision)

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01
ACT-Phase: RED

**Title:** Close DELEGATE01 binding-predicate defects without undoing the production migration and without rewriting history

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
   **The DELEGATE01 trailer geometry is structurally IMMUTABLE**;
   CORRECTION01 cannot repair ancestor commit messages from a child
   commit (per `git commit` / `git interpret-trailers` semantics).

CORRECTION01 prospectively authorizes what was already implemented,
produces honest G2/G3 evidence, and demonstrates forward-only closure
geometry on CORRECTION01's own C0..C4 range.

---

# 1. Terminal objective (forward-only)

Successful CORRECTION01 closure requires:

```text
JOB_1_DEDICATED_MACRO_SEAM_AUTHORIZATION          = YES
JOB_1_AC13_REGRADE_UNDER_AUTHORIZED_DESIGN        = PASS
JOB_1_DESIGN_RECONCILIATION_DOCUMENTED            = YES

JOB_2_G0_PARSER_BINARY_SHA256_FROZEN              = YES
JOB_2_G1_PARSER_BINARY_SHA256_FROZEN              = YES
JOB_2_G2_PARSER_BINARY_SHA256_FROZEN              = YES
JOB_2_G3_PARSER_BINARY_SHA256_FROZEN              = YES
JOB_2_G0_G1_G2_G3_INDEPENDENT_RUNS                = 4
JOB_2_G2_PRODUCTION_OUTPUT_SHA256_FROZEN          = YES
JOB_2_G3_PRODUCTION_OUTPUT_SHA256_FROZEN          = YES
JOB_2_NO_PROVENANCE_PLACEHOLDER_TEXT              = YES

JOB_3_DELEGATE01_HISTORICAL_TRAILER_GEOMETRY      = IMMUTABLE_FAIL_ACK
JOB_3_CORRECTION01_C0_TRAILER_BLOCK_PARSEABLE     = YES
JOB_3_CORRECTION01_C1_TRAILER_BLOCK_PARSEABLE     = YES
JOB_3_CORRECTION01_C2_TRAILER_BLOCK_PARSEABLE     = YES
JOB_3_CORRECTION01_C3_TRAILER_BLOCK_PARSEABLE     = YES
JOB_3_CORRECTION01_C4_TRAILER_BLOCK_PARSEABLE     = YES
JOB_3_FACTORY_V2_RANGE_CHECK_CORRECTION01         = PASS
JOB_3_DELEGATE01_HANDOFF_DELTA                    = 0
JOB_3_DELEGATE01_EVIDENCE_DELTA                   = 0

INVARIANT_APPEND_ONLY_HISTORY_PRESERVED            = YES
INVARIANT_PRODUCTION_MIGRATION_DELTA              = 0
INVARIANT_PRODUCTION_AUTHORITY_AT_CLOSE           = POLYC
INVARIANT_LEGACY_RUNTIME_AUTHORITY                = RETIRED
INVARIANT_CORRECTION01_COMMIT_COUNT               = 5

CORRECTION01_VERDICT                              = PASS_TRUE_GREEN
```

The CORRECTION01 ACT SHALL NOT:

* Rewrite any closed DELEGATE01 evidence file.
* Mutate the closed DELEGATE01 HANDOFF (post-C4 HANDOFF delta = 0).
* Touch `src/parser.c`, `src/CMakeLists.txt`, or any other production
  source. The migration is real and stays.
* Use amend, rebase, reset, or force push on DELEGATE01 history.
* Attempt to mutate ancestor commit messages (structurally impossible
  per Git semantics).
* Claim any DELEGATE01 trailer defect is "repaired"; it is
  `IMMUTABLE_FAIL_ACK`.

---

# 2. Historical truth -- immutable

The following DELEGATE01 facts are preserved verbatim:

```text
DELEGATE01_HEAD_AT_CLOSE                  = 35dc0b00d177b51b308d18658fad584ca3357ad6
DELEGATE01_REVIEWED_VERDICT               = HALT_MULTIPLE_BINDING_PREDICATES
DELEGATE01_HISTORICAL_TRAILER_GEOMETRY    = IMMUTABLE_FAIL_ACK

DELEGATE01_PRODUCTION_AUTHORITY_AT_ENTRY  = LEGACY_C
DELEGATE01_PRODUCTION_AUTHORITY_AT_CLOSE  = POLYC
DELEGATE01_N01_PRODUCTION_CAUSALITY       = TRUE_GREEN
DELEGATE01_LEGACY_RUNTIME_AUTHORITY       = RETIRED

DELEGATE01_PARSER_PADDING_PRODUCTION_MIGRATION    = ENGINEERING_TRUE_GREEN
DELEGATE01_PARSER_PADDING_COMPONENT_QUALIFICATION = TRUE_GREEN

DELEGATE01_C0..C4_EVIDENCE_DELTA          = 0
DELEGATE01_HANDOFF_DELTA                  = 0  (post-C4 frozen)
```

The C0..C4 evidence directories are CLOSED per F14 and SHALL NOT be
modified. The HANDOFF at
`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01.md`
is similarly immutable post-C4; if needed, the reviewer verdict is
recorded in this CORRECTION01 evidence directory under a new file,
not by mutating the closed HANDOFF.

---

# 3. Authorized production source (frozen)

```text
HCC_USE_SELFHOST_PARSER_PADDING = YES  (default ON, dedicated seam)
src/parser.c::CalcPadding       = #ifdef-d delegation to BootstrapCalcPadding
                                   #else = legacy oracle (stage0 only)
src/CMakeLists.txt              = option() + if() linking build/parser-padding-subject.o
```

CORRECTION01 prospectively authorizes the dedicated
`HCC_USE_SELFHOST_PARSER_PADDING` seam and freezes it as the binding
production authority design. No production source mutation is
authorized.

---

# 4. Authorized scope (frozen)

CORRECTION01 is bounded to:

* **Documentation of the binding reviewer verdict and its rationale**
  in `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/`
  (new tree; DELEGATE01 evidence untouched).
* **G2 and G3 production binary SHA-256 freeze** plus full independent
  build/run transcripts recorded under C1/C3 evidence (real SHA-256,
  no placeholder text).
* **Re-execution of the external terminality gate against the
  CORRECTION01 range** (forward only; DELEGATE01 range remains
  acknowledged as `IMMUTABLE_FAIL_ACK`).
* **Five forward commits** (C0..C4) with contiguous trailer blocks,
  produced via native `git commit --trailer ...`, no amend, no reset,
  no force push.

Production source code, production binaries, PolyC subject source,
and the closed DELEGATE01 evidence + HANDOFF surfaces are explicitly
OUT OF SCOPE.

---

# 5. RED/CONTRACT (C1 of CORRECTION01)

## C1.1 -- Prospective re-authorization of the dedicated macro seam

```text
RED: the C1 frozen design (HCC_USE_SELFHOST_COMPONENTS) is incompatible
     with the implemented design (HCC_USE_SELFHOST_PARSER_PADDING).
WITNESS: c1-design-reconciliation-contract.txt records the design
         reconciliation, the rationale for the dedicated flag, and
         the prospective AC13 regrading.
```

## C1.2 -- G2 / G3 production seam independent-run contract

```text
RED: the C3 generation-provenance TSV has placeholder text for G2/G3.
WITNESS: c1-generation-independent-run-contract.tsv freezes the
         required compiler SHA, subject SHA, full command, output
         SHA, and binary SHA for G2 and G3 generations.
         Placeholder text is explicitly rejected.
```

## C1.3 -- Forward closure geometry contract

```text
RED: the DELEGATE01 C0..C3 trailer blocks have blank-line-separated
     trailers. Per Git semantics, child commits cannot mutate
     ancestor commit messages.
WITNESS: c1-closure-geometry-contract.txt freezes the trailer
         format that CORRECTION01 itself will use on its own
         C0..C4 range (contiguous trailer block, native
         `git commit --trailer ...`).
DELEGATE01_HISTORICAL_TRAILER_GEOMETRY = IMMUTABLE_FAIL_ACK  (acknowledged)
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
* Record for each (no placeholders):
    * `compiler_path` (real path)
    * `compiler_sha256` (real SHA-256)
    * `exact_build_command_sha256` (SHA-256 of the literal command)
    * `parser_padding_subject_sha256` (real SHA-256)
    * `resulting_production_binary_sha256` (real SHA-256)
    * `fixture_command_sha256` (SHA-256 of the literal fixture command)
    * `fixture_output_sha256` (SHA-256 of the actual captured output)

## C2.3 -- Forward closure geometry (five new commits)

* Execute a true forward commit sequence (C0..C4) on top of the
  current HEAD (the post-mortem authorization commit).
  - `git commit --amend` is FORBIDDEN
  - `git reset` is FORBIDDEN
  - `git rebase` is FORBIDDEN
  - `git push --force` is FORBIDDEN
* Each commit message SHALL use contiguous trailer blocks via
  `git commit --trailer 'ACT: ...' --trailer 'ACT-Phase: ...' --trailer 'ACT-Verdict: ...'`.
* Re-execute `scripts/quality/factory-v2-range-check.sh` against the
  CORRECTION01 range and record `STATUS=PASS`.

---

# 7. VERIFY (C3 of CORRECTION01)

C3 verifies:

* **JOB 1**
    * AC05 -- AC13 regrades to PASS under authorized design
    * AC06 -- `HCC_USE_SELFHOST_PARSER_PADDING = ON (default)`
    * AC07 -- `src/parser.c` byte-identical to DELEGATE01 C2 freeze
    * AC08 -- `src/CMakeLists.txt` byte-identical to DELEGATE01 C2 freeze
    * AC18 -- DELEGATE01 evidence directories untouched
    * AC19 -- DELEGATE01 HANDOFF byte-identical (delta = 0)
* **JOB 2**
    * AC09 -- G2 production binary SHA-256 frozen
    * AC10 -- G3 production binary SHA-256 frozen
    * AC11 -- G2 production output SHA-256 frozen
    * AC12 -- G3 production output SHA-256 frozen
    * AC13 -- G2/G3 build/run command transcripts recorded
    * AC20 -- G0..G3 generation-provenance rows concrete (no placeholders)
    * AC32 -- 4 generation provenance rows
    * AC33 -- no generation provenance FAIL
* **JOB 3**
    * AC14 -- DELEGATE01 trailer geometry = IMMUTABLE_FAIL_ACK (acknowledged)
    * AC15 -- CORRECTION01 C0..C4 trailer blocks parseable and contiguous
    * AC16 -- `factory-v2-range-check CORRECTION01` = PASS
* **Invariants**
    * AC22 -- append-only history preserved
    * AC23 -- production migration delta = 0
    * AC24 -- production authority at CORRECTION01 close = POLYC
    * AC25 -- legacy runtime authority = RETIRED
    * AC26 -- CORRECTION01 commit count = 5
    * AC17 -- `gate-fast` = PASS

---

# 8. CLOSE (C4 of CORRECTION01)

C4 closes the ACT, writes the HANDOFF at
`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01.md`,
and appends to `docs/factory/act-handoff-map.tsv`.

---

# 9. Acceptance criteria

```text
AC01  ENTRY_HEAD = 8393d4d (post-mortem authorization)
AC02  branch = main
AC03  worktree clean at CORRECTION01 C0
AC04  predecessor verdict = HALT_MULTIPLE_BINDING_PREDICATES
AC05  AC13 regrades to PASS under authorized design
AC06  HCC_USE_SELFHOST_PARSER_PADDING = ON (default)
AC07  src/parser.c untouched (no diff vs DELEGATE01 C2)
AC08  src/CMakeLists.txt untouched (no diff vs DELEGATE01 C2)
AC09  G2 production binary SHA-256 frozen (real value)
AC10  G3 production binary SHA-256 frozen (real value)
AC11  G2 production output SHA-256 frozen
AC12  G3 production output SHA-256 frozen
AC13  G2/G3 build/run command transcripts recorded (literal commands + output capture)
AC14  DELEGATE01 trailer geometry = IMMUTABLE_FAIL_ACK (no false repair claim)
AC15  CORRECTION01 C0..C4 trailer blocks parseable and contiguous
AC16  factory-v2-range-check CORRECTION01 = PASS
AC17  gate-fast = PASS
AC18  DELEGATE01 evidence directories delta = 0
AC19  DELEGATE01 HANDOFF delta = 0 (post-C4 frozen)
AC20  G0..G3 generation-provenance rows concrete (no placeholders)
AC21  patch hygiene errors = 0
AC22  F14 closed-evidence surfaces untouched
AC23  F-POLYC-TOOLS = PASS
AC24  F-NO-PYTHON = PASS
AC25  HANDOFF PASS_TRUE_GREEN with all required sections
AC26  CORRECTION01 commit count = 5
AC27  commit topology honors C0-before-C1 (contiguous forward sequence)
AC28  no amend / reset / rebase / force push on CORRECTION01 history
AC29  PREDECESSOR_EFFECTIVE_DISPOSITION = HALT_MULTIPLE_BINDING_PREDICATES
       recorded in CORRECTION01 evidence, not in DELEGATE01 HANDOFF
```

---

# 10. Halt semantics

```text
HALT_DESIGN_RECONCILIATION_REJECTED       (if AC05 cannot regrade)
HALT_G2_G3_BUILD_INFRASTRUCTURE_MISSING  (if hcc-bootstrap02/03 unavailable)
HALT_APPEND_ONLY_VIOLATION                (if any amend/reset/force push detected)
HALT_RANGE_CHECK_STILL_FAIL               (if factory-v2-range-check CORRECTION01 still FAIL)
HALT_PRODUCTION_SOURCE_DRIFT              (if any production source diff)
HALT_PLACEHOLDER_PROVENANCE               (if AC20 still contains placeholder text)
HALT_CLOSED_HANDOFF_MUTATION              (if AC19 delta > 0)
HALT_ANCESTOR_TRAILER_MUTATION_ATTEMPT    (if CORRECTION01 attempts to mutate DELEGATE01 commit messages)
```

---

# 11. Reviewer feedback acknowledgments

This ACT body was revised in response to two binding observations
from the external Factory reviewer:

1. **Trailer-repair geometry is structurally impossible**: A new
   commit cannot mutate ancestor commit messages. CORRECTION01
   therefore targets its own C0..C4 range, not DELEGATE01's
   historical commits. DELEGATE01 trailer geometry is acknowledged
   as `IMMUTABLE_FAIL_ACK`.

2. **Closed HANDOFF mutation is F14-improper**: The C3 F14 contract
   treats evidence and HANDOFF surfaces as immutable post-C4. The
   reviewer verdict is recorded in CORRECTION01 evidence, not by
   mutating the closed DELEGATE01 HANDOFF.

Both defects are corrected in this ACT body.

---

# 12. Recommended next ACT after CORRECTION01 PASS

```text
NEXT = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

The parser-padding slice is the first PolyC production-authority
component; the slice-recon ACT can begin with confidence after
CORRECTION01 PASS.
