# ACT-POLYC-TOOLING-SHELL-INVENTORY01

**Title:** Inventory PolyC's shell scripts and freeze the <=50 LOC ratchet

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** TOOLING / RECON

**Predecessor:** ACT-POLYC-LLVM-GEP01 (CLOSED PASS) -- this ACT is parallel, not dependent.

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## 0. Mission

Produce an authoritative, machine-checkable inventory of every
shell script under `scripts/`, classify each by size class,
role, and migration cost, and **freeze the policy that no new
shell file may exceed 50 physical LOC** and no existing shell
file may grow past its current line count.

This ACT establishes the ratchet; the migration of existing
over-50-LOC shell into PolyC is the work of subsequent ACTs
(SHELL-BUDGET01, TOOLING-RUNTIME01, etc.).

## 1. Why

PolyC's medium-term goal is to be a self-hosting compiler.
Its immediate evidence machinery (test harnesses, gate runners,
factory append-only tests) is overwhelmingly written in POSIX
shell -- currently 6,131 LOC across 27 scripts.

We have just closed GEP01 with a brand-new 232-LOC shell
harness. If we do not freeze a budget now, every subsequent
ACT will keep adding to the shell debt.

A ratchet policy (<=50 LOC for new files, no-growth for
existing) is the smallest mechanical step that stops the debt
from growing.

This ACT does NOT yet migrate anything. It records the baseline
and freezes the ratchet. Migration is downstream work.

## 2. Scope

### allowed

- `scripts/quality/inventory.sh` (new)
- `scripts/quality/shell-loc-gate.sh` (new)
- `evidence/ACT-POLYC-TOOLING-SHELL-INVENTORY01/c1/` (new)
- `evidence/ACT-POLYC-TOOLING-SHELL-INVENTORY01/c2/` (new)
- `docs/ROADMAP.md` (small SHELL-INVENTORY note)
- This ACT document

### forbidden

- any edit to existing shell scripts under `scripts/`
- any edit to `src/`, `Makefile`, or any production code
- any edit to historical ACT documents (F14)
- migration of any shell script to PolyC (deferred to
  SHELL-BUDGET01 / TOOLING-RUNTIME01 / etc.)
- addition of new shell dependencies (awk, jq, yq, etc.)

## 3. Entry gate

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Required state:

- on `main`;
- worktree clean;
- entry HEAD recorded.

## 4. Principal RED

Per F3, the RED is a real failing witness. For this
recon/ratchet ACT the RED is:

```text
scripts/quality/shell-loc-gate.sh does not exist ->
  the ratchet is not enforced.
```

After this ACT the gate must exist, must be <=50 LOC itself,
and must (a) refuse any new shell file >50 LOC and
(b) refuse growth of any existing shell file past its frozen
baseline.

## 5. Implementation boundary

### minimum new files

1. `scripts/quality/inventory.sh` -- produces the inventory.
   - Walks `scripts/` and emits one row per file with path,
     LOC, executable bit, shebang, role tag.
   - Hard cap: <= 50 LOC.

2. `scripts/quality/shell-loc-gate.sh` -- enforces the ratchet.
   - Reads the frozen baseline.
   - Fails iff a NEW shell file >50 LOC was added, or an
     EXISTING shell file grew past its baseline.
   - Hard cap: <= 50 LOC.

### minimum new evidence files

- `c1/baseline.txt` -- frozen LOC of every shell file under
  `scripts/` at the start of this ACT.
- `c1/inventory.txt` -- produced by inventory.sh.
- `c1/role-taxonomy.txt` -- explains the role tags.
- `c2/gate-output.txt` -- shell-loc-gate.sh fresh-run output.
- `c2/grandfathered-debt.txt` -- sorted list of over-50-LOC
  files with role and migration priority.
- `c2/closure-summary.txt` -- RESIDUE + verdict.

### what is deliberately NOT included

- NO migration of any existing shell script.
- NO rewrite of llvm-gep01-test.sh in PolyC.
- NO new tooling for PolyC runtime (TOOLING-RUNTIME01).
- NO edits to factory-v2 tests.
- NO new shell files anywhere else outside the two allowed.

## 6. Acceptance criteria

Each AC MUST be checkable by a single concrete command.

- AC01 -- inventory.sh exists and is <= 50 LOC.
- AC02 -- shell-loc-gate.sh exists and is <= 50 LOC.
- AC03 -- inventory.sh produces a row per shell file in scripts/.
- AC04 -- baseline.txt matches pre-ACT shell LOC.
- AC05 -- shell-loc-gate.sh fresh-run output captured.
- AC06 -- grandfathered-debt.txt sorted by LOC desc.
- AC07 -- no new shell file was added outside this ACT's scope.
- AC08 -- no existing shell file grew past its baseline.
- AC09 -- ROADMAP.md has a SHELL-INVENTORY section.
- AC10 -- this ACT document is committed on main.

## 7. Conservation gates

Must remain PASS:

- `bash scripts/quality/gate-fast.sh`
- `bash scripts/quality/factory-append-only-test.sh`
- `bash scripts/quality/factory-closure-status` (via gate-fast)
- `bash scripts/quality/llvm-gep01-test.sh`
- `bash scripts/quality/llvm-byte-memory01-test.sh`
- `python3 scripts/quality/llvm-cap-table-verifier.py`
- `HCC_INSTALL_DIR=build/test-prefix bash scripts/quality/llvm-spike-test.sh`

These are the gates GEP01 just closed; they must remain
green after this ACT.

## 8. Halt taxonomy

- HALT_SCOPE_EXPANSION_REQUIRED -- if a real need for a new
  over-50-LOC shell file is identified during the ACT.
- HALT_RED_NOT_REPRODUCED -- if the principal RED cannot be
  reproduced (it is mechanical, so this should not fire).
- HALT_CONSERVATION_GATE_REGRESSION -- if any conservation
  gate fails after the IMPL.
- HALT_TEST_WEAKENED -- never weaken a test; only repair
  the product (F5).

## 9. Residue (pre-declared)

- P0 -- none expected.
- P1 -- the >50-LOC grandfathered shell debt (~6,000 LOC
  across ~25 files). This ACT records the debt; migration
  is downstream.
- P2 -- the factory-v2-*.sh scripts are evidence-collection
  machinery for the Factory process itself; their migration
  to PolyC is much later (after TOOLING-RUNTIME01).

## 10. Commit topology

Three commits, contiguous:

1. C1 RED -- ACT document + baseline.txt + role-taxonomy.txt
   + the new inventory.sh + shell-loc-gate.sh (no existing
   files changed; this commit IS the RED because the gate
   did not exist before).
2. C2 IMPL -- frozen inventory.txt + gate-output.txt +
   grandfathered-debt.txt + closure-summary.txt.
3. C3 CLOSE -- ROADMAP update + final gate run.

Do not exceed 3 commits.

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`:
- VERDICT
- IDENTITY (entry / final / branch)
- FINDING (no defect, this is a recon+ratchet ACT)
- RED (mechanical: gate does not exist)
- IMPLEMENTATION (two new files; zero edits to existing)
- GATES (all conservation gates PASS)
- SCOPE (F11-classified residue)
- NEXT ACT (SHELL-BUDGET01, the migration-ratchet ACT)
