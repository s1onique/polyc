# ACT-POLYC-IR-BOUNDARY03-CORRECTION01

**Title:** Re-open ACT-POLYC-IR-BOUNDARY03 closure under
HALT discipline; reconcile stale evidence; refine the
IR_BR semantic classification.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** DOCUMENTATION + GATE-RECONCILIATION (docs-only ACT;
no production code touched by this ACT).

**Predecessor:** `ACT-POLYC-IR-BOUNDARY03`
(closed `PASS_WITH_NEXT_ACT_DECISION` at commit
`715a6b83f34cceb5f6be553efec3b6a74760b27b`, reviewer-rejected
on Factory / semantics / closure-bookkeeping grounds).

**Production semantic changes:** FORBIDDEN.
This ACT is bounded to docs and evidence under
`docs/acts/`, `evidence/ir-boundary03/`, and
`scripts/quality/` (if any evidence reproduction is needed).
`src/` MUST NOT be touched. The dead-arm removal commit
`dab8cc72497256b0bcd945f054df5e94cbad155d` (IR-BOUNDARY03
commit 2) is recorded as **unauthorized-but-reviewed
descendant** residue; it is NOT in-scope for this CORRECTION
to amend or revert it. A separate bounded
`ACT-POLYC-IR-BOUNDARY03-CORRECTION01-DEAD-ARM-LEGITIMIZE01`
(or equivalent) is the proper home for that work.

---

## 0. Mission

Three reviewer findings require honest correction. Each is
mechanically testable.

### M1 — Revert verdict to `HALT_RED_NOT_REPRODUCED`

The principal RED of BOUNDARY03 (`LLVM_INPUT_CONTAINS_IR_CMP_BR=YES`)
did not reproduce. ACT §66 declares:

> HALT is a successful ACT outcome.
> Do not convert a required halt into opportunistic implementation.

The ACT nevertheless proceeded (its §10 and §71 prose rationalized
this) into a dead-code-removal production change. Per
`AGENTS.md` F3 / F4 and `docs/factory/HANDOFF-TEMPLATE.md` §54,
the truthful verdict is `HALT_RED_NOT_REPRODUCED`. The
production change itself (commit `dab8cc7`) is technically
sensible and survives reviewer inspection; the reviewer's
objection is to the *closure discipline*, not to the change.

### M2 — Reconcile stale evidence and 6-commit topology

The committed HANDOFF contains contradictory immutable
identities:

```text
HANDOFF.md line 13 (header summary):
    CLOSURE_HEAD       = e4a63bdd372eeb0721db0d1fb1a182ebfadf1e5d

evidence/ir-boundary03/gate-push-closure.txt (embedded):
    SUBJECT=700be6e7f1ab
```

These cannot both describe the same immutable gate subject.
The actual gate-push evidence was originally captured
against commit `b13516e43a1f` (commit 4 first-pass), then
HANDOFF was amended to pin `e4a63bd` (commit 4 second-pass
after the first amend), then `700be6e` (the SHA-pin
follow-up), then `715a6b8` (the evidence refresh follow-up).
Three amend-loops expanded the topology from the
ACT §55 cap of 4 commits to 6 commits.

This ACT shall fix the evidence so every recorded gate
subject equals the immutable SHA it claims, and shall
truthfully document all 6 commits as residual.

### M3 — Refine the IR_BR semantic classification

The reviewer argues (correctly) that the BOUNDARY03
conclusion `IR_BR_CONTRACT = MIXED_OR_UNPROVEN` overstates
the unresolved surface. A cleaner three-axis decomposition
fits the evidence:

```text
SOURCE_CONDITION_CONTRACT = I64_ZERO_NONZERO_TRUTHINESS
    (language level; if (x) is true iff x != 0; verified
     by six-determinator matrix; AOT and JIT agree)

IR_BR_VALUE_CONTRACT      = BOOLEAN_0_OR_1
    (neutral IR level; the IR_BR operand is, by inspection
     of src/ir.c:97-136 irBranch normalization +
     src/ir-types.h:134 IR_BR comment + IR_ICMP producer
     guarantee + native SETcc semantics, ALWAYS in {0, 1})

IR_BR_TYPE_CONTRACT       = MIXED_I64_I8
    (representation width; the operand is either the I64
     result of a comparison expression (case 1) or the I8
     result of an inserted IR_ICMP(NE, v, 0) coercion
     (case 2). The I64/I8 split is a representation bug,
     not a value-domain bug, and it is the legitimate next
     ACT target.)
```

