# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE08

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE08`
**Class:** SELFHOST / PARSER / STRUCTURAL-BOUNDARY / PRODUCTION-AUTHORITY-TRANSFER
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07`
(closed, `ACT-Verdict: PASS`)

VERDICT

PASS

---

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. The outcome, in short

**One legacy-C parser decision has been migrated to production-
authoritative compiled PolyC: the default-arm termination decision.**

```text
SELECTED_CANDIDATE_ID   = SUB-002
SELECTED_CLASS          = STRUCTURAL
SELECTED_DECISION       = DEFAULT_ARM_TERMINATION
SELECTED_SOURCE_FILE    = src/parser.c
SELECTED_SOURCE_RANGE   = 1683..1684
SELECTED_SOURCE_SHA256  = a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199
SELECTED_ABI            = I64 ast_kind -> I64 terminate
SELECTED_POLYC_SYMBOL   = BootstrapDefaultArmTerminates
SELECTED_SELECTOR       = HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES
DEFAULT_ARM_TERMINATION_AUTHORITY = POLYC
LEGACY_DEFAULT_ARM_C_AUTHORITY    = RETIRED
CURRENT_POLYC_PARSER_AUTHORITIES  = 8
PRODUCTION_SEMANTIC_DELTA          = 1
```

**Exactly one production decision changed.**  The default-arm loop,
the `parseStatement(cc)` call, the `listAppend` host AST write, the
token cursor, the scope state, the recovery state and the diagnostics
are all unchanged.

---

## 2. The exported symbol and the seam

The new component is `tools/bootstrap/selfhost-parser-slice08.HC`.  It
exports EXACTLY ONE global text symbol:

```text
_BootstrapDefaultArmTerminates
```

and implements the ENTIRE five-kind rule of the legacy condition:

```text
AST_COMPOUND_STMT 274   AST_CASE 287   AST_BREAK 280
AST_RETURN 270           AST_GOTO 258
```

Every other value -- including `AST_DEFAULT` 293 and every out-of-enum
probe -- does not terminate the arm.  The component is TOTAL over the
whole I64 domain, has NO range check (the legacy condition has none
either), and reads NOTHING except its scalar argument: no host AST
pointer, no allocation, no global mutable state, no callback, no
recovery dependency, no host string.

The C side keeps everything else.  The adapter
`parseDefaultArmTerminates(int kind)` owns ONLY the two mechanical
duties the original C ABI requires -- the argument projection
(`int kind -> I64 ast_kind`) and the result conversion (`I64 -> the
legacy boolean`).

---

## 3. Why this is a DISTINCT authority, not the SUB-001 one

SUB-002 shares a five-kind membership SHAPE with the already-migrated
SUB-001, but the two decisions are NOT interchangeable:

| | SUB-001 (case arm) | SUB-002 (default arm) |
|---|---|---|
| symbol | `BootstrapSwitchArmTerminates` | `BootstrapDefaultArmTerminates` |
| source | `tools/bootstrap/selfhost-parser-slice06.HC` | `tools/bootstrap/selfhost-parser-slice08.HC` |
| site | `_parseCaseLabel` | `_parseDefaultStatement` |
| terminating kinds | SIX, including `AST_DEFAULT` 293 | FIVE, EXCLUDING `AST_DEFAULT` 293 |

The distinction is not asserted; it is **proved by execution**.  The
C0 RED-5 experiment linked the REAL compiled SUB-001 PolyC object and
evaluated it over the frozen 41-kind domain: it answers `1` for kind
293, where the frozen SUB-002 fixture requires `0` at row 35.  Each
subject defines ONLY its own symbol.

---

## 4. The object-level authority proof

Inside `_parseDefaultStatement` in the PRODUCTION parser object:

```text
ldrsw x0, [x21]      the scalar projection of stmt->kind
bl   <reloc>        the call to _BootstrapDefaultArmTerminates
cbnz w0, <branch>   the branch ON THE POLYC RETURN VALUE
```

and the `0x2041` five-kind bitset mask appears **ZERO times in the
whole production parser object**.  The legacy C predicate is not
merely inactive: it is ABSENT.  There is no parallel C authority and
no decorative leftover.

The function-scoped attribution is MANDATORY and was performed.  In
the selector-OFF object the SAME mask appears in FOUR functions --
`_ParserLegacyDefaultArmTerminatesOracle`, `_parseDefaultStatement`,
`_ParserLegacySwitchArmTerminatesOracle` and `_parseCaseLabel` -- and
the attribution separates the SUB-002 site from the SUB-001 site.  A
whole-object mask count would have misattributed the SUB-002 evidence.

---

## 5. The real object producer and the fail-closed discipline

```text
SUBJECT SOURCE = tools/bootstrap/selfhost-parser-slice08.HC
SUBJECT OBJECT = build/parser-default-arm-subject.o
PRODUCER       = build/host-stage0/hcc (the stage0 legacy control)
```

