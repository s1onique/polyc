# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 — C1 RED

C1 of this ACT captures the mechanical evidence that proves
the predecessor ACT's gate-push failure is **not attributable**
to its production delta, plus the three hygiene witnesses the
predecessor's HANDOFF listed under one over-broad P1 entry.

## Files in this directory

- `red-grep-summary.txt` — byte-identical pre-/post- C2
  comparison of the four gep01 FAIL rows (AC-C1.1, AC-C1.2,
  AC-C1.3 of the ACT).
- `red-hygiene-witnesses.txt` — hygiene residue (a) `[dbg]`
  stale log lines, (b) seven fresh `src/aarch64.c` warnings,
  (c) gep01 four-failure aggregate decomposed.

## RED claim

The predecessor ACT (`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`)
recorded `GEP01_PASS=26 GEP01_FAIL=4` and committed
`ACT-Verdict: PASS` at C4, but its own
`c4/acceptance-matrix.txt` explicitly marks AC18 / AC29 as
FAIL. This ACT's C1 RED captures mechanical proof that the
gep01 failure is byte-identical pre-/post- the predecessor's
`src/aarch64.c` production delta.

## Mechanical proof

The predecessor's `c3/llvm-gep01-test.txt` (line 220-221)
shows:

```
220:GEP01_PASS=26
221:GEP01_FAIL=4
```

The predecessor's predecessor
(`ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01`)
recorded the **same** counts at line 428-429 of
`c3/gate-push-correction01.log` against a tree that did NOT
contain the predecessor's `src/aarch64.c` delta.

The four FAIL row TEXTS are also byte-identical (see
`red-grep-summary.txt`):

```
diff /tmp/pre_d1.txt /tmp/post_d1.txt  -> exit 0 (same)
diff /tmp/pre_d2.txt /tmp/post_d2.txt  -> exit 0 (same)
```

Therefore the gep01 failure mode is unchanged by the C2
production delta:

```
production_subject_attribute = NONE
gate_push_failure_attributable_to_production_delta = FALSE
```

Under v2 doctrine (`docs/factory/DOCTRINE.md` §25):

```
HALT_CLASS  = GOVERNANCE
BLOCKS_NEXT = NO
```

The predecessor's C4 trailer (`ACT-Verdict: PASS`) is
preserved (F14); this ACT records an additive
`ACT-Corrected-Verdict` rather than rewriting history.

## Hygiene residue captured

```
(a) [dbg] stale log lines  -> P1 evidence-hygiene cleanup
(b) 7 fresh aarch64.c warnings -> P1 warning cleanup
(c) gep01 D1+D2 4-failure aggregate -> separate bounded ACT
```

Items (a), (b), (c) are recorded under
`red-hygiene-witnesses.txt`. This ACT does NOT take ownership
of them; they are listed for a future bounded cleanup ACT or
the gep01 recovery ACT.

## Reproduction commands

```sh
# AC-C1.1, AC-C1.2, AC-C1.3
PRE=evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/c3/gate-push-correction01.log
POST=evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c3/llvm-gep01-test.txt
grep -n 'GEP01_PASS\|GEP01_FAIL' "$PRE" "$POST"
grep -n 'readat.HC: SHAPE_DEPENDENT' "$PRE" "$POST"
grep -n 'could not read cap verifier output' "$PRE" "$POST"

# Byte-identical text comparison
grep 'readat.HC: SHAPE_DEPENDENT' "$PRE" > /tmp/pre_d1.txt
grep 'readat.HC: SHAPE_DEPENDENT' "$POST" > /tmp/post_d1.txt
diff /tmp/pre_d1.txt /tmp/post_d1.txt   # expect: no output, exit 0

grep 'could not read cap verifier output' "$PRE" > /tmp/pre_d2.txt
grep 'could not read cap verifier output' "$POST" > /tmp/post_d2.txt
diff /tmp/pre_d2.txt /tmp/post_d2.txt   # expect: no output, exit 0

# AC-C2.1 / AC-C2.2 — production delta not re-mutated
git diff --stat b76f0d8..HEAD -- src/aarch64.c src/x86_64.c
# expect: empty

# AC-C3.1..C3.5 — predecessor evidence not mutated (F14)
git diff --stat b76f0d8..HEAD -- \
  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c1/ \
  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c2/ \
  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c3/ \
  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c4/ \
  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/HANDOFF.md
# expect: empty
```
