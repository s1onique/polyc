# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06 — the N-06 LITERAL CONTROL AUDIT

**Phase:** C0 (read-only entry audit)
**Status:** HALT trigger — `N06_UNPROVEN`
**Mutations performed by this audit:** NONE.

This audit is a bounded, read-only inspection of ALREADY-COMMITTED
artifacts. It did not mutate any source, did not build a mutant
compiler, and does not present any new experiment as historical SLICE07
evidence. Every quoted observation is transcribed from a committed file
and its path is given.

---

## 0. The frozen obligation

The obligation is RECON05's frozen `c2/selected-negative-controls.md`
(lines 66-76), SHA-256
`f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325`.
The file is **unmodified** since its C2 commit `062a68f`
(`git log --all --oneline -- <file>` returns exactly that one commit,
and the file's current SHA-256 equals the one SLICE07 froze in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/selected-contract-hashes.tsv`).

```text
## N-06 -- the causal direction is not observed

MUTATION=Mutate ONLY the selected C decision in a disposable
          worktree, rebuild the real compiler, and run the witness.
DETECTOR=CAUSAL_DIRECTION_CHANGE
REASON=The EXECUTED experiment in this ACT observed exactly this
        direction; see c2/selected-causal-contract.md section 3.
```

The frozen file's own preamble states its binding force:

```text
These are the controls the SUCCESSOR must implement, in addition to the
nineteen reconnaissance controls that this ACT already executed.
```

---

## 1. Question (a) — Did the actual C3 evidence execute a selected-C-decision mutant during SLICE07?

**NO.**

The decisive record is
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c3/causal-polyc-mutation-restoration.txt`:

```text
WORKTREE_PATH=/tmp/slice07-wt
WORKTREE_BRANCH=detached
WORKTREE_BASE=885a2a6f58d5d8565af7f9a655ea2924a35c7686
MUTATION_SCOPE=tools/bootstrap/selfhost-parser-slice07.HC ONLY
TRACKED_MAIN_WORKTREE_MUTATED=NO
MERGED_OR_COMMITTED_THE_MUTATION=NO
```

and, in the mutation description:

```text
MUTATED_POLYC_SHA256=c7825240648e4b1b05babdcfd982c209fd138dfb117810bb5fd03a69693b0f93
MUTATION_IS_IN_THE_POLYC_SOURCE=YES
MUTATION_IS_IN_SRC_PARSER_C=NO
MUTATION_IS_IN_AN_ORACLE=NO
MUTATION_IS_IN_THE_FIXTURE_EXPECTED_COLUMN=NO
```

The joined control row in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c3/inherited-controls-join.tsv`
records the subject as `the PolyC source`:

```text
N-06	the PolyC source	Mutate ONLY the selected decision in a disposable worktree, rebuild the real compiler, and run the witness.	CAUSAL_DIRECTION_CHANGE	the mutant production compiler BUILDS and REJECTS the static witness ...	1	YES	SENSITIVE
```

Note the join's own mutation text silently drops the word **"C"**
("the selected decision" vs. the frozen "the selected **C** decision").

---

## 2. Question (b) — If only a PolyC mutant, do the FROZEN BINDING RULES explicitly permit that substitution?

**NO.** The equivalence-permission clause does not exist in any frozen
binding rule. It exists only in an artifact authored by SLICE07 itself —
the party that performed the substitution.

### 2.1 The exhaustive search of the frozen corpus

The RECON05 frozen contract set comprises the twelve `c2/selected-*`
files plus `c2/successor-authorization.md`, the ACT document and the
HANDOFF. Searching the whole frozen corpus for an authorisation of
subject substitution:

```text
COMMAND=grep -rniE 'analog|analogue|substitut|successor.?authority|polyc subject|subject-specific' \
#         evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/ \
#         docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05.md \
#         docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05.md
```

returns only three hits, and **none** of them concerns N-06's subject:

| Hit | File | What it is |
|---|---|---|
| `RC-01b ... SUBSTITUTE_AN_ORDER_DEPENDENT_REPORTED_RANKING` | `c2/eligibility-and-ranking-controls.txt:28` | a ranking-order control |
| `RC-05 ... SUBSTITUTE_A_STALE_SOURCE_RANGE_WHILE_KEEPING_THE_CANDIDATE_ID` | `c2/eligibility-and-ranking-controls.txt:32` | a source-binding control |
| `CC-02 ... MAKE_THE_C_ORACLE_DEPEND_ON_THE_POLYC_TARGET_OR_SUBSTITUTE_A_HAND_WRITTEN_ORACLE` | `c2/eligibility-and-ranking-controls.txt:34` | an oracle-provenance control |

A second search for the phrase that would have to appear if the
substitution were authorised:

```text
COMMAND=grep -rn 'selected C decision\|C decision' evidence/.../RECON05/c2/
```

```text
c2/selected-red-contract.md:52:        before it can be trusted to replace the C decision.
c2/selected-red-contract.md:75:| RED-05 | the C decision is active | the C decision is delegated and the behaviour is unchanged |
c2/selected-causal-contract.md:17:> same tree, compile a witness, mutate ONLY the prospective C decision
c2/selected-negative-controls.md:69:MUTATION=Mutate ONLY the selected C decision in a disposable
c2/selected-abi.md:88:The legacy C decision is `int`. The PolyC ABI is `I64 -> I64`.
```

Every one of these occurrences refers to the **C** decision.

### 2.2 The frozen RED-05 affirmatively requires the C decision to be DELEGATED

`c2/selected-red-contract.md` section 2 is a two-column table whose
"Required successor state" column is normative:

```text
| RED | Predecessor state | Required successor state |
| RED-05 | the C decision is active | the C decision is delegated and the behaviour is unchanged |
```

and section 1 RED-05 states:

```text
EXPECTED=Removing the SUB-003 decision from the REAL compiler changes
        the compiled behaviour in the OBSERVED direction.
```

So the frozen contract, after the migration, contains **no active
selected C decision to mutate**. The frozen contract is internally in
tension with a literal reading of N-06 and resolves that tension
NOWHERE. The resolution therefore cannot come from the frozen
contract; it can only come from a clause that does not exist.

### 2.3 The only equivalence text is SLICE07's own, self-authored C0 artifact

`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/negative-control-contract.tsv`
contains the equivalence reasoning (lines 64-66 and 113-122):

```text
# NOTE ON N-06: the frozen mutation text says "mutate ONLY the selected C
# decision".  In THIS ACT the production authority IS the PolyC
...
# component, so the subject-specific analogue of N-06 is the PolyC
# source mutation.  The DETECTOR class (CAUSAL_DIRECTION_CHANGE) and
# the REASON (the executed experiment observed exactly this direction)
# are preserved exactly; the subject is the PolyC source, which is
# what the SLICE07 ACT section 7.2/7.3 additionally requires
# (S7-CC-01).  The DETECTOR is NOT reinterpreted and the control is
# NOT omitted: it is executed against the PolyC subject and its
# result is reported under BOTH N-06 and S7-CC-01.
```

This is **not** a pre-existing frozen contract. It is:
* authored by SLICE07, the act that performed the substitution;
* authored at SLICE07's C0, i.e. *by the successor itself*;
* not a clause of any frozen RECON05 artifact;
* and it is contradicted by the frozen contract it claims to honour
  (see §2.2, where the frozen successor state requires the C decision
  to be delegated).

The ACT's `N06_EQUIVALENCE_PERMITTED_AND_PROVEN` outcome requires
"a **pre-existing frozen contract** explicitly authorizes a
successor-authority analogue and evidence satisfies that authority
**without retroactive reinterpretation**". Neither limb is met.

---

## 3. Question (c) — Is the historical RECON05 C-mutation evidence eligible to discharge a SLICE07-run obligation?

**NO. It is inherited background evidence, not a discharge.**

The RECON05 C mutation is fully documented in
`evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/selected-causal-contract.md`
section 3.1:

```diff
-                if (stmt->kind == AST_DECL && stmt->declvar->kind == AST_GVAR) {
-                    tok = cctrlTokenPeek(cc);
-                    continue;
-                }
                 listAppend(body->stms,stmt);
```

with `MUTATION_SCOPE=src/parser.c ONLY` and
`WORKTREE_BASE=525374202a96d5d4235e25ed76cdff5504d65e7b`.

It is not eligible to discharge a SLICE07-phase obligation because:

1. **It was executed in a different ACT, on a different tree, against a
   different authority state.** RECON05's own ACT §8 item 7 says the
   mutation is performed "mutate ONLY the prospective C decision (**the
   PolyC successor does not yet exist**)". By the time SLICE07 executed
   its C3, the PolyC successor DID exist and was the production
   authority. The historical experiment therefore answers a question
   about the *pre-migration* state, not about SLICE07's C3.