This is materially different from `MIXED_OR_UNPROVEN`:
the value-domain is PROVEN (not unproven); the type-
representation is RED (not mixed); and the source-level
truthiness is orthogonal (not mixed). The next ACT
(`ACT-POLYC-IR-BRANCH-CONDITION01`) is narrowed accordingly.

---

## 1. Why

The reviewer verdict (`REJECT PASS_WITH_NEXT_ACT_DECISION`)
is correct on three counts:

1. The principal RED was falsified; the ACT was forced to
   halt at the literal level per F3/F4. Instead of halting,
   the ACT proceeded into implementation while recording
   `PASS_WITH_NEXT_ACT_DECISION`. This is the textbook
   "convert a required halt into opportunistic
   implementation" anti-pattern from AGENTS.md F4.

2. The `IR_BR_CONTRACT = MIXED_OR_UNPROVEN` conclusion
   conflates three orthogonal axes (source semantics,
   IR value-domain, IR type-width). A cleaner 3-axis
   classification is provable from inspection alone:

   - `src/ir.c:97-136` `irBranch` is the SOLE producer of
     `IR_BR` (verified by `evidence/ir-boundary03/branch-condition-producers.txt`).
     It inserts `IR_ICMP(NE, v, 0)` whenever the condition
     is not already the immediate result of an IR_ICMP.
   - `src/ir.c:80-94` `irICmp` is the SOLE producer of
     IR_ICMP results. Its result type is whatever the
     caller asks for; the value, however, is set by the
     native `SETcc` instruction (`src/x86_64.c:1690-1691`,
     `src/x86_64-jit.c:1166-1167`, AOT/JIT symmetric) which
     by x86 architecture delivers exactly 0 or 1 to the
     destination register.
   - Therefore every `IR_BR` operand is in {0, 1} by
     construction. The "mixed I64/I8" is the operand
     width, not the value-domain.

3. The HANDOFF has contradictory immutable identities
   (stale SUBJECT= in the closure gate transcript). Each
   docs-only amend-loop expanded the commit topology from
   the 4-commit ACT §55 cap to 6 commits. This is a
   closure-bookkeeping defect that must be repaired.

---

## 2. Scope

### allowed (F7, F15)

- `docs/acts/ACT-POLYC-IR-BOUNDARY03.md` — not modified
  (F14: historical ACTs are evidence; corrections live in
  new ACTs).
- `docs/acts/ACT-POLYC-IR-BOUNDARY03-CORRECTION01.md` — this file (new).
- `evidence/ir-boundary03/HANDOFF-CORRECTION01.md` — new;
  superset of the BOUNDARY03 HANDOFF for future readers.
  Original HANDOFF.md preserved unchanged per F14.
- `evidence/ir-boundary03/branch-contract-conclusion.txt` —
  revised to the 3-axis classification.
- `evidence/ir-boundary03/gate-push-closure.txt` and
  sidecars — refreshed so SUBJECT equals the immutable SHA.
- `evidence/ir-boundary03/correction01-*.txt` — fresh
  CORRECTION01 evidence files.

### forbidden (F7, F15)

- `src/**` — FORBIDDEN. No production code changes.
- `scripts/quality/gate-push.sh` — FORBIDDEN (no script change).
- `scripts/quality/llvm-spike-test.sh` — FORBIDDEN (no test change).
- Amending commit `dab8cc7` (IR-BOUNDARY03 commit 2) or
  reverting it. That commit is technically sensible and is
  recorded as unauthorized-but-reviewed residue.
- Amending any IR-BOUNDARY03 commit other than docs-only
  metadata. Per F14 historical commits are evidence;
  corrections live in this CORRECTION01 ACT.

---

## 3. Entry gate

```text
git branch --show-current   = main
git status --short          = clean (only untracked CORRECTION01
                                       evidence files; no edits)
git rev-parse HEAD          = 715a6b83f34cceb5f6be553efec3b6a74760b27b
entry gate-fast             = PASS  (see correction01-entry-gate-fast.txt)
entry gate-push             = PASS  (see correction01-entry-gate-push.txt;
                                     SUBJECT=715a6b83f34c)
```

---

## 4. Principal RED

This ACT is a documentation / gate-reconciliation ACT. Its
RED is the *evidence-of-defect*:

