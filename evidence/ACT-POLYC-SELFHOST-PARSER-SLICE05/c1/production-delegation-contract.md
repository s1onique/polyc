# ACT-POLYC-SELFHOST-PARSER-SLICE05 -- C1 PRODUCTION-DELEGATION CONTRACT

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** production-delegation-contract

## 1. The switch

```text
HCC_USE_SELFHOST_PARSER_AST_UNARY
```

```text
PRODUCTION_DEFAULT=ON
STAGE0_BUILD=OFF
LEGACY_ORACLE_BUILD=OFF
```

* The **production** compiler defines it.  The `ON` branch delegates.
* The **stage0** compiler does not define it.  The stage0 compiler must
  not depend on a component that does not exist yet, and it must remain
  the LEGACY control that produces the other PolyC subjects.
* The **legacy oracle** does not define it, so the oracle executes the
  REAL legacy switch body.

The switch is a **DEDICATED** selector, exactly like the predecessor's
`HCC_USE_SELFHOST_PARSER_AST_BINOP`.  It is deliberately NOT the generic
`HCC_USE_SELFHOST_COMPONENTS` flag, because that flag also activates
the lexer delegations in `src/lexer.c`, which would require linking the
lexer subjects too.  The AST-operator migrations are independent of the
lexer migrations and are scoped to their own flags.

## 2. The C adapter's exact duties

The production wrapper **retains the original C signature**:

```c
int astUnaryOpFromToken(s64 op, AstUnOp *_result);
```

The adapter owns exactly three mechanical duties, and NOTHING else:

1. **Argument projection** -- `s64 op` -> `I64 token_value`.
2. **Success/failure conversion** -- the `-1` sentinel -> the boolean
   return value.
3. **Conditional enum storage** -- the write through `_result`, and
   ONLY on success.

The adapter must **not** own token classification.  There is no switch,
no table, no range test, and no fallback call to the legacy C mapping in
the production branch.

```text
TOKEN_DECISION_OWNER=POLYC
C_ADAPTER_CONDITIONAL_STORAGE=YES
LEGACY_SWITCH_EXECUTED=NO
```

**No shadow verification.**  The production branch does not call the
PolyC component and then check the legacy result against it.  That
would be a second decision path and would mask a divergence rather than
expose it.

**No fallback.**  There is no call to the legacy C mapping before,
after, or alongside the delegation.

## 3. The required behaviour

```text
success: return_value=1, output_after_call=<mapped AstUnOp>
failure: return_value=0, output_after_call=output_before_call
```

A failed lookup must **not** overwrite the caller's output storage.

## 4. The legacy switch is RETAINED in the OFF branch

The legacy C switch stays in the `#else` branch.  This is deliberate:

* the **stage0** compiler needs it (it must not depend on a PolyC
  subject that does not exist yet);
* the **legacy oracle** needs it (the G0 generation and the
  differential oracle must be the REAL legacy code, not a
  reimplementation of it).

The legacy switch is **not** on the production path.  It is inside the
preprocessor branch that the production compiler does not select.

## 5. The fail-closed requirement

When the flag is ON, the production build MUST have a **verified** PolyC
subject object carrying the exported symbol
`BootstrapAstUnaryOpFromToken` as a single **strong global text
definition**.

The verifier MUST reject:

```text
MISSING_OBJECT
EMPTY_OBJECT
INVALID_OBJECT_FORMAT
UNDEFINED_ONLY_SYMBOL
LOCAL_ONLY_SYMBOL
WEAK_ONLY_SYMBOL
DUPLICATE_STRONG_DEFINITION
WRONG_SYMBOL_NAME
```

A legitimate strong global symbol MUST PASS on the actual target
platform.

Mach-O naming MUST NOT be hard-coded into generic ELF verification: the
expected symbol's object-format spelling is derived from the TARGET
OBJECT FORMAT, which is passed in explicitly.

The verification MUST execute for the **current** subject rather than
trusting an old stamp.  The stamp file is a RECORD of a successful
verification, never the thing that decides whether a verification
happens.

## 6. The frozen binary-classifier boundary

The binary classifier is **frozen**:

* `astBinOpFromToken`'s source body MUST remain byte-identical to the
  ENTRY HEAD;
* its production authority MUST remain `BootstrapAstBinOpFromToken`;
* its production causal path MUST remain functional.

The only production file that changes in the AST source is
`src/ast.c`, and within it only the unary classifier's body and the
minimum declaration/conditional-compilation needed for its delegation.

## 7. The frozen scope of the production mutation

```text
src/ast.c
src/CMakeLists.txt
```

`src/ast.c` may change only:

* the selected unary-classifier body, and
* the minimum declaration or conditional compilation needed for its
  delegation.

Nothing else in `src/ast.c` may change.  In particular the binary
classifier's body, the ABI, and every other function are frozen.

## 8. The proof obligation

The delegation MUST be **load-bearing**, which means:

* the production `ast.c.o` MUST reference the PolyC symbol;
* the linked production compiler MUST contain the PolyC symbol's strong
  definition;
* the legacy unary mapping MUST NOT be present on the production path;
* mutating the PolyC subject MUST change the behaviour of a real
  compiled program (see the mutation contract).
