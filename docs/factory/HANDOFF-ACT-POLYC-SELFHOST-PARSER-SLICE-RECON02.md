# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02

VERDICT

PASS_TRUE_GREEN

  This ACT mechanically selected the next production-authoritative
  PolyC parser component and authorized its successor migration ACT.
  It performed ZERO compiler semantic mutation.

  Closure verdict is authoritative in the `ACT-Verdict` trailer of the
  ACT's CLOSE commit.

---

## Result

```text
PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC
PARSER_SLICE_RECON02_INVENTORY=COMPLETE
PARSER_SLICE_RECON02_ELIGIBILITY=COMPLETE

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_R0<=2

SELECTED_ABI_CONTRACT=FROZEN
SELECTED_RED_MODEL=REPRODUCIBLE
SELECTED_PROOF_MODEL=COMPLETE
SELECTED_PRODUCTION_SEAM=FEASIBLE

PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE02
```

The selected target:

```text
CAND-001  parseValidPostControlFlowToken  src/parser.c:832..864
R0=0  R1=1  R2=2  R3=0  R4=0  R5=1  R6=src/parser.c:832
ABI: I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind,
     I64 value) -> I64      ABI_HOST_IDENTITY_FIELDS=0
5 live production call sites: src/parser.c:950, 961, 1254, 1288, 1321
```

---

## 1. Current parser self-hosting authority inventory

```text
COMPONENT                              AUTHORITY      SEAM
BootstrapScanIdent                     POLYC          src/lexer.c::lexIdentifier
BootstrapClassifyOperator              POLYC          src/lexer.c::lexCore
BootstrapScanScalarLiteral             POLYC          src/lexer.c::lexNumeric + lexCharConst
BootstrapScanTrivia                    POLYC          src/lexer.c::lexSkipCodeComment
BootstrapLinkDirective                 POLYC          src/lexer.c::lexLink
BootstrapCalcPadding                   POLYC          src/parser.c::CalcPadding
--------------------------------------------------------------
parseValidPostControlFlowToken        LEGACY C       src/parser.c:832..864  <- SELECTED
CalcUnionSize                          LEGACY C       src/parser.c:397..408
CalcClassSize                          LEGACY C       src/parser.c:410..428
astIsConstTrueCond                     LEGACY C       src/parser.c:1940..1944
astStmtHasBreak                        LEGACY C       src/parser.c:1948..1971
astStmtFallsThrough                    LEGACY C       src/parser.c:1973..2013
asmTextHasReturn                       LEGACY C       src/parser.c:2021..2052
```

The padding migration is production-authoritative, verified against the
LIVE tree rather than documentation:

```text
HCC_USE_SELFHOST_PARSER_PADDING=ON_BY_DEFAULT
  src/CMakeLists.txt:231-233   option(... ON)
  build/CMakeCache.txt:242     HCC_USE_SELFHOST_PARSER_PADDING:BOOL=ON
CalcPadding_DELEGATES_TO_BootstrapCalcPadding=YES
  src/parser.c:431             #ifdef HCC_USE_SELFHOST_PARSER_PADDING
  src/parser.c:452-453         return (int)BootstrapCalcPadding(...)
  src/CMakeLists.txt:326-327   target_compile_definitions + target_link_libraries
LEGACY_C_CALC_PADDING_PRODUCTION_PATH=INACTIVE
  the legacy body is only in the #else branch, which production does not compile
  $ nm build/hcc | grep -c '_BootstrapCalcPadding'   ->  1
```

---

## 2. Historical-vs-current candidate differences

All 14 RECON01 candidates were revisited; all 64 historically surveyed
parser helpers were mapped (8 relocated: 6 to `src/prslib.c`, 2
lexer-owned in `src/lexer.h`; 2 new functions added). Two genuinely new
candidate slices were found by a fresh search.

