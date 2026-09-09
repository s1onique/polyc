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

# Run the production pre-push hook against a fresh synthetic
# repo with a stub gate-push.sh and the given stdin line.
# Compares the hook's exit code against expect_rc and updates
# PASS_COUNT / FAIL_COUNT.
run_hook() {
    name="$1"; stdin_line="$2"; expect_rc="$3"
    repo="$TMPROOT/$name"
    rm -rf "$repo"
    mkdir -p "$repo"
    cd "$repo"
    git init -q -b main .
    git -c core.hooksPath=/dev/null config user.email "append-only-test@polyc.local"
    git -c core.hooksPath=/dev/null config user.name "polyc-append-only-test"
    # Stub gate-push.sh: return 0 unconditionally so the only
    # way the hook can fail is the append-only check.
    mkdir -p scripts/quality
    printf '#!/bin/sh\nexit 0\n' > scripts/quality/gate-push.sh
    chmod +x scripts/quality/gate-push.sh
    # A harmless seed commit (under the stub hooks path).
    echo s > s
    git add s
    git -c core.hooksPath=/dev/null commit -qm s
    # Plumb the production pre-push hook into the synthetic repo.
    git config core.hooksPath "$REPO_ROOT/.githooks"
    # Run the hook with the test stdin.
    out=$(printf '%s\n' "$stdin_line" | sh "$HOOK" origin "$repo" 2>&1)
    rc=$?
    if [ "$rc" = "$expect_rc" ]; then
        echo "  PASS  $name  rc=$rc"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  $name  rc=$rc expected=$expect_rc  out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
    cd "$TMPROOT"
}

# Build a linear synthetic repo with N commits and emit the
# SHAs of HEAD and HEAD^ on stdout. Used by NC1, NC4, NC6, NC7.
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
    git rev-parse HEAD^
    cd "$TMPROOT"
}

echo "POLYC_GATE=factory-append-only-tests"

# ---- NC1: normal FF main push -> PASS ------------------------------
set -- $(build_linear_repo nc1 2)
HEAD="$1"; PARENT="$2"
run_hook NC1 "refs/heads/main $HEAD refs/heads/main $PARENT" 0

# ---- NC2: non-FF main update -> REJECT -----------------------------
# Build a repo with two diverging children of the same parent.
nc2_repo="$TMPROOT/nc2-raw"
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
run_hook NC2 "refs/heads/main $B_TIP refs/heads/main $A_TIP" 1
cd "$TMPROOT"

# ---- NC3: force-equivalent non-FF transition -> REJECT ------------
# Same as NC2: the hook has no view of the user's command-line
# flags, so the simulated stdin is the same shape. The hook
# MUST still refuse because the result is a non-FF transition.
run_hook NC3 "refs/heads/main $B_TIP refs/heads/main $PARENT_COMMIT" 1

# ---- NC4: delete main -> REJECT ------------------------------------
# Use nc4 with at least one child so HEAD is not the seed.
# We only need HEAD; the local_sha is the only thing that
# matters for the delete check.
set -- $(build_linear_repo nc4 2)
HEAD="$1"
run_hook NC4 "refs/heads/main $HEAD refs/heads/main $ZERO_SHA" 1

# ---- NC5: refs/replace present -> REJECT ---------------------------
# Populate `refs/replace` so the hook's first-line check fires.
nc5_repo="$TMPROOT/nc5"
rm -rf "$nc5_repo"
mkdir -p "$nc5_repo"
cd "$nc5_repo"
git init -q -b main .
git -c core.hooksPath=/dev/null config user.email "append-only-test@polyc.local"
git -c core.hooksPath=/dev/null config user.name "polyc-append-only-test"
mkdir -p scripts/quality
printf '#!/bin/sh\nexit 0\n' > scripts/quality/gate-push.sh
chmod +x scripts/quality/gate-push.sh
echo s > s
git add s
git -c core.hooksPath=/dev/null commit -qm seed
git config core.hooksPath "$REPO_ROOT/.githooks"
SEED=$(git rev-parse HEAD)
git replace "$SEED" "$SEED"
# Capture hook output and exit code without `set -e`
# firing on the expected non-zero return.
set +e
out=$(printf 'refs/heads/main %s refs/heads/main %s\n' "$SEED" "$SEED" \
        | sh "$HOOK" origin "$nc5_repo" 2>&1)
rc=$?
git replace -d "$SEED" 2>/dev/null
set -e
if [ "$rc" != "0" ]; then
    echo "  PASS  NC5  rc=$rc"
    PASS_COUNT=$((PASS_COUNT+1))
else
    echo "  FAIL  NC5  rc=0 expected non-zero  out=$out"
    FAIL_COUNT=$((FAIL_COUNT+1))
fi
cd "$TMPROOT"

# ---- NC6: new non-main branch -> PASS ------------------------------
# Build a linear repo, then simulate a push that creates a new
# topic ref pointing at HEAD. Remote ref is all-zeros.
set -- $(build_linear_repo nc6 1)
HEAD="$1"
run_hook NC6 "refs/heads/feature $HEAD refs/heads/feature $ZERO_SHA" 0

# ---- NC7: FF non-main branch -> PASS -------------------------------
# Same linear repo, advance the topic ref by one FF step. Need
# a second repo with two children so we have HEAD and HEAD^.
set -- $(build_linear_repo nc7 2)
HEAD="$1"; PARENT="$2"
run_hook NC7 "refs/heads/feature $HEAD refs/heads/feature $PARENT" 0

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