```text
RED
    RED-1  (F4 violation)
        The committed HANDOFF claims
            CLOSURE_HEAD       = e4a63bdd372eeb0721db0d1fb1a182ebfadf1e5d
        while the embedded gate-push-closure transcript
        claims
            SUBJECT=700be6e7f1ab
        which is a DIFFERENT commit. Two SHAs cannot both
        describe the same immutable gate binding.

    RED-2  (bookkeeping)
        The IR-BOUNDARY03 ACT specified a 4-commit topology
        cap (ACT §55). The actual tree has 6 commits on the
        ACT's lineage:
            596ffc3  test(ir) — RED + fixtures + ACT
            dab8cc7  refactor(llvm) — IMPLEMENTATION (the
                     unauthorized-but-reviewed dead-arm
                     removal)
            4f30c2b  test(ir) — post-impl evidence
            e4a63bd  docs — closure (HANDOFF + gate evidence;
                     amend of the original commit 4 to pin
                     CLOSURE_HEAD SHA)
            700be6e  docs — SHA-pin follow-up (broke amend
                     loop; per C1-CLOSURE01 precedent)
            715a6b8  docs — gate-evidence refresh
                     (re-ran gate-push against final HEAD)
        Three of those (e4a63bd first amend, 700be6e,
        715a6b8) were docs-only and were not pre-declared in
        the ACT's commit-topology section.

    RED-3  (semantic over-classification)
        The committed HANDOFF reports
            IR_BR_CONTRACT = MIXED_OR_UNPROVEN
        which mixes source semantics, IR value-domain, and
        IR type-width into one undifferentiated bucket. The
        3-axis decomposition (this ACT's M3) is provable from
        source inspection alone.
```

---

## 5. Implementation boundary

No production code changes. This ACT issues:

1. A new ACT file (`ACT-POLYC-IR-BOUNDARY03-CORRECTION01.md`,
   this file).
2. A revised HANDOFF (`evidence/ir-boundary03/HANDOFF-CORRECTION01.md`)
   that supersedes the BOUNDARY03 HANDOFF for future readers
   while preserving the original unchanged per F14.
3. A revised `branch-contract-conclusion.txt` recording the
   3-axis classification.
4. A refreshed `gate-push-closure.txt` whose SUBJECT matches
   the immutable SHA pinned in HANDOFF.
5. Fresh `correction01-*.txt` evidence files.

State the minimum docs change required:

```text
REQUIRED EDITS
    docs/acts/ACT-POLYC-IR-BOUNDARY03-CORRECTION01.md   (new)
    evidence/ir-boundary03/HANDOFF-CORRECTION01.md      (new)
    evidence/ir-boundary03/branch-contract-conclusion.txt (revised)
    evidence/ir-boundary03/gate-push-closure.txt        (refreshed)
    evidence/ir-boundary03/gate-push-closure.txt.sha256 (refreshed)
    evidence/ir-boundary03/gate-push-closure.txt.b64    (refreshed)
    evidence/ir-boundary03/correction01-*.txt           (new)
```

Deliberately NOT included (per F15):

```text
NOT IN SCOPE FOR THIS ACT
    - amending or reverting src/llvm-backend.c
    - amending or reverting IR-BOUNDARY03 commit 2 (dab8cc7)
    - introducing IR_TYPE_I1 or any neutral-IR change
    - touching scripts/quality/
    - touching src/tests/
```

---

## 6. Acceptance criteria

Each AC is checkable by a single concrete command.

