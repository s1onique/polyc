# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION04 — Evidence Index

This directory collects evidence for the CORRECTION04 phase of
ACT-POLYC-TOOLING-RUNTIME01. CORRECTION04 is an EVIDENCE-ONLY
correction to CORRECTION03; it does not change any production
semantics.

## What CORRECTION04 fixes

CORRECTION03 closed PASS but committed an empty
`evidence/ACT-POLYC-TOOLING-RUNTIME01/correction03/patch-hygiene.txt`
while reporting "CORRECTION03 patch = clean". That was an
evidence-integrity defect:

- An empty file is not evidence that `git diff --check` passed.
- Re-running `git diff --check HEAD~1..HEAD` from a clean
  working tree shows rc=2 with 3 diagnostics, all in
  CORRECTION03-introduced evidence files.
- The production code (`src/CMakeLists.txt` and
  `src/holyc-lib/tooling.HC`) is clean; the defect was in
  the evidence of hygiene, not in the actual code.

## Files

### Witnesses

- `install-rc-table.txt` — per-step return codes for the
  CORRECTION03-corrected install step, captured 2025-09-12 from
  main @ e5a2e50.
- `install-prefix-witness.txt` — direct `test -f/-L/readlink`
  triple against a fresh install prefix showing
  `libtos.dylib -> libtos.0.0.1.dylib`.
- `patch-hygiene-classified.txt` — full classification of all
  `git diff --check` diagnostics in the 456b71c..HEAD range.

### Closure

- `closure-summary.txt` — bounded verdict, what went wrong,
  what CORRECTION04 does, conservation status, next ACT.

## Reproduction

The corrected patch-hygiene check is:

```sh
# After CORRECTION04 closes:
git diff --check HEAD~2..HEAD   # only the c04 commit's range
# Expected: zero diagnostics.

git diff --check HEAD~3..HEAD~1 # the CORRECTION03 range
# Expected: 1 P2 residue diagnostic (cmake-install.log:15 trailing
# whitespace, captured verbatim command argv).

git diff --check 456b71c..HEAD  # full ACT range
# Expected: 7 F14-protected + 1 P2 residue; 0 c03/c04-introduced.
```
