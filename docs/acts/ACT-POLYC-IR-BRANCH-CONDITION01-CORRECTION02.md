# ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION02

Status: SUPERSEDED by CORRECTION03.
Inherits from: CORRECTION01 (PASS on substance, but with stale
              closure identity bookkeeping).
Goal: docs/evidence-only closure identity repair. Three
      bookkeeping defects must be corrected; no production
      code changes permitted.

CORRECTION03 note (2026-09-08): the CORRECTION02 ACT body below
preserved the fixed-depth `HEAD~3` contract in `## Required
repair`, `F-CM1`, and `## Closure`. After CORRECTION02 itself
landed, that contract falsified itself (HEAD~3 became the
substantive commit, not the impl). CORRECTION03 replaces the
fixed-depth references throughout this file with the dynamic
DEPTH rule. The historical wording is preserved below for
audit (F14); the **authoritative** contract is now the
CORRECTION03 dynamic recipe.

## Reviewer findings (CORRECTION01 closure)

The substantive corrections in CORRECTION01 were accepted:

  Implementation cbf726e                       PASS (preserved)
  IR_BR canonicalization                       PASS
  AC-23 real LLVM requalification              PASS (12/0)
  LLVM spike                                   PASS (12/0)
  AC-26 corrected IR/native distinction        PASS
  shell rc artifact diagnosis                  PASS
  production changes in CORRECTION01           NONE
  NEXT LLVM engineering ACT                    technically ready

But three closure-bookkeeping defects remain.

## P0-1: closure-facts.txt reports N=2, actual depth is N=3

The committed `closure-facts.txt` says N=2 and pins HEAD~2.

## Required repair (docs/evidence only)

This ACT is bounded to:

1. closure-facts.txt:
   - Update N from 2 to 3 (historical depth from 50a158e to
     impl cbf726e at CORRECTION01 closure)
   - Update CORRECTION01_COMMIT list from
       574840d / 7820bf5
     to
       574840d / de90851 / 50a158e
   - Update "commits on top of impl" from 2 to 3
   - [superseded by CORRECTION03: also fix $SUBJ typo;
     replace fixed HEAD~3 with dynamic DEPTH]

2. HANDOFF:
   - Remove the self-pinning CORRECTION01_FINAL=de90851 line
   - Add mechanical binding:
       CORRECTION01_IMPL_SUBJECT = cbf726ed9399
       VERIFY_WITH:
           SUBJECT=$(...)
           DEPTH=$(git rev-list --count $SUBJECT..HEAD)
           test "$(git rev-parse HEAD~$DEPTH | cut -c1-12)" = "$SUBJECT"
       FINAL_HEAD:
           authoritative = git rev-parse HEAD
           do not embed a self-referential SHA
   - Optionally record 50a158e historically as
     CORRECTION01_LOOP_BREAKER
   - [superseded by CORRECTION03: also drop "Expected today
     DEPTH=3" snapshot; recipe alone is the contract]

3. ACT:
   - Status: HALT_CORRECTION01_CLOSURE_IDENTITY → CORRECTION02 OPEN
     → CORRECTION02 SUPERSEDED by CORRECTION03 after this repair
   - AC-C09: change "tos.HH rc=0" wording to
       "The historical `--emit-llvm` rc=0 transcript is
        reclassified as a shell-capture artifact; actual hcc
        rc=1."

4. Verify (mechanical, not F6):
   - SUBJECT=$(grep ^SUBJECT evidence/.../gate-push-impl/log.txt | head -1 | cut -d= -f2)
   - DEPTH=$(git rev-list --count $SUBJECT..HEAD)
   - test "$(git rev-parse HEAD~$DEPTH | cut -c1-12)" = "$SUBJECT"
   - git diff --check  (no whitespace-only corruption)
   - git status --short   (worktree clean after repair)

## Out of scope (F7)

- Modifying src/ir.c or any other src/* file.
- Modifying LLVM lowering, tests, scripts, Makefile.
- Touching the implementation commit cbf726ed9399.
- Re-running gate-push or llvm-spike-test (the prior captured
  output remains valid; this ACT only corrects bookkeeping).
- Touching the predecessor CORRECTION01 evidence except the
  three files named above (F14: historical evidence remains
  historical).

## Failure modes

F-CM1  If `git merge-base --is-ancestor "$SUBJECT_FULL" HEAD`
       is false, HALT with HALT_IDENTITY_BINDING_DIVERGED.
       DEPTH must always be computed, never prescribed.
       [superseded the original F-CM1 that said "HEAD~3 !=
        impl commit SHA"; that contract falsified itself when
        CORRECTION02 itself landed.]

F-CM2  If any non-doc/evidence file would need to change to
       satisfy the reviewer's bookkeeping correction, HALT
       with HALT_SCOPE_EXPANSION_REQUIRED. The reviewer's
       brief explicitly excludes src/.

## Closure

CORRECTION02 closes when:

- closure-facts.txt reports the historical CORRECTION01 commit
  chain and binding contract (originally stated N=3; that
  wording is preserved as historical fact, with the dynamic
  DEPTH rule being the actual binding contract after
  CORRECTION03)
- HANDOFF uses mechanical binding (no self-pinning)
- ACT status moved OPEN → SUPERSEDED via the bounded repair
- AC-C09 wording corrected
- Mechanical verification recipe (dynamic DEPTH) produces PASS

If any of these cannot be satisfied without scope expansion,
this ACT closes HALT_SCOPE_EXPANSION_REQUIRED, not PASS.

At CORRECTION01 closure the actual depth was N=3
(HEAD~3 from FINAL_HEAD = impl cbf726e). After CORRECTION02
and CORRECTION03 added more commits on top, the current
DEPTH (computed dynamically) is 4 from HEAD to cbf726e.
The historical statement "N=3 at CORRECTION01 closure" is
preserved; the current binding uses dynamic DEPTH.

## P0-2: HANDOFF CORRECTION01_FINAL self-pinning (stale)

The committed HANDOFF pins CORRECTION01_FINAL = de90851 and
acknowledges drift in a DRIFT NOTE. The actual FINAL_HEAD is
the loop-breaker `50a158e`. Self-pinning plus drift note is
exactly the stale-self-identity class we eliminated earlier.
Correct binding uses mechanical verification, not committed
self-SHA.

## P1: ACT AC-C09 references wrong finding ("tos.HH rc=0")

AC-C09 currently says `tos.HH rc=0`. The actual finding is
the `--emit-llvm without LLVM support rc=0` transcript — a
shell-capture artifact, not an hcc bug. P1 (evidence itself
correct; only contract text stale).
