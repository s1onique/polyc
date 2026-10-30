# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01`
**Class:** SELFHOST / PARSER / EVIDENCE-INTEGRITY / APPEND-ONLY
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE08` (closed, `ACT-Verdict: PASS`,
left UNCHANGED)
**Factory-Version:** 2

VERDICT

PASS

The authoritative verdict is the `ACT-Verdict` trailer of the CLOSE
commit.  This HANDOFF is a summary, not terminal verdict authority.

**DISPOSITION:** `PASS_EVIDENCE_CORRECTED`

---

## 1. The outcome, in short

**Two evidence-integrity defects in `SLICE08` were reconciled from the
committed bytes.  The historical files were NOT repaired, because
repairing them would rewrite immutable evidence.  The production
transfer is NOT challenged.**

```text
SLICE08_HISTORICAL_CLOSE_VERDICT=PASS_UNCHANGED
SLICE08_C0_FROZEN_CONTROL_ROWS=23
SLICE08_C3_ACTUAL_CONTROL_ROWS=24
SLICE08_C3_HISTORICAL_EXTRA_IDS=SL-EC-06
SL_EC_06_FROZEN_STATUS=FROZEN_OMITTED_FROM_C0
SLICE08_HISTORICAL_AC33_AC35_DISPOSITION=SUPPLEMENTED_BY_THIS_CORRECTION (AC33 and AC35 were NOT independently discharged for SL-EC-06 at the historical C3)
CORRECTION_FROZEN_CONTROL_OBLIGATIONS_PROVEN=24
CORRECTION_SUPPLEMENTAL_CONTROLS=10
ORIGINAL_C1_PRINTED_SHA256=a9a33ff1c3993560f5504582ec372c3f64573caca630e8cda32f58755bbd0fea
FROZEN_RECON07_SOURCE_SHA256=a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
SOURCE_HASH_CHRONOLOGY=the frozen range 1683..1684 held THE LEGACY INLINE PREDICATE (a9fcb6a7..., 175 bytes) at RECON07 CLOSE, RECON07 C0, SLICE08 C0 and SLICE08 C1; the SAME LINE NUMBERS hold A COMMENT FRAGMENT (a9a33ff1..., 94 bytes) at SLICE08 C2, C3 and CLOSE; the DECISION MOVED to 1736..1738 (dc43f25e..., 152 bytes)
PRODUCTION_SEMANTIC_DELTA=0
CURRENT_POLYC_PARSER_AUTHORITIES=8
NEXT_TARGET=NONE
SLICE09_AUTHORIZED=NO
```

---

## 2. Defect 1 -- the inherited-control count

### The measurement

```text
F = 24   the RECON07 frozen obligations
          21 markdown table rows in c2/selected-negative-controls.md
           3 control_id assignments in c2/selected-causal-contract.md
B = 23   the SLICE08 C0 inherited-controls-contract.tsv data rows
J = 24   the SLICE08 C3 inherited-controls-join.tsv data rows

F\B = {SL-EC-06}      B\F = {}
B\J = {}              J\B = {SL-EC-06}
F\J = {}              J\F = {}
```

`F\B` and `J\B` are the **same set**.  The C0 contract dropped
exactly one frozen obligation; the C3 join silently restored it
while asserting `INHERITED_CONTROLS_EXTRA=0`.

### The classification

```text
SL_EC_06_FROZEN_STATUS=FROZEN_OMITTED_FROM_C0
```

RECON07 froze `SL-EC-06` at `c2/selected-negative-controls.md:33`,
inside a hash-frozen contract (`b610dcc8...`):

```text
| SL-EC-06 | Unknown ID or missing required eligibility fact | Unknown-ID or missing-fact-specific detector |
```

The three rival readings are ruled out from the committed bytes:

* **Not `SUPPLEMENTAL_NOT_FROZEN`** -- the ID is in the frozen set.
* **Not `DUPLICATE_OR_ALIAS`** -- the string `SL-EC-06` occurs
  exactly once in the RECON07 negative-controls contract and zero
  times in the causal contract; there is no frozen equivalence clause
  naming it.  The only frozen alias relation is between
  `SL-CC-05` and `RECON07-SUB-002-POST-POLYC-MUTANT`.
* **Not `UNPROVEN_OR_INVENTED`** -- it is in the frozen bytes.

On the SEPARATE execution axis it was unproven: `SL-EC-06` occurs in
exactly one place in the whole SLICE08 evidence tree -- the C3 join
row that makes the claim -- and its `evidence_path` points at that
same file.  **15 of the 24 C3 rows are self-referential in this
way.**  They assert five positive observation flags while binding
no command, exit, object digest, positive baseline or restoration.

### What this correction did about it

The frozen obligation was carried forward and discharged by **two NEW,
correction-owned adverse executions**, reported under their own
execution IDs and **never backdated**:

```text
E8-EC06-A  THE UNKNOWN-ID HALF
  detector  the RECON07 independent recomputer's roster lookup
  adverse   inject one ranking row whose candidate_id is not in the roster
  pristine  MALFORMED=0  STATUS=PASS  exit 0
  adverse   MALFORMED=1  STATUS=FAIL  exit 1

