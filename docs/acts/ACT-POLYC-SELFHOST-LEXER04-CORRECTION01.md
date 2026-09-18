# ACT-POLYC-SELFHOST-LEXER04-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT
Status: OPEN
Authored-At: 2026-09-18
Entry-Head: 54e1940

**Title:** Requalify the preserved LEXER04 `lexLink/#link` migration under proper prior authorization, repair the PolyC-native verification blocker, prove a genuine G0/G1/G2/G3 production semantic seam, replay the original AC01..AC32 contract, and close the FALSE_GREEN lineage without rewriting historical evidence.

## 0. Mission (frozen)

The underlying LEXER04 migration contains useful engineering that SHALL be preserved:

```
BootstrapLinkDirective             = EXISTS
LEXER09_DIRECT_DIFFERENTIAL        = 23/23 PASS
LEXER09_STAGE0_STAGE1_SEAM         = PASS
LEXER09_COMPONENT_FIXED_POINT      = PASS
G3_DETERMINISM                     = PASS
FIXEDPOINT_NEGATIVE_CONTROL        = PASS
```

The closure nevertheless contains six mechanically confirmed defects:

```
D1 NO_PRIOR_C0_AUTH
D2 C3_MUTATED_IMPLEMENTATION
D3 AUTHORIZED_AC_CONTRACT_REPLACED
D4 F_POLYC_TOOLS_VIOLATED
D5 G0_G1_G2_G3_PRODUCTION_SEAM_MISSING
D6 GIT_DIFF_CHECK_FAILED
```

This ACT SHALL repair those defects **without rewriting closed LEXER04 evidence or pretending the historical lineage was authorized**.

```
ORIGINAL_LEXER04_CLOSE = FALSE_GREEN                # remains historical truth
LEXER04_ENGINEERING_REQUALIFIED_UNDER_C01 = YES
LEXER04_EFFECTIVE_SEMANTIC_QUALIFICATION  = TRUE_GREEN
ACT-POLYC-SELFHOST-LEXER04-CORRECTION01    = PASS_TRUE_GREEN
```

## 1. Historical truth that SHALL NOT be rewritten

```
LEXER04_C1 = a09104d
LEXER04_C2 = ffee58b
LEXER04_C3 = 388fdc2
LEXER04_C4 = b5ccba3
RECLASSIFICATION = 54e1940
```

The original LEXER04 lineage lacked a committed C0 authorization artifact. Therefore this ACT SHALL NOT claim `ORIGINAL_LEXER04_AUTHORIZATION_LINEAGE = PASS`. It SHALL instead record `ORIGINAL_LEXER04_AUTHORIZATION_LINEAGE = FAIL` and `CORRECTION01_AUTHORIZATION_LINEAGE = PASS`.

The original C1/C2/C3/C4 commits remain append-only history.

## 2. F14 immutable predecessor surfaces

This ACT SHALL NOT modify:

```
evidence/ACT-POLYC-SELFHOST-LEXER04/c1/**
evidence/ACT-POLYC-SELFHOST-LEXER04/c2/**
evidence/ACT-POLYC-SELFHOST-LEXER04/c3/**
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04.md
evidence/ACT-POLYC-SELFHOST-SURFACE-RECON02/**
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-SURFACE-RECON02.md
```

All correction authority SHALL live in:

```
docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION01.md         (this document)
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION01.md
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION01/**
```

## 3. C0 AUTH (this commit)

Before C1 evidence or implementation changes:

```sh
git status --porcelain=v1
git rev-parse HEAD
git branch --show-current
```

Required:

```
ENTRY_HEAD=54e1940
BRANCH=main
WORKTREE_CLEAN_AT_AUTH=YES
```

No implementation mutation is permitted before C0 AUTH. Phase discipline per §36.

## 4. C1 RED — reproduce all six predecessor defects

`evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION01/c1/`

C1 is recon/evidence only. No repair yet.

### D1 — missing original authorization artifact

```sh
git ls-tree -r b5ccba3 -- docs/acts/ACT-POLYC-SELFHOST-LEXER04.md
git log --oneline b7c719b..b5ccba3
```

