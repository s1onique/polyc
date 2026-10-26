# HANDOFF — ACT-POLYC-SELFHOST-PARSER-SLICE02

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** SELFHOST / PRODUCTION-AUTHORITY-MIGRATION

**Predecessor:** ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01

**Production semantic changes:** the production control-flow-token
decision now comes from the PolyC component. The DECISION ITSELF is
unchanged.

---

## 1. What this ACT did

Implemented the PolyC component
`BootstrapValidPostControlFlowToken`, proved it against the real legacy C
function, and transferred production authority to it.

```text
LEGACY_C
   ↓
POLYC_PRODUCTION_AUTHORITY
```

The component is compiled by the **stage-0** compiler, so it does not
depend on the production compiler it serves.

## 2. The component

| Item | Value |
|------|-------|
| Source | `tools/bootstrap/selfhost-parser-control-flow-token.HC` |
| Symbol | `_BootstrapValidPostControlFlowToken` |
| ABI | `I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value) -> I64` |
| `ABI_HOST_IDENTITY_FIELDS` | 0 |
| Host dependency | none |
| Allocation | none |
| Global mutable state | none |

### The aliasing it honours

`src/lexer.h:15` defines `TK_SUPERSCRIPT 0x301` and `src/lexer.h:19`
defines `TK_STR 0x301` — the **same number**. The legacy body compares
the kind **by number**, so kind `0x301` is `TK_STR` and is **accepted**,
whatever the payload. The subject binds the kind **by number**, so it
matches. Fixture F041 pins this.

## 3. The proof

### The oracle IS the production function

The oracle carries the production body of `src/parser.c` **verbatim**
(only the function name differs, so the copied oracle and the real
production function can be linked into the same binary) and includes the
**live** `src/lexer.h`, so its constants are production values.

Its equivalence with the real production object is established by a
cross-check that links **both** and compares them:

```text
CROSS_ROWS=326 CROSS_SAME=326 CROSS_DIFF=0
```

326 comparisons — 12 kinds × 27 payloads, plus the two absent-token
cases — all identical.

### The direct differential

The comparison layer is **PolyC** (terminal authority). It calls the
PolyC subject and the C oracle on every row, and also checks the
fixture's own `expected` column against the oracle, so a subject/oracle
disagreement cannot be masked by an equally wrong fixture.

```text
SLICE02_DIFFERENTIAL_TOTAL=42
SLICE02_DIFFERENTIAL_PASS=42
SLICE02_DIFFERENTIAL_FAIL=0
SLICE02_DIFFERENTIAL_PARSE_ERRORS=0
SLICE02_DIFFERENTIAL_ORACLE_VS_EXPECTED_MISMATCH=0
STATUS=PASS
```

### The negative controls

The differential is only meaningful if it fails when it should:

| Control | Expectation | Observed |
|---------|-------------|----------|
| NC1 — the predecessor's frozen matrix (F041 stated 0) | rejected | `ORACLE_VS_EXPECTED_MISMATCH=1`, `STATUS=FAIL`, exit 1 |
| M1 — subject rejects kind `0x301` | detected | 39 pass / **3 fail** (F005, F006, F041) |
| M2 — subject accepts the absent token | detected | 41 pass / **1 fail** (F001) |
| M3 — subject rejects the `'*'` payload | detected | 41 pass / **1 fail** |
| M4 — subject rejects `KW_TRY` | detected | 41 pass / **1 fail** |

4 of 4 mutations detected. The subject is restored pristine afterwards.

## 4. Production authority

`CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY=POLYC` requires all of:

| # | Requirement | Evidence |
|---|-------------|----------|
| 1 | production parser code obtains the decision from the PolyC component | the disassembly of the production `parseValidPostControlFlowToken` contains `bl 0x100064304 <_BootstrapValidPostControlFlowToken>` |
| 2 | the legacy C algorithm is not used on the migrated path | the legacy body survives only under the `#else` branch, which the production build never compiles |
| 3 | mutating the subject changes production-observable behavior | the mutant made the production parser raise `Unexpected character `*` while parsing else body` and `... while parsing for loop body` |
| 4 | restoring the pristine subject restores behavior | the same cases compile cleanly again |
| 5 | no silent C fallback | configuring without a producer and with the component absent is a hard `FATAL_ERROR` (exit 1); with a producer the component is produced **and** its exported symbol is verified before the link |

Requirement 3 is the decisive one: a source reference or a linked symbol
is not sufficient, and the causal control establishes that the production
compiler genuinely executes the PolyC code.

## 5. What is NOT changed

| Item | Value | Changed? |
|------|-------|----------|
| Selected candidate | CAND-001 `parseValidPostControlFlowToken` | NO |
| The decision's semantics | the frozen table | NO |
| The ABI | `I64 (I64 present, I64 kind, I64 value) -> I64` | NO |
| `ABI_HOST_IDENTITY_FIELDS` | 0 | NO |
| Bound constants | the live `src/lexer.h` values | NO |
| Production call sites | 5 | NO |
| The predecessor's corrected contract | 42 items, 11 changed, 31 unchanged | NO |

## 6. Gates

```text
GATE_FAST     = PASS (RC=0; manifest PAIR_OK=27 PAIR_FAIL=0)
FACTORY_V2    = PASS (PASS=53 FAIL=0)
APPEND_ONLY   = PASS (PASS=11 FAIL=0)
PATCH_HYGIENE = PASS (git diff --check over the COMMITTED range -> RC=0)
SIBLING_PARSER_PADDING_DIFFERENTIAL = PASS (16640/16640)
STATIC_FUNCTION_LINKAGE_TEST = PASS
AC_LEDGER     = 12 PASS / 0 DEFERRED / 0 FAIL
```

The two checker failures (`F-NO-PYTHON`, `F-POLYC-TOOLS`) are
PRE-EXISTING baseline violations in files this ACT does not touch. They
are **not waived**: their exact results are recorded in
`c3/c3-required-result.txt`.

## 7. Verdict

VERDICT

---

PASS
