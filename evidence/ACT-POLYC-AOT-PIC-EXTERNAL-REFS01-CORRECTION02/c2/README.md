# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02 — C2 IMPL

C2 captures the v2-correct trailer set as a plain-text
artifact (since amending the historical commit is forbidden)
plus a ROADMAP correction note under the CORRECTION01 status
block.

## Files in this directory

- `v2-correct-trailer-set.txt` — the trailer set that SHOULD
  have been committed at `505b007`. Captured here as a
  plain-text artifact; verifier verdict on this trailer set
  is `STATUS=PASS`.
- `green-invariant-check.txt` — F1 identity, AC-02.1..02.4
  live checks (nothing outside scope was mutated), v2-correct
  verifier verdict, append-only invariant PASS.

## What this ACT does

1. Captures the v2-correct trailer set as a plain-text
   artifact (NOT as a trailer modification of `505b007`).
2. Documents the HALT classification binding surface
   (descriptive artifacts only):
   - ROADMAP.md CORRECTION01 status block
   - CORRECTION01 c4/closure-summary.txt PRE-CONDITION
     CLAIM block
   - CORRECTION01 c4/roadmap-transition.txt entire document
3. Adds a ROADMAP correction note under the CORRECTION01
   status block, naming the defect and the v2-correct
   trailer set.
4. Does NOT amend `505b007` (forbidden by F-GIT-IDENTITY
   + §23).

## IMPL claim

The v2-correct trailer set passes the verifier:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
```

Verifier output (captured at
`v2-correct-trailer-set.txt`):

```
MODE=ACT
STATUS=PASS
ACT=ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
PHASE=CLOSE
VERDICT=PASS
HALT_CLASS=
BLOCKS_NEXT=
```

`STATUS=PASS`. The HALT classification metadata for the
corrected verdict is in the descriptive artifacts (and
verifies against the `HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`
binding that the corrected verdict implies).

## Conservation gates

```
factory-append-only-test  PASS  11/11
(no amend, no rebase, no filter-branch, no git replace,
 no reset+recommit)
```

All AC-02.1..AC-02.4 invariants: empty diff vs `505b007`
on `src/`, on the CORRECTION01 evidence directories, on
the predecessor evidence directories, and on the
CORRECTION01 ACT document.
