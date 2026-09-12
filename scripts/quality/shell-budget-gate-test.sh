#!/bin/sh
# scripts/quality/shell-budget-gate-test.sh
# Negative test packet N1..N10 for shell-budget-gate.sh.
# Uses a fresh worktree (git worktree add) so the gate sees a
# real repo. Each case mutates the manifest / tree and asserts
# the verifier's exit code.
set -u
GATE=scripts/quality/shell-budget-gate.sh
MAN=docs/factory/SHELL-BUDGET.tsv
BR=__budget_probe_$$
ROOT=$(git rev-parse --show-toplevel)
WT=$(mktemp -d)
git worktree prune 2>/dev/null || true
git branch -D "$BR" 2>/dev/null || true
git worktree add -b "$BR" "$WT" HEAD 2>&1
trap 'git worktree remove -f "$WT" 2>/dev/null; git branch -D "$BR" 2>/dev/null; rm -rf "$WT"' EXIT
cd "$WT"
cp "$ROOT/$MAN" "$MAN"
PASS=0; FAIL=0
run() {
    n=$1; expect=$2; setup=$3
    # Clean worktree to HEAD's manifest + tracked files
    rm -f scripts/quality/__probe6.sh scripts/quality/llvm-gep01-test.sh
    git checkout -q HEAD -- docs/factory/SHELL-BUDGET.tsv scripts/quality/ 2>/dev/null || true
    git reset -q HEAD scripts/quality/__probe6.sh 2>/dev/null || true
    cp "$ROOT/$MAN" "$MAN"
    eval "$setup"
    rc=$(sh "$GATE" "$MAN" HEAD >/dev/null 2>&1; echo $?)
    if [ "$rc" != "$expect" ]; then sh "$GATE" "$MAN" HEAD 2>&1 | head -8; fi
    if [ "$rc" = "$expect" ]; then echo "PASS  N$n"; PASS=$((PASS+1))
    else echo "FAIL  N$n expect=$expect got=$rc"; FAIL=$((FAIL+1)); fi
}
run 1 0 ":"
run 2 1 "sed -i 's|scripts/quality/llvm-intops01-test.sh.*|scripts/quality/llvm-intops01-test.sh\t231\t231\tGRANDFATHERED\tTEST\tMEDIUM\tX|' $MAN"
run 3 1 "sed -i 's|scripts/quality/llvm-intops01-test.sh\t230\t230|scripts/quality/llvm-intops01-test.sh\t230\t231|' $MAN"
run 4 0 "head -n 229 scripts/quality/llvm-intops01-test.sh > scripts/quality/llvm-intops01-test.sh.new && mv scripts/quality/llvm-intops01-test.sh.new scripts/quality/llvm-intops01-test.sh; sed -i 's|scripts/quality/llvm-intops01-test.sh\t230\t230|scripts/quality/llvm-intops01-test.sh\t230\t229|' $MAN"
run 5 1 "echo '#!/bin/sh' > scripts/quality/llvm-gep01-test.sh && echo ': stub' >> scripts/quality/llvm-gep01-test.sh; git add -A scripts/quality/llvm-gep01-test.sh"
run 6 1 "f=scripts/quality/__probe6.sh; echo '#!/bin/sh' > \$f; for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19; do echo '# pad' >> \$f; done; git add -N \$f"
run 8 1 "f=scripts/quality/inventory.sh; { head -c 1200 \$f; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do echo '# pad'; done; } > \$f.new; mv \$f.new \$f"
run 9 1 "rm -f scripts/quality/llvm-intops01-test.sh"
run 10 0 "rm -f scripts/quality/llvm-intops01-test.sh; sed -i 's|scripts/quality/llvm-intops01-test.sh.*|scripts/quality/llvm-intops01-test.sh\t0\t0\tMIGRATED\tTEST\tSKIP\tX|' $MAN"
echo "---"; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]
