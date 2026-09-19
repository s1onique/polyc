HANDOFF for ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01

VERDICT

PASS_TRUE_GREEN

  The four P0 defects and the G-1 governance defect in the
  predecessor's lib-tos closure are repaired. The canonical
  archive is built fail-closed from a clean state. The five
  required runtime symbols are mechanically verified. The
  required semantic matrices are mechanically exercised by
  a PolyC-native test program. The N02 negative control is
  isolated to a single mutation. Phase ordering is honored
  (C0 AUTH precedes C1 RED).

IDENTITY

  ACT: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01
  Predecessor: ACT-POLYC-LIBTOS-SYMBOL-GAPS01 (REJECTED)

  Predecessor verdict (reclassified by this ACT):
    Original claim:        PASS_TRUE_GREEN
    Reviewer reclassification: FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT_LEVEL
    This ACT's verdict:    reclassified to PASS_FALSE_GREEN_HALTTED_AT_
                           REVIEWER_AUDIT_LEVEL (the substrate engineering
                           result is preserved; only the truth status
                           of the closure changes per F14)

  This ACT commit topology (5 commits, append-only):
    C0 AUTH:           1e04f94
    C1 RED/RECON:      cb0bd02
    C2 IMPL:           e4ec317
    C3 VERIFY:         5580f98
    C4 CLOSE:          <this commit>

  PATCH_HYGIENE_BASELINE   = 6e30e7f (binding predecessor HEAD)
  ENTRY_HEAD               = 6e30e7f66a5516ee1af5ca9e68f9828303fc54bc
  WORKTREE_STATUS_AT_CLOSE = clean

ROOT CAUSE / FINDING

  The predecessor ACT (ACT-POLYC-LIBTOS-SYMBOL-GAPS01) closed with
  PASS_TRUE_GREEN but reviewer audit identified four binding
  engineering defects and one governance defect:

    P0-1: make lib-tos is fail-open.
          Recipe: hcc ... || true && cc ... && ar ... && ranlib ... && cp ...
          A hcc invocation that produces no all.o is swallowed by
          `|| true`; the chain continues with cc -c errno_shim.c
          (always succeeds; errno_shim.c is standalone), then
          `ar r libtos.a errno_shim.o` produces a "libtos.a" with
          only errno_shim.o (1 T symbol: _Errno). The cp step
          fails because build/test-prefix/lib/ doesn't exist, so
          the failure is detected ONLY because of the test-prefix
          ordering, not because of any archive-content check.
          With a pre-existing test-prefix, the cp would succeed
          and a non-canonical archive would be shipped.

    P0-2: opportunistic bootstrap selection.
          LIBTOS_HCC := if ./build/hcc-bootstrap04 exists then
                          ./build/hcc-bootstrap04
                        else ./hcc
          The "else" branch is the known-broken ./hcc at HEAD
          (commit 6ba9f5ec) which regressed on ARM64 inline-asm
          mnemonics in src/holyc-lib/{memory,strings}.HC. The
          cmake install seam had the same opportunistic pattern.

    P0-3: N02 confounded.
          The predecessor's N02 produced a corrupted archive
          missing errno_shim.o entirely (because the harness
          re-ran `cc -c errno_shim.c` and `ar r libtos-corrupted.a
          errno_shim.o` without errno_shim.o in the working
          directory). The link failure cited both _SpawnAndCapture
          AND _Errno as undefined. The mutation cannot be
          attributed to symbol-hiding _SpawnAndCapture alone.

    P0-4: semantic matrices established by source inspection.
          The predecessor's c3-*-semantics.txt evidence argued
          from the assembly body of each function (CBZ x0,@@1 for
          NULL no-op; STRB loop for MEMSET; etc.) plus transitive
          Factory-test PASS. None of the required edge-case
          matrices (NULL no-op, allocated storage, equal/less/
          greater/prefix/empty, len=0/len=1/nonzero/0xff, etc.)
          were mechanically executed.

    G-1: governance defect (C0+C1 combined).
          The predecessor's commit 24b3921 was titled "C0 AUTH +
          C1 RED/RECON", explicitly combining two phases. The
          Factory rule requires C0 authorization to commit BEFORE
          C1 evidence is gathered.

  This ACT's repair preserves the predecessor's substrate
  engineering result (5 required symbols exported; archive-only
  consumer links; verifier executes) and makes the surrounding
  evidence and build seam honest.

