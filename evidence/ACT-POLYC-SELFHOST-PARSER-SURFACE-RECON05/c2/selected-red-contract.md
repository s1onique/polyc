# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SELECTED RED CONTRACT

**Selected candidate:** `SUB-003`
**Source:** `src/parser.c:2049`
**SHA-256:** `378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8`

---

## 1. What the successor must reproduce

The successor implements the PolyC component and delegates the
production decision to it. Before it can claim the migration, it must
reproduce the following REDs against the **real** production compiler.

### RED-01 — the PolyC component does not exist yet

```text
COMMAND=nm build/CMakeFiles/hcc.dir/parser.c.o | grep BootstrapCompoundBlockAppendsStatement
EXPECTED=(no output)
REASON=The production object must NOT reference the proposed symbol
        before the delegation is implemented.
```

### RED-02 — the delegation is not load-bearing

```text
COMMAND=nm build/CMakeFiles/hcc.dir/parser.c.o | grep BootstrapCompoundBlockAppendsStatement
EXPECTED=U _BootstrapCompoundBlockAppendsStatement
REASON=The production object must IMPORT the PolyC symbol as an
        UNDEFINED reference.  A symbol that merely EXISTS in the final
        binary does NOT satisfy this.
```

### RED-03 — the legacy decision is still compiled in

```text
COMMAND=objdump -d build/CMakeFiles/hcc.dir/parser.c.o
EXPECTED=The wrapper's disassembly is a PURE CALL: no comparison of
        263 (AST_DECL), no comparison of 256 (AST_GVAR), and no
        constant that encodes the decision.
REASON=The legacy C body must be COMPILED OUT of the active production
        authority, not merely bypassed.
```

### RED-04 — the component's ABI is wrong

```text
COMMAND=<the differential> <the fixture>
EXPECTED=The component's result differs from the real C oracle on at
        least one fixture row.
REASON=The component must be shown to be a FAITHFUL transcription
        before it can be trusted to replace the C decision.
```

### RED-05 — the causal direction is not established

```text
COMMAND=<the disposable worktree mutation experiment>
EXPECTED=Removing the SUB-003 decision from the REAL compiler changes
        the compiled behaviour in the OBSERVED direction.
REASON=The EXECUTED experiment in this ACT established that direction:
        the pristine compiler compiles and runs the witness, and the
        mutant compiler FAILS TO COMPILE it with
        "ERROR: Mapping exists for 1 -> %l2 i64 local".
```

## 2. The REDs that must be SHOWN TO FAIL before the fix

| RED | Predecessor state | Required successor state |
|---|---|---|
| RED-01 | the symbol is absent | the symbol is absent (the pre-state) |
| RED-02 | the symbol is absent | the symbol is an UNDEFINED reference |
| RED-03 | the C comparison is present in the object | the C comparison is GONE and a pure CALL is present |
| RED-04 | no component exists | the component matches the real C oracle on every fixture row |
| RED-05 | the C decision is active | the C decision is delegated and the behaviour is unchanged |

## 3. The conservation baseline the successor must not break

```text
PARSER_HOST_ARCH_ASSERTIONS=376/376
PARSER_HOST_ARCH_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
LEXER07_BROAD_CORPUS_FAILURE_IDENTITY_MD5=7ee761440de83552e751e3c3976c1683
CROSS_TARGET=67 attempted / 67 failed-to-open-file / 0 passed
GATE_FAST=PASS
GATE_PUSH=PASS
```

The assertion-sequence MD5 is the **exact** identity of the 90-file
production suite.  A successor that changes it has changed the
production semantics, and that is a HALT, not a PASS.
