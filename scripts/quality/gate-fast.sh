#!/bin/sh
# scripts/quality/gate-fast.sh
#
# PolyC local fast quality gate.
#
# Question: is the proposed commit mechanically sane enough to create?
#
# This gate MUST stay sub-second to a few seconds and MUST NOT
# perform a compiler build. A wider correctness check lives in
# gate-push.sh.
#
# Exit code:
#   0  all checks PASS
#   non-zero on any FAIL or HALT
#
# Required environment: git.
# Network: not required.

set -eu

# --- locate repository root -------------------------------------------------

# cd to the directory containing this script, then resolve the repo root
# so the script can be invoked from anywhere.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

if [ ! -d .git ]; then
    echo "POLYC_GATE=fast"
    echo "STATUS=ERROR"
    echo "REASON=not inside a git repository ($REPO_ROOT)"
    exit 2
fi

# --- helper -----------------------------------------------------------------

fail() {
    echo "POLYC_GATE=fast"
    echo "CHECK=$1 STATUS=FAIL"
    if [ -n "${2-}" ]; then
        echo "REASON=$2"
    fi
    echo "VERDICT=FAIL"
    exit 1
}

pass() {
    echo "CHECK=$1 STATUS=PASS"
}

echo "POLYC_GATE=fast"

# --- GFAST-1: staged diff hygiene ------------------------------------------

if ! diff_output=$(git diff --cached --check 2>&1); then
    echo "CHECK=diff-check STATUS=FAIL"
    printf '%s\n' "$diff_output"
    echo "VERDICT=FAIL"
    exit 1
fi
pass diff-check

# --- GFAST-2: shell syntax for staged shell scripts ------------------------

# Collect staged files that look like shell scripts and live under
# scripts/ or .githooks/. We use git's porcelain to find the staged
# paths so we cover additions, modifications, and renames.

staged_paths=$(git diff --cached --name-only --diff-filter=ACMR)

