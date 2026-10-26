# ACT-POLYC-SELFHOST-PARSER-SLICE02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Implement the PolyC component
`BootstrapValidPostControlFlowToken` and transfer production
control-flow-token authority from legacy C to it

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** SELFHOST / PRODUCTION-AUTHORITY-MIGRATION

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01`
(closed `PASS`; the corrected successor-facing contract is
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c2/c2-corrected-contract.tsv`)

**Entry HEAD:** `4fa6c8f05e6e8e379d81c4340da59c722ec1f7e3`

**Target surface:** the token that may begin a statement after a
control-flow header

**Legacy authority:** `src/parser.c::parseValidPostControlFlowToken`

**Qualified PolyC subject:**
`tools/bootstrap/selfhost-parser-control-flow-token.HC::BootstrapValidPostControlFlowToken`

**Transition:**

```text
LEGACY_C
   ↓
POLYC_PRODUCTION_AUTHORITY
```

---

## 0. Mission

Implement the control-flow-token decision in PolyC, prove it against the
real legacy C function, and make the production compiler actually consume
the PolyC result — without changing the decision's semantics.

At successful close:

```text
CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY = POLYC
LEGACY_PARSE_VALID_POST_CONTROL_FLOW_TOKEN_AUTHORITY = RETIRED
BootstrapValidPostControlFlowToken = LOAD_BEARING_IN_PRODUCTION
```

---

## 1. Why this ACT is now authorized

The predecessor recon selected exactly one candidate and the correction
ACT published a satisfiable contract for it:

```text
SELECTED_CANDIDATE       = CAND-001 parseValidPostControlFlowToken
SOURCE_RANGE             = src/parser.c:832..864
ABI                      = I64 BootstrapValidPostControlFlowToken(
                             I64 present, I64 kind, I64 value) -> I64
ABI_HOST_IDENTITY_FIELDS = 0
ELIGIBLE_SET             = {CAND-001}
CORRECTED_FIXTURE_COUNT  = 42  (23 accept, 19 reject)
CORRECTED_ORACLE_DISAGREEMENTS = 0
```

The successor's differential is therefore satisfiable, and the selected
candidate is uniquely determined. No further reconnaissance is required.

---

## 2. Core invariant

The migration must preserve the legacy semantic function exactly:

```text
valid_post_control_flow_token(present, kind, value) =
    0                                      if present == 0
    1                                      if kind == TK_IDENT  (0x300)
    1                                      if kind == TK_STR    (0x301)
    1                                      if kind == TK_PUNCT  (0x329)
                                               and value in
                                               {0x306, 0x305, 0x7B,
                                                0x3B, 0x2A}
    1                                      if kind == TK_KEYWORD(0x332)
                                               and value in
                                               {66, 38, 44, 46, 18, 20,
                                                40, 24, 26, 80, 82, 28}
    0                                      otherwise
```

```text
CONTROL_FLOW_TOKEN_SEMANTIC_DELTA = 0
```

### 2.1 The aliasing that MUST be honoured

`src/lexer.h` defines

```text
line 15:  #define TK_SUPERSCRIPT  0x301
line 19:  #define TK_STR          0x301
```

The two names denote the **same number**. The legacy body compares the
kind **by number** (`tok->tk_type == TK_STR`), so kind `0x301` is
`TK_STR` and is **ACCEPTED**, whatever the payload. At the ABI level
there is no distinct "superscript" kind.

A subject that assumed a distinct value would produce a different result
and would FAIL the differential. Fixture F041 pins this.

---

## 3. Frozen ABI

```text
I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value);
```

| Field | Type | Meaning |
|-------|------|---------|
| `present` | I64 | 1 when a token is present, 0 when the token is absent (the legacy NULL `Lexeme`) |
---

## 4. Scope

### allowed

- `tools/bootstrap/selfhost-parser-control-flow-token.HC` (the subject)
- `tools/quality/parser-control-flow-token-differential.HC` (the PolyC
  comparison layer)
- `tools/quality/parser-slice02-oracle.c`,
  `tools/quality/parser-slice02-oracle.h`,
  `tools/quality/parser-control-flow-token-oracle-impl.c` (the oracle)
