# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair the remaining indented-row recognition bypass in the
direct differential, and record truthfully the terminality / F14
discrepancy found in the review of
`ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01`

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** CORRECTION / QUALIFICATION-HARDENING

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01`
(closed `PASS`)

**Predecessor effective disposition:** `PASS_WITH_NONBLOCKING_RESIDUE`
(the predecessor's engineering result stands; its CLOSURE is narrowed,
not reversed, by this ACT)

**Successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## 0. Mission

Close the one remaining, source-level, reproducible qualification gap
that the review of the predecessor ACT found: the repaired row
recognizer in `tools/quality/parser-control-flow-token-differential.HC`
still treats **any** indented line as a skippable metadata continuation,
without requiring that a metadata block is actually in scope. An
indented unknown-fixture row is therefore still silently invisible to
the unknown-ID ledger, and the differential returns `STATUS=PASS`.

This ACT ALSO records, truthfully and without mutating any closed
evidence, the terminality discrepancy that the predecessor's two
post-CLOSE commits introduced:

```text
post-CLOSE commits that added a file to the CLOSED evidence directory
  = bc1d2d3 (adds c3/terminality.txt)
  = 638e2e0 (rewrites c3/terminality.txt)
```

Those commits are historical evidence under F14. They are NOT rewritten,
NOT reverted, and NOT amended. This ACT records the violation and the
correct terminality geometry in its OWN evidence namespace.

Nothing else.

---

## 1. Why

The review of the predecessor ACT established three facts against the
real seams.

### 1.1 The engineering result stands

The two original findings are repaired:

- the unknown-fixture-ID bypass is closed for a row that is a
  *recognizable* data row (`X001`, `Z999`, `F01`);
- the LEXER07 broad corpus was executed and compared, source by source,
  against the frozen baseline registry, with zero new failure
  identities and zero removed pass identities.

The production PolyC authority is unchanged.

### 1.2 P0 -- the closure is not clean (REPRODUCED)

The predecessor's committed history is:

```text
fb85cff  C4 CLOSE -- PASS
bc1d2d3  Record external terminality check
638e2e0  Correct the terminality artifact
```

`HEAD` is `638e2e0`, not the CLOSE commit. The two trailing commits
are not ACT continuations (they carry no `ACT:` trailer), but that is
irrelevant to the question asked: **was the closed evidence tree
modified after closure?** The answer is mechanically yes:

```sh
git diff --name-status fb85cff..HEAD \
  -- evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/
