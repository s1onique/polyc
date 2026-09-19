# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03

## 0. Mission

Close the second-round post-close reviewer audit of
ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02. CORRECTION02's
`PASS_TRUE_GREEN` trailer is hereby reclassified (per F14) to
`FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT`. The remaining binding
defects are:

  P0-1: The "provenance-strict" mechanism is self-certifying.
        `LIBTOS_BOOTSTRAP_SHA` is freshly measured and embedded
        into `producer_id.o`, then the archive is checked against
        the same freshly-measured value. The judge derives its
        expected identity from the subject being judged. There
        is no external pinning, and `LIBTOS_HCC` remains
        overridable on the command line (GNU Make command-line
        variables override ordinary Makefile assignments unless
        `override` is used).

  P0-2: AC17 was substituted. The authorized AC17 predicate is
        "`tools/factory/factory-no-python-check.HC` (or its sh
        wrapper) still passes". The checker is missing its build
        artifact (`build/factory-no-python-check` does not exist
        because no Makefile target compiles it via the bootstrap
        chain). The wrapper returns RC=3 (binary missing). The
        CORRECTION02 C3 evidence then reclassified the predicate
        to "F14-equivalent: did this ACT add any new Python",
        which is NOT the authorized predicate.

  C3-1: AC20 evidence was captured at C3 (before the C4 commit),
        so it correctly records `FAIL: uncommitted changes`.
        The ledger then marked AC20 PASS anyway. AC20's predicate
        `git status --short` is empty can only be evaluated AFTER
        C4 commits.

  C3-2: AC22 evidence was captured against the bounded range
        `6e30e7f..HEAD` (entire ancestor history from CORRECTION01
        entry), finding 12 commits, while the predicate expects
        exactly 5 CORRECTION02 commits. The evidence must be
        captured against the bounded CORRECTION02 commit range
        only.

  C3-3: `__.SYMDEF` terminology misuse. `__.SYMDEF` is the
        BSD/Darwin archive symbol table mapping symbols to
        members, NOT a container in which `producer_id.o` lives.
        The c3-ac04.txt evidence uses the incorrect framing.

This ACT's bounded repair closes all five defects. No new
substrate engineering is in scope; this is a correctness /
authority / evidence-binding correction.

## 1. Predecessor(s)

  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01  (substrate; PASS at ad77672)
  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02  (FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT at 0f24900)

## 2. Scope

In scope:

  (a) Makefile:
      - Freeze the authorized bootstrap identity by adding
        `override LIBTOS_HCC := ./build/hcc-bootstrap04`
        AND
        `LIBTOS_BOOTSTRAP_EXPECTED_SHA := 3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6`.
        The Makefile MUST reject any LIBTOS_HCC whose measured
        SHA-256 differs from the frozen expected value, even if
        it can build all.HC. The error must name
        `HCC_BOOTSTRAP_PROVENANCE_SHA`, the measured SHA, and
        the expected SHA.
      - Add `make factory-no-python-check-binary` target that
        compiles `tools/factory/factory-no-python-check.HC`
        using the bootstrap hcc (not the broken `./hcc`) and
        archive-only links against
        `build/test-prefix/lib/libtos.a`.

  (b) Evidence:
      - CORRECTION03 c1/, c2/, c3/, c4/ directories with per-AC
        evidence files for AC01..AC22.
      - AC20 evidence lives in C4 (after the C4 commit), not C3.
      - AC22 evidence uses the bounded CORRECTION03 range only.
      - AC04 evidence uses correct terminology
        (`ar t ... libtos.a` lists producer_id.o as a regular
        archive member, and `nm -j producer_id.o` reports the
        __producer_id symbol).

Out of scope (preserved):

  - lib-tos recipe structure (8-step build).
  - Archive symbol set (5 required symbols).
  - tools/quality/libtos-n02-isolate.HC (361 LOC PolyC).
  - scripts/quality/libtos-n02-harness.sh (34 LOC shell dispatch).
  - All closed evidence trees and HANDOFFs.

## 3. C0-AUTHORIZED AMENDMENTS

Per reviewer's defect #2 ("A pre-existing reason can justify a
HALT or amendment authorized before verification. It cannot
turn an explicitly failing required command into `PASS` at C3"),
the following predicate amendments are C0-authorized BEFORE any
C1/C2/C3 verification runs:

### 3.1 AC03 amendment (P0-1 closure authorization)

The CORRECTION02 AC03 predicate was:

> PASS iff, with `build/hcc-bootstrap04` removed, `make lib-tos`
> exits nonzero with a precondition error message that names
> `HCC_BOOTSTRAP_PROVENANCE_SHA`.

This predicate is REPLACED by the bounded CORRECTION03 AC03
predicate, which the reviewer-required mutation control enforces:

> PASS iff ALL of:
>   (a) `make lib-tos` with `build/hcc-bootstrap04` removed exits
>       nonzero with a precondition error that names
>       `HCC_BOOTSTRAP_PROVENANCE_SHA`.
>   (b) `make lib-tos` with `LIBTOS_HCC=/tmp/mutated-hcc` where
>       `mutated-hcc` can successfully build `src/holyc-lib/all.HC`
>       but whose SHA-256 differs from the frozen expected
>       `3b447421...` exits nonzero with a precondition error
>       that names BOTH the measured SHA and the expected SHA.
>   (c) `make lib-tos` with the default LIBTOS_HCC exits 0 and
>       writes a libtos.a whose recorded producer_id matches
>       `3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6`.
>   (d) The Makefile uses `override LIBTOS_HCC := ...` so that
>       command-line `make lib-tos LIBTOS_HCC=...` is rejected
>       (or, equivalently, the Makefile's pinning mechanism
>       defeats the override).

