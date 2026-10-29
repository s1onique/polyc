# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01`
**Class:** SELFHOST / PARSER / EVIDENCE-HYGIENE / FROZEN NEGATIVE-CONTROL DISCHARGE
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06` (closed,
`ACT-Verdict: HALT_N06_FROZEN_OBLIGATION_UNPROVEN`,
`HALT_CLASS: GOVERNANCE`, `BLOCKS_NEXT: NO`)
**Historical subject:** `ACT-POLYC-SELFHOST-PARSER-SLICE07` (closed,
`ACT-Verdict: PASS`), frozen inherited control `N-06`

VERDICT

PASS

---

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. The outcome, in short

**The literal frozen `N-06` experiment has now been executed, and its
detector fired.**  The correction mutates ONLY the selected C
decision, in a disposable detached worktree, rebuilds the REAL
compiler, and runs the witness.

The frozen RECON05 control obliges the successor to *"Mutate ONLY the
selected **C** decision in a disposable worktree, rebuild the real
compiler, and run the witness."*  That obligation is now discharged by
a **new, independent** experiment whose subject is the selected C
decision in `src/parser.c`.

**No history was rewritten, and no production semantics changed.**

```text
DISPOSITION                       = PASS_EVIDENCE_SUPPLEMENTED
SLICE07_HISTORICAL_N06_EXECUTED_AS_WRITTEN = NO
SLICE07_HISTORICAL_S7_CC01_POLYC_MUTATION  = PROVEN
CORRECTION_N06_LITERAL_EXPERIMENT           = PROVEN
CORRECTION_OWN_DISTINCT_EXECUTION_ID        = N06_LITERAL_CORRECTION_EXPERIMENT
HISTORICAL_ARTIFACT_REWRITES                = 0
PRODUCTION_SEMANTIC_DELTA                    = 0
```

---

## 2. What the experiment was

### 2.1 The mutation

One hunk, one line, in the LEGACY (`#else`) arm of
`parseCompoundBlockAppendsStatement` in `src/parser.c`:

```diff
-    if (stmt_kind == AST_DECL && declvar_kind == AST_GVAR) return 0;
+    if (stmt_kind == AST_DECL && declvar_kind == AST_GVAR) return 1;
```

The frozen semantics are `return 0` (SKIP) iff
`stmt_kind == AST_DECL && declvar_kind == AST_GVAR`, and `return 1`
(APPEND) otherwise.  The mutation is the ADVERSARIAL POLARITY FLIP of
that decision: the `AST_DECL && AST_GVAR` class is APPENDED instead of
SKIPPED.  The `&&` short-circuit is preserved, and the host projection
`stmt->declvar->kind` remains conditional.

`src/ast.h`, the PolyC component, the Makefile, `src/CMakeLists.txt`,
the witness and the fixture are **all unchanged**.  The compiled PolyC
subject object is **byte-identical** before and after
(`e2dfbcfcb78261957fb9188916705dcc86d589e82a9d9e169f6ae8118237487c`).

### 2.2 The two compiler configurations

The causal claim is only meaningful in a build where the legacy C
decision is AUTHORITATIVE.  The ACT therefore built TWO real
production compilers from the same entry commit, differing ONLY in the
existing CMake option `HCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND`:

| | C-ON (production) | C-OFF (disposable reference) |
|---|---|---|
| selector | ON | OFF |
| other six authorities | ON | ON |
| parser object imports SUB-003 | **YES** | **NO** |
| executable contains SUB-003 | YES (defined) | **NO (0 occurrences)** |
| legacy C decision in the object | compiled OUT | **LIVE** |
| decision constants in the object | 0x107 only (projection guard) | **0x107 and 0x100** |

No tracked CMake, Makefile or C source was changed to construct either
configuration.  Changing the selector is a CONFIGURATION change, which
the ACT permits explicitly.

### 2.3 The causal result

The frozen detector `CAUSAL_DIRECTION_CHANGE` fired, on three
independent channels:

* **compiler acceptance** -- the pristine C-OFF compiler compiles and
  runs the committed RECON05 witness (`WITNESS_OUTPUT=13 15 2`, exit 0);
  the MUTANT C-OFF compiler **REJECTS** it with `ERROR: Mapping exists
  for 1 -> %l14 i64 local` and produces no executable.
* **compiled-program semantics** -- the four-class fixture compiles and
  prints `FIXTURE_OUTPUT=7 11 21 5 2` under the pristine compiler and
  is REJECTED by the mutant compiler.
