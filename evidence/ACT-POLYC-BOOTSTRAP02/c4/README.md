ACT-POLYC-BOOTSTRAP02 — C4 — README
=================================

B1 partial self-host — final-tree revalidation,
closure truth, roadmap transition, unlock of B2.

------------------------------------------------------------
Identity
------------------------------------------------------------

```text
ACT                  = ACT-POLYC-BOOTSTRAP02
Factory-Version      = 2
Phase                = C4 CLOSE
Class                = BOOTSTRAP / PARTIAL-SELF-HOST / CLOSURE

C4 entry HEAD        = 15c611f597ff5fd1f9483f7d673fa1568e2cc9a4
                       (C3 EVIDENCE forward-fix: binary deletion
                        + wording accuracy; non-substantive)
C3 substantive HEAD  = de6b30c82d64eba52467a4be156895c760c0cf20
                       (C3 EVIDENCE: broad-corpus equivalence +
                        reproducibility)
Predecessor (C2-CORRECTION03 CLOSE) =
                     = 6144361e52ed6aa3e400c3fd1145516a668446a7
```

------------------------------------------------------------
Predecessor binding
------------------------------------------------------------

The C3 packet on the C2-CORRECTION03 CLOSE base records:

```text
PARTIAL_SELF_HOST_EVIDENCE = PASS
C3_TO_C4_CLOSE_GATE        = OPEN
```

The C3 forward-fix on `15c611f` (this commit's C4 entry
HEAD) did NOT change any substantive B1 evidence. It
removed ~2.83 MB of Mach-O binaries from
`evidence/ACT-POLYC-BOOTSTRAP02/c3/rebuild-{A,B}/` (their
SHA-256s are still preserved textually in
`reproducibility.txt`) and reclassified unit-test /
jit-unit-test wording from "INHERITED 90/90" to
explicit CURRENT vs LAST_KNOWN_GOOD.

C4 therefore accepts the C3 binding block as predecessor
truth and revalidates closure-critical subsets on the
current tree (§3 / §4 / §5 / §6 / §7).

------------------------------------------------------------
What C4 establishes
------------------------------------------------------------

```text
B1_PARTIAL_SELF_HOST = PASS
```

C4 does **NOT** establish:

```text
FIRST_SELF_HOST      = YES
FULL_SELF_HOST       = YES
BOOTSTRAP_STABILITY  = PASS
```

Those remain later milestones (B2 / B3).

------------------------------------------------------------
Directory layout
------------------------------------------------------------

```text
evidence/ACT-POLYC-BOOTSTRAP02/c4/
  README.md                       (this file)
  acceptance-matrix.txt           AC-C4-01..52 mapped to evidence
  closure-summary.txt             machine-readable verdict block
  final-stage-binding.txt         §5 stage0 / B1 component / stage1
  final-b1-tests.txt              §4 + §9 B0/B1 differential counts
  final-corpus-binding.txt        §6 C3 matrix integrity + slice
  final-self-source.txt           §7 B1 source stage0/stage1 SHA
  final-reproducibility.txt       §8 reproducibility truth
  final-conservation.txt          §9 all currently runnable gates
  factory-gates.txt               §11 Factory conservation
  patch-hygiene.txt               §12 current C4 delta + history
  scope-audit.txt                 §13/§14 prior-evidence + production
  residue.txt                     §18 P0/P1/P2 residue classification
  roadmap-transition.txt          §20 ROADMAP block edit diff
```

No binary artifacts. No object files. No generated compiler.

------------------------------------------------------------
Hard stop after CLOSE
------------------------------------------------------------

Per ACT §26, after the single C4 CLOSE commit lands:

- STOP.
- Do not author B2.
- Do not "clean up" residue.
- Do not push.
- The next board-design task is to define B2.

------------------------------------------------------------
Predecessor evidence index
------------------------------------------------------------

| File                                  | Phase       | Role                            |
|---------------------------------------|-------------|---------------------------------|
| evidence/ACT-POLYC-BOOTSTRAP02/c1/    | C1          | ACT doc + RED packet            |
| evidence/ACT-POLYC-BOOTSTRAP02/c2/    | C2          | B1 IMPL evidence (l->ptr fix)   |
| evidence/ACT-POLYC-BOOTSTRAP02/c3/    | C3          | broad-corpus + reproducibility  |
| evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/ | corr  | historical                      |
| evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01/ | corr  | historical                      |
| evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02/ | corr  | historical                      |
| evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02-CORRECTION01/ | corr | historical |
| evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION03/ | corr | C2 final close                  |