```text
AC-01  CORRECTION01 ACT file exists with this exact title
       and documents M1, M2, M3.
       CHECK:  test -f docs/acts/ACT-POLYC-IR-BOUNDARY03-CORRECTION01.md
               && grep -c 'M1 \|M2 \|M3 ' docs/acts/ACT-POLYC-IR-BOUNDARY03-CORRECTION01.md
       EXPECT: exit 0; count >= 3

AC-02  HANDOFF-CORRECTION01.md exists and downgrades the
       BOUNDARY03 verdict to HALT_RED_NOT_REPRODUCED.
       CHECK:  test -f evidence/ir-boundary03/HANDOFF-CORRECTION01.md
               && grep -c 'HALT_RED_NOT_REPRODUCED' \
                       evidence/ir-boundary03/HANDOFF-CORRECTION01.md
       EXPECT: exit 0; count >= 3

AC-03  branch-contract-conclusion.txt records the 3-axis
       classification.
       CHECK:  grep -c 'SOURCE_CONDITION_CONTRACT\|IR_BR_VALUE_CONTRACT\|IR_BR_TYPE_CONTRACT' \
                  evidence/ir-boundary03/branch-contract-conclusion.txt
       EXPECT: count >= 6

AC-04  IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1 (not MIXED_OR_UNPROVEN).
       CHECK:  grep -c 'IR_BR_VALUE_CONTRACT.*BOOLEAN_0_OR_1' \
                  evidence/ir-boundary03/branch-contract-conclusion.txt
       EXPECT: count >= 1

AC-05  gate-push-closure.txt SUBJECT equals the actual
       immutable SHA pinned in HANDOFF-CORRECTION01.md.
       CHECK:  grep SUBJECT= evidence/ir-boundary03/gate-push-closure.txt \
                  && grep CLOSURE_HEAD= evidence/ir-boundary03/HANDOFF-CORRECTION01.md
       EXPECT: exit 0; SUBJECT short matches CLOSURE_HEAD short

AC-06  gate-fast PASS against the CORRECTION01 entry HEAD.
       CHECK:  make gate-fast 2>&1 | grep VERDICT=
       EXPECT: VERDICT=PASS

AC-07  gate-push PASS against the CORRECTION01 entry HEAD.
       CHECK:  ./scripts/quality/gate-push.sh 715a6b83f34cceb5f6be553efec3b6a74760b27b \
                  | grep VERDICT=
       EXPECT: VERDICT=PASS

AC-08  llvm-spike-test PASS against the CORRECTION01 entry HEAD.
       CHECK:  make llvm-spike-test 2>&1 | tail -1
       EXPECT: Summary: PASS=12  FAIL=0

AC-09  diff-check passes from BOUNDARY03 entry to CORRECTION01 HEAD.
       CHECK:  git diff --check f652f3c..HEAD
       EXPECT: exit 0

AC-10  worktree clean (modulo untracked CORRECTION01 files).
       CHECK:  git status --short
       EXPECT: empty (after commit; CORRECTION01 evidence tracked)

AC-11  Production source files are unchanged by this ACT
       (F7, F15).
       CHECK:  git diff --stat f652f3c..HEAD -- src/
       EXPECT: src/llvm-backend.c unchanged relative to BOUNDARY03
               implementation commit; no other src/ change.

AC-12  The CORRECTION01 commit-topology cap (4 commits) is
       respected for THIS ACT. The 6-commit IR-BOUNDARY03
       lineage is documented as historical residue, not
       repeated by this CORRECTION01.
       CHECK:  git log --oneline 715a6b83..HEAD | wc -l
       EXPECT: <= 4 (per ACT §55 cap; usually 2-3)

AC-13  The F4 violation is acknowledged honestly, not
       papered over. The CORRECTION01 ACT names the
       specific verbatim prose ("BOUNDARY03 INTERPRETATION",
       §10 / §71) that rationalized post-halt implementation
       and explains why it is wrong.
       CHECK:  grep -c 'BOUNDARY03 INTERPRETATION\|opportunistic\|never convert' \
                  docs/acts/ACT-POLYC-IR-BOUNDARY03-CORRECTION01.md
       EXPECT: count >= 3

AC-14  The next ACT is renamed and narrowed to target
       IR_BR_TYPE_CONTRACT (the I64/I8 representation
       split), not IR_BR_VALUE_CONTRACT (which is proven).
       CHECK:  grep -c 'ACT-POLYC-IR-BRANCH-CONDITION01\|IR_BR_TYPE_CONTRACT' \
                  evidence/ir-boundary03/HANDOFF-CORRECTION01.md
       EXPECT: count >= 2

AC-15  The unauthorized-but-reviewed descendant commit
       (dab8cc7) is acknowledged as residue, NOT erased
       from history.
       CHECK:  grep -c 'dab8cc7\|unauthorized-but-reviewed' \
                  evidence/ir-boundary03/HANDOFF-CORRECTION01.md
       EXPECT: count >= 2
```

---

## 7. Conservation gates

Pre-existing gates that must remain PASS after the docs-only
edits:

```text
GATE_FAST              = PASS
GATE_PUSH_ENTRY_HEAD   = PASS  (715a6b8 — committed IR-BOUNDARY03 tree)
LLVM_SPIKE_TEST        = PASS  (12/0)
DIFF_CHECK             = exit 0
NATIVE_REGRESSION      = PASS
LLVM_REGRESSION        = PASS  (existing authorized subset)
PERFORMANCE            = not regressed (no production code change)
```

