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

## 0.1 Authorization revision lineage

This ACT body has been revised twice against the reviewer verdict:

| Commit       | Role                                                                |
|--------------|---------------------------------------------------------------------|
| `8393d4d`    | Post-mortem authorization (initial draft, two structural defects)   |
| `b73fe6b`    | First revision (trailer + HANDOFF mutations corrected)              |
| `<this>`     | Final pre-C0 revision (ENTRY_HEAD + SHA baselines frozen)           |

The current ACT body is committed at HEAD and is the authoritative
authorization for the next session's CORRECTION01 work. C0 begins at
the **first new commit after this revision**; it is **not** a
modification of any prior commit (append-only invariant).

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

JOB_3_DELEGATE01_HISTORICAL_TRAILER_GEOMETRY          = IMMUTABLE_FAIL_ACK
JOB_3_DELEGATE01_HANDOFF_HISTORICAL_F14_VIOLATION      = ACKNOWLEDGED
JOB_3_DELEGATE01_HANDOFF_DELTA_SINCE_ENTRY             = 0
JOB_3_DELEGATE01_EVIDENCE_DELTA_SINCE_ENTRY            = 0
JOB_3_CORRECTION01_C0_TRAILER_BLOCK_PARSEABLE         = YES
JOB_3_CORRECTION01_C1_TRAILER_BLOCK_PARSEABLE         = YES
JOB_3_CORRECTION01_C2_TRAILER_BLOCK_PARSEABLE         = YES
JOB_3_CORRECTION01_C3_TRAILER_BLOCK_PARSEABLE         = YES
JOB_3_CORRECTION01_C4_TRAILER_BLOCK_PARSEABLE         = YES
JOB_3_FACTORY_V2_RANGE_CHECK_CORRECTION01             = PASS

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

# DELEGATE01 HANDOFF mutation history (truthful decomposition)
DELEGATE01_HANDOFF_SHA256_AT_DELEGATE01_C4_CLOSE  = (see reflog / git show 35dc0b0:docs/factory/HANDOFF-...md)
DELEGATE01_HANDOFF_SHA256_AT_POST_MORTEM_8393d4d = (the post-mortem added a reviewer-verdict block)
DELEGATE01_HANDOFF_SHA256_AT_CORRECTION01_ENTRY  = 012d6054499d7e17f5c7cb450b05c36ed3f57b74e33453ae3cad2300c6ebb56d
DELEGATE01_HANDOFF_HISTORICAL_F14_VIOLATION       = ACKNOWLEDGED
DELEGATE01_HANDOFF_DELTA_SINCE_CORRECTION01_ENTRY = 0   (forward invariant)

# DELEGATE01 evidence surface
DELEGATE01_EVIDENCE_SHA256_SET_AT_CORRECTION01_ENTRY  = (see evidence/.../CORRECTION01/pre-c0/pre-c0-delegate01-evidence-sha-baseline.tsv)
DELEGATE01_EVIDENCE_HISTORICAL_F14_VIOLATION          = NONE (post-C4 evidence was not mutated by 8393d4d)
DELEGATE01_EVIDENCE_DELTA_SINCE_CORRECTION01_ENTRY    = 0
```

NOTE on the distinction: the reviewer's binding observation is that
"delta = 0" wording alone conflates two different facts. The two
predicates above make them explicit:

* **Historical F14 violation** -- the post-mortem commit `8393d4d`
  mutated the closed DELEGATE01 HANDOFF. That is acknowledged and
  **cannot** be undone (append-only invariant from `baf5dbd7`
  forward).
* **Forward invariant during CORRECTION01** -- no further mutation of
  the DELEGATE01 HANDOFF or evidence trees during the CORRECTION01
  C0..C4 sequence. This is what `*_DELTA_SINCE_CORRECTION01_ENTRY = 0`
  measures, and it is the actionable contract.

The frozen baseline values used to measure the forward invariant live
in `evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/pre-c0/`.

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
* **JOB 2**
    * AC09 -- G2 production binary SHA-256 frozen
    * AC10 -- G3 production binary SHA-256 frozen
    * AC11 -- G2 production output SHA-256 frozen
    * AC12 -- G3 production output SHA-256 frozen
    * AC13 -- G2/G3 build/run command transcripts recorded
    * AC21 -- G0..G3 generation-provenance rows concrete (no placeholders)
* **JOB 3**
    * AC14 -- DELEGATE01 trailer geometry = IMMUTABLE_FAIL_ACK (acknowledged)
    * AC15 -- CORRECTION01 C0..C4 trailer blocks parseable and contiguous
    * AC16 -- `factory-v2-range-check CORRECTION01` = PASS
    * AC18 -- DELEGATE01 evidence SHA256 set delta since ENTRY_HEAD = 0
      (verified by re-hashing the evidence tree at C4 and comparing to
      `pre-c0/pre-c0-delegate01-evidence-sha-baseline.tsv`)
    * AC19 -- DELEGATE01 HANDOFF delta since ENTRY_HEAD = 0
      (verified by re-hashing the HANDOFF at C4 and comparing to
      `pre-c0/pre-c0-delegate01-handoff-sha-baseline.txt`)
    * AC20 -- historical post-C4 HANDOFF mutation
      = ACKNOWLEDGED_F14_VIOLATION
* **Invariants**
    * AC23 -- F14 closed-evidence surfaces untouched
    * AC24 -- F-POLYC-TOOLS = PASS
    * AC25 -- F-NO-PYTHON = PASS
    * AC27 -- CORRECTION01 commit count = 5
    * AC29 -- no amend / reset / rebase / force push on CORRECTION01 history
    * AC17 -- `gate-fast` = PASS

---

# 8. CLOSE (C4 of CORRECTION01)

C4 closes the ACT, writes the HANDOFF at
`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01.md`,
and appends to `docs/factory/act-handoff-map.tsv`.

---

# 9. Acceptance criteria

```text
AC01  ENTRY_HEAD = authorization revision HEAD (b73fe6b family); C0 is
       the first new commit after the revision commit, NOT a modification
       of any prior commit
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
AC18  DELEGATE01 evidence SHA256 set delta since CORRECTION01 ENTRY_HEAD = 0
       (baseline frozen in pre-c0/pre-c0-delegate01-evidence-sha-baseline.tsv)
