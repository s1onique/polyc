INTEGRATION-REMOTE-MAIN-SYNC01
==============================

Closed ACT: ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01
                 C2.3 INTEGRATION GATE VERIFICATION
Predecessor link: ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.2.1 CLOSED
                  (commit 1e1730c)
Authorization: user instruction to "sync remote main containing Dafny work
into the current local main ... merge, not rebase ... before C2.3"

IDENTITY (F1)
-------------
pre-merge:
  HEAD                = 1e1730c69de826c2e4386821bc711c340510a7a4
  branch              = main
  origin/main         = 7d7b983686fac2239a47288fe4b8e5dbbb617d55
  divergence          = 25 local-only, 11 remote-only

merge commit:
  HEAD                = 0728b5384faa1624b134dd192b6d59c737ae5cbb
  merge-base          = 7d7b983686fac2239a47288fe4b8e5dbbb617d55
  local ancestor      = 1e1730c69de826c2e4386821bc711c340510a7a4 (preserved)
  remote ancestor     = 2381a7469ba5174c72e4c92217154910386992c4 (preserved)
  git replace -l      = empty
  merge strategy      = --no-ff true merge (two parents visible)
  rebase / reset / amend / force-push = NONE

APPEND-ONLY (DOCTRINE §23, §24)
-------------------------------
baf5dbd77cf89330699685dffd932c54031c815c boundary preserved: YES
No commits rewritten before this point. Merge adds new commits forward.
ancestor of local pre-merge in current main : YES  (1e1730c)
ancestor of remote main       in current main : YES  (2381a74)

CONFLICTS (resolved by union)
-----------------------------
Makefile
  .PHONY line: unioned; all targets from both sides retained:
    - formal-dafny                              (remote)
    - selfhost-component-binary / -build / -test / -selftest
    - selfhost-registry-validate                (local)
  formal-dafny target recipe (lines ~233..242) preserved from remote
  selfhost-component-* target recipes (lines ~1010..1066) preserved from local
  git diff --check                            = clean
  conflict markers (`<<<<<<<` etc.) remaining = NONE

docs/ROADMAP.md
  Auto-merged; SHELL-BUDGET01+PREBOOTSTRAP-GATES blocks (remote) and
  SELFHOST-SURFACE01+BOOTSTRAP04 blocks (local) coexist. FT3 tail
  identical on both sides (no conflict).

AGENTS.md
  Auto-merged; F-NO-PYTHON/F-POLYC-TOOLS pointer section (local add)
  retained despite remote deletion of same content (current is valid
  per C2.2 closure).

.gitignore
  Auto-merged; remote adds Dafny 4.11.0 distribution carve-out.
  No conflict.

FILES NOT STAGED IN MERGE (explicit residue, F11)
-------------------------------------------------
1 file from remote side was NOT staged:

  evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c2/score.py

Reason: tracked Python source would have increased
POLYC_TOOLS_TRACKED_PYTHON from 15 to 16, violating F-NO-PYTHON
(DOCTRINE.md §26). It remains in the remote history (F14 immutable)
but is NOT introduced into the merged tree. Owner: P1 residue for the
next bounded correction ACT (likely
ACT-POLYC-TOOLING-SHELL-BUDGET01-CORRECTION02) to decide between PolyC
re-implementation, removal, or explicit
HALT_POLYC_TOOLING_CAPABILITY_GAP.

GATE VERIFICATION (post-merge)
------------------------------

Canonical C2.2 baseline (conservation, F10):
  gate-fast                                 STATUS=PASS
  factory-v2-test                           PASS=35  FAIL=0   STATUS=PASS
  factory-halt-classification-test          PASS=12  FAIL=0   STATUS=PASS
  factory-append-only-test                  PASS=11  FAIL=0   STATUS=PASS
  factory-closure-status-check              PAIR_OK=6  PAIR_FAIL=0  STATUS=PASS
  shell-loc-gate                            PASS
  factory-no-python-check                   POLYC_TOOLS_TRACKED_PYTHON=15
                                            POLYC_TOOLS_TRACKED_INSPECTED=2804
                                            STATUS=FAIL (informational; checker
                                            not yet wired into gate-fast per
                                            C2.9 residue)

