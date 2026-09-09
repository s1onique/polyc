# PolyC Experimental Roadmap

This is an experimental map, not a release promise.

Ordering may change as evidence invalidates assumptions.

## Current position

### P0 — Preserve inherited behavior

Status: ACTIVE / foundational.

Goals:

- maintain executable baselines;
- preserve meaningful HolyC behavior while architecture changes;
- use differential evidence rather than assumptions.

### P1 — Understand the inherited compiler

Status: SUBSTANTIALLY COMPLETE via RECON01.

Established areas include:

- frontend topology;
- IR topology;
- AOT/JIT/REPL paths;
- native performance baseline.

### P2 — Backend-neutral semantic boundary

Status: IN REPAIR.

IR-BOUNDARY01 demonstrated a useful neutral/native distinction, including
separation of semantic parameters from physical register identities.

However its implementation introduced an AOT regression in struct
by-value / sret ABI paths.

Before the boundary is considered stable:

    ACT-POLYC-IR-BOUNDARY02

must restore the clean predecessor baseline on a fresh build while
preserving the neutral contract.

## Near horizon

### P3 — LLVM IR spike

Status: **DONE** via ACT-POLYC-LLVM-SPIKE01 + RESUME01 +
CORRECTION01 chains. Closure repair at
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02.

Final state (reviewer-accepted):

```
LLVM scalar spike
    direct SSA scalar binding             PASS
LLVM memory operations
    alloca 0  load 0  store 0
unsupported multi-store local
    explicit rejection                    PASS
PHI                                          not implemented (intentional)
memory fallback                              absent                  PASS
LLVM matrix                                  PASS=13 FAIL=0
historical C1 evidence                       immutable              PASS
native conservation                          PASS
closure inheritance                          ancestry+scope+conserv  PASS
```

Spike was "can this work?" — answer is yes, with explicit semantic fences.

### P3.5 — LLVM core semantic contract (CORE01)

Status: **AUTHORIZED** as next ACT (`ACT-POLYC-LLVM-CORE01`).
Reviewer unblocked 2026-09-08.

Conceptual transition:

    SPIKE:  "Can this work?"
        ↓
    CORE:   "Exactly what do we promise works,
             and exactly how do we refuse everything else?"

Required deliverables:

- capability table for neutral IR operations and types
  (SUPPORTED / REJECTED / NOT_YET_CLASSIFIED);
- canonise the single-definition-local SSA fence;
- resolve the `LLVMBuildTrunc(i1 → i1)` residue
  (current code widens the comparison to i64, then truncates — confirm
  whether a direct i1 IR shape would avoid the residue entirely);
- make backend diagnostics part of the contract
  (every REJECTED opcode has a named diagnostic, no silent acceptance);
- test rejection boundaries as seriously as successful lowering;
- explicit non-support for: PHI, memory load/store, F64, pointers,
  aggregates, target machine, ORC, execution.

### P3.6 — LLVM memory slice (MEMORY01)

Status: **DONE** via ACT-POLYC-LLVM-MEMORY01.

Conceptual transition:

    CORE:   "Exactly what do we promise works,
             and exactly how do we refuse everything else?"
        ↓
    MEMORY: "Real semantic memory access, still refused for everything else."

Promoted opcodes:

- `IR_LOAD_DEREF` and `IR_STORE_DEREF` from `REJECTED` to
  `SHAPE_DEPENDENT`. The supported shape is strictly:
  address-space-0 pointer parameter + I64 access type. Every
  other dereference shape remains rejected with a named
  diagnostic (`LLVM_BACKEND_UNSUPPORTED_POINTER` /
  `LLVM_BACKEND_UNSUPPORTED_TYPE`).

Other semantic changes from MEMORY01:

- IR_TYPE_PTR is now SUPPORTED as a function parameter type,
  lowered to LLVM opaque `ptr` via `LLVMPointerTypeInContext(ctx, 0)`.
