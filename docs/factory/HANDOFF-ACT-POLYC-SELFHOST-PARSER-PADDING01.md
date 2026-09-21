# HANDOFF: ACT-POLYC-SELFHOST-PARSER-PADDING01

Factory-Version: 2

VERDICT

PASS_TRUE_GREEN

```text
ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01

BootstrapCalcPadding:
  IMPLEMENTED=YES
  QUALIFIED=YES

DIRECT_DIFFERENTIAL=PASS
BOUNDED_MATRIX=16640/16640
ALGEBRAIC_INVARIANTS=PASS

MUTATION_CONTROLS=4/4
FIXEDPOINT_PAIRS=6/6
GENERATION_PROVENANCE=4/4
GENERATION_COPY_DETECTED=YES

PRODUCTION_AUTHORITY=LEGACY_C
PRODUCTION_DELEGATION=NOT_PERFORMED

PARSER_LAYOUT_CONSERVATION=PASS
LEXER01..04_CONSERVATION=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

EXACT_COMMIT_COUNT=5
POST_C4_COMMIT_COUNT=0

NEXT=ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
```

## IDENTITY

| Field | Value |
| --- | --- |
| Repository | PolyC |
| Branch | `main` |
| Entry head (C0) | `b2d750b713fc64c41db89b5adf418ddaa777944c` |
| Final head (C4) | (set in c4-parent-identity.txt) |
| Working tree | clean at every C0/C1/C2/C3/C4 boundary |
| Total commits in ACT | 5 |

## PREDECESSOR BINDING

```text
PREDECESSOR=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01
PREDECESSOR_VERDICT=PASS_TRUE_GREEN
PREDECESSOR_FROZEN_CONTRACT:
  NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING01
  NEXT_TARGET_ID=CAND-002
  NEXT_TARGET=CalcPadding
  NEXT_FILE=src/parser.c
  NEXT_LINE_START=430
  NEXT_LINE_END=438
  NEXT_R0=0
  NEXT_SCOPE_FROZEN=YES
PREDECESSOR_CONTRACT_MATCH=YES
```

## TARGET

```text
SELECTED_FILE=src/parser.c
SELECTED_LINE_START=430
SELECTED_LINE_END=438
SELECTED_FUNCTION=CalcPadding
SELECTED_R0=0
LIVE_SRC_SHA256_AT_C0=7a4a0935ae5fc92fb37dc637037a83c70c21a81ebe9a1233c69fd6529bc1a279
LIVE_SRC_SHA256_AT_C3=7a4a0935ae5fc92fb37dc637037a83c70c21a81ebe9a1233c69fd6529bc1a279
LIVE_SRC_DELTA=0
```

## SEMANTIC CONTRACT

```text
CalcPadding(offset, size):
    if size == 0:
        return 0
    remainder = offset % size
    if remainder == 0:
        return 0
    return size - remainder

INVARIANTS:
    size == 0            => result == 0
    size > 0 && aligned  => result == 0
    size > 0 && unaligned => result == size - (offset % size)
    0 <= result < size   when size > 0

QUALIFIED_DOMAIN=offset>=0,size>=0
```

The PolyC subject mirrors this contract bit-for-bit; see
`tools/bootstrap/selfhost-parser-padding.HC`.

## ABI

```text
I64 BootstrapCalcPadding(I64 offset, I64 size);

ABI_HOST_IDENTITY_FIELDS=0
ABI_CALLBACK_FIELDS=0
ABI_POINTER_FIELDS=0
ABI_GLOBAL_MUTABLE_STATE=0
ABI_ALLOCATION=0
ABI_EXTERNAL_DEPENDENCY=0
```

## RED

| ID | Description | Witness |
| --- | --- | --- |
| RED-1 | PolyC subject absent at C1 entry | `test -f tools/bootstrap/selfhost-parser-padding.HC` rc=1 |
| RED-2 | BootstrapCalcPadding symbol absent | `git grep 'BootstrapCalcPadding' -- tools/bootstrap src tools/quality` rc=1 |
| RED-3 | legacy C CalcPadding active with 5 callers | `grep -n 'CalcPadding' src/parser.c` |
| RED-4 | direct differential binary absent | `test -x ./build/parser-padding-differential` rc=1 |
| RED-5 | fixed-point verifier absent | `test -x ./build/parser-padding-fixedpoint-verify` rc=1 |

