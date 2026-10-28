# ACT-POLYC-SELFHOST-PARSER-SLICE05 -- C1 FIXTURE-INTEGRITY CONTRACT

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** fixture-integrity-contract

## 1. The two verifiers, and why they are separate

| Tool | Role |
|---|---|
| `tools/quality/parser-slice05-fixture-producer.HC` | WRITES the fixture |
| `tools/quality/parser-slice05-fixture-integrity.HC` | CHECKS the fixture |

The witness uses a **DIFFERENT COUNTING PATH** from the producer:

* the producer emits rows through a single emitter;
* the witness scans the file with a **WHOLE-FILE BYTE SCAN** that has
  **NO state machine at all**.  It walks the file record by record and
  tests each record's first bytes against the fixture-id PATTERN
  (`'F'` + three decimal digits).  A record that matches is a fixture
  row; a record that does not match is a non-fixture record and is
  accepted only when it is a **recognized** non-data record (a comment
  or a known metadata row).

An **INDENTED unknown row** does not match the id pattern, so it is
counted as a non-fixture record; it is neither a comment nor a metadata
row, so it is an **UNKNOWN RECORD** and a **FAILURE**.  It cannot
disappear silently.

## 2. The expected sets are written INDEPENDENTLY

The witness does **not** re-run the producer's partition logic.  Its
expected accepted-token set, expected rejected-value set, and expected
partition-name set are written **in the witness's own source**.

Therefore an omission in the producer is **detected**, not mirrored.

## 3. The required predicates

```text
EXPECTED_ID_SET=OBSERVED_ID_SET
EXPECTED_VALUE_SET=OBSERVED_VALUE_SET
EXPECTED_PARTITIONS=OBSERVED_PARTITIONS

DUPLICATE_IDS=0
MISSING_IDS=0
UNKNOWN_IDS=0

MALFORMED_ROWS=0
INVALID_I64_VALUES=0
UNTESTED_ACCEPTED_TOKENS=0

UNTESTED_FAILURE_STORAGE_CASES=0
```

Plus the two the ACT's text implies and this ACT adds:

```text
FAILURE_OVERWRITE_CASES=0
MISSING_PARTITIONS=0
EXTRA_PARTITIONS=0
OUT_OF_RANGE_IDS=0
UNKNOWN_RECORDS=0
```

* **FAILURE_OVERWRITE_CASES** -- the number of fixture rows whose
  `expected_success` is `0` but whose `expected_output` is **not**
  equal to their `initial_output`.  Such a row would claim that a
  failed lookup overwrites the caller's storage, which is exactly the
  property the legacy function does NOT have.
* **MISSING_PARTITIONS / EXTRA_PARTITIONS** -- the expected partition
  set is compared as a SET, so a renamed partition, a dropped
  partition, and an invented partition are all detected.

## 4. The exact-64-bit requirement

The witness parses every numeric field with an **exact** signed 64-bit
conversion whose magnitude is accumulated NEGATIVE, so `INT64_MIN` is
representable without an intermediate positive overflow.

**A "%d" conversion is used nowhere.**  It is a 32-bit conversion: it
prints `INT64_MIN` as `0` and `INT64_MAX` as `-1`.

### The literal trap, measured

The literal `-9223372036854775808` does **not** evaluate to `INT64_MIN`
in this language:

```text
I64 a = -9223372036854775808;     ->  -9223372036854775807
I64 d = -9223372036854775807 - 1; ->  -9223372036854775808
```

The positive magnitude `9223372036854775808` is one past `INT64_MAX`,
so the parser's constant folding wraps it to `INT64_MIN` and the unary
minus then wraps it **back**.  The exact form is therefore:

```text
#define NEG_MIN_2P63 (-9223372036854775807 - 1)
```

This defect was **found by running the verifier against the real
fixture**, not by inspection: the verifier rejected the legitimate
`INT64_MIN` row.  The same trap was independently found in the fixture
producer, where it had made the boundary row read `-9223372036854775807`
instead of `-9223372036854775808`.

