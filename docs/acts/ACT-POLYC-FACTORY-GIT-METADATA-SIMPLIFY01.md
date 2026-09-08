# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01

Factory-Version: 1 (transitional)
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** FACTORY / PROCESS / TOOLING

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Predecessor:** ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03
(closes HALT_CORRECTION02_CLOSURE_STATE_UNBOUND; itself a repair
ACT that exists only because Factory v1's identity bookkeeping
self-pinned).

**Compiler state:** FROZEN.

**Migration policy:** EXISTING HISTORY GRANDFATHERED -- NO
RETROACTIVE MIGRATION.

**Transition note:** This ACT executes under Factory v1 because
Factory v2 does not exist until this ACT closes. The transitional
topology discipline (at most three commits) is therefore binding
for this ACT only. After this ACT closes,
`NUMERIC_COMMIT_CAPS = REMOVED_FOR_FACTORY_V2`.

---

## 0. Mission

Replace self-referential Markdown closure bookkeeping with
Git-native ACT metadata and establish Factory v2 as the
authoritative process for all ACTs opened after this ACT
closes.

In one sentence:

> Git owns execution identity and topology.
> ACT documents own authorization and intent.
> Commit trailers own execution phase and closure verdict.
> HANDOFFs summarize outcomes but are not identity or verdict
> authorities.

---

## 1. Why

The Factory v1 process has accumulated a recurring class of
failures unrelated to compiler correctness:

* closure documents embedding the SHA of the commit that
  contains them (`FINAL_HEAD = this commit`, `DOCS_HEAD = next
  commit`);
* amend loops caused by trying to pin moving commit identities;
* ACT `Status` and HANDOFF `VERDICT` becoming independent
  mutable authorities that drift apart (and require yet another
  bounded correction ACT to reconcile);
* historical HANDOFFs requiring later reconciliation passes;
* arbitrary commit-count caps turning honest evidence commits
  into topology violations;
* persistent claims such as `worktree = clean` becoming false
  immediately after later local activity;
* increasingly elaborate closure oracles whose primary purpose
  is reconciling duplicated metadata.

The repeated failure is architectural. Factory currently asks
Markdown to describe facts that Git already owns.

Five RED witnesses are captured in
`evidence/factory-git-metadata-simplify01/`:

  red-self-pinning.txt         -- commit-SHA self-reference
  red-duplicate-verdict.txt    -- ACT vs HANDOFF verdict drift
  red-commit-cap.txt           -- arbitrary integer caps vs
                                  honest commits
  red-live-state.txt           -- persistent "worktree clean"
                                  claims vs live state
  red-git-trailers.txt         -- Git can already represent
                                  ACT metadata structurally

A successful implementation that merely replaces the current
machinery with an equally complicated new oracle is a failure
of this ACT. Simplicity is the load-bearing criterion.

---

## 2. Scope (this ACT, transitional v1)

### allowed

* `AGENTS.md` (v2 pointer note appended; F1-F15 unchanged);
* `docs/factory/DOCTRINE.md` (v2 delta note appended);
* `docs/factory/LLM-WORKFLOW.md` (v2 delta note appended);
* `docs/factory/ACT-TEMPLATE.md` (Factory v2 template appended
  alongside the existing v1 template);
* `docs/factory/HANDOFF-TEMPLATE.md` (Factory v2 template
  appended alongside the existing v1 template);
* `docs/factory/GIT-METADATA.md` (NEW canonical v2 detail);
* `scripts/quality/factory-v2-commit-msg-check.sh` (NEW);
* `scripts/quality/factory-v2-range-check.sh` (NEW);
* `scripts/quality/factory-v2-test.sh` (NEW);
* `.githooks/commit-msg` (NEW; thin wrapper around the
  commit-msg validator);


---

## 3. Entry gate

```text
git branch --show-current
git status --porcelain=v1
git rev-parse HEAD
```

Required state:

* on `main`;
* worktree clean;
* entry HEAD `29fb9afc49005401959febaa460a40f77ecc43cb`
  (CORRECTION03 closure).

Recorded in `evidence/factory-git-metadata-simplify01/entry.txt`.

---

## 4. Principal RED (mechanical and documentary)