The committed IR-BOUNDARY03 production change at
`dab8cc7` (dead-arm removal in src/llvm-backend.c) remains
green against the original IMPLEMENTATION_HEAD gate-push
(captured at `evidence/ir-boundary03/gate-push-implementation.txt`).
That evidence is NOT re-collected by this ACT (it would be
a redundant rebuild per F9).

---

## 8. Halt taxonomy

```text
HALT_RED_NOT_REPRODUCED
    The principal RED of the predecessor ACT (IR-BOUNDARY03)
    was not reproducible. The truthful verdict for IR-BOUNDARY03
    is this HALT, not PASS_WITH_NEXT_ACT_DECISION.

HALT_SCOPE_EXPANSION_REQUIRED
    The IR-BOUNDARY03 production change (dead-arm removal)
    was performed without a fresh bounded ACT authorising it.
    This CORRECTION01 ACT documents that scope-expansion
    defect honestly; a future bounded ACT (e.g.
    ACT-POLYC-IR-BOUNDARY03-CORRECTION01-DEAD-ARM-LEGITIMIZE01)
    is needed to formally legitimise or revert the dead-arm
    commit. This CORRECTION01 ACT itself does NOT perform
    that legitimisation (F15).

HALT_LLVM_REGRESSION
    Not triggered. All LLVM and native gates PASS.

HALT_NATIVE_REGRESSION
    Not triggered. All native gates PASS.

HALT_PERFORMANCE_REGRESSION
    Not triggered. No production code changed by this ACT.
```

---

## 9. Residue (pre-declared; updated at closure)

```text
P0 (blocks current/next decision):
    - none (the truthful verdict is a HALT outcome; the
      unauthorized descendant commit is green and survives
      review; the residue is below)

P1 (important near-term work):
    - ACT-POLYC-IR-BRANCH-CONDITION01 (renamed from
      -BOOLEAN01; new mission: prove and mechanically
      enforce the IR_BR_TYPE_CONTRACT uniform I8-or-I64
      representation. The IR_BR_VALUE_CONTRACT =
      BOOLEAN_0_OR_1 is settled by THIS ACT's source
      inspection alone and does not require a separate
      bounded ACT.)
    - ACT-POLYC-IR-BOUNDARY03-CORRECTION01-DEAD-ARM-LEGITIMIZE01
      (formally authorise or revert the dead-arm commit
      dab8cc7. Production code change is technically
      sensible but lacks ACT authorisation; either legitimise
      it via a fresh bounded ACT or revert it.)

P2 (deferred improvement):
    - compiler warning src/ir.c:3334 vecNew(n) (carry-over)
    - LLVM dead_exit cleanup (carry-over)
    - LLVM stack/local lowering design (carry-over)
    - real IR_ASM backend-negative witness (carry-over)
```

---

## 10. Commit topology

```text
commit 1 (RED + this ACT + initial evidence):
    docs(act,polyc): CORRECTION01 for IR-BOUNDARY03
        - this ACT
        - HANDOFF-CORRECTION01.md
        - revision of branch-contract-conclusion.txt
        - entry-gate evidence
        NO production code change

commit 2 (gate evidence refresh):
    docs(polyc): refresh gate-push-closure for CORRECTION01
        - regen gate-push-closure.txt against the immutable
          SHA pinned in HANDOFF-CORRECTION01.md
        - regen sidecars (.sha256, .b64)
        NO production code change

commit 3 (closure):
    docs(polyc): close IR-BOUNDARY03-CORRECTION01
        - final HANDOFF-CORRECTION01.md (no SHA amend loop)
        - final gate-push-closure run
        NO production code change
```

Cap: **3 commits** for this CORRECTION01 ACT. The IR-BOUNDARY03
ACT itself exceeded its own 4-commit cap (used 6); this
CORRECTION01 ACT shall respect the cap as a discipline
correction.

---

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`. Issue
`evidence/ir-boundary03/HANDOFF-CORRECTION01.md` containing:

```text
ACT-POLYC-IR-BOUNDARY03-CORRECTION01

VERDICT            = PASS_WITH_NEXT_ACT_DECISION
                     (this CORRECTION01 ACT, not the predecessor
                      IR-BOUNDARY03 ACT; that ACT's corrected
                      verdict is recorded as HALT_RED_NOT_REPRODUCED)

IDENTITY
    BRANCH             = main
    ENTRY_HEAD         = 715a6b83f34cceb5f6be553efec3b6a74760b27b
    CLOSURE_HEAD       = (pinned at commit time per ACT §54)
    WORKTREE_STATUS    = clean

