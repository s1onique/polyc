# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION01 — evidence index

## What this ACT did

Closed a P0 architecture defect in `SpawnAndCapture`
(src/holyc-lib/tooling.HC) that deadlocked the runtime when
the child wrote more than 64 KiB to one pipe while the
other stream stayed open. Replaced the sequential drain with
a single `poll(2)` loop that always attempts to read on any
revents and only closes on read==0.

Caught a sub-bug in the first attempt (POLLHUP-before-EOF
byte loss) and fixed it in the same commit.

## Files

| File | Purpose |
|------|---------|
| `deadlock-red.txt`         | RED: pre-fix 4 MiB stderr-flood reproducer (10s watchdog kill) |
| `deadlock-green.txt`       | GREEN: corrected runtime, full byte accounting on all 3 stress modes |
| `stress-red-raw.txt`       | Raw transcript of the 10s watchdog kill |
| `stress-green-raw.txt`     | Raw transcript of the corrected run (all 3 modes) |
| `deadlock_probe.c`         | C subprocess fixture (stderr-flood / stdout-flood / interleave) |
| `deadlock_probe.HC`        | Alternate PolyC reproducer (NOT used; kept for reference) |
| `dl_check.HC`              | PolyC host that iterates the 3 modes and prints verdicts |
| `regression-matrix.txt`    | Full C3 selftest rerun on corrected runtime (18/18 PASS) |
| `gep-dogfood-rerun.txt`    | llvm-gep01-test.sh conservation rerun (30/30 PASS) |
| `ac-matrix-correction01.txt` | AC matrix delta (adds AC06, AC19; corrects summary to 31/31) |
| `patch-hygiene.txt`        | git diff --check on 456b71c..HEAD; documents 5 historical trailing blanks |
| `residue-correction01.txt` | Residue delta vs c4/residue.txt |
| `roadmap-correction01.txt` | Handoff describing the docs/ROADMAP.md update in the CORRECTION01 commit |
| `closure-summary.txt`      | C5 CORRECTION01 closure summary |

## Reproduction (quick)

```bash
# 1. Build fixture
gcc -O0 -o /tmp/deadlock_probe <repo>/deadlock_probe.c

# 2. Build dl_check
cd <repo>
./hcc --install-dir=$(pwd)/build/test-prefix dl_check.HC -o dl_check

# 3. Run
/tmp/hcc-watchdog 30 ./dl_check
# Expected:
#   mode=stderr-flood rc=0 out=16 err=4194320
#     OUT_SENT ERR_SENT
#   mode=stdout-flood rc=0 out=4194320 err=16
#     OUT_SENT ERR_SENT
#   mode=interleave rc=0 out=2466 err=2466
#     OUT_SENT ERR_SENT
```

## RED reproduction (pre-fix)

```bash
# Save fix; revert to b7d8937 implementation
git -C <repo> show b7d8937:src/holyc-lib/tooling.HC > src/holyc-lib/tooling.HC
./hcc --install-dir=$(pwd)/build/test-prefix dl_check.HC -o dl_check
/tmp/hcc-watchdog 10 ./dl_check
# Expected:
#   VERDICT=HANG (killed after 10s)
```
