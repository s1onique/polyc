# ACT-POLYC-SELFHOST-PARSER-SLICE03

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT

**Title:** Implement the PolyC component `BootstrapOperatorPrecedence` and
transfer production operator-precedence authority from legacy C to it

**Repository:** `s1onique/polyc`
**Branch:** `main`

**Class:** SELFHOST / PARSER / ATOMIC-SLICE-IMPLEMENTATION / PRODUCTION-AUTHORITY-MIGRATION

**Priority:** P0

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`
(closed; its successor-facing contract is
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/`)
(its own closure carries `ACT-Verdict: PASS` on its CLOSE commit)

**Legacy authority:** `src/prslib.c::parseGetPriority` (`src/prslib.c:1139..1207`)

**Qualified PolyC subject:**
`tools/bootstrap/selfhost-parser-operator-precedence.HC::BootstrapOperatorPrecedence`

**Transition:**

```text
LEGACY_C
   ↓
POLYC_PRODUCTION_AUTHORITY
```

---

## 0. Mission

Implement the compiler's **operator precedence table** in PolyC, prove it
against the real legacy-C function, and make the production compiler
actually consume the PolyC result — without changing the precedence
semantics.

At successful close:

```text
OPERATOR_PRECEDENCE_PRODUCTION_AUTHORITY = POLYC
LEGACY_PARSE_GET_PRIORITY_AUTHORITY       = RETIRED
BootstrapOperatorPrecedence                = LOAD_BEARING_IN_PRODUCTION
```

The precedence value decides the AST shape of **every binary and unary
expression in every compiled program**.  This is the single most
production-reachable semantic decision that remains in legacy C.

---

## 1. Why this ACT is now authorized

### 1.1 The engineering work survived review; the Factory closure did not

`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03` selected exactly one candidate
and froze its contract:

```text
SELECTED_CANDIDATE_COUNT = 1
SELECTED_CANDIDATE_ID    = CAND-017
SELECTED_CANDIDATE       = parseGetPriority   src/prslib.c:1139..1207
SELECTED_R0              = 0
SELECTED_ABI             = I64 BootstrapOperatorPrecedence(I64 punct_value) -> I64 precedence
SELECTED_PRODUCTION_SEAM = src/prslib.c:1363, inside parseExpr (32 production call sites)
```

The selection, the eligibility computation, the ranking and the causal
mutation derivation were all re-verified independently in RECON03's C3
phase and all recomputed.  Those engineering findings stand.

The **closure** did not stand on its own: RECON03's AC47
(`gate-push` passes) was recorded as
`FAIL_PRE_EXISTING_HOST_ISSUE` rather than PASS, so the ACT could not be
closed with every mandatory AC green.  RECON03 is therefore treated
here as **HALT_ACKNOWLEDGED**: its engineering artifacts are inherited
as the starting contract, its closure defect is not repaired in place,
and this ACT re-establishes the required contract **independently**
before it implements anything.

### 1.2 A fresh `gate-push` was measured on the tested host

A fresh `gate-push` run PASSES on the tested host.  That does **not**
retroactively change RECON03's failed AC47.  It does establish that the
current tree can pass the gate **without a harness modification**, and
therefore this ACT does **not** introduce an unrelated harness repair.
Any `gate-push` result recorded by this ACT must be the result of a
fresh run against this ACT's own tree.

### 1.3 The successor contract needs requalification before use

RECON03's fixture contract is **not** usable as-is.  C0–C1 of this ACT
establishes, from the live source and not from the predecessor's prose:

```text
1. The fixture-count total in the frozen partition table is wrong.
2. One partition lists a value that IS a recognised operator under a
   partition whose expectation is that it is NOT an operator.
3. The precedence table must be re-derived from src/prslib.c and
   src/lexer.h rather than copied from the predecessor's contract.
```

The specific defects are stated in §4.  C0–C1 finds them, states them,
and freezes a corrected contract; it does **not** change the legacy
precedence semantics to make a fixture pass.

---

## 2. Core invariant

The migration must preserve the legacy semantic function exactly.

