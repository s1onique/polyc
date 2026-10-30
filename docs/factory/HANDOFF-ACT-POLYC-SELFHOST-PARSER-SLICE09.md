# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE09

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE09`
**Class:** SELFHOST / PARSER / STRUCTURAL-DISPATCH / PRODUCTION-AUTHORITY-TRANSFER
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08`
(closed, `ACT-Verdict: PASS`, disposition `PASS_SELECTED`)
**Entry:** `ba9cb884cebd2eabe17b53d6125849e180758b01`
(`8d3974e4156c2058c0627e49356360d9807b267c`)

VERDICT

PASS

---

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.  The post-CLOSE terminality receipt is produced **outside**
the repository after the CLOSE commit and is not claimed here.

---

## 1. The outcome, in short

**The production decision of which keyword-specific statement
constructor to invoke has left `src/parser.c` and now lives in one
pure compiled PolyC component.  The C side mechanically routes the
returned selector to the original constructors.**

```text
SELECTED_CANDIDATE_ID              = SUB-004
SELECTED_SOURCE_RANGE              = src/parser.c:1864..1877
SELECTED_SOURCE_SHA256             = cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0
SELECTED_POLYC_SYMBOL              = BootstrapStatementDispatch
SELECTED_ABI                       = I64(token_type, keyword_id) -> I64 statement_selector
PRODUCTION_STATEMENT_DISPATCH_AUTHORITY = POLYC
LEGACY_C_KEYWORD_DISPATCH_AUTHORITY_RETIRED = YES
POLYC_PARSER_AUTHORITIES           = 9   (8 predecessors preserved + 1 new)
```

This does **not** claim whole-parser or whole-compiler self-hosting.
Exactly one semantic decision was migrated.

## 2. The PolyC component

`tools/bootstrap/selfhost-parser-statement-dispatch.HC` exports one
function, `I64 BootstrapStatementDispatch(I64 token_type, I64
keyword_id)`.  It tests only its two scalar arguments, calls no other
function, reads no global, allocates nothing, and crosses no pointer,
callback, AST, cursor, symbol-table or recovery state.  It is total
over the whole I64 domain: every pair maps to a value in `[0,15]`.

Selector encoding (frozen at C0, dense and source-bound, **not** the
numeric KW enum order):

```text
 0 not-a-keyword-statement (the legacy default route)
 1 KW_IF      2 KW_FOR      3 KW_WHILE   4 KW_DO       5 KW_RETURN
 6 KW_TRY     7 KW_THROW    8 KW_SWITCH  9 KW_CASE    10 KW_DEFAULT
11 KW_BREAK  12 KW_CONTINUE 13 KW_ASM   14 KW_STATIC  15 KW_GOTO
```

## 3. The C seam

`src/parser.c` now calls the compiled selector and routes the result
through a mechanical `switch (stmt_sel)` whose every arm performs
exactly the action the original keyword arm performed (same
arguments, side effects, cursor advancement, diagnostics, recovery
and ownership).  The `if (tok->tk_type == TK_KEYWORD)` guard remains
only as the memory-safety/read-order projection: the disassembly
shows the `tok->i64` read strictly after the branch away from the
non-keyword path.  The legacy keyword comparison chain is compiled
out of the ON path and survives only in the selector-OFF object that
is the G0 oracle.

A dedicated option `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH`
defaults **OFF**; the qualified production target passes it **ON**
with a producer, and the stage0 control build passes it **OFF**.

## 4. The four generations

The comparison layer is byte-identical across the four runs; only the
linked decision object differs.

| Gen | Producer | Producer SHA-256 | Object SHA-256 |
|-----|----------|------------------|---------------|
| G0 | `/usr/bin/cc` (real production TU, selector OFF) | `9b11ead1ca76a03d61108ad5bf2c913d6aa8daa7deb9fd28893e847e3680e5e7` | `5df41d012d9602bf21d563d4bc173c2c225fcfadc72c4b50b60a808edc75ed15` |
| G1 | `build/host-stage0/hcc` | `4264610a6286f603503a69ad57411910fe4207db9eade6915be675a38444fd02` | `f9d9c05eaf9c8cb4d2821b9c2c6d59e10116eacdfc3197150855aaef693c1c3d` |
| G2 | `./hcc` | `8a83a8b8e469a0627ae842ecef1cc12fd51a5da8fc71b87b979ea0d9cc18a53b` | `f9d9c05eaf9c8cb4d2821b9c2c6d59e10116eacdfc3197150855aaef693c1c3d` |
| G3 | `build/hcc-bootstrap02` | `95bedab684bbb2ec1dfb464456be6de4c36e89313421476fd0f7f2f0389dc2cc` | `f9d9c05eaf9c8cb4d2821b9c2c6d59e10116eacdfc3197150855aaef693c1c3d` |

The three PolyC producers are pairwise distinct; the three PolyC
objects are byte-identical because compilation is deterministic (the
frozen contract anticipates this).

