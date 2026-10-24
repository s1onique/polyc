# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01

VERDICT

PASS_TRUE_GREEN

  This ACT closes the three binding-predicate defects of its
  predecessor `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01` WITHOUT
  undoing the production migration and WITHOUT rewriting history.

  One acceptance predicate (AC16, the CORRECTION01 range check) is
  reported as `FAIL_STRUCTURAL_IMMUTABLE` rather than PASS. It is
  mechanically unreachable for reasons proved by execution, it is a
  governance/bookkeeping defect in immutable ancestor commits, and it
  is NOT attributable to the production subject. Per F13 this handoff
  reports the measured result rather than asserting a passing gate.
  See "Known limitation" below and the C4 residue.

---

## 1. Predecessor disposition

```text
PREDECESSOR_ACT                   = ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
PREDECESSOR_CLOSE_COMMIT          = 35dc0b00d177b51b308d18658fad584ca3357ad6
PREDECESSOR_EFFECTIVE_DISPOSITION = HALT_MULTIPLE_BINDING_PREDICATES
```

The predecessor's own CLOSE carried
`ACT-Verdict: PASS_PENDING_EXTERNAL_TERMINALITY`. The binding external
reviewer verdict, recorded post-close, is
`HALT_MULTIPLE_BINDING_PREDICATES`. It supersedes the committed verdict
and is recorded HERE, in CORRECTION01's own handoff, NOT by editing the
closed DELEGATE01 HANDOFF (F14).

### Substantive engineering results retained

```text
PARSER_PADDING_COMPONENT_QUALIFICATION = TRUE_GREEN
PARSER_PADDING_PRODUCTION_MIGRATION    = ENGINEERING_TRUE_GREEN
PARSER_PADDING_PRODUCTION_AUTHORITY    = POLYC
BOOTSTRAP_CALC_PADDING_LOAD_BEARING    = YES
LEGACY_RUNTIME_AUTHORITY               = RETIRED
N01_PRODUCTION_CAUSALITY               = TRUE_GREEN
```

None of these was reverted, reimplemented, or silently replaced.

---

## 2. Dedicated macro seam authorization (JOB 1)

```text
CORRECTION01_AUTHORIZED_DESIGN=HCC_USE_SELFHOST_PARSER_PADDING
DEDICATED_MACRO_REQUIRED=YES
DEFAULT_PRODUCTION_VALUE=ON
LEGACY_STAGE0_PATH=EXPLICIT
PRODUCTION_SOURCE_CHANGE_REQUIRED=NO

JOB_1_DESIGN_AUTHORIZED=YES
JOB_1_AC13_PROSPECTIVE_PASS=YES
JOB_1_DESIGN_RECONCILIATION=PASS
```

DELEGATE01 C1 froze `D-C = HCC_USE_SELFHOST_COMPONENTS` with
`NO_NEW_MACRO=YES` and a halt trigger for any new macro. DELEGATE01 C2
implemented the dedicated `HCC_USE_SELFHOST_PARSER_PADDING` flag. The
engineering rationale is sound: the generic flag also activates the
lexer self-host components, so using it for the production `hcc` would
have required linking five out-of-scope lexer subject objects.

CORRECTION01 prospectively authorizes the dedicated seam EXACTLY AS
IMPLEMENTED. The dedicated flag is a deliberate architectural choice,
not a temporary workaround: it isolates the parser-padding migration so
it can land, be qualified, and be reverted independently of the lexer
migrations.

**The historical violation remains a historical fact:**

```text
ORIGINAL_C1_DESIGN=HCC_USE_SELFHOST_COMPONENTS
ORIGINAL_C1_NO_NEW_MACRO=YES
ACTUAL_IMPLEMENTATION=HCC_USE_SELFHOST_PARSER_PADDING
ORIGINAL_AC13=FAIL
```

AC13 is regraded to PASS *under the CORRECTION01-authorized design* --
a different statement from "the DELEGATE01 C1 contract was satisfied".

**No production source changed.** `src/parser.c` and `src/CMakeLists.txt`
are byte-identical to their DELEGATE01 C2 values.

---

## 3. Independent G0/G1/G2/G3 production evidence (JOB 2)

The predecessor's C3 asserted G2/G3 independence in prose: its
generation-provenance TSV carried placeholder text
(`(distinct from G1 because...)`) instead of SHA-256 values, and its
production-semantic-verify.txt contained real build/run transcripts only
for G0 and G1.

