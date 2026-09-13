# ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01

**Title:** C1 contract correction — replace `IDENTIFIER_GRAMMAR_EQUIVALENT` predicate (over-constrained: required `B0 == production`) with `IDENTIFIER_GRAMMAR_GATE = PASS` (correctly captures `production frozen ∧ B0 preserved ∧ B1 == production`); bound the `ctype` non-ASCII equivalence claim; tighten the oracle's evidentiary role

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP02` C1 RED (commits `aa29e16`, `db038e9`); ACT-POLYC-BOOTSTRAP01-CORRECTION01 (B0 closure)

**Class:** GOVERNANCE / DOC-STRUCTURE / CONTRACT-CORRECTION

**Production compiler semantic changes:** **FORBIDDEN** (no `src/lexer.c` mutation in this correction ACT)

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN** (already frozen by §12 of predecessor ACT)

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE` (C1 evidence and C2 authorization)

---

# 0. Mission

Reviewer audit of `ACT-POLYC-BOOTSTRAP02` C1 RED packet
identified three defects in the C1 contract and
supporting evidence:

- **P0** — `c1-required-result.txt` declares
  `IDENTIFIER_GRAMMAR_EQUIVALENT = YES` and asserts the
  corrected ACT §5's halt condition is `NOT_FIRED`. The
  original §5 explicitly required `B0 == production` and
  fired `HALT_B1_IDENTIFIER_CONTRACT_MISMATCH` when they
  differed. The C1 evidence correctly proves that
  `B0 != production` (production admits `$` in
  continuation, B0 does not). The agent retroactively
  reinterpreted `IDENTIFIER_GRAMMAR_EQUIVALENT` to mean
  `B1 == production`, which is a different predicate and
  not what the original ACT wrote.

- **P1** — `identifier-contract.txt` claims the production
  scanner's `<ctype.h>` usage is "ASCII-clean" because
  `isalpha(c)` is FALSE for `c >= 0x80`. This is only
  reliably true in the `"C"` locale; the production
  scanner does NOT set locale, but its `ctype` calls
  operate on plain `char` (signed on most platforms),
  and the standalone oracle deliberately normalizes
  through `unsigned char`. The two are NOT byte-equivalent
  for bytes `>= 0x80`.

- **P2** — `legacy-ident-oracle.tsv` describes
  `bootstrap02-ident-oracle.c` as a "verbatim C99
  transcription" of `src/lexer.c:873-885`. It is an
  *independent reference model* of the selected production
  algorithm, adapted from `Lexer` state + NUL sentinel +
  `lexNextChar`/`lexRewindChar` to
  `(src, src_len, start, out_end)`. The adaptation is
  mechanically faithful but not literally equivalent
  (e.g. cursor/file-state behaviour is not exercised).

This correction ACT records, repairs, and re-classifies
all three defects in a single bounded pass. The
substantive B1 technical direction (PolyC component
implementing production grammar, separate from B0) is
preserved. No `src/lexer.c` mutation occurs.

# 1. Authoritative defect enumeration

## DEFECT-P0 (P0): malformed C1 grammar prerequisite

The original `ACT-POLYC-BOOTSTRAP02` §5 stated:

```text
If production grammar is broader or narrower:
  HALT_B1_IDENTIFIER_CONTRACT_MISMATCH
  HALT_CLASS: DEPENDENCY
  BLOCKS_NEXT: YES
```

The C1 evidence correctly proved:

```text
CONTRACT_EQUIVALENT  = NO   (production grammar is BROADER)
CONTRACT_SUPERSET    = YES  (production accepts everything b0 accepts,
                             plus $ in continuation)
```

Yet `c1-required-result.txt` declared:

```text
IDENTIFIER_GRAMMAR_EQUIVALENT = YES (at production seam;
                                     B1 grammar == production grammar
                                     by ACT §3 design)
```

This retroactively reinterprets `EQUIVALENT` from
`B0 == production` (the original meaning) to
`B1 == production` (a different predicate). The
reinterpretation is *architecturally sound* (B1 should
match production, not B0), but it is not what the
original ACT wrote.

## DEFECT-P1 (P1): `ctype` non-ASCII equivalence over-claim

The current `identifier-contract.txt` says:

```text
isalpha(c) is FALSE for '$' and for any byte >= 0x80.
isalnum is likewise locale-clean for our subset.
```

