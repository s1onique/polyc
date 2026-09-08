# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01

Factory-Version: 1 (transitional; v2 activation still HALTED)
Lifecycle: AUTHORIZATION_ARTIFACT

## Status

PASS

**Class:** FACTORY / PROCESS / TOOLING (correction)

**Supersedes / corrects:** ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
(mechanical enforcement only; architectural model is accepted)

**Repository:** https://github.com/s1onique/polyc

## 0. Mission (single sentence)

Bind the implemented trailer grammar in the Factory v2
validators to the documented trailer grammar so that
malformed ACT identifiers and ACT-Verdict values cannot
reach `STATUS=PASS` through shell-glob patterns or
pre-validation value rewriting.

## 1. Predecessor gate

The predecessor ACT (ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01)
closed at commit `0c28b7c56567ad4b4ddf4dfeafd2633d8f295454`
with ## Status = PASS for the architectural model and a
reviewer HALT for mechanical enforcement. Its `HANDOFF.md`,
evidence files, validators, doctrine, and templates remain
authoritative for everything they correctly cover.

This correction does NOT redesign v2. It repairs the
implementation to match the documented contract.

## 2. Scope (bounded)

### 2.1 In scope

* `scripts/quality/factory-v2-commit-msg-check.sh`:
  - replace shell-glob `case` patterns for ACT id and
    ACT-Verdict with exact POSIX-ERE regex matches against
    the literal parsed value (no `gsub` normalization);
  - enforce `ACT-Corrected-Verdict` with the same
    regex match used for `ACT-Verdict`.
* `scripts/quality/factory-v2-range-check.sh`:
  - replace shell-glob `case` patterns for ACT id and
    ACT-Verdict with exact POSIX-ERE regex matches.
* `scripts/quality/factory-v2-test.sh`:
  - add negative cases for each false-GREEN RED:
    `ACT-POLYC-AAevil`, `ACT-POLYC-AA/BAD`,
    `ACT-POLYC-AA BAD`, `ACT-Verdict: PASS WITH NEXT`,
    `ACT-Verdict: PASS_X-bad`, `ACT-Verdict: HALT_X/bad`,
    `ACT-Corrected-Verdict: HALT_X bad`;
  - add positive boundary cases:
    `ACT-POLYC-A1`, `ACT-POLYC-LLVM-CORE04`,
    `ACT-POLYC-FOO_BAR-01`, `ACT-Verdict: PASS`,
    `ACT-Verdict: PASS_WITH_NEXT_ACT_DECISION`,
    `ACT-Verdict: HALT_RED_NOT_REPRODUCED`.
* `docs/factory/GIT-METADATA.md`:
  - resolve the "at least two characters" prose vs
    `*`-allows-one-character regex inconsistency.

### 2.2 Out of scope (this ACT will NOT touch)

* `src/`
* compiler build artifacts
* `gate-fast.sh`, `gate-push.sh`
* `factory-closure-status-check.sh`,
  `llvm-closure-status-check.sh`,
  `act-handoff-map.tsv`
* `install-git-hooks.sh`, `.githooks/pre-commit`,
  `.githooks/pre-push`
* legacy v1 ACT/HANDOFF files
* the v1 ACT templates (HANDOFF-TEMPLATE.md,
  ACT-TEMPLATE.md)
* the AGENTS.md Factory-version pointer section
* the FACTORY-STATUS-RECONCILIATION family of ACTs
* the legacy v1 closure-status oracle
  (factory-closure-status)

If any of these turn out to need a change for correctness,
HALT_FACTORY_V2_CORRECTION01_SCOPE_EXPANSION.

## 3. Authoritative contract

The grammar below is binding. Implementation must match
it byte-for-byte against the literal parsed trailer value.

### 3.1 ACT identifier

```text
^ACT-POLYC-[A-Z0-9][A-Z0-9_-]*$
```

NOTE: this is the existing documented contract. The
"at least two characters after the prefix" prose is NOT
enforced at the regex level. To make docs and code agree,
the prose is amended as follows in §6.4 below.

### 3.2 ACT-Verdict

```text
^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
```

### 3.3 ACT-Corrected-Verdict

When `ACT-Supersedes:` is present (CLOSE only), the
corrected verdict uses the same grammar as 3.2.

### 3.4 Cardinality

UNCHANGED from SIMPLIFY01:

* `ACT:`                -- exactly 1
* `ACT-Phase:`          -- exactly 1, value in
                           {RED, IMPL, EVIDENCE, CLOSE}
* `ACT-Verdict:`        -- exactly 0 for
                           RED/IMPL/EVIDENCE;
                           exactly 1 for CLOSE
* `ACT-Supersedes:`     -- 0 or 1, CLOSE only
* `ACT-Corrected-Verdict:` -- 0 or 1, requires
                           ACT-Supersedes, CLOSE only

## 4. Implementation contract

