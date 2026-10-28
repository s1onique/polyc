# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE06

**Factory-Version:** 2

## Result

The switch-case ARM TERMINATION decision in the PolyC parser is now
owned by a qualified PolyC component, and the legacy C decision has
been retired from the production path.  This is the SIXTH
production-authoritative PolyC parser decision.

The decision was migrated as ONE bounded structural sub-slice.  The
enclosing authority (`parseCaseLabel`) stays on the C side, and every
mutable-state authority -- the AST graph, the allocation, the
diagnostics, the recovery point, the symbol table and the token stream
-- is UNCHANGED.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. Actual ENTRY_HEAD

```text
ENTRY_HEAD=1ccf28d58fec9c856c12ad1f71bab9a2ca6e18e0
ENTRY_TREE=a8532b8027607e15dd8f4b9f6d683194bc577f82
BRANCH=main
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0
```

The observed HEAD was EXACTLY the ACT's declared Expected ENTRY_HEAD,
and that commit IS the predecessor's terminal CLOSE commit.  There was
therefore NO intervening commit to inventory: the entry tree IS the
predecessor's CLOSE tree.

The predecessor was resolved through local Git history, not from the
abbreviated form in the ACT text:

```text
PREDECESSOR_CLOSE_REACHABLE=YES
PREDECESSOR_ACT=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
PREDECESSOR_PHASE=CLOSE
PREDECESSOR_VERDICT=PASS
INTERVENING_COMMITS=0
```

## 2. The frozen target and ABI

```text
SELECTED_CANDIDATE=SUB-001
SELECTED_CANDIDATE_CLASS=STRUCTURAL_BOUNDARY
SELECTED_ENCLOSING_FUNCTION=parseCaseLabel
SELECTED_SOURCE_RANGE=src/parser.c:1551..1553
SELECTED_SOURCE_SHA256=31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707
SELECTED_ABI=I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
DELEGATION_MACRO=HCC_USE_SELFHOST_PARSER_SWITCH_ARM
FAILURE_SEMANTICS=NO_FAILURE_PATH
```

The source-range digest was RE-MEASURED at this ACT's entry and is
EXACTLY the frozen value, so the frozen source contract was VALID
against the live tree.

## 3. The six terminating values

```text
AST_COMPOUND_STMT = 274
AST_CASE          = 287
AST_DEFAULT       = 293
AST_BREAK         = 280
AST_RETURN        = 270
AST_GOTO          = 258
```

They were NOT inherited as an assumption.  They are bound to the live
`src/ast.h` by COMPILING it (c1/compiled-enum-values.tsv) and,
independently, by PARSING the live `src/parser.c` condition text
(c1/fixture-integrity.txt):

```text
DERIVED_ENUM_VALUES=41
DERIVED_TERMINATING=6
DERIVED_TERMINATING_LINE=1551
DERIVED_TERMINATING_SET=274 287 293 280 270 258
```

The component has NO range check, and it must NOT have one: the legacy
condition does not range-check either, so an out-of-enum value matches
none of the six constants and the arm CONTINUES.

## 4. The object-level G0 oracle

The predecessor's frozen oracle contract required the successor to
STRENGTHEN the source-bound extraction to the object-level form.  That
was done.

The G0 object is the ACTUAL production `src/parser.c` translation unit
compiled WITHOUT `HCC_USE_SELFHOST_PARSER_SWITCH_ARM`, so the
byte-identical legacy condition is the code that executes.  The
Makefile rule FAILS THE BUILD if that object references the PolyC
component.

```text
G0_ROWS=51
G0_TERMINATING_KINDS=258 270 274 280 287 293
G0_OBJECT_LEVEL_IDENTICAL_TO_FROZEN_EXTRACTION=YES
G0_MUTATION_CONFINED_TO_ONE_ROW=YES
```

The G0 object's disassembly carries the REAL decision as a bitset test
(`sub #0x102`, `cmp #0x23`, `tst` against the 64-bit mask).

## 5. The derived fixture

```text
DERIVED_FIXTURE_ROWS=64
DERIVED_FIXTURE_PARTITIONS=12
ROW_COUNT_HARDCODED=NO
```

The row count is DERIVED from the live enum and the frozen probe set
and is REPORTED by the producer.  It is 64, NOT the historical 51, and
c1/fixture.txt explains the difference from the live source: the same
51 value-rows plus 13 rows that assign the witness dimensions
(P08..P11) to concrete kinds.  Both counts cover the same domain.

