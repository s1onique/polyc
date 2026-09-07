# PolyC Design Notes

This document records candidate directions.

Nothing here is a language commitment.

Ideas graduate from this document only through a deliberate design and
implementation process.

## 1. Algebraic / sum types

Motivation:

Represent state alternatives directly rather than encoding invariants in
tag + partially-valid field structures.

Example concept:

    ParseResult =
        Ok(Node)
      | Eof
      | Error(ParseError)

Systems representation can remain simple:

    tag + payload

Potential benefits:

- fewer invalid states;
- fewer comments describing invariants;
- better exhaustive checking;
- excellent machine-readable state for agents.

## 2. Pattern-oriented switch

HolyC already has a stronger-than-C switch tradition.

A restrained extension could destructure sum-type variants:

    switch result {
    case Ok(node):
        Use(node);
    case Eof:
        ...
    case Error(err):
        ...
    }

Avoid initially:

- view patterns;
- active patterns;
- pattern-synonym systems;
- a second embedded pattern language.

## 3. Option and Result

Potential standard forms:

    Option<T>
    Result<T, E>

Goals:

- remove ambiguous sentinel/null conventions;
- make expected failure part of the type;
- enable structured propagation.

These should be ordinary representable values, not hidden runtime
machinery.

## 4. Ownership vocabulary without an immediate full borrow checker

C-like pointers carry too little ownership information.

Possible future distinctions:

- ordinary/raw pointer;
- borrowed reference;
- owning pointer.

Goals:

- document mechanically what programmers already reason about;
- diagnose obvious lifetime mistakes;
- retain unrestricted explicit low-level access.

Do not assume Rust's lifetime/borrow system is the target architecture.

## 5. Arena / region lifetimes

Arenas are especially attractive for:

- compiler workloads;
- parsing;
- request/session transactions;
- agent-generated short-lived work.

Benefits:

- low allocation overhead;
- simple bulk lifetime;
- locality;
- deterministic release;
- easy compiler implementation.

Potential syntax is deliberately undecided.

## 6. Immutability

Mutation remains essential in systems programming.

However immutable values can reduce reasoning state.

Possible direction:

- make immutable local bindings concise;
- require explicit intent for mutation where this improves clarity.

Do not impose functional purity.

## 7. First-class functions

Function values should remain direct and inspectable.

Desired qualities:

- obvious representation;
- no mandatory boxing;
- no hidden heap allocation.

## 8. Closures

Closures are desirable, but their representation and allocation should be
inspectable.

Conceptual representation:

    code pointer + environment pointer

The environment's allocation strategy should not be hidden when it
matters.

## 9. Minimal generics

Compiler self-hosting strongly benefits from types such as:

    Vec<Token>
    Vec<Node>
    Option<Type>
    Map<Symbol, Definition>

The intended direction is parameterized types/functions, not a
metaprogramming universe.

Likely initial strategy:

- monomorphization;
- constrained semantics;
- no SFINAE-like machinery;
- no accidental second compile-time language.

## 10. Compile-time execution

HolyC already legitimizes runtime/compiler-time continuity.

PolyC should explore using PolyC itself rather than proliferating:

- preprocessors;
- build DSLs;
- shell generators;
- Python code generation scripts.

The design must keep execution stages explicit enough to reason about.

## 11. Cost inspection

Future compiler/runtime introspection might expose conceptual operations
such as:

    inspect function
    show IR
    show assembly
    show code size
    show stack usage
    show allocations
    show compilation-stage timings

Exact syntax is not decided.

## 12. Structured diagnostics

Compiler errors should have structural identity independently of rendered
prose.

Conceptually:

    {
      code,
      kind,
      span,
      expected,
      found,
      context
    }

Human and agent consumers can render the same semantic diagnostic
differently.

## 13. Effects

An effect system could make important behavior visible:

- allocation;
- file I/O;
- network I/O;
- process creation;
- MMIO;
- panic/throw-like behavior.

This is powerful but dangerous to language simplicity.

Treat effects as a long-term experiment, not an assumed requirement.

## 14. Capabilities

A possible modernization of HolyC's "the programmer owns the machine"
principle is:

> Everything may remain accessible, while authority can still be explicit.

Capabilities might express authority as values rather than as invisible
ambient permission.

Unsafe/raw authority must remain obtainable when explicitly requested.

## 15. Safety model

PolyC should not equate transparency with deliberately accepting every
class of memory error.

Possible long-term direction:

    ordinary checked/structured facilities
         +
    explicit unrestricted unsafe access

`unsafe` should mean:

> the programmer is programming the machine directly here

rather than:

> the programmer has done something morally wrong.

## 16. Garbage collection

Mandatory GC is currently disfavored for the core systems language because
it introduces hidden lifetime and runtime machinery.

Optional libraries/runtimes are a separate question.

## 17. Exceptions

Invisible non-local control flow is currently disfavored.

Structured error values and concise propagation should be explored first.

## 18. Object orientation

Useful concepts such as:

- structs/classes;
- methods;
- interfaces/traits where justified;

do not require access-control machinery whose main effect is preventing
inspection.

## 19. Functional-programming influence

PolyC does not aim to become Haskell or ML.

The useful FP question is:

> Does this mechanism make state, alternatives, invariants, or effects
> easier to represent and reason about?

Functional ideas are welcome when they reduce conceptual state.

## 20. Performance engineering influence

A systems language should make performance evidence cheap to obtain.

PolyC should eventually treat:

- compiler latency;
- generated-code quality;
- memory consumption;
- code size;
- JIT latency;

as normal engineering evidence attached to changes.

## 21. Native vs LLVM

The existing native backend should not be removed merely because LLVM
exists.

It serves several purposes:

- fast interactive reference;
- small comprehensible implementation;
- educational path;
- bootstrap possibility;
- differential oracle.

LLVM serves different purposes:

- mature optimization;
- broad target support;
- AArch64 quality;
- debug metadata;
- sanitizer/tool ecosystem;
- ORC;
- mature object/ABI machinery.

PolyC should measure the trade rather than choose ideologically.

## 22. Inline assembly

Inline assembly is target-specific by language design.

A portable backend may:

- support target-appropriate inline assembly;
- reject mismatched assembly explicitly;
- condition it on a target;
- introduce a future portable intrinsic alternative.

Do not pretend arbitrary assembly is backend-neutral.

## 23. Agent-native programming environment

A future persistent session might support structured operations such as:

    define(source)
    compile(symbol)
    call(symbol, args)
    inspect(symbol)
    replace(symbol, source)
    disassemble(symbol)
    test(symbol)

This protocol should manipulate the same live compiler state used by a
human REPL.

Agents are not assumed to need millisecond-level response in every case,
but PolyC should preserve low latency where it can do so without
architectural distortion.

## 24. Self-hosting

Original TempleOS/HolyC demonstrated that a HolyC-family language can host
its own compiler.

PolyC's portable C implementation temporarily loses that property.

Recovering self-hosting is therefore an evolution/recovery goal, not an
alien feature.

Self-hosting must follow semantic and architectural stability rather than
be used to justify premature complexity.
