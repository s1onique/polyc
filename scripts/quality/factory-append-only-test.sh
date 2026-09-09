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
# Binding matrix (per ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01
# and ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01):
#
#   NC1  normal FF main push                       PASS
#   NC2  non-FF main update                        REJECT
#   NC3  force-equivalent non-FF transition        REJECT
#   NC4  create main when remote has none          PASS
#        (was: encoded "delete main" with the wrong
#         protocol shape; per CORRECTION01 the real
#         delete shape is NC8)
#   NC5  refs/replace present                      REJECT
#   NC6  new non-main branch                       PASS
#   NC7  FF non-main branch                        PASS
#   NC8  real delete of main (CORRECTION01)        REJECT
#        local_ref=(delete), local_sha=ZERO,
#        remote_ref=refs/heads/main, remote_sha=<tip>
#   NC9  feature -> main, non-FF (CORRECTION01)    REJECT
#        local_ref=refs/heads/feature,
#        remote_ref=refs/heads/main
#   NC10 HEAD -> main, non-FF (CORRECTION01)       REJECT
#        local_ref=HEAD (literal),
#        remote_ref=refs/heads/main
#   NC11 feature -> main, FF (CORRECTION01)        PASS
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

# Build a synthetic repo with a single seed commit, then a
# `feature` branch with one extra commit on top of seed, and
# a `main` branch with a DIFFERENT extra commit on top of
# seed. Emits (in order, on stdout):
#
#   <seed> <feature_tip> <main_tip>
#
# feature_tip and main_tip are siblings (neither is an
# ancestor of the other); this lets NC9 / NC10 build a
# non-fast-forward `feature -> main` transition, and NC11
# build a fast-forward one by using seed as the remote tip.
build_fork_repo() {
    name="$1"
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
    git -c core.hooksPath=/dev/null commit -qm "seed"
    seed=$(git rev-parse HEAD)
    git checkout -q -b feature
    echo f > f
    git add f
    git -c core.hooksPath=/dev/null commit -qm "feature-step"
    feature_tip=$(git rev-parse HEAD)
    git checkout -q main
    echo m > m
    git add m
    git -c core.hooksPath=/dev/null commit -qm "main-step"
    main_tip=$(git rev-parse HEAD)
    git config core.hooksPath "$REPO_ROOT/.githooks"
    printf '%s %s %s\n' "$seed" "$feature_tip" "$main_tip"
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

# ---- NC4: create main when remote has none -> PASS -----------------
# Build a linear repo with 3 commits; simulate the push
# shape that creates a brand-new `main` (no existing remote
# tip). Per githooks(5), this is `remote_sha == ZERO_SHA`,
# which is a legitimate push shape -- NOT a deletion. The
# real delete shape is NC8 below. The hook MUST accept
# this; the previous ACT's NC4 named this shape "delete
# main" but the encoding was the create shape; the parent
# NC4's rc=1 was an accidental consequence of the
# implementation-defined `merge-base --is-ancestor ZERO X`
# behaviour. CORRECTION01 renames this test to reflect the
# shape it actually exercises.
set -- $(build_linear_repo nc4 2)
HEAD="$1"
run_hook NC4 refs/heads/main "$HEAD" refs/heads/main "$ZERO_SHA" 0

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

# ---- NC8: real delete of main -> REJECT ----------------------------
# Per githooks(5), a ref deletion is encoded as
# (delete) ZERO refs/heads/main <remote-tip>. The hook MUST
# refuse. (Note: NC4's encoding in the parent ACT was the
# "create main" shape, NOT the delete shape; that test was
# mis-named.)
set -- $(build_linear_repo nc8 2)
HEAD="$1"
run_hook NC8 "(delete)" "$ZERO_SHA" refs/heads/main "$HEAD" 1

# ---- NC9: feature -> main, non-FF -> REJECT ------------------------
# Per githooks(5), `git push origin feature:main` is encoded
# as `refs/heads/feature <NEW> refs/heads/main <OLD>`.
# When NEW is not a descendant of OLD (diverging branches),
# this is a non-fast-forward rewrite of main. The hook MUST
# refuse.
set -- $(build_fork_repo nc9)
SEED="$1"; FTIP="$2"; MTIP="$3"
run_hook NC9 refs/heads/feature "$FTIP" refs/heads/main "$MTIP" 1

# ---- NC10: HEAD -> main, non-FF -> REJECT --------------------------
# Per githooks(5), `git push origin HEAD:refs/heads/main`
# is encoded with `local_ref = HEAD` (literal). Same
# forbidden outcome as NC9; different source-name shape.
set -- $(build_fork_repo nc10)
SEED="$1"; FTIP="$2"; MTIP="$3"
run_hook NC10 "HEAD" "$FTIP" refs/heads/main "$MTIP" 1

# ---- NC11: feature -> main, FF -> PASS -----------------------------
# Positive control: when NEW IS a descendant of OLD on the
# remote main (e.g. remote main is at `seed`, feature_tip
# sits on top of seed), the rewrite IS a fast-forward and
# MUST be accepted.
set -- $(build_fork_repo nc11)
SEED="$1"; FTIP="$2"; MTIP="$3"
run_hook NC11 refs/heads/feature "$FTIP" refs/heads/main "$SEED" 0

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
