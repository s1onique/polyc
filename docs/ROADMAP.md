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

Blocked until:

- IR-BOUNDARY02 restores the native baseline;
- LLVM 22 development tooling is available.

First goal:

    PolyC neutral IR
        ->
    verifier-clean textual LLVM IR

Initial subset:

- I64 parameters;
- I64 constants;
- add/sub/mul;
- comparisons;
- conditional/unconditional branches;
- direct calls;
- return.

No ORC initially.

No LLVM optimization initially.

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