Required: `D1_NO_ORIGINAL_C0_AUTH=CONFIRMED`

### D2 — C3 implementation mutation

```sh
git show 388fdc2 -- src/lexer.c
```

Required: `D2_C3_MUTATED_IMPLEMENTATION=CONFIRMED`. Record the TK_STR repair; do not undo it merely to recreate the bug.

### D3 — substituted AC contract

Compare committed `evidence/ACT-POLYC-SELFHOST-LEXER04/c3/mandatory-ac-status.tsv` AC01..AC32 to the operator-issued authorization contract frozen in §31.

Required: `D3_AUTHORIZED_AC_CONTRACT_REPLACED=CONFIRMED`

### D4 — F-POLYC-TOOLS violation

Inventory `tools/quality/lexer09-fixedpoint-verify.c` and `tools/quality/sha256-tool.c` for language, LOC, semantic responsibility, oracle-only, authoritative-verdict-producing.

Required: `D4_F_POLYC_TOOLS_VIOLATION=CONFIRMED`

### D5 — missing four-generation semantic seam

Required: `D5_4GEN_SEMANTIC_SEAM_MISSING=CONFIRMED`

### D6 — patch hygiene

```sh
git diff --check b7c719b..54e1940
```

Required: `D6_PATCH_HYGIENE_DEFECT=CONFIRMED`, `D6_OFFENDING_PATH=tools/bootstrap/selfhost-lexer-link.HC`

## 5. C1 root-cause investigation — PolyC verifier blocker

The correction SHALL NOT assume "ROTR bug" merely because the predecessor HANDOFF says so. Mechanically reduce the failure.

Class:

```
A. STATIC_FUNCTION_VISIBILITY_CODEGEN
B. JIT_SYMBOL_EXPORT
C. PARTIAL_LIBTOS_ABI
D. UNRESOLVED_RUNTIME_PRIMITIVE
E. MULTIPLE_DEF_COLLISION
F. OTHER
```

Required: `ROTR_ROOT_CAUSE_CLASS=<one>`, `ROTR_ROOT_CAUSE_FILE=...`, `ROTR_ROOT_CAUSE_SYMBOL=...`

## 6. Toolchain repair authorization gate

C2A compiler repair is authorized only if all are true:

```
ROTR_ROOT_CAUSE_REPRODUCED=YES
ROOT_CAUSE_IS_IN_HCC=YES
EXACT_PRODUCTION_FILE_SET_IDENTIFIED=YES
SEMANTIC_SCOPE_BOUNDED=YES
NO_LANGUAGE_SEMANTIC_CHANGE_REQUIRED=YES
```

Otherwise `HALT_TOOLCHAIN_PREREQUISITE_REQUIRED` and recommend a dedicated enabling ACT. **No F-POLYC-TOOLS waiver is authorized.**

## 7. C1 dynamic compiler-repair scope freeze

Default limits:

```
ROTR_REPAIR_MAX_FILES <= 2 production implementation files
NO lexer/parser semantic files
NO new dependency
NO ABI surface change unless purely internal compiler/JIT linkage metadata
```

Otherwise `HALT_TOOLCHAIN_SCOPE_EXPANSION_REQUIRED`.

## 8. Preserve known-good Lexer04 subject

May receive ONLY the EOF whitespace repair in `tools/bootstrap/selfhost-lexer-link.HC`. `src/lexer.c` may change only if fresh C01 evidence falsifies the preserved TK_STR correction.

Baseline to conserve:

```
DIRECT_DIFFERENTIAL=23/23 PASS
STAGE0_STAGE1_PRODUCTION_SEAM=PASS
COMPONENT_4GEN_FIXED_POINT=PASS
```

## 9. C2A — repair hcc static/internal symbol handling

Only if §6 authorizes it.

After repair:

```
STATIC_HELPER_COMPILES=YES
STATIC_HELPER_LINKS=YES
STATIC_HELPER_NOT_EXPORTED_AS_FORBIDDEN_GLOBAL=YES
ROTR_REPRO_BEFORE=FAIL
ROTR_REPRO_AFTER=PASS
```

