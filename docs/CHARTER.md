# PolyC Charter

This document contains design laws, not a frozen language specification.

Features and architectural changes should be judged against these
principles.

## P1. Comprehensibility over generality

The important parts of PolyC should remain traversable by a determined
engineer.

Generality has no intrinsic value if it makes the implementation harder to
understand.

## P2. Minimize conceptual count

Line count is useful but insufficient.

PolyC should also minimize:

- independent concepts;
- hidden invariants;
- implicit states;
- special cases;
- interacting mechanisms.

A larger implementation with fewer concepts can be simpler than a
smaller implementation full of exceptions.

## P3. Immediate execution matters

The edit/compile/execute loop should remain fast enough to feel direct.

The inherited native JIT is a performance reference, not an obsolete
implementation to delete.

## P4. Prefer one language over tool-language proliferation

Where practical, PolyC itself should eventually serve for:

- application code;
- systems code;
- scripting;
- build-time computation;
- metaprogramming;
- automation.

A separate DSL must justify itself.

## P5. The programmer owns the machine

PolyC must not make low-level machine access impossible merely to enforce
a safety ideology.

Unsafe operations may be explicit.

They must remain available.

## P6. Nothing important should be unnecessarily hidden

If the compiler performs important transformations or incurs important
cost, those mechanisms should have cheap inspection surfaces.

Possible future examples:

    #ir Foo
    #asm Foo
    #why Foo
    #memory Foo
    #effects Foo

Exact syntax is not chartered.

The principle is.

## P7. Performance is correctness-adjacent

Compiler performance and generated-program performance are design inputs,
not afterthoughts.

Language/compiler changes should eventually carry evidence about:

- compilation latency;
- execution latency;
- memory use;
- generated code;
- regression against meaningful baselines.

Do not optimize folklore.

Measure.

## P8. Compatibility is subordinate to evolution

PolyC begins from HolyC semantics but is not obliged to preserve every
historical decision indefinitely.

Compatibility may be broken when doing so demonstrably removes mistakes,
reduces complexity, improves semantics, or enables important evolution.

Breakage must be intentional, documented, and tested.

## P9. Abstraction must compress complexity

Abstraction is valuable when it removes invariants or repeated reasoning.

It is not valuable merely because it is fashionable.

A good abstraction should make the system smaller in the programmer's
head.

## P10. No speculative machinery

Do not add extension points, frameworks, generic interfaces, or future
hooks until a concrete requirement exists.

Build the narrow mechanism required now.

Refactor when evidence demands it.

## P11. Keep a small trusted core

PolyC's core should retain a deliberately constrained dependency and
conceptual closure.

Applications may have dependencies.

The compiler and core environment should not require an ecosystem-sized
dependency graph merely to function.

## P12. Source is authority

The system's important semantics should live in inspectable source.

PolyC's long-horizon direction includes:

- self-hosting;
- reproducible bootstrap;
- a small auditable stage-0 path.

## P13. Errors should be values where practical

Error state should be explicit, inspectable, and structurally
representable rather than existing only as prose or invisible control
flow.

Human-readable diagnostics and machine-readable diagnostics should be
different presentations of the same semantic error.

## P14. Cost should be observable

Allocation, compilation, code generation, specialization, JIT work, and
other meaningful costs should eventually be queryable rather than hidden.

Observability is part of systems design.

## P15. Systems must evolve

The principles are more durable than the mechanisms implementing them.

PolyC should continuously be allowed to replace:

- IRs;
- backends;
- runtimes;
- APIs;
- syntax;
- memory disciplines;

when a better design is demonstrated.

Respecting the past must not become architectural paralysis.

## Working interpretation

A useful reconciliation of HolyC, functional programming, and
infrastructure engineering is:

    FP:
        make state and effects explicit

    SRE:
        make state and effects observable

    HolyC:
        do not hide the machine

PolyC should explore the intersection.
