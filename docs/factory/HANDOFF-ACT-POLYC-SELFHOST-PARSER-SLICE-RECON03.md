# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

Factory-Version: 2

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This document is a human summary.

---

## 1. Entry identity and baseline

```text
ENTRY_HEAD       = 4e001cc5c92041a65bfb31f6199a5edb0f231473
BRANCH           = main
WORKTREE_CLEAN   = YES
GIT_REPLACE_REFS = 0
PREDECESSOR      = ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02
PREDECESSOR_REACHABLE = YES
```

The entry HEAD equals the verified predecessor HEAD exactly, so there
were no intervening commits to inventory.

The frozen source identities (SHA-256) of every parser surface are in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c0/source-freeze.tsv`.

---

## 2. Current self-hosted versus legacy-C parser authority

```text
COMPONENT                              AUTHORITY   SEAM
BootstrapScanIdent                     POLYC       src/lexer.c::lexIdentifier
BootstrapClassifyOperator              POLYC       src/lexer.c::lexCore
BootstrapScanScalarLiteral             POLYC       src/lexer.c::lexNumeric
BootstrapScanTrivia                    POLYC       src/lexer.c::lexSkipCodeComment
BootstrapLinkDirective                 POLYC       src/lexer.c::lexLink
BootstrapCalcPadding                   POLYC       src/parser.c:430  (5 call sites)
BootstrapValidPostControlFlowToken     POLYC       src/parser.c:832  (5 call sites)
```

Both parser authorities were verified against the LIVE CMake
configuration and the ACTUAL production object, not against source
comments and not merely an exported symbol.  The strong form of the
evidence is that `build/CMakeFiles/hcc.dir/parser.c.o` carries

```text
U _BootstrapCalcPadding
U _BootstrapValidPostControlFlowToken
```

as UNDEFINED symbols: the legacy C algorithm bodies live in the `#else`
branches and are therefore **not compiled into the production object**.
The surviving C symbols are thin forwarding adapters.

---

## 3. Newly discovered semantic sub-slices

RECON03 re-inventoried the parser surface (118 functions across
`src/parser.c`, `src/prslib.c`, `src/prsutil.c` and the parser-facing
primitives of `src/ast.c`), revisited all 17 RECON02 candidate records,
and discovered **19 new semantic sub-slices**.

Ten of them pass the ACT §5.2 sub-slice checklist and the full
13-clause eligibility conjunction:

```text
CAND-017  parseGetPriority            src/prslib.c:1139..1207
CAND-018  parseCompoundAssign         src/prslib.c:1269..1289
CAND-019  astBinOpFromToken           src/ast.c:206..236
CAND-020  astUnaryOpFromToken         src/ast.c:238..254
CAND-021  astBinOpToTokenPunct        src/prslib.c:1293..1316
CAND-022  parseCountPrintfFormatSpecs src/prslib.c:760..792
CAND-023  parseFormatArgIdx           src/prslib.c:798..810
CAND-025  astIsAssignment             src/ast.c:845..866
CAND-026  astIsValidPointerOp         src/ast.c:876..892
CAND-030  parseIsClassOrUnion         src/prsutil.c:22..25
```

The other nine each fail a NAMED clause of the §5.2 checklist (unbounded
recursion, a host pointer in the ABI, no production call path, or host
graph mutation).  A sub-slice is not eligible merely because its
proposed signature accepts scalar values.

---

## 4. Full eligibility results

The verdict is COMPUTED by a PolyC-native checker from the fact fields;
the checker's input has **no `eligible` column**, so an eligibility flag
cannot be hand-authored anywhere in the path.

```text
TOTAL_CANDIDATES        = 35
ELIGIBLE_CANDIDATES     = 10
EXCLUDED_CANDIDATES     = 25
ELIGIBILITY_CONTROLS    = 13/13 PASS
```