* Use POSIX `grep -Eq` (or `awk` with explicit match) for
  regex. POSIX shell `case` patterns are FORBIDDEN for any
  ACT grammar check.
* Do NOT normalize the parsed value before regex matching.
  Whitespace inside the value is a regex match against the
  literal, not against an underscore-replacement.
* The validator must report STATUS=PASS only when the
  literal value satisfies the regex.
* Existing machine-readable reporting
  (MODE / ACT / PHASE / VERDICT / SUPERSEDES /
  CORRECTED_VERDICT / STATUS) is preserved.
* The validator exit code contract is unchanged:
  STATUS=PASS rc=0, STATUS=FAIL rc=1,
  internal error rc=2.

## 5. Test contract

`scripts/quality/factory-v2-test.sh` must:

* continue to PASS all prior T1..T18 tests
  (no regression);
* add new negative tests, each must FAIL the commit-msg
  check (validator returns STATUS=FAIL rc=1);
* add new positive boundary tests, each must PASS the
  commit-msg check (validator returns STATUS=PASS rc=0).

A regression in any prior T1..T18 case fails this ACT.

## 6. Acceptance criteria

### 6.1 RED-1 (shell-glob ACT id) is gone

For each of the following trailers, the validator must
return STATUS=FAIL rc=1:

    ACT: ACT-POLYC-AAevil
    ACT: ACT-POLYC-AA/BAD
    ACT: ACT-POLYC-AA BAD

### 6.2 RED-2 (gsub normalization) is gone

For each of the following trailers, the validator must
return STATUS=FAIL rc=1 and the reported `ACT` /
`VERDICT` value must equal the literal parsed value (no
underscore rewriting):

    ACT: ACT-POLYC-AA BAD
    ACT-Verdict: PASS WITH NEXT ACT

### 6.3 RED-3 (verdict glob) is gone

For each of the following trailers, the validator must
return STATUS=FAIL rc=1:

    ACT-Verdict: PASS_X-bad
    ACT-Verdict: HALT_X/bad
    ACT-Corrected-Verdict: HALT_X bad

### 6.4 RED-4 (doctrine inconsistency) is gone

`docs/factory/GIT-METADATA.md` section 2.1 is amended so
the prose and the regex agree. This ACT picks option (b):
the ACT id regex becomes

```text
^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$
```

and the "at least two characters after the prefix"
prose is retained (now actually accurate).

A test is added so `ACT-POLYC-A` (single-character suffix)
is rejected by the validator.

### 6.5 Conservative gates

* `git diff --check` rc=0
* `sh scripts/quality/factory-v2-test.sh` STATUS=PASS
  with the new tests
* `sh scripts/quality/factory-v2-commit-msg-check.sh`
  with the existing Factory v2 sample commit messages
  still PASSES (no false-FAIL introduced)
* `sh scripts/quality/gate-fast.sh` rc=0
* `sh scripts/quality/factory-closure-status-check.sh`
  rc=0 (legacy v1 universe still PASS)
* `git diff --name-only <correction-ENTRY>..HEAD -- src/`
  empty
* No modifications to historical ACT/HANDOFF files

## 7. Non-goals

* No numeric commit cap (reaffirmed)
* No SHA tables in ACT documents (reaffirmed)
* No handwritten Markdown identity parser (reaffirmed)
* No persistent identity database (reaffirmed)
* No new dependency (reaffirmed)
* No CI integration (separate ACT)

## 8. HALT conditions

* HALT_FACTORY_V2_CORRECTION01_SCOPE_EXPANSION -- if any
  §2.2 file needs modification for correctness
* HALT_FACTORY_V2_CORRECTION01_PRIOR_TEST_REGRESSION --
  if any T1..T18 prior test begins to fail after the
  implementation change and the regression is not
  explained by an actual prior-test defect

## 9. Topology

This is a v1 transitional ACT because Factory v2
activation is itself HALTED. Topological shape:

  C1 RED     -- 4 RED witness files + ACT contract committed
  C2 IMPL    -- commit-msg-check + range-check fixed,
                test matrix extended
  C3 CLOSE   -- HANDOFF, tests.txt, gate capture,
                ## Status OPEN -> PASS

Three commits total (v1 cap). If a fourth commit is
required, emit
HALT_FACTORY_V2_CORRECTION01_TOPOLOGY.

## 10. NEXT ACT after PASS

After this correction PASSes, Factory v2 activation may
proceed and `ACT-POLYC-LLVM-CORE04` becomes the first
real Factory v2 ACT.

## 11. Activation flag (informational)

After this correction PASSes, the reviewer HALT
`HALT_FACTORY_V2_TRAILER_GRAMMAR_NOT_BOUND` is resolved.
The CLOSE commit message for this ACT SHOULD include a
brief trailer-style summary in its body documenting
which REDs closed and the new test counts.