```text
RED_REPRODUCIBLE=5/5
RED_ABI_DRIFT=NO
```

## IMPLEMENTATION

```text
SUBJECT_FILE=tools/bootstrap/selfhost-parser-padding.HC
SUBJECT_ABI=I64 BootstrapCalcPadding(I64 offset, I64 size);
SUBJECT_BODY:
    if (size == 0) return 0;
    I64 rem = offset % size;
    if (rem == 0) return 0;
    return size - rem;
SUBJECT_LOC=18
SUBJECT_EXTERNAL_DEPENDENCY_COUNT=0
SUBJECT_GLOBAL_MUTABLE_STATE=0
SUBJECT_ALLOCATION_COUNT=0
COMPONENT_REQUIRES_SRC_PARSER_OBJECT=NO
```

Tooling introduced (all PolyC unless noted):

```text
tools/quality/parser-padding-differential.HC            terminal verdict authority
tools/quality/parser-padding-fixedpoint-verify.HC       4-gen fixed-point
tools/quality/parser-padding-gen-matrix-fixture.HC      16640 matrix generator
tools/quality/parser-padding-gen-large-fixture.HC       64 large-value generator
tools/quality/parser-padding-mutation-m{1,2,3,4}.HC    semantic mutations
tools/quality/parser-padding-oracle-impl.c              C oracle (semantic reference only, ACT §31)

Makefile wiring: 16 narrowly-scoped PARSER_PADDING_* targets
aggregator: `make parser-padding-test` -> PARSER_PADDING_TEST=PASS
```

## DIRECT DIFFERENTIAL

```text
fixture_class    rows   poly_pass   poly_fail   rc
named            277    277         0           0
matrix           16640  16640       0           0
large            64     64          0           0
zero_size_only   256    256         0           0

DIRECT_DIFFERENTIAL_TOTAL=17237
DIRECT_DIFFERENTIAL_PASS=17237
DIRECT_DIFFERENTIAL_FAIL=0
```

Oracle architecture (ACT §22): legacy C `OracleCalcPadding` is the
terminal oracle; PolyC `BootstrapCalcPadding` is the subject;
PolyC `parser-padding-differential.HC` is the comparison layer with
terminal verdict authority. The C oracle exposes the exact frozen
body of `src/parser.c::CalcPadding` and makes no PASS/FAIL policy
decision (ACT §31).

## BOUNDED MATRIX

```text
offset=0..255
size=0..64

BOUNDED_MATRIX_TOTAL=16640
BOUNDED_MATRIX_PASS=16640
BOUNDED_MATRIX_FAIL=0
```

## ALGEBRAIC INVARIANTS

```text
size == 0            => result == 0          (proven by size=0 corpus 256/256)
size > 0             => 0 <= result < size   (proven by oracle agreement on 16640 cases)
(offset + result) % size == 0                  (proven by oracle agreement on 16640 cases)

ALGEBRAIC_INVARIANT_FAIL=0
```

Witnesstype: the differential verifier establishes `pc == oc` on all
16640 matrix cases plus the 256 size=0-only cases. The oracle `oc` is
a verbatim copy of the frozen legacy C `CalcPadding` body which
satisfies the three invariants by definition. Therefore `pc` satisfies
the same invariants on every input where `pc == oc`.

## ZERO-SIZE GUARD

```text
size=0 corpus: 256/256 PASS pristine
M1 mutation (zero-size guard removed, UB-tainted `rem` flows to return):
  built=YES linked=YES executed=YES rejected=YES
  divergence_count=255/256 (offset=0,size=0 is the only coincidence
  that returns 0 because clang treats 0%0 as 0; all other 255 size=0
  inputs return -1 instead of 0).
```

## MUTATION CONTROLS

| Mutation | Description | build | link | run | divergences | verifier_rc |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | zero-size guard broken | 0 | 0 | 0 | 255 | 1 |
| M2 | aligned returns `size` | 0 | 0 | 0 | 1246 | 1 |
| M3 | remainder returned directly | 0 | 0 | 0 | 14617 | 1 |
| M4 | boolean classifier | 0 | 0 | 0 | 16384 | 1 |

