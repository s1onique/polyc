# HANDOFF -- ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01

Factory-Version: 2

## Result

Append-only Git history is now a mechanically enforced
Factory invariant for authoritative `main`.

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

* `.githooks/pre-push`: added two graph-property checks for
  `refs/heads/main` (refuse delete; refuse non-fast-forward
  via `git merge-base --is-ancestor`). The existing
  `git replace -l` check is unchanged in semantics and now
  bound by a permanent regression test. Topic branches are
  intentionally not policed by this ACT.
* `scripts/quality/factory-append-only-test.sh`: new
  regression suite that runs against synthetic repos and
  exercises NC1..NC7.
* `AGENTS.md`: extended the "Append-only Git history"
  section with a "Mechanical enforcement" subsection
  pointing at the hook and the regression suite.
* `docs/factory/DOCTRINE.md`: added §24
  (F-GIT-APPEND-ONLY mechanical enforcement) binding the
  hook's enforcement posture.
* `docs/factory/GIT-METADATA.md`: added a "Mechanical
  binding" subsection referencing the ACT and the
  regression suite.
* `evidence/factory-append-only-guard01/`: RED and GREEN
  transcripts for the suite, plus the RED notes.

## Evidence

* `evidence/factory-append-only-guard01/red-pre-impl-suite.txt`
  Pre-IMPL run of the new suite against the unchanged
  hook: PASS=4 FAIL=3 (NC2, NC3, NC4 fail).
* `evidence/factory-append-only-guard01/red-notes.txt`
  Per-RED explanation of NC2/NC3/NC4 and the absence of
  any test for NC5.
* `evidence/factory-append-only-guard01/green-post-impl-suite.txt`
  Post-IMPL run of the same suite against the new hook:
  PASS=7 FAIL=0.
* Conservation: `scripts/quality/factory-v2-test.sh`
  PASS=35 FAIL=0; `scripts/quality/gate-fast.sh`
  VERDICT=PASS; `git diff --check` clean; production
  source untouched.

## Production delta

None.

* `git diff --name-only <ENTRY>..HEAD -- src/` is empty.
* No compiler / IR / LLVM / ABI change.
* No historical ACT/HANDOFF rewritten.
* No new third-party dependency.
* No daemon / registry / DB.

## Residue

* P1 -- server-side enforcement (`receive.denyNonFastForwards`
  + `receive.denyDeletes`, plus the GitHub branch-protection
  equivalent) is intentionally out of scope; this is an
  operator action.
* P2 -- merge-aware Factory-v2 range checker (per
  pre-declared residue). Not a defect.
* P2 -- the historical 551-ahead fork graph. F14: frozen as
  evidence; do not reopen.

## Recommended next ACT

ACT-POLYC-LLVM-BYTE-MEMORY01 (per agreed board ordering).
