# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 — C2 IMPL

C2 of this ACT is purely an evidence-capture phase. There is
no production code change. The implementation is:

```
classification: HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO
correction:     ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
                (preserves predecessor's ACT-Verdict: PASS
                 trailer; F14 does not allow rewriting)
```

## Files in this directory

- `green-invariant-check.txt` — live re-run of all C1
  invariants on the current tree (`b76f0d8`) plus F1
  identity, AC-C2.1, AC-C2.2, AC-C3.1..C3.5, AC-C4.1
  capture.

## IMPL claim

This ACT's "implementation" is to (a) capture the byte-
identical proof that the predecessor's gep01 failure is not
attributable to its `src/aarch64.c` delta, (b) freeze the
hygiene residue that the predecessor's HANDOFF listed under
one over-broad P1 entry, and (c) record the v2 classification
`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO` so that downstream
successor ACTs do not over-block on a prose-only defect.

The implementation does NOT touch `src/aarch64.c`,
`src/x86_64.c`, the predecessor evidence directories, or
the canonical libtos install. This is verified in
`green-invariant-check.txt`:

```
AC-C2.1: src/aarch64.c diff vs b76f0d8 -> empty
AC-C2.2: src/x86_64.c diff vs b76f0d8 -> empty
AC-C3.1..C3.5: predecessor evidence dirs -> empty
```

## F1 identity (recorded before any mutation)

```
branch:  main
status:  (untracked: ACT doc + this evidence dir;
          all tracked files clean)
HEAD:    b76f0d8d38d57e950e69e559e486fde0a0555175
replace: 0 entries
```

## Live byte-identical re-run

The byte-identical comparison was re-run on the current tree
to verify the C1 RED captured the right state and the state
is stable. Both `diff` runs returned exit 0 (= same):

```
D1 (SHAPE_DEPENDENT stderr marker):
    pre-C2 line text == post-C2 line text -> diff exit 0

D2 (cap verifier output unavailable, 3 rows):
    pre-C2 line texts == post-C2 line texts -> diff exit 0
```

Therefore the v2 classification holds on this tree.
