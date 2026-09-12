# `ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01`

**Title:** Restore pre-BOOTSTRAP gate integrity after Track-A/Track-B integration: bind the PolyC GEP01 regression harness, unify the tooling-runtime install path, and restore the ≤50-LOC shell ratchet.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** INTEGRATION / BUILD-AND-GATE-INTEGRITY

**Factory-Version:** 2

**Predecessor state:** the two-parent Track-A + Track-B integration merge is complete locally; topology is accepted and MUST NOT be recreated.

**Production compiler semantic changes:** **FORBIDDEN**

**Parser / typechecker / neutral-IR changes:** **FORBIDDEN**

**LLVM backend semantic changes:** **FORBIDDEN**

**ABI semantic changes:** **FORBIDDEN**

**Weakening existing gates:** **FORBIDDEN**

**Rewriting either merge parent or the merge commit:** **FORBIDDEN**

**Historical evidence mutation:** **FORBIDDEN**

**Opening `ACT-POLYC-BOOTSTRAP01` before this ACT closes PASS and the merged `main` is successfully pushed:** **FORBIDDEN**

---

## 0. Mission

Turn the already-correct Track-A + Track-B merge into a **mechanically pushable and regression-complete pre-BOOTSTRAP substrate**.

Exactly three defects are in scope:

```text
D1  GEP01 regression harness exists but is not bound to
    any canonical build/gate path.

D2  tooling-runtime installation has two inconsistent paths;
    direct `hcc -lib tos` callers omit errno_shim.o and fail.

D3  two newly-added Factory shell scripts exceed the
    repository's ≤50-LOC new-shell ratchet.
```

The ACT succeeds only when all three are closed **and the exact final CLOSE tree passes `gate-push.sh`**.

The ACT is not a compiler-feature ACT.

The ACT is not a historical-closure correction ACT.

The ACT MUST NOT repair prose merely to make old evidence prettier.

Mechanical truth wins.

---

# 1. Frozen integration truth

The merge itself is accepted as the architectural join point.

Required invariants throughout the ACT:

```text
MERGE_HAS_TWO_PARENTS                  = TRUE
TRACK_A_PARENT_REMAINS_ANCESTOR        = TRUE
TRACK_B_PARENT_REMAINS_ANCESTOR        = TRUE

TRACK_A_LLVM_SUBSTRATE_PRESENT         = TRUE
TRACK_B_TOOLING_RUNTIME_PRESENT        = TRUE
TRACK_B_FACTORY_DOCTRINE_PRESENT       = TRUE

HISTORICAL_EVIDENCE_DELETED            = FALSE
HISTORY_REWRITE                        = FALSE
GIT_REPLACE_REFS                       = NONE
```

No implementation phase may recreate, squash, amend, or rebase the merge.

---

# 2. Principal RED

C1 RED MUST mechanically reproduce all three defects before changing implementation files.

## R1 — GEP01 is unbound

Required observations:

```text
test -f tools/quality/llvm-gep01-test.HC    => PASS
test ! -f scripts/quality/llvm-gep01-test.sh => PASS
grep executable build/gate graph for llvm-gep01-test => NO binding found
```

Search at minimum:

```bash
grep -RIn 'llvm-gep01-test' \
  Makefile CMakeLists.txt src scripts .github 2>/dev/null
```

Narrative/evidence references do not count.

The RED packet MUST distinguish:

```text
SOURCE_EXISTS       = YES
CAN_RUN_AD_HOC      = YES
CAN_RUN_FROM_GATE   = NO
```

The third line is the defect.

The existing untracked pre-RED note may be used as input, but C1 MUST create a proper immutable packet under:

```text
evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c1/
```

Do not leave a loose evidence README at the ACT root after C1.

---

## R2 — install path is inconsistent

Reproduce both real failing callers:

```text
Makefile lsp-test
scripts/quality/gate-push.sh install/GPUSH-2 path
```

Both must be shown reaching a direct equivalent of:

```text
hcc ... -lib tos ... all.HC
```

without incorporating the platform shim required by the canonical CMake install implementation.

Freeze the relationship:

```text
errno_shim.c
   ↓
canonical CMake install path
   ↓
libtos.a / libtos.dylib          GREEN

direct hcc -lib tos call
   ↓
all.o only
   ↓
missing _Errno                   RED
```

Required RED evidence includes the actual undefined-symbol failure.

---

## R3 — shell ratchet violation

Mechanically capture:

```bash
wc -l \
  scripts/quality/factory-halt-classification-check.sh \
  scripts/quality/factory-halt-classification-test.sh
```

and:

```bash
bash scripts/quality/shell-loc-gate.sh
```