Add focused regression test covering:

```
static U32 ROTR(...)
static helper used by another local function
two translation units with same static helper name
```

## 10. C2A negative controls

```
NC-A  same static name in two translation units — coexist without global collision
NC-B  genuine external function — remains externally visible
NC-C  unresolved external — remains unresolved
```

## 11. C2B — restore PolyC-native verification authority

Required final authoritative tooling:

```
tools/quality/lexer09-fixedpoint-verify.HC
```

plus a PolyC SHA-256 implementation/tool (prefer existing PolyC SHA-256 lineage if compatible). No gratuitous abstraction.

## 12. SHA-256 self-test

5 vectors: empty, "abc", 55-byte, 56-byte, 57-byte. Required: `SHA256_SELFTEST=5/5_PASS`

## 13. Remove C verification authority

Final tree must not use `tools/quality/lexer09-fixedpoint-verify.c` or `tools/quality/sha256-tool.c` as authoritative fixed-point/SHA verdict producers. Preferred disposition: `DELETE`. If retained for comparative testing, must be `NON_AUTHORITATIVE`, `NOT_CALLED_BY_CANONICAL_TARGET`, `NOT_USED_BY_CLOSURE_EVIDENCE`.

Required:

```
AUTHORITATIVE_FIXEDPOINT_VERIFIER_LANGUAGE=POLYC
AUTHORITATIVE_SHA256_LANGUAGE=POLYC
SUBSTANTIVE_C_VERIFICATION_AUTHORITY=0
```

## 14. F-POLYC-TOOLS terminal predicate

```
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
SUBSTANTIVE_C_VERIFICATION_AUTHORITY=0
SHELL_LOC_GATE=PASS
```

C oracle/reference implementations remain allowed only where they are actual preserved semantic oracles:

```
tools/quality/lexer09-link-oracle.c
tools/quality/lexer09-link-oracle-impl.c
tools/quality/lexer09-direct-differential.c
tools/quality/lexer09-real-seam-runner.c
```

If Factory doctrine classifies any of those as substantive forbidden tooling, HALT rather than silently relabel it.

## 15. C2B — repair patch hygiene

Remove the trailing blank line at EOF in `tools/bootstrap/selfhost-lexer-link.HC`. No semantic changes.

Required: `SUBJECT_SEMANTIC_DIFF_FROM_54e1940=NONE_EXCEPT_WHITESPACE` unless fresh evidence separately authorizes a semantic fix.

## 16. Genuine four-generation production semantic seam

```
G0 = legacy production #link path
G1 = production lexer + G0-produced BootstrapLinkDirective
G2 = production lexer + G1-produced BootstrapLinkDirective
G3 = production lexer + G2-produced BootstrapLinkDirective
```

Stage2/stage3 MUST be real binaries/executions. They may not be inferred from object equality.

## 17. Production seam fixture corpus

Reuse the existing ten real-production seam cases unless C1 discovers a missing valid behavior class:

```
L01 single quoted path
L02 single angle name
L03 mixed multiple links
L04 angle duplicate
L05 quoted duplicate
L06 back-to-back directives
L07 complex angle name
L08 relative quoted path
L09 link-only source
L10 no-directive conservation case
```

## 18. Canonical semantic serializer

Per stage:

```
CASE
TOKENS
LINENO
CURSOR_AT_EOF
LINK_LIBS_COUNT
LINK_LIB[i]
SHARED_OBJECT_FILES_COUNT
SHARED_OBJECT_FILE[i]
ERROR_CLASS
CASE_END
```

Do NOT serialize raw addresses, arena pointers, allocation order, FIRST_I64 pointer-derived values, build timestamps, or host-specific pointer identity. `BUILD_LABEL` may be emitted separately but excluded from semantic comparison.

## 19. Four-generation seam equality

Pairwise comparison of `c3-production-seam-g{0,1,2,3}.txt`:

