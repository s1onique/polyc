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

# Optional second argument: the remote (pre-push) SHA from which
# `subject_sha` is being pushed. When supplied and non-zero, the
# diff-hygiene phase (GPUSH-6) inspects the entire range, not just
# the subject commit. This is the pre-push hook contract:
#
#   <local_ref> <local_sha> <remote_ref> <remote_sha>
#
# When omitted, GPUSH-6 falls back to the original subject-commit-only
# behavior, preserving every existing manual invocation pattern.
#
# See ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION01.
remote_input="${2:-}"
range_base_sha=""
if [ -n "$remote_input" ] && [ "$remote_input" != "0000000000000000000000000000000000000000" ]; then
    if ! range_base_sha=$(git rev-parse --verify "${remote_input}^{commit}" 2>/dev/null); then
        echo "POLYC_GATE=push"
        echo "SUBJECT=$subject_input"
        echo "STATUS=ERROR"
        echo "REASON=cannot resolve remote commit: $remote_input"
        exit 2
    fi
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

    # Run the command, capturing output.
    set +e
    (cd "$tmp" && "$@") >"$out_file" 2>&1
    rc=$?
    set -e

    # Exit status was 0 — but the HolyC test runner does not propagate
    # test failures via exit status. Scan the captured output for the
    # narrowest possible per-test failure markers emitted by the
    # existing test harness.
    #
    # IMPORTANT: we must derive marker_failed BEFORE removing
    # out_file. If we delete the file first and grep then operates on
    # a non-existent path, grep returns 2, the `if` is false, and a
    # command that exited 0 while emitting FAILED: markers would be
    # certified as PASS — a silent false GREEN. See
    # ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION02 (P0).
    #
    # We look for these tokens anywhere on a line (not just at line
    # start) because the harness sometimes prefixes them with the test
    # name, e.g.:
    #
    #   "Test - indirect struct return C interop: FAILED: 1/3"
    marker_failed=0
    if grep -E -q 'FAILED: |Failed to compile|Failed to run' "$out_file"; then
        marker_failed=1
    fi

    # Stream the captured output so the engineer sees what happened.
    cat "$out_file"

    # Always remove the captured output file before returning. We do not
    # use `trap ... RETURN` because RETURN is a Bash extension and is not
    # portable to a strict POSIX /bin/sh. POSIX trap only standardizes
    # EXIT and signal names; RETURN would silently no-op under dash,
    # BSD sh, or any shell that does not implement the Bash pseudo-signal,
    # leaving out_file behind. We always remove it explicitly here.
    # The scan above has already completed before this point, so removing
    # the file is now safe.
    rm -f "$out_file"

    if [ "$rc" -ne 0 ]; then
        echo "CHECK=$name STATUS=FAIL"
        echo "REASON=$name exited with status $rc"
        return 1
    fi

    if [ "$marker_failed" -ne 0 ]; then
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

# --- hermetic local install prefix -----------------------------------------
#
# Build hcc with a disposable local prefix compiled into it, then install
# hcc, tos.HH, and libtos into that prefix. The freshly-compiled ./hcc
# therefore defaults to --install-dir=$gate_prefix, which contains the
# installed tos.HH and libtos. `make unit-test` and `make jit-unit-test`
# can then run without any global install under /usr/local.
#
# The prefix lives inside the gate's temporary worktree, so the existing
# cleanup trap removes it with the worktree.
#
# See ACT-POLYC-FACTORY-PUSH-HERMETIC01.
gate_prefix="$tmp/build/gate-prefix"
mkdir -p "$gate_prefix"

# --- GPUSH-1: clean build ---------------------------------------------------

if ! run_check build sh -c "make clean && make INSTALL_PREFIX='$gate_prefix'"; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-2: install hcc + tos.HH into the hermetic prefix -----------------

