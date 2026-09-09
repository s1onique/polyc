#!/bin/sh
# scripts/quality/factory-append-only-test.sh
#
# ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01
#
# Regression suite for the append-only Git-history invariant
# enforced by `.githooks/pre-push`. Every negative control
# exercises a shape of rewrite that the hook MUST refuse; every
# positive control exercises a shape the hook MUST accept.
#
# All tests run against synthetic repos in temporary
# directories. No production state is touched.
#
# Binding matrix (per ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01):
#
#   NC1  normal FF main push                       PASS
#   NC2  non-FF main update                        REJECT
#   NC3  force-equivalent non-FF transition        REJECT
#   NC4  delete main                               REJECT
#   NC5  refs/replace present                      REJECT
#   NC6  new non-main branch                       PASS
#   NC7  FF non-main branch                        PASS
#
# The hook enforces graph properties of the proposed ref
# transition, NOT a blacklist of `git push` command-line
# arguments. NC3 deliberately omits any `--force` flag on the
# simulated input -- the hook has no way to see command-line
# flags, and it should not need to.
#
# The synthetic repos that exercise NC1..NC7 do NOT carry the
# production gate-push.sh script, so the hook's downstream
# `gate-push.sh` invocation MUST short-circuit on the
# append-only check before reaching it. We do that by giving
# the synthetic repos a stub `scripts/quality/gate-push.sh`
# that returns 0; that way, the only way the hook can return
# non-zero is the append-only check itself.
#
# Usage:
#   sh scripts/quality/factory-append-only-test.sh
#
# Output (rc=0):
#   STATUS=PASS  PASS=<n>  FAIL=<n>
# Output (rc=1):
#   STATUS=FAIL  PASS=<n>  FAIL=<n>
#
# Network: not required.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
HOOK="$REPO_ROOT/.githooks/pre-push"

if [ ! -x "$HOOK" ]; then
    echo "STATUS=ERROR"
    echo "REASON=hook not executable: $HOOK"
    exit 2
fi

PASS_COUNT=0
FAIL_COUNT=0

