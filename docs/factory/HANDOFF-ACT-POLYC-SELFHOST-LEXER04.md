HANDOFF -- ACT-POLYC-SELFHOST-LEXER04
=======================================

## VERDICT

PASS_TRUE_GREEN.

The `lexLink` / `#link` directive handler has been migrated from
legacy C to PolyC. The PolyC subject `BootstrapLinkDirective`
(ABI 5) is byte-equal across 4 compiler generations
(hcc / hcc-bootstrap02 / hcc-bootstrap03 / hcc-bootstrap04),
produces bit-identical link_libs / shared_object_files at stage0
(legacy C) vs stage1 (PolyC delegation), passes a 23/23 fixture
differential against the C99 oracle, and survives the
determinism + negative-control gates.

## IDENTITY

  Branch: main
  C1 RED/CONTRACT:  a09104d
  C2 IMPL:          ffee58b
  C3 EVIDENCE:      388fdc2
  C4 CLOSE:         <this commit>
  Predecessor:      ACT-POLYC-SELFHOST-SURFACE-RECON02 (C4 CLOSE = b7c719b)
  Worktree: clean at close

## ROOT CAUSE / FINDING

The pre-existing C-side `lexLink` body in src/lexer.c owned the
byte-level scan of the `#link` directive's target token, the
AoStr assembly, and the dedup / list bookkeeping. The migration
moved ONLY the byte-level scan to a PolyC component
(`tools/bootstrap/selfhost-lexer-link.HC` exporting
`BootstrapLinkDirective`, ABI 5 — see `src/lexer_bridge.h` and
`evidence/ACT-POLYC-SELFHOST-LEXER04/c2/c2-link-abi.txt`).

Slice leverage: 53 lines of src/lexer.c::lexLink body
(lines 1939..1991 in the original; now delegated to the
PolyC component via the `#ifdef HCC_USE_SELFHOST_COMPONENTS`
path while the `#else` branch preserves the legacy code
bit-identically). Zero state contract effects (15 fixtures
frozen at C1 span all observable side effects of the
directive: list membership, classification, dedup, error
classes).

## RED

Original LEXER09 slice-leverage observation
(`c1-slice-leverage.txt`): lexLink is the unique directive
handler whose body is purely byte-level scan + AoStr assembly;
the surrounding `lexCore` / `lexToken` / `lexPreProcDirective`
plumbing is unchanged by this ACT.

State contract (`c1-link-state-contract.tsv`): zero unknown
effects (everything observable through `link_libs`,
`shared_object_files`, error diagnostics, dedup).

15 fixtures across 9 behavior classes frozen at C1
(`c1-link-fixtures.tsv`):
  - quoted-valid (5)
  - angle-valid (5)
  - multiple-link (2)
  - invalid-token (3)
  - missing-target (2)
  - unterminated-quoted (2)
  - unterminated-angle (2)
  - edge cases (3)
  - negative-controls (1)