CORRECTION01 **actually built and executed** all four generations.

### Build substrate (preconditions verified)

```text
./hcc                    exists, executable, sha256 77285899852d779f0af653434c48b703768940541dc2857e55f45719a91f3fa2
./build/hcc-bootstrap02  exists, executable, sha256 3b1e2cd16b027bf533e661567875ae9bf8e626cf74f372355626706601fe785a
./build/hcc-bootstrap03  exists, executable, sha256 b8a9781a7ef68e3da05427d03bc04f4250b76a967fd761147c6ef7100b9acdca
tools/bootstrap/selfhost-parser-padding.HC  exists, sha256 b555b76b484edda5830abba46dbda803a12ec1834f9ab0a64763f5899f2452f3
```

### Real compiler and binary SHA-256 identities

| Gen | Compiler | Compiler SHA-256 | Subject object SHA-256 | Production binary SHA-256 |
|---|---|---|---|---|
| G0 | `./hcc` | `77285899852d779f0af653434c48b703768940541dc2857e55f45719a91f3fa2` | `NOT_APPLICABLE_LEGACY_CONTROL` | `831d353e6f12e74568c080058cbd2e6108867e883ac5d08d32045aaef737d3ac` |
| G1 | `./build/hcc-bootstrap02` | `3b1e2cd16b027bf533e661567875ae9bf8e626cf74f372355626706601fe785a` | `187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1` | `dd6d8dfef798e4739e8a64c2143c16482f2477db031403ee6249962c10c28702` |
| G2 | `./build/hcc-bootstrap02` | `3b1e2cd16b027bf533e661567875ae9bf8e626cf74f372355626706601fe785a` | `187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1` | `dd6d8dfef798e4739e8a64c2143c16482f2477db031403ee6249962c10c28702` |
| G3 | `./build/hcc-bootstrap03` | `b8a9781a7ef68e3da05427d03bc04f4250b76a967fd761147c6ef7100b9acdca` | `187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1` | `dd6d8dfef798e4739e8a64c2143c16482f2477db031403ee6249962c10c28702` |

### Real production output SHA-256

| Fixture | G0 | G1 | G2 | G3 |
|---|---|---|---|---|
| `fixture_alignof` | `86c75cd71eacaf9121d5de93b88921ec3c129a766b8e72955c33add329fff190` | same | same | same |
| `fixture_u0_tail` | `0e5283368a110861df70744b21c8c3f544866ec7d78cbb2c9dcf4322d9d838f0` | same | same | same |
| `fixture_inheritance` | `bb266b2e37a5cde6f4e266097a03407a7fc99a5474a97a099960e399bf4891c9` | same | same | same |

### Provenance completeness

```text
GENERATION_ROWS=4
GENERATION_PROVENANCE_FAIL=0
GENERATION_PLACEHOLDER_COUNT=0
JOB_2_PROVENANCE_ROWS=4
JOB_2_PROVENANCE_PLACEHOLDERS=0
```

C3 independently **recomputed** all 39 recorded provenance fields from
disk (or from the literal command string) and compared them to the
recorded values. All 39 matched. No field contains `N/A`,
`same as previous`, `distinct because`, an abbreviated SHA, or
explanatory text.

### Independence -- why identical G1/G2/G3 hashes are still independent

The build is deterministic, so the same source tree + same flags +
byte-identical subject object yield a byte-identical production binary.
Identical hashes do NOT prove independent execution. Independence is
established by construction:

```text
distinct subject object paths     g1/ g2/ g3/parser-padding-subject.o
distinct CMake build directories  g1/cmake g2/cmake g3/cmake
distinct PARSER_PADDING_OBJECT    verified in each CMakeCache.txt
distinct production binaries       g1/hcc g2/hcc g3/hcc
distinct fixture executables      g1/*.bin g2/*.bin g3/*.bin
distinct compile+run invocations  per generation (c3-*-production-run.txt)
```

Each generation's subject object was built from scratch by that
generation's own compiler, each production binary was linked from that
generation's own subject object, and each fixture was compiled AND
executed by that generation's own production binary.

### G0 is a genuine legacy control

```text
G0 _BootstrapCalcPadding symbol present  = 0
G0 HCC_USE_SELFHOST_PARSER_PADDING in defines = 0
G0 binary differs from G1/G2/G3           = YES
```

The stage0 control does NOT activate the PolyC-padding authority, so
the six-way comparison is a real legacy-vs-PolyC differential rather
than a PolyC-vs-PolyC tautology.

