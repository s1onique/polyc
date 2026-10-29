# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07`
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-N06-SUPPLEMENT / SUCCESSOR-SELECTION
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01`
(closed, `ACT-Verdict: PASS`, disposition `PASS_EVIDENCE_SUPPLEMENTED`)
**Historical governance predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06`
(closed, `ACT-Verdict: HALT_N06_FROZEN_OBLIGATION_UNPROVEN`,
`HALT_CLASS: GOVERNANCE`, `BLOCKS_NEXT: NO`) -- PRESERVED EXACTLY.

VERDICT

PASS

---

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. The outcome, in short

**One legacy-C parser decision has been selected for the next PolyC
migration, and the selection is a computed output rather than a
choice.**

```text
SELECTED_CANDIDATE_ID = SUB-002
SELECTED_CLASS        = STRUCTURAL
SELECTED_DECISION     = DEFAULT_ARM_TERMINATION
SELECTED_SOURCE_FILE  = src/parser.c
SELECTED_SOURCE_RANGE = 1683..1684
SELECTED_SOURCE_SHA256= a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
SELECTED_ABI          = I64 ast_kind -> I64 terminate
NEXT_ACT             = ACT-POLYC-SELFHOST-PARSER-SLICE08
NEXT_ACT_STATUS      = READY_TO_DRAFT
NEXT_TARGET          = SUB-002
PRODUCTION_SEMANTIC_DELTA      = 0
SUCCESSOR_IMPLEMENTATION_DELTA = 0
```

**No production semantics changed.**  This ACT migrated nothing.  It
produced one trustworthy successor contract.

---

## 2. The N-06 supplement, audited read-only

The historical RECON06 HALT was caused by an unexecuted frozen
obligation.  That obligation was discharged by an APPEND-ONLY
correction ACT, and this ACT verified the correction's RAW evidence
rather than its summary verdict:

```text
RECON07_N06_SUPPLEMENT_VERIFIED      = YES
RECON07_N06_GATE                     = CORRECTED_SUPPLEMENT_VERIFIED
CORRECTION01_NEW_LITERAL_N06_VERIFIED= YES
SLICE07_HISTORICAL_N06_EXECUTED_AS_WRITTEN = NO
N06_AND_S7_CC01_HISTORICALLY_INDEPENDENT   = NO
RECON06_HISTORICAL_VERDICT           = HALT_N06_FROZEN_OBLIGATION_UNPROVEN
RECON06_HISTORICAL_ARTIFACTS_UNCHANGED = YES
```

The six required sub-facts were each read from a raw committed
artifact: a genuine C-authoritative selector-OFF compiler was built;
exactly one file, one hunk and one line of `src/parser.c` was mutated
in a detached worktree; the mutant compiler built successfully; the
witness acceptance changed on three independent channels; the
selector-ON build was byte-identical; and the restoration was
byte-identical.  The experiment has its own execution identity and is
distinct from the historical SLICE07 PolyC mutation.

**RECON06's HALT is preserved exactly.  It was not relabelled.**

---

## 3. The census, and a real defect it found

The live census was re-derived from the source bytes.  It is **272**
functions, not the historical 270:

```text
LIVE_FUNCTIONS_TOTAL       = 272
RECON05_FUNCTIONS_ADDED     = 2
RECON05_FUNCTIONS_REMOVED   = 0
RECON05_FUNCTIONS_CHANGED   = 12
RECON05_FUNCTIONS_UNCHANGED = 258
UNCLASSIFIED_FUNCTIONS      = 0
```

Every row is explained by exactly ONE commit (the SLICE07 C1
insertion of 130 lines into `src/parser.c`).

