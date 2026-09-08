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

### P4 — LLVM core semantic coverage

Expand only from evidence.

Likely areas:

- integer widths/signedness;
- F32/F64;
- memory load/store;
- pointers/GEP;
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