Per-candidate results, the excluded reasons and the failed clause
numbers are in `c2/eligibility-results.tsv`,
`c2/eligible-candidates.tsv` and `c2/excluded-candidates.tsv`.

---

## 5. Full ranked candidate set

The ranking is COMPUTED by a PolyC-native ranker over the FROZEN
dimensions `(R0, R1, R2, R3, R4, R5, R6)`; the R1..R6 meanings are
restated with their provenance in `c2/ranking-dimensions.tsv`.

```text
RANK CANDIDATE  R0 R1 R2 R3 R4 R5 R6
1    CAND-017   0  1  2  2  0  0  src/prslib.c:1139   <== SELECTED
2    CAND-022   0  2  2  2  0  0  src/prslib.c:760
3    CAND-018   0  2  2  2  0  0  src/prslib.c:1269
4    CAND-021   0  2  2  2  0  0  src/prslib.c:1293
5    CAND-023   0  2  2  2  1  1  src/prslib.c:798
6    CAND-019   0  2  3  2  0  0  src/ast.c:206
7    CAND-020   0  2  3  2  0  0  src/ast.c:238
8    CAND-025   0  2  3  2  0  0  src/ast.c:845
9    CAND-026   0  2  3  2  0  0  src/ast.c:876
10   CAND-030   0  2  3  2  0  0  src/prsutil.c:22
```

Rank 1 is the UNIQUE lexicographic minimum.  No tie-break was needed and
none was invented.

---

## 6. Selected target and production call graph

```text
CAND-017  parseGetPriority   src/prslib.c:1139..1207
R0=0  R1=1  R2=2  R3=2  R4=0  R5=0  R6=src/prslib.c:1139
```

**What it is:** the operator precedence table of the whole compiler.

**The input projection is mechanically complete on ONE scalar.**  The
body of `src/prslib.c:1139..1207` is a single `switch` over `tok->i64`
and references no other field and no other identifier:

```text
$ sed -n '1139,1207p' src/prslib.c | grep -n 'tok->'
2:    switch (tok->i64) {
```

**It owns no host state:** no Cctrl, no AST, no List/Map/Vec traversal,
no pointer identity, no allocation, no callback, no recovery, no global
or static state, no diagnostic ownership.

**The production call graph:**

```text
32 parseExpr call sites (src/parser.c 23, src/prslib.c 8, src/lexer.c 2,
                        including the macro preprocessor)
    -> parseExpr                       src/prslib.c:1343
        -> parseGetPriority            src/prslib.c:1363   <== THE SEAM
            -> prec2
                -> next_prec           src/prslib.c:1430
                -> next_prec++ ('=')   src/prslib.c:1431
                    -> parseExpr(cc,next_prec)  src/prslib.c:1435
                        -> THE AST SHAPE OF EVERY BINARY AND UNARY EXPRESSION
```

**Why it is the right target:** it is maximally production-reachable, it
is semantically central (the precedence value decides the AST shape of
every expression in every compiled program), and it unlocks multiple
following surfaces (R1=1).

---

## 7. ABI and fixture contract

```text
POLYC_SYMBOL  = BootstrapOperatorPrecedence
INPUT         = I64 punct_value
OUTPUT        = I64 precedence
```

The complete ABI contract, including the exact precedence table with
the live `src/lexer.h` constant values, the `-1` sentinel semantics, the
delegation shape and the out-of-scope list, is in
`c2/selected-abi-contract.md`.

```text
ABI_HOST_IDENTITY_FIELDS = 0
ABI_ALLOCATION_SITES     = 0
```

The fixture model is 19 partitions with 91 minimum rows, covering every
accepted precedence class, the rejected values, the boundary integers,
the sign/width boundaries, the aliasing-sensitive value and one
production-observable row.  It is in `c2/fixture-partitions.tsv`.

---

## 8. RED and causal proof model

All five REDs of `c2/red-contract.md` were checked to be REPRODUCIBLE
against the live tree (`c3/red-contract-verify.txt`).

