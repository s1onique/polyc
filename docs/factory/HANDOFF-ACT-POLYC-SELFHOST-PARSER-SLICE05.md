# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE05

**Factory-Version:** 2

## Result

Both AST token-to-operator classifiers of the PolyC parser are now
owned by qualified PolyC components, and the legacy C decisions have
been retired from the production path.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. Actual ENTRY_HEAD

```text
ENTRY_HEAD=b7634f9afb6b530f7bac987317754ab35b8dbead
BRANCH=main
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0
```

The observed HEAD was EXACTLY the ACT's declared Expected ENTRY_HEAD,
so there was no intervening commit to inventory: the entry tree IS the
predecessor's CLOSE tree.

The predecessor was resolved through local Git history, not from the
abbreviated form in the ACT text:

```text
PREDECESSOR_CLOSE_REACHABLE=YES
PREDECESSOR_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE04
PREDECESSOR_VERDICT=PASS
```

## 2. The frozen unary mapping and ABI

```text
I64 BootstrapAstUnaryOpFromToken(I64 token_value) -> I64
FAILURE_SENTINEL=-1
DELEGATION_MACRO=HCC_USE_SELFHOST_PARSER_AST_UNARY
```

The ten mappings were **RE-DERIVED, not inherited**.  The live
`src/lexer.h` and `src/ast.h` were **compiled**, and a probe printed
the values the compiler assigned; the mapping itself was **measured by
executing the real legacy function**:

```text
816 -> 2   TK_PRE_PLUS_PLUS     -> AST_UN_OP_PRE_INC
817 -> 3   TK_PRE_MINUS_MINUS   -> AST_UN_OP_PRE_DEC
773 -> 0   TK_PLUS_PLUS         -> AST_UN_OP_POST_INC
774 -> 1   TK_MINUS_MINUS       -> AST_UN_OP_POST_DEC
 43 -> 4   '+'                  -> AST_UN_OP_PLUS
 45 -> 5   '-'                  -> AST_UN_OP_MINUS
126 -> 7   '~'                  -> AST_UN_OP_BIT_NOT
 33 -> 6   '!'                  -> AST_UN_OP_LOG_NOT
 38 -> 8   '&'                  -> AST_UN_OP_ADDR_OF
 42 -> 9   '*'                  -> AST_UN_OP_DEREF
else -> -1
```

The live `AstUnOp` enum spans `0..12`, so the `-1` sentinel cannot
collide with any successful mapping.

## 3. The real C oracle and the fixture counts

The oracle is the **real legacy C function**, compiled from the live
`src/ast.c` with the delegation OFF.  Its object contains
`_astUnaryOpFromToken` and contains **no reference** to
`_BootstrapAstUnaryOpFromToken`.  The driver contains **no mapping
table**.

```text
FIXTURE_ROW_COUNT=346
FIXTURE_PARTITION_COUNT=13
FIXTURE_ACCEPTED_TOKEN_COUNT=10
FIXTURE_DISTINCT_VALUES=150
```

The row count is **derived**, not chosen: the producer emits the rows
and reports the count it wrote.  It is **not** SLICE04's 322 rows,
because the unary token set produces a different partition structure.

The fixture was verified against the real legacy oracle **before** the
contract was frozen (196 rows with initial 12345 and 150 rows with
initial 54321, 0 mismatches), and again against the production build
(346/346, 0 mismatches).

### Two defects were found by measurement, not by inspection

* **D-FIX-01** -- the U04 neighbour rule emitted a *rejection* for
  816, which is itself an accepted token (`TK_PRE_PLUS_PLUS` is the
  immediate predecessor of `TK_PRE_MINUS_MINUS` = 817).  Found by
  running the fixture against the real legacy function.
* **D-FIX-02** -- the direct literal `-9223372036854775808` does
  **not** evaluate to `INT64_MIN` in this language: the positive
  magnitude is one past `INT64_MAX`, so constant folding wraps it to
  `INT64_MIN` and the unary minus wraps it *back* to
  `-9223372036854775807`.  Found by the verifier rejecting the
  legitimate `INT64_MIN` fixture row.

Both were fixed before the contract was frozen.  A contract frozen
without running its own tools against the real legacy function would
have carried both defects into the qualification.

## 4. Production delegation and object-symbol proof

The production `ast.c.o` carries an undefined reference to
`_BootstrapAstUnaryOpFromToken`.  Its disassembly is now twelve
instructions with **no jump table and no switch**: a call, a test of
the `-1` sentinel, a conditional store through the output pointer, and
the success/failure conversion.  The legacy mapping is not present in
the production object.