- Pointer-typed SSA locals are now supported (no alloca, no
  store-to-local, no load-from-local; the local is bound to the
  SSA pointer value).
- The constant-cache aliasing bug (constants' `as._i64 = N`
  overlaid `as.var.id = N`, colliding with parameter/tmps at
  the same id) is fixed locally in `llLowerValue` for IR_VAL_CONST_INT;
  this also incidentally corrects a long-standing silent
  miscompilation in the existing scalar spike (`x + 1` was
  emitted as `x + x` because of the same aliasing).

Closed (per ACT-POLYC-LLVM-MEMORY01):

```
LLVM memory slice
    pointer-param I64 dereference load    supported       PASS
    pointer-param I64 dereference store   supported       PASS
LLVM opaque-pointer model                correct         PASS
pointee/access type                       proven, not guessed
llvm-as                                  PASS
LLVM verifier (opt --passes=verify)      PASS
GEP in MEMORY01 fixtures                 0               PASS
alloca in MEMORY01 fixtures              0               PASS
ptrtoint/inttoptr/bitcast in fixtures    0               PASS
SSA-local memory fallback                0               PASS
native semantics                         unchanged       PASS
existing LLVM core spike                 GREEN           PASS (PASS=18 FAIL=0)
historical evidence                      conserved       PASS
Factory v2                               GREEN           PASS
ACT-range hygiene (git diff --check)     PASS            PASS
```

Closure commit count: 5 commits across RED + IMPL +
EVIDENCE + CLOSE phases (plus an in-range whitespace-normalisation
fixup; see ACT-POLYC-LLVM-MEMORY01-CORRECTION01 for the NC5
hardening that required a fresh tree). Factory v2 has no numeric
commit cap; this number is descriptive only.

Counter snapshot from the closure run:

```
=== capability counters (MEMORY01 matrix) ===
SUPPORTED           : 7
REJECTED            : 0
SHAPE_DEPENDENT     : 8
DEFENSIVE_INVARIANT : 0
UNREACHABLE_ON_LLVM : 0
```

Note on `REJECTED = 0`: ACT §11 expected `REJECTED > 0`,
which is falsified for the MEMORY01 matrix. The MEMORY01
negative matrix exercises exactly one fixture (`neg_struct.HC`)
which is rejected at the function-parameter type admission
seam (`llPass1`) BEFORE any per-opcode dispatch arm runs; that
class-generic rejection fires `LLVM_BACKEND_UNSUPPORTED_TYPE`
and exits, but does not increment the per-opcode REJECTED
counter (the per-opcode counter exists in the capability table
and is exercised by the predecessor `llvm-spike-test.sh`
negative matrix, where each rejected fixture's per-opcode arm
emits `LL_INC_REJECTED`). The MEMORY01 matrix is intentionally
narrow: it tests the supported path plus exactly one class-
generic rejection, not per-opcode rejection. The `REJECTED > 0`
expectation was therefore NOT APPLICABLE TO MEMORY01 MATRIX;
no code or counter bug exists. ACT-POLYC-LLVM-MEMORY01-
CORRECTION01 records this falsification.

Residue intentionally left for later (per ACT §27):
F64 memory, narrow int memory, struct/aggregate memory, arrays,
field access, GEP, pointer arithmetic, pointer comparison,
pointer casts, globals, heap memory, stack allocation,
volatile/atomic, non-zero address spaces, pointer ABI
generalization, LLVM execution, TargetMachine/object emission,
ORC/JIT.

P1 residue (IR-level):
The IR-side `as._i64` / `as.var.id` union aliasing is now
worked around in the LLVM backend; a neutral-IR-level fix
(separate the `_i64` field from `var.id` storage, or assign
constants a unique id space) is out of scope for MEMORY01 and
would require a separate IR ACT (see ACT §23
HALT_NEUTRAL_IR_CHANGE_REQUIRED).

### P4 — LLVM core semantic coverage

Expand only from evidence.