Required RED:

```text
factory-halt-classification-check.sh > 50 LOC
factory-halt-classification-test.sh  > 50 LOC

both are NEW relative to shell baseline
shell-loc-gate => FAIL
```

No grandfathering is permitted.

---

# 3. Architectural decisions

## 3.1 D1 — one canonical GEP01 target

Add a canonical Make target:

```text
make llvm-gep01-test
```

It MUST:

1. build any required local test/install prefix from the current tree;
2. compile `tools/quality/llvm-gep01-test.HC` from source;
3. execute the resulting binary;
4. propagate its real exit status;
5. require:

```text
GEP01_PASS=30
GEP01_FAIL=0
STATUS=PASS
```

No committed harness binary.

No warm-tree-only dependency.

No dependence on a manually prebuilt `llvm-gep01-test`.

The target must be reproducible after removal of its generated binary and scratch directory.

---

## 3.2 D1 — bind it to an actual gate

The GEP01 target MUST be reachable from the standard gate graph.

Minimum mandatory binding:

```text
gate-push
  └── make llvm-gep01-test
```

This ACT does **not** require GEP01 to enter `gate-fast`.

Reason: `gate-fast` is itself a latency contract. We should not silently turn it into a compiler-build lane.

Regardless of that optional decision:

```text
GEP01_BOUND_TO_GATE_PUSH = REQUIRED
```

This removes ambiguity and guarantees a pre-push regression check.

---

## 3.3 D1 — negative binding proof

A passing positive run is insufficient.

The implementation MUST prove the gate depends on the harness.

Then demonstrate:

```text
make llvm-gep01-test => FAIL
gate-push GEP step   => FAIL
```

Restore the tree immediately afterward.

No committed sabotage.

This is the most important D1 acceptance test.

---

# 4. D2 — single source of truth for tooling-runtime installation

The CMake installation logic is authoritative.

Do **not** copy the seven-step `errno_shim.o` ritual into several callers.

Do **not** add another subtly different link command.

Instead converge the graph:

```text
canonical local install operation
         ↓
CMake install machinery
         ↓
test prefix with complete libtos
         ↓
lsp-test
gate-push
GEP01 harness if it needs the prefix
runtime01-selftest
```

The exact implementation can be a bounded Make target such as:

```text
test-prefix-install
```

or an equivalently named existing target, but it MUST have one property:

> every quality caller needing an installed PolyC runtime consumes the same canonical installed prefix rather than rebuilding `tos` independently with raw `hcc -lib tos`.

Accordingly, remove/bypass the duplicate direct-library rebuild from:

```text
Makefile lsp-test
gate-push GPUSH-2
```

unless F2 recon proves one of them has a materially different purpose.

---

# 5. D2 negative control

Installation truth must be mechanically bound.

C2/C3 must demonstrate:

```text
canonical install succeeds
libtos archive contains Errno symbol
libtos dynamic library is valid
runtime01-selftest against installed prefix = 18/18
lsp-test progresses past the historical _Errno failure
gate-push progresses past the historical install failure
```

Additionally, prove stale producer defense remains intact:

1. seed an old/stale install artifact;
2. sabotage the current producer;
3. canonical install MUST fail;
4. stale artifact MUST NOT turn the run green.

This preserves the RUNTIME01 stale-producer invariant.

---

# 6. D3 — shell ratchet restoration

The 50-LOC limit MUST remain unchanged.

Forbidden solutions:

```text
raise threshold
add files to grandfather baseline
exclude these scripts by name
split 180 LOC into four 49-LOC shell libraries
minify shell to beat wc -l
```

Required end-state:

```text
factory-halt-classification-check.sh <= 50 LOC
factory-halt-classification-test.sh  <= 50 LOC
```

Both become thin launchers only.

Substantive logic MUST move to a non-shell implementation.

Preferred implementation order:

1. **PolyC**, if it can run without introducing a cyclic dependency in Factory bootstrap/gate-fast;
2. otherwise a small deterministic non-shell implementation using an already-required host facility;
3. HALT if satisfying the ratchet would require weakening Factory independence or adding a substantial new dependency.

A pure "many tiny `.sh` files" decomposition is explicitly forbidden.

---

# 7. D3 semantic conservation

The migration of the halt-classification checker is behavior-preserving.

Freeze the current 12-case matrix before implementation.

After implementation:

```text
FACTORY_HALT_CLASSIFICATION_PASS = 12
FACTORY_HALT_CLASSIFICATION_FAIL = 0
```

Every pre-migration fixture must map to the same verdict.

Preserve the existing prospective/grandfathering boundary.

---

