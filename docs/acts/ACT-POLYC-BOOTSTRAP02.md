# ACT-POLYC-BOOTSTRAP02

**Title:** B1 partial self-host — replace the production identifier-span seam with a PolyC component compiled by stage0 `hcc`

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP01-CORRECTION01` (B0 GREEN_WITH_CLOSURE_CORRECTION; B1 unblocked per §11 of that ACT)

**Class:** BOOTSTRAP / PARTIAL-SELF-HOST / LEXER

**Production compiler semantic changes:** **AUTHORIZED** (bounded, see §14)

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN** (B0 grammar frozen)

**VERDICT (target):** `PASS` (then re-evaluated by C1-CORRECTION01 and C4)

---

# 0. Mission

Build one genuinely self-hosted compiler slice:

```
stage0 (./hcc, host C source)
    ↓ compiles
tools/bootstrap/bootstrap02-ident.HC
    ↓ produces
build/bootstrap02-ident.o (PolyC-compiled object)
    ↓ linked into
build/hcc-bootstrap02 (separate stage1 binary)
    ↓ which uses
src/lexer.c (host C, modified at one delegate site)
```

with the production seam delegating *only* identifier-span discovery to the B1 component.

# 1. Scope (one production seam only)

Exactly one production source file is touched:

- `src/lexer.c` (the production identifier-span seam at `lexIdentifier`, line 873)

Exactly one declaration-only bridge header is added:

- `src/lexer_bridge.h` (kept separate from `src/lexer.h` to minimise scope)

Build infrastructure:

- `Makefile` / `CMakeLists.txt`: stage1 artifact construction only.

# 2. Out of scope

- parser / AST / IR / backend / runtime
- B0 lexer component (`tools/bootstrap/bootstrap01-lexer.HC`)
- LLVM-IR emission / `IR_STORE_DEREF` / MEMORY01 widening
- GEP01 harness
- pre-existing residue (PUSH_RESIDUE = GEP01_D1_D2)

# 3. Frozen components (forbidden to change in C2..C4)

- `tools/bootstrap/bootstrap01-lexer.HC` (B0 component)
- B0 `BTK_*` and `BLEX_*` ABI
- `src/lexer.h` public API (`TK_IDENT`, `Lexer`, `Lexeme`, `LexFile`)
- Production lexer dispatcher gate at `src/lexer.c:1458` (only the delegate's body is rewritten)

# 4. Component: `tools/bootstrap/bootstrap02-ident.HC`

```
public I64 BootstrapScanIdent(
    U8  *src,        // caller-owned, read-only
    I64  src_len,    // explicit byte length
    I64  start,      // cursor into src
    I64 *out_end     // first byte after identifier
);
```

- returns `1` on success, `0` on invalid input
- on success: `*out_end = start + N` (N >= 1)
- on success: no mutation of `src`, no globals, no allocation

# 5. HALT taxonomy (as originally written; corrected by C1-CORRECTION01)

```text
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH fires iff:
  production grammar is broader or narrower than B0 grammar

HALT_B1_ABI_PROBE_FAILED          fires iff:
  the C ↔ PolyC ABI witness does not reproduce

HALT_B1_MEMORY01_DEPENDENCY       fires iff:
  the B1 component requires the MEMORY01 LLVM-IR fence

HALT_B1_GEP01_DEPENDENCY          fires iff:
  the B1 component requires the GEP01 harness

HALT_B0_REGRESSION                fires iff:
  any B0 test (15/15) regresses under stage0 OR stage1

HALT_B1_DELEGATION_FAIL           fires iff:
  a delegation from src/lexer.c to BootstrapScanIdent
  silently fails, ignores the result, or falls back to
  the legacy C implementation
```

NOTE — The original §5 grammar-mismatch predicate
("production grammar broader or narrower than B0")
was over-constrained and did not match the B1
architectural intent. C1-CORRECTION01 replaces this
clause with:

```text
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH fires iff:
  production grammar cannot be mechanically frozen
  OR
  proposed B1 grammar cannot preserve production semantics
  OR
  satisfying production semantics would require changing B0
