# ACT-POLYC-SELFHOST-LEXER02-CORRECTION02

**Title:** Repair three additional closure-truth defects in
ACT-POLYC-SELFHOST-LEXER02-CORRECTION01 closure (`d048ca9`)

**Class:** CORRECTION (FACTORY-DETECT-CLOSE-MISMATCH)

**ACT-Supersedes:** ACT-POLYC-SELFHOST-LEXER02-CORRECTION01 (for the
three new defects listed below)

**Predecessor (binding):**
ACT-POLYC-SELFHOST-LEXER02-CORRECTION01 CLOSED `d048ca9`

**Trigger (post-CORRECTION01 reviewer audit):**
1. P0 #1 (reopened): The `error-corpus-4-stage.txt` claim of "16
   error/negative fixtures" was a hand-typed category label
   (prefix `err_`), not a mechanically observed contract. 9 of the
   21 `err_*`-prefixed fixtures actually return `err=0` because
   the production lexer accepts them as valid forms (e.g.
   `0xFe` is hex 0xFE, `1.` is float 1.0, `.` is float 0, `1e`
   stops at `e`, `1e-` stops at `-`). The 16 actually-erroneous
   fixtures exist by observed `err!=0`, not by prefix.

2. P0 #2 (reopened): The "broad corpus 4-stage" evidence
   (24/24 holyc-lib + 189/189 wider) compared **filtered scalar
   token streams** (`TK_I64 | TK_F64 | TK_CHAR_CONST | TK_STR`)
   rather than the LEXER01-CORRECTION01 canonical pattern of
   **full compiler invocation + bytecode byte-equality** on the
   181-source corpus. That canonical pattern is:
   ```text
   STAGE0_PASS_STAGE1_FAIL = 0
   STAGE0_PASS_STAGE2_FAIL = 0
   STAGE0_PASS_STAGE3_FAIL = 0
   STAGE0_FAIL_STAGE*_PASS = 0
   successful outputs: sha256(stage0) == sha256(stage1)
                                == sha256(stage2)
                                == sha256(stage3)
   ```
   The current CORRECTION01 evidence proves token-stream
   equivalence, not full-compiler equivalence.

3. P1 (bookkeeping): The category arithmetic in CORRECTION01
   asserted A=41 + B=28 + C=16 + D=3 = 88, plus "1 overlap" for
   89. An overlap does not increase union cardinality; the
   arithmetic was fictional. The 89 is real (the binary reports
   it) but the categorical accounting is incoherent.

**Engineering verdict preserved:** the LEXER02 implementation
remains sound; the migration of `scalar_literal_scanner` to
PolyC remains GREEN.

**Mission (bounded):** closure-truth correction only — no
semantic mutation of the LEXER02 component. Repair:

1. Generate a mechanically-derived fixture-inventory TSV
   (observed kind/err, not hand-typed labels) and use it to
   re-prove the cardinality floors at all 4 stages.
2. Re-run the canonical 181-source compiler corpus through
   stages 0/1/2/3 with full compiler invocation + bytecode
   byte-equality, plus success/failure equivalence.
3. Bind the reused stage{1,2,3} .o directories to compiler
   provenance + expected sha256, so a stale build cannot
   silently satisfy the test.
4. Replace the categorical arithmetic with the mechanical
   inventory; total cardinality 89 remains the truth.

**Scope:**
- `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION02/c{1,2,3,4}/`
  (NEW)
- `tools/quality/lexer07-direct-differential.c` (add
  per-fixture contract annotation that emits observed kind/err
  as part of output; no INPUTS[] mutation needed)
- New `scripts/quality/lexer07-fixture-inventory.sh` (mechanical
  classifier that produces a TSV from the binary output)
- New `scripts/quality/lexer07-broad-corpus-4-stage.sh`
  (181-source compile + bytecode byte-equality)
- `Makefile` (new targets for the above)
- `docs/ROADMAP.md` (CLOSE status update)
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION02.md`
  (NEW)

**Out of scope:**
- `src/lexer.c` semantics
- `tools/bootstrap/selfhost-lexer-scalar-literal.HC` semantics
- `src/lexer_bridge.h` ABI 3 declaration
- `src/CMakeLists.txt` stage linkage
- The C oracle body (verbatim extraction, F2 contract)
- `test-prefix-install` target repair (pre-existing failure)
- Cardinality floors in CORRECTION01 that are now mechanically
  satisfied (kind=3 char ≥ 24: 33; err≠0 ≥ 16: 16)

**ACT-Verdict (target):** PASS only after the three additional
defects are mechanically closed.