# 8. Allowed files

Expected implementation surface:

```text
Makefile

scripts/quality/gate-push.sh

scripts/quality/factory-halt-classification-check.sh
scripts/quality/factory-halt-classification-test.sh

one or more NON-SHELL implementation source files for the
halt-classification logic, if required

possibly one bounded shared build helper IF F2 proves that is
the cleanest way to expose canonical CMake test-prefix install

docs/ROADMAP.md
docs/acts/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01.md

evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/**
```

`src/CMakeLists.txt` may be changed **only if F2 proves the canonical install API itself lacks a reusable entry point**.

Changing compiler/runtime semantics inside it is forbidden.

---

# 9. Forbidden scope

No changes to:

```text
parser semantics
typechecker semantics
neutral IR semantics
LLVM lowering semantics
Option-W semantics
PHI semantics
GEP semantics
language syntax
ABI semantics
ARRAY/STRUCT roadmap
BOOTSTRAP01 implementation
```

No rewriting of:

```text
MIGRATE-GEP01 evidence
RUNTIME01 evidence
MECHANICAL-BLOCKING01 evidence
OPTION-W evidence
merge history
```

No "fix historical prose while here."

---

# 10. Acceptance criteria

### GEP binding

```text
AC01  make llvm-gep01-test exists.
AC02  AC01 builds llvm-gep01-test from tools/quality/llvm-gep01-test.HC.
AC03  Canonical run: GEP01_PASS=30 GEP01_FAIL=0 STATUS=PASS rc=0
AC04  Existing harness negative mode remains non-green.
AC05  gate-push invokes the canonical GEP01 target.
AC06  Breaking/removing the harness in a temporary negative experiment
      makes BOTH the target and its gate step fail.
AC07  Gate does not consume a stale pre-existing harness binary.
```

### Install seam

```text
AC08  Exactly one canonical local test-prefix install path is used.
AC09  Makefile lsp-test no longer independently rebuilds tos
      through the broken direct hcc -lib path.
AC10  gate-push no longer independently rebuilds tos through the
      broken direct hcc -lib path.
AC11  Installed libtos contains the Errno shim symbol.
AC12  runtime01-selftest against the installed prefix: 18/18 PASS.
AC13  lsp-test does not fail with undefined _Errno.
AC14  gate-push install stage does not fail with undefined _Errno.
AC15  stale-producer negative control still fails closed.
```

### Shell ratchet

```text
AC16  factory-halt-classification-check.sh <= 50 LOC.
AC17  factory-halt-classification-test.sh  <= 50 LOC.
AC18  shell-loc-gate PASS with no threshold/baseline weakening.
AC19  halt-classification behavior matrix remains 12/0 PASS.
AC20  substantive halt-classification logic is not merely fragmented.
```

### Integration closure

```text
AC21  Track-A LLVM gates preserve their frozen counts.
AC22  factory-v2-test PASS.
AC23  factory-append-only-test PASS.
AC24  factory-closure-status PASS.
AC25  factory-halt-classification-test PASS.
AC26  gate-fast PASS.
AC27  gate-push PASS on the exact final CLOSE tree.
AC28  git diff --check on the ACT range PASS.
AC29  working tree clean.
AC30  git replace -l empty.
AC31  original Track-A parent remains ancestor.
AC32  original Track-B parent remains ancestor.
AC33  merge remains a two-parent merge in ancestry.
AC34  no compiler/parser/typechecker/IR/LLVM semantic delta.
AC35  no historical evidence mutation.
```

---

# 11. Required fresh-tree conservation suite

At C3 EVIDENCE and again on the C4 CLOSE candidate:

```bash
make clean
make llvm-all

make llvm-gep01-test

bash scripts/quality/llvm-byte-memory01-test.sh
bash scripts/quality/llvm-intops01-test.sh
bash scripts/quality/ir-return-slot-forwarding01-test.sh

bash scripts/quality/factory-v2-test.sh
bash scripts/quality/factory-append-only-test.sh
bash scripts/quality/factory-closure-status-check.sh
bash scripts/quality/factory-halt-classification-test.sh

bash scripts/quality/shell-loc-gate.sh
bash scripts/quality/gate-fast.sh
```

Then run the **actual push gate against the final candidate**:

```bash
bash scripts/quality/gate-push.sh
```

`gate-push` must not be replaced by individually running what we think it contains.

---

# 12. Gate truth table

CLOSE may be `PASS` only when:

