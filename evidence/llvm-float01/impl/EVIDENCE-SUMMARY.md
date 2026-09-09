# ACT-POLYC-LLVM-FLOAT01 / IMPL evidence summary

Status: IMPL GREEN; capturing evidence for EVIDENCE + CLOSE phases.

Captured files:

| File                              | Purpose                                       |
|-----------------------------------|-----------------------------------------------|
| positive-matrix.txt               | 13 positive fixtures rc + supported counts    |
| negative-matrix.txt               | 3 negative fixtures rc + named diagnostics    |
| comparison-predicate-map.txt      | binding table: PolyC op -> LLVM predicate     |
| fast-math-purity.txt              | zero fast-math flag structural proof          |
| llvm-as.txt                       | llvm-as pass matrix                           |
| opt-verify.txt                    | opt --passes=verify matrix                    |
| determinism.txt                   | NC3/NC6 byte-identical re-emission            |
| counter-matrix.txt                | capability counter totals + per-fixture attrib|
| native-conservation.txt           | F10 conservation ledger                       |
| scope.txt                         | F7 scope ledger + F11 residue                 |
| float01-test-output.txt           | full harness stdout/stderr capture            |
| *.ll (14 files)                   | textual IR for each positive fixture          |

All gates currently PASS:

  scripts/quality/llvm-float01-test.sh        FLOAT01_PASS=28 FAIL=0
  scripts/quality/llvm-spike-test.sh          PASS=18
  scripts/quality/llvm-memory01-test.sh       PASS=6
  scripts/quality/llvm-memory01-nc5-probe.sh  PASS
  scripts/quality/llvm-cap-table-verifier.py  PASS
  scripts/quality/factory-v2-test.sh          PASS=35
  scripts/quality/gate-fast.sh                PASS

Predecessor evidence:
  * spike harness re-GREEN after neg_f64.HC re-scope (F32 params still rejected).
  * MEMORY01 harness unchanged and still GREEN.
  * NC5 probe (load + store) unchanged and still GREEN.
  * cap table verifier reflects the new IR_FADD/IR_FSUB/IR_FMUL/IR_FCMP
    -> SUPPORTED rows (verified by scripts/quality/llvm-cap-table-verifier.py).
  * factory-v2 PASS=35 (no regressions in the F12 / F13 / F14 / F15
    contract gate set).

No residue that blocks CLOSE.
