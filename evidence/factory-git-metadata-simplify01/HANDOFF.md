# HANDOFF -- ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01

## Result

PASS

Factory v2 is activated for all ACTs opened after this
closure. Existing Factory v1 ACTs and HANDOFFs are
grandfathered (V2-13 / F14) and remain valid historical
evidence; the legacy closure-status oracle
(`factory-closure-status-check.sh`,
`act-handoff-map.tsv`, `llvm-closure-status-check.sh`)
remains responsible for its bounded 6-pair v1 universe.

`ACT-POLYC-LLVM-CORE04` is unblocked and becomes the first
Factory-v2 ACT.

## Proven

* Five RED witnesses captured and reproduced:
  RED-1 self-pinning (CORRECTION02 HANDOFF placeholders);
  RED-2 duplicate-verdict-authority (CORE03-CORRECTION01
  HANDOFF VERDICT=PASS vs ACT ## Status=HALT_*);
  RED-3 arbitrary-commit-cap (IR-BOUNDARY03-CORRECTION02
  3-vs-4, FACTORY-STATUS-RECONCILIATION-CORRECTION02
  self-pinning required CORRECTION03);
  RED-4 persistent-worktree-claim (live `git status`
  cycle);
  RED-5 Git-trailer-feasibility (`git interpret-trailers
  --parse` round-trips ACT / ACT-Phase / ACT-Verdict).
* `git interpret-trailers --parse` + `git log %(trailers:
  key=...,separator=@@@)` suffice for ACT metadata
  parsing. No custom Markdown identity parser exists or is
  needed.
* New tooling exercises the full T1-T18 matrix in
  `scripts/quality/factory-v2-test.sh`: 19/19 PASS.
* Legacy v1 closure-status oracle still PASSes its
  bounded 6-pair universe (gate-fast GFAST-6 rc=0).
* `gate-fast` rc=0, `git diff --check` rc=0,
  `git status --porcelain=v1` empty at closure.
* Compiler sources untouched: `git diff --name-only
  29fb9afc..HEAD -- src/` is empty.

## Doctrine changed

* `docs/factory/GIT-METADATA.md` (NEW) -- canonical v2
  detail (trailer grammar, range derivation, identity
  ownership, commit topology, HANDOFF/ACT templates,
  reviewer procedure, tooling surface, non-goals).
* `AGENTS.md` -- appended Factory version pointer.
* `docs/factory/DOCTRINE.md` -- appended Section 21
  (Factory v2 additive mechanics).
* `docs/factory/LLM-WORKFLOW.md` -- appended Factory v2
  lifecycle note.
* `docs/factory/ACT-TEMPLATE.md` -- appended Factory v2
  ACT template alongside the v1 template.
* `docs/factory/HANDOFF-TEMPLATE.md` -- appended Factory
  v2 HANDOFF template alongside the v1 template.

Existing Factory v1 doctrine and templates are NOT removed;
they remain binding for their grandfathered universe.

## Conservation

* compiler sources untouched (no `src/` change)
* legacy v1 gate preserved (factory-closure-status PASS,
  GFAST-6 PASS)
* gate-fast rc=0
* diff-check rc=0
* worktree clean at closure (verified live)

## Residue

* P2 -- legacy factory-closure-status oracle
  decommission remains future work. A separate ACT may
  retire `factory-closure-status-check.sh`,
  `llvm-closure-status-check.sh`, and
  `act-handoff-map.tsv` once all v1 ACTs are closed.
* P2 -- "this commit" / "next commit" / SHA-table patterns
  in any committed ACT or HANDOFF outside the immediate
  CORRECTION02 chain remain grandfathered (V2-13).
* P2 -- CI enforcement of v2 trailers (V2-3 / V2-4 /
  T1-T18) remains a future ACT.
* P2 -- cryptographic signing of ACT commits remains a
  future ACT (explicit non-goal in §23).
* P2 -- ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1 in
  ROADMAP) remains a separate ACT.

## Next

ACT-POLYC-LLVM-CORE04

(Becomes the first Factory-v2 ACT; uses Git trailers for
identity / phase / verdict; uses
`factory-v2-range-check.sh` for closure review; uses the
Factory v2 HANDOFF template.)
