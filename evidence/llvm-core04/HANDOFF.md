# CORE04 HALT HANDOFF — HALT_RED_NOT_REPRODUCED

**ACT:** ACT-POLYC-LLVM-CORE04
**Verdict:** HALT_RED_NOT_REPRODUCED
**Closed by:** commit on main, identity recorded in `git rev-parse HEAD`.
**Date:** 2026-08-09

---

## 1. What CORE04 set out to do (verbatim from the ACT)

```text
CORE04 closes two residue items recorded in
ACT-POLYC-LLVM-CORE03 §8:

  M1. assert every `case IR_X:` in the dispatch has a
      matching `kLLVMBackendCapability[]` row (the reverse
      of CORE03 M1).
  M2. per-class execution counters (e.g.
      `n_rejections_per_class`) emitted in the harness
      summary.
```

The reviewer accepted authorization to begin C1.

---

## 2. Why the halt fired (before any production change)

The reviewer (and recon) established that CORE04's M1 is
stale against the current predecessor chain:

- `ACT-POLYC-LLVM-CORE03-CORRECTION01` introduced
  `scripts/quality/llvm-cap-table-verifier.py` with
  invariant **I2**, defined in the file header as:

  > Every explicit `case IR_X:` arm or `if (ins->op == IR_X)`
  > short-circuit in the dispatch corresponds to a row in
  > kLLVMBackendCapability[]. (Reverse of I1; prevents the
  > dispatch from claiming a class for an opcode that has
  > no contract row.)

- `CORRECTION02` then added the **arm-local** body
  extractor (M2 of that ACT).
- `CORRECTION03` residue (line 246-247) refines the
  remaining work as: *"P1: get_dispatch_arms() still
  discovers `if (ins->op == IR_X)` short-circuits in any
  function, while the stricter body extractor scopes to
  llLowerInstr"* — a **discovery-scope mismatch**, not an
  absence of inverse-coverage checking.

A live run of the existing verifier confirms:

```text
$ python3 scripts/quality/llvm-cap-table-verifier.py
PASS  parsed 56 IrOp enum entries (IR_NOP=0 .. IR_ASM=55)
PASS  loaded 56 capability rows via hcc --print-cap-table
PASS  dispatch scan: 48 case arms in llLowerInstr,
      9 if-shorts anywhere
PASS  M1 round-trip: 56 rows round-trip byte-identical
PASS  M2 arm-group scan: 21 case-arm groups,
      7 if-arm bodies in dispatch
...
PASS  I3: harness queries hcc --print-cap-table
PASS: dispatch <-> capability <-> harness bound
rc=0
```

The verifier's `check_reverse()` function (lines 603-616)
is exactly the M1 the ACT claimed did not exist.

CORE04's principal RED is therefore **NOT REPRODUCED**.
Per CORE04 §8 (`HALT_RED_NOT_REPRODUCED`), execution halts
before any production change.

The additional design criticism (third hand-maintained C
list adds duplication rather than removing it) is also
adopted; the proposed `llValidateDispatchCoverage()`
runtime list is dropped, not deferred.

---

## 3. AC09 also fails to bind

CORE04's adversarial witness AC09 was:

```text
add a fictitious `case IR_FAKE_OP:` without a capability
row, expect the runtime validator to fail.
```

`IR_FAKE_OP` is not a member of the `IrOp` enum, so
`case IR_FAKE_OP:` fails C compilation before any runtime
validator executes. AC09 does not test the mechanism it
claims to test. The reviewer rejects it on this ground.

A correct negative witness must use a real existing `IrOp`
and create a real dispatch-shape mismatch.

---

## 4. RED-M2 is real

The second principal RED (no per-class execution
counters) is reproduced and survives review:

```text
$ grep -nE 'n_support|n_rejected|counts_per_class' \
      src/llvm-backend.c src/llvm-backend.h \
      scripts/quality/llvm-spike-test.sh
(no matches)
```

M2 is preserved and is the second mission of the
continuation ACT (CORE04-RESUME01).

---

## 5. What is NOT authorized at this halt

Per F15, no scope expansion is allowed at halt:

- No source code change to `src/llvm-backend.c`,
  `src/llvm-backend.h`, `src/llvm-backend-cap.c`,
  `src/main.c`, or any compiler source.
- No source code change to `scripts/quality/`.
- No change to Factory v2 grammar, range-checker, or
  commit policy.
- No retroactive edits to any closed ACT or HANDOFF (F14).
- No SHA table update for CORE04 (the ACT document is
  never updated at closure under Factory v2; closure
  identity lives in the CLOSE commit's `ACT-Verdict`
  trailer).

The halt commit is a CLOSE commit and an evidence file
only.

---

## 6. Identity

- Pre-halt HEAD: `168e3293aca2551b9da010846d9043c1dcab2073`
- Halt commit:   recorded as the parent of the next commit
- Branch:        `main`
- Worktree:      clean

---

## 7. Gates at halt

```text
factory-v2-test               rc=0  PASS=35 FAIL=0
factory-closure-status        rc=0  STATUS=PASS VERDICT=PASS
llvm-cap-table-verifier       rc=0  PASS
git diff --check HEAD         rc=0
```

No production source changed. All conservation gates are
trivially satisfied.

---

## 8. Scope of this halt commit

Changed:

- `evidence/llvm-core04/HANDOFF.md` (this file, new).
- `evidence/llvm-core04/entry.txt` (new, F1 entry identity
  record).

Not changed:

- `docs/acts/ACT-POLYC-LLVM-CORE04.md` (F14 — authorization
  artifact remains historically stable; no OPEN->PASS/HALT
  mutation under Factory v2).
- Any closed ACT or HANDOFF.
- Any source/test script.
- Any Factory v2 file.
- `docs/ROADMAP.md` (ROADMAP edits accompany the RESUME01
  ACT, not this halt).

---

## 9. Residue at halt

This halt consumes none of the CORE04 missions; it only
clarifies them.

- M1 — *inverse check absent* — **WITHDRAWN**. Already
  implemented in `llvm-cap-table-verifier.py` (I2).
- M1' — *unify `get_dispatch_arms()` discovery scope with
  arm-local body extraction* — **CARRIED FORWARD** as
  RESUME01's M1.
- M2 — *per-class execution counters* — **CARRIED FORWARD**
  unchanged as RESUME01's M2.

P2 (backlog, unchanged):
- FT1, FT2, FT3.
- Per-fixture counter deltas (RESUME01-candidate future).
- Per-opcode histogram (RESUME01-candidate future).
- Legacy factory-closure-status-check retirement.
- CI enforcement of v2 trailers.

---

## 10. Next ACT

`ACT-POLYC-LLVM-CORE04-RESUME01` will open with the
corrected two missions:

```text
M1  unify get_dispatch_arms() discovery with arm-local
    body extraction into one scoped dispatch model in
    scripts/quality/llvm-cap-table-verifier.py; reproduce
    the discovery-scope mismatch adversarially; GREEN
    only after the unified scoped model rejects the
    adversarially-placed `if (ins->op == IR_X)` outside
    the real dispatch functions.

M2  per-class execution counters in the harness summary;
    decide explicitly whether counters live per-LLCtx
    invocation and how multiple functions/modules
    aggregate into harness-level totals.
```

No production code change for M1. The verifier is the
canonical seam for the inverse-coverage story; no new
hard-coded C list is added.