```
G0_G1_SEMANTIC_EQUAL=YES
G0_G2_SEMANTIC_EQUAL=YES
G0_G3_SEMANTIC_EQUAL=YES
G1_G2_SEMANTIC_EQUAL=YES
G1_G3_SEMANTIC_EQUAL=YES
G2_G3_SEMANTIC_EQUAL=YES
LEXER09_4_STAGE_SEMANTIC_SEAM=PASS
```

## 20. Four-generation seam negative control

```
pristine 4-way seam -> PASS
mutated semantic output -> comparator nonzero
semantic mismatch identified -> YES
pristine inputs -> PASS
LEXER09_4_STAGE_SEAM_NEGATIVE_CONTROL=PASS
```

## 21. Re-prove direct differential

```
DIRECT_DIFFERENTIAL_TOTAL=23
DIRECT_DIFFERENTIAL_PASS=23
DIRECT_DIFFERENTIAL_FAIL=0
STATUS=PASS
```

## 22. Re-prove stage0↔stage1 production seam

```
LEXER09_PRODUCTION_SEAM_STAGE0_VS_STAGE1=PASS
```

## 23. Re-prove component object fixed point using PolyC-native verifier

Compile `tools/bootstrap/selfhost-lexer-link.HC` with G0=./hcc, G1=./build/hcc-bootstrap02, G2=./build/hcc-bootstrap03, G3=./build/hcc-bootstrap04. Required: all six pairs byte-equal; `OBJECT_SIZE_UNIQUE_COUNT=1`, `OBJECT_SHA256_UNIQUE_COUNT=1`, `LEXER09_COMPONENT_OBJECT_FIXED_POINT=PASS`. Authoritative verifier must be PolyC.

## 24. Determinism and mutation controls

```
G3_REPEAT_BYTE_EQUAL=YES
PRISTINE_VERIFIER_RC=0
MUTATED_VERIFIER_RC_NONZERO=YES
BYTE_MISMATCH_DETECTED=YES
PRISTINE_RECHECK_RC=0
LEXER09_FIXEDPOINT_NEGATIVE_CONTROL=PASS
```

## 25. Conservation — prior lexer lineages

```
LEXER01_DIRECT_DIFFERENTIAL=47/47 PASS
LEXER02_DIRECT_DIFFERENTIAL=89/89 PASS
LEXER07_PRODUCTION_SEAM_4_STAGES=PASS
LEXER03_DIRECT_DIFFERENTIAL=45/45 PASS
LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1=PASS
LEXER03_COMPONENT_OBJECT_FIXED_POINT=PASS
```

## 26. LEXER08 verifier secondary confirmation

After C2A:

```sh
make lexer08-trivia-fixedpoint
```

Required: `LEXER08_TRIVIA_FIXEDPOINT=PASS`. Distinct unrelated libtos defect → `HALT_SECOND_DISTINCT_TOOLCHAIN_DEFECT`.

## 27. Broad corpus conservation

```
LEXER08_BROAD_CORPUS_4_STAGE=PASS
LEXER09_LINK_BROAD_CORPUS_4_STAGE=PASS
```

## 28. Actual patch hygiene

```sh
git diff --check 54e1940..<CANDIDATE_CLOSE>          # CORRECTION_RANGE_DIFF_CHECK=PASS
git diff --check b7c719b..<CANDIDATE_CLOSE>          # EFFECTIVE_LEXER04_RANGE_DIFF_CHECK=PASS
```

## 29. F-NO-PYTHON

```
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_VIOLATIONS=0
```

## 30. Closed evidence immutability

```sh
git diff 54e1940..<CANDIDATE_CLOSE> -- \
    evidence/ACT-POLYC-SELFHOST-LEXER04/c1 \
    evidence/ACT-POLYC-SELFHOST-LEXER04/c2 \
    evidence/ACT-POLYC-SELFHOST-LEXER04/c3 \
    docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04.md
```

Required: empty. `CLOSED_LEXER04_EVIDENCE_DELTA=0`, `CLOSED_LEXER04_HANDOFF_DELTA=0`.

## 31. Recovered original LEXER04 AC contract (PREV-AC01..32)

All PREV-AC01..PREV-AC32 are mandatory. No renumbering. No semantic substitution. No PARTIAL/DEFERRED.