* **exact-ID per-row differential** -- over the FROZEN 1753-row
  SLICE07 fixture, the pristine legacy oracle has **0** mismatches and
  the MUTANT legacy oracle differs on **EXACTLY** rows `1, 1750, 1751`
  -- the three `(AST_DECL=263, AST_GVAR=256)` rows -- and on no other
  row, while the PolyC component still matches the expected column on
  every row.

The mutated row IDs are the SAME set SLICE07's PolyC mutation produced.
That is the expected consequence of both subjects implementing the same
frozen semantics, and it is the strongest available confirmation that
the two experiments measured the same decision.

### 2.4 The dormant-branch anti-control

C-ON was rebuilt from the SAME C-mutated source.  Its parser object is
**BYTE-IDENTICAL** to the pristine C-ON parser object
(`253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246`):
the mutation is provably COMPILED OUT of the production path.  The
PolyC SUB-003 import is present, the `AST_GVAR` comparison is absent,
and the witness and fixture outputs are byte-identical to pristine C-ON.
The retired-authority invariant HOLDS.

### 2.5 The restoration

The C source was restored byte-identically
(`2b31a7912bfbcfe538786aff17383a8282da815f0990910a652a0119f084fe17`;
decision range `60a388fac3903ccd45a8dc5e393794e300251715223e5fc9fac2ad455f10cf2d`).
The REBUILT restored parser object is byte-identical to the pristine one
(`db118ef6d648bdd3ceaf9e4e3965723eeebb14e904dd90880088186d20bf4aac`),
and the restored compiler accepts and runs the witness again with the
pristine output hash `5d6f3a9ef366f5489097fbf3f465e21d53c22647237d4e687442cd0698b23cc9`.

---

## 3. The accounting: N-06 versus S7-CC-01

This is the part the correction exists to make honest.

```text
N06_FROZEN_SUBJECT                    = selected C decision
N06_HISTORICAL_SUBJECT                = PolyC source
N06_HISTORICAL_DISPOSITION            = UNPROVEN_AS_WRITTEN
N06_NEW_LITERAL_C_MUTANT              = EXECUTED
N06_NEW_C_ONLY_BUILD                  = SUCCESS
N06_NEW_CAUSAL_DIRECTION              = OBSERVED
S7_CC01_HISTORICAL_POLYC_CAUSALITY     = PRESERVED
N06_AND_S7_CC01_HISTORICALLY_INDEPENDENT = NO
NEW_C_MUTANT_AND_HISTORICAL_POLYC_MUTANT_INDEPENDENT = YES
```

The historical SLICE07 experiment mutated the **PolyC source** and was
reported under **BOTH** `N-06` and `S7-CC-01`.  That was ONE
experiment under TWO control ids, and it remains on the record as
such.  The historical disposition is **NOT** revised.

The new experiment has its OWN execution identity
(`N06_LITERAL_CORRECTION_EXPERIMENT`), its OWN source-diff hash
(`6f0ab1d927b802855f755b898d43037837285354b085fcd1b3bd6946e12dce28`),
and its OWN evidence path.  The independent PolyC auditor re-derives
all three differences from the committed bytes, so the double counting
is explicitly and mechanically avoided.

---

## 4. The negative controls

All EIGHT adverse controls were ACTUALLY EXECUTED, each produced the
EXACT required detector class, and each has a positive control
demonstrating that the detector is SENSITIVE.  None is vacuous.

| NC | Adverse condition | Detector |
|----|-------------------|----------|
| NC01 | Relabel a build with no actual C mutation | Source-hash and scope mismatch |
| NC02 | Offer the C-ON object as the C-OFF oracle | Selector/import/disassembly provenance rejection |
| NC03 | Reuse one C-OFF executable for pristine and mutant | Object/executable identity and causal non-change |
| NC04 | Mutate an unrelated C comparison | Selected source-range/symbol and witness-subject mismatch |
| NC05 | Corrupt one fixture expected row | Fixture exact-ID/semantic mismatch |
| NC06 | Claim a failed build as changed behaviour | Build-success precondition failure |
| NC07 | Restore the C source incompletely | Byte-hash restoration rejection |
| NC08 | Relabel the historical PolyC experiment | Subject + execution-ID + evidence-path join rejection |

The independent PolyC auditor confirms `NC_ROWS_FOUND=8`,
`NC_ROWS_WITH_DETECTOR_CLASS=8`, `NC_ROWS_WITH_POSITIVE_CONTROL=8`,
`NC_ROWS_DETECTOR_MATCHED=8`, `NC_VACUOUS=0`.

