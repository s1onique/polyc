# HANDOFF -- ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01

VERDICT

PASS_TRUE_GREEN

---

## Verdict disposition

This ACT successfully removed the dual-authority governance
dependency from the Factory closure-status oracle.

Required predicates (all PASS):

  MANIFEST_IS_SINGLE_ENUMERATION_AUTHORITY = YES
  HARDCODED_PAIR_UNIVERSE                  = NONE
  STATIC_LINKAGE_CORRECTION_MANAGED        = YES
  SELF_ACT_MANAGED                         = YES
  CLOSURE_ORACLE_FROZEN_BEFORE_C3          = YES
  PAIR_OK                                  = 9
  PAIR_FAIL                                = 0
  STATUS                                   = PASS

The canonical closure-status oracle at
scripts/quality/factory-closure-status-check.sh now reads its
managed universe from docs/factory/act-handoff-map.tsv alone.
The bounded here-doc lists of MANAGED_ACTS / MANAGED_HANDOFFS
have been removed; no ACT or HANDOFF path is hardcoded inside
the checker.

Adding a new managed ACT/HANDOFF pair requires only appending a
valid row to the manifest:

  docs/acts/<ACT_ID>.md<TAB>docs/factory/HANDOFF-<ACT_ID>.md

The FACTORY_ACT_HANDOFF_MAP=<path> env var is the canonical
test seam for falsification tests (per ACT §18). It changes
only the manifest source; pair-validation semantics remain
unchanged.

## Successful closure meaning

The following statement is now authorized:

  Factory closure-status no longer owns a hardcoded list of
  ACT/HANDOFF pairs.

  docs/factory/act-handoff-map.tsv is the sole managed-universe
  authority.

  Adding a valid manifest row changes the managed universe
  without changing the checker.

  Malformed, duplicate, missing, or unsafe rows fail closed.

  The checker that judged this ACT was frozen before C3.

  This ACT was already present in the manifest before C3,
  failed while its HANDOFF was absent, then passed after
  C4 created that HANDOFF without modifying the oracle.

  The previously excluded STATIC-FUNCTION-LINKAGE01-CORRECTION01
  pair is now managed and validated.

## Phase topology executed

  C0 AUTH     (commit f8ae7ac, 1 file, 1260 lines)
  C1 RED      (commit ea3bd79, 8 files, 254 insertions)
  C2 IMPL     (commit 52a8b12, 6 files, 291 insertions / 161 deletions)
  C3 VERIFY   (commit 43e7f1e, 27 files, 859 insertions)
  C4 CLOSE    (this commit)

Total: 5 commits, exactly the prospective maximum per ACT §55.

## Frozen-oracle identity (preserved at C4)

  CHECKER_C2_SHA256 = 1ca6ef4dcac67505f1549a46126eb1474c71f3a5f8d10d2b1763ee3af19666fe
  CHECKER_C3_SHA256 = 1ca6ef4dcac67505f1549a46126eb1474c71f3a5f8d10d2b1763ee3af19666fe
  CHECKER_C4_SHA256 = <verified equal at C4 close>

  MANIFEST_C2_SHA256 = c21289718c17fc1352ec76320e86afcf7f14865eacb91c68d907d44d7087fccb
  MANIFEST_C3_SHA256 = c21289718c17fc1352ec76320e86afcf7f14865eacb91c68d907d44d7087fccb
  MANIFEST_C4_SHA256 = <verified equal at C4 close>

## Documented residue

  - The static-linkage-correction ACT body
    (docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-
    CORRECTION01.md) received a ## Status section at C2 to
    satisfy the closure-status oracle's structural metadata
    requirement. The HANDOFF remains the canonical verdict
    source; the ACT body mirrors it for oracle validation
    only. No semantic change.

  - The closure-status checker's HANDOFF path-prefix check
    accepts BOTH docs/factory/HANDOFF-*.md AND
    evidence/*/HANDOFF.md to preserve closed predecessor
    artifacts per F14.

## Identity

  This HANDOFF does NOT claim its own commit SHA. Per F-NO-SHA-OF-SELF,
  the C4 CLOSE commit's SHA is queryable from Git history.

  Predecessor (C3 commit): 43e7f1e73c024ce68c23db7baa0e6fd9d1acf6ff

## NEXT

  NEXT = ACT-POLYC-LIBTOS-SYMBOL-GAPS01

  The Factory governance dependency is no longer blocking
  compiler work. Followed by:

    ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ACT-POLYC-SELFHOST-SURFACE-RECON03
