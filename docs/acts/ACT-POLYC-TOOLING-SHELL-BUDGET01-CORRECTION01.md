# ACT-POLYC-TOOLING-SHELL-BUDGET01-CORRECTION01

## 0. Why this correction exists

The original closure commit (`424ed55`,
`C3 CLOSE: ACT-POLYC-TOOLING-SHELL-BUDGET01 PASS`) was
issued under false AC claims. Fresh-tree measurement
at the closure tree produces four mechanical AC
failures that the closure narrative attributed as
PASS:

| AC   | Required (per original §9)                              | Actual at 424ed55                                  | Status   |
|------|---------------------------------------------------------|----------------------------------------------------|----------|
| AC24 | At least one READY_NOW candidate exists.                | 0 READY_NOW rows in `c2/migration-queue.tsv`       | FAIL     |
| AC28 | `shell-loc-gate` remains PASS.                          | FAILs on `factory-halt-classification-{test,check}.sh` (cur=182 / cur=187 > 50) | FAIL     |
| AC29 | `shell-budget-gate` PASS on current tree.               | PASS (this gate is independent of AC28's defect)   | PASS     |
| AC30 | `gate-fast` / canonical Factory gate remains PASS AND invokes the new verifier. | `gate-fast` does NOT invoke `shell-budget-gate`; AC30's "enforces" claim is vacuous | FAIL     |
| AC31 | GEP PolyC harness PASS (30/0).                          | `hcc` not installed; harness unrunnable             | NOT_EXECUTED_IN_ENV |

Per the ACT's own §14 halt taxonomy:

```text
AC24 -> HALT_NO_MIGRATION_CANDIDATE
AC28+AC29+AC30 -> HALT_GATE_FALSE_GREEN
                 (gate says PASS while a stronger invariant FAILs)
AC31 -> ENVIRONMENTALLY_UNAVAILABLE (the ACT does not name
       this halt; but the closure narrative conflated it with
       PASS, which it is not.)
```

Per F3 (RED before production), F4 (HALT is a
successful outcome when an ACT precondition fails),
and F15 (never self-authorize scope expansion), the
truthful verdict is **HALT**, not **PASS**.

## 1. Predecessor

`docs/acts/ACT-POLYC-TOOLING-SHELL-BUDGET01.md` --
original ACT whose C3 closure was issued at commit
`424ed55`.

## 2. Scope of correction

This correction only:

1. re-classifies the original C3 closure verdict
   (PASS -> HALT);
2. reverts the corresponding ROADMAP update
   (CLOSED PASS -> HALT, removes the spuriously
   added `MIGRATE-FACTORY-HALT-CLASSIFICATION01`
   NEXT entry);
3. documents residue per F11 (P0/P1/P2);
4. defers all product fixes to
   `ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01`
   (R1 binds GEP harness; R3 migrates/shrinks
   `factory-halt-classification-{test,check}.sh`)
   and to a future Track-B ACT that owns the
   gate-fast wiring.

This correction does NOT:

- revert the budget manifest
  (`docs/factory/SHELL-BUDGET.tsv`);
- revert the verifier
  (`scripts/quality/shell-budget-gate.sh`) or its
  negative tests
  (`scripts/quality/shell-budget-gate-test.sh`);
- revert the C1 / C2 evidence;
- alter any prior commit.

The implementation work is sound and useful; only
the closure verdict was wrong.

## 3. Halt classification

```text
HALT_CLASS   = PRODUCT
BLOCKS_NEXT  = YES  (for Track A merge into integrated main)
```

Per AGENTS.md F15 and DOCTRINE §25: this halt is
**product** (mechanically unmet ACs in the binding
layer of Track B itself), not prose. It blocks the
Track A integrated merge, but does not block
`PREBOOTSTRAP-GATES01` from opening on the existing
Track A + Track B(e544a48) join.

## 4. Concrete evidence of failure (fresh-tree)

### AC24 -- no READY_NOW candidate

```text
$ grep -c 'READY_NOW' \
    evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c2/migration-queue.tsv
0
$ head -5 \
    evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c2/migration-queue.tsv
rank  path                                          loc  category
1     scripts/quality/factory-halt-classification-test.sh   182  NEEDS_FACTORY_REDESIGN
2     scripts/quality/factory-v2-commit-msg-check.sh        218  NEEDS_FACTORY_REDESIGN
3     scripts/quality/factory-halt-classification-check.sh  187  NEEDS_FACTORY_REDESIGN
4     scripts/quality/factory-v2-test.sh                    465  NEEDS_FACTORY_REDESIGN
```

The C2 ranking covers all 36 GRANDFATHERED rows, but
**zero** rows have `READY_NOW`. Selecting the highest-
scoring `NEEDS_FACTORY_REDESIGN` row does not turn it
into a ready migration -- the category classification
itself says more work is needed before migration.

### AC28 -- `shell-loc-gate` FAILs at the closure tree

```text
$ sh scripts/quality/shell-loc-gate.sh
FAIL  NEW   scripts/quality/factory-halt-classification-test.sh   cur=182 > 50
FAIL  NEW   scripts/quality/factory-halt-classification-check.sh  cur=187 > 50
$ echo $?
1
```

The original `c3/conservation-gates.txt` recorded
`rc=0` for this same invocation -- that capture
itself was wrong. The C3 evidence runner failed to
bind the displayed `FAIL` lines to the subprocess
exit status.

The two `FAIL NEW` lines are pre-existing
defects introduced by `ACT-POLYC-FACTORY-MECHANICAL-
BLOCKING01` (`d4ad74f`), NOT by this ACT. They are
correctly assigned to `ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01`
(R3: shrink or migrate `factory-halt-classification-*`).

### AC30 -- `gate-fast` does not invoke `shell-budget-gate`

```text
$ grep -n 'shell-budget' scripts/quality/gate-fast.sh
(no output)
```

The original ACT §14 (`This ACT wires the new
verifier into gate-fast.sh for local feedback`) is
explicitly authorized in-scope and explicitly
required. The C3 closure narrative admitted this
wiring was deferred -- i.e. the original ACT was not
implemented end-to-end, and AC30 was false.

The implementation gap has the same geometric shape
as the GEP harness gap (D1 in `PREBOOTSTRAP-GATES01`):
the new policy can silently stop running.

### AC31 -- GEP PolyC harness unrunnable in this env

```text
$ which hcc
hcc not found
$ ls tools/quality/llvm-gep01-test.HC
-rw-r--r--  ... tools/quality/llvm-gep01-test.HC
```

The C3 evidence classified AC31 as
`ENVIRONMENTALLY_UNAVAILABLE` and reported it under
a `RESIDUE` heading. That is a valid per-ACT
classification **for the AC itself**, but it is
**not** the AC31 PASS that the §16 closure truth
block asserted. The closure truth block's
`GEP_POLYC_HARNESS = PASS (30/0)` is mechanically
false.

Independent of AC31's classification,
`PREBOOTSTRAP-GATES01` R1 is the correct
architectural response: bind the GEP harness so it
runs against `build/test-prefix/bin/`, which fixes
both the env unavailability and the unbinding defect
simultaneously.

## 5. Residue classification (F11)

| Priority | Item                                                                                                                                |
|----------|-------------------------------------------------------------------------------------------------------------------------------------|
| P0       | `scripts/quality/gate-fast.sh` does NOT invoke `scripts/quality/shell-budget-gate.sh`. Same B5 geometry as the GEP harness gap.     |
| P0       | `shell-loc-gate` FAILs on `factory-halt-classification-{test,check}.sh` (pre-existing; introduced by MECHANICAL-BLOCKING01 d4ad74f). |
| P0       | `c3/conservation-gates.txt` capture runner reported `rc=0` for the FAILing `shell-loc-gate` invocation -- evidence capture defect.   |
| P0       | `c2/migration-queue.tsv` has duplicate header row (cosmetic, but evidence of script defect that should be filed).                   |
| P1       | GEP PolyC harness is `ENVIRONMENTALLY_UNAVAILABLE` in this env (no `hcc`).                                                          |
| P1       | `AC31` closure-truth block asserted PASS (30/0) when the actual classification is UNAVAILABLE.                                       |
| P2       | `c2/budget-after.tsv` budget arithmetic explanation was wrong about the +2 slack source. Inequality holds; prose was misleading.    |
| P2       | The manifest grandfathered 182-LOC and 187-LOC files (factory-halt-classification-{test,check}). First-layer hard cap and second-layer budget snapshot disagree; the second-layer is wrong. |

Items marked P0 are owned by
`ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01`. Items
marked P1/P2 are documented but not blocking.

## 6. What is NOT changed by this correction

The implementation work of the original ACT is sound:

| Artifact                                          | Value to the project                                                  |
|---------------------------------------------------|-----------------------------------------------------------------------|
| `docs/factory/SHELL-BUDGET.tsv`                   | Repository-wide tracked-shell inventory + budget snapshot             |
| `scripts/quality/shell-budget-gate.sh`            | Deterministic per-file monotonicity verifier (B1..B9)                 |
| `scripts/quality/shell-budget-gate-test.sh`       | Negative test packet N1..N10 (9 implemented)                          |
| `evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c1/`   | Six real-seam RED reproductions                                       |
| `evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01/c2/`   | Budget manifest, migration queue, verifier test results               |

These survive the verdict correction unchanged and
should be **reused** by whatever future ACT closes
Track B. The repository-wide inventory is
architecturally better than the original
`scripts/quality/`-only baseline because it uses
`git ls-files '*.sh'` (the Git-documented primitive
for tracked index entries, not the worktree).

## 7. ROADMAP update (Track B after this correction)

```text
SHELL-BUDGET01        HALT (PRODUCT) -- implementation useful,
                                    closure false; see
                                    CORRECTION01 for residue.
PREBOOTSTRAP-GATES01  NEXT (Track B integration gate)
```

The spuriously-added `MIGRATE-FACTORY-HALT-CLASSIFICATION01`
NEXT entry is REMOVED, because:

1. AC24 was false at the closure tree (no READY_NOW
   candidate), so the ACT's own selection rule did
   not actually fire; and
2. `PREBOOTSTRAP-GATES01` R3 is the correct pre-
   migration shrink/migrate work that would convert
   those candidates from `NEEDS_FACTORY_REDESIGN` to
   `READY_NOW`.

## 8. Track-A merge status

The Track-A integrated tree at `e544a48` (the
pre-`SHELL-BUDGET01` Track B parent) remains the
correct join point. Adding `424ed55` to the Track-A
merge would import:

* an unbound new gate (AC30 false);
* a manifest that grandfathered the two scripts
  `PREBOOTSTRAP-GATES01` R3 intends to migrate (P0);
* a claimed PASS with four mechanically false ACs;
* no capability Track A needs to start fixing D1..D3.

Track-A merge is HALTED on this Track-B tip.

## 9. Halt taxonomy mapping

```text
AC24                          -> HALT_NO_MIGRATION_CANDIDATE
AC28 (shell-loc-gate FAIL)    -> HALT_GATE_FALSE_GREEN
AC30 (gate-fast not wired)    -> HALT_GATE_FALSE_GREEN
AC31 (env unavailability)     -> ENVIRONMENTALLY_UNAVAILABLE
                                (no PASS claimed after correction)
```

All four halts are mechanically reproducible against
the current tree at `424ed55`.

## 10. Handoff & evidence

```text
EVIDENCE ROOT = evidence/ACT-POLYC-TOOLING-SHELL-BUDGET01-CORRECTION01/
  fresh-tree-failures.txt       = current AC24/28/30/31 measurements
  halt-classification.txt       = halt grammar output
```

This ACT has no C2 implementation phase because no
production change is authorized here. The correction
is purely governance: reclassify the closure verdict
and document residue.

## 11. Closure truth

```text
ACT_VERDICT                 = HALT
HALT_CLASS                  = PRODUCT
BLOCKS_NEXT                 = YES (Track A merge into integrated main)
ROADMAP_STATE               = HALT (was incorrectly CLOSED PASS)
ORIGINAL_CLOSURE_COMMIT     = 424ed55 (immutable per F14)
CORRECTION_COMMIT           = <this correction's commit>
NEXT_ACT                    = ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01
                              (already open on Track A side; owns
                               the four P0 fixes enumerated in §5)
```

No SHA-of-self. No mutation of `424ed55`. No
production code touched.
