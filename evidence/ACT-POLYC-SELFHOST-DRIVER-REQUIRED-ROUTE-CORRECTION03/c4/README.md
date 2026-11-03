# CORRECTION03 C4 REMEDIATION EVIDENCE

This directory holds the FORWARD-ONLY evidence for the C4 remediation of
the independent Codex review's P1 and P2 findings against the C3 head
`cdd927ac804fe007a9440d577929984bbf4f08f8`.

Nothing in the C0, C1, C2 or C3 evidence directories is modified. The
historical commits and their source bytes are preserved exactly as
committed.

## THE FILES

| file | kind | what it establishes |
| --- | --- | --- |
| `p1-repair-summary.md` | prose | what each P1 finding was, what the repair is, and what the repair does NOT change |
| `p1-1-red-fresh-build.log` | RED | the committed rule fails a fresh isolated build with NO seeded object |
| `p1-1-green-fresh-build.log` | GREEN | the repaired rule passes a fresh isolated build with NO seeded object |
| `p1-1-failure-mode-matrix.tsv` | measurement | every failure mode is detected INDEPENDENTLY with its OWN reason token |
| `p1-2-adverse-probe.log` | measurement | the ten adverse probes, each rejected |
| `p1-2-adverse-probe-rejection-ledger.tsv` | measurement | each probe's DISTINGUISHING rejection reason |
| `p1-3-emission-coverage.log` | measurement | the four emission domains and the emission-domain fail-closed check |
| `p1-3-emission-coverage-ledger.tsv` | measurement | each domain's expected and observed classes, with the archive distinction |
| `abi-domain-coverage.tsv` | measurement | the EXTENDED sixteen-case selected-emission roster |
| `conservation-16-authorities.tsv` | measurement | the 16 production authorities, re-censused fresh |
| `chronology-and-accounting-correction.md` | prose | the C1 chronology retraction and the 15-versus-8 accounting correction |
| `self-referential-manifest-hashes.tsv` | measurement | the measured self-referential hash discrepancy in the committed manifests |
| `covering-manifest.txt` | manifest | the FORWARD-ONLY covering manifest, which EXCLUDES its own hash |

## WHAT IS NOT CLAIMED

* NO claim of preimplementation freezing of the C1 contract. The C1
  evidence files were FIRST committed alongside the C2 implementation,
  in the single commit `cb6ffe9c5ec9d0a515a0ae28517e9e03700e3ff6`.
* NO claim that the C4 emission-coverage tests were frozen before the
  implementation. They are NEW, FORWARD-ONLY supplemental evidence.
* NO change to the committed C2 "15/15" claim. It is corrected in NEW
  evidence, not retroactively in the historical file.
* NO rewrite of a committed manifest to repair its self-referential
  hash. A forward-only covering manifest is added instead.
* NO whole-CLI compiler ownership, NO WP-001 completion, and NO M2
  self-hosting claim.
* NO C4 CLOSE, and NO push. The C4 CLOSE is permitted only after a NEW
  independent, READ-ONLY review of the corrected head returns
  `C4_READY=YES` with zero unresolved substantive P0/P1 findings.
