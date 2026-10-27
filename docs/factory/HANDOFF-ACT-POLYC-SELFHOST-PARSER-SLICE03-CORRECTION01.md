# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01

Factory-Version: 2

## Result

The qualification authority of SLICE03 is restored.  The **production
migration** is untouched, the **seven historical defects** are recorded
as measured facts, and the fixture contract is requalified to a
semantically complete **123-row** form that carries the signed-I64
extremes it claimed to carry.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.

## What did NOT change

- `BootstrapOperatorPrecedence` remains the **production** authority.
- The legacy `parseGetPriority` algorithm remains **retired** from the
  production path.
- The other two PolyC parser components remain production authorities
  with their live call sites.
- `src/prslib.c`, `src/parser.c`, `src/lexer.c`, `src/CMakeLists.txt`
  and the three qualified PolyC parser subjects are **byte-identical**
  to the correction entry.
- The predecessor's ACT document, evidence tree, HANDOFF and `PASS`
  trailer are **untouched**.

```text
TRACKED_PRODUCTION_SOURCE_CHANGES = 0
PRODUCTION_SEMANTIC_DELTA          = 0
PREDECESSOR_F14_DELTA             = 0
```

## The seven historical defects

Each was reproduced by a command against the live tree or against the
closed predecessor artifacts.  None is asserted from prose.  None is a
newly discovered production compiler regression.

| ID | Defect | Repair |
|---|---|---|
| D1 | the P16 signed-I64 extremes were absent (0/4 present) | the producer writes every value with a 64-bit conversion |
| D2 | five files were added outside SLICE03's authorized mutation list | used prospectively; not deleted, not retrospectively declared compliant |
| D3 | G0 recorded the POLYC compiler SHA, not the C compiler SHA | the G0 provenance now records the actual C compiler |
| D4 | the C1 evidence carried a stale fixture-count observation of 99 | the corrected count is 123 and is computed on every run |
| D5 | the historical range has six commits, not the specified five | recorded exactly; not rewritten |
| D6 | the literal P16 enumeration cannot fit within the frozen 40 rows | the P16 row count is derived from the required value set |
| D7 | P16's nominal `expected_output=-1` does not describe its mixed values | every row's expected value comes from the derived table |

### The D1 mechanism, measured

The predecessor's `app_i` helper formats a value with
`snprintf(..., "%d\n", v)`.  `%d` is a **32-bit** conversion, so

```text
INT64_MIN     (-9223372036854775808) -> printed as  0
INT64_MIN+1   (-9223372036854775807) -> printed as  1
INT64_MAX     ( 9223372036854775807) -> printed as -1
INT64_MAX-1   ( 9223372036854775806) -> printed as -2
```

which is exactly what the predecessor's fixture rows `F069..F072`
carry.  A C-side `%lld` printer shows that the PolyC `I64` arithmetic
and the `I64_MIN`/`I64_MAX` hex constants carry the full 64-bit value,
so the defect is in the producer's **output format**, not in the
compiler and not in the precedence semantics.

### The D7 consequence, measured

The predecessor's P16 rows carry the mixed expected set
`{-1, 1, 3, 4, 5}` over 40 rows.  A verifier that took the partition
declaration of `-1` as the expected value would have rejected 8 of
them.


## What changed

- `tools/quality/parser-slice03-corr01-fixture.HC` (new, PolyC)

  The corrected fixture producer.  It re-derives the precedence table
  from the live `src/prslib.c` (the `parseGetPriority` body, located
  **by name**) and the live `src/lexer.h`, resolves every case label
  through the define table, and reads the `-1` sentinel out of the live
  `default` arm.  An unresolvable label is a **failure**, never a
  silent skip.

  It writes every value with a 64-bit conversion.  The four symbolic
  boundary constants are resolved **explicitly** from hex literals; no
  numeric fragment is ever scanned out of an identifier, so the false
  `64` values the predecessor harvested from `INT64_MIN` and
  `INT64_MAX` cannot reappear.

  The P16 row count is **derived** from the required value set, so the
  neighbour sweep cannot be truncated to fit an unfittable budget.

  The producer **fails** rather than emitting a superficially complete
  fixture: it refuses when the table cannot be derived cleanly, when a
  required value is missing, and when a domain edge is
  unrepresentable.

