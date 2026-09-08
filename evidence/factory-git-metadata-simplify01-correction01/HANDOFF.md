# HANDOFF -- ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01

## Result

PASS

The reviewer HALT
`HALT_FACTORY_V2_TRAILER_GRAMMAR_NOT_BOUND` is resolved.
The Factory v2 architectural model is unaffected and remains
accepted. The mechanical enforcement is now bound to the
documented regex grammar.

`ACT-POLYC-LLVM-CORE04` is unblocked and becomes the first
real Factory v2 ACT.

## Proven (REDs -> GREENs)

* RED-1 (shell-glob false-GREEN on ACT id) is gone.
  - Old: `case "$ACT_ID_RAW" in ACT-POLYC-[A-Z0-9][A-Z0-9_-]*)`
    where POSIX shell `*` matches any string after the
    first character class.
  - New: `printf '%s\n' "$ACT_ID_RAW" | grep -Eq '^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$'`.
  - Negative tests T19 (`ACT-POLYC-AAevil`) and T20
    (`ACT-POLYC-AA/BAD`) FAIL rc=1 with STATUS=FAIL on
    the corrected validator; PASS on the old one.

* RED-2 (gsub whitespace normalization) is gone.
  - Old: `gsub(/[[:space:]]+/, "_", $0)` inside
    `trailer_value()` rewrote literal spaces to underscores
    before validation.
  - New: no rewriting; the literal parsed value is matched.
  - Negative tests T21 (`ACT-POLYC-AA BAD`) and T23
    (`PASS WITH NEXT ACT`) FAIL rc=1 with the literal
    value reported in REASON.

* RED-3 (verdict shell-glob false-GREEN) is gone.
  - Old: `PASS|PASS_[A-Z0-9_]*|HALT_[A-Z0-9_]*` shell glob
    accepted hyphens, slashes, and anything after the first
    character class.
  - New: `grep -Eq '^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'`.
  - Negative tests T24 (`PASS_X-bad`), T25 (`HALT_X/bad`),
    T26 (`HALT_X bad` as corrected verdict) all FAIL rc=1.
  - Range-check T34 verifies the same binding on
    ACT-Verdict on the CLOSE commit.

* RED-4 (doctrine inconsistency) is gone.
  - `docs/factory/GIT-METADATA.md` ACT id regex changed
    from `*` to `+`, so the prose "at least two
    characters after the prefix" now actually binds.
  - Negative test T22 (`ACT-POLYC-A`) FAIL rc=1.
  - Range-check T33 verifies the same on the ACT id arg.

## Files changed

* `scripts/quality/factory-v2-commit-msg-check.sh`
  - removed gsub normalization
  - replaced shell-glob case with grep -Eq
* `scripts/quality/factory-v2-range-check.sh`
  - same changes for ACT id arg and CLOSE verdict
* `scripts/quality/factory-v2-test.sh`
  - added T19-T34 (16 new tests)
  - introduced `expect_range_fail_no_cd` helper
* `docs/factory/GIT-METADATA.md`
  - ACT id regex `*` -> `+`
  - ACT-Verdict regex changed from PCRE `(?:_...)` to
    POSIX-ERE `(_...)`
  - added note forbidding shell-glob or PCRE-only
    constructs in validator implementations

## Conservation

* `src/` untouched (git diff --name-only <ENTRY>..HEAD -- src/
  empty)
* historical ACT/HANDOFF files untouched
* legacy `factory-closure-status-check.sh` PASS
  (GFAST-6, 6/6 pairs)
* gate-fast rc=0
* `git diff --check` rc=0
* worktree clean at closure
* T1-T12 commit-msg matrix: still PASS (no regression)
* T13-T18 range-check matrix: still PASS (no regression)

## Test counts

| Marker | Before this ACT | After this ACT |
| ------ | --------------- | -------------- |
| factory-v2-test PASS | 19 | 35 |
| factory-v2-test FAIL |  0 |  0 |
| Negative grammar tests | 0 | 8 (T19-T26) |
| Positive boundary tests | 0 | 6 (T27-T32) |
| Range-check grammar tests | 0 | 2 (T33-T34) |

## Residue

* P2 -- legacy `factory-closure-status-check.sh` remains
  future-work for retirement.
* P2 -- CI enforcement of v2 trailers (V2-3/V2-4/T1-T34)
  remains a separate ACT.
* P2 -- CORRECTION01 demonstrates the v1 self-pinning
  pattern is still in use for this transitional ACT and
  its HANDOFF (single transitional case, allowed by
  SIMPLIFY01 §21).

## Topology

```
29fb9afc  (predecessor -- SIMPLIFY01 closure)
0c28b7c   (SIMPLIFY01 C3 CLOSE -- 3 commits, at v1 cap)
0f999f8   (CORRECTION01 C1 RED    -- ACT + 4 RED witnesses + entry)
88853f1   (CORRECTION01 C2 IMPL   -- validators + tests + doctrine)
<pending> (CORRECTION01 C3 CLOSE  -- this HANDOFF + ## Status PASS)
```

Three commits total for CORRECTION01 (v1 cap).

## Next ACT

ACT-POLYC-LLVM-CORE04

(Becomes the first real Factory v2 ACT; uses Git trailers
for identity / phase / verdict; uses
`factory-v2-range-check.sh` for closure review; uses the
Factory v2 HANDOFF template.)
