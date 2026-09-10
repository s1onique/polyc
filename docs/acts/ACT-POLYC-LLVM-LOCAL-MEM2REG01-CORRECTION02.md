# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02

**Title:** Faithful memory-backed lowering of the smallest
mutable-local class (Option W); no frontend SSA
reconstruction.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01`
(closed at `8072b9a` with verdict `HALT_DEFECTIVE_IMPL`,
post-CLOSE Option-W evidence at `e286f59`)

**Class:** CONTRACT-HONESTY / ARCHITECTURAL-CORRECTION /
TEST-COVERAGE

**Production semantic changes:** AUTHORISED only under
the strict eligibility discriminator frozen in §2, and
only for the mutable-local class identified in §3.
Other mutable-state lowering is FORBIDDEN in this ACT.

**IR / ABI / neutral-IR boundary changes:** **FORBIDDEN**

**LLVM IR lowering additions:** AUTHORISED — replacing
the C9 predecessor-store synthesis with original-site
store/load lowering for the eligible mutable local
only.

**Target machine / execution / ORC:** **FORBIDDEN**

**Language change authorization:** **NONE**

---

## 0. Mission

C9 attempted to memory-back a single mutable local via
a backend SSA cache and predecessor-store synthesis.
The reviewer board (post-closure on `e286f59`) judged
this architecturally broken: a single
`var.id → LLVMValueRef` map cannot represent a
path-dependent mutable variable.

CORRECTION02 replaces C9 with the **Option W**
contract:

```text
PolyC neutral IR
    mutable local definitions and reads
                ↓
LLVM backend
    alloca once in entry block
    store at each ORIGINAL definition site
    load at each ORIGINAL use site
                ↓
LLVM mem2reg
                ↓
SSA + PHIs
```

The invariant:

```text
A store is emitted because a PolyC definition occurs
HERE.

NEVER:
A store is emitted because a CFG successor will
eventually need one.
```

`lc->values[V]` is NOT authoritative for V once V is
classified as memory-backed.

---

## 1. Reviewer residue from CORRECTION01 closure

### 1.1 `e286f59` residue (P0-2)

The post-CLOSE evidence append at `e286f59` carries NO
`ACT:` trailer, so under Factory v2 grammar it has no
ACT identity binding. Mechanically:

```sh
$ git show -s --format='%B' e286f59 \
    | git interpret-trailers --parse
# (empty)
```

```text
e286f59
    identity      = NON_ACT
    limitation    = reviewer evidence is not mechanically
                    bound to an ACT lifecycle
    historical    = preserved
```

This is residue, not a defect: a docs-only `NON_ACT`
commit is not inherently malformed under the Factory
model. The bad outcome would have been a closed
CORRECTION01 id after its CLOSE, recreating rule-6
contamination. The append at `e286f59` is neither.

Per the reviewer board:

> Desired outcome is either NON_ACT or already the new
> CORRECTION02 identity — not the closed CORRECTION01
> id.

Append-only doctrine means we cannot fix the commit.
This ACT records the residue and ensures all
CORRECTION02 work carries a proper `ACT:` trailer so
that subsequent commits are mechanically bound to the
CORRECTION02 lifecycle.

### 1.2 Historical-evidence contamination (P0-3)

The regression harness transiently rewrites four files
under `evidence/llvm-core04-resume01/c2/red-multi_def/`
and `evidence/llvm-memory01/spike/red-6-live-transcripts/`
with the same counter drift on every run (2→7, 2→4).

This is a **producer** defect (harness writes outside
its evidence namespace), not a CORRECTION01 defect.
CORRECTION02 binds the producer fix as an ENTRY GATE
before any RED witness can be declared.

### 1.3 Runtime correctness is now mandatory

The IR verifier caught C9's bug. The next defect might
produce valid IR with the WRONG incoming value (which
verification would happily accept).

CORRECTION02 IMPL CLOSE requires semantic execution of
at minimum:

```text
ProbePath(0, 42)   == 10
ProbePath(5, 42)   == 43
ProbePath(-3, 42)  == -42

