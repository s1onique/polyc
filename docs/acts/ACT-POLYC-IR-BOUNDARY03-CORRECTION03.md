# ACT-POLYC-IR-BOUNDARY03-CORRECTION03

Status: PASS.
Inherits from: CORRECTION02 (which is being honest-downgraded to
              PASS_WITH_TOPOLOGY_BREACH).
Goal: docs/evidence-only closure correction. Three reviewer P0/P1
      findings must be acknowledged honestly; no production code
      changes permitted.

## Reviewer findings (CORRECTION02 closure)

The main semantic correction in CORRECTION02 was accepted:
  SOURCE_CONDITION_CONTRACT = ZERO/NONZERO TRUTHINESS   PROVEN
  IR_BR_VALUE_CONTRACT      = ZERO/NONZERO TRUTHINESS   PROVEN
                              (replaces BOOLEAN_0_OR_1)
  IR_BR_TYPE_CONTRACT       = MIXED_I64_I8              PROVEN
  bypass reachable from real source                      PROVEN
  LLVM clean refusal                                      PROVEN

But three closure defects remain.

## P0-1: cap-violation (3 vs 4)

ACT-POLYC-IR-BOUNDARY03-CORRECTION02.md §9 declared a 3-commit cap:

```
## §9 — Commit topology (cap = 3 commits)
...
This 3-commit cap is enforced by this ACT §11.
```

and AC-12 says `CORRECTION02 commit cap = 3`.

The actual lineage was 4 commits (cbc0e00, 0971c4d, e4b66f7, 46a65c2).

## P0-2: FINAL_HEAD self-pinning (amend-loop residual)

The CORRECTION02 HANDOFF pinned FINAL_HEAD = 68ce2bf033428e0e26c984890741f1eb6eb101d2
with a DRIFT NOTE admitting "may be off by 1-2 amend iterations".
That is not an immutable identity. Correct binding stores the
gate output in evidence whose name does NOT contain the SUBJECT SHA,
and lets the reviewer verify by `git rev-parse HEAD~` (the
substantive Commit 1, since the FINAL_HEAD itself is the
evidence-only Commit 2) matching the SUBJECT line in the
captured log, not by trusting a committed SHA.

## P1: "all four native backends zero-extend the operand" overclaim

backend-emission-analysis.md stated the four backends "zero-extend the
operand and test the full register". Actually emitted x86_64 AOT
sequence (witness-02, the bypass case):

```asm
# _TestId body
    callq   _Identity
    testq   %rax, %rax          ; IR_BR emission (no movzbq here)
    jz      .LIRBB1_6

# _Identity body (callee)
    movzbq  %al, %rax           ; IR_RET epilogue (zext lowering)
    retq
```

aarch64 AOT sequence (same witness):

```asm
# _TestId body
    bl      _Identity
    cmp     x0, #0              ; IR_BR emission (no uxtb here)
    b.eq    .LIRBB1_6

# _Identity body
    uxtb    w0, w0              ; IR_RET epilogue (zext lowering)
    ret
```

The zero-extension happens in the callee's IR_RET epilogue, NOT in
the caller's IR_BR emission. IR_BR itself just does an integer test
on the operand value as-is.

For the bypass class the IR-level ret in the callee is i64 because
parameter-arrival/store widens narrow values, so the IR_RET epilogue
in the callee lowers to a zero-extending move (`movzbq %al, %rax` /
`uxtb w0, w0`). The caller's IR_BR then sees a zero-extended value
in the full return register and the test is correct.

The two-layer claim must be three layers:
  L1: IR_BR emits an integer test on the operand register.
  L2: For IR_BR i8 from IR_CALL, the callee's IR_RET lowering
      performs zero-extension (because the IR-level ret is i64).
  L3: Therefore IR_BR's full-register test is correct at runtime.


L1 is proven by src/x86_64.c:1883..1908 and src/aarch64.c:1635..1670
(emitted textual integer-test sequence).
L2 is proven by the emitted assembly captured in this ACT's
evidence and by the IR dump (`Identity` does `zext %t4 i64 tmp,
%l2 i8 local; ret %t4 i64 tmp`).
L3 follows mechanically.

## Mission (single)

    M1: docs/evidence-only closure correction.
        M1.1  ACKNOWLEDGE the 3->4 commit-cap breach of CORRECTION02
              §9 / AC-12 as a historical record (per F14, do NOT
              rewrite §9 retroactively); record
              ACT_DECLARED_CAP=3 / ACTUAL_COMMITS=4 in CORRECTION03
              evidence.
        M1.2  CAPTURE gate-push against the FINAL_HEAD of CORRECTION02
              (the closure loop-breaker commit) and store the gate
              output in evidence whose name does NOT contain the
              SUBJECT SHA. Provide a mechanical `git rev-parse HEAD~`
              check in closure-facts.txt that confirms the
              substantive Commit 1 SHA matches the recorded SUBJECT
              (Commit 2 is the evidence carrier and exempt per AC-06).
        M1.3  REWRITE the "all four native backends zero-extend the
              operand" sentence in backend-emission-analysis.md as a
              three-layer L1/L2/L3 statement backed by the
              actually-emitted assembly snippets captured in this
              ACT's evidence dir.

## Scope (F7)