The integrity witness is INDEPENDENT of the producer: it reads the
LIVE SOURCE TEXT of `src/ast.h` and `src/parser.c` and parses it, so a
transcription error in the producer would be detected.

```text
FIXTURE_INTEGRITY_STATUS=PASS
```

## 6. The three-source differential

Every row is compared across three sources: the legacy oracle's
decision, the PolyC component's decision and the fixture's
independently derived expected value.

```text
SLICE06_DIFF_ROWS=64
SLICE06_DIFF_PASS=64
SLICE06_DIFF_FAIL=0
SLICE06_DIFF_ORACLE_VS_EXPECTED_MISMATCH=0
SLICE06_DIFF_POLYC_VS_EXPECTED_MISMATCH=0
SLICE06_DIFF_ORACLE_VS_POLYC_MISMATCH=0
SLICE06_DIFF_STATUS=PASS
```

## 7. The negative controls

All eight fixture controls (FC-01..FC-08) and all three
production-differential controls (PD-01..PD-03) were EXECUTED and each
fired for its INTENDED reason.

```text
FIXTURE_NEGATIVE_CONTROLS=PASS
PRODUCTION_DIFFERENTIAL_NEGATIVE_CONTROLS=PASS
```

The structural-boundary controls SB-01..SB-03 belong to the
predecessor's ranking, which this ACT is explicitly forbidden from
re-opening, so they were NOT re-executed.  The production-reachability
fact they protect is independently established by the C2 evidence.

## 8. The four generations

Four generations were BUILT and EXECUTED independently, with four
DISTINCT producing compiler binaries:

```text
G0's producer = /usr/bin/cc              (the real host C compiler)
G1's producer = build/host-stage0/hcc     (the stage0 compiler)
G2's producer = ./hcc                     (the G1 compiler)
G3's producer = ./build/hcc-bootstrap02   (the G2 compiler)
```

Each generation's SEMANTIC OUTPUT is the stdout of a REAL COMPILED
PROGRAM: the generation's component was linked into its OWN production
compiler, that compiler compiled the SAME frozen observation program,
and the program was EXECUTED.  All four produce:

```text
SUB001:ARM2_MARKER
SUB001:x=1
```

and all twelve ORDERED pairs are equal.

The three PolyC objects are BYTE-IDENTICAL, and that is reported
HONESTLY: the PolyC compiler is deterministic for this source, so the
independence is in the COMPILATION -- four distinct compiler
processes, four distinct compiler binaries and four distinct build
receipts with four DISTINCT nonces -- not in the output bytes.

```text
G0_G3_INDEPENDENT=YES
GENERATION_SEMANTICS=PASS
PROVENANCE_BINDING=PASS
```

## 9. The provenance negative controls

A separate PolyC observer checks every generation WITHOUT
short-circuiting: the binding, the run binding, the execution receipt,
the nonce, the probe output and the LIVE compiler, object and source
identities.  Five controls were EXECUTED and each fired for its
INTENDED reason.

```text
NC-01  G3_BINDING_MISMATCH (+ RECEIPT_MISMATCH, DUPLICATE_NONCE)
NC-02  G3_EXECUTION_RECEIPT_MISSING
NC-03  COMPILER_IDENTITY_MISMATCH
NC-04  OBJECT_IDENTITY_MISMATCH
NC-05  STAGE_IDENTITY_MISMATCH

PROVENANCE_NEGATIVE_CONTROLS=PASS
```

## 10. The production delegation

```text
PRODUCTION_OBJECT_REFERENCES_POLYC=YES  (U _BootstrapSwitchArmTerminates)
PRODUCTION_OBJECT_DEFINES_POLYC=NO
LEGACY_CONDITION_IN_PRODUCTION_OBJECT=NO
PRODUCTION_DELEGATION_IS_LOAD_BEARING=YES
```

The production wrapper's disassembly is a PURE CALL: no comparison,
no branch and no constant.  The legacy condition is compiled OUT of
the active production authority, and the legacy condition is NOT
evaluated before, after or alongside the delegation.

The C side still owns the `break` that leaves the arm loop, and the C
side still owns the AST graph, the allocation, the diagnostics, the
recovery point, the symbol table and the token stream.

## 11. The causal experiment

The mutation was applied to the POLYC decision, NOT to the C source.
The full production compiler was REBUILT SUCCESSFULLY in an isolated
worktree of this repository at this ACT's own C2 commit.