2. **It does not test the subject SLICE07 shipped.** The C decision
   SLICE07 produced is a *delegation* whose correctness is the
   PolyC component's correctness. The RECON05 experiment removed the
   C decision entirely; that is evidence about the C decision's
   *predecessor* semantics, not evidence that SLICE07's delegated
   path is causally load-bearing.

3. **The frozen contract distinguishes them.** RECON05's ACT §9 item 3
   requires each control to have "executed subject-specific mutations".
   The inherited set was *frozen as* subject-specific. Reusing a
   different subject's experiment as the discharge would make the
   control vacuous in exactly the way F5 forbids.

**VERDICT ON (c): NOT eligible. The RECON05 C-mutation evidence is
inherited background evidence only.**

---

## 4. Question (d) — Were N-06 and S7-CC-01 independent experiments, or one experiment reported twice? Did the frozen contract require independence?

**ONE EXPERIMENT REPORTED TWICE. The frozen contract did NOT require
independence between N-06 and S7-CC-01 — but it DID require N-06's
own literal subject, and the single experiment did not have it.**

The predecessor states the double reporting explicitly in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c1/negative-control-red.txt`:

```text
The ten inherited controls N-01..N-10 (RECON05
c2/selected-negative-controls.md) are recorded, UNCHANGED, in
c0/negative-control-contract.tsv.  They are executed at C2/C3 against
the PolyC subject; N-06's subject-specific analogue is the PolyC
source mutation and its result is reported under BOTH N-06 and
S7-CC-01.
```

Both joined rows cite the same evidence file and the same diagnostic:

| Control | Join file | Subject | Observed | Cited evidence |
|---|---|---|---|---|
| N-06 | `c3/inherited-controls-join.tsv` | the PolyC source | mutant BUILDS and REJECTS the static witness with `ERROR: Mapping exists for 1 -> %l14 i64 local` | `c3/causal-polyc-mutation-restoration.txt` |
| S7-CC-01 | `c3/new-controls-join.tsv` | the PolyC source | the mutant production compiler BUILDS (EXIT=0) and REJECTS the static witness with `ERROR: Mapping exists for 1 -> %l14 i64 local` | `c3/causal-polyc-mutation-restoration.txt` |

The two namespaces are disjoint in **ID** (the ACT requires this) but
the two controls are not disjoint in **EXPERIMENT**. The predecessor's
own C1 count arithmetic double-counts them:

```text
CONTROL_COUNT_TOTAL=30
  (6 executed at C1 + 14 prepared + 10 inherited)
