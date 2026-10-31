# Selected core bundle contract

ACT: `ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01`
Bundle: `BUNDLE-OPERATOR-CORE-01`
Rank: `R0=1, R1=3, R2=1, R3=3, R4=1, R5=23, R6=BUNDLE-OPERATOR-CORE-01`

This is a future implementation contract. No production migration is
authorized or implemented here.

## Frozen source identity

| Site | Source range | Range SHA-256 | Production object | Caller |
|---|---|---|---|---|
| `SITE-COMPOUND-ASSIGN` | `src/prslib.c:1328..1348` | `4d941407ee054e207586b3a4fb645caf8917e6b43fa467b79d50a75e1b54bb43` | `build/CMakeFiles/hcc.dir/prslib.c.o` | `src/prslib.c:1480` (`parseExpr`) |
| `SITE-VALID-POINTER-OP` | `src/ast.c:974..990` | `bc06b0d757538f6c00ce0e96003cf5613823e98f4c48288c727cf9ac1dd82ac5` | `build/CMakeFiles/hcc.dir/ast.c.o` | `src/ast.c:1079` (`astGetResultType`) |
| `SITE-RANGE-OPERATOR` | `src/ast.c:2348..2358` | `8c1acadaa4f1ae26d27c6be491812db2d16a8dd18528cb5cf2cc81d242b24f99` | `build/CMakeFiles/hcc.dir/ast.c.o` | `src/ir.c:507,509`; `src/x86.c:1357,1359` |

The frozen source blobs are `a4746804976c4f5c85ac314e0dde031afccb4988`
(`src/prslib.c`) and `bddfa240800b12f0ad1d4740695aab75bfbac9d2`
(`src/ast.c`). The entry object digests are
`b8172eda93c7001d5df9029c1c6a66c5c1f8db9a12acf596d407d6439f5bca99`
and `64776d8ba33bb860e320cdcd9ac6550593592565221f24c1d8f3815e3e51ec8c`.

## Proposed ABI v1

The future subject owns only operator classification. It never sees raw
`Ast`, `Lexeme`, `Map`, `List`, `Cctrl`, or `Arena` layout.

```text
I64 AbiCoreClassifyCompoundAssign(I64 token_type, I64 token_value,
                                  I64 *out_operator);
I64 AbiCoreIsValidPointerOperator(I64 binary_operator);
I64 AbiCoreIsRangeOperator(I64 binary_operator);
```

Host operations and ownership:

- C copies `token_type` and `token_value` before the call.
- C owns `deconstructed_compound_op`; the subject writes it only on success.
- Positive operator values are source enum values; negative values are host
  status codes and are disjoint from operator values.
- The subject has no pointer parameter, no allocation, no callback, no
  `setjmp`, no `longjmp`, and no ownership transfer.
- All AST mutation, symbol tables, containers, arenas, recovery, diagnostics,
  and program allocation remain C-owned.
- Failure recovery is ordinary C control flow; no nonlocal recovery crosses
  the PolyC frame.

The exact status codes and source enum values must be frozen by the future
implementation ACT before any production mutation. A negative result must not
be confused with an operator value.

## G0 and fixture obligations

The genuine G0 is the unchanged C rule compiled with the selector OFF. Its
consumer objects must not import the future subject symbols.

Fixtures must include:

- all ten compound-assignment operators, ordinary `=`, non-punctuation, and
  invalid operator tokens;
- pointer add/subtract, pointer comparisons, pointer logical operators, and
  rejected pointer multiply;
- chained relational range expressions, equality chains, and mixed relational
  operators;
- positive, negative, boundary, and invalid-input cases;
- source-derived expected acceptance, AST, IR/object, and runtime behavior.

## Selector, producers, and rollback

- Selector: `HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY`.
- Stage0 OFF: stage0 compiles the unchanged C rule and does not link the
  subject.
- Production ON: the stage0 producer compiles the PolyC subject, whose object
  is an explicit prerequisite of the consumer object and link.
- G1, G2, and G3 are three distinct future producer executables and object
  digests. Their identities must not be backdated from this reconnaissance.
- Selector OFF rebuilds the unchanged C rule; verification requires zero
  subject imports, the active C comparison tables, and an independent G0
  oracle.

## Executed C mutation versus future PolyC mutation

`CSCR01-M1` is an executed **C-authority** mutation from this reconnaissance.
It changed only the `TK_ADD_EQU` mapping in `src/prslib.c:1334`, rebuilt the
real production compiler, linked the changed `prslib.c.o`, and changed a
compiled program's result from 30 to 246. The restored source and object
hashes returned exactly to pristine.

Future G1/G2/G3 PolyC-source mutations are distinct experiments after a
separately authorized authority transfer. They must not be represented by,
backdated to, or counted as `CSCR01-M1`.

## Negative controls required by the successor

The implementation ACT must include, at minimum:

1. selector OFF versus ON byte-identical fixtures;
2. G0/G1/G2/G3 agreement;
3. mutation of each of the three operators;
4. stale-object and missing-prerequisite controls;
5. wrong-status/negative-value ambiguity controls;
6. raw-layout handle rejection;
7. callback and cross-frame recovery rejection;
8. restoration of source, object, and witness hashes;
9. production authority count conserved at 10 until the authorized transfer;
10. prospective graph effects reported without claiming a cut.

## Graph and self-hosting caveat

The production graph remains 52 nodes, 134 mandatory edges, one proven cut
(`E-TYP-0136`), 34 SCCs, and largest SCC 19. This bundle can prospectively
replace scalar operator decisions, but it does not by itself retire a typed
layout, mutable-state, callback, or recovery edge. No SCC reduction, M1/M2
milestone, authority retirement, or self-hosting claim is made.
