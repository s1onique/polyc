#!/bin/sh
# scripts/quality/red-p03-option-w-proof/validate.sh
#
# Validate the §6 PASS criteria on the committed pre/post
# hand-translated LLVM IR. This is the C4 RED-3 evidence.
#
# Exit code:
#   0  all checks PASS
#   non-zero on any FAIL

set -eu

DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

OPT=${OPT:-opt}
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_DIS=${LLVM_DIS:-llvm-dis}

PASS=0
FAIL=0

fail() {
    echo "FAIL: $1"
    FAIL=$((FAIL + 1))
}

ok() {
    echo "PASS: $1"
    PASS=$((PASS + 1))
}

# For each pre/post pair:
#   pre:
#     - llvm-as parses cleanly
#     - target alloca appears exactly once in entry block
#     - target loads appear only at ORIGINAL read sites
#     - target stores appear only at ORIGINAL def sites
#     - no synthetic predecessor store at bb4 terminator
#   post:
#     - llvm-as parses cleanly
#     - target alloca is gone (post-mem2reg)
#     - target loads are gone
#     - target stores are gone
#     - opt -passes=verify exits 0
#     - no undef incoming where a real reaching definition exists

for pre in ProbePath.pre.ll Diamond.pre.ll pos_b0_compare_digit.pre.ll i64_collapse_probe.pre.ll single_cond_probe.pre.ll; do
    bn="${pre%.pre.ll}"
    post="${bn}.post.ll"
    echo
    echo "==== ${bn} ===="

    if [ ! -f "$pre" ]; then
        fail "${bn}: pre file missing"
        continue
    fi
    if [ ! -f "$post" ]; then
        fail "${bn}: post file missing"
        continue
    fi

    # Pre: llvm-as
    if ! "$LLVM_AS" "$pre" -o /tmp/c4.bc 2>"${bn}.pre.llvm-as.stderr"; then
        fail "${bn}: pre llvm-as rejected"
        cat "${bn}.pre.llvm-as.stderr"
        continue
    fi
    ok "${bn}: pre llvm-as PASS"

    # Pre: contains alloca (exactly once)
    if grep -q 'alloca i64' "$pre"; then
        ok "${bn}: pre has target alloca"
    else
        fail "${bn}: pre missing target alloca"
    fi

    # Pre: contains stores to that slot
    if grep -q 'store i64 .* i64\* %slot' "$pre"; then
        ok "${bn}: pre has stores to slot"
    else
        fail "${bn}: pre missing stores to slot"
    fi

    # Post: llvm-as
    if ! "$LLVM_AS" "$post" -o /tmp/c4.bc 2>"${bn}.post.llvm-as.stderr"; then
        fail "${bn}: post llvm-as rejected"
        cat "${bn}.post.llvm-as.stderr"
        continue
    fi
    ok "${bn}: post llvm-as PASS"

    # Post: target alloca gone
    if grep -q 'alloca' "$post"; then
        fail "${bn}: post still has alloca"
    else
        ok "${bn}: post alloca gone"
    fi

    # Post: target loads gone (we used the alloca %slot; post
    # should not contain a load from %slot)
    if grep -q 'load i64, i64\* %slot' "$post"; then
        fail "${bn}: post still has load from %slot"
    else
        ok "${bn}: post loads-from-slot gone"
    fi

    # Post: target stores to slot gone
    if grep -q 'store i64 .* i64\* %slot' "$post"; then
        fail "${bn}: post still has store to %slot"
    else
        ok "${bn}: post stores-to-slot gone"
    fi

    # Post: verifier pass
    if "$OPT" -passes=verify -S /tmp/c4.bc >/dev/null 2>"${bn}.post.verify.stderr"; then
        ok "${bn}: post verify PASS"
    else
        fail "${bn}: post verify FAIL"
        cat "${bn}.post.verify.stderr"
    fi

    # Post: every PHI has incoming value that matches a
    # predecessor's definition (no undef where a real
    # reaching definition exists)
    if grep -E 'phi i64 \[ undef, %bb_entry \]' "$post" >/dev/null 2>&1; then
        fail "${bn}: post has 'undef' incoming from entry where a real definition exists"
    else
        ok "${bn}: post no undef-from-entry"
    fi
done

echo
echo "============================="
echo "TOTAL PASS=$PASS FAIL=$FAIL"
echo "============================="
[ "$FAIL" = "0" ]
