# HANDOFF -- ACT-POLYC-FACTORY-APPEND-ONLY-LINEAGE-RECONCILE01

Factory-Version: 2

## Result

The complete historical append-only violation is permanently disclosed,
all twenty affected commit identities are reachable again from `main`
through forward-only true merges, and the pre-reconciliation production
tree is preserved exactly.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.

## What changed

- Opened the separate governance ACT with explicit authority for
  recovery refs, true merges, and a narrow Factory-v2 validator
  correction.
- Froze all thirteen post-boundary reset transitions, all twenty
  affected commit identities, their trees, parents, metadata, subjects,
  and raw reflog records.
- Preserved the affected objects in an external bundle and under
  `refs/archive/lineage-reconcile01/`.
- Proved by exhaustive set-cover that eleven covering tips are the
  unique minimum over the bounded candidate set.
- Created eleven true merges on `main`; all twenty identities are now
  ancestors and the pre-merge tip remains an ancestor.
- Updated the Factory-v2 range checker to enumerate an ACT's
  first-parent phase lineage while rejecting malformed same-ACT
  second-parent history.
- Added permanent disclosure to `AGENTS.md` and Doctrine §28.

## Evidence

- `evidence/factory-append-only-lineage-reconcile01/recon/reset-inventory.tsv`
- `evidence/factory-append-only-lineage-reconcile01/recon/affected-commits.tsv`
- `evidence/factory-append-only-lineage-reconcile01/recon/minimal-cover-proof.txt`
- `evidence/factory-append-only-lineage-reconcile01/red/external-preservation.txt`
- `evidence/factory-append-only-lineage-reconcile01/red/factory-v2-topology-red.txt`
- `evidence/factory-append-only-lineage-reconcile01/impl/disposable-simulation.txt`
- `evidence/factory-append-only-lineage-reconcile01/impl/live-ancestry.tsv`
- `evidence/factory-append-only-lineage-reconcile01/closure/gate-captures.txt`

## Production delta

- Compiler production semantics: unchanged.
- Production tree at the reconciliation subject: byte-identical to the
  pre-reconciliation tree.
- Existing historical ACT and HANDOFF documents: unchanged.
- History rewrite: none. The original breach remains historical fact.

## Residue

- P1: local `main` non-fast-forward protection remains a separate
  bounded ACT; the pre-push hook cannot prevent a local reset.
- P2: the external preservation receipt under `/tmp` is local operator
  storage. The committed inventory and recovery refs are the durable
  in-repository anchors.
- P2: CORRECTION03 remains open. Its technical remediation must resume
  only from the newly verified lineage without reset or replay.

## Recommended next ACT

`ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03` continuation
from the reconciled lineage, subject to a fresh entry gate.
