# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SELECTED CAUSAL CONTRACT

**Selected candidate:** `SUB-003`
**Source:** `src/parser.c:2049`
**SHA-256:** `378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8`

This contract records the EXECUTED causal experiment for `SUB-003`, and
also the EXECUTED disqualification of `SUB-002`.

---

## 1. The requirement

ACT section 8 item 7:

> In a detached disposable worktree build the real compiler from the
> same tree, compile a witness, mutate ONLY the prospective C decision
> (the PolyC successor does not yet exist), successfully rebuild and run
> the same witness, then restore byte-identical source and compiler
> output. Prove an actual structural compiled-output change for a
> structural candidate, or identify a precise externally observable
> diagnostic/type/IR behavior for an eligible scalar candidate. A
> mutation detected by a source parser only, an oracle-only change, or
> a failed build CANNOT discharge this gate.

---

## 2. The disposition of the worktree

```text
WORKTREE_PATH=/tmp/recon05-wt
WORKTREE_BRANCH=detached
WORKTREE_BASE=525374202a96d5d4235e25ed76cdff5504d65e7b
MUTATION_SCOPE=src/parser.c ONLY
TRACKED_MAIN_WORKTREE_MUTATED=NO
MERGED_OR_COMMITTED_THE_MUTATION=NO
```

Every mutation was applied **only** inside the detached worktree. The
tracked main worktree's `src/parser.c` was never modified.

### 2.1 The restoration proof

```text
COMMAND=git checkout -- src/parser.c
COMMAND=diff src/parser.c <main-worktree>/src/parser.c
RESULT=identical
SHA256_BEFORE=27281d56b4abf2e9fcdd1ecd43f3d349336be114fb1c4d14fcd1ffeae8bd9d35
SHA256_AFTER =27281d56b4abf2e9fcdd1ecd43f3d349336be114fb1c4d14fcd1ffeae8bd9d35
CAUSAL_RESTORATION_BYTE_IDENTICAL=YES
```

---

## 3. THE SELECTED CANDIDATE `SUB-003` — THE CAUSAL PROOF

### 3.1 The mutation

ONE decision is removed: the `SKIP` of a global-variable declaration
inside a compound block.

```diff
--- a/src/parser.c
+++ b/src/parser.c
@@ -2046,10 +2046,6 @@
             }
         } else {
             if ((stmt = parseStatement(cc)) != NULL) {
-                if (stmt->kind == AST_DECL && stmt->declvar->kind == AST_GVAR) {
-                    tok = cctrlTokenPeek(cc);
-                    continue;
-                }
                 listAppend(body->stms,stmt);
             } else {
                 break;
```

The full patch is `c2/probes/sub003-mutant-patch.txt`.

### 3.2 The build

```text
COMMAND=cmake -DCMAKE_BUILD_TYPE=Release -DHCC_ENABLE_JIT=ON \
          -DCMAKE_INSTALL_PREFIX=/tmp/recon05-wt/build/test-prefix ../src
COMMAND=make -j4
RESULT=[100%] Built target hcc
BUILD_EXIT=0
```

The REAL compiler was rebuilt from the SAME tree with ONLY the one
decision mutated.

### 3.3 The witness

`c2/probes/witness-sub003-block-static.HC` declares a `static` variable
**inside a compound block**, which is exactly the shape the `SUB-003`
decision routes.

### 3.4 The observed directional change

| Build                       | Witness compile                                   | Witness run                       |
|-----------------------------|---------------------------------------------------|------------------------------------|
| **PRISTINE** (unmutated)    | **succeeds**                                     | **`WITNESS_OUTPUT=12 2`**, exit 0   |
| **MUTANT** (`SUB-003` gone) | **FAILS**                                        | **no executable produced**         |

The mutant's diagnostic is:

```text
ERROR: Mapping exists for 1 -> %l2 i64 local
```

The mutant is therefore **strictly worse**: it does not merely change
the output, it **destroys the compilation** of a program the pristine
compiler accepts.

### 3.5 The production test suite, run with the mutant

The whole 90-file production suite was compiled and run with the
mutant compiler:

```text
PRISTINE  376/376   md5=b6f117eb1386ca80f81bc06226e2a741
MUTANT    371/371   md5=dc2f36f1bd63bca22fc7ea57359a770d
```

The assertion-sequence MD5 **changed**, and **5 assertions were lost**.
The exact tests that changed are:

```text
Test - local static variables and global variables:   PASSED: 3/3  ->  ERROR
Test - Global and static array                        PASSED: 2/2  ->  ERROR
```

with the mutant's diagnostic:

```text
ERROR: Mapping exists for 1 -> %l11 array local
```

This is the strongest form of the causal gate: the `SUB-003` decision is
**observable in the EXISTING production test suite**, so the suite is
already a ready-made differential for the successor.

### 3.6 The verdict for `SUB-003`