Likely areas:

- integer widths/signedness;
- F32/F64;
- struct/aggregate memory (after MEMORY01 closes the IR-side
  constant-id aliasing or after a dedicated GEP ACT);
- pointer arithmetic / GEP;
- globals;
- external functions;
- aggregate layout;
- ABI-sensitive values.

### P5 — LLVM execution

Establish native-code execution and semantic parity before introducing a
persistent LLVM JIT environment.

Possible progression:

    LLVM IR
      ->
    TargetMachine/object
      ->
    executable witness

### P6 — LLVM ORC

Only after core lowering and execution semantics are trustworthy.

Measure separately:

- persistent context/session startup;
- module construction;
- verification;
- optimization;
- target code generation;
- JIT linking;
- lookup;
- execution.

Compare against the inherited native JIT rather than against intuition.

### P7 — Persistent compiler session

Generalize the live environment around a persistent semantic/compiler
session shared by:

- human REPL;
- agent API;
- embedded API.

### P8 — Agent protocol

Candidate operations:

    define
    compile
    call
    inspect
    replace
    disassemble
    test

Responses should be structured and deterministic.

The compiler does not need an embedded LLM.

## Language evolution

Language evolution should begin only when foundational architecture is
sufficiently stable to measure semantic and performance consequences.

Candidate areas are tracked in DESIGN-NOTES.md.

Potential priorities:

1. structured diagnostics;
2. algebraic/sum types;
3. Option/Result;
4. exhaustive pattern-oriented switch;
5. minimal parametric polymorphism;
6. immutable bindings;
7. first-class function values;
8. inspectable closures;
9. arena/region facilities;
10. explicit ownership vocabulary;
11. effect/capability experiments.

None are committed syntax or semantics.

## Compiler observability

Long-term experiments may expose:

- compiler-stage timing;
- allocation accounting;
- emitted IR;
- emitted assembly;
- generated code size;
- specialization/monomorphization cost;
- effect/capability summaries.

Performance regressions should eventually become testable similarly to
correctness regressions.

## Self-hosting path

Self-hosting is a long-horizon objective.

A plausible staged progression:

### SH1 — PolyC systems library substrate

Build enough stable facilities to comfortably write compiler code:

- strings;
- vectors;
- maps;
- arenas;
- files;
- paths;
- diagnostics;
- byte buffers.

### SH2 — Self-hosted frontend

Migrate bounded compiler components:

- token model;
- lexer;
- source positions;
- diagnostics;
- parser;
- AST;
- semantic analysis.

Use differential tests against the C implementation during transition.

### SH3 — Self-hosted middle-end

Move:

- IR construction;
- CFG;
- validation;
- optimization;
- backend-independent transformations.

### SH4 — Self-hosted LLVM adapter

Use LLVM through a stable C ABI from PolyC.

LLVM itself need not be rewritten in PolyC for the compiler to count as
self-hosted.

### SH5 — Bootstrap closure

Establish:

    stage0 -> stage1 -> stage2 -> stage3

and define an appropriate reproducibility/equivalence criterion for:

    stage2 ~= stage3

### SH6 — Small trusted seed

Reduce the normal bootstrap dependency to a small, auditable seed.

Possible forms are intentionally undecided.

## Factory-tooling roadmap

### FT1 — Closure oracle trust (deferred from CORRECTION02)

Status: P1 residue recorded by reviewer; non-blocking for compiler work.

Issue: the closure oracle (`evidence/.../identity.sh`) lives inside
its own allowed descendant set. A future commit could weaken the
oracle (e.g. drop invariant B) and the path-classification rule would
still classify it as allowed. Current descendants are all reviewed;
the issue is reusability, not present correctness.

Recommended fix (reviewer option C): relocate reusable closure oracles
to `scripts/quality/` (or equivalent). Treat closure-validation code
as gate machinery, not disposable evidence. Changes require an
explicit gate/review rather than inheriting the old subject.

