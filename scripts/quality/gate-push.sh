#!/bin/sh
# scripts/quality/gate-push.sh
#
# PolyC local push quality gate.
#
# Question: does the exact committed tree being pushed reproduce the
# repository's broad local quality baseline?
#
# This gate creates a temporary detached Git worktree at the requested
# commit and runs the full local native gate inside it. The caller's
# working tree is not used directly.
#
# Usage:
#   scripts/quality/gate-push.sh [<commit>]
#
# Default commit: HEAD
#
# Exit code:
#   0  all checks PASS
#   non-zero on any FAIL or HALT
#
# Network: not required.

set -eu

# --- locate repository root -------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

if [ ! -d .git ]; then
    echo "POLYC_GATE=push"
    echo "STATUS=ERROR"
    echo "REASON=not inside a git repository ($REPO_ROOT)"
    exit 2
fi

# --- resolve subject commit -------------------------------------------------

subject_input="${1:-HEAD}"

if ! subject_sha=$(git rev-parse --verify "${subject_input}^{commit}" 2>/dev/null); then
    echo "POLYC_GATE=push"
    echo "SUBJECT=$subject_input"
    echo "STATUS=ERROR"
    echo "REASON=cannot resolve commit: $subject_input"
    exit 2
fi

# Short form for human-readable output.
subject_short=$(printf '%s' "$subject_sha" | cut -c1-12)

echo "POLYC_GATE=push"
echo "SUBJECT=$subject_short"

# --- set up temporary detached worktree ------------------------------------

# Place the worktree under TMPDIR when available, otherwise /tmp.
tmp_base="${TMPDIR:-/tmp}"
tmp=$(mktemp -d "${tmp_base%/}/polyc-gate.XXXXXX")

cleanup() {
    git worktree remove --force "$tmp" >/dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM HUP

if ! git worktree add --detach "$tmp" "$subject_sha" >/dev/null 2>&1; then
    echo "STATUS=ERROR"
    echo "REASON=failed to create detached worktree at $subject_short"
    exit 2
fi

# From here on, every command runs inside the isolated worktree.
# We deliberately do NOT rely on the caller's dirty working tree.

# --- helper -----------------------------------------------------------------

# run_check <name> <command...>
#
# Runs the command in the isolated worktree, streaming its output to the
# caller's stdout/stderr so engineers can see real progress. Returns 0
# if both:
#
#   (a) the command's exit status is 0; AND
#   (b) no generic failure markers appear in the output (the HolyC
#       test-runner intentionally returns 0 from Main even when tests
#       fail, so exit status alone is insufficient).
#
# We deliberately do NOT scrape specific counts like "90/90" or
# numbers-of-tests. We only look for the universal failure markers
# already emitted by the existing test harness. This is the smallest
# change that makes the gate reflect reality without encoding a
# specific expected baseline.
#
# We do NOT scrape specific counts. We do NOT match the bare "ERROR:"
# token, since the compiler emits ERROR-prefixed diagnostics that are
# not always failures of the test (e.g. JIT-internal diagnostics
# appearing in successful AOT tests).

run_check() {
    name=$1
    shift

    # Stream output to a temp file so we can both display it (when the
    # check passes) and grep it (when we need to verify no failures).
    out_file=$(mktemp "${TMPDIR:-/tmp}/polyc-gate-out.XXXXXX")
    trap 'rm -f "$out_file" 2>/dev/null || true' RETURN

    # Run the command, capturing output.
    set +e
    (cd "$tmp" && "$@") >"$out_file" 2>&1
    rc=$?
    set -e

    # Stream the captured output so the engineer sees what happened.
    cat "$out_file"

    if [ "$rc" -ne 0 ]; then
        echo "CHECK=$name STATUS=FAIL"
        echo "REASON=$name exited with status $rc"
        return 1
    fi

    # Exit status was 0 — but the HolyC test runner does not propagate
    # test failures via exit status. Scan for the narrowest possible
    # per-test failure markers emitted by the existing test harness.
    #
    # We look for these tokens anywhere on a line (not just at line
    # start) because the harness sometimes prefixes them with the test
    # name, e.g.:
    #
    #   "Test - indirect struct return C interop: FAILED: 1/3"
    if grep -E -q 'FAILED: |Failed to compile|Failed to run' "$out_file"; then
        echo "CHECK=$name STATUS=FAIL"
        echo "REASON=$name emitted test-failure markers despite zero exit status"
        return 1
    fi

    echo "CHECK=$name STATUS=PASS"
    return 0
}

# We collect the highest-severity result; checks run in order so the
# user sees partial state when something fails.
gate_failed=0

# --- GPUSH-1: clean build ---------------------------------------------------

if ! run_check build sh -c 'make clean && make'; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-2: AOT suite -----------------------------------------------------

if ! run_check aot sh -c 'make unit-test'; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-3: JIT suite -----------------------------------------------------

if ! run_check jit sh -c 'make jit-unit-test'; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-4: LSP suite -----------------------------------------------------

# Makefile's `make lsp-test` is already hermetic: it builds libtos into
# build/test-prefix, then compiles the HolyC harness against that prefix.
if ! run_check lsp sh -c 'make lsp-test'; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-5: diff hygiene over the isolated tree --------------------------

# Standalone mode: validate the tree itself is clean in the index sense.
# (No pushed range to diff against when invoked standalone on a SHA.)
if ! (cd "$tmp" && git diff --check >/dev/null 2>&1); then
    echo "CHECK=diff-check STATUS=FAIL"
    echo "REASON=git diff --check reported whitespace or conflict markers"
    gate_failed=1
else
    echo "CHECK=diff-check STATUS=PASS"
fi

# --- verdict ----------------------------------------------------------------

if [ "$gate_failed" -ne 0 ]; then
    echo "VERDICT=FAIL"
    exit 1
fi

echo "VERDICT=PASS"
exit 0
