# ACT-POLYC-FACTORY-NONINFERRED (fixture for RED-3A1)

## Status

HALT_FACTORY_NONINFERRED_DEMO

## Goal

Demonstrate RED-3A1: this ACT lives at a non-inferred path.
The seed closure-status-check.sh pairing rule computes the
target evidence directory from the ACT filename by lowercasing
the tail and special-casing the "core" and "boundary" prefixes.
A path that does not match any of those special-case patterns
will not be inferred at all.

## Pairing

This ACT is paired with a HANDOFF at
extra-scope-factory-NON_INFERRED/evidence/handoff-noninfer/HANDOFF.md
which the seed cannot infer from the ACT filename.