Dedicated ACT: `ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01` (to be opened).

### FT2 — Range checker post-CLOSE descendant scan (P2; deferred from CORRECTION01 close)

Status: P2 residue recorded by reviewer; non-blocking for compiler work.

Issue: `factory-v2-range-check.sh` currently walks the full
reachable history with `git rev-list --children --all` to
enforce the doctrine rule "no commit after CLOSE may carry
`ACT: <id>`" (GIT-METADATA.md §7). Reviewer observes this is
a global descendant invariant — exactly the kind of
"increasingly clever history oracle" pattern Factory v1
suffered from, and a recurrence the Factory-v2 thesis
specifically aimed to escape.

Cleaner model: a CLOSE terminates its own execution range.
`factory-v2-range-check.sh` validates only the contiguous
backward run ending at that CLOSE. Future misuse of the same
ACT id (e.g. an agent reverting or hand-editing history) is
caught at commit time by `factory-v2-commit-msg-check.sh`,
not retroactively by the historical range checker.

Proposed change (not yet authorised by an ACT):
- remove the `git rev-list --children --all` block and the
  per-child ACT scan from `factory-v2-range-check.sh`;
- delete rule 7 ("No commit after CLOSE may carry `ACT: <id>`")
  from `docs/factory/GIT-METADATA.md`, OR replace it with a
  commit-policy rule (commit-msg check) rather than a
  range-check rule;
- add one positive test verifying that a CLOSE remains PASS
  even after unrelated descendant commits are added;
- record the precedent: corrections always use a new ACT id;
  closed ACT ids are immutable execution identifiers.

Reviewer explicitly recommended deferring this to P2 and
proceeding to CORE04 rather than opening
`SIMPLIFY01-CORRECTION02`. Adopted as policy here.

No defect has been demonstrated against the current
descendant scan; this is a complexity-reduction proposal,
not a fix.

Dedicated ACT: `ACT-POLYC-FACTORY-RANGE-CHECK-DESCENDANT-SCAN01`
(to be opened only if a real defect is observed or if a new
ACT needs to remove the rule for forward-graph reasons).

### FT3 — Trailer-key casing policy (P2; deferred)

Status: P2 residue recorded by reviewer; non-blocking for
compiler work.

Classification:

```text
POLICY_DECISION = MADE   (case-sensitive `ACT:` is canonical)
IMPLEMENTATION  = NOT_DONE
SEVERITY        = P2
BLOCKS_CORE04   = NO
```

Important: behaviour gap is **not** closed. The current
validator lets `act:` slip into `MODE=NON_ACT` rather than
emitting a Factory-side `MODE=ACT STATUS=FAIL`. The proposed
enforcement would explicitly route `act:` into
`MODE=ACT STATUS=FAIL REASON=ACT trailer key must be
uppercase`. Do not let a future reviewer infer that
lowercase-key rejection is already mechanically enforced.

Recorded against reviewer feedback. Wording correction
applied here; the underlying validator behaviour is left
untouched per the discipline rule that Factory
implementation only changes inside a dedicated Factory ACT.

Observed (verified against the committed validator):

```text
factory-v2-commit-msg-check.sh:73
    grep -Eq '^ACT:[[:space:]]+.+'
```

is case-sensitive. So `ACT: ACT-POLYC-...` triggers the
ACT path, but `act: ACT-POLYC-...` falls through to
`MODE=NON_ACT`. Same for `trailer_value` (line 97) — the
awk match is case-sensitive.

Reviewer identifies a latent problem: Git's own trailer
facilities treat configured trailer keys case-insensitively,
so humans and tools that produce `act:` thinking they are
supplying Factory metadata would silently get the ordinary
NON_ACT treatment. That is a worse failure than the original
case-sensitivity because the user clearly intended ACT
metadata and got none of the validation.

Proposed policy (reviewer option A — adopt):