```
PREV-AC01  WORKTREE_CLEAN_AT_ENTRY=YES
PREV-AC02  SURFACE_RECON02=PASS_TRUE_GREEN
           SELECTED_TARGET=INV.LEXER.LINK
           SELECTED_ATOMIC_SLICE=lexLink/#link
PREV-AC03  LEXER04_RED_REPRODUCED=YES
PREV-AC04  SLICE_LEVERAGE_PROVEN=YES
PREV-AC05  UNKNOWN_STATE_EFFECTS=0
PREV-AC06  FIXTURE_TOTAL=<frozen total>
           FIXTURE_CLASS_TOTAL=<frozen class total>
PREV-AC07  LEXCORE_MUTATION=0
           PREPROCESSOR_OTHER_THAN_LINK_MUTATION=0
           FORBIDDEN_SUBSYSTEM_DELTA=0
PREV-AC08  selfhost-lexer-link.HC=EXISTS
           BootstrapLinkDirective=EXISTS
PREV-AC09  POLYC_PRODUCTION_DELEGATION_PRESENT=YES
PREV-AC10  LEXER09_DIRECT_DIFFERENTIAL_FAIL=0
           STATUS=PASS
PREV-AC11  LEXER09_PRODUCTION_SEAM=PASS
PREV-AC12  LEXER09_4_STAGE_SEMANTIC_SEAM=PASS
PREV-AC13  G0_COMPONENT_COMPILE=PASS
PREV-AC14  G1_COMPONENT_COMPILE=PASS
PREV-AC15  G2_COMPONENT_COMPILE=PASS
PREV-AC16  G3_COMPONENT_COMPILE=PASS
PREV-AC17  LEXER09_COMPONENT_OBJECT_FIXED_POINT=PASS
PREV-AC18  PROVENANCE_ROWS=4
           SOURCE_SHA_UNIQUE_COUNT=1
PREV-AC19  G3_REPEAT_BYTE_EQUAL=YES
PREV-AC20  LEXER09_NEGATIVE_CONTROL=PASS
PREV-AC21  47/47 PASS                            (LEXER01)
PREV-AC22  89/89 PASS                            (LEXER02)
PREV-AC23  45/45 PASS                            (LEXER03)
           LEXER03_COMPONENT_OBJECT_FIXED_POINT=PASS
PREV-AC24  BROAD_CORPUS_CONSERVATION=PASS
PREV-AC25  NEW_PYTHON_SOURCES=0
           NEW_PYTHON_INVOCATIONS=0
PREV-AC26  NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
           SHELL_LOC_GATE=PASS
           (predecessor C substitutions retired as authoritative tooling)
PREV-AC27  gate-fast=PASS
           factory-append-only-test=PASS
           + all authoritative current gates
PREV-AC28  CLOSED_PREDECESSOR_EVIDENCE_DELTA=0
PREV-AC29  git diff --check=clean
PREV-AC30  WORKTREE_CLEAN_AT_CLOSE=YES
PREV-AC31  APPEND_ONLY_HISTORY=TRUE
PREV-AC32  C4_C3_EVIDENCE_DELTA=0
```

## 32. Correction-specific acceptance criteria (RC01..RC18)

