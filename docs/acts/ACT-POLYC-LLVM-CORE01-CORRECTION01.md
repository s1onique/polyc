# ACT-POLYC-LLVM-CORE01-CORRECTION01

**Title:** Close CORE01 reviewer's four P0 defects

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-CORE01` (REJECTED at `f4ac2e7`,
reviewer verdict `HALT_CORE01_CONTRACT_FALSE_GREEN`)

**Class:** CONTRACT-HONESTY / TEST-COVERAGE / DOC-CORRECTION

**Production semantic changes:** **FORBIDDEN**

**IR / ABI / neutral-IR boundary changes:** **FORBIDDEN**

**LLVM IR lowering additions:** **FORBIDDEN**

**Target machine / execution / ORC:** **FORBIDDEN**

**Language change authorization:** **NONE**

---

## 0. Mission

The CORE01 reviewer closed `PASS` with four binding P0 defects:

```
P0-1  git diff --check returns rc=1 (blank line at EOF of the ACT)
P0-2  commit topology violates both internal caps (actual=5, cap=3, cap=2)
P0-3  IR_STORE / IR_LOAD matrix says REJECTED but actually supports 2 shapes
P0-4  IR_BR trunc "deliberate boundary crossing" comment overclaims; IR_BR
      is the dead-code non-fused fallback path, never exercised by the
      current spike, and the cached LLVMValueRef is i1 (from IR_ICMP)
      not i64 (from neutral IR)