> Factory trailer keys are canonically case-sensitive in the
> PolyC validator even though Git itself is more permissive.
> `ACT:` is the only accepted spelling. `act:`, `Act:`,
> `aCt:`, etc. are malformed Factory metadata.

Two reasons to lock this in rather than relax it:

1. **Diagnostic clarity.** Every Git pretty-format tool,
   `git log`, `git log -10 --format=%(trailers:key=ACT,valueonly)`,
   `git interpret-trailers`, and human eye all expect
   uppercase. Lowercase would surprise reviewers reading
   `git log` output. Keep one canonical spelling.
2. **Validation totality.** The validator is case-sensitive
   today; preserving that means malformed casing produces a
   predictable FAIL with `REASON=...` rather than slipping
   through.

Implementation note (for the eventual ACT):

- the case-sensitive grep on line 73 is the right behaviour;
  add a test asserting that `act:` falls into MODE=ACT with
  `STATUS=FAIL REASON=ACT trailer key must be uppercase`;
- explicitly document the policy in `docs/factory/GIT-METADATA.md`
  under the trailer schema table;
- add a non-mandatory `git interpret-trailers --parse` cross
  check is **not** required — the awk match is sufficient and
  avoids depending on Git's case-insensitive behaviour.

Dedicated ACT: `ACT-POLYC-FACTORY-TRAILER-CASING-POLICY01`
(to be opened only if a future FAILer report requires
formalising the rule, or if the case-sensitive grep is ever
inadvertently relaxed).


### CORE04 — first real Factory-v2 compiler ACT (HALT → RESUME01)

Status: HALT_RED_NOT_REPRODUCED recorded at `4be5df3`;
continuation `ACT-POLYC-LLVM-CORE04-RESUME01` authorised
and ready to enter C1.

CORE04 originally proposed two missions transcribed from
`ACT-POLYC-LLVM-CORE03 §8`:

- M1: assert every `case IR_X:` in the dispatch has a
  matching `kLLVMBackendCapability[]` row (the reverse of
  CORE03 M1).
- M2: per-class execution counters in the harness summary.

Pre-C1 recon (F2) established that M1 was **stale**: the
predecessor chain (`CORE03-CORRECTION01`,
`CORE03-CORRECTION02`, `CORE03-CORRECTION03`) already
delivered the I2 reverse check inside
`scripts/quality/llvm-cap-table-verifier.py`. The current
verifier runs rc=0 with all three invariants (I1, I2, I3)
green; CORE04's `grep` for `inverse|dispatch_count|case_count`
searched only the C runtime, not the verifier, so it missed
the implementation. AC09 (`case IR_FAKE_OP:`) also failed
to bind — `IR_FAKE_OP` is not in the `IrOp` enum and would
fail C compilation before any runtime check runs.

The genuine remaining CORE04 work, per
`CORE03-CORRECTION03` P1 residue and `llvm-cap-table-verifier.py`
header, is the **dispatch-discovery scope mismatch**:
`get_dispatch_arms()` still scans file-wide for
`if (ins->op == IR_X)` short-circuits, while the
arm-local body extractor scopes to `llLowerInstr` and
explicit switch helpers. CORE04-CORRECTION03 closed the
symptom (bad rows in `kLLVMBackendCapability[]`); RESUME01
closes the cause.

CORE04 was also critiqued for proposing a third
hand-maintained dispatch list (`llValidateDispatchCoverage()`
runtime C list) when the verifier was already the canonical
seam. The proposed C-side list is dropped, not deferred.

Reviewer disposition:

- **CORE04** — `HALT_RED_NOT_REPRODUCED`. Verdict recorded
  in CLOSE commit trailer on main. ACT document remains
  historically stable (F14; Factory v2).
- **CORE04-RESUME01** — authorised with the corrected
  missions:

