HANDOFF — ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02
==========================================================================

VERDICT
-------
PASS

The HALT_CORRECTION01_CLOSURE_IDENTITY review found that the prior ACT
closed with a stale identity (committed `HEAD=` was `f703cec` but the
digest it was reviewed against pointed at `a5818c6`). The same review
also flagged the "3 commits" topology claim and the gate transcript
whose `SUBJECT` did not match `git rev-parse HEAD` at the substantive
tree.

This ACT mechanically repairs those three bookkeeping items.
**No source code changed.** No new compiler behaviour.

IDENTITY (dynamic binding)
--------------------------

```
ENTRY_HEAD    = bde6045a200a1526435fd161f41b59e02df012b7
```

Closure subject (resolved dynamically from the gate log, per the
reviewer's exact demanded pattern):

```sh
SUBJECT=$(grep '^SUBJECT=' gate-push-final.log | head -1 | cut -d= -f2)
SUBJECT_FULL=$(git rev-parse "$SUBJECT^{commit}")
git merge-base --is-ancestor "$SUBJECT_FULL" HEAD
```

Result of running the above:

```
SUBJECT_FULL = a5818c66cbbb6f447ea636f30925b63e408d0aa4
HEAD         = a5818c66cbbb6f447ea636f30925b63e408d0aa4
SUBJECT_FULL ancestor of HEAD = YES
```

(See `identity.txt` and `dynamic-binding.txt` for the live run.)

TOPOLOGY (truthful enumeration)
-------------------------------

`git log --oneline --reverse bde6045a..HEAD`:

```
50a43c6 test(llvm): RESUME01 CORRECTION01-RESUME01 RED phase
1cfc34a refactor(llvm): lower bounded scalar locals as SSA values
d52d5af docs(polyc): close deferred LLVM spike correction ACT
910c6ec test(llvm): CORRECTION01-RESUME01-CORRECTION01 RED + C1 restoration
5eed2af fix(llvm): reject SSA-local multiple reaching stores
1b63225 docs(polyc): close CORRECTION01-RESUME01-CORRECTION01 ACT
f703cec fix(harness): keep harness transcripts out of C1 evidence dir
a5818c6 docs(polyc): update HANDOFF/identity with final CLOSURE shape
```

Count: `git rev-list --count bde6045a..HEAD` = 8.

The previous ACT's HANDOFF spoke of "3 commits" as a *semantic
grouping* of RED/IMPL/CLOSURE. The reviewer reasonably read it as a
*topology* claim. From this ACT forward, the topology is stated in
absolute terms (`N commits in ENTRY..HEAD`) and never as a semantic
grouping count. F12 says "small truthful commits" but does not impose
a numerical cap.

ROOT CAUSE OF THE PRIOR HALT
----------------------------
Stale self-pinned identity. The previous HANDOFF and identity.txt
both hard-coded `HEAD = f703cec`, but two further commits had already
landed (`f703cec` itself + `a5818c6`). The committed gate transcript
was the one that ran at `f703cec`, but the substantive tree was
`a5818c6`. This is the same class of self-pinning defect Factory
has already burned several corrections eliminating.

IMPLEMENTATION (this ACT)
-------------------------

Docs/evidence only. No source code modifications:

1. `docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02.md`
   — new ACT contract for the closure repair.
2. `evidence/llvmspike01-resume01-correction01-resume01-correction02/topology.txt`
   — truthful enumeration of the lineage (oldest-first, with roles).
3. `evidence/llvmspike01-resume01-correction01-resume01-correction02/gate-push-final.log`
   (and `.sha256`, `.b64`) — re-captured at the substantive final
   tree `a5818c6`. SUBJECT=a5818c66cbbb.
4. `evidence/llvmspike01-resume01-correction01-resume01-correction02/dynamic-binding.txt`
   — running the reviewer's exact demanded pattern against the
   committed transcript.
5. `evidence/llvmspike01-resume01-correction01-resume01-correction02/identity.txt`
   — replaces the stale `HEAD = f703cec` with the dynamic-binding
   pattern.
6. `evidence/llvmspike01-resume01-correction01-resume01-correction02/llvm-spike-test.matrix-final.txt`
   — re-run at HEAD for completeness. PASS=13/FAIL=0.
7. `evidence/llvmspike01-resume01-correction01-resume01-correction02/HANDOFF.md`
   (this file).

The previous ACT's evidence tree is **not modified**. F14 forbids
rewriting historical evidence to look newer than it was; the stale
state recorded in the previous ACT's `HANDOFF.md` and `identity.txt`
is itself historical evidence of the self-pinning defect.

GATES
-----
* gate-push at HEAD = VERDICT=PASS, SUBJECT=a5818c66cbbb
  (the committed log proves this; see `dynamic-binding.txt`).
* llvm-spike-test harness at HEAD = PASS=13/FAIL=0.
* Memory-op matrix after = alloca=0 store=0 load=0.
* diff-check HEAD = rc=0.
* P0-2 mechanical AC = empty diff (verified AFTER the harness run).

SCOPE
-----
Authorised ACT scope only. No source modifications. No edits to the
previous ACT's evidence tree.

Production:
    (none)
Tests:
    (none)
Evidence (NEW, this ACT only):
    docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02.md
    evidence/llvmspike01-resume01-correction01-resume01-correction02/
        HANDOFF.md, identity.txt, topology.txt,
        dynamic-binding.txt,
        gate-push-final.log (+ .sha256, .b64),
        llvm-spike-test.matrix-final.txt

RESIDUE
-------
P2: the previous ACT's committed `HANDOFF.md` and `identity.txt`
    remain in their stale state at HEAD (post-this-ACT). They are
    historical evidence of the self-pinning defect per F14. Not
    rewritten; the closure repair lives in this ACT's evidence dir.

P2: the closure transcript for the previous ACT now lives in two
    places — the previous ACT's `gate-push-implementation.log`
    (whose SUBJECT=f703cec, reflecting the state at that docs
    commit) and this ACT's `gate-push-final.log`
    (SUBJECT=a5818c66cbbb, reflecting the substantive final tree).
    Both are accurate at their respective commit times; the
    binding to the substantive tree is the dynamic-binding check
    documented in `dynamic-binding.txt`.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE01 (unchanged from prior ACT's residue).
