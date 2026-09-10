#!/bin/sh
# scripts/quality/derive-case-b-opcode-set.sh
#
# Derive CASE_B_OPCODE_SET from the six RED-2 fixtures' neutral IR.
# Frozen at C3. See
# evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c3/red-p02-def-use-tables.txt
#
# This script is a documentation aid for the RED-2 frozen artefact.
# It is NOT executed by ordinary regression (no durable evidence
# produced; only stdout).

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)

EVID_DIR="$REPO_ROOT/evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c3"

if [ ! -d "$EVID_DIR/fixture-probepath" ]; then
    echo "ERROR: $EVID_DIR/fixture-* not present" >&2
    exit 2
fi

echo "===== Raw observation: every '... %lN i64 local' instruction ====="
awk '/    [a-z]+ +%l[0-9]+ i64 local/ {print FILENAME": "$0}' \
    "$EVID_DIR"/fixture-*/pre-ir.txt

echo
echo "===== Unique opcodes (post awk | sort -u) ====="
awk '/    [a-z]+ +%l[0-9]+ i64 local/ {print $1}' \
    "$EVID_DIR"/fixture-*/pre-ir.txt | sort -u

echo
echo "===== Removing terminator + case-(a) store ====="
awk '/    [a-z]+ +%l[0-9]+ i64 local/ {print $1}' \
    "$EVID_DIR"/fixture-*/pre-ir.txt | sort -u | \
    grep -v -E '^(ret|store)$'

echo
echo "FROZEN CASE_B_OPCODE_SET = {iadd, isub}"