```text
CAUSAL_MUTANT_BUILD=SUCCESS
CAUSAL_WITNESS_DIRECTION=PRISTINE_COMPILES_AND_RUNS / MUTANT_FAILS_TO_COMPILE
CAUSAL_TEST_SUITE_DIRECTION=PRISTINE_376_376_b6f117eb1386ca80f81bc06226e2a741
                           MUTANT_371_371_dc2f36f1bd63bca22fc7ea57359a770d
CAUSAL_DISTINCT_PRODUCTION_BEHAVIOUR=YES
CAUSAL_EXTERNAL_OBSERVABLE_EFFECT=YES
SELECTED_CAUSAL_FEASIBILITY=EXECUTED
```

---

## 4. THE DISQUALIFICATION OF `SUB-002`

`SUB-002` is the canonical rank-1 candidate. It was tested the same
way, and it FAILED.

### 4.1 The mutation

`AST_DEFAULT` is **ADDED** to the `SUB-002` default-arm termination
condition, making it **exactly** the already-migrated `SUB-001`
condition.

```diff
--- a/src/parser.c
+++ b/src/parser.c
@@ -1680,7 +1680,7 @@
         if (stmt && stmt->kind != AST_CASE) {
             listAppend(stmts,stmt);
         }
-        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
+        if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE || stmt->kind == AST_DEFAULT || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
                 || stmt->kind == AST_GOTO) break;
```

The full patch is `c2/probes/sub002-mutant-patch.txt`.

### 4.2 The observed result

```text
PRISTINE  376/376   md5=b6f117eb1386ca80f81bc06226e2a741
MUTANT    376/376   md5=b6f117eb1386ca80f81bc06226e2a741
```

The assertion sequences are **BYTE-IDENTICAL**. The mutation has
**ZERO** observable effect.

A dedicated witness (`c2/probes/witness-sub002-default-arm.HC`, a
switch whose `default` arm contains a nested switch with its own
`default` arm) also produces identical output:

```text
PRISTINE  WITNESS_OUTPUT=2300
MUTANT    WITNESS_OUTPUT=2300
```

### 4.3 Why the mutation has no effect

`AST_DEFAULT` is **unreachable** at that position, and the LIVE SOURCE
says so:

- `src/parser.c:1676` — `parseDefaultStatement` stores the new default
  node in `cc->tmp_default_case`.
- `src/parser.c:1669` — `parseDefaultStatement` raises
  `"Duplicate default case"` if `cc->tmp_default_case` is already
  non-NULL.
- `src/parser.c:1725` — `parseSwitchStatement` clears
  `cc->tmp_default_case` before parsing the switch body.
- `src/parser.c:1737` — the switch body is parsed by `parseStatement`.

So a `default` nested inside a `default` arm hits the
`"Duplicate default case"` check and the inner `parseDefaultStatement`
**never returns normally**. The exception propagates and
`stmt->kind == AST_DEFAULT` is never observed.

Therefore the `SUB-002` condition (five kinds) and the migrated
`SUB-001` condition (the same five plus `AST_DEFAULT`) are
**semantically identical**.

### 4.4 The verdict for `SUB-002`

```text
CAUSAL_MUTANT_BUILD=SUCCESS
CAUSAL_WITNESS_DIRECTION=NO_CHANGE
CAUSAL_TEST_SUITE_DIRECTION=NO_CHANGE (byte-identical MD5)
CAUSAL_DISTINCT_PRODUCTION_BEHAVIOUR=NO
CAUSAL_EXTERNAL_OBSERVABLE_EFFECT=NO
SUB-002_DISQUALIFIED=YES
SUB-002_DISQUALIFICATION_REASON=SEMANTICALLY_IDENTICAL_TO_THE_ALREADY_MIGRATED_SUB-001_DECISION
```

**`SUB-002` is DUPLICATED CODE, not a distinct decision.** Transferring
it would create a SECOND PolyC authority for a decision the FIRST
authority already owns. It is removed from the feasible subset by this
machine-verifiable reason and the selection is re-run on the remaining
eligible set, which yields `SUB-003`.

---

## 5. The runner-up, `SUB-004`

For completeness, the rank-3 structural candidate was also tested.

The mutation routes `KW_WHILE` to `parseDoWhileStatement`:

```diff
-            case KW_WHILE:    return parseWhileStatement(cc);
+            case KW_WHILE:    return parseDoWhileStatement(cc);
```

The REAL compiler then fails to parse **every** `while` loop:

```text
error: Unexpected character `(` while parsing do while loop body
 --> ./run_shared.HC:5:11
     |
   5 |        while (0<=*str1<=9) {
```

```text
SUB-004_CAUSAL_FEASIBILITY=EXECUTED
SUB-004_CAUSAL_EFFECT=OBSERVED (the compiler cannot parse while loops)
```

`SUB-004` is feasible but ranks BELOW `SUB-003` on the canonical
ranking, so it is the runner-up, not the selection.
