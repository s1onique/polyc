# ACT-POLYC-SELFHOST-PARSER01-CORRECTION01

**ACT:** ACT-POLYC-SELFHOST-PARSER01-CORRECTION01
**Predecessor:** ACT-POLYC-SELFHOST-PARSER01 (HALT_PHASE_CORRECTION_REQUIRED)
**Selection lineage origin:** ACT-POLYC-SELFHOST-SURFACE-RECON03 (PASS_TRUE_GREEN)
**Authoritative scope origin:** ACT-POLYC-SELFHOST-PARSER01 (frozen §1–§80)

---

# 0. Lifecycle

```text
C0  AUTH / bind predecessor + inherited contract
C1  RED + live parser dependency recon
C2  IMPL
C3  VERIFY
C4  CLOSE
```

Exactly five commits.

Predecessor PARSER01 is **closed evidence** and immutable (F14). All
contract detail (surface, ABI, fixture shape, proof model, halt
taxonomy) is inherited by reference from PARSER01 §1..§80. This
CORRECTION01 ACT body is additive only — it does not duplicate the
contract text, it binds to it.

---

# 1. Binding to PARSER01

```text
INHERITED_FROM=ACT-POLYC-SELFHOST-PARSER01
INHERITED_HEAD=69a7794
INHERITED_BODY=docs/acts/ACT-POLYC-SELFHOST-PARSER01.md

SURFACE                        = INV.PARSER.COMPOUND
ATOMIC_SLICE                   = parseCompoundStatementInternal
LEGACY_AUTHORITY               = src/parser.c::parseCompoundStatementInternal
LEGACY_REGION                  = src/parser.c ~1752..2012
ABI                            = ABI 7
ABI_FUNCTION                   = BootstrapParseCompoundStatementInternal
INTENDED_LANGUAGE_DELTA        = 0
EXPECTED_MIGRATION_DELTA       = LEGACY_C_AUTHORITY -> POLYC
```

PARSER01 §3 (mission), §10 (ABI 7 contract), §37–§44 (fixture &
proof targets), §64 (acceptance criteria), §73 (commit topology),
§74 (HANDOFF), §75 (terminal predicate), §76 (HALT taxonomy),
§77 (residue not blocking) bind directly.

---

# 2. What is NEW in this correction

This correction ACT is not a re-do of PARSER01. It is the **production
execution lineage**. Concretely new:

1. **Predecessor bound to PARSER01 closed-evidence head** (not to
   SURFACE-RECON03 directly).
2. **C1 must produce a real live parser dependency recon**, not a
   re-declaration of intent. C1 produces:
   - `c1-function-shape.txt` — actual line ranges, brace counts,
     local variables, recovery points
   - `c1-dependency-map.tsv` — every Cctrl/Ast field read or
     written, with classification (`KEEP_AS_LEGACY` /
     `MIRROR_IN_POLYC` / `THREADED_ACROSS_ABI`)
   - `c1-state-read-write.tsv` — exact set of fields mutated
   - `c1-setjmp-recovery.tsv` — every longjmp target + condition
   - `c1-subordinate-parser-deps.tsv` — every callback into
     still-legacy parser functions
   - `c1-fixture-shape.tsv` — 23 fixtures, each classified by
     which of the above paths it exercises
   - **`c1-bounded-dependency-graph.tsv`** — the load-bearing
     deliverable that drives C2: explicitly enumerates whether
     the slice can be migrated with bounded PolyC ↔ C coupling
     or whether it requires migrating forbidden parser regions.
   - `c1-legacy-baseline.tsv` — frozen oracle outputs of all 23
     fixtures captured at ENTRY_HEAD with the legacy C path,
     SHA-256-pinned.
   - `c1-required-result.txt` — `BOUNDED_DEPENDENCY_GRAPH=YES`
     OR `BOUNDED_DEPENDENCY_GRAPH=NO` (the latter triggering
     HALT_DEPENDENCY_EXPLOSION per PARSER01 §76).
3. **C2 IMPL is gated by C1 verdict.** If C1 reports
   `BOUNDED_DEPENDENCY_GRAPH=NO`, the ACT halts with
   HALT_DEPENDENCY_EXPLOSION and the next ACT must reconsider
   the atomic slice. CORRECTION01 does NOT silently widen scope.
