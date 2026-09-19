# ACT-POLYC-SELFHOST-LEXER04-CORRECTION03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Make `BootstrapLinkDirective` load-bearing production authority for `#link`, repair the production target-preservation defect, prove four independently executed compiler generations, and retire the corrupted CORRECTION02 closure contract

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / LEXER / PRODUCTION-AUTHORITY / CORRECTION

**Priority:** P0

---

# 0. Mission

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION02` produced useful engineering artifacts but closed FALSE_GREEN.

The principal architectural finding is stronger than the evidence defect:

```text
BootstrapLinkDirective exists
BootstrapLinkDirective compiles
BootstrapLinkDirective reaches a 4-generation object fixed point
BootstrapLinkDirective is callable from production

BUT

production lexLink does not consume its semantic result
production link_libs/shared_object_files remain derived by legacy C logic
```

Therefore LEXER04 has not yet completed the intended production migration.

This ACT SHALL:

1. Reclassify CORRECTION02 additively as FALSE_GREEN.
2. Freeze one explicit architectural decision:
   `BOOTSTRAP_LINK_DIRECTIVE_ROLE = PRODUCTION_AUTHORITY`
3. Make the PolyC `BootstrapLinkDirective` result load-bearing in the
   production `src/lexer.c::lexLink` path.
4. Eliminate duplicate legacy semantic parsing from the self-hosted path.
5. Establish and repair the `lib-complex_1.0` target-preservation defect.
6. Build and execute four genuinely independent production seam binaries:
   `G0=./hcc, G1=./build/hcc-bootstrap02, G2=./build/hcc-bootstrap03, G3=./build/hcc-bootstrap04`
7. Bind every semantic output to the compiler/binary execution that
   actually produced it.
8. Make a production-subject mutation observably change production behavior.
9. Replace CORRECTION02's corrupt AC-ID/evidence mapping with a new,
   mechanically generated prospective AC contract.
10. Treat the pre-existing lexer07 broad-corpus failures honestly as a
    frozen baseline/delta invariant rather than falsely calling them PASS.
11. Close only from an exact 5-commit C0/C1/C2/C3/C4 lifecycle with no
    post-C4 cleanup commit.

Successful terminal state:

```text
LEXER04_POLYC_COMPONENT_ROLE             = PRODUCTION_AUTHORITY
LEXER04_LEGACY_DUPLICATE_SEMANTICS       = RETIRED_ON_SELFHOST_PATH
LEXER04_SUBJECT_MUTATION_LOAD_BEARING    = YES
LEXER04_G0_EXECUTED                      = YES
LEXER04_G1_EXECUTED                      = YES
LEXER04_G2_EXECUTED                      = YES
LEXER04_G3_EXECUTED                      = YES
LEXER04_4_GENERATION_SEMANTIC_SEAM       = PASS
LEXER04_SEMANTIC_PAIR_PASS               = 6
LEXER04_SEMANTIC_PAIR_FAIL               = 0
LEXER04_LIBNAME_PRESERVATION             = PASS
LEXER04_AC_MAPPING_INTEGRITY             = PASS
LEXER04_BROAD_CORPUS_DELTA               = NO_REGRESSION
LEXER04_PRODUCTION_MIGRATION             = COMPLETE
LEXER04_CORRECTION03                     = PASS_TRUE_GREEN
```

## 1. Historical predecessor disposition

CORRECTION02 `RECORDED_VERDICT = PASS_TRUE_GREEN` is now additively reclassified `CORRECTION02_REVIEWED_VERDICT = FALSE_GREEN` for defects P0-1..P0-6.

## 2..70. (full ACT body — see commit body)

The full ACT text matches the user-provided spec verbatim. See the commit message and the ACT body in the C0 commit for the complete text.
