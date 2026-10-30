# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08`
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-SLICE08 / INDEPENDENT-SELECTION
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01`
(closed, `ACT-Verdict: PASS`, disposition `PASS_EVIDENCE_CORRECTED`)
**Historical implementation predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE08`
(closed, `ACT-Verdict: PASS`; byte-immutable)
**Historical governance predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06`
(closed, `ACT-Verdict: HALT_N06_FROZEN_OBLIGATION_UNPROVEN`,
`HALT_CLASS: GOVERNANCE`, `BLOCKS_NEXT: NO`) -- PRESERVED EXACTLY.

VERDICT

PASS

---

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. The outcome, in short

**One legacy-C parser decision has been selected for the next PolyC
migration, and the selection is a computed output rather than a
choice.**

```text
SELECTED_CANDIDATE_ID = SUB-004
SELECTED_CLASS        = STRUCTURAL
SELECTED_DECISION     = STATEMENT_DISPATCH
SELECTED_SOURCE_FILE  = src/parser.c
SELECTED_SOURCE_RANGE = 1864..1877
SELECTED_SOURCE_SHA256= cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0
SELECTED_ABI          = I64 token_type, I64 keyword_id -> I64 statement_selector
NEXT_ACT             = ACT-POLYC-SELFHOST-PARSER-SLICE09
NEXT_ACT_STATUS      = READY_TO_DRAFT
NEXT_TARGET          = SUB-004
PRODUCTION_SEMANTIC_DELTA      = 0
SUCCESSOR_IMPLEMENTATION_DELTA = 0
```

**No production semantics changed.**  This ACT migrated nothing.  It
produced one trustworthy successor contract.

---

## 2. The decision, and why it was not a choice

`SUB-004` is the keyword-to-statement-constructor dispatch in
`src/parser.c`'s `parseStatement`:

```c
    if (tok->tk_type == TK_KEYWORD) {
        switch (tok->i64) {
            case KW_IF:       return parseIfStatement(cc);
            ...
```

It was selected because it was **rank 1 in a computed order** and it
**qualified**.  The order was computed by the repository's own
unmodified canonical ranker and, independently, by this ACT's new
PolyC verifier; the two agree on every position.

```text
RANKED:1  SUB-004   0 2 1 2 2 2  src/parser.c:1864
RANKED:2  CAND-018  0 2 2 2 0 0  src/prslib.c:1328
RANKED:3  CAND-021  0 2 2 2 0 0  src/prslib.c:1352
RANKED:4  CAND-025  0 2 3 2 0 0  src/ast.c:943
RANKED:5  CAND-026  0 2 3 2 0 0  src/ast.c:974
RANKED:6  CAND-036  0 2 3 2 0 0  src/ast.c:992
RANKED:7  CAND-037  0 2 3 2 0 0  src/ast.c:2348
RANKED:8  CAND-030  0 2 3 2 0 0  src/prsutil.c:22
RANKED:9  CAND-022  1 2 2 2 0 0  src/prslib.c:760
RANKED:10 CAND-023  1 2 2 2 1 1  src/prslib.c:798
```

`SUB-002` was RECON07's leader.  SLICE08 migrated it, so it is now
already PolyC-owned and is excluded by clause 02.  That is why
`SUB-004` leads the current order.


---

## 3. The raw causal decision

The decision was qualified by an **executed real-compiler experiment**
in a disposable detached worktree, not by assertion:

| Phase | Compiler | Witness `w2` diagnostic |
|---|---|---|
| pristine | `6be93a72…` | *error: Unexpected keyword `I64` while parsing **if** body* |
| mutant | `c353a493…` | *error: Unexpected keyword `I64` while parsing **while loop** body* |
| restored | `6be93a72…` | *error: Unexpected keyword `I64` while parsing **if** body* |

The mutation was **one line and one token**
(`case KW_IF: return parseIfStatement(cc);` →
`case KW_IF: return parseWhileStatement(cc);`).

The diagnostic text is produced by the two **different** statement
constructors, so the mutated decision was **executed**, not merely
present in the binary.  The function-scoped relocation table proves
it was in the linked compiler at the decision site: the mutant's
`_parseStatement` has **zero** relocations to `_parseIfStatement` and
its `_parseWhileStatement` relocation has moved to the `KW_IF` arm's
slot.

The restoration is byte-exact: the rebuilt compiler and object are
identical to the pristine ones, and the restored compiler reproduces
the pristine diagnostic.

---

## 4. What the C0 RED found, and what it cost

Two of the five C0 RED conditions exposed **real gaps** in the
existing tooling, established by observation:

1. **The canonical checker and the RECON07 recomputer have no
   source-range hash column at all.**  A stale phase hash is
   silently ACCEPTED by both.  This ACT therefore built its own
   source-bound verifier (`tools/quality/parser-surface-recon08-verify.HC`),
   whose `ANCHOR` mode recomputes each candidate's range digest from
   the live bytes with its own SHA-256 and its own line-offset table.

2. **The canonical ranker trusts its `eligible` column.**  A forged
   flag promotes an excluded candidate to rank 1.  The ranker input's
   eligible column is therefore **joined mechanically** from the
   checker's actual output.

Neither defect is repaired here; both are recorded as separate debt.

A **third, previously undocumented compiler defect** was found while
building the verifier and is recorded in the tool's own source:

> A file-scope `static` **scalar** global **with an initialiser** is
> placed at the storage slot that `Main`'s `argc` parameter occupies.
> `argc` then reads back as the global's value and `argv` reads back
> as NULL.

The tool avoids it by using the unaffected one-element-array form.
This is **not** fixed under this ACT.

---

## 5. The eight production authorities, preserved

```text
POLYC_PARSER_AUTHORITIES = 8
PRODUCTION_SEMANTIC_DELTA = 0
```

All eight are reproved at the C3 tree: one definition each in the
linked executable, one import per caller object, no local definition,
an active selector, real relocations at the decision sites, and the
legacy C decisions compiled out to pass-through stubs.  The tracked
source still carries the entry digest.

---

## 6. The conservation, honestly reported

```text
PARSER_ASSERTIONS            = 376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5= b6f117eb1386ca80f81bc06226e2a741  (identical to C0)
LEXER_DIRECT                 = 89/89, 45/45, 23/23
LEXER07_STATUS               = FAIL_KNOWN_BASELINE
LEXER07_FAILURE_IDENTITY_MD5 = 7ee761440de83552e751e3c3976c1683  (identical to C0)
CROSS_TARGET_STATUS          = FAIL_ENVIRONMENT_PREFIX (67 historical)
F_NO_PYTHON                  = FAIL_KNOWN_BASELINE (12 historical, 0 new)
F_POLYC_TOOLS                = UNAVAILABLE (the checker has not landed)
GATE_FAST                    = PASS (exit 0)
GATE_PUSH                    = PASS (exit 0)
F14                          = PASS
APPEND_ONLY                  = PASS (11/11)
NEW_FAILURE_IDENTITIES       = 0
```

**The nonzero statuses are reported as failures.**  The LEXER07
suite is not called PASS; the cross-target run is not called PASS; the
Python-policy check is not called PASS.

---

## 8. The fifty acceptance criteria

```text
MANDATORY_AC_TOTAL    = 50
MANDATORY_AC_PASS     = 49
MANDATORY_AC_FAIL     = 0
MANDATORY_AC_UNPROVEN = 1   (AC50, DEFERRED to the external post-CLOSE probe)
```

The fiftieth criterion requires the **external** post-CLOSE terminality
probe, which cannot run before the terminal commit exists.  It is
reported as UNPROVEN at C3 and is claimed PASS only after that probe
succeeds.

---

## 9. The successor contract

The frozen contract is in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08/c2/`:

| File | What it freezes |
|---|---|
| `selected-source-contract.md` | the identity, the range, the digest, the decision, the witnesses |
| `selected-abi-and-projection.md` | the single exact PolyC ABI, the projection, the ownership |
| `selected-production-seam.md` | the seam, the call path, the linkage policy |
| `selected-g0-oracle-and-fixture.md` | the genuine G0 oracle, the fixture, the partitions |
| `selected-stage-provenance-and-causal-contract.md` | G0–G3, the three time-scoped causal controls |
| `selected-negative-controls.md` | the 24-control roster, the join invariant, the split |
| `selection-qualification.tsv` | the qualification of every candidate, with its cause |

The ABI is bounded and total:

```polyc
I64 BootstrapStatementDispatch(I64 token_type, I64 keyword_id);
```

Nothing but two integers crosses the seam.  The token, the cursor,
the `Cctrl`, the symbol table, the AST construction, the recovery
state, the diagnostics and every allocation stay on the C side.

---

## 10. What SLICE09 must do, and must not do

```text
NEXT_ACT        = ACT-POLYC-SELFHOST-PARSER-SLICE09
NEXT_TARGET     = SUB-004
SLICE09_IMPLEMENTED = NO
```

SLICE09 must:

* implement the successor in PolyC behind the dedicated selector
  `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH`, default **OFF**;
* build the genuine G0 oracle from the real production TU with the
  selector OFF, and fail the build if that object imports the
  successor symbol;
* produce three **distinct** compiler generations (G1, G2, G3) and
  compare all twelve ordered pairs on the frozen fixture;
* execute the **POST-POLYC-MUTANT** control against the **compiled
  PolyC component** — a NEW experiment with its own source, phase,
  selector state, producer and execution ID.

SLICE09 must **not** discharge the POST-POLYC-MUTANT control with
RECON08's pre-migration C experiment.  They have different subjects,
different selector states, different producers and different phases.

---

## 11. The residue, classified

| Class | Item |
|---|---|
| P1 | The canonical checker and the RECON07 recomputer cannot detect a stale source-range hash.  RECON08's own verifier can, but it is not wired into the canonical gate graph. |
| P1 | The canonical ranker trusts its `eligible` column.  RECON08's pipeline joins it mechanically, but the tool itself is unchanged. |
| P1 | The `static` initialised scalar global collides with `Main`'s `argc` slot.  It is a real compiler defect, measured and recorded, and **not fixed** here. |
| P2 | The F-POLYC-TOOLS checker has still not landed, so the RECON08 verifier cannot be bound into the canonical gate graph. |
| P2 | The shared `/tmp/holyc-asm.s` assembly race remains.  It caused one transient failure in this ACT, which was re-run serially and passed. |
| — | The 15 historical self-referential SLICE08 C3 rows, the 15 LEXER07 identities, the 67 cross-target cases and the 12 Python-policy violations are **historical**, and are neither fixed nor relabelled. |

---

## 12. The evidence tree

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08/
  c0/  entry identity, the predecessor and correction audit, the
       575-path freeze, the baselines, the eight-authority proof, the
       frozen 50-AC and 24-control contracts, the five REDs
  c1/  the 274-function census, the reconciled 24-candidate registry,
       the raw 13-clause and R0..R6 facts, the dependency inventory,
       the reachability facts, the source anchors, the independent
       census verification
  c2/  the canonical provenance, the eligibility and the full order,
       the independent recomputation, the attempted dispositions, the
       causal build and witness, the restoration, the selected-*
       contract, the control roster
  c3/  the independent adjudication, the control join, the
       conservation, the gates, the Factory-v2/F14/append-only checks,
       the immutable-predecessor check, the 50-AC ledger
  c4/  the terminality plan
```

The full closure record, the commands and the actual exits are in the
C0–C3 evidence files and in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08/`.


---

## 7. The negative controls

```text
FROZEN_CONTROL_IDS        = 24
OBSERVED_CONTROL_IDS      = 24
MISSING=0  EXTRA=0  DUPLICATE=0  UNEXECUTED=0
SELF_REFERENTIAL=0  WRONG_SUBJECT=0
PHYSICAL_EXECUTIONS       = 25
```

The physical count is **derived** from the per-row column and is 25,
not 24, because `R8-EC-06` requires two distinct executions.  No
"24 independent experiments" claim is made.

The `R8-XC-04` experiment is real: a **dormant** mutation in a
decision the witness never reaches leaves the diagnostic
byte-identical to the pristine one, while the genuine mutation changes
it, so the injected fake positive is rejected and the genuine effect
remains observable.
