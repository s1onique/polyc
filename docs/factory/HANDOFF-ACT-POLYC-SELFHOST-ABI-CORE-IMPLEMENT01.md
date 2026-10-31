# HANDOFF — ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01

Factory-Version: 2
Lifecycle: terminal handoff (descriptive only; the closure verdict is the
`ACT-Verdict` trailer of the CLOSE commit)
Class: SELFHOST / ABI_CORE / COHERENT_OPERATOR_BUNDLE / PRODUCTION_AUTHORITY_TRANSFER
Binding predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01
Frozen bundle: BUNDLE-OPERATOR-CORE-01
Frozen ABI: ABI-CORE-OP-1
Frozen selector: HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY

VERDICT
--------

PASS

Three core-operator decisions of the frozen `BUNDLE-OPERATOR-CORE-01` are
now owned by one compiled PolyC subject linked into the production
compiler, and each transfer is proven separately by its own executed
PolyC-source mutation, its own full production rebuild and its own
compiled-program witness. The legacy C rules are proven live when the
selector is off and dormant when it is on. All twelve ordered G0/G1/G2/G3
comparisons agree over the source-bound fixture population, all twenty-four
adverse controls are reason-specifically sensitive, the live exit-127 build
hazard is corrected and made fail-closed, every baseline is conserved, and
the production graph is unchanged at 52 nodes / 134 active mandatory edges /
34 SCCs / largest 19 with a truthful zero new proven cuts. 49 of 50
acceptance criteria pass; AC50 is deferred to the external post-CLOSE
receipt. No M1/M2 milestone and no self-hosting claim is made.

## 1. What was transferred

Three C-owned core-operator decisions are now made by ONE compiled PolyC
subject linked into the production compiler.

| Site | C site (frozen) | PolyC symbol | Authority now owned by |
|---|---|---|---|
| SITE-COMPOUND-ASSIGN | `src/prslib.c:1328..1348` `parseCompoundAssign` | `_AbiCoreClassifyCompoundAssign` | the compiled PolyC subject |
| SITE-VALID-POINTER-OP | `src/ast.c:974..990` `astIsValidPointerOp` | `_AbiCoreIsValidPointerOperator` | the compiled PolyC subject |
| SITE-RANGE-OPERATOR | `src/ast.c:2348..2358` `astIsRangeOperator` | `_AbiCoreIsRangeOperator` | the compiled PolyC subject |

The three source ranges still hash to the frozen values
`4d941407ee054e207586b3a4fb645caf8917e6b43fa467b79d50a75e1b54bb43`,
`bc06b0d757538f6c00ce0e96003cf5613823e98f4c48288c727cf9ac1dd82ac5` and
`8c1acadaa4f1ae26d27c6be491812db2d16a8dd18528cb5cf2cc81d242b24f99`.

## 2. (a) Source-derived three-site completion IS NOT a three-symbol count

The three decisions are three DISTINCT CALL SITES with three distinct
exported symbols, three distinct object relocations and three distinct
executed causal experiments. They live in ONE subject object because they
share one coherent ABI, not because they are one authority.

The count of 13 is a count of DECISION SITES: 9 predecessor parser
authorities, 1 predecessor CPA authority, and 3 new core-operator
decisions. Each of the three is individually countable, individually
testable and individually mutable.

Proof that this is not a symbol count:
`evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/authority-ledger.tsv`
gives every authority its own defined-symbol count, caller-import count and
subject-object digest, and
`.../c3/independent-authority-proof.tsv` records the output of a SEPARATE
compiled PolyC auditor (`tools/quality/core-operator-implement01-verify.HC`)
that recomputes the transfers from the actual objects and binaries.

## 3. (b) The predecessor's C mutation IS NOT any of the new PolyC mutations

`CSCR01-M1` (in ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01, C2) was
a C-SOURCE experiment on `src/prslib.c` for SITE-COMPOUND-ASSIGN ONLY, with
the witness 30 → 246 → 30. It is preserved as historical C-side evidence.

The three new experiments are DIFFERENT physical experiments on the POLYC
source, each in its own disposable detached worktree, each with its own full
production rebuild, its own source digest and its own subject-object digest:

| ID | Site | Mutation | Own discriminator |
|---|---|---|---|
| `M-POLYC-CA` | SITE-COMPOUND-ASSIGN | `TK_ADD_EQU` maps to `AST_BIN_OP_SUB` | W-CA: 30 → 246 |
| `M-POLYC-PO` | SITE-VALID-POINTER-OP | the `AST_BIN_OP_LOG_AND` case is removed | W-PO-AND: accepted → rejected |
| `M-POLYC-RO` | SITE-RANGE-OPERATOR | the `AST_BIN_OP_LT` case is removed | W-PO-LT: accepted → rejected |

See `.../c3/mutant-ca.tsv`, `.../c3/mutant-po.tsv`, `.../c3/mutant-ro.tsv`,
`.../c3/mutant-restoration.tsv` and `.../c3/site-isolation.tsv`.