The expected SHA is frozen in the Makefile as
`LIBTOS_BOOTSTRAP_EXPECTED_SHA := 3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6`.

### 3.2 AC17 amendment (P0-2 closure authorization)

The CORRECTION02 AC17 predicate was:

> PASS iff `tools/factory/factory-no-python-check.HC` (or its
> sh wrapper) still passes.

This predicate is ambiguous as written because the checker
classifies tracked Python files as grandfathered violations
(POLYC_TOOLS_TRACKED_PYTHON > 0) under F-NO-PYTHON's forward-only
doctrine. CORRECTION03 C0-AUTHORIZES the following interpretation:

> PASS iff ALL of:
>   (a) The checker binary `build/factory-no-python-check` is
>       buildable from source via the authorized bootstrap
>       chain (`./build/hcc-bootstrap04 --install-dir=...
>        -c tools/factory/factory-no-python-check.HC -o ...o`,
>       then `cc ... -L./build/test-prefix/lib -ltos -o ...`).
>   (b) `scripts/quality/factory-no-python-check.sh` exits with
>       a non-3 RC (i.e. the wrapper did not abort due to a
>       missing binary; it actually ran the checker).
>   (c) The checker emits a structured report with
>       `POLYC_TOOLS_TRACKED_INSPECTED > 0` and
>       `POLYC_TOOLS_TRACKED_PASSES > 0`.
>   (d) No new Python was introduced by THIS ACT (CORRECTION03),
>       verified by `git diff ENTRY_HEAD HEAD -- '*.py'
>       ':(exclude)docs/factory/LEGACY-NON-POLYC-TOOLS.tsv'`
>       returning an empty diff.

### 3.3 AC20 procedure amendment (C3-1 closure authorization)

AC20's predicate `git status --short` is empty can only be
evaluated AFTER C4 commits the closure handoff. The CORRECTION02
C3 evidence captured this at C3, where it correctly reported
FAIL. The CORRECTION02 ledger then promoted it to PASS, which
contradicted its own evidence. CORRECTION03 C0-AUTHORIZES:

> AC20 evidence lives in `c4/c4-ac20.txt`, captured AFTER the
> C4 commit. The C3 ledger records `AC20 = DEFERRED_TO_C4` and
> the C4 handoff records the final worktree status.

### 3.4 AC22 procedure amendment (C3-2 closure authorization)

AC22's predicate requires 5 commits in C0..C4 order. CORRECTION02
C3 captured the log against `6e30e7f..HEAD` (CORRECTION01 entry),
finding 12 commits (the entire predecessor lineage). CORRECTION03
C0-AUTHORIZES:

> AC22 evidence uses `git log --oneline ENTRY_HEAD..HEAD` where
> ENTRY_HEAD is the CORRECTION03 C0 commit's first parent.
> This bound isolates CORRECTION03's commits and shows exactly
> 5 (C0, C1, C2, C3, C4) in order.

### 3.5 AC04 terminology fix (C3-3 closure authorization)

CORRECTION02's c3-ac04.txt framed the producer_id as "under
__.SYMDEF", which is incorrect: `__.SYMDEF` is the BSD/Darwin
archive symbol table, not a directory in which members live.
CORRECTION03 C0-AUTHORIZES:

> AC04 evidence says: "Pristine archive `ar t
> build/test-prefix/lib/libtos.a` lists `__.SYMDEF` (symbol
> table), `all.o`, `errno_shim.o`, and `producer_id.o`. The
> producer_id is a regular archive member, not nested under
> `__.SYMDEF`. `nm -j producer_id.o` reports `__producer_id`
> as a defined symbol. `strings producer_id.o | grep -qF
> 3b447421...` confirms the SHA-256 is baked in."

## 4. Acceptance criteria

This ACT reuses the AC01..AC22 contract from CORRECTION01 §6
with the amendments in §3 above explicitly authorized at C0.

  AC01..AC22: 22 PASS / 0 FAIL / 0 UNKNOWN / 0 MISSING
               (AC03, AC04, AC17, AC20, AC22 evaluated per
               the §3 amendments; AC01..AC02, AC05..AC16,
               AC18..AC19, AC21 use the CORRECTION01 §6
               predicate verbatim).

## 5. Conservation gates

  - `make gate-fast`                         RC=0, STATUS=PASS
  - `factory-append-only-test`               PASS=11 FAIL=0
  - `git diff --check ENTRY_HEAD HEAD`       RC=0
  - `git status --short` at C4               empty
  - LEXER08 + LEXER09 fixed-point verifiers  PASS
  - 21/21 runtime-contract-test cases        PASS
  - 10/10 N02 isolation sub-cases            PASS
  - Predecessor evidence trees untouched per F14
    (gated on `git diff ENTRY_HEAD HEAD -- evidence/` returning
    no diff for any CORRECTION02 or earlier evidence subtree).