```

```text
A	evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/c3/terminality.txt
```

That is an ADDITION to the closed evidence directory after the CLOSE
commit. It conflicts with:

- the predecessor ACT's section 7, "Do not append a post-CLOSE metadata
  or whitespace fixup commit"; and
- the strict F14 reading in `docs/factory/DOCTRINE.md` section 22
  ("Strict F14 reading for corrections"), which forbids mutating any
  artifact in a closed ACT's evidence directory.

`git interpret-trailers --parse` establishes only whether a commit
message carries recognizable trailers. It does not establish whether a
closed evidence tree was modified.

### 1.3 P1 -- the indented-row recognition bypass (REPRODUCED)

The predecessor's repair introduced a POSITIVE recognition test. Its
metadata clause is:

```text
if (line[0] == ' ' || line[0] == '\t') return 1;
```

This accepts ANY indented line as a metadata continuation, without
confirming that a metadata block is in scope. An indented unknown
fixture row is therefore still skipped before the unknown-ID ledger
runs. Measured against the real differential binary:

```sh
# 42 canonical rows, with "  X001\tUNKNOWN\t..." inserted between F020 and F021
./build/parser-control-flow-token-differential /tmp/ind_x001.tsv
```

```text
SLICE02_DIFFERENTIAL_OBSERVED_FIXTURE_COUNT=42
SLICE02_DIFFERENTIAL_UNKNOWN_IDS=0
STATUS=PASS
```

The differential returns PASS for a fixture holding an unknown fixture
ID. This is the SAME defect class the predecessor ACT was opened to
repair, narrowed from "any unrecognized row" to "any indented
unrecognized row".

### 1.4 P1 -- a recorded evidence block that its own command does not produce

The review observed that the predecessor's recorded `NC-D12` block
reports `TOTAL=42`, which is inconsistent with "42 canonical rows plus
a 43rd row". The reviewer's inference was that the appended text may
have joined the last existing row.

That inference is **not** the cause, and this ACT records the actual
cause, because the evidence must be truthful either way. The recorded
command is:

```text
COMMAND={ cat $FIXTURE_CANONICAL; printf 'X001\t...\n'; } > /tmp/nc_d12.tsv
```

Run against the canonical fixture, that command produces
`TOTAL=43, PASS=42, MISSING_IDS=0, FIXTURE_IDS_COMPLETE=1`. The
RECORDED output is `TOTAL=42, PASS=41, MISSING_IDS=1,
FIXTURE_IDS_COMPLETE=0`. Those signatures are not the same.

The recorded output is reproducible ONLY from a base fixture that is
already missing one canonical id (41 rows, `F042` absent). Reproduced
exactly:

```sh
grep '^F[0-9][0-9][0-9]' <canonical> | grep -v '^F042' > /tmp/base41.tsv
{ cat /tmp/base41.tsv; printf 'X001\tUNKNOWN\t1\t1\t1\t1\tnc-d12\tnc-d12\n'; } > /tmp/hyp.tsv
./build/parser-control-flow-token-differential /tmp/hyp.tsv
```

```text
SLICE02_DIFFERENTIAL_TOTAL=42
SLICE02_DIFFERENTIAL_PASS=41
SLICE02_DIFFERENTIAL_MISSING_IDS=1
SLICE02_DIFFERENTIAL_UNKNOWN_IDS=1
SLICE02_DIFFERENTIAL_FIXTURE_IDS_COMPLETE=0
SLICE02_DIFFERENTIAL_FIXTURE_SCHEMA_VALID=0
REASON=FIXTURE_ID_UNKNOWN
STATUS=FAIL
```

So the recorded block is a truthful measurement of a DIFFERENT input
than the recorded command states. The recorded output is not
fabricated; the recorded command line does not describe it. The
reviewer's suspicion that the block was not what it claims to be is
correct, and the specific defect is an evidence-truth defect in the
C2 block, not a row-joining defect.

This does NOT change the predecessor's conclusion: the unknown-ID
bypass IS repaired, and the corrected NC-D12 measurement is
`TOTAL=43, UNKNOWN_IDS=1, REASON=FIXTURE_ID_UNKNOWN`. It DOES mean
the predecessor's `c2/p0-fixture-integrity.txt` block "GREEN 2"
cannot be cited as a measurement of the canonical fixture. That file
is closed evidence and is NOT modified by this ACT.

### 1.5 P1 -- `EditAppendLine()` does not separate the appended row

`tools/quality/parser-control-flow-token-negative-controls.HC`
appends at `g_src_len` without inserting a separating newline:

```text
U0 EditAppendLine(U8 *text)
{
  g_cut_a = g_src_len;
  g_cut_b = g_src_len;
  ...
  g_repl[tl] = '\n';
```

If the source does not end with a newline, the appended row joins the
last existing row. The canonical fixture DOES end with a newline
(`0x0a`), so the driver's controls are unaffected today. The source
risk is real and is repaired by this ACT so that the control driver
cannot silently produce a merged row.

---

## 2. Scope

### Allowed production and qualification files

```text
tools/quality/parser-control-flow-token-differential.HC
```

### Allowed test/tooling files

```text
tools/quality/parser-control-flow-token-negative-controls.HC
```

### Allowed evidence and lifecycle files

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02.md
docs/factory/act-handoff-map.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/**
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
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/**
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01/**
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/**
```

The predecessor's evidence directory is READ-ONLY under F14. This ACT's
evidence lives in its own directory.

### Forbidden

- modifying any file under `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/`;
- amending, rebasing, reverting or force-pushing any commit;
- changing the production PolyC control-flow-token component or its
  delegation;
- changing any parser, lexer, LLVM, AST or recovery semantics;
- changing the canonical fixture model;
- preselecting or opening `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`;
- adding a dependency.

---

## 3. Entry gate

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -8 --format='%H %s'
git replace -l
```

Required state:

- on `main`;
- worktree clean;
- `git replace -l` empty.

Observed at C0 (`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c0/entry-identity.txt`).

---

## 4. Principal RED

Two REDs, both against the real seam, neither a mock.

### RED A -- the indented-row bypass

An unknown fixture ID that is indented is silently skipped and the
differential returns `STATUS=PASS` with `UNKNOWN_IDS=0`.

### RED B -- the F14 / terminality violation

```sh
git diff --name-status <CLOSE>..HEAD \
  -- evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/
```

returns a non-empty `A` entry.

RED witnesses live in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c0/`.

---

## 5. Required implementation shape

### 5.1 Metadata-block context (Gap A)

An indented line MAY be skipped ONLY when a metadata block is actually
in scope. The metadata block is entered by a recognized `KEY=VALUE`
metadata row and continues through its indented continuation rows.

The implementation MUST:

- keep the comment-row recognition (`#`) exactly as it is;
- keep the `KEY=VALUE` first-field recognition exactly as it is;
- require an ACTIVE metadata block for the indented-continuation
  recognition, so that an indented line which does not continue a
  metadata block is a DATA row and MUST be validated;
- remain in PolyC;
- NOT weaken any existing clause of the acceptance predicate.

Every existing rejection reason (`FIXTURE_ID_SET_INCOMPLETE`,
`FIXTURE_SCHEMA_INVALID`, `ORACLE_VS_EXPECTED_MISMATCH`,
`SUBJECT_VS_ORACLE_MISMATCH`, `FIXTURE_SET_EMPTY`,
`FIXTURE_COUNT_MISMATCH`) MUST remain reachable, and
`FIXTURE_ID_UNKNOWN` MUST remain reachable.

The canonical fixture's metadata block (`FIXTURE_COUNT=42`,
`PARTITION_COUNT=6` followed by indented continuations, and the
`ACCEPT_BREAKDOWN` / `REJECT_BREAKDOWN` blocks) MUST continue to be
recognized, so the canonical fixture still returns `STATUS=PASS`.

