# HANDOFF-ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01

ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01

VERDICT

PASS_WITH_RESIDUE

Both externally-reviewed defects in the closed WP-001 driver takeover were
confirmed by measurement and repaired: the differential runner's Mach-O
filetype mapping now matches Apple's own definitions and the dylib route
is genuinely observed, and the PolyC driver's emit-LLVM conflict
predicate now honours the legacy C oracle's outer `--emit-llvm` guard.
Neither finding touched the WP-001 route migration itself. The only open
items are two P2 residues: the predecessor's ordered-plan surface, and a
pre-existing legacy-C lexer end-of-file overread that is invisible in the
canonical Release build.

IDENTITY
ENTRY_HEAD=16a7fc93ab36de713d090b2b97b7454247ea1157
FINAL_HEAD=the closure commit; query Git for the terminal SHA. This
  document is committed INSIDE that commit and therefore cannot state
  its own SHA (F-GIT-IDENTITY).
WORKTREE_STATUS=clean at closure, except for the authorized EVIDENCE and
  HANDOFF artefacts this commit carries.

ROOT CAUSE / FINDING

TWO FINDINGS, BOTH CONFIRMED BY MEASUREMENT, BOTH REPAIRED.

FINDING 1 -- THE MACHO FILETYPE MAPPING WAS WRONG.

The differential runner's classifier mapped the Mach-O filetypes as:

    if (ft == 1) return CLASS_OBJECT;   // labelled MH_OBJECT
    if (ft == 6) return CLASS_EXEC;     // labelled MH_EXECUTE
    if (ft == 2) return CLASS_EXEC;     // labelled MH_EXECUTE
    if (ft == 8) return CLASS_DYLIB;    // labelled MH_DYLIB

APPLE'S ACTUAL VALUES, from the LOCAL SDK's own loader.h:

    /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/
      mach-o/loader.h

    #define MH_OBJECT   0x1   relocatable object file
    #define MH_EXECUTE  0x2   demand paged executable file
    #define MH_DYLIB    0x6   dynamically bound shared library
    #define MH_BUNDLE   0x8   dynamically bound bundle file

So the mapping read MH_DYLIB (6) as an EXECUTABLE and MH_BUNDLE (8) as a
DYLIB. The labels in the source were wrong too: the comment on the
`ft == 6` line said MH_EXECUTE, and 6 is not MH_EXECUTE.

THE MEASUREMENT WAS DIRECT, against the REAL artifacts the production
compiler produced. The filetype byte at offset 12 was read from the
files themselves:

    executable   -> 02 00 00 00   (MH_EXECUTE) -> the OLD mapping said EXEC (correct)
    dylib        -> 06 00 00 00   (MH_DYLIB)   -> the OLD mapping said EXEC (WRONG)

    $ file libcase.out.dylib
    libcase.out.dylib: Mach-O 64-bit dynamically linked shared library arm64

THE COMPOUNDING GAP: THE DYLIB ROUTE WAS NOT COVERED AT ALL.

The frozen case table's D14 row was:

    D14_dylib  %P -lib libtos.dylib input.HC -o case.out.o  0

with expected class NONE (0). The dylib route writes lib<name>.dylib
and does NOT write case.out.o, so the runner read NONE and the
expectation matched: the case verified NOTHING. And even if the runner
HAD looked at the dylib, the wrong mapping would have reported it as an
EXECUTABLE.


FINDING 2 -- THE EMIT-LLVM CONFLICT PREDICATE WAS TOO BROAD.

The legacy C oracle tested the mutual-exclusion condition INSIDE an
`if (args.emit_llvm)` guard:

    if (args.emit_llvm) {
      if (args.jit || args.repl || args.run || args.assemble_only ||
          args.emit_object || args.emit_dylib || args.transpile ||
          args.lsp)
      { ...conflict... }
    }

The OUTER guard is part of the condition: a conflicting option WITHOUT
an --emit-llvm request is NOT a conflict, because there is no LLVM
request to be exclusive with.

The PolyC driver flattened that nesting and DROPPED the outer guard, so
it returned 1 on seeing any of the conflicting options, whether or not
--emit-llvm was requested.