```

while the C3 join reports `INHERITED_CONTROL_COUNT=10` and
`NEW_CONTROL_COUNT=18`, and the HANDOFF reports `TOTAL_CONTROL_COUNT = 28`.
The count itself is arithmetically consistent as a count of IDs; it is
the *evidence* that is not independent.

**Does the frozen contract require N-06 and S7-CC-01 to be independent
of each other?** No. RECON05's frozen `selected-negative-controls.md`
contains only N-01..N-10 and knows nothing of an S7-* namespace; the
S7-* set is SLICE07's own additive obligation. There is no frozen
independence clause between them.

**Does the frozen contract require N-06's literal subject?** Yes,
unambiguously: "Mutate ONLY the selected **C** decision". And the
single executed experiment mutated the PolyC source. So the defect is
---

## 5. Question (e) — Did an actual real compiler rebuild and witness outcome support the detector?

**YES — for the subject that was actually mutated.**

From `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c3/causal-polyc-mutation-restoration.txt`:

```text
COMMAND=make INSTALL_PREFIX=/tmp/slice07-wt/build/test-prefix production-hcc
  PRODUCTION_HCC=./hcc
  EXIT=0

COMMAND=make ./build/parser-compound-block
  (the mutant production compiler BUILDS)
  EXIT=0

PRISTINE_WITNESS_COMPILE=SUCCESS
PRISTINE_WITNESS_RUN=SUCCESS
PRISTINE_WITNESS_OUTPUT=WITNESS_OUTPUT=13 15 2
PRISTINE_WITNESS_OUTPUT_SHA256=5d6f3a9ef366f5489097fbf3f465e21d53c22647237d4e687442cd0698b23cc9

