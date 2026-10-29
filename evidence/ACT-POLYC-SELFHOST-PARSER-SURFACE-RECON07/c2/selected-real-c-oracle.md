# SELECTED REAL C ORACLE

## THE G0 ORACLE

```text
G0_OBJECT=build/g0/parser-legacy.o   (in the disposable worktree)
G0_OBJECT_SHA256=8737313a547f20b507f4841af4056b3e9c1a51850076e01c121e5c7f3126959c
G0_PRODUCER=cc -std=c99 -O2 -Isrc -c -o build/g0/parser-legacy.o src/parser.c
G0_COMPILE_EXIT=0
G0_ORACLE_SYMBOL=_ParserLegacyDefaultArmTerminatesOracle
G0_POLYC_REFERENCES=0
G0_DEFINES_MAIN=0
```

The G0 oracle is the **REAL production C translation unit**
(`src/parser.c`) compiled with the decision factored out, exactly as
the seven already-migrated authorities are. It is NOT a hand-written
re-implementation and it does NOT depend on any PolyC component.

## THE PROVENANCE PROOF

```text
COMMAND=nm build/g0/parser-legacy.o | grep -c Bootstrap
0
COMMAND=nm build/g0/parser-legacy.o | grep -c ' T _main'
0
COMMAND=nm build/g0/parser-legacy.o | grep -c ' T _parseDefaultStatement$'
1
COMMAND=nm build/g0/parser-legacy.o | grep -c ' T _parseStatement$'
1
COMMAND=nm build/g0/parser-legacy.o | grep -c ' T _parseSwitchStatement$'
1
COMMAND=nm build/g0/parser-legacy.o | grep -c ' T _parseCompoundStatementInternal$'
1
COMMAND=nm build/g0/parser-legacy.o | grep -c ' T _parseDeclOrStatement$'
1
```

A handwritten substitute has NONE of these five production symbols
and DOES define its own `main`. That is the CC-02 detector, and it
was exercised against both the positive and the adverse case.

## THE COMPILED DECISION IS THE SOURCE DECISION

The compiler folds the five-way comparison into a bitset test. The
mask was decoded from the compiled object and matches the source
condition EXACTLY:

```text
sub  w8, w0, #0x102     ; kind - 258
cmp  w8, #0x1d          ; in [258, 287]?
mov  w0, #0x1
lsl  w8, w0, w8         ; 1 << (kind - 258)
mov  w9, #0x1001
movk w9, #0x2041, lsl #16   ; the mask
tst  w8, w9
```

The mask `0x20411001` over the base 258 covers exactly:

```text
258 AST_GOTO
270 AST_RETURN
274 AST_COMPOUND_STMT
280 AST_BREAK
287 AST_CASE
```

which are EXACTLY the five kinds of the live source condition at
`src/parser.c:1683-1684`.

## THE MUTANT'S COMPILED DECISION

When the `AST_COMPOUND_STMT` arm is removed, the compiled mask at the
decision site inside `_parseDefaultStatement` becomes `0x20410001`
(the `AST_COMPOUND_STMT` bit cleared), and the compiled decision is
therefore observably different at the OBJECT level:

```text
MUTANT parser object: 35864f988ee8847a64affb6aa848038ac672775c892ef1d3c434a6caed0fc833
PRISTINE parser object: b4efaadb1cbcdd12e52e27523b0e0c5dabd44ccaa3f77ef3f0ffd623d5a17cc5
RESTORED parser object: 253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246
```

## THE FUNCTION-SCOPED ATTRIBUTION

The mutant production object contains exactly ONE bitset site with
the `0x2041` mask, and it is inside `_parseDefaultStatement`, the
SELECTED function:

```text
COMMAND=otool -tvV <mutant parser.c.o>   (attributed per function)
  _parseDefaultStatement  0x3508  movk w23, #0x2041, lsl #16
```

The already-migrated SUB-001 (case-arm) decision compiles to the SAME
bitset SHAPE but lives in `_parseCaseLabel`. A detector that counted
`cmp`/`tst` instructions anywhere in the object would have
misattributed the SUB-002 evidence to the wrong function. The
function-scoped attribution is therefore MANDATORY, and it is the
CC-04 control.

## THE SUCCESSOR MUST REBUILD THE ORACLE

The successor MUST produce its OWN G0 object from ITS OWN entry tree
and MUST NOT reuse this object's bytes. This ACT's object is evidence
of THIS ACT's tree.
