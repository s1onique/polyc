#!/bin/sh
# ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4.1 v3 C-API probe runner
#
# Runs the v3 capi_probe against all 3 RED fixtures and
# the errpath_probe (deliberately bad pipeline string)
# against 1 fixture. Captures per-fixture stdout/stderr
# AND the shell exit code. The reviewer requires
# process exit = 0 for all 3 RED fixtures, AND for the
# err-path probe (consumed-error path must NOT crash).
#
# Usage: ./run_capi_probes.sh
#
# Output files (all in this directory):
#   <fixt>.capi-stdout.txt           : post-pipeline IR for both APIs
#   <fixt>.capi-stderr.txt           : verdict + cleanup exit-0 confirmation
#   err-path.stderr                  : bad-pipeline-string module+function API error
#   cleanup-exit.txt                 : fixture-by-fixture shell exit code table
#   cleanup-exit-summary.txt         : aggregate STATUS line
#
# This script is RECON-only evidence; it is NOT part of
# the PolyC build.

set -u

PROBE=./capi_probe
ERRPROBE=./errpath_probe
PROBES_DIR=../probes
CLEANUP_EXIT_LOG=cleanup-exit.txt
CLEANUP_SUMMARY=cleanup-exit-summary.txt

if [ ! -x "$PROBE" ]; then
    echo "[run] $PROBE not built" >&2; exit 2
fi
if [ ! -x "$ERRPROBE" ]; then
    echo "[run] $ERRPROBE not built" >&2; exit 2
fi
if [ ! -d "$PROBES_DIR" ]; then
    echo "[run] $PROBES_DIR missing" >&2; exit 2
fi

FIXTURES="single_cond_probe_ENTRY_BLOCK_NAMED_BB1 i64_collapse_probe pos_b0_compare_digit"
: > "$CLEANUP_EXIT_LOG"
all_green=1

for fixt in $FIXTURES ; do
    src="$PROBES_DIR/$fixt.ll"
    stdout="$fixt.capi-stdout.txt"
    stderr="$fixt.capi-stderr.txt"
    if [ ! -f "$src" ]; then
        printf 'fixture=%-50s shell_exit=-1 (fixture missing: %s)\n' "$fixt" "$src" >> "$CLEANUP_EXIT_LOG"
        all_green=0
        continue
    fi
    "$PROBE" "$src" > "$stdout" 2> "$stderr"
    rc=$?
    cleanup_seen=$(grep -c 'CLEANUP-EXIT-0' "$stderr" || true)
    module_seen=$(grep -c '\[module-api\] VERDICT: PASS' "$stderr" || true)
    function_seen=$(grep -c '\[function-api\] VERDICT: PASS' "$stderr" || true)
    printf 'fixture=%-50s shell_exit=%d  CLEANUP-EXIT-0=%s  module-PASS=%s  function-PASS=%s\n' \
        "$fixt" "$rc" "$cleanup_seen" "$module_seen" "$function_seen" \
        >> "$CLEANUP_EXIT_LOG"
    if [ "$rc" != "0" ] || [ "$cleanup_seen" != "1" ] \
        || [ "$module_seen" != "1" ] || [ "$function_seen" != "1" ]; then
        all_green=0
    fi
done

# Err path: bad pipeline "mem2reggg,verify" against one fixture.
# Expectation:
#   * module API returns non-NULL LLVMErrorRef -> "unknown pass name 'mem2reggg'"
#   * function API returns non-NULL LLVMErrorRef -> "unknown function pass 'mem2reggg'"
#   * errpath_probe exits 0 (cleaned up; consumed errors)
#   * the captured stderr contains both error messages
ERR_OUT=err-path.stderr
"$ERRPROBE" "$PROBES_DIR/single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll" \
    > /dev/null 2> "$ERR_OUT"
rc=$?
mod_err=$(grep -c "unknown pass name 'mem2reggg'" "$ERR_OUT" || true)
fn_err=$(grep -c "unknown function pass 'mem2reggg' in pipeline 'mem2reggg,verify'" "$ERR_OUT" || true)
cleanup_seen=$(grep -c 'CLEANUP-EXIT-0' "$ERR_OUT" || true)
printf 'errpath=%-46s shell_exit=%d  CLEANUP-EXIT-0=%s  module-err=%s  function-err=%s\n' \
    "single_cond_probe_ENTRY_BLOCK_NAMED_BB1" "$rc" "$cleanup_seen" "$mod_err" "$fn_err" \
    >> "$CLEANUP_EXIT_LOG"
if [ "$rc" != "0" ] || [ "$mod_err" != "1" ] || [ "$fn_err" != "1" ] \
    || [ "$cleanup_seen" != "1" ]; then
    all_green=0
fi

if [ "$all_green" = "1" ]; then
    printf 'STATUS=PASS  (all 3 fixtures: shell_exit=0, CLEANUP-EXIT-0=1, module-PASS=1, function-PASS=1; err-path: shell_exit=0, both-error-msgs=1, CLEANUP-EXIT-0=1)\n' > "$CLEANUP_SUMMARY"
    exit 0
else
    printf 'STATUS=FAIL  (see %s)\n' "$CLEANUP_EXIT_LOG" > "$CLEANUP_SUMMARY"
    exit 1
fi