```text
CAND-003 CalcClassSize        R0 0 -> 4   RECLASSIFIED
  src/parser.c:424  type->offset = offset;
  The historical R0=0 was derived from the SCALAR RETURN VALUE rather
  than from the state boundary.  The write to a host-owned AstType node
  is the disqualifier.  Now INELIGIBLE.

CAND-011 parseFlattenAnonymous R0 3 -> 4   RECLASSIFIED
  src/parser.c:254  type->offset += offset;   (+ mapAdd at :257)
  The historical R0=3 understated it: it mutates the host graph twice.

CAND-002 CalcPadding          ALREADY_SELFHOSTED
  Production authority moved to PolyC.  CAND-002_SELECTED_AGAIN=FORBIDDEN.

CAND-015 parseIfClause         NEW CANDIDATE   R0=3, 5 callbacks -> INELIGIBLE
CAND-016 parseRaiseCaseException NEW CANDIDATE R0=3, diagnostic helper
CAND-003S CalcClassSize pure-size sub-slice   CONSIDERED, REJECTED
  The offset side effect is interleaved in the SAME loop as the size
  accumulation, so a pure sub-slice would duplicate the alignment walk,
  would have no production call site, and would need a new callback
  contract.  Not independently nominable.

All other candidates: UNCHANGED.
```

---

## 3. Full eligibility and ranking result

The hard-eligibility conjunction (13 clauses, no human override) was
applied to every candidate, each exclusion anchored to the current
source. It was re-applied MECHANICALLY at C3 by a checker that reads the
C1 artifacts and ANDs the clauses; that checker's stdout is
byte-identical to `c3/c3-eligibility-recomputed.tsv`.

```text
ELIGIBLE_COUNT=1      CAND-001
INELIGIBLE_COUNT=16
UNKNOWN_CANDIDATES=0
UNCLASSIFIED_STATE_DEPENDENCIES=0
ELIGIBLE_ALREADY_SELFHOSTED=0
```

The lexicographic ranking on the FROZEN historical dimensions
`(R0, R1, R2, R3, R4, R5, R6)`:

```text
rank candidate_id  R0 R1 R2 R3 R4 R5 R6                 disposition
1    CAND-001      0  1  2  0  0  1  src/parser.c:832  SELECTED
2    CAND-004      0  2  2  0  0  0  src/parser.c:397  R0=0 but seam is a
                                                          u32(*)(List*) callback
3    CAND-008      1  2  2  0  0  1  src/parser.c:1980 unbounded AoStr
4    CAND-006      2  1  2  1  0  0  src/parser.c:1907 unbounded AST
5    CAND-007      2  1  2  1  0  1  src/parser.c:1932 unbounded AST
6    CAND-005      2  2  2  1  0  0  src/parser.c:1899 unbounded AST
```

R0 remained the first and strongest dimension. No new column and no
redefinition of any historical column was introduced; the only changed
values are CAND-003's R0 (source-anchored) and the R6 line numbers (the
file grew above the candidates).

**The ranking was COMPUTED, not asserted.** The ranker reproduces the
RECON01 historical winner (CAND-002) when fed the RECON01 historical
input — that is its self-check. All nine mandatory anti-bias controls
were executed at C2 and re-run at C3, and all nine PASS:

```text
CONTROL_1  previously migrated CalcPadding      excluded as ALREADY_SELFHOSTED
CONTROL_2  whole parseCompoundStatementInternal  excluded as recovery-coupled
CONTROL_3  current CalcClassSize graph writes    detected, not ignored
CONTROL_4  ineligible + favourable R1..R6        still excluded
CONTROL_5  R0 perturbation of the leader         ranking changes appropriately
CONTROL_6  remove the selected candidate         next eligible candidate wins
CONTROL_7  shuffle inventory row order            20/20 -> CAND-001 (unchanged)
CONTROL_8  opaque host handle as scalar          rejected
CONTROL_9  callback hidden inside a helper       rejected
```

The three falsifiable controls each CHANGE the winner, which is only
possible if the ranker genuinely reads the scores. The ranker lives in
the IGNORED build directory and is not a tracked tool.

---

## 4. Exactly one selected target

```text
CAND-001  parseValidPostControlFlowToken
FILE      src/parser.c
LINES     832..864   (33 LOC)
SIGNATURE int parseValidPostControlFlowToken(Lexeme *tok)
```

Why it wins:

```text
R0=0  The entire observable input is two scalar fields plus a presence
      flag.  The `Lexeme *` is used purely as a container of immutable
      values; the decision never depends on WHICH Lexeme it is.
R1=1  Consumed by FOUR distinct production parser functions (if, else,
      for, while, do-while) -- it unlocks multiple following surfaces.
R3=0  The observable is a scalar 0/1 used only as a boolean.
R4=0  Zero helper dependencies, zero shared mutable state.
R5=1  33 LOC and a simple fixture-matrix differential.
```

And, decisively, it is the only candidate whose production seam is an
ORDINARY call site rather than a function-pointer callback contract.

