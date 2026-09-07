# ACT-POLYC-IR-BOUNDARY03-CORRECTION02

**Title:** Resolve the `IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1` proof hole
identified by the CORRECTION01 reviewer. Either prove the contract
mechanically (GREEN) or halt the predecessor's PROVEN claim
(HALT_IR_BR_I8_ORIGIN_UNPROVEN).

## §1 — Context

ACT-POLYC-IR-BOUNDARY03-CORRECTION01 closed the predecessor
IR-BOUNDARY03 ACT and recorded three orthogonal axes:

    SOURCE_CONDITION_CONTRACT = I64_ZERO_NONZERO_TRUTHINESS   (PROVEN)
    IR_BR_VALUE_CONTRACT      = BOOLEAN_0_OR_1                (PROVEN — but see §2)
    IR_BR_TYPE_CONTRACT       = MIXED_I64_I8                  (PROVEN)

The reviewer rejected the IR_BR_VALUE_CONTRACT claim:

> `irBranch` (src/ir.c:97-136) bypasses normalization whenever
> `cond->type == IR_TYPE_I8`. Nothing in that function establishes
> `cond->type == IR_TYPE_I8` ⇒ cond originated from IR_ICMP.
> The corrected HANDOFF repeats that implication explicitly, so
> it is currently UNPROVEN.

The reviewer proposed:

> Open a tiny docs/test-recon correction, or fold this into a
> reviewer correction before declaring this ACT closed. The
> principal RED/question should be: "Can a real source program
> cause an arbitrary non-{0,1} IR_TYPE_I8 value to become the
> operand of IR_BR?" Use the real frontend seam. At minimum try
> U8 x = 2; if (x) return 1; return 0; and equivalents.

## §2 — Mission (M1)

Resolve the IR_BR_VALUE_CONTRACT proof hole by running real
source witnesses through the actual PolyC frontend (`--dump-ir`)
and recording what IR_BR operands actually appear. The mission is:

    M1.1 Reproduce the bypass class. Construct at least one source
         program whose `if (expr)` expression has `IR_TYPE_I8`
         and is NOT an immediate comparison, then dump the IR and
         confirm that the IR_BR operand is a raw `IR_TYPE_I8`
         value (not preceded by an inserted `cmp_ne`).
    M1.2 Reproduce the normalisation class. Confirm that
         non-I8 expressions still get the `cmp_ne` insertion
         (as expected from src/ir.c:107-122).
    M1.3 Decide. If M1.1 reproduces:
            IR_BR_VALUE_CONTRACT =
                BOOLEAN_0_OR_1 is FALSIFIED.
            The CORRECTION01 classification must be REVISED.
         Otherwise:
            IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1 stands.

## §3 — Verdict determination rule

    Outcome A (bypass REPRODUCES):
        IR_BR_VALUE_CONTRACT ≠ BOOLEAN_0_OR_1
        The contract must be REVISED to reflect what the IR
        actually permits and what the backends actually do.
        ACT-POLYC-IR-BRANCH-CONDITION01's mission widens.

    Outcome B (bypass DOES NOT reproduce):
        IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1 remains PROVEN.
        ACT-POLYC-IR-BRANCH-CONDITION01 retains its narrow
        mission (type-width uniformity only).

## §4 — Acceptance criteria (15 ACs)

    AC-01  ACT-POLYC-IR-BOUNDARY03-CORRECTION02.md exists
           and contains M1.1/M1.2/M1.3.
    AC-02  At least 4 distinct source witnesses run via
           `--dump-ir` and the output is captured in
           evidence/ir-boundary03-correction02/.
    AC-03  At least one witness shows the bypass class
           (IR_BR operand is i8 from a non-ICMP source).
    AC-04  At least one witness shows the normalization class
           (cmp_ne precedes br for non-I8 source).
    AC-05  The bypass-vs-normalization distinction is precisely
           characterised: which source shapes trigger which path
           in src/ir.c:107-122.
    AC-06  Runtime correctness verified for the bypass class
           via the JIT (`-jit` on a return-and-assert witness).
           The actual semantic at runtime is recorded.
    AC-07  Each native backend (x86_64 AOT, x86_64 JIT,
           aarch64 AOT, aarch64 JIT) is examined to determine
           how it interprets the bypass IR_BR operand. The
           actual emitted instruction sequence for a bypass
           case is captured.
    AC-08  The LLVM backend (src/llvm-backend.c) is examined
           for the bypass case. Either a clean rejection path
           is recorded (the IR_BR condition must be I64; an I8
           branch is refused with LLVM_BACKEND_UNSUPPORTED_*),
           or a witness shows it lowers correctly.
    AC-09  HANDOFF-CORRECTION02.md records the corrected
           classification with verbatim source citations
           and witness transcripts.
    AC-10  evidence/ir-boundary03-correction02/branch-contract-conclusion.txt
           replaces the CORRECTION01 classification of
           IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1 with the
           evidence-derived classification.
    AC-11  gate-fast and gate-push pass at CORRECTION02
           FINAL_HEAD (the substantive content commit).
    AC-12  CORRECTION02 commit cap = 3 (≤ ACT §11 cap of 4).
    AC-13  src/ untouched since dab8cc7 (git diff --stat empty).
    AC-14  CORRECTION01 verdict downgraded honestly if needed;
           residue captured for ACT-POLYC-IR-BRANCH-CONDITION01.
    AC-15  NEXT_ACT = ACT-POLYC-IR-BRANCH-CONDITION01 (now
           possibly widened), recorded in HANDOFF-CORRECTION02.md.