- `tools/quality/parser-slice03-corr01-coverage.HC` (new, PolyC)

  The independent semantic coverage verifier.  It does **not** share
  the producer's symbolic-token parsing logic.  It **discovers** the
  operator values by **executing** the real legacy-C oracle over the
  ASCII and token-constant regions, derives the required value set
  from those discovered values, and uses the oracle's **own answer** as
  the authority for every fixture row.

  The two paths are therefore independent: the producer reads the live
  source **text**, the verifier executes the live source **code**.  A
  defect that made the producer mis-read the source would have to be
  reproduced in the C compiler to escape the verifier.

  It checks **semantic** membership, not a row count: every required
  value must appear as a P16 row, no P16 row may carry a value outside
  the required set, and every row's expectation must agree with the
  real oracle.  Its 64-bit parser **rejects** an out-of-range magnitude
  rather than truncating it.

- `Makefile` (narrow wiring only)

  The new targets, plus a correction-owned G0 provenance target that
  records the actual C compiler identity.  No existing rule was
  weakened.

## The corrected contract

```text
CORRECTED_FIXTURE_ROWS       = 123
  P16_BOUNDARY_INTEGERS_ROWS  = 65
  NON_P16_ROWS                = 58
PARTITION_COUNT              = 19   (ALL preserved)

P16_REQUIRED_VALUE_SET_SHA256 =
  e16bd5d9d6334baddd556735c249da9e781d304ca40fc90c8b4866e025446df9
FIXTURE_SOURCE_SHA256 =
  d46d857e707e50b6fff10944377f72bdaf29fce41683bba99b56b312b006b84c
```

The P16 value-set SHA computed independently in C0 and the SHA of the
P16 block of the produced fixture are **identical**, so the producer
emits exactly the frozen set.

The predecessor's 98-row total is **not** preserved: it was the
incorrect one.  All 19 partitions and their required coverage **are**
preserved; the only changed partition is P16.

## The G0 compiler identity

```text
COMPILER_INVOCATION  = cc
COMPILER_RESOLVED    = /usr/bin/cc

## Evidence

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c0/historical-defects.txt`

  All seven defects, each reproduced by a command.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c0/p16-required-value-enumeration.txt`

  The independent enumeration of the 65 required P16 values and the
  freeze of their SHA-256.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c1/corrected-fixture.tsv`

  The corrected 123-row fixture.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c1/corrected-partition-audit.tsv`

  The per-partition row counts against the predecessor's.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/fixture-coverage-verification.txt`

  The independent semantic coverage verification.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/fixture-negative-controls.txt`

  The five coverage controls and the producer control, each firing.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/corrected-fixture-differential.txt`

  The 123-row differential against the real legacy-C oracle.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/g0-compiler-identity.txt`

  The actual C compiler identity.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/generation-provenance.txt`

  The G0..G3 provenance with the corrected G0 reading.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/conservation.txt`

  The parser and lexer conservation, measured against a compiler built
  from the correction entry tree.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/gates.txt`

  gate-fast, gate-push, factory-v2, append-only and patch hygiene.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/mandatory-acceptance.tsv`

  The 25 mandatory predicates, each with its evidence file.

## Acceptance

```text
PARSER_PRECEDENCE_PRODUCTION_AUTHORITY = POLYC
PRODUCTION_SUBJECT_SHA_DELTA          = 0
PRODUCTION_SEMANTIC_DELTA             = 0

P16_REQUIRED_VALUES_COMPLETE         = YES
P16_SIGNED_EXTREMES_PRESENT          = 4/4
P16_ALL_OPERATOR_NEIGHBORS_PRESENT   = YES
P16_FALSE_SYMBOLIC_NUMERICS          = 0
FIXTURE_COVERAGE_VERIFIER            = PASS
FIXTURE_NEGATIVE_CONTROLS            = PASS (5/5 + 1/1)

REAL_C_ORACLE_DIFFERENTIAL           = PASS
DIFFERENTIAL_MISMATCHES              = 0
G0_COMPILER_IDENTITY                 = CORRECT
G0_G3_PROVENANCE                     = PASS

