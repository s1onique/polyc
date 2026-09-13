ACT-POLYC-BOOTSTRAP02 — HANDOFF
==============================

# VERDICT

```text
ACT-POLYC-BOOTSTRAP02 is CLOSED.

B0 compiler-shaped bootstrap:  PASS
B1 partial self-host:           PASS

B1 component:
  written in PolyC
  compiled by stage0
  linked into stage1
  actually used by production identifier seam

Direct equivalence:
  component          15/15
  cursor             6/6
  real Lexer         6/6
  EOF safety         PASS

Broad corpus:
  inventory          181
  stage0 success     175
  stage1 divergence  0
  successful diff    0

Stage1 self-source:
  PASS
  stage0/stage1 output identical
  (SHA-256 = a1b620c076e81d898f953889f2b9db97f0bf8f6228af3b4a10644e2e78cd854f)

Reproducibility:
  PASS (3 independent compile paths produce the same B1 SHA)

B0 conservation:
  15/15

LSP conservation:
  43/43

Unit/jit:
  CURRENT = ENVIRONMENTALLY_UNAVAILABLE / RUNNER_FALSE_GREEN
  LAST_KNOWN_GOOD = 90/90
  B1 attributable regression = NONE

Factory gates:
  PASS

Production delta in C4:
  ZERO

Historical evidence mutation:
  ZERO

Current C4 patch hygiene:
  PASS

Historical raw-evidence whitespace:
  GOVERNANCE / BLOCKS_NEXT=NO

FIRST_SELF_HOST:
  NO

FULL_SELF_HOST:
  NO

BOOTSTRAP_STABILITY:
  NOT_YET

ROADMAP:
  B0 = GREEN
  B1 = GREEN
  B2 = UNLOCKED / NEXT
  B3 = LOCKED
```

# IDENTITY

```text
C4 entry HEAD       = 15c611f597ff5fd1f9483f7d673fa1568e2cc9a4
                       (C3 EVIDENCE forward-fix:
                        binary deletion + wording accuracy;
                        non-substantive w.r.t. B1 evidence)
C3 substantive      = de6b30c82d64eba52467a4be156895c760c0cf20
                       (C3 EVIDENCE: broad-corpus equivalence +
                        reproducibility)
Predecessor (C2-CORRECTION03 CLOSE):
                    = 6144361e52ed6aa3e400c3fd1145516a668446a7
Factory version    = 2
Phase              = C4 CLOSE
Branch             = main
Worktree at entry  = clean
git replace at entry = empty
```

# ROOT CAUSE / MISSION

The active parent ACT is **ACT-POLYC-BOOTSTRAP02**,
which asks the question:

> Can the existing PolyC compiler replace one bounded
> production lexer path with a PolyC-written lexer
> component, link that component into a stage1 compiler,
> and prove via reproducible differential evidence that
> stage0 and stage1 produce equivalent output throughout
> the proven envelope?

B1 (partial self-host) is the milestone in which one
bounded subsystem is itself written in PolyC and proven
to behave equivalently to the inherited C implementation.
The mission of C4 CLOSE is **not** to build new bootstrap
functionality; it is to:

  1. freeze the proven B1 result on the current tree;
  2. revalidate closure-critical evidence with fresh
     executions;
  3. record residue without "fixing" it;
  4. update the board;
  5. create exactly one authoritative CLOSE commit.

Successful C4 establishes:

```text
B1_PARTIAL_SELF_HOST = PASS
```

It explicitly does NOT establish:

```text
FIRST_SELF_HOST      = YES
FULL_SELF_HOST       = YES
BOOTSTRAP_STABILITY  = PASS
```

# RED

The C1 RED packet for the parent ACT is in
`evidence/ACT-POLYC-BOOTSTRAP02/c1/`. The C1 RED
established that a single bounded PolyC-written lexer
component (`BootstrapScanIdent`) could replace the
inherited `lexIdentifier` C path WITHOUT changing the
production Lexer seam externally observable behavior.

The C2 IMPL evidence is in `c2/`, and the C2 final
close is `C2-CORRECTION03`. The C3 EVIDENCE is in `c3/`
on `de6b30c`. The C4 forward-fix in `c3/` on `15c611f`
did not change any substantive B1 evidence; it only
cleaned up geometry (deleted ~2.83 MB of Mach-O
binaries whose SHA-256s were already preserved textually
in `reproducibility.txt`) and corrected claim-shape
on the unit-test / jit-unit-test numbers.

C4 itself adds no RED. C4 is the closure phase.

# IMPLEMENTATION

C4 is a CLOSE phase; it does NOT introduce new
implementation. The implementation history is:

| Phase | Head    | Summary                                              |
|-------|---------|------------------------------------------------------|
| C1    | c1/     | ACT doc + RED packet + bootstrap02-ident.HC seed     |
| C2    | c2/     | l->ptr at EOF fix; legacy l->start postcondition     |
| C2-CORRECTION03 | 6144361 | Production-source mutation: l->ptr at EOF + legacy l->start |
| C3    | de6b30c | 175/175 corpus equivalence + reproducibility A/B    |
| C3 (ff) | 15c611f | Forward-fix: binary deletion + wording accuracy     |
| C4    | (this)  | Closure summary + ROADMAP transition + HANDOFF       |

The B1 implementation (`tools/bootstrap/bootstrap02-ident.HC`)
is the single bounded subsystem in PolyC. Its artifact
hash has remained byte-stable across all builds since
the C2 close:

```text
SHA-256(bootstrap02-ident.o) =
  a1b620c076e81d898f953889f2b9db97f0bf8f6228af3b4a10644e2e78cd854f
```

