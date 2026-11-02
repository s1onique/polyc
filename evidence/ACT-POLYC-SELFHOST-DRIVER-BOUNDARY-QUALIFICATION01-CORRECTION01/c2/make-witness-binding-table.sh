#!/bin/sh
set -u
REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
I=$D/c2/inputs
E=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
CLOSE=edfc3b16620e8d84b00a276984109a3b2fa8b338
cd "$REPO" || exit 1

git ls-tree -r --name-only "$CLOSE" > /tmp/wb_closetree.txt
grep -v '^#' "$D/c1/witness-binding-audit.tsv" | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$2"\t"$4"\t"$5"\t"$6"\t"$9}' | sort > /tmp/wb_audit.tsv
grep -v '^#' "$D/c1/reconciled-predecessor-verdicts.tsv" | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$14}' | sort > /tmp/wb_status.tsv
grep -v '^#' "$D/c1/alternate-witness-search.tsv" | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$5"\t"$7"\t"$9}' | sort > /tmp/wb_alt.tsv
grep -v '^#' "$D/c1/analyst-adjudications.tsv" | awk -F'\t' '{print $2"\t"$5"\t"$7"\t"$11}' | sort > /tmp/wb_adj.tsv

{
echo '# THE WITNESS BINDING TABLE FOR THE CORRECTION VERIFIER.'
echo '#'
echo '# One row per PREDECESSOR criterion AC01..AC50. Every field is'
echo '# MEASURED, not asserted.'
echo '#'
echo '#   frozen_phase        the predecessor Q0 frozen roster.'
echo '#   cited_witness       the predecessor ledger cited path.'
echo '#   cited_present       the cited path EXISTS in the predecessor'
echo '#                       close tree.'
echo '#   cited_phase_valid   the cited path was committed AT OR BEFORE'
echo '#                       the frozen criterion phase.'
echo '#   cited_carries       the cited witness MATCHES the frozen'
echo '#                       predicate.'
echo '#   binding_artifact    the artifact that ACTUALLY discharges the'
echo '#                       frozen predicate. NONE when no artifact'
echo '#                       discharges it.'
echo '#   binding_present     the binding artifact EXISTS in the close tree.'
echo '#   binding_phase_valid the binding artifact is at a valid phase.'
echo '#   binding_carries     the binding artifact carries the frozen'
echo '#                       subject.'
echo '#   verified_status     the reconciled verdict, which is the'
echo '#                       correction adjudication and the AUTHORITY'
echo '#                       over the intermediate alternate-witness'
echo '#                       search verdict.'
echo '#'
echo '# A criterion may be adjudicated PROVEN only when it has a binding'
echo '# artifact that is present, phase-valid and carries the subject.'
echo '# A criterion that is NOT proven has NO binding artifact, even when'
echo '# the intermediate alternate-witness search proposed one.'
echo '#'
printf 'ac_id\tfrozen_phase\tcited_witness\tcited_present\tcited_phase_valid\tcited_carries\tbinding_artifact\tbinding_present\tbinding_phase_valid\tbinding_carries\tverified_status\n'
} > "$I/witness-existence.tsv"

: > /tmp/wb_out.tsv
while IFS="$(printf '\t')" read -r id fph cit citp citpv citc; do
  st=$(awk -F'\t' -v i="$id" '$1==i{print $2; exit}' /tmp/wb_status.tsv)
  ba=NONE; bpv=NOT_APPLICABLE; bpc=NO
  case "$st" in
    PROVEN_AS_FROZEN)
      # The CITED witness discharges the criterion.
      ba="$cit"; bpv="$citpv"; bpc="$citc" ;;
    PROVEN_BY_ALTERNATE_EXISTING_WITNESS)
      # A DIFFERENT existing witness discharges it. The ALTERNATE
      # SEARCH proposes it; the analyst ADJUDICATION supersedes it
      # when one exists for this criterion.
      ba=$(awk -F'\t' -v i="$id" '$1==i{print $2; exit}' /tmp/wb_alt.tsv)
      bpv=$(awk -F'\t' -v i="$id" '$1==i{print $4; exit}' /tmp/wb_alt.tsv)
      bpc=$(awk -F'\t' -v i="$id" '$1==i{print $3; exit}' /tmp/wb_alt.tsv)
      aart=$(awk -F'\t' -v i="$id" '$1==i{print $2; exit}' /tmp/wb_adj.tsv)
      if [ -n "$aart" ] && [ "$aart" != "NONE" ]; then
        ba="$aart"
        bpv=$(awk -F'\t' -v i="$id" '$1==i{print $3; exit}' /tmp/wb_adj.tsv)
        bpc=NO
        av=$(awk -F'\t' -v i="$id" '$1==i{print $4; exit}' /tmp/wb_adj.tsv)
        case "$av" in PROVEN*) bpc=YES ;; esac
      fi
      if [ -z "$ba" ] || [ "$ba" = "NONE" ]; then ba=NONE; bpv=NOT_APPLICABLE; bpc=NO; fi ;;
  esac
  bpres=NO
  case "$ba" in */*) grep -qx -- "$E/$ba" /tmp/wb_closetree.txt && bpres=YES ;; esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$fph" "$cit" "$citp" "$citpv" "$citc" \
    "$ba" "$bpres" "$bpv" "$bpc" "$st" >> /tmp/wb_out.tsv
done < /tmp/wb_audit.tsv
cat /tmp/wb_out.tsv >> "$I/witness-existence.tsv"
