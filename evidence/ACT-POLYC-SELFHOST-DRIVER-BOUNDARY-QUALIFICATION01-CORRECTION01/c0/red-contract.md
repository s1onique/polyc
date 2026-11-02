# C0 RED CONTRACT

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01`

**Phase:** C0 — RED / AUTHORIZATION

**Contract status:** FROZEN. The REDs below are specified BEFORE the
correction verifier exists. They are executed at C1 against the
EXISTING vulnerable acceptance machinery, and their actual results are
recorded before any fix.

---

## 1. What a RED is here

A RED is a **bounded, mechanical, reproducible** demonstration that the
predecessor's committed acceptance machinery accepts something it must
not accept — or that its committed arithmetic disagrees with its own
rows.

A RED is NOT:

- an opinion about the predecessor's verdict;
- a fresh measurement substituted for a historical one;
- a mutation of the frozen inputs.

The frozen inputs are read-only. Every adverse RED runs against a
**DISPOSABLE COPY** in a temporary directory.

---

## 2. The RED roster

| RED | Subject | What must be demonstrated | Vulnerable machinery exercised |
|---|---|---|---|
| R1 | Frozen AC phase drift | The predecessor's ledger records a phase for each AC that DISAGREES with the frozen phase, and the predecessor's acceptance machinery does not detect the disagreement | predecessor Q3 ledger + predecessor Q2 verifier `ACCEPT` mode |
| R2 | Frozen AC predicate substitution | The predecessor's ledger binds a witness whose content does NOT discharge the frozen predicate for that AC, and the predecessor's acceptance machinery accepts the binding | predecessor Q3 ledger + predecessor Q2 verifier `ACCEPT` mode |
| R3 | Ledger status arithmetic | The predecessor's ledger's own criterion rows sum to a status partition that disagrees with the ledger's own written summary | predecessor Q3 ledger summary vs its rows |
| R4 | Handoff/ledger count disagreement | The predecessor's handoff states a criterion count that matches NEITHER the ledger's criterion rows NOR the ledger's written summary | predecessor handoff vs predecessor ledger |
| R5 | Witness path binding | The predecessor's ledger cites a witness path that does NOT exist in the predecessor's close tree | predecessor Q3 ledger + `git ls-tree` at the predecessor close |
| R6 | Route-scope laundering | The predecessor's route matrix records a token-route witness under a scope that a required-route-only reading would count as required-route proof | predecessor Q1 route matrix |
| R7 | Baseline NOT_REMEASURED laundering | The predecessor's handoff textual claim asserts a fresh conservation that the committed baseline ledger records as NOT_REMEASURED | predecessor handoff vs predecessor Q3 baseline ledger |
| R8 | Detector capability backdating | The predecessor's Q0 detector source does NOT contain six reason tokens that the frozen Q0 roster names | predecessor Q0 detector source vs predecessor Q0 frozen NC roster |

---

## 3. The RED commands (POSIX / Git only, no Python)

Each command is reproducible from the repository root with the
predecessor's objects read directly from the Git object store.

```sh
PRE=907af8c82abfb2292d5eccfdf18b63080da767f2
CLOSE=edfc3b16620e8d84b00a276984109a3b2fa8b338
E=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
```

### R1 — phase drift

```sh
join -t"$(printf '\t')" -1 1 -2 1 \
  <(git show "$PRE:$E/q0/frozen-ac01-ac50.tsv" \
     | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$2}' | sort) \
  <(git show "$PRE:$E/q3/acceptance-ledger.tsv" \
     | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$2}' | sort) \
