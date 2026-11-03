# CORRECTION03 C4 ROUND 2 INTERIM STATUS

This is NOT a closure HANDOFF. The ACT is still OPEN. It is an interim
status that records where the ACT stands after the SECOND round of C4
remediation, so that the reviewer has a single document to read.

Under Factory v2 the verdict authority is the CLOSE commit's
`ACT-Verdict` trailer. There is NO CLOSE commit, so there is NO verdict
yet.

## IDENTITY

```text
ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03

ENTRY_HEAD_OF_ROUND_TWO    b5fe53867db2b4b0a27d2639396e836d7e59c9d8
WORK_FINAL_HEAD            NOT RECORDED. The commit that contains this
                           document is discovered from the Git history.
CONTAINED_BY               NOT RECORDED, by the repository's
                           "No SHA-of-self claims" rule.
```

The field naming convention is documented in
`c4r2/interim-head-clarification.md`.

## THE THREE P1 FINDINGS

| finding | state | the decisive measurement |
| --- | --- | --- |
| P1-1 pristine-build graph | REPAIRED | a pristine isolated checkout builds the comparator, the emission witness, the adverse probe and the capture tool with NO manual `make test-prefix-install`, NO object seeding and NO hidden setup; the header and the runtime archive are auto-generated and are real file targets with content-sensitive prerequisites; `c4r2/f1-failure-mode-matrix.tsv` |
| P1-2 fail-closed comparator | REPAIRED | the comparator validates the Mach-O structure on EACH SIDE independently, reads the exit status STRICTLY, REJECTS an unsupported expected class, and binds every observation to an invocation through a capture record and a per-case run ledger; sixteen adverse probes are each rejected with their OWN reason token; `c4r2/f2-adverse-rejection-ledger.tsv` |
| P1-3 archive semantic equivalence | REPAIRED | the archive is DECODED on each side and the DECODED members are compared by identity, name format, payload validity and payload bytes; five archive adverse experiments are each rejected with their OWN reason token; the independent `ar` cross-check measures DIFFERENT; `c4r2/f3-archive-rejection-ledger.tsv` |

## THE FOUR P2 FINDINGS

| finding | state | the decisive measurement |
| --- | --- | --- |
| P2-1 subject stamp | ADDRESSED | the stamp carries the subject's SHA-256, its Mach-O architecture, the verified symbol count, the producer's SHA-256 and the timestamp; `c4r2/p2-subject-stamp.txt` |
| P2-2 adverse reason attribution | ADDRESSED | every adverse probe requires its EXACT reason token, not merely a nonzero exit; `c4r2/f2-adverse-rejection-ledger.tsv` |
| P2-3 emission-domain recognition | ADDRESSED | the domain is recognized from the OBSERVED ARTIFACTS, not from source tokens; `c4r2/p2-emission-domain-observation.tsv` |
| P2-4 the 16-versus-15 ABI accounting | ADDRESSED | the roster's sixteenth row is now a DISTINCT argv shape, and the probe carries a MECHANICAL self-check that requires every pair of rows to be distinct; the measurement is 16 rows and 0 duplicates; `c4r2/p2-abi-distinct-shapes.tsv` |
| P2-5 the causal mutation reconstruction | ADDRESSED | the mutation is reconstructed FROM THE CURRENT TREE and MEASURED; the mutated class is ASSEMBLER_TEXT, which CONFIRMS the C3 description and the C3 result; `c4r2/causal-and-dormancy-correction.md` |
| P2-6 the original C4 causal record | PRESERVED | the committed `c4/causal-and-dormancy.tsv` is NOT modified; the correction is a new forward-only document |
| P2-7 the interim HEAD field | CLARIFIED | the committed field names the last commit of the remediation WORK; it cannot name the commit that contains the document; the committed document is NOT modified; `c4r2/interim-head-clarification.md` |

## THE FIVE DEFECTS THAT ROUND TWO ALSO FOUND

Round two did not only repair the findings. It also found five further
defects in the round-one repair, and every one of them is now fixed and
measured.

| defect | what it was | the decisive measurement |
| --- | --- | --- |
| D1 the required-symbol off-by-one | the comparator's symbol scan began at `argv[17]` and therefore SKIPPED its first required symbol, so the symbol requirement and the symbol-string bounds check NEVER RAN in the whole suite | the check now runs 8 times, once per case, and every case passes; `c4r2/f2-adverse-rejection-ledger.tsv` |
| D2 the doubled archive destination | the `libtos.a` recipe copied to `$(CURDIR)/$@` when `$@` is already absolute, so the destination was doubled and the copy FAILED in a pristine checkout | the pristine isolated checkout builds the archive; `c4r2/f1-pristine-build.log` |
| D3 the missing Mach-O structural controls | the adverse harness mutated content but never the Mach-O STRUCTURE | three controls, each with its own reason token; `c4r2/f2-adverse-rejection-ledger.tsv` |
| D4 the position-only member comparison | the witness compared the members BY POSITION, so it could not distinguish a RENAME from a DUPLICATE or an UNEXPECTED member | the member NAME MULTISET is now compared per side; `c4r2/f3-archive-rejection-ledger.tsv` |
| D5 the unchecked extended-name encoding | the decoder accepted ANY NUL inside the declared length, so an archive with a corrupted length was accepted and a PREFIX OF THE PAYLOAD was reported as the member's name | the decoder rejects a length whose terminator lies at or beyond the Mach-O magic; `c4r2/f3-archive-rejection-ledger.tsv` |

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

## SCOPE

```text
PRODUCTION_SEMANTICS_CHANGED=NO
```

The working production precedence decision in
`tools/bootstrap/selfhost-driver-wp001.HC` is NOT modified. The C oracle
source is NOT modified. The historical C0/C1/C2/C3 evidence is NOT
modified. The first C4 remediation's evidence is NOT modified. The ACT
document is NOT modified.

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
