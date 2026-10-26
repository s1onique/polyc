# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Close the two bounded qualification gaps found in the review of
`ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01` -- the fixture-row bypass that
lets an unknown fixture ID be silently ignored, and the missing
LEXER07 broad-corpus conservation witness

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** CORRECTION / QUALIFICATION-HARDENING

**Priority:** P0 -- the P0 gap is a source-level false-PASS defect in a
qualification gate that the predecessor ACT claimed FAIL-CLOSED

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01` (closed `PASS`)

**Predecessor effective disposition:** `PASS_WITH_NONBLOCKING_RESIDUE`
(the predecessor's PASS is narrowed, not reversed, by this ACT)

**Successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`

**Entry HEAD:** `4113123fbc766d966244d0d22d5d088247d79a48`
(the predecessor's CLOSE commit)

---

## 0. Mission

Repair the two concrete, narrowly testable gaps identified in the review of
the predecessor ACT. Nothing else.

### Gap P0 (source-level defect, FAIL-CLOSED violation)

The predecessor ACT's central claim is that the direct differential has a
FAIL-CLOSED fixture-integrity contract:

```text
DIFFERENTIAL_FIXTURE_AUTHORITY = COMPLETE
```

That claim is **false for rows whose ID does not begin with `F` followed by
a digit**. In `tools/quality/parser-control-flow-token-differential.HC`
the row reader is:

```text
if (line[0] != 'F') continue;
if (line[1] < '0' || line[1] > '9') continue;
```

Any row that fails this test is skipped **before** the unknown-ID
accounting runs. Consequently a fixture consisting of the 42 canonical rows
**plus** an unknown row such as `X001` is accepted with
`STATUS=PASS`, `SLICE02_DIFFERENTIAL_UNKNOWN_IDS=0`,
`SLICE02_DIFFERENTIAL_OBSERVED_FIXTURE_COUNT=42`.

This directly contradicts the frozen requirement that unknown fixture IDs
must be rejected, and it contradicts the predecessor ACT's own C1 negative
control `NC-D12` ("a fixture id that is not F### (e.g. X001)" -> `FAIL`,
`FIXTURE_ID_UNKNOWN`), which was specified in C1 but **never executed** in
C3. The C3 negative-control evidence shows NC-D1..NC-D7, NC-D9 and NC-D11
only; `NC-D12` is absent.

### Gap P1 (conservation evidence, wrong test population)

The predecessor ACT's `c3/lexer07-conservation.txt` records:

```text
COMMAND=make gate-push
CHECK=lsp STATUS=PASS
lsp: 43/43 passed

LEXER07_FAILURE_SOURCES=NONE
LEXER07_TOTAL=43
LEXER07_FAILED=0
LEXER07_NEW_FAILURES=0
```

The LSP suite and the LEXER07 four-generation broad corpus are **different
test populations**. The broad corpus is the one governed by the canonical
authority registry `docs/factory/LEXER07-BASELINE-AUTHORITY.tsv`, which
records **21 known failures** in the frozen prospective baseline:

```text
PROSPECTIVE_BASELINE_RUN_A_COUNTER_TEXT=PASS_S0=166 HISTORICAL_S0=0 PASS_S1=175 PASS_S2=175 PASS_S3=175
PROSPECTIVE_BASELINE_RUN_A_FAILURE_COUNT=21
```

Therefore the predecessor's broad AC30 claim ("zero new parser or lexer
failures") is **not established** by the LSP-only witness. The LSP witness
supports what it actually measures -- LSP conservation -- and that is
retained. What is missing is the broad-corpus measurement.

### Non-goals

This ACT does NOT:

- reopen the predecessor's five-commit history;
- rewrite the predecessor's historical prose or evidence;
- change the production PolyC control-flow-token component or its
  delegation;
- change any parser, lexer, LLVM, AST or recovery semantics;
- preselect or open `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`.

---

## 1. Entry identity

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -8 --format='%H %s'
git replace -l
```

Observed at C0 (`evidence/.../c0/entry-identity.txt`):

```text
BRANCH                        = main
ENTRY_HEAD                    = 4113123fbc766d966244d0d22d5d088247d79a48
WORKTREE_CLEAN                = YES (no tracked-file modification)
GIT_REPLACE_REFS              = 0
PREDECESSOR_CLOSE_REACHABLE   = YES
ACTIVE_CONFLICTING_FACTORY_ACT= NONE
```

---

## 2. Scope

### Allowed production and qualification files

```text
tools/quality/parser-control-flow-token-differential.HC
```

### Allowed test/tooling files

```text
tools/quality/parser-control-flow-token-negative-controls.HC   (NEW: PolyC negative-control driver)
Makefile                                                        (target for the negative-control driver)
```

### Allowed evidence and lifecycle files

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/**
```

### Read-only surfaces

```text
src/parser.c
src/lexer.h
tools/bootstrap/selfhost-parser-control-flow-token.HC
tools/bootstrap/selfhost-parser-padding.HC
tools/quality/parser-slice02-oracle.c
tools/quality/parser-slice02-oracle.h
tools/quality/parser-control-flow-token-oracle-impl.c
tools/quality/lexer07-broad-corpus-4-stage.HC
tools/quality/lexer07-baseline-authority-verify.HC
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01/**
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/**
```

The predecessor's evidence directory is READ-ONLY under F14. This ACT's
evidence lives in its own directory.

---


## 3. Mandatory acceptance criteria

### Gap P0 -- fixture-row recognition

| ID   | Criterion                                                              | Status |
|------|------------------------------------------------------------------------|--------|
| AC01 | The differential MUST reject a fixture that is the 42 canonical rows PLUS an unknown-ID row `X001` | DEFERRED_TO_C1 |
| AC02 | The rejection MUST be reported as a FIXTURE-INTEGRITY failure, NOT a subject/oracle mismatch | DEFERRED_TO_C1 |
| AC03 | `NC-D12` MUST be executed and recorded, with its reason token | DEFERRED_TO_C1 |
| AC04 | The 42-row canonical fixture MUST still return `STATUS=PASS` | DEFERRED_TO_C1 |
| AC05 | A valid 42-row fixture in SHUFFLED order MUST still return `STATUS=PASS` (NC-D8) | DEFERRED_TO_C1 |
| AC06 | Only EXPLICITLY RECOGNIZED comment and metadata rows may be skipped | DEFERRED_TO_C1 |
| AC07 | Every other row MUST be validated; malformed/unknown rows MUST be counted as failures | DEFERRED_TO_C1 |
| AC08 | All predecessor negative controls (NC-D1..NC-D11) MUST still FAIL as specified | DEFERRED_TO_C1 |
| AC09 | The production PolyC component and its delegation MUST be UNCHANGED | DEFERRED_TO_C1 |
| AC10 | The integer-boundary tool MUST still pass (the `parse_int` verbatim copy is untouched) | DEFERRED_TO_C1 |

### Gap P1 -- LEXER07 broad-corpus conservation

| ID   | Criterion                                                              | Status |
|------|------------------------------------------------------------------------|--------|
| AC11 | The canonical LEXER07 broad-corpus target MUST be EXECUTED, not merely referenced | DEFERRED_TO_C1 |
| AC12 | The observed failure identities MUST be compared against the prospective baseline registry | DEFERRED_TO_C1 |
| AC13 | The baseline failure set and the observed failure set MUST BOTH be recorded | DEFERRED_TO_C1 |
| AC14 | Historical baseline failures MUST NOT be relabeled as PASS | DEFERRED_TO_C1 |
| AC15 | NEW failure identities relative to the registry MUST be 0 | DEFERRED_TO_C1 |
| AC16 | REMOVED pass identities relative to the registry MUST be 0 | DEFERRED_TO_C1 |
| AC17 | The registry MUST be byte-identical before and after (read-only) | DEFERRED_TO_C1 |

### Conservation, gates and lifecycle

| ID   | Criterion                                                              | Status |
|------|------------------------------------------------------------------------|--------|
| AC18 | `make gate-fast` MUST pass | DEFERRED_TO_C1 |
| AC19 | `make gate-push` MUST pass | DEFERRED_TO_C1 |
| AC20 | F14 conservation: no tracked file outside the C1 scope changed | DEFERRED_TO_C1 |
| AC21 | F-NO-PYTHON: no new Python sources or invocations | DEFERRED_TO_C1 |
| AC22 | F-POLYC-TOOLS: new tools are PolyC, shell only as <=50-LOC dispatch glue | DEFERRED_TO_C1 |
| AC23 | Committed-range patch hygiene clean | DEFERRED_TO_C1 |
| AC24 | HANDOFF present and valid | DEFERRED_TO_C1 |
| AC25 | External terminality verified after CLOSE | DEFERRED_TO_C1 |

---


## 4. Required implementation shape (Gap P0)

The row reader MUST distinguish three classes of line:

1. **Recognized comment row** -- the line begins with `#`.
2. **Recognized metadata row** -- the line is a `KEY=VALUE` metadata line,
   or an indented continuation line of the metadata block.
3. **Data row** -- everything else.

Only classes 1 and 2 MAY be skipped. A class-3 line MUST be validated as a
fixture row, and MUST contribute to `total`, `unknown_ids` or
`malformed_rows` / `truncated_rows` as appropriate.

The classification MUST NOT be "starts with `F` followed by a digit",
because that is precisely the bypass being repaired. The
classification MUST be driven by the recognized comment/metadata forms,
so that an unknown ID is a **data row that fails validation** rather than
a row that is never examined.

The implementation MUST remain in PolyC and MUST NOT weaken any existing
clause of the acceptance predicate. Every existing rejection reason
(`FIXTURE_ID_SET_INCOMPLETE`, `FIXTURE_SCHEMA_INVALID`,
`ORACLE_VS_EXPECTED_MISMATCH`, `SUBJECT_VS_ORACLE_MISMATCH`,
`FIXTURE_SET_EMPTY`, `FIXTURE_COUNT_MISMATCH`) MUST remain reachable.

A `FIXTURE_ID_UNKNOWN` reason MUST become reachable for an unknown ID.

---

## 5. Required evidence shape (Gap P1)

The LEXER07 conservation evidence MUST record, as separate facts:

```text
BASELINE_FAILURE_COUNT=<from docs/factory/LEXER07-BASELINE-AUTHORITY.tsv>
BASELINE_FAILURE_IDENTITIES=<the registry's known-failure identities>
OBSERVED_FAILURE_COUNT=<from the executed broad-corpus run>
OBSERVED_FAILURE_IDENTITIES=<from the executed broad-corpus run>
NEW_FAILURE_IDENTITIES=<observed minus baseline>
REMOVED_PASS_IDENTITIES=<baseline passes no longer passing>
```

The broad-corpus run MUST be the canonical target
`make lexer07-broad-corpus-4-stage` (or the equivalent direct invocation
of the same PolyC tool with the same corpus inventory), executed against
the current tree.

If the observed failure set differs from the registry's baseline, the
difference MUST be reported honestly. Historical failures MUST NOT be
relabeled PASS, and observed failures MUST NOT be silently dropped.

If the broad corpus cannot be executed in this environment, the ACT MUST
halt with `HALT_EXTERNAL_CORPUS_UNAVAILABLE` rather than substituting the
LSP suite for it.

---

## 6. HALT taxonomy

```text
HALT_ENTRY_IDENTITY_INVALID

HALT_RED_NOT_REPRODUCED
HALT_SCOPE_CONTRACT_VIOLATED
HALT_UNAUTHORIZED_PRODUCTION_MUTATION

HALT_UNKNOWN_FIXTURE_ID_STILL_ACCEPTED
HALT_FIXTURE_RECOGNITION_REGRESSION
HALT_NEGATIVE_CONTROL_NOT_LOAD_BEARING

HALT_LEXER07_BROAD_CORPUS_NOT_EXECUTED
HALT_LEXER07_NEW_FAILURES_NONZERO
HALT_LEXER07_REMOVED_PASSES_NONZERO
HALT_EXTERNAL_CORPUS_UNAVAILABLE

HALT_PRODUCTION_AUTHORITY_REGRESSION
HALT_CONSERVATION_REGRESSION
HALT_FACTORY_GATE_NOT_GREEN
HALT_F14_VIOLATION
HALT_MANDATORY_AC_NOT_GREEN
```

---

## 7. Terminality and verdict

For successful closure:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

Use a single contiguous terminal trailer block accepted by the live
Factory-v2 validator. After committing CLOSE, run:

```sh
git status --porcelain=v1

git diff --check <ENTRY_HEAD>..HEAD

sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01 HEAD

git log -1 --format='%B' |
  git interpret-trailers --parse
```

Do not append a post-CLOSE metadata or whitespace fixup commit.

---

## 8. Next ACT

Upon successful qualification:

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
```

The next reconnaissance must use the actual new parser authority state.
Do not open RECON03 within this ACT or preselect its winner.

---

## 9. Explicit execution instruction

Execute the full bounded ACT: reproduce the P0 bypass as a real RED
witness, repair the fixture-row recognition, execute the real LEXER07
broad corpus, record both baseline and observed failure identities, and
close through Factory v2.

**Prioritize executable correctness over documentation elaboration.**