### 5.2 Row separation in the control driver (Gap C)

`EditAppendLine()` MUST NOT join the appended row to an unterminated
last line. It MUST emit a separating newline when the source does not
already end with one.

### 5.3 Terminality and F14 recording (Gap B)

This ACT MUST record:

- the exact `git diff --name-status` output that establishes the
  post-CLOSE addition to the closed evidence directory;
- the fact that the two post-CLOSE commits are historical evidence and
  are NOT rewritten;
- the correct terminality geometry for THIS ACT: the CLOSE commit is
  the last commit of this ACT's contiguous range, and no commit after
  it carries this ACT's `ACT:` trailer.

It MUST NOT edit the predecessor's closed evidence.

---

## 6. Acceptance criteria

Each AC MUST be checkable by a single concrete command.

| ID   | Criterion | Status |
|------|-----------|--------|
| AC01 | An indented unknown row between F020 and F021 MUST be rejected with `REASON=FIXTURE_ID_UNKNOWN` | DEFERRED_TO_C1 |
| AC02 | The same for a TAB-indented unknown row | DEFERRED_TO_C1 |
| AC03 | The 42-row canonical fixture MUST still return `STATUS=PASS` | DEFERRED_TO_C1 |
| AC04 | A valid 42-row fixture in SHUFFLED order MUST still return `STATUS=PASS` (NC-D8) | DEFERRED_TO_C1 |
| AC05 | The canonical fixture's indented metadata continuations MUST still be recognized (canonical fixture is AC03's witness) | DEFERRED_TO_C1 |
| AC06 | All 16 existing negative controls MUST still behave as specified, with 0 broken | DEFERRED_TO_C1 |
| AC07 | A NEW control for the indented unknown row MUST FAIL with `FIXTURE_ID_UNKNOWN` | DEFERRED_TO_C1 |
| AC08 | A NEW control for an appended row on a NON-newline-terminated source MUST observe a separate row | DEFERRED_TO_C1 |
| AC09 | `make parser-control-flow-token-int-bounds` MUST still pass | DEFERRED_TO_C1 |
| AC10 | The production PolyC component and its delegation MUST be UNCHANGED | DEFERRED_TO_C1 |
| AC11 | The F14 violation MUST be recorded with the exact `git diff --name-status` output | DEFERRED_TO_C1 |
| AC12 | The predecessor's closed evidence directory MUST be byte-identical to its state at the predecessor's CLOSE commit | DEFERRED_TO_C1 |
| AC13 | `make gate-fast` MUST pass | DEFERRED_TO_C1 |
| AC14 | `make gate-push` MUST pass | DEFERRED_TO_C1 |
| AC15 | F-NO-PYTHON: no new Python sources or invocations | DEFERRED_TO_C1 |
| AC16 | F-POLYC-TOOLS: new tools are PolyC, shell only as <=50-LOC dispatch glue | DEFERRED_TO_C1 |
| AC17 | Committed-range patch hygiene clean | DEFERRED_TO_C1 |
| AC18 | HANDOFF present and valid | DEFERRED_TO_C1 |
| AC19 | The terminality check MUST be run against this ACT's own CLOSE commit | DEFERRED_TO_C1 |
| AC20 | No commit after this ACT's CLOSE may carry this ACT's `ACT:` trailer | DEFERRED_TO_C1 |

