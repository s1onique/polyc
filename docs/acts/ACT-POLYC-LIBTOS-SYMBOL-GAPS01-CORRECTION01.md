# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair four binding defects in the LIBTOS-SYMBOL-GAPS01
closure (fail-open build seam, opportunistic bootstrap, confounded
N02 negative control, source-inspection semantic ACs) so that
PASS_TRUE_GREEN is honest.

**Repository:** PolyC
**Branch:** `main`

**Class:** IMPLEMENTATION / FACTORY / CORRECTION

**Predecessor:** ACT-POLYC-LIBTOS-SYMBOL-GAPS01 (committed lineage;
REJECT verdict per reviewer audit)

**Production semantic changes:** AUTHORIZED (scoped — Makefile +
src/CMakeLists.txt + tests/HC; no src/parser.c / src/aarch64.c
mutation; no compiler semantics change)

**IR / ABI / LLVM authorization:** NONE

---

## 0. Predecessor verdict and falsification

ACT-POLYC-LIBTOS-SYMBOL-GAPS01 was closed PASS_TRUE_GREEN at HEAD
5cbda9bd306d00c411e923399ac49e92a920a6d1. Reviewer audit falsified
that verdict across four binding defects and one governance defect:

  P0-1   `make lib-tos` is fail-open.
         Recipe chain:
           hcc ... -lib tos ./all.HC || true
           && cc ... errno_shim.o
           && ar r ./libtos.a ./errno_shim.o
         fails closed if hcc produces no libtos.a, because
         `|| true` swallows the nonzero exit and the chain
         continues with a missing archive. The errno_shim.o
         step then rebuilds an archive from whatever (or
         nothing) was emitted. CANONICAL_BUILD_FAIL_CLOSED=FAIL.

  P0-2   The "canonical fresh build" depends on an opportunistic
         pre-existing build artifact. The builder selection:
           if [ -x ./build/hcc-bootstrap04 ]; then echo ...; else echo ./hcc; fi
         prefers a build output that is not part of this ACT's
         committed tree. A fresh checkout without the bootstrap
         chain takes the known-broken `./hcc` branch (the
         ARM64 inline-asm regression at commit 6ba9f5ec) and
         per P0-1 silently masks the failure.
         CLEAN_CHECKOUT_BUILDABILITY=NOT_PROVEN.

  P0-3   N02 negative control is confounded. The corrupted
         archive was built by `ar r libtos-corrupted.a errno_shim.o`,
         which itself failed because errno_shim.o was not in the
         working directory:
           ar: errno_shim.o: No such file or directory
         The binary was missing both _SpawnAndCapture AND _Errno,
         so the link failure cannot be attributed to the symbol-
         hiding mutation alone. N02=NOT_LOAD_BEARING; AC23=NOT_PROVEN.

  P0-4   Semantic ACs for FREE / STRNCMP / MEMSET / STRLEN_FAST /
         SpawnAndCapture were established by source inspection +
         transitive Factory-test success, not by the required
         edge-case matrices. Required matrices:
           FREE:                FREE_NULL_NOOP, FREE_ALLOCATED_STORAGE
           STRNCMP:             equal, less, greater, prefix, empty
           MEMSET:              len=0, len=1, nonzero fill, 0xff fill
           STRLEN_FAST:         empty, ASCII, UTF-8 boundary, NUL
           SpawnAndCapture:     success, nonzero exit, stdout,
                                stderr, empty output, cmd-not-found
         AC13/14/15/16/18=PARTIAL.

  G-1    Governance defect: C0 and C1 were combined into a
         single commit (24b3921), explicitly acknowledged in
         the HANDOFF. The Factory rule requires C0 authorization
         to commit BEFORE C1 evidence is gathered. This ACT
         MUST commit C0 separately from C1.

Falsification is recorded as historical evidence under
`evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/c0/`. The
prior HANDOFF (PASS_TRUE_GREEN) remains as a historical document
(F14) and is reclassified by this ACT to FALSE_GREEN_HALTTED_AT_
REVIEWER_AUDIT_LEVEL. The substrate repair (rebuilt archive,
archive-only verifier link, removed all.s fallback) IS preserved;
only the truth status of the closure changes.

## 1. Mission

Repair the four P0 defects and the G-1 governance defect so that
`make lib-tos` is fail-closed from a clean checkout, the
negative controls are properly isolated, the required semantic
matrices are mechanically exercised, and the closure phase
ordering is honored. The substrate claim — "the canonical
archive exports all five required symbols and a PolyC verifier
links + executes against it alone" — is preserved and remains
GREEN; what changes is the honesty of the surrounding evidence.

## 2. Scope

