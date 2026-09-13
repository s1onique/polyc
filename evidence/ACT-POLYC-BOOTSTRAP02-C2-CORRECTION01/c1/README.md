# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01 — C1 RED packet

This directory contains the RED evidence for opening
ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01. The two defects
being corrected are:

- **P0**: ACT §14 wording forbids `#ifdef` literally; C2
  IMPL uses a build-time `#ifdef` for stage separation
  (semantically correct, but literally violates the
  wording).
- **P1**: `cursor-equivalence.txt` over-claims that byte-
  identical objects imply identical token streams.

See:
- `defect-p0-§14-wording.txt` — exact §14 wording and the
  C2 implementation extract that violates it.
- `defect-p1-cursor-over-claim.txt` — exact wording from
  `cursor-equivalence.txt` and the corrected two-pillar
  taxonomy.
- `corrected-§14-wording.txt` — the corrected §14 wording
  the C2 IMPL actually satisfies.
- `corrected-cursor-taxonomy.txt` — pillar A (object
  parity) vs pillar B (direct cursor witness).
- `required-result.txt` — binding C1 RED → C2 IMPL gate
  contract for this correction ACT.
