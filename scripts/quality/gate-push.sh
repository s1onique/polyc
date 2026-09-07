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
#   scripts/quality/gate-push.sh <commit> <remote_sha>
#   scripts/quality/gate-push.sh <commit> --new-branch <remote>
#   scripts/quality/gate-push.sh <commit> --root-range
#
# Default commit: HEAD
#
# Modes:
#   <commit>            tip-only: inspect <commit>^..<commit>
#   <commit> <sha>      range:    inspect <sha>..<commit>
#   <commit> --new-branch <remote>
#                       new-branch: inspect commits reachable from
#                       <commit> but not from <remote>'s
#                       remote-tracking refs. Recommended for a
#                       brand-new branch pushed against a remote
#                       that may already hold its ancestors.
#   <commit> --root-range
#                       full history reachable from <commit>,
#                       down to the root. Degenerate fallback for
#                       anonymous URL pushes.
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

# Optional second argument. Three forms:
#
#   * <remote_sha>           -- range mode
#                                inspect reachable(subject) \ reachable(remote_sha)
#                                ordinary existing-branch push
#
#   * --new-branch <remote>  -- new-branch mode
#                                inspect reachable(subject) \ reachable(<remote>'s
#                                remote-tracking refs)
#                                brand-new branch against a remote that may
#                                already hold its ancestors
#
#   * --root-range           -- root-range mode
#                                inspect every commit reachable from <subject>
#                                down to the root. Degenerate fallback for
#                                new branches pushed where no destination
#                                remote can be determined (e.g. anonymous
#                                URL push with no configured remote).
#
#   (omitted)                -- tip-only mode
#                                inspect <subject>^..<subject>
#                                manual invocation pattern
#
# See ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION02 and
# ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION03.
remote_input="${2:-}"
third_input="${3:-}"
range_base_sha=""
new_branch_remote=""
range_mode="tip"  # "tip" | "range" | "new-branch" | "root-range"
if [ -n "$remote_input" ]; then
    case "$remote_input" in
        --new-branch)
            # New-branch mode: <remote> is the destination remote name.
            # The hook passes this from the remote_ref field (e.g. for
            # refs/heads/feature, the remote is the configured upstream
            # such as 'origin'). The third positional argument is the
            # remote name; default to 'origin' if absent.
            new_branch_remote="${third_input:-origin}"
            range_mode="new-branch"
            ;;
        --root-range)
            # Explicit full-history mode. Invoked when the hook has no
            # destination remote available (e.g. anonymous URL push).
            # This is the CORRECTION02 default for new branches; kept
            # as a deliberate fallback, NOT the default new-branch
            # semantics.
            range_mode="root-range"
            ;;
        *)
            if ! range_base_sha=$(git rev-parse --verify "${remote_input}^{commit}" 2>/dev/null); then
                echo "POLYC_GATE=push"
                echo "SUBJECT=$subject_input"
                echo "STATUS=ERROR"
                echo "REASON=cannot resolve remote commit: $remote_input"
                exit 2
            fi
            range_mode="range"
            ;;
    esac
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
# Four modes, controlled by the optional second positional argument:
#
#   * range mode (a real SHA is supplied as $2):
#         inspect every commit reachable from <subject_sha> but not
#         from <range_base_sha>. This is what the pre-push hook
#         supplies for ordinary existing-branch pushes.
#
#   * new-branch mode ($2 is "--new-branch", $3 is the remote name):
#         inspect reachable(subject) MINUS reachable(remote's
#         remote-tracking refs). The set of commits newly asked of
#         the destination remote by a brand-new branch whose
#         ancestors may already live there. Implemented as
#         `git rev-list <subj> --not --remotes=<remote>`.
#
#   * root-range mode ($2 is "--root-range"):
#         inspect every commit reachable from <subject_sha>, down to
#         the root. Degenerate fallback for anonymous URL pushes
#         where the hook cannot determine a destination remote.
#
#   * tip-only mode (no second arg):
#         inspect only <subject_sha>^..<subject_sha>. Preserves
#         every existing manual invocation pattern
#         (`gate-push.sh <commit>`).
#
# Implementation primitive: per-commit `git diff-tree --check --root -m`.
#
#   --check    Apply Git's documented whitespace + conflict-marker policy
#              (trailing whitespace, space-before-tab, <<<<<<< / >>>>>>>
#              markers, plus anything configured via core.whitespace).
#              We do not reimplement Git's semantics in awk; we call Git.
#
#   --root     Include the root commit in the inspection set even when
#              there is no parent to diff against.
#
#   -m         For merge commits, diff against every parent. Without -m,
#              a merge commit's tree is compared only against one parent
#              (the first by default), so a conflict resolution that
#              introduced whitespace on the other side would be missed.
#              With -m, every parent gets its own diff-tree and every
#              dirty resolution is caught.
#
#   --no-commit-id -r   Recurse into trees, omit the commit-id header so
#              each line of output corresponds to one file in one diff.
#
# We deliberately do NOT use `git diff --check <A> <B>`. That primitive
# compares the *tree* state at B against the *tree* state at A, which
# is blind to whitespace that existed only in an intermediate commit
# (it never appears in the resulting tree if a later commit overwrites
# the file). The per-commit diff-tree primitive inspects every commit's
# contribution to the resulting tree, which is what "diff hygiene of
# the pushed series" actually means.
#
# We also deliberately do NOT use `git format-patch --stdout <range> |
# awk`. `format-patch` omits merge commits from its output (documented
# Git behavior), and an awk reimplementation of Git's whitespace policy
# is strictly weaker than `git diff --check`. Both defects are fixed
# by switching to per-commit `git diff-tree --check --root -m`.
#
# See ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION02 and
# ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION03.
case "$range_mode" in
    range)
        range_desc="pushed range $range_base_sha..$subject_sha"
        rev_list_args="$range_base_sha..$subject_sha"
        ;;
    new-branch)
        # New branch against a remote that may already hold the
        # branch's ancestors. The set of commits newly asked of the
        # remote is reachable(subject) MINUS reachable(<remote>'s
        # remote-tracking refs). Implemented as
        # `git rev-list <subj> --not --remotes=<remote>`.
        #
        # If no remote-tracking refs exist for <remote>, --not
        # resolves to nothing and rev-list returns the full
        # reachable set, which is the previous (CORRECTION02)
        # behavior. We document this fallback but do not silently
        # widen the inspection set.
        #
        # Caveat: remote-tracking refs can be stale. That is a
        # client-side limitation; Git provides only the old OID
        # for refs being updated, not a complete remote
        # reachability graph.
        range_desc="new branch (commits not in remote $new_branch_remote)"
        rev_list_args="$subject_sha --not --remotes=$new_branch_remote"
        ;;
    root-range)
        # Degenerate fallback: every commit reachable from
        # <subject_sha> down to the root. Used when the hook has
        # no destination remote available (e.g. anonymous URL
        # push). The CORRECTION02 default for new branches; kept
        # as an explicit, opt-in fallback in CORRECTION03.
        range_desc="full history reachable from $subject_sha (root-range fallback)"
        rev_list_args="--reverse $subject_sha"
        ;;
    tip)
        range_desc="subject commit (tip-only)"
        rev_list_args="$subject_sha -n1"
        ;;