4. **Exact 5-commit topology is binding.** A sixth commit is
   HALT_PHASE_CORRECTION_REQUIRED; a "complexity" rationale is
   NOT admissible (see PARSER01 C0 closing correction, F4, F13).

---

# 3. Inherited contract (verbatim binding)

The following PARSER01 sections bind by reference. They are NOT
re-quoted here; consult PARSER01 §N directly:

```text
§1  Mission
§2  Authority scope
§3  Predecessor + entry identity
§4  Selection lineage
§5  Inventory baseline
§6  Language semantic delta target
§7  Behavioral surface
§8  Atomic slice
§9  Forbidden scope
§10 ABI 7 contract
§11 Mirror fields (deprecated; superseded by ABI 7)
§12 .. §22   ABI 7 detail / projection
§23 Production seam
§24 Four-generation requirement
§25 Component fixed point
§26 Fixedpoint verifier
§27 Generation provenance
§28 Generation-copy negative control
§29 N01 production causal negative control
§30 N01 mutation choice
§31 Negative-control success criterion
§32 N01 forged/incomplete witness control
§33 Parser bridge causal proof
§34 Semantic production outputs
§35 No fake generation output
§36 Parser-specific malformed-input proof
§37 Nested compound proof
§38 Declaration/statement boundary proof
§39 Mid-body preprocessor fixtures
§40 C2 implementation boundary
§41 C2 phase purity
§42 Direct differential target
§43 Fixedpoint target
§44 Production seam target
§45 N01 target
§46 Quality-tool authority (PolyC-only)
§47 Shell budget (≤50 LOC)
§48 F-NO-PYTHON
§49-§52 Conservation (LEXER01..04 + LEXER07)
§53 Parser-specific broad corpus
§54 F14 (closed-evidence discipline)
§55 Patch hygiene
§56-§59 C1/C2 artifacts
§60 C2 freeze
§61-§63 C3 phase and required result
§64-§69 Acceptance criteria AC01..AC43
§65 AC ledger binding
§66 Evidence truth binding
§67-§69 False-PASS / evidence-SHA mutation / AC-ID shuffle controls
§70 C4 precondition
§71 C4 scope
§72 C4 terminal measurements
§73 Commit topology
§74 C4 HANDOFF
§75 PASS_TRUE_GREEN terminal predicate
§76 HALT taxonomy
§77 Residue explicitly not blocking
§78 Expected board effect
§79 Successor selection after PARSER01
§80 Governing invariant
```

Every binding above is mechanically testable. C3 evidence must show
each required-result token from PARSER01 §63 reproduced for
CORRECTION01.

---

# 4. Inherited acceptance criteria (binding)

`mandatory-ac-status.tsv` SHALL have exactly AC01..AC43 with the
same predicates as PARSER01 §64. The ledger verifier
`parser10-ac-ledger-verify.HC` (inherited by reference from
PARSER01 §58) verifies them.

Predicates are reused verbatim:

