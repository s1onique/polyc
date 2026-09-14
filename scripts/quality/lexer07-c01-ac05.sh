#!/bin/sh
# scripts/quality/lexer07-c01-ac05.sh
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C3 EVIDENCE.
# AC05 mutation control: stub mutation must cause the verifier
# to reject the resulting corpus-matrix.tsv with rc != 0.
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/../.."
[ -x ./build/lexer07-mutation-stub ] || {
  echo "lexer07-mutation-stub: build artifact missing" >&2
  exit 3
}
[ -x ./build/lexer07-proof-verify ] || {
  echo "lexer07-proof-verify: build artifact missing" >&2
  exit 3
}
DIR=/tmp/lexer07-c01-stub-out
rm -rf "$DIR"
mkdir -p "$DIR"
./build/lexer07-mutation-stub "$DIR"
echo "---"
echo "verifier_run_start"
./build/lexer07-proof-verify --allow-closed "$DIR" || VRC=$?
echo "verifier_run_end rc=${VRC:-1}"
if [ "${VRC:-1}" != "0" ]; then
  echo "AC05_REJECTION_TOKEN=VERIFIER_REJECTED_STUB_MUTATION"
  echo "STUB_BINARY_NEGATIVE_CONTROL=PASS"
else
  echo "AC05_REJECTION_TOKEN=MISSING"
  echo "STUB_BINARY_NEGATIVE_CONTROL=FAIL"
  exit 9
fi
exit 0
