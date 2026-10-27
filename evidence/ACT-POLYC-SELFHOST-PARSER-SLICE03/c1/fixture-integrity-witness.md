# Fixture-integrity witness — ACT-POLYC-SELFHOST-PARSER-SLICE03

**Tool:** `tools/quality/parser-slice03-fixture-integrity.HC` (PolyC)
**Fixture:** `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/c1/fixture-model.tsv`
**Fixture SHA-256:** `f4ca809004bb16f04c9532a8e3d044da83cab5fa93557fb7e625f4d587ece5ee`
**Mandatory rows:** 98

---

## 1. Why a separate witness is required

`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03` reproduced a **metadata
bypass** in the closed control-flow-token qualification tool: an
**indented unknown fixture row** was silently skipped, the unknown-id
ledger never saw it, and the differential reported `STATUS=PASS`.

That tool is closed evidence under F14 and MUST NOT be reused as the
sole proof authority for adversarial fixture completeness.

This witness therefore uses a **different counting path** from the
differential's row classification:

| | differential | this witness |
|---|---|---|
| row classification | a **contextual state machine** (comment / KEY=VALUE / indented continuation of an OPEN metadata block) | **none** |
| row test | state-dependent | the **first four bytes** of the record, against a fixed id pattern |
| traversal | line-oriented, with metadata-block state | a **whole-file byte scan**, record by record |

The two paths share **no code** and no decision.

---

## 2. What the witness establishes

1. the **exact number** of fixture rows that were executed;
2. the **exact set** of canonical fixture ids observed;
3. that an **unknown or additional row is REJECTED**, not skipped;
4. that a **dropped** row is detected as a missing id;
5. that a **duplicate** id is detected.

The witness exits with RC=0 only when **all** of the following hold:

```text
observed_rows      == expected_rows
distinct_ids       == expected_rows
missing_ids        == 0
unknown_ids        == 0
duplicate_ids      == 0
unknown_rows       == 0
```

---

## 3. The positive run

```text
$ ./build/parser-slice03-fixture-integrity \
      evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/c1/fixture-model.tsv 98

FIXTURE_INTEGRITY_OBSERVED_ROWS=98
FIXTURE_INTEGRITY_DISTINCT_IDS=98
FIXTURE_INTEGRITY_EXPECTED_ROWS=98
FIXTURE_INTEGRITY_NONFIXTURE_RECORDS=9
FIXTURE_INTEGRITY_UNKNOWN_IDS=0
FIXTURE_INTEGRITY_DUPLICATE_IDS=0
FIXTURE_INTEGRITY_MISSING_IDS=0
FIXTURE_INTEGRITY_UNKNOWN_ROWS=0
STATUS=PASS
```

Exit code 0.  The 9 non-fixture records are the comment header lines
of the fixture file.

---

## 4. The negative controls

All four controls are **executed**, and all four **fire**.  A witness
that cannot fail is not a witness.

### NC-1 — an unknown fixture id (`X001`)

```text
FIXTURE_ROW_UNKNOWN at record 108
FIXTURE_INTEGRITY_UNKNOWN_ROWS=1
STATUS=FAIL
```

Exit code 1.  The row is **rejected**, not skipped.

### NC-2 — an additional out-of-range id (`F099`)

```text
FIXTURE_ID_UNKNOWN=99
FIXTURE_INTEGRITY_OBSERVED_ROWS=99
FIXTURE_INTEGRITY_DISTINCT_IDS=98
FIXTURE_INTEGRITY_UNKNOWN_IDS=1
STATUS=FAIL
```

Exit code 1.  The id has the canonical shape but is out of range, so it
is rejected by the **range** check rather than the shape check.

### NC-3 — a dropped row (`F050` removed)

```text
FIXTURE_INTEGRITY_OBSERVED_ROWS=97
FIXTURE_INTEGRITY_MISSING_IDS=1
STATUS=FAIL
```

Exit code 1.  A fixture that silently lost a row cannot pass.

### NC-4 — an **indented** unknown row (the exact RECON03 bypass class)

```text
FIXTURE_ROW_UNKNOWN at record 108
FIXTURE_INTEGRITY_UNKNOWN_ROWS=1
STATUS=FAIL
```

Exit code 1.  **This is the bypass that
`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03` reproduced.**  The witness
treats an indented row as an UNKNOWN ROW unless it is a comment,
because the indented-continuation rule is precisely the rule that let
the bypass through.

---

## 5. Why the indented row is not a recognized non-data record

The witness recognizes exactly two non-data record forms:

```text
COMMENT    the record begins with '#'
METADATA   an '=' occurs in the FIRST field, before the first TAB
```

The `'='` test is scoped to the first field because a data row's
rationale may legitimately contain an `'='` (for example
`tok == NULL returns 0`), so scanning the whole record would
misclassify a data row as metadata.

An **indented** row is deliberately **not** recognized.  The
indented-continuation rule is what allowed the bypass, and accepting
it here would re-open the very hole this witness exists to close.

---

## 6. The frozen fixture contract

```text
EXPECTED_FIXTURE_IDS     F001 .. F098
EXPECTED_FIXTURE_COUNT   98
FIXTURE_SCHEMA           01 fixture_id
                         02 partition
                         03 punct_value
                         04 expected
                         05 rationale
FIXTURE_SOURCE_SHA256    f4ca809004bb16f04c9532a8e3d044da83cab5fa93557fb7e625f4d587ece5ee
```

Every row's `expected` value is the precedence the **derived table**
gives the value, so the fixture cannot carry a hand-authored
expectation that disagrees with the live `src/prslib.c`.

```text
FIXTURE_INTEGRITY = PASS
NEGATIVE_CONTROLS = 4/4 FIRE
```