Production code MUST NOT change. Touched:
  - docs/acts/ACT-POLYC-IR-BOUNDARY03-CORRECTION03.md (new)
  - evidence/ir-boundary03-correction03/ (new)
  - evidence/ir-boundary03-correction02/HANDOFF-CORRECTION02.md
    (single annotation append-only block, marked
    "CORRECTION03 annotated" per M1.1)
  - evidence/ir-boundary03-correction02/backend-emission-analysis.md
    (REWRITE the overclaim per M1.3 in the relevant section)

Not touched: src/**, scripts/**, Makefile, etc. New test fixtures
may be added under src/tests/ir-boundary03-correction03/ if M1.3
needs them.

## Acceptance criteria

    AC-01  ACT-POLYC-IR-BOUNDARY03-CORRECTION03.md exists and
           contains M1.1, M1.2, M1.3 (parseable; verifiable by grep).
    AC-02  ACT_DECLARED_CAP=3 / ACTUAL_COMMITS=4 annotation present
           in HANDOFF-CORRECTION02.md (append-only block) AND in
           evidence/ir-boundary03-correction03/closure-facts.txt.
    AC-03  gate-push was run on the FINAL_HEAD of CORRECTION02 (the
           closure loop-breaker commit); the evidence file under
           evidence/ir-boundary03-correction03/gate-push-final/ has
           a name that does NOT contain the SUBJECT SHA. The SUBJECT
           line in the gate output identifies the substantive Commit
           1; a mechanical `git rev-parse HEAD~` check in
           evidence/ir-boundary03-correction03/closure-facts.txt
           confirms the substantive Commit 1 SHA matches SUBJECT
           (Commit 2 / FINAL_HEAD is exempt per AC-06).
    AC-04  backend-emission-analysis.md section "all four native
           backends zero-extend" replaced with the three-layer
           L1/L2/L3 statement; x86_64 and aarch64 emitted-assembly
           snippets are captured verbatim as separate files under
           evidence/ir-boundary03-correction03/witness-02-emitted/
               witness-02-x86_64-apple-darwin.s
               witness-02-aarch64-apple-darwin.s
           The .gitignore has a per-file exception for both files
           (the blanket *.s rule was silently excluding them).
    AC-05  diff-check empty from CORRECTION02 FINAL_HEAD to
           CORRECTION03 FINAL_HEAD for src/ + scripts/ + Makefile.
    AC-06  gate-push PASS on the substantive Commit 1 tree is
           the closure contract. The gate output is committed
           verbatim in
           evidence/ir-boundary03-correction03/gate-push-final/log.txt
           with SUBJECT=<Commit 1 SHA>. Commit 2 (the FINAL_HEAD,
           the evidence carrier) is exempt from a self-referential
           gate-push witness per the reviewer's option (1) — a
           gate-push on FINAL_HEAD is not required because Commit 2
           adds only docs/evidence (no production code), so
           conservation-of-established-behavior (F10) is satisfied
           by inheritance from Commit 1's PASS. The Commit 2 SHA
           appears nowhere in the closure contract. The reviewer
           verifies identity by running
               git rev-parse HEAD~
               grep ^SUBJECT evidence/.../gate-push-final/log.txt
           which must yield the same value.
    AC-07  CORRECTION03 commit cap = 2 (RED + GREEN only).
    AC-08  NEXT_ACT decision unchanged from CORRECTION02 §15
           (still ACT-POLYC-IR-BRANCH-CONDITION01, now with
           additional input: the L1/L2/L3 distinction).

## §Y - Commit topology (cap = 2 commits)

    Commit 1 (RED+substantive): ACT + HANDOFF-annotation +
              closure-facts + backend-emission-analysis.md
              (rewritten) + l1l2l3-analysis.md + the two emitted
              .s files + .gitignore exception.
    Commit 2 (evidence-only): gate-push-final/log.txt which
              contains the captured gate-push output for
              Commit 1's tree (SUBJECT=<Commit 1 SHA>, bound
              mechanically per AC-06). Commit 2 is exempt
              from a self-referential gate-push witness per
              AC-06.

    This 2-commit cap is enforced by this ACT §Y. The closure
    loop procedure, if Commit 1 must be amended after
    Commit 2 exists, is:

        1.  re-stage the needed docs/evidence edits;
        2.  re-run `scripts/quality/gate-push.sh HEAD` on the
            new Commit 1 tree;
        3.  overwrite
            evidence/ir-boundary03-correction03/gate-push-final/log.txt
            with the new gate output (SUBJECT=<new Commit 1 SHA>);
        4.  `git commit --amend` Commit 2 with the new log.txt.

    After this procedure, `git rev-parse HEAD~` equals the
    new Commit 1 SHA equals the new SUBJECT line in log.txt,
    so AC-06's mechanical identity check continues to hold.
    This is docs/evidence-only closure correction, so no
    production code or test is regenerated between iterations.

## §Z - Next ACT (unchanged)

    ACT-POLYC-IR-BRANCH-CONDITION01
        Mission: choose between (i) uniform I8/I64 representation
                 in IR_BR (canonicalise IR_CALL dst or insert a
                 ZEXT before IR_BR) OR (ii) tighter cmp_ne
                 invariant (reject i8 condition paths in
                 src/ir.c:107..122). This ACT now also has the
                 L1/L2/L3 distinction as additional input:
                 (ii) would only need to touch L1, while (i)
                 would touch both L1 and L2.

    The CORRECTION02 ACT explicitly does NOT pick (i) vs (ii);
    CORRECTION03 inherits that constraint.
