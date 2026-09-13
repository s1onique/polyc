# HANDOFF -- ACT-POLYC-BOOTSTRAP01-CORRECTION01

Factory-Version: 2

## Result

Governance/hygiene/doc-structure correction for
`ACT-POLYC-BOOTSTRAP01` closed PASS_WITH_HYGIENE_RESIDUE.

Reviewer audit identified four mechanical defects; this
correction ACT records, repairs, and re-classifies them
in a single bounded pass. The substantive B0 engineering
result (15/15 differential, determinism, source
immutability, output boundary, allocation-free PolyC
lexer, native AOT path) is preserved unchanged.

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the correction's CLOSE commit.

## Defects addressed

DEFECT-1 (P0): Cardinality-1 CLOSE invariant violation
  Recorded as EXCEPTION 4 in
  evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/
  correction04/historical-cardinality-exceptions.txt.
  Predecessor ACT-POLYC-BOOTSTRAP01 has 2 CLOSE
  commits (4b42e06 authoritative + 147069f docs-only
  follow-up that should have been EVIDENCE).

DEFECT-2 (P0): Source patch-hygiene (3 EOF blanks)
  Stripped exactly one trailing newline from each of:
    - tools/bootstrap/bootstrap01-lexer.HC
    - tools/quality/bootstrap01-lexer-oracle.c
    - tools/quality/bootstrap01-lexer-test.HC
  No semantic change; BTK_*/BLEX_* ABI and BootstrapLex
  byte-equivalent modulo the trailing newline.

DEFECT-3 (P1): Captured-evidence trailing whitespace
  evidence/ACT-POLYC-BOOTSTRAP01/c3/fresh-build.txt:144
  has trailing whitespace. Captured-evidence residue
  (verbatim compiler driver command line). Classified
  GOVERNANCE_RESIDUE per F-MECHANICAL-BLOCKING. Not
  blocking.

DEFECT-4 (P1): B0_LLVM verdict wording
  Re-authored as BLOCKED_BY_EXISTING_MEMORY01_FENCE
  in this correction's closure-truth block. Substantive
  truth is the same as predecessor (MEMORY01 fence);
  wording is now explicit and not permissive.

DEFECT-5 (P1): ACT document section ordering
  Corrected authoring copy deposited at
  evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/
    ACT-POLYC-BOOTSTRAP01-CORRECTED.md
  with §0..§37 in numerical order; section bodies
  byte-identical to the original (Python section_map
  diff = 0 differences). Original ACT document
  preserved at docs/acts/ACT-POLYC-BOOTSTRAP01.md as
  F14 historical evidence.

## Evidence

Predecessor:

  ACT-POLYC-BOOTSTRAP01                       CLOSED PASS
  (now Cardinality-1 EXCEPTION 4 in DOCTRINE §24)

C1 packet:    evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c1/
C2 packet:    evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c2/
C3 packet:    evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c3/
C4 packet:    evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c4/

Corrected authoring copy:

  evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/
    ACT-POLYC-BOOTSTRAP01-CORRECTED.md

EXCEPTION 4 record:

  evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/
    historical-cardinality-exceptions.txt

Fresh-tree evidence at C3:

  git diff --check 72f61e3..HEAD
    -> only DEFECT-3 captured-evidence residue

  rm -f ./build/bootstrap01-*
  make bootstrap01-test
    -> BOOTSTRAP01_CASES=15 PASS=15 FAIL=0 STATUS=PASS

Cardinality-1 invariant for this correction ACT:

  git log --all-match --oneline \
    --grep='^ACT: ACT-POLYC-BOOTSTRAP01-CORRECTION01$' \
    --grep='^ACT-Phase: CLOSE$'
    -> exactly 1 commit (verified at C4)

## Production delta

Total production source delta:

  tools/bootstrap/bootstrap01-lexer.HC        -1 line (EOF)
  tools/quality/bootstrap01-lexer-oracle.c    -1 line (EOF)
  tools/quality/bootstrap01-lexer-test.HC     -1 line (EOF)

  Total src/ delta: 0 bytes.

Documentation delta:

  docs/acts/ACT-POLYC-BOOTSTRAP01-CORRECTION01.md   +ACT doc

Evidence delta:

  evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/    +full pack
  evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/
    correction04/historical-cardinality-exceptions.txt
                                                  +EXCEPTION 4

No production compiler change. No B0 ABI change. No
MEMORY01 widening. No B1 work.

## Residue

P0: NONE.

P1:

  R-P1-1  ACT-POLYC-BOOTSTRAP01 Cardinality-1
          historical exception 4.
  R-P1-2  Predecessor c4/closure-summary.txt uses
          "N/A (path-dependent)" wording for
          B0_LLVM_AS/B0_LLVM_VERIFY; this correction's
          c4/closure-summary.txt uses
          BLOCKED_BY_EXISTING_MEMORY01_FENCE.
          Predecessor text is F14 historical evidence
          and is not modified.
  R-P1-3  GEP01 cap-verifier 26/4 pre-existing.
  R-P1-4  LLVM IR_STORE_DEREF MEMORY01 fence.
  R-P1-5  Captured-evidence trailing whitespace at
          evidence/ACT-POLYC-BOOTSTRAP01/c3/
          fresh-build.txt:144.

P2:

  R-P2-1  Pre-commit / pre-push hook for EOF hygiene.
  R-P2-2  Markdown section-order linter.

## Recommended next ACT

`ACT-POLYC-BOOTSTRAP02` (or equivalent bounded B1 ACT):
replace one bounded production lexer path with the
proven B0 lexer and pass differential tests against
the current compiler.

B1 entry gates are documented in
`evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c4/
  b1-unlock-criteria.txt`.

## Push

Not performed. PUSH_RESIDUE unchanged at GEP01_D1_D2.
