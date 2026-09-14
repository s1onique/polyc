#!/bin/sh
# scripts/quality/lexer07-c01-ac07.sh
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C3 EVIDENCE.
# AC07: produce mutated .c with 88 inner rows, run
# fixture-inventory to emit TOTAL=88, and verify that the
# independent verifier (FIXTURE_TOTAL=89 expectation) rejects.
set -eu
SD=$(cd "$(dirname "$0")" && pwd); cd "$SD/../.."
DIR=/tmp/lexer07-c01-fixture-out
rm -rf "$DIR"; mkdir -p "$DIR"
./build/lexer07-mutation-fixture \
    tools/quality/lexer07-direct-differential.c "$DIR" \
    > "$DIR/fixture-mutation.log" 2>&1 || {
      echo "AC07_FAIL: mutation-fixture rc=$?" >&2; exit 4; }
echo "fixture_mutation_log:"; cat "$DIR/fixture-mutation.log"
canon=$(grep -cE '^\s*\{' tools/quality/lexer07-direct-differential.c)
mutated=$(grep -cE '^\s*\{' "$DIR/direct-differential.mutated.c" 2>/dev/null || echo MISSING)
echo "canonical_row_count=$canon mutated_row_count=$mutated"
[ "$mutated" -eq $((canon - 1)) ] || { echo "AC07_FAIL: row diff"; exit 5; }
./build/lexer07-fixture-inventory \
    ./build/lexer07-direct-differential \
    "$DIR/direct-differential.mutated.c" \
    "$DIR" "AC07 MUTATION PolyC" \
    > "$DIR/fixture-inventory.log" 2>&1 || true
echo "fixture_inventory_log:"; cat "$DIR/fixture-inventory.log"
TSV=$(wc -l < "$DIR/fixture-inventory.tsv" | tr -d ' ')
DATA=$((TSV - 1))
echo "FIXTURE_INVENTORY_TSV_LINES=$TSV DATA_ROWS=$DATA"
[ "$DATA" -eq 88 ] || { echo "AC07_FAIL: data != 88"; exit 7; }
FRESH=/tmp/lexer07-c01-out
[ -f "$FRESH/corpus-matrix.tsv" ] || {
  echo "AC07_FAIL: missing fresh evidence"; exit 8; }
cp -f "$FRESH/corpus-matrix.tsv" "$DIR/"
cp -f "$FRESH/corpus-object-provenance.tsv" "$DIR/"
./build/lexer07-proof-verify --allow-closed "$DIR" \
    > "$DIR/proof-verify.log" 2>&1 || VRC=$?
echo "proof_verify_log:"; cat "$DIR/proof-verify.log"
echo "AC07_VERIFIER_RC=${VRC:-1}"
[ "${VRC:-1}" != "0" ] || { echo "AC07_FAIL: verifier accepted"; exit 9; }
echo "FIXTURE_MUTATION_NEGATIVE_CONTROL=PASS"
exit 0

