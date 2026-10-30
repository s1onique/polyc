# C1 — token saturation and signed-result plan

## 1. Generation wrap (AI-15, AC22) — fail closed, not wrap

v1 wrapped: `if (generation == 0) generation = 1;`. With a 16-bit counter a slot
issues at most 65,535 distinct identities before a value repeats, so a
sufficiently old token can alias a fresh live one. v1.1 replaces the wrap with
permanent retirement:

```c
/* Register() */
if ((u32)s->generation + 1u > 0xffffu) {           /* would wrap */
    s->retired = 1; s->live = 0; s->obj = NULL;
    return -ABI_SLOT_RETIRED;
}
/* AbiRelease() */
if ((u32)s->generation + 1u > 0xffffu) s->retired = 1;   /* never re-issue */
else                                  s->generation++;
```

A retired slot is skipped by `Register()` and rejected by `Lookup()` with
`-17 ABI_SLOT_RETIRED`. **No aliasing token can exist.**

### 1.1 The accelerated proof (bounded, but exercises the REAL transition code)

65,536 full compiler rebuilds would be wasteful, so the C1/C2 measurement uses a
fixture-only hook `AbiHostSetGeneration(handle, gen)` that writes the slot's
generation counter and then drives the *unmodified* `Register()` / `AbiRelease()`
transition. The executed sequence is:

```text
t1 = Register(ast)                 generation 1
Release(t1)                        generation 2
AbiHostSetGeneration(t1, 0xFFFE)   near-wrap setup (fixture hook only)
t2 = Register(ast)                 generation 0xFFFF  -> t2 issued
Release(t2)                        next increment would wrap -> slot RETIRED
ShouldPrint(t2)                    -17 SLOT_RETIRED
t3 = Register(ast)                 a DIFFERENT slot: t3 != t1 and t3 != t2
```

Measured in `c0/red-probe-raw.txt` (`CONTROL=C0-WRAP ... REPLAY=-17 ...
ALIASED=0`). The real detector is the slot table state machine, not a stub.

**Honest limit:** the accelerated hook shortens the *setup*; it does not replace
the transition logic. A full 65,536-issue sweep is therefore not claimed as
executed. The claim made is narrower and true: *the increment is refused rather
than wrapped, on the real code path.*

## 2. Capacity and domain exhaustion (AI-16, AC22)

```text
slot table     bounded.  The C0 probe uses 4 slots, the shadow host uses 64.
               Exhaustion returns -15 ABI_OUT_OF_MEMORY.  Measured:
               CONTROL=C0-CAPACITY SLOTS=4 ... EXPECTED=-15 ACTUAL=-15
domain         1-byte domain id, validated on every lookup.  A token from
               another domain returns -6 ABI_HANDLE_DOMAIN_MISMATCH.  Measured:
               CONTROL=C0-DOMAIN EXPECTED=-6 ACTUAL=-6
```

**No claim of arbitrary capacity.** The documented population is 64 slots ×
65,535 generations × 255 domains, and only the bounded probes above are proved.

## 3. Signed data versus error status (AI-17, AC23)

The selected operation never carries a signed payload:

```text
AbiCpaAstKind        values 256..299   vs statuses -17..-1   DISJOINT
AbiCpaShouldPrintAst values 0,1        vs statuses -17..-1   DISJOINT
```

Measured: `CONTROL=C0-SIGNED ... ERROR=-5 DECISION=0 DISJOINT=1`.

**Why this ACT does not put a list payload across the boundary.** RECON01's
`AbiListAt` returns `(I64)value` or a negative status, which is genuinely
ambiguous for a signed payload: a list holding `-3` is indistinguishable from a
status. This ACT therefore does not use `AbiListAt` in the shadow consumer at
all. The status/value split for signed payloads is left as an explicit
`v1.2`-or-later problem, documented rather than papered over.

## 4. A measured trap that PolyC must respect

The handle encoding puts `0xC0DE` in bits 48..63, so **every valid token is a
negative `I64`**:

```text
PRISTINE kind=266 token=-4549197469790961318 polyc=1 oracle=1 MATCH
```

Consequence (frozen constraint for the shadow subject and every future ABI
consumer): **a handle must never be tested with `< 0`, and must never be
compared with a status value.** Handles are opaque bit patterns; only the host
interprets them. The C0 probe respects this (it passes tokens through and never
inspects their sign), and the shadow PolyC subject does the same.

## 5. Recovery (AI-19, AC25)

No `setjmp`/`longjmp` surface exists in the ABI. The C0 probe binary contains
neither symbol (`SETJMP_LONGJMP_IN_BINARY PRESENT=NO`) and C2 re-checks the
shadow compiler. `Cctrl` recovery remains `BLOCKED`. The control proves a real
fail-closed *absence* at the public boundary rather than mocking success: there
is no function through which a nonlocal jump could be requested.
