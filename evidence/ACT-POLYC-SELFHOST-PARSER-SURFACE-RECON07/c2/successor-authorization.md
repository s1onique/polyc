# SUCCESSOR AUTHORIZATION

```text
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE08
NEXT_ACT_STATUS=READY_TO_DRAFT
NEXT_TARGET=SUB-002
NEXT_TARGET_CLASS=STRUCTURAL
NEXT_TARGET_DECISION=DEFAULT_ARM_TERMINATION
SUCCESSOR_IMPLEMENTATION_DELTA=0
```

## WHAT THIS ACT AUTHORIZES

Exactly ONE thing: the DRAFTING of
`ACT-POLYC-SELFHOST-PARSER-SLICE08`, a fresh implementation ACT whose
subject is the migration of the **SUB-002 default-arm termination
decision** from the legacy C authority to a compiled PolyC component.

## WHAT THIS ACT DOES NOT AUTHORIZE

* It does NOT authorize EXECUTING or CLOSING SLICE08. SLICE08 needs
  its own ACT, its own entry identity and its own entry check.
* It does NOT authorize any eighth PolyC parser authority to exist
  yet. `PRODUCTION_SEMANTIC_DELTA=0` for THIS ACT.
* It does NOT authorize touching `src/ast.c`, `src/prslib.c`,
  `src/prsutil.c`, `src/cctrl.c`, `src/lexer.c`, `src/transpiler.c`,
  `src/ir.c` or `src/x86.c`.
* It does NOT authorize any historical artifact to be edited.
* It does NOT authorize repairing any of the excluded backlog items
  (the SLICE06 stale CMake `--install-dir` producer wiring, the
  factory-halt-classification inline-assembly tool-build failure, the
  unlanded F-POLYC-TOOLS checker, the 12 F-NO-PYTHON violations, the
  15 LEXER07 broad-corpus failures, the 67 cross-target prefix
  failures, the shared `/tmp/holyc-asm.s` collision, ARM64 stage-0
  portability, or the Dafny proof work).

## THE SUBJECT SLICE08 MUST IMPLEMENT

```text
CANDIDATE=SUB-002
DECISION=DEFAULT_ARM_TERMINATION
SOURCE=src/parser.c:1683-1684
SOURCE_SHA256=a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
ABI=I64 ast_kind -> I64 terminate
SEAM=the single `if (...) break;` in the default-arm loop of parseDefaultStatement
SELECTOR=HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES
```

## THE FROZEN ARTIFACTS SLICE08 MUST CONSUME

```text
selected-source-and-identity.md
selected-production-seam.md
selected-abi.md
selected-enums-fixture.tsv
selected-real-c-oracle.md
selected-causal-contract.md
selected-generation-and-provenance.md
selected-negative-controls.md
selected-conservation-contract.md
selected-red-contract.md
selected-scope-and-ownership.md
selected-ranking-and-exclusions.tsv
selected-contract-hashes.tsv
```

## THE FALLBACK

If SLICE08's implementation of SUB-002 fails its own gates, the
canonical order makes **SUB-004** (the keyword-to-statement dispatch
in `parseStatement`, src/parser.c:1773-1786) the next candidate to
test. It is ELIGIBLE. It is NOT claimed to be causally feasible by
this ACT, and a successor that takes the fallback MUST run its own
causal feasibility experiment for SUB-004.

## THE PRECONDITIONS SLICE08 MUST RE-VERIFY

1. The source range and its SHA-256, re-derived from SLICE08's OWN
   entry tree. If they differ from the values frozen here, SLICE08
   MUST HALT rather than proceed.
2. The seven existing production authorities, still present and still
   PolyC-owned.
3. The canonical eligibility checker and ranker, still unmodified.
4. The 41-row fixture, still bound to the live AstKind values.