- `tools/quality/slice02-is-terminal-stub.c` (the link stub)
- `src/cmake/VerifyControlFlowTokenObject.cmake` (the fail-closed check)
- `src/parser.c` (the production delegation)
- `src/CMakeLists.txt` (the component wiring)
- `Makefile` (the build targets)
- `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02/**`
- `docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE02.md`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02.md`
- `docs/factory/act-handoff-map.tsv` (one appended row)
- `docs/ROADMAP.md` (one appended status section)

### forbidden

- changing the decision's semantics
- changing the selected candidate, the ABI, the eligibility conjunction
  or the scoring
- any change to the predecessor's corrected contract artifacts
- any history rewrite: no amend, rebase, reset, force-push,
  filter-branch, filter-repo or git replace
- a silent C fallback on the migrated path

---

## 5. Principal RED

The RED is the **absence** of the PolyC subject and of the production
delegation:

```text
tools/bootstrap/selfhost-parser-control-flow-token.HC   -> ABSENT
src/parser.c delegation to BootstrapValidPostControlFlowToken -> ABSENT
production ./hcc links _BootstrapValidPostControlFlowToken -> NO
```

A RED that is satisfied by a synthetic mock is not acceptable here: the
seam is the real production function and the real production binary.

---

## 6. Implementation boundary

1. The PolyC subject, compiled by the **stage-0** compiler so that the
   component does not depend on the production compiler it serves.
2. The oracle: the **verbatim** production body from `src/parser.c`,
   bound to the **live** `src/lexer.h`.
3. The PolyC comparison layer, which is the terminal authority.
4. The production delegation in `src/parser.c`, guarded by
   `HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN`.
5. The fail-closed build wiring: a missing or symbol-less component is a
   hard build error, never a silent legacy fallback.

---

## 7. Acceptance criteria

See `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02/c3/mandatory-ac-status.tsv`
(AC01..AC12, each with a concrete re-runnable command).

---

## 8. Conservation gates

- `make gate-fast` -> RC=0
- `sh scripts/quality/factory-v2-test.sh` -> PASS=53 FAIL=0
- `sh scripts/quality/factory-append-only-test.sh` -> PASS=11 FAIL=0
- `git diff --check <first>..<close>` -> RC=0
- the sibling parser-padding differential -> PASS (16640/16640)
- `sh scripts/quality/static-function-linkage-test.sh` -> PASS

---

## 9. Halt taxonomy

- `HALT_SCOPE_EXPANSION_REQUIRED`
- `HALT_F14_VIOLATION`
- `HALT_PRODUCTION_MUTATION`
- `HALT_MANDATORY_AC_NOT_GREEN`
- `HALT_SEMANTIC_DELTA_NONZERO`

---

## 10. Commit topology

```text
1. RED      (the subject, the oracle and the differential, green)
2. EVIDENCE (the production delegation and the causal control)
3. CLOSE    (the HANDOFF and the closure verification)
```

---

## 11. Closure handoff

`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02.md`.

The CLOSE commit carries:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE02
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

| `kind`    | I64 | the token kind **number**, bound to the live `src/lexer.h` values |
| `value`   | I64 | the token payload, meaningful only for the kinds that dispatch on a payload |

| Constraint | Value |
|------------|-------|
| `ABI_HOST_IDENTITY_FIELDS` | 0 |
| Host dependency | none (no parser / lexer / cctrl / ast) |
| Allocation | none |
| Global mutable state | none |

The bound constants, taken from the **live** `src/lexer.h`:

```text
TK_IDENT    0x300     TK_STR      0x301
TK_PUNCT    0x329     TK_KEYWORD  0x332
TK_PLUS_PLUS 0x305    TK_MINUS_MINUS 0x306
'{'         0x7B      ';'         0x3B      '*'  0x2A
KW_DO 66  KW_FOR 38  KW_GOTO 44  KW_IF 46  KW_RETURN 18
KW_SWITCH 20  KW_WHILE 40  KW_BREAK 24  KW_CONTINUE 26
KW_TRY 80  KW_THROW 82  KW_ASM 28
```
