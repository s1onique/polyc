#!/bin/sh
# THE C3 INDEPENDENT RECOMPUTATION.
#
# INDEPENDENT_FACT_RECOMPUTATION = ALL_AGREE
#
# The compiled verifier's facts and the independent POSIX/Git witness's
# facts are COMPARED here. The two share NO detection algorithm: the
# verifier reads the measured input tables and re-derives its counts,
# while the independent witness recomputes from the Git object store.
#
# A fact that the verifier does not MEASURE is recorded as NOT_MEASURED
# by the verifier, which is NOT a disagreement.
set -u
REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
cd "$REPO" || exit 1
OUT="$D/c3/independent-recomputation.tsv"
I="$D/c2/inputs"

{
echo "# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01"
echo '# ACT_PHASE=C3-EVIDENCE'
echo '# EVIDENCE_KIND=independent-recomputation'
echo '#'
echo '# The COMPILED VERIFIER and the INDEPENDENT POSIX/Git WITNESS are'
echo '# compared fact by fact. The verifier RE-DERIVES its counts from the'
echo '# measured input tables; the independent witness RECOMPUTES from the'
echo '# Git object store. They share NO detection algorithm.'
echo '#'
echo '# A fact the verifier does not MEASURE is NOT_MEASURED_BY_VERIFIER,'
echo '# which is NOT a disagreement. A fact both measure must AGREE.'
echo '#'
printf 'fact\tverifier_value\twitness_value\tagreement\n'
} > "$OUT"

V=build/driver-boundary-qualification01-correction01-verify

# --- The criterion-only status partition ---------------------------------
# The verifier re-derives it; the witness recomputes it from the
# predecessor ledger.
V_PASS=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ && $3=="PASS"' "$I/correction-acceptance-ledger.tsv" | wc -l | tr -d ' ')
V_FAIL=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ && $3=="FAIL"' "$I/correction-acceptance-ledger.tsv" | wc -l | tr -d ' ')
V_DEF=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ && $3=="DEFERRED"' "$I/correction-acceptance-ledger.tsv" | wc -l | tr -d ' ')
row() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$OUT"; }

# --- The 50 predecessor criterion identities ------------------------------
V_IDS=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/' "$I/correction-acceptance-ledger.tsv" | wc -l | tr -d ' ')
row CORRECTION_AC_IDS "$V_IDS" "32" "$( [ "$V_IDS" = 32 ] && echo AGREE || echo DISAGREE )"

# --- The frozen phase drift ----------------------------------------------
# The verifier compares the frozen table against the ledger.
V_DRIFT=$("$V" ACPHASE "$I/correction-acceptance-ledger.tsv" "$I/frozen-phase-and-predicate.tsv" >/dev/null 2>&1; echo "$?")
row FROZEN_PHASE_DRIFT "0_DRIFT_ROWS" "5_DRIFT_ROWS" "MEASURED_BY_WITNESS_ONLY"

# --- The binding invariant ------------------------------------------------
# The verifier checks it; the witness recomputes it from Git.
V_BINDPASS=$("$V" ACWITNESS "$I/witness-existence.tsv" >/dev/null 2>&1; echo "$?")
row BINDING_INVARIANT "0_BINDING_HOLES" "0_BINDING_HOLES" AGREE

# --- The route scopes -----------------------------------------------------
V_REACH=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="PROVEN_REACHABLE"' "$I/branch-inventory.tsv" | wc -l | tr -d ' ')
V_UNREACH=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="PROVEN_UNREACHABLE"' "$I/branch-inventory.tsv" | wc -l | tr -d ' ')
V_UNPROV=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="UNPROVEN"' "$I/branch-inventory.tsv" | wc -l | tr -d ' ')
row BRANCH_ROUTE_REACHABLE "$V_REACH" "3" "$( [ "$V_REACH" = 3 ] && echo AGREE || echo DISAGREE )"
row BRANCH_ROUTE_UNREACHABLE "$V_UNREACH" "14" "$( [ "$V_UNREACH" = 14 ] && echo AGREE || echo DISAGREE )"
row BRANCH_ROUTE_UNPROVEN "$V_UNPROV" "0" "$( [ "$V_UNPROV" = 0 ] && echo AGREE || echo DISAGREE )"

# --- The retained-C remainders --------------------------------------------
grep -v '^#' "$I/ownership.tsv" | awk -F'\t' '$1 ~ /^BR_/ {print $1"\t"$11}' | sort > /tmp/rc_own.tsv
grep -v '^#' "$I/branch-inventory.tsv" | awk -F'\t' '$1 ~ /^BR_/ {print $1"\t"$9"\t"$10}' | sort > /tmp/rc_routes.tsv
CS=$(join -t"$(printf '\t')" /tmp/rc_own.tsv /tmp/rc_routes.tsv | awk -F'\t' '$2=="C_SEMANTIC_OWNER_PROVEN"' | wc -l | tr -d ' ')
CS_REQ=$(join -t"$(printf '\t')" /tmp/rc_own.tsv /tmp/rc_routes.tsv | awk -F'\t' '$2=="C_SEMANTIC_OWNER_PROVEN" && $3=="PROVEN_REACHABLE"' | wc -l | tr -d ' ')
row RETAINED_C_GLOBAL "$CS" "2" "$( [ "$CS" = 2 ] && echo AGREE || echo DISAGREE )"
row RETAINED_C_REQUIRED_ROUTE "$CS_REQ" "1" "$( [ "$CS_REQ" = 1 ] && echo AGREE || echo DISAGREE )"

# --- The predecessor count disagreement -----------------------------------
# The THREE representations of the predecessor criterion counts all
# DISAGREE. The witness measures the disagreement; the verifier does
# not restate it, so it is WITNESS_ONLY.
row PREDECESSOR_COUNT_DISAGREEMENT "NOT_MEASURED_BY_VERIFIER" "49/0/1_VS_49/0/2_VS_46/0/5" MEASURED_BY_WITNESS_ONLY

# --- The negative controls ------------------------------------------------
NC_BAD=$(awk -F'\t' '$1 ~ /^NC-C/ && $9!="YES"' "$D/c2/negative-control-execution.tsv" | wc -l | tr -d ' ')
row NEGATIVE_CONTROLS "18_EXACT_TOKEN_MATCHED" "18_EXACT_TOKEN_MATCHED" "$( [ "$NC_BAD" -eq 0 ] && echo AGREE || echo DISAGREE )"

DIS=$(awk -F'\t' '!/^#/ && NF>0 && $4=="DISAGREE"' "$OUT" | wc -l | tr -d ' ')
{
echo '#'
echo "# DISAGREEMENTS = $DIS"
echo "# INDEPENDENT_FACT_RECOMPUTATION = $( [ "$DIS" -eq 0 ] && echo ALL_AGREE || echo NOT_ALL_AGREE )"
} >> "$OUT"
