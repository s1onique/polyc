# Q1 EVIDENCE RESTORATION RECORD (FORWARD-ONLY)

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`
**Phase:** Q2-IMPL
**Kind:** forward-record of a Q1 evidence-file defect

## WHAT WAS DEFECTIVE

The Q1 evidence file

```
evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q1/32-row-current-classification-contract.tsv
```

was committed at `2a74b45b` **WITHOUT** its two header
constructs:

1. the `#`-prefixed descriptive comment block that states the
   provenance of the `historical_*` columns and the meaning of every
   measured column, and

2. the single `historical_id historical_file ... note` column-header
   row.

The **32 data rows themselves were never affected**: they are
byte-identical between the committed version and the restored version.

## WHY IT WAS NOT AMENDED

`AGENTS.md` F14 forbids mutating a closed ACT's evidence, and the
append-only invariant (`docs/factory/DOCTRINE.md` §23) forbids
rewriting committed history. The Q1 commit `2a74b45b` is therefore
**left exactly as committed**. The correction is a **new file in
the Q2 evidence tree** plus a **forward modification of the Q1 file
that ADDS the missing header**, carried by the Q2 commit.

The Q1 commit is not rewritten, and its evidence is not deleted; the
missing header is *added back* by a later, forward-only commit.

## THE MEASURED EQUIVALENCE

```text
COMMITTED_Q1_DATA_ROWS      = 32
RESTORED_Q1_DATA_ROWS       = 32
DATA_ROW_BYTES_IDENTICAL    = YES
DIFFERING_LINES_IGNORING_HEADER = 0
```

The verification is mechanical:

```sh
diff <(git show 2a74b45b:<q1 file> | grep -v '^#') \
     <(grep -v '^#' <q1 file> | grep -v '^historical_id')
```

The only difference is the ADDED column-header row.

## THE Q2 INPUT IS THE RESTORED TABLE

The Q2 verifier input
`q2/inputs/current-classification.tsv` is the restored Q1 table. It
carries the same descriptive comment block, the same column-header
row and the same 32 data rows. The verifier's loader requires the
column-header row; the restoration is therefore not cosmetic but a
**precondition of the compiled verifier**.

## DISCLOSURE

This defect was found during Q2, not before. It is disclosed here
rather than silently corrected, and the corrected file is committed
forward by the Q2 commit. **No production file was modified.**