Its measured purity (re-verified at C3):

```text
ONLY_TWO_SCALAR_FIELDS_READ=YES      (tok->tk_type, tok->i64)
ZERO_WRITES_ZERO_CC_ACCESS=YES
ZERO_RECOVERY=YES
ZERO_ALLOCATIONS=YES
ZERO_CALLS=YES
```

---

## 5. ABI proposal and evidence

```text
symbol_name        = BootstrapValidPostControlFlowToken
input_field_count  = 3   (I64 token_present, I64 token_kind, I64 token_value)
output_field_count = 1   (I64, restricted to {0,1})
ABI_HOST_IDENTITY_FIELDS=0
```

Every accepted constant is bound to the live `src/lexer.h`, not guessed:
`TK_IDENT` 0x300, `TK_STR` 0x301, `TK_PUNCT` 0x329, `TK_KEYWORD` 0x332,
`TK_PLUS_PLUS` 0x305, `TK_MINUS_MINUS` 0x306, and the twelve keyword
constants `KW_RETURN` 18 ... `KW_THROW` 82, plus `'{'`=123, `';'`=59,
`'*'`=42 (verified with `od`).

**A live-header aliasing the successor MUST honour:** `TK_SUPERSCRIPT`
and `TK_STR` are BOTH defined as `0x301` (`src/lexer.h:15` and `:19`).
At the ABI level 0x301 is therefore `TK_STR` and is ACCEPTED. A
successor that assumed a distinct "superscript" kind would produce a
different result and fail the differential. Fixture F041 pins it.

Diagnostic ownership does not move: the component returns 0 and the C
caller raises (`cctrlRaiseException` at src/parser.c:951-952, 962-965,
1255-1256, 1289-1290, 1322-1324). Token resynchronisation stays in C.

The frozen fixture matrix has 42 rows (22 accept, 20 reject), each
expectation derived by reading the exact source line that decides it.

---

## 6. Frozen RED and proof model

**RED** (each with a re-runnable witness; re-executed at C3):

```text
RED-1  legacy authority exists      src/parser.c:832..864 + 5 live call sites
RED-2  PolyC authority absent        grep -rn BootstrapValidPostControlFlowToken
                                     src/ tools/   ->  0 matches
RED-3  production delegation absent  nm build/hcc | grep -c
                                     _BootstrapValidPostControlFlowToken -> 0
                                     (the symbol does not exist at all: not a
                                      shadow test, not a dead linked object)
RED-4  no qualified successor proof  the five missing proof dimensions are
                                     enumerated, each checkable by a command
RED-5  observable causal sensitivity six frozen mutation classes; M1 (drop
                                     TK_IDENT acceptance) is primary and is
                                     observable at the PRODUCTION level via
                                     the existing "while parsing if body"
                                     diagnostic
```

**Proof model** — 16 frozen dimensions: legacy reference (the ACTUAL C
function, not a substitute), direct differential, fixture coverage,
4-generation/6-pairwise fixed point, generation provenance,
generation-copy forgery control, production delegation, production causal
mutation, legacy authority retirement, parser conservation, lexer
conservation, LEXER07, F14, F-POLYC-TOOLS, F-NO-PYTHON, Factory gates.

Two guards are explicit: fixed-point equality proves REPRODUCIBILITY, not
semantic correctness; and the stage0 -> stage1 semantics are frozen as
EQUALITY, never as a tolerated migration delta.

---

## 7. Conservation and Factory gate results

```text
GATE_FAST            PASS   (RC=0)
GATE_PUSH            PASS   (VERDICT=PASS, 8/8 checks)
FACTORY_V2           PASS   (PASS=53 FAIL=0)
APPEND_ONLY          PASS   (PASS=11 FAIL=0)
PATCH_HYGIENE        PASS   (git diff --check RC=0)
F14                  PASS   (closed evidence delta 0, closed HANDOFF delta 0)

PARSER_CONSERVATION  PASS   67 files, 363 assertions, 0 compile failures,
                             0 run failures, 0 regressions
LEXER_CONSERVATION   PASS   LSP 43/43; AOT and JIT 363 each
LEXER07              CONSISTENT
                             counter text matches the registry EXACTLY
                             both failure-source sets match EXACTLY
                             (9 NO_FALLBACK, 6 ALL_FAIL_4)
                             registered verifier: BASELINE_MATCH=YES
                             NEW_LEXER07_FAILURES=0, 6 sources IMPROVED
                             full corpus recorded as STATUS=FAIL (exit 1),
                             NOT relabelled as PASS
```