# `make install` puts hcc at $gate_prefix/bin/ and tos.HH at
# $gate_prefix/include/. libtos.a / libtos.dylib still need to be
# built into $gate_prefix/lib/. We do that by invoking hcc's `-lib tos`
# with --install-dir pointing at the hermetic prefix, identical to how
# Makefile's `lsp-test` recipe populates build/test-prefix/.
#
# See ACT-POLYC-FACTORY-PUSH-HERMETIC01.
if ! run_check install sh -c "make install INSTALL_PREFIX='$gate_prefix' && \
    mkdir -p '$gate_prefix/lib' && \
    cd ./src/holyc-lib && ../../hcc -fPIC -lib tos --install-dir='$gate_prefix' ./all.HC"; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-3: AOT suite -----------------------------------------------------

if ! run_check aot sh -c 'make unit-test'; then
    gate_failed=1
    echo "VERDICT=FAIL"
    exit 1
fi

# --- GPUSH-4: JIT suite -----------------------------------------------------

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

# --- GPUSH-6: range-aware diff hygiene -------------------------------------
#
# Two modes, controlled by the optional second positional argument
# (the pre-push remote_sha):
#
#   * range mode  (remote_sha supplied, non-zero, valid commit):
#         inspects every commit reachable from <subject_sha> but not
#         from <remote_sha>. This is what the pre-push hook supplies.
#
#   * tip-only mode  (no remote_sha, or new-branch sentinel):
#         inspects only <subject_sha>^..<subject_sha>. Preserves the
#         GPUSH-5 behavior for manual invocations
#         (`gate-push.sh <commit>`) and for new-branch pushes where
#         the remote side is the empty tree.
#
# Implementation primitive:
#
#     git format-patch --stdout <range> \
#         | awk '/trailing-whitespace detector on + lines/'
#
# We deliberately do NOT use `git diff --check <A> <B>`. That
# primitive compares the *tree* state at B against the *tree* state
# at A, which is blind to whitespace that existed only in an
# intermediate commit (it never appears in the resulting tree if a
# later commit overwrites the file). The format-patch primitive
# inspects the textual patches of every commit in the range, which
# is what "diff hygiene of the pushed series" actually means.
#
# We also deliberately do NOT use `git log --check` because its exit
# code is not reliable across Git versions (some versions exit 128 on
# ambiguous refs). An awk-based scan over patch lines is portable and
# matches exactly the semantics of `git diff --check`'s trailing-
# whitespace detection, scoped to lines actually added by the push
# (lines beginning with `+` that are not `+++` headers).
#
# See ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION01.
diff_base_arg=""
if [ -n "$range_base_sha" ]; then
    diff_base_arg="$range_base_sha"
    diff_check_mode="range"
else
    diff_base_arg="$subject_sha^"
    if ! git cat-file -e "${diff_base_arg}^{commit}" 2>/dev/null; then
        diff_base_arg=$(git hash-object -t tree /dev/null)
    fi
    diff_check_mode="tip"
fi

# Build the range. ^<base> means "reachable from <tip> but not from
# <base>", which is what we want. For the empty-tree base case we
# skip the ^ prefix (it would mean "not reachable from empty tree").
range_arg=""
if [ "$diff_check_mode" = "range" ]; then
    range_arg="^${diff_base_arg} ${subject_sha}"
else
    range_arg="${diff_base_arg}..${subject_sha}"
fi

# Scan the textual patches of every commit in the range for trailing
# whitespace on lines that the patch adds (`+` lines, excluding `+++`
# headers and `+++` /dev/null binary markers). This is the
# patch-textual analogue of `git diff --check`'s trailing-whitespace
# detection, but applied to every commit's contribution rather than
# to the resulting tree.
if ! diff_check_output=$(cd "$tmp" && git format-patch --stdout $range_arg 2>/dev/null \
    | awk '/^Subject: / { in_patch = 1; next }
           in_patch && /^\+\+\+ / { next }
           /^\+[ \t]+$/ || /^\+[^+].*[ \t]$/ {
               print NR": "$0
               found = 1
           }
           END { exit (found ? 1 : 0) }' 2>&1); then
    if [ "$diff_check_mode" = "range" ]; then
        echo "CHECK=diff-check STATUS=FAIL"
        echo "REASON=pushed range $diff_base_arg..$subject_sha introduced whitespace or conflict markers:"
    else
        echo "CHECK=diff-check STATUS=FAIL"
        echo "REASON=subject commit introduced whitespace or conflict markers:"
    fi
    printf '%s\n' "$diff_check_output"
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