**The census also exposed a material defect in the RECON05 candidate
facts.**  The census's `body_line` convention includes each
function's own trailing comment block, so TEN of the twelve RECON05
scalar candidate ranges span past their own closing brace.  **NINE
candidate range pairs overlap, and THREE of the RECON05 ranges
contain ANOTHER CANDIDATE'S ENTIRE BODY** -- for example RECON05's
`CAND-038` (`astNormaliseFunctionName`, 931..1018) contains
`astIsAssignment` 943..964, `astIsValidPointerOp` 974..990 and
`astIsBinCmp` 992..1017 in full, when the true body is 931..941.

A range that contains another candidate's body cannot be the
source-binding for a bounded ABI: a component migrated from it would
by construction also own the other candidate's decision.  RECON07
records the TIGHT, function-bodied ranges.  **The historical evidence
is preserved unchanged** (F14); no historical artifact was edited.

---

## 4. The selection, and why it was not hand-picked

The population is 24 candidates: 12 historical structural IDs, 12
historical scalar follow-ups with their real canonical IDs, and no
invented or misnumbered ID.

The **unmodified** canonical 13-clause eligibility checker admitted 11
of the 17 checker-population rows; the **unmodified** canonical
R0..R6 ranker ordered them.  The `eligible` column of the ranking
input was taken mechanically from the checker's output.

The **first eligible structural candidate**, SUB-002, was the first
to be tested for causal feasibility.  It PASSED.  The procedure
therefore stops there; no lower-ranked candidate was tested and none
is claimed to have been.

### The complete ranked population

| Rank | Candidate | Class | R0..R5 | R6 | Disposition |
|---|---|---|---|---|---|
| 1 | SUB-002 | STRUCTURAL | 0 1 1 2 1 1 | src/parser.c:1683 | **SELECTED** |
| 2 | SUB-004 | STRUCTURAL | 0 2 1 2 2 2 | src/parser.c:1773 | ELIGIBLE_FALLBACK |
| 3 | CAND-018 | SCALAR | 0 2 2 2 0 0 | src/prslib.c:1328 | not reached |
| 4 | CAND-021 | SCALAR | 0 2 2 2 0 0 | src/prslib.c:1375→1352 | not reached |
| 5 | CAND-025 | SCALAR | 0 2 3 2 0 0 | src/ast.c:943 | not reached |
| 6 | CAND-026 | SCALAR | 0 2 3 2 0 0 | src/ast.c:974 | not reached |
| 7 | CAND-036 | SCALAR | 0 2 3 2 0 0 | src/ast.c:992 | not reached |
| 8 | CAND-037 | SCALAR | 0 2 3 2 0 0 | src/ast.c:2348 | not reached |
| 9 | CAND-030 | SCALAR | 0 2 3 2 0 0 | src/prsutil.c:22 | not reached |
| 10 | CAND-022 | SCALAR | 1 2 2 2 0 0 | src/prslib.c:760 | not reached |
| 11 | CAND-023 | SCALAR | 1 2 2 2 1 1 | src/prslib.c:798 | not reached |

### The complete excluded set (6, all checker-confirmed)

| Candidate | Excluded by | Reason |
|---|---|---|
| SUB-001 | clause 02 | already PolyC-owned (`BootstrapSwitchArmTerminates`) |
| SUB-003 | clause 02 | already PolyC-owned (`BootstrapCompoundBlockAppendsStatement`) |
| SUB-005 | clauses 11+12 | **transitively** depends on the mutable `cc->symbol_table`, `cc->clsdefs`, `cc->uniondefs` |
| CAND-038 | clauses 11+12 | unbounded HOST STRING in, NEW HOST STRING out |
| CAND-039 | clauses 11+12 | Lexeme + mutable host scope in, NEW HOST STRING out |
| CAND-040 | clauses 11+12 | unbounded opaque HOST BUFFER |

Seven further whole-region blockers (SUB-006..SUB-012) were
re-evaluated and classified.  **No bounded sub-decision is concealed
by a whole-function blocker**: SUB-004, the keyword dispatch inside
the ineligible whole-function `parseStatement`, survives as its own
candidate.

---

## 5. The causal proof