**Pre-existing environment limitation (recorded, not waived).** The
canonical `make unit-test` reports failures on this host because
`src/tests/run.HC`'s host-arch branch (run.HC:13-14) passes no
`--install-dir`, so `hcc` falls back to its compile-time
`INSTALL_PREFIX` = `/usr/local`, which does not exist here and is not
creatable without elevated privileges. Running the same suite through the
harness's own supported `--target` mechanism (with the hermetic prefix
staged) gives 363 assertions passed, 0 compile failures, 0 run failures.
The 7 residual failures are isolated to `src/tests/39_arg_count.HC`,
which invokes `hcc` with no `--install-dir`; that file is unchanged since
2023 and this ACT changed zero files under `src/`. Proven pre-existing by
five independent checks.

**Pre-existing checker violations (recorded, not waived).** The
no-Python checker (RC=1, 12 violations) and the shell-budget checker
(RC=1) report violations in files this ACT did not touch; 0 new
violations were introduced. Their exact results and the pre-existence
proof are in `c3/c3-f-no-python.txt` and `c3/c3-f-polyc-tools.txt`.

---

## 8. Explicit residue

| Priority | Item | Disposition |
| --- | --- | --- |
| P1 | `src/tests/run.HC`'s host-arch branch passes no `--install-dir`, so the canonical `make unit-test` fails on hosts without a writable `/usr/local`. The cross-target branch (run.HC:17) does pass it. | Pre-existing; repairing the harness is outside this ACT's scope (it forbids modifying canonical test oracles). Carried forward. |
| P1 | `src/tests/39_arg_count.HC:24` invokes `hcc` with no `--install-dir`, so its 6 assertions fail on such hosts. | Pre-existing; same disposition. |
| P1 | RECON01's published ranking places CAND-003 before CAND-004, while its own C3 note says CAND-004 wins the R6 tie-break. The mechanical ranker agrees with the note. | IMMATERIAL: the disagreement changes neither the RECON01 winner (CAND-002 under both) nor this ACT's selection (CAND-003 is excluded at R0=4, CAND-004 on the seam). The published history is preserved under F14 and is NOT rewritten. |
| P1 | The F-NO-PYTHON and F-POLYC-TOOLS checkers report pre-existing violations (12 Python sources/invocations, several unbudgeted and over-budget shell scripts). | Pre-existing, owned by other ACTs. Recorded, not fixed. The no-Python checker is still not wired into gate-fast. |
| P2 | The five unselected state-boundary-eligible candidates (CAND-004, CAND-005, CAND-006, CAND-007, CAND-008) remain in the inventory. Their seams are a function-pointer callback contract or unbounded projections. | Carry forward; a future parser-selfhost ACT may revisit them if their seams are redesigned. |
| P2 | `parseCompoundStatementInternal` remains R0=5 (recovery-coupled). The PARSER01-CORRECTION01 finding is a permanent architectural observation. | Do not address in this ACT. |

---

## 9. Next ACT

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE02
NEXT_ACT_DESCRIPTIVE_TITLE=ACT-POLYC-SELFHOST-PARSER-CONTROL-FLOW-TOKEN01
NEXT_TARGET=CAND-001 parseValidPostControlFlowToken (src/parser.c:832..864)
NEXT_R0=0
NEXT_ABI=I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value)
NEXT_SCOPE_FROZEN=YES
```

The successor's binding objectives:

1. Add the PolyC component implementing the frozen ABI.
2. Build a direct differential against the ACTUAL C
   `parseValidPostControlFlowToken` over the frozen 42-row fixture
   matrix.
3. Produce four generations and all six pairwise comparisons, with real
   generation provenance and a forged-provenance rejection control.
4. Delegate the PRODUCTION call path (the 5 call sites) to the PolyC
   component under a DEDICATED build macro, so the legacy C body is not
   compiled into the enabled production binary.
5. Demonstrate the production causal mutation (M1..M6, at least M1 at
   the production level).
6. Run the parser and lexer conservation suites and the LEXER07 corpus
   against the prospective baseline.

The successor's frozen out-of-scope list is in
`c2/c2-selected-proof-contract.md` section 4, plus the
component-specific prohibitions: no ABI shape change, no `Lexeme *`
across the boundary, and no constant binding other than the live
`src/lexer.h` values (including the `0x301` aliasing).
