ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01
====================================================

## Status

OPEN

## Predecessor

ACT-POLYC-FACTORY-STATUS-RECONCILIATION
(HALT_FACTORY_STATUS_COMPLETENESS_NOT_BOUND)

## Bounded objective

Repair the factory closure-status oracle so the four
`UNMAPPED_*`/`EXTRA_*` set-difference counters are produced by the
checker itself (not asserted in prose) and so the checker enforces
independent bidirectional completeness between the bounded managed
universe and the manifest.

The current implementation iterates only over manifest rows and
treats the `docs/acts/ACT-*.md` glob as advisory; it cannot fail a
4-row manifest when all 5 bounded ACT/HANDOFF files remain on disk.
The closure summary's `UNMAPPED_* = 0` / `EXTRA_* = 0` claims were
therefore documentary, not mechanically proven.

## Managed universe (authoritative)

This bounded ACT names the managed universe explicitly. Future ACTs
may widen it; this one does not.

```text
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md
```

```text
evidence/llvmspike01-core03-correction01/HANDOFF.md
evidence/llvmspike01-core03-correction02/HANDOFF.md
evidence/llvmspike01-core03-correction03/HANDOFF.md
evidence/llvmspike01-core03-correction04/HANDOFF.md
evidence/llvmspike01-core03-correction05/HANDOFF.md
```

## Required invariants

R1. Independent enumeration
   The checker MUST enumerate the 5 managed ACTs and 5 managed
   HANDOFFs independently of the manifest. The manifest is the
   pairing map; the managed list is the universe authority.

R2. Mechanically emitted set-difference counters
   The checker MUST emit, as part of its standard output, the
   following counters:
       MANAGED_ACTS
       MANAGED_HANDOFFS
       UNMAPPED_MANAGED_ACTS
       UNMAPPED_MANAGED_HANDOFFS
       EXTRA_MANIFEST_ACTS
       EXTRA_MANIFEST_HANDOFFS
   `UNMAPPED_MANAGED_ACTS` and `UNMAPPED_MANAGED_HANDOFFS` are
   computed as set differences:
       MANAGED_ACTS     \ MANIFEST_ACTS
       MANAGED_HANDOFFS \ MANIFEST_HANDOFFS
   `EXTRA_MANIFEST_ACTS` and `EXTRA_MANIFEST_HANDOFFS` are:
       MANIFEST_ACTS     \ MANAGED_ACTS
       MANIFEST_HANDOFFS \ MANAGED_HANDOFFS
   Any non-zero value in any of these four counters causes the
   checker to exit non-zero with `STATUS=FAIL`.

R3. Genuine POSIX sh
   The checker MUST be invocable as a POSIX `/bin/sh` script.
   `declare -A` and any other Bash-only extensions are FORBIDDEN.
   The checker's standard invocation (GFAST-6) MUST be:
       sh scripts/quality/factory-closure-status-check.sh
   and the same script MUST exit 0 on the clean 5-pair state when
   invoked under a strict POSIX sh such as `dash`.

R4. Replace N12 with the real adversarial case
   N12 currently only proves "empty manifest -> FAIL". That is not
   the bounded completeness invariant. N12 MUST be replaced with a
   test that:
       - keeps all 5 ACT/HANDOFF files on disk
       - reduces the manifest from 5 rows to 4 by removing exactly
         one row (e.g. correction02)
       - asserts UNMAPPED_MANAGED_ACTS=1, UNMAPPED_MANAGED_HANDOFFS=1,
         and that the checker exits non-zero
   The new test ID is N16. N12's "empty manifest -> FAIL" property
   is preserved as N12' or N13' (the reviewer-correctness witness)
   but does not, by itself, prove bounded completeness.

R5. Mirror negative (out-of-managed universe)
   A test (N17) MUST demonstrate that adding a 6th manifest row
   pointing to a valid ACT/HANDOFF that is OUTSIDE the managed
   universe (e.g. ACT-POLYC-IR-BOUNDARY01 + its HANDOFF) causes the
   checker to fail with EXTRA_MANIFEST_ACTS=1,
   EXTRA_MANIFEST_HANDOFFS=1, rc != 0.

R6. Clean state under POSIX sh
   The clean 5-pair state MUST pass under BOTH
       sh  scripts/quality/factory-closure-status-check.sh
   AND
       dash scripts/quality/factory-closure-status-check.sh

## Out of scope (residue, not fixed by this ACT)

- generalising the managed universe beyond the bounded 5 pairs;
- removing the legacy `llvm-closure-status-check.sh` compatibility
  wrapper;
- changing the exact-token regex.

## Required closure state

```text
MANAGED_ACTS                 = 5
MANAGED_HANDOFFS             = 5
MANIFEST_ROWS                = 5

UNMAPPED_MANAGED_ACTS        = 0
UNMAPPED_MANAGED_HANDOFFS    = 0
EXTRA_MANIFEST_ACTS          = 0
EXTRA_MANIFEST_HANDOFFS      = 0

PAIR_OK                      = 5
PAIR_FAIL                    = 0

factory checker              rc=0  (under sh AND dash)
gate-fast                    rc=0
pre-commit regression        PASS
git diff --check             rc=0
worktree                     clean
```

## Commit cap

3 commits at most: C1 RED, C2 IMPL, C3 DOCS+HANDOFF.
