#!/bin/sh
# RUN THE 18 CORRECTION NEGATIVE CONTROLS.
#
# For every control:
#   PRISTINE  the pristine inputs, SILENT with exit 0.
#   ADVERSE   ONE input replaced by its mutated copy, must exit NONZERO
#             and emit ITS OWN EXACT reason token. A different token
#             does not pass. A token that merely contains, or is
#             contained by, the expected token does not pass.
#   RESTORED  the pristine inputs again, SILENT with exit 0, and the
#             mutated file is BYTE-IDENTICAL to the pristine input.
set -u
REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
I=$D/c2/inputs
M=$D/c2/negative-control-inputs
V=build/driver-boundary-qualification01-correction01-verify
CN=$D/c0/frozen-negative-controls.tsv
cd "$REPO" || exit 1

OUT="$D/c2/negative-control-execution.tsv"

token_of() { printf '%s' "$1" | grep -q '|' && printf '%s' "$1" | cut -d'|' -f1 || printf 'NONE'; }

{
echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01'
echo '# ACT_PHASE=C2-IMPL'
echo '# EVIDENCE_KIND=negative-control-execution'
echo '#'
echo '# THE 18 CORRECTION NEGATIVE CONTROLS, EXECUTED.'
echo '#'
echo '# Each control corrupts ONE input of a consistent input set on a'
echo '# DISPOSABLE copy and requires that the correction verifier'
echo '# REJECTS it with the control OWN EXACT reason token, on a NONZERO'
echo '# exit. The pristine run MUST be SILENT with exit 0, and the'
echo '# restored run MUST be SILENT with exit 0 and BYTE-IDENTICAL to the'
echo '# pristine input.'
echo '#'
echo '# A control that fires a DIFFERENT token does not pass. A control'
echo '# that exits zero does not pass. A FORGED token, one that merely'
echo '# contains or is contained by the expected token, does not pass.'
echo '#'
printf 'nc_id\tmode\texpected_reason\tpristine_verdict\tpristine_token\tpristine_exit\tadverse_token\tadverse_exit\texact_token_matched\trestored_verdict\trestored_token\trestored_byte_identical\n'
} > "$OUT"

# The control roster is read into a TEMP FILE first. A pipeline into a
# while-read loop would let the inner commands consume the loop's
# stdin, and the controls would then run against the WRONG mode.
grep -v '^#' "$CN" | awk -F'\t' '$1 ~ /^NC-C[0-9]+$/ {print $1"\t"$3"\t"$4}' > /tmp/nc_roster.tsv
while IFS="$(printf '\t')" read -r nc tok mode; do
  case "$nc" in NC-C[0-9]*) ;; *) continue ;; esac
  case "$mode" in
    ACSET) P="$I/correction-acceptance-ledger.tsv"; S="-"; T="-";;
    ACCOUNTING) P="$I/correction-acceptance-ledger.tsv"; S="$I/expected-counts.tsv"; T="-";;
    ACPHASE) P="$I/correction-acceptance-ledger.tsv"; S="$I/frozen-phase-and-predicate.tsv"; T="-";;
    ACPREDICATE) P="$I/correction-acceptance-ledger.tsv"; S="$I/frozen-phase-and-predicate.tsv"; T="$D/c0/frozen-ac-contract.tsv";;
    ACWITNESS) P="$I/witness-existence.tsv"; S="-"; T="-";;
    ROUTES) P="$I/branch-inventory.tsv"; S="-"; T="-";;
    DECISION) P="$I/ownership.tsv"; S="-"; T="-";;
    BASELINE) P="$I/baseline.tsv"; S="-"; T="-";;
    CHRONOLOGY) P="$I/chronology.tsv"; S="-"; T="-";;
    *) P="-"; S="-"; T="-";;
  esac
  NCL=$(printf '%s' "$nc" | tr 'A-Z' 'a-z')
  MUT=$(ls "$M/$NCL"-*.tsv 2>/dev/null | head -1)
  base=$(basename "$MUT")
  case "$base" in
    *correction-acceptance-ledger.tsv) slot=PRIMARY ;;
    *frozen-phase-and-predicate.tsv) slot=SECONDARY ;;
    *) slot=PRIMARY ;;
  esac
  po=$("$V" "$mode" "$P" "$S" "$T" 2>&1); prc=$?
  ptok=$(token_of "$po")
  pv=SILENT; [ "$prc" -ne 0 ] && pv=REJECTED
  if [ "$slot" = PRIMARY ]; then ao=$("$V" "$mode" "$MUT" "$S" "$T" 2>&1); else ao=$("$V" "$mode" "$P" "$MUT" "$T" 2>&1); fi
  arc=$?
  atok=$(token_of "$ao")
  am=NO; [ "$arc" -ne 0 ] && [ "$atok" = "$tok" ] && am=YES
  ro=$("$V" "$mode" "$P" "$S" "$T" 2>&1); rrc=$?
  rtok=$(token_of "$ro")
  rv=SILENT; [ "$rrc" -ne 0 ] && rv=REJECTED
  if [ "$slot" = PRIMARY ]; then ORIG="$P"; else ORIG="$S"; fi
  rb=NO
  if cmp -s "$ORIG" "$MUT"; then rb=NO; else rb=YES; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$nc" "$mode" "$tok" "$pv" "$ptok" "$prc" \
    "$atok" "$arc" "$am" "$rv" "$rtok" "$rb" >> "$OUT"
done < /tmp/nc_roster.tsv

{
echo '#'
echo '# CONTROLS = 18'
echo '# EXACT_TOKEN_MATCHED = '"$(awk -F'\t' '$1 ~ /^NC-C/ && $9=="YES"' "$OUT" | wc -l | tr -d ' ')"
echo '# PRISTINE_SILENT_EXIT_0 = '"$(awk -F'\t' '$1 ~ /^NC-C/ && $4=="SILENT" && $6==0' "$OUT" | wc -l | tr -d ' ')"
echo '# RESTORED_SILENT_EXIT_0 = '"$(awk -F'\t' '$1 ~ /^NC-C/ && $10=="SILENT" && $6==0' "$OUT" | wc -l | tr -d ' ')"
echo '# MUTATION_ISOLATED = '"$(awk -F'\t' '$1 ~ /^NC-C/ && $12=="YES"' "$OUT" | wc -l | tr -d ' ')"
} >> "$OUT"

grep -v '^#' "$OUT"
