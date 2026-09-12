# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01 - RED evidence

This directory contains the C1 RED-phase evidence for
`ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01`. Per Factory
v2, the authoritative verdict lives on the C3 CLOSE
commit's `ACT-Verdict` trailer; this directory is
descriptive only.

## Files

| File                                  | Purpose                                              |
|---------------------------------------|------------------------------------------------------|
| `r1-r3-principal-red.txt`             | R1, R2, R3 RED witnesses run against the real tree.  |
| `r4-matrix-preview.md`                | R4 R1-R7 matrix preview / design rationale.          |

## Reproduction

```sh
# R1
grep -n 'F-MECHANICAL-BLOCKING' \
    docs/factory/DOCTRINE.md AGENTS.md
echo rc=$?
# rc=1 (zero matches)

# R2
grep -n 'HALT_CLASS\|BLOCKS_NEXT' scripts/quality/*.sh
echo rc=$?
# rc=1 (zero matches)

# R3
git log --format='%B' -1 1732c3f | \
    grep -E 'HALT_CLASS|BLOCKS_NEXT'
echo rc=$?
# rc=1 (the corrective verdict on the predecessor
# carries no class metadata)
```

All three witnesses are deterministic and depend only
on the current tree contents.

## Identity (per F1, captured at RED entry)

```text
branch         = main
working tree   = clean
entry HEAD     = bf52316ba4ab91da00a5c25747079254fd105044
predecessor    = ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02
                 (CLOSED PASS per its CLOSE trailer at HEAD;
                  ACT-Corrected-Verdict=HALT_AC07_NOT_SATISFIED)
```

## RED summary

The principal RED reproduces:

  R1: `F-MECHANICAL-BLOCKING` is absent from
      `DOCTRINE.md` and `AGENTS.md`.
  R2: `HALT_CLASS` and `BLOCKS_NEXT` are absent from
      every Factory verifier under `scripts/quality/`.
  R3: The current halt verdict
      (`HALT_AC07_NOT_SATISFIED`) carries no
      `HALT_CLASS` and no `BLOCKS_NEXT`, so a verifier
      that required them would correctly FAIL on the
      current tree.
  R4: The R1-R7 matrix in `r4-matrix-preview.md`
      defines the new verifier's test surface.

This RED is enough to authorize C2 IMPL.

## What this ACT does NOT do in this turn

- It does NOT add the new doctrine section to
  `DOCTRINE.md` (C2 IMPL).
- It does NOT add the verifier scripts (C2 IMPL).
- It does NOT modify the existing CORRECTION02
  evidence tree (forbidden; F14).
- It does NOT open `SHELL-BUDGET01` or any Track-B ACT
  (forbidden; CORRECTION02 §12).
- It does NOT authorize `TRACK_B_ADVANCE` (forbidden;
  a separate authorization ACT is required).

## Hard stop after RED

Per Cline ACT-mode rule and Factory operating laws:
the agent opens the ACT in RED, commits the evidence,
and stops. The board authorizes C2 IMPL in a future
turn.
