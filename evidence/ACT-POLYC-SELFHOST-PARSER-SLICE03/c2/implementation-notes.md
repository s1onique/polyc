ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE03
ACT_PHASE=C2-IMPL
EVIDENCE_KIND=implementation-notes

THE POLYC SUBJECT
=================

  tools/bootstrap/selfhost-parser-operator-precedence.HC
  I64 BootstrapOperatorPrecedence(I64 punct_value) -> I64 precedence

The subject is a transcription of the DERIVED TABLE (the live
src/prslib.c switch, resolved through the live src/lexer.h).  It is
NOT a transcription of the predecessor's prose: the derivation is
recomputed in C1 and recorded in
  c1/precedence-table-derived.tsv

THE SUBJECT IS CHECKED AGAINST THE DERIVED TABLE
===============================================

A C harness linked the compiled subject and compared it against
every row of the derived table:

  TABLE_ROWS=39 MISMATCHES=0

THE PRODUCTION DELEGATION
=======================

src/prslib.c:1139..1243 now reads:

  static int parseGetPriority(Lexeme *tok) {
  #ifdef HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE
      extern long long BootstrapOperatorPrecedence(long long punct_value);
      return (int)BootstrapOperatorPrecedence((long long)tok->i64);
  #else
      <the VERBATIM legacy switch>
  #endif
  }

The legacy switch body was verified to be BYTE IDENTICAL to the
entry commit's body:

  git show HEAD:src/prslib.c | sed -n '1140,1206p'  vs  sed -n '1175,1241p' src/prslib.c
  -> no difference

The ONLY additions to src/prslib.c are the guard, the adapter and
the zero-logic oracle entry point.

THE ORACLE ADAPTER
=================

  long long ParserLegacyOperatorPrecedenceOracle(long long punct_value)

It calls the REAL parseGetPriority with a Lexeme whose only
relevant field is i64, because the real body reads only tok->i64.
It adds NO logic.

THE BUILD WIRING IS FAIL-CLOSED
===============================

src/cmake/VerifyOperatorPrecedenceObject.cmake rejects the object
unless it carries EXACTLY ONE strong global text definition of the
symbol _BootstrapOperatorPrecedence.  A missing object, an
undefined-only symbol, a local symbol, a weak symbol and a
duplicate definition are all hard build errors.

The production build reported:

  OPERATOR_PRECEDENCE_OBJECT_STATUS=PASS
  EXPECTED_SYMBOL=BootstrapOperatorPrecedence
  TARGET_OBJECT_FORMAT=Mach-O
  TARGET_SYMBOL=_BootstrapOperatorPrecedence
  DEFINED_GLOBAL_TEXT_SYMBOL_COUNT=1

The Makefile also asserts that the production binary links the
symbol:

  nm ./hcc | grep -q _BootstrapOperatorPrecedence

LEGACY_PRECEDENCE_SEMANTIC_DELTA=0
