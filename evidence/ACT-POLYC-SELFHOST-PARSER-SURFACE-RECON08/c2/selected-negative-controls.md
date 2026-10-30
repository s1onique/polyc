# The Selected Successor Contract — Negative Controls

**ACT:** ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
**Selected candidate:** `SUB-004`

---

## 1. The 24-control roster for RECON08

The roster is frozen at C0 in
`c0/frozen-24-negative-controls.tsv` and its count is derived from its
rows: **24**.

| Class | IDs | Count |
|---|---|---|
| INVENTORY / IDENTITY | `R8-IC-01` … `R8-IC-04` | 4 |
| ELIGIBILITY | `R8-EC-01` … `R8-EC-06` | 6 |
| RANKING | `R8-RC-01` … `R8-RC-05` | 5 |
| CAUSAL (selected subject) | `R8-CC-01` … `R8-CC-04` | 4 |
| PROVENANCE | `R8-PV-01` | 1 |
| EXECUTION | `R8-XC-01` … `R8-XC-04` | 4 |
| **total** | | **24** |

**Physical executions: 25.** `R8-EC-06` requires TWO distinct
physical executions — one per detector half. The physical count is
derived from the per-row `physical_executions` column of
`c2/negative-control-raw-results.tsv`, not asserted to equal 24.

---

## 2. The join invariant

The C3 join compares the **frozen** roster against the **observed**
roster **by exact ID**. It derives every count from the two files and
never trusts a claimed `TOTAL`.

```
FROZEN_CONTROL_COUNT=24
OBSERVED_CONTROL_IDS=24
MISSING=0
EXTRA=0
DUPLICATE=0
UNEXECUTED=0
SELF_REFERENTIAL=0
WRONG_SUBJECT=0
```

The exact-ID diff is what rejects an omitted ID. This is the
**SL-EC-06 mistake**, and this ACT's roster is built so that it
cannot recur: the roster file's count is derived from its rows, and
the join reports `MISSING_ID=<the omitted id>`.

---

## 3. The four selected-subject controls

These four concern the **actual final selected candidate** `SUB-004`,
and they were executed against it:

| ID | What was actually executed |
|---|---|
| `R8-CC-01` | the real `src/parser.c` mutated in a detached worktree, the **real production compiler rebuilt**, and the frozen witness re-run: the pristine compiler says *"while parsing if body"*, the mutant says *"while parsing while loop body"*, the restored says *"while parsing if body"* again |
| `R8-CC-02` | the genuine production TU object **passes** the G0-provenance detector with 12/12 constructor relocations; a handmade oracle and a PolyC-importing oracle are both **rejected** with `G0_NOT_GENUINE_C_TU`, each with its own distinct reason |
| `R8-CC-03` | the source-derived fixture **passes**; a fixture with one corrupted expected value is **rejected** with the exact row `FX-0003` and both the expected and the actual value |
| `R8-CC-04` | the function-scoped relocation table shows the mutant's `parseStatement` carrying **two** `_parseWhileStatement` relocations and **zero** `_parseIfStatement` relocations inside its own range, while the pristine carries both |

Because the provisional rank leader was **qualified and selected**,
the selected-subject controls were never rebound: they were executed
against `SUB-004` from the first attempt.

---

## 4. The controls that must survive into SLICE09

These four are **SLICE09's** to execute, because they concern the
PolyC component, which does not exist yet:

| ID | Why it belongs to SLICE09 |
|---|---|
| `RECON08-SUB-004-POST-POLYC-MUTANT` | the subject is the compiled PolyC component, not the legacy C source |
| `RECON08-SUB-004-G0-ORACLE` | the G0 oracle is the production TU built with the candidate selector OFF, which requires the successor to exist |
| `RECON08-SUB-004-C-OFF-C-MUTANT` | conditional: only if the frozen successor contract demands it |
| the G1/G2/G3 provenance and the 12 ordered pairs | the three future generations do not exist yet |

**The RECON08 pre-migration C mutant CANNOT discharge any of them.**
They have different subjects, different selector states, different
producers and different phases.

---

## 5. What the control set does NOT claim

* It does not claim 24 *independent* experiments. It claims 24
  *control IDs* backed by 25 *physical executions*, and the two IDs
  that share work are named as such.
* It does not claim that the RECON08 C experiment validates the
  PolyC successor. It does not: it validates the **decision**.
* It does not claim that the 15 historical SLICE08 self-referential
  rows are fixed. They are historical evidence and are preserved.