```
RC01 C0_AUTH_PRECEDES_C1=YES; C0_AUTH_PRECEDES_IMPLEMENTATION=YES
RC02 D1..D6 all CONFIRMED
RC03 ORIGINAL_LEXER04_CLOSE=FALSE_GREEN; ORIGINAL_AUTHORIZATION_LINEAGE=FAIL
RC04 ROTR_ROOT_CAUSE_CLASS != UNKNOWN
RC05 ROTR_REPRO_AFTER=PASS
RC06 AUTHORITATIVE_FIXEDPOINT_VERIFIER_LANGUAGE=POLYC
    AUTHORITATIVE_SHA256_LANGUAGE=POLYC
RC07 SUBSTANTIVE_C_VERIFICATION_AUTHORITY=0
RC08 SHA256_SELFTEST 5/5 PASS
RC09 LEXER09_4_STAGE_SEMANTIC_SEAM=PASS
RC10 LEXER09_4_STAGE_SEAM_NEGATIVE_CONTROL=PASS
RC11 CORRECTION_RANGE_DIFF_CHECK=PASS
    EFFECTIVE_LEXER04_RANGE_DIFF_CHECK=PASS
RC12 PREV_AC_TOTAL=32; PREV_AC_PASS=32; PREV_AC_FAIL=0
RC13 CLOSED_LEXER04_EVIDENCE_DELTA=0
    CLOSED_LEXER04_HANDOFF_DELTA=0
RC14 LEXER08_TOOLCHAIN_CONFIRMATION=PASS
RC15 C4_CORRECTION_C3_DELTA=0
RC16 FACTORY_GATES=PASS; F_NO_PYTHON=PASS; F_POLYC_TOOLS=PASS
RC17 WORKTREE_CLEAN=TRUE; APPEND_ONLY_HISTORY=TRUE
RC18 ORIGINAL_LEXER04_PASS_TRUE_GREEN=FALSE
     CORRECTION01_PASS_TRUE_GREEN=TRUE
     LEXER04_EFFECTIVE_ENGINEERING_QUALIFICATION=TRUE_GREEN
```

## 33. Mandatory status tables

Two separate tables; no row may repurpose an ID:

```
evidence/.../CORRECTION01/c3/predecessor-ac-status.tsv       AC01..AC32  32 rows
evidence/.../CORRECTION01/c3/mandatory-ac-status.tsv         RC01..RC18  18 rows
```

## 34. C3 evidence namespace

```
evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION01/c3/
```

Required artifacts: `c3-entry-identity.txt`, `c3-rotr-regression.txt`, `c3-rotr-symbol-visibility.txt`, `c3-sha256-selftest.txt`, `c3-polyc-verifier-build.txt`, `c3-polyc-authority-audit.txt`, `c3-direct-differential.txt`, `c3-production-seam-g{0,1,2,3}.txt`, `c3-production-seam-4way.txt`, `c3-production-seam-negative-control.txt`, `c3-fixedpoint-g{0,1,2,3}.txt`, `c3-fixedpoint-provenance.tsv`, `c3-byte-equality.txt`, `c3-determinism.txt`, `c3-fixedpoint-negative-control.txt`, `c3-lexer01-conservation.txt`, `c3-lexer02-conservation.txt`, `c3-lexer03-conservation.txt`, `c3-lexer08-toolchain-confirmation.txt`, `c3-broad-corpus.txt`, `c3-f-no-python.txt`, `c3-f-polyc-tools.txt`, `c3-factory-gates.txt`, `c3-closed-evidence-immutability.txt`, `c3-patch-hygiene.txt`, `predecessor-ac-status.tsv`, `mandatory-ac-status.tsv`, `c3-required-result.txt`.

## 35. Required-result ledger

C3 must mechanically emit at least the KEY=VALUE ledger defined in the operator-issued authorization (ACT §35): ACT, ENTRY_FALSE_GREEN_COMMIT, D1..D6, ROTR_*, AUTHORITATIVE_*, SHA256_SELFTEST, LEXER09_*, LEXER09_4_STAGE_*, LEXER09_COMPONENT_OBJECT_FIXED_POINT, conservation, F_NO_PYTHON, F_POLYC_TOOLS, PREV_AC_*, RC_*, CORRECTION_RANGE_DIFF_CHECK, EFFECTIVE_LEXER04_RANGE_DIFF_CHECK, CLOSED_*, FACTORY_GATES, WORKTREE_CLEAN, APPEND_ONLY_HISTORY, ORIGINAL_LEXER04_CLOSE, LEXER04_CORRECTION01, LEXER04_EFFECTIVE_ENGINEERING_QUALIFICATION.

## 36. Phase discipline

C0 AUTH (this document) → C1 RED/ROOT-CAUSE → C2A TOOLCHAIN FIX (only if §6) → C2B LEXER04 CORRECTION → C3 EVIDENCE (HALT on defect, no rewrite) → C4 CLOSE (new HANDOFF + ROADMAP only).

