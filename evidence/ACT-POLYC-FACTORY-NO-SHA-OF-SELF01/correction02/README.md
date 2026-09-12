# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02 — Evidence Index

This packet records the F14-governance defect that occurred
in the just-closed CORRECTION01 and prevents the same
failure mode from being repeated.

## What happened

CORRECTION01 (`3d9b275`) fixed the Git query semantics bug
(`--grep` is OR by default; needs `--all-match` for AND).
The fix is correct.

But CORRECTION01 applied the recipe update to two files in
the CORRECTION06 evidence directory:

  evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/
    closure-summary-replacement.md
    no-sha-of-self-repair-record.txt

Those files were created by CORRECTION06's commits (f031bc7,
23bc92a). CORRECTION01's mutation of them is the exact
F14 violation that the new DOCTRINE.md §22 explicitly
forbids.

## Why we do not "undo" it

Three options were considered:

1. Revert CORRECTION01. Rejected: F-GIT-IMMUTABILITY
   forbids history rewrite, and reverting would also
   undo the correct Git-semantics fix in DOCTRINE.md.

2. Re-mutate the CORRECTION06 files to revert them to
   their original (naive-recipe) form. Rejected: would
   compound the F14 violation with another F14 violation.
   And the "naive recipe" is now demonstrably wrong; we
   don't want to keep it preserved just to satisfy a
   purity rule.

3. Document the violation, stop repeating it, mark the
   C06 file state as "historically mutated by a
   CORRECTION01 that itself violated F14", and move on.
   Adopted.

The F14 violation is acknowledged in
`f14-violation-record.txt`. The authoritative recipe
that future corrections and consumers should use lives
in `authoritative-recipe.txt`.

## Files

- `f14-violation-record.txt` — what CORRECTION01 did wrong
- `authoritative-recipe.txt` — the canonical recipe
- `cardinality-witness.txt` — empirical proof
- `c05-doctrine-classification.txt` — explicit classification
  of the C05 "ADDENDUM is acceptable" text as superseded
