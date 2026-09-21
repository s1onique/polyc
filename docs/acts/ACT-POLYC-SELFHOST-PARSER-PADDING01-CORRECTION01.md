# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01

**Title:** HALT_FALSE_GREEN at closure ledger; bounded proof-repair of
AC18 (algebraic invariants), AC29 (generation-copy control), AC35..AC39
(lexer conservation reruns), and P1 oracle-authority contract drift.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** CORRECTION

**Predecessor:** ACT-POLYC-SELFHOST-PARSER-PADDING01 (closed at `81afe8b`)

**Status:** OPEN

---

## 1. Purpose

ACT-POLYC-SELFHOST-PARSER-PADDING01 closed with verdict
`PASS_TRUE_GREEN` at `81afe8b` on top of `b2d750b`. Independent
factory-causal review against the committed C3 evidence (not the
hand-off summary) found **three binding closure defects** and one P1
contract drift. The implementation itself is sound; the closure ledger
and one tool design are not.

This correction ACT is **bounded proof-repair only**. It does NOT
modify `BootstrapCalcPadding`, the legacy `CalcPadding` ABI, the
differential corpus, the bounded matrix, the mutation harness, the
fixed-point harness, the parser-layout corpus, or the production
authority. Per F15, F14, and the append-only invariant, no closed
evidence directory is mutated; corrections live in new commit(s).

## 2. The three binding closure defects

### P0-1 -- AC29 generation-copy control is mechanically false

ACT-POLYC-SELFHOST-PARSER-PADDING01 C3 required a real
generation-substitution negative control: replace temporary G3 with
G1, retain the G3 provenance expectation, and require rejection.

But all four legitimate objects are intentionally byte-identical (the
4-gen fixed-point theorem requires G1 and G3 to agree), so a
byte-only *equality* check **cannot** distinguish "this is G1 written
to the G3 path" from "this is the genuine G3".

Committed evidence:

```text
c3/c3-generation-copy-control.txt:
  ...
  PAIR G3_VS_MUTATED file_i=3 file_j=4 size_a=744 size_b=744 equal=YES
  PARSER_PADDING_FIXEDPOINT_RC=1 reason=mutated-equals-pristine
  PARSER_PADDING_NEGATIVE_CONTROL=FAIL reason=verifier-accepted-mutation
```

The control file **itself** records
`PARSER_PADDING_NEGATIVE_CONTROL=FAIL`. The forgery object is a
pristine G1 written to the G3 path; its SHA is the pristine SHA; the
verifier's `equal=YES` is correct; the verifier does NOT check
*provenance*; therefore the control cannot reject.

Yet `c3/mandatory-ac-status.tsv` AC29 reads:

```text
AC29  GENERATION_COPY_DETECTED=YES  PASS  forged=G1 detected rc=1
```

Direct evidence/ledger contradiction. Verdict must be:

```text
AC29 = FAIL
GENERATION_COPY_DETECTED = NO
```

The required design is **provenance**, not byte inequality. Provenance
must bind something outside the object equality -- e.g. (compiler
identity, command line, freshly-created artifact identity). A
byte-only control cannot detect a byte-identical forgery.

### P0-2 -- AC18 violated its own independence requirement

ACT-POLYC-SELFHOST-PARSER-PADDING01 C3-S48 was explicit:

> algebraic invariants must be mechanically tested and are
> **independent of simple equality with the C result**.

The hand-off asserted the opposite:

```text
invariants are proven by oracle agreement; because pc == oc,
PolyC inherits the oracle's invariants "by definition."
```

The committed AC ledger row:

```text
AC18  ALGEBRAIC_INVARIANT_FAIL=0  PASS
      witness = 16640/16640 oracle-equal -> invariants by construction
```

The stand-alone algebraic-invariant verifier was scoped out mid-C3 to
preserve phase purity (C3 would otherwise have introduced a new
tool). That decision is defensible for the lifecycle, but it
explicitly discharges AC18's authorized witness. Verdict must be:

```text
AC18 = NOT_PROVEN_AS_AUTHORIZED
```

