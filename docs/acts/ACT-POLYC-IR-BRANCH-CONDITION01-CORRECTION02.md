# ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION02

Status: PASS.
Inherits from: CORRECTION01 (PASS on substance, but with stale
              closure identity bookkeeping).
Goal: docs/evidence-only closure identity repair. Three
      bookkeeping defects must be corrected; no production
      code changes permitted.

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
   - Update N from 2 to 3
   - Update HEAD~N recipe from HEAD~2 to HEAD~3
   - Update CORRECTION01_COMMIT list from
       574840d / 7820bf5
     to
       574840d / de90851 / 50a158e
   - Update "commits on top of impl" from 2 to 3

2. HANDOFF:
   - Remove the self-pinning CORRECTION01_FINAL=de90851 line
   - Add mechanical binding:
       CORRECTION01_IMPL_SUBJECT = cbf726ed9399
       VERIFY_WITH:
           SUBJECT=$(...)
           test "$(git rev-parse HEAD~3 | cut -c1-12)" = "$SUBJECT"
       FINAL_HEAD:
           authoritative = git rev-parse HEAD
           do not embed a self-referential SHA
   - Optionally record 50a158e historically as
     CORRECTION01_LOOP_BREAKER

3. ACT:
   - Status: HALT_CORRECTION01_CLOSURE_IDENTITY → CORRECTION02 OPEN
     → CORRECTION02 PASS after the bounded repair lands
   - AC-C09: change "tos.HH rc=0" wording to
       "The historical `--emit-llvm` rc=0 transcript is
        reclassified as a shell-capture artifact; actual hcc
        rc=1."

4. Verify (mechanical, not F6):
   - SUBJECT=$(grep ^SUBJECT evidence/.../gate-push-impl/log.txt | head -1 | cut -d= -f2)
   - test "$(git rev-parse HEAD~3 | cut -c1-12)" = "$SUBJECT"
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

F-CM1  If the depth check HEAD~3 != impl commit SHA, HALT
       with HALT_IDENTITY_BINDING_DIVERGED. Do NOT silently
       widen N to a value that happens to match.

F-CM2  If any non-doc/evidence file would need to change to
       satisfy the reviewer's bookkeeping correction, HALT
       with HALT_SCOPE_EXPANSION_REQUIRED. The reviewer's
       brief explicitly excludes src/.

## Closure

CORRECTION02 closes PASS when:

- closure-facts.txt reports N=3 and the correct commit list
- HANDOFF uses mechanical binding (no self-pinning)
- ACT status moved OPEN → PASS via this bounded repair
- AC-C09 wording corrected
- Mechanical verification recipe produces PASS

If any of these cannot be satisfied without scope expansion,
this ACT closes HALT_SCOPE_EXPANSION_REQUIRED, not PASS.

That was correct when first drafted (before the loop-breaker
was added). After the loop-breaker (`50a158e`), the actual
depth is N=3 (HEAD~3 = impl commit).

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
