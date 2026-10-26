# Successor production seam — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Selected target:** `parseGetPriority` (`src/prslib.c:1139..1207`)

---

## 1. The seam

The seam is a single ordinary direct call.  There is no callback
contract, no diagnostic seam and no recovery seam.

```text
src/prslib.c:1363     prec2 = parseGetPriority(tok);
```

`parseGetPriority` is `static` in `src/prslib.c`, so the successor must
expose it through a thin, non-static C adapter in the SAME translation
unit, in the same shape the two existing parser migrations use
(`src/parser.c:476` `ParserLegacyCalcPaddingOracle`, and the
`parseValidPostControlFlowToken` adapter at `src/parser.c:861`).

The adapter is the only new C code, and it adds no logic.

---

## 2. The production call graph

```text
production caller (32 call sites of parseExpr)
    -> parseExpr                         src/prslib.c:1343
        -> parseGetPriority              src/prslib.c:1363   <== THE SEAM
            -> prec2
                -> next_prec             src/prslib.c:1430
                -> next_prec++ for '='   src/prslib.c:1431
                    -> parseExpr(cc,next_prec)  src/prslib.c:1435
                        -> THE AST SHAPE OF EVERY BINARY AND UNARY
                           EXPRESSION IN EVERY COMPILED PROGRAM
```

The `parseExpr` call sites, by file:

```text
src/lexer.c:2202   macro preprocessor: #if expression
src/lexer.c:2362   macro preprocessor: #elif expression
src/parser.c:203   array-declaration initialiser
src/parser.c:759   variable initialiser
src/parser.c:937   if-clause initialiser
src/parser.c:947   if-clause condition
src/parser.c:1039  optional expression
src/parser.c:1143  range-loop container
src/parser.c:1288  for-statement step
src/parser.c:1323  while-statement condition
src/parser.c:1379  do-while-statement condition
src/parser.c:1407  return-statement value
src/parser.c:1466  throw-statement value
src/parser.c:1500  case-label expression
src/parser.c:1518  case-label expression
src/parser.c:1613  switch-statement condition
src/parser.c:1818  statement expression
src/parser.c:2709  toplevel initialiser
src/parser.c:2732  toplevel initialiser
src/parser.c:2756  toplevel initialiser
src/parser.c:2765  toplevel initialiser
src/parser.c:2777  toplevel initialiser
src/prslib.c:117   default function parameter
src/prslib.c:329   array dimension
src/prslib.c:664   function argument
src/prslib.c:1210  subscript expression
src/prslib.c:1435  parseExpr RECURSION (the right-hand side)
src/prslib.c:1691  parenthesised expression
src/prslib.c:1717  unary operand
```

---

## 3. What stays C-owned

```text
The token stream and the Cctrl        (unchanged)
The error reporting and diagnostics   (unchanged; the component never
                                       raises and never aborts)
The recovery point                    (unchanged; the component owns
                                       no setjmp and cannot longjmp)
parseExpr and the AST construction    (unchanged)
The -1 sentinel handling in parseExpr (unchanged)
```

---

## 4. The delegation flag

The successor MUST use a DEDICATED flag, following the shape of the two
existing parser migrations
(`HCC_USE_SELFHOST_PARSER_PADDING`, `HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN`):

```text
HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE
```

A dedicated flag is required rather than the generic
`HCC_USE_SELFHOST_COMPONENTS` selector, because the generic selector
also activates the LEXER delegations in `src/lexer.c`, which would
require linking the lexer subjects as well.  The operator-precedence
migration is independent of the lexer migrations.

The flag MUST default to ON in the production `hcc` build, exactly as
both existing parser flags do, and the legacy body MUST live in the
`#else` branch so that it is NOT COMPILED into the production object.
This is the same fail-closed shape that
`build/CMakeFiles/hcc.dir/parser.c.o` demonstrates today: the production
object carries `U _BootstrapCalcPadding` and
`U _BootstrapValidPostControlFlowToken` as UNDEFINED symbols, proving
the legacy algorithm bodies are not in the production binary.

---

## 5. The causal proof obligation

Because the precedence value decides the AST shape of every expression,
a bounded mutation of the PolyC component is guaranteed to be
observable in a compiled program.  The successor MUST demonstrate:

```text
pristine component -> build/link -> execute  -> reference output
mutated component  -> build/link -> execute  -> divergent output
restore pristine                          -> reference output again
```

The mutation must be syntactically valid and must LINK SUCCESSFULLY.
A failed build or a missing output is NOT semantic divergence.

The canonical mutation is to change ONE precedence class (for example
to move `'*'` from precedence 4 to precedence 5).  That changes the
grouping of `a * b + c` from `((a*b)+c)` to `(a*(b+c))`, which is
observable in the compiled program.

---

## 6. The real legacy-C oracle

The oracle MUST be the REAL legacy C function, or an actual linked
legacy implementation exported through a narrow test seam.  Because
`parseGetPriority` is `static`, the oracle seam is a thin non-static
adapter in `src/prslib.c` that calls the real function — the same
adapter strategy that `src/parser.c:476`
`ParserLegacyCalcPaddingOracle` uses for `CalcPadding`.

A handwritten reimplementation of the precedence table is NOT an
acceptable sole oracle.
