#!/bin/sh
# scripts/quality/lexer09-generation-provenance-verify.sh
#
# ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL.
# Generation provenance verifier (≤50 LOC dispatch glue).
# Substantive SHA-256 logic lives in PolyC ./build/lexer07-sha256.
#
# USAGE:
#   scripts/quality/lexer09-generation-provenance-verify.sh <provenance.tsv> \
#       [forged_raw_output_path] [forged_as=G3]
set -eu
PROV_TSV="${1:-}"
FORGED_PATH="${2:-}"
FORGED_AS="${3:-G3}"
[ -z "$PROV_TSV" ] || [ ! -f "$PROV_TSV" ] && { echo "PROVENANCE_VERIFIER_RC=2 reason=missing-tsv"; exit 2; }
[ -x ./build/lexer07-sha256 ] || { echo "PROVENANCE_VERIFIER_RC=2 reason=missing-sha-tool"; exit 2; }
sha_of() { ./build/lexer07-sha256 --file "$1" 2>/dev/null | tr -d '\r\n'; }
awk_pass=0; awk_fail=0
while IFS="$(printf '\t')" read -r gen cpath csha spath ssha rpath rsha; do
  [ "$gen" = "$FORGED_AS" ] && [ -n "$FORGED_PATH" ] && rpath="$FORGED_PATH"
  eff=$(sha_of "$rpath")
  if [ "$eff" = "$rsha" ]; then echo "PROVENANCE_ROW generation=$gen raw_sha_match=YES"; awk_pass=$((awk_pass+1));
  else echo "PROVENANCE_ROW generation=$gen raw_sha_match=NO recorded=$rsha actual=$eff"; awk_fail=$((awk_fail+1)); fi
done < <(tail -n +2 "$PROV_TSV")
echo "PROVENANCE_ROW_PASS=$awk_pass"
echo "PROVENANCE_ROW_FAIL=$awk_fail"
[ -n "$FORGED_PATH" ] && {
  echo "FORGED_GENERATION=$FORGED_AS"
  echo "FORGED_PATH=$FORGED_PATH"
  FORGED_SHA=$(sha_of "$FORGED_PATH")
  RECORDED_SHA=$(awk -F'\t' -v a="$FORGED_AS" 'NR>1 && $1==a {print $7; exit}' "$PROV_TSV")
  echo "FORGED_RECORDED_RAW_SHA=$RECORDED_SHA"
  echo "FORGED_ACTUAL_RAW_SHA=$FORGED_SHA"
  if [ "$FORGED_SHA" != "$RECORDED_SHA" ]; then echo "FORGED_COPY_DETECTED=YES"; echo "GENERATION_COPY_DETECTED=YES"; echo "GENERATION_COPY_VERIFIER_RC_NONZERO=YES";
  else echo "FORGED_COPY_DETECTED=NO"; echo "GENERATION_COPY_DETECTED=NO"; echo "GENERATION_COPY_VERIFIER_RC_NONZERO=NO"; fi
}
[ "$awk_fail" = "0" ] && { echo "PROVENANCE_VERIFIER_RC=0 verdict=PASS"; exit 0; } || { echo "PROVENANCE_VERIFIER_RC=1 verdict=FAIL"; exit 1; }
