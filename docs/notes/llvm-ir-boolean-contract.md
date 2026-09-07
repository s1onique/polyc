# PolyC neutral-IR ↔ LLVM boolean / i1 contract

**Status:** CORRECTION01 RED-7 evidence-based note.
**Author:** ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01.
**Entry HEAD:** `130098c7344c4fb430c1dec0291bbd16ce0bf3e6`.
**Scope:** investigation only. **No production change in this
ACT.** Implementation lands in
`ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01` after
`ACT-POLYC-IR-BOUNDARY03` closes GREEN.

## 1. The actual question (sharpened after the C1 evidence pass)

The earlier-draft framing was "cached-i1 vs explicit-zext."
That framing is less precise than the real question the C1
evidence forces. The real question is:

```text
Does the PolyC neutral IR guarantee:

    IR_BR condition ∈ {0, 1}       (Boolean invariant)

or merely:

    IR_BR condition ∈ I64,
    zero     = false,
    nonzero  = true                (Truthiness invariant)
```

The answer determines whether `trunc i64 → i1` is semantically
correct. If the neutral IR only guarantees truthiness, then
`trunc` (which discards high bits) implements **parity** at
the LLVM boundary:

```text
x = 0    -> trunc -> 0  -> false
x = 1    -> trunc -> 1  -> true
x = 2    -> trunc -> 0  -> false   (WRONG: should be true)
x = 3    -> trunc -> 1  -> true
x = -1   -> trunc -> 1  -> true
x = 4    -> trunc -> 0  -> false   (WRONG: should be true)
```

For this to be sound, every producer of an `IR_BR` condition
(above all, `IR_ICMP`) must itself guarantee the value is
exactly `0` or `1`.

`LLVMBuildTrunc` is defined by the LLVM Language Reference as
discarding the high-order bits; it is not a
*sign-of-zero-to-i1* conversion. The LLVM examples explicitly
show:

```llvm
trunc i32 123 to i1  ; true   (LSB)
trunc i32 122 to i1  ; false  (LSB)
```

Poison/UB under `trunc` only applies to the `nuw`/`nsw`
constrained variants when the truncated value is out of
range. Plain `trunc i64 %x to i1` is well-defined for every
`%x`; it is only **semantically wrong** if the upstream
producer relies on a `0/1` invariant the LLVM emitter cannot
recover.

(An earlier draft of this note mis-stated the trunc UB
claim. The corrected statement is the one above.)

## 2. Two candidate contracts

```text
A. "cached-i1" (Boolean invariant):
     - IR_ICMP returns IR_TYPE_I1.
     - IR_BR consumes IR_TYPE_I1.
     - LLVM emission is direct: icmp -> condbr.
     - No trunc, no parity hazard.
     - Requires IR_TYPE_I1 to enter IrValueType
       (currently commented out at src/ir-types.h:172).

B. "explicit-i64 with strict invariant" (status quo:
     plain trunc on the emission boundary):
     - IR_ICMP returns IR_TYPE_I64, with the IR-level
       invariant that the value is exactly 0 or 1.
     - IR_BR consumes IR_TYPE_I64, asserted at
       src/llvm-backend.c:585.
     - LLVM emission uses LLVMBuildTrunc on every branch
       (src/llvm-backend.c:594). The truncation is sound
       IFF the 0/1 invariant is preserved by every
       producer.
     - Preserves the native-backend EFLAGS path
       (IR_CMP_BR, src/ir-types.h:135-150).

C. "truthiness" (NOT a contract, listed only because the
   reviewer raised it):
     - IR_BR condition is I64, zero=false / nonzero=true.
     - LLVM emission must use `icmp ne i64 %x, 0` before
       the conditional `br`.
     - This is NOT what the current source does.
     - Listed as the option the existing code does NOT
       implement, so the choice between A and B is
       understood as the choice between "preserve the 0/1
       invariant explicitly" and "make the i1 type
       explicit." Option C is the false alternative.
```

The earlier-draft "explicit-zext" option is not a distinct
contract; it is the same as B with a different name for the
same code motion. Discarded.

## 3. Evidence from current source (F2 / F13)

### 3.1 `IR_TYPE_I1` is intentionally absent from `IrValueType`

`src/ir-types.h:170-181` reads:

```c
// Value types in the IR. Kept small and explicit.
typedef enum {
    IR_TYPE_VOID,
    IR_TYPE_I8,
    IR_TYPE_I16,
    IR_TYPE_I32,
    IR_TYPE_I64,
    IR_TYPE_F64,
    // IR_TYPE_I1,        /* Boolean (1 bit) */
} IrValueType;
```

The type is commented out, not deleted. The neutral IR has
no `i1` type today. Every value flowing through the IR,
including the result of an `IR_ICMP`, is `IR_TYPE_I64` (or
wider). A comment immediately above at
`src/ir-types.h:170-173` makes this intentional.