---

## 4. Semantic comparison results

```text
G0_G1_EQUAL=YES
G0_G2_EQUAL=YES
G0_G3_EQUAL=YES
G1_G2_EQUAL=YES
G1_G3_EQUAL=YES
G2_G3_EQUAL=YES

PRODUCTION_SEMANTIC_PAIR_PASS=6
PRODUCTION_SEMANTIC_PAIR_FAIL=0
MIGRATION_DELTA=0
```

Per-fixture totals (3 fixtures x 6 generation pairs = 18 comparisons,
each performed with `cmp`, which fails on mismatch):

```text
PER_FIXTURE_PAIR_PASS=18
PER_FIXTURE_PAIR_FAIL=0
```

Output determinism confirmed: 1 distinct output SHA-256 over 3
consecutive executions per fixture.

### Fixture provenance

The predecessor's fixture contract named ephemeral `/tmp/fixture_*.HC`
paths that were never committed and did not survive the previous
session. CORRECTION01 deterministically REGENERATED them and COMMITTED
the sources under this ACT's evidence tree, so every generation uses a
byte-identical, version-controlled fixture source. Every value the
predecessor pinned is reproduced exactly (`Hdr=8 HdrMixed=16`,
`NarrowBase=1 WideDerived=16`, `Mixed=24 alignof=8`, `BaseClass=16
SuperClass=32 Empty=16 Cat=8`, ...). The predecessor's historical
output SHA's byte-level framing is not recoverable (7200 candidate
framings were searched without a match) and is disclosed in
`evidence/.../c1/c1-fixture-source-provenance.txt`. The SEMANTIC
conclusion (MIGRATION_DELTA=0) is unaffected.

---

## 5. Production-source conservation

```text
HCC_USE_SELFHOST_PARSER_PADDING_DEFAULT=ON
PRODUCTION_PADDING_AUTHORITY=POLYC
LEGACY_RUNTIME_FALLBACK=NO
PRODUCTION_SOURCE_DELTA=0
BOOTSTRAP_CALC_PADDING_SOURCE_DELTA=0
```

All six frozen subjects are byte-identical to their C0 values, and
`git diff --exit-code 87361da..HEAD -- src/parser.c src/CMakeLists.txt
tools/bootstrap/selfhost-parser-padding.HC` returns 0.

---

## 6. F14 conservation

```text
DELEGATE01_EVIDENCE_DELTA_SINCE_ENTRY=0     (53/53 files individually rehashed)
DELEGATE01_HANDOFF_DELTA_SINCE_ENTRY=0
DELEGATE01_HANDOFF_HISTORICAL_F14_VIOLATION=ACKNOWLEDGED
```

The DELEGATE01 evidence tree and HANDOFF were NOT modified by
CORRECTION01, verified both by per-file rehash against the frozen
baseline and by `git diff --exit-code 93f85ed..HEAD`.

---

## 7. Factory gates

```text
GATE_FAST=PASS
APPEND_ONLY_FAIL=0              (factory-append-only-test: 11/11 PASS)
PATCH_HYGIENE_ERRORS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
F_NO_PYTHON=PASS
F_POLYC_TOOLS=PASS
```

CORRECTION01 added no scripts and no tooling: only `.txt`, `.tsv`, and
`.HC` evidence files (3 `.HC`, 7 `.tsv`, 25+ `.txt`).

---

## 8. Historical defects explicitly NOT rewritten

```text
DELEGATE01_HISTORICAL_TRAILER_GEOMETRY=IMMUTABLE_FAIL_ACK
DELEGATE01_HANDOFF_HISTORICAL_F14_VIOLATION=ACKNOWLEDGED
```

* The DELEGATE01 C0..C3 commit messages still have blank-line-separated
  trailers. They are immutable: a forward commit cannot rewrite an
  ancestor's message under the append-only invariant.
* The DELEGATE01 HANDOFF still contains the `8393d4d` post-mortem
  mutation. It is F14-improper, it is acknowledged, and it is NOT
  repaired here -- only forward mutations were forbidden.
* No DELEGATE01 evidence file was modified.
* No DELEGATE01 commit message was modified.

---

## 9. Known limitation -- AC16 / CORRECTION01 range check

```text
AC16  factory-v2-range-check CORRECTION01 = PASS
      -> FAIL_STRUCTURAL_IMMUTABLE (measured, not asserted)
```

