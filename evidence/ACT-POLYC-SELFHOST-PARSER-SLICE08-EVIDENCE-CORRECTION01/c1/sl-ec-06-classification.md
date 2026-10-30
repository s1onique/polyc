# SL-EC-06 -- THE FROZEN-STATUS CLASSIFICATION

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01`
**Phase:** C1 -- EVIDENCE
**Evidence kind:** sl-ec-06-classification

---

## 1. The question

Was `SL-EC-06` part of the predecessor's frozen obligation, an extra
supplementary experiment, a C0 omission, or another condition?

The four permitted answers are:

```text
1  SUPPLEMENTAL_NOT_FROZEN
2  FROZEN_OMITTED_FROM_C0
3  DUPLICATE_OR_ALIAS
4  UNPROVEN_OR_INVENTED
```

---

## 2. The classification

```text
SL_EC_06_FROZEN_STATUS=FROZEN_OMITTED_FROM_C0
```

**`SL-EC-06` WAS frozen by RECON07. It WAS omitted from the SLICE08 C0
frozen contract. It WAS present in the SLICE08 C3 join, which then
declared `INHERITED_CONTROLS_EXTRA=0`.**

The four candidate answers are ruled out as follows.

---

## 3. Why it is NOT `SUPPLEMENTAL_NOT_FROZEN` (answer 1)

The RECON07 frozen contract, at its committed bytes, contains the ID:

```text
$ git show 3eb8afa:evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-negative-controls.md
...
33  | SL-EC-06 | Unknown ID or missing required eligibility fact | Unknown-ID or missing-fact-specific detector |
...
```

That file is inside the RECON07 frozen-contract hash set, and its digest
is unchanged:

```text
b610dcc87abc554b82457d19bca2f7809e93755168eacd3a531534f8d66ae62a  evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-negative-controls.md
```

`SL-EC-06` is therefore **in** the frozen set `F`. It is not
supplemental. It is not invented.

The mechanical set difference confirms it:

```text
F\B = {SL-EC-06}
```

---

## 4. Why it is NOT `DUPLICATE_OR_ALIAS` (answer 3)

An alias would require a **frozen** equivalence clause naming `SL-EC-06`
as another control's name. There is none.

The RECON07 frozen bytes contain exactly **one** occurrence of the
string `SL-EC-06`:

```text
$ grep -c 'SL-EC-06' evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-negative-controls.md
1
```

and exactly **one** occurrence in `selected-causal-contract.md`:

```text
$ grep -c 'SL-EC-06' evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-causal-contract.md
0
```

There is no "SL-EC-06 = SL-EC-xx" clause, no alias note, no
"same obligation as" note. The only alias relation that RECON07 froze is
a different one, and it is between two other IDs:

```text
SL-CC-05  ==  RECON07-SUB-002-POST-POLYC-MUTANT
```

which the SLICE08 C0 contract documents at length, with a shared
physical execution. `SL-EC-06` has no such clause. It is its own
obligation.

The candidate reading "`SL-EC-06` was discharged by `S8-FC-03`
('Inject unknown fixture ID')" is **disproven on subject and
detector**:

```text
SL-EC-06  subject   = the SUB-002 ELIGIBILITY FACTS
           detector  = Unknown-ID or missing-fact-specific detector
S8-FC-03  subject   = the frozen 41-row FIXTURE
           detector  = Unknown ID with no false missing
```

A fixture-row detector is not an eligibility-fact detector. Moreover
there are **zero** eligibility-class controls among the 18 new `S8-*`
controls:

```text
$ grep -cE '^S8-EC-' evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c0/new-controls-contract.tsv
0
```

---

## 5. Why it is NOT `UNPROVEN_OR_INVENTED` (answer 4)

It is not invented: it is in the frozen RECON07 bytes (§3).

It is, however, **unproven as an executed experiment**, and that is a
separate axis from its frozen status. The classification above records
the *frozen status*, not the *execution status*. The execution status
is `ORIGINAL_UNPROVEN`, and it is established by the following
measurement, which is a matter of record, not of interpretation:

```text
$ grep -rn 'SL-EC-06' evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08//c3/inherited-controls-join.tsv:38:SL-EC-06  ELIGIBILITY ...
```

`SL-EC-06` occurs in **exactly one** place in the entire SLICE08
evidence tree: the C3 join row that makes the claim. There is no
command, no exit status, no object digest, no positive baseline and no
restoration record for it. Its own `evidence_path` field points at
`c3/inherited-controls-join.tsv`, the file that contains the assertion.

---

## 6. Why it is `FROZEN_OMITTED_FROM_C0` (answer 2)

The C0 frozen contract for the inherited controls is the SLICE08 file
`c0/inherited-controls-contract.tsv`. Its header claims:

```text
# THE INHERITED NEGATIVE CONTROLS.  These are the controls the
# RECON07 predecessor froze FOR THE SUCCESSOR, in the committed
# file c2/selected-negative-controls.md, PLUS the three
# time-scoped causal controls in c2/selected-causal-contract.md.
#
# Their IDs and their SEMANTICS are COPIED VERBATIM from those
# committed bytes.  None is improvised, renumbered or omitted.
```

It then lists 23 rows. `SL-EC-06` is **not** among them.

The omission is unambiguous:

```text
RECON07 froze          24 obligations
SLICE08 C0 copied      23
SLICE08 C3 joined      24
```

and the missing one is `SL-EC-06`. The file's own claim -- "None is
improvised, renumbered or omitted" -- is false with respect to this
single ID.

### 6.1 The three-way arithmetic

```text
F = 24   RECON07 frozen obligations
B = 23   SLICE08 C0 frozen contract
J = 24   SLICE08 C3 join