This is only reliably true under the `"C"` locale.
`<ctype.h>` `isalpha` / `isalnum` are
**locale-sensitive** and **undefined behaviour when
called with a negative plain `char` value** that has
not been converted to `unsigned char`. The production
scanner at `src/lexer.c:873-885` passes `char` (signed
on most platforms) directly to `isalnum` and `isalpha`,
while the standalone oracle at
`tools/quality/bootstrap02-ident-oracle.c` normalizes
through `unsigned char`. The two are NOT byte-equivalent
for bytes `>= 0x80` if `char` is signed.

For the current ASCII fixture corpus this changes
nothing, but the C1 wording "verbatim", "byte-exact",
"exact production semantics" is too strong.

## DEFECT-P2 (P2): oracle terminology over-claim

`legacy-ident-oracle.tsv` describes
`bootstrap02-ident-oracle.c` as:

```text
verbatim C99 transcription of src/lexer.c:873-885
algorithm reproduction is byte-exact
```

The oracle adapts the production algorithm from:

```text
Lexer state + NUL sentinel + lexNextChar()/lexRewindChar()
```

to:

```text
src + src_len + start + out_end
```

The adaptation is mechanically faithful but does not
exercise:

- `Lexer` cursor / file-state semantics
- multi-line lexing
- EOF behaviour distinct from NUL sentinel
- `lexRewindChar` interactions with prior tokens

The oracle is therefore a **reference model** of the
selected production algorithm, not a direct production
execution. This distinction matters for C3, where the
stage0/stage1 compiler corpus is the primary
production-equivalence witness; the oracle alone is
not sufficient.

# 2. Corrected C1 → C2 gate (binding)

The original `IDENTIFIER_GRAMMAR_EQUIVALENT = YES`
predicate is **removed** and replaced by the corrected
gate:

```text
IDENTIFIER_GRAMMAR_GATE = PASS iff:
  PRODUCTION_GRAMMAR_FROZEN             = YES
  B0_GRAMMAR_PRESERVED                  = YES
  B0_VS_PRODUCTION_DIFFERENCE           = DOCUMENTED
  B1_REQUIRED_GRAMMAR_EQUALS_PRODUCTION = YES
```

None of these four conditions fires here:

- `PRODUCTION_GRAMMAR_FROZEN = YES`
  (proved by `c1/identifier-contract.txt`)
- `B0_GRAMMAR_PRESERVED = YES`
  (B0 file unchanged across the C1 RED commit;
  15/15 fixture conservation preserved;
  §12 of original ACT forbids changing B0)
- `B0_VS_PRODUCTION_DIFFERENCE = DOCUMENTED`
  (one extra byte `$` in continuation; production
  sources such as `_opendir$INODE64` use it)
- `B1_REQUIRED_GRAMMAR_EQUALS_PRODUCTION = YES`
  (B1 component is `bootstrap02-ident.HC`, deliberately
  separate from B0; ACT §3 design specifies production
  grammar for B1)

Therefore:

```text
IDENTIFIER_GRAMMAR_GATE                = PASS
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH   = NOT_FIRED
   (corrected predicate evaluates to NOT_FIRED;
    production grammar is mechanically frozen;
    B1 grammar can preserve production semantics;
    satisfying production semantics does not require
    changing B0)
```

# 3. Corrected HALT_B1_IDENTIFIER_CONTRACT_MISMATCH predicate

The original §5 clause:

```text
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH fires iff:
  production grammar is broader or narrower than B0 grammar
```

is replaced by:

```text
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH fires iff:
  production grammar cannot be mechanically frozen
  OR
  proposed B1 grammar cannot preserve production semantics
  OR
  satisfying production semantics would require changing B0
```

None of these three conditions is true in the
predecessor C1 state; the corrected halt clause
evaluates to NOT_FIRED.

# 4. Bounded `ctype` claim

The corrected `identifier-contract.txt` declares:

```text
B1_IDENTIFIER_CHARACTER_DOMAIN = ASCII

B1_IDENT_START =
  A-Z | a-z | _

B1_IDENT_REST =
  A-Z | a-z | 0-9 | _ | $

NON_ASCII_PRODUCTION_CTYPE_BEHAVIOR =
  NOT_CLAIMED_EQUIVALENT

RATIONALE =
  current production uses locale-sensitive ctype on plain char;
  B1 freezes only the mechanically exercised ASCII language;
  C3 must use explicit comparisons in bootstrap02-ident.HC
  rather than reproducing host ctype() semantics
```

