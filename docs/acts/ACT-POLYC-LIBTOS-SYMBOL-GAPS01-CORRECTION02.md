# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02

## 0. Predecessor verdict and falsification

`ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01` closed with the
trailer `ACT-Verdict: PASS_TRUE_GREEN` (commit `ad77672`).
A post-close reviewer audit REJECTED that verdict, identifying
three closure-truth defects that this ACT is bounded to repair:

- **P0-1 — substituted AC table.** The C3 evidence file
  `mandatory-ac-status.tsv` reports 22 PASS / 0 FAIL but uses a
  *different* AC01..AC22 mapping than the one authorized in
  `docs/acts/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01.md`
  §6. The reviewer's authoritative mapping is the one in the
  ACT document. The C3 ledger is therefore not a replay of the
  authorized AC01..AC22.

- **P0-2 — bootstrap identity not verified.** Authorized AC03
  requires the missing-bootstrap precondition error to NAME
  `HCC_BOOTSTRAP_PROVENANCE_SHA`. Authorized AC04 requires a
  producer-identity check on the resulting archive. Neither
  is implemented. `LIBTOS_HCC` is overrideable; an executable
  at the path is not provenance.

- **P0-3 — F-POLYC-TOOLS violated.** Authorized §5 C2-3 and §2
  explicitly permit only one new tool:
  `tools/quality/runtime-contract-test.HC`. The C2 commit added
  `scripts/quality/libtos-n02-harness.sh` at 262+ LOC, which is
  substantive shell, not "≤50 LOC of bootstrap glue". The
  C3 evidence acknowledged the violation and tried to reclassify
  it as a "quality harness" exemption. F-POLYC-TOOLS has no
  such exemption; F5 forbids weakening the rule.

- **W1 — LEXER conservation not rerun.** Authorized AC14
  requires `make lexer08-fixedpoint-verify` and
  `make lexer09-fixedpoint-verify` to PASS. The C3 evidence
  concluded conservation from "no LEXER source files mutated",
  which is a weaker predicate than the AC requires, especially
  given that the runtime archive (the linker substrate for both
  verifiers) was rebuilt by C2.

The predecessor verdict `PASS_TRUE_GREEN` is hereby reclassified
to `FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT` per F14. The HANDOFF
file `docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-
CORRECTION01.md` is not rewritten (F14); its verdict is
reclassified by this ACT and the new verdict.

Substrate engineering result preserved from CORRECTION01:
fail-closed build seam (no `|| true` at archive boundary), 5
required symbols exported, archive-only consumer link works,
21-case semantic matrix PASS, N02 isolated to a single symbol.

## 1. Mission

Close the three P0 closure-truth defects and the W1 LEXER
gap so the AC ledger is a faithful replay of the authorized
AC01..AC22. Keep all substrate engineering from CORRECTION01.

## 2. Scope

### allowed

- `Makefile` lib-tos target: add `HCC_BOOTSTRAP_PROVENANCE_SHA`
  to the precondition error message (AC03); add archive-level
  producer-identity verification (AC04); keep fail-closed.