CAUSAL_REAL_WITNESS_OBSERVATION_CLASS=COMPILER_ACCEPTANCE_CHANGED
CAUSAL_MUTANT_OUTPUT_SHA256=NOT_APPLICABLE (the mutant REJECTED the witness)
CAUSAL_RESTORED_OUTPUT_SHA256=5d6f3a9ef366f5489097fbf3f465e21d53c22647237d4e687442cd0698b23cc9
CAUSAL_RESTORATION_BYTE_IDENTICAL=YES
MUTANT_BUILD_FAILURE_MISTAKEN_FOR_CAUSALITY=NO
AUTHORITATIVE_MAIN_MUTATED=NO
```

The real production compiler was genuinely rebuilt from the mutated
PolyC object (exit 0), the mutant genuinely changed the compiler's
acceptance of the witness, and the restoration was byte-identical.
The **detector class** `CAUSAL_DIRECTION_CHANGE` is therefore
honestly observed **for the PolyC subject**.

The **subject** is not N-06's frozen subject. A detector firing on the
wrong subject is not a discharge of the frozen control.

---

## 6. The disposition

The ACT's three permitted dispositions are:

| Disposition | Requires | Met? |
|---|---|---|
| `N06_LITERAL_PROVEN` | literal mutation and expected detector evidenced, no semantic substitution | **NO** — the mutation was of the PolyC source |
| `N06_EQUIVALENCE_PERMITTED_AND_PROVEN` | a **pre-existing frozen contract** explicitly authorizes a successor-authority analogue, and the evidence satisfies that authority **without retroactive reinterpretation** | **NO** — no such clause exists in any frozen artifact; the only permission text is SLICE07's own post-hoc C0 note, which is exactly a retroactive reinterpretation |
| `N06_UNPROVEN` | actual join missing, wrong subject, unexecuted experiment, unsupported equivalence, or unexplained double counting | **YES** — the join exists and is executed, but the subject is WRONG (PolyC source, not the selected C decision), the equivalence is UNSUPPORTED by any frozen clause, and the double counting is EXPLAINED by the predecessor's own text but leaves N-06 without its own evidence |

**DISPOSITION = `N06_UNPROVEN`.**

### 6.1 Why this is not a mere information gap

The ACT warns: "do not turn an information gap into either a PASS or a
finding of failure." This audit is **not** an information gap. Every
artifact the disposition depends on is present and was read directly:

* the frozen N-06 text — present, read, hash-verified;
* the SLICE07 C0 contract — present, read;
* the C3 inherited join — present, read (the decisive `MUTATION_SCOPE`
  and `MUTATION_IS_IN_SRC_PARSER_C=NO` lines);
* the C3 causal file — present, read;
* the C1 negative-control RED — present, read (the double-reporting
  statement);
* the C3 new-controls join — present, read;
* the RECON05 causal contract — present, read;
* the RECON05 red contract — present, read.

The finding is therefore **affirmative and falsifiable**: the committed
C3 evidence says, in its own words, that the mutation was NOT in
`src/parser.c`.

### 6.2 A C-decision mutant was mechanically available

This is not a case where the literal experiment was impossible. At
SLICE07's C3 the legacy C comparison still existed in the source,
guarded by the selector:

```text
src/parser.c:1978  #ifdef HCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND
src/parser.c:2002      if (stmt_kind == AST_DECL && declvar_kind == AST_GVAR) return 0;
src/parser.c:2003      return 1;
src/parser.c:2004  #endif
```

so a disposable-worktree mutation of the selected C decision (or of the
delegation that replaced it) was mechanically available at the time.
The literal obligation was executable; it was not executed.

### 6.3 The scope of the finding

**This finding does NOT impeach SLICE07's production result.** The
seven PolyC parser authorities are independently object-verified by
this ACT at C0 (see `c0/existing-production-authorities.tsv`): the
production object imports each subject as an undefined reference, each
subject object defines it, the production binary links it, and the
legacy C comparison is compiled out of the active production path.
The SUB-003 migration is a fact about the built compiler, not a
conclusion drawn from the N-06 causal control.

**What the finding does impeach** is the completeness of the
predecessor's *control bookkeeping*: one frozen inherited control
(N-06) was discharged by an experiment on a different subject and
reported under two control IDs, with the permission for that
substitution asserted only by the substituting ACT itself.

---

## 7. The required correction (narrowly scoped, append-only)

The correction needed is **evidence-hygiene**, not a production change.
It must be a NEW, append-only ACT; no closed artifact may be edited.

A sufficient correction would, at minimum:

1. Execute the literal N-06 experiment — mutate ONLY the selected C
   decision in a disposable detached worktree, rebuild the real
   compiler, run the witness — and record it as N-06's OWN evidence,
   separately from S7-CC-01;
2. OR, if the frozen contract's own RED-05 successor-state column
   ("the C decision is delegated") is held to make a literal N-06
   unsatisfiable, record an explicit, pre-declared, frozen amendment
   that authorises the successor-authority analogue, so the
   substitution is no longer a retroactive reinterpretation;
3. Disambiguate the N-06 / S7-CC-01 double reporting in the accounting.

**No production source change is required, and none is proposed here.**

### 7.1 The mechanical-blocking classification

Per `docs/factory/DOCTRINE.md` §25, the blocking predicates are B1-B5.
This finding is a **historical evidence-hygiene defect**, which §25
lists explicitly among the NON-BLOCKING categories by default. It is
not B1 (no executable gate fails), not B2 (no reproducible
semantic/runtime/compiler defect — the compiler is correct), not B3
(no safety/integrity invariant violated), not B4 (no production change
is needed), and not B5 (the successor's production authority does not
mechanically depend on the N-06 *causal-control* evidence; it depends
on the object-verified delegation, which is sound).

Therefore the corresponding HALT is classified
`HALT_CLASS=GOVERNANCE`, `BLOCKS_NEXT=NO`: the roadmap may proceed;
the correction is a hygiene obligation on the evidence, not a
production blocker.

---

## 8. The measurement record

```text
COMMAND=git log --all --oneline -- evidence/.../RECON05/c2/selected-negative-controls.md
#   062a68f ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 C2: the eligibility, the ranking, the executable causality and the frozen successor contract
#   (exactly ONE commit -- the file has never been modified)

