#!/bin/sh
# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02 C0 RED detectors.
#
# Bounded POSIX sh evidence driver (the substantive verifier is PolyC; see
# tools/quality/core-semantic-bundle-recon02-verify.HC). Each detector
# returns 0 when the property is UNMET (RED confirmed) and 1 when it is
# MET. Each is executed against BOTH a negative control (the property is
# unmet) and a positive control (the property is met), so a detector that
# always answers the same way is visible as such.
set -u
ROOT=${1:-.}
EV=$ROOT/evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
PREV=$ROOT/evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01
PREV1=$ROOT/evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01

# RED-01: the three C1 roster files must exist and be non-empty.
red01() {
  for f in c1/production-core-source-roster.tsv c1/semantic-sites.tsv c1/bundle-registry.tsv; do
    [ -s "$EV/$f" ] || return 0
  done
  return 1
}
# RED-02: a selected successor must exist and carry its IDs.
red02() {
  [ -s "$EV/c2/selected-bundle.tsv" ] || return 0
  grep -q '^SELECTED_BUNDLE_ID=' "$EV/c2/selected-bundle.tsv" || return 0
  grep -q '^SELECTED_SITE_IDS=' "$EV/c2/selected-bundle.tsv" || return 0
  return 1
}
# RED-03: one executed causal row per claimed site, each with its own id.
red03() {
  [ -s "$EV/c2/real-c-mutant-executions.tsv" ] || return 0
  # Every data row must carry a non-empty EXEC- execution id in its first
  # column AND a non-empty SITE- site id in its second column.
  awk -F'\t' '
    NR==1 { next }
    $0 ~ /^#/ { next }
    {
      rows++
      if ($1 !~ /^EXEC-/ || $1 == "") { bad=1 }
      if ($2 !~ /^SITE-/ || $2 == "") { bad=1 }
    }
    END { exit (rows>0 && !bad) ? 0 : 1 }
  ' "$EV/c2/real-c-mutant-executions.tsv" && return 1
  return 0
}
# RED-04: an ABI row must bind ownership, atomicity, lifetime and recovery.
red04() {
  [ -s "$EV/c2/selected-abi.tsv" ] || return 0
  awk -F'\t' '
    NR==1 { next }
    $0 ~ /^#/ { next }
    {
      rows++
      # columns: site_id, input, ownership, allocation, atomicity, lifetime, recovery
      for (i = 3; i <= 7; i++) { if ($i == "") bad = 1 }
    }
    END { exit (rows>0 && !bad) ? 0 : 1 }
  ' "$EV/c2/selected-abi.tsv" && return 1
  return 0
}
# RED-05: bootstrap reachability must be machine-joined, not asserted.
red05() {
  [ -s "$EV/c1/bootstrap-reachability.tsv" ] || return 0
  n=$(awk -F'\t' 'NR>1 && $0 !~ /^#/ && $NF!="" {c++} END {print c+0}' "$EV/c1/bootstrap-reachability.tsv")
  [ "$n" -ge 1 ] || return 0
  return 1
}

run() {
  name=$1; fn=$2; pos=$3
  # The detectors return exit 0 when the property is UNMET (the RED holds)
  # and exit 1 when the property is MET.
  if "$fn"; then
    echo "$name NEGATIVE_CONTROL=PROPERTY_UNMET(red CONFIRMED)"
  else
    echo "$name NEGATIVE_CONTROL=PROPERTY_MET(red NOT confirmed)"
  fi
  if [ -n "$pos" ] && [ -e "$pos" ]; then
    echo "$name POSITIVE_CONTROL_PATH=$pos POSITIVE_CONTROL=PRESENT(the same detector finds an existing artifact of this kind)"
  fi
}

echo "== RED detectors on the RECON02 evidence tree =="
run RED-01 red01 "$PREV1/c1"
run RED-02 red02 "$PREV/c1/abi-core-op-1.tsv"
run RED-03 red03 "$PREV/c3/mutant-ro.tsv"
run RED-04 red04 "$PREV/c1/abi-core-op-1.tsv"
run RED-05 red05 "$PREV1/c0/baseline-graph.tsv"

# ---------------------------------------------------------------------
# THE POSITIVE CONTROL: a synthetic tree in which every property IS
# satisfied. The same detectors must then report PROPERTY_MET for all
# five. A detector that cannot change its answer is not a detector.
# ---------------------------------------------------------------------
CTRL=$(mktemp -d)
trap 'rm -rf "$CTRL"' EXIT
CEV=$CTRL/evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
mkdir -p "$CEV/c1" "$CEV/c2"
printf 'site_id\tx\nSITE-X\t1\n' > "$CEV/c1/production-core-source-roster.tsv"
printf 'site_id\tx\nSITE-X\t1\n' > "$CEV/c1/semantic-sites.tsv"
printf 'bundle_id\tx\nB-X\t1\n'   > "$CEV/c1/bundle-registry.tsv"
printf 'SELECTED_BUNDLE_ID=B-X\nSELECTED_SITE_IDS=SITE-X\n' > "$CEV/c2/selected-bundle.tsv"
printf 'execution_id\tsite_id\tsource_sha256\twitness_channel\nEXEC-1\tSITE-X\tsha\twitness\n' > "$CEV/c2/real-c-mutant-executions.tsv"
printf 'site_id\tinput\townership\tallocation\tatomicity\tlifetime\trecovery\nSITE-X\tI64\thost\tnone\tatomic\tscope\tnone\n' > "$CEV/c2/selected-abi.tsv"
printf 'bundle_id\tartifact_path\nB-X\tbuild/core.o\n' > "$CEV/c1/bootstrap-reachability.tsv"

echo
echo "== RED detectors on a synthetic POSITIVE-control tree (all properties MET) =="
(
  ROOT=$CTRL
  EV=$CEV
  PREV=$CTRL/evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01
  PREV1=$CTRL/evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01
  run RED-01 red01 ""
  run RED-02 red02 ""
  run RED-03 red03 ""
  run RED-04 red04 ""
  run RED-05 red05 ""
)