```text
UNARY_PRODUCTION_OBJECT_REFERENCES_POLYC=YES
POLYC_UNARY_STRONG_DEFINITION_PRESENT=YES
LEGACY_UNARY_MAPPING_IN_PRODUCTION=NO
TOKEN_DECISION_OWNER=POLYC
C_ADAPTER_CONDITIONAL_STORAGE=YES
LEGACY_SWITCH_EXECUTED=NO
NO_SHADOW_VERIFICATION=YES
NO_FALLBACK=YES
```

From a **pristine tree**, the five PolyC authorities in the linked
production binary each have exactly one strong global text definition,
and the duplicate-symbol count is zero.

The unary subject is verified by **SLICE04's already-qualified
generic verifier**, reused READ-ONLY and parameterized with the unary
expected symbol, so there is no second, weaker verifier to drift.  The
fail-closed controls rejected the missing, empty, malformed,
undefined-only, local-only, weak-only and wrong-name cases, and the
production build failed closed in practice when the subject was absent.

## 5. Four-generation build identities and comparisons

```text
g0  LEGACY_C_REFERENCE       /usr/bin/cc                 (the ACTUAL host C compiler)
g1  POLYC_STAGE1_PRODUCTION  ./hcc
g2  POLYC_STAGE2_INDEPENDENT ./build/hcc-bootstrap02
g3  POLYC_STAGE3_INDEPENDENT ./build/hcc-bootstrap03
```

Each generation was built by its own compiler and executed.  No
generation's output was copied as a substitute for another
generation's compilation.  G1, G2 and G3 produce **byte-identical**
objects, which is exactly why the provenance witness -- and not the
object bytes -- is what detects a substitution.

The semantic output of a generation is the **stdout of a real compiled
program**: the generation's component was linked into its own
production compiler, that compiler compiled the frozen observation
program, and the program was run.

```text
G1_EQ_G2=YES  G1_EQ_G3=YES  G2_EQ_G3=YES
all twelve ordered semantic pairs = YES
GENERATION_SEMANTICS=PASS
```

## 6. Precise provenance-control results

**The two SLICE04 deficiencies were CORRECTED, not repeated.**  The
historical SLICE04 CASE-1 rejected with a **row-count** reason
(`REJECT_STAGE_LABELS ... carries 3 generations, expected 4`), and its
CASE-2 named **G0** rather than G3.  SLICE05's controls start from a
COMPLETE four-generation witness, mutate exactly one field, and are
rejected with a **generation-scoped** reason:

```text
NC-P01  the G1 payload in the G3 slot   -> G3_BINDING_MISMATCH
NC-P02  only the G3 receipt removed    -> G3_EXECUTION_RECEIPT_MISSING
NC-P03  one compiler SHA changed       -> COMPILER_IDENTITY_MISMATCH
NC-P04  a non-byte-identical subject   -> OBJECT_IDENTITY_MISMATCH
NC-P05  the G1 and G3 stage ids swapped -> STAGE_IDENTITY_MISMATCH
```

The verifier does **not** short-circuit: it evaluates every check for
every generation and reports every diagnostic, so the intended
generation-scoped reason is always among them.

The verifier also **caught a real staleness** during the C3 phase: the
`hcc-bootstrap02` and `hcc-bootstrap03` binaries were rebuilt, the
recorded compiler SHAs went stale, and the verifier reported
`G2_COMPILER_IDENTITY_MISMATCH` and `G3_COMPILER_IDENTITY_MISMATCH`.
The witness was regenerated and the controls re-run.

### The honest security boundary

A locally recorded compiler SHA, execution receipt and object SHA can
prove **consistency with independently retained build observations**.
They cannot prove resistance to an adversary who can rewrite the entire
evidence store.  SLICE05 claims exactly what its controls demonstrate:

```text
DETECTION OF THE SPECIFIED WITNESS SUBSTITUTIONS AND OMISSIONS = DEMONSTRATED
RESISTANCE TO A TOTAL EVIDENCE-STORE REWRITE                 = NOT CLAIMED
```

## 7. Production-causal mutation and restoration

Three **actual production compilers** were built -- pristine, mutated,
restored -- and each compiled and ran the frozen observation program.

```text
A (pristine)  UNARY_MINUS_RESULT=-7
B (mutated)   UNARY_MINUS_RESULT=7
C (restored)  UNARY_MINUS_RESULT=-7
```

