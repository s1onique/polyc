HANDOFF -- ACT-POLYC-SELFHOST-SURFACE-RECON02
==============================================

## VERDICT

PASS_TRUE_GREEN.

The next bounded self-host migration target is **mechanically selected**:
`INV.LEXER.LINK` (atomic slice: `lexLink` / `#link` directive).

The successor ACT is **ACT-POLYC-SELFHOST-LEXER04**, with frozen scope,
RED, and proof contract.

## IDENTITY

  Branch: main
  C0 AUTH:      0b13abd
  C1 INVENTORY: f2ec425
  C2 RANK:      ea46eef
  C3 VERIFY:    e808108
  C4 CLOSE:     <this commit>
  Predecessor:  ACT-POLYC-SELFHOST-LEXER03-CORRECTION02
                C3 EVIDENCE = c2504a2, C4 CLOSE = 4fa66c7
  Worktree: clean at close

## How much compiler semantic surface remains non-self-hosted?

Of 26 inventoried surfaces (live tree, not historical count):

  SELFHOSTED_TRUE_GREEN         4   (lexer: trivia, ident, scalar, opclass)
  LEGACY_C_AUTHORITY           19   (the candidates for migration)
  LEGACY_NON_POLYC_AUTHORITY    1   (runtime library — not compiler surface)
  BUILD_ORCHESTRATION           1
  QUALITY_TOOLING               1

So 19 compiler-semantic surfaces still own authoritative C code.
Of those, 3 are eligible bounded candidates under the §12 predicate:

  - INV.LEXER.LINK        (lexLink/lexCore dispatch + directive handlers)
  - INV.PARSER.TOPLEVEL   (parseToAst + parseToplevelDef)
  - INV.PARSER.COMPOUND   (parseCompoundStatementInternal)

The remaining 16 surfaces are classified DOES_NOT_BLOCK_SELFHOST
(cross-cutting, CHARTER-preserved reference backend, REPL/tooling/experimental,
plumbing).

## Which surfaces still own production authority?

All 19 LEGACY_C_AUTHORITY rows in `c1-authority-residue.tsv`. They are reached
in G0/G1/G2/G3 (per `c1-stage-ownership.tsv`).

## Which are merely legacy residue?

Surfaces tagged DOES_NOT_BLOCK_SELFHOST in `c1-blocker-classification.tsv`:

  Plumbing:        INV.MEM.ARENA, INV.UTIL.MISC
  Tooling:         INV.LSP, INV.TRANSPILE, INV.JIT.X86
  Cross-cutting:   INV.PARSER.COMPOUND, INV.PARSER.SUBSCRIPTS,
                   INV.AST.CREATE, INV.CCTRL.SCOPE, INV.DIAG.PRINT,
                   INV.IR.LOWER, INV.IR.CGFUN, INV.MAIN.DRIVER,
                   INV.PREPROC.PP
  CHARTER-preserved: INV.CODEGEN.X86, INV.CODEGEN.AARCH64
  Experimental:    INV.LLVM.BACKEND

These cannot be migrated as bounded atomic units without enabling ACTs
(parser, cctrl, AST, IR, driver).

## Which stage(s) depend on each?

All three eligible candidates reach G0/G1/G2/G3 (stage_reach=4). See
`c1-stage-ownership.tsv` and `c2-candidate-metrics.tsv`.

## Which candidate ranked first?

**INV.LEXER.LINK** (atomic slice: `lexLink` / `#link` directive).

## Why did it rank first mechanically?

Per §14 lexicographic tuple (R1..R6):

  R1 leverage: 3 (BLOCKS_NEXT_SELFHOST_STAGE; only surface in inventory
                  with this classification)
  R2 src_count: 1 (single responsibility)
  R3 callers:   12 (parseToAst, cctrlInitParse, lexLink, lexPushFile, ...)
  R4 obs:       3 (existing direct differential + real production seam)
  R5 stage:     4 (all four generations reach it)
  R6 loc:       1200 LOC in src/lexer.c minus the 4-5 delegated functions

INV.PARSER.COMPOUND and INV.PARSER.TOPLEVEL both have R1 leverage=2
(BLOCKS_PRODUCTION_POLYC_AUTHORITY) and lose on R1 alone.

## What exactly may the next ACT change?