### 3.2 `IR_BR` carries its condition as `IR_TYPE_I64`

`src/llvm-backend.c:583-595`:

```c
if (ins->op == IR_BR) {
    /* IR_BR carries its condition via `dst` (per ir-eval.c). */
    if (!ins->dst || ins->dst->type != IR_TYPE_I64) {
        fprintf(stderr,
            "%s: IR_BR condition must be i64 (got kind=%d type=%d)\n",
            LLVM_BACKEND_UNSUPPORTED_IR,
            ins->dst ? ins->dst->kind : -1,
            ins->dst ? ins->dst->type : -1);
        exit(1);
    }
    LLVMValueRef cond64 = llLowerI64Value(lc, ins->dst);
    LLVMValueRef cond1  = LLVMBuildTrunc(lc->bld, cond64,
                                         LLVMInt1TypeInContext(lc->ctx), "");
    ...
```

The assertion (`type == IR_TYPE_I64`) and the explicit
`LLVMBuildTrunc` together prove the boundary contract is
**explicit-i64 at the IR, plain trunc at the emission
boundary** - i.e. contract B above. The soundness of B
rests entirely on the unstated invariant that the value
held in `cond64` is in `{0, 1}`. That invariant is nowhere
asserted.

### 3.3 `IR_ICMP` arm emits via `LLVMBuildICmp`

`src/llvm-backend.c:741-749`:

```c
if (ins->op == IR_ICMP) {
    LLVMValueRef lhs = llLowerI64Value(lc, ins->icmp.lhs);
    LLVMValueRef rhs = llLowerI64Value(lc, ins->icmp.rhs);
    LLVMIntPredicate pred = llCmpKindToLLVMPred(ins->icmp.kind);
    LLVMValueRef res = LLVMBuildICmp(lc->bld, pred, lhs, rhs, "");
    llSetSlot(lc, ins->dst, res);
    break;
}
```

`LLVMBuildICmp` returns an `i1` value (per the LLVM
Language Reference, `icmp` always produces `i1`). The
consumer then puts that `i1` into the slot bound to
`ins->dst`. Two consequences:

1. Inside `lc` (the LLVM-C backend), the value held in the
   slot IS `i1` until the next user widens or truncates it.
2. The PolyC neutral IR does NOT have an `IR_TYPE_I1`. So
   `ins->dst->type` is recorded as `IR_TYPE_I64` even
   though the LLVM value backing it is `i1`. The 0/1
   invariant is enforced by the LLVM-C representation, not
   by an explicit IR-level operation.

That is the actual fragility: the neutral IR and the
LLVM-C representation disagree on the type of the
comparison result. The truncation in section 3.2 is correct
**only because** every intermediate user of `ins->dst`
inside `lc` is an IR instruction that LLVM-C keeps as
`i1`, so the high bits are always zero when the value
leaves the consumer.

### 3.4 `IR_CMP_BR` is below the neutral boundary

`src/ir-types.h:135-150` defines `IR_CMP_BR`:

```c
IR_CMP_BR,      /* Fused compare-and-branch: cmp r1, r2; j<cc> target,
                 * fallthrough. ... dst is unused
                 * (the result lives in EFLAGS for one instruction).
                 *
                 * ACT-POLYC-IR-BOUNDARY01: this opcode is BELOW THE
                 * NEUTRAL BOUNDARY. ... */
```

The opcode is created exclusively by `irOptPinResultReg`
(`src/ir-optimise.c:1079, 1113`) and never by the lowering
(`irLowerFunction`). The LLVM consumer's `IR_CMP_BR` switch
arm (`src/llvm-backend.c:610-639`) silently reinvents an
icmp + condbr sequence on the fly, which is why the
existing 04_cmp_branch.HC emission is verifier-clean in
spite of the placement defect.

### 3.5 `llTypeSupported` admits no `IR_TYPE_I1`

`src/llvm-backend.c:327-337`:

```c
static int llTypeSupported(IrValueType t) {
    ...
    /* IR_TYPE_I1 is intentionally not in `IrValueType`; the spike
     * only emits i64 for source values. The cond->i1 truncation for
     * IR_BR uses LLVMInt1TypeInContext directly. */
```

This corroborates section 3.1: the consumer never asks for
an i1 value to flow through `llTypeSupported`. i1 exists
only as a transient at the LLVM IRBuilder boundary.

## 4. Conclusion

The current source implements **contract B** -
explicit-i64 at the neutral IR, plain trunc on the LLVM
emission boundary. The soundness of B rests on a
**Boolean invariant** (IR_BR condition in `{0, 1}`) that is
nowhere enforced in neutral IR.

What has been observed:

```text
- The current LLVM consumer happens to materialise
  IR_ICMP as LLVM `i1` inside the LLVM-C `lc` state.

- The only path that takes the value out of `lc` and
  back to `ins->dst->type == IR_TYPE_I64` is the trunc
  in section 3.2.

- Therefore, within the LLVM consumer's representation,
  the value is `i1` between IR_ICMP emission and the
  IR_BR trunc, and is in `{0, 1}` at the trunc.
```

What this does NOT establish:

```text
- That neutral IR (above the boundary) semantically
  guarantees `IR_BR condition ∈ {0, 1}`. The neutral-IR
  proof obligation is absent; nothing in the neutral
  IR contract asserts the value is in `{0, 1}`.

- That the `{0, 1}` invariant would survive a change to
  the LLVM consumer's representation, a future
  alternate consumer, or any pass that touches the
  IR_ICMP result outside the LLVM-C state.

- That contract B is therefore "sound today" in any
  stronger sense than "the current LLVM consumer
  happens to keep the value in `{0, 1}` between the
  IR_ICMP arm and the IR_BR trunc."
```

Whether neutral IR guarantees the `{0, 1}` Boolean
invariant (contract A or B above) or only the
`zero=false / nonzero=true` Truthiness invariant
(listed as option C above) is an OPEN question.
That question is the input to ACT-POLYC-IR-BOUNDARY03,
not something this note proves. IR-BOUNDARY03 must
NOT inherit "contract B is sound today" as an
established fact; it must re-derive the answer from
neutral-IR semantics.

### What contract B requires of neutral-IR producers

If contract B is to remain the contract, every IR producer
of an `IR_ICMP` (and every later pass that touches the
result) MUST keep the value in `{0, 1}`. The current
producer set is:

```text
src/ir-lower.c       (or wherever irLowerFunction lowers IR_ICMP)
src/ir-optimise.c    (any pass that moves or rewrites IR_ICMP)
```

Neither file has an assertion that `IR_ICMP` results are
in `{0, 1}`. Adding that assertion is a candidate for the
future ACT's scope, but it is a production change and
therefore outside C1.

### What contract A would require

If contract A is chosen instead, the future ACT must:

1. Add `IR_TYPE_I1` to `IrValueType`.
2. Update `llTypeSupported` to admit it.
3. Update `IR_ICMP` to set `ins->dst->type = IR_TYPE_I1`.
4. Update `IR_BR`'s assertion to `IR_TYPE_I1`.
5. Remove the trunc in `src/llvm-backend.c:594` (the value
   is already i1).
6. Update the interpreter/native/JIT paths (out of scope
   for the LLVM spike).

Contract A is the cleaner long-term choice. Contract B is
the smaller near-term change. The decision belongs to
`ACT-POLYC-IR-BOUNDARY03`, not here.

## 5. RED-7 outcome

**RED-7 status: PASS - current contract documented and
falsifiable; source locations cited; the trunc-UB claim
from the earlier draft has been corrected.**

This is **not** a defended choice between A and B. It is a
defended statement of what the current source implements
(contract B) and the invariant contract B requires
(IR_BR condition in `{0, 1}`). The earlier draft's claim
that plain `trunc` produces UB on out-of-range values is
wrong and has been removed. The earlier draft's
"explicit-zext" framing has been folded into B as a
renaming.

If a future reviewer disagrees that contract B is a
defensible description of the current code, or that the
{0, 1} invariant is the right way to phrase the fragility,
the close becomes `HALT_IR_BOOLEAN_CONTRACT_UNRESOLVED`
and the future ACT must author the contract instead of
inheriting this one.

## 6. Source location index

For the future ACT's convenience:

```text
src/ir-types.h:135-150      IR_CMP_BR definition; "BELOW THE
                            NEUTRAL BOUNDARY" classification.
src/ir-types.h:170-181      IrValueType; IR_TYPE_I1 commented out.
src/ir-types.h:358-         IrCmpBr struct (extra.cmp_br fields).
src/ir-types.h:396          IrCmpBr cmp_br field in IrInstrExtra.
src/llvm-backend.c:327-340  llTypeSupported; i1 comment.
src/llvm-backend.c:502-510  llCmpKindToLLVMPred; six signed predicates.
src/llvm-backend.c:583-608  IR_BR arm; i64 condition, trunc to i1.
src/llvm-backend.c:610-639  IR_CMP_BR arm; consumer-side fusion.
src/llvm-backend.c:741-749  IR_ICMP arm; LLVMBuildICmp -> i1.
src/ir-optimise.c:1079      irOptPinResultReg (creates IR_CMP_BR).
src/ir-optimise.c:1113      irOptPinResultReg fusion site.
```

The contract choice (A vs B) is delegated to
ACT-POLYC-IR-BOUNDARY03 and the future
CORRECTION01-RESUME01 ACT, not made here.