- `Makefile` runtime-contract-test target: unchanged.
- New PolyC tool `tools/quality/libtos-n02-isolate.HC` that
  contains the substantive archive-mutation, inspection, and
  link-checking logic (replaces the shell harness's body).
- `scripts/quality/libtos-n02-harness.sh`: rewrite as ≤50 LOC
  dispatch shell that invokes the PolyC tool.
- `evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02/{c0,c1,c2,c3,c4}/`
- `docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02.md`

### forbidden

- No mutation of `src/parser.c`, `src/aarch64.c`,
  `src/holyc-lib/*.HC`.
- No re-classification of any prior HANDOFF (F14).
- No new non-PolyC tools beyond the rewritten shell dispatch.
- No silent fallback to `./hcc` or any other compiler.

## 3. Entry gate

```text
git branch --show-current   = main
git status --short          = clean (C0 untracked → tracked)
git rev-parse HEAD          = ad776721cfd176c594eb433a27bfb3cbf72389cc
```

## 4. Principal RED (C1)

- RED-1: replay the AC ledger from the authorized AC01..AC22
  definitions and confirm the prior ledger's mapping is
  substituted. (Capture which AC IDs differ.)
- RED-2: invoke `make lib-tos` with bootstrap absent; confirm
  the precondition error does NOT name
  `HCC_BOOTSTRAP_PROVENANCE_SHA` (and the archive has no
  `__.SYMDEF` producer-id note).
- RED-3: count `scripts/quality/libtos-n02-harness.sh` LOC;
  confirm >50.
- RED-4: invoke `make lexer08-fixedpoint-verify` and
  `make lexer09-fixedpoint-verify`; confirm the verifiers
  themselves are not yet built.

## 5. Implementation boundary (C2)

C2-1: Capture the actual bootstrap hcc commit SHA at C0 entry
  (from `build/hcc-bootstrap04` itself or from the canonical
  build trace). Store as `HCC_BOOTSTRAP_PROVENANCE_SHA` and
  embed in the precondition error message and in the C3
  evidence.

C2-2: Bake a producer-identity note into the canonical
  archive's `__.SYMDEF`. Either:
    (a) via `ar qs` (which preserves a string at the archive
        level) with the producer-id; OR
    (b) via a small synthetic `.o` member that contains a
        `__producer_id` symbol with the SHA as its value.

C2-3: Replace `scripts/quality/libtos-n02-harness.sh` body
  with a PolyC tool `tools/quality/libtos-n02-isolate.HC`
  that does extract / llvm-objcopy / ar rcs / consumer link
  / undefined-symbol capture. Rewrite the shell as ≤50 LOC
  of dispatch glue that invokes the PolyC tool with the same
  command-line surface.

C2-4: Build `build/lexer08-fixedpoint-verify` and
  `build/lexer09-fixedpoint-verify` from current source (no
  source mutation), invoke them, and capture exit codes /
  output for AC14.

## 6. Acceptance criteria

The AC01..AC22 definitions in
`docs/acts/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01.md`
§6 are the authoritative reference. The C3 ledger MUST replay
those definitions verbatim and report PASS/FAIL/UNKNOWN/MISSING
for each. Required ACs:

- AC02 — fail-closed with LIBTOS_HCC=/bin/false, no libtos.a written.
- AC03 — missing bootstrap fails with error message naming
  `HCC_BOOTSTRAP_PROVENANCE_SHA` and the expected SHA.
- AC04 — `ar t libtos.a` lists `__.SYMDEF` and the producer
  identity under it matches `HCC_BOOTSTRAP_PROVENANCE_SHA`.
- AC05..AC11 — semantic matrices via `make runtime-contract-test`.
- AC12 — N02 isolation: corrupted archive has all pristine
  members; only `_SpawnAndCapture` is hidden; link fails
  solely with `_SpawnAndCapture` undefined.
- AC13 — archive-only consumer link still works.
- AC14 — `make lexer08-fixedpoint-verify` AND
  `make lexer09-fixedpoint-verify` both PASS (exit 0).
- AC15..AC22 — gates, hygiene, F-NO-PYTHON, F-POLYC-TOOLS,
  F14, worktree clean, append-only, phase ordering.

AC18 (F-POLYC-TOOLS) is strengthened for THIS correction:
PASS iff the only shell file added or rewritten is ≤50 LOC
of dispatch glue; the substantive n02 logic is in PolyC.

## 7. Conservation gates

- LEXER08/09 verifiers: must still PASS (AC14).
- factory-closure-status-test: PAIR_OK=14.
- factory-append-only-test: PASS=11 FAIL=0.
- factory-no-python-check: PASS.
- F14: predecessor HANDOFF and predecessor evidence tree
  remain untouched in the working tree.

## 8. HALT conditions

- HALT_BOOTSTRAP_PROVENANCE_UNMEASURABLE: if the bootstrap
  hcc at `build/hcc-bootstrap04` cannot report its commit SHA
  via any reproducible mechanism, halt with this token; do
  not invent a SHA.
- HALT_F_POLYC_TOOLS_EXEMPTION_DENIED: if F-POLYC-TOOLS cannot
  be satisfied without rewriting the shell harness as PolyC,
  rewrite the harness; do not weaken the rule.
- HALT_SCOPE_EXPANSION_REQUIRED: if AC14 requires source
  mutations to the LEXER verifiers, halt; that work belongs
  in a separate LEXER ACT.

## 9. Residue (pre-declared)

- P1: `./hcc` ARM64 inline-asm parser regression at commit
  `6ba9f5ec`. Unchanged from CORRECTION01.
- P2: PolyC verifier's `SpawnAndCapture` invocation uses
  relative path. Unchanged.

## 10. Commit topology

Five separate commits, append-only:

```text
C0: ACT document + entry identity
C1: RED witnesses (4)
C2: implementation
C3: verification + evidence (incl. AC ledger replay)
C4: closure handoff
```

## 11. Closure handoff

`docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02.md`.
Verdict trailer in the C4 commit.
