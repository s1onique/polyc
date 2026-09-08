# ACT-POLYC-LLVM-CORE02

**Title:** Full backend-capability classification; finish IR_BR classification; supersede CORRECTION01 i64-trunc claim

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-CORE01` (REJECTED, f4ac2e7)
- `ACT-POLYC-LLVM-CORE01-CORRECTION01` (HALT_TOPOLOGY_RECORDED, b05ea7e)
- `ACT-POLYC-LLVM-CORE01-CORRECTION02` (PASS, 75983a8)

**Reviewer-authorized state:**
- Fresh IR_BR recon proved IR_BR live, IR_CMP_BR dead-on-LLVM-path
- 6 distinct rejection classes confirmed (PASS=18 / FAIL=0)
- Topology discipline restored (CORRECTION02 = 2 commits)
- CORE02 is authorized to proceed

**Class:** CAPABILITY / CLASSIFICATION

**Production semantic changes:** **NONE** (per CORE02 scope: classification
+ 1 docs-only comment cleanup)

**IR / ABI / neutral-IR boundary changes:** **NONE**

**LLVM IR lowering additions:** **NONE**

**Source change scope:** **1 docs-only comment edit** to the
capability matrix in `src/llvm-backend.c` (around line 131-133),
updating the IR_BR row to reflect "normal LLVM-path conditional
branch" instead of "non-fused fallback".

**Language change authorization:** **NONE**

---

## 0. Mission

CORE01 closed with the matrix containing `NOT_YET_CLASSIFIED` rows
for `IR_NOP` and `IR_LABEL`, and the IR_BR row called itself a
"non-fused fallback" — a phrase that is technically true on the
native pipeline (where `IR_CMP_BR` is the fused form) but
**misleading on the LLVM pipeline** (where fusion never runs and
`IR_BR` is the normal branch representation).

The reviewer authorised CORE02 with three sharpened questions:

1. **Classify every remaining `NOT_YET_CLASSIFIED` opcode**
   (`IR_NOP`, `IR_LABEL`, and any other reach that recon discovers).
2. **Audit every shape-dependent capability** so the matrix
   states *which shapes* are supported/rejected, not merely the
   opcode.
3. **Finish `IR_BR` capability classification**:
   - normal path = live `i1` direct-use (CONFIRMED by CORRECTION02);
   - determine whether physical `i64` condition is reachable from
     real neutral IR (re-analysed below: **UNREACHABLE**, defensive
     invariant);
   - if unreachable, classify it as defensive/invariant code rather
     than pretending it is supported runtime surface;
   - clean the misleading "non-fused fallback" wording.

Plus the reviewer's non-blocking P1:
- **Explicitly supersede** CORRECTION01's "predicate fixtures
  exercise i64→i1 trunc" claim, with status `FALSIFIED /
  SUPERSEDED` and the fresh observation.

---

## 1. Mission 1 — Classify every NOT_YET_CLASSIFIED opcode

Evidence: `evidence/llvmspike01-core02/classify-everything.txt`

Findings:

| opcode       | emit site                                | state on LLVM path                |
|--------------|------------------------------------------|-----------------------------------|
| `IR_NOP`     | `irMakeNop` (multiple sites in opt)      | UNREACHABLE (`irRemoveAllNops`     |
|              |                                          | strips before emission)           |
| `IR_LABEL`   | (none — never created by lowerer)        | UNREACHABLE (reserved-but-unused  |
|              |                                          | per `src/ir-types.h:155`)         |
| `IR_CMP_BR`  | `irOptPinResultReg`                      | UNREACHABLE on LLVM path          |
|              | (src/ir-optimise.c:1113)                | (fusion never runs)               |
| `IR_RMW_DEREF` | `irFuseLoadOpStore`                   | UNREACHABLE for supported subset  |
|              | (src/ir-optimise.c:914)                 | (needs `IR_LOAD_DEREF` input,     |
|              |                                          | which is REJECTED)                |

AC01: matrix at top of `src/llvm-backend.c` updates `IR_NOP` and
      `IR_LABEL` rows from `NOT_YET_CLASSIFIED (generic)` to
      `UNREACHABLE_ON_LLVM_PATH` with the matching rationale.

AC02: matrix keeps the `default:` arm as a safety net (F4: failures
      are evidence; F5: no test weakening) so a future regression
      that lets one through still produces a loud diagnostic.

AC03: matrix keeps the explicit `IR_CMP_BR` REJECTED arm (now
      upgraded from a generic diagnostic to a "boundary violation"
      diagnostic, which it already is at src/llvm-backend.c:803-825).

NO new tests are required: the existing 18/0 harness already covers
the IR_BR live case (7 branched fixtures); the unreachable opcodes
cannot be exercised without violating upstream invariants.

---

## 2. Mission 2 — Audit shape-dependent capabilities

AC04: every shape-dependent row in the matrix is already
      documented with per-shape SUPPORTED/REJECTED lines:

```
IR_STORE per shape:
    local, single reaching store   SUPPORTED    (binds local -> scalar SSA)
    return-slot                    FOLDED       (collapse-elimination)
    local, multiple reaching defs  REJECTED     LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
    non-local dst                  REJECTED     LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
    missing dst                    REJECTED     LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL

