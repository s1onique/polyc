# PolyC Vision

PolyC is an experimental descendant of HolyC.

It began as a fork of James Barford's portable HolyC implementation and
exists to explore what HolyC's core ideas might become on modern machines
without treating either ISO C compatibility or historical TempleOS
constraints as sacred.

PolyC is named in part for Saint Petersburg Polytechnic University.

## Why PolyC exists

HolyC demonstrated an unusually coherent systems-programming model:

- the programming language, command language, and live execution
  environment can be one thing;
- compilation can be fast enough to feel immediate;
- programmers can inspect and manipulate the machinery directly;
- the implementation can remain understandable enough for one determined
  engineer to traverse;
- compatibility may be broken when evolution genuinely simplifies the
  system.

PolyC does not aim to recreate TempleOS.

It asks instead:

> What does that philosophy look like on modern architectures,
> with modern compiler infrastructure, functional-programming lessons,
> performance engineering, observability, and agent programmers?

## Preserve principles, not accidents

PolyC distinguishes design principles from historical constraints.

Potentially enduring principles include:

- simplicity;
- immediacy;
- comprehensibility;
- direct machine access;
- small conceptual and dependency surface;
- visible cost;
- self-hosting;
- one coherent programming environment.

Historical choices such as one CPU architecture, one OS environment,
ring-0 execution, a particular display mode, or a particular native
backend are not automatically project doctrine.

Systems must evolve.

## Humans and agents

HolyC's original loop was approximately:

    inspect -> modify -> execute -> observe

An agent's programming loop is strikingly similar:

    generate -> execute -> observe -> modify

PolyC therefore treats the live compiler/runtime not merely as a human
REPL but potentially as a persistent programmable compilation session.

A future PolyC environment may expose the same underlying session through:

- a human REPL;
- a structured agent protocol;
- an embedded API.

The agent interface should remain deterministic and explicit rather than
embedding an LLM inside the compiler.

## Multiple execution strategies

PolyC intends to preserve the inherited lightweight native compiler while
experimenting with LLVM as an additional backend.

Conceptually:

                    PolyC source
                         |
                  semantic frontend
                         |
                  backend-neutral IR
                    /           \
                   /             \
          small native backend    LLVM
             JIT / AOT         JIT / AOT

The native implementation provides immediacy, comprehensibility, and a
performance control group.

LLVM provides mature optimization, ABI handling, debug information,
portable target support, and excellent AArch64 code generation.

Neither backend is assumed to be permanently mandatory.

## Long-horizon destination

PolyC should eventually be capable of compiling itself.

Self-hosting is not an early milestone and must not distort architecture
to arrive sooner.

A plausible destination is:

    small trusted bootstrap seed
             |
             v
      PolyC compiler
      written in PolyC
             |
             v
       recompiles itself
             |
             v
      reproducible closure

LLVM may remain an external backend dependency while the PolyC compiler
itself becomes self-hosted.

The long-horizon trust goal is not merely self-hosting but a small,
auditable bootstrap path.

## Heritage

PolyC is derived from HolyC and began as a fork of
James Barford's `holyc-lang`.

The project intends to preserve attribution and licensing requirements
while deliberately evolving the language and compiler architecture.