COMMAND=shasum -a 256 evidence/.../RECON05/c2/selected-negative-controls.md
#   f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325
#   == the value SLICE07 froze in c0/selected-contract-hashes.tsv

COMMAND=grep -n 'N-06' evidence/.../SLICE07/c3/inherited-controls-join.tsv
#   the N-06 row, subject = "the PolyC source"

COMMAND=grep -n 'MUTATION_SCOPE\|MUTATION_IS_IN_SRC_PARSER_C' evidence/.../SLICE07/c3/causal-polyc-mutation-restoration.txt
#   MUTATION_SCOPE=tools/bootstrap/selfhost-parser-slice07.HC ONLY
#   MUTATION_IS_IN_SRC_PARSER_C=NO

COMMAND=grep -rn 'analog|analogue|subject-specific' evidence/.../RECON05/c2/ docs/acts/.../RECON05.md docs/factory/HANDOFF-.../RECON05.md
#   only RC-01b, RC-05, CC-02 -- none concerns N-06's subject

COMMAND=grep -n 'RED-05' evidence/.../RECON05/c2/selected-red-contract.md
#   | RED-05 | the C decision is active | the C decision is delegated and the behaviour is unchanged |

COMMAND=grep -n 'reported under BOTH N-06 and S7-CC-01' evidence/.../SLICE07/c1/negative-control-red.txt
#   the explicit double-reporting statement
```

```text
N06_DISPOSITION=N06_UNPROVEN
N06_EVIDENCE_JOIN_PATH=evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06/c0/n06-literal-control-audit.tsv
N06_AUDIT_IS_READ_ONLY=YES
N06_AUDIT_PERFORMED_ANY_MUTATION=NO
N06_LITERAL_C_MUTATION_EXECUTED_DURING_SLICE07=NO
N06_EQUIVALENCE_EXPLICITLY_PERMITTED_BY_A_FROZEN_RULE=NO
N06_RECON05_C_MUTATION_ELIGIBLE_AS_DISCHARGE=NO
N06_AND_S7_CC01_INDEPENDENT=NO
N06_REAL_COMPILER_REBUILD_AND_WITNESS_OBSERVED=YES
N06_PRODUCTION_AUTHORITY_IMPEACHED=NO
```
