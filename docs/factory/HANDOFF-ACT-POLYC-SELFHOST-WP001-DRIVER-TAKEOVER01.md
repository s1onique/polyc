# HANDOFF-ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01

ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01

VERDICT

PASS_WITH_RESIDUE

The remaining WP-001 compiler-driver semantic authority moved from C
to the compiled PolyC driver, and the production compiler's behaviour
is conserved. The plan-validity experiment found one FAIL-OPEN in the
route guard, which was repaired and re-measured with a causal
negative control. The only open item is a P2 SURFACE residue: three
ordered-plan exports that the host does not consume.

IDENTITY
ENTRY_HEAD=c92be04965f3ac805577c514a003ed81153bfd9d
FINAL_HEAD=the closure commit; query Git for the terminal SHA. This
  document is committed INSIDE that commit and therefore cannot state
  its own SHA (F-GIT-IDENTITY).
WORKTREE_STATUS=clean at closure, except for the authorized EVIDENCE and
  HANDOFF artefacts this commit carries.

ROOT CAUSE / FINDING

THE FINDING OF THIS ACT IS A FAIL-OPEN IN THE ROUTE GUARD, and it was
found by the plan-validity experiment rather than by inspection.

The C host's route guard was a pure numeric BOUND check:

    if (wp_route < 0 || wp_route >= WP_DRIVER_STEP_COUNT)

The host's route dispatch is a set of POSITIVE EQUALITY TESTS with an
IMPLICIT FALL-THROUGH to compile. So an EMPTY plan -- whose selected
route is WP_DRIVER_STEP_INVALID (0) -- PASSED the guard, because 0 is
INSIDE { 0 .. WP_DRIVER_STEP_COUNT-1 }. The driver had selected
NOTHING, and the compiler compiled anyway and produced an artifact.

THE MEASURED NEGATIVE CONTROL, with the real production compiler, the
real input file and the same poisoned subject, the guard being the ONLY
difference:

    empty plan, ORIGINAL guard  -> exit 0, case.out.o PRODUCED
    empty plan, REPAIRED guard  -> exit 1, no artifact

THE REPAIR HAS TWO HALVES, and BOTH are required:

    R1  the C guard rejects WP_DRIVER_STEP_INVALID (src/main.c:603), so
        route 0 is no longer inside the accepted domain; and
    R2  the PolyC driver selects the COMPILE route EXPLICITLY when no
        option route wins (WpDriverPlanBuild in
        tools/bootstrap/selfhost-driver-wp001.HC), so a LEGITIMATE argv
        never produces an empty plan.

R1 alone would break every ordinary compile, because the empty plan WAS
the ordinary compile. R2 alone would leave the fail-open in place for a
genuinely empty plan.

RED

THE PRINCIPAL RED, at the REAL production seam, with the real compiled
PolyC detector reading the REAL Mach-O symbol table of the REAL
production route object:

    $ ./build/wp001-takeover-red build/CMakeFiles/hcc.dir/main.c.o \
        WpDriverSelectedAction
    ACCESSOR name=WpDriverSelectedAction classification=NOT_CONSUMED
    WP001_DRIVER_TAKEOVER_RED=FIRED
    EXIT 1

The PolyC driver computed the whole-argv action and the production route
selection never called it, so the C branches in main() remained the real
authority over the assemble, repl, print-tokens, transpile, print-AST,
dump-IR, dump-IR-pooled, CFG, JIT and emit-LLVM routes.

At CLOSE, the same detector on the same kind of object:

    $ ./build/wp001-takeover-red <close production main.c object> \
        _WpDriverSelectedRoute _WpDriverPlanStatus _WpDriverSelectedEmission
    ACCESSOR name=_WpDriverSelectedRoute classification=IMPORTED
    ACCESSOR name=_WpDriverPlanStatus classification=IMPORTED
    ACCESSOR name=_WpDriverSelectedEmission classification=IMPORTED
    WP001_DRIVER_TAKEOVER_RED=NOT_FIRED
    EXIT 0

THE SECOND RED, the plan-validity experiment, is the fail-open above.
An earlier iteration of it was INVALID: the probe directory had no input
file, so the compiler failed with "Failed to open file" instead of
exercising the guard. That iteration was discarded and re-measured with
a real input file.

IMPLEMENTATION

THE POLYC SIDE (tools/bootstrap/selfhost-driver-wp001.HC)

The driver now owns the WHOLE-CLI route decision as a DriverPlan. The
plan is an ORDERED list of steps, because the live compiler's route was
a SEQUENCE of independent `if (args.<flag>)` statements in a fixed
order and the FIRST matching branch won.