RED-1 self-pinning                reproduced (CORRECTION02 HANDOFF)
RED-2 duplicate verdict authority  reproduced (CORRECTION01..05)
RED-3 arbitrary commit cap         reproduced (BOUNDARY03-C02,
                                    STATUS-RECON-C02/C03)
RED-4 persistent worktree claim    reproduced (live check)
RED-5 Git trailers suffice         reproduced (interpret-trailers)

Captured verbatim in `evidence/factory-git-metadata-simplify01/`.

The principal RED for the *new tooling* is the test matrix in
section §12. Each T1-T18 must mechanically exercise the new
validator scripts.

---

## 5. Implementation boundary

The minimum useful enforcement:

1. `scripts/quality/factory-v2-commit-msg-check.sh` -- opt-in
   trailer validator. Returns `MODE=NON_ACT rc=0` for messages
   without `ACT:`. For messages with `ACT:`, enforces the
   exact trailer grammar from §6 of this ACT and the regex
   from §V2-4.
2. `scripts/quality/factory-v2-range-check.sh` -- mechanical
   reviewer helper that derives FIRST/ENTRY/CLOSE/COMMITS/VERDICT
   from the contiguous run of `ACT: <id>` commits ending at a
   CLOSE commit. No numeric cap. No persistent identity
   database.
3. `scripts/quality/factory-v2-test.sh` -- matrix runner for
   T1-T18. Reads no production state; reads only the validator
   scripts.
4. `.githooks/commit-msg` -- thin wrapper that invokes the
   commit-msg validator. Hook is enabled by the existing
   `core.hooksPath = .githooks` mechanism; no installer
   change required.
5. `docs/factory/GIT-METADATA.md` -- the canonical v2 detail
   (trailer grammar, range algorithm, supersession trailers).
6. Additions (not rewrites) to the four existing canonical
   doctrine files: appendices describing Factory v2 as the
   binding contract for new ACTs, with the v1 grandfather
   policy stated explicitly.
7. Factory v2 ACT and HANDOFF templates appended alongside the
   v1 templates; v1 templates preserved for their grandfathered
   managed universe.

Deliberately excluded:

* a "factory v2 managed universe" manifest;
* a CI step that fails pushes lacking trailers (out of scope
  per ACT §23);
* cryptographic signing (out of scope per ACT §23);
* migration tooling for old HANDOFFs (V2-13 forbids it);
* a database of ACTs (V2-5 forbids it; the ACT is its own
  history on the linear branch).

---

## 6. Acceptance criteria

### AC01 -- recon
All relevant existing doctrine files classified as KEEP,
REPLACE_IN_V2, LEGACY_ONLY, or UNRELATED. Recorded in
`evidence/factory-git-metadata-simplify01/recon.txt`.

### AC02 -- self-pin RED
At least one historical self-pinning failure captured.
`red-self-pinning.txt` exists with `REPRODUCED=YES`.

### AC03 -- duplicate-authority RED
At least one ACT/HANDOFF drift example captured.
`red-duplicate-verdict.txt` exists with `REPRODUCED=YES`.

### AC04 -- topology RED
At least two arbitrary-cap process failures captured.
`red-commit-cap.txt` exists with two case studies and
`REPRODUCED=YES`.

### AC05 -- live-state RED
Worktree cleanliness demonstrated as a live state.
`red-live-state.txt` exists with the create/delete cycle.

### AC06 -- Git-trailer feasibility
`git interpret-trailers --parse` successfully parses ACT
metadata. `red-git-trailers.txt` exists with the demonstration
output.

### AC07 -- v2 canonical doctrine
`docs/factory/GIT-METADATA.md` exists and is the canonical
v2 detail.

### AC08 -- identity ownership
The new v2 ACT and HANDOFF templates contain no self-pinned
SHA fields and no instructions to pin SHAs into docs.

### AC09 -- verdict ownership
The new v2 HANDOFF template has no authoritative `VERDICT:`
field; verdict authority is delegated to the CLOSE commit
trailer.

### AC10 -- lifecycle ownership
The new v2 ACT template is an authorization artifact; it
does not require an OPEN -> PASS / HALT mutation and has
no mutable authoritative `Status:` field.