---

## 7. HALT taxonomy

```text
HALT_ENTRY_IDENTITY_INVALID
HALT_RED_NOT_REPRODUCED
HALT_SCOPE_CONTRACT_VIOLATED
HALT_UNAUTHORIZED_PRODUCTION_MUTATION

HALT_UNKNOWN_FIXTURE_ID_STILL_ACCEPTED
HALT_FIXTURE_RECOGNITION_REGRESSION
HALT_NEGATIVE_CONTROL_NOT_LOAD_BEARING

HALT_PRODUCTION_AUTHORITY_REGRESSION
HALT_CONSERVATION_REGRESSION
HALT_FACTORY_GATE_NOT_GREEN
HALT_F14_VIOLATION
HALT_MANDATORY_AC_NOT_GREEN
```

---

## 8. Terminality and verdict

For successful closure:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

Use a single contiguous terminal trailer block accepted by the live
Factory-v2 validator. After committing CLOSE, run:

```sh
git status --porcelain=v1

git diff --check <ENTRY_HEAD>..HEAD

sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02 HEAD

git log -1 --format='%B' |
  git interpret-trailers --parse
```

Do not append a post-CLOSE metadata or whitespace fixup commit, and do
not add a file to this ACT's own evidence directory after the CLOSE
commit. This ACT's terminality evidence is recorded BEFORE the CLOSE
commit, in its own C3 phase, and the CLOSE commit is the last commit
of the ACT's range.

---

## 9. Next ACT

Upon successful qualification:

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
```

The next reconnaissance must use the actual new parser authority state.
Do not open RECON03 within this ACT or preselect its winner.

---

## 10. Explicit execution instruction

Execute the full bounded ACT: reproduce the indented-row bypass as a
real RED witness, repair the metadata-block recognition so an indented
unrecognized row is validated, repair the control driver's row
separation, record the F14 / terminality violation truthfully in this
ACT's own evidence namespace without touching the closed evidence, and
close through Factory v2.

**Prioritize executable correctness over documentation elaboration.**