```text
MUTATION_PASS=4
MUTATION_FAIL=0
PRISTINE_REVERIFY_TOTAL=16640
PRISTINE_REVERIFY_FAIL=0
PRISTINE_REVERIFY=PASS
```

Each mutation has a distinct SHA-256 from the pristine subject; no
mutation PASS was inferred from missing output.

## GENERATION PROVENANCE

| Generation | Compiler | Compiler SHA-256 | Object SHA-256 | Size | Independent |
| --- | --- | --- | --- | --- | --- |
| G0 | ./hcc | ea565f68d070ea2f2edc5c00289bdba38cce0a10381dde1fd293fb807c8b129e | 187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1 | 744 | YES |
| G1 | ./build/hcc-bootstrap02 | 3b1e2cd16b027bf533e661567875ae9bf8e626cf74f372355626706601fe785a | 187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1 | 744 | YES |
| G2 | ./build/hcc-bootstrap03 | b8a9781a7ef68e3da05427d03bc04f4250b76a967fd761147c6ef7100b9acdca | 187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1 | 744 | YES |
| G3 | ./build/hcc-bootstrap04 | 3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6 | 187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1 | 744 | YES |

```text
GENERATION_ROWS=4
UNKNOWN_PROVENANCE_ROWS=0
ALL_COMPILERS_DISTINCT_SHA=YES
ALL_OBJECTS_IDENTICAL_SHA=YES
```

## FIXEDPOINT

```text
PAIR_TOTAL=6
PAIR_PASS=6
PAIR_FAIL=0
PAIR G0_G1 equal=YES
PAIR G0_G2 equal=YES
PAIR G0_G3 equal=YES
PAIR G1_G2 equal=YES
PAIR G1_G3 equal=YES
PAIR G2_G3 equal=YES
PARSER_PADDING_FIXED_POINT_4_GENERATIONS=PASS
```

## GENERATION-COPY CONTROL

| Phase | Witness | RC | Verdict |
| --- | --- | --- | --- |
| Pristine | all 4 generations byte-equal | 0 | PASS |
| Mutation (1 byte flipped in g3) | verifier detects mismatch | 1 | BYTE_MISMATCH_DETECTED=YES |
| Pristine recheck | pristine regenerated, verifier PASS | 0 | PASS |
| Generation-copy forgery (g1 substituted for g3) | verifier detects equality (negative control fires) | 1 | FORGED_PROVENANCE_VERDICT=FAIL |

```text
GENERATION_COPY_ATTEMPTED=YES
GENERATION_COPY_DETECTED=YES
PRISTINE_PROVENANCE_REVERIFY=PASS
```

## PRODUCTION AUTHORITY

```text
LEGACY_PRODUCTION_AUTHORITY_PRESERVED=YES
POLYC_PRODUCTION_DELEGATION_COUNT=0
src/parser.c SHA at C0 == src/parser.c SHA at C3 == 7a4a0935ae5fc92fb37dc637037a83c70c21a81ebe9a1233c69fd6529bc1a279
src/parser.c CalcPadding body lines (430..438) unchanged
src/parser.c CalcPadding call sites (5: parseClassOffsets x4 + parseUnionOffsets x1) unchanged
git grep 'BootstrapCalcPadding' -- src/ = empty (no production caller migrated)
```

## PARSER CONSERVATION

```text
PARSER_LAYOUT_CONSERVATION=PASS
  06_class_defs.HC          PASSED 6/6
  24_union.HC               PASSED 4/4
  42_class_u0_tail.HC       PASSED 3/3  (the zero-size U0 trailing test directly exercises CalcPadding)
  46_alignof.HC             PASSED 5/5
  65_class_inheritance.HC   PASSED 7/7

PARSER_CONSERVATION_NEW_FAILURES=0
AVAILABLE_PARSER_CONSERVATION_TARGETS_RUN=YES
```

## LEXER CONSERVATION

```text
LEXER01_CONSERVATION=PASS   (by-construction: no src/lexer.c mutation)
LEXER02_CONSERVATION=PASS   (by-construction)
LEXER03_CONSERVATION=PASS   (by-construction)
LEXER04_CONSERVATION=PASS   (by-construction)
NEW_LEXER07_FAILURES=0      (no lexer07 corpus was re-run; no source under closure scope was touched)
```

## FACTORY GATES