```text
A_BUILD_RC=0  A_EXEC_RC=0
B_BUILD_RC=0  B_EXEC_RC=0
C_BUILD_RC=0  C_EXEC_RC=0
B_OUTPUT_DIFFERS_FROM_A=YES
C_OUTPUT_EQUALS_A=YES
C_SUBJECT_SHA_EQUALS_A=YES
```

The A and C compiler SHAs are **identical**, the mutated object SHA
differs, and the tracked component SHA is unchanged before and after:
the mutation lived in a **scratch copy**.  The other three
observations are identical in A, B and C, so the mutation is
**specific**.

## 8. Four previous PolyC parser migrations conserved

```text
tools/bootstrap/selfhost-parser-padding.HC
  sha256=b555b76b484edda5830abba46dbda803a12ec1834f9ab0a64763f5899f2452f3
tools/bootstrap/selfhost-parser-control-flow-token.HC
  sha256=77199636db559024365fffc168cd191c1281593452682aab80005151e6baf196
tools/bootstrap/selfhost-parser-operator-precedence.HC
  sha256=3e7a9cf4983e8b625ab3e004dba15b4afcaddb7c83c18f234adf89b9c8468979
tools/bootstrap/selfhost-parser-slice04.HC
  sha256=43f3b95933a6d87aca9824b0337d416abeddc24bfb25743413554be922c8f63d
```

All four are **identical to the C0 entry freeze**.  The binary
classifier's source is byte-identical to the entry HEAD: the diff of
`src/ast.c` has exactly **one hunk**, at the unary classifier.

## 9. Parser and lexer result-identity comparisons

```text
parser suite (host arch):
  ENTRY   376/376 assertions, 90 test files, 0 failures
  C2      376/376 assertions, 90 test files, 0 failures
  assertion-sequence md5: b6f117eb1386ca80f81bc06226e2a741 (IDENTICAL)

lexer differentials:  89 / 45 / 23 rows, 0 fail  (identical to the baseline)
LEXER07 broad corpus:  PASS_S0=166 FAIL_S0=15 FAIL_S1=6
                       REGRESSION=0 DIVERGED=0  STATUS=FAIL

NEW_PARSER_FAILURE_IDENTITIES=0
NEW_PARSER_SEMANTIC_REGRESSIONS=0
NEW_LEXER_FAILURE_IDENTITIES=0
NEW_LEXER07_FAILURE_IDENTITIES=0
```

The LEXER07 corpus remains honestly `STATUS=FAIL`; it is **not**
relabelled PASS.  What is preserved is the regression delta, which is
zero.

The cross-target parser run fails on **both** trees with
`Failed to open file: /usr/local/include/tos.HH`.  That is the
historical installation-prefix condition (this host has no
`/usr/local`), it is identical on the entry tree and the C2 tree, and
it is preserved honestly rather than relabelled PASS.  It is not a
new failure identity.

## 10. Factory gates and the acceptance ledger

```text
GATE_FAST=PASS
GATE_PUSH=PASS   (build, install, gep01, aot, jit, lsp, diff-check -- all green)
APPEND_ONLY=PASS (11/11)
FACTORY_CLOSURE_STATUS=PASS
F14=PASS
PATCH_HYGIENE=PASS
NEW_PYTHON_FILES=0
NEW_PYTHON_INVOCATIONS=0
NEW_UNAUTHORIZED_TOOL_VIOLATIONS=0
F_POLYC_TOOLS_CHECKER=UNAVAILABLE (not landed; reported, not invented)
```

The F-NO-PYTHON findings are **byte-identical** to the entry tree's
(12 tracked Python findings and 1 known PolyC -> Python execution
edge).  SLICE05 introduced none.

The acceptance ledger has **exactly the frozen C1 contract's ID set**:

```text
AC_TOTAL=50
AC_UNIQUE_IDS=50
AC_DUPLICATE_IDS=0
AC_MISSING_IDS=0
AC_PASS=49
AC_DEFERRED_TO_CLOSE=1   (AC50 only)
AC_FAIL=0
AC_UNPROVEN=0
```

At C3, AC50 was `DEFERRED_TO_CLOSE` with the reason recorded
explicitly, exactly as the ACT permits.  Its actual post-CLOSE
satisfaction is established by the external terminality checks of ACT
section 14.

## 11. Honest residual problems

* **The F-POLYC-TOOLS checker does not exist** in this repository.
  `tools/factory/factory-polyc-tools-check.HC` is not landed.  Its PASS
  result is **not** invented; it is reported as unavailable.  The
  related wiring residue (C2.9) is unchanged by this ACT.
