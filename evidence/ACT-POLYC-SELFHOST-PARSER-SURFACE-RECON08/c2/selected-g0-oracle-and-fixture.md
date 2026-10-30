# The Selected Successor Contract — G0 Oracle and Fixture

**ACT:** ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
**Selected candidate:** `SUB-004`

---

## 1. The G0 oracle: a REAL production translation unit, selector OFF

The G0 oracle is **not** a hand-transcription of the rule. It is the
real `src/parser.c` translation unit, compiled with the
candidate-specific selector **OFF**, so that the legacy switch body
is the one being executed.

| Requirement | How it is met |
|---|---|
| built from the real production TU | `src/parser.c` is compiled by the real CMake graph with `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH` undefined |
| the legacy body is the one that runs | the selector is OFF, so the `#else` arm is live |
| the G0 object imports no PolyC successor symbol | the build MUST FAIL if the selector-OFF object imports `BootstrapStatementDispatch`; that is the fail-closed check |
| it is not a re-implementation | the oracle is the production object, not a copy |

The negative control `R8-CC-02` supplies a **handmade** oracle and a
**PolyC-importing** oracle and requires the detector
`G0_NOT_GENUINE_C_TU` to fire on both.

---

## 2. The fixture: source-derived, enum-bound, branch-complete

The fixture is derived from the **source and the enum**, not from a
prose description.

### 2.1 The partitions

| Partition | Rows | Derivation |
|---|---|---|
| `P0-NONKEYWORD` | 1 | a token whose `tk_type` is not `TK_KEYWORD` (e.g. `TK_IDENT`) |
| `P1-KEYWORD` | one per `KW_*` arm in the frozen range | each `case KW_*:` label in `src/parser.c 1864..1877` |
| `P2-UNKNOWN-KEYWORD` | 1 | a `keyword_id` that is in the `TK_KEYWORD` class but is not any arm of the dispatch |
| `P3-EXTREME` | 2 | `I64` extremes (the minimum and the maximum) in each of the two parameters |

### 2.2 The expected value for each row

The expected value is **derived from the source**, independently of
the implementation:

* for `P0-NONKEYWORD`, the expected selector is the
  *not-a-keyword-statement* value: the `TK_KEYWORD` guard means the
  dispatch is not entered;
* for `P1-KEYWORD`, the expected selector is the constructor that the
  corresponding `case` label names, read from the source text;
* for `P2-UNKNOWN-KEYWORD`, the expected selector is the
  *not-a-keyword-statement* value;
* for `P3-EXTREME`, the expected selector is likewise the
  *not-a-keyword-statement* value, because no `KW_*` value equals an
  `I64` extreme.

The fixture's expected values are produced by a **source-bound
generator** that reads the `case` labels out of
`src/parser.c 1864..1877`, and are checked against an **independent
enum witness** that reads the `KW_*` values out of `src/lexer.h`.
The two must agree row-for-row.

### 2.3 The witness channels

| Channel | What it observes |
|---|---|
| `W-OBJ` | the compiled object's sha256, for the ACCEPT/REJECT outcome |
| `W-DIAG` | the compiler's diagnostic **text**, which names the constructor that ran |
| `W-RUN` | the runtime output of a compiled witness program, where the dispatch's effect is observable in the program's behaviour |

`W-DIAG` is the channel that makes the dispatch's outcome observable
at all, and it is the channel the RECON08 mutant experiment used.

---

## 3. The discriminating witness, and why it discriminates

`w2` is an `if` whose body is a **declaration**:

```polyc
I32 Main(I32 argc, U8 **argv)
{
  I64 x = 1;
  if (x) I64 y = 2;
  return 0;
}
```

* `parseIfStatement` **accepts** a declaration body;
* `parseWhileStatement` **rejects** it through
  `parseValidPostControlFlowToken`.

So the two compilers produce **different diagnostic text** for the
same source. The message names the constructor, which makes the
observation about the decision's *outcome* rather than about the
mere presence of a symbol.

---

## 4. The bound on the fixture

The fixture's row count is bounded by the number of `case` labels in
the frozen range plus the four non-keyword partitions. It is **not**
an unbounded enumeration of the `I64` domain: the domain is covered
by *partitions* with a stated reason, and each partition's expected
value is derived from the source.

A full enumeration of the `I64` domain is neither necessary nor
possible. The partitions above are exhaustive over the decision's
*reachable* behaviour: every input that the production guard admits
falls into `P0` or `P1`, and `P2`/`P3` cover the unreachable
remainder by declared, source-derived expectations.