PREDECESSOR_F14_DELTA                = 0
HISTORICAL_SCOPE_VIOLATION           = ACKNOWLEDGED
HISTORICAL_SIX_COMMIT_RANGE          = ACKNOWLEDGED
RETROACTIVE_REPAIR_CLAIM             = FALSE

NEW_PARSER_FAILURE_IDENTITIES        = 0
NEW_LEXER_FAILURE_IDENTITIES         = 0
GATE_FAST                             = PASS
GATE_PUSH                             = PASS
FACTORY_V2                            = PASS (53/0)
APPEND_ONLY                           = PASS (11/0)
PATCH_HYGIENE_ERRORS                  = 0

MANDATORY_PREDICATES_PROVEN           = 25/25
MANDATORY_PREDICATES_UNPROVEN         = 0
```

## Conservation

The baseline is the **correction entry tree** (`3dd44a6`), not the
previous ACT's report.

```text
BASELINE_PASSED=87  BASELINE_FAILED=3
CURRENT_PASSED=87   CURRENT_FAILED=3     (identical failure identities)

NEW_PARSER_FAILURE_IDENTITIES = 0
NEW_LEXER_FAILURE_IDENTITIES  = 0
NEW_LEXER07_FAILURE_IDENTITIES = 0
```

The two failures are the pre-existing `/usr/local/include/tos.HH` host
issue.  They are recorded as measured, not relabelled PASS.

The LEXER07 broad corpus is identical to the canonical baseline
registry: `REGRESSION=0`, `DIVERGED=0`.

## Residue

- The two parser-suite failures and the 12 tracked Python findings are
  **pre-existing** and unchanged by this ACT.  They are recorded as
  measured.  They are not relabelled PASS.

- The five historically out-of-scope SLICE03 files remain in the tree.
  They are load-bearing for the production migration and are used
  prospectively here.  Removing them is out of this ACT's scope.

- `F-POLYC-TOOLS` is not yet wired into the canonical gate graph (a
  pre-existing gap recorded by an earlier ACT).  The checker exists
  and was run manually for this ACT.

## Next ACT

```text
ACT-POLYC-SELFHOST-PARSER-SLICE04
```

Candidate shortlist: `CAND-019 astBinOpFromToken` and
`CAND-020 astUnaryOpFromToken`.

Exactly one candidate is selected through the successor's **binding
eligibility and ranking contract**.  No winner is preselected here by
prose, and this HANDOFF does not rank the shortlist.

The successor inherits:

- the production authority is `BootstrapOperatorPrecedence` (PolyC),
  with the legacy algorithm retired;
- the qualifier for the precedence slice is the correction-owned
  producer and coverage verifier, which are independent of each other
  and of the closed predecessor tools;
- the G0 provenance reading is the **actual** C compiler identity.

## Terminality

This CLOSE commit is the last commit of the ACT's range.  No commit
after it carries this ACT's `ACT:` trailer, and no file is added to
this ACT's evidence directory after it.  Any post-CLOSE terminality
check is READ-ONLY and its results are kept OUTSIDE tracked closed
evidence.

VERDICT

PASS

The qualification authority of SLICE03 is restored.  The production
migration is preserved unchanged, the seven historical defects are
recorded as measured facts, the fixture contract is requalified to a
semantically complete 123 rows, and all 25 mandatory acceptance
predicates are proven.

COMPILER_SHA256      = 9b11ead1ca76a03d61108ad5bf2c913d6aa8daa7deb9fd28893e847e3680e5e7
COMPILER_VERSION     = Apple clang version 15.0.0 (clang-1500.0.40.1)
SOURCE               = tools/quality/slice03-gen/g0-legacy-reference.c
SOURCE_SHA256        = 94567a13992135f4a40498107a0c1fc10553a2e619765897711fef253a83d8ff
BUILD_COMMAND        = cc -std=c99 -O2 -Isrc -c -o build/corr01/g0/g0.o tools/quality/slice03-gen/g0-legacy-reference.c
COMPONENT_OBJECT_SHA256 = 937a29dcfb22b5c00b187b11e47a27efd6d301374060b5451263f1507e60d52d
G0_COMPILER_IS_THE_POLYC_COMPILER = NO
```