AC19  DELEGATE01 HANDOFF delta since CORRECTION01 ENTRY_HEAD = 0
       (baseline SHA256 frozen in pre-c0/pre-c0-delegate01-handoff-sha-baseline.txt)
AC20  historical post-C4 HANDOFF mutation = ACKNOWLEDGED_F14_VIOLATION
       (truthful record of the 8393d4d mutation; not undone)
AC21  G0..G3 generation-provenance rows concrete (no placeholders)
AC22  patch hygiene errors = 0
AC23  F14 closed-evidence surfaces untouched
AC24  F-POLYC-TOOLS = PASS
AC25  F-NO-PYTHON = PASS
AC26  HANDOFF PASS_TRUE_GREEN with all required sections
AC27  CORRECTION01 commit count = 5
AC28  commit topology honors C0-before-C1 (contiguous forward sequence)
AC29  no amend / reset / rebase / force push on CORRECTION01 history
AC30  PREDECESSOR_EFFECTIVE_DISPOSITION = HALT_MULTIPLE_BINDING_PREDICATES
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
HALT_PLACEHOLDER_PROVENANCE               (if AC21 still contains placeholder text)
HALT_FORWARD_HANDOFF_MUTATION             (if AC19 HANDOFF SHA256 != baseline at C4)
HALT_FORWARD_EVIDENCE_MUTATION            (if AC18 evidence SHA set != baseline at C4)
HALT_F14_FALSE_DENIAL                      (if AC20 not recorded as ACKNOWLEDGED)
HALT_ANCESTOR_TRAILER_MUTATION_ATTEMPT    (if CORRECTION01 attempts to mutate DELEGATE01 commit messages)
```

---

# 11. Reviewer feedback acknowledgments

This ACT body was revised in response to binding observations from
the external Factory reviewer. Two rounds of corrections have been
applied.

## Round 1 (resolved in commit `b73fe6b`)

1. **Trailer-repair geometry was structurally impossible**: a new
   commit cannot mutate ancestor commit messages. CORRECTION01
   therefore targets its own C0..C4 range, not DELEGATE01's
   historical commits. DELEGATE01 trailer geometry is acknowledged
   as `IMMUTABLE_FAIL_ACK`.

2. **Closed HANDOFF mutation was F14-improper**: the C3 F14 contract
   treats evidence and HANDOFF surfaces as immutable post-C4. The
   reviewer verdict is recorded in CORRECTION01 evidence, not by
   mutating the closed DELEGATE01 HANDOFF.

## Round 2 (resolved in the final pre-C0 revision commit)

3. **ENTRY_HEAD contradiction**: the round-1 ACT body still froze
   `ENTRY_HEAD = 8393d4d` even though the ACT body itself lived at
   `b73fe6b`. C0 would have started after `b73fe6b` and could not
   have satisfied AC01 as written. Fixed by:

   - AC01 now reads `ENTRY_HEAD = authorization revision HEAD;
     C0 is the first new commit after the revision commit, NOT a
     modification of any prior commit`.
   - The two C0-named evidence files originally committed in
     `b73fe6b` (created while the round-1 ACT body was still
     incorrect) have been reclassified as **pre-C0/revision
     snapshots** and moved into `evidence/.../CORRECTION01/pre-c0/`.
     Real C0 evidence will be produced under the corrected ACT body.

4. **HANDOFF delta ambiguity**: the round-1 wording `DELEGATE01_HANDOFF_DELTA = 0`
   conflated two different facts (the post-mortem mutation, which
   is historical F14 damage, and the forward invariant during
   CORRECTION01). Fixed by:

   - `DELEGATE01_HANDOFF_HISTORICAL_F14_VIOLATION = ACKNOWLEDGED`
     (truthful record of the `8393d4d` mutation; cannot be undone
     because append-only is enforced from `baf5dbd7` forward).
   - `DELEGATE01_HANDOFF_SHA256_AT_CORRECTION01_ENTRY = <sha>`
     (frozen baseline in `pre-c0/pre-c0-delegate01-handoff-sha-baseline.txt`).
   - `DELEGATE01_HANDOFF_DELTA_SINCE_CORRECTION01_ENTRY = 0`
     (the actionable forward invariant; verifiable by re-hashing the
     HANDOFF at C4 and comparing to the frozen baseline).
   - AC18 / AC19 rewritten to refer to the frozen baselines
     rather than to the historical C4 close.
   - AC20 added to record the historical mutation as
     `ACKNOWLEDGED_F14_VIOLATION` (so we never falsely claim
     "HANDOFF delta = 0 against the original C4 close").

All four defects are now corrected in this ACT body. The board
signal is: `CORRECTION01 = AUTHORIZATION_READY_FOR_C0`.

---

# 12. Recommended next ACT after CORRECTION01 PASS

```text
NEXT = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

The parser-padding slice is the first PolyC production-authority
component; the slice-recon ACT can begin with confidence after
CORRECTION01 PASS.