E8-EC06-B  THE MISSING-FACT HALF
  detector  the canonical 13-clause eligibility checker's field count
  adverse   drop the semantic_authority fact from the SUB-002 row
  pristine  MALFORMED=0  STATUS=PASS  exit 0
  adverse   MALFORMED=1  STATUS=FAIL  exit 1
```

Both canonical tools are UNMODIFIED and their digests are the digests
the RECON07 contract asserts.

A fact about the frozen detector is recorded because it is one: the
eligibility **checker** rejects a missing fact but does **not** reject
an unknown id -- it adjudicated the injected unknown id as ELIGIBLE
with all thirteen clauses holding.  The **recomputer** rejects the
unknown id.  The frozen detector is "Unknown-ID **or**
missing-fact-specific detector", so the two together discharge the
obligation.  **Neither alone discharges it.**

---

## 3. Defect 2 -- the source-range digest

### The measurement

```text
git show <commit>:src/parser.c | sed -n '1683,1684p' | shasum -a 256

RECON07-CLOSE 3eb8afa  175 bytes  a9fcb6a7...  THE LEGACY INLINE PREDICATE
RECON07-C0    31b23e2  175 bytes  a9fcb6a7...  THE LEGACY INLINE PREDICATE
SLICE08-C0    331a073  175 bytes  a9fcb6a7...  THE LEGACY INLINE PREDICATE
SLICE08-C1    a1a5303  175 bytes  a9fcb6a7...  THE LEGACY INLINE PREDICATE
SLICE08-C2    c923f65   94 bytes  a9a33ff1...  A COMMENT FRAGMENT
SLICE08-C3    b2188b5   94 bytes  a9a33ff1...  A COMMENT FRAGMENT
SLICE08-CLOSE a43348a   94 bytes  a9a33ff1...  A COMMENT FRAGMENT
```

The DECISION itself moved, and is located by the text of the
condition rather than by inherited line numbers:

```text
MOVED-PREDICATE SLICE08-C2    1736..1738  152 bytes  dc43f25e...
MOVED-PREDICATE SLICE08-CLOSE 1736..1738  152 bytes  dc43f25e...
```

Three mutually distinct byte-range identities, differing in digest, in
length **and** in subject.  **A line number is not a subject.**

### The classification

This is a **CHRONOLOGY DEFECT**, not a typographical mismatch.

The C1 evidence file was committed AT the C1 commit `a1a5303` (blob
`8195bfc4...`, unchanged at CLOSE).  It prints `a9a33ff1...` for
range `1683..1684` and greps four line numbers (1712 / 1754 / 1759 /
1775) for the helper, the oracle, the function and the delegated call
site.  **At the C1 commit none of those existed:**

```text
git show a1a5303:src/parser.c | grep -c parseDefaultArmTerminates  ->  0
git show a1a5303:src/parser.c | grep -n parseDefaultStatement
  1667:Ast *parseDefaultStatement(Cctrl *cc) {
```

and `1683..1684` still held the legacy predicate.  The helper was
first introduced by `c923f65`, the C2 IMPL commit, **after** the C1
commit.  The file also contradicts itself: its body says
`a9a33ff1` while its own summary line says
`SELECTED_SOURCE_SHA256=a9fcb6a7` with `RANGE_MATCH=YES`.

The sub-claim that IS true: the decision did not change at C1.  The
C1 tree carried the RECON07 pristine C source byte for byte --

```text
git show a1a5303:src/parser.c | shasum -a 256
  2b31a7912bfbcfe538786aff17383a8282da815f0990910a652a0119f084fe17
```

which is exactly the frozen
`REC07_PRE_C_MUTANT_SOURCE_SHA256_PRISTINE`.

### The corrected statement

```text
ORIGINAL_HASH_EQUALITY_CLAIM=FALSE
ORIGINAL_C1_CHRONOLOGY_CLAIM=FALSE
CORRECTED_C1_SOURCE_RANGE=1683..1684 (at the C1 commit a1a5303)
CORRECTED_C1_SOURCE_RANGE_DIGEST=a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
CORRECTED_C1_SOURCE_RANGE_BYTES=175
```

---

## 4. The independent auditor

```text
tools/quality/parser-slice08-evidence-correction01-verify.HC
```

A PolyC implementation, 2069 lines, no shell glue.  Six modes:
`FREEZE`, `JOIN`, `PROVENANCE`, `NEGATIVE`, `VERIFY`, `SELFTEST`.

Every decisive fact is derived **by parsing** the bytes of the
committed artifacts.  There is **no hardcoded expected control-ID
list** and **no hardcoded expected summary value**.  The `E8-NC-*`
identifiers it names are the frozen contract identifiers, not a
transcription of the historical rows.

The file digests are computed by the **repository's own** PolyC
SHA-256 tool (`build/lexer07-sha256`) through the process-spawn
surface, so the auditor carries no second digest implementation and
shares none with the artifacts it judges.

The self-test passes **37 of 37** known-answer vectors, including the
FIPS 180-4 digest vectors and the parser's rejection of a malformed
row.

The auditor independently reproduces every C0 finding:

```text
JOIN_F_ROWS=24   JOIN_B_ROWS=23   JOIN_J_ROWS=24
JOIN_F_MINUS_B=1    JOIN_F_MINUS_B_ID=SL-EC-06
JOIN_J_MINUS_B=1    JOIN_J_MINUS_B_ID=SL-EC-06
DETECT_EXTRA_ID=1
DETECT_CLAIMED_COUNT_CONTRADICTS_ROWS=1
DETECT_FROZEN_OMISSION_FROM_C0=1
FREEZE_TOTAL=231  FREEZE_OK=231  FREEZE_MISSING=0  FREEZE_MISMATCH=0
DETECT_FALSE_HASH_EQUALITY=1
DETECT_INTERNAL_SELF_CONTRADICTION=1
PROV_ORIGINAL_HASH_EQUALITY_CLAIM=FALSE
```

---

## 5. The ten correction-owned negative controls

All ten PASS.  Each is a separate physical execution with its own
execution ID, its own disposable directory, its own pristine and
restored digests and its own exit status, run as a
pristine -> targeted mutation -> adverse -> restoration -> restored
sequence.  **The committed historical artifacts are never written
to.**

```text
E8-NC-01  EXTRA_ID                             PASS
E8-NC-02  MISSING_ID                           PASS
E8-NC-03  DUPLICATE_ID                         PASS
E8-NC-04  SUBJECT_OR_PHASE_MISMATCH            PASS
E8-NC-05  FROZEN_SEMANTICS_MISMATCH            PASS
E8-NC-06  CLAIMED_COUNT_CONTRADICTS_ROWS       PASS
E8-NC-07  FALSE_HASH_EQUALITY                  PASS
E8-NC-08  SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH  PASS
E8-NC-09  UNPROVEN_EXECUTION_PROVENANCE        PASS
E8-NC-10  IMMUTABILITY_OR_TRUNCATION_FAILURE   PASS
```

Each fired **its own** reason-specific class, each mutation changed
the bytes, and each restored fixture is byte-identical to its
pristine state.  The verification is by reason, not by exit code
alone.

---

## 6. The independent witness

The independent witness does **not** use the auditor's reported PASS
fields as ground truth.  It recomputes the set differences from the
source data and the source digests from the historical Git objects,
with a **second, distinct implementation**: a POSIX `awk` program
for the reconciliation and a POSIX shell program over the Git objects
for the chronology.  A different language, a different parser, a
different code path.

```text
THE_TWO_IMPLEMENTATIONS_AGREE=YES
COMPLETE_INDEPENDENCE_DEMONSTRATED=YES
```

---

## 7. The historical acceptance criteria

`AC09`, `AC33`, `AC35`, `AC42` and `AC49` are given a truthful,
**non-inherited** disposition in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/c3/original-ac-impact-disposition.tsv`.

The historical ledger is **not** edited and its PASS is **not**
inherited blindly.  The production transfer is **not** challenged:
none of the five bears on the eighth authority, the four-generation
differential, the 41-row fixture or the post-migration PolyC
mutation.  What was defective is the **proof accounting** of two
evidence files.

---

## 8. IDENTITY

```text
ENTRY_HEAD=a43348acc481146853b771609c75e4e0d324e375
ENTRY_TREE=b4447a6bf8adbfc177ad7991dc7593833ad224f9
ENTRY_BRANCH=main
ENTRY_REPLACE_REFS=0
```

The five phase commits of this ACT are recorded in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/c3/factory-v2-f14-append-only.txt`.

---

## 9. RED

Five REDs, each an actual observed failure of the historical claim,
demonstrated with read-only committed-byte comparisons:

```text
RED-1  EXTRA_ID                        the join accepted an ID outside the frozen C0 contract
RED-2  CLAIMED_COUNT_CONTRADICTS_ROWS  the summary understates its own data rows
RED-3  FALSE_HASH_EQUALITY              two unequal digests asserted IDENTICAL
RED-4  SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH  a post-C2 range labelled as entry identity
RED-5  UNPROVEN_EXECUTION_PROVENANCE   an assertion-only row passes as an independent control
```

Three candidate readings were tested and **disproven**, and are
recorded as such rather than papered over with a faked RED.

---

## 10. IMPLEMENTATION

One new bounded substantive tool:

```text
tools/quality/parser-slice08-evidence-correction01-verify.HC
```

plus the Makefile build target for it.  **No production source was
touched.**  The `Makefile` addition is a build rule for the new
tool; it changes no existing rule and no gate.

---

## 11. GATES

```text
GATE_FAST=PASS   EXIT=0
GATE_PUSH=PASS   EXIT=0
PARSER=376/376 over 90 files, ordered MD5 b6f117eb1386ca80f81bc06226e2a741
LEXER_DIRECT=89/89, 45/45, 23/23
LEXER07_BROAD=FAIL (the KNOWN BASELINE, 15 identities, MD5 7ee761440de83552e751e3c3976c1683, preserved honestly and NOT relabelled PASS)
CROSS_TARGET=67 environment-prefix failures (the KNOWN BASELINE, preserved honestly)
F_NO_PYTHON=12 known violations (the KNOWN BASELINE, preserved honestly)
F_POLYC_TOOLS=UNAVAILABLE (the checker is not landed; this ACT does NOT claim it PASSES)
NEW_FAILURE_IDENTITIES=0
```

The two gates were run **serially**, so the shared
`/tmp/holyc-asm.s` was never contended.

---

## 12. SCOPE

```text
FILES_CHANGED=
  docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01.md
  docs/factory/act-handoff-map.tsv                      (one additive row)
  docs/ROADMAP.md                                       (one bounded additive section)
  evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/**
  tools/quality/parser-slice08-evidence-correction01-verify.HC   (new)
  Makefile                                             (one build target for the new tool)
DIFF_CHECK=CLEAN
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO
HISTORICAL_ARTIFACTS_REWRITTEN=0
FROZEN_PREDECESSOR_PATHS_UNCHANGED=231/231
NEW_PYTHON=0
NEW_DEPENDENCIES=0
```

---

## 13. RESIDUE

```text
P0=0
P1=1  the SLICE08 C3 inherited-controls-join.tsv summary block still asserts
      TOTAL=23 and EXTRA=0 against its own 24 rows, and 15 of its rows
      remain self-referential.  Both facts are historical evidence and
      are NOT repaired: F14 forbids it.  The corrected accounting lives
      in this ACT's own ledger.
P2=0
```

---

## 14. NEXT_ACT

```text
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08  (PROPOSED, not authorized)
NEXT_TARGET=NONE
SLICE09_AUTHORIZED=NO
```

**No successor is preselected and SLICE09 is NOT authorized.**  The
proposed successor is a fresh source-bound reconnaissance and
selection after eight authorities.  This correction does **not**
assume SUB-004, does **not** implement SLICE09, and makes neither a
side effect.

---

## 15. The terminal CLOSE and its external receipt

The terminal CLOSE commit carries `ACT-Phase: CLOSE` and
`ACT-Verdict: PASS`.

`CAC28` -- the one terminality criterion -- is discharged by an
**external, read-only, post-CLOSE check** whose receipt is stored
**outside** the repository.  The check verifies the final HEAD and
tree, the phase range, the trailers, a clean worktree, zero replace
refs, the absence of any post-CLOSE commit, the byte-unchanged state
of all 231 frozen predecessor paths, F14, the append-only invariant,
the zero production semantic delta and the gate state.

A failed external check cannot be hidden by appending a stealth
post-CLOSE commit, because the receipt lives outside the tree.

The pre-commit plan is
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/c4/terminality-plan.txt`.

---

See

`docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01.md` and
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01/`.