## §5 — Halts

    HALT_BYPASS_NOT_REPRODUCIBLE:
        If the witness class in M1.1 cannot be constructed
        (every I8 condition comes from a comparison/literal),
        then IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1 stands
        and this ACT closes PASS. This is the only case in
        which PASS is appropriate.

    HALT_BACKEND_BUG:
        If the runtime witness in AC-06 returns a value that
        disagrees with the source-level truthiness expectation,
        the native backends are incorrect and a separate
        ACT is required (this ACT then HALTs with
        HALT_BACKEND_BUG).

    HALT_SCOPE_EXPANSION_REQUIRED:
        If widening IR_BR_VALUE_CONTRACT requires changing
        production semantics (not just IR shape), this ACT
        HALTs with HALT_SCOPE_EXPANSION_REQUIRED and a
        separate bounded ACT is authored.

## §6 — Entry identity

    Per AGENTS.md F1, capture entry identity at ACT-start:

    ENTRY_HEAD = current HEAD when this ACT is opened.
    BRANCH     = main (current working branch).
    STATUS     = clean (no uncommitted changes).

## §7 — Residue (expected before execution)

    P0 = none blocking
    P1 = CORRECTION01 IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1
         over-proven (the active finding)
    P1 = dab8cc7 legitimisation (carry-over from CORRECTION01)
    P2 = src/ir.c:3334 vecNew(n) warning (carry-over)
    P2 = LLVM dead_exit cleanup (carry-over)
    P2 = LLVM stack/local lowering design (carry-over)
    P2 = real IR_ASM backend-negative witness (carry-over)

## §8 — Doctrine highlights

    F2 recon before redesign: the bypass is observed by running
        actual witnesses, not by reasoning about hypothetical
        source shapes. The witness comes first; the classification
        follows.
    F3 RED before production implementation: the M1.1 RED is
        observed by running `--dump-ir` against a real source.
        A "the bypass might exist in theory" argument is not a
        RED.
    F4 failures are evidence: if M1.1 reproduces, the previous
        PROVEN claim is WRONG, not "narrowly mistaken". The
        verdict for CORRECTION01 IR_BR_VALUE_CONTRACT PROVEN
        claim is downgraded.
    F5 no test weakening: no test is rewritten to make this
        ACT PASS.
    F6 no silent fallback: the LLVM backend's narrow
        `llTypeSupported = I64` rejection is NOT presented as
        a substitute for the IR's actual behaviour.
    F7 scope is conserved: no refactoring of src/ir.c or the
        backends; this is a recon/docs correction only.
    F8 no speculative abstraction: do not propose a uniform
        IR_BR normalization helper based on these witnesses;
        let the bounded ACT-POLYC-IR-BRANCH-CONDITION01 do that.
    F9 fresh-tree evidence: gate-push runs against the actual
        immutable SHA, not stale build dirs.
    F10 conservation before closure: gate-push at FINAL_HEAD
        must reproduce the same broad gates as the entry.
    F11 explicit residue: each discovered non-scope item gets
        a P-level entry.
    F13 evidence over persuasive prose: the verdict is "PASS"
        or "HALT_..." with a witness transcript, not adjectives.
    F14 current truth may invalidate history: CORRECTION01
        IR_BR_VALUE_CONTRACT PROVEN claim may be downgraded;
        the predecessor file is preserved unchanged.

## §9 — Commit topology (cap = 3 commits)

    Commit 1: ACT + HANDOFF + revised branch-contract-conclusion
              + entry identity + entry gates + raw witness
              transcripts (NEW evidence dir).
    Commit 2: Refresh gate-push-closure.txt to bind SUBJECT to
              FINAL_HEAD; refresh llvm-spike-test.txt if needed.
    Commit 3: Closure metadata (pin CLOSURE_HEAD = commit 2 SHA).

    This 3-commit cap is enforced by this ACT §11.
    (CORRECTION01 used 3 commits; this ACT inherits the same
    discipline to make the regression visible in history.)
