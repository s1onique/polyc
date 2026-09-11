#!/bin/bash
# scripts/quality/capture-red2-neutral-ir.sh
#
# Capture the post-basic-optimisation neutral IR for every
# RED-2 fixture into the c3/ evidence tree.
#
# This script is a documentation aid. It writes into the
# c3/ evidence tree, so it is NOT intended for ordinary
# regression. It is documented here so the C3 frozen
# artefact is reproducible from the source tree.
#
# Usage:
#   HCC_INSTALL_DIR=<path-with-tos.HH> \
#     sh c3/capture-neutral-ir.sh
#
# Required environment:
#   HCC_INSTALL_DIR  - install dir containing include/tos.HH
#                      and lib/libtos.{a,dylib}. Optional if hcc
#                      is installed system-wide.
#
# Required tools: a pre-built ./hcc.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
cd "$REPO_ROOT"

if [ ! -x ./hcc ]; then
    echo "ERROR: ./hcc not found at $REPO_ROOT/hcc" >&2
    exit 2
fi

HCC_INSTALL_ARG=""
if [ -n "${HCC_INSTALL_DIR:-}" ]; then
    HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
fi

EVID_DIR="$REPO_ROOT/evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c3"
mkdir -p "$EVID_DIR/fixture-diamond"

# Five existing fixtures under src/tests/llvm-byte-memory01/
declare -a FIXTURES=(
    "nc_p01_predecessor_paths:fixture-probepath"
    "pos_b0_compare_digit:fixture-pos_b0_compare_digit"
    "i64_collapse_probe:fixture-i64_collapse_probe"
    "single_cond_probe:fixture-single_cond_probe"
    "safe_fwd_single_pred:fixture-safe_fwd_single_pred"
)

for entry in "${FIXTURES[@]}"; do
    src="${entry%%:*}"
    dst="${entry##*:}"
    mkdir -p "$EVID_DIR/$dst"
    ./hcc $HCC_INSTALL_ARG --dump-ir \
        "src/tests/llvm-byte-memory01/$src.HC" \
        > "$EVID_DIR/$dst/pre-ir.txt" 2>&1
    echo "captured $src -> $dst/pre-ir.txt"
done

# Diamond fixture is a new source committed under c3/.
# It is NOT promoted into src/tests/ because C3 is RED-only
# (F7). See c3/red-p02-def-use-tables.txt §4 RESIDUE.
./hcc $HCC_INSTALL_ARG --dump-ir \
    "$EVID_DIR/fixture-diamond/Diamond.HC" \
    > "$EVID_DIR/fixture-diamond/pre-ir.txt" 2>&1
echo "captured Diamond -> fixture-diamond/pre-ir.txt"

echo "DONE"