The plan's step codes are DISJOINT from the action domain and from the
status domain, so an out-of-domain step can never be confused with a
valid one. The plan is rebuilt on demand and is deterministic for
identical argv.

The driver's priority table encodes the legacy chain's order EXACTLY:

    ASSEMBLE 10, REPL 20, PRINT_TOKENS 30, TRANSPILE 40, PRINT_AST 50,
    DUMP_IR 60, DUMP_IR_POOLED 70, EMIT_LLVM 80, JIT 90, CFG 100,
    COMPILE 200 (the default)

The C chain's order is ASSEMBLE, REPL, PRINT_TOKENS, TRANSPILE,
PRINT_AST, DUMP_IR, DUMP_IR_POOLED, EMIT_LLVM, JIT, CFG, COMPILE. The
two orders are IDENTICAL.

THE C SIDE (src/main.c)

The C host consumes the plan mechanically. Under the selector it does
NOT test any args.<flag> to decide a route; it tests the ONE route code
the driver selected:

    long long wp_route = WpDriverSelectedRoute();
    if (wp_route <= WP_DRIVER_STEP_INVALID ||
        wp_route >= WP_DRIVER_STEP_COUNT) {
        loggerPanic("hcc: the driver selected an invalid route (%lld)\n",
                wp_route);
        memoryRelease();
        return 1;
    }

and then a set of positive equality tests, one per route.

The selector-OFF build keeps the ORIGINAL C chain untouched, which is
what makes it an INDEPENDENT G0 ORACLE: it contains ZERO driver PolyC
symbols.

THE DEFECT THE DIFFERENTIAL CAUGHT

The first implementation mapped `-S` to the ASSEMBLE route. That is
WRONG: `-S` sets args.assemble_only, which selects the ARTIFACT CLASS,
and the live chain tested args.assemble, which is set by the FILE TYPE
of a `.s` input. Mapping `-S` to the assemble route made the compiler
assemble the .HC SOURCE file, which failed at link. The 30-case G0/G1
differential caught it; the driver now finds the assemble route by FILE
TYPE and no option selects it.

THE FINDING OF THE FOCUSED READ-ONLY REVIEW

The review found one inaccuracy in the new source scan:
`WpDriverFirstSourceArg` classified EVERY argument by file type, so an
option whose value is the NEXT argument could hand it a value that
happens to end in ".HC". For `hcc -c -o out.HC real.HC` the scan
recorded "out.HC" -- the `-o` option's VALUE -- instead of "real.HC".

THE IMPACT WAS NIL, and that is why review, not a failure, found it.
The production host does not READ the plan's argument index: it uses
the CliArgs fields, and the plan's argument is metadata. The case was
measured directly with both builds and the observable behaviour was
identical. The scan now consumes an option's value, exactly as the
live parser does and exactly as `WpDriverFirstArgForStep` already
did, so the plan is a truthful record for the first consumer that
does read it. The whole suite was re-measured after the repair:
parser 376/376 with the byte-identical MD5, lexers 89/89, 45/45 and
23/23, the 30-case differential with 0 disagreements, gate-fast PASS,
both fail-closed poisons still failing closed, and the bootstrap
subject still byte-identical.

THE FINAL OWNERSHIP TALLY, over all 44 sites of the re-measured
inventory:

    POLYC_OWNED    35
    C_MECHANICAL    8
    C_SEMANTIC      1

The single C_SEMANTIC row is the LEGACY C PARSER, which is retained
deliberately as the selector-OFF oracle. Seventeen sites carry the
TRANSFERRED group: the twelve C-side route sites that now consume the
driver's route code, the four PolyC-side sites that carry the
decision, and the C-side domain guard that turns an invalid route into
a fail-closed stop.

GATES

BUILD=PASS
TARGETED=PASS
UNIT=PASS
JIT=PASS
LSP=PASS
DIFF_CHECK=PASS

THE MEASUREMENTS, each on the post-IMPL tree:

    PARSER            376/376 over 90 blocks, 0 failed lines,
                      assertion-sequence MD5
                      b6f117eb1386ca80f81bc06226e2a741 == the ENTRY
                      baseline (BYTE-IDENTICAL)
    LEXER07           89/89, 0 fail
    LEXER08           45/45, 0 fail
    LEXER09           23/23, 0 fail
    G0/G1 DIFFERENTIAL 30 cases, 0 disagreements, DIFFERENTIAL=PASS
    WHOLE-COMPILER CENSUS  make census01-all: 19/19 selftest cases,
                      all four checks PASS, all 19 adverse controls
                      PASS
    GATE_FAST         VERDICT=PASS
    GATE_PUSH         VERDICT=PASS, exit 0
                      (CHECK=build/install/gep01/aot/jit/lsp/diff-check
                      all STATUS=PASS)
    BOOTSTRAP         the stage0 compiler compiles the PolyC driver
                      subject, and the result is BYTE-IDENTICAL to the
                      production subject:
                      76aa9fab02b0e8f0ae37b1abfd54b1fdafaf90ea043e6e787dd63d65833a1547
    MISSING SUBJECT   cmake -DDRIVER_WP001_OBJECT=<nonexistent> fails
                      with REJECT_MISSING_DRIVER_SUBJECT, exit 1. NO
                      silent fallback (F6).