Per `c2-next-act-scope.txt`:

  ALLOWED_PRODUCTION_FILES =
      src/lexer.c                  (modify lexLink body only)
      tools/bootstrap/selfhost-lexer-link.HC   (NEW PolyC component)
      Makefile                     (add build rule + tests)
      tools/quality/lexer09-link-oracle.c
      tools/quality/lexer09-link-oracle-impl.c
      scripts/quality/lexer09-link-direct-differential.sh

  FORBIDDEN_SUBSYSTEMS =
      src/parser.c, src/ast.c, src/cctrl.c, src/ir.c, src/x86_64.c,
      src/aarch64.c, src/llvm-backend.c, src/main.c, src/cli.c,
      src/lexer.c::lexCore, lexLink semantics beyond the #link directive,
      and any already-migrated PolyC component (.HC).

## What exactly must it prove?

Per `c2-next-act-proof-model.txt`:

  REQUIRED:
    direct differential          (lexer09-direct-differential: N/N PASS)
    production seam              (lexer09-real-seam-runner: G0/G1/G2/G3
                                  produce the same l->cc->link_libs and
                                  l->cc->shared_object_files for #link "..."
                                  and #link <...>)
    stage seam                   (4-stage same compilation, byte-identical
                                  link-list output)
    object fixed point           (4-gen fixed point of selfhost-lexer-link.o)
    corpus conservation          (existing lexer08 broad corpus 45/45 PASS)
    negative mutation control    (mutated BootstrapLinkDirective must cause
                                  verifier to exit non-zero)
    provenance binding           (source SHA + 4 compiler SHAs + 4 object SHAs
                                  recorded in C2 IMPL and C3 EVIDENCE commits)

## Which tempting alternatives were deferred and why?

1. **INV.PARSER.TOPLEVEL (parseToAst)** — top-level parser dispatch.
   Atomic candidate in principle, but:
   - No atomic oracle exists (parser corpus only via end-to-end smoke)
   - Cross-cuts INV.CCTRL.SCOPE (parser raises cctrl exceptions, syncs
     toplevel, peeks tokens)
   - A successful migration would likely require migrating parseCompound
     simultaneously or risk splitting the parser at an unstable boundary
   - Deferred; would need an enabling ACT first

2. **INV.PARSER.COMPOUND (parseCompoundStatementInternal)** — body
   dispatcher.
   - ~1100 LOC
   - No atomic oracle exists
   - Cross-cuts cctrl (depends on cc->tmp_locals, cc->localenv,
     cc->current_recovery, setjmp)
   - Cannot be migrated without cctrl

3. **INV.PREPROC.PP (lexPreProcIf etc.)** — preprocessor directives.
   - Interleaved with lexCore dispatcher; would couple LEXER04 with
     preprocessor migration
   - Deferred; better as its own atomic ACT if pursued

4. **INV.MAIN.DRIVER / INV.CCTRL.SCOPE / INV.AST.CREATE / INV.IR.LOWER /
   INV.CODEGEN.X86 / INV.CODEGEN.AARCH64** — not bounded atomic
   candidates; CHARTER-preserved, experimental, or cross-cutting.

5. **A natural "LEXER04 = lexLink + lexInclude" pair** — feasible but
   lexInclude is ~150 LOC and touches l->builtin_root + l->cur_file for
   path resolution. Keeping LEXER04 to a single atomic directive
   (`#link`) is the most atomic possible slice; the #include slice
   could be a follow-on LEXER05 candidate.

## Top 5 eligible candidates

Only 3 surfaces pass the §12 eligibility predicate:

  1. INV.LEXER.LINK         SELECTED (lexLink / #link directive)
  2. INV.PARSER.COMPOUND    DEFERRED (parseCompoundStatementInternal)
  3. INV.PARSER.TOPLEVEL    DEFERRED (parseToAst + parseToplevelDef)

(No 4th or 5th; remaining residues fail the §12 predicate: cross-cutting,
no atomic oracle, or CHARTER-preserved reference backend.)

## NEXT

Per ACT §30: only after TRUE GREEN, freeze the successor ACT ID and scope.

NEXT = ACT-POLYC-SELFHOST-LEXER04
  Atomic slice: lexLink (#link directive)
  Scope: as frozen in c2-next-act-scope.txt
  RED: as bound in c2-next-act-red.txt
  Proof model: as classified in c2-next-act-proof-model.txt

After LEXER04 closes, the next surface-recon ACT will re-evaluate
INV.PARSER.* and any newly-emerging surfaces.
