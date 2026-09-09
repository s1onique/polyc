# HANDOFF -- ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01

Factory-Version: 2

## Result

The pre-push hook's append-only enforcement for
authoritative `refs/heads/main` is now bound to Git's
documented protocol fields (`remote_ref` for the
authoritative ref, `local_sha == ZERO_SHA` for the deletion
sentinel). The parent ACT's two binding bugs (P0-1
backwards deletion detection; P0-2 wrong source-vs-destination
ref) are closed. The regression suite covers eleven
protocol shapes (NC1..NC11) and passes against the
corrected hook.

Closure verdict is authoritative in the `ACT-Verdict`
trailer of this ACT's CLOSE commit.

## What changed (vs the parent's closed state at `a537672`)

* `.githooks/pre-push`: the append-only block now keys on
  `remote_ref == refs/heads/main` (not `local_ref`) and
  detects deletion via `local_sha == ZERO_SHA` (not
  `remote_sha == ZERO_SHA`). The skip-deletes block is
  moved AFTER the append-only guard so a real
  `git push origin :main` reaches the guard before being
  skipped.
* `scripts/quality/factory-append-only-test.sh`: extended
  from NC1..NC7 to NC1..NC11 with four new protocol-shape
  controls (NC8 real delete, NC9 feature->main non-FF,
  NC10 HEAD->main non-FF, NC11 feature->main FF positive)
  and a renamed NC4 whose semantic description now matches
  the protocol shape it actually exercises (create main
  when remote has none).
* `AGENTS.md`: the "Mechanical enforcement" subsection now
  names the correct fields, references `githooks(5)` for
  the deletion sentinel, and points at this correction ACT.
* `docs/factory/DOCTRINE.md` §24
  `F-GIT-APPEND-ONLY`: rebinds the forbidden-outcome list
  to the correct fields and explicitly enumerates the
  `feature:main` / `HEAD:main` source-name shapes.
* `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01.md`:
  this correction's contract (Mission / Why / Scope /
  Principal RED / AC01..AC09 / HALT / Residue).
* `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01-HANDOFF.md`:
  this HANDOFF.
* `evidence/append-only-guard01-correction01/`:
  - `red-pre-impl-suite.txt` -- pre-IMPL run of the
    extended suite against the parent's closed hook:
    PASS=7 FAIL=4 (NC4, NC8, NC9, NC10 FAIL).
  - `red-pre-impl-extra.txt` -- live shell-level
    reproductions of P0-1 (real delete accepted) and P0-2
    (feature:main non-FF accepted; HEAD:main non-FF
    accepted) against the parent's closed hook.
  - `red-notes.txt` -- per-RED explanation of why each
    adversarial case fails under the parent's hook.
  - `ac01-real-delete.txt`, `ac02-feature-non-ff.txt`,
    `ac03-head-non-ff.txt`, `ac04-feature-ff.txt`,
    `ac05-suite.txt` -- post-IMPL AC evidence.

## Evidence

* Pre-IMPL:
  `evidence/append-only-guard01-correction01/red-pre-impl-suite.txt`
  shows PASS=7 FAIL=4 against the parent's hook (the
  principal RED).
* Post-IMPL:
  `evidence/append-only-guard01-correction01/ac05-suite.txt`
  shows PASS=11 FAIL=0 against the corrected hook.
* Per-AC live hook transcripts at
  `evidence/append-only-guard01-correction01/ac0*.txt`.
* Conservation:
  - `scripts/quality/factory-v2-test.sh` PASS=35 FAIL=0
  - `scripts/quality/gate-fast.sh`        VERDICT=PASS
    (6/6 pairs)
  - `git diff --check`                    clean
  - `git diff --name-only <ENTRY>..HEAD -- src/` empty

## Production delta

None.

* `git diff --name-only <ENTRY>..HEAD -- src/` is empty.
* No compiler / IR / LLVM / ABI change.
* The parent's `ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01` and
  its HANDOFF are NOT rewritten (F14 -- they remain
  historical evidence of the reviewer's HOLD finding).
* No new third-party dependency.
* No daemon / registry / DB.

## Residue

* P0 -- none.
* P1 -- server-side enforcement
  (`receive.denyNonFastForwards` + `receive.denyDeletes`,
  plus the GitHub branch-protection equivalent) remains an
  operator action and is unchanged from the parent ACT.
* P2 -- merge-aware Factory-v2 range checker (unchanged).
* P2 -- the historical 551-ahead graph (F14: frozen).

## Next ACT

Per agreed board ordering: the Factory hardening pass is
now genuinely finished. Resume production work at
`ACT-POLYC-LLVM-BYTE-MEMORY01`. The pre-push hook now
mechanically enforces append-only `main` against the
real protocol shapes Git can deliver.
