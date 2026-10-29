# SELECTED CONSERVATION CONTRACT

The successor MUST prove that migrating SUB-002 changes NOTHING else.

## THE MEASURED BASELINE (this ACT's fresh C0 measurements)

```text
PARSER_ASSERTIONS=376/376
PARSER_ASSERTION_FILES=90
PARSER_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
LEXER07_DIRECT_DIFFERENTIAL=89/89
LEXER08_DIRECT_DIFFERENTIAL=45/45
LEXER09_DIRECT_DIFFERENTIAL=23/23
LEXER07_BROAD_STATUS=FAIL_KNOWN_BASELINE
LEXER07_FAILURE_IDENTITIES=15
LEXER07_FAILURE_IDENTITY_MD5=7ee761440de83552e751e3c3976c1683
CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX
CROSS_TARGET_PREFIX_FAILURES=67
F_NO_PYTHON=FAIL_KNOWN_BASELINE
F_NO_PYTHON_VIOLATIONS=12
F_POLYC_TOOLS=UNAVAILABLE
```

## WHAT THE SUCCESSOR MUST RE-RUN, AND WHAT IT MUST REPORT

| Check | Requirement |
|---|---|
| Parser suite | 376/376 over 90 files, and the per-test PASSED-sequence MD5 MUST be exactly `b6f117eb1386ca80f81bc06226e2a741`. Zero new failed IDs. |
| Lexer07/08/09 direct differentials | 89/89, 45/45, 23/23, with the exact per-case ID comparison. |
| LEXER07 broad corpus | MUST still FAIL with the EXACT SAME 15 failure identities, MD5 `7ee761440de83552e751e3c3976c1683`. The successor MUST NOT report this as PASS. |
| Cross-target | MUST still report `FAIL_ENVIRONMENT_PREFIX` with 67 missing-prefix cases. The runner's exit 0 does NOT make this a PASS. |
| F-NO-PYTHON | MUST still report `FAIL_KNOWN_BASELINE` with EXACTLY the same 12 paths. Zero new. |
| F-POLYC-TOOLS | MUST still report `UNAVAILABLE`. The checker is not landed; the successor MUST NOT claim it PASSES merely because its new code is PolyC. |
| gate-fast / gate-push | MUST execute and PASS, with the command and the exit captured. |

## THE "ZERO NEW FAILURE IDENTITIES" RULE

The conservation check is not "the counts are the same". It is "the
FAILURE IDENTITY SETS are the same". The successor MUST compare the
exact identity sets (or their MD5s) against the values above, and
MUST report any new identity by its exact ID.

## THE KNOWN-BASELINE RULE

A historical failure that is still failing, with the same identity, is
NOT a new regression and MUST NOT be reported as one. But it MUST
ALSO NOT be relabelled as a PASS. Both directions are errors.

## THE PRODUCTION SEMANTIC DELTA

The successor's migration MUST be a pure delegation of the SUB-002
decision. It MUST NOT change:

* the `do { ... } while (1)` default-arm loop,
* the `parseStatement(cc)` call,
* the `listAppend(stmts, stmt)` host AST write,
* the token-cursor handling,
* the recovery state,
* the diagnostics,
* any other decision.

`PRODUCTION_SEMANTIC_DELTA` for the successor is the number of
changed production decisions, and it MUST be exactly 1 (the SUB-002
decision) if the successor PASSES.