### AC11 -- trailer validator


---

## 7. Conservation gates (unchanged for v1 universe)

* `git diff --check` PASS at every commit.
* `sh scripts/quality/gate-fast.sh` PASS at the closure
  commit (GFAST-1..6 unchanged).
* `sh scripts/quality/factory-closure-status-check.sh` PASS
  (6-pair bounded universe, 6 ACTs + 6 HANDOFFs).
* `bash evidence/factory-status-reconciliation-correction02/n1-n19/run.sh`
  PASS (PASS=63 FAIL=0).
* No production code in `src/` touched.

---

## 8. Halt taxonomy

* `HALT_GIT_TRAILER_MODEL_INSUFFICIENT` (H1) -- if `git
  interpret-trailers --parse` cannot represent ACT / ACT-Phase
  / ACT-Verdict without a custom parser. **Not triggered:**
  red-git-trailers.txt demonstrates it.
* `HALT_FACTORY_AUTHORITY_CONFLICT` (H2) -- if AGENTS.md or
  another higher authority requires mutable SHA/status
  bookkeeping in a way that cannot be superseded. **Not
  triggered:** F1-F15 epistemologically persist; only the
  SHA/verdict mechanics are superseded and only for new ACTs.
* `HALT_LEGACY_FACTORY_CONSERVATION_RED` (H3) -- if v2 changes
  break the grandfathered v1 checker. **Not triggered:** v2
  tooling is opt-in by trailer presence; the v1 checker is not
  modified.
* `HALT_GIT_WORKFLOW_OVERREACH` (H4) -- if the commit-msg hook
  requires ACT trailers for ordinary commits. **Not
  triggered:** the validator returns `MODE=NON_ACT rc=0` for
  messages without `ACT:`.
* `HALT_FACTORY_V2_COMPLEXITY_REGRESSION` (H5) -- if v2
  requires a database, daemon, large parser, or external
  dependency. **Not triggered:** only three POSIX shell
  scripts and one Git hook.
* `HALT_FACTORY_V2_TRANSITION_TOPOLOGY` (H6) -- if this ACT
  requires a fourth commit. **Not triggered:** three commits
  suffice.

---

## 9. Residue (anticipated)

* P2 -- legacy factory-closure-status oracle decommission
  remains future work. A separate ACT
  (`ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01` or successor)
  may retire `factory-closure-status-check.sh`,
  `llvm-closure-status-check.sh`, and
  `act-handoff-map.tsv` once all v1 ACTs are closed.
* P2 -- "this commit" / "next commit" / SHA-table patterns
  in any committed ACT or HANDOFF outside the immediate
  CORRECTION02 chain remain grandfathered (V2-13).
* P2 -- CI enforcement of v2 trailers (V2-3 / V2-4 / T1-T18)
  remains a future ACT.
* P2 -- cryptographic signing of ACT commits remains a future
  ACT (explicit non-goal in §23).

---

## 10. Commit topology (transitional v1 cap = 3)