esac

# Capture every commit in the range (or root-range, or single tip).
# The shell expands $rev_list_args unquoted (as a list of words) so we
# don't need bash arrays; the entire rest of the script stays POSIX.
commit_list=$(cd "$tmp" && git rev-list $rev_list_args)

# Echo the resolved range so the engineer running the gate can see
# what was actually inspected (matters most for new-branch mode where
# the inspection set can be much smaller than the full history).
echo "POLYC_GATE_RANGE_MODE=$range_mode"
echo "POLYC_GATE_RANGE_DESC=$range_desc"

# Per-commit hygiene scan. For each commit, diff-tree --check emits
# zero or more "<path>: <reason>." lines if Git's whitespace policy is
# violated, and exits non-zero. We prefix each line with the commit
# short SHA so failures are traceable back to a specific commit.
diff_check_failed=0
diff_check_output=""
while IFS= read -r commit; do
    [ -z "$commit" ] && continue
    short=$(printf '%s' "$commit" | cut -c1-12)
    # Capture both stdout and exit status. The 2>&1 merges stderr so
    # Git's diagnostic lines ("warning: CRLF will be replaced by LF")
    # are surfaced.
    if ! single_commit_output=$(cd "$tmp" && git diff-tree \
            --check \
            --root \
            -m \
            --no-commit-id \
            -r \
            "$commit" 2>&1); then
        # Build a header showing which commit caused the failure and
        # the mode context, then concatenate Git's per-file output.
        # When --root is in effect for the root commit, Git emits
        # nothing on stderr in normal cases; the file list comes on
        # stdout. When -m is in effect for a merge commit, Git emits
        # one diff-tree block per parent; --check applies to each.
        diff_check_output="${diff_check_output}commit ${short} (${range_mode}):
${single_commit_output}
"
        diff_check_failed=1
    fi
done << EOF
$commit_list
EOF

if [ "$diff_check_failed" -ne 0 ]; then
    echo "CHECK=diff-check STATUS=FAIL"
    echo "REASON=${range_desc} introduced whitespace or conflict markers:"
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