```

The corrected predicate is recorded in
`docs/acts/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01.md`.

# 6. Acceptance criteria

```text
AC01..AC08  — captured at C1
AC09        — C2 implementation of bootstrap02-ident.HC
AC10        — stage0 hcc compiles bootstrap02-ident.HC cleanly
AC11        — stage1 hcc-bootstrap02 builds and links
AC12        — src/lexer.c delegates to BootstrapScanIdent
AC13        — delegation has no silent fallback
AC14        — BOOTSTRAP01 15/15 conservation under stage0
AC15        — BOOTSTRAP01 15/15 conservation under stage1
AC16        — direct differential vs bootstrap02-ident-oracle
AC17        — stage0/stage1 valid corpus equivalence
AC18        — stage0/stage1 error corpus equivalence
AC19        — stage1 compiles bootstrap02-ident.HC itself
AC20        — full quality gates pass (factory-v2, gate-fast,
              append-only, halt-classification, shell-loc)
AC21        — residue.txt captures non-blockers honestly
AC22        — source immutability of src under B1
```

# 7. C1 → C2 gate (as originally written; corrected by C1-CORRECTION01)

```text
IDENTIFIER_SEAM_ISOLATABLE    = YES
IDENTIFIER_GRAMMAR_EQUIVALENT = YES      <-- corrected
LEGACY_ORACLE_CAPTURED        = YES
POLYC_C_ABI_PROVEN            = YES
B1_REQUIRES_B0_LLVM_PATH      = NO
B1_REQUIRES_GEP01_HARNESS     = NO
```

NOTE — `IDENTIFIER_GRAMMAR_EQUIVALENT = YES` is replaced by
`IDENTIFIER_GRAMMAR_GATE = PASS` in
`docs/acts/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01.md`.
The replacement predicate is:

```text
IDENTIFIER_GRAMMAR_GATE = PASS iff:
  PRODUCTION_GRAMMAR_FROZEN                = YES
  B0_GRAMMAR_PRESERVED                     = YES
  B0_VS_PRODUCTION_DIFFERENCE              = DOCUMENTED
  B1_REQUIRED_GRAMMAR_EQUALS_PRODUCTION    = YES
```

# 8. Build topology

```text
hcc (stage0, host C)
   ↓ -c tools/bootstrap/bootstrap02-ident.HC
build/bootstrap02-ident.o
   ↓ linked into stage1