```text
GEP01_TARGET                 PASS
GEP01_GATE_BINDING           PASS
GEP01_NEGATIVE_BINDING       PASS

CANONICAL_INSTALL            PASS
ERRNO_SYMBOL                 PASS
RUNTIME01_SELFTEST           PASS
LSP_ERRNO_REGRESSION         PASS
STALE_PRODUCER_NEGATIVE      PASS

SHELL_LOC                    PASS
HALT_CLASSIFICATION          PASS

TRACK_A_CONSERVATION         PASS
FACTORY_CONSERVATION         PASS
GATE_FAST                    PASS
GATE_PUSH                    PASS

MERGE_TOPOLOGY               PRESERVED
COMPILER_SEMANTIC_DELTA      ZERO
```

No narrative override can turn a missing row green.

---

# 13. HALT taxonomy

Use only real mechanical halt conditions:

```text
HALT_RED_NOT_REPRODUCED
HALT_COMPILER_SEMANTIC_CHANGE_REQUIRED
HALT_INSTALL_API_EXPANSION_REQUIRED
HALT_FACTORY_BOOTSTRAP_CYCLE
HALT_GEP_GATE_BINDING_FAILED
HALT_CONSERVATION_REGRESSION
HALT_GATE_PUSH_FAILED
HALT_MERGE_TOPOLOGY_DAMAGED
HALT_SCOPE_EXPANSION_REQUIRED
```

If a documentation/evidence defect is discovered that has no B1–B5 mechanical impact:

```text
NON_BLOCKING_GOVERNANCE_RESIDUE
```

Do not halt this ACT for prose.

---

# 14. Commit topology

Use four truthful commits:

```text
C1 RED
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

Factory trailers:

```text
C1:
ACT: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01
ACT-Phase: RED

C2:
ACT: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01
ACT-Phase: IMPL

C3:
ACT: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01
ACT-Phase: EVIDENCE

C4:
ACT: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

Exactly one CLOSE.

No SHA-of-self fields.

---

# 15. RED evidence packet

C1 must produce:

```text
evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c1/
  README.md
  d1-gep-unbound.txt
  d1-gate-graph-search.txt
  d2-errno-gate-push-red.txt
  d2-errno-lsp-red.txt
  d2-install-callgraph.txt
  d3-shell-loc-red.txt
  integration-topology.txt
  baseline-gates.txt
```

---

# 16. C3 evidence packet

Minimum:

```text
evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c3/
  README.md

  gep-target-green.txt
  gep-gate-green.txt
  gep-negative-binding.txt

  install-green.txt
  installed-symbols.txt
  runtime01-selftest.txt
  lsp-test.txt
  stale-producer-negative.txt

  shell-loc-green.txt
  halt-classification-parity.txt

  track-a-conservation.txt
  factory-conservation.txt
  gate-fast.txt
  gate-push.txt

  topology-preservation.txt
  semantic-delta.txt
  patch-hygiene.txt
```

No generated binaries committed.

---

# 17. C4 closure packet

Record only current truth:

```text
D1_GEP_GATE_BINDING          = PASS
D1_GEP_NEGATIVE_BINDING      = PASS

D2_CANONICAL_INSTALL         = PASS
D2_ERRNO_SEAM                = PASS
D2_STALE_PRODUCER_FENCE      = PASS

D3_SHELL_RATCHET             = PASS
D3_FACTORY_PARITY            = PASS

TRACK_A_CONSERVATION         = PASS
TRACK_B_CONSERVATION         = PASS
GATE_FAST                    = PASS
GATE_PUSH                    = PASS

MERGE_TOPOLOGY               = PRESERVED
COMPILER_SEMANTIC_DELTA      = ZERO

PREBOOTSTRAP_SUBSTRATE       = GREEN
```

---

# 18. Push authorization

This ACT explicitly authorizes one irreversible action **after C4 CLOSE exists**:

```text
git push origin main
```

but only when all of these are simultaneously true on the exact CLOSE tree:

```text
ACT-Verdict = PASS
gate-push   = PASS
worktree    = clean
git replace -l = empty
origin/main is an ancestor of local main
push is fast-forward from origin's perspective
```

Do not use `--force`, `--force-with-lease`, `--no-verify`.

---

# 19. ROADMAP transition

On PASS:

```text
TRACK_A_TRACK_B_INTEGRATION             MERGED
PREBOOTSTRAP_GATE_INTEGRITY             CLOSED PASS
MERGED_MAIN_PUSHED                      YES
ACT-POLYC-BOOTSTRAP01                   NEXT / UNLOCKED
```

Only after the push succeeds.

---

# 20. Next ACT

On successful CLOSE + push:

```text
NEXT_ACT = ACT-POLYC-BOOTSTRAP01
```

No additional Track-A/Track-B reconciliation ACT.

No historical correction ACT.
