# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06`
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-SLICE07-SELECTION
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE07` (closed, `ACT-Verdict: PASS`)

VERDICT

HALT_N06_FROZEN_OBLIGATION_UNPROVEN

---

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. The outcome, in short

**No candidate was selected, and no eighth PolyC parser authority is
authorized.**  The ACT halted at its C0 entry audit because the
predecessor's frozen inherited negative control `N-06` was **not
discharged as written**.

The frozen RECON05 control obliges the successor to *"Mutate ONLY the
selected **C** decision in a disposable worktree, rebuild the real
compiler, and run the witness."*  The committed SLICE07 C3 evidence
records that the executed mutation was of the **PolyC** source:

```text
MUTATION_SCOPE=tools/bootstrap/selfhost-parser-slice07.HC ONLY
MUTATION_IS_IN_SRC_PARSER_C=NO
```

and the predecessor's own C1 file states that the single experiment's
result *"is reported under BOTH N-06 and S7-CC-01"*.

No frozen RECON05 artifact authorises that substitution.  The whole
frozen `c2/` corpus contains **zero** such clause, and the frozen
`selected-red-contract.md` RED-05 successor-state column affirmatively
requires *"the C decision is delegated"*, so after the migration there
is no active C decision left to mutate.  The equivalence-permission
text exists only in SLICE07's own C0 artifact -- authored by the
successor that performed the substitution -- which is exactly the
retroactive reinterpretation the ACT's `N06_EQUIVALENCE_PERMITTED_AND_PROVEN`
outcome forbids.

```text
N06_DISPOSITION = N06_UNPROVEN
HALT_REASON     = HALT_N06_FROZEN_OBLIGATION_UNPROVEN
HALT_CLASS      = GOVERNANCE
BLOCKS_NEXT     = NO
```

The full audit, with the five required answers and the evidence for
each, is at
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-literal-control-audit.md`.
The machine-checked join row is at
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-literal-control-audit.tsv`.
The independent PolyC re-derivation is at
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-machine-verification.txt`.

---

## 2. What the halt does NOT say

### 2.1 The seven PolyC parser authorities are real and conserved

This ACT re-verified all seven **independently from the live build**,
not from the predecessor's prose:

```text
CURRENT_POLYC_PARSER_AUTHORITIES = 7
AUTHORITIES_WITH_SELECTOR_ON      = 7
AUTHORITIES_SUBJECT_DEFINES_SYMBOL= 7
AUTHORITIES_CALLER_IMPORTS_SYMBOL = 7
AUTHORITIES_LINKED_IN_EXECUTABLE  = 7
AUTHORITIES_WITH_RETIRED_C_DECISION = 7
```

The legacy C decision is compiled out of the active production path:
the only AST-kind comparison left in `_parseCompoundStatementInternal`
is the single `cmp w0, #263` (AST_DECL) field-read guard, and the count
of comparisons against `#256` (AST_GVAR) is **zero**.  The delegation
is load-bearing: a `BRANCH26` relocation at 0x3a68 targets
`_BootstrapCompoundBlockAppendsStatement` from inside that function.

The SUB-003 migration is a fact about the built compiler.  It is not a
conclusion drawn from `N-06`.

### 2.2 SLICE07's historical CLOSE is untouched

Per F14, this ACT does **not** rewrite, reopen or invalidate SLICE07's
CLOSE.  The predecessor's five-commit range, its trailers, its canonical
Factory-v2 range check and its external terminality receipt were all
re-verified and PASS:

```text
PREDECESSOR_SLICE07_CLOSE_VERIFIED      = YES
PREDECESSOR_SLICE07_COMMIT_COUNT       = 5
PREDECESSOR_SLICE07_TRAILERS_VALID      = YES
PREDECESSOR_SLICE07_TERMINALITY_RECEIPT = YES
PREDECESSOR_SLICE07_ZERO_POST_CLOSE_COMMITS = YES
FROZEN_PATH_COUNT                       = 298
FROZEN_PATH_MISMATCHES                  = 0
FROZEN_PATH_MISSING                     = 0
```

The finding is about the completeness of the predecessor's *control
bookkeeping*, not about the validity of its commit graph.

### 2.3 No claim is made about candidate availability

The census, the eligibility run, the ranking, the object-level G0
oracle, the fixture, the causal proof and the twenty negative controls
were **not executed**.  They are forward obligations of phases C1, C2
and C3, which this ACT never reached.  No candidate is claimed to exist
or not to exist.

---

## 3. The required correction

```text
PROPOSED_CORRECTION_ACT   = ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01
PROPOSED_CORRECTION_CLASS = EVIDENCE-HYGIENE (no production change)
NEXT_ACT_STATUS           = ACTIVE
NEXT_TARGET               = NONE
```

The correction must be **append-only** and must, at minimum:

1. **Execute the literal N-06 experiment** -- mutate ONLY the selected C
   decision in a disposable detached worktree, rebuild the real
   compiler, run the witness -- and record it as N-06's OWN evidence,
   separately from S7-CC-01; **or**
2. **Record an explicit, pre-declared, frozen amendment** authorising
   the successor-authority analogue, acknowledging that the frozen
   RED-05 successor-state column requires the C decision to be
   delegated, and stating exactly what is amended and why the frozen
   text was unsatisfiable as written; **and**
3. **Disambiguate the N-06 / S7-CC-01 double reporting** so that one
   experiment is not reported as two independent control discharges.

**No production source change is required, and none is proposed.**

`SLICE08` is **not** authorized.  It requires an ACT whose own
selection and terminality succeed; this ACT's selection did not happen.

---

## 4. The measured baseline (honest, including the historical failures)

Every baseline was measured at C0, with all build, JIT, test and gate
runs **serialized** (the shared `/tmp/holyc-asm.s` is a known race
risk, and no two runs overlapped).

```text
PARSER_HOST_ARCH_ASSERTIONS    = 376/376 over 90 test files
PARSER_ASSERTION_SEQUENCE_MD5  = b6f117eb1386ca80f81bc06226e2a741
NEW_PARSER_FAILURE_IDENTITIES  = 0

LEXER07_DIRECT_DIFFERENTIAL    = 89/89 PASS
LEXER08_DIRECT_DIFFERENTIAL    = 45/45 PASS
LEXER09_DIRECT_DIFFERENTIAL    = 23/23 PASS
NEW_LEXER_FAILURE_IDENTITIES   = 0

LEXER07_BROAD_CORPUS           = FAIL_KNOWN_BASELINE
LEXER07_FAILURE_IDENTITY_COUNT = 15
LEXER07_FAILURE_IDENTITY_MD5   = 7ee761440de83552e751e3c3976c1683
LEXER07_BROAD_CORPUS_REGRESSION = 0
LEXER07_BROAD_CORPUS_DIVERGED   = 0

CROSS_TARGET                   = FAIL_ENVIRONMENT_PREFIX
CROSS_TARGET_FAILED_TO_OPEN_FILE = 67
CROSS_TARGET_PASSED            = 0

F_NO_PYTHON                     = FAIL_KNOWN_BASELINE (exactly 12, zero new)
F_POLYC_TOOLS                   = UNAVAILABLE (its checker is not landed)

GATE_FAST                       = PASS
GATE_PUSH                       = PASS
APPEND_ONLY                     = PASS (11/11)
FACTORY_V2_RANGE_CHECK          = PASS
PATCH_HYGIENE                   = PASS
```

The historical failures are **preserved honestly** and are never
relabelled PASS.  `F_POLYC_TOOLS` is `UNAVAILABLE`, never PASS.

One documented, expected, NON-FATAL diagnostic appears in the unit-test
log: the runtime-prefix install prints `ld: Undefined symbols: _Errno`
and `hcc -lib exited with code 1; this is expected when all.o
references _Errno.  Continuing.`  That is the documented behaviour of
`src/CMakeLists.txt:1872`; there are zero `FAILED:` assertion lines and
the suite exits 0.  It is recorded so that a reader who greps the raw
log for "error" is not misled.

---

## 5. The RECON06 verifier

`tools/quality/parser-surface-recon06-audit.HC` is the ACT's only new
substantive verifier.  It is a **PolyC** implementation
(F-POLYC-TOOLS compliant), built and run with the actual compiler.

```text
./hcc --install-dir=./build/test-prefix -c \
      tools/quality/parser-surface-recon06-audit.HC \
      -o build/parser-surface-recon06-audit.o
cc build/parser-surface-recon06-audit.o \
   -L./build/test-prefix/lib -ltos -o build/parser-surface-recon06-audit
```

| Mode | Purpose |
|---|---|
| `FREEZE <paths> <out>` | generate the `sha256<TAB>path` manifest |
| `VERIFY <manifest>` | re-check a manifest -- the F14 detector |
| `N06 <recon05-dir> <slice07-dir>` | mechanically re-derive the decisive N-06 facts |
| `SELFTEST` | SHA-256 known-answer vectors; proves the tool is not a no-op |

Its SHA-256 output was cross-validated against `shasum -a 256`, and its
digest for the RECON05 ACT document equals the one SLICE07 froze
(`89a0d1660a7aa96c632d200e84f9074ea2a3b6fad0c3cf9771992d4bf71a1b71`).

Its `N06` mode independently reproduces the audit:

