C2 IMPL — registry migration + forward restoration.

Two file changes:

1. CREATE docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv
   containing EXCEPTION_1 through EXCEPTION_5 (migrated verbatim
   from the legacy file with corrections to EXCEPTION_5 wording).

2. Forward-commit a BIT-IDENTICAL restoration of
   evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/
     historical-cardinality-exceptions.txt
   to its pre-BOOTSTRAP-CORRECTION01 state (commit 4a78bdf^).

The forward commit does NOT amend history; it stages the
pre-BOOTSTRAP content as a new commit's tree. The legacy
file's SHA in the new commit tree equals its SHA at
4a78bdf^:1f6e5dedf828a6f28e4fb0abdaed350d2344c005.

DOCTRINE.md §24 was strengthened with three new sub-sections:
  §24.1 Truth hierarchy (codified)
  §24.2 Exception registry location (canonical)
  §24.3 Git notes do NOT reclassify commits
These are additive insertions and do not rewrite existing
prose.