## 5. The frozen result

```text
FIXTURE_INTEGRITY_OBSERVED_ROWS=346
FIXTURE_INTEGRITY_EXPECTED_ROWS=346
FIXTURE_INTEGRITY_NON_DATA_RECORDS=1
FIXTURE_INTEGRITY_UNKNOWN_RECORDS=0
FIXTURE_INTEGRITY_DUPLICATE_IDS=0
FIXTURE_INTEGRITY_MISSING_IDS=0
FIXTURE_INTEGRITY_OUT_OF_RANGE_IDS=0
FIXTURE_INTEGRITY_UNKNOWN_IDS=0
FIXTURE_INTEGRITY_MALFORMED_ROWS=0
FIXTURE_INTEGRITY_INVALID_I64_VALUES=0
FIXTURE_INTEGRITY_UNTESTED_ACCEPTED_TOKENS=0
FIXTURE_INTEGRITY_UNTESTED_FAILURE_STORAGE_CASES=0
FIXTURE_INTEGRITY_FAILURE_OVERWRITE_CASES=0
FIXTURE_INTEGRITY_MISSING_PARTITIONS=0
FIXTURE_INTEGRITY_EXTRA_PARTITIONS=0
FIXTURE_INTEGRITY_OBSERVED_DISTINCT_VALUES=150
FIXTURE_INTEGRITY_OBSERVED_PARTITIONS=13
FIXTURE_INTEGRITY_EXPECTED_PARTITIONS=13
FIXTURE_INTEGRITY_STATUS=PASS
```

## 6. The differential's own fail-closed contract

The differential (`tools/quality/parser-slice05-differential.HC`) is
also fail-closed, and it is a **DIFFERENT tool** from the witness:

* a row that cannot be parsed is a **FAILURE**, never a silent skip;
* a non-data line that is neither a comment nor a metadata row is a
  `SLICE05_DIFF_PARSE_ERROR` and a **FAILURE**;
* an id outside `1..expected_count` is an **OUT-OF-RANGE ID** and a
  **FAILURE**;
* the EXACT canonical id set must be present, each id exactly once.

The differential compares **three sources** on every row:

```text
LEGACY_SUCCESS  = POLYC_ADAPTER_SUCCESS
LEGACY_OUTPUT   = POLYC_ADAPTER_OUTPUT
LEGACY_OUTPUT   = EXPECTED_OUTPUT
POLYC_OUTPUT    = EXPECTED_OUTPUT
```

so an equally wrong fixture cannot mask a disagreement between the
PolyC component and the production oracle, and a broken oracle cannot
mask a disagreement either.

```text
DIFFERENTIAL_MISMATCHES=0
ORACLE_EXPECTED_MISMATCHES=0
POLYC_EXPECTED_MISMATCHES=0
OUTPUT_PRESERVATION_FAILURES=0
```

## 7. The frozen differential result

```text
SLICE05_DIFF_TOTAL=346
SLICE05_DIFF_PASS=346
SLICE05_DIFF_FAIL=0
SLICE05_DIFF_PARSE_ERRORS=0
SLICE05_DIFF_FIELD_PARSE_ERRORS=0
SLICE05_DIFF_ORACLE_VS_EXPECTED_MISMATCH=0
SLICE05_DIFF_POLYC_VS_EXPECTED_MISMATCH=0
SLICE05_DIFF_OUTPUT_PRESERVATION_FAILURES=0
SLICE05_DIFF_ENUM_MAPPING_MISMATCHES=0
SLICE05_DIFF_UNKNOWN_IDS=0
SLICE05_DIFF_DUPLICATE_IDS=0
SLICE05_DIFF_MISSING_IDS=0
SLICE05_DIFF_MALFORMED_ROWS=0
SLICE05_DIFF_TRUNCATED_ROWS=0
SLICE05_DIFF_OUT_OF_RANGE_IDS=0
SLICE05_DIFF_EXPECTED_ROW_COUNT=346
SLICE05_DIFF_STATUS=PASS
```
