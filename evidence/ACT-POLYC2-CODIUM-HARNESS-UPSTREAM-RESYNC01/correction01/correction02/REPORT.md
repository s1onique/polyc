# CORRECTION02 — Precision cleanup of CORRECTION01 evidence

## VERDICT

```
VERDICT=PASS
RESYNC_OPERATION=PASS
D1=FIXED
D2=FIXED
CORRECTION01_SUBSTANCE=PASS
REMAINING_RESIDUE=EVIDENCE_NOMENCLATURE_AND_BINDING
```

## Why this exists

The reviewer flagged two remaining precision defects in
`CORRECTION01`'s evidence chain. Both are evidence / terminology
issues; neither reopens the resync.

### R3 — `merge-base = 7d7b983` is mislabeled

`current-ref-verification.txt` described the range-diff inputs with
"where merge-base = 7d7b983...", but `7d7b983` is the **post-fetch
tip of origin/main** (= `UPSTREAM_HEAD`), not the historical merge
base. The historical merge base was `e544a48...` (recorded by the
parent ACT as `MERGE_BASE`).

The actual range expression

```
git range-diff 7d7b983..backup/ACT-... origin/main..harness/codium-polyc2
```

is still semantically correct because Git's `A..B` is
reachability-set subtraction (`reachable(B) \ reachable(A)`), not
"must be a merge base". With the post-rebase graph, the endpoint
`7d7b983..backup` selects exactly the 9 pre-ACT local-only commits.

### R4 — Parent immutability claim is observational, not proven

`parent-files-current-hashes.txt` records present hashes but has
no pre-correction anchor to compare against. The strongest honest
claim available is "no parent mutation was observed", with
filesystem-mtime corroboration.

## Forward-only fix

This CORRECTION02:

* adds new files under
  `evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/correction01/correction02/`,
* leaves `current-ref-verification.txt` unchanged (F14 / C1:
  immutable prior artifact),
* leaves `parent-files-current-hashes.txt` unchanged,
* does not rewrite repository history,
* does not modify any product code.

The new files are:

* `range-diff-terminology.txt` — full R3 fix with corrected
  terminology (`ORIGINAL_MERGE_BASE` vs `CURRENT_UPSTREAM_BASE`)
  and the reachability-subtraction rationale.
* `parent-immutability.txt` — full R4 fix with the truthful
  classification (`PARENT_FILES_ARE_UNTRACKED`,
  `PARENT_PRE_CORRECTION_DIGEST_ANCHOR_EXISTS = false`,
  `NO_PARENT_MUTATION_OBSERVED = true`,
  `PARENT_IMMUTABILITY_MECHANICALLY_PROVEN = only against
  parent-files-current-hashes.txt in a later correction cycle`).
* `range-diff-left-side-commits.txt` — the 9 commits selected
  by the LEFT reachability-exclusion endpoint, in reverse order.
  Count = 9.
* `range-diff-right-side-commits.txt` — the 9 rebased commits.
  Count = 9.

## Mechanical witness

```
$ git rev-list --count 7d7b983..backup/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01-1f8250b
9
$ git rev-list --count origin/main..harness/codium-polyc2
9
```

Both range-diff sides yield exactly 9 commits; the LEFT side
matches the parent ACT's `pre-ACT-local-only-commits.txt` and
the RIGHT side matches `post-ACT-harness-commits.txt`. The
reachability-exclusion endpoint `7d7b983` (upstream tip) selects
the right commits.

## Reclassification summary

| Item | Before CORRECTION02 | After CORRECTION02 |
|------|---------------------|--------------------|
| R3 terminology (`merge-base = 7d7b983`) | MISLABELED | CORRECTED with `ORIGINAL_MERGE_BASE` / `CURRENT_UPSTREAM_BASE` split |
| R4 parent immutability | implicitly "proven" | explicit `NO_PARENT_MUTATION_OBSERVED = true`, with forward anchor documented |
| C01 / C14 | PASS_MECHANICALLY_PROVEN | PASS_WITH_EVIDENCE_QUALIFICATION (style match with A2/A12 reclassification) |
| Range-diff conclusion | stands | stands (selection semantics confirmed) |
| Resync operation | PASS | PASS |

## Acceptance contract

| ID  | Criterion                                                           | Status |
|-----|---------------------------------------------------------------------|--------|
| X01 | R3 mislabeling acknowledged                                         | PASS (`range-diff-terminology.txt`) |
| X02 | R3 reachability semantics explained                                 | PASS (`range-diff-terminology.txt`) |
| X03 | R3 range-diff selection verified (9/9 left, 9/9 right)              | PASS (`range-diff-{left,right}-side-commits.txt`, count = 9 each) |
| X04 | R4 immutability qualification recorded                              | PASS (`parent-immutability.txt`) |
| X05 | R4 forward anchor (`parent-files-current-hashes.txt`) identified    | PASS |
| X06 | CORRECTION01 substance unchanged                                    | PASS (no edits to correction01/* files) |
| X07 | No parent evidence mutated                                          | PASS (no `../` edits; filesystem mtimes corroborate) |
| X08 | No repository history rewritten                                     | PASS |
| X09 | No product code changed                                             | PASS |
| X10 | Resync operation still PASS                                         | PASS (HEAD 12e4e7a, main 7d7b983, backup 1f8250b all unchanged) |

## Files added

```
evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/correction01/correction02/
  REPORT.md                       (this file)
  range-diff-terminology.txt      (R3 fix)
  parent-immutability.txt         (R4 fix)
  range-diff-left-side-commits.txt (9 commits reachable from backup, not origin/main)
  range-diff-right-side-commits.txt (9 commits reachable from harness, not origin/main)
```