The legacy body (`src/prslib.c:1139..1207`) is a single `switch` over
`tok->i64` and reads **no other field and no other identifier**.  Its
complete table, re-derived from the live source, is:

```text
precedence  1 : TK_ARROW (0x328), '.' (0x2E), '(' (0x28)
precedence  2 : '[' (0x5B)
precedence  3 : '!' (0x21), '~' (0x7E), TK_PLUS_PLUS (0x305),
                TK_MINUS_MINUS (0x306), TK_PRE_PLUS_PLUS (0x330),
                TK_PRE_MINUS_MINUS (0x331)
precedence  4 : '*' (0x2A), '/' (0x2F), '%' (0x25)
precedence  5 : '-' (0x2D), '+' (0x2B)
precedence  6 : TK_SHL (0x309), TK_SHR (0x30A)
precedence  7 : TK_LESS_EQU (0x30D), TK_GREATER_EQU (0x30E),
                '<' (0x3C), '>' (0x3E)
precedence  8 : TK_EQU_EQU (0x30B), TK_NOT_EQU (0x30C)
precedence  9 : '^' (0x5E)
precedence 10 : '&' (0x26)
precedence 11 : '|' (0x7C)
precedence 12 : TK_AND_AND (0x30F)
precedence 13 : TK_OR_OR (0x310)
precedence 14 : '=' (0x3D), TK_ADD_EQU (0x319), TK_SUB_EQU (0x31A),
                TK_MUL_EQU (0x314), TK_DIV_EQU (0x315), TK_MOD_EQU (0x322),
                TK_AND_EQU (0x316), TK_OR_EQU (0x317), TK_XOR_EQU (0x318),
                TK_SHL_EQU (0x312), TK_SHR_EQU (0x313)
any other    : -1
```

```text
OPERATOR_PRECEDENCE_SEMANTIC_DELTA = 0
```

### 2.1 The `-1` sentinel is load-bearing

`parseExpr` consumes the value in exactly three ways
(`src/prslib.c:1364`, `:1430`, `:1431`):

```text
if (prec2 < 0 || prec <= prec2) { rewind; return LHS; }
next_prec = prec2;
if (tok->i64 == '=') next_prec++;
```

`-1` means "this token is not a binary operator".  It MUST be preserved
exactly.

### 2.2 No `tk_type` check

The legacy function never inspects `tk_type`.  The PolyC component MUST
NOT add a `tk_type` check: adding one would change the result for any
caller that reaches the function with a non-`TK_PUNCT` token.

### 2.3 The `TK_STR` / `TK_SUPERSCRIPT` aliasing

`src/lexer.h:15` defines `TK_SUPERSCRIPT 0x301` and `src/lexer.h:19`
defines `TK_STR 0x301`.  Neither value appears in the precedence table,
so both MUST return `-1`.  The component MUST NOT distinguish them.

---

## 3. Scope

### 3.1 Readable engineering surfaces

```text
src/prslib.c
src/prslib.h
src/lexer.h
src/lexer.c
src/parser.c
src/parser.h
src/CMakeLists.txt

tools/bootstrap/
tools/quality/

src/tests/
Makefile
```

### 3.2 Authorized tracked mutations

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE03.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE03.md

docs/factory/act-handoff-map.tsv

docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/**

src/prslib.c
src/CMakeLists.txt

tools/bootstrap/selfhost-parser-operator-precedence.HC

tools/quality/parser-slice03-*.HC
tools/quality/parser-slice03-*.c
tools/quality/parser-slice03-*.h

Makefile
```

`src/prslib.c` is authorized ONLY for:

1. the delegation guard at the `parseGetPriority` decision site
   (`src/prslib.c:1363`), and
2. a thin, non-static C oracle adapter that calls the **real** legacy
   function and adds **no logic** (the frozen adapter strategy).

`src/prslib.c` is NOT authorized for any change to the precedence table,
to the `-1` sentinel, to `parseExpr`, to the recursion, or to the AST.

### 3.3 Forbidden mutations

```text
existing closed evidence/**
existing closed HANDOFFs
existing closed ACT documents

docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/**
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md

src/parser.c
src/lexer.c
src/ast.c
src/cctrl.c
src/prsutil.c

existing closed qualification tools
existing Factory validators
pre-push hooks
```

**F14 is binding.** RECON03's evidence tree and HANDOFF are closed
evidence.  The historical two-tool scope violation (§4.4) is RECORDED
in this ACT's own evidence; it is NOT repaired by editing RECON03.

Git commit trailers (`ACT:`, `ACT-Phase:`, `ACT-Verdict:`) are commit
metadata.  They are **not** a mechanism for retroactively repairing
closed ACT evidence.

### 3.4 Forbidden semantic changes

- changing the precedence VALUES;
- changing the `-1` sentinel;
- adding a `tk_type` check;
- changing the constant binding away from the live `src/lexer.h` values;
- changing `parseExpr`, the recursion, or the AST;
- changing the legacy precedence semantics **merely to make fixtures
  pass**;
- a silent C fallback on the migrated path.

---

## 4. Stage C0–C1 — Contract requalification

### 4.1 The precedence table must be independently derived

C0–C1 MUST re-derive the complete precedence table **directly from
`src/prslib.c` and `src/lexer.h`** and record the derivation as
mechanically checkable evidence: for every table entry, the constant
name, its numeric value from `src/lexer.h`, its precedence, and the
`src/prslib.c` line that binds it.

The re-derivation MUST be computed by a tool, not by hand-typed prose,
and MUST be checked against the live source at run time.

### 4.2 The fixture-count contradiction must be resolved

RECON03's `c2/fixture-partitions.tsv` declares:

```text
TOTAL_MIN_ROWS=91
EXPECTED_FIXTURE_COUNT=91
PARTITION_COUNT=19
```

but the per-partition `min_rows` values do not sum to 91.  C0–C1 MUST
determine the **actual** mandatory row count, state the arithmetic
explicitly, and freeze the corrected count.

**Known defect (to be confirmed and recorded by C0–C1, not assumed):**
the `P18_SIGN_AND_WIDTH_BOUNDARIES` row is missing the `input_domain`
column, so it has 4 tab-separated fields where every other partition
row has 5.  A field-position-5 parse reads the wrong cell for that row
and silently drops it from the sum.  The true sum is 91 **+ 8 = 99**.

**MEASURED (C1).** The requalification tool confirms this: reading
the `min_rows` of every partition of the predecessor's table **by field
position** gives `SUM_MIN_ROWS_WELLFORMED=91`, and adding back the
malformed row's own declared value gives
`SUM_MIN_ROWS_ALL_DECLARED=99`.  The discrepancy is exactly the 8 rows
of P18.

The CORRECTED count is **98**, not 99: correcting the `TK_SHR` defect
(§4.3) removes one reject row from P15, so P15's `min_rows` falls from
10 to 9 and the total falls by one.

C0–C1 MUST compute the corrected total mechanically from the partition
table and MUST record both the defective arithmetic and the corrected
arithmetic.

### 4.3 The `TK_SHR` defect must be corrected

**Known defect (to be confirmed and recorded by C0–C1, not assumed):**
the `P15_REJECTED_NOT_AN_OPERATOR` partition lists `0x30B-1` among the
values that MUST return `-1`.  `0x30B - 1` is `0x30A`, which is
`TK_SHR` — a **recognised operator** with precedence **6**.  The
partition therefore states a semantically false expectation.

C0–C1 MUST:

1. confirm the defect against the live `src/lexer.h` and the live
   `src/prslib.c` body;
2. state the corrected partition membership (the value must be either
   removed from the reject set or moved to the precedence-6 partition
   with expected output 6);
3. record the defect as a defect of the **predecessor's contract**, not
   as a defect of the legacy semantics — the legacy semantics are
   correct and MUST NOT change.

C0–C1 MUST also audit **every** partition row for the same class of
error: each listed reject value MUST actually be absent from the
precedence table, and each listed accept value MUST actually be
present with the stated precedence.  The audit MUST be mechanical.

**MEASURED (C1).** The audit reports
`AUDIT_INCONSISTENT_PARTITIONS=1` and names the offending value:

```text
DEFECT value=778 (0x30A) table_precedence=6 partition_expects=-1
```

The 14 ACCEPT partitions and the three other REJECT partitions are
CONSISTENT with the derived table.  The `TK_SHR` defect is the only
value-level inconsistency in the whole predecessor contract.

### 4.4 The historical two-tool scope violation must be recorded

RECON03's scope section authorized "**one** bounded PolyC-native quality
tool" under `tools/quality/parser-slice-recon03-*.HC`.  The C1 commit
added **two**:

```text
tools/quality/parser-slice-recon03-eligibility.HC
tools/quality/parser-slice-recon03-ranking.HC
```

C0–C1 MUST record this as a historical scope violation of the
predecessor, with the commit identity, and MUST NOT modify RECON03's
ACT document, evidence tree or HANDOFF.

### 4.5 The fixture-integrity witness must be executable and frozen

C0–C1 MUST freeze an **executable** fixture-integrity witness that:

1. counts the executed fixture rows by a path **independent** of the
   row-classification path the differential exercises;
2. reports the exact canonical fixture-ID set it observed;
3. **REJECTS** an unknown or additional fixture row rather than
   skipping it;
4. has a recorded **negative control**: a deliberately corrupted or
   augmented fixture MUST produce a reported FAILURE, not a silent
   PASS.

The witness MUST be usable as the successor's own fixture-integrity
authority.  The closed control-flow-token qualification tool MUST NOT be
relied upon as that sole authority.

### 4.6 C0–C1 evidence

```text
c0/
  entry-identity.txt
  predecessor-binding.txt
  source-freeze.tsv
  scope.txt
  production-authority.tsv
  baseline-authority.txt

c1/
  precedence-table-derived.tsv
  precedence-derivation-check.txt
  fixture-partitions-audit.tsv
  fixture-count-arithmetic.txt
  fixture-contract-freeze.tsv
  tk-shr-defect.txt
  predecessor-scope-violation.txt
  fixture-integrity-witness.md
  required-result.txt
```

Commit C0 with `ACT-Phase: RED`, C1 with `ACT-Phase: EVIDENCE`.

---

## 5. Stage C2–C4 — Implementation and qualification

### 5.1 Principal RED

The RED is the **absence** of the PolyC subject and of the production
delegation:

```text
tools/bootstrap/selfhost-parser-operator-precedence.HC   -> ABSENT
src/prslib.c delegation to BootstrapOperatorPrecedence    -> ABSENT
production ./hcc links _BootstrapOperatorPrecedence       -> NO
```

A RED satisfied by a synthetic mock is not acceptable: the seam is the
real production function and the real production binary.

Additional REDs, all reproduced against the real seam before the
corresponding production change:

| ID | RED | Falsifier |
|---|---|---|
| RED-1 | legacy semantic authority remains in C | `prslib.c.o` already carries `U _BootstrapOperatorPrecedence` |
| RED-2 | PolyC implementation absent | the symbol exists in `tools/bootstrap/` |
| RED-3 | no production delegation | the production object references the component |
| RED-4 | no qualified four-generation evidence | a `G0..G3` artifact set already exists for this component |
| RED-5 | production-causal sensitivity | the mutation produces no observable divergence |

### 5.2 Implementation boundary

1. The PolyC subject, compiled by the **stage-0** compiler so the
   component does not depend on the production compiler it serves.
2. The oracle: the **real** legacy-C function, reached through a thin
   non-static adapter in `src/prslib.c` that adds no logic.
3. The PolyC comparison layer, which is the terminal authority.
4. The production delegation in `src/prslib.c`, guarded by
   `HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE`, with the legacy body
   in the `#else` branch.
5. The fail-closed build wiring: a missing or symbol-less component is a
   hard build error, never a silent legacy fallback.
6. The independent fixture-integrity witness from §4.5.

The delegation flag MUST be **dedicated** (not the generic
`HCC_USE_SELFHOST_COMPONENTS` selector, which would also require the
lexer subjects) and MUST default to ON in the production `hcc` build.

### 5.3 The real legacy-C oracle

The differential MUST compare against the **REAL** legacy-C function.
A handwritten reimplementation of the precedence table is **NOT** an
acceptable sole oracle: it could share the same misreading of the
legacy source as the PolyC component and would agree with it while both
are wrong.

The oracle MUST come from a build in which the delegation flag is
**OFF**, so that the legacy body is the one being executed.  A
differential run against the delegated build would compare the PolyC
component against itself and would be vacuous.

The fixture's own `expected` column MUST be checked against the oracle
as well, so that a disagreement between the PolyC subject and the
production oracle cannot be masked by an equally wrong fixture.

The differential MUST include a negative control showing the comparison
can FAIL.

### 5.4 The four-generation qualification

```text
G0 = legacy/stage0 reference
G1 = stage1 PolyC production path
G2 = independently built stage2
G3 = independently built stage3
```

For each generation the ACT MUST record the compiler identity (binary
path **and** SHA-256), the exact build command, and the SHA-256 of every
source file that went into it.  The generations MUST be distinct builds
and MUST be executed independently; one binary copied four times is not
four generations.

Required:

- six component-object pairwise comparisons (G0/G1/G2/G3);
- six production semantic pair comparisons;
- generation provenance checking;
- copy-forgery rejection, including byte-identical object substitution;
- a negative control for copied seam outputs;
- the direct C-oracle differential;
- the production-causal mutation;
- the actual production authority transfer.

**G0 is an intentional legacy reference.** Its component object is built
from the LEGACY C implementation, so byte-identity with G1/G2/G3 is NOT
expected.  The permitted G0-versus-PolyC comparison contract is
**semantic** (the oracle differential), not byte-identity.  This
exception MUST be frozen explicitly in this ACT's own evidence.

**A mutation-specific semantic delta does NOT count as
normal-generation equivalence.** The mutation run is a separate
obligation.

### 5.5 The production-causal mutation

The frozen mutation:

```text
MUTATION_LOCATION = the precedence-4 arm of the PolyC component
  PRISTINE: '*' -> 4;  '/' -> 4;  '%' -> 4
  MUTATED:  '*' -> 6;  '/' -> 4;  '%' -> 4

MUTATION_KIND = SEMANTIC_CONSTANT_CHANGE (one precedence class moves)

EXPECTED_AFFECTED_FIXTURE = the P4 fixture row for '*' (0x2A);
                            its expected precedence changes from 4 to 6

EXPECTED_PRODUCTION_OBSERVABLE = the grouping of a mixed-precedence
                            expression changes

EXPECTED_PRISTINE_RESULT = 62   (a=6, b=7, c=20: 42 + 20)
EXPECTED_MUTATED_RESULT  = 162  (a=6, b=7, c=20: 6 * 27)
```

The observation MUST be the **output of a compiled program**, not an
internal AST dump and not a shadow verifier.

The required execution sequence:

```text
pristine component -> build -> link -> execute -> capture output A
mutated component  -> build -> link -> execute -> capture output B
assert A != B
restore pristine  -> build -> link -> execute -> capture output C
assert C == A
```

The restore-and-reverify step is mandatory.  A failed build or a missing
output is **NOT** semantic divergence.  The SHA-256 of each output MUST
be recorded.

### 5.6 The production authority transfer

The strong form of the evidence:

```sh
$ nm -u build/CMakeFiles/hcc.dir/prslib.c.o | grep BootstrapOperatorPrecedence
_U _BootstrapOperatorPrecedence
```

The legacy algorithm body MUST live in the `#else` branch and MUST NOT
be compiled into the production object.  The ACT MUST also confirm that
the other two production authorities are unchanged:

```text
_U _BootstrapCalcPadding
_U _BootstrapValidPostControlFlowToken
```

and that both keep their five live production call sites.

### 5.7 The fixture model

The fixture model is the **corrected** one frozen by C0–C1, with:

```text
EXPECTED_FIXTURE_IDS     the complete set of mandatory fixture ids
EXPECTED_FIXTURE_COUNT   the corrected count
FIXTURE_SCHEMA           the column layout of the fixture file
FIXTURE_SOURCE_SHA256    the SHA-256 of the fixture file
```

Every mandatory partition MUST be present and every mandatory row MUST
be EXECUTED, witnessed by the independent witness of §4.5.  Unknown or
additional fixture rows MUST be REJECTED, not skipped.

### 5.8 Conservation obligations

The ACT MUST run and record:

```text
the parser conservation suite
the lexer conservation suite (LEXER01..04 and the LEXER07 broad corpus)
the Factory gates (gate-fast, gate-push, factory-v2, append-only)
the F-NO-PYTHON and F-POLYC-TOOLS checkers
git diff --check <ENTRY_HEAD>..HEAD
```

with **ZERO new failures** relative to the baseline this ACT freezes.

Pre-existing violations are recorded as measured.  They are not
relabelled PASS and are not silently waived.

### 5.9 C2–C4 evidence

```text
c2/
  implementation-notes.md
  component-source-freeze.tsv
  build-receipt.txt
  differential-fixture.tsv
  differential-run.txt
  differential-negative-control.txt
  fixture-integrity-run.txt
  fixture-integrity-negative-control.txt
  oracle-run.txt
  required-result.txt

c3/
  generation-manifest.tsv
  generation-provenance.txt
  component-object-pairs.tsv
  production-semantic-pairs.tsv
  copy-forgery-control.txt
  seam-copy-negative-control.txt
  causal-mutation-run.txt
  production-authority.txt
  parser-conservation.txt
  lexer-conservation.txt
  lexer07-baseline-comparison.txt
  gate-fast.txt
  gate-push.txt
  factory-v2.txt
  append-only.txt
  f-no-python.txt
  f-polyc-tools.txt
  f14-conservation.txt
  patch-hygiene.txt
  mandatory-ac-status.tsv
  required-result.txt
```

---

## 6. Mandatory acceptance criteria

| ID | Binding predicate |
|---|---|
| AC01 | Entry identity established from live HEAD |
| AC02 | Worktree clean before authorization |
| AC03 | Predecessor closure reachable |
| AC04 | RECON03's historical closure verdict recorded as HALT_ACKNOWLEDGED without modifying it |
| AC05 | RECON03's engineering selection inherited (CAND-017, R0=0, ABI frozen) |
| AC06 | Precedence table independently re-derived from live `src/prslib.c` + `src/lexer.h` |
| AC07 | The derivation is tool-computed and checkable against the live source |
| AC08 | Every table entry bound to a live `src/lexer.h` numeric value |
| AC09 | The `-1` sentinel confirmed against the live source |
| AC10 | The fixture-count contradiction resolved with explicit arithmetic |
| AC11 | The corrected fixture count is tool-computed from the partition table |
| AC12 | Every partition row audited for accept/reject membership correctness |
| AC13 | The `TK_SHR` defect confirmed against the live source and corrected in the contract |
| AC14 | The legacy precedence semantics are UNCHANGED by the contract correction |
| AC15 | The historical two-tool scope violation recorded, with commit identity |
| AC16 | RECON03's ACT, evidence tree and HANDOFF unmodified (F14) |
| AC17 | The fixture-integrity witness is executable |
| AC18 | The witness counts executed rows by an independent path |
| AC19 | The witness rejects an unknown/additional fixture row |
| AC20 | The witness has a recorded negative control that fires |
| AC21 | The PolyC subject exists and implements the frozen ABI exactly |
| AC22 | The subject is compiled by the stage-0 compiler |
| AC23 | The real legacy-C oracle is linked and used, not a reimplementation |
| AC24 | The oracle comes from a build with the delegation flag OFF |
| AC25 | The fixture's own `expected` column is checked against the oracle |
| AC26 | The differential has a negative control that reports a disagreement |
| AC27 | The differential covers every mandatory fixture row |
| AC28 | The independent fixture-integrity witness passes on the executed fixture |
| AC29 | G0, G1, G2, G3 all produced, distinct and independently executed |
| AC30 | Each generation's identity, build command and source identities recorded |
| AC31 | Six component-object pairwise comparisons recorded |
| AC32 | Six production semantic pair comparisons recorded |
| AC33 | Generation provenance checking performed |
| AC34 | Copy-forgery rejection demonstrated, including byte-identical substitution |
| AC35 | Copied-seam-output negative control demonstrated |
| AC36 | The G0-versus-PolyC semantic (non-byte-identity) exception frozen explicitly |
| AC37 | Production delegation compiles under `HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE` |
| AC38 | The legacy body is NOT compiled into the production object |
| AC39 | `U _BootstrapOperatorPrecedence` present in the production object |
| AC40 | `U _BootstrapCalcPadding` and `U _BootstrapValidPostControlFlowToken` unchanged |
| AC41 | Both existing PolyC parser components keep their five live call sites |
| AC42 | The causal mutation executed: pristine 62, mutated 162, restored 62 |
| AC43 | The mutation built and LINKED successfully (not a build failure) |
| AC44 | The restore-and-reverify step performed, with output SHA-256s recorded |
| AC45 | The mutation is not used to satisfy normal-generation equivalence |
| AC46 | The precedence values are unchanged (`OPERATOR_PRECEDENCE_SEMANTIC_DELTA = 0`) |
| AC47 | The `-1` sentinel is unchanged |
| AC48 | No `tk_type` check was added |
| AC49 | The `TK_STR`/`TK_SUPERSCRIPT` aliasing is honoured |
| AC50 | The parser conservation suite shows zero new failure identities |
| AC51 | The lexer conservation suite shows zero new failure identities |
| AC52 | The LEXER07 broad corpus shows zero new failure identities |
| AC53 | `make gate-fast` -> RC=0 |
| AC54 | `make gate-push` -> fresh run against this ACT's tree, result recorded as measured |
| AC55 | `factory-v2-test.sh` -> PASS |
| AC56 | `factory-append-only-test.sh` -> PASS |
| AC57 | `git diff --check <ENTRY_HEAD>..HEAD` -> RC=0 |
| AC58 | F-NO-PYTHON and F-POLYC-TOOLS results recorded as measured |
| AC59 | The F-POLYC-TOOLS constraint satisfied for any new tool (PolyC, or shell glue <= 50 LOC) |
| AC60 | The fail-closed build wiring rejects a missing/symbol-less component |
| AC61 | The legacy C adapter adds no logic |
| AC62 | The fixture schema, ID set, count and source SHA-256 are frozen |

---

## 7. Halt taxonomy

```text
HALT_RED_NOT_REPRODUCED
HALT_SCOPE_EXPANSION_REQUIRED
HALT_F14_VIOLATION
HALT_PRODUCTION_MUTATION
HALT_MANDATORY_AC_NOT_GREEN
HALT_SEMANTIC_DELTA_NONZERO
HALT_CONSERVATION_REGRESSION
HALT_FACTORY_GATE_NOT_GREEN
HALT_REAL_ORACLE_UNAVAILABLE
HALT_FIXTURE_INTEGRITY_NOT_ESTABLISHED
HALT_CONTRACT_REQUALIFICATION_FAILED
```

For a HALT verdict, apply the Factory-v2 `HALT_CLASS` and `BLOCKS_NEXT`
requirements.  A legitimate HALT preserves the engineering findings and
identifies the blocking prerequisite.

---

## 8. Commit topology

```text
1. C0 RED      (authorization, entry identity, baseline freeze)
2. C1 EVIDENCE (contract requalification, corrected fixture contract,
                fixture-integrity witness)
3. C2 IMPL     (the PolyC subject, the oracle, the differential)
4. C3 EVIDENCE (generations, delegation, causal proof, conservation)
5. C4 CLOSE    (the HANDOFF and the closure verification)
```

---

## 9. Closure handoff

`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE03.md`.

The CLOSE commit carries:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE03
ACT-Phase: CLOSE
ACT-Verdict: PASS
```
