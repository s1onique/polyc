# ACT-POLYC-IR-RETURN-SLOT-FORWARDING01

**Mission:** make the neutral-IR `irForwardReturnSlot` pass
dominance-safe so that the canonical
`store return_slot, V; load return_slot; ret load_result`
shape survives any multi-block / multi-predecessor exit
block.

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT —
neutral-IR optimisation correctness repair.

**Language semantic changes:** **NONE**. PolyC source
semantics are unchanged.

**Production compiler change:** **YES** — bounded
neutral-IR optimisation correctness repair in
`src/ir-optimise.c::irForwardReturnSlot`.

**Predecessor:** `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`
CLOSE `HALT_SCOPE_EXPANSION_REQUIRED`. C1 evidence at
[`evidence/llvm-byte-memory01-resume01/c1/`](../../evidence/llvm-byte-memory01-resume01/c1/)
isolated the defect upstream of the LLVM collapse code: the
neutral-IR pass `irForwardReturnSlot`
(`src/ir-optimise.c:256-309`) rewrites
`store slot, V; load slot; ret load_result` into
`ret V` for the exit block without verifying that `V`
dominates the exit block along every predecessor path. The
defect is generic; it reproduces on I64-only fixtures
(`i64_collapse_probe.HC`, `single_cond_probe.HC`).

## 0. Authority and scope