The B1 component (`bootstrap02-ident.HC`) is required
to implement the ASCII identifier contract above using
**explicit byte comparisons** (e.g. `if (c >= 'A' && c <= 'Z')`)
rather than calling `isalpha` / `isalnum`. This is
explicitly required so that:

1. B1 semantics are deterministic across hosts and
   locales.
2. Non-ASCII production behaviour is not silently
   inherited.
3. The B1 component matches the corrected `ctype`
   claim boundary.

# 5. Tightened oracle evidentiary role

`tools/quality/bootstrap02-ident-oracle.c` is
re-classified as:

```text
EVIDENTIARY_ROLE        = REFERENCE_MODEL
EVIDENCE_TYPE           = independent C99 model of the
                          selected production algorithm
DIRECT_PRODUCTION_EXECUTION = NO
BYTE_EQUIVALENCE_PRODUCTION = NO  (Lexer state adapted;
                                   ctype calls adapted)
MECHANICAL_FAITHFULNESS     = YES (algorithm reproduction
                                    is faithful for the
                                    ASCII fixture corpus)
```

The oracle's role in C3 is bounded:

- It validates the B1 component's *algorithm* against a
  faithful C99 model.
- It does NOT substitute for the stage0/stage1 compiler
  corpus, which exercises real production `Lexer`
  state.
- The C3 required-result block must include a direct
  differential against the stage1 binary on a real
  source corpus (e.g. `src/holyc-lib/dir.HC`).

# 6. Conservation: what C1 still proves (reviewer-preserved)

```text
AC01  Actual production identifier seam is mapped.   PASS
AC02  Production identifier grammar is mechanically
      frozen (ASCII subset only).                    PASS
AC03  B0 vs production grammar comparison documented.PASS
AC04  Reference-model oracle captured.                PASS
      (re-classified: REFERENCE_MODEL, not verbatim)
AC05  Cross-language C↔PolyC ABI witness passes.      PASS
AC06  B1 does not require B0 LLVM path.               PASS
AC07  B1 does not require GEP01 harness.              PASS
AC08  Entry conservation baseline captured.           PASS

STAGE0_IDENTIFIER_SELF_HOSTED                NO
STAGE1_ARTIFACT_EXISTS                       NO
B1_DELEGATIONS                               0
PRODUCTION_GRAMMAR_FROZEN                    YES
B0_GRAMMAR_PRESERVED                         YES
B0_VS_PRODUCTION_DIFFERENCE                  DOCUMENTED
B1_REQUIRED_GRAMMAR_EQUALS_PRODUCTION        YES
IDENTIFIER_GRAMMAR_GATE                      PASS
```

# 7. Authorized file scope (§25)

```text
docs/acts/ACT-POLYC-BOOTSTRAP02.md                    (created)
docs/acts/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01.md   (created)

evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/
  README.md
  defect-classification.txt
  corrected-grammar-gate.txt
  corrected-ctype-claim.txt
  corrected-oracle-role.txt
  required-result.txt
```

And in-place rewrites of the predecessor C1 evidence:

```text
evidence/ACT-POLYC-BOOTSTRAP02/c1/README.md
evidence/ACT-POLYC-BOOTSTRAP02/c1/identifier-contract.txt
evidence/ACT-POLYC-BOOTSTRAP02/c1/legacy-ident-oracle.tsv
evidence/ACT-POLYC-BOOTSTRAP02/c1/c1-required-result.txt
```

No `src/lexer.c`, `src/lexer.h`, `src/CMakeLists.txt`,
`Makefile`, `tools/bootstrap/bootstrap02-ident.HC`, or
`src/lexer_bridge.h` mutation.

# 8. Required C2/C3/C4 implementation (forward-bound)

After this correction closes:

- C2 IMPL must implement `tools/bootstrap/bootstrap02-ident.HC`
  using **explicit byte comparisons** (no `ctype.h`).
  The B1 component's identifier contract is now
  explicitly ASCII-only and locale-independent.
- C2 IMPL must add `src/lexer_bridge.h` declaring
  `BootstrapScanIdent`.
- C2 IMPL must modify `src/lexer.c::lexIdentifier` to
  delegate to `BootstrapScanIdent`. No fallback.
- C3 EVIDENCE must include a stage0/stage1 differential
  on a real production source corpus (e.g.
  `src/holyc-lib/dir.HC`, which uses `_opendir$INODE64`)
  in addition to the 15-fixture differential.
