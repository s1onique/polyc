# ACT-POLYC-SELFHOST-LEXER02

**Title:** Migrate the mechanically-selected `scalar_literal_scanner` region to PolyC and prove four-generation equivalence

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** COMPILER / SELF-HOST / LEXER-OWNERSHIP-EXPANSION

**Authorized subject:** `scalar_literal_scanner`

**Frozen members:**

- `countNumberLen`
- `lexNumeric`
- `lexCharConst`

**Selection provenance:**

- `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`
- `+ CORRECTION01`
- `+ CORRECTION02`
- `+ CORRECTION03` (governance-only correction)

**Frozen selection result:**

```text
region_id              = R-F
FINAL_SCORE            = +627
runner_up              = +285
margin                 = +342
margin_class           = ROBUST
E1..E14                = PASS
projected ABI          = 4 inputs / 7 outputs
direct oracle          = feasible
production seam        = possible
```

**Predecessor self-host components:**

- `identifier_scanner` (BOOTSTRAP02)
- `operator_punctuation_recognizer` (LEXER01)

**Production-semantic authorization:** EXACTLY the frozen `scalar_literal_scanner` region.

**Parser / AST / IR / backend:** FORBIDDEN

**New compiler generation:** FORBIDDEN

**No-Python campaign:** PAUSED

**ACT-Verdict (target):** PASS only after C4 re-proves all 59 acceptance criteria.

---

# Mission (binding summary)

Move the semantics currently owned collectively by `countNumberLen`, `lexNumeric`, and `lexCharConst` from host C into one coherent PolyC component `scalar_literal_scanner`, while retaining stage0's existing C implementation as the reference/bootstrap path.

**Required ownership topology after this ACT:**

```text
stage0 ./hcc
  identifier     -> legacy C
  operators      -> legacy C
  scalar literals-> legacy C

stage1 hcc-bootstrap02
stage2 hcc-bootstrap03
stage3 hcc-bootstrap04

  identifier      -> PolyC
  operators       -> PolyC
  scalar literals -> PolyC
```

NO runtime legacy fallback. NO shadow C/PolyC execution in production. NO fourth bootstrap generation. NO duplicate PolyC semantic implementation.

See `evidence/ACT-POLYC-SELFHOST-LEXER02/` for per-phase evidence packets and `HANDOFF.md` for the human-readable closure summary.