The RESUME01 contract (see
[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md`](ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)
§1 and §3) explicitly forbids "IR-builder seam changes
OUTSIDE the llCollapseStoreValue reload selection repair"
and mandates `HALT_SCOPE_EXPANSION_REQUIRED` if the smallest
invariant-preserving repair requires "changes outside the
authorized `llCollapseStoreValue` seam". C1 demonstrated
that the smallest repair is in `src/ir-optimise.c`, not
`src/llvm-backend.c`. RESUME01 closes with
`HALT_SCOPE_EXPANSION_REQUIRED`; this ACT
(`IR-RETURN-SLOT-FORWARDING01`) is the natural continuation
with a correctly authorized production seam.

The reviewer's recommended naming preference: this defect
is "not really an LLVM collapse defect" (C1 proved it is a
neutral-IR optimisation defect). Hence the
`IR-RETURN-SLOT-FORWARDING01` name rather than
`LLVM-IR-COLLAPSE-FIX01`.

## 1. Authorized set (delta from RESUME01 recon freeze)

The recon freeze at
[`evidence/llvm-byte-memory01-resume01/c1/`](../../evidence/llvm-byte-memory01-resume01/c1/)
is REPLACED by the following authorized set:

```text
IMPLEMENT
  src/ir-optimise.c
    irForwardReturnSlot
      dominance-safe forwarding (conservative sufficient
      condition: only forward when the exit block has a
      single predecessor)

PRESERVE
  src/llvm-backend.c
  llCollapseStoreValue
  llDetectCollapsibleReturn
  src/llvm-backend-cap.c

EXPLICITLY FORBIDDEN
  changes to llvm-backend.c
  changes to llCollapseStoreValue
  changes to llDetectCollapsibleReturn
  changes to ALREADY_SUPPORTED behaviour
  changes to byte / i64 / i8 / u8 lowering semantics
  changes to neutral-IR opcode semantics
  changes to dispatch-table coverage machinery
  general pointer aliasing machinery, TBAA metadata
```

Defence-in-depth changes to `llCollapseStoreValue` /
`llDetectCollapsibleReturn` are EXCLUDED because C1 now
proves those seams are not the producer of the invalid IR;
a simultaneous change would destroy causal attribution.

## 2. RED (mandatory, all must fail `LLVMVerifyModule`)

The RED fixtures are committed BEFORE this ACT's IMPL
commit so the failing witness is on record:

```text
pos_b0_compare_digit.HC        FAIL  (B0-shaped multi-block
                                       conditional byte
                                       return; carried over
                                       from RESUME01)
i64_collapse_probe.HC          FAIL  (I64-only generic
                                       trigger; two-arm
                                       conditional collapse)
single_cond_probe.HC           FAIL  (I64-only generic
                                       trigger; single
                                       conditional,
                                       multi-predecessor exit)
```

For each fixture, the actual RED seam is the
compiler's INTERNAL `LLVMVerifyModule` (src/llvm-backend.c
around line 2317):

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/<fixture>.HC
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  <bad instruction + use>
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  <bad instruction + use>
CAPABILITY_COUNTERS ...
EXIT=1
```

The compiler rejects the invalid module BEFORE
producing a `.ll` file. **No `.ll` file is produced at
RED.** `opt --passes=verify` is therefore not the
observable RED seam unless a pre-verifier dump facility
is added to the compiler -- and that machinery is
explicitly FORBIDDEN for this ACT (reviewer P0: "Do not
add a debug/dump production feature merely to satisfy
the ACT wording").

The CAPABILITY_COUNTERS line is the post-condition
evidence that the LLVM backend was invoked and reached
the verifier gate.

## 3. GREEN (mandatory, all must pass full pipeline)

For each fixture, after IMPL:

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/<fixture>.HC
EXIT=0
CAPABILITY_COUNTERS supported=N rejected=0 shape_dependent=K defensive=0 unreachable=0
# (a .ll file is emitted)

$ llvm-as <module.ll | opt --passes=verify
EXIT=0
```

The GREEN contract is strictly stronger than RED:
the compiler must NOT reject the module internally,
AND an independent `llvm-as` + `opt --passes=verify`
chain must accept it. This is the ideal before/after
proof:

```text
RED    internal verifier catches malformed SSA
GREEN  compiler emits module + independent LLVM tools accept it
```

## 4. Source change scope (bounded)

1. `src/ir-optimise.c` -- repair `irForwardReturnSlot`
   (lines 256-309) so the rewrite `rt->dst = st->r1;` only
   fires when the exit block has a single predecessor.
   The exact mechanism is:

   ```c
   // before the rewrite at line 287:
   if (irBlockGetPredecessors(fn, bb)->size != 1)
       continue;
   ```

   The guard is a deliberately conservative
   **mechanically-testable sufficient condition**, not a
   claim of general necessity. Multi-predecessor exit
   blocks where the value being substituted for the load
   is defined in a common dominator are deliberately not
   optimized; the canonical `store; load; ret` shape
   survives and is handled correctly by the existing
   LLVM-side collapse seam (`llCollapseStoreValue` +
   `llDetectCollapsibleReturn`).

   This is **Repair E** from the reviewer's enumerated
   options (A, B, C, D, E). Reviewer selected E because E
   is conservatively safer than A/D (no need for
   predecessor-wise definition reasoning) and smaller than
   B (no PHI insertion) and C (no value-flow analysis).

2. NO change to `src/llvm-backend.c`.
3. NO change to `src/llvm-backend-cap.c`.
4. NO change to the neutral-IR opcode grammar.
5. NO change to dispatch-table coverage machinery.

## 5. Negative control (mandatory, structural)

A single-predecessor exit block case
(`src/tests/llvm-byte-memory01/safe_fwd_single_pred.HC`)
must STILL observe the `irForwardReturnSlot` rewrite.
This proves the guard is not over-broad (it does not
regress the safe-case forwarding).

**Structural proof required:** the NC is verified
NOT by "the program still passes" (a future change that
disables `irForwardReturnSlot` entirely would also pass
the binary compile, falsifying the ACT's claim). The NC
is verified by neutral-IR before/after inspection:

```text
before:
  bb -> predecessors: {1}
    store    %t3 i64 tmp, %l6 i64 local
    load     %t8 i64 tmp, %t3 i64 tmp
    ret      %t8 i64 tmp

after (pre-IMPL, current behaviour):
  bb -> predecessors: {1}
    ret      %l6 i64 local

after (post-IMPL, with guard):
  bb -> predecessors: {1}
    ret      %l6 i64 local   <- identical to pre-IMPL
```

If the rewrite fires in BOTH the pre-IMPL AND post-IMPL
shapes (the ret's operand is a function-local rather than
a load-result tmp), the guard is proven not over-broad.
If a future change disables the rewrite entirely, the
post-IMPL shape will revert to `ret %t8` (or
`store; load; ret %t8` unchanged), falsifying the
ACT's claim.

The structural before/after dump is captured at C1 RED
via:

```text
$ ./hcc --install-dir=/tmp/polyc-install --dump-ir \
    src/tests/llvm-byte-memory01/safe_fwd_single_pred.HC \
    > evidence/llvm-ir-return-slot-forwarding01/c1/safe_fwd_single_pred-dump-ir.txt
```

The post-IMPL dump (at C3 EVIDENCE / CLOSE) must show
the same rewrite fired (ret operand is `%l6`, a function-
local, not `%t8`, a load result).

## 6. IR / ABI / neutral-IR boundary changes

**NONE.** The neutral IR is unchanged.
`irForwardReturnSlot` is a pre-existing optimisation pass
whose semantics are constrained to single-predecessor exit
blocks.

## 7. Closure gates

| Gate                              | Status requirement                                        |
|-----------------------------------|-----------------------------------------------------------|
| `pos_b0_compare_digit` (RED->GREEN)| `hcc --emit-llvm` EXIT=0 AND `.ll` is produced AND independent `opt --passes=verify` accepts |
| `i64_collapse_probe` (RED->GREEN) | same                                                     |
| `single_cond_probe` (RED->GREEN)  | same                                                     |
| Negative control (NC, structural) | pre-IMPL AND post-IMPL `--dump-ir` show the same rewrite (`ret %l6`) on the single-predecessor exit block; binary compile still EXIT=0 |
| `byte-memory01-test.sh`           | PASS — including `pos_b0_compare_digit` GREEN            |
| `cap-table-verifier`              | PASS                                                      |
| `intops01-test`                   | PASS=4 FAIL=0                                             |
| `spike-test`                      | PASS=18 FAIL=0                                            |
| `memory01-test`                   | PASS=6 FAIL=0                                             |
| `float01-test`                    | PASS=29 FAIL=0                                            |
| `factory-v2-test`                 | PASS=35 FAIL=0                                            |
| `factory-append-only-test`        | PASS=11 FAIL=0                                            |
| `gate-fast`                       | VERDICT=PASS, `git diff --check` clean                    |

## 8. Out-of-scope

- changes to `src/llvm-backend.c` (defence-in-depth
  excluded; causal attribution preserved)
- changes to `llCollapseStoreValue`
- changes to `llDetectCollapsibleReturn`
- GEP / pointer indexing
- `ptrtoint` / `inttoptr`
- `alloca` byte array
- `IR_STORE_DEREF` byte shape
- bitwise / shift / division opcodes
- multi-byte arbitrary-width memory
- F32 / F64 widening
- new frontend syntax
- new neutral IR opcode
- new native backend semantics
- unaligned / volatile / atomic memory
- general SSA dominance / PHI inference machinery (the
  guard is conservative-by-design; we are not building a
  general dominance-aware forwarding pass)

## 9. NEXT ACT (provisional)

After IR-RETURN-SLOT-FORWARDING01 closes, the next ACTs in
sequence are:

- `ACT-POLYC-LLVM-GEP01` -- bounded GEP/indexing for arrays
  / structs (can now proceed safely; the dominance bug no
  longer lurks upstream).
- `ACT-POLYC-LLVM-STRUCT01` -- struct field access.
- `ACT-POLYC-LLVM-ARRAY01` -- arrays / indexing.
- `ACT-POLYC-BOOTSTRAP01` -- B0: PolyC-written lexer /
  tokenizer that compiles and runs.

If after IMPL the GREEN test suite demonstrates that
`irForwardReturnSlot`-only repair is sufficient (no other
seam in `llvm-backend.c` was implicated), then
`BYTE-MEMORY01-RESUME02` may close `BYTE-MEMORY01` cleanly.
If a second seam is implicated, `BYTE-MEMORY01-RESUME02`
opens with the newly authorized second seam.

## 10. Hand-off summary (descriptive)

```text
ENTRY       = 8871f32 (ROADMAP range-check note)
FIRST       = <RED commit for this ACT>
CLOSE       = pending

Substance   = neutral-IR irForwardReturnSlot single-
              predecessor guard (Repair E, ~2 lines in
              src/ir-optimise.c).

RED         = pos_b0_compare_digit.HC  EXIT=1
                LLVM_BACKEND_VERIFY_FAILED
              i64_collapse_probe.HC    EXIT=1
                LLVM_BACKEND_VERIFY_FAILED
              single_cond_probe.HC     EXIT=1
                LLVM_BACKEND_VERIFY_FAILED

NC          = safe_fwd_single_pred.HC EXIT=0,
              before/after --dump-ir proves the
              irForwardReturnSlot rewrite fires on the
              single-predecessor exit block (ret operand
              is %l6, a function-local, not %t8, a load
              result).

GREEN (post-IMPL) = all three + structural NC +
                    conservation.

CONSERVATION= ALREADY_SUPPORTED LLVM collapse seam
              preserved verbatim; byte-memory01-test still
              PASS=37; spike/memory01/float01 tests
              unchanged.
```

Per `docs/factory/GIT-METADATA.md`, this document is
descriptive only; the verdict authority is the CLOSE
commit's `ACT-Verdict` trailer.

## 11. C2/C3 outcome: HALT_SECOND_SEAM_REQUIRED

The C2 IMPL applied the single-predecessor guard at
`src/ir-optimise.c::irForwardReturnSlot`:

```c
Map *bb_preds = irBlockGetPredecessors(fn, bb);
if (bb_preds && bb_preds->size > 1) continue;
```

The post-IMPL matrix at HEAD:

```text
              RED?         LLVM .ll    llvm-as   opt --passes=verify
pos_b0        EXIT=1       REJECTED    n/a       n/a
i64_collapse  EXIT=1       REJECTED    n/a       n/a
single_cond   EXIT=1       REJECTED    n/a       n/a
safe_fwd_NC   EXIT=0       produced    PASS      PASS
```

The dominance-violating rewrite is suppressed on the
RED fixtures (post-opt IR now shows
`bb4 -> predecessors {1,3,5}; ret %l8` instead of the
C1 RED shape `ret %i8_arith_zext`). However, the
post-suppression IR still carries an
`IR_ALLOCA + store; load; ret` triple on the multi-
predecessor exit, and the SSA-only spike rejects it
with `LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL`. So the
three REDs still do not reach verifier-valid LLVM IR.

The IMPL alone is provably insufficient. Per F4 (a
HALT is a successful execution outcome when an ACT
precondition fails), this ACT halts with
`HALT_SECOND_SEAM_REQUIRED`.

Three hypothetical fixes exist, ALL outside this
ACT's authorised scope:

* **A. Widen `llDetectCollapsibleReturn`**
  (`src/llvm-backend.c:400`) to also recognise the
  3-instruction `store; load; ret` shape on a multi-
  predecessor exit. Conflicts with the SSA-only PHI
  ban.
* **B. Insert an IR-level collapse-elimination pass**
  that rewrites the alloca-bearing store;load;ret
  triple into the per-predecessor direct-return
  shape BEFORE the LLVM backend sees the IR.
  Requires IR_PHI or explicit per-edge
  parameterisation. Conflicts with the neutral-IR
  grammar (the spike is "SSA-only" and forbids
  per-edge parameterisation).
* **C. Widen the SSA-only spike** to accept
  `IR_ALLOCA` in collapse-eligible functions.
  Changes the spike's canonical contract.

Per the §4 contract:

```text
ALLOWED production:
    src/ir-optimise.c
        irForwardReturnSlot only

FORBIDDEN:
    src/llvm-backend.c
    llCollapseStoreValue
    llDetectCollapsibleReturn
    src/llvm-backend-cap.c
    neutral IR grammar/opcode changes
    PHI construction
    generic dominance framework
```

None of A/B/C is reachable from this ACT.

### Recommended next ACT

A separate ACT must authorise ONE of A/B/C above (or
a fourth option). Recommended title:
`ACT-POLYC-LLVM-MULTIPRED-COLLAPSE01` or
`ACT-POLYC-IR-RETURN-SLOT-FORWARDING01-CORRECTION01`
(the CORRECTION01 suffix extends this ACT's IMPL
contract).

### Conservation achieved at HALT

The IMPL still closes one specific defect path
(the dominance-violating rewrite) and preserves all
existing behaviour:

```text
gate-fast                       VERDICT=PASS
factory-v2-test                 PASS=35 FAIL=0
factory-append-only-test        PASS=11 FAIL=0
git diff --check                clean
refs/replace                    empty
simple positive fixture
    (pos_byte_compare_simple.HC)
                                llvm-as PASS
                                opt --passes=verify PASS
```

IMPL scope is surgically bounded to
`src/ir-optimise.c::irForwardReturnSlot` (+12 lines).
No changes to `src/llvm-backend.c`,
`llCollapseStoreValue`, `llDetectCollapsibleReturn`,
`src/llvm-backend-cap.c`, the neutral IR grammar, or
the SSA-only spike contract.

### Test fixtures are now permanent regressions

The dedicated GREEN harness
`scripts/quality/ir-return-slot-forwarding01-test.sh`
captures the four fixtures as permanent regressions.
At HEAD it returns STATUS=FAIL (3/3 PASS=FAIL=3),
which is the expected HALT matrix. When the next ACT
closes the second seam, this harness should return
STATUS=PASS with all four fixtures in the GREEN
state.
