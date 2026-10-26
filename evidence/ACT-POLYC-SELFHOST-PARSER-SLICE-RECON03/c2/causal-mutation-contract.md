# Production-causal mutation contract — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Selected target:** `parseGetPriority` (`src/prslib.c:1139..1207`)
**Component:** `BootstrapOperatorPrecedence` (PolyC)

**The mutation described here is EMPIRICALLY VERIFIED, not merely
proposed.**  RECON03 built a mutant compiler from a throwaway copy of
the source tree and observed the divergence in a compiled program's
output.  The transcript is in `causal-mutation-verification.txt`.

---

## 1. The frozen mutation

```text
MUTATION_LOCATION
  = the precedence-4 arm of the PolyC component.
    PRISTINE:
        case '*': case '/': case '%':
            return 4;
    MUTATED:
        case '*':
            return 6;
        case '/': case '%':
            return 4;

    ONLY '*' (0x2A) changes.  '/' and '%' keep precedence 4, so the
    mutation is bounded to ONE operator.

MUTATION_KIND
  = SEMANTIC_CONSTANT_CHANGE (a precedence class is moved)

EXPECTED_AFFECTED_FIXTURE
  = the P4 fixture row for '*' (0x2A); its expected precedence changes
    from 4 to 6.

EXPECTED_PRODUCTION_OBSERVABLE
  = the grouping of a mixed-precedence expression changes.

    PRISTINE:  '*' binds tighter than '+', so `a * b + c` groups as
               ((a * b) + c).
    MUTATED:   '*' binds LOOSER than '+', so `a * b + c` groups as
               (a * (b + c)).

EXPECTED_PRISTINE_RESULT
  = the compiled program prints 62   (with a=6, b=7, c=20: 42 + 20)

EXPECTED_MUTATED_RESULT
  = the compiled program prints 162  (with a=6, b=7, c=20: 6 * 27)
```

The two results are different, so the mutation is PRODUCTION-CAUSAL:
the semantic decision crossed into the component and the compiled
program changed.

---

## 2. Why precedence 6 and not precedence 5

This is not an arbitrary choice.  The mutation was DERIVED from the
actual `parseExpr` recursion, and the derivation is falsifiable.

`parseExpr(prec)` loops; for each punct token it computes
`prec2 = parseGetPriority(tok)` and stops when
`prec2 < 0 || prec <= prec2` (`src/prslib.c:1364`).  Otherwise it
recurses with `next_prec = prec2` (`:1430`).

For `a * b + c` with the outer call at `prec = 16`:

```text
  '*' at precedence P
    outer: 16 <= P ?  no  -> recurse with next_prec = P
      inner parseExpr(P): reads '+' (precedence 5)
        P <= 5 ?  stop  -> RHS = b   -> LHS = (a * b)
        P > 5 ?  continue -> RHS = (b + c) -> LHS = a * (b + c)
    outer continues: reads '+' (precedence 5)
      16 <= 5 ? no -> recurse with next_prec = 5
        inner parseExpr(5): reads EOF -> RHS = c
      LHS = (a * b) + c        [when the inner call stopped]
      LHS = a * (b + c)       [when the inner call consumed the '+']
```

So the grouping flips exactly when `P > 5`.  Moving '*' from 4 to **5**
does NOT flip the grouping (`5 <= 5` still stops); moving it to **6**
does (`6 > 5` continues).  The mutation is therefore the MINIMAL
single-operator change that produces a grouping difference, and it is
derived from the source rather than guessed.

---

## 3. The mutation requirements

```text
The mutation MUST remain SYNTACTICALLY VALID.
The mutation MUST LINK SUCCESSFULLY.
The mutation MUST NOT change the ABI shape.
The mutation MUST NOT change the input domain.
```

A failed build or a missing output is **NOT** semantic divergence.  If
the mutated build fails to link, the mutation is rejected and a
different one must be chosen; it must not be reported as a
"successful" divergence.

---

## 4. The required execution sequence

```text
pristine component -> build -> link -> execute -> capture output A
mutated component  -> build -> link -> execute -> capture output B
assert A != B
restore pristine  -> build -> link -> execute -> capture output C
assert C == A
```

The restore-and-reverify step is mandatory: without it, a mutant that
merely fails to produce output would be indistinguishable from a
semantic divergence.

---

## 5. The observation channel

The observation MUST be the OUTPUT OF A COMPILED PROGRAM, not an
internal AST dump and not a shadow verifier.  The canonical observation
is a small PolyC program whose printed value depends on the grouping of
a mixed-precedence expression:

```c
#include "tos.HH"
I64 main() {
  I64 a = 6; I64 b = 7; I64 c = 20;
  I64 r = a * b + c;
  printf("%d\n", r);
  return 0;
}
```

The successor MUST record, for the mutated run and the restored run:

```text
the exact source of the observation program
the compile command
the executable's output
the SHA-256 of the output
```

---

## 6. The observation is guaranteed to be reachable

The precedence value is consumed in `parseExpr` at
`src/prslib.c:1364`, `:1430` and `:1431`, and therefore determines the
RECURSION STRUCTURE of the expression parser, which determines the
AST.  `parseExpr` is reached from 32 production call sites across
`src/parser.c`, `src/prslib.c` and `src/lexer.c`, so the mutation is
observable in essentially every compiled program that contains an
arithmetic expression.  The mutation is not a shadow mutation: it
changes the AST that the code generator consumes.