The causal mutation was **EXECUTED, not merely proposed.**  A throwaway
copy of the source tree was mutated so that the `*` operator moves from
precedence 4 to precedence 6, the mutant compiler was built and
**LINKED**, and the divergence was observed in a compiled program:

```text
pristine  -> 62    ((a*b)+c)
mutated   -> 162   (a*(b+c))
restored  -> 62    (identical SHA-256 to the pristine output)
```

The mutation is the MINIMAL single-operator change that flips the
grouping, and the derivation from the `parseExpr` recursion is recorded
in `c2/causal-mutation-contract.md`, so the choice is falsifiable rather
than guessed.  The tracked source was never modified.

The four-generation proof model is frozen in
`c2/successor-proof-contract.md`.

---

## 9. Conservation outcomes and genuine residue

```text
PRODUCTION_SOURCE_MODIFIED   = 0     (git diff --stat 4e001cc5..HEAD -- src/ is empty)
NEW_PARSER_FAILURE_IDENTITIES = 0    (87 parser tests pass, 0 fail)
NEW_LEXER_FAILURES            = 0    (lexer07/08/09 differentials: 89/45/23 rows, 0 fail)
NEW_LEXER07_FAILURE_IDENTITIES = 0   (the failure identity sets are IDENTICAL to the baseline)
REMOVED_LEXER07_FAILURE_IDENTITIES = 0
GATE_FAST                     = PASS
FACTORY_V2                    = PASS (53/0)
APPEND_ONLY                   = PASS (11/0)
F14                           = PASS  (the predecessor evidence tree hash is identical)
PATCH_HYGIENE                 = PASS
F_NO_PYTHON                   = PRE-EXISTING (12 tracked; 0 new)
F_POLYC_TOOLS                 = PRE-EXISTING (5 shell-LOC; 0 new)
```

**The LEXER07 broad corpus reports `STATUS=FAIL` and `make` reports
RC=2.**  That is preserved as measured and is not relabelled.  The
prospective conservation result is nevertheless zero new failures: the
per-stage pass counters are identical to the baseline
(166/175/175/175), `REGRESSION=0`, `DIVERGED=0`, and the failure
identity sets are unchanged (the same 9 `NO_FALLBACK` and the same 6
`ALL_FAIL` sources).

**AC47 is recorded as `FAIL_PRE_EXISTING_HOST_ISSUE`, not as PASS.**  The
only failing gate-push check is `CHECK=aot`, which is `make unit-test`;
its per-test compile omits `--install-dir`, so the compiler falls back
to its compile-time prefix `/usr/local`, which does not exist on this
host.  The same test compiles and PASSES when the prefix is supplied,
and the `src/` tree is byte-identical to the entry commit, so the
failure necessarily occurs there too.  This is the P1 residue recorded
by `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02`.

### Residue