Diamond(true, 42)  == 43
Diamond(false, 42) == 41
```

If the host cannot execute the compiler output (e.g.
arm64 host vs. x86_64 runtime artifact), runtime
execution is recorded as an environment-dependent
CLOSE gate and CI/x86 carries the binding. The IR
verifier gate remains necessary but not sufficient.

---

## 2. Eligibility discriminator (FROZEN for CORRECTION02)

A mutable local V is eligible for Option W lowering
ONLY if all of the following hold:

```text
1. type == I64
2. not address-taken (no GEP, no escape, no &V)
3. all definitions are ordinary scalar assignments
   (IR_STORE to V's slot, with no nested GEP, no nested
   address-of, no IR_CALL argument passing)
4. all reads can be lowered directly (no IR_CALL passes
   V by address, no field access, no indexing)
5. compiler-generated return handling only
   (V is the source local feeding the synthetic return
   slot, or V is itself the function return local for
   void-returning functions — never a user-declared
   pointer alias)
6. DEFINITE ASSIGNMENT

   Every eligible read of V must have at least one
   reaching definition on every executable CFG path to
   that read.

   There must be no path from function entry to a read
   of V that contains no definition of V.

   This condition must be established mechanically
   from the neutral IR or inherited from an already-
   bound frontend definite-assignment invariant.

   Rationale: a verifier-pass on the post-mem2reg IR is
   not sufficient for uninitialized-value safety.
   mem2reg can promote loads not dominated by a store,
   but the uninitialised path remains semantically
   uninitialised. The IMPL must not let LLVM implicitly
   choose PolyC's uninitialised semantics for V.
```

If V fails any of the above, CORRECTION02 MUST:

  (a) reject the function with a named diagnostic
      (`LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE`).
      Do NOT silently produce wrong IR; OR
  (b) defer the entire shape (function, or distinct
      subgraph of the function) to a future ACT for
      which a dedicated RED witness will establish
      Option-W eligibility, possibly with a different
      lowering strategy.

It is FORBIDDEN to:

  - lower V through the C9 predecessor-store path;
  - silently fall back to C9 for an eligible V;
  - admit V to Option W with a documented gap in rule 6
    on the theory that "mem2reg will handle it";
  - extend the C9 machinery to cover V's shape.

The C9 predecessor-store path is closed for CORRECTION02
because CORRECTION01 closed it with
`HALT_DEFECTIVE_IMPL` (representation model is wrong for
path-dependent mutable locals; see §0). Bringing it
back, even conditionally, recreates the architecture
the reviewer board rejected.

The discriminator is conservative on purpose. A wider
discriminator can be approved by a future ACT after
evidence exists to justify it.

---

## 3. Two distinct storage concepts (RED recon)

C9 conflated two storage concepts:

```text
synthetic return slot
    the compiler-generated %t5-style slot that holds
    the value to be returned by the function
    (lives across the function's epilogue, single
    consumer: the IR_RET)

mutable source local
    a user-declared I64 local that the source program
    mutates across branches
    (lives across the function body, multiple
    consumers: every read in any basic block)