TMPROOT=$(mktemp -d -t polyc-append-only.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

# Zero-SHA sentinel used by Git for ref deletion.
ZERO_SHA=0000000000000000000000000000000000000000

# Run the production pre-push hook against an existing
# synthetic repo at $TMPROOT/$name using the given stdin line.
# Compares the hook's exit code against expect_rc and updates
# PASS_COUNT / FAIL_COUNT.
#
# Args:
#   name       -- label for the test
#   local_ref  -- full ref name (e.g. refs/heads/main)
#   local_sha  -- 40-char SHA that must exist in the synthetic repo
#   remote_ref -- full ref name (e.g. refs/heads/main)
#   remote_sha -- 40-char SHA (or zero sentinel) that must exist
#                 in the synthetic repo's object store
#   expect_rc  -- expected exit code from the hook
run_hook() {
    name="$1"; local_ref="$2"; local_sha="$3"
    remote_ref="$4"; remote_sha="$5"; expect_rc="$6"
    fallback="${7:-}"
    stdin_line="$local_ref $local_sha $remote_ref $remote_sha"
    run_hook_at "$name" "$stdin_line" "$expect_rc" "$fallback"
}

# Build a linear synthetic repo with N+1 commits (one seed plus
# N steps) and emit HEAD and HEAD^ on stdout. Repo is left at
# $TMPROOT/$name with stub gate-push.sh installed and the
# production pre-push hook plumbed into core.hooksPath.
build_linear_repo() {
    name="$1"; n="$2"
    repo="$TMPROOT/$name"
    rm -rf "$repo"
    mkdir -p "$repo"
    cd "$repo"
    git init -q -b main .
    git -c core.hooksPath=/dev/null config user.email "append-only-test@polyc.local"
    git -c core.hooksPath=/dev/null config user.name "polyc-append-only-test"
    mkdir -p scripts/quality
    printf '#!/bin/sh\nexit 0\n' > scripts/quality/gate-push.sh
    chmod +x scripts/quality/gate-push.sh
    echo s > s
    git add s
    i=0
    while [ "$i" -le "$n" ]; do
        if [ "$i" = "0" ]; then
            git -c core.hooksPath=/dev/null commit -qm "seed"
        else
            echo "$i" > "$i.txt"
            git add "$i.txt"
            git -c core.hooksPath=/dev/null commit -qm "step-$i"
        fi
        i=$((i+1))
    done
    git rev-parse HEAD
    # Only emit HEAD^ if it exists; otherwise emit the empty
    # string so callers don't trip on "fatal: ambiguous argument".
    if git rev-parse --verify HEAD^ >/dev/null 2>&1; then
        git rev-parse HEAD^
    fi
    # Plumb the production hook BEFORE returning so run_hook
    # finds it already configured.
    git config core.hooksPath "$REPO_ROOT/.githooks"
    cd "$TMPROOT"
}

# Run the production pre-push hook against an existing
# synthetic repo at $TMPROOT/$name using the given stdin line.
# Compares the hook's exit code against expect_rc and updates
# PASS_COUNT / FAIL_COUNT. If $TMPROOT/$name does not exist,
# $TMPROOT/$fallback_name is used instead (for cases where
# multiple negative controls share the same synthetic repo,
# e.g. NC2 and NC3).
run_hook_at() {
    name="$1"; stdin_line="$2"; expect_rc="$3"
    fallback_name="${4:-}"
    repo="$TMPROOT/$name"
    if [ ! -d "$repo" ] && [ -n "$fallback_name" ] && [ -d "$TMPROOT/$fallback_name" ]; then
        repo="$TMPROOT/$fallback_name"
    fi
    set +e
    # Run the hook from inside the synthetic repo so that
    # `git rev-parse --show-toplevel` resolves to it.
    cd "$repo"
    out=$(printf '%s\n' "$stdin_line" | sh "$HOOK" origin "$repo" 2>&1)
    rc=$?
    cd "$TMPROOT"
    set -e
    if [ "$rc" = "$expect_rc" ]; then
        echo "  PASS  $name  rc=$rc"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  $name  rc=$rc expected=$expect_rc  out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
}

echo "POLYC_GATE=factory-append-only-tests"

# ---- NC1: normal FF main push -> PASS ------------------------------
# Build a linear repo with 3 commits (seed + 2 steps). Use HEAD
# as local, HEAD^ as remote -- that's a one-step fast-forward.
set -- $(build_linear_repo nc1 2)
HEAD="$1"; PARENT="$2"
run_hook NC1 refs/heads/main "$HEAD" refs/heads/main "$PARENT" 0

# ---- NC2: non-FF main update -> REJECT -----------------------------
# Build a repo with two diverging children of the same parent.
nc2_repo="$TMPROOT/nc2"
rm -rf "$nc2_repo"
mkdir -p "$nc2_repo"
cd "$nc2_repo"
git init -q -b main .
git -c core.hooksPath=/dev/null config user.email "append-only-test@polyc.local"
git -c core.hooksPath=/dev/null config user.name "polyc-append-only-test"
mkdir -p scripts/quality
printf '#!/bin/sh\nexit 0\n' > scripts/quality/gate-push.sh
chmod +x scripts/quality/gate-push.sh
echo s > s
git add s
git -c core.hooksPath=/dev/null commit -qm seed
git checkout -q -b branch-a
echo a > a
git add a
git -c core.hooksPath=/dev/null commit -qm a
A_TIP=$(git rev-parse HEAD)
git checkout -q main
echo b > b
git add b
git -c core.hooksPath=/dev/null commit -qm b
B_TIP=$(git rev-parse HEAD)
PARENT_COMMIT=$(git rev-parse main^)
git config core.hooksPath "$REPO_ROOT/.githooks"
# Pretend remote main is at A_TIP; local main advances to B_TIP
# (a sibling of A_TIP, NOT a descendant). Non-FF.
run_hook NC2 refs/heads/main "$B_TIP" refs/heads/main "$A_TIP" 1
cd "$TMPROOT"

# ---- NC3: force-equivalent non-FF transition -> REJECT ------------
# Same synthetic repo as NC2, but use a totally unrelated commit
# as remote_sha so the transition is unambiguously non-FF. The
# hook has no view of `--force`; only the resulting transition
# matters. Build a third, unrelated commit in a separate repo
# and present it as the remote main.
unrelated_repo="$TMPROOT/unrelated"
rm -rf "$unrelated_repo"
mkdir -p "$unrelated_repo"
cd "$unrelated_repo"
git init -q -b main .
git -c core.hooksPath=/dev/null config user.email "append-only-test@polyc.local"
git -c core.hooksPath=/dev/null config user.name "polyc-append-only-test"
echo u > u
git add u
git -c core.hooksPath=/dev/null commit -qm unrelated
UNRELATED=$(git rev-parse HEAD)
cd "$TMPROOT"
run_hook NC3 refs/heads/main "$B_TIP" refs/heads/main "$UNRELATED" 1 nc2

# ---- NC4: delete main -> REJECT ------------------------------------
# Build a linear repo with 3 commits; simulate a push whose
# remote_sha is the zero sentinel (delete).
set -- $(build_linear_repo nc4 2)
HEAD="$1"
run_hook NC4 refs/heads/main "$HEAD" refs/heads/main "$ZERO_SHA" 1

# ---- NC5: refs/replace present -> REJECT ---------------------------
# Build a single-commit repo, then populate refs/replace so the
# hook's first-line check fires before any ref is processed.
set -- $(build_linear_repo nc5 0)
SEED="$1"
cd "$TMPROOT/nc5"
git replace "$SEED" "$SEED"
cd "$TMPROOT"
run_hook NC5 refs/heads/main "$SEED" refs/heads/main "$SEED" 1
# Clean up the replace ref so the trap's rm -rf is the only thing
# left touching this directory.
set +e
cd "$TMPROOT/nc5"
git replace -d "$SEED" 2>/dev/null
cd "$TMPROOT"
set -e

# ---- NC6: new non-main branch -> PASS ------------------------------
# Build a linear repo, then simulate a push that creates a new
# topic ref pointing at HEAD. Remote ref is all-zeros.
set -- $(build_linear_repo nc6 1)
HEAD="$1"
run_hook NC6 refs/heads/feature "$HEAD" refs/heads/feature "$ZERO_SHA" 0

# ---- NC7: FF non-main branch -> PASS -------------------------------
# Build a linear repo with 3 commits; advance the topic ref by
# one FF step (HEAD^ -> HEAD).
set -- $(build_linear_repo nc7 2)
HEAD="$1"; PARENT="$2"
run_hook NC7 refs/heads/feature "$HEAD" refs/heads/feature "$PARENT" 0

echo
echo "--- summary ---"
echo "PASS=$PASS_COUNT"
echo "FAIL=$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "STATUS=FAIL"
    exit 1
fi
echo "STATUS=PASS"
exit 0
