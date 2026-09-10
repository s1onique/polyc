Reviewer architectural review of HALT_DEFECTIVE_IMPL

Date: 2026-09-10
Scope: validates C10 halt + proposes architectural direction
      for the next ACT (CORRECTION02).

Reviewer identity:

  Compiler/SSA architect + LLVM backend engineer + Factory
  reviewer (combined review, not a separate individual).
  Source: post-C10 reviewer board (transcribed here as
  residue for the next ACT to bind).

---

## 1. Reviewer verdict on HALT_DEFECTIVE_IMPL

PASS — the halt is exactly right.

  * The new NC (ProbePath) correctly demonstrates that C9
    produced correct-looking SSA only for CFGs where the
    backend's single var.id → LLVMValueRef cache happened
    to coincide with the value reaching each predecessor.
  * In ProbePath, %l6 has three definitions and bb4 has
    two distinct reaching values; selecting %3 from the
    cache at bb4 is not merely insufficient — it is
    conceptually the wrong abstraction.
  * The captured verifier failure binds that very precisely.
  * The halt is also appropriately append-only: C9 remains
    as the failed-implementation witness, while C10 adds
    the counterexample and closes with HALT_DEFECTIVE_IMPL.
  * Patch hygiene for the two-commit range is clean.

---

## 2. Why the reviewer's "X/Y/Z" framing is incomplete

C9 tried to convert this:

```text
mutable PolyC local %l6
    definitions in bb1 / bb3 / bb5

               ↓

backend SSA cache:
    values[var_id] = "latest LLVM value seen"

               ↓

synthetic stores at predecessor terminators

               ↓

mem2reg
```

The broken part is the middle. A single backend map keyed
by local ID cannot represent a path-dependent mutable
variable. Once control flow branches, there simply is no
globally meaningful "latest LLVM value for %l6".

LLVM's mem2reg exists specifically so the frontend does
not need to solve that reaching-definition problem. It
expects the imperative program to be represented faithfully
as memory operations; then it computes the SSA rename
itself using dominator frontiers and PHIs.

So the next architecture should be:

```text
Option W — MEMORY-BACK THE SELECTED MUTABLE LOCAL

For one eligible mutable local V:

    each definition of V
        ↓
    compute RHS normally
        ↓
    store RHS -> V's alloca
        at the ORIGINAL definition site

    each read of V
        ↓
    load V's alloca
        at the ORIGINAL use site

Then:
    LLVM mem2reg
        ↓
    LLVM performs reaching-def analysis
        ↓
    LLVM inserts PHIs
        ↓
    canonical SSA
```

No predecessor recursion. No backend PHIs. No
"latest value" heuristic. That is much closer to the
normal frontend→LLVM contract.

---

## 3. Why W is better than X / Y / Z

X (recursively walk predecessors) is the road back to
building our own SSA-renaming algorithm. The HALT summary
even says "this is what mem2reg does internally," which
is the warning sign: if we are recreating mem2reg just so
we can then run mem2reg, we have crossed the abstraction
boundary backwards.

Y (put PolyC neutral IR into SSA first) is architecturally
legitimate, but vastly larger. It means PHIs, dominance,
renaming, and potentially changes across every backend.
That may eventually be desirable, but B0 does not justify
it yet.

Z (reject multi-def cases) is safe but probably defeats
the reason we started this chain. Ordinary lexer code
will have mutable cursor/token/accumulator state across
branches. We would likely keep rediscovering the same
restriction.

W instead says: PolyC neutral IR may remain imperative for
mutable locals; the LLVM backend faithfully lowers that
imperative state to memory; LLVM performs SSA construction.

That division is almost boring — which is a very good
property here.

## 4. Worked example for ProbePath under W

For:

```text
I64 ProbePath(I64 cond, I64 x) {
    I64 r;
    r = 10;
    if (cond > 0) {
        r = x + 1;
    }
    if (cond < 0) {
        r = 0 - x;
    }
    return r;
}
```

The pre-mem2reg LLVM under W should look conceptually
like:

```llvm
entry:
    %r.slot = alloca i64
    store i64 10, ptr %r.slot
    br ...

positive:
    %v1 = add i64 %x, 1
    store i64 %v1, ptr %r.slot
    br ...

negative:
    %v2 = sub i64 0, %x
    store i64 %v2, ptr %r.slot
    br ...

exit:
    %r = load i64, ptr %r.slot
    ret i64 %r
```

Then mem2reg owns the hard part. For this control flow we
would expect something morally equivalent to:

```llvm
%r.merge = phi i64 [ ... appropriate incoming values ... ]
```

without PolyC computing those incoming values itself.

---

## 5. C9 machinery to delete/supersede (not extend)

```text
llEmitMem2RegStoreAtPredEnd
mem2reg_store_block_id
mem2reg_store_value
IR_JMP synthetic store injection
IR_BR synthetic store injection
```

