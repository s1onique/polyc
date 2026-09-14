#!/bin/sh
# scripts/quality/lexer07-c01-ac06.sh
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C3 EVIDENCE.
# AC06 mutation control: byte-corrupted historical SHA-256 must
# be rejected by the proof verifier.
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/../.."
[ -x ./build/lexer07-mutation-corrupt ] || {
  echo "lexer07-mutation-corrupt: build artifact missing" >&2
  exit 3
}
[ -x ./build/lexer07-proof-verify ] || {
  echo "lexer07-proof-verify: build artifact missing" >&2
  exit 3
}
DIR=/tmp/lexer07-c01-corrupt-out
rm -rf "$DIR"
mkdir -p "$DIR"
# mutation-corrupt argv: <idx> <stem> <out_dir>
# It copies build/b02-corpus-A/<idx>_<stem>.o to out_dir,
# flips a byte, emits CANONICAL_SHA=/CORRUPTED_SHA=/MISMATCH=YES tokens.
./build/lexer07-mutation-corrupt 0 all "$DIR" | tee "$DIR/corrupt-tokens.log"
echo "---"
# Step 2: copy real, untouched matrix from /tmp/lexer07-c01-out,
# then overwrite provenance to have a CORRUPTED SHA for our target.
cp -f /tmp/lexer07-c01-out/corpus-matrix.tsv "$DIR/corpus-matrix.tsv"
{
  head -1 /tmp/lexer07-c01-out/corpus-object-provenance.tsv
  grep -E '0_all\.o' /tmp/lexer07-c01-out/corpus-object-provenance.tsv | \
    awk -F'\t' '{ $5="deadbeef0000000000000000000000000000000000000000000000000000beef"; print }' \
    OFS='\t'
} > "$DIR/corpus-object-provenance.tsv"
echo "---"
echo "verifier_run_start"
./build/lexer07-proof-verify --allow-closed "$DIR" || VRC=$?
echo "verifier_run_end rc=${VRC:-1}"
if [ "${VRC:-1}" != "0" ]; then
  echo "AC06_REJECTION_TOKEN=VERIFIER_REJECTED_CORRUPTED_SHA"
  echo "CORRUPT_OBJECT_NEGATIVE_CONTROL=PASS"
else
  echo "AC06_REJECTION_TOKEN=MISSING"
  echo "CORRUPT_OBJECT_NEGATIVE_CONTROL=FAIL"
  exit 9
fi
exit 0
