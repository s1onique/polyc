# Semantic witness programme

ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 — C1 EVIDENCE.

Each selected site has a REAL COMPILED-PROGRAM witness, not merely a
fixture value. A fixture proves the classifier agrees; a compiled-program
witness proves the transferred authority is actually load-bearing in the
production compiler.

Every baseline value below was MEASURED at the entry with the current
production compiler. They are baselines, not predictions.

## SITE-COMPOUND-ASSIGN

**Decision:** is the current token a compound assignment, and which
operator does it desugar to?

**Witness (W-CA):** the predecessor's executed witness program
`evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/c2/probes/compound-assign-witness.HC`:

```polyc
I64 Main() {
  I64 x = 10;
  x += 20;
  return x;
}
```

- MEASURED PRISTINE EXIT = **30**
- MEASURED under the predecessor's executed C mutation `CSCR01-M1` = **246**
- MEASURED after restore = **30**

The successor MUST reuse this program as its pristine baseline and MUST
NOT represent it as a new PolyC mutation. The C mutation `CSCR01-M1` is
HISTORICAL C-side evidence; the successor's `M-POLYC-CA` is a distinct
experiment on the PolyC source.

**Channel:** the runtime exit status (the returned value) of the compiled
program. A PolyC mutation of the `TK_ADD_EQU` mapping changes the
operator the C side desugars to, which changes the returned value.

**Negative companion:** a program using a plain `=` (which the C side
handles on a different path) must be unchanged by the mutation, proving
the mutation is site-specific rather than a blanket breakage.

## SITE-VALID-POINTER-OP

**Decision:** is the binary operator valid for pointer arithmetic?

**Witness (W-PO), positive:** a pointer comparison.

```polyc
I64 Main() {
  I64 x = 1; I64 y = 2;
  I64 *p = &x; I64 *q = &y;
  if (p < q) { return 1; }
  return 0;
}
```

- MEASURED: COMPILES, RUNS, EXIT = **0**

**Witness (W-PO), negative:** a rejected pointer operation (pointer
multiply).

```polyc
I64 Main() {
  I64 x = 1; I64 y = 2;
  I64 *p = &x; I64 *q = &y;
  I64 *r = p * q;
  return 0;
}
```

- MEASURED: COMPILER REJECTS with
  ``error: The `*` operator cannot be applied to a pointer type ``
  and a nonzero compiler status. The program is never produced.

**Why this is observable from a compiled program:** the decision selects
whether `astGetResultType` (src/ast.c:1079) takes its `goto error`
path. The error path produces the type diagnostic above; the accepted
path produces a runnable program. The two are distinguishable by the
compiler's exit status and by the diagnostic text.

**Channel:** compiler acceptance / rejection and the emitted diagnostic,
plus the runtime result of the accepted program.

## SITE-RANGE-OPERATOR

**Decision:** is the binary operator one of the four relational range
operators (LT, LE, GT, GE)?

**Witness (W-RO), positive:** a chained relational range expression
`a < b < c`.

```polyc
I64 Main() {
  I64 a = 1; I64 b = 2; I64 c = 3;
  if (a < b < c) { return 1; }
  return 0;
}
```

- MEASURED: COMPILES, RUNS, EXIT = **1**

**Witness (W-RO), negative companion:** a chained NON-range operator.

```polyc
I64 Main() {
  I64 a = 1; I64 b = 1; I64 c = 1;
  if (a == b == c) { return 1; }
  return 0;
}
```

- MEASURED: COMPILES, RUNS, EXIT = **1** (and it does NOT take the range
  lowering path)

**Why this is observable:** the C comment at src/ir.c:503-506 and the
code at src/ir.c:507-509 and src/x86.c:1357-1359 show the consequence
exactly: a chained range comparison is lowered as the short-circuit AND
`(a OP1 b) && (b OP2 c)` instead of the default binary lowering. The
decision therefore selects a different IR and native-code path, which is
observable in the emitted code and in the runtime result.

**Channel:** the runtime result of the chained comparison and the emitted
native code path.

## Generation matrix

Each witness is executed against ALL FOUR generations (G0 C-only oracle,
G1, G2, G3 PolyC subjects) and the outputs must be equal.

## Anti-requirements

- A compile failure is NOT a semantic difference (NC-21).
- A fixture-only equality is NOT a production authority (ACT 0.1).
- A linked-but-uncalled subject is NOT a production authority (NC-16).
