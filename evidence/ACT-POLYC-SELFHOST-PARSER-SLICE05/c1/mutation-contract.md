# ACT-POLYC-SELFHOST-PARSER-SLICE05 -- C1 MUTATION CONTRACT

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** mutation-contract

## 1. The frozen mutation

```text
Token '-' maps to AST_UN_OP_PLUS
instead of AST_UN_OP_MINUS.
```

In the PolyC component, the single line

```text
  if (token_value == 45)  return 5;   // '-'  -> AST_UN_OP_MINUS
```

becomes

```text
  if (token_value == 45)  return 4;   // '-'  -> AST_UN_OP_PLUS
```

The token value `45` is `'-'`, the compiled `src/lexer.h` value.  The
enum values `4` and `5` are the compiled `src/ast.h` values of
`AST_UN_OP_PLUS` and `AST_UN_OP_MINUS`.

**Exactly ONE line changes.**  Nothing else in the component changes.

## 2. Why this mutation is causally observable

A nonzero operand exposes the difference:

```text
-x   with AST_UN_OP_MINUS   ->  -7
-x   with AST_UN_OP_PLUS    ->  +7
```

The observation is a **real PolyC program** compiled by the **real
compiler**, not a direct call to the mapping function.

## 3. The frozen observation program

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/unary-observation.HC
```

```c
I32 Main(I32 argc, U8 **argv)
{
  I64 x = 7;
  I64 y = -x;
  "UNARY_MINUS_RESULT=%lld\n", y;
  I64 z = +x;
  "UNARY_PLUS_RESULT=%lld\n", z;
  I64 n = !x;
  "UNARY_LOG_NOT_RESULT=%lld\n", n;
  I64 b = ~x;
  "UNARY_BIT_NOT_RESULT=%lld\n", b;
  return 0;
}
```

## 4. The frozen observation channel

**stdout**, as plain decimal numbers.

The observation does **NOT** rely on a process exit code: an exit
status truncates a negative value on many hosts, and the mutation's
whole point is to turn a NEGATIVE observation into a POSITIVE one.

## 5. The frozen pristine output

```text
UNARY_MINUS_RESULT=-7
UNARY_PLUS_RESULT=7
UNARY_LOG_NOT_RESULT=0
UNARY_BIT_NOT_RESULT=-8
```

This was **measured** on the entry-tree compiler at C1, before any
implementation existed:

```text
COMMAND=<hcc> --install-dir=<prefix> \
          evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/unary-observation.HC \
          -o <out>
COMMAND=./<out>
```

## 6. The frozen mutated output

```text
UNARY_MINUS_RESULT=7
UNARY_PLUS_RESULT=7
UNARY_LOG_NOT_RESULT=0
UNARY_BIT_NOT_RESULT=-8
```

Only the FIRST line differs.  The mutation is **specific**: it changes
the '-' classification and nothing else.  The other three lines being
unchanged is itself evidence that the mutation is a targeted change to
one classification rather than a blanket corruption of the unary path.

## 7. The frozen A / B / C sequence

```text
A. pristine production compiler
B. production compiler linked with mutated unary subject
C. restored pristine production compiler
```

Required:

```text
A_BUILD_RC=0
A_EXEC_RC=0

B_BUILD_RC=0
B_EXEC_RC=0
B_OUTPUT_DIFFERS_FROM_A=YES

C_BUILD_RC=0
C_EXEC_RC=0
C_OUTPUT_EQUALS_A=YES

C_SUBJECT_SHA_EQUALS_A=YES
```

## 8. The scratch-copy rule

**The tracked component file MUST NOT be mutated.**  The mutation is
applied to a **scratch copy** of
`tools/bootstrap/selfhost-parser-slice05.HC` in the build directory,
and the production compiler for phase B is configured to use that
scratch copy as its unary subject.

The tracked file's SHA is recorded before and after the sequence and
MUST be identical.

The compiler executable's SHA and the component object's SHA are
tracked for A, B, and C:

* **A** and **C** MUST have the SAME subject SHA (the restored
  pristine subject);
* **B** MUST have a DIFFERENT subject SHA (the mutated subject);
* the compiler executable SHAs of A and C MUST be identical (same
  source, same flags, same toolchain);
* the compiler executable SHA of B MAY differ, because the mutated
  subject is a different object; that difference is not itself the
  proof -- the OUTPUT difference is.

## 9. What the sequence proves

* If the production compiler's unary classification were NOT
  load-bearing, phase B would produce the SAME output as phase A, and
  `B_OUTPUT_DIFFERS_FROM_A` would be `NO`.  The sequence therefore
  PROVES that the production path actually consults the PolyC
  component.
* If the restoration were not faithful, phase C would differ from
  phase A.  `C_OUTPUT_EQUALS_A=YES` and `C_SUBJECT_SHA_EQUALS_A=YES`
  therefore PROVE that the production state was restored exactly.

## 10. The expected host-specific nondeterminism

**None is expected for this observation.**  The program performs only
integer arithmetic and writes four fixed-format lines.  There is no
address, no timestamp, no hash-order iteration, and no filesystem
access in the observed output.

If any nondeterminism were observed, it would have to be **identified
at C1**, not silently normalised at C3.  This contract records that
none is expected, so any observed difference is a real difference.