- C4 CLOSE records `B1_ASCII_DOMAIN = YES`,
  `B1_NON_ASCII_EQUIVALENCE = NOT_CLAIMED`,
  `B1_REFERENCE_MODEL_ORACLE = tools/quality/bootstrap02-ident-oracle.c`.

# 9. Required C2 implementation in this correction ACT

- create `docs/acts/ACT-POLYC-BOOTSTRAP02.md` (done)
- create this correction ACT (done)
- create `evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/`
- rewrite `evidence/ACT-POLYC-BOOTSTRAP02/c1/README.md`
- rewrite `evidence/ACT-POLYC-BOOTSTRAP02/c1/identifier-contract.txt`
- rewrite `evidence/ACT-POLYC-BOOTSTRAP02/c1/legacy-ident-oracle.tsv`
- rewrite `evidence/ACT-POLYC-BOOTSTRAP02/c1/c1-required-result.txt`
- 1 commit per file group, plus 1 CLOSE commit

# 10. Required C3 evidence in this correction ACT

- post-fix `git diff --check <entry>..HEAD` (rc=0)
- post-fix `make bootstrap01-test` (15/15 PASS preserved)
- post-fix `gate-fast` PASS
- post-fix `factory-v2` PASS
- post-fix `factory-append-only-test` PASS
- post-fix `factory-halt-classification-test` PASS
- post-fix `shell-loc-gate` PASS

# 11. Required C4 closure in this correction ACT

- closure-summary.txt with corrected verdict
- residue.txt (P0/P1/P2)
- roadmap-transition.txt: no `docs/ROADMAP.md` change
  (B0 GREEN unchanged; B1 still mid-ACT; correction is
  in-flight governance)
- HANDOFF.md
- single CLOSE commit on
  `ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01`
- cardinality-1 verified

# 12. HALT taxonomy (this correction ACT)

```text
HALT_RED_NOT_REPRODUCED                  — n/a (governance)
HALT_SCOPE_EXPANSION_REQUIRED            — n/a (bounded)
HALT_MEMORY01_WIDENING_REQUIRED          — NOT AUTHORIZED
HALT_LLVM_VERIFY_REQUIRED                — NOT AUTHORIZED
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH     — corrected (this ACT)
HALT_B1_ABI_PROBE_FAILED                 — n/a (no ABI change)
HALT_B1_MEMORY01_DEPENDENCY              — n/a (no dependency change)
HALT_B1_GEP01_DEPENDENCY                 — n/a (no dependency change)
HALT_B0_REGRESSION                       — verified NOT FIRED
                                            (15/15 conservation)
HALT_B1_DELEGATION_FAIL                  — n/a (no delegation yet)
```

# 13. Authoritative corrected C1 verdict

```text
ACT-Verdict                       = PASS_WITH_CORRECTION_RESIDUE
B0_CONSERVATION                   = PASS   15/15
PRODUCTION_GRAMMAR_FROZEN         = YES
B0_GRAMMAR_PRESERVED              = YES
B0_VS_PRODUCTION_DIFFERENCE       = DOCUMENTED
B1_REQUIRED_GRAMMAR_EQUALS_PROD   = YES
B1_ASCII_DOMAIN                   = YES
B1_NON_ASCII_EQUIVALENCE          = NOT_CLAIMED
B1_REFERENCE_MODEL_ORACLE         = tools/quality/bootstrap02-ident-oracle.c
B1_REFERENCE_MODEL_BYTE_EQUIVALENT = NO  (Lexer state adapted;
                                          ctype calls adapted)
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH = NOT_FIRED
IDENTIFIER_GRAMMAR_GATE              = PASS
C1_RED_TO_C2_IMPL_GATE               = OPEN
PUSH_PERMISSION                      = NOT_PERFORMED
PUSH_RESIDUE                         = GEP01_D1_D2 (pre-existing)
```

# 14. Commit topology

```text
C1 RED   — 1+ commit(s), opens the correction ACT
C2 IMPL  — N commits (governance/evidence rewrites only)
C3 EVID  — 1 commit, all gates
C4 CLOSE — 1 commit, single CLOSE for
           ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01
```

Cardinality-1 invariant verified at C4 with:

```text
git log --all-match --oneline \
    --grep='^ACT: ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01$' \
    --grep='^ACT-Phase: CLOSE$'
```

returning exactly 1 commit.

# 15. No SHA-of-self claims (DOCTRINE.md §22)

No closure artifact committed in this ACT may claim the
SHA of the commit that contains it.

# 16. Push policy

Push is NOT performed by this ACT.