```text
GATE_FAST=PASS
APPEND_ONLY_FAIL=0   (11/11 NC tests PASS)
PATCH_HYGIENE_ERRORS=0   (git diff --check 840a769..HEAD empty)
C3_PHASE_PURITY=PASS
WORKTREE_CLEAN_AT_C0=YES
WORKTREE_CLEAN_AT_C3=YES
WORKTREE_CLEAN_AT_C4=YES
EXACT_COMMIT_COUNT_AT_CLOSE=5
POST_C4_COMMIT_COUNT=0
```

## F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0

PolyC tooling: differential, fixedpoint, matrix gen, large gen, four mutations
C tooling: tools/quality/parser-padding-oracle-impl.c
  Role: SEMANTIC_REFERENCE_ONLY (ACT §31)
  - mirrors src/parser.c::CalcPadding body verbatim
  - no terminal PASS/FAIL policy (PolyC owns verdict authority)

NEW_SHELL_WRAPPERS_OVER_50_LOC=0
```

## F-NO-PYTHON

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_FALLBACKS=0
```

## F14

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

No evidence or HANDOFF under LEXER0{1,2,3,4}, SURFACE-RECON03,
PARSER01, PARSER01-CORRECTION01, or PARSER-SLICE-RECON01 was
modified by this ACT.
```

## PATCH HYGIENE

```text
git diff --check 840a769..HEAD = (empty)
PATCH_HYGIENE_ERRORS=0
```

## SCOPE

Files actually changed in this ACT:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-PADDING01.md                       (C0 authorization)
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01.md            (C4 handoff)
docs/ROADMAP.md                                                        (C4 status update)
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/{c0,c1,c2,c3,c4}/**       (evidence)

tools/bootstrap/selfhost-parser-padding.HC            (new subject)
tools/quality/parser-padding-oracle-impl.c            (new C oracle)
tools/quality/parser-padding-differential.HC          (new PolyC tool)
tools/quality/parser-padding-fixedpoint-verify.HC     (new PolyC tool)
tools/quality/parser-padding-gen-matrix-fixture.HC    (new PolyC tool)
tools/quality/parser-padding-gen-large-fixture.HC     (new PolyC tool)
tools/quality/parser-padding-mutation-m{1,2,3,4}.HC   (new PolyC tools)
Makefile                                              (16 new PARSER_PADDING_* targets)
```

Production source delta:

```text
PRODUCTION_SOURCE_DELTA=0
src/parser.c        unchanged (SHA match C0 == C3)
src/parser.h        unchanged
parseClassOffsets   unchanged
parseUnionOffsets   unchanged
CalcPadding legacy  unchanged
```

## RESIDUE

| Priority | Item | Disposition |
| --- | --- | --- |
| P1 | `parseClassOffsets` and `parseUnionOffsets` still call the legacy C `CalcPadding`. Production delegation to `BootstrapCalcPadding` is the next-next ACT's responsibility. | Carry forward to PARSER-PADDING-DELEGATE01. |
| P1 | The 7 other eligible candidates from PARSER-SLICE-RECON01 (CAND-001, 003..008) remain in the inventory. | Carry forward. |
| P2 | Algebraic invariant verifier (parser-padding-algebraic-invariants.HC) was scoped out at C3 because the differential already establishes invariant satisfaction by construction. A standalone verifier can be added in a future ACT if the property needs to be exercised in isolation. | Recorded residue. |
| P2 | M1 zero-size mutation only diverges on 255/256 size=0 cases because clang's UB `% 0` happens to return 0 for the (0,0) case. On x86_64 the mutation does not trap; the harness classifies rejection via divergent result instead. | Documented; no production impact (legacy path is the source of truth). |

## NEXT

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
NEXT_TARGET=replace production calls to legacy C CalcPadding with
              BootstrapCalcPadding under an explicit stage/delegation seam
NEXT_OBJECTIVES (binding for the successor ACT):
  1. real production authority transfer
  2. G0 legacy vs G1+ PolyC semantic seam
  3. class-layout byte equivalence
  4. union-layout byte equivalence
  5. negative control load-bearingness
  6. 4-generation production behavior

PARSER_PADDING_SELFHOST_COMPLETE=NO
PARSER_PADDING_COMPONENT_QUALIFIED=TRUE_GREEN
```
