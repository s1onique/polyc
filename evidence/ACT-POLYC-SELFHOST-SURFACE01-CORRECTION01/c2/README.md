# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 — C2 evidence

## C2.1.1 IMPL — reviewer-driven forward fixes

Reviewer verdict (post-C2.1) identified three P0/P1
defects in C2.1:

* **P0**: Make injection hardening incomplete (single-
  quote escape broke single-quoted Make assignment;
  reviewer's worst-case backtick case created a sentinel
  even under `make -n` due to a presence-check line that
  itself interpolated `$(COMPONENT)`).
* **P0**: `factory-no-python-check.HC` had obvious false
  positives caused by a misuse of `StrFirstOcc` (which
  is a char-set scan, not substring search). The
  checker flagged `#!/bin/sh` as Python and historical
  documentation as invocation edges.
* **P1**: Checker transport used newline-delimited paths
  instead of NUL-delimited, contradicting the doctrine.
* **P1**: AGENTS.md/DOCTRINE.md stated present facts
  ("both checkers are wired into gate-fast") that the
  changeset had not yet produced.

All four fixed forward in C2.1.1.