## 4. (c) Behavioural conservation IS NOT semantic-authority retirement

The two are reported separately and neither is inferred from the other.

- Behavioural conservation: the parser suite is 376/376 over 90 files with
  the assertion-sequence MD5 `b6f117eb1386ca80f81bc06226e2a741` (identical
  to the C0 baseline); the three lexer differentials are 89/89, 45/45 and
  23/23; every compiled-program witness is equal between the migrated ON
  compiler and the independent C oracle OFF compiler.
- Semantic-authority retirement: in the selector-ON build the legacy C
  comparison tables are COMPILED OUT of `src/prslib.c` and `src/ast.c`;
  the migrated functions are pure tail calls to the PolyC symbols; and
  mutating the legacy C rule changes NOTHING in the ON build while it DOES
  change the OFF build.

The last point is the C-dormancy anti-control
(`.../c3/c-off-on-dormancy.tsv`): for each of the three legacy C rules,
the OFF build's behaviour changes when the rule is mutated (the rule is
LIVE) and the ON build's behaviour does not change at all (the rule is
DORMANT).

## 5. (d) Genuine production graph cuts ARE NOT mere operator delegation

The three transferred decisions are SCALAR operator classifications. They
retire no typed-layout, mutable-state, callback or recovery edge.

```text
GRAPH BEFORE = 52 nodes / 134 active mandatory edges / 34 SCCs / largest 19
GRAPH AFTER  = 52 nodes / 134 active mandatory edges / 34 SCCs / largest 19
NEW_PROVEN_CUTS = 0
```

This is a truthful zero, recomputed independently with the PolyC verifier
(`.../c3/graph-after.tsv`). No graph cut, no SCC reduction and no lower M2
estimate is claimed.

## 6. The ABI — ABI-CORE-OP-1

```text
I64 AbiCoreClassifyCompoundAssign(I64 token_type, I64 token_value, I64 *out_operator);
I64 AbiCoreIsValidPointerOperator(I64 binary_operator);
I64 AbiCoreIsRangeOperator(I64 binary_operator);
```

The contract is frozen in `.../c1/abi-core-op-1.tsv`.

- Scalar-only. No raw `Ast*`, `Lexeme*`, `List*`, `Map*`, `Cctrl*`,
  `Arena*` or pointer-bitcast handle crosses the boundary. The single
  out-parameter is ONE host-owned scalar cell.
- Result/status separation is PROVEN DISJOINT. Every function returns a
  value in {0,1}; the negative status range is reserved and never
  produced (the subject is total over the whole I64 domain). For
  SITE-COMPOUND-ASSIGN the operator value deliberately does NOT travel in
  the return value, because `AST_BIN_OP_MUL` is 0 and would collide with
  the "not a compound assignment" result 0.
- The C side keeps every other responsibility: token objects, AST
  representation and graph mutation, type checking, IR lowering, code
  generation, allocation, diagnostics and recovery
  (`.../c2/ownership-conservation.tsv`).
- The subject has no allocation, no callback, no `setjmp`/`longjmp`, no
  global mutable state and no recovery dependency
  (`.../c2/polyc-subject-build.txt`).

## 7. The generations and the differential

| Generation | Producer | Role |
|---|---|---|
| G0 | `tools/quality/core-operator-implement01-g0-oracle.c`, compiled by the host `cc` | genuine C-only oracle: a verbatim copy of the three original C predicates, with ZERO PolyC symbol references |
| G1 | `build/host-stage0/hcc` | the entry-frozen stage0 producer |
| G2 | `build/hcc` | the real production compiler of the current tree |
| G3 | `build/hcc-bootstrap04` | the stage3 compiler of the live generation graph |

The three PolyC PRODUCER EXECUTABLES have pairwise distinct digests. The
three SUBJECT OBJECTS are byte-identical: that is deterministic
compilation, which the ACT explicitly permits. The independence property
is carried by the producer executables, and the differential harness
contains no decision of its own — only the linked subject object differs.

All 12 ordered G0/G1/G2/G3 comparisons agree over the 146-row
source-bound fixture population with ZERO mismatches
(`.../c3/generation-fixture-differential.tsv`). The comparator is proven
SENSITIVE: corrupting one value in one generation produces exactly one
mismatch, attributed to the correct site.

## 8. The build-wiring correction

The predecessor's recorded exit-127 hazard is LIVE at the entry and was
diagnosed exactly (see `.../c1/strict-build-negative.txt`):

> The `test-prefix-install` recipe's cmake invocation was truncated by a
> missing trailing backslash, so the `-DHCC_USE_SELFHOST_ABI_CPA=ON` and the
> four `-DABI_CPA_*` flags were executed by the shell as a separate command
> (status 127) and NEVER REACHED CMAKE. The test-prefix compiler was
> therefore built with the CPA authority OFF while the recipe text claimed
> it was ON.

The correction (a) restored the line continuation so the cmake invocation
is ONE shell command, and (b) added a fail-closed configuration check that
ABORTS the recipe if the configure did not enable the requested selectors.
The correction is bounded to the Makefile's build wiring. The
predecessor's own C0 evidence was NOT rewritten.

