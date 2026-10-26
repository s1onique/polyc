# Legacy-C oracle contract — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Selected target:** `parseGetPriority` (`src/prslib.c:1139..1207`)

---

## 1. The oracle authority

The differential MUST compare the PolyC component against the **REAL
legacy-C semantic function**, or against an actual linked legacy
implementation exported through a narrow test seam.

A handwritten reimplementation of the precedence table is **NOT** an
acceptable sole oracle.  Such a reimplementation could share the same
misreading of the legacy source as the PolyC component and would agree
with it while both are wrong.

---

## 2. The adapter strategy

`parseGetPriority` is `static` in `src/prslib.c`, so it cannot be
linked directly from a separate translation unit.  The frozen adapter
strategy is therefore:

```c
/* In src/prslib.c, next to the real function.  This adds NO logic: it
 * calls the real parseGetPriority and returns its result. */
long long ParserLegacyOperatorPrecedenceOracle(long long punct_value) {
    /* The real function takes a Lexeme*.  The oracle seam constructs a
     * lexeme whose ONLY relevant field is i64, because the real
     * function reads only tok->i64. */
    Lexeme lx;
    memset(&lx, 0, sizeof(lx));
    lx.i64 = (s64)punct_value;
    return (long long)parseGetPriority(&lx);
}
```

This is the SAME adapter strategy the two existing parser migrations
use:

```text
src/parser.c:476   ParserLegacyCalcPaddingOracle(long long offset, long long size)
src/parser.c:861   the parseValidPostControlFlowToken delegation adapter
```

The adapter MUST NOT change the semantics of the function it wraps.  The
`memset` + `lx.i64` construction is sound precisely because the real
body reads only `tok->i64` — which this ACT established mechanically
(the single field access in `src/prslib.c:1139..1207`).

**Alternative, equally acceptable adapter:** the successor MAY compile
`src/prslib.c` a second time WITHOUT the delegation macro (the
"stage0 legacy" pattern the padding migration uses to build
`build/parser-padding-legacy.o`) and link that object as the oracle.
That variant exercises the byte-identical legacy source, which is
strictly stronger.  Either strategy is acceptable; the successor MUST
state which one it uses.

---

## 3. What the differential must compare

```text
For every fixture row:
    polyc_result = BootstrapOperatorPrecedence(punct_value)
    legacy_result = ParserLegacyOperatorPrecedenceOracle(punct_value)
    ASSERT polyc_result == legacy_result
```

with:

```text
POLYC_INPUT_COUNT   = 1
POLYC_INPUT_TYPE    = I64
LEGACY_INPUT_COUNT  = 1
LEGACY_INPUT_TYPE   = I64 (the punct value)
```

---

## 4. The negative control

The differential MUST include a negative control that shows the
comparison can FAIL.  The canonical control is to feed the oracle a
fixture row whose expected value has been deliberately altered, and to
require that the differential reports a DISAGREEMENT.

Without such a control, a differential that compares nothing would
report `STATUS=PASS`.

---

## 5. The oracle must be the LEGACY build, not the delegated build

When the delegation flag is on, the production `hcc` routes the
precedence decision through the PolyC component.  A differential that
runs against the delegated build would therefore compare the PolyC
component against ITSELF and would be vacuous.

The oracle MUST come from a build in which the delegation flag is OFF,
so that the legacy body is the one being executed.

This is the same discipline the padding migration uses with
`build/parser-padding-legacy.o`.
