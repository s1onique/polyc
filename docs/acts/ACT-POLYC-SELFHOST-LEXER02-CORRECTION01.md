# ACT-POLYC-SELFHOST-LEXER02-CORRECTION01

**Title:** Repair three closure-truth defects in ACT-POLYC-SELFHOST-LEXER02 closure (`af418a9`)

**Class:** CORRECTION (FACTORY-DETECT-CLOSE-MISMATCH + SCOPE-CONSERVATION-CORRECTION)

**ACT-Supersedes:** ACT-POLYC-SELFHOST-LEXER02

**Predecessor (binding):** ACT-POLYC-SELFHOST-LEXER02 CLOSED `af418a9`

**Trigger:**
1. Reviewer audit (P0 #1): frozen ABI projection 4/≤7 was violated by
   measured required ABI 4/8 (out_strlen) during C2; the
   `HALT_LEXER02_ABI_BOUNDARY_MISMATCH` clause should have fired.
2. Reviewer audit (P0 #2): §32 FIXTURE_CARDINALITY (DIRECT_REGION_CASES ≥ 64
   with ≥24 char-const, ≥16 error/negative) was not satisfied by the
   40-fixture corpus.
3. Reviewer audit (P0 #3): real-lexer seam and broad corpus were proven
   only at stages 0/1, not all 4 stages (LEXER01-CORRECTION01 pattern
   requires all 4).

**Engineering verdict preserved:** the LEXER02 implementation is sound;
the migration of `scalar_literal_scanner` to PolyC is GREEN.

**Mission (bounded):** closure-truth correction only — no
semantic mutation of the LEXER02 component. Repair:
1. ABI projection 4/7 → 4/8 with formal disposition
2. Direct fixture cardinality ≥ 64 with sub-floor ≥ 24 char + ≥ 16 error
3. Real-lexer seam at all 4 stages
4. Broad corpus at all 4 stages
5. Error corpus at all 4 stages
6. Re-run all Factory gates

**Scope:**
- `evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION01/c{1,2,3,4}/` (NEW)
- `tools/quality/lexer07-direct-differential.c` (fixture expansion)
- `tools/quality/lexer07-scalar-literal-oracle.c` (additional self-tests)
- `Makefile` (lexer07-lexer-seam-stage{2,3} without test-prefix-install dep)
- `docs/ROADMAP.md` (CLOSE status update)
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION01.md` (NEW)

**Out of scope (residue):**
- `test-prefix-install` Makefile target (pre-existing failure, ARM64 asm
  issue in src/holyc-lib/strings.HC); this ACT provides a build path that
  does not require it.

**ACT-Verdict (target):** PASS only after all six closure repairs are
green and conservation re-verified.