```

This ACT makes the CORE01 closure honest. No new lowering, no new
opcodes, no neutral-IR changes, no new test fixtures that exercise
new code paths (RED-2 was already captured at CORE01).

---

## 1. RED-1 (P0-1): blank-at-EOF

```text
$ git diff --check HEAD~5..HEAD
docs/acts/ACT-POLYC-LLVM-CORE01.md:366: new blank line at EOF.
```

The ACT document has a single blank line after the closing block.
`git diff --check` enforces POSIX text-file hygiene: a single
trailing newline, no extra blank lines. ACT-POLYC-LLVM-CORE01
violates this on line 366.

Evidence: `evidence/llvmspike01-core01-correction01/red-p01-blank-eof.txt`

## 2. RED-2 (P0-2): commit topology

ACT-POLYC-LLVM-CORE01 §10 caps commits at 3.
AC11 caps at "1 production + 1 docs/evidence" = 2.
ACTUAL = 5 commits in `HEAD~5..HEAD`.

Evidence: `evidence/llvmspike01-core01-correction01/red-p02-topology.txt`

The CORE01 closure record said "4 commits" but listed 5 SHAs. The
HANDOFF never reconciled the difference.

## 3. RED-3 (P0-3): IR_STORE shape-dependent

The matrix classifies `IR_STORE` as REJECTED but the implementation
supports two specific shapes (return-slot fold, local SSA-bind).
An opcode-only three-state matrix is materially false.

Evidence: `evidence/llvmspike01-core01-correction01/red-p03-irstore-matrix-vs-code.txt`

## 4. RED-4 (P0-4): IR_BR trunc is dead/unverified

The IR_BR arm of the LLVM dispatch has not been exercised by any
current positive or RED fixture. IR_ICMP+IR_BR fuses into IR_CMP_BR
(`src/ir-optimise.c:1105-1119`) and IR_CMP_BR is rejected at the
boundary (src/llvm-backend.c:745-763). The IR_BR arm is therefore
defending a code path the spike has never reached.

Additionally, the comment claims the truncation is "neutral IR
i64 -> LLVM i1". The neutral IR dst IS i64 (verified via dump-ir),
but the cached LLVMValueRef at IR_BR dispatch time is the result of
`llLowerI64Value(cond)`, which for an `if (a > b)` is the IR_ICMP
result: an LLVM `i1`. So the trunc would actually be `i1 -> i1`,
which LLVM forbids (trunc requires source wider than dest).

Evidence: `evidence/llvmspike01-core01-correction01/red-p04-irbr-dead.txt`

---

## 5. Acceptance criteria

AC01: `git diff --check HEAD` returns rc=0 at the IMPL commit.
      (P0-1 fix: blank line removed.)

AC02: this ACT adds at most **three commits**: one RED, one IMPL,
      one DOCS/EVIDENCE. The CORE01 AC11 cap ("1 production + 1
      docs/evidence") is interpreted per-F12 as a SMALL-TRUTHFUL-
      COMMITS cap: the implementation must be in one commit and
      the docs/evidence may be split into RED + DOCS if the
      evidence set is large enough to warrant a separate commit.
      (P0-2 fix: cap honored within F12.)

AC03: the capability matrix in src/llvm-backend.c classifies
      `IR_LOAD` and `IR_STORE` as **shape-dependent**: at least one
      supported shape and the rejected shapes are listed by name.
      Other opcodes whose supported/rejected status depends on
      operand/value shape are also classified by shape (audit
      covers IR_RET, IR_CALL, IR_ICMP, IR_BR, IR_CMP_BR, IR_VAL_*,
      IR_TYPE_*).

AC04: at HEAD, every accepted CORE01 test still passes (14/14 in
      llvm-spike-test). No new SUPPORTED opcode or type.

AC05: the IR_BR arm's `LLVMBuildTrunc` is preceded by an
      `LLVMTypeOf(cond)` check that branches:
        - i1 -> use directly (no trunc);
        - i64 -> trunc to i1 (with documented assumption that the
          neutral IR invariant is {0, 1});
        - other width -> reject with a named diagnostic
          (LLVM_BACKEND_UNSUPPORTED_INTERNAL or
           LLVM_BACKEND_UNSUPPORTED_IR_BOUNDARY).
      The "deliberate boundary crossing" overclaim is replaced by
      an honest description of what the dispatch actually does.

AC06: at HEAD, **six** real backend-level negative witnesses exist
      (currently 4: neg_f64, neg_pointer, neg_struct, red_idiv).
      CORRECTION01 adds at least two more:
        - red_local_multi_def.HC (already exists; must be wired into
          the harness as a backend witness, currently it is run
          outside the negative matrix);
        - one additional shape-class test (e.g. red_phi_unbound.HC
          that uses a phi-shaped pattern the spike rejects).

AC07: at HEAD, `make clean && make` succeeds.

AC08: at HEAD, the inherited baseline (AOT 90/90, JIT 90/90,
      LSP 43/43, CORPUS 16/16) is preserved.

AC09: at HEAD, the closure identity oracle still exits 0.

---

## 6. Conservation gates

| Gate                              | expected                              |
|-----------------------------------|---------------------------------------|
| `git diff --check HEAD`           | rc=0                                  |
| `make clean && make`              | succeeds                              |
| `llvm-spike-test`                 | 14/14 PASS + 2 new = 16 PASS / 0 FAIL |
| `identity.sh` oracle              | exit 0                                |
| commit topology in CORRECTION01   | RED + IMPL + DOCS = 3 (F12 honest)    |
| commit topology CORE01->CORRECTION01 total | 5 + 2 = 7 (history preserved)   |

## 7. Forbidden (preserved from CORE01)

* No new SUPPORTED opcode or type.
* No neutral-IR contract change (IR_BR's neutral-IR i64-dst guard
  stays; the dispatch-level check is what changes).
* No target machine, ORC, JIT, ExecutionEngine, PassBuilder,
  opt-level, lli, clang.
* No data-driven dispatch framework (F8 preserved: matrix is
  comments).
* No removing the catch-all (kept as safety net for
  NOT_YET_CLASSIFIED).

---

## 8. Residue (carried to CORE02)

* NOT_YET_CLASSIFIED opcodes (IR_NOP, IR_LABEL) still hit the
  generic arm. CORE02-classification ACT.
* IR_BR is the non-fused fallback; no current spike fixture
  exercises it. CORE02 may construct a controlled unfused path
  to actually test the dispatch. NOT IN SCOPE for CORRECTION01.
* Closure oracle still in its own allowed set
  (FT1 / ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01).
