# The Selected Successor Contract — Production Seam

**ACT:** ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
**Selected candidate:** `SUB-004`

---

## 1. The seam, in one picture

```
                    C side (host ownership)                | PolyC side
  --------------------------------------------------------|----------------
  cctrlTokenGet(cc) -> tok (Lexeme *)                      |
  tok == NULL ? raise : continue                          |
  tok->tk_type == TK_KEYWORD ?  ---- the GUARD stays on C -|
        |                                                     |
        |  tok->tk_type (I64)  ------------------------------>| BootstrapStatementDispatch
        |  tok->i64      (I64)  ------------------------------>|   (pure scalar classifier)
        |                                                     |
        |  selector (I64) <-----------------------------------|
        |                                                     |
  switch (selector) {                                       |
      STMT_IF  -> parseIfStatement(cc)   }                  |
      STMT_FOR -> parseForStatement(cc)  }  ALL ON THE C SIDE
      ... 12 arms ...                                        |
  }                                                         |
  each constructor builds its own Ast, drives the token      |
  cursor, owns the recovery state, raises the diagnostics   |
```

**The seam is a value crossing.** Two bounded integers go out; one
bounded integer comes back. No pointer, no callback, no handle, no
ownership transfer.

---

## 2. The production call path

The decision is reached from the production parse entry point:

```
parseToAst
  -> parseToplevelDef
     -> parseFunctionDef
        -> parseCompoundStatement
           -> parseCompoundStatementInternal
              -> parseStatement              <-- the decision site
                 -> cctrlTokenGet(cc)
                 -> if (tok->tk_type == TK_KEYWORD)
                    switch (tok->i64)         <-- SUB-004
```

The decision is NOT an oracle wrapper, NOT a fixture helper, NOT
dead code, and NOT already delegated to PolyC. It is the live
production dispatch, and it is compiled INTO the production
`hcc` binary: the function-scoped relocation table of
`build/CMakeFiles/hcc.dir/parser.c.o` places a `BR26` relocation to
each of the twelve constructors inside `_parseStatement`.

---

## 3. The exact production linkage policy for the future ACT

| Item | Requirement |
|---|---|
| Selector | `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH`, default **OFF** |
| Subject | `tools/bootstrap/selfhost-parser-statement-dispatch.HC` |
| Subject object | a new object linked into the `hcc` target |
| Selector-OFF object | the legacy switch body, reachable only in the selector-OFF build; it must import NO PolyC successor symbol |
| Selector-ON object | the production object; it MUST import the successor symbol and MUST NOT retain the legacy comparison chain |
| Legacy oracle | `ParserLegacyStatementDispatchOracle`, a pass-through adapter whose body is a single branch to the PolyC symbol, exactly like the three existing legacy oracles |
| Fail-closed | when the selector is ON, the C side must NOT evaluate the legacy switch and MUST NOT fall back to it |
| Python | the successor is PolyC; no Python may be introduced |

---

## 4. What stays exactly where it is

| Concern | Owner |
|---|---|
| `Lexeme *tok` | C |
| the token cursor advance | C |
| the `Cctrl *` and `cc->symbol_table` | C |
| the twelve statement constructors | C |
| every `Ast` node allocation | C |
| `cc->current_recovery` and `setjmp` | C |
| every diagnostic message | C |
| `cc->localenv` scoping | C |
| the `KW_*` / `TK_*` enum values | C (passed by value) |

---

## 5. The evidence that this seam is the real decision

| Claim | Evidence |
|---|---|
| the decision is in the production binary | the `BR26` relocations inside `_parseStatement` in `build/CMakeFiles/hcc.dir/parser.c.o` |
| the decision is function-scoped | the relocation addresses fall inside `_parseStatement`'s own range (`0x1af0..0x3568`) |
| the decision is causally load-bearing | the real-compiler mutant experiment in `candidate-causal-build-and-witness.tsv` |
| the mutation was really linked | the mutant object's `_parseStatement` has NO relocation to `_parseIfStatement` and its `_parseWhileStatement` relocation moved to the `KW_IF` arm's slot |
| the mutation was restored | the rebuilt compiler and object are byte-identical to the pristine ones, and the restored compiler reproduces the pristine diagnostic text |