IR_LOAD per shape:
    local with single reaching store SUPPORTED  (resolves to bound SSA value)
    local with multiple reaching    REJECTED    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
    unbound local (no reaching)     REJECTED    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
```

AC05: this audit confirms the existing matrix is shape-aware where
      required. No new shape rows needed for CORE02 scope.

AC06: the per-shape lines are documented in the matrix comment
      itself, not in a separate doc, so the matrix and the dispatch
      table stay coupled.

---

## 3. Mission 3 — Finish IR_BR capability classification

Evidence: `evidence/llvmspike01-core02/irbr-i64-vs-i1-reachability.txt`

AC07: matrix updates IR_BR row:

      Before:
      ```
      * IR_BR   SUPPORTED  (non-fused fallback; dispatches
      *                     i1 / i64 cond to condbr; see IR_BR
      *                     arm below for the LLVMTypeOf dispatch)
      ```

      After:
      ```
      * IR_BR   SUPPORTED  (normal LLVM-path conditional branch;
      *                     cond is the dst of the preceding
      *                     IR_ICMP, so it is always physically
      *                     i1; the i64→i1 trunc arm is a
      *                     defensive invariant guard and is
      *                     not reachable from current neutral IR)
      ```

AC08: this ACT explicitly supersedes CORRECTION01's claim:

      CORRECTION01 RED-4 claim:
          "predicate fixtures exercise i64→i1 trunc"
      STATUS:
          FALSIFIED / SUPERSEDED
      FRESH OBSERVATION:
          predicate fixtures exercise i1 direct-use
      CONFIRMATION:
          - 7/7 branched fixtures at HEAD=b05ea7e produced
            `br i1 %cond, ...` in emitted `.ll`;
          - 0 `trunc i64 -> i1` instructions appear in any
            positive fixture's emitted `.ll`;
          - `LLVMBuildICmp` returns i1 by API contract;
          - `irNormalizeBranchCondition` always wraps non-ICMP
            conds in an IR_ICMP whose dst is a fresh monotonic
            tmp id;
          - the i64→i1 trunc arm of the IR_BR dispatch has no
            observable caller under the current architecture.

AC09: this ACT does NOT change the dispatch logic. The
      `LLVMBuildTrunc` arm stays as a defensive invariant guard.

---

## 4. Reviewer's P1 — explicit supersede annotation

The reviewer asked for:

> an F14 annotation in CORE02 or the next ACT is enough

This ACT adds the annotation directly in §3 above and in
`evidence/llvmspike01-core02/irbr-i64-vs-i1-reachability.txt`
under "SUPERSEDES". No retroactive edit to CORRECTION01 docs.

---

## 5. Conservation gates

| Gate                              | expected                  |
|-----------------------------------|---------------------------|
| `git diff --check HEAD`           | rc=0                      |
| `make clean && make`              | succeeds                  |
| `llvm-spike-test`                 | PASS=18 FAIL=0            |
| `git diff src/llvm-backend.h`     | empty                     |
| `git diff src/llvm-backend.c`     | 1 comment-only edit (the matrix row above) |
| CORE02 commits                    | RED + IMPL-as-comment + DOCS = 3 commits  |

---

## 6. Forbidden

* Any change to dispatch logic in `src/llvm-backend.c`.
* Any retroactive rewriting of CORRECTION01 or CORRECTION02 commits.
* Any opening of CORE03.

---

## 7. Residue

P2: IR_CMP_BR / IR_RMW_DEREF / IR_NOP / IR_LABEL still REJECTED in
    the matrix with explicit arms (defensive; per F5 no test
    weakening).
P2: the `default:` arm in the dispatch stays as a safety net (per
    F4 failures are evidence).
P2: closure oracle trust (FT1) — unchanged.
P2: NOT_YET_CLASSIFIED in the matrix table is updated to
    UNREACHABLE_ON_LLVM_PATH for IR_NOP / IR_LABEL only (CORE02's
    Mission 1).

## 8. Next ACT

ACT-POLYC-LLVM-CORE03:
- generalise the capability matrix to a runtime check
  (e.g. assert every dispatch case matches the matrix);
- add a per-fixture matrix-decoder in the harness.

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1).
