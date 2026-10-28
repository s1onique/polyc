# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SELECTED RED CONTRACT

**SELECTED_CANDIDATE:** `SUB-001`
**SELECTED_SOURCE_RANGE:** `src/parser.c:1551..1553`

---

## 0. THE SOURCE DECISION EXISTS; THE COMPONENT DOES NOT

This slice is a NEWLY EXTRACTED sub-slice.  The ACT section 12
distinction applies and is recorded explicitly:

```text
SOURCE_DECISION_EXISTS=YES
EXTRACTED_COMPONENT_EXISTS=NO
```

The C decision is LIVE in the production source at the frozen range.
The PolyC component that would own it does not exist yet.

## 1. The REDs, with exact rerunnable commands and observed results

Every command below was EXECUTED at RECON04's own entry tree, and the
observed result is recorded verbatim.

### RED-1  the selected PolyC component is absent

```sh
ls tools/bootstrap/selfhost-parser-switch-arm.HC
grep -rn 'BootstrapSwitchArmTerminates' src/ tools/
```

Observed:

```text
ls: cannot access 'tools/bootstrap/selfhost-parser-switch-arm.HC': No such file or directory
(no match for BootstrapSwitchArmTerminates)
```

### RED-2  the production delegation is absent

```sh
grep -c 'HCC_USE_SELFHOST_PARSER_SWITCH_ARM' src/CMakeLists.txt src/parser.c
```

Observed:

```text
src/CMakeLists.txt:0
src/parser.c:0
```

### RED-3  the legacy C decision still owns the production semantics

```sh
sed -n '1551,1553p' src/parser.c
```

Observed:

```c
        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE ||
                stmt->kind == AST_DEFAULT || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
                || stmt->kind == AST_GOTO) break;
```

The condition is the LIVE production condition; there is no
`#ifdef` around it and no delegation.

### RED-4  the expected ABI/bridge is not yet available

```sh
nm build/CMakeFiles/hcc.dir/parser.c.o | grep -c BootstrapSwitchArmTerminates
```

Observed:

```text
0
```

The production object neither defines nor imports the PolyC symbol, so
the bridge does not exist.

### RED-5  mutation-sensitive production behaviour is established on the legacy oracle

This RED is already GREEN at RECON04 time, and it is recorded as the
successor's RED-5 precondition: the mutation-sensitive behaviour MUST
be established on the LEGACY oracle before the PolyC component is
allowed to replace it.

```sh
cc -std=c99 -O1 -I src -o build/recon04-oracle/legacy-sub001-oracle \
    build/recon04-oracle/legacy-sub001-oracle.c
build/recon04-oracle/legacy-sub001-oracle
```

Observed: 51 rows; the terminating kinds are exactly
`258 270 274 280 287 293`.

And the production-level mutation experiment was EXECUTED (see
c2/selected-causal-contract.md):

```text
PRISTINE_BUILD=PASS
MUTANT_BUILD=PASS
RESTORED_BUILD=PASS
MUTATED_OUTPUT_DIFFERS=YES
RESTORED_OUTPUT_EQUALS_PRISTINE=YES
```

## 2. What the successor must reproduce

The successor MUST reproduce RED-1, RED-2, RED-3 and RED-4 at its OWN
entry HEAD, with the same commands, and MUST observe the same results.
If any of them is already green at the successor's entry HEAD, the
successor has already implemented part of the slice and MUST record
that rather than claim a fresh RED.

RED-5 is already established; the successor MUST carry it forward and
extend it to the PolyC component (the mutation must then be applied to
the POLYC decision, not to the C condition).

## 3. The successor's own post-implementation REDs

After the successor implements the slice, the following must become
GREEN, and each must be proven by an OBSERVATION, not by a symbol
appearing in a binary:

```text
GREEN-1  the production object imports BootstrapSwitchArmTerminates
         (U) and does NOT contain the legacy condition
GREEN-2  the four-generation differential over the 51-row matrix is
         byte-identical across G0..G3
GREEN-3  the production causal experiment changes the compiled program
         output when the POLYC decision is mutated, and returns to the
         pristine output when it is restored
GREEN-4  the parser and lexer conservation suites have zero new
         failure identities
```
