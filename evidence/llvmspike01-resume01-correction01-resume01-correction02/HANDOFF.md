HANDOFF — ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02
==========================================================================

VERDICT
-------
PASS

This ACT mechanically repaired the closure-bookkeeping defects the
reviewer identified across two rounds:

  - CORRECTION01 review: stale HEAD, stale SUBJECT, "3 commits" claim
  - CORRECTION02 review: ancestor-only is insufficient (false-GREEN
    on src/ between SUBJECT and HEAD), oracle must exit nonzero,
    snapshots must not be self-pinned as authoritative

Both rounds closed without any compiler change.

IDENTITY (oracle, dynamic binding + scope check)
------------------------------------------------

The authoritative oracle is `identity.sh`. It exits 0 only if ALL of:

    [A] GATED_SUBJECT_ANCESTOR  = YES
    [B] POST_SUBJECT_DELTA      = ALLOWED (docs/, evidence/...01/, evidence/...02/)
    [C] C1_IMMUTABILITY         = YES (3 historical files bit-identical to bde6045a)
    [D] DIFF_CHECK              = PASS (rc=0)

Each failure path exits with a distinct non-zero code (1/2/3/4/5).

`identity.sh` resolves the gate subject dynamically from the committed
transcript (the reviewer-demanded pattern), not from a hard-coded SHA.

Live run output (at HEAD = 6e7bc4d):

```
[A] GATED_SUBJECT_ANCESTOR ...
    PASS: a5818c6 is ancestor of 6e7bc4d
[B] POST_SUBJECT_DELTA ...
    PASS: all descendants in allowed paths (docs/, evidence/...01/, evidence/...02/)
[C] C1_IMMUTABILITY ...
    PASS: C1 files unchanged from bde6045a200a1526435fd161f41b59e02df012b7
[D] DIFF_CHECK ...
    PASS: rc=0

OK: all invariants hold at HEAD=6e7bc4d
exit=0
```

Negative test (verifying invariant B catches behaviour-affecting
descendants): a side-branch committing `src/llvm-backend.c` change
post-SUBJECT correctly exits 2 with FAIL message:

```
[B] POST_SUBJECT_DELTA ...
    FAIL: behaviour-affecting descendants exist after gated subject:
      src/llvm-backend.c
exit=2
```

TOPOLOGY
--------
13 commits in bde6045a..HEAD (live count). See `topology.txt` for the
truthful enumeration, oldest-first.

ROOT CAUSE OF THE PRIOR HALTS
-----------------------------
Two self-pinning defects:

  ROUND 1 (CORRECTION01): HANDOFF/identity hard-coded HEAD=f703cec
  while the substantive tree was a5818c6 (2 docs commits ahead).

  ROUND 2 (CORRECTION02): the closure relied on
    merge-base --is-ancestor SUBJECT HEAD
  which only proves topology, not conservation. A commit between
  SUBJECT and HEAD that touches src/ would inherit the gate PASS
  even though the substantive tree's verdict no longer applies.

IMPLEMENTATION
--------------

This ACT adds ONE functional commit (oracle strengthening) on top of
the docs-only closure repair from CORRECTION02:

  6e7bc4d fix(oracle): strengthen identity.sh to verify ANCESTOR + DELTA-SCOPE

  - Added invariant B: post-subject delta must be in allowed paths
    (docs/, evidence/...01/, evidence/...02/). merge-base alone permits
    false-GREEN on src/ changes between SUBJECT and HEAD.
  - Added invariant C: C1 historical files bit-identical to bde6045a.
  - snapshot.txt + identity.txt explicitly labelled SNAPSHOT (NOT
    authoritative). Authoritative oracle is the script exit status.
  - All checks exit nonzero on failure (set -e + exit N).

GATES
-----
* gate-push at HEAD = VERDICT=PASS, SUBJECT=a5818c66cbbb (substantive
  tree a5818c6 is ancestor of HEAD, dynamic binding YES).
* llvm-spike-test harness at HEAD = PASS=13/FAIL=0.
* Memory-op matrix after = alloca=0 store=0 load=0.
* diff-check HEAD = rc=0.
* identity.sh oracle at HEAD = exit 0, all 4 invariants PASS.
* False-GREEN tests (side-branches, removed):
    - src/llvm-backend.c change post-subject -> exit 2 (B catches it)
    - C1 mutation via test commit -> exit 2 (B catches it via path
      that is not in allowed paths; invariant C is the structural
      backup if C1 ever moves into an allowed parent dir).

SCOPE
-----
Authorised ACT scope only. No source modifications. No edits to the
previous ACT's evidence tree.

Production:
    (none)
Tests:
    (none)
Evidence (NEW or MODIFIED, this ACT only):
    docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02.md
    evidence/llvmspike01-resume01-correction01-resume01-correction02/
        identity.sh    (oracle; exit-code authoritative)
        snapshot.txt   (SNAPSHOT, not authoritative)
        identity.txt   (SNAPSHOT, not authoritative)
        topology.txt   (SNAPSHOT, truthful enumeration)
        dynamic-binding.txt  (records oracle invariants A/B/C/D)
        HANDOFF.md     (this file)
        final-verification.txt (last recorded run output)

RESIDUE
-------
P2: the previous ACT's committed HANDOFF.md and identity.txt remain
    in their stale state at HEAD. They are historical evidence of the
    self-pinning defect per F14 and are not rewritten; the closure
    repair lives in this ACT's evidence dir.

P2: the closure transcript for the previous ACT now lives in two
    places — the previous ACT's `gate-push-implementation.log`
    (SUBJECT=f703cec, accurate at that commit) and this ACT's
    `gate-push-final.log` (SUBJECT=a5818c66cbbb, accurate for the
    substantive tree). Both are accurate at their respective commit
    times; the binding to the substantive tree is the dynamic-
    binding check in `dynamic-binding.txt` (and now strengthened by
    invariant B in `identity.sh`).

P2 (reviewer refinement): "second store" does not necessarily mean
    "multiple reaching definitions" in the data-flow-theory sense;
    a sequential first definition may be dead before the second.
    Rejecting all second stores is deliberately stricter and safe.
    Wording change deferred.

P2: invariant D (`git diff --check HEAD`) catches only merge-conflict
    whitespace, not arbitrary trailing-whitespace additions. If
    broader hygiene is needed, replace D with a stricter linter.
    Not in this ACT's scope.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE01 — turn the bounded experiment into a
deliberately-supported scalar LLVM backend core; canonise the
SSA-only local contract; address the LLVMBuildTrunc residue.