```text
M1  unify get_dispatch_arms() discovery with arm-local
    body extraction into one scoped dispatch model in
    scripts/quality/llvm-cap-table-verifier.py;
    reproduce the discovery-scope mismatch adversarially
    via an in-file seeded constant; GREEN only after the
    unified scoped model rejects the adversarial
    `if (ins->op == IR_X)` outside the real dispatch
    functions.

M2  per-class execution counters in the harness summary;
    decide explicitly where counters live and how
    multiple functions/modules aggregate into harness-
    level totals.
```

Production-semantic changes: none. Production diagnostic
additions: none. LLVM IR lowering additions: none. Language
change authorization: none.

Reviewer discipline rule baked into RESUME01 §13:

> No Factory implementation changes inside RESUME01 unless
> a RESUME01 RED actually demonstrates that Factory v2
> prevents or invalidates the compiler ACT.

Factory v2 exercises correctly: the halt was cheap (one
CLOSE commit + one HANDOFF + one new ACT authorization),
no SHA-table surgery, no ACT-document mutation at closure,
verdict identity lives in the trailer.

Reviewer-accepted phase bookkeeping after the pre-IMPL
review:

- `0604467` is the **documentary-RED commit** — it opens
  the ACT and captures RED-M1 (CORRECTION03 residue line
  246-247) and RED-M2 (`grep` returns no matches) in
  prose. Both REDs are observable from committed tree
  state.
- The first *code* commit (C1) is the **executable RED**
  — adds `check_dispatch_scope_is_tight()` with permanent
  adversarial fixture, and a `counters=missing` line in
  `llvm-spike-test.sh`. Trailer `ACT-Phase: RED`.
- The next commit (C2) is **IMPL** — flips both to PASS.
  Trailer `ACT-Phase: IMPL`. C2 actually shipped as three
  IMPL/EVIDENCE commits because the reviewer issued a
  HOLD C3 verdict after the initial C2 GREEN, citing two
  binding defects (P0-1 historical evidence conservation,
  P0-2 location-aware rogue-arm check). The full C2 chain
  is:
    - `e10f9f9` initial C2 IMPL GREEN (`ACT-Phase: IMPL`)
    - `f5d0f84` C2 P0-1/P0-2 corrections (`ACT-Phase: IMPL`)
    - `a3d27e9` C2 evidence refresh — post-correction
      snapshot of `legacy-spike-test.txt` and
      `m1-verifier-green.txt` (`ACT-Phase: IMPL`)
  After `a3d27e9`, the reviewer ACCEPTed C2 and
  authorized C3 EVIDENCE.
- The next commit (C3) is **EVIDENCE** — captures the
  reviewer-closed disposition, the strong NC1 for the
  location-aware rogue check, the post-rename adversarial
  fixture (real IrOp names so scope discovery is exercised
  rather than enum-name filtering), and the final counter
  baseline (supported=14, rejected=4, shape_dependent=7,
  defensive=0, unreachable=0). Trailer `ACT-Phase:
  EVIDENCE`.
- The final commit (C4) will be **CLOSE** — `ACT-Verdict:
  PASS` trailer only; no production code, no
  semantic change.
- The adversarial fixture is **permanent** (AC13); not
  removed at GREEN.
- Closure hygiene uses the **ACT-derived range**:
  `git diff --check <RESUME01-entry>..<RESUME01-CLOSE>`,
  not `git diff --check HEAD`. The grandfathered EOF
  whitespace in `evidence/llvm-core04/HANDOFF.md:229`
  (committed at `4be5df3`) is recorded as P2 residue
  and does NOT block RESUME01 closure per F14 (historical
  HALT evidence is not rewritten).


## Things that may never happen

Not every interesting language mechanism belongs in PolyC.

Strong skepticism applies to:

- mandatory garbage collection;
- invisible exception-based control flow;
- C++-style template metaprogramming;
- enormous trait/typeclass machinery;
- classical encapsulation whose main purpose is hiding implementation;
- a mandatory Rust-scale borrow checker;
- dependency ecosystems required for trivial programs.

These are design biases, not eternal prohibitions.