```text
G0_OBJECT_SHA256              = 8737313a547f20b507f4841af4056b3e9c1a51850076e01c121e5c7f3126959c
G0_POLYC_REFERENCES           = 0
G0_DEFINES_MAIN               = 0
G0_PRODUCTION_SYMBOLS_PRESENT = 5 of 5
PRISTINE_WITNESS_OUTPUT       = WITNESS_OUTPUT=110 155
MUTANT_WITNESS_OUTPUT         = WITNESS_OUTPUT=110 177
MUT_BUILD_EXIT                = 0
MUTANT_PARSER_OBJECT_SHA256   = 35864f988ee8847a64affb6aa848038ac672775c892ef1d3c434a6caed0fc833
RESTORED_PARSER_OBJECT_SHA256 = 253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246
RESTORED_SRC_SHA256           = 2b31a7912bfbcfe538786aff17383a8282da815f0990910a652a0119f084fe17
CAUSAL_DIRECTION_CHANGE       = FIRES
```

The G0 oracle is the **real production translation unit** compiled
from `src/parser.c` with the decision factored out, exactly as the
seven already-migrated authorities are.  Its compiled bitset mask
`0x20411001` decodes to EXACTLY the five kinds of the live source
condition, so the compiled decision IS the source decision.

The restoration is byte-identical in the SOURCE **and** in the PARSER
OBJECT, and the restored object is byte-identical to the authoritative
main checkout's production parser object.  The mutation is not merely
reverted in the source; it is ABSENT from the compiled artifact.

A bounded, source-derived mutation set of FIVE single-arm mutants
covered every distinct decision outcome, and each changed EXACTLY ONE
of the 41 fixture rows.

---

## 6. Two findings that change what the successor must do

### 6.1 The canonical checker cannot detect a forged fact row

It is a pure function of its input facts.  A forged `already_selfhosted`
or a forged `production_delegation_feasible` is believed.  The
defence is the **source-bound** verification:

```text
DETECTOR=MUTABLE_HOST_STATE_DEPENDENCE
DEPENDENCE_SITE=TRANSITIVE_THROUGH_A_CALLEE
```

which re-derives SUB-005's dependence from the live bytes.

### 6.2 The canonical ranker trusts its `eligible` column

Given a forged `eligible=YES` for the already-excluded `CAND-040`
with the best possible numeric dimensions, it **SELECTS CAND-040**.  A
SECOND, SEPARATE implementation
(`tools/quality/parser-surface-recon07-recompute.HC`) re-derives the
eligibility and the order from the raw facts alone and still selects
SUB-002.

**Therefore the independent recomputation is a REQUIRED gate, not a
redundancy.**  This ACT wrote that recomputer and used it.

---

## 7. The independent re-derivation

```text
CANONICAL_ROWS=17  INDEPENDENT_ROWS=17
CANONICAL_ELIGIBLE=11  INDEPENDENT_ELIGIBLE=11
ELIGIBILITY_MISMATCH=0
CLAUSE_DISAGREEMENTS=0
FULL_RANKING_MISMATCH=0
WRONG_TIES=0
MISSING_IDS=0  EXTRA_IDS=0  DUPLICATE_IDS=0
SELECTED_ID_MISMATCH=0
```

---

## 8. The twenty negative controls

All twenty were ACTUALLY EXECUTED, each with a reason-specific
detector, a positive baseline, an exit and a restoration.  None is
vacuous.

```text
NEGATIVE_CONTROLS_TOTAL=20  PASS=20  MISSING=0  EXTRA=0
DUPLICATE=0  VACUOUS=0  UNEXECUTED=0  UNRESTORED=0
```

---

## 9. The conservation, honestly reported

