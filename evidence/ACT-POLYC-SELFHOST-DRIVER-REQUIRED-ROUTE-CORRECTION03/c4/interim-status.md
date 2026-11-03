# CORRECTION03 C4 INTERIM STATUS

This is NOT a closure HANDOFF. The ACT is still OPEN. It is an interim
status that records where the ACT stands after the C4 remediation, so
that the reviewer has a single document to read.

Under Factory v2 the verdict authority is the CLOSE commit's
`ACT-Verdict` trailer. There is NO CLOSE commit, so there is NO verdict
yet.

## IDENTITY

```text
ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03

ENTRY_HEAD_OF_THE_C4_REMEDIATION   cdd927ac804fe007a9440d577929984bbf4f08f8
FINAL_HEAD                          1cd483975c38d45a1085b5a9ebb707fae7e946b0
WORKTREE_STATUS                     clean
```

The C4 remediation is two forward-only commits:

```text
33d24f8ecbf3ad6ec78e7178b846313ca888e1ca  EVIDENCE: repair the fresh-build target, the comparator and the emission coverage
1cd483975c38d45a1085b5a9ebb707fae7e946b0  EVIDENCE: record the parser and lexer conservation measurement
```

Both carry `ACT: ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03`
and `ACT-Phase: EVIDENCE`. Neither carries an `ACT-Verdict`, which is
correct: only a CLOSE commit carries a verdict.

## THE THREE P1 FINDINGS

| finding | state | the decisive measurement |
| --- | --- | --- |
| P1-1 fresh-build target | REPAIRED | a fresh isolated build with NO seeded object PASSES; the RED is in `p1-1-red-fresh-build.log` and the GREEN in `p1-1-green-fresh-build.log`; every failure mode is detected independently in `p1-1-failure-mode-matrix.tsv` |
| P1-2 comparison infrastructure | REPAIRED | the comparator validates every observation BEFORE it compares it; ten adverse probes are each rejected with their OWN distinguishing reason in `p1-2-adverse-probe-rejection-ledger.tsv` |
| P1-3 emission coverage | REPAIRED | four emission domains have production executable witnesses with expectations derived from the genuine C oracle, in `p1-3-emission-coverage-ledger.tsv`; the ABI probe covers sixteen cases in `abi-domain-coverage.tsv` |

## THE TWO P2 FINDINGS

| finding | state | the decisive measurement |
| --- | --- | --- |
| P2-1 evidence hygiene and chronology | RECORDED FORWARD-ONLY | `chronology-and-accounting-correction.md` retracts the preimplementation-freezing claim; `self-referential-manifest-hashes.tsv` measures the historical discrepancy; `covering-manifest.txt` is the forward-only covering manifest and EXCLUDES its own hash |
| P2-2 the 15-versus-8 ABI accounting | CORRECTED IN NEW EVIDENCE | the original C2 claim was NOT rewritten; `chronology-and-accounting-correction.md` records what the C2 claim said, what the C2 green log measured (8), and what the C4 extension measures (16) |

## GATES

```text
BUILD                      PASS
CORRECTION03 (fresh)       PASS  8/8 cases x 22 checks, 0 failures; ABI probe 16/16
CORRECTION03 emission      PASS  4 domains, 0 failures; domain fail-closed 6/6
CORRECTION03 adverse       PASS  10/10 probes rejected with distinct reasons
TARGETED (required route)  PASS
TARGETED (precedence)      PASS  5/5, fail-closed PASS
UNIT                       PASS  376/376 assertions, md5 BYTE-IDENTICAL to the baseline
LEXER                      PASS  89 / 45 / 23, zero failures
JIT                        PASS  (gate-push)
LSP                        PASS  (gate-push)
DIFF_CHECK                 PASS
AUTHORITIES                PASS  16/16 VERIFIED
CAUSALITY                  PASS  the ON observable CHANGED under a PolyC mutation
C DORMANCY                 PASS  the ON observable did NOT change under a C policy mutation
```

## SCOPE

```text
PRODUCTION_SEMANTICS_CHANGED=NO
```

The working production precedence decision in
`tools/bootstrap/selfhost-driver-wp001.HC` is NOT modified by the
remediation. The C oracle source is NOT modified. The historical
C0/C1/C2/C3 evidence is NOT modified. The ACT document is NOT modified.
The committed manifests are NOT rewritten.

The C4 change touches exactly the files the ACT's allowed scope
permits:

```text
Makefile
tools/quality/driver-required-route-correction03-compare.HC
tools/quality/driver-required-route-correction03-abi-probe.HC
tools/quality/driver-required-route-correction03-emission.HC   (new)
tools/quality/driver-required-route-correction03-adverse.HC   (new)
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c4/   (new)
```

## THE REMAINING GATE

C4 CLOSE is permitted ONLY after a NEW independent, READ-ONLY review of
the corrected head returns `C4_READY=YES` with ZERO unresolved
substantive P0/P1 findings.

That review has NOT run. It is the operator's responsibility to run it.

Until it returns `C4_READY=YES`:

* there is NO CLOSE commit;
* there is NO `ACT-Verdict`;
* there is NO push;
* there is NO WP-001 completion claim;
* there is NO M2 self-hosting claim;
* there is NO whole-CLI compiler ownership claim.

## RESIDUE

```text
P0 = -
P1 = the independent review of the corrected head must re-test all three
     P1 findings with fresh isolated builds and adversarial comparator
     inputs, and must return C4_READY=YES before C4 CLOSE
P1 = CORRECTION02's contradictory frozen predictions, generation matrix,
     NC17 conflict and acceptance ledgers require a separate evidence
     reconciliation ACT (inherited, unchanged)
P1 = whole-CLI compiler ownership remains incomplete and out of scope
     (inherited, unchanged)
P2 = a reusable evidence verifier distinguishing PASS, FAIL, UNRESOLVED
     and UNSUPPORTED is deferred to the evidence-reconciliation ACT
     (inherited, unchanged)
```

## NEXT_ACT

```text
the C4 CLOSE of THIS ACT, once the independent review returns
C4_READY=YES with zero unresolved substantive P0/P1 findings
```
