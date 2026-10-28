# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SUCCESSOR SCOPE

**SUCCESSOR:** `ACT-POLYC-SELFHOST-PARSER-SLICE06`
**TARGET:** `SUB-001` -- the switch-arm termination decision at
`src/parser.c:1551..1553`

---

## 1. IN SCOPE

```text
1. Add the PolyC component implementing the frozen ABI
   I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64

2. Add the dedicated delegation selector
   HCC_USE_SELFHOST_PARSER_SWITCH_ARM
   and the subject link, following the pattern of the five already
   migrated authorities.

3. Replace EXACTLY ONE condition in src/parser.c -- the `if` at
   src/parser.c:1551..1553 -- with a call to the PolyC component.

4. Produce the four independently compiled generations (G0 legacy C,
   G1/G2/G3 PolyC) and the six pairwise comparisons.

5. Run the direct differential against the REAL legacy oracle over the
   derived fixture matrix.

6. Run the production causal experiment with the POLYC decision
   mutated, and the restoration.

7. Run the parser and lexer conservation suites and the required
   Factory gates.
```

## 2. OUT OF SCOPE

```text
NO_CHANGE_TO=src/ast.h                (the AstKind enum values are FROZEN)
NO_CHANGE_TO=any other parser function
NO_CHANGE_TO=src/lexer.c, src/lexer.h
NO_CHANGE_TO=src/ast.c, src/ast.h, src/prslib.c, src/prsutil.c
NO_CHANGE_TO=src/cctrl.c, src/cctrl.h
NO_CHANGE_TO=src/transpiler.c, src/main.c
NO_CHANGE_TO=the recovery protocol
NO_CHANGE_TO=the diagnostic texts
NO_CHANGE_TO=the arm-loop structure
NO_CHANGE_TO=the other three structural sub-slices (SUB-002, SUB-003,
                SUB-004) -- they are separate targets
NO_CHANGE_TO=the seven historical scalar candidates
NO_NEW_PYTHON
NO_CHANGE_TO=tools/quality/parser-slice-recon03-*.HC
NO_CHANGE_TO=the closed evidence trees
```

## 3. WHAT THE SUCCESSOR MUST NOT REOPEN

The ranking is CLOSED.  The successor MUST implement EXACTLY `SUB-001`.
It MUST NOT re-run the ranking and choose an easier target, and it MUST
NOT migrate `SUB-002`, `SUB-003`, `SUB-004` or any historical scalar
candidate "while it is there".  Those are separate migrations with
separate fixtures, oracles and conservation baselines.

## 4. THE FOUR-GENERATION PROOF MODEL

```text
G0  the legacy C decision, compiled from src/parser.c WITHOUT the
    delegation macro.  This is the reference.
G1  the PolyC component compiled by the stage0 compiler.
G2  the PolyC component compiled by G1.
G3  the PolyC component compiled by G2.
```

All four generations must be INDEPENDENTLY compiled, and their outputs
must be semantically comparable over the fixture matrix.  A build PLAN
is not a proof; the successor must produce four real objects with real
provenance.

## 5. THE CONSERVATION BASELINE THE SUCCESSOR MUST MATCH

```text
PARSER_HOST_ARCH_ASSERTIONS=376/376
PARSER_HOST_ARCH_TESTFILES=90
PARSER_HOST_ARCH_FAILURE_IDENTITIES=0
PARSER_CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX
PARSER_CROSS_TARGET_FAILURE_IDENTITIES=0
LEXER07_DIRECT_DIFF_PASS=89
LEXER08_DIRECT_DIFF_PASS=45
LEXER09_DIRECT_DIFF_PASS=23
LEXER07_BROAD_CORPUS_STATUS=FAIL
LEXER07_BROAD_CORPUS_REGRESSION=0
LEXER07_BROAD_CORPUS_DIVERGED=0
LEXER07_BROAD_CORPUS_FAILURE_IDENTITY_COUNT=15
LEXER07_BROAD_CORPUS_FAILURE_IDENTITY_MD5=7ee761440de83552e751e3c3976c1683
GATE_FAST_RESULT=PASS
GATE_PUSH_RESULT=PASS
```

The successor MUST reproduce the failure-IDENTITY SETS, not merely the
counts.

## 6. THE STRUCTURAL OWNERSHIP THE SUCCESSOR MUST PRESERVE

```text
RECOVERY_OWNER=C
AST_GRAPH_OWNER=C
SYMBOL_TABLE_OWNER=C
TOKEN_STREAM_OWNER=C
DIAGNOSTIC_OWNER=C
LONGJMP_TARGET_OWNER=C
ERROR_MESSAGE_OWNER=C
TOKEN_REWIND_OWNER=C
```

The successor changes ONE boolean decision.  Everything else about the
parser's ownership of mutable state stays exactly as it is.