* **The `make test-prefix-install` runtime-library link emits a
  pre-existing linker error** on this host, in the `all.o` runtime
  archive step.  It is **non-fatal** (the target's exit code is 0) and
  it reproduces identically on the entry tree, so it is an environment
  condition, not a SLICE05 regression.
* **The cross-target parser suite cannot run** on this host because
  there is no `/usr/local` runtime prefix.  The host-architecture run
  is the meaningful measurement and it is clean on both trees.
* **The SLICE04 provenance-control deficiencies are not repaired in
  place.**  SLICE04's closed evidence, HANDOFF and `PASS` trailer are
  untouched (F14).  The defects are recorded as a reading in SLICE05's
  own evidence and corrected in SLICE05's own new controls.
* The `libtos` archive in the working tree's test prefix predates the
  current runtime revision (it carries 313 symbols but not
  `_PrintResult`).  The gate-push hermetic prefix is unaffected.

## 12. AST operator classifier family status

```text
SELFHOSTED PARSER COMPONENTS
----------------------------

CalcPadding                     POLYC
parseValidPostControlFlowToken  POLYC
parseGetPriority                POLYC
astBinOpFromToken               POLYC
astUnaryOpFromToken             POLYC

AST_OPERATOR_CLASSIFICATION     COMPLETE
PARSER_SELFHOSTING              IN_PROGRESS
```

This completes the **bounded AST token-to-operator mapping family**.  It
does **not** imply that the entire parser, the AST construction
subsystem, or the compiler is self-hosted.

## 13. The recommended next reconnaissance scope

```text
ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
```

Re-inventory the remaining parser and AST semantic authorities after
five qualified parser migrations, reclassify every candidate against
the live source, and select the next bounded migration surface.  **No
next winner is preselected.**

A future reconnaissance should reconsider the structural parser slices
previously excluded because of host AST graph mutation, callback
dependencies, or recovery coupling -- but it must **not** pretend those
dependencies disappeared as a result of migrating operator classifiers.
The AST operator family was a good migration surface precisely because
it had no such dependencies; the structural slices are a different
problem.

## Terminal facts

```text
TARGET                       = CAND-020
FUNCTION                     = astUnaryOpFromToken
POLYC_SYMBOL                 = BootstrapAstUnaryOpFromToken
POLYC_ABI                    = I64 BootstrapAstUnaryOpFromToken(I64) -> I64
FAILURE_SENTINEL             = -1
DELEGATION_MACRO             = HCC_USE_SELFHOST_PARSER_AST_UNARY
PRODUCTION_CALL_SITES        = src/prslib.c:1450, src/prslib.c:1757
COMPONENT_SOURCE             = tools/bootstrap/selfhost-parser-slice05.HC
COMPONENT_SOURCE_SHA256      = 26a9b4578d3dc6301a26df5f6d8ee3d8bb4326869aa1165949112aa9c44065fb
COMPONENT_OBJECT_SHA256      = 27075194e1d3ff94703b51459cc3e5c8ea472747ea1f255a451a97f44b416e72
G0_COMPILER                  = /usr/bin/cc
G0_COMPILER_SHA256           = 9b11ead1ca76a03d61108ad5bf2c913d6aa8daa7deb9fd28893e847e3680e5e7
G0_COMPILER_VERSION          = Apple clang version 15.0.0 (clang-1500.0.40.1)
G0_COMPILER_IS_THE_POLYC_COMPILER = NO
FIXTURE_ROW_COUNT            = 346
ACCEPTED_MAPPING_COUNT       = 10
```

## The acceptance ledger

```text
AC_TOTAL=50
AC_ID_UNIQUE=YES
AC_MISSING=0
AC_DUPLICATE=0
AC_PASS=49
AC_DEFERRED_TO_CLOSE=1
AC_FAIL=0
AC_UNPROVEN=0
```

The ledger was produced by an **exact acceptance-ID join** against the
frozen C1 contract, and the counts were recomputed from the written
ledger's own rows.  At C3, AC50 was `DEFERRED_TO_CLOSE` with the
reason recorded explicitly, exactly as the ACT permits; its actual
post-CLOSE satisfaction is established by the external terminality
checks of ACT section 14, recorded in the CLOSE phase.

VERDICT

PASS

Both AST token-to-operator classifiers are now PolyC-owned, the legacy
C decisions are retired from the production path, the two SLICE04
provenance-control deficiencies are corrected rather than repeated, the
production delegation is proven causally load-bearing by a
pristine/mutated/restored sequence of three actual production
compilers, all four previously migrated components are conserved, and
all 50 mandatory acceptance predicates are proven.
