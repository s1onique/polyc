# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02 — CLOSE

VERDICT

PASS_PRECEDENCE_RESTORED_WITH_ROUTE_REMAINDER

The required compiler-producing route now takes its `-o-`/`-S`
**precedence decision** from the **compiled PolyC driver**, and the
transfer is proven causally rather than declared.

This close is a **precedence** PASS and nothing more. The whole-CLI
remainder is explicitly OPEN, the historical evidence debts are
explicitly OPEN, and the final external terminality receipt has **not**
yet run: this tree commits its **PLAN**, not a forecast of its result.

```text
ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02

IDENTITY
ENTRY_HEAD=4bbd1bbbf4249f0a7fa1cf05997bd24d8562cdba
ENTRY_TREE=3f267506a1b57bac4a5039fc4aae698b2a374539
FINAL_HEAD=<the terminal CLOSE commit, queried from Git>
FINAL_TREE=<the terminal CLOSE commit's tree, queried from Git>
WORKTREE_STATUS=CLEAN
BRANCH=main
REPLACE_REFS=0
ACT_OWNED_WORKTREES_REMAINING=0
PUSH_PERFORMED=NONE

PHASES
C0_RED=edd9488b
C1_EVIDENCE=a32517a2
C2_IMPL=a0b471ee
C3_EVIDENCE=cc31a84f
C4_CLOSE=<the terminal CLOSE commit, queried from Git>

ROOT CAUSE / FINDING
A C-OWNED POLICY DECIDED THE `-o-`/`-S` CONDITION ON THE REQUIRED
ROUTE, AND IT FIRED WITHOUT CONSULTING THE POLYC-SELECTED STATUS.

  src/cli.c::cliParseArgsPolyC, in the selector-ON region, read
  args->to_stdout and args->assemble_only and fired on their own.
  The PolyC status domain had NO member for that condition, so the C
  side HAD to decide it. The source comment claimed the opposite.

  The consequence was not a wrong message. It was an AUTHORITY
  failure: an argv whose PolyC-selected status was USAGE reported the
  C-owned `-o-` diagnostic instead of the driver's, because the C
  policy PREEMPTED the selected status.

  The G0 oracle agreed with the selector-ON compiler on every such
  argv, so a G0-vs-ON behavioural differential CANNOT see this defect.
  The comparison that sees it is the observed diagnostic against the
  PolyC-selected status.

  The C3 phase MEASURED a SECOND defect on the same seam. The C-side
  status dispatch was a set of POSITIVE equality tests with no domain
  bound and no default branch, so an OUT-OF-DOMAIN status matched NONE
  of them and the compiler PROCEEDED as if the driver had selected OK:
  exit 0, an artifact produced, no diagnostic. That is a FAIL-OPEN,
  and it violated AC36.

IMPLEMENTATION
THE CONDITION MOVED INTO THE POLYC DRIVER, AND THE C SIDE BECAME A
MECHANICAL EXECUTOR OF AN ALREADY-CHOSEN STATUS.

  tools/bootstrap/selfhost-driver-wp001.HC
    + WP_STATUS_TO_STDOUT 6, a NEW status-domain member. It is the
      LARGEST value, so it is DISJOINT from every pre-existing status.
    + WpDriverStdoutNeedsAssembly(), the driver's own decision. The
      driver ALREADY classified both options -- `-S` is
      WP_KIND_ASSEMBLY and `-o-` is WP_KIND_STDOUT -- so this adds NO
      option table, NO option name, NO flag test and NO arity rule.
    + WpDriverMapStatus returns WP_STATUS_TO_STDOUT for the condition,
      in the FROZEN precedence position.

  src/selfhost-driver-wp001.h
    + WP_DRIVER_STATUS_TO_STDOUT 6, the C mirror of the SAME source
      value. The C side invents no parallel value.
    + WP_DRIVER_STATUS_COUNT 7, the EXCLUSIVE UPPER BOUND of the
      mirrored status domain. The bound IS the member count, so the
      two cannot drift apart.

  src/cli.c
    + the `-o-` guard is now dispatched on the PolyC-selected status.
      It no longer reads args->to_stdout and args->assemble_only.
    + the fail-closed guard, placed BEFORE any diagnostic dispatch:
      a status outside the domain is rejected, the process exits 1, no
      artifact is produced, and there is no fallback to the legacy C
      decision.

  src/main.c is UNCHANGED, byte for byte. The artifact-class decision
  and the emission translation table remain C-owned and FROZEN. The
  parser, the AST, the IR, the backend and the language semantics are
  UNCHANGED, byte for byte, against the digests frozen at C1.

THE C1 PREDICTION WAS REFUTED BY MEASUREMENT

  The C1 freeze predicted EXACTLY ONE intended behavioural delta. The
  MEASURED behavioural delta is ZERO, over 14 fixtures and the full
  five-field comparator.

  What changed is WHO DECIDED, not WHAT WAS SAID. The defect was
  never that the wrong diagnostic was printed; it was that a C-OWNED
  POLICY printed it while the PolyC driver had already selected a
  status.

  The C1 freeze is IMMUTABLE historical evidence of what was predicted
  (F14). It is NOT rewritten. The C2 and C3 evidence record the
  refutation.

GATES AND MEASUREMENTS

  G0 C-ONLY INDEPENDENCE
    driver symbols in the G0 binary       0
    driver relocations in the G0 binary   0
    total relocation lines                30275
    traces of the new status members      0
    R04 against the REAL G0 binary: SILENT (exit 0) = PROVEN
    INDEPENDENT.

  THE FOUR EXPERIMENTS
    M-POLYC-PRECEDENCE-01  the PolyC precedence IS CAUSAL: mutating
      the driver's status return CHANGES the reported diagnostic.
    M-C-LEGACY-02          the legacy C policy is DORMANT on the
      selector-ON build (0 differing fixtures) and LIVE on the G0
      oracle (3 differing fixtures).
    M-POLYC-STATUS-03      the driver's status mapping IS CAUSAL for
      the USAGE diagnostic.
    M-POLYC-POISON-04      the out-of-domain status FAILS CLOSED:
      exit 1, no artifact, no fallback.

  THE PRODUCER DAG AND THE ORDERED PAIRS
    four DISTINCT producer identities by content SHA-256; no alias.
    9 of the 12 ordered pairs agree on all 14 fixtures. The 3 that
    differ are exactly the pairs that involve G3, the PINNED-tree
    producer, which predates the PolyC driver; they differ on ONE
    fixture, fx_prec_stdout_ok, in the stdout digest ONLY. ALL FIVE
    PRECEDENCE FIXTURES AGREE IN EVERY ONE OF THE 12 PAIRS. The
    difference is a GENERATOR difference, not a precedence difference.

  THE 24 NEGATIVE CONTROLS
    all 24 are SILENT on the fixed tree;
    23 fire their OWN exact reason token on their adverse material;
    NC17 is SILENT on the live tree and fires only on a deliberately
    DORMANT subject. This matches the FROZEN roster: NC_MUST_FIRE 23,
    NC_MUST_NOT_FIRE 1.

  CONSERVATION
    the observable delta against the pre-fix build   0 fixtures
    the parser suite           376/376, 0 failed
    the assertion MD5          b6f117eb1386ca80f81bc06226e2a741
                               (BYTE-IDENTICAL to the historical value)
    the lexer differentials    89/89, 45/45, 23/23
    the production authorities 16/16 defined and linked; delta 0
    F-NO-PYTHON                the SAME 12 pre-existing path IDs, 0 new

  GATES
    gate-fast                  PASS
    gate-push (serialized)     PASS, 7 of 7 checks
    factory-append-only-test   11/11 PASS
    factory-v2-test            53/53 PASS
    factory-closure-status     PASS
    F14                        the C0/C1/C2 evidence is byte-identical
                               since the C2 commit

REMAINDER -- EXPLICITLY OPEN, DISCLOSED, NOT MIGRATED

  THE REQUIRED-ROUTE C SEMANTIC REMAINDER IS 1.

    BR_MAIN_COMPILE_TO_AST   C_SEMANTIC_ENGINE_RETAINED
      the retained C parser FAULT GATE. compileToAst returns 0 when
      the retained C parser accumulated errors. The decision is a
      FAULT COUNT from the retained engine, NOT a route choice.

  THE WHOLE-CLI REMAINDER IS 12 MEASURED ROWS.

    Every C-owned decision that is NOT on the required route but
    remains C-owned on the whole CLI. Each row carries its line number
    re-derived from the post-C3 source, and a classification that says
    WHY it is retained. The inventory is in
    evidence/.../c3/whole-cli-remainder.tsv.

    BR_CLI_O_DASH_S_GUARD    the `-o-`/`-S` condition, now DISPATCHED
                             on the PolyC-selected status. The C side
                             FORMATS the selected diagnostic and
                             DECIDES NOTHING. The remaining C-owned
                             part is the message TEXT, frozen by AC25.
    BR_MAIN_PRINT_TOKENS    the --print-tokens mode choice
    BR_MAIN_TRANSPILE       the -transpile mode choice
    BR_MAIN_COMPILE_TO_AST  the C parser FAULT GATE
    BR_MAIN_PRINT_AST       the --print-ast mode choice
    BR_MAIN_DUMP_IR         the --dump-ir mode choice
    BR_MAIN_DUMP_IR_POOLED  the pooled --dump-ir mode choice
    BR_MAIN_EMIT_LLVM       the --emit-llvm mode choice
    BR_MAIN_JIT_OR_REPL     the -jit/-repl mode choice
    BR_MAIN_REPL            the -repl mode choice
    BR_MAIN_ASSEMBLE        the -S assembly mode choice
    BR_MAIN_LSP             the -lsp mode choice

  M2 IS NOT ACHIEVED. The artifact-class decision and
  `src/main.c`'s emission translation table remain C-owned and FROZEN.

HISTORICAL DEBT -- CONSERVED, NOT REPAIRED

  The predecessor committed THREE acceptance ledgers of 50 rows each,
  whose recomputed status partitions are 10/39/1, 47/2/1 and 49/0/1
  respectively (PASS / NOT_RUN / DEFERRED), and a negative-control
  result of 23/24, where NC17 correctly did NOT fire because its
  subject is PROVEN LIVE.

  A four-way partition of the predecessor's acceptance criteria into
  `29 / 10 / 10 / 1` was REQUESTED. NO SUCH PARTITION EXISTS. The
  whole Git history was searched for it over 1833 commits with no
  match. The requested figure is recorded as a REFUTED HYPOTHESIS, and
  the conserved value is the MEASURED one.

  This ACT does NOT repair the predecessor's debt and does NOT
  endorse it. The predecessor's adjudications remain immutable
  historical evidence.

THE PROPOSED SEPARATE EVIDENCE SUCCESSOR, NOT AUTHORIZED HERE

  ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-EVIDENCE-CORRECTION01 --
  independently re-adjudicate the predecessor's 50 historical criteria
  against immutable phase-specific evidence. Do not start it under
  this ACT.

TERMINALITY

  The final external receipt has NOT run. This tree commits its PLAN.

  evidence/.../c4/terminality-plan.txt describes what the external,
  read-only probe WILL verify AFTER this CLOSE. It asserts nothing
  about the outcome. AC50 is NOT claimed: its receipt lives OUTSIDE
  the repository and is POST-CLOSE.

  No SHA OF SELF is claimed by any artifact committed in the CLOSE
  commit. The CLOSE commit's own SHA and TREE are queried from Git.

RESIDUE

  P1  The whole-CLI remainder: 12 C-owned decisions, DISCLOSED and
      MEASURED, not migrated. A successor ACT must migrate them.
  P1  The predecessor's historical debt: CONSERVED, not repaired.
      The separate evidence successor above is not authorized here.
  P2  The `factory-polyc-tools-check.HC` checker is still not landed;
      `F-POLYC-TOOLS` is recorded in the pointer but not enforced.
      This is a pre-existing binding, not a residue of this ACT.

NEXT ACT

  The next ACT is the whole-CLI remainder migration, scoped to the
  twelve rows measured in
  evidence/.../c3/whole-cli-remainder.tsv. It is NOT authorized by
  this ACT and must be opened on its own authority.
