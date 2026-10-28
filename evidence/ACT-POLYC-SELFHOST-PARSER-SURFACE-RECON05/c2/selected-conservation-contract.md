# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SELECTED CONSERVATION CONTRACT

**Selected candidate:** `SUB-003`

---

The successor must conserve EVERY one of these.  A change in any of
them is a HALT, not a PASS.

## 1. The parser host suite

```text
PARSER_HOST_ARCH_ASSERTIONS=376/376
PARSER_HOST_ARCH_TESTFILES=90
PARSER_HOST_ARCH_FAILURE_IDENTITIES=0
PARSER_HOST_ARCH_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
```

The assertion-sequence MD5 is the **exact identity** of the suite, not
a count.  Two suites with the same count but a different MD5 are
different suites.

## 2. The lexer differentials

```text
LEXER07_DIRECT_DIFFERENTIAL=PASS
LEXER08_DIRECT_DIFFERENTIAL=45/45 PASS
LEXER09_DIRECT_DIFFERENTIAL=23/23 PASS
```

## 3. The LEXER07 broad corpus

```text
LEXER07_BROAD_CORPUS_TOTAL=181
LEXER07_BROAD_CORPUS_PASS_S0=166
LEXER07_BROAD_CORPUS_FAIL_S0=15
LEXER07_BROAD_CORPUS_PASS_S1=175
LEXER07_BROAD_CORPUS_FAIL_S1=6
LEXER07_BROAD_CORPUS_PASS_S2=175
LEXER07_BROAD_CORPUS_FAIL_S2=6
LEXER07_BROAD_CORPUS_PASS_S3=175
LEXER07_BROAD_CORPUS_FAIL_S3=6
LEXER07_BROAD_CORPUS_BOTH_FAIL_4=6
LEXER07_BROAD_CORPUS_REGRESSION=0
LEXER07_BROAD_CORPUS_DIVERGED=0
LEXER07_BROAD_CORPUS_FAILURE_IDENTITY_MD5=7ee761440de83552e751e3c3976c1683
LEXER07_BROAD_CORPUS_STATUS=FAIL_KNOWN_BASELINE
```

The nonzero exit is the KNOWN baseline condition.  It is reported
honestly and is NOT a PASS.  The failure-identity MD5 is the invariant:
it must be unchanged.

## 4. The cross-target condition

```text
CROSS_TARGET_TESTS_ATTEMPTED=67
CROSS_TARGET_FAILED_TO_OPEN_FILE=67
CROSS_TARGET_PASSED=0
CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX
```

This is the historical ENVIRONMENT condition (the aarch64 prefix has
no installed PolyC runtime).  It is preserved honestly and is NOT a
new failure identity.

## 5. The already-migrated authorities

All SIX must still be live:

```text
BootstrapCalcPadding                 MACRO=YES  U=YES  T=NO
BootstrapValidPostControlFlowToken   MACRO=YES  U=YES  T=NO
BootstrapOperatorPrecedence           MACRO=YES  U=YES  T=NO
BootstrapAstBinOpFromToken            MACRO=YES  U=YES  T=NO
BootstrapAstUnaryOpFromToken          MACRO=YES  U=YES  T=NO
BootstrapSwitchArmTerminates          MACRO=YES  U=YES  T=NO
```

## 6. The tool policy

```text
F_NO_PYTHON=FAIL with EXACTLY the 12 PRE-EXISTING violations
F_POLYC_TOOLS=UNAVAILABLE (the authoritative checker is NOT LANDED)
```

The F-POLYC-TOOLS checker is still not landed.  It is reported
UNAVAILABLE and is NEVER reported PASS.

## 7. The Factory gates

```text
GATE_FAST=PASS
GATE_PUSH=PASS
APPEND_ONLY=PASS (11/11)
FACTORY_V2_RANGE_CHECK=PASS
F14=PASS
```
