# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01

VERDICT

HALT_GATE_PUSH_NOT_GREEN

  HALT_CLASS = GOVERNANCE
  BLOCKS_NEXT = NO

  CORRECTION NOTICE (ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-
  CORRECTION01)

  This HANDOFF's VERDICT section was CORRECTED by
  ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01, which
  records the corrected disposition of this ACT in its own artifacts and
  in the ROADMAP. The correction changed NOTHING about this ACT's
  engineering result, its evidence, or its measured values; it repaired
  this ACT's CLOSE TOPOLOGY.

  THE TOPOLOGY DEFECT: a commit carrying this ACT's id was made AFTER
  this ACT's C4 CLOSE commit, in order to record the external terminality
  observations. docs/factory/GIT-METADATA.md section 3, rule 7 forbids
  that: "No commit after CLOSE may carry `ACT: <id>`." Because the
  history is append-only, the offending commit could not be removed, so
  the Factory's correction mechanism was used instead: a new ACT id with
  its own contiguous C0..C4 range, whose CLOSE records the external
  terminality observations INSIDE the range.

  The mechanical range check confirms the predecessor's range is now
  well-formed:
    $ bash scripts/quality/factory-v2-range-check.sh \
        ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 290d917
    (the range ending at this ACT's own CLOSE passes rules 1..7)

  The predecessor's EVIDENCE is untouched (F14). Only this VERDICT
  section, which by the Factory's own rule owns the terminal verdict,
  is corrected.

  WHY THIS VERDICT, AND NOT PASS
  ------------------------------
  ACT section 40 lists `GATE_PUSH_UNMODIFIED=PASS` among the
  preconditions for a production PASS verdict. That precondition is NOT
  met: the unmodified full push gate fails, at its `gep01` check.
  ACT section 42 is explicit about the consequence:

    "If a binding mandatory predicate fails, use the appropriate honest
     HALT_* verdict and the Factory-required HALT_CLASS and BLOCKS_NEXT
     trailers."

  `HALT_GATE_PUSH_NOT_GREEN` is the token this ACT's own HALT taxonomy
  (section 45) defines for exactly this condition. The verdict was
  additionally validated against the mechanical classifier
  (tools/factory/factory-halt-classification.HC), which reports:

    MODE=ACT
    STATUS=PASS
    VERDICT=HALT_GATE_PUSH_NOT_GREEN
    HALT_CLASS=GOVERNANCE
    BLOCKS_NEXT=NO

  A PASS verdict is NOT available here: the mechanical checker rejects
  HALT_CLASS on a PASS verdict, and the gate is not green.

  WHY THIS VERDICT IS NOT A BLOCKER FOR THE ROADMAP
  -------------------------------------------------
  The failing check is the PRE-EXISTING LLVM GEP01 cap-verifier defect.
  Its failing rows are BYTE-IDENTICAL to the baseline recorded before
  this ACT, and the Factory's own ROADMAP already records the same
  defect as pre-existing. It is not attributable to this ACT's
  production delta, which is mechanically GREEN.

  HALT_CLASS=GOVERNANCE with BLOCKS_NEXT=NO is therefore the correct
  classification, and it is the Factory's documented board signal that
  the roadmap may proceed: no additional authorization artifact is
  required for a same-scope successor ACT to open.

  THE ENGINEERING OBJECTIVE IS MET AND MEASURED
  ---------------------------------------------
  A clean Git checkout now builds the default production compiler with
  the PolyC parser-padding authority, with no ignored or hand-placed
  binary anywhere in the path:

    COLD_BUILD=PASS
    PRODUCTION_PADDING_AUTHORITY=POLYC
    BOOTSTRAP_GRAPH_ACYCLIC=YES
    STALE_OBJECT_REUSE=NO
    WRONG_ARCH_REJECTED=YES
    WRONG_BOOTSTRAP_REJECTED=YES
    PARSER_PADDING_CONSERVATION=PASS
    LEXER_CONSERVATION=PASS
    F14=PASS
    PATCH_HYGIENE_ERRORS=0

  Every engineering predicate of section 40 is met. The ONE unmet
  predicate is the full gate, and it is unmet for a reason that
  predates this ACT.

  A second, separate pre-existing condition is also reported rather
  than hidden: the repository-wide F-NO-PYTHON checker reports FAIL on
  seven PRE-EXISTING tracked Python files. This ACT added no Python.

  Per F13 this handoff reports the measured result rather than asserting
  a passing gate.

---

## 1. Mission and disposition

```text
ACT                    = ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01
AUTHORIZED ENTRY       = fda4a62add5c2f268d1904f9243731727ae5d00b
PRIMARY HOST           = macOS ARM64 (AppleClang 15.0.0, CMake 4.1.6,
                          LLVM 22.1.8)
VERDICT                = HALT_GATE_PUSH_NOT_GREEN
HALT_CLASS             = GOVERNANCE
BLOCKS_NEXT            = NO
```

The ACT's objective was to repair PolyC's bootstrap dependency graph so
that

```bash
make clean
make
```

works from a clean Git checkout, with the production compiler using

```text
src/parser.c::CalcPadding
  -> BootstrapCalcPadding
  -> PolyC-generated object
```

and with the legacy implementation available only as an explicit
stage0/differential control.

---

## 2. Measured root cause

The entry tree had TWO build blockers and TWO warm-tree assumptions.

```text
B1 = the parser-padding object was never SCHEDULED by the build.
     src/CMakeLists.txt probed `if(NOT EXISTS ...)` at CONFIGURE time.
     Nothing in the graph ever produced the object, so on a clean
     checkout the configure always aborted:
       "required self-host parser-padding component missing at
        .../build/parser-padding-subject.o"
     => CYCLE 1: make all -> padding object -> ./hcc -> make all

B2 = the runtime producer was demanded at GLOBAL CONFIGURE time.
     src/CMakeLists.txt aborted EVERY configuration -- including
     compiler-only ones -- when build/hcc-bootstrap04 was absent. The
     producer is itself produced by a chain that runs a cmake
     configure, so the gate forbade the chain that produces the gate's
     input.
     => CYCLE 2: bootstrap04 -> ... -> test-prefix-install ->
        cmake configure -> HCC_BOOTSTRAP -> bootstrap04

B3 = CMAKE_RUNTIME_OUTPUT_DIRECTORY was an unconditional normal
     variable (`../`), so an isolated stage0 build would overwrite the
     production ./hcc.

B4 = a cross build needed a TARGET-ARCHITECTURE padding object; the
     native one is architecture-incompatible.

B5 = the runtime install depended on a provenance-strict producer that
     could only be satisfied by a hand-placed binary.

B6 = the Linux runtime port has separate, pre-existing limitations.
```

A further class of defect was found during C2 verification: several
QUALIFICATION targets (the parser-padding four-generation fixed point,
the bootstrap stage builds) consumed warm-tree artifacts with NO
declared dependency. On a clean tree they failed with "No rule to make
target build/hcc-bootstrap02" and "required self-host operator component
missing". These were the same defect class as B1 and are now DECLARED.

---

## 3. Final dependency graph

```text
  host C compiler
       |
       v
  [S0] bootstrap-stage0          build/host-stage0/hcc
       |   -DHCC_USE_SELFHOST_PARSER_PADDING=OFF   (legacy control)
       |   -DHCC_RUNTIME_OUTPUT_DIRECTORY=<abs>/build/host-stage0
       |   PREV: src/**.c src/**.h
       v
  [P]  bootstrap-prefix          build/bootstrap-prefix/include/tos.HH
       |   header-only. NO runtime archive. NO global fallback.
       |   PREV: src/holyc-lib/tos.HH
       v
  [PP] parser-padding-subject    build/parser-padding-subject.o
       |   produced by build/host-stage0/hcc -c <src> -o <obj>
       |   verified: symbol _BootstrapCalcPadding present
       |   verified: object architecture == target architecture
       |   PREV: the PolyC subject, S0, P
       v
  [H]  production hcc             ./hcc
       |   HCC_USE_SELFHOST_PARSER_PADDING=ON
       |   CMake SCHEDULES PP production via
       |     add_custom_command(OUTPUT ... DEPENDS ...)
       |   PREV: PP, src/**, src/CMakeLists.txt, src/cmake/*.cmake
       v
  [RP] runtime-producer          build/runtime-producer/hcc-bootstrap04
       |   reproduced from the PINNED source tree and verified against
       |   the FROZEN sha256 identity
       |   PREV: (independent of the current tree's build graph)
       v
  [I]  canonical runtime install  build/test-prefix/lib/libtos.{a,dylib}
       |   PREV: production hcc, runtime-producer
```

BOOTSTRAP_GRAPH_ACYCLIC=YES. Both historical cycles are broken:

* cycle 1 is broken because the padding subject is produced by the
  ISOLATED stage0 compiler, which does not depend on the padding
  subject;
* cycle 2 is broken because the strict producer check moved from global
  configure time to the point where the runtime is actually produced,
  and because the producer is now REPRODUCIBLE from a clean tree
  instead of being hand-placed.

---

## 4. Changed production files

```text
Makefile                        the bootstrap graph, the qualified runtime
                                producer, the file-level edges, and the
                                isolated stage0 output directory
src/CMakeLists.txt              the parser-padding scheduling seam, the
                                overridable runtime output directory, and
                                the relocation of the strict producer check
src/cmake/RequireRuntimeProducer.cmake    the shared fail-closed producer
                                          verification
src/cmake/VerifyParserPaddingObject.cmake  the fail-closed padding-object
                                          verification
.github/workflows/release.yml   the corrected bootstrap ordering and the
                                target-architecture cross object
.gitignore                      the pinned producer's materialized tree
```

NOT changed (the ACT's frozen exclusions):

```text
src/parser.c                              UNCHANGED
tools/bootstrap/selfhost-parser-padding.HC UNCHANGED
src/lexer.c and the LEXER self-host implementations  UNCHANGED
the compiler's parser and code generator semantics     UNCHANGED
scripts/quality/gate-push.sh               UNCHANGED
scripts/quality/gate-fast.sh               UNCHANGED
.githooks/pre-push                         UNCHANGED
the Factory-v2 range-check implementation  UNCHANGED
any closed predecessor's evidence or HANDOFF UNCHANGED
```

---

## 5. Negative controls

All five were executed in isolated detached worktrees at the C2
candidate commit.

```text
N01  missing stage0 compiler
     BUILD_RC_NONZERO=YES (2), PRODUCTION_FALLBACK_TO_LEGACY=NO,
     ./hcc NOT produced
N02  failed object producer
     PADDING_OBJECT_PRODUCER_FAILED=YES, BUILD_RC_NONZERO=YES (2),
     STALE_OBJECT_ACCEPTED=NO, PRODUCTION_HCC_LINKED=NO
N03  wrong-architecture object (a REAL x86_64 Mach-O object)
     WRONG_ARCH_OBJECT_DETECTED=YES, PRODUCTION_LINK_RC_NONZERO=YES (2),
     SILENT_LEGACY_FALLBACK=NO
N04  stale artifact (producer input invalidated, old object retained)
     STALE_OBJECT_REUSED=NO (the producer demonstrably re-ran),
     PRODUCER_INPUT_CHANGE_DETECTED=YES, and the dependent compiler
     RELINKED
N05  wrong bootstrap04 producer
     WRONG_BOOTSTRAP04_PRODUCER_REJECTED=YES,
     CANONICAL_RUNTIME_ARCHIVE_ACCEPTED=NO

NEGATIVE_CONTROLS_PASS=5
NEGATIVE_CONTROLS_FAIL=0
```

The forbidden silent fallbacks of ACT section 17 were each checked
against the implementation and, where reachable, exercised: missing
object, legacy fallback, cached-object acceptance, random-system-hcc
fallback, expected-SHA recomputation, and continue-linking-after-
failure. None is implemented.

---

## 6. Positive controls

```text
P01 pristine build from a clean checkout
    CLEAN_BUILD_RC=0, STAGE0_BUILT=YES, PADDING_OBJECT_BUILT=YES,
    PRODUCTION_HCC_BUILT=YES, PRODUCTION_PADDING_AUTHORITY=POLYC,
    PREEXISTING_IGNORED_BINARIES=0
P02 LLVM-enabled clean build
    LLVM_ENABLED_CLEAN_BUILD=PASS (LLVM 22.1.8 linked),
    PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC
P03 cold runtime install
    RUNTIME_INSTALL_FROM_COLD_BUILD=PASS,
    BOOTSTRAP_PRODUCER_PROVENANCE=PASS (the pinned sha256),
    LIBTOS_REQUIRED_SYMBOLS=PASS (all 5 symbols)
P04 incremental build
    NOOP_REBUILD_UNNECESSARY_OBJECT_REBUILDS=0,
    SOURCE_CHANGE_REBUILDS_PADDING_OBJECT=YES,
    SOURCE_CHANGE_RELINKS_PRODUCTION_HCC=YES
P05 parser-padding qualification
    PARSER_PADDING_TEST=PASS (direct differential, algebraic invariants,
    generation provenance, four-generation fixed point, and the M1..M4
    mutation load-bearing control)
P06 LEXER conservation
    LEXER01 47/47, LEXER02 89/89, LEXER03 45/45, LEXER04 23/23,
    LEXER07 direct differential 89/89 and fixture inventory PASS,
    LEXER07_NEW_FAILURES_INTRODUCED=0
P07 full push gate
    GPUSH_BUILD=PASS, GPUSH_INSTALL=PASS, GPUSH_AOT=PASS,
    GPUSH_JIT=PASS, GPUSH_LSP=PASS (lsp 43/43),
    GPUSH_GEP01=FAIL (PRE-EXISTING), GATE_PUSH_BYPASS_USED=NO
```

The padding subject's sha256 is
`187a4de9465e8dbe3c640484b05540daaad4a3267dd1543a169e3c304b02d5b1`,
byte-identical to the value frozen by the closed predecessor
ACT-POLYC-SELFHOST-PARSER-PADDING01. The object is therefore produced
from the CURRENT source tree and is the qualified artifact.

The qualified runtime producer's sha256 is
`3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6`,
equal to the FROZEN provenance constant. It is REPRODUCIBLE from a clean
checkout, which is what makes the existing check satisfiable without a
hand-placed binary.

---

## 7. Platform matrix

```text
macOS ARM64 (native)      cold build GREEN, canonical runtime GREEN,
                          padding authority POLYC. The CI-only packaging
                          and smoke step was not executed locally.
macOS x86_64 (cross)      an x86_64 Mach-O padding object and an x86_64
                          Mach-O compiler were produced and linked; the
                          compiler carries _BootstrapCalcPadding.
Linux x86_64              UNQUALIFIED -- no host, no CI observation.
Linux aarch64             UNQUALIFIED -- no host, no CI observation.
```

NO four-platform release PASS is inferred from a one-host test. The two
Linux legs are reported as unqualified, not as green.

---

## 8. Gate results

```text
make gate-fast                             PASS
scripts/quality/factory-append-only-test.sh PASS (11/11)
git diff --check <entry>..HEAD              0 errors
factory-no-python-check                     FAIL (7 PRE-EXISTING tracked
                                            Python files; this ACT added
                                            none)
./scripts/quality/gate-push.sh HEAD         FAIL at the gep01 check
```

The gate-push failure is the pre-existing LLVM GEP01 cap-verifier
defect. Its four failing rows are byte-identical to the baseline in
evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/c3/
gate-push-correction01.log, and the counts are the same
(GEP01_PASS=26 / GEP01_FAIL=4). The defect is also recorded as
pre-existing in the Factory's own ROADMAP. No bypass was used: the
gate script was not modified, no environment trick was applied, no
hook was replaced, and no check was disabled.

---

## 9. Known limitations and outstanding unrelated defects

```text
R1 (P1, PRE-EXISTING, separately owned)
   The GEP01 cap-verifier defect. scripts/quality/llvm-cap-table-verifier.py
   is a PYTHON tool, which is also in tension with F-NO-PYTHON. The
   measured cause of the four failing rows is the SHAPE_DEPENDENT
   counter and the three sibling-opcode rows, reproduced identically
   before this ACT. NOT repaired here: repairing it is out of this
   ACT's scope, and it would require migrating legacy Python tooling.

R2 (P1, PRE-EXISTING, owned by ACT-POLYC-TOOLING-LINUX-PORT01)
   The Linux runtime port is macOS-only in this build
   (src/CMakeLists.txt: "Tooling runtime host is macOS-only in this
   build."). The Linux release legs do not use the cmake install seam,
   so they are not blocked by it, but the runtime port itself remains
   unsupported there. NOT repaired here.

R3 (P1, PRE-EXISTING)
   The compiler's `@@N` asm local-label rendering regression. It is
   present in BOTH the current tree's stage0 and the pinned producer's
   stage0, and it is precisely why the runtime producer must come from
   the pinned source tree rather than from a freshly built current-tree
   compiler. Named in src/CMakeLists.txt. NOT repaired here.

R4 (P2, PRE-EXISTING, separately owned)
   CORRECTION01's historical Factory-v2 range-check FAIL. A governance
   defect, explicitly not repaired or reclassified by this ACT.

   MEASURED ROOT CAUSE (new, for the next owner): the range check reads
   the CLOSE commit's trailers with git's %(trailers) formatter, and
   Git 2.54.0's TRAILER PARSER REJECTS THE ENTIRE TRAILER BLOCK when any
   trailer key contains an UNDERSCORE. Measured:

     printf 'x\n\nACT: A\nACT-Phase: CLOSE\n' | git interpret-trailers --parse
       -> ACT: A / ACT-Phase: CLOSE            (parses)
     printf 'x\n\nACT: A\nACT-Phase: CLOSE\nHALT_CLASS: G\n' | git interpret-trailers --parse
       -> (empty; the whole block is dropped)

   Every underscore-bearing key (HALT_CLASS, BLOCKS_NEXT, HALT_X) drops
   the block; HALTCLASS does not. ACT section 42 REQUIRES HALT_CLASS and
   BLOCKS_NEXT on a HALT_* CLOSE, so a conforming HALT commit cannot be
   read by the current range check.

   THE SAME DEFECT ALREADY AFFECTS THE FACTORY'S OWN PRECEDENT: the
   established precedent commit 505b007 (ACT-POLYC-AOT-PIC-EXTERNAL-
   REFS01-CORRECTION01) fails the identical check with the identical
   reason.

   This ACT's own topology is correct: FIRST is the C0 commit
   (85c6e29, ACT-Phase=RED), the C3 commit is f05a84e
   (ACT-Phase=EVIDENCE), the CLOSE commit 290d917 is a direct
   descendant on a linear append-only history, and the CLOSE message
   contains exactly one ACT, one ACT-Phase: CLOSE and one ACT-Verdict.
   See c3/factory-v2-range-check.txt for the full transcript.

R5 (P2, QUALIFICATION, not a defect)
   The Linux release legs were not executed: this environment has no
   Linux host and no CI observation. They are reported as unqualified.
```

---

## 10. Board effect

```text
PARSER_PADDING_COMPONENT=TRUE_GREEN
PARSER_PADDING_PRODUCTION_DELEGATION=TRUE_GREEN
PARSER_PADDING_CLEAN_BUILD=TRUE_GREEN
PARSER_PADDING_BUILD_GRAPH=ACYCLIC
PARSER_PADDING_PUSH_GATE=QUALIFIED_EXCEPT_PREEXISTING_GEP01

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

---

## 11. Evidence index

```text
c0/  entry-identity.txt, production-source-freeze.tsv,
     preexisting-gate-state.txt, build-graph-contract.txt, scope.txt
c1/  c1-red1-clean-build.txt, c1-red2-dependency-graph.txt,
     c1-red3-compiler-only-config.txt, c1-red4-gate-push.txt,
     c1-red5-release-matrix.txt, c1-frozen-design.txt,
     c1-provenance-mechanism.txt, c1-summary.txt
c2/  dependency-graph-after.txt, stage0-build.txt, bootstrap-prefix.txt,
     padding-object-build.txt, production-link.txt,
     architecture-provenance.tsv, cmake-contract.txt,
     makefile-contract.txt, release-workflow-delta.txt,
     production-source-conservation.tsv
c3/  cold-build-before-after.txt, cold-build-command-transcripts.txt,
     stage0-provenance.tsv, padding-object-provenance.tsv,
     production-hcc-provenance.tsv, incremental-build.txt,
     n01-stage0-missing.txt, n02-object-producer-failure.txt,
     n03-wrong-architecture.txt, n04-stale-object.txt,
     n05-wrong-producer.txt, parser-padding-conservation.txt,
     lexer-conservation.txt, gate-push-unmodified.txt,
     runtime-install.txt, release-matrix.tsv,
     production-source-freeze-check.txt, f14-conservation.txt,
     factory-gates.txt, factory-v2-range-check.txt,
     mandatory-ac-status.tsv, required-result.txt
```
