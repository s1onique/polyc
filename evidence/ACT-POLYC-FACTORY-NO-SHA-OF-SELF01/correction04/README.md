# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION04 — Evidence Index

This packet carries:
  1. The forward Cardinality-1-CLOSE invariant codification
  2. The historical exceptions list (every ACT that
     currently violates Cardinality-1)
  3. The two wording fixes from CORRECTION04's ACT doc

## Why this exists

The reviewer identified that the Cardinality-1 CLOSE
invariant has been violated historically in this session
itself. Specifically:

  CORRECTION06:  2 CLOSE commits (main + hygiene follow-up)
  CORRECTION05:  2 CLOSE commits (main + identity-fix follow-up)
  NO-SHA-OF-SELF01: 5 CLOSE commits (main + hygiene follow-up +
                                 CORRECTION01 + CORRECTION02 +
                                 CORRECTION03)

Going forward, hygiene follow-ups should NOT carry
`ACT-Phase: CLOSE`. They should carry `ACT-Phase: EVIDENCE`
or be opened as a separate bounded correction ACT.

## Files

- `cardinality-invariant.txt` — formal statement of the
  forward invariant
- `historical-cardinality-exceptions.txt` — enumerated list
  of every current violation
- `tformat-recipe.txt` — the recommended SHA-extraction
  recipe using `--pretty=tformat:`