| awk -F'\t' '$2 != $3 {print $1, "frozen="$2, "ledger="$3}'
```

**RED is REPRODUCED** iff the output is non-empty. Each printed row is
one frozen-phase drift.

### R2 — predicate substitution

For each `AC01..AC50`, extract the frozen predicate and the ledger's
claimed measurement, then compare them **semantically**: a ledger row
whose witness artifact path does not appear anywhere in the frozen
predicate's subject matter, and whose measured text shares no content
token with the frozen predicate, is a substitution candidate.

The mechanical, reproducible form of this test:

```sh
git show "$PRE:$E/q0/frozen-ac01-ac50.tsv" \
| awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$3}' | sort > /tmp/frozen-pred.tsv
git show "$PRE:$E/q3/acceptance-ledger.tsv" \
| awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$4"\t"$5}' | sort > /tmp/ledger-claim.tsv
```

Then, for each AC, tokenise the frozen predicate and the ledger claim
into lowercased alphanumeric words of length >= 4, and compute the
**shared-token count**. A frozen predicate and a ledger claim with
**ZERO shared content tokens** are, by construction, about different
subjects: the ledger does not discharge the frozen predicate.

This test is conservative: it only flags pairs that share no content
word at all. It CANNOT produce a false positive for a genuine
substitution of wording, and it CANNOT miss a total subject change.

### R3 — ledger status arithmetic

```sh
git show "$PRE:$E/q3/acceptance-ledger.tsv" \
| awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {c[$3]++} END {for (s in c) print s, c[s]}'
```

Compare against the ledger's own written summary (`LEDGER_PASS`,
`LEDGER_FAIL`, `LEDGER_DEFERRED`).

**RED is REPRODUCED** iff the criterion-only partition differs from the
written summary.

### R4 — handoff vs ledger

Extract `ACCEPTANCE_LEDGER` from
`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md`
at `$PRE`, and compare it with BOTH the criterion-only partition and
the written summary.

**RED is REPRODUCED** iff the handoff figure equals neither.

### R5 — witness path binding

For every ledger row, resolve the claimed witness path against the
predecessor CLOSE tree:

```sh
git ls-tree -r --name-only "$CLOSE" -- "$E/" | sort > /tmp/close-tree.txt
```

A ledger row whose claimed path is NOT in that list is a binding error.

**RED is REPRODUCED** iff at least one row's claimed path is absent.

### R6 — route-scope laundering

Extract from the predecessor Q1 route matrix the `route_scope` of each
branch, and the route actually exercised by its witness. A branch whose
`route_scope` is `WHOLE_CLI_SURFACE` but whose observed witness route
is a non-required route (e.g. `-tokens`) CANNOT be counted as
required-route proof.

**RED is REPRODUCED** iff such a row exists AND the predecessor's
overall remainder counts include it.

### R7 — baseline NOT_REMEASURED laundering

Extract from the predecessor Q3 baseline ledger every row whose
`status` is `NOT_REMEASURED` or `CONSERVED_AS_NOT_REMEASURED`, and
compare with the predecessor handoff's textual conservation claim.

**RED is REPRODUCED** iff the handoff asserts a fresh PASS over a
baseline the committed ledger records as NOT_REMEASURED.

### R8 — detector capability backdating

```sh
for tok in CORRECTION_CLOSE_IDENTITY_WRONG \
           NON_ACT_TRAILER_PROMOTED \
           HISTORICAL_CLOSE_DUPLICATE_HIDDEN \
           MUTATION_LINK_PROVENANCE_MISSING \
           G0_DRIVER_CONTAMINATED \
           COMPILER_SEMANTIC_COMPARATOR_INSENSITIVE ; do
  git show "$PRE:tools/quality/driver-boundary-qualification01-red.HC" \
  | grep -q "$tok" && echo "Q0_HAS $tok" || echo "Q0_LACKS $tok"
done
```

**RED is REPRODUCED** iff at least one token is `Q0_LACKS`.

---

## 4. What the REDs do NOT establish

- A RED against the predecessor's machinery does NOT prove the
  predecessor's underlying audit was wrong. It proves the predecessor's
  **acceptance bookkeeping** did not detect a discrepancy that this
  correction CAN detect.
- A RED does NOT license rewriting the predecessor's ledger. The
  predecessor's ledger is historical evidence (F14). This correction
  records a **forward-only reconciliation**.
- A RED does NOT license inventing a historical measurement. Where the
  historical evidence is insufficient, the criterion is `UNPROVEN` or
  `UNSUPPORTED_BY_CITED_WITNESS`, not `PASS`.

---

## 5. HALT condition

If the **principal** REDs — R1, R3, R5 — cannot be reproduced against
the actual committed objects:

```text
HALT_RED_NOT_REPRODUCED
```

and no correction verifier is implemented.

Secondary REDs (R2, R4, R6, R7, R8) that do not reproduce are recorded
as `NOT_REPRODUCED` and do not block the ACT.

---

## 6. The FIX (specified now, implemented at C2)

The fix is a NEW compiled PolyC verifier:

```text
tools/quality/driver-boundary-qualification01-correction01-verify.HC
```

with modes:

```text
ACSET ACPHASE ACPREDICATE ACWITNESS ACCOUNTING
ROUTES DECISION BASELINE CHRONOLOGY SELFTEST
```

plus an independent POSIX/Git witness that recomputes the same facts
without sharing the compiled verifier's comparison algorithms.

The predecessor's detector and verifier are NOT modified.

The fix must make the REDs **PASS** in the sense of: the new machinery
REJECTS the adverse condition with its own exact reason token, and
ACCEPTS the pristine historical inputs.

---

## 7. Frozen at C0

```text
RED_ROSTER_SIZE = 8
PRINCIPAL_REDS  = R1 R3 R5
SECONDARY_REDS  = R2 R4 R6 R7 R8
```

These REDs, the 32-ID acceptance roster and the 18-ID negative-control
roster are FROZEN. They are not edited to obtain a PASS.