The subject is produced by the STAGE0 compiler, so the component does
not depend on the production compiler it is about to serve.

Three fail-closed configurations were built and observed:

| Configuration | Result |
|---|---|
| selector ON, subject MISSING, no producer | CONFIGURE_EXIT=1 |
| selector ON, subject defines the WRONG symbol | the verifier refuses to link, Error 1 |
| selector ON, subject is an EMPTY object | the verifier refuses to link, Error 1 |

The selector-OFF mode is a real C-authoritative production
translation unit: the OFF build has ZERO SUB-002 PolyC symbols and its
parser object DOES carry the legacy `0x2041` mask.

---

## 6. The four generations and the 41-row differential

| Gen | Subject | Producer | Producer SHA-256 |
|---|---|---|---|
| G0 | the REAL production `src/parser.c`, selector OFF | `cc` | `9b11ead1ca76a03d61108ad5bf2c913d6aa8daa7deb9fd28893e847e3680e5e7` |
| G1 | the NEW PolyC component | `build/host-stage0/hcc` | `302e9f3336397717f4fa4257d6147d07dd7c4b7ef967bf8455151bc43e3e1bae` |
| G2 | the NEW PolyC component | `./hcc` | `69beebd00b3d3e9b38f9375275af8f89da05092a323e1835f386c3c4b39d5dea` |
| G3 | the NEW PolyC component | `build/hcc-bootstrap02` | `a1c9b8d6d21d4fa725255aa5b22ec79c5d618f1baa796a0e227bb430f824dd01` |

The three producer binaries are PAIRWISE DISTINCT executables.  The
three PolyC OBJECTS are byte-identical
(`d72cee87ccff4b5c1b801c5d1420d5267809e9214526720800010ff591cba22b`), which
the frozen contract explicitly permits and requires to be explained:
the identity difference is not material because each generation was
BUILT BY ITS OWN producer from the same source, and the component is
a pure function of one scalar.  The producer identity, not the object
identity, is what makes the generations independent.  The G0 object
DIFFERS from all three, because G0 is the C TRANSLATION UNIT.

```text
G0 / G1 / G2 / G3   41/41 PASS, zero on every mismatch counter
ALL 12 ORDERED PAIRS  41 row IDs compared, 0 value mismatches, 12/12
```

The G0 object is byte-identical to the RECON07 G0 object
(`8737313a547f20b507f4841af4056b3e9c1a51850076e01c121e5c7f3126959c`), which
is a STRONGER result than the frozen contract required: the factoring
of the decision into the helper introduced ZERO compiled difference in
the C authority.

---

## 7. The three-state causal witness

The witness is the one frozen by RECON07: a compound statement in the
default arm followed by a reachable statement.  The channel is
`COMPILED_PROGRAM_SEMANTIC_OUTPUT_CHANGED` and it was declared BEFORE
the mutation.

```text
PRISTINE  WITNESS_OUTPUT=110 155
MUTANT    WITNESS_OUTPUT=110 177
RESTORED  WITNESS_OUTPUT=110 155
```

The **POST-POLYC-MUTANT** experiment is a NEW experiment on the
POST-MIGRATION subject: the mutation is in the COMPILED POLYC
COMPONENT, executed in a detached worktree, and the authoritative main
checkout was never modified.

```text
EXECUTION_ID = RECON07-SUB-002-POST-POLYC-MUTANT
MUT_BUILD_EXIT = 0
mutant subject object  42cd7950... != pristine d72cee87...  (NOT dormant)
mutant fixture row      16, kind 274  (the ONLY row that changed)
restored source         57e8f5b0... == pristine 57e8f5b0... (byte-identical)
restored object         d72cee87... == pristine d72cee87... (byte-identical)
```

The three exits -- the compiler build, the witness compile and the
witness run -- are recorded SEPARATELY.  The mutant worktree was
disposed.

The **PRE-C-MUTANT** control is **CITED** as a RECON07 prior event and
was NOT re-run.  Its subject file, phase, selector state and execution
ID are all disjoint from the SLICE08 post-migration event, so it
cannot be credited as that event.

The **conditional C-OFF C-mutant** control is **NOT REQUIRED**: the
frozen clause was quoted and bound, and the frozen successor contract
places the mutation obligation on the NEW PolyC subject, not on a C
mutant.  It is recorded as NOT REQUIRED, a distinct and honest
disposition, not as a silent skip.



---

## 8. The negative controls

```text
INHERITED CONTROLS  23  (20 from RECON07 selected-negative-controls.md
                         plus 3 from selected-causal-contract.md)
NEW S8 CONTROLS      18  (5 fixture, 5 subject-authority, 5 provenance,
                         3 causality)
VACUOUS               0
DOUBLE-DISCHARGE      0
WRONG SUBJECT         0
```

The inherited controls were executed with their UNCHANGED ids and
subjects against the **unmodified** canonical PolyC checkers, whose
SHA-256 digests are recorded in `c3/inherited-controls-join.tsv`.