```text
PARSER_ASSERTIONS=376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
LEXER07/08/09_DIRECT_DIFFS=89/89, 45/45, 23/23
LEXER07_BROAD_STATUS=FAIL_KNOWN_BASELINE (15 identities,
  MD5 7ee761440de83552e751e3c3976c1683)
CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX (67)
F_NO_PYTHON=FAIL_KNOWN_BASELINE (exactly 12)
F_POLYC_TOOLS=UNAVAILABLE
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0
GATE_FAST=PASS  GATE_PUSH=PASS  APPEND_ONLY=PASS  F14=PASS
```

**Every historical nonzero status is preserved exactly.  Nothing was
relabelled PASS.**

---

## 10. The successor contract

Thirteen ACT-owned artifacts, each bound by SHA-256 in
`c2/selected-contract-hashes.tsv`.  The successor MUST re-verify
those hashes at its own C0 and HALT if any differs.

**The most important part is the causal contract's two TIME-SCOPED
controls**, which exist so the successor cannot repeat the N-06
mistake:

| Control | Phase | Subject | Status |
|---|---|---|---|
| `RECON07-SUB-002-PRE-C-MUTANT` | PRE-migration | the legacy C decision | **ALREADY EXECUTED by this ACT**, as a CITED PRIOR EXECUTION |
| `RECON07-SUB-002-POST-POLYC-MUTANT` | POST-migration | the compiled PolyC component | **MUST be newly executed by the successor** |
| `RECON07-SUB-002-SLICE08-C-OFF-C-MUTANT` | POST-migration, C-OFF | the legacy C decision | required only if the successor inherits a C-mutant demand |

One experiment must not silently discharge two controls.  If two
control IDs are to share one experiment, BOTH must say so explicitly
and must not claim experiment independence.

**The four-generation plan is a PLAN:**

```text
FUTURE_G1_G2_G3_EXECUTED=NO
FUTURE_G1_G2_G3_FEASIBILITY=PROVEN
```

---

## 11. The fifty acceptance predicates

```text
MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=49      (AC01..AC49, joined by exact ID to real evidence)
MANDATORY_AC_DEFERRED_TO_CLOSE=1  (AC50, discharged only by the
                                   external read-only post-CLOSE check)
MANDATORY_AC_FAIL=0
MANDATORY_AC_UNPROVEN=0
```

---

## 12. The scope of change

```text
PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0
TRACKED src/** MUTATIONS=0
TRACKED tools/bootstrap/** MUTATIONS=0
NEW POLYC PARSER AUTHORITIES=0
NEW PYTHON=0
NEW DEPENDENCIES=0
HISTORICAL_ARTIFACT_REWRITES=0
```

The only tracked additions outside the evidence tree are one new
PolyC verifier (`tools/quality/parser-surface-recon07-recompute.HC`)
and two additive Makefile targets for it.

---

## 13. The next step

```text
NEXT_ACT        = ACT-POLYC-SELFHOST-PARSER-SLICE08
NEXT_ACT_STATUS = READY_TO_DRAFT
NEXT_TARGET     = SUB-002
SLICE08_IMPLEMENTED=NO
```

**SLICE08 is NOT authorized to execute or close.**  It needs its own
ACT, its own entry identity and its own entry check.  If SLICE08's
implementation of SUB-002 fails its own gates, the canonical order
makes **SUB-004** the next candidate to test; it is ELIGIBLE, but its
causal feasibility is NOT claimed by this ACT.

---

## 14. The backlog this ACT did NOT touch

Explicitly out of scope, and untouched: the SLICE06 stale CMake
`--install-dir` producer wiring; the factory-halt-classification
inline-assembly tool-build failure; the unlanded F-POLYC-TOOLS
checker; the 12 F-NO-PYTHON violations; the 15 LEXER07 broad-corpus
failure identities; the 67 cross-target missing-prefix cases; the
shared `/tmp/holyc-asm.s` assembly-temp collision; ARM64 stage-0
portability; and the Dafny proof stability, stage identity and
optional external provers.

Each needs its own bounded ACT with its own baseline and acceptance
evidence.