| Priority | Item | Disposition |
| --- | --- | --- |
| P1 | The closed control-flow-token qualification tool **silently skips an INDENTED unknown fixture row**: the observed count stays 42, `UNKNOWN_IDS=0`, `STATUS=PASS`.  A non-indented unknown row IS detected (count 43, `STATUS=FAIL`), so the defect is specific to the indented-continuation rule.  The predecessor's own NC-D18 control reports this case as passing, so the predecessor and this probe DISAGREE. | `FIXTURE_METADATA_BYPASS=REPRODUCED`.  The old parser is NOT edited: it is closed evidence under F14 and is forbidden by this ACT's scope.  Owned by a future bounded correction of the qualification tool.  Does NOT block the next decision.  The successor contract therefore REQUIRES an independent fixture-id and row-count witness and forbids relying on that parser alone. |
| P1 | `make unit-test` / the gate-push `aot` check fails on a host without a writable `/usr/local`, because `src/tests/run.HC:13-14` compiles each test without `--install-dir`. | Pre-existing; documented by `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02` (HANDOFF section 8).  Repairing the harness is outside this ACT's scope.  Carried forward. |
| P1 | The F-NO-PYTHON checker reports 12 tracked Python sources and the shell-LOC ratchet reports 5 over-budget scripts. | Pre-existing baseline violations in files this ACT did not touch; 0 new.  Recorded, not waived, not fixed. |
| P2 | `tools/factory/factory-polyc-tools-check.HC` (the authoritative F-POLYC-TOOLS checker) is NOT YET LANDED. | The C2.9 residue recorded by AGENTS.md.  The nearest live enforcement (the shell-LOC ratchet) is satisfied by this ACT. |
| P2 | The nine remaining eligible candidates (`CAND-018`, `CAND-019`, `CAND-020`, `CAND-021`, `CAND-022`, `CAND-023`, `CAND-025`, `CAND-026`, `CAND-030`) remain unmigrated. | Carry forward.  Each is a viable later target; `CAND-019`/`CAND-020` in particular are the natural companion migrations to the precedence table. |

---

## 10. Single successor ACT identity

```text
NEXT_ACT_ID      = ACT-POLYC-SELFHOST-PARSER-SLICE03
NEXT_TARGET      = CAND-017 parseGetPriority (src/prslib.c:1139..1207)
NEXT_ABI         = I64 BootstrapOperatorPrecedence(I64 punct_value) -> I64 precedence
NEXT_SCOPE_FROZEN = YES
```

The successor's binding objectives:

1. Add the PolyC component implementing the frozen ABI.
2. Build a direct differential against the REAL legacy-C function over
   the frozen 91-row fixture matrix, using the frozen oracle adapter
   strategy.
3. Produce four generations and all six pairwise comparisons, with real
   generation provenance and a copy-forgery rejection control.
4. Delegate the PRODUCTION call path (`src/prslib.c:1363`) to the PolyC
   component under a DEDICATED build macro, so the legacy C body is not
   compiled into the enabled production binary.
5. Demonstrate the production causal mutation (62 -> 162 -> 62).
6. Run the parser and lexer conservation suites and the LEXER07 corpus
   against the prospective baseline.

The successor's frozen out-of-scope list is in
`c2/successor-proof-contract.md` section 11, plus the component-specific
prohibitions: no change to the precedence values, no change to the `-1`
sentinel, no addition of a `tk_type` check, and no constant binding other
than the live `src/lexer.h` values.

---

## 11. Verdict

VERDICT

---

PASS

### The result

```text
ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
VERDICT=PASS

PARSER_PADDING_AUTHORITY=POLYC
PARSER_CONTROL_FLOW_TOKEN_AUTHORITY=POLYC

CURRENT_PARSER_INVENTORY=COMPLETE
LEGACY_AUTHORITY_INVENTORY=COMPLETE

NEW_ATOMIC_SLICES_CLASSIFIED=YES
UNCLASSIFIED_DEPENDENCIES=0

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_R0<=2
SELECTED_CANDIDATE_ELIGIBLE=YES

SELECTED_PRODUCTION_SEAM=FEASIBLE
SELECTED_ABI_CONTRACT=FROZEN
SELECTED_REAL_C_ORACLE=IDENTIFIED
SELECTED_RED_MODEL=REPRODUCIBLE
SELECTED_CAUSAL_PROOF=FEASIBLE

PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEW_PARSER_FAILURES=0
NEW_LEXER_FAILURES=0

F14=PASS
FACTORY_V2=PASS
APPEND_ONLY=PASS
PATCH_HYGIENE=PASS

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE03
```

The AC ledger is in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c3/mandatory-ac-status.tsv`:
52 rows, 49 PASS, 1 `FAIL_PRE_EXISTING_HOST_ISSUE` (AC47, with its proof),
2 DEFERRED (AC50 and AC52, which require the CLOSE commit), 0 UNPROVEN.