```

C9 attempted to memory-back the former and reconstruct
the latter at CFG edges. `ProbePath` proves the hard
state is the latter (%l6), while the former (%t5) is
just the final return slot.

CORRECTION02 RED recon must enumerate, for EVERY
target fixture in §5, the local's:

```text
local id                              (var.id)
definition block(s)                   (bb.id + exact instr)
read block(s)                         (bb.id + exact instr)
definition opcode                     (IR_STORE / IR_VAL_LOCAL / ...)
read opcode                           (IR_VAL_LOCAL / ...)
address taken?                        (yes / no)
escape/GEP?                           (yes / no)
type                                  (I64 / other)
every read definitely assigned on
every CFG path?                       (yes / no; required)
Option-W eligible?                    (yes / no + reason)
```

The "every read definitely assigned on every CFG path"
row is mandatory for every fixture. If the answer is
"no", the fixture is OUT of scope for this ACT (§2
rule 6); RED-2 records that explicitly with the
shortest witness path that lacks a reaching definition.

This recon is the §5 RED-2 artefact and MUST be
committed as evidence before any IMPL.

---

## 4. RED-1 (P0-1): harness evidence isolation

```text
run every regression/conservation harness
then: git status --porcelain
must NOT contain anything under:
  evidence/llvm-core04-resume01/
  evidence/llvm-memory01/
  any other closed ACT evidence tree
```

### 4.1 TOOLING IMPL authorisation

RED-1 is reproduced today (see
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c1/red-p01-harness-isolation.txt`).
Therefore the producer fix is authorised as a TOOLING
IMPL of CORRECTION02:

```text
TOOLING_IMPL_AUTH = RED-1 reproduced  ✅  (this commit)
```

Scope of the tooling IMPL is exactly:

  - `scripts/quality/*.sh` modifications that route
    evidence through `EVIDENCE_OUT` (preferred) or stop
    re-emitting evidence during ordinary regression;
  - the `make evidence-update` target if option (b) is
    chosen;
  - any harness test that proves a fresh regression
    run yields an empty `git status --porcelain` mod
    in-progress edits.

It is NOT a compiler change. `src/llvm-backend.c` and
the IR contract are NOT in tooling IMPL scope.

### 4.2 Producer fix (binding choice, two options)

  (a) accept an `EVIDENCE_OUT` env var and route every
      re-emitted summary into the current ACT's
      namespace; OR
  (b) stop re-emitting evidence during ordinary
      regression execution entirely (move emission to
      a separate `make evidence-update` target).

The binding choice is committed as the RED-1 IMPL
artefact, with a before/after diff that demonstrates a
fresh regression run yields an empty
`git status --porcelain`.

### 4.3 COMPILER IMPL authorisation (split from §4.1)

```text
COMPILER_IMPL_AUTH =
    TOOLING_IMPL_AUTH
    AND RED-1 producer fix GREEN
    AND RED-2 PASS
    AND RED-3 PASS
```