host C sources (src/*.c)
   +
src/lexer_bridge.h (new)
   ↓
build/hcc-bootstrap02 (stage1 binary)
```

# 9. Stage1 binary invariants

- The stage1 binary is a separate executable (`build/hcc-bootstrap02`); it does NOT replace `./hcc`.
- `./hcc` (stage0) remains the only binary that compiles new bootstrap components.
- `./hcc` is itself UNCHANGED (no host-C source mutation in B1).
- Stage1 delegates only the identifier-span seam; all other lexing/parsing/IR remains in host C.

# 10. Conservation baseline

```text
BOOTSTRAP01_NATIVE_CASES  = 15 (must remain 15/15)
BOOTSTRAP01_LLVM_PATH     = N/A (no change expected)
GATE_FAST                 = PASS
FACTORY_V2                = PASS
APPEND_ONLY               = PASS
HALT_CLASSIFICATION       = PASS
SHELL_LOC                 = PASS
```

# 11. Forbidden mechanisms

```text
amend, rebase, filter-branch, filter-repo, git replace,
reset + recommit, squash merge, force push, fallback to
legacy C implementation at the delegation site, runtime
toggle, B0 grammar change, B0 ABI change, B0 file change
```

# 12. Relationship to B0

B0 (`tools/bootstrap/bootstrap01-lexer.HC`) is preserved bit-identically. B0's grammar (`[A-Za-z_][A-Za-z0-9_]*`) does NOT match production grammar (which admits `$` in continuation). This asymmetry is real and required — production source uses `$`-bearing identifiers (e.g. `_opendir$INODE64` in `src/holyc-lib/dir.HC`). B1 is a deliberately separate component that implements production grammar (NOT B0 grammar). The asymmetry is bounded, mechanical, and resolved by C1-CORRECTION01.

# 13. The 15 fixtures (carried from B0, with I15 added)

See `evidence/ACT-POLYC-BOOTSTRAP01/c1/bootstrap01-fixtures.tsv` and `evidence/ACT-POLYC-BOOTSTRAP02/c1/legacy-ident-oracle.tsv`.

# 14. Production-source mutation in C2

C2 modifies `src/lexer.c` *only*:

```text
lexIdentifier() body
    ↓ delegates to
BootstrapScanIdent(src, src_len, start, &end)
    ↓ caller (lexCore) sets
l->ptr        = src + end
l->cur_strlen = end - start
```

No runtime toggle. No `#ifdef`. No legacy fallback.

# 15. Required-result blocks

- C1: `evidence/ACT-POLYC-BOOTSTRAP02/c1/c1-required-result.txt` (corrected by C1-CORRECTION01)
- C2: `evidence/ACT-POLYC-BOOTSTRAP02/c2/required-result.txt`
- C3: `evidence/ACT-POLYC-BOOTSTRAP02/c3/required-result.txt`
- C4: `evidence/ACT-POLYC-BOOTSTRAP02/c4/required-result.txt`

# 16. Push policy

Push is NOT performed by this ACT.

# 17. Closure-truth shape

`c4/closure-summary.txt` records:

```text
ACT-Verdict                       = PASS  (or residue-coded variant)
B1_NATIVE_SEMANTICS               = PASS
B1_DIFFERENTIAL_ORACLE            = PASS
B1_STAGE0_STAGE1_EQUIVALENCE      = PASS
B0_CONSERVATION_UNDER_STAGE1      = PASS  15/15
B1_SOURCE_IMMUTABILITY            = PASS
B1_OUTPUT_BOUNDARY                = PASS
B1_ALLOCATION_FREE                = PASS
B1_DELEGATION_NO_FALLBACK         = PASS
B1_STAGE1_COMPILES_ITS_OWN_SOURCE = PASS
PUSH_PERMISSION                   = NOT_PERFORMED
PUSH_RESIDUE                      = GEP01_D1_D2 (pre-existing)
```

# 18. Commit topology

```text
C1 RED       — 1+ commit(s), opens ACT
C2 IMPL      — N commit(s), implementation + Makefile + bridge
C3 EVIDENCE  — 1+ commit(s), all gates
C4 CLOSE     — 1 commit, single CLOSE for ACT-POLYC-BOOTSTRAP02
```

Cardinality-1 invariant verified at C4 with:

```text
git log --all-match --oneline \
    --grep='^ACT: ACT-POLYC-BOOTSTRAP02$' \
    --grep='^ACT-Phase: CLOSE$'
```

returning exactly 1 commit.

# 19. Correction ACT

`docs/acts/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01.md` supersedes §5's grammar-mismatch predicate and §7's `IDENTIFIER_GRAMMAR_EQUIVALENT` predicate with the corrected gate.

No SHA-of-self claims anywhere (DOCTRINE.md §22).

# 20. HALT taxonomy (binding, post-correction)

```text
HALT_RED_NOT_REPRODUCED                  — n/a
HALT_SCOPE_EXPANSION_REQUIRED            — bounded, no expansion
HALT_MEMORY01_WIDENING_REQUIRED          — NOT AUTHORIZED
HALT_LLVM_VERIFY_REQUIRED                — NOT AUTHORIZED
HALT_B1_IDENTIFIER_CONTRACT_MISMATCH     — corrected by C1-CORRECTION01
HALT_B1_ABI_PROBE_FAILED                 — fires iff ABI witness fails
HALT_B1_MEMORY01_DEPENDENCY              — fires iff MEMORY01 needed
HALT_B1_GEP01_DEPENDENCY                 — fires iff GEP01 harness needed
HALT_B0_REGRESSION                       — fires iff any B0 test regresses
HALT_B1_DELEGATION_FAIL                  — fires iff delegation silently fails
```
