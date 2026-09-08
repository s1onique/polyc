# ACT-POLYC-FACTORY-STATUS-RECONCILIATION

## Status

PASS

## Goal

Close the factory closure-status reconciliation defect that was
reproduced three times in a row in CORE03-CORRECTION02/03/04 and
recorded as HALT_CORRECTION05_OWN_GATE_RED in CORE03-CORRECTION05.

The seed oracle (`scripts/quality/llvm-closure-status-check.sh`)
is RED at the entry HEAD and is structurally incapable of
enforcing the desired invariant:

1. It collapses `HALT_*` / `PASS_*` exact tokens to lifecycle
   classes (`HALT`, `PASS`), so `HALT_TOPOLOGY_RECORDED` and
   `HALT_SCOPE_CONTRACT_VIOLATED` are reported as identical.
2. It silently skips ACTs whose HANDOFF is absent or whose path
   is not the inferred form.
3. It compares the ACT against itself in pathological cases (per
   CORE03 reviewer's `HALT_CORE03_CONTRACT_NOT_ACTUALLY_BOUND`).

This ACT introduces an exact-token factory closure oracle plus
a manifest bijection, wires it as a hard normal-path pre-commit
gate, and reconciles the historical HANDOFFs that legitimately
need reconciliation under the new contract.

## Scope (managed universe)

Exactly five ACT/HANDOFF pairs:

```
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
  ↔ evidence/llvmspike01-core03-correction01/HANDOFF.md

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md
  ↔ evidence/llvmspike01-core03-correction02/HANDOFF.md

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md
  ↔ evidence/llvmspike01-core03-correction03/HANDOFF.md

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md
  ↔ evidence/llvmspike01-core03-correction04/HANDOFF.md

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md
  ↔ evidence/llvmspike01-core03-correction05/HANDOFF.md
```

The manifest is the bijection between ACT paths and HANDOFF
paths; it is not the authority deciding which files deserve
checking.

The compiler/LLVM is frozen for the duration of this ACT.

## Acceptance criteria

A1. `scripts/quality/factory-closure-status-check.sh` exists and
    implements exact-token metadata extraction and comparison.

A2. `docs/factory/act-handoff-map.tsv` exists and is a TSV
    bijection of five ACT-path ↔ HANDOFF-path rows.

A3. The new checker exits 0 iff every managed pair agrees
    exactly, every managed file is present, the manifest is a
    bijection onto the managed universe, and no managed ACT or
    HANDOFF is unmapped.

A4. The legacy `scripts/quality/llvm-closure-status-check.sh` is
    retained as a thin compatibility wrapper that delegates to
    the new checker for the same paired ACTs.

A5. `scripts/quality/gate-fast.sh` runs the new checker as
    `GFAST-6 factory-closure-status` after GFAST-5 and exits
    non-zero on any failure.

A6. `.githooks/pre-commit` aborts a normal `git commit` when
    `GFAST-6` is RED. (Already true by inheritance from
    `gate-fast.sh`; no wiring change required.)

A7. Hermetic negative tests N1–N15 each FAIL when the seeded
    defect is introduced and PASS once the defect is removed.

A8. After HANDOFF reconciliation, every managed pair agrees
    exactly: `EXACT_OK=5 EXACT_FAIL=0`.

A9. RED-2B (`EXACT_OK=1 EXACT_FAIL=4 rc=1`) is captured as
    evidence **before** any HANDOFF reconciliation edit.

A10. CORRECTION05 prose claiming CORRECTION04's two HALT tokens
     "match" is annotated as superseded-by-exact-token rather
     than silently rewritten.

A11. Commit count ≤ 3 (C1 RED, C2 IMPL, C3 DOCS/HANDOFF).

A12. Closure summary at `evidence/factory-status-reconciliation/HANDOFF.md`.

## Entry identity

```
ENTRY_HEAD    = 862d2cc8c9c0873158c9b60707ab625e08794260
branch        = main
working tree  = clean
compiler/LLVM = frozen
```

## Authoritative tokens (live-confirmed at ENTRY_HEAD)

```
CORRECTION01 ACT      -> HALT_TOPOLOGY_RECORDED
CORRECTION02 ACT      -> HALT_SCOPE_CONTRACT_VIOLATED
CORRECTION03 ACT      -> HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
CORRECTION04 ACT      -> HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
CORRECTION05 ACT      -> HALT_CORRECTION05_OWN_GATE_RED

CORRECTION01 HANDOFF  -> PASS  (legacy; to be reconciled)
CORRECTION02 HANDOFF  -> PASS  (legacy; to be reconciled)
CORRECTION03 HANDOFF  -> PASS  (legacy; to be reconciled)
CORRECTION04 HANDOFF  -> HALT_STATUS_RECONCILIATION_AT_CAP (legacy; to be reconciled)
CORRECTION05 HANDOFF  -> HALT_CORRECTION05_OWN_GATE_RED (already exact; untouched)
```

## Metadata contract

ACT metadata extraction:

1. Find the first heading that matches `^## Status$` exactly.
2. From that heading, read until the next `^## ` heading.
3. Skip blank lines and bullet markers.
4. From the first non-blank line, extract the first
   whitespace-delimited token.
5. Apply regex: `^(OPEN|PASS(?:_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$`

HANDOFF metadata extraction:

1. Find the first line that equals `VERDICT` exactly.
2. Skip the underline (a line of only `-` characters).
3. Skip blank lines.
4. From the first non-blank line, extract the first
   whitespace-delimited token.
5. Apply the same regex.

Cardinality invariants:

* ACT: exactly one `## Status` heading; exactly one extracted
  authoritative token.
* HANDOFF: exactly one authoritative VERDICT section; exactly
  one extracted authoritative token.

## RED matrix (binding)

* RED-1: seed `OK=2 FAIL=3 rc=1` — reproduced at ENTRY_HEAD.
* RED-2: `HALT_TOPOLOGY_RECORDED` vs `HALT_SCOPE_CONTRACT_VIOLATED`
  reported as identical by seed (lossy normalization).
* RED-3A1: managed ACT + HANDOFF at non-inferred path → seed
  silently skips the pair.
* RED-3A2: same pair explicitly listed in fixture manifest →
  new checker discovers and validates it.
* RED-3A3: manifest row removed while both files remain → new
  checker reports `UNMAPPED_*` and exits non-zero.
* RED-3B: managed ACT exists but HANDOFF is absent → seed
  silently skips; new checker reports `MISSING_HANDOFF_FILES > 0`.

## C2 ordering (load-bearing)

```
1. Implement exact checker + manifest machinery.
2. Run N1..N14 hermetic negative tests against the new checker.
3. Run new checker against the unreconciled real tree.
4. Capture RED-2B: EXACT_OK=1 EXACT_FAIL=4 rc=1.
5. Only now reconcile HANDOFF verdicts (CORRECTION01..04).
6. Run real-tree checker again: EXACT_OK=5 EXACT_FAIL=0.
7. Run N15.
8. Run gate-fast / GFAST-6.
```

## Reconciliation table (binding)

| Pair | ACT authority                                          | HANDOFF after reconciliation                       |
| ---- | ------------------------------------------------------ | -------------------------------------------------- |
| 01   | `HALT_TOPOLOGY_RECORDED`                               | `HALT_TOPOLOGY_RECORDED`                           |
| 02   | `HALT_SCOPE_CONTRACT_VIOLATED`                         | `HALT_SCOPE_CONTRACT_VIOLATED`                     |
| 03   | `HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT`         | `HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT`     |
| 04   | `HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE`             | `HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE`         |
| 05   | `HALT_CORRECTION05_OWN_GATE_RED`                       | unchanged                                          |

## Closure criteria

```
MANAGED_ACTS                 = 5
MANAGED_HANDOFFS             = 5
MANIFEST_ROWS                = 5

MANIFEST_PARSE_ERRORS        = 0
DUPLICATE_ACT_PATHS          = 0
DUPLICATE_HANDOFF_PATHS      = 0
MISSING_ACT_FILES            = 0
MISSING_HANDOFF_FILES        = 0
UNMAPPED_MANAGED_ACTS        = 0
UNMAPPED_MANAGED_HANDOFFS    = 0
EXTRA_MANIFEST_ACTS          = 0
EXTRA_MANIFEST_HANDOFFS      = 0
MALFORMED_ACT_STATUS         = 0
MALFORMED_HANDOFF_VERDICT    = 0
EXACT_VERDICT_MISMATCHES     = 0

PAIR_OK                      = 5
PAIR_FAIL                    = 0
checker rc                   = 0

N1..N15                      = PASS
GFAST-6                      = PASS
make gate-fast               = PASS
git diff --check             = PASS
worktree                     = clean
commit count                 <= 3
```

## Next ACT

ACT-POLYC-LLVM-CORE04.

## Residue

* P2: extend the exact-token checker to the broader FACTORY-*
  ACT universe (ir-boundary*, llvmspike01-core*, etc.). Out of
  scope for this bounded ACT.
* P2: phase the legacy `llvm-closure-status-check.sh` wrapper
  out of the tree once all consumers migrate.