The cycle that existed in the prior draft ("IMPL must
wait for the harness fix, but the harness fix is an
IMPL change") is broken by recognising that the
harness repair is itself an IMPL but a TOOLING IMPL,
not a COMPILER IMPL. RED-2 and RED-3 may proceed in
parallel with the tooling IMPL.

### 4.4 HALT

If RED-1 cannot be reproduced as failing today, close
`HALT_RED1_NOT_REPRODUCED` (F3).

---

## 5. RED-2 (P0-1): mutable-local def/use recon

For each of:

```text
ProbePath               (P0-1 binding NC from C10)
Diamond                 (new)
pos_b0_compare_digit    (C8 RED)
i64_collapse_probe      (C8 RED)
single_cond_probe       (C8 RED)
safe_fwd_single_pred    (conservation control)
```

produce a structured §3-style table (one table per
fixture) committed as evidence. Each table is checked
against the actual neutral IR produced by the current
spike (`make ir-dump`) before being committed.

Evidence:
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c1/red-p02-def-use-tables.txt`

If any fixture fails the §2 discriminator, document
that explicitly in the table (the discriminator
expansion must be a future ACT, not C0).

---

## 6. RED-3 (P0-1): hand-translated Option-W proof

For each of the five fixtures above, hand-write the
pre-mem2reg LLVM IR that Option W SHOULD produce
(entry-block alloca, store at each original definition,
load at each original use), and require:

```text
opt -passes=mem2reg     PASS
opt -passes=verify      PASS
target alloca           gone
target loads/stores     gone
path merge              represented in SSA
```

For ProbePath, the hand-written pre-mem2reg IR MUST be
structurally equivalent to:

```llvm
entry:
    %r = alloca i64
    store i64 10, ptr %r

positive:
    %x1 = add i64 %x, 1
    store i64 %x1, ptr %r

negative:
    %nx = sub i64 0, %x
    store i64 %nx, ptr %r

exit:
    %value = load i64, ptr %r
    ret i64 %value
```

If `opt -passes=mem2reg + verify` does NOT promote
the alloca and produce a single PHI at exit, close
`HALT_OPTION_W_FALSIFIED`. Do not start IMPL.

Evidence:
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c1/red-p03-option-w-proof/`

---

## 7. Implementation freeze (only after all three REDs PASS)

When all three RED artefacts are GREEN, the IMPL MAY
proceed. The IMPL is bound by the following remove
list (C9 machinery to delete, not extend):

```text
llEmitMem2RegStoreAtPredEnd
lc->mem2reg_store_block_id
lc->mem2reg_store_value
IR_JMP synthetic store injection
IR_BR  synthetic store injection
```

The replacement invariant:

```text
on definition of memory-backed V (at the ORIGINAL site):
    rhs = lower(...)
    LLVMBuildStore(rhs, slot)

on read of memory-backed V (at the ORIGINAL site):
    LLVMBuildLoad2(..., slot)

after function construction:
    LLVMRunPassesOnFunction("mem2reg,verify")

lc->values[V]:
    NOT authoritative while V is memory-backed
```

A backend store must ALWAYS have a direct neutral-IR
semantic cause. The "store is needed because a CFG
successor will eventually need one" motivation is
deleted from the backend entirely.

---

## 8. Acceptance criteria

AC01: TOOLING IMPL for harness isolation committed
      AND a fresh regression run produces an empty
      `git status --porcelain` mod in-progress edits.
      (This is the §4.1 / §4.2 tooling IMPL, NOT a
      compiler IMPL.)

AC02: RED-2 def/use tables committed for all six
      fixtures (ProbePath, Diamond, pos_b0_compare_digit,
      i64_collapse_probe, single_cond_probe,
      safe_fwd_single_pred).

AC03: RED-3 hand-translated Option-W proof committed
      for all five eligible fixtures and PASSES
      `opt -passes=mem2reg` + `opt -passes=verify`.

AC04: At COMPILER IMPL commit time, all C9
      remove-list symbols are deleted from
      `src/llvm-backend.c` and no new
      predecessor-store synthesis helper exists.
      The "fallback_to_C9" path is mechanically
      impossible: there is no branch in the backend
      that calls into any C9 remove-list helper. This
      is verified by a `grep`-based test that fails
      if any of the remove-list identifiers appears
      anywhere in `src/` after IMPL.

AC05: At COMPILER IMPL commit time, the §2
      discriminator is implemented in the backend
      (`llIsOptionWEligible`) and any ineligible V is
      rejected with a named diagnostic
      (`LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE`).
      The CORRECTION02 IMPL MUST NOT contain any path
      that lowers an ineligible V through the C9
      predecessor-store path. Such a path is FORBIDDEN
      by §2 and §10. The IMPL CLOSE evidence must show
      the negative-result branch in the IR pipeline
      for at least one deliberately-ineligible fixture.

AC06: At IMPL CLOSE commit time, the IMPL artifacts
      (`.bc` or `.ll`) for ProbePath and Diamond are
      inspected and contain:
      - one entry-block alloca;
      - one store per ORIGINAL definition site
        (no store at terminator);
      - one load at the original read site;
      - no `phi` operand that does not dominate its use
        (verifier check).

AC07: At IMPL CLOSE commit time, semantic execution of:
      `ProbePath(0, 42)   == 10`
      `ProbePath(5, 42)   == 43`
      `ProbePath(-3, 42)  == -42`
      `Diamond(true, 42)  == 43`
      `Diamond(false, 42) == 41`
      is captured as evidence. If host execution is
      impossible (arm64 host vs. x86_64 runtime), the
      evidence is `RED_RUNTIME_HOST_MISMATCH` and the
      CLOSE verdict is bound to a CI/x86 captured run.

AC08: At IMPL CLOSE commit time, all 18 prior
      `llvm-spike-test` fixtures still pass.

AC09: At IMPL CLOSE commit time, the 3 RED fixtures
      from C8 (`single_cond_probe`, `i64_collapse_probe`,
      `pos_b0_compare_digit`) stay GREEN.

AC10: At IMPL CLOSE commit time, the P0-1 binding NC
      `nc_p01_predecessor_paths.HC` is GREEN.

AC11: `make clean && make` succeeds at every commit.

AC12: `git diff --check HEAD` returns rc=0 at every
      commit.

AC13: Identity oracle (`factory-closure-status`)
      exits 0 at CLOSE.

---

## 9. Conservation gates

| Gate                                       | expected                        |
|--------------------------------------------|---------------------------------|
| `git diff --check HEAD`                    | rc=0                            |
| `make clean && make`                       | succeeds                        |
| `llvm-spike-test`                          | 18 PASS / 0 FAIL baseline       |
| `factory-closure-status`                   | exit 0                          |
| `factory-append-only-test`                 | PASS=11 / 0 FAIL                |
| `ir-return-slot-forwarding01-test`         | PASS=6 / 0 FAIL                 |
| harness-isolation `git status --porcelain` | empty after every RED run       |
| C9 remove-list grep                        | no matches                      |

---

## 10. Forbidden (preserved from CORRECTION01)

* No neutral-IR contract change.
* No new SUPPORTED opcode or type.
* No new mutable-local class admitted beyond the §2
  discriminator.
* No path through the backend that lowers any V through
  the C9 predecessor-store machinery. CORRECTION01
  closed that machinery with `HALT_DEFECTIVE_IMPL`;
  CORRECTION02 MUST NOT revive it, even conditionally,
  even with an "if-and-only-if proven correct" gate.
  If V is ineligible for Option W, V is REJECTED or
  DEFERRED. There is no third option.
* No incremental half-removal of the C9 machinery. The
  remove-list in §7 is deleted atomically in the
  COMPILER IMPL commit; no intermediate state is
  permitted where the C9 helpers are partially gone.
* No scope expansion to byte arrays, structs, arrays,
  or GEP in this ACT. These are future ACTs.
* No deferral that lowers an ineligible V by inventing
  a new predecessor-store strategy. New strategies are
  a new ACT, not a CORRECTION02 amendment.

---

## 11. Commit topology

```text
C1  RED
    contract open + RED-1 reproduced
    ACT-Phase: RED

C2  RED   (this commit)
    reviewer board corrections to contract:
      P0-1 gate cycle split into TOOLING_IMPL_AUTH vs
            COMPILER_IMPL_AUTH
      P0-2 §2(b) escape hatch removed; §2 rule 6
            replaced with definite-assignment
      P0-3 §3 table extended with "every read
            definitely assigned on every CFG path"
            row (mandatory)
      P1  §1.1 / §12 wording softening (residue, not
            defect)
    ACT-Phase: RED

C3  RED
    RED-2: def/use tables for six fixtures
    ACT-Phase: RED

C4  RED
    RED-3: hand-translated Option-W proof for five
           eligible fixtures via
           `opt -passes=mem2reg + verify`
    ACT-Phase: RED

C5  IMPL-TOOLING
    harness-isolation producer fix
    scripts/quality/* and Makefile only
    no src/ change
    ACT-Phase: IMPL (TOOLING)

C6  IMPL-COMPILER
    bounded backend change: delete C9 remove-list,
    implement §2 discriminator, implement §7
    invariant
    src/llvm-backend.c only
    ACT-Phase: IMPL (COMPILER)

C7  CLOSE
    acceptance-criteria evidence + verdict
    ACT-Phase: CLOSE
```

Seven commits. F12 honest classification per phase;
TOOLING and COMPILER IMPL are distinct phases because
they have distinct authorisation predicates (§4.1,
§4.3).

---

## 12. Residue (carried forward)

* `e286f59` (P0-2): the post-CLOSE evidence append
  carries no `ACT:` trailer. Cannot be amended under
  append-only doctrine.

  ```text
  e286f59
      identity   = NON_ACT
      limitation = reviewer evidence is not mechanically
                   bound to an ACT lifecycle
      historical = preserved
  ```

  Recorded here for future audits. All CORRECTION02
  commits carry a proper `ACT:` trailer.

* Historical-evidence contamination (P0-3): the
  harness producer defect remains unfixed at
  CORRECTION02 OPEN. RED-1 binds the fix as a TOOLING
  IMPL entry gate (§4.1). When C5 lands, the
  contamination becomes a closed defect.

* The native backend remains the small differential /
  reference backend. No LLVM parity claims for the
  native backend are made in this ACT.

* Runtime vs. host architecture: if the local host
  cannot execute the compiler output, the semantic
  controls in AC07 fall back to CI/x86. The IR verifier
  gate remains the local-environment binding.

* P0-1/P0-2/P0-3 reviewer-board corrections (this
  commit C2): three contract defects identified during
  the C1 review. Corrections recorded inline in §1.1,
  §2, §3, §4, §10, §11, §14. No production code change.

---

## 13. Halt taxonomy

This ACT closes `PASS` only if all three REDs PASS
and the IMPL satisfies all acceptance criteria.

Possible halt verdicts:

```text
HALT_RED1_NOT_REPRODUCED      (harness isolation is
                               already fixed today;
                               RED-1 fix becomes
                               moot)
HALT_RED2_INELIGIBLE          (a fixture fails the §2
                               discriminator — including
                               rule 6 definite-assignment
                               — and document-as-future-
                               ACT is impossible because
                               the fixture is B0-binding)
HALT_OPTION_W_FALSIFIED       (opt -passes=mem2reg +
                               verify cannot promote the
                               hand-written pre-IR; the
                               architecture is wrong)
HALT_IMPL_SCOPE_EXPANSION     (COMPILER IMPL cannot
                               satisfy the remove-list
                               without broadening scope)
HALT_C9_FALLBACK_INTRODUCED   (COMPILER IMPL accidentally
                               revives the C9 path; the
                               grep-based test in AC04
                               detects it)
HALT_UNINITIALISED_VALUE      (an eligible V admits a
                               read with no reaching
                               definition; rule 6
                               violated; the verifier
                               would have passed but
                               the runtime gate fails)
HALT_RUNTIME_HOST_MISMATCH    (host cannot execute
                               compiler output; AC07
                               cannot be closed locally
                               and the gate must be
                               bound to CI/x86)
```

---

## 14. Authorisation

The reviewer board explicitly authorised writing the
full CORRECTION02 contract at this point. They did
NOT authorise production COMPILER IMPL — the
hand-translated Option-W RED is cheap and is exactly
the kind of experiment that should happen before
replacing several hundred lines of backend logic.

Authorisation predicates:

```text
TOOLING_IMPL_AUTH =
    RED-1 reproduced                    ✅ (C1)

COMPILER_IMPL_AUTH =
    TOOLING_IMPL_AUTH
    AND RED-1 producer fix GREEN        (C5)
    AND RED-2 PASS                      (C3)
    AND RED-3 PASS                      (C4)
```

RED-2 and RED-3 MAY proceed in parallel with the
TOOLING IMPL. They MUST all PASS before COMPILER IMPL
is authorised.

Until COMPILER_IMPL_AUTH is true, this ACT remains in
RED phase and `src/llvm-backend.c` is untouched.

ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
ACT-Phase: RED