```text
AC01  C0_AUTH_BEFORE_WORK=YES
AC02  WORKTREE_CLEAN_AT_C0=YES
AC03  LEGACY_AUTHORITY_PRESENT=YES, POLYC_PRODUCTION_AUTHORITY_PRESENT=NO  (at C1 RED)
AC04  UNCLASSIFIED_STATE_DEPENDENCIES=0
AC05  FIXTURE_TOTAL=23
AC06  FIXTURE_BASELINE_BOUND_TO_ENTRY_HEAD=YES
AC07  PARSER01_POLYC_COMPONENT_EXISTS=YES          (rename: PARSER_CORRECTION01_POLYC_COMPONENT_EXISTS)
AC08  ABI7_DEFINED=YES
AC09  ABI7_CALL_EXECUTED=YES
AC10  ABI7_LOAD_BEARING=YES
AC11  DIRECT_DIFFERENTIAL_PASS=23, DIRECT_DIFFERENTIAL_FAIL=0
AC12  G0_AUTHORITY=LEGACY_C, G1..G3_AUTHORITY=POLYC
AC13  SEMANTIC_PAIR_PASS=138, SEMANTIC_PAIR_FAIL=0
AC14  FIXEDPOINT_PAIR_PASS=6, FIXEDPOINT_PAIR_FAIL=0
AC15  PROVENANCE_ROWS=4, PROVENANCE_FAIL=0
AC16  GENERATION_COPY_DETECTED=YES
AC17  MUTATED_BUILD=PASS, MUTATED_LINK=PASS, MUTATED_EXECUTION=PASS
AC18  AFFECTED_FIXTURE_COUNT>=1
AC19  N01_OUTCOME=PASS
AC20  N01_INCOMPLETE_WITNESS_REJECTED=YES
AC21  UNCLOSED_BRACE_EQUIVALENCE=PASS
AC22  NESTED_COMPOUND_EQUIVALENCE=PASS
AC23  DECL_CALLBACK_PATH_EXERCISED=YES
AC24  STMT_CALLBACK_PATH_EXERCISED=YES
AC25  MID_BODY_PREPROC_EQUIVALENCE=PASS
AC26  PARSER10_BROAD_CORPUS_NEW_REGRESSION=0
AC27  LEXER01_CONSERVATION=PASS
AC28  LEXER02_CONSERVATION=PASS
AC29  LEXER03_CONSERVATION=PASS
AC30  LEXER04_CONSERVATION=PASS
AC31  NEW_LEXER07_FAILURES=0
AC32  TERMINAL_VERDICT_NON_POLYC_TOOL_COUNT=0
AC33  SHELL_BUDGET_VIOLATIONS=0
AC34  NEW_PYTHON_SOURCES=0, NEW_PYTHON_INVOCATIONS=0
AC35  CLOSED_EVIDENCE_DELTA=0, CLOSED_HANDOFF_DELTA=0
AC36  C2_TO_C3_IMPLEMENTATION_FROZEN=YES
AC37  C3_PHASE_PURITY=PASS
AC38  GATE_FAST=PASS
AC39  APPEND_ONLY_FAIL=0
AC40  PATCH_HYGIENE_ERRORS=0
AC41  WORKTREE_CLEAN_BEFORE_C4=YES
AC42  EXACT_COMMIT_COUNT_AT_CLOSE=5
AC43  POST_C4_COMMIT_COUNT=0
```

AC07 reads `PARSER01_POLYC_COMPONENT_EXISTS` in PARSER01 §64; in
CORRECTION01 the predicate token is renamed to
`PARSER_CORRECTION01_POLYC_COMPONENT_EXISTS=YES` and otherwise
identical. This is a permitted token-level surface rename only;
the meaning (a PolyC component is present at C2) is preserved.

---

# 5. ENTRY_HEAD / PATCH_HYGIENE_BASELINE

```text
ENTRY_HEAD                  = 69a7794 (this C0 AUTH parent)
PATCH_HYGIENE_BASELINE      = 69a7794
PRE_C0_WORKTREE_CLEAN       = YES
```

Predecessor lineage:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03   CLOSED PASS_TRUE_GREEN @ 5526813
ACT-POLYC-SELFHOST-PARSER01          HALT_PHASE_CORRECTION_REQUIRED
  cf74b49 C0 AUTH
  3443a4a C0 amendment
  69a7794 C0 closing correction
ACT-POLYC-SELFHOST-PARSER01-CORRECTION01  THIS ACT
```

---

# 6. C0 entry identity (this commit)

```text
BRANCH                      = main
ENTRY_HEAD                  = 69a7794
PATCH_HYGIENE_BASELINE      = 69a7794
WORKTREE_CLEAN_AT_C0        = YES
PREDECESSOR                 = ACT-POLYC-SELFHOST-PARSER01 (HALT_PHASE_CORRECTION_REQUIRED)
SELECTION_LINEAGE_ORIGIN    = ACT-POLYC-SELFHOST-SURFACE-RECON03
C0_AUTH_BEFORE_WORK         = YES
FACTORY_VERSION             = 2
LIFECYCLE                   = AUTHORIZATION_ARTIFACT
ACT_PHASE                   = C0-AUTH
EXACT_COMMIT_COUNT_TARGET   = 5
EXACT_COMMIT_COUNT_BINDING  = §0 of this ACT and PARSER01 §73
```

---

# 7. C1 phase — real recon

This is the load-bearing phase. C1 must produce real evidence, not
re-declarations of intent.

Required C1 evidence files (paths under
`evidence/ACT-POLYC-SELFHOST-PARSER01-CORRECTION01/c1/`):

```text
c1-entry-identity.txt
c1-red-component-absent.txt
c1-red-abi-absent.txt
c1-red-legacy-authority.txt

