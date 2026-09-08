# ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION03

Status: PASS.
Inherits from: CORRECTION02 (PASS on intent, but introduced a
              subtler identity-binding defect).
Goal: Make the identity-binding contract genuinely dynamic. No
      production code change permitted.

## Reviewer findings (CORRECTION02 closure)

Compiler/IR state remains good and is **preserved**:

```text
Implementation cbf726e                       PASS (preserved)
IR_BR canonicalization                       PASS (preserved)
AC-23 real LLVM requalification              PASS (preserved, 12/0)
LLVM spike                                   PASS (preserved, 12/0)
AC-26 corrected IR/native distinction        PASS (preserved)
shell rc artifact diagnosis                  PASS (preserved)
production changes in CORRECTION02           NONE
```

But CORRECTION02 introduced a subtler form of the same defect
it was meant to eliminate:

### P0-1: CORRECTION02 ACT itself uses fixed-depth contract

CORRECTION02's `## Required repair` and `F-CM1` say:

```text
test "$(git rev-parse HEAD~3 | cut -c1-12)" = "$SUBJECT"
F-CM1  If the depth check HEAD~3 != impl commit SHA, HALT ...
```

But the conversational explanation in the same ACT correctly
notes that dynamic `DEPTH = git rev-list --count SUBJECT..HEAD`
is the better invariant. The ACT document did not actually
change its contract to use that invariant.

After CORRECTION02 itself lands:

```text
HEAD~4 = cbf726e (impl)
HEAD~3 = 574840d (substantive)
```

So by CORRECTION02's own written F-CM1, the finished ACT
should HALT. Self-inconsistent.

### P0-2: committed mechanical recipe has a shell-variable typo

`closure-facts.txt` contains:

```sh
SUBJECT=$(...)
DEPTH=$(...)
HM=$(...)
test "$SUBJ" = "$HM" && echo PASS || echo FAIL
```

Variable `SUBJ` is never assigned. The recipe as committed
always returns FAIL (unless `SUBJ` is inherited from the
caller's environment, which itself violates hermetic-witness).

### P1-A: stale `tos.HH rc=0` wording in CORRECTION01 ACT §2

CORRECTION01 ACT §2 Scope still says:

```text
- Recording the `tos.HH rc=0` finding as P1 residue
```

The real finding (corrected in CORRECTION02) is the
`--emit-llvm` shell-RC capture artifact.

### P1-B: "Expected today DEPTH=3" prose is stale

HANDOFF.md and closure-facts.txt mix historical `N=3`
(depth from CORRECTION01 loop-breaker 50a158e to impl cbf726e)
with current-binding language that says "today DEPTH=3".

After CORRECTION02 lands, current `DEPTH=4`. The prose must
explicitly split historical depth from current binding.

## Required repair (docs/evidence only)

This ACT is bounded to:

1. closure-facts.txt:
   - Fix `$SUBJ` to `$SUBJECT` typo in committed recipe.
   - Replace "MATCH: HEAD~3 == SUBJECT == implementation commit"
     with a dynamic-Depth assertion (the rule, not a fixed
     number).
   - Split historical "For this CORRECTION01: N=3" (correct as
     history) from any current-binding rule.
   - Remove "Concrete expected output today: DEPTH=3" — that is
     not a contract; it is a snapshot.

2. HANDOFF.md:
   - Remove "Expected today: DEPTH=3" block. Replace with the
     dynamic recipe alone (no example snapshot labelled "today").

3. CORRECTION02 ACT:
   - Replace every fixed-depth `HEAD~3` reference in the
     contract (Required repair, F-CM1, Closure) with the
     dynamic `DEPTH := git rev-list --count SUBJECT..HEAD`
     contract.
   - Replace F-CM1 with the dynamic invariant.

4. CORRECTION01 ACT §2:
   - Replace `tos.HH rc=0` with `--emit-llvm` shell-RC artifact
     wording. Preserve the historical ACT body via a
     "[historical; see CORRECTION03 for corrected wording]"
     annotation (F14 forbids silently rewriting historical
     evidence).

5. Mechanical verification:
   - All assertions must use the dynamic recipe. Re-run after
     the repair and assert HEAD~DEPTH == SUBJECT_FULL and
     git merge-base --is-ancestor SUBJECT_FULL HEAD.
   - diff-check rc=0; worktree clean.

## Out of scope (F7)

- Modifying src/ir.c or any other src/* file.
- Modifying LLVM lowering, tests, scripts, Makefile.
- Touching the implementation commit cbf726ed9399.
- Re-running gate-push or llvm-spike-test.
- Touching any captured log under evidence/.
- Deleting historical ACT sections (F14).

## Failure modes

F-CM1  If `git merge-base --is-ancestor "$SUBJECT_FULL" HEAD`
       is false, HALT with HALT_IDENTITY_BINDING_DIVERGED.
       DEPTH must always be computed, never prescribed.

F-CM2  If any non-doc/evidence file would need to change to
       satisfy the reviewer's correction, HALT with
       HALT_SCOPE_EXPANSION_REQUIRED.

F-CM3  If the committed recipe still contains a shell-variable
       typo or any other executable defect, HALT with
       HALT_RECIPE_NON_EXECUTABLE. The recipe must be
       executable verbatim by a reviewer.

## Closure

CORRECTION03 closes PASS when:

- closure-facts.txt recipe is typo-free and uses dynamic DEPTH
- HANDOFF has no "Expected today DEPTH=3" snapshot
- CORRECTION02 ACT F-CM1 and contract use dynamic DEPTH only
- CORRECTION01 ACT §2 has corrected `--emit-llvm` wording
  (with F14 historical-preservation annotation)
- Mechanical verification using dynamic recipe PASSes
- All historical evidence remains visible (F14)
- diff-check rc=0; worktree clean

## Why docs/evidence-only

```text
git diff --stat 50a158e..HEAD -- src/ scripts/ Makefile
  (must remain empty)
```

The implementation commit cbf726e is preserved verbatim.
Only the binding contract that future agents use to verify
"this work is closed" is being made genuinely amend-resilient.
