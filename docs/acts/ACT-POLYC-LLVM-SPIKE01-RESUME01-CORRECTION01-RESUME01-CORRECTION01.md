# ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01

**Verdict so far:** in progress (HALT_LLVM_SSA_BINDING_CONTRACT was issued
by review after d52d5af4; this ACT addresses the two P0s).

## Scope (bounded)

Two P0s only.

### P0-1 — Bind the SSA-local rejection contract

The previous IMPL stated "if multiple reaching definitions exist, fail
with LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL", but `IR_STORE` unconditionally
overwrites the binding in `lc->values`. A local with two stores
silently picks whichever store happened to be lowered last.

Concrete witness today:

```c
I64 MultiDef(I64 a, I64 b, I64 c) {
    I64 x = a;
    I64 y = b;
    if (c > 0)
        y = a;
    return x + y;
}
```

Observed today:

```llvm
bb4:                                              ; preds = %bb3, %bb1
  %4 = add i64 %0, %0
  ret i64 %4
```

Both stores were accepted; the second store silently rewrote the
binding from `%1` (b) to `%0` (a). `llvm-as` accepts it. This is
exactly the silent miscompile F3 forbids.

Required behaviour:

```text
current        -> LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL, nonzero exit,
                  "function <name>: local id=<id> has multiple
                   reaching stores at lines <n1>, <n2>"
forbidden      -> verifier-clean .ll with whichever binding happened
                  to be visited last
```

Constraints (per previous IMPL charter):

* No PHI.
* No alloca/store/load fallback.
* The single-def path (`x = a`) must continue to work.

Implementation note: track IR_STORE-bound local ids in a per-function
set (`lc->local_defs`). Reject a second bind. The check happens at
`IR_STORE` time, before `llvmSet` is called. Existing initial bindings
from `llBindParams` are not affected: params have distinct ids from
locals and are set up before any block iteration.

### P0-2 — Restore historical C1 evidence immutability

The previous IMPL commit regenerated three C1 RED evidence files in
`evidence/llvmspike01-resume01-correction01/` with post-IMPL output:

```
evidence/llvmspike01-resume01-correction01/red-1B.emit-llvm.ll
evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.ll
evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.txt
```

F14 forbids rewriting historical evidence to look like it was generated
against a newer commit. The fix:

* Restore those three files byte-for-byte from bde6045a200a (entry).
* Redirect live harness output of `--emit-llvm` for the multi_def RED
  fixture to `evidence/llvmspike01-resume01-correction01-resume01-correction01/red-multi_def/`
  (NOT into the C1 evidence dir).
* Mechanical AC: `git diff ENTRY..HEAD -- <those three files>` empty.

Other C1 files that were *added* during the IMPL commit (e.g. new
sha256/b64 sidecars for normalisation) are NOT historical evidence and
stay. Only files that EXISTED at entry and were OVERWRITTEN are
restored.

## Out of scope

* The `LLVMBuildTrunc(i1 -> i1)` residue (P1). The reviewer explicitly
  accepted it as residue for LLVM-CORE01, not a P0.
* The C1 boundary reclassification (C1 also folded the
  `LLVM_INPUT_IR_CMP_BR=NO` decision into the boundary contract).
* Any expansion of the supported subset.
* Native backend changes.

## Identity

```
ENTRY_HEAD  = bde6045a200a1526435fd161f41b59e02df012b7
RED_HEAD    = (this ACT)
IMPL_HEAD   = (this ACT)
CLOSURE     = (this ACT)
```

## Authorised file scope

Production:

* `src/llvm-backend.c` — add `lc->local_defs` set, reject 2nd bind.
* `src/llvm-backend.h` — none new (diagnostic code already exists).

Tests:

* `src/tests/llvm-spike/red_local_multi_def.HC` — NEW fixture.
* `scripts/quality/llvm-spike-test.sh` — register the fixture in the
  *live* harness (output -> this ACT's evidence dir, NOT C1).

Evidence:

* `evidence/llvmspike01-resume01-correction01-resume01-correction01/`
  — full closure evidence tree.
* Restore three C1 files from ENTRY.

## Acceptance criteria

1. New RED fixture `red_local_multi_def.HC` compiled today produces
   verifier-clean LLVM IR with wrong semantics (last-store-wins).
   Capture under `red-multi_def/`.
2. After IMPL, the same fixture produces non-zero exit with
   `LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL` on stderr.
3. The original 12-fixture matrix remains PASS=12/FAIL=0
   (alloca=0, store=0, load=0).
4. `gate-push.sh HEAD` returns VERDICT=PASS.
5. `git diff ENTRY..HEAD -- evidence/llvmspike01-resume01-correction01/red-{1B.emit-llvm.ll,2.emit-llvm.ll,2.emit-llvm.txt}`
   is empty.
6. `git diff --check HEAD` is clean.

## Status

Started. RED captured. IMPL pending.