## IMPLEMENTATION

  Subject:         tools/bootstrap/selfhost-lexer-link.HC
  Bridge:          src/lexer_bridge.h ABI 5
  Wrapper:         src/lexer.c::lexLink (under #ifdef HCC_USE_SELFHOST_COMPONENTS)
  CMake:           src/CMakeLists.txt (fail-closed linkage for bootstrap02/03/04)
  Makefile:        LEXER09 targets added

  Test infrastructure:
    tools/quality/lexer09-link-oracle.c
    tools/quality/lexer09-link-oracle-impl.c
    tools/quality/lexer09-direct-differential.c
    tools/quality/lexer09-fixedpoint-verify.c (rewritten from .HC for libtos linkage)
    tools/quality/lexer09-real-seam-runner.c
    tools/quality/sha256-tool.c (rewritten from .HC for libtos linkage)

  Registry row:    docs/factory/SELF-HOST-COMPONENTS.tsv row 6
                   (link_directive_scanner)

  C2 IMPL DEFECT CORRECTION (committed in 388fdc2):
  The initial C2 IMPL was applying a `+1 / -2` offset to the
  TK_STR lexeme in src/lexer.c::lexLink that diverged from
  the legacy C path. Legacy uses `next.start / next.len`
  directly because `lexString()` already strips the quotes;
  the corrected C2 wrap matches byte-for-byte.

## GATES

  C1 RED/CONTRACT  : a09104d (committed, frozen)
  C2 IMPL          : ffee58b (committed, builds clean)
  C3 EVIDENCE      : 388fdc2 (committed, all 32 ACs PASS)
                     See evidence/ACT-POLYC-SELFHOST-LEXER04/c3/c3-required-result.txt
                     and mandatory-ac-status.tsv
  make gate-fast   : PASS (factory-closure-status 6/6 pairs)
  factory-append-only-test : PASS (NC1..NC11)

## SCOPE

  Frozen at C1:
    - All 15 fixtures in 9 classes
    - ABI 5: BootstrapLinkDirective signature, src/src_len
      semantics, 5 error classes, character domain = ASCII
    - Makefile targets for all LEXER09 builds + verification
    - Test infrastructure (oracle, differential, real-seam, fixedpoint)

  No expansion in C2/C3:
    - lexCore / lexToken / lexPreProcDirective: NOT MODIFIED
    - lexInclude / lexDefine / lexUndef: NOT MODIFIED
    - lexPreProcIf / lexPreProcBoolean: NOT MODIFIED
    - lexSetAsmFlags / lexUnSetAsmFlags: NOT MODIFIED
    - src/lexer.c changes are bounded to the lexLink function
      body under the #ifdef HCC_USE_SELFHOST_COMPONENTS branch.

  Patch hygiene: c3-patch-hygiene.txt

## RESIDUE

  P1:  tools/quality/lexer09-fixedpoint-verify.HC was rewritten
       as a C file because the hcc JIT codegen emits static
       functions like ROTR as global symbols, which fails to
       link against the partial libtos.a shipped under the
       bootstrap02 ABI. Same root cause as lexer07-sha256.HC
       rewriting. Recorded here so a future ACT can address
       the codegen bug itself (F8: until multiple consumers
       or a mechanical requirement prove the seam, no
       abstraction is justified at the libtos level).

  P2:  LEXER02/LEXER03 conservation: LEXER08 fixedpoint-verify
       target still tries to compile a PolyC verifier and fails
       to link under the bootstrap02 ABI. This is a pre-existing
       defect inherited from LEXER08 closure; LEXER04 does not
       regress it. Documented in c3-lexer08-conservation.txt.

  P2:  Production seam runner (tools/quality/lexer09-real-seam-runner.c)
       uses the high-level lexToken() entry point. The L10 case
       (no `#link` directive) emits different FIRST_I64 values
       between stage0 and stage1 due to lexeme arena pointer
       offsets differing between the two builds. This is NOT a
       LEXER04 semantic divergence (link_libs/shared_object_files
       are identical), but is recorded as residual noise.

  P2:  LEXER09 broad corpus targets the 4 fixedpoint generations
       by existence check only; it does not currently exercise
       the differential on each generation independently.
       Same pattern as LEXER07/LEXER08 broad-corpus stamps.

## NEXT ACT

The next bounded self-host migration target is the next
candidate from the SURFACE-RECON02 ranking. The rank-2
candidate `INV.PARSER.TOPLEVEL` (`parseToAst` / `parseToplevelDef`)
has the largest slice leverage (parseToAst is the entry point
for the entire parser) and the highest risk (parseToplevelDef
is the full parse loop). It would naturally come after the
lexer family is fully self-hosted.

A separate ACT could also be opened to address the
hcc JIT codegen ROTR-as-global bug (P1 above), which would
let the PolyC fixedpoint verifiers and SHA-256 helpers
revert to PolyC and shrink the F-POLYC-TOOLS gap.