The mathematical argument (pc == oc implies pc inherits invariants of
oc) is correct in form and the differential corpus is substantial.
But C3-S48 forbade using that argument as the AC18 witness. The
required mechanical checker is a separate, runnable tool that proves
the four invariants (size=0 implies 0; rem=0 implies 0;
0 < rem < size implies rem; non-negative output) on the 16640 inputs
WITHOUT invoking the C oracle.

### P0-3 -- AC35..AC39 not run as authorized

ACT C3-S57 required:

```text
Run canonical current conservation:
  LEXER01_CONSERVATION=PASS
  LEXER02_CONSERVATION=PASS
  LEXER03_CONSERVATION=PASS
  LEXER04_CONSERVATION=PASS
```

ACT C3-S58 required `NEW_LEXER07_FAILURES=0` against the frozen
baseline.

The hand-off substituted a by-construction argument for AC35..AC39:

```text
LEXER01_CONSERVATION=PASS (by-construction: no src/lexer.c delta)
```

The committed `c3-lexer0*-conservation.txt` files rest the entire
argument on `git diff b1aa4ab6..HEAD -- src/lexer.c tools/bootstrap
src/holyc-lib` being empty, then declare PASS without re-running the
LEXER0* corpus. The `c3-lexer07-delta.txt` file likewise declares
`NEW_LEXER07_FAILURES=0` without re-running the lexer07 corpus.

By-construction is a legitimate *scope-conservation* argument. It is
NOT a substitute for the C3-S57 / C3-S58 directive "run canonical
current conservation". Verdict must be:

```text
AC35 = NOT_EXECUTED_AS_AUTHORIZED
AC36 = NOT_EXECUTED_AS_AUTHORIZED
AC37 = NOT_EXECUTED_AS_AUTHORIZED
AC38 = NOT_EXECUTED_AS_AUTHORIZED
AC39 = NOT_EXECUTED_AS_AUTHORIZED
```

## 3. The P1 contract drift

ACT C3-S31 forbade "a second independent expected-value algorithm"
and required the oracle to "call or expose the actual legacy
CalcPadding semantics".

The committed oracle:

```c
I64 OracleCalcPadding(I64 offset, I64 size) {
  if (size == 0) return 0;
  return offset % size == 0 ? 0 : size - offset % size;
}
```

It is a *copy* of the legacy body, with two derivations:

1. The return type is widened from `int` to `I64` (ABI parity with
   the PolyC subject; defensible).
2. The implementation is duplicated, not delegated to the actual
   CalcPadding.

The duplication is semantically very likely correct (it is the
frozen legacy body, byte-for-byte modulo type widening). But the
causal chain becomes:

```text
legacy source --copied manually--> oracle
                                   ^
PolyC subject --------------------+
```

instead of:

```text
actual legacy CalcPadding --------+
                                   +- differential
PolyC BootstrapCalcPadding -------+
```

Recorded as:

```text
ORACLE_AUTHORITY_CONTRACT = CONTRACT_DRIFT
```

The fix is to expose CalcPadding through a narrow exported seam and
call it. That is a C3-S31 contract repair; it does not change the
BootstrapCalcPadding implementation or any test corpus.

## 4. What remains genuinely green

The reviewer confirmed:

```text
BOOTSTRAP_CALC_PADDING_IMPLEMENTATION   = GREEN
DIRECT_DIFFERENTIAL                    = GREEN
BOUNDED_MATRIX                         = GREEN
CAUSAL_MUTATIONS_M1_M4                 = GREEN
4GEN_OBJECT_FIXEDPOINT                 = GREEN
PRODUCTION_AUTHORITY_PRESERVED         = GREEN
PARSER_LAYOUT_CONSERVATION             = GREEN
PATCH_HYGIENE                          = GREEN
EXACT_5_COMMIT_TOPOLOGY                = GREEN
```

These are not in dispute.

## 5. Reconciliation

```text
PARSER_PADDING01_PASS_TRUE_GREEN = FALSE_GREEN
```

The closure commit `81afe8b` is immutable. The closure ledger is
honest about what was witnessed, but C3-S48 and C3-S57 / C3-S58
authorized witnesses were not produced. The implementation is sound;
the closure artifact over-claims.