RED

  Four RED witnesses, one per defect class, all reproduced against
  the predecessor's commit (HEAD = 6e30e7f) and captured in
  evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/c1/:

    RED-1 (P0-1, fail-open):
      With the build cache fully scrubbed (rm -rf build/test-prefix
      src/holyc-lib/libtos.a src/holyc-lib/all.o
      src/holyc-lib/errno_shim.o src/holyc-lib/libtos.dylib),
      `make lib-tos LIBTOS_HCC=/bin/false` invoked the recipe with
      a non-working hcc. The `|| true` swallowed the failure; cc
      and ar succeeded; libtos.a was emitted with ONLY errno_shim.o
      (1 T symbol). All 5 required symbols absent.
      See: c1/c1-red1-fail-open.txt

    RED-2 (P0-2, opportunistic bootstrap):
      With build/hcc-bootstrap04 absent, `make lib-tos` silently
      degraded to ./hcc (the broken ARM64 inline-asm regressor at
      commit 6ba9f5ec). No precondition error. The build proceeded
      to call the broken compiler; cp happened to fail only
      because test-prefix/lib/ didn't exist.
      See: c1/c1-red2-clean-checkout.txt

    RED-3 (P0-3, N02 confounded):
      Reproduced the predecessor's broken N02 procedure
      (errno_shim.o missing from corrupted archive). Then
      demonstrated the correct isolation procedure (extract
      pristine -> llvm-objcopy --localize-symbol=_SpawnAndCapture
      on all.o only -> ar rcs with original errno_shim.o -> link
      fails with ONLY _SpawnAndCapture undefined).
      See: c1/c1-red3-n02-confound.txt

    RED-4 (P0-4, semantic matrices):
      Catalogued the required edge-case matrices that the
      predecessor's evidence did not exercise. Demonstrated that
      the matrices can be mechanically executed (the substrate
      runtime supports them; just no test program existed).
      See: c1/c1-red4-semantic-matrices.txt

  Summary: evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/c1/c1-red-summary.tsv