---

## 5. The conservation

Measured FRESH at C3 and compared IDENTITY BY IDENTITY with the C0
baseline:

```text
PARSER_ASSERTIONS               = 376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5   = b6f117eb1386ca80f81bc06226e2a741  (identical to C0)
LEXER07_DIRECT_DIFF             = 89/89
LEXER08_DIRECT_DIFF             = 45/45
LEXER09_DIRECT_DIFF             = 23/23
LEXER07_BROAD_CORPUS_STATUS     = FAIL_KNOWN_BASELINE (15 identities,
                                 MD5 7ee761440de83552e751e3c3976c1683, identical to C0)
CROSS_TARGET_PREFIX_STATUS      = FAIL_ENVIRONMENT_PREFIX (67 failures)
F_NO_PYTHON                      = FAIL_KNOWN_BASELINE (exactly 12)
F_POLYC_TOOLS                    = UNAVAILABLE
GATE_FAST                        = PASS
GATE_PUSH                        = PASS
APPEND_ONLY                      = PASS (11/11)
FACTORY_V2_RANGE_CHECK           = PASS
F14                              = PASS
CLOSURE_STATUS                   = PASS
CURRENT_POLYC_PARSER_AUTHORITIES = 7
PRODUCTION_SEMANTIC_DELTA        = 0
```

No residual status was relabelled PASS.  The LEXER07, cross-target,
F-NO-PYTHON and F-POLYC-TOOLS residuals are reported truthfully.

---

## 6. What this ACT did NOT do

* It did **not** rewrite, amend, rebase, reset or force-push history.
* It did **not** edit any closed ACT, HANDOFF or evidence artifact.
  All 1155 frozen predecessor paths still hash to their C0 values.
* It did **not** convert RECON06's HALT into a PASS, and did **not**
  resume RECON06 by adding commits after its CLOSE.
* It did **not** relabel the historical SLICE07 experiment, and did
  **not** claim the new experiment "ran during SLICE07".
* It did **not** add an eighth PolyC parser authority, and did **not**
  select a parser candidate.
* It did **not** authorize SLICE08.
* It did **not** change any tracked `src/**` or `tools/bootstrap/**`
  file.
* It did **not** weaken any gate, and did **not** add Python or a
  dependency.

---

## 7. The residue

```text
RESIDUE_CLASS=P2
RESIDUE_LOCATION=docs/factory/DOCTRINE.md section 27 (F-POLYC-TOOLS)
RESIDUE_REQUIRES_PRODUCTION_CHANGE=NO
RESIDUE_FIXED_IN_THIS_ACT=NO (the checker is not landed; this ACT
  reports it as UNAVAILABLE, which is the honest status)
RESIDUE_DISPOSITION=DEFERRED
```

A second, unrelated residue was observed and is deliberately NOT
repaired, because the ACT forbids it: the
`factory-halt-classification` checker cannot be built on this host
because its inline-assembly blocks do not assemble here.  That checker
is **not** part of the canonical gate graph, and both canonical gates
PASS.  Repairing inline assembly is explicitly out of scope.

---

## 8. The next step

```text
NEXT_ACT        = a FRESH SELECTION ACT (not a SLICE08 implementation)
NEXT_TARGET    = NONE
SLICE08_AUTHORIZED = NO
```

The correction closure allows a fresh selection ACT.  It does not
authorize a migration.  RECON06's HALT stands as a historical fact
about the state of the evidence at the time it was written; the
correction supplies the missing evidence going FORWARD, without
rewriting what was known then.

---

## 9. Where the evidence lives

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01/
  c0/ entry-identity.txt  predecessor-freeze.tsv  frozen-n06-contract.md
      historical-n06-reproduction.tsv  baseline-*.txt
      mandatory-ac-contract.tsv  negative-controls-contract.tsv
      production-authorities.tsv  red-reproduction.txt
  c1/ source-binding.tsv  pristine-c-on.txt  pristine-c-off.txt
      compiled-oracle-and-provenance.tsv  witness-contract.tsv
  c2/ c-only-mutation.diff  c-only-build-and-causality.txt
      dormant-branch-anti-control.txt  source-restoration.txt
      negative-controls-raw.tsv
  c3/ independent-n06-join.tsv  independent-controls-join.tsv
      conservation.txt  gate-fast.txt  gate-push.txt
      factory-invariants.txt  mandatory-ac-status.tsv
  c4/ terminality.txt

tools/quality/parser-slice07-evidence-correction01-audit.HC
```