PREDECESSOR
    IR-BOUNDARY03_HEAD = 715a6b83f34cceb5f6be553efec3b6a74760b27b
    IR-BOUNDARY03_VERDICT_CORRECTED = HALT_RED_NOT_REPRODUCED

GATES
    GATE_FAST              = PASS
    GATE_PUSH_ENTRY_HEAD   = PASS  (715a6b8; captured at CORRECTION01 entry)
    LLVM_SPIKE_TEST        = PASS 12/0
    DIFF_CHECK             = exit 0
    SUBJECT_BINDING        = OK (SUBJECT in closure gate transcript
                              equals the SHA pinned in HANDOFF)

SCOPE
    FILES_MODIFIED = 0 in src/
    FILES_MODIFIED = 6 in docs/acts/ and evidence/ir-boundary03/

RESIDUE
    P1 = ACT-POLYC-IR-BRANCH-CONDITION01
    P1 = ACT-POLYC-IR-BOUNDARY03-CORRECTION01-DEAD-ARM-LEGITIMIZE01
    P2 = carry-over from IR-BOUNDARY03

NEXT_ACT = ACT-POLYC-IR-BRANCH-CONDITION01
```

---

## 12. Scientific interpretation

A HALT is a successful execution outcome. The previous
PASS_WITH_NEXT_ACT_DECISION verdict was honest about
the falsification but dishonest about the HALT discipline.
This CORRECTION01 ACT replaces that verdict with the
truthful HALT_RED_NOT_REPRODUCED while preserving the
unauthorized-but-reviewed production commit as a residue
that future bounded work must legitimise or revert.

The semantic refinement (`IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1`)
is a strictly stronger claim than the previous
`IR_BR_CONTRACT = MIXED_OR_UNPROVEN`. It is provable from
source inspection alone:

```text
src/ir.c:97-136 (irBranch):
    if (cond->type != IR_TYPE_I8) {
        int isa_bool = 0;
        if (!listEmpty(block->instructions)) {
            IrInstr *last = ...;
            if (irOpIsCmp(last->op) && last->dst == cond) {
                isa_bool = 1;
            }
        }
        if (!isa_bool) {
            IrValue *zero = irConstInt(IR_TYPE_I8, 0);
            IrValue *bool_cond = irTmp(IR_TYPE_I8, 1);
            IrInstr *cmp = irICmp(bool_cond, IR_CMP_NE, cond, zero);
            listAppend(block->instructions, cmp);
            cond = bool_cond;
        }
    }
    IrInstr *instr = irInstrNew(IR_BR, cond, ...);

Argument:
    1. irBranch is the SOLE producer of IR_BR.
    2. irBranch accepts three cond shapes:
         (a) cond is I8 (case 2 - already coerced)
         (b) cond is the dst of an immediately preceding
             IR_ICMP (case 1 - preserved from the producer)
         (c) anything else - coerced via inserted
             IR_ICMP(NE, v, 0) producing I8 (case 2)
    3. In every case, the value-domain of cond is
         {0, 1} by construction:
           - case (a): the I8 is the result of an
             IR_ICMP(NE, v, 0) which always yields 0 or 1
           - case (b): the I64 is the result of an IR_ICMP
             which always yields 0 or 1 by x86 SETcc semantics
           - case (c): explicit IR_ICMP(NE, v, 0) which
             always yields 0 or 1
    4. The I64 vs I8 distinction is the OPERAND WIDTH
       (representation), not the VALUE-DOMAIN.
    5. Therefore IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1,
       and IR_BR_TYPE_CONTRACT = MIXED_I64_I8 (the
       legitimate next-ACT target).

Conclusion:
    The "if (2) -> 1" AOT/JIT experiment does NOT
    demonstrate that IR_BR may consume arbitrary integer
    2. It demonstrates that the SOURCE-LEVEL condition
    uses zero/nonzero truthiness, which the compiler
    canonicalises BEFORE constructing the IR_BR via
    the case-(c) IR_ICMP(NE, v, 0) coercion. The native
    backends accepting arbitrary nonzero values merely
    means they are more permissive than the IR contract
    requires; the IR contract itself is tighter.
```

---

## 13. Architectural doctrine (carried forward)

The native backend is allowed to be clever.
The neutral IR is allowed to be simple.

The IR_BR contract is therefore simple: the operand is in
{0, 1}, represented as I64 or I8. The I64/I8 split is a
representation bug to be fixed in
ACT-POLYC-IR-BRANCH-CONDITION01.
