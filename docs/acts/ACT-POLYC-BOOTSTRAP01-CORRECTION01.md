# ACT-POLYC-BOOTSTRAP01-CORRECTION01

**Title:** Cardinality-1 CLOSE repair + EOF hygiene + ACT-document section-ordering repair + B0 native/LLVM closure-truth reclassification

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP01` (PASS_WITH_CARDINALITY_AND_HYGIENE_DEFECTS)

**Class:** GOVERNANCE / HYGIENE / DOC-STRUCTURE

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN** (frozen `BTK_*` and `BLEX_*` ABI)

**VERDICT (target):** `PASS_WITH_HYGIENE_RESIDUE` (governance-residue only)

---

# 0. Mission

Reviewer audit of `ACT-POLYC-BOOTSTRAP01` closure identified
four mechanical defects. This correction ACT records,
repairs, and re-classifies them in a single bounded pass.

The substantive B0 engineering result (15/15 differential,
determinism, source immutability, output boundary,
allocation-free PolyC lexer, native AOT path) is preserved.
The correction is governance/hygiene/doc-structure only.

# 1. Authoritative defect enumeration

DEFECT-1 (P0): Cardinality-1 CLOSE invariant violation.

  Commits carrying both `ACT: ACT-POLYC-BOOTSTRAP01` and
  `ACT-Phase: CLOSE`:

    - 4b42e06 (closure-truth pack)
    - 147069f (docs/ROADMAP.md B0 outcome block)

  Per DOCTRINE.md §22 / Cardinality-1-CLOSE invariant, the
  set MUST have cardinality exactly 1.

  DOCTRINE.md §24 explicitly contemplates this class of
  violation and provides the disposition: open a CORRECTION
  ACT, append a historical exception to
  `historical-cardinality-exceptions.txt`, and treat the
  earlier commit as the authoritative closure. The follow-up
  commit is re-classified as a docs-only follow-up that
  *should* have carried `ACT-Phase: EVIDENCE`.

DEFECT-2 (P0): Source patch-hygiene defects.

  `git diff --check <BOOTSTRAP01-entry>..HEAD` reports:

    tools/bootstrap/bootstrap01-lexer.HC:224:
        new blank line at EOF
    tools/quality/bootstrap01-lexer-oracle.c:333:
        new blank line at EOF
    tools/quality/bootstrap01-lexer-test.HC:337:
        new blank line at EOF

  These three EOF blank lines were introduced by this ACT's
  C2 implementation. They are source/test patch-hygiene
  failures, not just captured-evidence residue.

DEFECT-3 (P1): Captured-evidence trailing-whitespace residue.

  `evidence/ACT-POLYC-BOOTSTRAP01/c3/fresh-build.txt:144:
    trailing whitespace`

  This is captured-evidence residue: a verbatim copy of a
  compiler driver command line that ends in a literal space
  (from `Makefile` line continuation). Classified as
  `GOVERNANCE_RESIDUE` per F-MECHANICAL-BLOCKING.

DEFECT-4 (P1): B0_LLVM acceptance criterion reframed after
RED.

  The original `ACT-POLYC-BOOTSTRAP01` §16 required:

    hcc --emit-llvm
    llvm-as
    opt --passes=verify

  The closure truth at `c4/closure-summary.txt` recorded:

    B0_LLVM_AS     = N/A   (path-dependent)
    B0_LLVM_VERIFY = N/A   (path-dependent)

  This is a contract reframing after RED. The reframing is
  *substantively correct* (the MEMORY01 `IR_STORE_DEREF`
  fence is a known substrate boundary; widening it is
  outside B0 scope), but the closure verdict wording was
  permissive where the original authorization was strict.
  This correction re-words the verdict so the B0 engineering
  result and the LLVM-path blocker are both recorded
  truthfully without ambiguity.

DEFECT-5 (P1): `docs/acts/ACT-POLYC-BOOTSTRAP01.md` section
order is wrong.

  `grep -n '^## ' docs/acts/ACT-POLYC-BOOTSTRAP01.md` reports
  §24/§25 placed *after* the Closure metadata (§37), and §6
  and §1 placed *after* §25. This is a structural authoring
  defect. Per F14, the original file remains immutable as
  historical evidence; a corrected authoring copy is
  deposited in this correction's evidence tree.

# 2. Authorized scope

2.1 Append `ACT-POLYC-BOOTSTRAP01` to
    `historical-cardinality-exceptions.txt` as EXCEPTION 4.

2.2 Strip the three introduced EOF blank lines from:

    - tools/bootstrap/bootstrap01-lexer.HC
    - tools/quality/bootstrap01-lexer-oracle.c
    - tools/quality/bootstrap01-lexer-test.HC

2.3 Verify `git diff --check <BOOTSTRAP01-entry>..HEAD` rc=0
    modulo the captured-evidence residue (DEFECT-3), which
    is recorded but not blocking.

2.4 Write a corrected authoring copy of
    `docs/acts/ACT-POLYC-BOOTSTRAP01.md` to
    `evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/
        ACT-POLYC-BOOTSTRAP01-CORRECTED.md`
    with sections in numerical order. The original
    `docs/acts/ACT-POLYC-BOOTSTRAP01.md` stays in place
    (F14 historical evidence).

2.5 Re-author the B0_LLVM verdict wording as
    `BLOCKED_BY_EXISTING_MEMORY01_FENCE` (not `N/A`).

2.6 Re-author the B0 native/LLVM engineering result as
    `GREEN_WITH_CLOSURE_CORRECTION` and lift B1's
    "TEMPORARILY_LOCKED" status to
    "READY_FOR_AUTH_AFTER_CORRECTION_CLOSES".

2.7 Re-run `make bootstrap01-test` at this correction's
    CLOSE commit and prove BOOTSTRAP01_CASES=15 / PASS=15 /
    FAIL=0 / STATUS=PASS.

# 3. Forbidden

  - any change to `BTK_*` or `BLEX_*` ABI
  - any change to `BootstrapLex` or `BootstrapToken`
  - any semantic change to `bootstrap01-lexer-oracle.c`
  - any change to the C oracle's expected output streams
  - any change to the frozen fixture matrix
  - any change to `src/` (production compiler)
  - any MEMORY01 widening (boundary stays exactly where
    Option-W C6 documented it)
  - any B1 work (parsing, AST, codegen)
  - any modification to `docs/acts/ACT-POLYC-BOOTSTRAP01.md`
    (F14 historical evidence)
  - any modification to `evidence/ACT-POLYC-BOOTSTRAP01/
    {c1,c2,c3,c4}/` (F14 historical evidence)
  - any modification to the existing closure HANDOFF.md
    (F14 historical evidence). The *new* closure-truth
    pack lives in
    `evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c4/`.

# 4. Required C1 packet

  evidence/ACT-POLYC-BOOTSTRAP01-CORRECTION01/c1/
    defect-classification.txt
    authorized-scope.txt
    forbidden-scope.txt
    dependency-and-predecessor.txt
    residue-classification.txt
    required-result.txt
    README.md

# 5. Required C2 implementation

  - only new commits (no amend, no rebase, no reset)
  - strip EOF blank line in 3 files
  - append EXCEPTION 4 to
    historical-cardinality-exceptions.txt
  - deposit corrected authoring copy
  - deposit reclassification of B0_LLVM verdict wording
  - deposit B1 unlock criteria

# 6. Required C3 evidence

  - post-fix `git diff --check <entry>..HEAD` output (rc=0
    modulo captured-evidence residue, recorded)
  - post-fix fresh-tree `make bootstrap01-test` output
    (BOOTSTRAP01_CASES=15 PASS=15 FAIL=0 STATUS=PASS)
  - new closure-truth block with corrected verdict wording
  - B1 unlock criteria: ACT-POLYC-BOOTSTRAP02 is
    READY_FOR_AUTH_AFTER_CORRECTION_CLOSES

# 7. Required C4 closure

  - closure-summary.txt with `ACT-Verdict:
    PASS_WITH_HYGIENE_RESIDUE`
  - residue.txt (P0/P1/P2)
  - roadmap-transition.txt
  - HANDOFF.md (Factory v2)
  - single CLOSE commit on
    `ACT-POLYC-BOOTSTRAP01-CORRECTION01`

# 8. HALT taxonomy

  HALT_RED_NOT_REPRODUCED         — n/a (governance)
  HALT_SCOPE_EXPANSION_REQUIRED   — n/a (bounded)
  HALT_MEMORY01_WIDENING_REQUIRED — NOT AUTHORIZED
  HALT_LLVM_VERIFY_REQUIRED       — NOT AUTHORIZED
  HALT_B1_WORK_REQUIRED           — NOT AUTHORIZED

# 9. Cardinality-1 disposition for the predecessor ACT

  ACT-POLYC-BOOTSTRAP01
  CLOSE-commits count: 2
    - 4b42e06 (main, closure-truth pack)
    - 147069f (ROADMAP B0 outcome block; should have
              been EVIDENCE, not CLOSE)
  Classification: ROADMAP follow-up carried CLOSE trailer
                  in error; should have carried EVIDENCE.
                  F14 residue; not fixed.
  Authoritative CLOSE: 4b42e06.

# 10. Authoritative corrected B0 closure verdict

  ACT-Verdict (correction)     = PASS_WITH_HYGIENE_RESIDUE
  BOOTSTRAP_B0                 = GREEN
  B0_NATIVE_SEMANTICS          = PASS
  B0_DIFFERENTIAL_ORACLE       = PASS  15/15
  B0_DETERMINISM               = PASS
  B0_SOURCE_IMMUTABILITY       = PASS
  B0_OUTPUT_BOUNDARY           = PASS
  B0_ALLOCATION_FREE           = PASS
  B0_HCC_NATIVE_COMPILE        = PASS
  B0_NATIVE_LINK               = PASS
  B0_NATIVE_RUN                = PASS
  B0_LLVM_PATH                 = BLOCKED_BY_EXISTING_MEMORY01_FENCE
  B1_AUTH                      = READY_FOR_AUTH_AFTER_CORRECTION_CLOSES
  BOOTSTRAP_STABILITY          = NOT_YET
  FIRST_SELF_HOST              = NOT_YET
  PUSH_PERMISSION              = NOT_PERFORMED
  PUSH_RESIDUE                 = GEP01_D1_D2 (pre-existing)

# 11. Push policy

  Push is NOT performed by this ACT. PUSH_RESIDUE
  unchanged.

# 12. Closure-truth shape

  See `c4/closure-summary.txt` for the canonical block.
  No SHA-of-self claims anywhere (DOCTRINE.md §22).

# 13. Commit topology

  C1 RED       — 1 commit, opens ACT
  C2 IMPL      — N commits (governance edits only)
  C3 EVIDENCE  — 1 commit
  C4 CLOSE     — 1 commit, single CLOSE for
                 ACT-POLYC-BOOTSTRAP01-CORRECTION01

  Cardinality-1 invariant verified at C4 with
  `git log --all-match --oneline --grep='^ACT:
   ACT-POLYC-BOOTSTRAP01-CORRECTION01$'
   --grep='^ACT-Phase: CLOSE$'` returning exactly 1
  commit.
