# ACT-POLYC-LLVM-CORE01-CORRECTION02

**Title:** Reconcile CORRECTION01 false-GREEN closure; fresh IR_BR seam recon; ≥6 distinct rejection classes

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-CORE01-CORRECTION01` (REJECTED at `b05ea7e`,
reviewer verdict `HALT_CORE01_CORRECTION01_RECON_CONFLICT`)

**Class:** RECON / DOCS-ONLY-CLOSURE / TEST-COVERAGE

**Production semantic changes:** **FORBIDDEN** (the IMPL at `99a8531` is
correct as the reviewer confirmed; only RED-premise was wrong)

**IR / ABI / neutral-IR boundary changes:** **FORBIDDEN**

**LLVM IR lowering additions:** **FORBIDDEN**

**Target machine / execution / ORC:** **FORBIDDEN**

**Language change authorization:** **NONE**

**Scope-of-work constraint:** this ACT is a docs-only closure of
CORRECTION01 plus fresh IR_BR recon plus two extra rejection-class
fixtures. NO production code change.

---

## 0. Mission

The reviewer rejected CORRECTION01 with three binding problems:

```
P0-1 (new)  The committed HANDOFF.md still says "VERDICT: PASS" while
            the actual state is HALT_TOPOLOGY_RECORDED with 6 commits.
P0-2 (new)  Topology cannot be "fixed" by widening the contract after
            the breach; once the declared limit is exceeded F4 says HALT
            and the ACT cannot dynamically reinterpret the cap.
P0-3 (new)  The "IR_BR is dead code" premise contradicts the established
            pipeline recon: LLVM path does NOT call irFunctionPrepForCodeGen
            (which is what calls irOptPinResultReg / fusion), so IR_BR is
            LIVE on the LLVM path. The IMPL change at 99a8531 is correct
            (i1-direct-use, i64-trunc, other-reject), but the RED
            justification was wrong.

P1 (AC08)   Six distinct backend rejection classes not yet demonstrated
            (current matrix has only 4 distinct classes:
             TYPE, INT_DIVISION, SSA_LOCAL, CONVERSION).
```

The reviewer authorised a bounded CORRECTION02 with three missions:

1. **Fresh IR_BR seam recon** — prove live vs dead with code tracing,
   reclassify the IMPL under the real RED.
2. **Rejected-class coverage** — get to ≥6 distinct backend classes.
3. **Docs-only closure reconciliation** — record CORRECTION01 as
   `HALT_TOPOLOGY_RECORDED`; no attempt to rewrite six commits into
   three; clean worktree; no source change unless fresh RED proves
   99a8531 wrong.

The fresh tracing proves 99a8531 is correct (IMPL stays); only the
RED justification was wrong. Source is unchanged at this ACT.

---

## 1. Mission 1 — Fresh IR_BR seam recon (already executed)

Evidence: `evidence/llvmspike01-core01-correction02/red-p04-irbr-live.txt`

Findings:
- `IR_BR` is reached for every branched positive fixture
  (7/7 branched fixtures; 0 non-branched fixtures).
- `IR_CMP_BR` is reached for ZERO fixtures on the LLVM path.
- Cond LLVM physical type is consistently `i1` (LLVMIntegerTypeKind
  width 1, from `LLVMBuildICmp`).

The IMPL change at 99a8531 is correct for the live case:
`LLVMTypeOf(cond) == i1` branch fires; no trunc emitted;
`br i1 cond, ...` is used directly.

The CORRECTION01 RED-4 premise (`evidence/llvmspike01-core01-correction01/
red-p04-irbr-dead.txt`) said "IR_BR is dead code" — that is FALSE.

AC01 (this ACT): RED-4 premise is corrected; IMPL at 99a8531 is
preserved as correct.

## 2. Mission 2 — Rejected-class coverage

Current state: 4 distinct backend diagnostic classes
(`TYPE`, `INT_DIVISION`, `SSA_LOCAL`, `CONVERSION`).

Required: ≥6 distinct classes.

AC02: this ACT adds **2 new RED fixtures** that exercise distinct
      rejection classes:
      - `src/tests/llvm-spike/red_remainder_mod.HC` -> `INT_REMAINDER`
      - `src/tests/llvm-spike/red_shift_shl.HC` -> `INT_SHIFT`
      (or `BITWISE`, whichever proves natural; CONVERSION is
      already covered.)

      NO new production code is added (the dispatch arms for
      these classes already exist in `src/llvm-backend.c` from
      CORRECTION01).

AC03: the harness at HEAD runs the negative matrix and asserts
      ≥6 distinct `LLVM_BACKEND_UNSUPPORTED_*` classes.

## 3. Mission 3 — Docs-only closure reconciliation

AC04: this ACT closes CORRECTION01 as `HALT_TOPOLOGY_RECORDED` with
      one docs-only commit that updates the CORRECTION02 evidence
      directory. No retroactive regrouping of CORRECTION01 commits.

AC05: this ACT adds at most 2 commits:
        - RED (this ACT + RED evidence for IR_BR seam recon +
               2 new rejection-class fixtures wired into harness)
        - DOCS (HANDOFF for CORRECTION02 + final reconciliation
                of CORRECTION01)

      The IMPL is unchanged. The harness is extended by exactly
      2 new negative witnesses (RED fixtures). No source code
      modification beyond the harness shell script.

## 4. Conservation gates

| Gate                              | expected                  |
|-----------------------------------|---------------------------|
| `git diff --check HEAD`           | rc=0                      |
| `make clean && make`              | succeeds                  |
| `llvm-spike-test`                 | PASS=18 FAIL=0            |
| `git diff src/llvm-backend.c`     | empty                     |
| `git diff src/llvm-backend.h`     | empty                     |
| CORRECTION02 commits              | ≤2                        |

## 5. Forbidden

* Any change to `src/llvm-backend.c` or `src/llvm-backend.h`.
* Any retroactive rewriting of CORRECTION01 commits.
* Any opening of CORE02 (still gated on CORRECTION02 PASS).

---

## 6. Residue

P1: closure oracle trust (FT1) — unchanged.
P2: NOT_YET_CLASSIFIED opcodes (IR_NOP, IR_LABEL) — unchanged.
P2: AC08 distinct-class count moves from 4 to 6 (this ACT); CORE02
    may add more.
P2: CORRECTION01 final state is `HALT_TOPOLOGY_RECORDED` (6 commits
    over the 3-cap). Future ACTs should reproduce the F12 ideal.

## 7. Next ACT

After CORRECTION02 PASS:
- `ACT-POLYC-LLVM-CORE02` — fill the NOT_YET_CLASSIFIED gap, audit
  remaining shape-dependent opcodes.

Also tracked (Factory-tooling):
- `ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01` (FT1).