## 37. Commit topology

Max 6 commits: C0, C1, C2A, C2B, C3, C4. C2A may be skipped if root cause already fixed; do not manufacture an empty C2A commit. More than six → `HALT_COMMIT_BUDGET_EXHAUSTED`. No amend. No rebase. No force-push. No reset+recommit.

## 38. HALT taxonomy

HALT tokens per operator-issued authorization §38 (HALT_ENTRY_DIRTY, HALT_RED_NOT_REPRODUCIBLE, HALT_TOOLCHAIN_ROOT_CAUSE_UNKNOWN, HALT_TOOLCHAIN_PREREQUISITE_REQUIRED, HALT_TOOLCHAIN_SCOPE_EXPANSION_REQUIRED, HALT_STATIC_VISIBILITY_REGRESSION, HALT_SECOND_DISTINCT_TOOLCHAIN_DEFECT, HALT_POLYC_VERIFIER_UNAVAILABLE, HALT_F_POLYC_TOOLS_NOT_REPAIRED, HALT_DIRECT_DIFFERENTIAL_MISMATCH, HALT_STAGE0_STAGE1_SEAM_MISMATCH, HALT_4_STAGE_SEMANTIC_SEAM_MISMATCH, HALT_4_STAGE_SEAM_NEGATIVE_CONTROL_FAILED, HALT_FIXEDPOINT_BYTE_DIVERGENCE, HALT_FIXEDPOINT_NEGATIVE_CONTROL_FAILED, HALT_PREDECESSOR_REGRESSION, HALT_BROAD_CORPUS_REGRESSION, HALT_F_NO_PYTHON_REGRESSION, HALT_PATCH_HYGIENE, HALT_PREDECESSOR_EVIDENCE_MUTATED, HALT_ORIGINAL_AC_NOT_GREEN, HALT_CORRECTION_AC_NOT_GREEN, HALT_C3_MUTATED_AFTER_FREEZE, HALT_COMMIT_BUDGET_EXHAUSTED).

## 39. C4 closure predicate

PASS_TRUE_GREEN for CORRECTION01 only when the full predicate set in operator-issued authorization §39 is green.

## 40. C4 HANDOFF

`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION01.md` shall explicitly separate:

```
HISTORICAL ORIGINAL LEXER04
CORRECTION01 REQUALIFICATION
TOOLCHAIN REPAIR
SEMANTIC PROOFS
RESIDUE
NEXT
```

It SHALL state:

```
ORIGINAL LEXER04 b5ccba3 remains FALSE_GREEN historically.

CORRECTION01 does not retroactively authorize that lineage.

The preserved lexLink/#link implementation has been requalified
under a properly authorized correction lineage.
```

## 41. Residue policy

May remain residue only if unrelated to this ACT's mandatory predicates:

```
test-prefix-install unrelated historical failure
non-semantic L10 pointer diagnostics outside canonical serializer
stronger per-generation broad-corpus differential
cross-architecture fixed-point qualification
future self-host surface recon
```

May NOT remain residue at PASS:

```
ROTR/static-symbol blocker
PolyC verifier availability
F-POLYC-TOOLS violation
4-generation production seam
git diff --check
original AC01..32 replay
C3 phase purity
```

## 42. NEXT

Only after CORRECTION01 closes PASS_TRUE_GREEN:

```
NEXT = ACT-POLYC-SELFHOST-SURFACE-RECON03
```

Freshly inventory the self-host frontier after the corrected LEXER04 qualification. Do not auto-select LEXER05.

## 43. Execution instruction

Start with C0 AUTH. Then C1 answers two real technical questions before any repair:

1. What exact hcc/JIT/linkage defect makes a PolyC static ROTR helper behave as an externally-visible/global symbol?
2. Can G0, G1, G2 and G3 each run the real production #link path and serialize exactly the same semantic state?

If the toolchain defect is bounded, fix it and restore PolyC-native verification. If it is not bounded, HALT into a prerequisite ACT. Do not weaken F-POLYC-TOOLS.