Self-host C2.2 invariants:
  ./build/selfhost-component selftest       SHC_SELFTEST_PASS=13  FAIL=0
  STAGE=0 build  identifier_scanner         BUILD_RC=0  SYMBOL_CHECK=PASS
                                            OUTPUT_SHA256=a1b620c0...854f
  STAGE=1 build  identifier_scanner         BUILD_RC=0  SYMBOL_CHECK=PASS
                                            OUTPUT_SHA256=a1b620c0...854f
  STAGE=2 build  identifier_scanner         BUILD_RC=0  SYMBOL_CHECK=PASS
                                            OUTPUT_SHA256=a1b620c0...854f
  bootstrap04-test                          B1 fixed point 15/15 PASS
  bootstrap04-cursor-test                   6/6 cursor fixed point PASS
  bootstrap04-lexer-seam-test               6/6 byte-identical PASS

NEW REMOTE-SIDE GATES (imported by this merge):

  shell-budget-gate                         STATUS=FAIL  (rc=1)
                                            B4 unbudgeted paths (4):
                                              - evidence/.../extract-signature.sh
                                              - scripts/quality/factory-no-python-check.sh
                                              - scripts/quality/selfhost-component-registry.sh
                                              - tools/selfhost/selfhost-component.sh
                                            Three of these predate the merge
                                            (local) and one (extract-signature.sh)
                                            arrived with the remote. All are
                                            small (<=68 LOC). This is the exact
                                            residue class that ACT-POLYC-
                                            INTEGRATION-PREBOOTSTRAP-GATES01 R4
                                            was opened to own (binding shell-
                                            budget-gate into the canonical gate
                                            graph + closing the budget for these
                                            paths). The remote's own HALT/CLOSE
                                            narrative at ACT-POLYC-TOOLING-SHELL-
                                            BUDGET01 explicitly anticipated this
                                            state.

  shell-budget-gate-test                    STATUS=FAIL  (rc=1)
                                            Same 4 unbudgeted paths; N4 / N10
                                            gate assertions fail.

  formal-dafny                              STATUS=PASS
                                            Dafny 4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2
                                            Z3 4.12.1 (solver-bound via
                                            --solver-path)
                                            "Dafny program verifier finished with
                                             17 verified, 0 errors"
                                            AUDIT_FINDINGS=0  AUDIT_GATE=PASS
                                            (I1..I7 invariants mechanically
                                             preserved; no -axiom or assume
                                             outside the documented allowances)

BINDING RESULT TABLE
--------------------
REMOTE_MAIN_FETCHED             = YES
LOCAL_HISTORY_REWRITTEN         = NO
MERGE_COMMIT                    = YES (0728b53, two-parent true merge)
DAFNY_HISTORY_PRESERVED         = YES
C2_2_HISTORY_PRESERVED          = YES

FACTORY_GATES                   = PASS  (5/5 factory-* + shell-loc-gate)
SELFHOST_COMPONENT_SELFTEST     = PASS_13_OF_13
SELFHOST_STAGE_EQ               = PASS_3_OF_3 (identical SHA256)
F_NO_PYTHON                     = 15  (pre-merge baseline conserved)
BOOTSTRAP04_FIXED_POINT         = 15/15
BOOTSTRAP04_CURSOR_FIXED_POINT  = 6/6
BOOTSTRAP04_LEXER_SEAM          = 6/6

DAFNY_GATE                      = PASS (17 verified, 0 errors; audit 0)
SHELL_BUDGET_GATE               = FAIL (B4 unbudgeted: 4 known paths)
SHELL_BUDGET_GATE_TEST          = FAIL (same; expected per ACT-POLYC-
                                          INTEGRATION-PREBOOTSTRAP-GATES01 R4)

MERGE_INTRODUCED_REGRESSION     = NONE in C2.2 invariants; the four
                                   unbudgeted paths are a known imported
                                   condition (3 pre-existing, 1 added by
                                   the remote); the merged score.py is
                                   NOT in the merged tree (recorded as
                                   P1 residue).

C2_3_ENTRY_GATE                 = OPEN  (with documented residue)

RESIDUE (F11)
-------------
P0  none introduced by this merge
P1  evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c2/score.py:
      tracked Python source from the remote side, not introduced
      into the merged tree. Owner of remediation: a future bounded
      correction ACT (likely SHELL-BUDGET01-CORRECTION02).
P1  Four B4-unbudgeted shell paths in scripts/quality/, tools/selfhost/,
      and evidence/. Owner of remediation: ACT-POLYC-INTEGRATION-
      PREBOOTSTRAP-GATES01 R3 + R4.

NEXT ACT
--------
Continue ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.3:
  factory-halt-classification.py -> PolyC port.
The merge is in; C2.3 entry gates are OPEN. The two P1 residues are
pre-existing or imported conditions owned by other ACTs and do not
block C2.3's per-F15/per-F7 scope.