```text
C1 RED:    this ACT contract
           + recon.txt
           + entry.txt
           + red-self-pinning.txt
           + red-duplicate-verdict.txt
           + red-commit-cap.txt
           + red-live-state.txt
           + red-git-trailers.txt
           (no production/templating/tooling edit yet)

C2 IMPL:   scripts/quality/factory-v2-commit-msg-check.sh
           + scripts/quality/factory-v2-range-check.sh
           + scripts/quality/factory-v2-test.sh
           + .githooks/commit-msg
           + docs/factory/GIT-METADATA.md
           + appendix additions to AGENTS.md,
             DOCTRINE.md, LLM-WORKFLOW.md,
             ACT-TEMPLATE.md, HANDOFF-TEMPLATE.md


---

## 12. RED matrix (binding for the new tooling)

T1   ordinary non-ACT commit message                  PASS
T2   valid RED                                        PASS
T3   RED with verdict                                 FAIL
T4   CLOSE without verdict                            FAIL
T5   valid CLOSE PASS                                 PASS
T6   valid qualified PASS                             PASS
T7   valid HALT                                       PASS
T8   duplicate ACT trailer                            FAIL
T9   duplicate phase                                  FAIL
T10  invalid phase                                    FAIL
T11  malformed verdict                                FAIL
T12  supersedes without corrected verdict (allowed)   PASS
T12b supersedes without corrected verdict (forbids    FAIL
     corrected verdict without supersedes)
T13  range RED->IMPL->CLOSE                           PASS (3 commits)
T14  range RED->IMPL->EVIDENCE->IMPL->CLOSE           PASS (5 commits)
T15  first phase not RED                              FAIL
T16  ACT ID changes inside range                      FAIL
T17  multiple CLOSE commits                           FAIL
T18  CLOSE with subsequent same-ACT IMPL              FAIL

Each T is exercised by `scripts/quality/factory-v2-test.sh`
using temporary commit-message fixtures only; no production
state is mutated.

---

## 13. Factory v2 design laws (canonical summary; see
`docs/factory/GIT-METADATA.md` for the binding detail)

V2-1  Git owns identity. No Markdown field may claim the SHA
      of the commit that contains it.
V2-2  ACT documents are authorization artifacts. No OPEN ->
      PASS mutation. No mutable `Status:` field.
V2-3  Every ACT commit carries `ACT:` and `ACT-Phase:`
      trailers.
V2-4  CLOSE commits additionally carry exactly one
      `ACT-Verdict:` trailer.
V2-5  ACT range is derived; never copied into Markdown.
V2-6  One ACT is one contiguous Git range.
V2-7  No numeric commit cap.
V2-8  RED-before-fix survives unchanged.
V2-9  HALT is a successful execution outcome.
V2-10 HANDOFF is descriptive, not authoritative.
V2-11 Current-state facts are checked live.
V2-12 Evidence may describe immutable subjects only.
V2-13 Historical Factory v1 remains untouched.

---

## 14. Explicit doctrine delta

Preserved (unchanged epistemologically):

  F1 identity before change
  F2 root cause before repair
  F3 RED before fix
  F4 HALT is successful execution outcome
  F5 do not weaken gates/tests
  F6 no silent fallback
  F7 bounded scope
  F8 minimal mechanism
  F9 qualification appropriate to risk
  F10 conservation
  F11 residue accounting
  F13 evidence over assumption
  F14 historical evidence preserved
  F15 no self-authorization

Superseded mechanics (for ACTs opened after this ACT closes):

  mutable HEAD/SHA tables in docs
  authoritative HANDOFF verdicts
  mutable ACT Status closure state
  self-pinned FINAL_HEAD / CLOSURE_HEAD
  arbitrary commit-count caps
  mandatory RED/IMPL/DOCS three-commit topology
  historical verdict rewrites
  persistent worktree-clean metadata

---

## 15. Verdict rules

PASS conditions:

  AC01..AC20 all GREEN
  F3 -- new tooling has mechanical RED/IMPL/GREEN evidence
       (T1-T18)
  F4 -- no HALT_* triggered
  F5 -- factory-closure-status-check still PASS for its
       grandfathered v1 universe
  F10 -- no production code changed
  F13 -- every closure-critical command was run and recorded
  F14 -- no historical ACT/HANDOFF rewritten

PASS verdict emits:

  VERDICT=PASS
  FACTORY_V2=ACTIVE_FOR_NEW_ACTS
  NEXT_ACT=ACT-POLYC-LLVM-CORE04

HALT conditions:

  H1..H6 emit:

  VERDICT=<HALT token>
  FACTORY_V2=NOT_ACTIVE
  LEGACY_FACTORY_V1=REMAINS_AUTHORITATIVE

No partial activation. No retroactive migration.

---

## 16. Handoff to CORE04

If PASS, `ACT-POLYC-LLVM-CORE04` becomes the **first
Factory-v2 ACT**. Its ACT document must therefore:

* contain no commit SHA identity table;
* contain no numeric commit cap;
* remain an authorization artifact;
* require RED-before-fix normally;
* require `ACT:` and `ACT-Phase:` on every execution commit;
* require `ACT-Verdict:` on its CLOSE commit;
* use a short, non-authoritative HANDOFF per the new v2
  template;
* use `factory-v2-range-check.sh` for closure/review.

CORE04 thereby becomes the live qualification test for
Factory v2 without mixing Factory migration into the LLVM
implementation itself.

---

## 17. Non-goals (explicit)

This ACT does not decide:

* whether Git commits should be cryptographically signed;
* whether trailers should be enforced in CI (the pre-push hook
  is unchanged; the pre-commit hook is opt-in by trailer
  presence);
* whether GitHub branch protection should understand ACT
  metadata;
* whether legacy ACTs should be migrated;
* whether old status-reconciliation tooling should be deleted;
* whether a database of ACTs should exist;
* whether multiple ACTs may execute concurrently on different
  branches;
* whether merge commits require additional semantics;
* whether automated agents may close ACTs without human
  authorization.

           (RED matrix now mechanically enforced by C2 scripts)

C3 CLOSE:  evidence/factory-git-metadata-simplify01/HANDOFF.md
           + evidence/factory-git-metadata-simplify01/tests.txt
           + evidence/factory-git-metadata-simplify01/legacy-gate.txt
           + evidence/factory-git-metadata-simplify01/diff-check.txt
           + evidence/factory-git-metadata-simplify01/gate-fast.txt
           ## Status OPEN -> PASS
```