Measured effect: `HCC_USE_SELFHOST_ABI_CPA:BOOL=ON` and
`HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY:BOOL=ON` now both reach cmake in
the test-prefix build.

Eight isolated adverse build probes (BC-A..BC-H) each fail for their named
reason (`.../c2/build-negative-controls.tsv`).

## 9. The control and acceptance joins

- 24 adverse controls, each executed through pristine → adverse →
  restored, each REJECTED in the adverse phase for its OWN reason:
  `.../c3/negative-control-execution.tsv` and `.../c3/negative-control-join.tsv`.
- 6 verifier selftests attack the control ledger itself (delete a row,
  change an ID, substitute a source hash, fabricate a PASS, misbind an
  experiment ID, suppress a prerequisite object): `.../c3/control-verifier-selftest.tsv`.
- The acceptance ledger: 49 PASS, 1 DEFERRED (AC50), 0 FAIL, 0 UNPROVEN,
  0 NOT_RUN, 0 duplicate IDs, 49 of 49 evidence paths present:
  `.../c3/ac01-ac49-ledger.tsv`.

## 10. Conservation

| Baseline | Value |
|---|---|
| PARSER_ASSERTIONS | 376/376 over 90 files, MD5 `b6f117eb1386ca80f81bc06226e2a741` |
| LEXER07_DIRECT | 89/89 |
| LEXER08_DIRECT | 45/45 |
| LEXER09_DIRECT | 23/23 |
| LEXER07_BROAD | FAIL_KNOWN_BASELINE, 15 failure identities, MD5 `7ee761440de83552e751e3c3976c1683` |
| CROSS_TARGET_PREFIX | FAIL_ENVIRONMENT_PREFIX, 67 |
| F_NO_PYTHON | FAIL_KNOWN_BASELINE, 12 historical, 0 new |
| F_POLYC_TOOLS | UNAVAILABLE |
| PREDECESSOR POLYC AUTHORITIES | 10 conserved, identical object digests |
| PRODUCTION POLYC AUTHORITIES | 13 (9 + 1 + 3) |
| GRAPH | 52 nodes / 134 active mandatory edges / 34 SCCs / largest 19 |
| GATE_FAST | PASS |
| GATE_PUSH | PASS |
| APPEND_ONLY | 11/11 PASS |

The known non-green baselines are recorded HONESTLY and are not relabelled
PASS.

## 11. What this ACT does NOT establish

- It does NOT complete whole-parser self-hosting.
- It does NOT eliminate the shared C data structures.
- It does NOT demonstrate M1 or M2: `SELFHOST_M2_ACHIEVED = NO`.
- It does NOT retire a production graph edge: `NEW_PROVEN_CUTS = 0`.
- It does NOT establish a validated future ACT count.
- `SLICE10_AUTHORIZED = NO`, `NEXT_TARGET = NONE`.

## 12. Next authorization

No successor is preselected. The proposed next class, after independent
review of this closure, is an evidence-backed `CORE_SEMANTIC_BUNDLE_RECON`
or an ABI prerequisite selected by the ACTUAL remaining bootstrap-critical
graph — not an automatic SLICE10.

## 13. Evidence index

```text
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/
  c0/ entry-identity.txt predecessor-terminal.tsv predecessor-freeze.tsv
       selected-site-freeze.tsv authorities.tsv graph-baseline.tsv
       hermetic-baseline.txt baselines.txt five-reds.tsv frozen-contracts.tsv
       probes/red01..red05*.sh
  c1/ enum-domain.tsv oracle-site-provenance.tsv ownership-effects.tsv
       g0-oracle-build.txt fixture-ca.tsv fixture-po.tsv fixture-ro.tsv
       fixture-all.tsv fixture-independent.tsv semantic-witnesses.md
       abi-core-op-1.tsv generation-plan.tsv producer-build-graph.txt
       strict-build-negative.txt scope-and-mutant-plan.tsv
       probes/ witnesses/
  c2/ polyc-subject-build.txt site-ca-linkage.tsv site-po-linkage.tsv
       site-ro-linkage.tsv ownership-conservation.tsv selector-build-matrix.tsv
       build-negative-controls.tsv production-object-relocations.tsv
       effective-compile-and-link-commands.txt semantic-equivalence.txt
  c3/ generation-fixture-differential.tsv generation-producer-proof.tsv
       mutant-ca.tsv mutant-po.tsv mutant-ro.tsv mutant-restoration.tsv
       site-isolation.tsv c-off-on-dormancy.tsv independent-authority-proof.tsv
       semantic-conservation.tsv negative-control-join.tsv
       negative-control-execution.tsv control-verifier-selftest.tsv
       predecessor-authorities.tsv authority-ledger.tsv graph-after.tsv
       parser-conservation.txt non-green-conservation.txt gates-and-factory.txt
       ac01-ac49-ledger.tsv mutation-diffs/ witnesses/
  c4/ terminality-plan.txt
```