### allowed

- `Makefile` lib-tos target reconstruction (fail-closed).
- `Makefile` factory-closure-status-test-binary target
  (preserved from predecessor; no further change).
- `src/CMakeLists.txt` install seam: explicit hcc producer
  contract via `HCC_PRODUCER_ID` and `HCC_PRODUCER_REQUIRED`
  env vars, not opportunistic filesystem fallback.
- `tools/quality/lexer08-fixedpoint-verify.HC` (consumer;
  unchanged in semantics; used as the archive-only linker
  witness).
- `tools/quality/runtime01-selftest.HC` (out-of-scope residue;
  NOT modified here).
- `evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/{c0,c1,c2,c3,c4}/`
  full evidence tree (new directory; F14 forbids appending to
  the prior ACT's evidence tree).
- `docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01.md`
  closure handoff.
- New `tools/quality/runtime-contract-test.HC` PolyC-native
  test program that mechanically exercises the required edge-
  case matrices for FREE / STRNCMP / MEMSET / STRLEN_FAST /
  SpawnAndCapture. Links archive-only against `libtos.a`.

### forbidden

- Mutation of `src/parser.c` or `src/aarch64.c` (out of ACT
  scope; the `./hcc` ARM64 inline-asm parser regression is
  upstream residue tracked at P1 in the predecessor's HANDOFF
  and remains so).
- Mutation of `src/holyc-lib/*.HC` (definitions already
  correct).
- Changes to the canonical archive's emitted symbol set
  (313 T symbols at this ACT's entry is the frozen baseline;
  only archive member composition changes, not symbol set).
- Network or dependency additions.
- CI / framework / container changes.
- Re-classification of the prior HANDOFF (F14; the prior
  HANDOFF remains as historical evidence of an overclaim; the
  correction is recorded here, not there).

## 3. Entry gate

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Required state at C0 entry:

- on main;
- worktree clean (or only the new C0 ACT document and entry
  identity file untracked → tracked in the C0 commit);
- entry HEAD recorded.

Predecessor HEAD: 5cbda9bd306d00c411e923399ac49e92a920a6d1

## 4. Principal RED (C1)

Four independent RED witnesses, one per defect class:

  RED-1 (fail-open build seam):
    rm -f build/test-prefix/lib/libtos.a
    cp /dev/null /tmp/empty.HC
    ./build/hcc-bootstrap04 --install-dir=./build/test-prefix \
       -lib tos /tmp/empty.HC 2>/dev/null || true   # simulate
                                                     # hcc failure
    make lib-tos LIBTOS_HCC=/bin/false
    Expected AFTER: make exits nonzero OR target is reported
    "not remade" with no archive written.
    Actual BEFORE this ACT: make exits 0 and writes a
    not-quite-complete archive.

  RED-2 (clean-checkout buildability):
    rm -rf build/hcc-bootstrap04
    make lib-tos
    Expected AFTER: explicit failure or explicit "requires
    hcc-bootstrap04 to be built first" precondition error.
    Actual BEFORE this ACT: make exits 0 (per P0-1) and
    writes a non-canonical archive (per P0-2).

  RED-3 (N02 confounding):
    Re-run N02 in isolation. Inspect the corrupted archive
    contents. Expected: corrupted archive has all members of
    pristine archive EXCEPT the symbol-hiding mutation;
    link fails solely with the hidden symbol missing.
    Actual BEFORE this ACT: corrupted archive is missing
    errno_shim.o entirely.

  RED-4 (semantic matrices):
    Compile and run a PolyC test that exercises:
      Free(NULL);                       // expect no crash
      Free(p) where p was malloc'd;    // expect libc free path
      StrNCmp("abc", "abc", 3) == 0;
      StrNCmp("abc", "abd", 3) < 0;
      StrNCmp("abd", "abc", 3) > 0;
      MemSet(NULL, 0, 0) == NULL;
      MemSet(buf, 0xff, 16);            // check each byte
      StrLenFast("") == 0;
      SpawnAndCapture(SHA256_BIN, ...); // success
      SpawnAndCapture(NONEXISTENT, ...);// expect 127
    Expected AFTER: each case returns the documented value
    and exits 0.
    Actual BEFORE this ACT: no such test exists; ACs were
    argued from source + transitive Factory test PASS.

RED witnesses live under `c1/` after the C1 commit.

## 5. Implementation boundary (C2)

Minimum production change required:

  C2-1: Replace the opportunistic `LIBTOS_HCC` selection with
        a strict provenance contract. Either:
          (a) `make lib-tos` is invoked with `HCC=` set on
              the command line to a known-good producer; OR
          (b) the Makefile fails with a precondition error
              unless `build/hcc-bootstrap04` exists AND its
              recorded commit SHA matches the frozen
              `HCC_BOOTSTRAP_PROVENANCE_SHA` (set by this
              ACT at C0 from `./build/hcc-bootstrap04`'s
              actual commit). No `|| true`. No filesystem
              cache as silent fallback.

  C2-2: Split the `lib-tos` recipe into an archive phase
        (must succeed) and a dylib phase (may legitimately
        fail and is tolerated, but only after the archive
        phase has demonstrably produced a fresh
        `libtos.a` containing the expected producer's
        `__producer_id` note in `__.SYMDEF`).

  C2-3: Add a PolyC-native runtime contract test
        (`tools/quality/runtime-contract-test.HC`) that
        exercises the FREE / STRNCMP / MEMSET / STRLEN_FAST /
        SpawnAndCapture edge-case matrices. Compiles with
        the canonical archive. Executed as a Makefile
        target `runtime-contract-test` whose exit code
        becomes the AC13..AC18 evidence.

  C2-4: Rewrite the N02 harness so the corrupted archive is
        produced from the pristine archive by atomically:
          (1) extract pristine archive members;
          (2) use llvm-objcopy on all.o to localize
              `_SpawnAndCapture` (T -> t);
          (3) re-`ar r` with the modified all.o AND the
              original errno_shim.o AND the original
              __.SYMDEF; do NOT re-run `cc -c errno_shim.c`
              (errno_shim.o already exists in the working
              directory from C2-1's recipe).

NOT included:

  - No mutation of `./hcc` itself. The ./hcc ARM64
    inline-asm parser regression remains a separate P1
    residue.
  - No new dependencies.
  - No LLVM IR / ABI / language semantic change.
  - No new tools beyond runtime-contract-test.HC.

## 6. Acceptance criteria

Each AC MUST be checkable by a single concrete command.

  AC01: `git rev-parse HEAD` recorded in `c0/c0-entry-identity.txt`.
        PASS iff file exists, contains `HEAD=...`, and matches
        `git rev-parse HEAD` at C1 entry.

  AC02: `make lib-tos` is fail-closed.
        PASS iff, with the build cache scrubbed, a
        `make lib-tos HCC=/bin/false` invocation exits
        nonzero and does not write
        `build/test-prefix/lib/libtos.a`.

  AC03: `make lib-tos` is provenance-strict.
        PASS iff, with `build/hcc-bootstrap04` removed,
        `make lib-tos` exits nonzero with a precondition
        error message that names `HCC_BOOTSTRAP_PROVENANCE_SHA`.

  AC04: Pristine archive has the expected producer identity.
        PASS iff `ar t build/test-prefix/lib/libtos.a` lists
        `__.SYMDEF` and the producer identity note under
        `__.SYMDEF` matches the bootstrap hcc commit.

  AC05: AC13..AC18 semantic matrices are mechanically
        exercised by `make runtime-contract-test`, which
        compiles + runs `tools/quality/runtime-contract-test.HC`
        against the canonical archive.

  AC06: AC13 FREE semantics.
        PASS iff `Free(NULL)` is a no-op AND `Free(p)` for
        malloc'd `p` returns storage to libc.

  AC07: AC14 STRNCMP semantics.
        PASS iff the equal / less / greater / prefix / empty
        case matrix matches C semantics.

  AC08: AC15 MEMSET semantics.
        PASS iff length=0 is no-op, length=1 writes one byte,
        nonzero fill and 0xff fill write the expected byte
        at every position.

  AC09: AC16 STRLEN_FAST semantics.
        PASS iff empty string returns 0; ASCII string returns
        byte length; UTF-8 continuation bytes do not overcount.

  AC10: AC17 SpawnAndCapture ABI frozen.
        PASS iff c1-spawn-and-capture-contract.txt is byte-
        identical to the predecessor's c1/ copy (no
        silent redefinition).

  AC11: AC18 SpawnAndCapture semantics.
        PASS iff success returns 0, command-not-found returns
        127, nonzero exit returns the nonzero value, stdout
        is captured, stderr is captured separately.

  AC12: N02 negative control isolated.
        PASS iff the corrupted archive contains all members
        of the pristine archive AND only `_SpawnAndCapture`
        is hidden, AND the link fails solely with
        `_SpawnAndCapture` undefined.

  AC13: Archive-only consumer link still works.
        PASS iff `cc build/runtime-contract-test.o
        -L./build/test-prefix/lib -ltos -lpthread -lc -lm`
        exits 0 with no undefined symbols.

  AC14: LEXER conservation preserved.
        PASS iff `make lexer08-fixedpoint-verify` and
        `make lexer09-fixedpoint-verify` still PASS.

  AC15: Factory gates green.
        PASS iff `make gate-fast` exits 0 with
        `factory-closure-status-test PASS>=14` and
        `factory-append-only-test PASS=11 FAIL=0`.

  AC16: Patch hygiene.
        PASS iff `git diff --check 5cbda9b HEAD` exits 0.

  AC17: F-NO-PYTHON preserved.
        PASS iff `tools/factory/factory-no-python-check.HC`
        (or its sh wrapper) still passes.

  AC18: F-POLYC-TOOLS preserved.
        PASS iff no new non-PolyC tooling was added (the
        only new tool, runtime-contract-test.HC, is PolyC).

  AC19: F14 closed-evidence surfaces untouched.
        PASS iff the predecessor's evidence tree
        (evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01/**) and
        HANDOFF are byte-identical to their C3 closure
        state.

  AC20: Worktree clean at C4.
        PASS iff `git status --short` is empty.

  AC21: Append-only history.
        PASS iff `factory-append-only-test` returns
        `PASS=11 FAIL=0`.

  AC22: Commit topology honors C0-before-C1.
        PASS iff the commit log shows:
            C0: ACT document + entry identity
            C1: RED witnesses
            C2: implementation
            C3: verification + evidence
            C4: closure handoff
        as 5 separate commits in that order (no C0+C1
        combination).

Mandatory AC ledger SHALL report PASS/FAIL/UNKNOWN/MISSING for
each of AC01..AC22.

## 7. Conservation gates

The following predecessor gates MUST remain PASS:

  - `make lexer08-fixedpoint-verify`
  - `make lexer09-fixedpoint-verify`
  - `make factory-closure-status-test-binary`
  - `scripts/quality/factory-closure-status-check.sh`
  - `scripts/quality/factory-append-only-test.sh`
  - `make gate-fast`
  - `tools/factory/factory-no-python-check.HC`

The canonical archive at this ACT's entry (HEAD 5cbda9b) MUST
remain the substrate baseline:
  - 313 T symbols
  - _FREE / _STRNCMP / _MEMSET / _STRLEN_FAST / _SpawnAndCapture
    each with strong_definition_count = 1
  - errno_shim.o present

If any of those changes incidentally, this ACT halts and
recommends opening a separate bounded ACT.

## 8. HALT conditions

  HALT_FAIL_OPEN_REMAINS:        P0-1 not closed by C2.
  HALT_OPPORTUNISTIC_FALLBACK:   P0-2 not closed by C2.
  HALT_N02_CONFOUNDED:           P0-3 not closed by C2.
  HALT_SEMANTIC_MATRICES_MISSING:P0-4 not closed by C2.
  HALT_GOVERNANCE_COMBINED_PHASE:G-1 not honored (C0 must
                                 precede C1 evidence).
  HALT_RED_NOT_REPRODUCED:       any RED-1..RED-4 cannot be
                                 mechanically reproduced.
  HALT_SCOPE_EXPANSION_REQUIRED: AC requires a mutation outside
                                 §2 scope.

This ACT MUST halt with one of the above if its mission is not
honestly achievable in the authorized scope.

## 9. Residue (pre-declared)

  P1: The `./hcc` ARM64 inline-asm parser regression at commit
      6ba9f5ec is upstream residue. NOT mutated by this ACT.
      Track as ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
      candidate.

  P1: `tools/quality/runtime01-selftest.HC` duplicates archive
      symbols. NOT mutated by this ACT.

  P2: PolyC verifier's SpawnAndCapture invocation uses a relative
      path. NOT mutated by this ACT.

  P3: The predecessor HANDOFF's PASS_TRUE_GREEN claim is
      reclassified to FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT_LEVEL
      but remains in the tree as historical evidence per F14.

## 10. Commit topology

```text
C0 AUTH:     ACT document + entry identity
C1 RED:      four RED witnesses (RED-1..RED-4)
C2 IMPL:     fail-closed lib-tos, provenance-strict hcc
             selection, runtime-contract-test.HC, N02 harness
             rewrite
C3 VERIFY:   mandatory AC ledger + all gates + conservation
C4 CLOSE:    HANDOFF only (no production mutation)
```

5 commits; C0 commits BEFORE C1 evidence is gathered (governs
G-1).

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md` (Factory v2 section).

Verdict authority lives in the CLOSE commit's `ACT-Verdict`
trailer per GIT-METADATA.md. The HANDOFF body is descriptive.

Expected verdict at closure: PASS_TRUE_GREEN with all 22 ACs
PASS, OR a HALT_* token from §8 if defects persist.
