# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01 — CLOSE evidence

This directory holds the CLOSE-phase evidence for
ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01.

Files:

- `closure-summary.txt` — structured closure handoff
  (VERDICT / IDENTITY / RED / IMPLEMENTATION / GATES /
  SCOPE / RESIDUE / NEXT_ACT).

## How to read this CLOSE

This ACT introduces the Factory v2 operating law
`F-MECHANICAL-BLOCKING` (prose alone never blocks
progress) and the additive `HALT_CLASS` /
`BLOCKS_NEXT` trailer pair. Together they let the
board distinguish:

```
ACT truth    : did this ACT satisfy its own contract?
Roadmap truth: does that outcome prevent the next
               authorized action?
```

The default behavior is `HALT_CLASS=GOVERNANCE` and
`BLOCKS_NEXT=NO` for halt verdicts whose blocking
predicate is not mechanically demonstrated on the
relevant subject. This is the documented board
signal that no further authorization artifact is
required for a same-scope successor ACT to open.

Historical CLOSE commits are NOT re-validated; the
verifier's activation boundary is the timestamp of
this ACT's CLOSE commit.

## What this CLOSE does NOT change

- No production source was mutated.
- No closed ACT's verdict was mutated.
- No new Track-B ACT was opened in this turn.
- No intermediate "authorization to authorize" ACT
  is required or recommended.
