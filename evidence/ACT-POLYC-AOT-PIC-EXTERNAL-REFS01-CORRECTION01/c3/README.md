# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 — C3 EVIDENCE

C3 captures the conservation-gate evidence on the current
tree (`b76f0d8`).

## Files in this directory

- `c3-evidence-gate-run.txt` — live re-run of `make gate-fast`
  on the current tree, plus the conservation gates inherited
  from the predecessor ACT's C3 evidence.

## Conservation gates

```
unit-test      : 90/90 PASS     (predecessor c3/unit-test.txt)
jit-unit-test  : 90/90 PASS     (predecessor c3/jit-unit-test.txt)
lsp-test       : 43/43 PASS     (predecessor c3/lsp-test.txt)
gate-fast      : PASS           (re-run today, see c3-evidence-gate-run.txt)
gate-push      : FAIL on gep01  (NOT attributable to production
                                 delta; see c1/red-grep-summary.txt
                                 byte-identical proof)
```

The gate-push FAIL on gep01 is the same byte-identical
failure mode present pre-C2; the production delta did not
introduce it and does not own it. Per v2 §25 it is
`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`.

## Invariant under this ACT

```
git diff --stat b76f0d8..HEAD -- src/aarch64.c src/x86_64.c
    -> empty
git diff --stat b76f0d8..HEAD -- predecessor evidence dirs
    -> empty
git replace -l
    -> empty
```

This ACT does not re-mutate production. It does not
re-mutate predecessor evidence. It does not introduce
git-replace objects. All v2 conservation invariants
are satisfied.