THE MEASUREMENT, with a probe against the REAL production driver
subject, calling the REAL exported predicate on the REAL argv shapes:

    shape                  legacy C oracle   PolyC driver   verdict
    plain -c                    0                 1           DIVERGENT
    plain -S                    0                 1           DIVERGENT
    plain -transpile            0                 1           DIVERGENT
    plain -lsp                  0                 1           DIVERGENT
    plain -lib                  0                 1           DIVERGENT
    --emit-llvm alone           0                 0           agrees
    --emit-llvm + -c            1                 1           agrees
    --emit-llvm + -S            1                 1           agrees
    --emit-llvm + -jit          1                 1           agrees
    --emit-llvm + -repl         1                 1           agrees
    --emit-llvm + -transpile    1                 1           agrees
    --emit-llvm + -lsp          1                 1           agrees

The observable COMPILER behaviour was masked: the host renders the
conflict diagnostic only on the LLVM route, and the status is consulted
only when the action's own status is OK. The EXPORTED status was
nevertheless wrong, and it is the PolyC driver's published semantic
authority.

RED

THE PRINCIPAL RED IS A COMPILED POLYC PROGRAM:
`tools/quality/wp001-driver-takeover01-conflict-red.HC`.

It is a REAL-SEAM witness. It links against the REAL production driver
subject, calls the REAL exported `WpDriverEmitLlvmConflict()` on the REAL
argv shapes, and compares the driver's answer against the legacy C
oracle's transcribed answer. The oracle's own answer is checked against
the case table, so the table and the transcription cannot drift apart
unnoticed. It never reads a verdict string.

BEFORE THE REPAIR (the guard removed from the subject):

    CONFLICT_MISMATCH shape=plain_c         want=0 got=1
    CONFLICT_MISMATCH shape=plain_S         want=0 got=1
    CONFLICT_MISMATCH shape=plain_transpile want=0 got=1
    CONFLICT_MISMATCH shape=plain_lsp       want=0 got=1
    CONFLICT_MISMATCH shape=plain_lib       want=0 got=1
    WP001_EMIT_LLVM_CONFLICT_RED=FIRED
    EXIT 1

AFTER THE REPAIR:

    WP001_EMIT_LLVM_CONFLICT_RED=NOT_FIRED
    EXIT 0

THE RED FOR FINDING 1 IS THE FROZEN D14 ROW ITSELF. Before the repair it
expected class NONE while observing a file the dylib route does not
write, so the case was vacuous. After the repair it expects DYLIB and the
runner observes libcase.out.dylib, the file the route actually writes.


IMPLEMENTATION

F1 -- the differential runner:

  * the filetype mapping becomes Apple's values:
      1 -> OBJECT, 2 -> EXEC, 6 -> DYLIB, 8 -> DYLIB;
  * the runner observes the dynamic library FIRST, because the dylib route
    does not write the object;
  * the content digest is taken from whichever artifact the class was
    read from, so a dylib is compared by its bytes;
  * the dylib is removed between runs, with the trailing space the `rm`
    command needs.

  The runner's shared name buffer is resized: a `dylib_name` region and a
  `slash_dylib` region are added, and every subsequent offset and
  NB_TOTAL are recomputed. Every region's capacity was checked against
  the bytes written into it; no region overflows.

F2 -- the production predicate `WpDriverEmitLlvmConflict()` now FIRST
establishes that --emit-llvm was requested, and only then looks for a
conflicting option. The legacy nesting is restored; nothing else about
the predicate changed.

THE THREE ADDITIONAL TEST-INFRASTRUCTURE DEFECTS found while making F1
work were each real, and each was repaired:

  D1  the `NB_SLASH_ASM` region had NO TRAILING SPACE. Every other slash
      region ends with a space (32) before its NUL; this one ended with
      the NUL directly, so the `rm` command concatenated the next path
      onto it:

          rm -f .../case.out.s/tmp/.../g0/libcase.out.dylib

      The dylib was therefore NEVER removed, and every case after the
      dylib case observed a stale DYLIB. This was a PRE-EXISTING latent
      defect, harmless while no case produced a dylib.

  D2  `NB_TOTAL` was ONE BYTE SHORT, so the array's last byte was the
      next buffer's first byte.

  D3  a LONG run of byte-writes into a static array is MISCOMPILED by
      this compiler. A 19-write run placed its last two bytes at the
      wrong offsets and the path became "libcase.out.dylb", while the
      13-byte region beside it was correct. The write is now split into
      short runs, and the runtime bytes were re-measured to confirm the
      placement.

