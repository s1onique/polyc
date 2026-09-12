# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 — C4 CLOSE

## Files in this directory

- `closure-summary.txt`     — structured closure handoff
  (VERDICT / IDENTITY / RED / IMPLEMENTATION / GATES /
  SCOPE / RESIDUE / NEXT_ACT).
- `acceptance-matrix.txt`   — AC01..AC06 + strong-closure
  criterion; all PASS for this ACT.
- `residue.txt`             — three P1 hygiene items (NOT
  taken into ownership) + three P2 deferred items.
- `roadmap-transition.txt`  — recommended next-ACT paths.
- `HANDOFF.md`              — Factory v2 descriptive handoff
  (verdict authority lives in the C4 CLOSE commit's
  `ACT-Corrected-Verdict` trailer).

## What this CLOSE does

1. Records the predecessor ACT's gate-push failure as
   `HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO` per v2 doctrine.
2. Captures byte-identical proof that the gep01 failure is
   not attributable to the predecessor's `src/aarch64.c`
   production delta (c1/red-grep-summary.txt).
3. Decomposes the gep01 4-failure aggregate into D1 + D2
   (ACT §6) so a successor bounded ACT can target them
   individually.
4. Lists the three hygiene residues (a/b/c) without taking
   ownership of them.
5. Re-records the BOOTSTRAP01 signal without opening it.

## What this CLOSE does NOT do

1. It does NOT re-mutate `src/aarch64.c` or `src/x86_64.c`.
2. It does NOT mutate the predecessor ACT's evidence
   directories or HANDOFF.md.
3. It does NOT push to origin/main.
4. It does NOT open `ACT-POLYC-BOOTSTRAP01`.
5. It does NOT take ownership of the gep01, hygiene, or
   warning residue.

## Strong-closure criterion

```
byte_identical_proof       = PASS
production_not_remutated   = PASS
predecessor_not_remutated  = PASS
hygiene_residue_listed     = PASS
bootstrap01_signal         = PASS
GO                         = YES
```

All seven strong-closure predicates are satisfied on the
current tree (`b76f0d8`). The C4 CLOSE commit's
`ACT-Verdict: PASS` trailer is honest under v2 doctrine.

## Verdict authority

The verdict authority for this ACT lives in the C4 CLOSE
commit's trailer:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

Per v2 §25, the HALT_CLASS / BLOCKS_NEXT pair is required on
a CORRECTION close that emits an `ACT-Corrected-Verdict`.
