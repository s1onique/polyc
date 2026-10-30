# Next ACT class (recommendation only; this ACT authorizes nothing)

Measured basis:

* the ABI is expressible and executable on the real target: a compiled PolyC
  object called eight C accessors/mutators over genuine `Ast`/`List` objects,
  matched an independent C-only oracle, propagated host errors, and rejected
  null/wrong-kind/stale/forged/domain/arena-expired handles;
* no production compiler subsystem was recompiled against the interface, so
  **zero** mandatory edges are `CUT_PROVEN_BY_EXECUTION`;
* 14 AST/container representation edges are `CUT_CANDIDATE_NOT_PROVEN`, and
  the 19-subsystem SCC is unchanged;
* `Map`/`AoStr`/`Cctrl` and Arena allocation remain `NO_HANDLE_YET`; callback
  retention and cross-frame recovery are blocked by real semantics;
* the remaining C semantic surface is 2130 rows once the vendored line editor,
  the six mechanical adapters and the nine already-migrated PolyC authorities
  are excluded.

Recommended next class: **ABI_FOUNDATION_IMPLEMENT** — take exactly one
source-representative compiler consumer (the strongest candidate is an AST
reader that today includes `ast.h` only to inspect node kinds/children) and
recompile it against ABI v1, with the C host remaining accountable for the
object. Only that can move a row from `CUT_CANDIDATE_NOT_PROVEN` to
`CUT_PROVEN_BY_EXECUTION`.

Alternative classes, in order of evidence:

1. **DIALECT_FFI_CORRECTION** if a broader handle surface needs the dialect to
   accept something it currently rejects (measured C0 limits: no `(void)`
   parameter lists, postfix casts only, `Bool` is 1 byte).
2. **BUNDLE_QUALIFICATION** if the next question is cost rather than
   dependency: validate the site->ACT mapping on a real bundle before any
   forecast is trusted.

`NEXT_TARGET = NONE`. `SLICE10_AUTHORIZED = NO`. `SELFHOST_M2_ACHIEVED = NO`.
