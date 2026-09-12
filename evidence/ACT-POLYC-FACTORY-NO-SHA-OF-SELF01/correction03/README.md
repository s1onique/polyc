# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION03 — Evidence Index

This packet documents and fixes a SECOND bug in the
canonical cardinality-check recipe: `wc -l` + `--pretty=format:'%H'`
returns 0 even when 1 commit matches, because the format
emits no trailing newline.

## What happened

CORRECTION01 added the cardinality check to DOCTRINE.md §22:

```sh
matches=$(git log --all-match \
                  --grep='^ACT: ACT-POLYC-FOO01-CORRECTION03$' \
                  --grep='^ACT-Phase: CLOSE$' \
                  --pretty=format:'%H' | wc -l)
test "$matches" -eq 1 || { echo ...; exit 1; }
```

The `--all-match` part is correct. The `--grep` patterns
are correct. The bug is `--pretty=format:'%H'` + `wc -l`:

  - `--pretty=format:'%H'` prints ONLY the SHA with no
    trailing newline.
  - `wc -l` counts newline characters.
  - So `wc -l` returns 0 for a 1-match query, and a single
    SHA on a single line is still 0 newlines.

This bug was caught by the reviewer audit of CORRECTION02
(it surfaced as a cardinality-check anomaly: 0 matches
expected for nonexistent ACTs, 1 expected for existing
ACTs, but actual output was 0 for both).

## Why we don't re-mutate correction02/

The recipe in correction02/'s authoritative-recipe.txt and
the witness in cardinality-witness.txt both contain the
buggy form. Under strict F14, those files are immutable
historical evidence. We don't rewrite them.

Instead:

  - DOCTRINE.md §22 gets the corrected recipe (this is a
    canonical-contract file; mutating it is allowed).
  - This correction03/ packet carries the v2 of the
    authoritative recipe and the empirical witness.
  - Future consumers should read correction03/ as the
    current truth; correction02/ remains valid as the
    record of "this is what was once thought correct".

## Files

- `wc-l-bug-reproduction.txt` — empirical proof
- `authoritative-recipe-v2.txt` — corrected recipe
- `cardinality-witness-v2.txt` — new witness for the
  newline-safe counting primitive
- `recipe-revision-history.txt` — what was fixed when
