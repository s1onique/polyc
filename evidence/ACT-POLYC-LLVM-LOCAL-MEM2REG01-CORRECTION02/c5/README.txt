C5 — HARNESS-EVIDENCE-ISOLATION PRODUCER FIX

ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
ACT-Phase: IMPL  (descriptive lane: IMPL-TOOLING)
Commit: C5
Date: 2026-09-11

================================================================================
0. The defect
================================================================================

RED-1 (committed at C1) reproduced the following defect:

  Run every regression/conservation harness.
  Then: git status --porcelain
  Must NOT contain anything under:
    evidence/llvm-core04-resume01/
    evidence/llvm-memory01/
    any other closed ACT evidence tree

  Actual result: the harness mutated
    evidence/llvm-core04-resume01/c2/red-multi_def/
    evidence/llvm-memory01/spike/red-6-live-transcripts/

The two paths were hardcoded as defaults in
scripts/quality/llvm-spike-test.sh:

================================================================================
1. The fix (Option A)
================================================================================

Strategy: route emitted evidence through EVIDENCE_OUT/current
namespace. The harness now accepts an EVIDENCE_OUT env var:

  When EVIDENCE_OUT is unset (ordinary regression):
    - $EVID         defaults to $REPO_ROOT/build/evidence/spike/<pid>-<rnd>/
                    (a gitignored scratch dir; not tracked)
    - $EVID_CORR    defaults to $EVID/red-6-live-transcripts
    - $EVID_MULTIDEF = $EVID/red-multi_def
    -> Ordinary regression NEVER mutates tracked historical
       evidence trees.

  When EVIDENCE_OUT is set (explicit evidence-update path):
    - $EVID         = $EVIDENCE_OUT/spike
    - $EVID_CORR    = $EVIDENCE_OUT/red-6-live-transcripts
    - $EVID_MULTIDEF = $EVIDENCE_OUT/red-multi_def
    -> All outputs land under the user-specified destination.

  When LLVM_SPIKE_EVID_OVERRIDE or LLVM_SPIKE_EVID_CORR_OVERRIDE
  is set (legacy paths): those overrides continue to win
  (preserves historical explicit-evidence usage).

The Makefile gets a new `evidence-update` target that requires
EVIDENCE_OUT and runs the harness against that destination.



  EVID_CORR=$REPO_ROOT/evidence/llvm-memory01/spike/red-6-live-transcripts

================================================================================
2. Files changed
================================================================================

  M scripts/quality/llvm-spike-test.sh
       EVID, EVID_CORR, EVID_CORR2 defaults rewritten to honor
       EVIDENCE_OUT.
  + scripts/quality/harness-evidence-isolation-test.sh
       New regression test that asserts a fresh
       `make llvm-spike-test` produces ZERO modification under
       the two RED-1 closed-ACT evidence trees.
  M Makefile
       + evidence-update target (explicit evidence regen)
       + harness-evidence-isolation-test target

No src/ changes. No compiler semantics change. No neutral IR
change. No Option-W implementation change.


  EVID_CORR2=$REPO_ROOT/evidence/llvm-core04-resume01/c2

================================================================================
3. Before/after evidence
================================================================================

BEFORE the fix (RED-1 reproduction, captured at C1):

  $ git status --porcelain > after.txt
  $ cat after.txt
   M evidence/llvm-core04-resume01/c2/red-multi_def/red-multi_def.live.stderr
   M evidence/llvm-core04-resume01/c2/red-multi_def/red-multi_def.live.summary
   M evidence/llvm-memory01/spike/red-6-live-transcripts/red-1B.emit.stderr
   M evidence/llvm-memory01/spike/red-6-live-transcripts/red-2.emit.stderr

AFTER the fix (this C5 commit):

  $ git status --porcelain > evidence/.../c5/after.txt
  $ cat evidence/.../c5/after.txt
   M Makefile
   M scripts/quality/llvm-spike-test.sh
  ?? evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c5/

The only modifications are the C5 producer-fix files themselves
(in scope for this commit per §4.2 of the ACT contract). No
modification appears under any closed ACT evidence tree.

SHA-256 invariant: every file under
  evidence/llvm-core04-resume01/c2/red-multi_def/
  evidence/llvm-memory01/spike/red-6-live-transcripts/

has the SAME SHA-256 before and after a fresh
`make llvm-spike-test` run. This is asserted programmatically by
`scripts/quality/harness-evidence-isolation-test.sh`.



================================================================================
4. Run output
================================================================================

$ HCC_INSTALL_DIR=$(pwd)/build/test-prefix make llvm-spike-test
... (full 18/18 PASS, see build/evidence/spike/<pid>-<rnd>/) ...

$ git status --porcelain
 M Makefile
 M scripts/quality/llvm-spike-test.sh
?? evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c5/

No modification under any closed ACT evidence tree. Property
satisfied.

$ HCC_INSTALL_DIR=$(pwd)/build/test-prefix make harness-evidence-isolation-test
=== running make llvm-spike-test (C5 isolation check) ===
PASS: harness-evidence-isolation-test
  closed-ACT trees scanned: 50 files
  git status --porcelain mod in any closed-ACT evidence tree: NONE

The isolation test re-runs `make llvm-spike-test` and re-asserts
the SHA-256 invariant. Idempotent across multiple runs.



================================================================================
5. RESIDUE (F11)
================================================================================

R-P1  Default `build/evidence/spike/<pid>-<rnd>/` accumulates
     evidence across runs. The trap in the harness only removes
     `_tmp` subdirs, not the top-level pid-rnd dir. A `make
     clean` (which removes ./build) clears it. No long-term
     disk pressure under ordinary usage.

R-P2  The legacy `LLVM_SPIKE_EVID_OVERRIDE` and
     `LLVM_SPIKE_EVID_CORR_OVERRIDE` env vars are preserved
     for backwards compatibility with existing explicit-evidence
     workflows. A future cleanup ACT may deprecate them in favor
     of the unified EVIDENCE_OUT.

R-P3  Other harnesses (llvm-byte-memory01-test.sh,
     llvm-memory01-test.sh, llvm-memory01-red-test.sh) also
     write to evidence/ paths. They write to THEIR OWN ACT's
     evidence tree (e.g. evidence/llvm-byte-memory01/impl/_tmp),
     not to any closed ACT tree. No contamination of the RED-1
     reproducer set was observed for them. They are out of C5
     scope (F7); a future ACT may apply the same EVIDENCE_OUT
     pattern to them.

ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
ACT-Phase: IMPL