Four control ids -- `SL-CC-05`, `RECON07-SUB-002-POST-POLYC-MUTANT`,
`S8-CC-01` and `S8-SA-05` -- **share one physical experiment**, and
that sharing is stated EXPLICITLY with the shared execution ID.  They
are NOT counted as four independent experiments.

---

## 9. The conservation

```text
PARSER_ASSERTIONS=376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
  (identical to the C0 baseline and to the frozen historical identity)
LEXER07_DIRECT_DIFFERENTIAL=89/89
LEXER08_DIRECT_DIFFERENTIAL=45/45
LEXER09_DIRECT_DIFFERENTIAL=23/23
LEXER07_BROAD_STATUS=FAIL_KNOWN_BASELINE, exactly 15 identities,
  MD5 7ee761440de83552e751e3c3976c1683 (byte-identical set)
CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX, exactly 67
F_NO_PYTHON=FAIL_KNOWN_BASELINE, exactly 12, zero new
F_POLYC_TOOLS=UNAVAILABLE (the checker is NOT landed)
GATE_FAST=PASS   GATE_PUSH=PASS   APPEND_ONLY=PASS (11/11)
```

**Every historical nonzero status is preserved honestly.**  Nothing was
relabelled PASS.

---

## 10. The immutable predecessors

```text
FROZEN_PREDECESSOR_PATHS=5201, all byte-identical
LIVE_FREEZE_PATHS=5202, 0 missing
RECON07 contract artifacts unchanged (21 of 21)
RECON06 governance HALT preserved exactly
HISTORICAL_ARTIFACTS_MODIFIED=0
```

---

## 11. The acceptance criteria

```text
MANDATORY_AC_TOTAL   = 50
MANDATORY_AC_PASS    = 49   (AC01..AC49)
MANDATORY_AC_DEFERRED_TO_CLOSE = 1  (AC50 only)
MANDATORY_AC_FAIL    = 0
MANDATORY_AC_UNPROVEN= 0
```

AC50 is discharged ONLY by the external, read-only, post-CLOSE
terminality observation, which lives OUTSIDE the tracked terminal
commit.  It is not claimed here.

---

## 12. The residue, carried forward honestly

These are historical conditions, unchanged by this ACT, and NOT
regressions:

```text
the 15 LEXER07 broad-corpus failures
the 67 cross-target missing-prefix failures
the 12 F-NO-PYTHON violations
the unlanded F-POLYC-TOOLS checker
the shared /tmp/holyc-asm.s collision
the SLICE06 stale CMake --install-dir producer wiring
```

**The eighth authority is eight DECISION SITES, not eight component
FILES.**  The eight authorities are distinct production decision
sites; they are implemented by eight distinct PolyC components, one
per migrated decision.

**No successor is preselected.**  This ACT does NOT authorise a
SLICE09, and it does NOT preselect the next candidate.  The canonical
fallback in the frozen RECON07 contract is SUB-004, and a successor
that takes it MUST run its own causal feasibility experiment.

---

## 13. The evidence tree

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/
  c0/  entry-identity.txt predecessor-close-verification.txt
       predecessor-freeze.tsv selected-contract-bindings.tsv
       selected-contract-hashes-verification.tsv
       mandatory-ac-contract.tsv inherited-controls-contract.tsv
       new-controls-contract.tsv seven-production-authorities.tsv
       baseline-parser.txt baseline-lexer.txt baseline-lexer07.txt
       baseline-cross-target.txt baseline-tool-policy.txt
       baseline-gates.txt red-reproduction.txt
  c1/  selected-source-and-abi.txt c-only-g0-production-object.txt
       live-enums-and-rule.tsv source-bound-fixture.tsv
       source-bound-fixture-summary.tsv
       independent-fixture-verification.txt
       witness-and-observation-contract.txt
       stage-compiler-provenance-plan.tsv build-prerequisite-preflight.txt
  c2/  production-source-delta.txt polyc-subject-source-and-symbol.txt
       selector-and-build-graph.txt effective-cmake-and-make-commands.txt
       production-function-disassembly.txt object-import-export-linkage.txt
       fixture-first-green.txt seven-authorities-conservation.tsv
       provider-fail-closed.txt
  c3/  generation-provenance.tsv g0-g3-41-row-differential.tsv
       all-12-ordered-pairs.tsv independent-live-enum-recompute.txt
       inherited-controls-join.tsv new-controls-join.tsv
       pre-c-mutant-citation.txt post-polyc-mutation-and-restoration.txt
       conditional-c-off-mutation.txt function-scoped-authority-audit.txt
       producer-build-graph-audit.txt parser-conservation.txt
       lexer-direct-conservation.txt lexer07-failure-identities.txt
       cross-target-and-tool-policy.txt gate-fast.txt gate-push.txt
       factory-invariants.txt immutable-predecessor-check.txt
       mandatory-ac-status.tsv
  c4/  terminality-plan.txt
```