This ACT does **not** re-open the production migration question. The
production authority remains `LEGACY_C` and `BootstrapCalcPadding`
has zero production references. No delegation seam was ever created.

## 6. Correction scope

This ACT is bounded to **proof-repair**. Specifically:

1. **AC18 repair.** Implement a stand-alone PolyC mechanical verifier
   (`tools/quality/parser-padding-algebraic-invariants.HC`) that
   proves the four algebraic invariants on the 16640 bounded matrix
   WITHOUT consulting the C oracle. The verifier is a NEW tool
   introduced in this correction ACT (C2 of THIS ACT), not
   retro-fitted into the closed ACT's C3. Run on the frozen 16640
   fixture; record the per-invariant pass counts.

2. **AC29 repair.** Replace the byte-equality generation-copy control
   with a **provenance** check. The negative control must:
   - record for each generation
     (compiler_path, compiler_sha256, command_line, object_path,
     object_sha256, object_size, build_mtime),
   - substitute G1 into the G3 slot, and
   - require rejection on the basis that the substitute's
     (compiler_path, build_mtime, ...) tuple does not equal the
     recorded G3 tuple -- NOT on byte inequality, since the theorem
     requires byte equality.

   The byte-equality 6/6 fixed-point check is preserved as a
   separate, non-control witness.

3. **AC35..AC39 repair.** Run the canonical LEXER01..04 conservation
   suites AND the LEXER07 broad-corpus gate against the entry head
   and the FINAL head of THIS correction ACT. Record the actual
   pass/fail counts (not a by-construction argument). The scope is
   src/lexer.c is untouched so the runs must yield identical counts
   to the frozen baseline.

4. **P1 oracle-authority repair.** Expose the actual legacy
   CalcPadding through a narrow exported seam and have the oracle
   *call* it instead of re-implementing the body. The seam is a
   pure refactor: a single `extern` declaration plus a single call
   site in `parser-padding-oracle-impl.c`. The legacy function
   signature and behavior are unchanged. ABI widening from `int` to
   `I64` stays (it is a separate ABI choice for the PolyC subject).

5. **No F5 weakening.** Every existing differential, fixed-point,
   mutation, parser-layout, and parser-test gate continues to pass.
   The new tools are additive; no predicate becomes weaker.

## 7. Scope discipline (F7)

No change to:

- `tools/bootstrap/selfhost-parser-padding.HC`
- `src/parser.c::CalcPadding` body
- the bounded matrix (`size in {1..32}`, `offset in {0..519}`)
- the named corpus
- the four causal mutations M1..M4
- the production migration plan
- the LEXER01..04 / LEXER07 corpus content

Only changes allowed by this ACT:

- `tools/quality/parser-padding-algebraic-invariants.HC` (NEW)
- `tools/quality/parser-padding-fixedpoint-verify.HC` (EDIT:
  provenance schema addition)
- `tools/quality/parser-padding-oracle-impl.c` (EDIT: call legacy
  seam)
- A narrow exported seam in `src/parser.c` if and only if needed
  for the oracle to call the actual legacy function (TBD during C1
  of this ACT; alternative is to keep the seam inside `tools/`)
- New LEXER01..04 / LEXER07 conservation runs (no source mutation)
- New evidence files under
  `evidence/.../CORRECTION01/c0..c4/`
- A new hand-off
  `HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01.md`
- A new manifest row

## 8. Acceptance gate

This ACT closes `PASS_TRUE_GREEN` only when:

```text
AC18  ALGEBRAIC_INVARIANT_FAIL=0      PASS  per-invariant witness on 16640
AC29  GENERATION_COPY_DETECTED=YES    PASS  provenance-based control
AC35  LEXER01_CONSERVATION=PASS       PASS  actual corpus rerun
AC36  LEXER02_CONSERVATION=PASS       PASS  actual corpus rerun
AC37  LEXER03_CONSERVATION=PASS       PASS  actual corpus rerun
AC38  LEXER04_CONSERVATION=PASS       PASS  actual corpus rerun
AC39  NEW_LEXER07_FAILURES=0          PASS  actual corpus rerun
ORACLE_AUTHORITY_CONTRACT = SATISFIED   (oracle calls actual legacy)

ALL PRIOR GREEN GATES STILL GREEN:
  BOOTSTRAP_CALC_PADDING_IMPLEMENTATION   = GREEN
  DIRECT_DIFFERENTIAL                    = GREEN
  BOUNDED_MATRIX                         = GREEN
  CAUSAL_MUTATIONS_M1_M4                 = GREEN
  4GEN_OBJECT_FIXEDPOINT                 = GREEN
  PRODUCTION_AUTHORITY_PRESERVED         = GREEN
  PARSER_LAYOUT_CONSERVATION             = GREEN
  PATCH_HYGIENE                          = GREEN
  EXACT_5_COMMIT_TOPOLOGY                = GREEN

FACTORY GATES:
  gate-fast                            = PASS
  factory-append-only-test             = PASS
  git diff --check (closed predecessor vs THIS head) = clean

PHASE PURITY:
  EXACT_COMMIT_COUNT_AT_CLOSE (THIS ACT) = bounded
  POST_C4_COMMIT_COUNT                  = 0
  WORKTREE_CLEAN_AT_CLOSE               = YES

TRUTHFUL TERMINAL VERDICT:
  PARSER_PADDING01_PASS_TRUE_GREEN  = TRUE_GREEN
  PARSER_PADDING_POLYC_COMPONENT    = GREEN
  PARSER_PADDING_PRODUCTION_AUTHORITY  = LEGACY_C
  PARSER_PADDING_PRODUCTION_DELEGATION = NOT_PERFORMED
```

## 9. Lifecycle plan

```text
C0 AUTH     = current commit (open ACT, freeze scope, identity)
C1 RED      = reproduce the four defects against THIS ACT's entry
C2 IMPL     = AC18 verifier, AC29 provenance schema, oracle seam
C3 VERIFY   = all AC01..AC50 PASS (with corrected AC18/29/35..39)
C4 CLOSE    = HALT_FALSE_GREEN reversal -> PASS_TRUE_GREEN
```

Commit count for THIS ACT is bounded by the five phases above; no
intermediate C2.x / C3.x commits unless a specific defect requires
one.

## 10. Out of scope for this ACT

- `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01` (production
  migration). That ACT opens only AFTER this correction closes with
  TRUE_GREEN.

- Additional parser primitives. The PARSER-SLICE-RECON01 frozen
  successor contract is unchanged.

- Lexer conservation test corpus changes. AC35..AC39 run the
  existing corpus; they do not redesign it.

## 11. Residue classification (this ACT)

```text
P0 = AC18, AC29, AC35..AC39, oracle-authority drift  (in scope)
P1 = (none yet)
P2 = AC49 / AC50 were moved into the C4 LEDGER without independent
        verification in THIS correction ACT's C1 RED. The
        predecessor ACT's AC ledger treats them as deferred-to-C4;
        C4 closure is recorded but the deferred status was not
        independently re-checked here. For this ACT's C4 we will
        re-record AC49 / AC50 with explicit observational witnesses
        (post-C4 commit count = 0; worktree clean at close = YES;
        patch hygiene check = empty).
```

The P2 item is itself a small ledger-discipline issue inherited
from the predecessor ACT. It is recorded here as residue; if it
becomes P1 it will be opened as a successor correction.

## 12. Truthful terminal statement

```text
PARSER-PADDING01 closed at 81afe8b with verdict PASS_TRUE_GREEN.
Independent review found the verdict to be FALSE_GREEN:
  AC18 was discharged by a "by construction" argument that C3-S48
  explicitly forbade.
  AC29 was satisfied by a byte-equality check that cannot reject
  the byte-identical forgery the control was designed to catch;
  the control file itself records FAIL.
  AC35..AC39 were satisfied by a by-construction argument that
  C3-S57 / C3-S58 explicitly did not authorize.

The implementation (BootstrapCalcPadding), the differential corpus,
the bounded matrix, the four mutations, the 4-gen fixed-point, and
production-authority discipline are not in dispute and remain GREEN.

This correction ACT re-opens the closure ledger only. It does not
modify production code, ABI, or corpus. It is proof-repair.
```