THE CAUSAL AND DORMANCY MEASUREMENTS

    POLYC-SIDE MUTATION   changing the driver's compile push to
                          PRINT_AST changed G1: it printed the AST and
                          produced NO artifact. The PolyC driver really
                          owns the route.
    C-SIDE MUTATION       changing the selector-OFF C chain to
                          PRINT_AST changed G0: it printed the AST and
                          produced NO artifact. The C chain really is
                          the oracle.
    DORMANCY              the SAME C-side mutation left G1's artifact
                          BYTE-IDENTICAL to the unmutated G1's. The C
                          route chain is no longer authoritative under
                          the selector.
    RESTORATION           the unmutated G0 still compiles normally.

THE G0/G1 SAME-TREE REQUIREMENT

SCOPE
FILES_CHANGED=Makefile ;
  docs/acts/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.md ;
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.md ;
  docs/factory/act-handoff-map.tsv ;
  docs/ROADMAP.md ;
  evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01/c0/* ;
  evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01/c2/* ;
  evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01/c3/* ;
  src/cli.c ; src/main.c ; src/selfhost-driver-wp001.h ;
  tests/driver-wp001/takeover/cases.tsv ;
  tools/bootstrap/selfhost-driver-wp001.HC ;
  tools/quality/wp001-driver-takeover01-diff.HC ;
  tools/quality/wp001-driver-takeover01-red.HC
DIFF_CHECK=PASS (git diff --check over the ACT range, exit 0)
PRODUCTION_SEMANTICS_CHANGED=YES -- this IS the production semantic
  transfer: the whole-CLI route decision moved from C to the compiled
  PolyC driver. The change is the ACT's subject, and the conservation
  measurements above are the evidence that no unrelated behaviour moved.
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO

THE DRIVER SYMBOL COUNT IS ACCOUNTED FOR, not merely conserved. The
entry selector-ON binary carried 30 driver PolyC symbols; the close
binary carries 42. The 12 added names are exactly the takeover's own
machinery:

    _WpDriverEmitLlvmConflict, _WpDriverFirstArgForStep,
    _WpDriverFirstSourceArg, _WpDriverPlanActionAt,
    _WpDriverPlanActionCount, _WpDriverPlanArgAt, _WpDriverPlanBuild,
    _WpDriverPlanPush, _WpDriverPlanStatus, _WpDriverSelectedRoute,
    _WpDriverStepForKind, _WpDriverStepPriority

NO entry symbol was removed.

RESIDUE
P0=-
P1=-
P2=The ORDERED-PLAN SURFACE is exported but not consumed. The plan
    resolves the legacy chain's precedence to ONE winning step, so the
    plan always holds exactly one step, and the C host consumes the
    single selected route. The three exports
    (WpDriverPlanActionCount, WpDriverPlanActionAt, WpDriverPlanArgAt)
    are therefore declared, exported and NOT consumed by the production
    host. Sites S41-S43 of the final ownership inventory.

    This is a SURFACE residue, NOT a correctness defect: the precedence
    IS preserved, and the 30-case G0/G1 differential measures it. The
    exports could be removed, or the plan could be made genuinely
    multi-step, but NEITHER is required by this ACT and NEITHER is
    authorized by it.

    DISPOSITION=DEFERRED. It is recorded, not silently dropped (F11).

    The same class of residue was already recorded at entry: the
    whole-argv ACTION export is computed and not consumed. The ROUTE
    export supersedes it as the consumed surface.

NEXT_ACT=-

THE PREDECESSOR'S STATUS IS UNCHANGED BY THIS ACT.
ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 has a reported
independent C4_READY=YES and NO terminal CLOSE. This ACT does not
inherit a verdict CORRECTION03 never recorded, does not claim
CORRECTION03 was closed, and does not reopen the historical
governance-reconciliation project.

G0 and G1 MUST be built from the SAME working-tree state, because
--version embeds the build metadata. Three cases (D03, D12, D20)
disagreed against a G0 built from an earlier tree; the disagreement was
the commit hash in the --version output, a build-metadata difference
and not a semantic one. Rebuilt from the same tree, the differential is
30/30 AGREE. This is recorded rather than hidden.
