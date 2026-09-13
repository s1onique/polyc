ACT-POLYC-SELFHOST-LEXER01 — HANDOFF
====================================

Status: CLOSED (PASS).

This ACT migrated one mechanically-selected coherent
host-C lexer slice (operator/punctuation recognition)
to PolyC, proved stage0↔stage1↔stage2↔stage3
equivalence, and closed S1 expansion of the self-host
lexical surface.

WINNER
------
operator_punctuation_recognizer (rank 1, FINAL_SCORE=952)
- Host-C locus: src/lexer.c lexCore switch, operator cases
- Token kinds owned: 32 (TK_* multi-char + ASCII single-char)
- ABI: BootstrapClassifyOperator(src, src_len, cursor, flags,
                                 out_kind, out_length)
- Subject: tools/bootstrap/selfhost-lexer-operator-classify.HC

WITSNESSES (RED → GREEN)
------------------------
RED (C1):
  - 47-fixture C oracle: 47/47 PASS (frozen formula)
  - 47-fixture C-vs-PolyC differential: 47/47 PASS
  - 33-fixture production seam: 33/33 PASS
  - 181-source corpus: 175/175 PASS, 6/6 equivalent errors
  - ABI witness: stage0 hcc compiles PolyC probe,
    _BootstrapClassifyOperator exported
  - Generation / error / no-python / formal-dafny baselines frozen

GREEN (C2 IMPL):
  - src/lexer.c: lexCore operator cases refactored to call
    a thin wrapper lexClassifyOperator()
  - Build-time selection: HCC_USE_SELFHOST_COMPONENTS for
    stage1+ (PolyC); legacy (default) C switch bit-identical
  - Stage0/1/2/3 binary build paths extended
  - 175/175 byte-identical corpus (matches B3 baseline exactly)
  - Operator fixed point: N0==N1==N2==N3
  - Identifier fixed point preserved: N0==N1==N2
  - C-oracle / differential / production seam re-run: all PASS

CONSERVATION
------------
- Required behavior changed: lexCore operator cases now
  delegate to PolyC component in stage1+ (was inline C).
- Unrelated established behavior remained unchanged:
  - Identifier lexer (B1) byte-identical across all stages
  - All 175 successfully-compiled sources byte-identical
  - 6 intentional-error fixtures fail equivalently in all stages
  - POLYC_TOOLS_TRACKED_PYTHON = 12 (unchanged from C1 baseline)
  - Formal Dafny: 17/17 verified (unchanged)

CRITICAL INCIDENT (resolved)
----------------------------
During C2 verification, an asm-block parser failure was
traced to a flag-bit mismatch: the PolyC component's
OP_CCF_* macros used (1<<16)/(1<<17) but src/lexer.h
defines CCF_ASM_BLOCK=(1<<4) and CCF_MULTI_COLON=(1<<3).
The wrapper forwards l->flags unchanged, so the bit
positions in the component had to be aligned with the
host-C definitions. After alignment (and a parallel fix
to the differential harness which had the same wrong
definitions), all 47/47 differential cases pass and the
181-source corpus reaches 175/175 byte-identical.

SCOPE
-----
Files modified:
  - Makefile (new bootstrap06-* targets + paths)
  - docs/factory/SELF-HOST-COMPONENTS.tsv (row 2)
  - src/CMakeLists.txt (stage1/2/3 link paths)
  - src/lexer.c (lexCore operator cases + new helper)
  - src/lexer_bridge.h (BootstrapClassifyOperator extern)
  - tools/selfhost/selfhost-component.HC (stage=3 support)
Files created:
  - tools/bootstrap/selfhost-lexer-operator-classify.HC
  - tools/quality/bootstrap06-operator-classify-oracle.c
  - tools/quality/bootstrap06-direct-differential.c
  - tools/quality/bootstrap06-lexer-seam-runner.c
Evidence:
  - evidence/ACT-POLYC-SELFHOST-LEXER01/{c1,c2,c3,c4,HANDOFF.md}

RESIDUE
-------
P1: No-Python campaign remains paused at C2.3 GREEN
    (12 grandfathered Python files); not in ACT scope.
P2: Wrapper's synthetic l->ptr = start + length advance
    could be unified with lexNextChar's step-by-step advance.
P2: Wrapper's strlen(start) for src_len could be tightened
    to use the lexer's known buffer bound.

NEXT ACT
--------
ACT-POLYC-SELFHOST-LEXER01 is CLOSED.

A successor ACT (proposed id: ACT-POLYC-SELFHOST-LEXER02)
should be opened to migrate the next-highest-scoring
eligible slice. From C1's ownership map:

  candidate                rank  score
  numeric_length_scan        2    -53 (negative: too tightly
                                       coupled to countNumberLen
                                       caller's out-params)
  comment_skip               3   -226 (negative: rejects)
  char_const_scan            4    -47 (deferred to later ACT)
  numeric_value_parse        5   -103 (negative: libc)

None of the remaining C1 candidates have a positive
FINAL_SCORE; this ACT consumed the only eligible positive-
score slice. A successor ACT would need to either (a)
relax one or more E1..E14 gates to make a currently-
rejected slice eligible, or (b) introduce a new candidate
slice not in the original 22-slice inventory.

Plausible next-direction options (F-DESIGN-NOTES-style,
not committed):
  - Aggregate the four lexCore helpers (numeric_length_scan,
    comment_skip, char_const_scan, numeric_value_parse) into
    a single "lexCore_classification_helpers" migration if
    the ABI cost can be brought down.
  - Open a recon ACT to re-survey the lexer surface after
    the S1 expansion has been demonstrated end-to-end.

REGISTRY
--------
docs/factory/SELF-HOST-COMPONENTS.tsv row 2:
  operator_punctuation_recognizer  STAGED  status=CLOSED
  identifiers=BootstrapClassifyOperator
  producer=tools/bootstrap/selfhost-lexer-operator-classify.HC
  ABI=I64 (U8* src, I64 src_len, I64 cursor, I64 flags,
           I64* out_kind, I64* out_length)