The new invariant should be:

```text
A store is emitted because a PolyC definition occurs HERE.

NEVER:
A store is emitted because a CFG successor will eventually
need one.
```

That sentence is the single most useful contract for
CORRECTION02.

The LLVM backend becomes local:

```text
on definition of memory-backed V:
    rhs = lower(...)
    LLVMBuildStore(rhs, slot)

on use of V:
    LLVMBuildLoad2(..., slot)

after function construction:
    LLVMRunPassesOnFunction("mem2reg,verify")
```

And `lc->values[V]` must NOT act as authoritative state
for V once V is classified as memory-backed.

---

## 6. Strong NCs the next ACT should require GREEN

  1. ProbePath (permanent; this NC is the P0-1 binding).
  2. Diamond — force two definitions meeting at a join:

```c
I64 Diamond(I64 cond, I64 x) {
    I64 r;
    if (cond)
        r = x + 1;
    else
        r = x - 1;
    return r;
}
```

  3. safe_fwd_single_pred (conservation control proving
     trivial neutral-IR forwarding still wins and no
     unnecessary stack slot is materialised).
  4. Address-taking/escape rejection control: a fixture
     that takes the address of the memory-backed local,
     which must be REJECTED (escapes beyond mem2reg-only
     capability).

## 7. Runtime correctness becomes mandatory from here

The IR verifier caught C9's bug. The next mistake might
generate completely valid LLVM IR with the WRONG incoming
value. Verification would happily accept that.

CORRECTION02 should require semantic execution for at
least the pure-I64 probes on the host:

```text
ProbePath(0, 42)   = 10
ProbePath(5, 42)   = 43
ProbePath(-3, 42)  = -42
```

The current `runtime_correctness_c9.HC` couldn't run on
this host because the runtime was built x86_64 and the
host is arm64. That is an environment limitation, not a
reason to abandon runtime checking. For ProbePath, the
next ACT should either:

  (a) create a minimal host-runnable fixture that does
      not depend on the mismatched runtime if the
      language/toolchain permits it; or
  (b) capture runtime execution in CI/x86 as a CLOSE gate.

Verifier correctness and semantic correctness are
different contracts from this point onward.

---

## 8. Conservation gate for the next ACT

The reviewer's hard conservation gate (binding invariant):

```text
run every regression/conservation harness

then:

git status --porcelain

must NOT contain anything under:
  evidence/llvm-core04-resume01/
  evidence/llvm-memory01/
  any other closed ACT evidence tree
```

Today's outputs belong under the CURRENT ACT's evidence
namespace. The dirty digest generated at C10 still showed
exactly those four paths being modified by the harness
with the same counter drift (2→7, 2→4). Restoration alone
did not solve the underlying side effect.

---

## 9. Reviewer's recommended ACT name + mission

Name: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 (for
continuity with the existing CORRECTION chain).

Mission:

> Faithful memory-backed lowering of the smallest mutable-
> local class; no frontend SSA reconstruction.

C1 RED / recon answers only four things:

  1. Identify the exact local involved in each current
     failure. Distinguish synthetic function return slot
     vs mutable source local feeding that slot.
     (C9 concentrated on the former, but ProbePath proves
     the hard state is really %l6, the mutable local,
     while %t5 is just the final return slot.)
  2. Enumerate every definition and read of that local in
     neutral IR and prove they can be translated directly
     to store/load at the same CFG location.
  3. Run a hand-translated Option-W probe for
     ProbePath + pos_b0_compare_digit + i64_collapse_probe +
     single_cond_probe through opt -passes=mem2reg +
     opt -passes=verify BEFORE touching production.
  4. Freeze the smallest eligibility discriminator.
     Starting suggestion:

```text
I64 mutable local only
non-address-taken
no GEP/escape
all definitions are ordinary scalar assignments
all reads can be lowered directly
compiler-generated return handling only
```

Do not generalise from there until B0 asks for it.

---

## 10. The contract for CORRECTION02 IMPL

```text
Represent mutation as memory where the mutation actually
occurs; let LLVM turn that memory into SSA.
```

This is the one-line direction the reviewer asks us to
freeze before writing another 500 lines of backend code.

---

## 11. Board (reviewer's view)

```text
LOCAL-MEM2REG01
    architectural mem2reg hypothesis           DONE / PASS

CORRECTION01
    C9 predecessor-store synthesis             defective
    C10 HALT_DEFECTIVE_IMPL                    correct / frozen

CORRECTION02
    Option-W memory-backed mutable local recon NEXT
    external memory-form probe
    bounded IMPL
    semantic NCs
    CLOSE

then:
BYTE-MEMORY01-RESUME02
GEP01
STRUCT01
ARRAY01
BOOTSTRAP01                                     B0
```

We have not gone backwards. We learned something useful:
mem2reg is still the right tool; we were simply feeding
it a memory program invented too late in the CFG.