Frozen fixture: `c1/frozen-dispatch-fixture.tsv`, SHA-256
`12decd1712912ad3bac940de8c5f6de772fd9df677ce62137b6310d13b2a687f`,
**21 rows in 4 partitions**, independently re-derived from the
entry-tree source (`8e68487e…`) and the live lexer enum
(`TK_KEYWORD=818`, 15 arms).  Every generation matches every row, and
**all 12 ordered pairs have full row coverage with zero
disagreements**.

## 5. The causal experiment

A **new** post-migration mutation on the compiled PolyC source, in an
isolated detached worktree at the C2 commit:

```text
mutation:  if (keyword_id == 46) return 1;  ->  return 3;   (KW_IF -> WHILE selector)
pristine:  source 7063b946…  object f9d9c05e…  hcc 117095a7…  w2="while parsing if body"; w3=ACC=12 exit 0
mutant:    source 5ac6c2c9…  object a1510e6d…  hcc 1f77010a…  w2="while parsing while loop body"; w3 altered
restored:  source 7063b946…  object f9d9c05e…  hcc 117095a7…  w2 and w3 recover
CLASSIFICATION = COMPILER_DIAGNOSTIC_PATH_CHANGED
```

The RECON08 PRE-C mutation is **cited**, not rerun, and cannot
discharge this control.  The conditional C-OFF-C mutation was **not
required** by the frozen successor contract and is not claimed.

## 6. Controls

* Inherited RECON08 roster: **24 IDs / 25 physical executions**,
  phase-aware join: 24 historical verified, 2 newly executed,
  2 prohibited as substitutes, 0 unproven.
* SLICE09-owned: **18 controls, 19 physical executions**, all
  sensitive, no vacuous or self-referential rows, sharing declared.
  `S9-CC-01` shares its one physical experiment with
  `RECON08-SUB-004-POST-POLYC-MUTANT`.

## 7. Conservation and gates

```text
PARSER_ASSERTIONS             = 376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5 = b6f117eb1386ca80f81bc06226e2a741
LEXER_DIRECT                  = 89/89, 45/45, 23/23 PASS
LEXER07_BROAD                 = FAIL_KNOWN_BASELINE, 15 IDs, MD5 7ee761440de83552e751e3c3976c1683, REGRESSION=0, DIVERGED=0
CROSS_TARGET                  = FAIL_ENVIRONMENT_PREFIX, 67 cases, one distinct message
F_NO_PYTHON                   = FAIL, 12 historical violations, 0 new
F_POLYC_TOOLS                 = UNAVAILABLE (checker not landed)
GATE_FAST                     = PASS
GATE_PUSH                     = PASS
F14_FREEZE                    = 575 rows, 0 blob/SHA-256 mismatches
APPEND_ONLY                   = 11/11 PASS
FACTORY_V2_RANGE (RECON08)    = PASS
PATCH_HYGIENE (diff --check)  = PASS
```

## 8. Honest findings recorded, not hidden

* The FIRST C3 gate-push attempt failed at configure: the dedicated
  option had default **ON**, so the stage0 control build demanded the
  subject.  Corrected to default OFF with an explicit OFF in the
  stage0 configure.  This was a real build-graph defect found by the
  gate.
* A gate-push attempt then failed at `jit`; the cause was the known
  shared `/tmp/holyc-asm.s` assembly-temporary race (a concurrent
  process was running).  Re-run with nothing else executing, `jit`
  passed.  A further attempt failed only at `diff-check` because one
  evidence file had a trailing blank line at EOF; corrected.
  No failure was concealed.
* The existing RECON08 G0 detector does not reject a purely handmade
  object; a SLICE09-owned provenance detector now does.

## 9. Scope changed

```text
src/parser.c                                   # SUB-004 seam + adjacent oracle wrapper
src/CMakeLists.txt                             # subject option / build / link wiring
Makefile                                       # subject producer, prereq edge, generation + differential rules
tools/bootstrap/selfhost-parser-statement-dispatch.HC
tools/quality/parser-slice09-*.HC / *.c
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE09.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE09.md
docs/factory/act-handoff-map.tsv               # one additive row
docs/ROADMAP.md                                # bounded additive outcome
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/**
```

No other `src/**`, test, gate, `.githooks`, runtime header/ABI or
closed ACT/HANDOFF/evidence was modified.

## 10. Residue (not repaired here)

The known separate debts remain: 15 historical LEXER07 failure IDs,
67 cross-target missing-prefix cases, 12 F-NO-PYTHON violations, the
unlanded F-POLYC-TOOLS checker, the SLICE06 stale CMake producer, the
shared `/tmp/holyc-asm.s` race, the initialized-static-global /
`Main(argc)` collision, the pointer-valued ternary OOM lead, the
canonical checker's source-hash omission, the canonical ranker's
trust of its eligibility column, and the historical SLICE08
self-referential control rows.

```text
NEXT_TARGET      = NONE
SLICE10_AUTHORIZED = NO
```

## 11. Evidence

`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/c0..c4/`.
Phase C3 holds the four-generation differential, the twelve ordered
comparisons, the mutation trilogy, the control joins, the
conservation, the gates, the F14/append-only check and the exact-ID
50-AC ledger.