`scripts/quality/factory-v2-range-check.sh` derives FIRST by walking
parents backwards for as long as each parent carries `ACT: <id>`. The
three pre-C0 authorization commits already carry the CORRECTION01 ACT
id:

```text
8393d4d  ACT-Phase=POST_MORTEM_AUTHORIZATION
b73fe6b  ACT-Phase=AUTH_REVISED
93f85ed  ACT-Phase=AUTH_READY_FOR_C0
```

so FIRST is pinned to `8393d4d` and the check reports:

```text
STATUS=FAIL
REASON=FIRST commit 8393d4d97d434eff38e7024266405effe13b3708 has ACT-Phase='POST_MORTEM_AUTHORIZATION', expected RED
```

This was proved EMPIRICALLY: a scratch clone given a PERFECT C0..C4
trailer sequence (exactly the trailers this ACT prescribes) produces
the same FAIL. No forward commit can change it.

Per DOCTRINE section 25:

```text
HALT_CLASS  = GOVERNANCE
BLOCKS_NEXT = NO
```

The failure is NOT attributable to the production subject (which is
ENGINEERING_TRUE_GREEN and unchanged); it is a bookkeeping defect in
immutable ancestor commits. It is not a B1-B5 blocking predicate.

The CORRECTION01 range-check result is reported as measured. This
handoff does NOT claim `FACTORY_V2_RANGE_CHECK=PASS` for the
CORRECTION01 range.

---

## 10. Residue

### P1 -- range-validator FIRST derivation includes authorization commits

`scripts/quality/factory-v2-range-check.sh` should derive FIRST from the
contiguous run of commits whose `ACT-Phase` is canonical
(RED/IMPL/EVIDENCE/CLOSE), not from the raw presence of `ACT: <id>`.
This would let a correction whose authorization commits carry the ACT id
close with a passing range check, and would also make the check robust
to the PADDING01-CORRECTION04-style pattern (ACT id introduced at the
first EXECUTION commit).

**Dedicated ACT recommended:** `ACT-POLYC-FACTORY-RANGE-CHECK-FIRST-DERIVATION01`.

### P1 -- pre-existing Python residue

`scripts/quality/factory-no-python-check.sh` reports `STATUS=FAIL` with
12 tracked Python/legacy items. All 12 predate this ACT (LLVM spike and
bootstrap02/03/04 corpus runners). CORRECTION01 introduced zero Python.
Not silently fixed here, per F7/F11.

### P1 -- `tools/factory/factory-polyc-tools-check.HC` does not exist

The F-POLYC-TOOLS authoritative checker is not yet landed (per the
`AGENTS.md` pointer, C2.9 residue of an earlier correction). F-POLYC-TOOLS
compliance was verified directly instead: this ACT added no tooling
other than three PolyC fixture sources.

### P2 -- production fixtures should be committed, not written to /tmp

The predecessor's `/tmp/fixture_*.HC` loss forced a regeneration step in
CORRECTION01. Future production-seam fixtures should live in the
repository.

---

## 11. Next ACT

```text
NEXT = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

That successor must re-inventory the remaining legacy-C parser semantic
authority, rank bounded low-coupling slices, and select the next
production migration. The parser-padding slice is the first PolyC
production-authority component; the slice-recon ACT can begin with
confidence now that the padding migration's production authority is
independently qualified.

`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02` is NOT opened by this ACT.

---

## 12. Evidence index

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/
  c0/   entry identity, predecessor disposition, source freeze,
        HANDOFF freeze, evidence freeze, scope, required result
  c1/   RED-D1 design contradiction, RED-D2 generation placeholders,
        RED-D3 trailer geometry, RED-D4 pre-C0 ACT-trailer collision,
        design reconciliation contract, generation run contract,
        fixture provenance (tsv + narrative), semantic contract,
        closure geometry contract, required result
  c2/   generation provenance TSV, per-generation build/run transcripts,
        semantic verification, pair matrix, design reconciliation,
        production source conservation, required result
  c3/   entry identity, design authorization, per-generation build/run,
        provenance TSV + independent verification, semantic verification,
        pair matrix, production authority + source conservation,
        F14 evidence/HANDOFF conservation, patch hygiene, factory gates,
        commit trailer audit, mandatory AC status, required result
  fixtures/  the three regenerated, committed production fixtures
```

The authoritative verdict lives in the C4 CLOSE commit's `ACT-Verdict`
trailer, not in this document.