F\B = {SL-EC-06}
B\F = {}
B\J = {}
J\B = {SL-EC-06}
F\J = {}
J\F = {}
```

`F\B` and `J\B` are the **same set**. The C0 contract dropped exactly
one frozen obligation; the C3 join silently restored it while asserting
that nothing extra was present.

### 6.2 The consequence for the C3 summary block

The C3 join file asserts:

```text
INHERITED_CONTROLS_TOTAL=23
INHERITED_CONTROLS_JOINED=23
INHERITED_CONTROLS_EXTRA=0
```

against **24** actual data rows. The `EXTRA=0` claim is **false as a
row-set measurement**: measured against the C0 frozen contract there is
exactly **one** extra ID, and it is `SL-EC-06`.

Two readings are possible and this correction does **not** choose
between them on intent grounds:

1. The C3 author counted the C0 contract's 23 and added a row for the
   genuinely-frozen `SL-EC-06` without updating the summary; or
2. The C3 author treated `SL-EC-06` as an in-contract control and the
   summary was simply never recomputed.

Under **both** readings the historical summary is wrong as a
row-set measurement, and under neither reading may this correction
assert that the C0 contract contained 24 rows. It contained 23.

---

## 7. The effect on the SLICE08 acceptance criteria

```text
SLICE08 AC33  "All RECON07 frozen successor controls executed/verified
               by unchanged IDs and subjects."
```

At the C3 commit, `SL-EC-06` had **no adverse execution evidence**. The
only record of it is the row asserting that it had one. Therefore
`AC33` as of the historical C3 was **not independently discharged** for
`SL-EC-06`, and the C3 evidence did not distinguish an assertion-only
row from an executed one.

```text
SLICE08 AC35  "No vacuous control, double-discharge, wrong-subject or
               forged prior event."
```

The `SL-EC-06` row asserted `independent_verification=YES` with no
external execution evidence. That is the defect RED-5 describes.

```text
SLICE08 AC42  "All generation/object/caller/provenance and
               subject/phase/execution-ID joins independently checked."
```

The inherited-control join was not independently checked against the
frozen contract, because the frozen contract itself was missing an ID
and the summary block was never reconciled against the rows.

This correction does **not** rewrite those historical ACs. It records
their truthful disposition at C3 and discharges the underlying
obligation with **new, correction-owned** evidence.

---

## 8. What this correction does with the obligation

Per the ACT, a supplemental C3 row alone cannot repair a missing C0
frozen obligation. Therefore:

1. The C3 row for `SL-EC-06` is reclassified as
   `ORIGINAL_EXTRAROW_NOT_FROZEN` **in the historical join sense** and
   `ORIGINAL_UNPROVEN` **in the execution sense** -- the row is not
   evidence of anything except that the claim was made.
2. The frozen obligation `SL-EC-06` -- "Unknown ID or missing required
   eligibility fact", detector "Unknown-ID or missing-fact-specific
   detector", subject "the SUB-002 eligibility facts" -- is carried
   forward into the correction-owned ledger as a **frozen obligation
   requiring a NEW, NAMED adverse execution**.
3. That new execution is performed at C2 in a disposable copy and is
   reported under a **correction-owned execution ID**. It is **never**
   backdated to SLICE08 C0 or C3.

---

## 9. The frozen contract text, verbatim

```text
| SL-EC-06 | Unknown ID or missing required eligibility fact | Unknown-ID or missing-fact-specific detector |
```

```text
source: evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/c2/selected-negative-controls.md
line:   33
sha256: b610dcc87abc554b82457d19bca2f7809e93755168eacd3a531534f8d66ae62a
```

---

## 10. The summary

```text
SL_EC_06_FROZEN_STATUS=FROZEN_OMITTED_FROM_C0
SL_EC_06_IN_RECON07_FROZEN_SET=YES
SL_EC_06_IN_SLICE08_C0_CONTRACT=NO
SL_EC_06_IN_SLICE08_C3_JOIN=YES
SL_EC_06_C3_ROW_EXECUTION_EVIDENCE=NONE (ASSERTION_ONLY)
SL_EC_06_C3_EVIDENCE_PATH=SELF-REFERENTIAL (the join file itself)
SL_EC_06_ORIGINAL_EXECUTION_STATUS=ORIGINAL_UNPROVEN
SL_EC_06_ORIGINAL_JOIN_STATUS=ORIGINAL_EXTRAROW_NOT_FROZEN
SL_EC_06_CORRECTION_DISPOSITION=REQUIRES_NEW_NAMED_ADVERSE_EXECUTION
SLICE08_C3_INHERITED_CONTROLS_EXTRA_CLAIM=FALSE (the true row-set extra is 1: SL-EC-06)
SLICE08_HISTORICAL_ARTIFACT_REWRITES=0
```
