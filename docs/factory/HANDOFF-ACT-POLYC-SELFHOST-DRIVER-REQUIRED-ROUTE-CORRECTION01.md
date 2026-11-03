# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01 — CLOSE

VERDICT

PASS_REQUIRED_ROUTE_POLYC_ACTION_AUTHORITY

The required compiler-producing route now takes its artifact class from
the **compiled PolyC driver**, and the transfer is proven causally
rather than declared.

This close is a **route** PASS and nothing more. The whole-CLI
remainder is explicitly OPEN, the historical evidence debts are
explicitly OPEN, and the final external terminality receipt has **not**
yet run: this tree commits its **PLAN**, not a forecast of its result.

```text
ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01

IDENTITY
ENTRY_HEAD=33f93347277c6ce242a93b71ab5f0123ccaea4e5
ENTRY_TREE=d34300d54de1f3c9f51c41702571a3a19a37739b
FINAL_HEAD=<the terminal CLOSE commit, queried from Git>
FINAL_TREE=<the terminal CLOSE commit's tree, queried from Git>
WORKTREE_STATUS=CLEAN
BRANCH=main
REPLACE_REFS=0
ACT_OWNED_WORKTREES_REMAINING=0
PUSH_PERFORMED=NONE

PHASES
C0_RED=074a1f088302cafda4a8b55baac4ff6a919455b2
C1_EVIDENCE=d05c78e7a9682e7737c2da5e870bc120accbbd3c
C2_IMPL=da49ad1137421786b4686c6d92e7ab4e520ebe21
C3_EVIDENCE=<the C3 commit, queried from Git>
C4_CLOSE=<the terminal CLOSE commit, queried from Git>

ROOT CAUSE / FINDING
THE PRODUCTION EMISSION FUNCTION DECIDED THE ARTIFACT CLASS FROM A C
REQUEST FIELD, AND THE POLYC DRIVER'S EXPORTED ACTION WAS NEVER
CONSULTED.

  src/main.c::emitFile branched on args->emit_object, and the linked
  binary showed that decision directly. The compiled PolyC driver
  exported WpDriverSelectedAction(), but the export had ZERO proven
  production callsites, so it was decorative. The existing object
  verifier established symbol PRESENCE, not CONSUMPTION.

  Both argv shapes -- "-c input.HC -o out.o" and "input.HC -o out" --
  select the SAME whole-argv action while producing DIFFERENT artifact
  classes, so the whole-argv action cannot express the required
  decision. The artifact class is a decision of its own.

IMPLEMENTATION
THE ARTIFACT-CLASS DECISION MOVED TO THE POLYC DRIVER, AND THE C SIDE
BECAME A MECHANICAL EXECUTOR OF AN ALREADY-CHOSEN ACTION.

  tools/bootstrap/selfhost-driver-wp001.HC
    exports WpDriverSelectedEmission(), whose DISJOINT scalar domain is
    0 absent/invalid, 1 object, 2 executable, 3 assembly, 4 dylib.

  src/main.c
    emitFile() CONSUMES that code and TRANSLATES it into a platform
    command. The translation table contains no option name, no flag
    test, no arity rule and no argv inspection. An out-of-domain code
    is a FAIL-CLOSED error; there is no path from an invalid action to
    the legacy C decision.

  src/selfhost-driver-wp001.h
    declares the accessor and the frozen domain.

  src/cmake/VerifyDriverWp001Consumption.cmake  (new)
    verifies the CONSUMPTION, not the definition, and is a BUILD-GRAPH
    EDGE: the production compiler is never linked without a verified
    PolyC emission action consumer.

  src/cmake/VerifyDriverWp001Object.cmake
    additionally requires the new export.

  tools/quality/driver-required-route-correction01-test.HC  (new)
    a COMPILED POLYC artifact-class classifier. It reads the Mach-O
    magic and filetype from the BYTES, never a file name and never an
    exit status.

  tests/driver-wp001/required-route/route-source.HC  (new)
    the frozen fixture, byte-identical to the C1-frozen fixture.

  Makefile
    the canonical target `make driver-wp001-required-route-test`.

  src/CMakeLists.txt
    two PRE-EXISTING build defects in the WP-001 producer rule were
    repaired (see RESIDUE).

THE CONSUMPTION IS PROVEN, NOT DECLARED.

  the production object IMPORTS the accessor
    _WpDriverSelectedEmission U 0 0
  the linked binary CALLS it from INSIDE the emission function
    0x10003908c  bl  _WpDriverSelectedEmission   (exactly once in a
    337-instruction window bounded by the _emitFile label)
  the production object carries a real relocation against it
    0x00000420  True  long  True  BR26  False  _WpDriverSelectedEmission
  the PolyC subject DEFINES the call target
    _WpDriverSelectedEmission  T  0x21e0
  the emission function does NOT read the C request field
    args->emit_object lives at CliArgs+0x70; the window contains NO
    load at that displacement
  the action is VALIDATED before it is used
    0x100039094  sub x8, x0, #0x1
    0x100039098  cmp x8, #0x4
    0x10003909c  b.hs 0x100039438   (FAIL CLOSED)

THE BUILD REFUSES TO LINK WITHOUT THE CONSUMPTION.

  ADV-01  the production source does not call the accessor
          REJECT_POLYC_ACTION_NOT_CONSUMED
  ADV-02  the production object defines its own accessor
          REJECT_DUPLICATE_ACTION_SOURCE
  ADV-03  the production object does not exist
          REJECT_MISSING_PRODUCTION_OBJECT
  ADV-04  the PolyC driver subject does not exist
          REJECT_MISSING_DRIVER_SUBJECT

  None of them produced a linked compiler.

RED
THE FIVE REDS REPRODUCED AT C0 AGAINST REAL BUILDS.

  R01_UNUSED_ACTION        the accessor had zero production callsites
  R02_C_EMISSION_POLICY    the C emission branch read args->emit_object
  R03_FAKE_OBJECT          the artifact class was not proven from bytes
  R04_ORACLE_LEAK          the G0 oracle's independence was unproven
  R05_BACKDATED_RECEIPT    terminality chronology was unproven

  R02 was REFINED at C2 and the refinement is a STRENGTHENING: it now
  examines ONLY the selector-ON region and ignores comment lines, so it
  distinguishes a real policy read from a permitted legacy read and
  from a mention. It was proven on the C0 source (FAILS), the C2 source
  (PASSES), an injected live read (FAILS), a legacy-region read
  (PASSES) and a comment mention (PASSES).

THE CAUSAL AND DORMANCY EXPERIMENTS, EXECUTED AT C3.

  M-POLYC-ACTION-01   the required route's artifact class FLIPPED from
                      an OBJECT to an EXECUTABLE. The action is CAUSAL.
  M-POLYC-STATUS-02   the unknown-option message changed. The frozen
                      prediction expected the exit status to stay 1; it
                      became 0 and a negative case produced an artifact.
                      The deviation is RECORDED, not explained away.
  M-C-LEGACY-03       the G0 oracle's artifact class FLIPPED (the
                      legacy rule is LIVE) and the selector-ON output
                      was BYTE-IDENTICAL (the legacy rule is DORMANT).
  M-POLYC-POISON-04   the compiler exited 1 with "hcc: the driver
                      selected an invalid emission action (99)", produced
                      NO artifact and did NOT fall back.

GATES
  the parser suite           376/376, 0 failed
  the assertion MD5          b6f117eb1386ca80f81bc06226e2a741  (identical
                             to the C0 baseline)
  the lexer differentials    89/89, 45/45, 23/23
  the production authorities  16/16 still defined and still linked; the
                             actual delta is 0
  the generation matrix       12/12 ordered pairwise comparisons AGREE
  the negative controls       23/24 FIRE with their OWN EXACT reason
                             tokens; the one that correctly did not fire
                             is NC17, whose subject is PROVEN LIVE
  the independent witness     12/12 claims recomputed from RAW
                             artifacts, not from any verdict string
  gate-fast                   PASS
  gate-push                   PASS (build, install, gep01, aot, jit,
                             lsp, diff-check -- all seven)
  append-only                 11/11
  factory-v2-test             53/53
  F-NO-PYTHON                 the SAME 12 pre-existing path IDs, ZERO new
  F14                         ZERO deletions in evidence/ and in docs/

SCOPE
THE AUTHORIZED ROUTE, AND ONLY THE AUTHORIZED ROUTE.

  WP001_REQUIRED_ROUTE_POLYC_OWNED	YES
  WP001_WHOLE_CLI_POLYC_OWNED		NOT CLAIMED
  WP001_HISTORICAL_AC_RECONCILED	NO
  P0_COMPLETE / M1_COMPLETE / M2_COMPLETE	NO
  PRODUCTION_POLYC_AUTHORITIES_FINAL	16, with NEW_AUTHORITY_COUNT_DELTA=0

  The production semantic change is scoped to the emission-action
  decision on the required compiler-producing route. No IR, no LLVM
  backend, no language semantics. src/cli.c and src/cli.h are unchanged.

RESIDUE
DISCLOSED, NOT CONCEALED. NONE OF THESE IS SILENTLY FIXED.

  REM-PRINT-TOKENS       src/main.c, the args.print_tokens branch. The
                         -tokens flag is ABSENT on the required route,
                         so the branch is not taken there, but it remains
                         C-owned on the whole CLI.
  REM-COMPILE-TO-AST     src/main.c, the compileToAst branch. The
                         policy/fault-gate separation is not established.
                         Classified SHARED_OR_UNPROVEN and REPORTED
                         SEPARATELY, NOT waived.
  REM-O-DASH-S-GUARD     src/cli.c, the -o-/-S compatibility guard. A
                         whole-CLI C policy that the earlier global
                         inventory OMITTED. Still present, not modified.
  HD-01                  the 32 alternate-witness proofs are not
                         independently established; at least four cited
                         candidates violate the frozen phase rule.
  HD-02                  the historical nine predicate drifts are a
                         lexical screen, NOT nine proven semantic drifts.
  HD-03                  the historical 50-AC boundary-qualification
                         ledger remains UNRESOLVED. It is NOT repaired by
                         reusing this ACT's own ledger.
  RES-01 (BUILD)         the AST-UNARY and SWITCH-ARM producer rules in
                         src/CMakeLists.txt still carry the literal-quote
                         `--install-dir="..."` form that this ACT
                         repaired in the WP-001 rule. Those subjects are
                         NOT on the required route, so the defect is left
                         untouched and recorded here.
  RES-02 (COMPILER)       the production compiler prefixes its object
                         output path with "./", so an ABSOLUTE -o path
                         becomes ".//abs/path". This is a whole-CLI debt
                         and is NOT changed by this ACT; the WP-001
                         producer rule was corrected to pass a RELATIVE
                         path instead.
  RES-03 (KNOWN)         the broad LEXER07 corpus and the cross-target
                         prefix were NOT remeasured at C3 and are NOT
                         reported as an all-green run.
  RES-04 (KNOWN)         F-POLYC-TOOLS is UNAVAILABLE: its canonical
                         checker does not exist in this tree. It is not
                         claimed. This ACT's own two new tools are PolyC
                         source and introduce no shell or Python.

THE WP-001 COST, REPRICED

  WP001_ACT_IDENTITIES_CONSUMED			8
  WP001_IDENTITIES_WITH_A_FACTORY_V2_CLOSE	6
  WP001_REPRICED_ACT_IDENTITY_COST		8

  The previously reported figures 2, 3 and 5 were each a narrower slice
  of the same family, not a correction of it. None of them was the ACT
  identity cost. The full family is the parent, CORRECTION01..04, the
  boundary qualification, its correction and this ACT.

THE C4 TERMINALITY PLAN, NOT A PRE-COMMITTED SUCCESS

  The external read-only probe HAS NOT RUN YET. This ACT's close commits
  the PLAN for it, and the plan carries no PASS for an event that has
  not happened. The probe runs after the close, its receipt lives
  OUTSIDE the repository and is never backdated, and its outcome is
  whatever it actually is. A failure of the probe is an ACTUAL FAILURE:
  it is reported with the receipt and a new, independently authorized
  forward-only correction is requested. It is never recast as green.

  AC50 reads DEFERRED in the CLOSE tree. It is discharged by the
  external receipt, not by a committed forecast.

See `docs/acts/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01.md`
and `evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01/`.