shell_files=""
if [ -n "$staged_paths" ]; then
    for f in $staged_paths; do
        case "$f" in
            scripts/*.sh|scripts/*/*.sh|.githooks/*)
                # Only files that exist in the index for syntax check
                if git cat-file -e ":$f" 2>/dev/null; then
                    shell_files="$shell_files $f"
                fi
                ;;
        esac
    done
fi

# Always syntax-check the hooks themselves when present, even if not staged,
# so a broken pre-push that would never run is caught at commit time on
# touched files. (We still only check staged scripts to keep fast gate fast.)
shell_check_rc=0
if [ -n "$shell_files" ]; then
    for f in $shell_files; do
        if ! git show ":$f" | sh -n; then
            echo "CHECK=shell-syntax STATUS=FAIL"
            echo "REASON=$f has syntax errors"
            echo "VERDICT=FAIL"
            exit 1
        fi
    done
fi
pass shell-syntax

# --- GFAST-3: documentation structure invariants ---------------------------

# Required documents MUST exist in the staged index, not just on disk.
#
# Checking the worktree ([ -f "$required" ]) is a vacuous green for any
# commit that stages a deletion of one of these canonical documents
# while leaving an unstaged working-tree copy of the old content in
# place. The proposed commit would silently drop the document, but the
# gate would still PASS. We therefore validate presence via
# `git cat-file -e ":$path"`, which inspects the index object
# database — exactly what the proposed commit will produce when
# created.
#
# This invariant only inspects documents that the proposed commit is
# NOT itself adding. A commit whose entire purpose is to introduce a
# missing required document is allowed: in that case the staged index
# contains the new blob and the check passes naturally.
for required in \
    AGENTS.md \
    docs/CHARTER.md \
    docs/ROADMAP.md \
    docs/DESIGN-NOTES.md
do
    # Is this path staged for deletion?
    if printf '%s\n' "$staged_paths" | grep -qx "$required"; then
        # Path is staged for some change. If it's a deletion or rename,
        # the new index entry does not exist as a regular blob. Detect
        # this via diff-filter and pass only when something is added
        # back in the same commit.
        diff_filter=$(git diff --cached --name-status -- "$required" \
                      | awk 'NR==1 {print $1}')
        case "$diff_filter" in
            A|C|M|T) ;;
            *)  echo "CHECK=doc-invariants STATUS=FAIL"
                echo "REASON=required document $required is staged for $diff_filter (deletion/rename without re-introduction)"
                echo "VERDICT=FAIL"
                exit 1
                ;;
        esac
    fi

    # Index-level presence check: does the staged tree contain this
    # path as a regular blob? This catches the
    # "index-empty / worktree-restored" pathological state that
    # `[ -f "$required" ]` cannot.
    if ! git cat-file -e ":$required" 2>/dev/null; then
        echo "CHECK=doc-invariants STATUS=FAIL"
        echo "REASON=required document $required is missing from the staged index"
        echo "VERDICT=FAIL"
        exit 1
    fi
done

# If DESIGN-NOTES.md is staged or changed, verify its numbered
# `## N.` sections are monotonically increasing in numerical order.
# This is a cheap, narrow invariant — not a general Markdown parser.
design_notes_staged=0
if printf '%s\n' "$staged_paths" | grep -qx 'docs/DESIGN-NOTES.md'; then
    design_notes_staged=1
fi

if [ "$design_notes_staged" = "1" ]; then
    last=-1
    bad=0
    # Read from the index (staged content), not the worktree.
    git show ':docs/DESIGN-NOTES.md' | \
        awk '/^## [0-9]+\.[[:space:]]/ {
            n = $2 + 0
            if (n <= last) { print NR": "$0; bad = 1 }
            last = n
        }
        END { exit bad }' || {
            echo "CHECK=doc-invariants STATUS=FAIL"
            echo "REASON=docs/DESIGN-NOTES.md has non-monotonic '## N.' section ordering"
            echo "VERDICT=FAIL"
            exit 1
        }
fi
pass doc-invariants

# --- GFAST-4: large staged-file guard --------------------------------------

# Refuse newly staged files larger than 5 MiB. Use index object size.
LARGE_THRESHOLD_BYTES=$((5 * 1024 * 1024))

large_culprit=""
if [ -n "$staged_paths" ]; then
    for f in $staged_paths; do
        # Only consider files that exist in the index.
        if ! git cat-file -e ":$f" 2>/dev/null; then
            continue
        fi
        # Use the staged blob size; -A filters for added files only is
        # too narrow — a renamed file with a large new blob is also a
        # risk. Use diff-filter=ACMR and treat each as a candidate.
        case "$f" in
            # Allowed evidence paths are excluded. None exist today.
            # Future ACTs may extend this list deliberately.
            *) ;;
        esac
        size=$(git cat-file -s ":$f" 2>/dev/null || echo 0)
        if [ "$size" -gt "$LARGE_THRESHOLD_BYTES" ]; then
            large_culprit="$f ($size bytes)"
            break
        fi
    done
fi

if [ -n "$large_culprit" ]; then
    echo "CHECK=large-file-guard STATUS=FAIL"
    echo "REASON=newly staged file exceeds 5MiB: $large_culprit"
    echo "VERDICT=FAIL"
    exit 1
fi
pass large-file-guard

# --- GFAST-5: explicit no-build witness ------------------------------------

echo "BUILD_RUN=NO"

# --- GFAST-6: factory closure-status reconciliation ------------------------
#
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION: the new hard normal-path
# gate. Runs the exact-token factory closure-status checker, which
# compares the ## Status block of every managed ACT against the
# VERDICT block of its paired HANDOFF on exact-token grounds (no
# lifecycle-class lossy normalization).
#
# The check is unconditional: it is run on every commit regardless
# of which files are staged, because the closure-status reconciliation
# defect is orthogonal to the staged diff.
#
# Exit code 0 -> pass.
# Exit code 1 -> fail; we exit 1 with CHECK=factory-closure-status.
# Exit code 2 -> manifest missing; we treat as hard fail.

if factory_closure_output=$(sh scripts/quality/factory-closure-status-check.sh 2>&1); then
    printf '%s\n' "$factory_closure_output" | grep -E '^(STATUS|POLYC_GATE|VERDICT|PAIR_OK|PAIR_FAIL|EXACT_VERDICT_MISMATCHES|MANIFEST_ROWS|MISSING_HANDOFF_FILES|MALFORMED_ACT_STATUS|MALFORMED_HANDOFF_VERDICT)=' || true
    pass factory-closure-status
else
    echo "CHECK=factory-closure-status STATUS=FAIL"
    printf '%s\n' "$factory_closure_output"
    echo "REASON=scripts/quality/factory-closure-status-check.sh exited non-zero"
    echo "VERDICT=FAIL"
    exit 1
fi

echo "VERDICT=PASS"
exit 0