# EVIDENCE

```text
evidence/ACT-POLYC-BOOTSTRAP02/c4/README.md
evidence/ACT-POLYC-BOOTSTRAP02/c4/acceptance-matrix.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/closure-summary.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/final-stage-binding.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/final-b1-tests.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/final-corpus-binding.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/final-self-source.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/final-reproducibility.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/final-conservation.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/factory-gates.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/patch-hygiene.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/scope-audit.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/residue.txt
evidence/ACT-POLYC-BOOTSTRAP02/c4/roadmap-transition.txt
```

No binary artifacts. No object files. No generated
compiler. All C4 evidence is text.

# GATES

```text
make bootstrap01-test                 BOOTSTRAP01        15/15 PASS
make bootstrap02-test                 BOOTSTRAP02        15/15 PASS
make bootstrap02-cursor-test          BOOTSTRAP02_CURSOR  6/6 PASS
make bootstrap02-lexer-seam-test      BOOTSTRAP02_LEXER_SEAM 6/6 PASS
make lsp-test                         LSP                43/43 PASS
make gate-fast                        GATE_FAST          PASS
./scripts/quality/factory-v2-test.sh  FACTORY_V2         PASS=35 FAIL=0
./scripts/quality/factory-append-only-test.sh
                                      FACTORY_APPEND_ONLY PASS=11 FAIL=0
./scripts/quality/factory-halt-classification-test.sh
                                      FACTORY_HALT_CLASSIFICATION PASS=12 FAIL=0
./scripts/quality/factory-closure-status-check.sh
                                      FACTORY_CLOSURE_STATUS PASS=6/0
./scripts/quality/shell-loc-gate.sh   SHELL_LOC          PASS
```

# SCOPE

```text
PRIOR_EVIDENCE_MUTATION    = ZERO
C4_PRODUCTION_DELTA        = ZERO
B1_COMPONENT_DELTA         = ZERO
C4_BINARY_EVIDENCE_FILES   = 0
C4_PATCH_HYGIENE           = PASS

Forbidden-by-C4 NOT touched:
  src/**
  tools/bootstrap/**
  tools/quality/**
  scripts/**
  Makefile

C4 evidence files only:
  evidence/ACT-POLYC-BOOTSTRAP02/c4/**
  evidence/ACT-POLYC-BOOTSTRAP02/HANDOFF.md

Plus:
  docs/ROADMAP.md  (single line-block edit per §20)
```

# RESIDUE

```text
P0 (mechanically blocking):
  NONE

P1 (engineering follow-up):
  NONE attributable to B1

P2 (governance / infrastructure):
  P2.1  unit-test current execution unavailable
        (inherited: /usr/local/include/tos.HH absent)
  P2.2  jit-unit-test current execution unavailable
        (same root cause)
  P2.3  Makefile runner false-green defect (`&&` non-propagation)
  P2.4  historical raw-evidence whitespace (125 findings,
        all in non-C4 evidence; governance only)
  P2.5  inherited GEP01 / push residue (unchanged from
        INTEGRATION-PREBOOTSTRAP-GATES01 halt)

All P2 items:
  CLASS             = GOVERNANCE / TEST_INFRASTRUCTURE
  PRODUCTION_IMPACT = NONE
  BLOCKS_B1_CLOSE   = NO
  BLOCKS_B2_OPEN    = NO
```

C4 records these honestly and does NOT repair them.
A future bounded correction ACT can decide whether to
open them.

# ROADMAP TRANSITION

The C4 CLOSE commit updates `docs/ROADMAP.md` to:

```text
B0 — COMPILER-SHAPED      GREEN
                              ACT-POLYC-BOOTSTRAP01 CLOSED PASS
                              ACT-POLYC-BOOTSTRAP01-CORRECTION01
                                CLOSED PASS_WITH_HYGIENE_RESIDUE
B1 — PARTIAL SELF-HOST    GREEN
                              ACT-POLYC-BOOTSTRAP02 CLOSED PASS
B2 — FIRST SELF-HOST      UNLOCKED / NEXT
B3 — BOOTSTRAP STABILITY  LOCKED
```

Recommended outcome block:

```text
B1_PARTIAL_SELF_HOST              = GREEN
B1_COMPONENT_POLYC                = YES
B1_COMPONENT_STAGE0_BUILT         = YES
B1_COMPONENT_STAGE1_BOUND         = YES
B1_REAL_LEXER_EQ                  = 6/6
B1_BROAD_CORPUS_EQ                = 175/175
B1_STAGE1_COMPILES_OWN_COMPONENT  = YES
B1_REPRODUCIBLE                   = YES
FIRST_SELF_HOST                   = NO
BOOTSTRAP_STABILITY               = NOT_YET
NEXT                              = B2
```

# NEXT ACT

The next board-design task is to **define B2** (first
self-host milestone), not to extend B1.

B0 / B1 / B2 / B3 milestones:

```text
B0  = compiler-shaped bootstrap   GREEN
B1  = partial self-host           GREEN  (this ACT)
B2  = first self-host             NEXT   (LOCKED -> UNLOCKED)
B3  = bootstrap stability         LOCKED
```

C4 unlocks the B2 milestone but does NOT pre-authorize
its specific implementation ACT. B2's design (which
B0/B1 layer to grow next, whether to expand the
lexer/tokenizer self-host further, or to target a
different bounded subsystem) is itself a board-design
decision.

After the single C4 CLOSE commit lands, the act
terminates with a hard stop. Do not author B2. Do not
"clean up" residue. Do not push.