IMPLEMENTATION

  Production mutations (4 files):

    Makefile (lib-tos target):
      Before (predecessor's fail-open):
        LIBTOS_HCC ?= $(shell if [ -x ./build/hcc-bootstrap04 ]; then
                           echo ./build/hcc-bootstrap04;
                         else echo ./hcc; fi)
        lib-tos:
            cd ./src/holyc-lib \
                && ../../$(LIBTOS_HCC) ... -lib tos ./all.HC || true \
                && cc ... errno_shim.c \
                && ar r ./libtos.a ./errno_shim.o \
                && ranlib ./libtos.a \
                && cp ./libtos.a $(TEST_PREFIX)/lib/libtos.a

      After (this ACT's fail-closed, provenance-strict):
        LIBTOS_HCC ?= ./build/hcc-bootstrap04   (NO opportunistic fallback)
        LIBTOS_REQUIRED_SYMBOLS := _FREE _STRNCMP _MEMSET _STRLEN_FAST _SpawnAndCapture
        lib-tos:
            (1) precondition: builder must be -x; exit 1 otherwise
            (2) mkdir -p test-prefix/lib test-prefix/include
            (3) install tos.HH header (prerequisite for hcc)
            (4) invoke hcc -lib tos all.HC (tolerate dylib-link
                failure ONLY because that is the canonical cmake
                contract when all.o is produced)
            (5) verify ./src/holyc-lib/all.o exists; exit 3 otherwise
            (6) cc -c errno_shim.c -> errno_shim.o
            (7) ar rcs libtos.a all.o errno_shim.o; ranlib
            (8) cp libtos.a to test-prefix/lib/
            (9) nm libtos.a | grep -q "T $sym$" for each required sym
                (fail with exit 2 if any missing)

    Makefile (runtime-contract-test target, new):
      PolyC-native edge-case matrix test. Compiles and links
      tools/quality/runtime-contract-test.HC archive-only,
      runs 21 cases, exits with FAIL count. Self-cleans binary.

    Makefile (.PHONY list):
      Added `lib-tos` and `runtime-contract-test`.

    src/CMakeLists.txt (HCC_PATH selection):
      Before: opportunistic; fell through to ${PREFIX}/bin/hcc.
      After:  FATAL_ERROR at configure time if
              build/hcc-bootstrap04 is absent. No silent fallback
              to the regressed ./hcc.

  New files (NOT mutating production source):

    scripts/quality/libtos-n02-harness.sh:
      8-step N02 harness. Extracts pristine members,
      llvm-objcopy --localize-symbol=_SpawnAndCapture on all.o,
      re-ar with original errno_shim.o, verifies all other T
      symbols preserved, compiles a minimal consumer that
      requires ONLY _SpawnAndCapture + Free + _Exit, links
      against the corrupted archive, verifies the link fails
      with ONLY _SpawnAndCapture undefined.

    tools/quality/runtime-contract-test.HC:
      PolyC-native test program (compiled with hcc-bootstrap04,
      linked archive-only against libtos.a). 21 cases:
        AC06 FREE:        NULL no-op, allocated storage
        AC07 STRNCMP:     equal, less, greater, prefix, empty
        AC08 MEMSET:      len=0, len=1, nonzero fill, 0x00 fill, 0xff fill
        AC09 STRLEN_FAST: empty, ASCII, NUL termination
        AC11 SAC:         success, nonzero exit, cmd-not-found,
                          empty output, stdout capture, stderr capture
      Uses macOS-correct paths (/usr/bin/true, /usr/bin/false,
      /bin/echo, /bin/sh). Uses StrNCmp for marker presence.

  NOT mutated (out of ACT scope per §2):
    - src/parser.c / src/aarch64.c (the ./hcc ARM64 inline-asm
      parser regression at commit 6ba9f5ec is upstream P1
      residue; recommended as ACT-POLYC-COMPILER-AARCH64-ASM-
      PARSER-FIX01).
    - src/holyc-lib/*.HC (definitions already correct).
    - The canonical archive itself (rebuilt from current source
      via the new fail-closed recipe; archive symbol set
      unchanged from predecessor: 313 T symbols, 5 required).

GATES

  C0/C1 RED/RECON complete:
    c0/c0-entry-identity.txt              PASS
    c1/c1-red1-fail-open.txt              PASS
    c1/c1-red2-clean-checkout.txt         PASS
    c1/c1-red3-n02-confound.txt           PASS
    c1/c1-red4-semantic-matrices.txt      PASS
    c1/c1-red-summary.tsv                 4/4 REDs reproduced

  C2 IMPL ran cleanly:
    Production mutation: 3 files (Makefile, src/CMakeLists.txt,
                            .PHONY list)
    New files: 2 (n02 harness, runtime-contract-test.HC)
    Total LOC delta: ~150 added, ~37 removed

  C3 VERIFY (this ACT's evidence tree):
    Fresh canonical archive:           PASS (157760 bytes, 313 T symbols)
    All 5 required symbols present:    PASS (each strong_definition_count=1)
    RED-1 (fail-open) closed:          PASS (c3-fail-closed.txt)
    RED-2 (clean-checkout) closed:     PASS (c3-clean-checkout.txt)
    RED-3 (N02 confounded) closed:     PASS (c3-n02-isolated.txt)
    RED-4 (semantic matrices) closed:  PASS (c3-semantic-matrices.txt)
    AC06..AC11 semantic matrices:      21 PASS / 0 FAIL
                                       (c3-semantic-matrices.txt)
    N02 isolated negative control:     PASS (only _SpawnAndCapture hidden;
                                              link fails with only
                                              _SpawnAndCapture undefined)
    make gate-fast:                    PASS
                                       (diff-check, shell-syntax,
                                        doc-invariants, large-file-guard,
                                        factory-closure-status PAIR_OK=14)
    factory-append-only-test:          PASS=11 FAIL=0
    factory-no-python-check:           PASS (no python in tree)
    LEXER conservation:                PASS (no LEXER-related files mutated)
    F14 conservation:                  PASS (no closed-evidence surface
                                              mutated)
    Patch hygiene:                     git diff --check 6e30e7f HEAD -> RC=0

  Mandatory AC ledger (evidence/.../c3/mandatory-ac-status.tsv):
    22 PASS, 0 FAIL, 0 UNKNOWN, 0 MISSING

SCOPE

  Production mutations:
    Makefile:           ~150 LOC added, ~37 LOC removed
                        (lib-tos fail-closed rewrite;
                         runtime-contract-test target;
                         .PHONY list)
    src/CMakeLists.txt:  ~14 LOC added, ~9 LOC removed
                        (HCC_PATH provenance-strict)

  New non-production files:
    scripts/quality/libtos-n02-harness.sh       (262 LOC, test harness)
    tools/quality/runtime-contract-test.HC      (~280 LOC, PolyC test)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/{c0,c1,c3}/ (full)
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01.md

  Total tracked-file delta (C2 only):
    ~150 lines added, ~37 lines removed (production)
    ~542 lines added (non-production: harness + test + C3 evidence)

  Residue (NOT in scope, documented per F11):

    P1 - hcc ARM64 inline-asm parser regression at commit 6ba9f5ec.
         This ACT's repair routes the libtos build around the
         regression via the bootstrap chain; the regression
         itself remains. Recommended bounded ACT:
         ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01.

    P1 - tools/quality/runtime01-selftest.HC duplicates archive
         symbols (#includes tooling.HC directly). Out of scope
         per upstream ACT-POLYC-TOOLING-RUNTIME01-CORRECTION03.

    P2 - PolyC verifier's SpawnAndCapture invocation uses a
         relative path. Out of scope.

  Closed-evidence surfaces (F14):
    evidence/ACT-POLYC-STATIC-FUNCTION-LINKAGE01/**           (untouched)
    evidence/ACT-POLYC-STATIC-FUNCTION-LINKAGE01-CORRECTION01/** (untouched)
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/**(untouched)
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION0*/**(untouched)
    evidence/ACT-POLYC-SELFHOST-LEXER*/**                     (untouched)
    evidence/ACT-POLYC-SELFHOST-LEXER04-CORRECTION01/**       (untouched)
    docs/factory/HANDOFF-ACT-POLYC-STATIC-FUNCTION-LINKAGE01*.md (untouched)
    docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01*.md (untouched)
    docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER0*.md        (untouched)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01/**                (untouched;
                                                             predecessor evidence
                                                             preserved per F14)
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01.md    (untouched;
                                                             reclassified to
                                                             FALSE_GREEN_HALTTED
                                                             _AT_REVIEWER_AUDIT)

    CLOSED_EVIDENCE_DELTA = 0
    CLOSED_HANDOFF_DELTA  = 0

  Append-only history:
    factory-append-only-test: PASS=11 FAIL=0 (NC1..NC11)
    No amend, rebase, force-push, reset, filter-branch, git replace
    since C0 entry. 5 commits added (C0, C1, C2, C3, C4), all linear
    descendants of 6e30e7f.

NEXT ACT

  ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 (immediate successor)

    Mission: produce the G0/G1/G2/G3 production semantic seam
    proof previously blocked by the libtos substrate gap, plus
    the PolyC-native verifier substrate (factoring out the C
    verifier and the C SHA-256 tool under F-POLYC-TOOLS), plus
    the authorized AC contract replay (AC01..AC32 per CORRECTION01
    §31). Closes the LEXER04 correction lineage.

    Why this ACT is now ready: the libtos substrate is now
    proven canonical, fail-closed, and provenance-strict. The
    PolyC verifier (tools/quality/lexer08-fixedpoint-verify.HC)
    already links archive-only via the new libtos; the LEXER
    fixed-point test was demonstrated GREEN by the predecessor
    and is preserved unchanged here.

  ACT-POLYC-SELFHOST-SURFACE-RECON03 (sequenced after CORRECTION02)

    Mission: select the next production migration mechanically,
    after LEXER04 CORRECTION02 closes TRUE_GREEN.

  Recommended upstream repair ACT (P1 residue):

  ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01

    Mission: repair the hcc ARM64 inline-asm parser regression
    at commit 6ba9f5ec so `./hcc` (rather than the bootstrap
    chain) can build src/holyc-lib/{memory,strings}.HC. The
    bootstrap hcc at commit ffee58b (build/hcc-bootstrap04) DOES
    parse these mnemonics correctly, so the parser regression
    is precisely localized to the diff between ffee58b and
    6ba9f5ec.

    Mechanically proven reproduction:
      ./build/hcc-bootstrap04 -c src/holyc-lib/memory.HC   # OK
      ./hcc                  -c src/holyc-lib/memory.HC   # FAILS:
        error: src/holyc-lib/memory.HC:146: error:
            asm: unexpected token at start of line
                (LDP X29, X30, [SP], 16)

    Out of scope for THIS ACT (per §2: src/parser.c, src/aarch64.c
    mutation requires HALT_COMPILER_SCOPE_EXPANSION). Recommend
    opening as a dedicated bounded ACT after LEXER04 CORRECTION02
    closes.

APPEND-ONLY NOTE

  Per ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19, PolyC
  authoritative Git history is append-only from
  baf5dbd77cf89330699685dffd932c54031c815c forward. This ACT's
  five commits (1e04f94, cb0bd02, e4ec317, 5580f98, <C4>) are
  linear descendants of 6e30e7f, which is itself an ancestor
  of the append-only point. The append-only invariant is
  preserved.

  The predecessor's HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01.md
  remains in the tree per F14 and is reclassified by this
  ACT's verdict and this HANDOFF to FALSE_GREEN_HALTTED_AT_
  REVIEWER_AUDIT_LEVEL. Its substrate engineering result
  (5 required symbols exported, archive-only consumer link,
  verifier execution, all.s fallback removed) is preserved;
  only the truth status of the closure changes.
