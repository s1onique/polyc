# HANDOFF -- ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01

Factory-Version: 2

## Result

VERDICT
-------

PASS

One coherent core semantic consumer bundle is frozen for a separately
authorized successor: `BUNDLE-OPERATOR-CORE-01`. It contains three live,
C-owned operator-classification decisions across parser, type semantics, and
IR/codegen lowering. The deterministic selector chose it without a preselected
source ID, and a rebuilt real production compiler proved its first site is
causally load-bearing.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the ACT's
CLOSE commit. The external post-CLOSE terminality receipt is produced outside
the repository after that commit.

## Selected successor contract

```text
SELECTED_BUNDLE = BUNDLE-OPERATOR-CORE-01
RANK_TUPLE = R0=1,R1=3,R2=1,R3=3,R4=1,R5=23,R6=BUNDLE-OPERATOR-CORE-01
PROPOSED_ABI = ABI-CORE-OP-1
SELECTOR = HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY (future only)
SITES =
  SITE-COMPOUND-ASSIGN   src/prslib.c:1328..1348
  SITE-VALID-POINTER-OP  src/ast.c:974..990
  SITE-RANGE-OPERATOR    src/ast.c:2348..2358
```

The ABI is scalar-only: it receives copied token/operator values and returns
bounded operator or status values. It exposes no raw `Ast`, `Lexeme`, `Map`,
`List`, `Cctrl`, or `Arena` layout; it owns no memory, callback, recovery, or
compiler state. C remains responsible for AST construction, type checks,
allocation, diagnostics, and all nonlocal recovery.

The complete source identity, object hashes, status/ownership/lifetime rules,
G0 fixture partitions, selector OFF/ON plan, G1/G2/G3 producer obligations,
and future negative controls are frozen in
`evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/c2/selected-core-bundle-contract.md`.

## Causal evidence

`CSCR01-M1` changed only the `TK_ADD_EQU` mapping in the selected
compound-assignment classifier. The real production compiler rebuilt, linked
the changed `prslib.c.o`, and changed a compiled program's result from 30 to
246. Restoring the source restored the object hash exactly and the witness
returned to 30. This is a core semantic runtime witness, not a diagnostic,
cosmetic, fixture-only, dormant, stale-object, or compile-failure result.

The C mutation is the reconnaissance's executed C-authority experiment. It is
not the future post-transfer PolyC-source mutation, which must use a separate
execution identity in the successor implementation ACT.

## Graph and authority conservation

```text
PRODUCTION_POLYC_AUTHORITIES = 10 (9 parser + 1 non-parser CPA)
PRODUCTION_GRAPH_NODES = 52
PRODUCTION_GRAPH_MANDATORY_EDGES = 134
PRODUCTION_PROVEN_CUTS = {E-TYP-0136}
SCC_COUNT = 34
LARGEST_SCC = 19
PRODUCTION_SEMANTIC_DELTA = 0
NEW_PRODUCTION_AUTHORITIES = 0
NEW_PRODUCTION_GRAPH_CUTS = 0
SELFHOST_M2_ACHIEVED = NO
```

The historical 134-edge ledger is not falsified. `E-MUT-0137` is
`UNSUPPORTED_WITNESS`: its declared compile-driver consumption is absent in
both source and object. The actual `cctrl`/`parser` consumption is recorded
as an alternative graph scenario only; it is not a production cut.

## Evidence

- `evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/c0/` — identity,
  predecessor freeze, fresh provenance, baselines, 50 ACs, 24 controls,
  eligibility/ranking contract, five REDs.
- `c1/` — source/object roster, semantic sites, family reconciliation,
  blockers/unknowns, ownership/recovery, `E-MUT-0137` audit, bundle registry,
  G0 and mutant plans.
- `c2/` — PolyC verifier, full eligibility/rank outputs, independent rank,
  real-compiler mutation/restoration, selected ABI contract, prospective graph
  impact.
- `c3/` — independent replay, 24 sensitive controls, verifier selftests,
  authority/graph conservation, baselines, gates, AC ledger.
- `c4/` — external terminality plan.

## Production delta

None. No production source, bootstrap subject, CMake file, gate, or test was
modified. The only implementation is the ACT-owned PolyC verifier under
`tools/quality/`.

## Residue

- P1: the successor implementation ACT must freeze exact status and source
  enum values, build all three subject sites with one coherent ABI, and
  provide independent G0/G1/G2/G3 proof.
- P1: the two non-witness sites in the selected bundle still require
  separate source-bound causal attribution in that successor.
- P1: the historical `E-MUT-0137` witness remains disputed in the frozen
  ledger; this ACT records the alternative scenario without rewriting it.
- P2: `F-POLYC-TOOLS` remains unavailable because the canonical checker has
  not landed.

## Recommended next ACT

`ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01` — implementation of the frozen
`BUNDLE-OPERATOR-CORE-01` contract. This ACT does not authorize its
execution, SLICE10, or any production migration.