```text
N06_FROZEN_TEXT_FOUND=1
N06_FROZEN_CORPUS_ANALOGUE_CLAUSES=0
N06_FROZEN_RED05_REQUIRES_C_DELEGATED=1
N06_SLICE07_C0_EQUIVALENCE_NOTE_PRESENT=1
N06_C3_MUTATION_NOT_IN_SRC_PARSER_C=1
N06_C3_N06_ROW_SHARES_THE_S7CC01_DIAGNOSTIC=1
N06_C3_S7CC01_ROW_SHARES_THE_N06_DIAGNOSTIC=1
N06_C3_MUTANT_PRODUCTION_BUILD_SUCCESS=1
N06_C3_RESTORATION_BYTE_IDENTICAL=1
N06_Q_A_C_DECISION_MUTANT_EXECUTED=0
N06_Q_B_EQUIVALENCE_EXPLICITLY_PERMITTED=0
N06_Q_C_RECON05_EVIDENCE_ELIGIBLE_AS_DISCHARGE=0
N06_Q_D_N06_AND_S7CC01_INDEPENDENT=0
N06_Q_E_REAL_COMPILER_REBUILD_AND_WITNESS=1
N06_DISPOSITION=N06_UNPROVEN
```

---

## 6. The REDs

Five REDs were reproduced; none is a no-op witness.

| RED | What fails | Disposition |
|---|---|---|
| RED-01 | the N-06 frozen subject is not the mutated subject | FAIL -- principal RED |
| RED-02 | no frozen clause authorises the substitution | FAIL |
| RED-03 | the historical RECON05 C-mutation evidence cannot discharge a SLICE07-run obligation | FAIL |
| RED-04 | N-06 and S7-CC-01 are one experiment under two ids | FAIL |
| RED-05 | the detector fired on the wrong subject | FAIL (the experiment itself was real) |
| RED-06 | the verifier is not a no-op | PASS (this is the discrimination witness) |

The ACT's section 7 step 5 also names six census/ranking/oracle/causal
REDs.  Those are **forward obligations** of C1 and C2, are **not**
claimed as reproduced, and are recorded as such.

---

## 7. The acceptance ledger

The fifty predicates are frozen in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/mandatory-ac-contract.tsv`.
Because the ACT halted at C0, **none** of them was observed as a
terminal PASS; the C0 contract is a frozen definition, not a result.

```text
MANDATORY_AC_TOTAL    = 50
MANDATORY_AC_PASS     = 0
MANDATORY_AC_FAIL     = 0
MANDATORY_AC_UNPROVEN = 50
```

The twenty negative controls are frozen in
`c0/frozen-negative-controls.tsv` and were **not** executed, because
they bind to a selected candidate and no candidate was selected.

```text
NEGATIVE_CONTROLS_TOTAL        = 20
NEGATIVE_CONTROLS_INTENDED_PASS = 0
NEGATIVE_CONTROLS_UNPROVEN     = 20
```

---

## 8. The scope of change

```text
PRODUCTION_SEMANTIC_DELTA      = 0
SUCCESSOR_IMPLEMENTATION_DELTA = 0
TRACKED src/** MUTATIONS       = 0
TRACKED tools/bootstrap/** MUTATIONS = 0
NEW PYTHON                     = 0
NEW DEPENDENCIES               = 0
NEW POLYC AUTHORITIES          = 0
```

The only new tool is the RECON06 PolyC verifier.  No gate was weakened.
No historical ACT, HANDOFF or evidence tree was modified.

---

## 9. The residue

```text
RESIDUE_CLASS = P1
RESIDUE_LOCATION = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c3/inherited-controls-join.tsv
                   (and c3/new-controls-join.tsv, c1/negative-control-red.txt)
RESIDUE_DESCRIPTION = the N-06 control's literal subject was substituted
                      and its result was reported under two control IDs
RESIDUE_REQUIRES_PRODUCTION_CHANGE = NO
RESIDUE_FIXED_IN_THIS_ACT = NO (by design: F14 forbids editing a closed artifact)
RESIDUE_DISPOSITION = HANDED TO A PROPOSED SEPARATE CORRECTION ACT
```

The separate backlog (the SLICE06 stale producer path, the historical
LEXER07 FAIL, the 67 cross-target prefix failures, the 12 F-NO-PYTHON
violations, the unlanded F-POLYC-TOOLS checker, the shared
`/tmp/holyc-asm.s` race, and the whole-function/AST-graph ownership
work) is **unchanged** by this ACT.

---

## 10. Where the evidence lives

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/
  entry-identity.txt
  predecessor-terminal-verification.txt
  predecessor-freeze.tsv
  n06-literal-control-audit.tsv
  n06-literal-control-audit.md
  n06-machine-verification.txt
  baseline-parser.txt
  baseline-lexer.txt
  baseline-lexer07.txt
  baseline-cross-target.txt
  baseline-tool-policy.txt
  baseline-gates.txt
  existing-production-authorities.tsv
  mandatory-ac-contract.tsv
  frozen-negative-controls.tsv
  red-reproduction.txt
```

No `c1/`, `c2/`, `c3/` or `c4/` evidence tree exists, because those
phases were not executed.