At most three commits. If a fourth is required:
`HALT_FACTORY_V2_TRANSITION_TOPOLOGY`.

---

## 11. Closure handoff

Follow the transitional v1 HANDOFF shape documented in
ACT §21. The HANDOFF.md for THIS ACT may include the final
PASS/HALT verdict because this ACT itself is still transitional
v1; the new v2 HANDOFF template appended to
`docs/factory/HANDOFF-TEMPLATE.md` MUST NOT be used for this
ACT's HANDOFF.

The new v2 HANDOFF template takes effect for all ACTs opened
*after* this ACT closes.

T1-T12 all PASS. Recorded in
`evidence/factory-git-metadata-simplify01/tests.txt`.

### AC12 -- range validator
T13-T18 all PASS. Recorded in the same tests.txt.

### AC13 -- no numeric cap
The 5-commit synthetic ACT in T14 passes.

### AC14 -- correction trailers
Supersession semantics mechanically validated (T12 covers
ACT-Supersedes optionality and ACT-Corrected-Verdict required
when ACT-Supersedes is present).

### AC15 -- commit-msg hook
Valid ACT commit message passes. Malformed trailer commit
message fails. Ordinary non-ACT commit remains permitted.

### AC16 -- historical conservation
No historical ACT/HANDOFF is rewritten. `git diff` for
`docs/acts/` and `evidence/**/HANDOFF.md` between the entry
HEAD and the closure HEAD is empty.

### AC17 -- legacy oracle conservation
`scripts/quality/factory-closure-status-check.sh` continues
to PASS its bounded managed universe (6 pairs). Recorded in
`evidence/factory-git-metadata-simplify01/legacy-gate.txt`.

### AC18 -- compiler conservation
`git diff --name-only <ENTRY>..HEAD -- src/` is empty.

### AC19 -- hygiene
At the live closure observation:

```
git diff --check              rc=0
sh scripts/quality/gate-fast.sh rc=0  (VERDICT=PASS)
worktree                       clean (git status --porcelain empty)
```

Recorded in
`evidence/factory-git-metadata-simplify01/{diff-check,gate-fast}.txt`.

### AC20 -- transitional topology
This ACT itself closes within its v1 cap of three commits
(C1 RED, C2 IMPL, C3 CLOSE).

* this ACT contract
  (`docs/acts/ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01.md`);
* closure evidence
  (`evidence/factory-git-metadata-simplify01/**`).

### forbidden

* any `src/**` change;
* any compiler, IR, LLVM, ABI, or production semantic change;
* any rewrite of historical ACT/HANDOFF files
  (V2-13 grandfather policy);
* any retroactive trailers on historical commits;
* rebases, history rewriting, or amend chains;
* removing `scripts/quality/factory-closure-status-check.sh`
  or `scripts/quality/llvm-closure-status-check.sh` (they
  remain responsible for their bounded v1 universe);
* widening `docs/factory/act-handoff-map.tsv` with v2 ACTs;
* GitHub CI changes;
* new third-party dependencies;
* a daemon, a database, or a registry for ACT metadata.
