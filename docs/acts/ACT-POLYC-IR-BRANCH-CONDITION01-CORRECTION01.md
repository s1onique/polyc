# ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION01 — Closure requalification

```text
ACT-ID                = ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION01
ACT-KIND              = closure-requalification (NOT a new compiler ACT)
                        the compiler change itself is preserved.
                        This ACT rewrites the closure contract.
PARENT-ACT            = ACT-POLYC-IR-BRANCH-CONDITION01 (f631760 PASS — now HALTED)
PARENT-IMPL           = cbf726ed939956ebc79790371a9d372942b10b05 (sound; preserved)
ENTRY                 = cbf726ed939956ebc79790371a9d372942b10b05
FINAL                 = 50a158ee403348bf85bc2654f867e58368a95ada (CORRECTION01 loop-breaker; mechanical binding — see HANDOFF.md ## Identity)
FOLLOWED-BY           = ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION02 (bounded docs/evidence repair; closure identity bookkeeping)
COMMIT-CAP            = 3 (RED + impl-doc + closure-evidence)
DOC-CHARTER           = docs/CHARTER.md
DOC-ROADMAP           = docs/ROADMAP.md
DOC-AGENTS            = AGENTS.md
```

## 0. Trigger and motivation

Reviewer verdict on ACT-POLYC-IR-BRANCH-CONDITION01:

```text
REJECT PASS — implementation is good, but closure has two binding P0s.
```

P0-1 (AC-23 false-GREEN):
  Original closure invoked F6 (toolchain unavailable) to claim
  "AC-23 PASS (structurally unchanged from predecessor)". The
  reviewer correctly pointed out: "structurally unchanged" is not
  "test harness PASS". Discovery: LLVM 22.1.8 IS available in the
  nix store (`/nix/store/b6fykfvclbq81yis03blk6bqsmapmhdm-llvm-22.1.8-dev/`),
  so the original "toolchain unavailable" claim was a false negative
  caused by failing to look in the canonical cross-package store.

P0-2 (AC-26/L2 overclaim):
  Original HANDOFF claimed "even if L2 were removed for other
  reasons, branch semantics for this class would still be correct".
  This is correct at the NEUTRAL IR SEMANTIC level (the explicit
  `cmp_ne(cond, 0)` establishes the predicate semantically) but
  is overclaimed for the CURRENT NATIVE EXECUTION (where IR_CALL
  i8 result still depends on the callee's movzbq/uxtb to establish
  a sane full-register narrow return before the native icmp).

## 1. Decision

This is a **closure-requalification ACT**, not a new compiler ACT.
The implementation commit `cbf726e` is **preserved verbatim**. No
production-code changes are authorized; only the closure contract
is corrected.

Decision rules:

```text
D1. If a closure commit claims AC-X PASS without actually running
    AC-X, the closure is FALSE-GREEN and must be HALTED.
D2. If a closure commit overclaims a semantic property beyond the
    proven scope, the closure is OVERSTATED and must be CORRECTED.
D3. Closure-requalification ACTs may revert (or amend) the prior
    closure commit. They MUST NOT modify the prior implementation
    commit absent new evidence requiring it.
D4. When F6 is invoked, the agent MUST enumerate canonical
    toolchain locations (PATH, /usr/local, /opt, nix store,
    brew cellar) before concluding "toolchain unavailable".
```

## 2. Scope

In scope:
- Re-running `make llvm-spike-test` against the implementation commit
  using the now-located LLVM 22.1.8 toolchain.
- Recording actual LLVM spike output (positive + negative matrices).
- Distinguishing IR-semantic vs native-machine in AC-26.
- Recording the `tos.HH rc=0` finding as P1 residue (independent
  bug discovered during this re-investigation).
- Issuing a new closure commit with corrected PASS verdict.

Out of scope:
- Modifying src/ir.c (the impl commit is preserved).
- Modifying any other src/* file.
- Adding LLVM feature support.
- Revising the predecessor CORRECTION03 evidence (F14).

## 3. Acceptance criteria

```text
AC-C01  Original ACT's f631760 closure is reversed (or amended)
AC-C02  LLVM 22 toolchain location is documented and reproducible
AC-C03  ./hcc rebuilt with HCC_ENABLE_LLVM=ON against cbf726e
AC-C04  `make llvm-spike-test` actually runs (not skipped, not stubbed)
AC-C05  Real llvm-spike-test output captured under evidence/
AC-C06  AC-23 verdict recorded from actual harness output (not F6)
AC-C07  AC-26 corrected to distinguish IR-semantic vs native-machine
AC-C08  L2 claim narrowed to "neutral IR semantics removed"
AC-C09  The historical `--emit-llvm` rc=0 transcript is
        reclassified as a shell-capture artifact; actual hcc
        rc=1 (verified at src/main.c:585-588). Recorded as
        P1 residue (no hcc bug).
AC-C10  No src/ changes beyond cbf726e
AC-C11  3-commit topology preserved (RED+impl-doc combined +
        closure-evidence + loop-breaker). The loop-breaker is
        part of CORRECTION01 closure; it is NOT a separate ACT.
        Total commits on top of impl cbf726e = 3.
AC-C12  HANDOFF supersedes original HANDOFF with corrected verdict
```

## 4. Failure modes

```text
F-CM1  If `make llvm-spike-test` RED-flaps a real defect introduced
       by cbf726e, HALT this correction ACT and surface the defect
       to the next ACT. Do NOT silently widen scope to fix.
F-CM2  If the LLVM-enabled build fails for reasons unrelated to
       cbf726e (build environment, missing transitive deps), halt
       with HALT_BUILD_ENVIRONMENT_DEGRADED.
F-CM3  If the original ACT's PASS claim cannot be corrected without
       reverting cbf726e, that is itself a finding. Open a new ACT
       to investigate whether the implementation itself is wrong;
       do NOT silently "fix" by reverting here.
```

## 5. Closure

A corrected PASS verdict requires:

```text
AC-C04 PASS = `make llvm-spike-test` exit code 0 against cbf726e
AC-C06 PASS = AC-23 verdict derived from harness output (no F6)
AC-C07 PASS = IR-semantic / native-machine distinction explicit
```

If any of these cannot be satisfied, this correction ACT closes
**HALT_BRANCH_CONDITION01_CLOSURE_REQUALIFICATION**, not PASS.