c1-function-shape.txt             (mandatory: actual line ranges)
c1-dependency-map.tsv             (mandatory: every Cctrl/Ast field
                                   classified KEEP_AS_LEGACY /
                                   MIRROR_IN_POLYC / THREADED_ACROSS_ABI)
c1-state-read-write.tsv           (mandatory: every field mutated)
c1-setjmp-recovery.tsv            (mandatory: longjmp targets + conditions)
c1-subordinate-parser-deps.tsv    (mandatory: callbacks to still-legacy
                                   parser functions, with name + line)

c1-fixture-shape.tsv              (mandatory: 23 fixtures, each
                                   classified by which paths it
                                   exercises)
c1-legacy-baseline.tsv            (mandatory: 23-fixture frozen
                                   oracle outputs at ENTRY_HEAD,
                                   SHA-256-pinned)

c1-bounded-dependency-graph.tsv   (LOAD-BEARING DELIVERABLE:
                                   enumerates whether the slice can
                                   be migrated with bounded
                                   PolyC ↔ C coupling; required
                                   to drive C2)
c1-required-result.txt            (BOUNDED_DEPENDENCY_GRAPH=YES or NO)

c1-proof-contract.tsv
c1-negative-control-contract.txt
c1-authorized-ac-contract.tsv
```

C1 required result:

```text
COMPONENT_PRESENT=NO
ABI7_PRESENT=NO
LEGACY_AUTHORITY_PRESENT=YES
POLYC_PRODUCTION_AUTHORITY_PRESENT=NO

FUNCTION_SHAPE_VERIFIED_BY_READ=YES
DEPENDENCY_MAP_ROWS=<matches actual line reads>
SETJMP_RECOVERY_TARGETS_IDENTIFIED=<int>
SUBORDINATE_PARSER_DEPS_IDENTIFIED=<int>

UNCLASSIFIED_STATE_DEPENDENCIES=0

FIXTURE_TOTAL=23
FIXTURE_BASELINE_BOUND_TO_ENTRY_HEAD=YES

N01_CONTRACT_DEFINED=YES

PRODUCTION_SOURCE_DELTA=0

BOUNDED_DEPENDENCY_GRAPH=<YES|NO>
```

If `BOUNDED_DEPENDENCY_GRAPH=NO`:

```text
HALT_DEPENDENCY_EXPLOSION
```

If `BOUNDED_DEPENDENCY_GRAPH=YES`:

proceed to C2 IMPL.

---

# 8. C2..C4 (binding to PARSER01 §40..§72)

C2 IMPL, C3 VERIFY, C4 CLOSE follow PARSER01 §40..§72 with no
weakening. CORRECTION01 evidence directories
(`evidence/ACT-POLYC-SELFHOST-PARSER01-CORRECTION01/{c2,c3,c4}/`)
replace PARSER01 directories.

---

# 9. Halt taxonomy

PARSER01 §76 binds in full. Added for CORRECTION01:

```text
HALT_BOUNDED_DEPENDENCY_GRAPH=NO
HALT_SUBORDINATE_PARSER_REQUIRES_MIGRATION
HALT_SETJMP_RECOVERY_ABI_INCOMPATIBLE
```

These three trigger when C1 produces direct evidence that the
slice cannot be migrated with bounded PolyC ↔ C coupling. They
are successful C1 outcomes (per F4), and the next ACT must
reconsider the atomic parser slice.

---

# 10. Board effect

Before C0:

```text
ACT-POLYC-SELFHOST-PARSER01          HALT_PHASE_CORRECTION_REQUIRED
INV.PARSER.COMPOUND                  LEGACY_C_AUTHORITY
```

After C0 AUTH (this commit):

```text
ACT-POLYC-SELFHOST-PARSER01-CORRECTION01  C0-AUTH COMPLETE
INV.PARSER.COMPOUND                       LEGACY_C_AUTHORITY
```

After PASS TRUE_GREEN (C4):

```text
ACT-POLYC-SELFHOST-PARSER01-CORRECTION01  CLOSED PASS_TRUE_GREEN
INV.PARSER.COMPOUND                       SELFHOSTED_TRUE_GREEN
BootstrapParseCompoundStatementInternal  PRODUCTION_AUTHORITATIVE
PARSER_SELFHOST_COMPONENT_COUNT          += 1
```
