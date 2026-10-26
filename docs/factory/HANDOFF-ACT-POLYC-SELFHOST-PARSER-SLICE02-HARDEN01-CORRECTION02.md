# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02

Factory-Version: 2

## Result

The last remaining row-recognition bypass in the direct differential is
closed, and the predecessor's closure defect is recorded truthfully
without mutating any closed evidence.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.

## What changed

- `tools/quality/parser-control-flow-token-differential.HC`

  The row reader now tracks a metadata-block context. A recognized
  `KEY=VALUE` row opens the block; an indented row continues it and is
  skippable only while it is open; a data row closes it. Before this
  change ANY indented line was skippable, so an indented unknown
  fixture id was invisible to the unknown-ID ledger and the
  differential returned `STATUS=PASS` with `UNKNOWN_IDS=0`.

  The comment recognition and the `KEY=VALUE` first-field recognition
  are unchanged, and no existing rejection reason is weakened.

- `tools/quality/parser-control-flow-token-negative-controls.HC`

  `EditAppendLine()` now emits a separating newline when the source
  does not already end with one, so an appended row can never join an
  unterminated last line. A well-formed source is byte-identical to
  what the previous form produced.

  Four controls were added: NC-D18 (indented unknown id),
  NC-D19 (tab-indented unknown id), NC-D20 (tab-indented unknown id
  with the canonical field count) and NC-D21 (an appended row must not
  join an unterminated last line). NC-D21 was proved load-bearing:
  with the separator removed it reports `BROKEN` and the retained
  fixture shows the two rows merged.

## Evidence

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c0/red-reproduction.txt`

  The four REDs, each against the real seam: the indented-row bypass,
  the post-CLOSE evidence addition, the driver's row-separation risk,
  and the recorded NC-D12 block that its own command does not produce.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c2/acceptance-criteria.txt`

  Each acceptance criterion with its measured result.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c2/f14-violation-record.txt`

  The F14 violation in the predecessor's closure, recorded with the
  exact `git diff --name-status` witness, together with the proof that
  this ACT did not modify the predecessor's evidence: both tree
  hashes are `3606f07439313124020971a472110d9c1fb4944b`.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c2/nc-d12-corrected-measurement.txt`

  The corrected NC-D12 measurement, and the exact reproduction of the
  predecessor's recorded block from a 41-row base.

- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c3/terminality.txt`

  The terminality check for this ACT, recorded BEFORE the CLOSE commit.

## Review disposition

The review of the predecessor found:

| Finding | Disposition |
|---------|-------------|
| P0 -- two commits after CLOSE, closed evidence modified | CONFIRMED and RECORDED. The diff witness is mechanical. The offending commits are historical evidence and are not rewritten. |
| P1 -- the recorded NC-D12 block reports `TOTAL=42` | CONFIRMED, with a sharper root cause than the review proposed: the block is reproducible only from a base already missing `F042`, so the recorded command line does not describe the recorded output. The predecessor's conclusion still holds. |
| P1 -- `is_skippable_row()` accepts any indented line | CONFIRMED and REPAIRED. An indented unknown row is now rejected. |
| P1 -- `EditAppendLine()` does not separate the appended row | CONFIRMED at source level and REPAIRED. It was not triggered on the canonical fixture, which ends with a newline. |

The production PolyC authority is unchanged, and the predecessor's
engineering result stands. What this ACT narrows is the predecessor's
CLOSURE, not its engineering.

## Production delta

None. `git diff --stat <entry>..HEAD -- src/ tools/bootstrap/` is empty:
the production compiler, the parser, the lexer, the AST representation
and the whole bootstrap chain are untouched.

## Residue

- P1 -- The predecessor's
  `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/c2/p0-fixture-integrity.txt`
  block "GREEN 2" cannot be cited as a measurement of the canonical
  fixture: its recorded command line does not produce its recorded
  output. It is closed evidence and is not modified. The authoritative
  successor measurement is
  `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02/c2/nc-d12-corrected-measurement.txt`.
- P2 -- The predecessor's two post-CLOSE commits remain in the
  authoritative history. They are evidence of the violation. They are
  not rewritten, because rewriting history is forbidden, and the
  violation is recorded rather than erased.
- P2 -- The Factory-v2 range check does not, and cannot, police
  post-CLOSE mutations of a closed evidence tree: it resolves an
  ACT's CLOSE from the commit it is given. A mechanical check for that
  class would be a separate, bounded concern.

## Recommended next ACT

ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

## 10. Verdict

VERDICT

---

PASS