```text
PRISTINE_OUTPUT =SUB001:ARM2_MARKER,SUB001:x=1
MUTATED_OUTPUT  =SUB001:ARM1_MARKER,SUB001:ARM2_MARKER,SUB001:x=1
RESTORED_OUTPUT =SUB001:ARM2_MARKER,SUB001:x=1

MUTATED_OUTPUT_DIFFERS=YES
RESTORED_OUTPUT_EQUALS_PRISTINE=YES
MUTANT_BUILD=PASS
RESTORED_COMPILER_BYTE_IDENTICAL=YES
```

The compiler binary and the subject object BOTH changed under the
mutation, so the mutation really reached the production compiler.  The
source was then restored BYTE-IDENTICALLY and both came back
byte-identical.

## 12. The conservation

```text
PARSER_HOST_ARCH_ASSERTIONS   = 376/376 over 90 test files
PARSER_ASSERTION_SEQUENCE_MD5 = b6f117eb1386ca80f81bc06226e2a741
NEW_PARSER_FAILURE_IDENTITIES = 0
LEXER07/08/09 DIRECT DIFF     = 89 / 45 / 23
NEW_LEXER_FAILURE_IDENTITIES  = 0
LEXER07_BROAD_CORPUS_STATUS   = FAIL (the historical nonzero baseline)
LEXER07_FAILURE_IDENTITY_MD5  = 7ee761440de83552e751e3c3976c1683
LEXER07_REGRESSION            = 0
LEXER07_DIVERGED              = 0
NEW_LEXER07_FAILURE_IDENTITIES= 0
CROSS_TARGET_STATUS           = FAIL_ENVIRONMENT_PREFIX (67 in BOTH trees)
```

The LEXER07 broad corpus and the cross-target run remain NONZERO.  They
are recorded HONESTLY: they are the frozen historical debt, they are
IDENTICAL to the entry tree's measurements, and they are NOT relabelled
PASS.

## 13. The Factory gates and invariants

```text
GATE_FAST=PASS
GATE_PUSH=PASS
APPEND_ONLY=PASS
F14=PASS
CLOSURE_STATUS=PASS
PATCH_HYGIENE=PASS
FACTORY_V2_RANGE_CHECK=PASS (run at C4 against the CLOSE commit)
NEW_PYTHON_FILES=0
NEW_PYTHON_INVOCATIONS=0
NEW_UNAUTHORIZED_TOOL_VIOLATIONS=0
```

Every gate ACTUALLY ran.  None of these is inferred from a stale
artifact.

## 14. The residue

```text
F_NO_PYTHON_STATUS=FAIL (12 PREEXISTING violations, 0 new)
F_POLYC_TOOLS_CHECKER=UNAVAILABLE (still not landed)
CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX (67 missing tos.HH)
LEXER07_BROAD_CORPUS_STATUS=FAIL (15 failure identities, unchanged)
```

None of these is a new ACT-owned violation, and none is waived.

## 15. The mandatory acceptance ledger

```text
MANDATORY_AC_TOTAL=36
MANDATORY_AC_PASS=36
MANDATORY_AC_FAIL=0
MANDATORY_AC_UNPROVEN=0
```

Every frozen ID is joined to its evidence and its observed result in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/c3/mandatory-ac-status.tsv`.

## 16. The remaining structural candidates

The other three eligible structural sub-slices (`SUB-002`, `SUB-003`,
`SUB-004`) and the twelve eligible scalar candidates remain
authorized for LATER acts.  They are NOT authorized here, and this ACT
did not choose among them.

The PARSER01 whole-function blockers REMAIN open:

```text
parseCompoundStatementInternal as a whole function
parseStatement as a whole function
parseExpr as a whole function
the recursive flow-analysis walks
the declaration-versus-statement routing decision (SUB-005)
```

## 17. The commit topology

```text
C0  fafcf49f9d94f905c4c84bdd6fe6ce7dd223d15b
C1  94f9086b187aa958a1ff10d5fc79327e44084231
C2  a5591d6be4fe037a3ac15a9c1d313d26d5ff581a
C3  23823d2
C4  (this ACT's CLOSE commit)
```

Five forward-only commits, no amend, no rebase, no reset, no
force-push.

VERDICT

PASS

Six production-authoritative PolyC parser decisions, including the
first migrated bounded structural switch-arm decision; all four
bootstrap generations independently demonstrated; no newly introduced
failures; and the frozen historical debt recorded honestly rather than
relabelled green.

A successor beyond SUB-001 remains separately unauthorized until a new
evidence-backed selection exists.