GATES

All measurements are on the repaired tree, with G0 and G1 built from the
SAME working-tree state and with the canonical Release build type.

    CONFLICT RED       WP001_EMIT_LLVM_CONFLICT_RED=NOT_FIRED ; EXIT 0
    G0/G1 DIFFERENTIAL CASES=30 ; DISAGREE=0 ; DIFFERENTIAL=PASS
                        D14_dylib        G0=0/DYLIB  G1=0/DYLIB  AGREE
                        D02_executable   G0=0/EXEC   G1=0/EXEC   AGREE
    GATE_FAST          VERDICT=PASS
    GATE_PUSH          PASS

SCOPE

FILES_CHANGED=Makefile ;
  docs/ROADMAP.md ;
  docs/acts/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01.md ;
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01.md ;
  docs/factory/act-handoff-map.tsv ;
  evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01/** ;
  tests/driver-wp001/takeover/cases.tsv ;
  tools/bootstrap/selfhost-driver-wp001.HC ;
  tools/quality/wp001-driver-takeover01-conflict-red.HC ;
  tools/quality/wp001-driver-takeover01-diff.HC
DIFF_CHECK=PASS (git diff --check over the ACT range, exit 0)
PRODUCTION_SEMANTICS_CHANGED=YES -- scoped to exactly one predicate:
  `WpDriverEmitLlvmConflict()`. The repair RESTORES the legacy C
  oracle's nesting; it does not introduce a new semantic. The WP-001
  route migration itself is untouched.
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO

THE PREDECESSOR'S ARTEFACTS ARE UNTOUCHED. The predecessor's HANDOFF,
its ACT document, and its evidence directories are immutable history
(F14) and were not modified. This ACT's evidence lives in its own
directory and this ACT's HANDOFF is its own document.

RESIDUE
P0=-
P1=-
P2=TWO RESIDUES, BOTH DEFERRED AND BOTH RECORDED (F11).

  R1  THE PREDECESSOR'S ORDERED-PLAN SURFACE. Three exports
      (WpDriverPlanActionCount, WpDriverPlanActionAt, WpDriverPlanArgAt)
      are exported but not consumed by the production host. This is a
      SURFACE residue, NOT a correctness defect: the precedence IS
      preserved and the 30-case differential measures it. Inherited from
      the predecessor; unchanged by this ACT.

  R2  A PRE-EXISTING LEGACY-C LEXER END-OF-FILE OVERREAD. Found while
      re-measuring, under a DEBUG (AddressSanitizer) build:

          ERROR: AddressSanitizer: heap-buffer-overflow
            #0 lexNextChar+0x188
            #1 lexCore
            #2 lex
            #3 lexToken

      It is PRE-EXISTING and NOT caused by either repair: it was measured
      by stashing EVERY change of this repair sequence and rebuilding the
      PRISTINE close tree (16a7fc93), which reproduces the identical
      abort at the identical frame.

      It is NOT OBSERVABLE IN THE CANONICAL BUILD. The repository's
      canonical build type is Release (Makefile: BUILD_TYPE ?= Release),
      and the Release build does not abort: the D25 case exits 0 in BOTH
      generations and the differential is 30/30 AGREE.

      Its repair is OUTSIDE this ACT's authorized scope: this ACT's
      subject is the WP-001 driver route authority and the reviewed
      predicate, and the legacy C lexer is retained deliberately as the
      selector-OFF oracle. It is recorded, not silently fixed, and not
      silently dropped.

NEXT ACT

NONE REQUIRED. The two reviewed findings are repaired and the open items
are P2 surface residues, which are recorded rather than acted upon.
