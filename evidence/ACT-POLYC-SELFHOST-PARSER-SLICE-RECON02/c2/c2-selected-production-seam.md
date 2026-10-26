# Selected Production Seam — CAND-001 `parseValidPostControlFlowToken`

ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT_PHASE=C2-RANK-SELECT
EVIDENCE_KIND=selected-production-seam

```text
PRODUCTION_SEAM_FEASIBLE=YES
SEAM_KIND=ORDINARY_CALL_SITE (not a function-pointer callback contract)
```

---

## 1. Why this seam is different from the rejected candidates

Every rejected candidate fails on the seam, not on the state boundary:

| Candidate | R0 | Why the seam fails |
|---|---|---|
| CAND-004 `CalcUnionSize` | 0 | Its ONLY call site is a **function-pointer argument**: `parseClassOrUnion(cc, cc->uniondefs, 0, CalcUnionSize, 0)` at `src/parser.c:722`, typed `u32 (*computeSize)(List *)`. Delegating it means changing that callback contract in production source and materialising a bounded copied size sequence on every call. |
| CAND-008 `asmTextHasReturn` | 1 | Its call site passes an `AoStr*` of **unbounded length** (`src/parser.c:2193`). A bounded ABI needs a length-capped copy, which changes the semantics for large asm bodies. |
| CAND-005/006/007 | 2 | Their call sites pass a **live `Ast*`** whose size is unbounded (`src/parser.c:2355` for CAND-007; the others are reachable only through it). A bounded copied AST projection of an entire function body is not bounded. |
| CAND-003 `CalcClassSize` | 4 | Host-graph writer (`src/parser.c:424`), and its call site is also a function-pointer argument (`src/parser.c:718`). |

CAND-001 has none of these problems. Its five call sites are ordinary
calls whose integer result is used only as a boolean.

---

## 2. The seam, exactly

```c
/* src/parser.c:950 -- parseIfStatement */
    Lexeme *peek = cctrlTokenPeek(cc);
    if (peek == NULL) {
        cctrlRaiseException(cc, "Unexpected end of input");
    }
    if (!parseValidPostControlFlowToken(peek)) {
        cctrlRaiseException(cc,"Unexpected %s `%.*s` while parsing if body",
                lexemeTypeToString(peek->tk_type), peek->len, peek->start);
    }
```

The shape at every one of the five sites is:

```text
    Lexeme *<name> = cctrlTokenPeek(cc);          /* or epeek */
    if (<name> == NULL) {
        cctrlRaiseException(cc, "Unexpected end of input");
    }
    if (!parseValidPostControlFlowToken(<name>)) {
        <optional token resync>
        cctrlRaiseException(cc, "Unexpected %s `%.*s` while parsing <region> body",
                lexemeTypeToString(<name>->tk_type), <name>->len, <name>->start);
    }
```

### Invariants of the seam

1. **The token pointer is never NULL at the call site.** Every site
   checks `peek == NULL` and raises "Unexpected end of input" BEFORE
   calling. So the NULL branch of the component is a defensive branch
   that production does not currently reach through these five sites —
   but it is still part of the C function's contract and MUST be
   reproduced (fixture F001).

2. **The result is consumed as a boolean only.** `!parseValidPostControlFlowToken(...)`.
   The exact integer value is never compared against anything but zero.

3. **Diagnostic ownership stays in C.** Every rejection site calls
   `cctrlRaiseException` on the C side, using `lexemeTypeToString`,
   `peek->len` and `peek->start`. None of that moves into PolyC.

4. **Token resync stays in C.** Two sites resynchronise before
   raising: `cctrlTokenRewind` x2 at `src/parser.c:962-963`, and
   `cctrlRewindUntilStrMatch` at `src/parser.c:1322`. These are token
   stream operations, not semantic decisions, and they stay in C.

5. **No parser state machine moves.** The call sites are inside
   `parseIfStatement`, `parseForStatement`, `parseWhileStatement` and
   `parseDoWhileStatement`. Delegating the decision does NOT move any
   of those functions, their `Cctrl *` handling, their recovery
   ownership, or their subordinate-parser callbacks.

---

## 3. The projection the C side must perform

At each call site the C side projects three scalars out of the token:

```c
present = (tok != NULL) ? 1 : 0;
kind    = tok->tk_type;      /* int  */
value   = tok->i64;          /* s64  */
```

and passes them to the PolyC component, which returns 0 or 1.

The projection is:

- **total** — every `Lexeme` has a `tk_type` and an `i64`;
- **deterministic** — a pure field read;
- **lossless for this decision** — the C function reads no other field,
  so the projection preserves every bit the decision depends on;
- **bounded** — three scalars.

No pointer crosses the boundary in either direction.

---

## 4. Precedent: the completed padding migration

This seam shape is the SAME shape the completed padding migration
used, and that is why it is known to work:

```text
CAND-002 CalcPadding:
  5 call sites, all ordinary calls, all `int` in / `int` out.
  Production delegation implemented under a DEDICATED macro
  (HCC_USE_SELFHOST_PARSER_PADDING), with the legacy C body confined to
  the #else branch so that production never compiles it.
  -> evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/
     c3/c3-production-authority-conservation.txt
     PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC
     LEGACY_RUNTIME_AUTHORITY=RETIRED
```

The successor for CAND-001 will use an analogous (but separate) macro,
so the two migrations remain independently switchable — exactly as the
padding ACT's comment in `src/parser.c:433-441` explains for the lexer
migrations.

---

## 5. Feasibility verdict

```text
The production seam is ORDINARY CALL SITES.
No production callback contract changes.
No parser state machine moves.
No diagnostic ownership moves.
No host pointer crosses the boundary.
The projection is total, deterministic, lossless and bounded.

PRODUCTION_SEAM_FEASIBLE=YES
PRODUCTION_DELEGATION_FEASIBLE=YES
SEAM_RISK=LOW
```

The one thing the successor must be careful about: the dedicated build
switch. The padding migration's own source comment records why a
DEDICATED macro (not the generic `HCC_USE_SELFHOST_COMPONENTS`) was
required — the generic selector also activates the lexer delegations.
The successor MUST follow the same pattern and MUST NOT reuse the
generic selector, or it will drag the lexer subjects into the link.
